extends SceneTree

const GameScene = preload("res://scenes/Game.tscn")
const LevelConfigType = preload("res://scripts/core/level_config.gd")
const OUTPUT_DIR := "res://reports/regenerated-scene-art-integration-v1/scene-screenshots/"
const RESOLUTIONS: Array[Vector2i] = [Vector2i(720, 1280), Vector2i(720, 1600)]
const LEVELS: Array[int] = [1, 7, 19]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for resolution in RESOLUTIONS:
		for level_number in LEVELS:
			await _capture_resolution(resolution, level_number)
	print("RESPONSIVE_SCENE_VARIETY_CAPTURE: PASS")
	quit(0)


func _capture_resolution(resolution: Vector2i, level_number: int) -> void:
	var viewport := SubViewport.new()
	viewport.name = "SceneVariety_%dx%d_L%d" % [resolution.x, resolution.y, level_number]
	viewport.size = resolution
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	var controller = GameScene.instantiate()
	viewport.add_child(controller)
	await process_frame
	controller.level_number = level_number
	controller.level_seed = LevelConfigType.seed_for_level(level_number)
	controller.restart()
	controller.set_process(false)
	controller._refresh_background_fill()
	controller._refresh_hud()
	controller.queue_redraw()
	await process_frame
	await create_timer(0.25, true, false, true).timeout
	await RenderingServer.frame_post_draw
	var config: Dictionary = controller.level_config
	var destination := OUTPUT_DIR + "%dx%d-level-%02d-bg-%02d-table-%02d.png" % [
		resolution.x,
		resolution.y,
		level_number,
		int(config.get("background_index", 0)) + 1,
		int(config.get("table_index", 0)) + 1,
	]
	var error := viewport.get_texture().get_image().save_png(destination)
	if error != OK:
		push_error("Unable to save responsive scene proof %s (error %d)" % [destination, error])
	viewport.queue_free()
	await process_frame
