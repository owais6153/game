extends SceneTree

const HomeOverlayType = preload("res://scripts/home_overlay_layer.gd")
const GameControllerType = preload("res://scripts/game_controller.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_home_to_game_level_ready()
	await _test_single_native_splash_to_home()
	await _test_production_controller_home_flow()
	await _test_back_and_idle_state_ownership()
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


func _test_production_controller_home_flow() -> void:
	paused = false
	var controller := GameControllerType.new()
	root.add_child(controller)
	await process_frame
	_assert(controller.app_flow_state == controller.AppFlowState.HOME, "Production startup must always enter Home, independent of platform feature flags")
	_assert(controller.home_overlay != null and controller.home_overlay.root_control.visible and controller.home_overlay.home_backdrop.visible, "Production startup must visibly present the complete Home screen")
	controller._on_home_level_intro_requested()
	_assert(controller.app_flow_state == controller.AppFlowState.LEVEL_READY and controller.home_overlay.level_intro_blocker.visible, "Home PLAY must enter Level Ready without starting gameplay")
	controller._show_home()
	_assert(controller.app_flow_state == controller.AppFlowState.HOME and controller.home_overlay.home_backdrop.visible and not controller.home_overlay.level_intro_blocker.visible, "Level Ready must return to Home")
	controller._on_home_level_intro_requested()
	controller._on_home_play_requested()
	controller._on_settings_requested()
	_assert(controller.gameplay_ui.is_pause_visible(), "Active gameplay must open Pause before testing its Home action")
	controller.gameplay_ui.home_requested.emit()
	_assert(controller.app_flow_state == controller.AppFlowState.HOME and controller.home_overlay.home_backdrop.visible and not controller.gameplay_ui.is_pause_visible(), "Pause HOME must synchronously return to the visible Home screen")
	paused = false
	controller.queue_free()
	await process_frame


func _test_back_and_idle_state_ownership() -> void:
	paused = false
	var controller := GameControllerType.new()
	root.add_child(controller)
	await process_frame
	controller.home_overlay._show_settings()
	_assert(controller._handle_back_request(false) == "home_overlay", "Back on Home Settings must dismiss the popup before exiting")
	_assert(controller.app_flow_state == controller.AppFlowState.HOME and paused and not controller.gameplay_ui.is_pause_visible(), "Dismissing Home Settings must preserve the paused Home state")
	_assert(controller._handle_back_request(false) == "exit", "Back on the bare Home screen must request a clean application exit")
	_assert(controller.app_flow_state == controller.AppFlowState.HOME and paused and not controller.gameplay_ui.is_pause_visible(), "A Home exit request must never open gameplay Pause or unpause the hidden board")
	controller._on_home_level_intro_requested()
	_assert(controller._handle_back_request(false) == "home_overlay", "Back on Level Ready must be consumed by the Home overlay")
	_assert(controller.app_flow_state == controller.AppFlowState.HOME and controller.home_overlay.home_backdrop.visible, "Back on Level Ready must return to Home")
	controller._on_home_level_intro_requested()
	controller._on_home_play_requested()
	_assert(controller._handle_back_request(false) == "pause" and controller.gameplay_ui.is_pause_visible() and paused, "Back during active play must open Pause")
	_assert(controller._handle_back_request(false) == "resume" and not paused, "Back on Pause must resume active play")
	await create_timer(0.3, true).timeout
	_assert(not controller.gameplay_ui.is_pause_visible(), "Resumed Pause overlay must finish its bounded exit animation")
	controller._show_home()
	var stable_piece_count := controller.pieces.size()
	await create_timer(0.5, true).timeout
	_assert(controller.app_flow_state == controller.AppFlowState.HOME and paused and controller.pieces.size() == stable_piece_count, "Idle Home must remain paused and stable while always-processing timers run")
	paused = false
	controller.queue_free()
	await process_frame


func _test_controller_flow_guards() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/game_controller.gd")
	var home_source := FileAccess.get_file_as_string("res://scripts/home_overlay_layer.gd")
	var export_source := FileAccess.get_file_as_string("res://export_presets.cfg")
	_assert(not source.contains("StartupSplash") and not FileAccess.file_exists("res://scripts/startup_splash_layer.gd"), "The extra custom splash layer must remain removed")
	_assert(not source.contains("_show_home(true)") and not home_source.contains("startup_intro") and not home_source.contains("_start_home_splash_intro"), "No hidden-controls Home intro may act as a second splash")
	_assert(not source.contains("if OS.has_feature(\"mobile\"):\n\t\t_show_home()"), "Startup Home must not depend on a fragile platform feature flag")
	_assert(export_source.contains("splash_screen/disable_godot_boot_splash=true"), "Godot Android boot splash must stay disabled so only the platform launch splash remains")
	_assert(export_source.contains("splash_screen/icon=\"res://assets/runtime/ui/majestic_gems_system_splash_1152_v2.png\""), "Android launch splash must use the dedicated high-resolution derivative")
	var splash := Image.load_from_file(ProjectSettings.globalize_path("res://assets/runtime/ui/majestic_gems_system_splash_1152_v2.png"))
	_assert(splash != null and splash.get_width() == 1152 and splash.get_height() == 1152, "Android launch splash derivative must retain 1152x1152 source detail")
	_assert(not home_source.contains("HomeVibrationToggle") and not source.contains("vibration_toggled.connect"), "Unsupported vibration controls must not be exposed or wired")
	_assert(GameConfig.target_coin_reward_for_result_level(2) == 10 and GameConfig.target_coin_reward_for_result_level(3) == 25 and GameConfig.target_coin_reward_for_result_level(4) == 60 and GameConfig.target_coin_reward_for_result_level(5) == 150 and GameConfig.target_coin_reward_for_result_level(6) == 350 and GameConfig.target_coin_reward_for_result_level(7) == 800 and GameConfig.target_coin_reward_for_result_level(8) == 1800, "Target coin reward table must remain explicit and auditable")
	_assert(not source.contains("next_level_requested.connect"), "Controller must not wire the removed post-reward Next Level action")
	_assert(source.contains("result_overlay.reward_animation_finished.connect(_on_reward_animation_finished)"), "Progression must wait for reward animation completion")
	_assert(source.contains("result_overlay.resolve_reward(coins, true)") and source.find("result_overlay.resolve_reward(coins, true)") > source.find("func _on_rewarded_ad_finished"), "Rewarded x2 animation must begin after fullscreen dismissal, not inside the earned callback")
	_assert(source.contains("AdConfigType.should_show_interstitial_after_level(level_number)"), "Every-two-level interstitial cadence must remain in the post-reward transition")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
