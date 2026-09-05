extends SceneTree

## Renders the popups that now carry the mascot, so the expression, the size and
## the shared half-out title plate can be reviewed without a device.

const GameScene := preload("res://scenes/Game.tscn")
const OUTPUT_DIR := "res://reports/mascot-popups-v1"
const RESOLUTION := Vector2i(720, 1440)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await _capture("result-win", func(c):
		_enter_play(c)
		c.result_overlay.present(true, 1200, 6, 8, 420, true))
	await _capture("result-fail", func(c):
		_enter_play(c)
		c.result_overlay.present(false, 800, 6, 8, 0, false))
	await _capture("briefing", func(c):
		_enter_play(c)
		c.level_briefing.present({
		"title": "LIMITED SHOTS", "badge": "timer",
		"body": "This level gives you only 12 shots.\n\nEvery gem you drop uses one.",
		"action": "START"}))
	await _capture("hud", func(c):
		c._on_home_level_intro_requested()
		c._on_level_chosen(c.highest_level)
		c._on_home_play_requested()
		c.gameplay_ui.react_to_combo(3))
	print("MASCOT_POPUPS_V1_CAPTURE: PASS")
	quit(0)


func _capture(name: String, action: Callable) -> void:
	var viewport := SubViewport.new()
	viewport.size = RESOLUTION
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var controller = GameScene.instantiate()
	viewport.add_child(controller)
	await process_frame
	action.call(controller)
	# Let the entrance tween and the mascot glide settle before the frame.
	for _i in range(50):
		await process_frame
	viewport.get_texture().get_image().save_png("%s/%s.png" % [OUTPUT_DIR, name])
	print("captured %s" % name)
	viewport.queue_free()
	await process_frame


## Home sits on a higher canvas layer than the result overlay, so a popup
## presented from the Home screen renders behind it. Every popup capture has to
## reach live gameplay first.
func _enter_play(controller) -> void:
	controller._on_home_level_intro_requested()
	controller._on_level_chosen(controller.highest_level)
	controller._on_home_play_requested()
