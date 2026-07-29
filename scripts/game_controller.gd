extends Node2D

const GemVisualsType = preload("res://scripts/gem_visuals.gd")
const HudRendererType = preload("res://scripts/hud_renderer.gd")
const AudioFeedbackServiceType = preload("res://scripts/audio_feedback_service.gd")
const HapticsServiceType = preload("res://scripts/haptics_service.gd")
const AssetCatalogType = preload("res://scripts/asset_catalog.gd")
const GemSpriteLayerType = preload("res://scripts/gem_sprite_layer.gd")

var pieces: Array[GemPiece] = []
var simulation := BoardSimulation.new()
var merge_service := ContactMergeService.new()
var next_piece_id := 1
var next_level := 1
var active_piece_id := -1
var shot_count := 0
var dragging := false
var merge_presentations: Array[Dictionary] = []
var score := 0
var chain_multiplier := 1
var danger_timers: Dictionary = {}
var won := false
var failed := false
var ready_delay_elapsed := 0.0
var audio_feedback: Node
var haptics_feedback: RefCounted
var gem_sprite_layer: GemSpriteLayer

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
	_setup_asset_presentation()
	audio_feedback = AudioFeedbackServiceType.new()
	haptics_feedback = HapticsServiceType.new()
	add_child(audio_feedback)
	_advance_launcher_lifecycle()
	gem_sprite_layer.sync_gems(pieces)
	queue_redraw()

func _process(delta: float) -> void:
	if won or failed:
		_update_merge_presentations(delta)
		queue_redraw()
		return
	simulation.step(pieces, delta, merge_service)
	_route_collision_feedback()
	var result := merge_service.resolve(pieces, next_piece_id)
	pieces = result.pieces
	next_piece_id = result.next_id
	_apply_confirmed_merge_events(result.presentation_events)
	_update_merge_presentations(delta)
	_update_danger_timers(delta)
	if won or failed:
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
		"current_level": active.level if active != null else next_level,
		"next_level": next_level,
		"score": score,
		"chain_multiplier": chain_multiplier,
		"shot_count": shot_count,
		"target_level": GameConfig.TARGET_LEVEL,
		"highest_level": highest_level,
		"sound_enabled": audio_feedback.enabled if audio_feedback != null else true,
		"vibration_enabled": haptics_feedback.enabled,
	}

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_pointer(event.position, event.pressed)
	elif event is InputEventScreenDrag and dragging:
		move_active_to(event.position.x)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_pointer(event.position, event.pressed)
	elif event is InputEventMouseMotion and dragging:
		move_active_to(event.position.x)

func _handle_pointer(pointer: Vector2, pressed: bool) -> void:
	if won or failed:
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
		var active := get_active_piece()
		if launcher_state == LauncherState.READY_TO_AIM and active != null and active.is_settled() and pointer.distance_to(active.position) <= active.radius * GameConfig.DRAG_HIT_RADIUS_MULTIPLIER:
			dragging = true
			move_active_to(pointer.x)
	elif dragging:
		dragging = false
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
		shot_count += 1
		launcher_state = LauncherState.SHOT_IN_FLIGHT

func spawn_active_piece() -> bool:
	# Idempotent for a lifecycle cycle: an existing launcher is never replaced.
	if get_active_piece() != null:
		return false
	var piece := GemPiece.new(next_piece_id, next_level, Vector2(360.0, GameConfig.LAUNCH_Y), GameConfig.PIECE_RADIUS)
	next_piece_id += 1
	piece.is_active_launcher = true
	pieces.append(piece)
	active_piece_id = piece.id
	next_level = 2 if next_level == 1 else 1
	return true

func get_active_piece() -> GemPiece:
	for piece in pieces:
		if piece.id == active_piece_id and piece.is_active_launcher and not piece.consumed:
			return piece
	return null

func all_pieces_settled() -> bool:
	for piece in pieces:
		if piece.is_moving():
			return false
	return true

func restart() -> void:
	pieces.clear()
	merge_service.clear()
	merge_presentations.clear()
	next_piece_id = 1
	next_level = 1
	active_piece_id = -1
	shot_count = 0
	score = 0
	chain_multiplier = 1
	danger_timers.clear()
	won = false
	failed = false
	dragging = false
	launcher_state = LauncherState.SPAWNING_NEXT
	ready_delay_elapsed = 0.0
	_advance_launcher_lifecycle()
	if gem_sprite_layer != null:
		gem_sprite_layer.sync_gems(pieces)

func _setup_asset_presentation() -> void:
	var background := Sprite2D.new()
	background.texture = AssetCatalogType.TROPICAL_BACKGROUND
	background.position = GameConfig.VIEWPORT_SIZE * 0.5
	background.scale = Vector2(GameConfig.VIEWPORT_SIZE.x / background.texture.get_size().x, GameConfig.VIEWPORT_SIZE.y / background.texture.get_size().y)
	background.z_index = -20
	add_child(background)
	var table := Sprite2D.new()
	table.texture = AssetCatalogType.CORAL_TABLE
	table.position = GameConfig.TABLE_TEXTURE_CENTER
	table.z_index = -10
	add_child(table)
	gem_sprite_layer = GemSpriteLayerType.new()
	gem_sprite_layer.z_index = 10
	add_child(gem_sprite_layer)

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
		if result_level == GameConfig.TARGET_LEVEL and not won:
			won = true
			active_piece_id = -1
			launcher_state = LauncherState.RESOLVING
			audio_feedback.emit_event("win")
			haptics_feedback.emit_event("win")
		resolution_multiplier += 1

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
				return
		else:
			danger_timers.erase(piece.id)
	for id in danger_timers.keys():
		if not live_ids.has(id):
			danger_timers.erase(id)

func _update_merge_presentations(delta: float) -> void:
	for presentation in merge_presentations:
		presentation.elapsed += delta
	merge_presentations = merge_presentations.filter(func(presentation: Dictionary) -> bool: return presentation.elapsed < GameConfig.MERGE_PRESENTATION_DURATION)

func _route_collision_feedback() -> void:
	for impact in simulation.consume_collision_impacts():
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
	if won or failed:
		_draw_result_overlay(font)

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

func _draw_result_overlay(font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, GameConfig.VIEWPORT_SIZE), Color(0.02, 0.02, 0.05, 0.48), true)
	draw_rect(GameConfig.OVERLAY_RECT, Color("1b1427", 0.97), true)
	draw_rect(GameConfig.OVERLAY_RECT, Color("f1cd78"), false, 3.0)
	var title := "You created a Diamond!" if won else "Table overflowed"
	var button := "Replay" if won else "Retry"
	draw_string(font, Vector2(132.0, 548.0), title, HORIZONTAL_ALIGNMENT_CENTER, 456.0, 33, Color.WHITE)
	draw_string(font, Vector2(132.0, 612.0), "Score: %d" % score, HORIZONTAL_ALIGNMENT_CENTER, 456.0, 26, Color("fff0bb"))
	draw_rect(GameConfig.OVERLAY_BUTTON_RECT, Color("5a3f68"), true)
	draw_rect(GameConfig.OVERLAY_BUTTON_RECT, Color("d8b46d"), false, 2.0)
	draw_string(font, Vector2(220.0, 811.0), button, HORIZONTAL_ALIGNMENT_CENTER, 280.0, 24, Color.WHITE)

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
