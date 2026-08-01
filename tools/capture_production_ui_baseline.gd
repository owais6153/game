extends SceneTree

## Development-only baseline capture used by the production UI finalization
## milestone. This script never joins the runtime scene or export package.
const GameScene = preload("res://scenes/Game.tscn")
const GemPieceType = preload("res://scripts/gem_piece.gd")
const OUTPUT_DIR := "res://reports/production-ui-finalization-v1/baseline-current-ui/"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var controller = GameScene.instantiate()
	root.add_child(controller)
	await process_frame
	controller.set_process(false)
	controller._refresh_hud()
	await _capture("gameplay-empty-score-0.png")

	controller.score = 9999
	controller._refresh_hud()
	await _capture("gameplay-score-9999.png")
	controller.score = 12550000
	controller._refresh_hud()
	await _capture("gameplay-score-12-5m.png")

	controller._on_settings_requested()
	await _capture("pause-popup.png")
	controller._on_resume_requested()

	controller.restart()
	controller.set_process(false)
	controller.target_index = 1
	controller._refresh_hud()
	await _capture("second-target.png")

	controller.result_overlay.present(true, 4720)
	await _capture("win-popup.png")
	controller.result_overlay.dismiss()
	controller.result_overlay.present(false, 4720)
	await _capture("fail-popup.png")
	controller.result_overlay.dismiss()

	controller.restart()
	controller.set_process(false)
	controller.pieces.clear()
	controller.active_piece_id = -1
	for index in range(20):
		var column := index % 5
		var row := index / 5
		var level := (index % 6) + 1
		controller.pieces.append(GemPieceType.new(9000 + index, level, Vector2(176.0 + column * 92.0, GameConfig.board_top() + 300.0 + row * 92.0), GameConfig.gem_collision_radius(level)))
	controller.gem_sprite_layer.sync_gems(controller.pieces)
	controller._refresh_hud()
	controller.queue_redraw()
	await _capture("gameplay-crowded.png")

	print("PRODUCTION_UI_BASELINE_CAPTURE: PASS")
	quit(0)


func _capture(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(OUTPUT_DIR + filename)
	if error != OK:
		push_error("Unable to save baseline evidence %s (error %d)" % [filename, error])
