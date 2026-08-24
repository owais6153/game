extends SceneTree

const GameScene = preload("res://scenes/Game.tscn")
const LevelConfigType = preload("res://scripts/core/level_config.gd")
const PieceType = preload("res://scripts/core/gem_piece.gd")
const OUTPUT_DIR := "res://reports/gem-pattern-feedback-v1/screenshots/"
const RESOLUTION := Vector2i(720, 1280)
const STEP := 1.0 / 60.0

var viewport: SubViewport
var display: TextureRect
var controller: Node2D
var next_id := 12000


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await _build_viewport()
	var samples := _pattern_sample_levels()
	for label in samples:
		await _load_level(int(samples[label]))
		_add_rail_contact_proofs()
		controller._sync_gems_and_mark_visibility()
		controller._refresh_hud()
		await _shoot("pattern-%s-level-%02d" % [label, int(samples[label])])
	await _capture_target_sequence()
	display.queue_free()
	viewport.queue_free()
	await process_frame
	print("GEM_PATTERN_FEEDBACK_V1_CAPTURE: PASS")
	quit(0)


func _build_viewport() -> void:
	viewport = SubViewport.new()
	viewport.size = RESOLUTION
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	display = TextureRect.new()
	display.texture = viewport.get_texture()
	display.size = Vector2(RESOLUTION)
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root.add_child(display)
	await process_frame


func _load_level(level_number: int) -> void:
	if controller != null:
		controller.queue_free()
		await process_frame
	controller = GameScene.instantiate()
	viewport.add_child(controller)
	await process_frame
	controller.level_number = level_number
	controller.level_seed = LevelConfigType.seed_for_level(level_number)
	controller.restart()
	controller._on_home_level_intro_requested()
	controller._on_home_play_requested()
	controller.set_process(false)
	paused = false
	await process_frame


func _pattern_sample_levels() -> Dictionary:
	var samples := {}
	for level_number in range(1, 81):
		var pattern := LevelConfigType.pattern_for_level(level_number)
		var family := String(pattern.family)
		var dominant := String(pattern.dominant)
		if family == "same_shape" and dominant == "circle" and not samples.has("shape-circle"):
			samples["shape-circle"] = level_number
		elif family == "same_shape" and dominant == "rounded_square" and not samples.has("shape-rounded-square"):
			samples["shape-rounded-square"] = level_number
		elif family == "same_color" and ["blue", "purple"].has(dominant) and not samples.has("color-cool"):
			samples["color-cool"] = level_number
		elif family == "same_color" and ["pink", "orange"].has(dominant) and not samples.has("color-warm"):
			samples["color-warm"] = level_number
		if samples.size() == 4:
			break
	return samples


func _add_rail_contact_proofs() -> void:
	controller.pieces.clear()
	controller.active_piece_id = -1
	var rows := [GameConfig.board_top() + 72.0, GameConfig.danger_line_y()]
	for row_index in range(rows.size()):
		var y: float = rows[row_index]
		for side in [-1, 1]:
			var tier := 8 - row_index
			var radius := GameConfig.gem_collision_radius(tier) * GameConfig.gem_perspective_scale_at(y)
			var x := GameConfig.table_left_at(y) + radius if side < 0 else GameConfig.table_right_at(y) - radius
			next_id += 1
			controller.pieces.append(PieceType.new(next_id, tier, Vector2(x, y), GameConfig.gem_collision_radius(tier)))


func _capture_target_sequence() -> void:
	await _load_level(1)
	controller.pieces.clear()
	controller.target_index = 0
	controller.presented_target_index = 0
	controller.target_progress = controller.active_target_quantity() - 1
	controller.presented_target_progress = controller.target_progress
	_merge_target(Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 260.0))
	await _advance(0.16)
	await _shoot("target-0160ms-three-ring-wave")
	await _advance(0.32)
	await _shoot("target-0480ms-settled-at-merge-point")
	await _advance(0.25)
	await _shoot("target-0730ms-moving-to-center")
	await _advance(0.35)
	await _shoot("target-1080ms-center-hold-and-table-coins")
	await _load_level(1)
	controller.pieces.clear()
	var sequence: Array = controller.target_sequence()
	controller.target_index = sequence.size() - 1
	controller.presented_target_index = controller.target_index
	controller.target_progress = controller.active_target_quantity() - 1
	controller.presented_target_progress = controller.target_progress
	_merge_target(Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 260.0))
	await _advance(3.0)
	await _shoot("final-target-four-coins-on-table")


func _merge_target(position: Vector2) -> void:
	next_id += 1
	var tier: int = controller.active_target_tier()
	controller.pieces.append(PieceType.new(next_id, tier, position, GameConfig.gem_collision_radius(tier)))
	var events: Array[Dictionary] = [{
		"result_id": next_id,
		"source_ids": [next_id + 10000, next_id + 20000],
		"level": tier,
		"first_position": position - Vector2(44.0, 0.0),
		"second_position": position + Vector2(44.0, 0.0),
		"midpoint": position,
		"depth": 0,
	}]
	controller._apply_confirmed_merge_events(events)


func _advance(seconds: float) -> void:
	var remaining := seconds
	while remaining > 0.0:
		controller._process(STEP)
		remaining -= STEP
	await process_frame


func _shoot(name: String) -> void:
	controller.queue_redraw()
	await create_timer(0.05, true, false, true).timeout
	await RenderingServer.frame_post_draw
	var error := viewport.get_texture().get_image().save_png(OUTPUT_DIR + name + ".png")
	if error != OK:
		push_error("Unable to save %s (error %d)" % [name, error])
