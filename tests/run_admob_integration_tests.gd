extends SceneTree

const AdConfigType = preload("res://scripts/ad_config.gd")
const AdManagerType = preload("res://scripts/ad_manager.gd")
const ResultOverlayType = preload("res://scripts/result_overlay_layer.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_ad_ids_and_cadence()
	await _test_manager_lifecycle_and_fail_open_paths()
	_test_reward_callback_is_exactly_once()
	await _test_result_actions()
	if failures.is_empty():
		print("ADMOB_INTEGRATION_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("ADMOB_INTEGRATION_TESTS: FAIL (%d)" % failures.size())
	quit(1)


func _test_ad_ids_and_cadence() -> void:
	_assert(AdConfigType.interstitial_ad_unit_id(true) == "ca-app-pub-3940256099942544/1033173712", "Debug interstitial must use Google's Android test unit")
	_assert(AdConfigType.rewarded_ad_unit_id(true) == "ca-app-pub-3940256099942544/5224354917", "Debug rewarded must use Google's Android test unit")
	_assert(AdConfigType.interstitial_ad_unit_id(false).is_empty(), "Release interstitial must remain an explicit production placeholder")
	_assert(AdConfigType.rewarded_ad_unit_id(false).is_empty(), "Release rewarded must remain an explicit production placeholder")
	_assert(not AdConfigType.should_show_interstitial_after_level(1), "Level 1 completion must not request an interstitial")
	_assert(AdConfigType.should_show_interstitial_after_level(2), "Level 2 completion must request an interstitial")
	_assert(not AdConfigType.should_show_interstitial_after_level(3), "Level 3 completion must not request an interstitial")
	_assert(AdConfigType.should_show_interstitial_after_level(4), "Level 4 completion must request an interstitial")


func _test_manager_lifecycle_and_fail_open_paths() -> void:
	var manager := AdManagerType.new()
	root.add_child(manager)
	var state := {"interstitial_finished": 0, "rewarded_finished": 0, "rewarded_earned": true}
	var interstitial_started := manager.show_interstitial(func() -> void: state.interstitial_finished += 1)
	var rewarded_started := manager.show_rewarded(
		func(_item = null) -> void: state.rewarded_earned = true,
		func(earned: bool) -> void:
			state.rewarded_earned = earned
			state.rewarded_finished += 1
	)
	await process_frame
	_assert(not interstitial_started and int(state.interstitial_finished) == 1, "Unavailable interstitial must complete its transition exactly once")
	_assert(not rewarded_started and int(state.rewarded_finished) == 1 and not bool(state.rewarded_earned), "Unavailable rewarded ad must return no reward and unblock exactly once")
	await create_timer(1.2).timeout
	_assert(manager.is_interstitial_ready() and manager.is_rewarded_ready(), "Initialization must preload both fullscreen formats")

	state.interstitial_finished = 0
	interstitial_started = manager.show_interstitial(func() -> void: state.interstitial_finished += 1)
	var active_interstitial = manager._active_interstitial_ad
	_assert(interstitial_started and manager.is_fullscreen_showing(), "A ready interstitial must enter one fullscreen session")
	_assert(not manager.show_interstitial(), "A second fullscreen request must be rejected while one is active")
	manager._finish_interstitial(active_interstitial)
	manager._finish_interstitial(active_interstitial)
	await process_frame
	_assert(int(state.interstitial_finished) == 1 and not manager.is_fullscreen_showing(), "Interstitial dismissal/failure must unblock exactly once")
	await create_timer(0.7).timeout
	_assert(manager.is_interstitial_ready(), "A consumed interstitial must reload")

	state.rewarded_finished = 0
	state.rewarded_earned = false
	state.reward_grants = 0
	rewarded_started = manager.show_rewarded(
		func(_item = null) -> void: state.reward_grants += 1,
		func(earned: bool) -> void:
			state.rewarded_earned = earned
			state.rewarded_finished += 1
	)
	var active_rewarded = manager._active_rewarded_ad
	var session_id := manager._reward_session_id
	_assert(rewarded_started and manager.is_fullscreen_showing(), "A ready rewarded ad must enter one fullscreen session")
	manager._on_user_earned_reward(session_id, null)
	manager._on_user_earned_reward(session_id, null)
	manager._finish_rewarded(active_rewarded)
	await process_frame
	_assert(int(state.reward_grants) == 1 and int(state.rewarded_finished) == 1 and bool(state.rewarded_earned), "Confirmed reward and dismissal must grant and finish exactly once")
	await create_timer(0.7).timeout
	_assert(manager.is_rewarded_ready(), "A consumed rewarded ad must reload")

	state.rewarded_finished = 0
	state.rewarded_earned = true
	rewarded_started = manager.show_rewarded(
		func(_item = null) -> void: state.reward_grants += 1,
		func(earned: bool) -> void:
			state.rewarded_earned = earned
			state.rewarded_finished += 1
	)
	active_rewarded = manager._active_rewarded_ad
	manager._finish_rewarded(active_rewarded)
	await process_frame
	_assert(rewarded_started and int(state.rewarded_finished) == 1 and not bool(state.rewarded_earned), "Early rewarded close/failure must grant nothing and restore the normal path")
	manager.queue_free()
	await process_frame


func _test_reward_callback_is_exactly_once() -> void:
	var manager := AdManagerType.new()
	var state := {"grants": 0}
	manager._rewarded_showing = true
	manager._reward_session_id = 17
	manager._reward_completion = func(_item = null) -> void: state.grants += 1
	manager._on_user_earned_reward(17, null)
	manager._on_user_earned_reward(17, null)
	manager._on_user_earned_reward(16, null)
	_assert(int(state.grants) == 1, "Repeated, stale, or resumed rewarded callbacks must never duplicate the bonus")
	manager.free()


func _test_result_actions() -> void:
	var overlay := ResultOverlayType.new()
	root.add_child(overlay)
	await process_frame
	var state := {"double_requests": 0}
	overlay.double_coins_requested.connect(func() -> void: state.double_requests += 1)
	_assert(overlay.present(true, 1200, 2, 8, 300, false), "Completed result must present once")
	_assert(overlay.retry_button.text == "COLLECT", "Completed result must expose the normal Collect action")
	_assert(overlay.double_button.visible and overlay.double_button.disabled, "Unavailable rewarded action must be visible but disabled")
	overlay.set_rewarded_available(true)
	overlay._on_double_pressed()
	overlay._on_double_pressed()
	_assert(int(state.double_requests) == 2, "The view may request an available reward; controller and manager own duplicate suppression")
	overlay.set_actions_pending(true)
	overlay._on_double_pressed()
	_assert(int(state.double_requests) == 2, "A pending ad action must suppress duplicate taps")
	overlay.set_actions_pending(false)
	overlay.mark_double_reward_applied(1500)
	overlay.mark_double_reward_applied(1800)
	overlay._on_double_pressed()
	_assert(int(state.double_requests) == 2, "A confirmed double reward must disable every later request")
	_assert(overlay.result_score == 1500 and overlay.double_button.disabled, "The reward view must apply its confirmed result only once")
	overlay.dismiss()
	_assert(overlay.present(false, 1500, 2, 8), "Failure result must remain available after the ad-flow additions")
	_assert(overlay.retry_button.text == "RETRY" and not overlay.double_button.visible, "Failure flow must remain Retry-only")
	overlay.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
