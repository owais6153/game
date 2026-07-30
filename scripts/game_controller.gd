extends Node2D

const GemVisualsType = preload("res://scripts/gem_visuals.gd")
const HudRendererType = preload("res://scripts/hud_renderer.gd")
const AudioFeedbackServiceType = preload("res://scripts/audio_feedback_service.gd")
const HapticsServiceType = preload("res://scripts/haptics_service.gd")
const AssetCatalogType = preload("res://scripts/asset_catalog.gd")
const GemSpriteLayerType = preload("res://scripts/gem_sprite_layer.gd")
const ResultOverlayLayerType = preload("res://scripts/result_overlay_layer.gd")
const LevelConfigType = preload("res://scripts/level_config.gd")

var pieces: Array[GemPiece] = []
var simulation := BoardSimulation.new()
var merge_service := ContactMergeService.new()
var next_piece_id := 1
var level_config: Dictionary = LevelConfigType.level_1()
var next_level := 1
var next_queue_index := 0
var target_progress := 0
var target_index := 0
var counted_target_result_ids: Dictionary = {}
## Results count only after their own merge presentation has completed.
var pending_target_presentations: Dictionary = {}
var active_piece_id := -1
var dragging := false
var merge_presentations: Array[Dictionary] = []
var score := 0
var chain_multiplier := 1
var danger_timers: Dictionary = {}
var won := false
var win_qualified := false
var win_presented := false
var win_hold_elapsed := 0.0
var failed := false
var collection_in_progress := false
var target_collection: Dictionary = {}
var ready_delay_elapsed := 0.0
var audio_feedback: Node
var haptics_feedback: RefCounted
var gem_sprite_layer: GemSpriteLayer
var result_overlay
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
	_configure_level_1()
	_setup_asset_presentation()
	audio_feedback = AudioFeedbackServiceType.new()
	haptics_feedback = HapticsServiceType.new()
	add_child(audio_feedback)
	_advance_launcher_lifecycle()
	gem_sprite_layer.sync_gems(pieces)
	queue_redraw()

func _process(delta: float) -> void:
	for marker in debug_contact_points:
		marker.age = float(marker.get("age", 0.0)) + delta
	debug_contact_points = debug_contact_points.filter(func(marker: Dictionary) -> bool: return float(marker.get("age", 0.0)) < 0.45)
	if failed:
		_update_merge_presentations(delta)
		gem_sprite_layer.sync_gems(pieces)
		queue_redraw()
		return
	if win_qualified:
		_update_merge_presentations(delta)
		gem_sprite_layer.sync_gems(pieces)
		_update_win_presentation(delta)
		queue_redraw()
		return
	simulation.step(pieces, delta, merge_service)
	_route_collision_feedback()
	var result := merge_service.resolve(pieces, next_piece_id)
	pieces = result.pieces
	next_piece_id = result.next_id
	_apply_confirmed_merge_events(result.presentation_events)
	_update_merge_presentations(delta)
	_update_target_collection(delta)
	_update_danger_timers(delta)
	if win_qualified or failed:
		gem_sprite_layer.sync_gems(pieces)
		queue_redraw()
		return
	if result.merge_count > 0:
		if get_active_piece() == null:
			active_piece_id = -1
		if launcher_state != LauncherState.READY_TO_AIM:
			launcher_state = LauncherState.RESOLVING
	_advance_launcher_lifecycle(delta)
	gem_sprite_layer.sync_gems(pieces)
	queue_redraw()

func _advance_launcher_lifecycle(delta: float = 0.0) -> void:
	if collection_in_progress:
		return
	match launcher_state:
		LauncherState.SHOT_IN_FLIGHT:
			if all_pieces_settled():
				var active := get_active_piece()
				if active != null:
					active.is_active_launcher = false
					active_piece_id = -1
				launcher_state = LauncherState.RESOLVING
				ready_delay_elapsed = 0.0
		LauncherState.RESOLVING:
			if all_pieces_settled() and not merge_service.has_pending_candidates() and merge_presentations.is_empty():
				ready_delay_elapsed += delta
				if ready_delay_elapsed >= GameConfig.NEXT_LAUNCHER_READY_DELAY:
					launcher_state = LauncherState.SPAWNING_NEXT
			else:
				ready_delay_elapsed = 0.0
		LauncherState.SPAWNING_NEXT:
			if all_pieces_settled() and spawn_active_piece():
				launcher_state = LauncherState.READY_TO_AIM
				chain_multiplier = 1
				ready_delay_elapsed = 0.0

func lifecycle_name() -> String:
	return LauncherState.keys()[launcher_state]

## Presentation data only. UI code reads this snapshot and never owns game rules.
func hud_snapshot() -> Dictionary:
	var active := get_active_piece()
	var highest_level := 1
	for piece in pieces:
		if not piece.consumed:
			highest_level = maxi(highest_level, piece.level)
	return {
		"level_number": 1,
		"current_level": active.level if active != null else next_level,
		"next_level": next_level,
		"score": score,
		"chain_multiplier": chain_multiplier,
		"target_level": active_target_tier(),
		"target_progress": target_progress,
		"target_quantity": active_target_quantity(),
		"target_index": target_index,
		"target_total": target_sequence().size(),
		"highest_level": highest_level,
		"sound_enabled": audio_feedback.enabled if audio_feedback != null else true,
		"vibration_enabled": haptics_feedback.enabled,
	}

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F8:
		debug_calibration_enabled = not debug_calibration_enabled
		queue_redraw()
		return
	if event is InputEventScreenTouch:
		_handle_pointer(event.position, event.pressed)
	elif event is InputEventScreenDrag and dragging:
		move_active_to(event.position.x)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_pointer(event.position, event.pressed)
	elif event is InputEventMouseMotion and dragging:
		move_active_to(event.position.x)

func _handle_pointer(pointer: Vector2, pressed: bool) -> void:
	if win_presented or failed:
		if pressed and GameConfig.OVERLAY_BUTTON_RECT.has_point(pointer):
			restart()
		return
	if pressed:
		if GameConfig.SOUND_TOGGLE_RECT.has_point(pointer):
			audio_feedback.enabled = not audio_feedback.enabled
			audio_feedback.emit_event("button")
			return
		if GameConfig.VIBRATION_TOGGLE_RECT.has_point(pointer):
			haptics_feedback.enabled = not haptics_feedback.enabled
			if haptics_feedback.enabled:
				haptics_feedback.emit_event("launch")
			return
		if GameConfig.RESTART_RECT.has_point(pointer):
			audio_feedback.emit_event("button")
			restart()
			return
		if collection_in_progress:
			return
		var active := get_active_piece()
		if launcher_state == LauncherState.READY_TO_AIM and active != null and active.is_settled() and pointer.distance_to(active.position) <= active.radius * GameConfig.DRAG_HIT_RADIUS_MULTIPLIER:
			dragging = true
			move_active_to(pointer.x)
	elif dragging:
		dragging = false
		if not collection_in_progress:
			launch_active_piece()

func move_active_to(x_position: float) -> void:
	var active := get_active_piece()
	if launcher_state == LauncherState.READY_TO_AIM and active != null and active.is_settled():
		active.position.x = clampf(x_position, GameConfig.table_left_at(active.position.y) + active.radius, GameConfig.table_right_at(active.position.y) - active.radius)

func launch_active_piece() -> void:
	var active := get_active_piece()
	if launcher_state == LauncherState.READY_TO_AIM and active != null and active.is_settled():
		active.velocity = Vector2(0.0, -GameConfig.LAUNCH_SPEED)
		audio_feedback.emit_event("launch")
		haptics_feedback.emit_event("launch")
		launcher_state = LauncherState.SHOT_IN_FLIGHT

func spawn_active_piece() -> bool:
	# Idempotent for a lifecycle cycle: an existing launcher is never replaced.
	if get_active_piece() != null:
		return false
	var piece := GemPiece.new(next_piece_id, next_level, Vector2(360.0, GameConfig.LAUNCH_Y), GameConfig.gem_collision_radius(next_level))
	next_piece_id += 1
	piece.is_active_launcher = true
	pieces.append(piece)
	active_piece_id = piece.id
	next_queue_index += 1
	next_level = LevelConfigType.launcher_level_at(level_config, next_queue_index)
	return true

func get_active_piece() -> GemPiece:
	for piece in pieces:
		if piece.id == active_piece_id and piece.is_active_launcher and not piece.consumed:
			return piece
	return null

func all_pieces_settled() -> bool:
	for piece in pieces:
		if not piece.consumed and piece.is_moving():
			return false
	return true

func restart() -> void:
	pieces.clear()
	merge_service.clear()
	merge_presentations.clear()
	next_piece_id = 1
	_configure_level_1()
	active_piece_id = -1
	score = 0
	target_progress = 0
	target_index = 0
	counted_target_result_ids.clear()
	pending_target_presentations.clear()
	chain_multiplier = 1
	danger_timers.clear()
	won = false
	win_qualified = false
	win_presented = false
	win_hold_elapsed = 0.0
	failed = false
	collection_in_progress = false
	_cancel_target_collection()
	dragging = false
	launcher_state = LauncherState.SPAWNING_NEXT
	ready_delay_elapsed = 0.0
	_advance_launcher_lifecycle()
	if gem_sprite_layer != null:
		gem_sprite_layer.sync_gems(pieces)
	if result_overlay != null:
		result_overlay.dismiss()

func _setup_asset_presentation() -> void:
	var background := Sprite2D.new()
	background.texture = AssetCatalogType.TROPICAL_BACKGROUND
	background.position = GameConfig.VIEWPORT_SIZE * 0.5
	background.scale = Vector2(GameConfig.VIEWPORT_SIZE.x / background.texture.get_size().x, GameConfig.VIEWPORT_SIZE.y / background.texture.get_size().y)
	background.z_index = -20
	add_child(background)
	var table := Sprite2D.new()
	table.texture = AssetCatalogType.NEW_TABLE
	table.position = GameConfig.TABLE_TEXTURE_CENTER
	table.scale = GameConfig.TABLE_TEXTURE_RENDER_SCALE
	table.z_index = -10
	add_child(table)
	gem_sprite_layer = GemSpriteLayerType.new()
	gem_sprite_layer.z_index = 10
	add_child(gem_sprite_layer)
	var overlay_canvas := CanvasLayer.new()
	overlay_canvas.layer = 10
	add_child(overlay_canvas)
	result_overlay = ResultOverlayLayerType.new()
	overlay_canvas.add_child(result_overlay)

func _apply_confirmed_merge_events(events: Array[Dictionary]) -> void:
	var resolution_multiplier := 1
	for merge_event in events:
		var result_level: int = int(merge_event.level)
		chain_multiplier = resolution_multiplier
		score += GameConfig.merge_score_for_result_level(result_level) * chain_multiplier
		# Chain resolution remains immediate and deterministic; this only staggers its visuals.
		merge_event.elapsed = -float(merge_event.get("depth", 0)) * GameConfig.CHAIN_PRESENTATION_STAGGER
		merge_presentations.append(merge_event)
		audio_feedback.emit_event("merge_%d" % result_level)
		haptics_feedback.emit_event("merge")
		if int(merge_event.get("depth", 0)) > 0:
			audio_feedback.emit_event("chain")
			haptics_feedback.emit_event("chain")
		if result_level == active_target_tier():
			var result_id := int(merge_event.get("result_id", -1))
			if result_id >= 0 and not counted_target_result_ids.has(result_id):
				pending_target_presentations[result_id] = true
		resolution_multiplier += 1

func _configure_level_1() -> void:
	level_config = LevelConfigType.level_1()
	merge_service.max_result_level = int(level_config.active_tier_max)
	next_queue_index = 0
	next_level = LevelConfigType.initial_launcher_level(level_config)

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
		if piece.position.y + piece.radius > GameConfig.DANGER_LINE_Y:
			danger_timers[piece.id] = float(danger_timers.get(piece.id, 0.0)) + delta
			if float(danger_timers[piece.id]) >= GameConfig.DANGER_GRACE_DURATION and not failed:
				failed = true
				active_piece_id = -1
				launcher_state = LauncherState.RESOLVING
				audio_feedback.emit_event("fail")
				haptics_feedback.emit_event("fail")
				result_overlay.present(false, score)
				return
		else:
			danger_timers.erase(piece.id)
	for id in danger_timers.keys():
		if not live_ids.has(id):
			danger_timers.erase(id)

func _update_merge_presentations(delta: float) -> void:
	for presentation in merge_presentations:
		presentation.elapsed += delta
	var completed: Array[Dictionary] = merge_presentations.filter(func(presentation: Dictionary) -> bool: return presentation.elapsed >= GameConfig.MERGE_PRESENTATION_DURATION)
	merge_presentations = merge_presentations.filter(func(presentation: Dictionary) -> bool: return presentation.elapsed < GameConfig.MERGE_PRESENTATION_DURATION)
	for presentation in completed:
		var result_id := int(presentation.get("result_id", -1))
		if pending_target_presentations.has(result_id):
			pending_target_presentations.erase(result_id)
			if not counted_target_result_ids.has(result_id):
				counted_target_result_ids[result_id] = true
				_begin_target_collection(result_id)

func _begin_target_collection(result_id: int) -> void:
	if collection_in_progress or result_id < 0:
		return
	var result_piece: GemPiece = null
	for piece in pieces:
		if piece.id == result_id and not piece.consumed:
			result_piece = piece
			break
	if result_piece == null:
		return
	# The actual confirmed merge result has already finished its presentation.
	# Remove it from the live simulation *before* its separate visual travels to
	# the HUD. Keeping a consumed RefCounted item in `pieces` used to leave a
	# stale body available to future contact/occupancy paths.
	result_piece.consumed = true
	pieces.erase(result_piece)
	danger_timers.erase(result_id)
	merge_service.clear()
	collection_in_progress = true
	active_piece_id = -1
	launcher_state = LauncherState.RESOLVING
	var sprite := Sprite2D.new()
	var entry := AssetCatalogType.gem_entry(result_piece.level)
	sprite.texture = entry.texture
	sprite.position = result_piece.position
	var diameter := result_piece.radius * 2.0 * float(GameConfig.GEM_VISUAL_BODY_SCALE.get(result_piece.level, 1.0))
	sprite.scale = Vector2(diameter / sprite.texture.get_size().x, diameter / sprite.texture.get_size().y)
	# Godot canvas z is bounded; this stays above the live gem layer (10)
	# without exceeding the engine's maximum canvas z range.
	sprite.z_index = 4090
	gem_sprite_layer.add_child(sprite)
	target_collection = {"result_id": result_id, "level": result_piece.level, "sprite": sprite, "start": result_piece.position, "elapsed": 0.0}

func _update_target_collection(delta: float) -> void:
	if not collection_in_progress:
		return
	var sprite: Sprite2D = target_collection.get("sprite")
	if sprite == null:
		_finish_target_collection()
		return
	var elapsed := float(target_collection.get("elapsed", 0.0)) + delta
	target_collection.elapsed = elapsed
	var duration := 0.48
	var t := clampf(elapsed / duration, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 3.0)
	var start: Vector2 = target_collection.start
	var destination := GameConfig.TARGET_PANEL_RECT.get_center() + Vector2(-58.0, 0.0)
	sprite.position = start.lerp(destination, eased)
	var pop := 1.0 + sin(clampf(t * 2.0, 0.0, 1.0) * PI) * 0.20
	# Keep a deterministic base scale instead of accumulating the pop each frame.
	var level := int(target_collection.level)
	var base_diameter := GameConfig.gem_collision_radius(level) * GameConfig.gem_perspective_scale_at(start.y) * 2.0 * float(GameConfig.GEM_VISUAL_BODY_SCALE.get(level, 1.0))
	sprite.scale = Vector2(base_diameter / sprite.texture.get_size().x, base_diameter / sprite.texture.get_size().y) * pop
	sprite.modulate = Color(1.0, 1.0, 1.0, 1.0 - t)
	if t >= 1.0:
		_finish_target_collection()

func _finish_target_collection() -> void:
	var sprite: Sprite2D = target_collection.get("sprite")
	if sprite != null:
		sprite.queue_free()
	target_collection.clear()
	collection_in_progress = false
	target_progress += 1
	if target_progress < active_target_quantity():
		return
	target_index += 1
	target_progress = 0
	if target_index >= target_sequence().size():
		_qualify_win_if_target_complete()

func _cancel_target_collection() -> void:
	var sprite: Sprite2D = target_collection.get("sprite")
	if sprite != null:
		sprite.queue_free()
	target_collection.clear()

func _qualify_win_if_target_complete() -> void:
	if target_index < target_sequence().size() or win_qualified:
		return
	won = true
	win_qualified = true
	win_presented = false
	win_hold_elapsed = 0.0
	active_piece_id = -1
	launcher_state = LauncherState.RESOLVING

func _update_win_presentation(delta: float) -> void:
	# The Diamond must have been synchronized and its merge pulse completed
	# before the dedicated UI layer can present victory.
	if win_presented or not merge_presentations.is_empty():
		return
	win_hold_elapsed += delta
	if win_hold_elapsed >= GameConfig.WIN_PRESENTATION_HOLD:
		win_presented = true
		result_overlay.present(true, score)
		audio_feedback.emit_event("win")
		haptics_feedback.emit_event("win")

func _route_collision_feedback() -> void:
	for impact in simulation.consume_collision_impacts():
		if debug_calibration_enabled and impact.has("position"):
			debug_contact_points.append({"position": impact.position, "age": 0.0})
		var kind := String(impact.get("kind", "gem"))
		var strength := float(impact.get("strength", 0.0))
		if kind == "wall":
			if strength >= GameConfig.WALL_CONTACT_SOUND_THRESHOLD:
				audio_feedback.emit_event("wall_contact", clampf(strength / GameConfig.LAUNCH_SPEED, 0.30, 0.75))
		elif strength >= GameConfig.GEM_CONTACT_SOUND_THRESHOLD:
			audio_feedback.emit_event("gem_contact", clampf(strength / GameConfig.LAUNCH_SPEED, 0.35, 1.0))

func _draw() -> void:
	# The supplied artwork is drawn by Sprite2D nodes. This dynamic line is kept
	# above the clean table art so it always shares the authoritative rail bounds.
	draw_dashed_line(Vector2(GameConfig.table_left_at(GameConfig.DANGER_LINE_Y) + 8.0, GameConfig.DANGER_LINE_Y), Vector2(GameConfig.table_right_at(GameConfig.DANGER_LINE_Y) - 8.0, GameConfig.DANGER_LINE_Y), Color("f6bb42"), 3.0, 12.0)
	var font := ThemeDB.fallback_font
	HudRendererType.draw(self, hud_snapshot(), font)
	# Draw the non-physical source ghosts first. The new simulated gem is then
	# rendered over them, avoiding a one-frame visual pop at the merge midpoint.
	for presentation in merge_presentations:
		_draw_merge_presentation(presentation)
	if debug_calibration_enabled:
		_draw_calibration_debug(font)

func _draw_calibration_debug(font: Font) -> void:
	var left_top := Vector2(GameConfig.table_left_at(GameConfig.BOARD_TOP), GameConfig.BOARD_TOP)
	var right_top := Vector2(GameConfig.table_right_at(GameConfig.BOARD_TOP), GameConfig.BOARD_TOP)
	var left_bottom := Vector2(GameConfig.table_left_at(GameConfig.BOARD_BOTTOM), GameConfig.BOARD_BOTTOM)
	var right_bottom := Vector2(GameConfig.table_right_at(GameConfig.BOARD_BOTTOM), GameConfig.BOARD_BOTTOM)
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
	var t: float = clampf(presentation.elapsed / GameConfig.MERGE_PRESENTATION_DURATION, 0.0, 1.0)
	var pull_t: float = clampf(presentation.elapsed / GameConfig.MERGE_SOURCE_PULL_DURATION, 0.0, 1.0)
	var midpoint: Vector2 = presentation.midpoint
	var source_scale := 1.0 - pull_t * 0.75
	var source_alpha := 1.0 - pull_t
	for source_position in [presentation.first_position, presentation.second_position]:
		var position: Vector2 = source_position.lerp(midpoint, pull_t * 0.72)
		GemVisualsType.draw_gem(self, presentation.level - 1, position, GameConfig.PIECE_RADIUS, source_alpha, source_scale)
	var ring_alpha := 1.0 - t
	var ring_color := GameConfig.gem_color(presentation.level).lightened(0.35)
	ring_color.a = ring_alpha
	draw_arc(midpoint, GameConfig.PIECE_RADIUS * (1.0 + t * 1.15), 0.0, TAU, 28, ring_color, 3.0)
	# Ease the visual pulse only; presentation never affects live gem geometry.
	var eased_t := 1.0 - pow(1.0 - t, 3.0)
	var pulse := 1.0 + sin(eased_t * PI) * (GameConfig.MERGE_PULSE_SCALE - 1.0)
	var glow := GameConfig.gem_color(presentation.level)
	glow.a = (1.0 - t) * 0.35
	draw_circle(midpoint, GameConfig.PIECE_RADIUS * pulse, glow)
