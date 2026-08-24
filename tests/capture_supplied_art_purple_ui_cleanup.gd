extends SceneTree

const GameScene = preload("res://scenes/Game.tscn")
const AssetCatalogType = preload("res://scripts/core/asset_catalog.gd")
const LevelConfigType = preload("res://scripts/core/level_config.gd")
const OUTPUT_DIR := "res://reports/supplied-art-purple-ui-cleanup-v1/screenshots/"
const RESOLUTIONS: Array[Vector2i] = [Vector2i(720, 1280), Vector2i(720, 1600)]
const TABLE_INDICES: Array[int] = [0, 4, 9]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for resolution in RESOLUTIONS:
		for table_index in TABLE_INDICES:
			await _capture_resolution(resolution, table_index)
	print("SUPPLIED_ART_PURPLE_UI_CAPTURE: PASS")
	quit(0)


func _capture_resolution(resolution: Vector2i, table_index: int) -> void:
	var viewport := SubViewport.new()
	viewport.name = "TableContainment_%dx%d_T%d" % [resolution.x, resolution.y, table_index + 1]
	viewport.size = resolution
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	var controller = GameScene.instantiate()
	viewport.add_child(controller)
	await process_frame
	controller.level_number = 1
	controller.level_seed = LevelConfigType.seed_for_level(1)
	controller.restart()
	controller._on_home_level_intro_requested()
	controller._on_home_play_requested()
	controller.set_process(false)
	controller.table_sprite.texture = AssetCatalogType.table_texture(table_index)
	controller._refresh_background_fill()
	_add_rail_edge_proof_pieces(controller)
	controller._sync_gems_and_mark_visibility()
	controller._refresh_hud()
	controller.queue_redraw()
	await process_frame
	await create_timer(0.25, true, false, true).timeout
	await RenderingServer.frame_post_draw
	var destination := OUTPUT_DIR + "%dx%d-table-%02d.png" % [resolution.x, resolution.y, table_index + 1]
	var error := viewport.get_texture().get_image().save_png(destination)
	if error != OK:
		push_error("Unable to save containment proof %s (error %d)" % [destination, error])
	viewport.queue_free()
	await process_frame


func _add_rail_edge_proof_pieces(controller) -> void:
	controller.pieces.clear()
	controller.active_piece_id = -1
	var proof_rows := [GameConfig.board_top() + 72.0, GameConfig.danger_line_y()]
	var proof_id := 9000
	for row_index in range(proof_rows.size()):
		var y_position: float = proof_rows[row_index]
		for side in [-1, 1]:
			var level := 8 - row_index
			var radius := GameConfig.gem_collision_radius(level) * GameConfig.gem_perspective_scale_at(y_position)
			var x_position := GameConfig.table_left_at(y_position) + radius if side < 0 else GameConfig.table_right_at(y_position) - radius
			var piece := GemPiece.new(proof_id, level, Vector2(x_position, y_position), GameConfig.gem_collision_radius(level))
			controller.pieces.append(piece)
			proof_id += 1
