extends SceneTree

const GameControllerType = preload("res://scripts/game_controller.gd")
const HomeOverlayType = preload("res://scripts/home_overlay_layer.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_timing_and_mix_contracts()
	await _test_exactly_once_restored_cadence_and_launcher_independence()
	await _test_back_state_priority()
	await _test_privacy_alignment_across_aspects()
	if failures.is_empty():
		print("ANIMATION_AUDIO_BACK_PRIVACY_POLISH_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("ANIMATION_AUDIO_BACK_PRIVACY_POLISH_TESTS: FAIL (%d)" % failures.size())
	quit(1)


func _test_timing_and_mix_contracts() -> void:
	_assert(is_equal_approx(GameConfig.COLLISION_VISUAL_DURATION, 0.11), "Collision response must restore the tester-approved 110 ms")
	_assert(is_equal_approx(GameConfig.MERGE_PRESENTATION_DURATION, 0.27) and is_equal_approx(GameConfig.MERGE_SOURCE_PULL_DURATION, 0.06), "Merge feedback and push animation must restore the approved fast cadence")
	_assert(is_equal_approx(GameConfig.MERGE_REVEAL_START, 0.0) and is_equal_approx(GameConfig.MERGE_REVEAL_SOUND_AT, 0.0), "Fast merge result reveal and chime must remain immediate")
	_assert(is_equal_approx(GameConfig.TARGET_COLLECTION_DURATION, 0.70), "Target reward must restore the post-checkmark-removal 700 ms cadence")
	_assert(is_equal_approx(GameConfig.TARGET_COLLECTION_CONFIRM_DURATION, 0.10) and is_equal_approx(GameConfig.TARGET_COLLECTION_TRAVEL_DURATION, 0.52), "Target reward must retain its 100 ms confirmation and 520 ms travel")
	_assert(is_equal_approx(GameConfig.TARGET_PANEL_PULSE_DURATION, 0.22), "Target pulse must restore the post-checkmark-removal 220 ms cadence")
	_assert(GameConfig.COIN_BURST_COUNT >= 4 and GameConfig.COIN_BURST_COUNT <= 6, "Coin reward must use four to six lightweight visuals")
	_assert(is_equal_approx(GameConfig.COIN_REWARD_START_DELAY, 0.26), "Coin reward must restore its 260 ms visual start delay")
	var effects_source := FileAccess.get_file_as_string("res://scripts/gameplay_effects_layer.gd")
	var coin_function := effects_source.find("func begin_target_coin_reward")
	var coin_delay := effects_source.find("GameConfig.COIN_REWARD_START_DELAY", coin_function)
	var merge_function := effects_source.find("func begin_merge_feedback")
	var merge_function_source := effects_source.substr(merge_function, coin_function - merge_function)
	_assert(coin_delay > coin_function and not merge_function_source.contains("GameConfig.COIN_REWARD_START_DELAY"), "Coin delay must apply only to target coins, never to the merge impact")
	_assert(is_equal_approx(GameConfig.COIN_FLIGHT_STAGGER, 0.08) and is_equal_approx(GameConfig.COIN_SPAWN_STAGGER, 0.08), "Coin stagger must restore the post-checkmark-removal cadence")
	_assert(is_equal_approx(GameConfig.COIN_FLIGHT_DURATION, 0.55) and is_equal_approx(GameConfig.MAJOR_COIN_FLIGHT_DURATION, 0.62), "Coin travel must restore the post-checkmark-removal cadence")
	var visible_coin_sequence := GameConfig.COIN_BURST_DURATION + float(GameConfig.MAJOR_COIN_BURST_COUNT - 1) * GameConfig.COIN_FLIGHT_STAGGER + GameConfig.MAJOR_COIN_FLIGHT_DURATION
	_assert(is_equal_approx(visible_coin_sequence, 0.98), "Visible coin sequence must restore the previous 980 ms total")
	var final_sequence := maxf(
		GameConfig.MERGE_PRESENTATION_DURATION + GameConfig.TARGET_COLLECTION_DURATION,
		GameConfig.COIN_REWARD_START_DELAY + visible_coin_sequence
	) + GameConfig.WIN_PRESENTATION_HOLD
	_assert(is_equal_approx(final_sequence, 1.66), "Final-target-to-result presentation must restore the previous 1.66 second bound")
	_assert(is_equal_approx(GameConfig.WIN_PRESENTATION_HOLD, 0.42), "Level-complete hold must restore 420 ms")
	_assert(is_equal_approx(GameConfig.CONTACT_SOUND_COOLDOWN, 0.065) and is_equal_approx(GameConfig.AUDIO_COOLDOWN_BY_EVENT.wall_contact, 0.09), "Contact cooldowns must use the original mapping")
	_assert(is_equal_approx(float(GameConfig.AUDIO_TONES.gem_contact.volume), 0.34), "Gem collision must restore the original volume")
	_assert(is_equal_approx(float(GameConfig.AUDIO_TONES.wall_contact.volume), 0.39), "Rail collision must restore the original volume")
	_assert(float(GameConfig.AUDIO_TONES.target_collect.volume) > float(GameConfig.AUDIO_TONES.normal_merge.volume), "Target arrival must sit above normal merge")
	_assert(float(GameConfig.AUDIO_TONES.win.volume) > float(GameConfig.AUDIO_TONES.target_collect.volume), "Level complete must remain the strongest short cue")
	_assert(ProjectSettings.get_setting("application/config/quit_on_go_back", true) == false, "Godot Android auto-quit must be disabled so app state owns Back")


func _test_exactly_once_restored_cadence_and_launcher_independence() -> void:
	paused = false
	var controller := GameControllerType.new()
	root.add_child(controller)
	await process_frame
	controller._on_home_level_intro_requested()
	controller._on_home_play_requested()
	var result_level := controller.active_target_tier()
	var result_id := 9001
	var event := {
		"result_id": result_id,
		"source_ids": [8001, 8002],
		"level": result_level,
		"first_position": Vector2(320.0, 720.0),
		"second_position": Vector2(400.0, 720.0),
		"midpoint": Vector2(360.0, 720.0),
		"depth": 0,
	}
	var before_coins := controller.coins
	var before_target_index := controller.target_index
	var before_target_progress := controller.target_progress
	var before_presented_index := controller.presented_target_index
	var before_presented_progress := controller.presented_target_progress
	var required_quantity := controller.active_target_quantity()
	controller._apply_confirmed_merge_events([event])
	controller._apply_confirmed_merge_events([event])
	var expected_reward := GameConfig.target_coin_reward_for_result_level(result_level)
	_assert(controller.merge_presentations.size() == 1, "Repeated confirmed result ID must create one merge presentation")
	_assert(controller.coins == before_coins + expected_reward, "Repeated confirmed result ID must award target coins exactly once")
	_assert(controller.effects_layer.active_coin_count() == GameConfig.COIN_BURST_COUNT, "Target reward must create one bounded coin group")
	if before_target_progress + 1 >= required_quantity:
		_assert(controller.target_index == before_target_index + 1 and controller.target_progress == 0, "Confirmed target result must advance authoritative target state immediately")
	else:
		_assert(controller.target_index == before_target_index and controller.target_progress == before_target_progress + 1, "Confirmed target result must advance authoritative quantity immediately")
	_assert(controller.presented_target_index == before_presented_index and controller.presented_target_progress == before_presented_progress, "HUD target state must wait for collection arrival")
	controller._update_merge_presentations(GameConfig.TARGET_COLLECTION_OVERLAP_START + 0.01)
	_assert(controller.collection_in_progress and controller.target_collection_queue.is_empty(), "Target travel must begin once during the restored merge settle")
	_assert(not controller.merge_presentations.is_empty(), "Target reward must overlap the unfinished merge presentation")
	controller._sync_gems_and_mark_visibility()
	controller.launcher_state = controller.LauncherState.RESOLVING
	for piece in controller.pieces:
		piece.is_active_launcher = false
	controller.active_piece_id = -1
	controller._advance_launcher_lifecycle(GameConfig.NEXT_LAUNCHER_READY_DELAY + 0.01)
	controller._advance_launcher_lifecycle(0.0)
	_assert(controller.get_active_piece() != null and controller.launcher_state == controller.LauncherState.READY_TO_AIM, "Next launcher must remain independent of the restored presentation")
	_assert(controller.presented_target_index == before_presented_index and controller.presented_target_progress == before_presented_progress, "Target HUD state must remain unchanged during travel")
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION + 0.01)
	if before_target_progress + 1 >= required_quantity:
		_assert(controller.presented_target_index == before_presented_index + 1 and controller.presented_target_progress == 0, "Completed target HUD must advance at collection arrival")
	else:
		_assert(controller.presented_target_index == before_presented_index and controller.presented_target_progress == before_presented_progress + 1, "Target HUD quantity must advance at collection arrival")
	var late_same_target := event.duplicate(true)
	late_same_target.result_id = result_id + 1
	var coins_after_target := controller.coins
	controller._apply_confirmed_merge_events([late_same_target])
	_assert(controller.coins == coins_after_target and not controller.pending_target_presentations.has(result_id + 1), "A later merge must use authoritative advanced target state, not the delayed HUD state")
	paused = false
	controller.queue_free()
	await process_frame


func _test_back_state_priority() -> void:
	paused = false
	var controller := GameControllerType.new()
	root.add_child(controller)
	await process_frame
	controller.home_overlay._show_settings()
	_assert(controller._handle_back_request(false) == "home_overlay" and not controller.home_overlay.settings_blocker.visible, "Back must close Home Settings first")
	_assert(controller._handle_back_request(false) == "exit_confirmation" and controller.home_overlay.exit_confirm_blocker.visible, "Bare Home Back must show exit confirmation")
	_assert(controller._handle_back_request(false) == "home_overlay" and not controller.home_overlay.exit_confirm_blocker.visible, "Back must close exit confirmation without exiting")
	controller._on_home_level_intro_requested()
	_assert(controller._handle_back_request(false) == "home_overlay" and controller.app_flow_state == controller.AppFlowState.HOME, "Back must return Level Ready to Home")
	controller._on_home_level_intro_requested()
	controller._on_home_play_requested()
	_assert(controller._handle_back_request(false) == "pause" and controller.gameplay_ui.is_pause_visible(), "Gameplay Back must open Pause")
	_assert(controller._handle_back_request(false) == "resume", "Back on Pause must resume")
	controller.result_overlay.present(false, controller.coins, controller.level_number, controller.active_target_tier())
	controller.app_flow_state = controller.AppFlowState.LEVEL_COMPLETE
	_assert(controller._handle_back_request(false) == "result_locked" and controller.result_overlay.visible_result, "Back must not bypass result/progression actions")
	paused = false
	controller.queue_free()
	await process_frame


func _test_privacy_alignment_across_aspects() -> void:
	for viewport_size in [Vector2i(576, 1312), Vector2i(720, 1280), Vector2i(720, 1600), Vector2i(1080, 2400)]:
		var viewport := SubViewport.new()
		viewport.size = viewport_size
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var home := HomeOverlayType.new()
		viewport.add_child(home)
		await process_frame
		home.set_safe_insets_for_testing(Vector4(0.0, 36.0, 0.0, 48.0))
		home.present(8, 11900, {})
		await process_frame
		var rect := home.privacy_policy_link.get_global_rect()
		_assert(absf(rect.get_center().x - float(viewport_size.x) * 0.5) <= 2.0, "%s Privacy Policy text box must be horizontally centered" % viewport_size)
		_assert(rect.size.x < 150.0, "%s Privacy Policy text must not retain the visually offset 180px box" % viewport_size)
		_assert(rect.position.y >= 0.0 and rect.end.y <= float(viewport_size.y), "%s Privacy Policy link must remain inside the safe viewport" % viewport_size)
		viewport.queue_free()
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
