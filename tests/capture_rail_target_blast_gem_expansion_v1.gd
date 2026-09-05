extends SceneTree

const GameScene = preload("res://scenes/Game.tscn")
const LevelConfigType = preload("res://scripts/core/level_config.gd")
const PieceType = preload("res://scripts/core/gem_piece.gd")
const OUTPUT_DIR := "res://reports/rail-target-blast-gem-expansion-v1/screenshots/"
const RESOLUTION := Vector2i(720, 1280)
const STEP := 1.0 / 60.0

var viewport: SubViewport
var controller: Node2D
var next_id := 18000


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	viewport = SubViewport.new()
	viewport.size = RESOLUTION
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	await _load_level()
	await _capture_rail_and_new_gems()
	await _load_level()
	await _capture_target_wave_and_blast()
	viewport.queue_free()
	await process_frame
	print("RAIL_TARGET_BLAST_GEM_EXPANSION_V1_CAPTURE: PASS")
	quit(0)


func _load_level() -> void:
	if controller != null:
		controller.queue_free()
		await process_frame
	controller = GameScene.instantiate()
	viewport.add_child(controller)
	await process_frame
	controller.level_number = 1
	controller.level_seed = LevelConfigType.seed_for_level(1)
	controller.restart()
	controller._on_home_level_intro_requested()
	controller._on_level_chosen(controller.highest_level)
	controller._on_home_play_requested()
	controller.set_process(false)
	paused = false
	await process_frame


func _capture_rail_and_new_gems() -> void:
	var mapping: Dictionary = controller.level_config.gem_identity_by_tier.duplicate(true)
	mapping[7] = 33
	mapping[8] = 34
	AssetCatalog.set_active_level_mapping(mapping)
	controller.pieces.clear()
	controller.active_piece_id = -1
	var rows := [GameConfig.board_top() + GameConfig.gem_collision_radius(8), GameConfig.board_bottom() - GameConfig.gem_collision_radius(7)]
	for row_index in range(rows.size()):
		var y: float = rows[row_index]
		for side in [-1, 1]:
			var tier: int = 8 - row_index
			var radius := GameConfig.gem_collision_radius(tier) * GameConfig.gem_perspective_scale_at(y)
			var x := GameConfig.table_left_at(y) + radius if side < 0 else GameConfig.table_right_at(y) - radius
			next_id += 1
			controller.pieces.append(PieceType.new(next_id, tier, Vector2(x, y), GameConfig.gem_collision_radius(tier)))
	controller.debug_calibration_enabled = true
	controller._sync_gems_and_mark_visibility()
	controller._refresh_hud()
	await _shoot("measured-rails-and-alpha-tight-gems")


func _capture_target_wave_and_blast() -> void:
	var tier: int = int(controller.active_target_tier())
	var mapping: Dictionary = controller.level_config.gem_identity_by_tier.duplicate(true)
	mapping[tier] = 33
	AssetCatalog.set_active_level_mapping(mapping)
	controller.pieces.clear()
	controller.target_progress = controller.active_target_quantity() - 1
	controller.presented_target_progress = controller.target_progress
	var origin := Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 300.0)
	next_id += 1
	var result_id := next_id
	controller.pieces.append(PieceType.new(result_id, tier, origin, GameConfig.gem_collision_radius(tier)))
	for offset in [Vector2(-120.0, 45.0), Vector2(120.0, 45.0), Vector2(0.0, 145.0)]:
		next_id += 1
		controller.pieces.append(PieceType.new(next_id, 2, origin + offset, GameConfig.gem_collision_radius(2)))
	var events: Array[Dictionary] = [{
		"result_id": result_id,
		"source_ids": [result_id + 1000, result_id + 2000],
		"level": tier,
		"first_position": origin - Vector2(48.0, 0.0),
		"second_position": origin + Vector2(48.0, 0.0),
		"midpoint": origin,
		"depth": 0,
	}]
	controller._apply_confirmed_merge_events(events)
	await _advance(0.18)
	await _shoot("enlarged-target-five-ring-wave-and-blast")


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
