extends SceneTree

const HomeOverlayType = preload("res://scripts/home_overlay_layer.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_home_to_game_level_ready()
	await _test_single_native_splash_to_home()
	_test_controller_flow_guards()
	if failures.is_empty():
		print("GAME_FLOW_REWARD_SPLASH_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("GAME_FLOW_REWARD_SPLASH_TESTS: FAIL (%d)" % failures.size())
	quit(1)


func _test_home_to_game_level_ready() -> void:
	var home := HomeOverlayType.new()
	root.add_child(home)
	await process_frame
	var snapshot := {"target_level": 5, "target_index": 0, "target_total": 1, "target_quantity": 1}
	home.present(3, 450, snapshot)
	_assert(home.home_backdrop.visible and not home.level_intro_blocker.visible, "Home must begin as the standalone Home composition")
	var state := {"ready_requests": 0}
	home.level_intro_requested.connect(func() -> void:
		state.ready_requests += 1
		home.present_level_intro(3, 450, snapshot)
	)
	home.play_button.pressed.emit()
	_assert(int(state.ready_requests) == 1, "Home PLAY must request the Level Ready transition exactly once")
	_assert(not home.home_backdrop.visible and not home.safe_margin.visible and home.level_intro_blocker.visible, "Level Start must replace Home visually so the gameplay screen is visible underneath")
	_assert(home.intro_start_button.text == "START GAME", "Level Ready must retain one explicit Start action")
	home.queue_free()
	await process_frame


func _test_single_native_splash_to_home() -> void:
	var home := HomeOverlayType.new()
	root.add_child(home)
	await process_frame
	home.present(1, 0, {})
	_assert(home.home_backdrop.texture.resource_path == "res://assets/runtime/backgrounds/scene_bg_01.webp", "Home must retain its exact full-bleed background asset")
	_assert(home.home_backdrop.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "Home background must preserve aspect and cover/crop the full viewport")
	_assert(home.play_button.visible and home.top_controls_margin.visible, "Home controls must be visible immediately; no second splash-like Home state may run")
	home.queue_free()
	await process_frame


func _test_controller_flow_guards() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/game_controller.gd")
	var home_source := FileAccess.get_file_as_string("res://scripts/home_overlay_layer.gd")
	var export_source := FileAccess.get_file_as_string("res://export_presets.cfg")
	_assert(not source.contains("StartupSplash") and not FileAccess.file_exists("res://scripts/startup_splash_layer.gd"), "The extra custom splash layer must remain removed")
	_assert(not source.contains("_show_home(true)") and not home_source.contains("startup_intro") and not home_source.contains("_start_home_splash_intro"), "No hidden-controls Home intro may act as a second splash")
	_assert(export_source.contains("splash_screen/disable_godot_boot_splash=true"), "Godot Android boot splash must stay disabled so only the platform launch splash remains")
	_assert(not source.contains("next_level_requested.connect"), "Controller must not wire the removed post-reward Next Level action")
	_assert(source.contains("result_overlay.reward_animation_finished.connect(_on_reward_animation_finished)"), "Progression must wait for reward animation completion")
	_assert(source.contains("result_overlay.resolve_reward(coins, true)") and source.find("result_overlay.resolve_reward(coins, true)") > source.find("func _on_rewarded_ad_finished"), "Rewarded x2 animation must begin after fullscreen dismissal, not inside the earned callback")
	_assert(source.contains("AdConfigType.should_show_interstitial_after_level(level_number)"), "Every-two-level interstitial cadence must remain in the post-reward transition")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
