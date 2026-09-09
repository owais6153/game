extends SceneTree

## Renders the four screens the star system touches, so the objectives, the
## award row, the header total and the per-node rows can be reviewed without a
## device.
##
## Development only; nothing in the game loads it. Run:
##
##   godot --headless --path . --script tests/capture_level_stars_v1.gd

const GameScene := preload("res://scenes/Game.tscn")
const LevelStarsType = preload("res://scripts/core/level_stars.gd")
const LevelConfigType = preload("res://scripts/core/level_config.gd")
const OUTPUT_DIR := "res://reports/level-stars-v1"
const RESOLUTION := Vector2i(720, 1440)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var objectives := LevelStarsType.objectives_for(
		LevelConfigType.generated(5, LevelConfigType.seed_for_level(5)))

	# Level Ready: three objectives, all empty, as a first visit shows them.
	await _capture("level-ready-objectives", func(c):
		c._on_home_level_intro_requested()
		c._on_level_chosen(c.highest_level), 40)

	# Level Complete mid-sequence: two of three earned, caught while the row is
	# filling and COLLECT is still locked.
	await _capture("result-stars-awarding", func(c):
		_enter_play(c)
		c.result_overlay.present(true, 1200, 5, 8, 420, true, false, 0, false, 0, 0, "danger_line", {
			"objectives": objectives, "results": [true, false, true],
			"earned": 2, "previous": 0, "total": 2,
		}), 70)

	# The same popup once the sequence has finished and the actions have unlocked.
	await _capture("result-stars-settled", func(c):
		_enter_play(c)
		c.result_overlay.present(true, 1200, 5, 8, 420, true, false, 0, false, 0, 0, "danger_line", {
			"objectives": objectives, "results": [true, true, true],
			"earned": 3, "previous": 0, "total": 3,
		}), 220)

	# The level screen: header total plus per-node rows behind the player.
	await _capture("level-map-stars", func(c):
		c.level_select.present(6, 1500, [] as Array[int], {1: 3, 2: 2, 3: 3, 4: 1, 5: 2}), 40)

	print("LEVEL_STARS_V1_CAPTURE: PASS")
	quit(0)


func _capture(name: String, action: Callable, settle_frames: int) -> void:
	var viewport := SubViewport.new()
	viewport.size = RESOLUTION
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var controller = GameScene.instantiate()
	viewport.add_child(controller)
	await process_frame
	action.call(controller)
	# The star sequence is deliberately slow, so the settle budget is per-shot:
	# the mid-sequence frame has to be taken while the row is still filling.
	for _i in range(settle_frames):
		await process_frame
	viewport.get_texture().get_image().save_png("%s/%s.png" % [OUTPUT_DIR, name])
	print("captured %s" % name)
	viewport.queue_free()
	await process_frame


## Home sits on a higher canvas layer than the result overlay, so a popup
## presented from Home renders behind it. Every popup capture reaches live
## gameplay first.
func _enter_play(controller) -> void:
	controller._on_home_level_intro_requested()
	controller._on_level_chosen(controller.highest_level)
	controller._on_home_play_requested()
	# A first entry into a level type opens the How To Play briefing, which draws
	# over the result popup and hid the whole star row in an earlier capture.
	# It is unrelated to what these shots are proving, so it is closed here.
	if controller.level_briefing != null and controller.level_briefing.is_open():
		controller.level_briefing.dismiss()
