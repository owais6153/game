extends Node2D

const GemVisualsType = preload("res://scripts/gem_visuals.gd")

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
	if won or failed:
		_update_merge_presentations(delta)
		queue_redraw()
		return
	simulation.step(pieces, delta, merge_service)
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
				chain_multiplier = 1

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
	if won or failed:
		if pressed and GameConfig.OVERLAY_BUTTON_RECT.has_point(pointer):
			restart()
		return
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
	score = 0
	chain_multiplier = 1
	danger_timers.clear()
	won = false
	failed = false
	dragging = false
	launcher_state = LauncherState.SPAWNING_NEXT
	_advance_launcher_lifecycle()

func _apply_confirmed_merge_events(events: Array[Dictionary]) -> void:
	var resolution_multiplier := 1
	for merge_event in events:
		var result_level: int = int(merge_event.level)
		chain_multiplier = resolution_multiplier
		score += GameConfig.merge_score_for_result_level(result_level) * chain_multiplier
		merge_event.elapsed = 0.0
		merge_presentations.append(merge_event)
		if result_level == GameConfig.TARGET_LEVEL and not won:
			won = true
			active_piece_id = -1
			launcher_state = LauncherState.RESOLVING
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

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, GameConfig.VIEWPORT_SIZE), Color("100d18"))
	draw_rect(Rect2(GameConfig.BOARD_LEFT - 9.0, GameConfig.BOARD_TOP - 9.0, GameConfig.BOARD_RIGHT - GameConfig.BOARD_LEFT + 18.0, GameConfig.BOARD_BOTTOM - GameConfig.BOARD_TOP + 18.0), Color("8b6b31"), true)
	draw_rect(Rect2(GameConfig.BOARD_LEFT, GameConfig.BOARD_TOP, GameConfig.BOARD_RIGHT - GameConfig.BOARD_LEFT, GameConfig.BOARD_BOTTOM - GameConfig.BOARD_TOP), Color("193b3b"), true)
	draw_rect(Rect2(GameConfig.BOARD_LEFT + 14.0, GameConfig.BOARD_TOP + 14.0, GameConfig.BOARD_RIGHT - GameConfig.BOARD_LEFT - 28.0, GameConfig.BOARD_BOTTOM - GameConfig.BOARD_TOP - 28.0), Color("214b46"), false, 3.0)
	draw_line(Vector2(GameConfig.BOARD_LEFT, GameConfig.BOARD_TOP), Vector2(GameConfig.BOARD_RIGHT, GameConfig.BOARD_TOP), Color("f6d77e"), 5.0)
	draw_line(Vector2(GameConfig.BOARD_LEFT, GameConfig.BOARD_TOP), Vector2(GameConfig.BOARD_LEFT, GameConfig.BOARD_BOTTOM), Color("d3a74c"), 5.0)
	draw_line(Vector2(GameConfig.BOARD_RIGHT, GameConfig.BOARD_TOP), Vector2(GameConfig.BOARD_RIGHT, GameConfig.BOARD_BOTTOM), Color("d3a74c"), 5.0)
	draw_dashed_line(Vector2(GameConfig.BOARD_LEFT + 8.0, GameConfig.DANGER_LINE_Y), Vector2(GameConfig.BOARD_RIGHT - 8.0, GameConfig.DANGER_LINE_Y), Color("f6bb42"), 3.0, 12.0)
	var font := ThemeDB.fallback_font
	var active := get_active_piece()
	var current_label := GameConfig.gem_name(active.level) if active != null else "Resolving"
	draw_rect(Rect2(30.0, 20.0, 660.0, 112.0), Color("201b2d"), true)
	draw_rect(Rect2(30.0, 20.0, 660.0, 112.0), Color("b9954a"), false, 2.0)
	draw_string(font, Vector2(52.0, 57.0), "CURRENT  %s" % current_label.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("fff4d5"))
	draw_string(font, Vector2(52.0, 88.0), "NEXT  %s     SHOTS  %d" % [GameConfig.gem_name(next_level).to_upper(), shot_count], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("d7e9df"))
	draw_string(font, Vector2(52.0, 116.0), "SCORE  %d     CHAIN x%d     TARGET  DIAMOND" % [score, chain_multiplier], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ffe6a1"))
	draw_rect(GameConfig.RESTART_RECT, Color("5a3f68"), true)
	draw_rect(GameConfig.RESTART_RECT, Color("d8b46d"), false, 2.0)
	draw_string(font, Vector2(542.0, 94.0), "Restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color.WHITE)
	# Draw the non-physical source ghosts first. The new simulated gem is then
	# rendered over them, avoiding a one-frame visual pop at the merge midpoint.
	for presentation in merge_presentations:
		_draw_merge_presentation(presentation)
	for piece in pieces:
		GemVisualsType.draw_shadow(self, piece.position, piece.radius)
		GemVisualsType.draw_gem(self, piece.level, piece.position, piece.radius)
	if won or failed:
		_draw_result_overlay(font)

func _draw_result_overlay(font: Font) -> void:
	draw_rect(Rect2(80.0, 420.0, 560.0, 470.0), Color("1b1427", 0.96), true)
	draw_rect(Rect2(80.0, 420.0, 560.0, 470.0), Color("f1cd78"), false, 3.0)
	var title := "You created a Diamond!" if won else "Table overflowed"
	var button := "Replay" if won else "Retry"
	draw_string(font, Vector2(142.0, 550.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color.WHITE)
	draw_string(font, Vector2(270.0, 615.0), "Score: %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("fff0bb"))
	draw_rect(GameConfig.OVERLAY_BUTTON_RECT, Color("5a3f68"), true)
	draw_string(font, Vector2(320.0, 812.0), button, HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color.WHITE)

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
	var pulse := 1.0 + sin(t * PI) * (GameConfig.MERGE_PULSE_SCALE - 1.0)
	var glow := GameConfig.gem_color(presentation.level)
	glow.a = (1.0 - t) * 0.35
	draw_circle(midpoint, GameConfig.PIECE_RADIUS * pulse, glow)
