extends Node2D

var pieces: Array[GemPiece] = []
var simulation := BoardSimulation.new()
var merge_service := ContactMergeService.new()
var next_piece_id := 1
var next_level := 1
var active_piece_id := -1
var shot_count := 0
var dragging := false
var merge_presentations: Array[Dictionary] = []

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
	_advance_launcher_lifecycle()
	queue_redraw()

func _process(delta: float) -> void:
	simulation.step(pieces, delta, merge_service)
	var result := merge_service.resolve(pieces, next_piece_id)
	pieces = result.pieces
	next_piece_id = result.next_id
	for merge_event in result.presentation_events:
		merge_event.elapsed = 0.0
		merge_presentations.append(merge_event)
	_update_merge_presentations(delta)
	if result.merge_count > 0:
		if get_active_piece() == null:
			active_piece_id = -1
		if launcher_state != LauncherState.READY_TO_AIM:
			launcher_state = LauncherState.RESOLVING
	_advance_launcher_lifecycle()
	queue_redraw()

func _advance_launcher_lifecycle() -> void:
	match launcher_state:
		LauncherState.SHOT_IN_FLIGHT:
			if all_pieces_settled():
				var active := get_active_piece()
				if active != null:
					active.is_active_launcher = false
					active_piece_id = -1
				launcher_state = LauncherState.RESOLVING
		LauncherState.RESOLVING:
			if all_pieces_settled() and not merge_service.has_pending_candidates() and merge_presentations.is_empty():
				launcher_state = LauncherState.SPAWNING_NEXT
		LauncherState.SPAWNING_NEXT:
			if all_pieces_settled() and spawn_active_piece():
				launcher_state = LauncherState.READY_TO_AIM

func lifecycle_name() -> String:
	return LauncherState.keys()[launcher_state]

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
	if pressed:
		if GameConfig.RESTART_RECT.has_point(pointer):
			restart()
			return
		var active := get_active_piece()
		if launcher_state == LauncherState.READY_TO_AIM and active != null and active.is_settled() and pointer.distance_to(active.position) <= active.radius * 1.8:
			dragging = true
			move_active_to(pointer.x)
	elif dragging:
		dragging = false
		launch_active_piece()

func move_active_to(x_position: float) -> void:
	var active := get_active_piece()
	if launcher_state == LauncherState.READY_TO_AIM and active != null and active.is_settled():
		active.position.x = clampf(x_position, GameConfig.BOARD_LEFT + active.radius, GameConfig.BOARD_RIGHT - active.radius)

func launch_active_piece() -> void:
	var active := get_active_piece()
	if launcher_state == LauncherState.READY_TO_AIM and active != null and active.is_settled():
		active.velocity = Vector2(0.0, -GameConfig.LAUNCH_SPEED)
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
	dragging = false
	launcher_state = LauncherState.SPAWNING_NEXT
	_advance_launcher_lifecycle()

func _update_merge_presentations(delta: float) -> void:
	for presentation in merge_presentations:
		presentation.elapsed += delta
	merge_presentations = merge_presentations.filter(func(presentation: Dictionary) -> bool: return presentation.elapsed < GameConfig.MERGE_PRESENTATION_DURATION)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, GameConfig.VIEWPORT_SIZE), Color("132337"))
	draw_rect(Rect2(GameConfig.BOARD_LEFT, GameConfig.BOARD_TOP, GameConfig.BOARD_RIGHT - GameConfig.BOARD_LEFT, GameConfig.BOARD_BOTTOM - GameConfig.BOARD_TOP), Color("274864"), true)
	draw_line(Vector2(GameConfig.BOARD_LEFT, GameConfig.BOARD_TOP), Vector2(GameConfig.BOARD_RIGHT, GameConfig.BOARD_TOP), Color("d5e8f3"), 6.0)
	draw_line(Vector2(GameConfig.BOARD_LEFT, GameConfig.BOARD_TOP), Vector2(GameConfig.BOARD_LEFT, GameConfig.BOARD_BOTTOM), Color("d5e8f3"), 6.0)
	draw_line(Vector2(GameConfig.BOARD_RIGHT, GameConfig.BOARD_TOP), Vector2(GameConfig.BOARD_RIGHT, GameConfig.BOARD_BOTTOM), Color("d5e8f3"), 6.0)
	draw_dashed_line(Vector2(GameConfig.BOARD_LEFT + 8.0, GameConfig.DANGER_LINE_Y), Vector2(GameConfig.BOARD_RIGHT - 8.0, GameConfig.DANGER_LINE_Y), Color("f6bb42"), 3.0, 12.0)
	var font := ThemeDB.fallback_font
	var active := get_active_piece()
	var current_label := GameConfig.gem_name(active.level) if active != null else "Resolving"
	draw_string(font, Vector2(54.0, 92.0), "Current: %s" % current_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color.WHITE)
	draw_string(font, Vector2(54.0, 124.0), "Next: %s    Shots: %d" % [GameConfig.gem_name(next_level), shot_count], HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("d9e8f3"))
	draw_rect(GameConfig.RESTART_RECT, Color("3b6689"), true)
	draw_string(font, Vector2(542.0, 94.0), "Restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color.WHITE)
	for piece in pieces:
		draw_circle(piece.position + Vector2(4.0, 6.0), piece.radius, Color(0.02, 0.05, 0.08, 0.35))
		draw_circle(piece.position, piece.radius, GameConfig.gem_color(piece.level))
		draw_arc(piece.position, piece.radius, 0.0, TAU, 32, Color.WHITE.lightened(0.15), 2.0)
		draw_string(font, piece.position + Vector2(-12.0, 8.0), "L%d" % piece.level, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("172334"))
	for presentation in merge_presentations:
		_draw_merge_presentation(presentation)

func _draw_merge_presentation(presentation: Dictionary) -> void:
	var t: float = clampf(presentation.elapsed / GameConfig.MERGE_PRESENTATION_DURATION, 0.0, 1.0)
	var pull_t: float = clampf(presentation.elapsed / GameConfig.MERGE_SOURCE_PULL_DURATION, 0.0, 1.0)
	var midpoint: Vector2 = presentation.midpoint
	var source_scale := 1.0 - pull_t * 0.75
	var source_alpha := 1.0 - pull_t
	for source_position in [presentation.first_position, presentation.second_position]:
		var position: Vector2 = source_position.lerp(midpoint, pull_t * 0.72)
		var color := GameConfig.gem_color(presentation.level - 1)
		color.a = source_alpha
		draw_circle(position, GameConfig.PIECE_RADIUS * source_scale, color)
	var ring_alpha := 1.0 - t
	var ring_color := GameConfig.gem_color(presentation.level).lightened(0.35)
	ring_color.a = ring_alpha
	draw_arc(midpoint, GameConfig.PIECE_RADIUS * (1.0 + t * 1.15), 0.0, TAU, 28, ring_color, 3.0)
	var pulse := 1.0 + sin(t * PI) * (GameConfig.MERGE_PULSE_SCALE - 1.0)
	var glow := GameConfig.gem_color(presentation.level)
	glow.a = (1.0 - t) * 0.35
	draw_circle(midpoint, GameConfig.PIECE_RADIUS * pulse, glow)
