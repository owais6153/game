extends SceneTree

const AdConfigType = preload("res://scripts/ad_config.gd")
const AdManagerType = preload("res://scripts/ad_manager.gd")
const ResultOverlayType = preload("res://scripts/result_overlay_layer.gd")
const CoinIconType = preload("res://scripts/coin_icon.gd")
const HomeOverlayType = preload("res://scripts/home_overlay_layer.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_ad_ids_and_cadence()
	_test_consent_gate_contract()
	await _test_manager_lifecycle_and_fail_open_paths()
	_test_reward_callback_is_exactly_once()
	await _test_result_actions()
	await _test_privacy_settings_actions()
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
	_assert(AdConfigType.interstitial_ad_unit_id(false) == "ca-app-pub-4605895178658062/5792148613", "Release interstitial must use the Majestic Gems production unit")
	_assert(AdConfigType.rewarded_ad_unit_id(false) == "ca-app-pub-4605895178658062/3277665917", "Release rewarded must use the Majestic Gems production unit")
	_assert(not AdConfigType.should_show_interstitial_after_level(1), "Level 1 completion must not request an interstitial")
	_assert(AdConfigType.should_show_interstitial_after_level(2), "Level 2 completion must request an interstitial")
	_assert(not AdConfigType.should_show_interstitial_after_level(3), "Level 3 completion must not request an interstitial")
	_assert(AdConfigType.should_show_interstitial_after_level(4), "Level 4 completion must request an interstitial")
	_assert(AdConfigType.PRIVACY_POLICY_URL == "https://teckvertexlabs.vercel.app/privacy/majestic-gems", "Privacy Policy must use the published Majestic Gems URL")
	_assert(AdConfigType.ump_debug_geography(false) == AdConfigType.UMP_DEBUG_GEOGRAPHY_DISABLED, "Release builds must always disable forced UMP geography")
	_assert(AdConfigType.ump_test_device_hashed_ids(false).is_empty(), "Release builds must never receive UMP test device IDs")


func _test_consent_gate_contract() -> void:
	var consent_information := ConsentInformation.new()
	_assert(consent_information.has_method("can_request_ads"), "Poing's existing ConsentInformation wrapper must expose can_request_ads")
	var manager := AdManagerType.new()
	var source: String = manager.get_script().source_code
	_assert(source.contains("UserMessagingPlatform.consent_information.can_request_ads()"), "AdManager must use the authoritative native canRequestAds bridge")
	manager._initialized = true
	manager._ads_start_committed = true
	manager._consent_can_request_ads_override_for_testing = false
	_assert(not manager._refresh_ad_request_permission() and not manager._ads_requests_allowed, "A failed/unknown consent path must not request ads when canRequestAds is false")
	manager._consent_can_request_ads_override_for_testing = true
	_assert(manager._refresh_ad_request_permission() and manager._ads_requests_allowed, "Previous valid consent must allow ads when canRequestAds remains true")
	manager.free()


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
	var state := {"collect_requests": 0, "double_requests": 0, "reward_finished": 0}
	overlay.collect_requested.connect(func() -> void: state.collect_requests += 1)
	overlay.double_coins_requested.connect(func() -> void: state.double_requests += 1)
	overlay.reward_animation_finished.connect(func() -> void: state.reward_finished += 1)
	_assert(overlay.present(true, 1200, 2, 8, 300, false), "Completed result must present once")
	_assert(overlay.retry_button.text == "COLLECT", "Completed result must expose the normal Collect action")
	_assert(overlay.reward_coin_icon is CoinIconType and overlay.total_coin_icon is CoinIconType, "Reward and total must reuse the exact gameplay HUD CoinIcon component")
	_assert(overlay.reward_value_label.text == "+300" and overlay.score_label.text == "900", "Reward hierarchy must separate the prominent earned amount from the current total")
	_assert(overlay._displayed_total == 900, "Completed result must show the banked total before its pending reward")
	_assert(overlay.double_button.visible and overlay.double_button.disabled, "Unavailable rewarded action must be visible but disabled")
	overlay._on_action_pressed()
	overlay._on_action_pressed()
	_assert(int(state.collect_requests) == 1, "Collect must lock immediately and emit exactly one reward request")
	overlay.resolve_reward(1200, false)
	overlay.resolve_reward(1500, true)
	_assert(overlay.retry_button.text != "NEXT LEVEL" and not overlay.retry_button.visible and not overlay.double_button.visible, "Resolved Collect must remove reward actions without exposing an intermediate Next Level button")
	await create_timer(1.0).timeout
	_assert(int(state.reward_finished) == 1 and overlay._displayed_total == 1200, "Normal reward animation must finish once and reconcile the displayed total")
	overlay._on_action_pressed()
	_assert(int(state.collect_requests) == 1, "Resolved reward input must stay locked after animation")
	overlay.dismiss()

	_assert(overlay.present(true, 1200, 2, 8, 300, false), "Completed result must be reusable for rewarded flow")
	overlay.set_rewarded_available(true)
	overlay._on_double_pressed()
	overlay._on_double_pressed()
	_assert(int(state.double_requests) == 1, "The view must suppress a second rewarded request immediately")
	overlay.set_actions_pending(true)
	overlay._on_double_pressed()
	_assert(int(state.double_requests) == 1, "A pending ad action must suppress duplicate taps")
	overlay.set_actions_pending(false)
	overlay._on_double_pressed()
	_assert(int(state.double_requests) == 2, "An early close/failure must allow one safe rewarded retry")
	overlay.set_actions_pending(true)
	overlay.set_actions_pending(false)
	overlay.resolve_reward(1500, true)
	overlay.resolve_reward(1800, true)
	overlay._on_double_pressed()
	_assert(int(state.double_requests) == 2, "A confirmed double reward must disable every later request")
	await create_timer(1.3).timeout
	_assert(overlay.result_score == 1500 and not overlay.double_button.visible and overlay.retry_button.text != "NEXT LEVEL", "The rewarded result must apply once and finish without an intermediate Next Level action")
	overlay.dismiss()
	_assert(overlay.present(false, 1500, 2, 8), "Failure result must remain available after the ad-flow additions")
	_assert(overlay.retry_button.text == "RETRY" and not overlay.double_button.visible, "Failure flow must remain Retry-only")
	overlay.queue_free()
	await process_frame


func _test_privacy_settings_actions() -> void:
	var home := HomeOverlayType.new()
	root.add_child(home)
	await process_frame
	_assert(home.root_control.find_child("HomePrivacyPolicyLink", true, false) != null, "Home must expose the bottom Privacy Policy link")
	_assert(home.root_control.find_child("HomePrivacyPolicy", true, false) == null, "Home Settings must not contain the old Privacy Policy button")
	_assert(not home.settings_privacy_options_button.visible, "Home Privacy Options must stay hidden until UMP requires an entry point")
	home.set_privacy_options_available(true)
	_assert(home.settings_privacy_options_button.visible, "Home Privacy Options must appear when UMP requires it")
	home.queue_free()
	await process_frame

	var hud_source := FileAccess.get_file_as_string("res://scripts/gameplay_hud_layer.gd")
	_assert(not hud_source.contains("PausePrivacyPolicy") and hud_source.contains("PausePrivacyOptions"), "Pause Settings must remove Privacy Policy while retaining conditional UMP Privacy Options")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
