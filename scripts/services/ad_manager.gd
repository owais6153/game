extends Node

signal initialization_completed(success: bool)
signal consent_state_changed(can_request_ads: bool)
signal privacy_options_availability_changed(available: bool)
signal interstitial_availability_changed(ready: bool)
signal rewarded_availability_changed(ready: bool)
signal fullscreen_started(ad_format: String)
signal fullscreen_finished(ad_format: String)

const AdConfigType = preload("res://scripts/services/ad_config.gd")
const LOAD_RETRY_DELAY_SECONDS := 15.0
const INITIALIZATION_FALLBACK_SECONDS := 5.0
const FULLSCREEN_SAFETY_TIMEOUT_SECONDS := 180.0

var _initialized := false
var _initializing := false
var _consent_update_started := false
var _consent_form_loading := false
var _consent_form_showing := false
var _privacy_options_showing := false
var _privacy_options_available := false
var _ads_requests_allowed := false
var _ads_start_committed := false
var _interstitial_loading := false
var _rewarded_loading := false
var _fullscreen_showing := false
var _interstitial_showing := false
var _rewarded_showing := false
var _interstitial_reported_shown := false
var _rewarded_reported_shown := false
var _interstitial_analytics_context: Dictionary = {}
var _rewarded_analytics_context: Dictionary = {}

var _interstitial_loader
var _rewarded_loader
var _interstitial_ad
var _active_interstitial_ad
var _rewarded_ad
var _active_rewarded_ad

var _interstitial_completion := Callable()
var _reward_completion := Callable()
var _reward_finished := Callable()
var _reward_session_id := 0
var _reward_granted_for_session := false
var _fullscreen_generation := 0
var _interstitial_retry_generation := 0
var _rewarded_retry_generation := 0
var _consent_can_request_ads_override_for_testing: Variant = null
var _shutting_down := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	initialize_once()


func initialize_once() -> void:
	if _shutting_down:
		return
	if OS.get_name() == "Android":
		_request_consent_information_once()
		return
	_ads_requests_allowed = true
	_start_mobile_ads_once()


func _request_consent_information_once() -> void:
	if _consent_update_started:
		return
	_consent_update_started = true
	var request := ConsentRequestParameters.new()
	request.tag_for_under_age_of_consent = false
	var debug_geography := AdConfigType.ump_debug_geography_for_current_build()
	if debug_geography != AdConfigType.UMP_DEBUG_GEOGRAPHY_DISABLED:
		var debug_settings := ConsentDebugSettings.new()
		debug_settings.debug_geography = debug_geography
		for hashed_id in AdConfigType.ump_test_device_hashed_ids_for_current_build():
			debug_settings.test_device_hashed_ids.append(hashed_id)
		request.consent_debug_settings = debug_settings
	UserMessagingPlatform.consent_information.update(
		request,
		_on_consent_information_updated,
		_on_consent_information_update_failed
	)


func _on_consent_information_updated() -> void:
	_refresh_privacy_options_availability()
	_refresh_ad_request_permission()
	var consent_information = UserMessagingPlatform.consent_information
	if (
		consent_information.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED
		and consent_information.get_is_consent_form_available()
	):
		_load_required_consent_form()


func _on_consent_information_update_failed(error: FormError) -> void:
	_log_consent_failure("information update", error)
	_refresh_privacy_options_availability()
	# Google documents that a previous-session decision can remain usable even
	# when this launch's network update fails. Only canRequestAds is authoritative.
	_refresh_ad_request_permission()


func _load_required_consent_form() -> void:
	if _consent_form_loading or _consent_form_showing:
		return
	_consent_form_loading = true
	UserMessagingPlatform.load_consent_form(
		_on_consent_form_loaded,
		_on_consent_form_load_failed
	)


func _on_consent_form_loaded(form: ConsentForm) -> void:
	_consent_form_loading = false
	if UserMessagingPlatform.consent_information.get_consent_status() != ConsentInformation.ConsentStatus.REQUIRED:
		_refresh_ad_request_permission()
		return
	_consent_form_showing = true
	form.show(_on_consent_form_dismissed)


func _on_consent_form_load_failed(error: FormError) -> void:
	_consent_form_loading = false
	_log_consent_failure("form load", error)
	_refresh_ad_request_permission()


func _on_consent_form_dismissed(error: FormError) -> void:
	_consent_form_showing = false
	if error != null:
		_log_consent_failure("form dismissal", error)
	_refresh_privacy_options_availability()
	_refresh_ad_request_permission()


func _refresh_ad_request_permission() -> bool:
	var allowed := _can_request_ads_authoritatively()
	var changed := allowed != _ads_requests_allowed
	_ads_requests_allowed = allowed
	if changed:
		consent_state_changed.emit(allowed)
	if allowed:
		_start_mobile_ads_once()
	else:
		_discard_cached_ads()
	return allowed


func _can_request_ads_authoritatively() -> bool:
	if _consent_can_request_ads_override_for_testing != null:
		return bool(_consent_can_request_ads_override_for_testing)
	return UserMessagingPlatform.consent_information.can_request_ads()


func _start_mobile_ads_once() -> void:
	if _ads_start_committed:
		return
	_ads_start_committed = true
	if _initialized or _initializing:
		return
	if not AdConfigType.is_configured_for_current_build():
		initialization_completed.emit(false)
		return
	_initializing = true
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		_finish_initialization(true)
	MobileAds.initialize(listener)
	if is_inside_tree():
		var fallback := get_tree().create_timer(INITIALIZATION_FALLBACK_SECONDS, true)
		fallback.timeout.connect(func() -> void:
			if _initializing:
				_finish_initialization(false)
		, CONNECT_ONE_SHOT)


func _finish_initialization(callback_received: bool) -> void:
	if _initialized or _shutting_down:
		return
	_initializing = false
	_initialized = true
	initialization_completed.emit(callback_received)
	if _ads_requests_allowed:
		preload_interstitial()
		preload_rewarded()


func is_privacy_options_available() -> bool:
	return _privacy_options_available


func show_privacy_options() -> bool:
	if (
		not _privacy_options_available
		or _privacy_options_showing
		or _consent_form_loading
		or _consent_form_showing
		or _fullscreen_showing
	):
		return false
	_privacy_options_showing = true
	UserMessagingPlatform.show_privacy_options_form(_on_privacy_options_form_dismissed)
	return true


func open_privacy_policy() -> bool:
	return OS.shell_open(AdConfigType.PRIVACY_POLICY_URL) == OK


func _on_privacy_options_form_dismissed(error: FormError) -> void:
	_privacy_options_showing = false
	if error != null:
		_log_consent_failure("privacy options", error)
	_refresh_privacy_options_availability()
	_refresh_ad_request_permission()


func _refresh_privacy_options_availability() -> void:
	var available := (
		UserMessagingPlatform.consent_information.get_privacy_options_requirement_status()
		== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED
	)
	if available == _privacy_options_available:
		return
	_privacy_options_available = available
	privacy_options_availability_changed.emit(available)


func is_interstitial_ready() -> bool:
	return _ads_requests_allowed and _interstitial_ad != null and not _interstitial_showing and not _fullscreen_showing


func is_rewarded_ready() -> bool:
	return _ads_requests_allowed and _rewarded_ad != null and not _rewarded_showing and not _fullscreen_showing


func is_fullscreen_showing() -> bool:
	return _fullscreen_showing


func preload_interstitial() -> void:
	var ad_unit_id := AdConfigType.current_interstitial_ad_unit_id()
	if _shutting_down or not _ads_requests_allowed or not _initialized or ad_unit_id.is_empty() or _interstitial_loading or _interstitial_ad != null or _interstitial_showing:
		return
	_interstitial_loading = true
	_interstitial_loader = InterstitialAdLoader.new()
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_interstitial_loading = false
		_interstitial_retry_generation += 1
		if _shutting_down or not _ads_requests_allowed:
			ad.destroy()
			interstitial_availability_changed.emit(false)
			return
		if _interstitial_ad != null:
			_interstitial_ad.destroy()
		# Fill succeeded. Reported here rather than at request time, so the load
		# funnel separates "asked for an ad" from "actually got one".
		_log_analytics("interstitial_loaded", {"placement": "level_complete"})
		_interstitial_ad = ad
		_setup_interstitial_callbacks(ad)
		interstitial_availability_changed.emit(is_interstitial_ready())
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_interstitial_loading = false
		if _shutting_down:
			return
		interstitial_availability_changed.emit(false)
		_log_load_failure("interstitial", error)
		_schedule_interstitial_retry()
	_interstitial_loader.load(ad_unit_id, AdRequest.new(), callback)


func preload_rewarded() -> void:
	var ad_unit_id := AdConfigType.current_rewarded_ad_unit_id()
	if _shutting_down or not _ads_requests_allowed or not _initialized or ad_unit_id.is_empty() or _rewarded_loading or _rewarded_ad != null or _rewarded_showing:
		return
	_rewarded_loading = true
	_rewarded_loader = RewardedAdLoader.new()
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		_rewarded_loading = false
		_rewarded_retry_generation += 1
		if _shutting_down or not _ads_requests_allowed:
			ad.destroy()
			rewarded_availability_changed.emit(false)
			return
		if _rewarded_ad != null:
			_rewarded_ad.destroy()
		_log_analytics("rewarded_ad_loaded", {})
		_rewarded_ad = ad
		_setup_rewarded_callbacks(ad)
		rewarded_availability_changed.emit(is_rewarded_ready())
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_rewarded_loading = false
		if _shutting_down:
			return
		rewarded_availability_changed.emit(false)
		_log_load_failure("rewarded", error)
		_schedule_rewarded_retry()
	_rewarded_loader.load(ad_unit_id, AdRequest.new(), callback)


func show_interstitial(on_finished: Callable = Callable(), analytics_context: Dictionary = {}) -> bool:
	if not is_interstitial_ready():
		_invoke_deferred(on_finished)
		preload_interstitial()
		return false
	var ad = _interstitial_ad
	_interstitial_ad = null
	_active_interstitial_ad = ad
	_interstitial_completion = on_finished
	_interstitial_analytics_context = analytics_context.duplicate(true)
	_interstitial_showing = true
	_interstitial_reported_shown = false
	_fullscreen_showing = true
	interstitial_availability_changed.emit(false)
	fullscreen_started.emit("interstitial")
	_start_fullscreen_safety_timeout("interstitial", ad)
	ad.show()
	return true


func show_rewarded(on_reward: Callable, on_finished: Callable = Callable(), analytics_context: Dictionary = {}) -> bool:
	if not is_rewarded_ready():
		_invoke_deferred(on_finished, [false])
		preload_rewarded()
		return false
	var ad = _rewarded_ad
	_rewarded_ad = null
	_active_rewarded_ad = ad
	_reward_completion = on_reward
	_reward_finished = on_finished
	_rewarded_analytics_context = analytics_context.duplicate(true)
	_reward_session_id += 1
	_reward_granted_for_session = false
	_rewarded_showing = true
	_rewarded_reported_shown = false
	_fullscreen_showing = true
	rewarded_availability_changed.emit(false)
	fullscreen_started.emit("rewarded")
	_start_fullscreen_safety_timeout("rewarded", ad)
	var session_id := _reward_session_id
	var reward_listener := OnUserEarnedRewardListener.new()
	reward_listener.on_user_earned_reward = func(item: RewardedItem) -> void:
		_on_user_earned_reward(session_id, item)
	ad.show(reward_listener)
	return true


func _setup_interstitial_callbacks(ad) -> void:
	var callbacks := FullScreenContentCallback.new()
	callbacks.on_ad_showed_full_screen_content = func() -> void:
		_on_interstitial_shown(ad)
	callbacks.on_ad_dismissed_full_screen_content = func() -> void:
		_finish_interstitial(ad)
	callbacks.on_ad_failed_to_show_full_screen_content = func(error: AdError) -> void:
		_log_show_failure("interstitial", error)
		_log_ad_failure("interstitial_failed", error, _interstitial_analytics_context)
		_finish_interstitial(ad)
	ad.full_screen_content_callback = callbacks


func _setup_rewarded_callbacks(ad) -> void:
	var callbacks := FullScreenContentCallback.new()
	callbacks.on_ad_showed_full_screen_content = func() -> void:
		_on_rewarded_shown(ad)
	callbacks.on_ad_dismissed_full_screen_content = func() -> void:
		_finish_rewarded(ad)
	callbacks.on_ad_failed_to_show_full_screen_content = func(error: AdError) -> void:
		_log_show_failure("rewarded", error)
		_log_ad_failure("rewarded_ad_failed", error, _rewarded_analytics_context)
		_finish_rewarded(ad)
	ad.full_screen_content_callback = callbacks


func _on_interstitial_shown(ad) -> void:
	if not _interstitial_showing or ad != _active_interstitial_ad or _interstitial_reported_shown:
		return
	_interstitial_reported_shown = true
	_log_analytics("interstitial_shown", _interstitial_analytics_context)


func _on_rewarded_shown(ad) -> void:
	if not _rewarded_showing or ad != _active_rewarded_ad or _rewarded_reported_shown:
		return
	_rewarded_reported_shown = true
	_log_analytics("rewarded_ad_shown", _rewarded_analytics_context)


func _on_user_earned_reward(session_id: int, item) -> void:
	if not _rewarded_showing or session_id != _reward_session_id or _reward_granted_for_session:
		return
	_reward_granted_for_session = true
	_log_analytics("rewarded_ad_completed", _rewarded_analytics_context)
	if _reward_completion.is_valid():
		_reward_completion.call(item)


func _finish_interstitial(ad) -> void:
	if not _interstitial_showing or ad != _active_interstitial_ad:
		return
	_fullscreen_generation += 1
	_interstitial_showing = false
	_fullscreen_showing = false
	if ad != null:
		ad.destroy()
	_active_interstitial_ad = null
	var completion := _interstitial_completion
	_interstitial_completion = Callable()
	_interstitial_analytics_context.clear()
	fullscreen_finished.emit("interstitial")
	preload_interstitial()
	_invoke_deferred(completion)


func _finish_rewarded(ad) -> void:
	if not _rewarded_showing or ad != _active_rewarded_ad:
		return
	_fullscreen_generation += 1
	_rewarded_showing = false
	_fullscreen_showing = false
	if ad != null:
		ad.destroy()
	_active_rewarded_ad = null
	var earned := _reward_granted_for_session
	var completion := _reward_finished
	_reward_completion = Callable()
	_reward_finished = Callable()
	_rewarded_analytics_context.clear()
	fullscreen_finished.emit("rewarded")
	preload_rewarded()
	_invoke_deferred(completion, [earned])


func _start_fullscreen_safety_timeout(ad_format: String, ad) -> void:
	_fullscreen_generation += 1
	var generation := _fullscreen_generation
	if _shutting_down or not is_inside_tree():
		return
	var timer := get_tree().create_timer(FULLSCREEN_SAFETY_TIMEOUT_SECONDS, true)
	timer.timeout.connect(func() -> void:
		if generation != _fullscreen_generation:
			return
		push_warning("AdManager: %s callback timeout; releasing the blocked transition" % ad_format)
		if ad_format == "interstitial":
			_log_analytics("interstitial_failed", _interstitial_analytics_context.merged({"failure_reason": "callback_timeout"}))
			_finish_interstitial(ad)
		else:
			_log_analytics("rewarded_ad_failed", _rewarded_analytics_context.merged({"failure_reason": "callback_timeout"}))
			_finish_rewarded(ad)
	, CONNECT_ONE_SHOT)


func _schedule_interstitial_retry() -> void:
	_interstitial_retry_generation += 1
	var generation := _interstitial_retry_generation
	if _shutting_down or not is_inside_tree():
		return
	var timer := get_tree().create_timer(LOAD_RETRY_DELAY_SECONDS, true)
	timer.timeout.connect(func() -> void:
		if not _shutting_down and generation == _interstitial_retry_generation:
			preload_interstitial()
	, CONNECT_ONE_SHOT)


func _schedule_rewarded_retry() -> void:
	_rewarded_retry_generation += 1
	var generation := _rewarded_retry_generation
	if _shutting_down or not is_inside_tree():
		return
	var timer := get_tree().create_timer(LOAD_RETRY_DELAY_SECONDS, true)
	timer.timeout.connect(func() -> void:
		if not _shutting_down and generation == _rewarded_retry_generation:
			preload_rewarded()
	, CONNECT_ONE_SHOT)


func _invoke_deferred(callback: Callable, arguments: Array = []) -> void:
	if not callback.is_valid():
		return
	call_deferred("_invoke_callback", callback, arguments)


func _invoke_callback(callback: Callable, arguments: Array) -> void:
	if callback.is_valid():
		callback.callv(arguments)


func _log_analytics(event_name: String, parameters: Dictionary = {}) -> void:
	# The ad lifecycle remains authoritative; analytics only observes callbacks
	# that have already committed a fullscreen show or earned reward.
	print("[Analytics] %s requested by AdManager" % event_name)
	if not is_inside_tree():
		print("[Analytics] Service unavailable for detached AdManager test instance")
		return
	var analytics := get_tree().root.get_node_or_null("Analytics")
	if analytics == null:
		push_warning("[Analytics] Service unavailable for %s" % event_name)
		return
	print("[Analytics] Service available for %s" % event_name)
	analytics.log_event(event_name, parameters)


func _log_ad_failure(event_name: String, error, context: Dictionary) -> void:
	var parameters := context.duplicate(true)
	parameters["failure_reason"] = "sdk_show_failure"
	parameters["error_code"] = int(error.code) if error != null else -1
	_log_analytics(event_name, parameters)


func _log_load_failure(ad_format: String, error) -> void:
	var code := int(error.code) if error != null else -1
	var message := String(error.message) if error != null else "unknown"
	print("AdManager: %s load failed (%d): %s" % [ad_format, code, message])


func _log_show_failure(ad_format: String, error) -> void:
	var code := int(error.code) if error != null else -1
	var message := String(error.message) if error != null else "unknown"
	print("AdManager: %s show failed (%d): %s" % [ad_format, code, message])


func _log_consent_failure(operation: String, error) -> void:
	var code := int(error.error_code) if error != null else -1
	var message := String(error.message) if error != null else "unknown"
	print("AdManager: consent %s failed (%d): %s" % [operation, code, message])


func _discard_cached_ads() -> void:
	_interstitial_retry_generation += 1
	_rewarded_retry_generation += 1
	if _interstitial_ad != null:
		_interstitial_ad.destroy()
		_interstitial_ad = null
	if _rewarded_ad != null:
		_rewarded_ad.destroy()
		_rewarded_ad = null
	interstitial_availability_changed.emit(false)
	rewarded_availability_changed.emit(false)


func shutdown_for_exit() -> void:
	if _shutting_down:
		return
	prepare_for_exit()
	_discard_cached_ads()


func prepare_for_exit() -> void:
	if _shutting_down:
		return
	_shutting_down = true
	_ads_requests_allowed = false
	_interstitial_retry_generation += 1
	_rewarded_retry_generation += 1
	_fullscreen_generation += 1
	_interstitial_completion = Callable()
	_reward_completion = Callable()
	_reward_finished = Callable()
	_interstitial_analytics_context.clear()
	_rewarded_analytics_context.clear()


func _exit_tree() -> void:
	shutdown_for_exit()
	if _interstitial_ad != null:
		_interstitial_ad.destroy()
	if _active_interstitial_ad != null:
		_active_interstitial_ad.destroy()
	if _rewarded_ad != null:
		_rewarded_ad.destroy()
	if _active_rewarded_ad != null:
		_active_rewarded_ad.destroy()
