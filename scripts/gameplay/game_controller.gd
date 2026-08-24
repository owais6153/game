extends Node2D

const AudioFeedbackServiceType = preload("res://scripts/services/audio_feedback_service.gd")
const HapticsServiceType = preload("res://scripts/services/haptics_service.gd")
const AssetCatalogType = preload("res://scripts/core/asset_catalog.gd")
const GemSpriteLayerType = preload("res://scripts/presentation/gem_sprite_layer.gd")
const ResultOverlayScene = preload("res://scenes/ui/ResultOverlay.tscn")
const LevelConfigType = preload("res://scripts/core/level_config.gd")
const GameplayHudScene = preload("res://scenes/ui/GameplayHud.tscn")
const GameplayEffectsLayerType = preload("res://scripts/presentation/gameplay_effects_layer.gd")
const ProgressionSaveServiceType = preload("res://scripts/services/progression_save_service.gd")
const GameSettingsServiceType = preload("res://scripts/services/game_settings_service.gd")
const HomeOverlayType = preload("res://scripts/ui/home_overlay_layer.gd")
const AdConfigType = preload("res://scripts/services/ad_config.gd")

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
## HUD-facing target state follows collection arrivals; gameplay target state
## above advances immediately at the confirmed merge event.
var presented_target_progress := 0
var presented_target_index := 0
var counted_target_result_ids: Dictionary = {}
## Exactly-once guard for production merge result IDs. It prevents duplicate
## score, target, sound, haptic, and reward presentation from a repeated event.
var processed_merge_result_ids: Dictionary = {}
## Confirmed results remain authoritative immediately; presentation work is queued and may overlap safely.
var pending_target_presentations: Dictionary = {}
var target_collection_queue: Array[Dictionary] = []
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
## Presentation-only hit-stop. It freezes the confirmed merge result for a few
## frames; every other body keeps stepping and no rule reads this state.
var merge_hitstops: Dictionary = {}
## Delayed real-piece rewards. They enter `pieces` 80 ms after the result reveal
## and are simulation-owned from that frame onward.
var pending_bonus_spawns: Array[Dictionary] = []
var bonus_spawn_history: Array[Dictionary] = []
var bonus_spawn_budget_remaining := GameConfig.BONUS_GEM_BUDGET_PER_SHOT
## Explicit celebration state for the final-target hero moment. While it is
## active, pointer input, shot spawning, and the Level Complete modal are locked
## so the authoritative reward can only resolve once.
var final_celebration_active := false
var final_celebration_elapsed := 0.0
var final_celebration_coins := 0
var final_celebration_coins_started := false
var final_celebration_hero_done := false
## Safety bound. If a queued earlier target delays the hero sequence, coins still
## start rather than leaving the celebration state — and Level Complete — stuck.
const FINAL_CELEBRATION_COIN_TIMEOUT := 2.0
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
var collision_visual_last_at: Dictionary = {}
var collision_visual_clock := 0.0
## Developer-only inspection aid. F8 toggles it in editor/desktop builds; it
## starts disabled and has no input or gameplay authority on Android.
var debug_calibration_enabled := false
var debug_contact_points: Array[Dictionary] = []
var _last_platform_back_msec := -1000
var _exit_request_pending := false
const PLATFORM_BACK_DEBOUNCE_MSEC := 350

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
	# Platform vibration is not part of the shipped feature set. Keep the
	# feedback service as a no-op event sink so confirmed gameplay routing stays
	# intact without exposing or persisting a control that has no user effect.
	haptics_feedback.enabled = false
	add_child(audio_feedback)
	_advance_launcher_lifecycle()
	_sync_gems_and_mark_visibility()
	_refresh_hud()
	queue_redraw()
	# Home is the authoritative entry state on every runtime target. Depending on
	# a platform feature flag allowed some Android/debug packaging combinations
	# to skip the complete Home flow and enter live gameplay immediately.
	_show_home()

func _process(delta: float) -> void:
	process_frame_index += 1
	collision_visual_clock += delta
	for marker in debug_contact_points:
		marker.age = float(marker.get("age", 0.0)) + delta
	debug_contact_points = debug_contact_points.filter(func(marker: Dictionary) -> bool: return float(marker.get("age", 0.0)) < 0.45)
	_sync_pending_target_coin_origins()
	if effects_layer != null:
		effects_layer.update_effects(delta)
	if gem_sprite_layer != null:
		gem_sprite_layer.update_reward_effects(delta)
	_update_piece_visual_feedbacks(delta)
	if failed:
		_sync_gems_and_mark_visibility()
		_refresh_hud()
		queue_redraw()
		return
	_update_pending_bonus_spawns(delta)
	_update_final_celebration(delta)
	if win_qualified:
		_update_merge_hitstops(delta)
		_update_merge_presentations(delta)
		_update_target_collection(delta)
		_sync_gems_and_mark_visibility()
		_update_win_presentation(delta)
		_refresh_hud()
		queue_redraw()
		return
	_update_merge_hitstops(delta)
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
			if not merge_service.has_pending_candidates():
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
	var visible_target := presented_target()
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
		"target_progress": presented_target_progress,
		"target_quantity": int(visible_target.get("quantity", 1)),
		"target_index": presented_target_index,
		"target_total": target_sequence().size(),
		"target_collecting": collection_in_progress,
		"target_completed": not target_sequence().is_empty() and presented_target_index >= target_sequence().size(),
		"highest_level": highest_level,
		"music_enabled": audio_feedback.music_enabled if audio_feedback != null else true,
		"sound_enabled": audio_feedback.sfx_enabled if audio_feedback != null else true,
	}


func presented_target() -> Dictionary:
	var sequence := target_sequence()
	if presented_target_index < 0 or presented_target_index >= sequence.size():
		return {}
	return sequence[presented_target_index] as Dictionary

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
		_dispatch_platform_back_request()
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
	_dispatch_platform_back_request()


func _dispatch_platform_back_request() -> String:
	var now := Time.get_ticks_msec()
	if now - _last_platform_back_msec < PLATFORM_BACK_DEBOUNCE_MSEC:
		return "duplicate"
	_last_platform_back_msec = now
	return _handle_back_request(true)


func _handle_back_request(_allow_application_exit: bool = true) -> String:
	# The app-flow owner decides Back. The previous gameplay-only callback could
	# open Pause over Home, unpause a hidden run, and leave mutually inconsistent
	# UI/process state behind.
	if home_overlay != null and home_overlay.handle_back_request():
		return "home_overlay"
	if result_overlay != null and result_overlay.visible_result:
		# Result actions own progression/reward resolution. Back is consumed without
		# dismissing the modal or skipping its required Collect/ad path.
		return "result_locked"
	match app_flow_state:
		AppFlowState.HOME:
			if home_overlay != null:
				home_overlay.show_exit_confirmation()
			return "exit_confirmation"
		AppFlowState.LEVEL_READY:
			_show_home()
			return "home"
		AppFlowState.PLAYING:
			if gameplay_ui != null and gameplay_ui.is_pause_visible():
				_on_resume_requested()
				return "resume"
			if not win_presented and not failed:
				_on_settings_requested()
				return "pause"
	return "ignored"

func _handle_pointer(pointer: Vector2, pressed: bool) -> void:
	# A qualified win or a running final celebration owns the screen. Input stays
	# locked so no shot can be aimed, launched, or dragged during the sequence.
	if win_presented or failed or win_qualified or final_celebration_active:
		dragging = false
		return
	if pressed:
		var active := get_active_piece()
		var grabbed_gem := active != null and pointer.distance_to(active.position) <= active.radius * GameConfig.DRAG_HIT_RADIUS_MULTIPLIER
		if launcher_state == LauncherState.READY_TO_AIM and active != null and active.is_settled() and (grabbed_gem or GameConfig.aim_guide_contains(pointer, active.position, active.radius)):
			dragging = true
			move_active_to(pointer.x)
	elif dragging:
		dragging = false
		launch_active_piece()
func move_active_to(x_position: float) -> void:
	var active := get_active_piece()
	if launcher_state == LauncherState.READY_TO_AIM and active != null and active.is_settled():
		active.position.x = GameConfig.launcher_drag_x(x_position, active.position.y, active.radius)

func launch_active_piece() -> void:
	var active := get_active_piece()
	if launcher_state == LauncherState.READY_TO_AIM and active != null and active.is_settled():
		bonus_spawn_budget_remaining = GameConfig.BONUS_GEM_BUDGET_PER_SHOT
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
	presented_target_progress = 0
	presented_target_index = 0
	counted_target_result_ids.clear()
	processed_merge_result_ids.clear()
	pending_target_presentations.clear()
	target_collection_queue.clear()
	presentation_event_trace.clear()
	process_frame_index = 0
	merge_hitstops.clear()
	pending_bonus_spawns.clear()
	bonus_spawn_history.clear()
	bonus_spawn_budget_remaining = GameConfig.BONUS_GEM_BUDGET_PER_SHOT
	_cancel_final_celebration()
	piece_visual_feedbacks.clear()
	collision_visual_last_at.clear()
	collision_visual_clock = 0.0
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
	gameplay_ui.home_requested.connect(_on_pause_home_requested)
	gameplay_ui.music_toggled.connect(_on_music_toggled)
	gameplay_ui.sound_toggled.connect(_on_sound_toggled)
	gameplay_ui.privacy_options_requested.connect(_on_privacy_options_requested)
	gameplay_ui.ui_tap_requested.connect(_on_ui_tap_requested)
	effects_layer = GameplayEffectsLayerType.new()
	effects_layer.z_index = 0
	gameplay_ui.attach_reward_foreground(effects_layer)
	effects_layer.coin_flight_started.connect(_on_coin_flight_started)
	effects_layer.coin_arrived.connect(_on_coin_arrived)
	effects_layer.level_reward_wave_launched.connect(_on_level_reward_wave_launched)
	effects_layer.level_reward_coin_arrived.connect(_on_level_reward_coin_arrived)
	effects_layer.level_reward_finished.connect(_on_level_reward_finished)
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
	home_overlay.home_requested.connect(_show_home)
	home_overlay.music_toggled.connect(_on_music_toggled)
	home_overlay.sound_toggled.connect(_on_sound_toggled)
	home_overlay.privacy_policy_requested.connect(_on_privacy_policy_requested)
	home_overlay.privacy_options_requested.connect(_on_privacy_options_requested)
	home_overlay.ui_tap_requested.connect(_on_ui_tap_requested)
	home_overlay.exit_requested.connect(_on_exit_requested)

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
			if target_collection.has("board_center"):
				target_collection.board_center = board_visual_center()
		for marker in debug_contact_points:
			marker.position += offset_delta
		if effects_layer != null:
			effects_layer.shift_world(offset_delta)
		if gem_sprite_layer != null:
			gem_sprite_layer.shift_reward_effects(offset_delta)
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
		var depth := int(merge_event.get("depth", 0))
		var completes_active_target := result_level == active_target_tier()
		merge_event.target_objective_completed = false
		merge_event.final_target_completed = false
		# Authoritative target state advances first so the reward presentation can
		# branch on the confirmed final-target result instead of guessing.
		if completes_active_target:
			_advance_target_state_authoritative(result_id, merge_event)
		var final_target := bool(merge_event.final_target_completed)
		# One shared timeline drives result scale, source pull, hit-stop, ring,
		# mini gems, sound timing, and pitch for this reward tier.
		var timeline: Dictionary = GameConfig.merge_timeline(depth, final_target)
		merge_event.timeline = timeline
		# Keep gameplay authority immediate while aligning the audible reward with
		# the resulting-gem reveal.
		merge_event.merge_sound_event = "merge_%d" % result_level if completes_active_target else "normal_merge"
		merge_event.merge_sound_pitch = float(timeline.get("pitch", 1.0))
		merge_event.reveal_sound_played = false
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
		merge_event.elapsed = -float(depth) * GameConfig.CHAIN_PRESENTATION_STAGGER
		merge_event.first_frame_visible = false
		merge_presentations.append(merge_event)
		_trace_presentation_event("merge_confirmed", result_id)
		_trace_presentation_event("result_created", result_id)
		_begin_merge_hitstop(result_id, float(timeline.get("hitstop", 0.0)))
		if gem_sprite_layer != null and result_id >= 0:
			var initial_transform := _merge_result_transform_for(0.0, timeline)
			gem_sprite_layer.set_presentation_transform(result_id, initial_transform.scale, initial_transform.rotation, initial_transform.offset, true)
		if effects_layer != null:
			effects_layer.begin_merge_feedback(merge_event)
			# The final target owns a dedicated staged celebration, so it must not
			# also fire the compact per-target coin group.
			if awarded_coins > 0 and not final_target:
				var coin_destination := gameplay_ui.coin_collection_destination() if gameplay_ui != null else GameConfig.COIN_HUD_FALLBACK_DESTINATION
				effects_layer.begin_target_coin_reward(merge_event, awarded_coins, coin_destination)
		if gem_sprite_layer != null:
			gem_sprite_layer.begin_merge_radial(
				Vector2(merge_event.get("midpoint", Vector2.ZERO)),
				result_level,
				float(timeline.get("radial_intensity", GameConfig.MERGE_RADIAL_INTENSITY_NORMAL)),
				float(depth) * GameConfig.CHAIN_PRESENTATION_STAGGER
			)
		_schedule_bonus_gems(merge_event)
		if completes_active_target and not final_target and gameplay_ui != null:
			gameplay_ui.acknowledge_target_progress()
		if final_target:
			_begin_final_celebration(awarded_coins)
		if depth > 0:
			audio_feedback.emit_event("chain", 1.0, float(timeline.get("pitch", 1.0)))
			haptics_feedback.emit_event("chain")
		else:
			haptics_feedback.emit_event("major_merge" if result_level >= GameConfig.MAJOR_REWARD_TIER else "merge")
		if completes_active_target and result_id >= 0 and not counted_target_result_ids.has(result_id):
			pending_target_presentations[result_id] = merge_event
		resolution_multiplier += 1


func _schedule_bonus_gems(merge_event: Dictionary) -> void:
	var depth := int(merge_event.get("depth", 0))
	if depth > GameConfig.BONUS_REWARD_MAX_CHAIN_DEPTH:
		_trace_presentation_event("bonus_gems_limited", int(merge_event.get("result_id", -1)))
		return
	var live_count := 0
	for piece in pieces:
		if not piece.consumed:
			live_count += 1
	var reserved_count := 0
	for pending in pending_bonus_spawns:
		reserved_count += (pending.get("levels", []) as Array).size()
	var population_capacity := maxi(0, GameConfig.BONUS_BOARD_PIECE_CAP - live_count - reserved_count)
	var count := mini(GameConfig.bonus_gem_count(depth), mini(bonus_spawn_budget_remaining, population_capacity))
	if count <= 0:
		_trace_presentation_event("bonus_gems_limited", int(merge_event.get("result_id", -1)))
		return
	bonus_spawn_budget_remaining -= count
	var result_id := int(merge_event.get("result_id", -1))
	var result_level := int(merge_event.get("level", 2))
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(level_seed * 1103515245 + result_id * 12345 + depth * 97)
	var levels: Array[int] = []
	for _index in range(count):
		var selected := _choose_bonus_level(result_level, rng)
		var highest_eligible := maxi(1, result_level - 2)
		# Multi-gem splits must be visually identifiable. Prefer a different tier
		# for every sibling whenever the result exposes enough eligible levels.
		if highest_eligible >= count and levels.has(selected):
			for offset in range(1, highest_eligible + 1):
				var alternate := 1 + posmod(selected - 1 + offset + result_id, highest_eligible)
				if not levels.has(alternate):
					selected = alternate
					break
		levels.append(selected)
	pending_bonus_spawns.append({
		"event_id": result_id,
		"result_id": result_id,
		"result_level": result_level,
		"origin": Vector2(merge_event.get("midpoint", Vector2.ZERO)),
		"levels": levels,
		"timeline": merge_event.get("timeline", GameConfig.MERGE_TIMELINE_NORMAL),
		"remaining": float((merge_event.get("timeline", GameConfig.MERGE_TIMELINE_NORMAL) as Dictionary).get("reveal", GameConfig.MERGE_REVEAL_START)) + float(depth) * GameConfig.CHAIN_PRESENTATION_STAGGER,
		"seed": rng.seed,
	})
	_trace_presentation_event("bonus_gems_scheduled", result_id)


func _choose_bonus_level(result_level: int, rng: RandomNumberGenerator) -> int:
	var highest_eligible := maxi(1, result_level - 2)
	if highest_eligible <= 1:
		return 1
	var low_end := maxi(1, int(ceil(float(highest_eligible) / 3.0)))
	var middle_end := maxi(low_end + 1, int(ceil(float(highest_eligible) * 2.0 / 3.0)))
	middle_end = mini(middle_end, highest_eligible)
	var roll := rng.randf()
	if roll < float(GameConfig.BONUS_TIER_WEIGHTS[0]):
		return rng.randi_range(1, low_end)
	if roll < float(GameConfig.BONUS_TIER_WEIGHTS[0]) + float(GameConfig.BONUS_TIER_WEIGHTS[1]):
		return rng.randi_range(mini(low_end + 1, highest_eligible), middle_end)
	return rng.randi_range(mini(middle_end + 1, highest_eligible), highest_eligible)


func _update_pending_bonus_spawns(delta: float) -> void:
	if pending_bonus_spawns.is_empty():
		return
	var waiting: Array[Dictionary] = []
	for reward in pending_bonus_spawns:
		reward.remaining = float(reward.get("remaining", 0.0)) - delta
		if float(reward.remaining) > 0.0:
			waiting.append(reward)
			continue
		_spawn_bonus_reward(reward)
	pending_bonus_spawns = waiting


func _sync_pending_target_coin_origins() -> void:
	if effects_layer == null:
		return
	for result_id in effects_layer.pending_target_coin_result_ids():
		var piece := _live_piece(result_id)
		if piece != null:
			effects_layer.reanchor_pending_target_coin_reward(result_id, piece.position)


func _spawn_bonus_reward(reward: Dictionary) -> void:
	var event_id := int(reward.get("event_id", -1))
	var result_id := int(reward.get("result_id", -1))
	var result_level := int(reward.get("result_level", 2))
	var timeline: Dictionary = reward.get("timeline", GameConfig.MERGE_TIMELINE_NORMAL) as Dictionary
	var initial_elapsed := maxf(0.0, -float(reward.get("remaining", 0.0)))
	var initial_scale := _bonus_result_scale_for(initial_elapsed, timeline)
	var origin: Vector2 = reward.get("origin", Vector2.ZERO)
	var result_piece := _live_piece(result_id)
	if result_piece != null:
		origin = result_piece.position
	var levels: Array = reward.get("levels", []) as Array
	var directions := GameConfig.bonus_spawn_directions(levels.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = int(reward.get("seed", event_id))
	var reserved: Array[Dictionary] = []
	var spawned_ids: Array[int] = []
	for index in range(levels.size()):
		var level := int(levels[index])
		var radius := GameConfig.gem_collision_radius(level) * GameConfig.gem_perspective_scale_at(origin.y)
		var angle := float(directions[index % directions.size()])
		angle += rng.randf_range(-9.0, 9.0) if levels.size() == 1 else rng.randf_range(-3.0, 3.0)
		var direction := Vector2.from_angle(deg_to_rad(angle))
		var result_radius := GameConfig.gem_collision_radius(result_level) * GameConfig.gem_perspective_scale_at(origin.y)
		var position := _find_bonus_spawn_position(origin, direction, radius, result_radius, reserved)
		var piece := GemPiece.new(next_piece_id, level, position, GameConfig.gem_collision_radius(level))
		next_piece_id += 1
		# The real body and its impulse become authoritative before this frame's
		# simulation step. There is no presentation-only position or physics hold.
		piece.velocity = direction * GameConfig.BONUS_SPAWN_IMPULSE
		piece.bonus_event_id = event_id
		piece.bonus_merge_grace_remaining = float(GameConfig.BONUS_MERGE_GRACE_MS) / 1000.0
		pieces.append(piece)
		reserved.append({"position": position, "radius": piece.radius})
		spawned_ids.append(piece.id)
		piece_visual_feedbacks[piece.id] = {
			"kind": "bonus_spawn",
			"elapsed": initial_elapsed,
			"duration": GameConfig.BONUS_VISUAL_BURST_DURATION,
			"timeline": timeline,
		}
		if gem_sprite_layer != null:
			gem_sprite_layer.set_presentation_scale(piece.id, initial_scale)
	bonus_spawn_history.append({"event_id": event_id, "result_id": result_id, "piece_ids": spawned_ids, "levels": levels.duplicate(), "origin": origin})
	while bonus_spawn_history.size() > 128:
		bonus_spawn_history.pop_front()
	_trace_presentation_event("bonus_gems_spawned", result_id)


func _find_bonus_spawn_position(origin: Vector2, direction: Vector2, radius: float, result_radius: float, reserved: Array[Dictionary]) -> Vector2:
	var best := origin
	var best_clearance := -INF
	var base_distance := result_radius + radius + GameConfig.BONUS_SPAWN_CLEARANCE
	var angle_offsets := [0.0, -12.0, 12.0, -24.0, 24.0, -38.0, 38.0]
	for distance_scale in [1.0, 1.22, 1.45]:
		for angle_offset in angle_offsets:
			var candidate_direction := direction.rotated(deg_to_rad(float(angle_offset)))
			var candidate := origin + candidate_direction * base_distance * float(distance_scale)
			candidate.y = clampf(candidate.y, GameConfig.board_top() + radius, GameConfig.board_bottom() - radius)
			candidate.x = clampf(candidate.x, GameConfig.table_left_at(candidate.y) + radius, GameConfig.table_right_at(candidate.y) - radius)
			var clearance := INF
			for piece in pieces:
				if piece.consumed:
					continue
				clearance = minf(clearance, candidate.distance_to(piece.position) - radius - piece.radius)
			for placed in reserved:
				clearance = minf(clearance, candidate.distance_to(Vector2(placed.position)) - radius - float(placed.radius))
			if clearance > best_clearance:
				best_clearance = clearance
				best = candidate
			if clearance >= GameConfig.BONUS_SPAWN_CLEARANCE:
				return candidate
	return best


## Freezes only the confirmed merge result. Its momentum is restored exactly, so
## the simulation resumes with the same value the merge service produced.
func _begin_merge_hitstop(result_id: int, duration: float) -> void:
	if result_id < 0 or duration <= 0.0:
		return
	for piece in pieces:
		if piece.id != result_id or piece.consumed:
			continue
		merge_hitstops[result_id] = {"remaining": duration, "velocity": piece.velocity}
		piece.velocity = Vector2.ZERO
		return


func _update_merge_hitstops(delta: float) -> void:
	if merge_hitstops.is_empty():
		return
	for piece_id in merge_hitstops.keys():
		var entry: Dictionary = merge_hitstops[piece_id]
		entry.remaining = float(entry.remaining) - delta
		var piece := _live_piece(int(piece_id))
		if piece == null:
			merge_hitstops.erase(piece_id)
		elif float(entry.remaining) <= 0.0:
			piece.velocity = entry.velocity
			merge_hitstops.erase(piece_id)
		else:
			piece.velocity = Vector2.ZERO


func _live_piece(piece_id: int) -> GemPiece:
	for piece in pieces:
		if piece.id == piece_id and not piece.consumed:
			return piece
	return null


## Visual center of the playable board, not of the physical screen.
func board_visual_center() -> Vector2:
	return Vector2(GameConfig.table_center_x(), (GameConfig.board_top() + GameConfig.board_bottom()) * 0.5)


func _begin_final_celebration(awarded_coins: int) -> void:
	final_celebration_active = true
	final_celebration_elapsed = 0.0
	final_celebration_coins = maxi(0, awarded_coins)
	final_celebration_coins_started = false
	final_celebration_hero_done = false
	dragging = false


func _cancel_final_celebration() -> void:
	final_celebration_active = false
	final_celebration_elapsed = 0.0
	final_celebration_coins = 0
	final_celebration_coins_started = false
	final_celebration_hero_done = false
	if effects_layer != null:
		effects_layer.cancel_level_reward_coins()
		effects_layer.end_hero_hold()


## Owns only the timing of the cosmetic reward stages. Coin totals, target state,
## and progression were already resolved by authoritative gameplay logic.
func _update_final_celebration(delta: float) -> void:
	if not final_celebration_active:
		return
	final_celebration_elapsed += delta
	if final_celebration_coins_started:
		return
	if final_celebration_elapsed < GameConfig.LEVEL_REWARD_COIN_SPAWN_AT:
		return
	# Coins may never overtake the hero gem. If an earlier queued target delayed
	# the hero sequence, wait for its arrival before the reward pile appears.
	if not final_celebration_hero_done and final_celebration_elapsed < GameConfig.LEVEL_REWARD_COIN_SPAWN_AT + FINAL_CELEBRATION_COIN_TIMEOUT:
		return
	final_celebration_coins_started = true
	if effects_layer == null or final_celebration_coins <= 0:
		final_celebration_active = false
		return
	var destination := gameplay_ui.coin_collection_destination() if gameplay_ui != null else GameConfig.COIN_HUD_FALLBACK_DESTINATION
	effects_layer.begin_level_reward_coins(board_visual_center(), final_celebration_coins, destination)
	_trace_presentation_event("level_reward_coins_spawned", final_target_result_id)


func _on_level_reward_wave_launched(_wave_index: int) -> void:
	if gameplay_ui != null:
		gameplay_ui.punch_coin_counter()


func _on_level_reward_coin_arrived(value: int, final_coin: bool) -> void:
	if gameplay_ui != null:
		# The counter interpolates upward per arrival; the wave punch is separate so
		# twenty coins never produce twenty container punches.
		gameplay_ui.collect_coin_chunk(value, final_coin, false)
		if final_coin:
			gameplay_ui.final_coin_counter_impact()
	if audio_feedback != null:
		audio_feedback.emit_event("coin_reward" if final_coin else "coin_tick")
	if final_coin and haptics_feedback != null:
		haptics_feedback.emit_event("coin_collect")


func _on_level_reward_finished() -> void:
	final_celebration_active = false
	_trace_presentation_event("level_reward_coins_collected", final_target_result_id)


func _advance_target_state_authoritative(result_id: int, merge_event: Dictionary) -> void:
	# This update belongs to the confirmed result, not to the duration of its UI
	# duplicate. It lets a rapid later merge compare against the correct target.
	var required_quantity := active_target_quantity()
	target_progress += 1
	if target_progress < required_quantity:
		return
	target_progress = 0
	target_index += 1
	merge_event.target_objective_completed = true
	if target_index >= target_sequence().size():
		merge_event.final_target_completed = true
		final_target_result_id = result_id
		_trace_presentation_event("final_target_confirmed", result_id)
		_qualify_win_if_target_complete()

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
	target_collection_queue.clear()
	merge_presentations.clear()
	piece_visual_feedbacks.clear()
	merge_hitstops.clear()
	pending_bonus_spawns.clear()
	_cancel_final_celebration()
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
		var timeline: Dictionary = presentation.get("timeline", GameConfig.MERGE_TIMELINE_NORMAL) as Dictionary
		var timeline_duration := float(timeline.get("duration", GameConfig.MERGE_PRESENTATION_DURATION))
		var overlap_start := GameConfig.FINAL_TARGET_COLLECTION_OVERLAP_START if bool(presentation.get("final_target_completed", false)) else GameConfig.TARGET_COLLECTION_OVERLAP_START
		if float(presentation.elapsed) >= float(timeline.get("sound_at", GameConfig.MERGE_REVEAL_SOUND_AT)) and not bool(presentation.get("reveal_sound_played", false)):
			presentation.reveal_sound_played = true
			if audio_feedback != null:
				audio_feedback.emit_event(String(presentation.get("merge_sound_event", "normal_merge")), 1.0, float(presentation.get("merge_sound_pitch", 1.0)))
			_trace_presentation_event("merge_reveal_sound", result_id)
		if float(presentation.elapsed) >= overlap_start and pending_target_presentations.has(result_id):
			pending_target_presentations.erase(result_id)
			_queue_target_collection(result_id, presentation)
		if float(presentation.elapsed) >= 0.0 and result_id >= 0 and gem_sprite_layer != null:
			var result_transform := _merge_result_transform_for(float(presentation.elapsed), timeline)
			gem_sprite_layer.set_presentation_transform(result_id, result_transform.scale, result_transform.rotation, result_transform.offset, true)
		var duration_complete := float(presentation.elapsed) >= timeline_duration
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
		# The target duplicate normally starts during merge settle above. This is
		# the exactly-once fallback for a legacy or zero-duration presentation.
		if pending_target_presentations.has(result_id):
			pending_target_presentations.erase(result_id)
			_queue_target_collection(result_id, presentation)


func _queue_target_collection(result_id: int, presentation: Dictionary) -> void:
	if result_id < 0 or counted_target_result_ids.has(result_id):
		return
	counted_target_result_ids[result_id] = true
	target_collection_queue.append({"result_id": result_id, "presentation": presentation})
	_trace_presentation_event("target_completed", result_id)
	_try_begin_next_target_collection()


func _try_begin_next_target_collection() -> void:
	if collection_in_progress or target_collection_queue.is_empty():
		return
	var entry: Dictionary = target_collection_queue.pop_front()
	_begin_target_collection(int(entry.get("result_id", -1)), entry.get("presentation", {}))

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
	var hero := bool(presentation.get("final_target_completed", false))
	target_collection = {
		"result_id": result_id,
		"level": level,
		"sprite": sprite,
		"start": start,
		"elapsed": 0.0,
		"base_scale": body_scale,
		"opacity": 1.0,
		"hero": hero,
		"hero_hold_started": false,
		"panel_anticipated": false,
		"board_center": board_visual_center(),
		"target_objective_completed": bool(presentation.get("target_objective_completed", false)),
		"final_target_completed": hero,
	}
	if hero:
		# The hero gem is detached from gameplay physics for the whole sequence and
		# must draw over every other reward visual while it is held.
		sprite.z_index = 6
		sprite.scale = body_scale * GameConfig.HERO_TRAVEL_START_SCALE
	_trace_presentation_event("collection_animation_started", result_id)

func _update_target_collection(delta: float) -> void:
	if not collection_in_progress:
		return
	var sprite: Sprite2D = target_collection.get("sprite")
	if sprite == null:
		_finish_target_collection()
		return
	if bool(target_collection.get("hero", false)):
		_update_hero_target_collection(delta, sprite)
		return
	var elapsed := float(target_collection.get("elapsed", 0.0)) + delta
	target_collection.elapsed = elapsed
	var t := clampf(elapsed / GameConfig.TARGET_COLLECTION_DURATION, 0.0, 1.0)
	var confirm_t := clampf(elapsed / GameConfig.TARGET_COLLECTION_CONFIRM_DURATION, 0.0, 1.0)
	var travel_t := clampf((elapsed - GameConfig.TARGET_COLLECTION_CONFIRM_DURATION) / GameConfig.TARGET_COLLECTION_TRAVEL_DURATION, 0.0, 1.0)
	var eased := smoothstep(0.0, 1.0, travel_t)
	var start: Vector2 = target_collection.start
	var destination := gameplay_ui.target_collection_destination() if gameplay_ui != null else GameConfig.TARGET_COLLECTION_DESTINATION
	target_collection.destination = destination
	var control := Vector2(lerpf(start.x, destination.x, 0.48), minf(start.y, destination.y) - 82.0)
	var inverse := 1.0 - eased
	sprite.position = start * inverse * inverse + control * 2.0 * inverse * eased + destination * eased * eased
	var pop := 1.0 + sin(confirm_t * PI) * (GameConfig.TARGET_COLLECTION_POP_SCALE - 1.0)
	if elapsed >= GameConfig.TARGET_COLLECTION_CONFIRM_DURATION:
		pop = lerpf(1.0, 0.86, eased)
	var base_scale: Vector2 = target_collection.get("base_scale", Vector2.ONE)
	sprite.scale = base_scale * pop
	var opacity := 1.0
	if t > GameConfig.TARGET_COLLECTION_FADE_START:
		opacity = lerpf(1.0, 0.15, smoothstep(GameConfig.TARGET_COLLECTION_FADE_START, 1.0, t))
	target_collection.opacity = opacity
	sprite.modulate = Color(1.0, 1.0, 1.0, opacity)
	if t >= 1.0:
		_finish_target_collection()

## Phase B travel -> Phase C hero hold -> Phase D flight to the target panel.
## The HUD target count is only allowed to change when Phase D arrives.
func _update_hero_target_collection(delta: float, sprite: Sprite2D) -> void:
	var elapsed := float(target_collection.get("elapsed", 0.0)) + delta
	target_collection.elapsed = elapsed
	var travel_end := GameConfig.HERO_TRAVEL_DURATION
	var hold_end := travel_end + GameConfig.HERO_HOLD_DURATION
	var anticipation_end := hold_end + GameConfig.HERO_LAUNCH_ANTICIPATION_DURATION
	var flight_end := anticipation_end + GameConfig.HERO_FLIGHT_DURATION
	var base_scale: Vector2 = target_collection.get("base_scale", Vector2.ONE)
	var start: Vector2 = target_collection.start
	var board_center: Vector2 = target_collection.board_center
	var destination := gameplay_ui.target_collection_destination() if gameplay_ui != null else GameConfig.TARGET_COLLECTION_DESTINATION
	target_collection.destination = destination
	var emphasis := GameConfig.HERO_TRAVEL_START_SCALE
	var rotation := 0.0
	var position := board_center
	if elapsed < travel_end:
		# Phase B — smooth ease-out cubic travel to the visual center of the board.
		var travel_t := clampf(elapsed / travel_end, 0.0, 1.0)
		var eased := 1.0 - pow(1.0 - travel_t, 3.0)
		position = start.lerp(board_center, eased)
		emphasis = lerpf(GameConfig.HERO_TRAVEL_START_SCALE, GameConfig.HERO_TRAVEL_END_SCALE, eased)
	elif elapsed < hold_end:
		# Phase C — the deliberate 500 ms recognition hold.
		if not bool(target_collection.get("hero_hold_started", false)):
			target_collection.hero_hold_started = true
			if effects_layer != null:
				effects_layer.begin_hero_hold(board_center, int(target_collection.get("level", 8)))
			_trace_presentation_event("hero_hold_started", int(target_collection.get("result_id", -1)))
		var hold_elapsed := elapsed - travel_end
		if hold_elapsed <= GameConfig.HERO_HOLD_RISE_DURATION:
			var rise := 1.0 - pow(1.0 - clampf(hold_elapsed / GameConfig.HERO_HOLD_RISE_DURATION, 0.0, 1.0), 3.0)
			emphasis = lerpf(GameConfig.HERO_TRAVEL_END_SCALE, GameConfig.HERO_HOLD_PEAK_SCALE, rise)
		elif hold_elapsed <= GameConfig.HERO_HOLD_RISE_DURATION + GameConfig.HERO_HOLD_SETTLE_DURATION:
			var settle := smoothstep(0.0, 1.0, (hold_elapsed - GameConfig.HERO_HOLD_RISE_DURATION) / GameConfig.HERO_HOLD_SETTLE_DURATION)
			emphasis = lerpf(GameConfig.HERO_HOLD_PEAK_SCALE, GameConfig.HERO_HOLD_SCALE, settle)
		else:
			var breath := (sin(hold_elapsed * TAU * GameConfig.HERO_HOLD_BREATH_HZ) + 1.0) * 0.5
			emphasis = lerpf(GameConfig.HERO_HOLD_SCALE, GameConfig.HERO_HOLD_BREATH_SCALE, breath)
	elif elapsed < anticipation_end:
		var anticipation_t := clampf((elapsed - hold_end) / GameConfig.HERO_LAUNCH_ANTICIPATION_DURATION, 0.0, 1.0)
		var opposite := (board_center - destination).normalized()
		position = board_center + opposite * GameConfig.HERO_LAUNCH_ANTICIPATION_DISTANCE * smoothstep(0.0, 1.0, anticipation_t)
		emphasis = lerpf(GameConfig.HERO_HOLD_SCALE, GameConfig.HERO_LAUNCH_ANTICIPATION_SCALE, smoothstep(0.0, 1.0, anticipation_t))
		if effects_layer != null:
			effects_layer.move_hero_hold(position)
		if not bool(target_collection.get("panel_anticipated", false)) and elapsed >= anticipation_end - GameConfig.HERO_PANEL_ANTICIPATION_LEAD:
			target_collection.panel_anticipated = true
			if gameplay_ui != null:
				gameplay_ui.anticipate_target_panel()
	else:
		# Phase D — curved flight into the HUD target panel.
		var flight_t := clampf((elapsed - anticipation_end) / GameConfig.HERO_FLIGHT_DURATION, 0.0, 1.0)
		var eased_flight := 1.0 - pow(1.0 - flight_t, 3.0)
		var flight_start := board_center + (board_center - destination).normalized() * GameConfig.HERO_LAUNCH_ANTICIPATION_DISTANCE
		var control := Vector2(lerpf(flight_start.x, destination.x, 0.42), minf(flight_start.y, destination.y) - 96.0)
		var inverse := 1.0 - eased_flight
		position = flight_start * inverse * inverse + control * 2.0 * inverse * eased_flight + destination * eased_flight * eased_flight
		emphasis = lerpf(GameConfig.HERO_LAUNCH_ANTICIPATION_SCALE, GameConfig.HERO_FLIGHT_END_SCALE, eased_flight)
		# A small controlled tilt out and back; never a coin-style spin.
		rotation = deg_to_rad(GameConfig.HERO_FLIGHT_TILT_DEGREES) * sin(flight_t * PI)
		if effects_layer != null:
			effects_layer.move_hero_hold(position)
		if not bool(target_collection.get("panel_anticipated", false)) and elapsed >= flight_end - GameConfig.HERO_PANEL_ANTICIPATION_LEAD:
			target_collection.panel_anticipated = true
			if gameplay_ui != null:
				gameplay_ui.anticipate_target_panel()
	sprite.position = position
	sprite.scale = base_scale * emphasis
	sprite.rotation = rotation
	sprite.modulate = Color.WHITE
	target_collection.opacity = 1.0
	if elapsed >= flight_end:
		_finish_target_collection()


func _finish_target_collection() -> void:
	var result_id := int(target_collection.get("result_id", -1))
	var objective_completed := bool(target_collection.get("target_objective_completed", false))
	var final_completed := bool(target_collection.get("final_target_completed", false))
	var hero := bool(target_collection.get("hero", false))
	var panel_destination: Vector2 = target_collection.get("destination", GameConfig.TARGET_COLLECTION_DESTINATION)
	var sprite: Sprite2D = target_collection.get("sprite")
	if sprite != null:
		sprite.queue_free()
	target_collection.clear()
	collection_in_progress = false
	if hero:
		final_celebration_hero_done = true
	if effects_layer != null and hero:
		effects_layer.end_hero_hold()
		effects_layer.burst_target_panel_sparkles(panel_destination)
		effects_layer.show_reward_amount(Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 54.0), final_celebration_coins)
	if gameplay_ui != null:
		if hero:
			gameplay_ui.impact_target_panel()
		else:
			gameplay_ui.pulse_target()
	audio_feedback.emit_event("target_collect")
	haptics_feedback.emit_event("target_collect")
	_trace_presentation_event("collection_animation_completed", result_id)
	presented_target_progress += 1
	if objective_completed:
		presented_target_progress = 0
		presented_target_index += 1
		if audio_feedback != null:
			audio_feedback.emit_event("target_complete")
		if final_completed:
			_trace_presentation_event("final_target_presented", result_id)
	_try_begin_next_target_collection()

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
	if win_presented or final_celebration_active or not merge_presentations.is_empty() or collection_in_progress or not target_collection_queue.is_empty() or not pending_target_presentations.is_empty() or (effects_layer != null and effects_layer.has_active_coin_flights()):
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
	return float(_merge_result_transform_for(elapsed, GameConfig.MERGE_TIMELINE_NORMAL).uniform_scale)

func _merge_timeline_for(result_id: int) -> Dictionary:
	for presentation in merge_presentations:
		if int(presentation.get("result_id", -1)) == result_id:
			return presentation.get("timeline", GameConfig.MERGE_TIMELINE_NORMAL) as Dictionary
	return GameConfig.MERGE_TIMELINE_NORMAL

func _merge_result_visual_transform(elapsed: float, result_id: int) -> Dictionary:
	return _merge_result_transform_for(elapsed, _merge_timeline_for(result_id))

## Walks the timeline's `scale_keys` list. The first segment uses a back-style
## overshoot so the reveal snaps; later segments settle with a cubic ease-out.
func _merge_result_transform_for(elapsed: float, timeline: Dictionary) -> Dictionary:
	var reveal := float(timeline.get("reveal", GameConfig.MERGE_REVEAL_START))
	var uniform_scale := 0.0
	if elapsed >= reveal:
		var scale_keys: Array = timeline.get("scale_keys", []) as Array
		var previous_time := reveal
		var previous_scale := float(timeline.get("start_scale", GameConfig.MERGE_RESULT_START_SCALE))
		uniform_scale = previous_scale
		for index in range(scale_keys.size()):
			var key: Array = scale_keys[index] as Array
			var key_time := float(key[0])
			var key_scale := float(key[1])
			if elapsed >= key_time:
				previous_time = key_time
				previous_scale = key_scale
				uniform_scale = key_scale
				continue
			var segment := maxf(0.001, key_time - previous_time)
			var segment_t := clampf((elapsed - previous_time) / segment, 0.0, 1.0)
			var eased := 1.0 - pow(1.0 - segment_t, 3.0)
			if index == 0:
				# Fast satisfying ease-out/back on the reveal pop only.
				var back := 1.70158
				var inverse := segment_t - 1.0
				eased = inverse * inverse * ((back + 1.0) * inverse + back) + 1.0
			uniform_scale = lerpf(previous_scale, key_scale, eased)
			break
	# The result uses one centered uniform pop; source compression and contact
	# response are separate presentation-only transforms.
	return {"scale": Vector2.ONE * uniform_scale, "uniform_scale": uniform_scale, "offset": Vector2.ZERO, "rotation": 0.0}

## Reward siblings share the result pop exactly while its timeline is active.
## The final-target timeline hands its result to the hero early, so its siblings
## ease the final shared scale back to 1.0 over the remaining burst interval.
func _bonus_result_scale_for(elapsed: float, timeline: Dictionary) -> float:
	var reveal := float(timeline.get("reveal", GameConfig.MERGE_REVEAL_START))
	var timeline_duration := float(timeline.get("duration", GameConfig.MERGE_PRESENTATION_DURATION))
	var timeline_elapsed := reveal + maxf(0.0, elapsed)
	if timeline_elapsed <= timeline_duration:
		return float(_merge_result_transform_for(timeline_elapsed, timeline).uniform_scale)
	var terminal_scale := float(_merge_result_transform_for(timeline_duration, timeline).uniform_scale)
	var shared_duration := maxf(0.001, timeline_duration - reveal)
	var settle_duration := maxf(0.001, GameConfig.BONUS_VISUAL_BURST_DURATION - shared_duration)
	var settle_t := clampf((elapsed - shared_duration) / settle_duration, 0.0, 1.0)
	return lerpf(terminal_scale, 1.0, 1.0 - pow(1.0 - settle_t, 3.0))

func _update_piece_visual_feedbacks(delta: float) -> void:
	if gem_sprite_layer == null or piece_visual_feedbacks.is_empty():
		return
	for piece_id in piece_visual_feedbacks.keys():
		var feedback: Dictionary = piece_visual_feedbacks[piece_id]
		feedback.elapsed = float(feedback.get("elapsed", 0.0)) + delta
		var duration := maxf(0.001, float(feedback.get("duration", 0.1)))
		var t := clampf(float(feedback.elapsed) / duration, 0.0, 1.0)
		var kind := String(feedback.get("kind", ""))
		if kind == "collision":
			var envelope := sin(t * PI)
			var compression := float(feedback.get("compression", 0.03)) * envelope
			var normal: Vector2 = feedback.get("normal", Vector2.RIGHT)
			gem_sprite_layer.set_impact_transform(int(piece_id), Vector2(1.0 - compression, 1.0 + compression * 0.55), normal)
			if t >= 1.0:
				gem_sprite_layer.clear_impact_scale(int(piece_id))
				piece_visual_feedbacks.erase(piece_id)
			continue
		var scale := 1.0
		if kind == "bonus_spawn":
			var timeline: Dictionary = feedback.get("timeline", GameConfig.MERGE_TIMELINE_NORMAL) as Dictionary
			scale = _bonus_result_scale_for(float(feedback.elapsed), timeline)
			if t >= 1.0:
				gem_sprite_layer.clear_presentation_scale(int(piece_id))
				piece_visual_feedbacks.erase(piece_id)
			else:
				gem_sprite_layer.set_presentation_scale(int(piece_id), scale)
			continue
		elif kind == "spawn":
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

func _on_ui_tap_requested() -> void:
	if audio_feedback != null:
		audio_feedback.emit_event("button")


func _on_exit_requested() -> void:
	if _exit_request_pending:
		return
	_exit_request_pending = true
	# Invalidate callbacks now, but let Android's Activity lifecycle own Java/ad
	# object destruction. Tearing down the engine synchronously inside a Button
	# signal was the path that produced the device's "app stopped" failure.
	if ad_manager != null and ad_manager.has_method("prepare_for_exit"):
		ad_manager.call("prepare_for_exit")
	if OS.get_name() == "Android" and _finish_android_activity():
		return
	if ad_manager != null and ad_manager.has_method("shutdown_for_exit"):
		ad_manager.call("shutdown_for_exit")
	call_deferred("_quit_tree_after_exit_request")


func _finish_android_activity() -> bool:
	if not Engine.has_singleton("AndroidRuntime"):
		return false
	var android_runtime = Engine.get_singleton("AndroidRuntime")
	var activity = android_runtime.getActivity()
	if activity == null:
		return false
	var finish_activity := func() -> void:
		activity.finishAndRemoveTask()
	var runnable = android_runtime.createRunnableFromGodotCallable(finish_activity)
	if runnable == null:
		return false
	activity.runOnUiThread(runnable)
	return true


func _quit_tree_after_exit_request() -> void:
	if is_inside_tree():
		get_tree().quit()

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
		false
	)

func _on_restart_requested() -> void:
	if gameplay_ui != null:
		gameplay_ui.hide_pause(false)
	if is_inside_tree():
		get_tree().paused = false
	restart()
	app_flow_state = AppFlowState.PLAYING

func _on_pause_home_requested() -> void:
	# Leave the paused gameplay modal synchronously before presenting Home. Home
	# then owns the paused tree and all input through its always-processing layer.
	if gameplay_ui != null:
		gameplay_ui.hide_pause(false)
	if is_inside_tree():
		get_tree().paused = false
	_show_home()

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
		# Home owns the complete screen. Keeping the gameplay HUD visible beneath
		# it made an Android-only Home dependency failure look like auto-started
		# gameplay and left Back operating on a state the player could not see.
		gameplay_ui.hide()
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
	if audio_feedback != null:
		audio_feedback.emit_event("coin_reward" if final_coin else "coin_tick")
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
				_begin_collision_visual(int(impact.get("piece_id", -1)), impact.get("normal", Vector2.RIGHT), strength)
		elif strength >= GameConfig.GEM_CONTACT_SOUND_THRESHOLD:
			var first_id := int(impact.get("first_id", -1))
			var second_id := int(impact.get("second_id", -1))
			var pair_key := "%d:%d" % [mini(first_id, second_id), maxi(first_id, second_id)]
			if merged_pairs.has(pair_key):
				continue
			audio_feedback.emit_event("gem_contact", clampf(strength / GameConfig.LAUNCH_SPEED, 0.35, 1.0))
			var normal: Vector2 = impact.get("normal", Vector2.RIGHT)
			_begin_collision_visual(first_id, -normal, strength)
			_begin_collision_visual(second_id, normal, strength)


func _begin_collision_visual(piece_id: int, normal: Vector2, strength: float) -> void:
	if piece_id < 0 or collision_visual_clock - float(collision_visual_last_at.get(piece_id, -100.0)) < GameConfig.COLLISION_VISUAL_COOLDOWN:
		return
	collision_visual_last_at[piece_id] = collision_visual_clock
	var intensity := clampf(strength / GameConfig.LAUNCH_SPEED, 0.0, 1.0)
	piece_visual_feedbacks[piece_id] = {
		"kind": "collision",
		"elapsed": 0.0,
		"duration": GameConfig.COLLISION_VISUAL_DURATION,
		"normal": normal,
		"compression": lerpf(0.018, GameConfig.COLLISION_VISUAL_MAX_COMPRESSION, intensity),
	}

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
	if launcher_state != LauncherState.READY_TO_AIM or win_qualified or failed:
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
	var timeline: Dictionary = presentation.get("timeline", GameConfig.MERGE_TIMELINE_NORMAL) as Dictionary
	var duration := float(timeline.get("duration", GameConfig.MERGE_PRESENTATION_DURATION))
	var reveal := float(timeline.get("reveal", GameConfig.MERGE_REVEAL_START))
	var pull_start := float(timeline.get("pull_start", GameConfig.MERGE_SOURCE_PULL_START))
	var pull_duration := maxf(0.001, float(timeline.get("pull_duration", GameConfig.MERGE_SOURCE_PULL_DURATION)))
	var elapsed := float(presentation.elapsed)
	var t: float = clampf(elapsed / duration, 0.0, 1.0)
	var midpoint: Vector2 = presentation.midpoint
	var result_level := int(presentation.level)
	var source_level := maxi(1, result_level - 1)
	var source_texture := presentation.get("source_texture") as Texture2D
	if source_texture == null:
		return
	# The hit-stop window holds the source pair exactly where contact confirmed;
	# the pull only starts afterwards and the pair is hidden at the reveal.
	var pull_t: float = clampf((elapsed - pull_start) / pull_duration, 0.0, 1.0)
	var compression_t := clampf(elapsed / GameConfig.MERGE_CONTACT_COMPRESSION_DURATION, 0.0, 1.0)
	var compressed_scale := Vector2.ONE.lerp(GameConfig.MERGE_CONTACT_COMPRESSION_SCALE, smoothstep(0.0, 1.0, compression_t))
	var source_axis_scale := compressed_scale.lerp(Vector2.ONE * GameConfig.MERGE_SOURCE_END_SCALE, pull_t)
	var source_alpha := 1.0 - smoothstep(reveal - 0.02, reveal, elapsed)
	if source_alpha > 0.0:
		for source_position in [presentation.first_position, presentation.second_position]:
			var position: Vector2 = source_position.lerp(midpoint, pull_t * 0.86)
			var source_diameter := GameConfig.gem_collision_radius(source_level) * GameConfig.gem_perspective_scale_at(source_position.y) * 2.0
			var texture_scale := source_diameter / maxf(source_texture.get_size().x, source_texture.get_size().y)
			var source_size := source_texture.get_size() * texture_scale * source_axis_scale
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
