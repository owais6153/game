extends SceneTree

## Fast, exact reproduction of the reported 576x1312 HUD state. This is kept
## separate from the full evidence sweep so visual iteration stays deliberate.
const GameScene = preload("res://scenes/Game.tscn")
const GemPieceType = preload("res://scripts/gem_piece.gd")
const OUTPUT := "res://reports/production-ui-polish-v4/576x1312/screenshot-reproduction-score-1300.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1640)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	var controller = GameScene.instantiate()
	viewport.add_child(controller)
	await process_frame
	await process_frame
	controller.set_process(false)
	controller.pieces.clear()
	controller.active_piece_id = -1
	var levels: Array[int] = [5, 2, 2, 3, 5, 1, 1]
	var positions: Array[Vector2] = [
		Vector2(215.0, GameConfig.board_top() + 120.0),
		Vector2(292.0, GameConfig.board_top() + 122.0),
		Vector2(375.0, GameConfig.board_top() + 157.0),
		Vector2(456.0, GameConfig.board_top() + 157.0),
		Vector2(518.0, GameConfig.board_top() + 124.0),
		Vector2(319.0, GameConfig.board_top() + 205.0),
		Vector2(360.0, GameConfig.launch_y()),
	]
	for index in range(7):
		var level: int = levels[index]
		controller.pieces.append(GemPieceType.new(9200 + index, level, positions[index], GameConfig.gem_collision_radius(level)))
	controller.gem_sprite_layer.sync_gems(controller.pieces)
	var snapshot: Dictionary = controller.hud_snapshot()
	snapshot.score = 1300
	snapshot.current_level = 4
	snapshot.highest_level = 5
	snapshot.next_level = 2
	snapshot.target_level = 7
	snapshot.target_progress = 0
	snapshot.target_quantity = 1
	snapshot.target_index = 0
	snapshot.target_total = 2
	controller.gameplay_ui.update_snapshot(snapshot)
	controller.queue_redraw()
	await create_timer(0.36, true, false, true).timeout
	await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	image.resize(576, 1312, Image.INTERPOLATE_LANCZOS)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var error := image.save_png(OUTPUT)
	if error != OK:
		push_error("Unable to save corrective preview (error %d)" % error)
		quit(1)
		return
	print("UI_CORRECTIVE_PREVIEW: PASS")
	quit(0)
