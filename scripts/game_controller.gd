extends Node2D

const AudioFeedbackServiceType = preload("res://scripts/audio_feedback_service.gd")
const HapticsServiceType = preload("res://scripts/haptics_service.gd")
const AssetCatalogType = preload("res://scripts/asset_catalog.gd")
const GemSpriteLayerType = preload("res://scripts/gem_sprite_layer.gd")
const ResultOverlayScene = preload("res://scenes/ui/ResultOverlay.tscn")
const LevelConfigType = preload("res://scripts/level_config.gd")
const GameplayHudScene = preload("res://scenes/ui/GameplayHud.tscn")
const GameplayEffectsLayerType = preload("res://scripts/gameplay_effects_layer.gd")
const ProgressionSaveServiceType = preload("res://scripts/progression_save_service.gd")
const GameSettingsServiceType = preload("res://scripts/game_settings_service.gd")
const HomeOverlayType = preload("res://scripts/home_overlay_layer.gd")
const AdConfigType = preload("res://scripts/ad_config.gd")

var pieces: Array[GemPiece] = []
var simulation := BoardSimulation.new()
var merge_service := ContactMergeService.new()
var next_piece_id := 1
var level_config: Dictionary = LevelConfigType.level_1()
var level_number := 1
var level_seed := 0
var level_start_coins := 0
var next_level := 1
var next_queue_index := 0
var target_progress := 0
var target_index := 0
var counted_target_result_ids: Dictionary = {}
## Exactly-once guard for production merge result IDs. It prevents duplicate
## score, target, sound, haptic, and reward presentation from a repeated event.
var processed_merge_result_ids: Dictionary = {}
## Results count only after their own merge presentation has completed.
var pending_target_presentations: Dictionary = {}
var active_piece_id := -1
var dragging := false
var merge_presentations: Array[Dictionary] = []
## Confirmed merge rewards are run coins. `score` remains a compatibility
## property for older tools/tests and always resolves to the same exact integer.
var coins := 0
var score: int:
	get:
		return coins
	set(value):
		coins = value
var chain_multiplier := 1
var danger_timers: Dictionary = {}
var won := false
var win_qualified := false
var win_presented := false
var win_hold_elapsed := 0.0
var failed := false
var collection_in_progress := false
var target_collection: Dictionary = {}
var final_target_result_id := -1
var background_sprite: Sprite2D
var table_sprite: Sprite2D
var applied_table_offset_x := 0.0
var applied_table_offset_y := 0.0
var ready_delay_elapsed := 0.0
var launcher_handoff_elapsed := 0.0
var audio_feedback: Node
var haptics_feedback: RefCounted
var gem_sprite_layer: GemSpriteLayer
var gameplay_ui: GameplayHudLayer
var effects_layer: GameplayEffectsLayer
var result_overlay: ResultOverlayLayer
var home_overlay: HomeOverlayLayer
var ad_manager: Node
var level_reward_for_completion := 0
var completion_action_pending := false
var completion_transition_consumed := false
var completion_destination := "play"
var rewarded_bonus_granted := false
var completion_reward_resolved := false
enum AppFlowState { STARTUP, HOME, LEVEL_READY, PLAYING, LEVEL_COMPLETE, REWARD_PROCESSING, AD_SHOWING }
var app_flow_state := AppFlowState.STARTUP
var presentation_event_trace: Array[Dictionary] = []
var process_frame_index := 0
var piece_visual_feedbacks: Dictionary = {}
## Developer-only inspection aid. F8 toggles it in editor/desktop builds; it
## starts disabled and has no input or gameplay authority on Android.
var debug_calibration_enabled := false
var debug_contact_points: Array[Dictionary] = []

# A completed shot can pass through each state only once. This prevents the
# settled-board condition from spawning a launcher again on every frame.
enum LauncherState {
	READY_TO_AIM,
	SHOT_IN_FLIGHT,
	RESOLVING,
	SPAWNING_NEXT,
}

var launcher_state: LauncherState = LauncherState.SPAWNING_NEXT

func _ready() -> void:
	ad_manager = get_node_or_null("/root/AdManager")
	if ad_manager != null and ad_manager.has_signal("rewarded_availability_changed"):
		ad_manager.rewarded_availability_changed.connect(_on_rewarded_availability_changed)
	if ad_manager != null and ad_manager.has_signal("privacy_options_availability_changed"):
		ad_manager.privacy_options_availability_changed.connect(_on_privacy_options_availability_changed)
	var saved := ProgressionSaveServiceType.load_progress()
	var saved_settings := GameSettingsServiceType.load_settings()
	level_number = int(saved.level_number)
	level_seed = int(saved.seed)
	coins = int(saved.total_coins)
	level_start_coins = coins
	_configure_generated_level(level_number, level_seed)
	_setup_asset_presentation()
	_on_privacy_options_availability_changed(
		ad_manager != null and bool(ad_manager.call("is_privacy_options_available"))
	)
	_refresh_background_fill()
	var viewport := get_viewport()
	if viewport != null:
		viewport.size_changed.connect(_refresh_background_fill)
	audio_feedback = AudioFeedbackServiceType.new()
	haptics_feedback = HapticsServiceType.new()
	audio_feedback.music_enabled = bool(saved_settings.music_enabled)
	audio_feedback.sfx_enabled = bool(saved_settings.sound_enabled)
	haptics_feedback.enabled = bool(saved_settings.vibration_enabled)
	add_child(audio_feedback)
	_advance_launcher_lifecycle()
	_sync_gems_and_mark_visibility()
	_refresh_hud()
	queue_redraw()
	if OS.has_feature("mobile"):
		_show_home()
	else:
		app_flow_state = AppFlowState.PLAYING

func _process(delta: float) -> void:
	process_frame_index += 1
	for marker in debug_contact_points:
		marker.age = float(marker.get("age", 0.0)) + delta
	debug_contact_points = debug_contact_points.filter(func(marker: Dictionary) -> bool: return float(marker.get("age", 0.0)) < 0.45)
	if effects_layer != null:
		effects_layer.update_effects(delta)
	_update_piece_visual_feedbacks(delta)
	if failed:
		_sync_gems_and_mark_visibility()
		_refresh_hud()
		queue_redraw()
		return
	if win_qualified:
		_update_merge_presentations(delta)
		_sync_gems_and_mark_visibility()
		_update_win_presentation(delta)
		_refresh_hud()
		queue_redraw()
		return
	simulation.step(pieces, delta, merge_service)
	var collision_impacts := simulation.consume_collision_impacts()
	var result := merge_service.resolve(pieces, next_piece_id)
	pieces = result.pieces
	next_piece_id = result.next_id
	_route_collision_feedback(collision_impacts, result.presentation_events)
	_apply_confirmed_merge_events(result.presentation_events)
	_update_merge_presentations(delta)
	_update_target_collection(delta)
	_update_danger_timers(delta)
	if win_qualified or failed:
		_sync_gems_and_mark_visibility()
		_refresh_hud()
		queue_redraw()
		return
	if result.merge_count > 0 and get_active_piece() == null:
		# Only a merge that actually consumed the fired launcher may advance its
		# lifecycle. An unrelated board merge must never strand a still-active
		# shot in RESOLVING/SPAWNING_NEXT.
		active_piece_id = -1
		if launcher_state != LauncherState.READY_TO_AIM:
			launcher_state = LauncherState.RESOLVING
			ready_delay_elapsed = 0.0
	_advance_launcher_lifecycle(delta)
	_sync_gems_and_mark_visibility()
	_refresh_hud()
	queue_redraw()

func _advance_launcher_lifecycle(delta: float = 0.0) -> void:
	if collection_in_progress:
		return
	match launcher_state:
		LauncherState.READY_TO_AIM:
			# A live game must never remain in a ready state without a usable
			# launcher.  Merge resolution normally changes this state itself, but
			# this recovery also covers an unexpectedly removed active body without
			# introducing a cap or touching danger/win terminal behavior.
			if get_active_piece() == null:
				active_piece_id = -1
				launcher_state = LauncherState.SPAWNING_NEXT
		LauncherState.SHOT_IN_FLIGHT:
			var active := get_active_piece()
			if active == null:
				active_piece_id = -1
				launcher_state = LauncherState.RESOLVING
				ready_delay_elapsed = 0.0
				launcher_handoff_elapsed = 0.0
			else:
				# Unlimited means bounded replacement time, not "wait until this
				# body eventually sleeps". Crowded contacts can keep it moving.
				launcher_handoff_elapsed += delta
				if launcher_handoff_elapsed >= GameConfig.LAUNCHER_HANDOFF_DELAY:
					active.is_active_launcher = false
					active_piece_id = -1
					launcher_state = LauncherState.RESOLVING
					ready_delay_elapsed = 0.0
					launcher_handoff_elapsed = 0.0
		LauncherState.RESOLVING:
			if not merge_service.has_pending_candidates() and merge_presentations.is_empty():
				ready_delay_elapsed += delta
				if ready_delay_elapsed >= GameConfig.NEXT_LAUNCHER_READY_DELAY:
					launcher_state = LauncherState.SPAWNING_NEXT
			else:
				ready_delay_elapsed = 0.0
		LauncherState.SPAWNING_NEXT:
			# Reaching this state with an active marker means a prior transition
			# was interrupted. Demote that stale marker instead of deadlocking the
			# queue forever inside spawn_active_piece().
			var stale_active := get_active_piece()
			if stale_active != null:
				stale_active.is_active_launcher = false
				active_piece_id = -1
			if spawn_active_piece():
				launcher_state = LauncherState.READY_TO_AIM
				chain_multiplier = 1
				ready_delay_elapsed = 0.0
				launcher_handoff_elapsed = 0.0

func lifecycle_name() -> String:
	return LauncherState.keys()[launcher_state]

## Presentation data only. UI code reads this snapshot and never owns game rules.
func hud_snapshot() -> Dictionary:
	var active := get_active_piece()
	var highest_level := 1
	var visible_target := active_target()
	var sequence := target_sequence()
	if visible_target.is_empty() and not sequence.is_empty():
		visible_target = sequence.back() as Dictionary
	for piece in pieces:
		if not piece.consumed:
			highest_level = maxi(highest_level, piece.level)
	return {
		"level_number": level_number,
		"gem_identity_order": _active_identity_order(),
		"current_level": active.level if active != null else next_level,
		"next_level": next_level,
		"coins": coins,
		"score": coins,
		"chain_multiplier": chain_multiplier,
		"target_level": int(visible_target.get("tier", 1)),
		"target_progress": target_progress,
		"target_quantity": int(visible_target.get("quantity", 1)),
		"target_index": target_index,
		"target_total": target_sequence().size(),
		"target_collecting": collection_in_progress,
		"target_completed": win_qualified,
		"highest_level": highest_level,
		"music_enabled": audio_feedback.music_enabled if audio_feedback != null else true,
		"sound_enabled": audio_feedback.sfx_enabled if audio_feedback != null else true,
		"vibration_enabled": haptics_feedback.enabled if haptics_feedback != null else true,
	}

func _active_identity_order() -> Array[int]:
	var order: Array[int] = []
	var mapping: Dictionary = level_config.get("gem_identity_by_tier", {})
	for tier in range(1, 9):
		order.append(int(mapping.get(tier, tier)))
	return order

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F8:
		debug_calibration_enabled = not debug_calibration_enabled
		queue_redraw()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if gameplay_ui != null and gameplay_ui.is_pause_visible():
			_on_resume_requested()
		elif not win_presented and not failed:
			_on_settings_requested()
		if get_viewport() != null:
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		_handle_pointer(event.position, event.pressed)
	elif event is InputEventScreenDrag and dragging:
		move_active_to(event.position.x)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_pointer(event.position, event.pressed)
	elif event is InputEventMouseMotion and dragging:
		move_active_to(event.position.x)


func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST or not is_inside_tree():
		return
	# Mobile Back is a UI-state action: dismiss Pause first, open Pause during
	# active play, and leave completed/failed results on their explicit action.
	if result_overlay != null and result_overlay.visible_result:
		return
	if gameplay_ui != null and gameplay_ui.is_pause_visible():
		_on_resume_requested()
	elif gameplay_ui != null and not win_presented and not failed:
		_on_settings_requested()

func _handle_pointer(pointer: Vector2, pressed: bool) -> void:
	if win_presented or failed:
		return
	if pressed:
		if collection_in_progress:
			return
		var active := get_active_piece()
		var grabbed_gem := active != null and pointer.distance_to(active.position) <= active.radius * GameConfig.DRAG_HIT_RADIUS_MULTIPLIER
		if launcher_state == LauncherState.READY_TO_AIM and active != null and active.is_settled() and (grabbed_gem or GameConfig.aim_guide_contains(pointer, active.position, active.radius)):
			dragging = true
			move_active_to(pointer.x)
	elif dragging:
		dragging = false
		if not collection_in_progress:
			launch_active_piece()
func move_active_to(x_position: float) -> void:
	var active := get_active_piece()
	if launcher_state == LauncherState.READY_TO_AIM and active != null and active.is_settled():
		active.position.x = GameConfig.launcher_drag_x(x_position, active.position.y, active.radius)

func launch_active_piece() -> void:
	var active := get_active_piece()
	if launcher_state == LauncherState.READY_TO_AIM and active != null and active.is_settled():
		active.velocity = Vector2(0.0, -GameConfig.LAUNCH_SPEED)
		audio_feedback.emit_event("launch")
		haptics_feedback.emit_event("launch")
		if effects_layer != null:
			effects_layer.begin_launch(active.position, active.level)
		piece_visual_feedbacks[active.id] = {"kind": "launch", "elapsed": 0.0, "duration": 0.12}
		if gem_sprite_layer != null:
			gem_sprite_layer.set_presentation_scale(active.id, 0.92)
		launcher_handoff_elapsed = 0.0
		ready_delay_elapsed = 0.0
		launcher_state = LauncherState.SHOT_IN_FLIGHT

func spawn_active_piece() -> bool:
	# Idempotent for a lifecycle cycle: an existing launcher is never replaced.
	if get_active_piece() != null:
		return false
	var piece := GemPiece.new(next_piece_id, next_level, Vector2(GameConfig.table_center_x(), GameConfig.launch_y()), GameConfig.gem_collision_radius(next_level))
	next_piece_id += 1
	piece.is_active_launcher = true
	pieces.append(piece)
	piece_visual_feedbacks[piece.id] = {"kind": "spawn", "elapsed": 0.0, "duration": 0.16}
	if gem_sprite_layer != null:
		gem_sprite_layer.set_presentation_scale(piece.id, 0.84)
	active_piece_id = piece.id
	next_queue_index += 1
	next_level = LevelConfigType.launcher_level_at(level_config, next_queue_index)
	return true

func get_active_piece() -> GemPiece:
	for piece in pieces:
		if piece.id == active_piece_id and piece.is_active_launcher and not piece.consumed:
			return piece
	return null

func restart() -> void:
	if is_inside_tree():
		get_tree().paused = false
	pieces.clear()
	merge_service.clear()
	merge_presentations.clear()
	next_piece_id = 1
	_configure_generated_level(level_number, level_seed)
	active_piece_id = -1
	score = level_start_coins
	target_progress = 0
	target_index = 0
	counted_target_result_ids.clear()
	processed_merge_result_ids.clear()
	pending_target_presentations.clear()
	presentation_event_trace.clear()
	process_frame_index = 0
	piece_visual_feedbacks.clear()
	chain_multiplier = 1
	danger_timers.clear()
	won = false
	win_qualified = false
	win_presented = false
	win_hold_elapsed = 0.0
	level_reward_for_completion = 0
	completion_action_pending = false
	completion_transition_consumed = false
	completion_destination = "play"
	rewarded_bonus_granted = false
	completion_reward_resolved = false
	final_target_result_id = -1
	failed = false
	collection_in_progress = false
	_cancel_target_collection()
	dragging = false
	launcher_state = LauncherState.SPAWNING_NEXT
	ready_delay_elapsed = 0.0
	launcher_handoff_elapsed = 0.0
	if effects_layer != null:
		effects_layer.clear()
	if gem_sprite_layer != null:
		gem_sprite_layer.clear_presentation_scales()
	_advance_launcher_lifecycle()
	if gem_sprite_layer != null:
		_sync_gems_and_mark_visibility()
	if result_overlay != null:
		result_overlay.dismiss()
	if gameplay_ui != null:
		# A restart always returns to active play, including after Home/Continue.
		gameplay_ui.show()
		gameplay_ui.reset_presentation()
		_refresh_hud()

func _setup_asset_presentation() -> void:
	var background := Sprite2D.new()
	background.texture = AssetCatalogType.background_texture(int(level_config.get("background_index", 0)))
	background_sprite = background
	background.z_index = -20
	add_child(background)
	var table := Sprite2D.new()
	table.texture = AssetCatalogType.table_texture(int(level_config.get("table_index", 0)))
	table_sprite = table
	table.position = GameConfig.table_texture_center()
	table.scale = GameConfig.table_texture_render_scale()
	table.z_index = -10
	add_child(table)
	gem_sprite_layer = GemSpriteLayerType.new()
	gem_sprite_layer.z_index = 10
	add_child(gem_sprite_layer)
	gameplay_ui = GameplayHudScene.instantiate() as GameplayHudLayer
	add_child(gameplay_ui)
	gameplay_ui.settings_requested.connect(_on_settings_requested)
	gameplay_ui.resume_requested.connect(_on_resume_requested)
	gameplay_ui.restart_requested.connect(_on_restart_requested)
	gameplay_ui.home_requested.connect(_show_home)
	gameplay_ui.music_toggled.connect(_on_music_toggled)
	gameplay_ui.sound_toggled.connect(_on_sound_toggled)
	gameplay_ui.vibration_toggled.connect(_on_vibration_toggled)
	gameplay_ui.privacy_options_requested.connect(_on_privacy_options_requested)
	gameplay_ui.ui_tap_requested.connect(_on_ui_tap_requested)
	effects_layer = GameplayEffectsLayerType.new()
	effects_layer.z_index = 0
	gameplay_ui.attach_reward_foreground(effects_layer)
	effects_layer.coin_flight_started.connect(_on_coin_flight_started)
	effects_layer.coin_arrived.connect(_on_coin_arrived)
	result_overlay = ResultOverlayScene.instantiate() as ResultOverlayLayer
	add_child(result_overlay)
	result_overlay.retry_requested.connect(_on_restart_requested)
	result_overlay.collect_requested.connect(_on_collect_requested)
	result_overlay.double_coins_requested.connect(_on_double_coins_requested)
	result_overlay.home_requested.connect(_on_result_home_requested)
	result_overlay.reward_animation_finished.connect(_on_reward_animation_finished)
	result_overlay.ui_tap_requested.connect(_on_ui_tap_requested)
	home_overlay = HomeOverlayType.new()
	add_child(home_overlay)
	home_overlay.play_requested.connect(_on_home_play_requested)
	home_overlay.level_intro_requested.connect(_on_home_level_intro_requested)
	home_overlay.music_toggled.connect(_on_music_toggled)
	home_overlay.sound_toggled.connect(_on_sound_toggled)
	home_overlay.vibration_toggled.connect(_on_vibration_toggled)
	home_overlay.privacy_policy_requested.connect(_on_privacy_policy_requested)
	home_overlay.privacy_options_requested.connect(_on_privacy_options_requested)
	home_overlay.ui_tap_requested.connect(_on_ui_tap_requested)

func _refresh_background_fill() -> void:
	if background_sprite == null or background_sprite.texture == null:
		return
	# `expand` exposes additional portrait canvas height. Cover it with the
	# supplied background while preserving image proportions. The shared table
	# geometry below updates artwork and simulation landmarks together.
	var viewport_size := get_viewport_rect().size if is_inside_tree() else GameConfig.VIEWPORT_SIZE
	GameConfig.configure_viewport(viewport_size)
	var new_offset := Vector2(
		GameConfig.viewport_center_offset_x,
		GameConfig.table_texture_center().y - GameConfig.TABLE_TEXTURE_CENTER.y
	)
	var offset_delta := new_offset - Vector2(applied_table_offset_x, applied_table_offset_y)
	if not offset_delta.is_zero_approx():
		for piece in pieces:
			piece.position += offset_delta
		for presentation in merge_presentations:
			presentation.midpoint += offset_delta
			presentation.first_position += offset_delta
			presentation.second_position += offset_delta
		if collection_in_progress:
			target_collection.start += offset_delta
		for marker in debug_contact_points:
			marker.position += offset_delta
		if effects_layer != null:
			effects_layer.shift_world(offset_delta)
		applied_table_offset_x = new_offset.x
		applied_table_offset_y = new_offset.y
	if table_sprite != null:
		table_sprite.position = GameConfig.table_texture_center()
		table_sprite.scale = GameConfig.table_texture_render_scale()
	var source_size := background_sprite.texture.get_size()
	var cover_scale := maxf(viewport_size.x / source_size.x, viewport_size.y / source_size.y)
	background_sprite.position = viewport_size * 0.5
	background_sprite.scale = Vector2.ONE * cover_scale

func _apply_confirmed_merge_events(events: Array[Dictionary]) -> void:
	var resolution_multiplier := 1
	for merge_event in events:
		var result_id := int(merge_event.get("result_id", -1))
		if result_id >= 0 and processed_merge_result_ids.has(result_id):
			continue
		if result_id >= 0:
			processed_merge_result_ids[result_id] = true
		var result_level: int = int(merge_event.level)
		var completes_active_target := result_level == active_target_tier()
		# Cache all presentation resources at confirmation time. The draw path
		# never loads textures or performs catalog analysis/lookups per frame.
		merge_event.source_texture = AssetCatalogType.gem_texture(maxi(1, result_level - 1))
		merge_event.result_texture = AssetCatalogType.gem_texture(result_level)
		chain_multiplier = resolution_multiplier
		# The reference awards and animates coins only when the current target is
		# fulfilled. Ordinary merges keep their impact/gem feedback but do not
		# change the currency counter or create coin records.
		var awarded_coins := GameConfig.target_coin_reward_for_result_level(result_level) * chain_multiplier if completes_active_target else 0
		if awarded_coins > 0:
			if gameplay_ui != null:
				gameplay_ui.begin_coin_reward(awarded_coins)
			coins += awarded_coins
		# Chain resolution remains immediate and deterministic; this only staggers its visuals.
		merge_event.elapsed = -float(merge_event.get("depth", 0)) * GameConfig.CHAIN_PRESENTATION_STAGGER
		merge_event.first_frame_visible = false
		merge_presentations.append(merge_event)
		_trace_presentation_event("merge_confirmed", result_id)
		_trace_presentation_event("result_created", result_id)
		if gem_sprite_layer != null and result_id >= 0:
			var initial_transform := _merge_result_visual_transform(0.0, result_id)
			gem_sprite_layer.set_presentation_transform(result_id, initial_transform.scale, initial_transform.rotation, initial_transform.offset, true)
		if effects_layer != null:
			effects_layer.begin_merge_feedback(merge_event)
			if awarded_coins > 0:
				var coin_destination := gameplay_ui.coin_collection_destination() if gameplay_ui != null else GameConfig.COIN_HUD_FALLBACK_DESTINATION
				effects_layer.begin_target_coin_reward(merge_event, awarded_coins, coin_destination)
		audio_feedback.emit_event("merge_%d" % result_level if completes_active_target else "normal_merge")
		if awarded_coins > 0:
			audio_feedback.emit_event("coin_reward")
		if int(merge_event.get("depth", 0)) > 0:
			audio_feedback.emit_event("chain")
			haptics_feedback.emit_event("chain")
		else:
			haptics_feedback.emit_event("major_merge" if result_level >= GameConfig.MAJOR_REWARD_TIER else "merge")
		if completes_active_target:
			if result_id >= 0 and not counted_target_result_ids.has(result_id):
				pending_target_presentations[result_id] = merge_event
		resolution_multiplier += 1

func _configure_level_1() -> void:
	_configure_generated_level(1, LevelConfigType.seed_for_level(1))

func _configure_generated_level(requested_level: int, requested_seed: int) -> void:
	level_number = maxi(1, requested_level)
	level_seed = requested_seed
	level_config = LevelConfigType.generated(level_number, level_seed)
	AssetCatalogType.set_active_level_mapping(level_config.get("gem_identity_by_tier", {}))
	merge_service.max_result_level = int(level_config.active_tier_max)
	next_queue_index = 0
	next_level = LevelConfigType.initial_launcher_level(level_config)
	if background_sprite != null:
		background_sprite.texture = AssetCatalogType.background_texture(int(level_config.get("background_index", 0)))
	if table_sprite != null:
		table_sprite.texture = AssetCatalogType.table_texture(int(level_config.get("table_index", 0)))
	_refresh_background_fill()

func target_sequence() -> Array:
	return level_config.get("target_sequence", []) as Array

func active_target() -> Dictionary:
	var sequence := target_sequence()
	if target_index < 0 or target_index >= sequence.size():
		return {}
	return sequence[target_index] as Dictionary

func active_target_tier() -> int:
	return int(active_target().get("tier", 1))

func active_target_quantity() -> int:
	return int(active_target().get("quantity", 1))

func _update_danger_timers(delta: float) -> void:
	var live_ids: Dictionary = {}
	for piece in pieces:
		live_ids[piece.id] = true
		if piece.id == active_piece_id or piece.is_active_launcher or piece.consumed or not piece.is_settled():
			danger_timers.erase(piece.id)
			continue
		if piece.position.y + piece.radius > GameConfig.danger_line_y():
			danger_timers[piece.id] = float(danger_timers.get(piece.id, 0.0)) + delta
			if float(danger_timers[piece.id]) >= GameConfig.DANGER_GRACE_DURATION and not failed:
				_trigger_failure()
				return
		else:
			danger_timers.erase(piece.id)
	for id in danger_timers.keys():
		if not live_ids.has(id):
			danger_timers.erase(id)

func _trigger_failure() -> void:
	if failed:
		return
	failed = true
	active_piece_id = -1
	launcher_state = LauncherState.RESOLVING
	dragging = false
	pending_target_presentations.clear()
	merge_presentations.clear()
	piece_visual_feedbacks.clear()
	collection_in_progress = false
	_cancel_target_collection()
	if gem_sprite_layer != null:
		gem_sprite_layer.clear_presentation_scales()
	if effects_layer != null:
		effects_layer.clear()
	haptics_feedback.emit_event("fail")
	result_overlay.present(false, score, level_number, active_target_tier())

func _update_merge_presentations(delta: float) -> void:
	var completed: Array[Dictionary] = []
	var remaining: Array[Dictionary] = []
	for presentation in merge_presentations:
		presentation.elapsed += delta
		var result_id := int(presentation.get("result_id", -1))
		if float(presentation.elapsed) >= 0.0 and result_id >= 0 and gem_sprite_layer != null:
			var result_transform := _merge_result_visual_transform(float(presentation.elapsed), result_id)
			gem_sprite_layer.set_presentation_transform(result_id, result_transform.scale, result_transform.rotation, result_transform.offset, true)
		var duration_complete := float(presentation.elapsed) >= GameConfig.MERGE_PRESENTATION_DURATION
		var waits_for_visible_frame := result_id >= 0 and not bool(presentation.get("first_frame_visible", false))
		if duration_complete and not waits_for_visible_frame:
			completed.append(presentation)
		else:
			remaining.append(presentation)
	merge_presentations = remaining
	for presentation in completed:
		var result_id := int(presentation.get("result_id", -1))
		if gem_sprite_layer != null and result_id >= 0:
			gem_sprite_layer.clear_presentation_scale(result_id)
		_trace_presentation_event("merge_presentation_completed", result_id)
		if pending_target_presentations.has(result_id):
			pending_target_presentations.erase(result_id)
			if not counted_target_result_ids.has(result_id):
				counted_target_result_ids[result_id] = true
				_trace_presentation_event("target_completed", result_id)
				_begin_target_collection(result_id, presentation)

func _begin_target_collection(result_id: int, presentation: Dictionary = {}) -> void:
	if collection_in_progress or result_id < 0:
		return
	var result_piece: GemPiece = null
	for piece in pieces:
		if piece.id == result_id and not piece.consumed:
			result_piece = piece
			break
	var level := result_piece.level if result_piece != null else int(presentation.get("level", active_target_tier()))
	var start := result_piece.position if result_piece != null else Vector2(presentation.get("midpoint", Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 180.0)))
	# The actual confirmed merge result has already finished its presentation.
	# Remove it from the live simulation *before* its separate visual travels to
	# the HUD. Keeping a consumed RefCounted item in `pieces` used to leave a
	# stale body available to future contact/occupancy paths.
	if result_piece != null:
		result_piece.consumed = true
		pieces.erase(result_piece)
	danger_timers.erase(result_id)
	merge_service.clear()
	_trace_presentation_event("physics_body_removed", result_id)
	collection_in_progress = true
	# A replacement launcher may already be waiting at the bottom. Preserve it
	# while collection temporarily blocks input; clearing its marker here was a
	# second way to make the game appear to run out of shots.
	dragging = false
	var sprite := Sprite2D.new()
	var entry := AssetCatalogType.gem_entry(level)
	sprite.texture = entry.texture
	sprite.position = start
	var diameter := GameConfig.gem_collision_radius(level) * GameConfig.gem_perspective_scale_at(start.y) * 2.0 * float(GameConfig.GEM_VISUAL_BODY_SCALE.get(level, 1.0))
	# Start from the exact live-gem axis mapping so collection never shrinks or
	# changes the result silhouette. Reward emphasis then multiplies both axes
	# uniformly and remains presentation-only.
	var texture_longest_side := maxf(sprite.texture.get_size().x, sprite.texture.get_size().y)
	var body_scale := Vector2.ONE * (diameter / texture_longest_side)
	sprite.scale = body_scale
	# Godot canvas z is bounded; this stays above the live gem layer (10)
	# without exceeding the engine's maximum canvas z range.
	sprite.z_index = 2
	(effects_layer if effects_layer != null else gem_sprite_layer).add_child(sprite)
	target_collection = {"result_id": result_id, "level": level, "sprite": sprite, "start": start, "elapsed": 0.0, "base_scale": body_scale, "opacity": 1.0}
	_trace_presentation_event("collection_animation_started", result_id)

func _update_target_collection(delta: float) -> void:
	if not collection_in_progress:
		return
	var sprite: Sprite2D = target_collection.get("sprite")
	if sprite == null:
		_finish_target_collection()
		return
	var elapsed := float(target_collection.get("elapsed", 0.0)) + delta
	target_collection.elapsed = elapsed
	var t := clampf(elapsed / GameConfig.TARGET_COLLECTION_DURATION, 0.0, 1.0)
	var eased := smoothstep(0.0, 1.0, t)
	var start: Vector2 = target_collection.start
	var destination := gameplay_ui.target_collection_destination() if gameplay_ui != null else GameConfig.TARGET_COLLECTION_DESTINATION
	target_collection.destination = destination
	var control := Vector2(lerpf(start.x, destination.x, 0.48), minf(start.y, destination.y) - 82.0)
	var inverse := 1.0 - eased
	sprite.position = start * inverse * inverse + control * 2.0 * inverse * eased + destination * eased * eased
	var pop := 1.0
	if t <= 0.32:
		pop = 1.0 + sin(t / 0.32 * PI) * (GameConfig.TARGET_COLLECTION_POP_SCALE - 1.0)
	else:
		pop = lerpf(1.0, 0.88, smoothstep(0.32, 1.0, t))
	var base_scale: Vector2 = target_collection.get("base_scale", Vector2.ONE)
	sprite.scale = base_scale * pop
	var opacity := 1.0
	if t > GameConfig.TARGET_COLLECTION_FADE_START:
		opacity = lerpf(1.0, 0.15, smoothstep(GameConfig.TARGET_COLLECTION_FADE_START, 1.0, t))
	target_collection.opacity = opacity
	sprite.modulate = Color(1.0, 1.0, 1.0, opacity)
	if t >= 1.0:
		_finish_target_collection()

func _finish_target_collection() -> void:
	var result_id := int(target_collection.get("result_id", -1))
	var sprite: Sprite2D = target_collection.get("sprite")
	if sprite != null:
		sprite.queue_free()
	target_collection.clear()
	collection_in_progress = false
	if gameplay_ui != null:
		gameplay_ui.pulse_target()
	audio_feedback.emit_event("target_collect")
	haptics_feedback.emit_event("target_collect")
	_trace_presentation_event("collection_animation_completed", result_id)
	target_progress += 1
	if target_progress < active_target_quantity():
		return
	target_index += 1
	target_progress = 0
	if target_index >= target_sequence().size():
		final_target_result_id = result_id
		_trace_presentation_event("final_target_confirmed", result_id)
		_qualify_win_if_target_complete()

func _cancel_target_collection() -> void:
	var sprite: Sprite2D = target_collection.get("sprite")
	if sprite != null:
		sprite.queue_free()
	target_collection.clear()
	collection_in_progress = false

func _qualify_win_if_target_complete() -> void:
	if target_index < target_sequence().size() or win_qualified:
		return
	won = true
	win_qualified = true
	win_presented = false
	win_hold_elapsed = 0.0
	var active := get_active_piece()
	if active != null:
		active.is_active_launcher = false
	active_piece_id = -1
	launcher_state = LauncherState.RESOLVING

func _update_win_presentation(delta: float) -> void:
	# The final target must finish merge presentation and collection before the
	# dedicated UI layer can present victory.
	if win_presented or not merge_presentations.is_empty() or (effects_layer != null and effects_layer.has_active_coin_flights()):
		return
	win_hold_elapsed += delta
	if win_hold_elapsed >= GameConfig.WIN_PRESENTATION_HOLD:
		var completed_tier := int((target_sequence().back() as Dictionary).get("tier", 8))
		level_reward_for_completion = maxi(0, coins - level_start_coins)
		var rewarded_ready := ad_manager != null and bool(ad_manager.call("is_rewarded_ready"))
		if result_overlay.present(true, score, level_number, completed_tier, level_reward_for_completion, rewarded_ready):
			win_presented = true
			app_flow_state = AppFlowState.LEVEL_COMPLETE
			if gameplay_ui != null:
				gameplay_ui.prepare_completion_reward_display(level_start_coins, coins)
			_trace_presentation_event("win_overlay_started", final_target_result_id)
			audio_feedback.emit_event("win")
			haptics_feedback.emit_event("win")

func _sync_gems_and_mark_visibility() -> void:
	if gem_sprite_layer == null:
		return
	gem_sprite_layer.sync_gems(pieces)
	for presentation in merge_presentations:
		if bool(presentation.get("first_frame_visible", false)) or float(presentation.get("elapsed", -1.0)) < 0.0:
			continue
		var result_id := int(presentation.get("result_id", -1))
		if result_id < 0:
			continue
		var has_visual := _has_live_piece(result_id) or (effects_layer != null and effects_layer.has_merge_result(result_id))
		if has_visual:
			presentation.first_frame_visible = true
			presentation.visible_frame = process_frame_index
			_trace_presentation_event("result_first_frame_visible", result_id)

func _refresh_hud() -> void:
	if gameplay_ui != null:
		gameplay_ui.update_snapshot(hud_snapshot())

func _merge_result_visual_scale(elapsed: float) -> float:
	return float(_merge_result_visual_transform(elapsed, 0).uniform_scale)

func _merge_result_visual_transform(elapsed: float, result_id: int) -> Dictionary:
	var uniform_scale := 1.0
	if elapsed <= 0.0:
		uniform_scale = GameConfig.MERGE_RESULT_START_SCALE
	elif elapsed <= GameConfig.MERGE_RESULT_POP_DURATION:
		var pop_t := clampf(elapsed / GameConfig.MERGE_RESULT_POP_DURATION, 0.0, 1.0)
		var pop_eased := 1.0 - pow(1.0 - pop_t, 3.0)
		uniform_scale = lerpf(GameConfig.MERGE_RESULT_START_SCALE, GameConfig.MERGE_RESULT_POP_SCALE, pop_eased)
	else:
		var settle_duration := maxf(0.001, GameConfig.MERGE_PRESENTATION_DURATION - GameConfig.MERGE_RESULT_POP_DURATION)
		var settle_t := clampf((elapsed - GameConfig.MERGE_RESULT_POP_DURATION) / settle_duration, 0.0, 1.0)
		# Restore the prior damped, uniform settle without changing the rigid
		# silhouette or feeding presentation scale into the simulation.
		uniform_scale = 1.0 + (GameConfig.MERGE_RESULT_POP_SCALE - 1.0) * exp(-4.2 * settle_t) * cos(settle_t * PI * 1.65)
	# The reference never changes a piece's silhouette. Merge emphasis is one
	# centered uniform pop only: no squash, stretch, tilt, or presentation kick.
	return {"scale": Vector2.ONE * uniform_scale, "uniform_scale": uniform_scale, "offset": Vector2.ZERO, "rotation": 0.0}

func _update_piece_visual_feedbacks(delta: float) -> void:
	if gem_sprite_layer == null or piece_visual_feedbacks.is_empty():
		return
	for piece_id in piece_visual_feedbacks.keys():
		var feedback: Dictionary = piece_visual_feedbacks[piece_id]
		feedback.elapsed = float(feedback.get("elapsed", 0.0)) + delta
		var duration := maxf(0.001, float(feedback.get("duration", 0.1)))
		var t := clampf(float(feedback.elapsed) / duration, 0.0, 1.0)
		var scale := 1.0
		if String(feedback.get("kind", "")) == "spawn":
			if t <= 0.68:
				var rise := 1.0 - pow(1.0 - t / 0.68, 3.0)
				scale = lerpf(0.84, 1.06, rise)
			else:
				scale = lerpf(1.06, 1.0, smoothstep(0.68, 1.0, t))
		else:
			scale = lerpf(0.92, 1.0, 1.0 - pow(1.0 - t, 2.0))
		if t >= 1.0:
			gem_sprite_layer.clear_presentation_scale(int(piece_id))
			piece_visual_feedbacks.erase(piece_id)
		else:
			gem_sprite_layer.set_presentation_scale(int(piece_id), scale)

func _has_live_piece(piece_id: int) -> bool:
	for piece in pieces:
		if piece.id == piece_id and not piece.consumed:
			return true
	return false

func _trace_presentation_event(event_name: String, result_id: int) -> void:
	if result_id < 0:
		return
	presentation_event_trace.append({"name": event_name, "result_id": result_id, "frame": process_frame_index})
	while presentation_event_trace.size() > GameConfig.PRESENTATION_EVENT_TRACE_LIMIT:
		presentation_event_trace.pop_front()

func presentation_events_for_result(result_id: int) -> Array[String]:
	var names: Array[String] = []
	for event in presentation_event_trace:
		if int(event.get("result_id", -1)) == result_id:
			names.append(String(event.get("name", "")))
	return names

func _on_settings_requested() -> void:
	if gameplay_ui == null or failed or win_presented or gameplay_ui.is_pause_visible():
		return
	dragging = false
	gameplay_ui.show_pause()
	if is_inside_tree():
		get_tree().paused = true

func _on_resume_requested() -> void:
	if gameplay_ui == null:
		return
	gameplay_ui.hide_pause(true)
	if is_inside_tree():
		get_tree().paused = false

func _on_music_toggled(value: bool) -> void:
	if audio_feedback != null:
		audio_feedback.music_enabled = value
	_save_settings()
	_refresh_hud()

func _on_sound_toggled(value: bool) -> void:
	if audio_feedback != null:
		audio_feedback.sfx_enabled = value
	_save_settings()
	_refresh_hud()

func _on_vibration_toggled(value: bool) -> void:
	if haptics_feedback != null:
		haptics_feedback.enabled = value
	_save_settings()
	_refresh_hud()

func _on_ui_tap_requested() -> void:
	if audio_feedback != null:
		audio_feedback.emit_event("button")

func _on_privacy_policy_requested() -> void:
	if ad_manager != null:
		ad_manager.call("open_privacy_policy")
	else:
		OS.shell_open(AdConfigType.PRIVACY_POLICY_URL)

func _on_privacy_options_requested() -> void:
	if ad_manager != null:
		ad_manager.call("show_privacy_options")

func _on_privacy_options_availability_changed(available: bool) -> void:
	if home_overlay != null:
		home_overlay.set_privacy_options_available(available)
	if gameplay_ui != null:
		gameplay_ui.set_privacy_options_available(available)

func _save_settings() -> void:
	GameSettingsServiceType.save_settings(
		audio_feedback.music_enabled if audio_feedback != null else true,
		audio_feedback.sfx_enabled if audio_feedback != null else true,
		haptics_feedback.enabled if haptics_feedback != null else true
	)

func _on_restart_requested() -> void:
	if gameplay_ui != null:
		gameplay_ui.hide_pause(false)
	if is_inside_tree():
		get_tree().paused = false
	restart()
	app_flow_state = AppFlowState.PLAYING

func _on_collect_requested() -> void:
	if not won or completion_action_pending or completion_transition_consumed or completion_reward_resolved:
		return
	app_flow_state = AppFlowState.REWARD_PROCESSING
	completion_reward_resolved = true
	completion_destination = "play"
	ProgressionSaveServiceType.save_progress(level_number, level_seed, coins)
	if result_overlay != null:
		result_overlay.set_actions_pending(true)
		result_overlay.resolve_reward(coins, false)
	if gameplay_ui != null:
		gameplay_ui.animate_completion_reward(coins)
	_refresh_hud()


func _begin_completion_transition(destination: String) -> void:
	if not won or completion_action_pending or completion_transition_consumed:
		return
	completion_action_pending = true
	completion_destination = destination
	if result_overlay != null:
		result_overlay.set_actions_pending(true)
	if AdConfigType.should_show_interstitial_after_level(level_number) and ad_manager != null:
		app_flow_state = AppFlowState.AD_SHOWING
		if result_overlay != null:
			result_overlay.dismiss()
		ad_manager.call("show_interstitial", Callable(self, "_finish_completion_transition"))
	else:
		if result_overlay != null:
			result_overlay.dismiss()
		call_deferred("_finish_completion_transition")


func _finish_completion_transition() -> void:
	if completion_transition_consumed or not completion_action_pending:
		return
	completion_transition_consumed = true
	completion_action_pending = false
	var destination := completion_destination
	level_number += 1
	level_seed = LevelConfigType.seed_for_level(level_number)
	level_start_coins = coins
	ProgressionSaveServiceType.save_progress(level_number, level_seed, coins)
	restart()
	if destination == "home":
		_show_home()
	else:
		_show_level_start()


func _on_double_coins_requested() -> void:
	if not won or completion_action_pending or completion_transition_consumed or completion_reward_resolved or rewarded_bonus_granted:
		return
	completion_action_pending = true
	app_flow_state = AppFlowState.AD_SHOWING
	if result_overlay != null:
		result_overlay.set_actions_pending(true)
	if ad_manager == null:
		_on_rewarded_ad_finished(false)
		return
	ad_manager.call(
		"show_rewarded",
		Callable(self, "_on_rewarded_bonus_earned"),
		Callable(self, "_on_rewarded_ad_finished")
	)


func _on_rewarded_bonus_earned(_rewarded_item = null) -> void:
	if not won or rewarded_bonus_granted or completion_transition_consumed:
		return
	rewarded_bonus_granted = true
	coins += level_reward_for_completion
	completion_reward_resolved = true
	ProgressionSaveServiceType.save_progress(level_number, level_seed, coins)


func _on_rewarded_ad_finished(earned: bool) -> void:
	if completion_transition_consumed or not completion_action_pending:
		return
	if earned and rewarded_bonus_granted:
		completion_action_pending = false
		app_flow_state = AppFlowState.REWARD_PROCESSING
		if result_overlay != null:
			# Start the x2 sequence only after the fullscreen ad has closed, so
			# the player sees it on the same surviving Level Complete popup.
			result_overlay.resolve_reward(coins, true)
		if gameplay_ui != null:
			gameplay_ui.animate_completion_reward(coins)
		_refresh_hud()
		return
	completion_action_pending = false
	app_flow_state = AppFlowState.LEVEL_COMPLETE
	if result_overlay != null:
		result_overlay.set_actions_pending(false)
		result_overlay.set_rewarded_available(ad_manager != null and bool(ad_manager.call("is_rewarded_ready")))


func _on_rewarded_availability_changed(ready: bool) -> void:
	if result_overlay != null and result_overlay.visible_result and won and not completion_action_pending and not completion_reward_resolved:
		result_overlay.set_rewarded_available(ready)

func _on_result_home_requested() -> void:
	# Leaving a completed result through Home still banks the win and prepares the
	# next generated level; Continue can never return to a consumed terminal run.
	if won:
		if not completion_reward_resolved:
			completion_destination = "home"
			_on_collect_requested()
			completion_destination = "home"
		elif app_flow_state != AppFlowState.REWARD_PROCESSING:
			_begin_completion_transition("home")
	else:
		_on_restart_requested()
		_show_home()

func _show_home() -> void:
	if home_overlay == null:
		return
	if gameplay_ui != null:
		gameplay_ui.hide_pause(false)
	if result_overlay != null:
		result_overlay.dismiss()
	app_flow_state = AppFlowState.HOME
	home_overlay.present(level_number, coins, hud_snapshot())
	if is_inside_tree():
		get_tree().paused = true


func _show_level_start() -> void:
	if home_overlay == null:
		return
	if gameplay_ui != null:
		gameplay_ui.hide_pause(false)
	if result_overlay != null:
		result_overlay.dismiss()
	app_flow_state = AppFlowState.LEVEL_READY
	if gameplay_ui != null:
		gameplay_ui.show()
	home_overlay.present_level_intro(level_number, coins, hud_snapshot())
	if is_inside_tree():
		get_tree().paused = true

func _on_home_play_requested() -> void:
	if home_overlay != null:
		home_overlay.dismiss()
	if gameplay_ui != null:
		gameplay_ui.show()
	app_flow_state = AppFlowState.PLAYING
	if is_inside_tree():
		get_tree().paused = false


func _on_home_level_intro_requested() -> void:
	if app_flow_state != AppFlowState.HOME:
		return
	_show_level_start()


func _on_reward_animation_finished() -> void:
	if not won or app_flow_state != AppFlowState.REWARD_PROCESSING or completion_transition_consumed:
		return
	_begin_completion_transition(completion_destination)

func _on_coin_flight_started(_result_id: int) -> void:
	pass

func _on_coin_arrived(_result_id: int, value: int, final_coin: bool) -> void:
	if gameplay_ui != null:
		gameplay_ui.collect_coin_chunk(value, final_coin)
	if final_coin and haptics_feedback != null:
		haptics_feedback.emit_event("coin_collect")

func _route_collision_feedback(impacts: Array[Dictionary], merge_events: Array[Dictionary] = []) -> void:
	var merged_pairs: Dictionary = {}
	for merge_event in merge_events:
		var source_ids: Array = merge_event.get("source_ids", [])
		if source_ids.size() == 2:
			var first_id := int(source_ids[0])
			var second_id := int(source_ids[1])
			merged_pairs["%d:%d" % [mini(first_id, second_id), maxi(first_id, second_id)]] = true
	for impact in impacts:
		if debug_calibration_enabled and impact.has("position"):
			debug_contact_points.append({"position": impact.position, "age": 0.0})
		var kind := String(impact.get("kind", "gem"))
		var strength := float(impact.get("strength", 0.0))
		if kind == "wall":
			if strength >= GameConfig.WALL_CONTACT_SOUND_THRESHOLD:
				audio_feedback.emit_event("wall_contact", clampf(strength / GameConfig.LAUNCH_SPEED, 0.30, 0.75))
		elif strength >= GameConfig.GEM_CONTACT_SOUND_THRESHOLD:
			var first_id := int(impact.get("first_id", -1))
			var second_id := int(impact.get("second_id", -1))
			var pair_key := "%d:%d" % [mini(first_id, second_id), maxi(first_id, second_id)]
			if merged_pairs.has(pair_key):
				continue
			audio_feedback.emit_event("gem_contact", clampf(strength / GameConfig.LAUNCH_SPEED, 0.35, 1.0))

func _draw() -> void:
	# Presentation-only guide and warning feedback share authoritative geometry
	# but never feed input, overflow, collision, launch, or simulation decisions.
	_draw_aim_guide()
	var danger_y := GameConfig.danger_line_y()
	var danger_start := Vector2(GameConfig.table_left_at(danger_y) + 8.0, danger_y)
	var danger_end := Vector2(GameConfig.table_right_at(danger_y) - 8.0, danger_y)
	var warning_strength := _danger_warning_strength()
	var pulse := 0.0
	if warning_strength > 0.0:
		pulse = (sin(float(Time.get_ticks_msec()) * 0.001 * TAU * GameConfig.DANGER_WARNING_PULSE_HZ) + 1.0) * 0.5
	var warning_alpha := lerpf(0.42, 0.78, warning_strength * (0.55 + pulse * 0.45))
	var danger_color := GameConfig.DANGER_LINE_COLOR
	danger_color.a = warning_alpha
	draw_dashed_line(danger_start, danger_end, Color(0.26, 0.12, 0.07, lerpf(0.22, 0.42, warning_strength)), lerpf(6.0, 8.0, warning_strength), 11.0)
	draw_dashed_line(danger_start, danger_end, danger_color, lerpf(3.0, 4.4, warning_strength * pulse), 11.0)
	# Draw the non-physical source ghosts first. The new simulated gem is then
	# rendered over them, avoiding a one-frame visual pop at the merge midpoint.
	for presentation in merge_presentations:
		_draw_merge_presentation(presentation)
	if debug_calibration_enabled:
		_draw_calibration_debug(ThemeDB.fallback_font)

func _draw_aim_guide() -> void:
	if launcher_state != LauncherState.READY_TO_AIM or collection_in_progress or win_qualified or failed:
		return
	var active := get_active_piece()
	if active == null or not active.is_settled():
		return
	var lane_top := GameConfig.vertical_lane_top_y(active.position.x, 5.0)
	var start := Vector2(active.position.x, lane_top + 10.0)
	var finish := Vector2(active.position.x, active.position.y - active.radius - 10.0)
	if start.y >= finish.y - 8.0:
		return
	var shadow := Color(0.04, 0.20, 0.23, GameConfig.AIM_GUIDE_ALPHA * 0.48)
	var guide := Color(1.0, 0.94, 0.62, GameConfig.AIM_GUIDE_ALPHA)
	draw_dashed_line(start, finish, shadow, GameConfig.AIM_GUIDE_WIDTH + 2.0, 13.0)
	draw_dashed_line(start, finish, guide, GameConfig.AIM_GUIDE_WIDTH, 13.0)
	draw_circle(start, 5.0, Color(1.0, 0.78, 0.30, GameConfig.AIM_GUIDE_ALPHA * 0.92))

func _danger_warning_strength() -> float:
	var line_y := GameConfig.danger_line_y()
	var nearest := GameConfig.DANGER_WARNING_NEAR_DISTANCE
	var found_near := false
	for piece in pieces:
		if piece.consumed or piece.id == active_piece_id or piece.is_active_launcher:
			continue
		var distance := line_y - (piece.position.y + piece.radius)
		if distance <= GameConfig.DANGER_WARNING_NEAR_DISTANCE:
			nearest = minf(nearest, maxf(0.0, distance))
			found_near = true
	if not found_near:
		return 0.0
	return clampf(1.0 - nearest / GameConfig.DANGER_WARNING_NEAR_DISTANCE, 0.20, 1.0)

func _draw_calibration_debug(font: Font) -> void:
	var board_top := GameConfig.board_top()
	var board_bottom := GameConfig.board_bottom()
	var left_top := Vector2(GameConfig.table_left_at(board_top), board_top)
	var right_top := Vector2(GameConfig.table_right_at(board_top), board_top)
	var left_bottom := Vector2(GameConfig.table_left_at(board_bottom), board_bottom)
	var right_bottom := Vector2(GameConfig.table_right_at(board_bottom), board_bottom)
	# These table-interpolated endpoints are the exact same geometry the solver
	# and launcher clamp read. F8 remains desktop/editor-only and off by default.
	draw_line(left_top, left_bottom, Color("ff3fc7"), 4.0)
	draw_line(right_top, right_bottom, Color("42dcff"), 4.0)
	draw_line(left_top, right_top, Color("ffdd55"), 1.5)
	draw_line(left_bottom, right_bottom, Color("ffdd55"), 1.5)
	for anchor in [left_top, left_bottom, right_top, right_bottom]:
		draw_circle(anchor, 6.0, Color("ffffff"))
		draw_circle(anchor, 3.0, Color("171725"))
	for piece in pieces:
		if piece.consumed:
			continue
		draw_arc(piece.position, piece.radius, 0.0, TAU, 32, Color("ffdd55"), 1.5)
		draw_line(piece.position - Vector2(5.0, 0.0), piece.position + Vector2(5.0, 0.0), Color("ffdd55"), 1.0)
		draw_line(piece.position - Vector2(0.0, 5.0), piece.position + Vector2(0.0, 5.0), Color("ffdd55"), 1.0)
		var shadow_rect := gem_sprite_layer.shadow_bounds(piece.id) if gem_sprite_layer != null else Rect2()
		if shadow_rect.size != Vector2.ZERO:
			draw_rect(shadow_rect, Color("8ad7ff", 0.65), false, 1.0)
	for marker in debug_contact_points:
		draw_circle(marker.position, 4.0, Color("ff5ccd"))
	draw_string(font, Vector2(24.0, 190.0), "RAIL DEBUG (F8): exact physical lines / anchors / colliders / contacts", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ffdd55"))

func _draw_crystal_atmosphere() -> void:
	# Lightweight procedural depth: only flat primitives, no shader/blur/particles.
	draw_rect(Rect2(Vector2.ZERO, GameConfig.VIEWPORT_SIZE), Color("09111f"), true)
	for index in range(7):
		var y := 110.0 + index * 175.0
		var shade := Color(0.05 + index * 0.006, 0.11 + index * 0.008, 0.19 + index * 0.012, 0.38)
		draw_circle(Vector2(90.0 + (index % 2) * 540.0, y), 170.0, shade)
	for ornament in [Vector2(38, 200), Vector2(682, 310), Vector2(34, 890), Vector2(680, 1110)]:
		var points := PackedVector2Array([ornament + Vector2(0, -18), ornament + Vector2(13, 0), ornament + Vector2(0, 18), ornament + Vector2(-13, 0)])
		draw_colored_polygon(points, Color("8bc7c2", 0.28))
		draw_polyline(points + PackedVector2Array([points[0]]), Color("e8ca7d", 0.42), 1.0)
	draw_rect(Rect2(0.0, 174.0, 720.0, 4.0), Color("d8b86a", 0.22), true)

func _draw_merge_presentation(presentation: Dictionary) -> void:
	if float(presentation.get("elapsed", -1.0)) < 0.0:
		return
	var t: float = clampf(presentation.elapsed / GameConfig.MERGE_PRESENTATION_DURATION, 0.0, 1.0)
	var pull_t: float = clampf(presentation.elapsed / GameConfig.MERGE_SOURCE_PULL_DURATION, 0.0, 1.0)
	var midpoint: Vector2 = presentation.midpoint
	var result_level := int(presentation.level)
	var source_level := maxi(1, result_level - 1)
	var source_texture := presentation.get("source_texture") as Texture2D
	if source_texture == null:
		return
	var source_scale := 1.0 - pull_t * 0.72
	var source_alpha := 1.0 - pull_t
	for source_position in [presentation.first_position, presentation.second_position]:
		var position: Vector2 = source_position.lerp(midpoint, pull_t * 0.72)
		var source_diameter := GameConfig.gem_collision_radius(source_level) * GameConfig.gem_perspective_scale_at(source_position.y) * 2.0
		var texture_scale := source_diameter / maxf(source_texture.get_size().x, source_texture.get_size().y) * source_scale
		var source_size := source_texture.get_size() * texture_scale
		draw_texture_rect(source_texture, Rect2(position - source_size * 0.5, source_size), false, Color(1.0, 1.0, 1.0, source_alpha))
	var glow := GameConfig.gem_color(result_level)
	glow.a = (1.0 - t) * 0.20
	draw_circle(midpoint, GameConfig.gem_collision_radius(result_level) * (0.85 + t * 0.35), glow)
	# A chain-intermediate result can be consumed in the same resolver call. It
	# still receives one visual frame through this presentation-only proxy.
	var result_id := int(presentation.get("result_id", -1))
	if result_id >= 0 and not _has_live_piece(result_id):
		var result_texture := presentation.get("result_texture") as Texture2D
		if result_texture == null:
			return
		var result_diameter := GameConfig.gem_collision_radius(result_level) * GameConfig.gem_perspective_scale_at(midpoint.y) * 2.0
		var result_transform := _merge_result_visual_transform(float(presentation.elapsed), result_id)
		var base_scale := result_diameter / maxf(result_texture.get_size().x, result_texture.get_size().y)
		var proxy_scale: Vector2 = result_transform.scale
		var result_position: Vector2 = midpoint + result_transform.offset
		draw_set_transform(result_position, float(result_transform.rotation), Vector2(base_scale * proxy_scale.x, base_scale * proxy_scale.y))
		draw_texture_rect(result_texture, Rect2(-result_texture.get_size() * 0.5, result_texture.get_size()), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
