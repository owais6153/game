extends SceneTree

## Development-only render proof for the table/Target/merge-path hierarchy fix.
const GameScene = preload("res://scenes/Game.tscn")
const OUTPUT_DIR := "res://reports/target-path-hierarchy-fix/final-screenshots/"
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(720, 1280),
	Vector2i(720, 1600),
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for resolution in RESOLUTIONS:
		await _capture_resolution(resolution)
	print("TARGET_PATH_HIERARCHY_CAPTURE: PASS")
	quit(0)


func _capture_resolution(resolution: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.name = "TargetPathCapture_%dx%d" % [resolution.x, resolution.y]
	viewport.size = resolution
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	var controller = GameScene.instantiate()
	viewport.add_child(controller)
	await process_frame
	await process_frame
	controller.set_process(false)
	controller._refresh_hud()
	controller.queue_redraw()
	await create_timer(0.28, true, false, true).timeout
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var destination := OUTPUT_DIR + "%dx%d-gameplay.png" % [resolution.x, resolution.y]
	var error := image.save_png(destination)
	if error != OK:
		push_error("Unable to save hierarchy proof %s (error %d)" % [destination, error])
	viewport.queue_free()
	await process_frame
