extends SceneTree

const GameScene = preload("res://scenes/Game.tscn")
const OUTPUT_DIR := "res://reports/production-screen-flow-v1"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1600)
	viewport.disable_3d = true
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var game = GameScene.instantiate()
	viewport.add_child(game)
	await process_frame
	await process_frame
	game.gameplay_ui.hide()
	game.home_overlay.present(12, 125500)
	await _capture(viewport, "home-continue.png")
	game.home_overlay.dismiss()
	game.gameplay_ui.show()
	game.gameplay_ui.show_pause()
	await _capture(viewport, "pause.png")
	game.gameplay_ui.hide_pause(false)
	game.result_overlay.present(true, 125500, 12, 8)
	await _capture(viewport, "level-complete.png")
	game.result_overlay.dismiss()
	game.result_overlay.present(false, 125500, 12, 8)
	await _capture(viewport, "level-failed.png")
	print("PRODUCTION_SCREEN_FLOW_CAPTURE: PASS")
	quit(0)

func _capture(viewport: SubViewport, filename: String) -> void:
	await process_frame
	await process_frame
	var image := viewport.get_texture().get_image()
	var error := image.save_png("%s/%s" % [OUTPUT_DIR, filename])
	if error != OK:
		push_error("Failed to save %s: %s" % [filename, error_string(error)])
