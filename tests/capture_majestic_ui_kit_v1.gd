extends SceneTree

## Visual proof sheet for the supplied-art UI kit pass. Renders every screen and
## popup the player can reach so the composition can be compared against
## `assets/ui_kit_source/mockup_home_screen.png`. Presentation only: no
## simulation, merge, launcher, or collision state is exercised here.

const GameScene = preload("res://scenes/Game.tscn")
const LevelConfigType = preload("res://scripts/core/level_config.gd")
const DailyMissionServiceType = preload("res://scripts/services/daily_mission_service.gd")
const OUTPUT_DIR := "res://reports/majestic-ui-kit-v1/screenshots/"
const RESOLUTIONS: Array[Vector2i] = [Vector2i(720, 1280), Vector2i(720, 1600)]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for resolution in RESOLUTIONS:
		await _capture_all(resolution)
	print("MAJESTIC_UI_KIT_CAPTURE: PASS")
	quit(0)


func _capture_all(resolution: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = resolution
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var controller = GameScene.instantiate()
	viewport.add_child(controller)
	await process_frame
	# A failed script load leaves a bare Node2D behind; without this the harness
	# happily reported PASS while every screenshot showed nothing.
	if not controller.has_method("hud_snapshot"):
		push_error("Game.tscn did not instantiate a GameController - script failed to load")
		quit(1)
		return
	controller.level_number = 3
	controller.level_seed = LevelConfigType.seed_for_level(3)
	controller.coins = 5200
	controller.restart()
	controller.set_process(false)

	# 1. Home, as the player first sees it.
	controller.home_overlay.present(3, 5200, controller.hud_snapshot())
	controller._refresh_hud()
	await _shot(viewport, resolution, "01-home")

	# 2. Daily missions showing all three states at once: claimed, ready to
	# claim, and still in progress.
	#
	# Built from a fresh roll rather than the loaded save. Mutating the saved
	# state let claims from an earlier capture run leak in, and the proof sheet
	# then showed every mission as DONE regardless of what this test set up.
	var state := DailyMissionServiceType.ensure_current_day({})
	var missions: Array = state.get("missions", []) as Array
	if missions.size() >= 3:
		missions[0]["progress"] = int(missions[0].get("target", 1))
		missions[0]["claimed"] = true
		missions[1]["progress"] = int(missions[1].get("target", 1))
		missions[1]["claimed"] = false
		missions[2]["progress"] = 0
		missions[2]["claimed"] = false
	state["missions"] = missions
	state["chest_claimed"] = false
	controller.daily_state = state
	controller.daily_overlay.present(state, 5200)
	await _shot(viewport, resolution, "02-daily-missions")
	controller.daily_overlay.dismiss()

	# 3. Gameplay HUD.
	controller.home_overlay.dismiss()
	controller._refresh_hud()
	await _shot(viewport, resolution, "03-gameplay-hud")

	# 4. Win result with a rewarded-ad offer.
	controller.result_overlay.present(true, 5200, 3, 8, 450, true, false, 0)
	await _shot(viewport, resolution, "04-result-win")
	controller.result_overlay.dismiss()

	# 5. Fail result offering both Continue and Skip.
	controller.result_overlay.present(false, 5200, 3, 8, 0, false, true, 800, true, 500, 5200)
	await _shot(viewport, resolution, "05-result-fail")
	controller.result_overlay.dismiss()

	# 6. Out-of-shots rescue.
	controller.result_overlay.present_out_of_shots(5200, 5, 300)
	await _shot(viewport, resolution, "06-out-of-shots")
	controller.result_overlay.dismiss()

	# 7. Limited-shots HUD: the counter panel, top-centre in the objective stack.
	controller.home_overlay.dismiss()
	controller.result_overlay.dismiss()
	controller.level_config["level_type"] = "limited_shots"
	controller.level_config["shot_limit"] = 36
	controller.shots_remaining = 12
	controller._refresh_hud()
	await _shot(viewport, resolution, "08-limited-shots-hud")

	# 8. First-time briefing for each level type.
	controller.level_briefing.present(controller._briefing_for_level_type("limited_shots"))
	await _shot(viewport, resolution, "09-briefing-limited-shots")
	controller.level_briefing.dismiss()
	await process_frame
	controller.level_briefing.present(controller._briefing_for_level_type("normal"))
	await _shot(viewport, resolution, "10-briefing-normal")
	controller.level_briefing.dismiss()

	# 7. Settings popup.
	controller.home_overlay.present(3, 5200, controller.hud_snapshot())
	controller.home_overlay._show_settings()
	await _shot(viewport, resolution, "07-settings")

	viewport.queue_free()
	await process_frame


func _shot(viewport: SubViewport, resolution: Vector2i, name: String) -> void:
	await process_frame
	await create_timer(0.75, true, false, true).timeout
	await RenderingServer.frame_post_draw
	var destination := OUTPUT_DIR + "%dx%d-%s.png" % [resolution.x, resolution.y, name]
	var error := viewport.get_texture().get_image().save_png(destination)
	if error != OK:
		push_error("Unable to save UI proof %s (error %d)" % [destination, error])
