extends Node

signal initialization_completed(success: bool)
signal interstitial_availability_changed(ready: bool)
signal rewarded_availability_changed(ready: bool)
signal fullscreen_started(ad_format: String)
signal fullscreen_finished(ad_format: String)

const AdConfigType = preload("res://scripts/ad_config.gd")
const LOAD_RETRY_DELAY_SECONDS := 15.0
const INITIALIZATION_FALLBACK_SECONDS := 5.0
const FULLSCREEN_SAFETY_TIMEOUT_SECONDS := 180.0

var _initialized := false
var _initializing := false
var _interstitial_loading := false
var _rewarded_loading := false
var _fullscreen_showing := false
var _interstitial_showing := false
var _rewarded_showing := false

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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	initialize_once()


func initialize_once() -> void:
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
	if _initialized:
		return
	_initializing = false
	_initialized = true
	initialization_completed.emit(callback_received)
	preload_interstitial()
	preload_rewarded()


func is_interstitial_ready() -> bool:
	return _interstitial_ad != null and not _interstitial_showing and not _fullscreen_showing


func is_rewarded_ready() -> bool:
	return _rewarded_ad != null and not _rewarded_showing and not _fullscreen_showing


func is_fullscreen_showing() -> bool:
	return _fullscreen_showing


func preload_interstitial() -> void:
	var ad_unit_id := AdConfigType.current_interstitial_ad_unit_id()
	if not _initialized or ad_unit_id.is_empty() or _interstitial_loading or _interstitial_ad != null or _interstitial_showing:
		return
	_interstitial_loading = true
	_interstitial_loader = InterstitialAdLoader.new()
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_interstitial_loading = false
		_interstitial_retry_generation += 1
		if _interstitial_ad != null:
			_interstitial_ad.destroy()
		_interstitial_ad = ad
		_setup_interstitial_callbacks(ad)
		interstitial_availability_changed.emit(is_interstitial_ready())
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_interstitial_loading = false
		interstitial_availability_changed.emit(false)
		_log_load_failure("interstitial", error)
		_schedule_interstitial_retry()
	_interstitial_loader.load(ad_unit_id, AdRequest.new(), callback)


func preload_rewarded() -> void:
	var ad_unit_id := AdConfigType.current_rewarded_ad_unit_id()
	if not _initialized or ad_unit_id.is_empty() or _rewarded_loading or _rewarded_ad != null or _rewarded_showing:
		return
	_rewarded_loading = true
	_rewarded_loader = RewardedAdLoader.new()
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		_rewarded_loading = false
		_rewarded_retry_generation += 1
		if _rewarded_ad != null:
			_rewarded_ad.destroy()
		_rewarded_ad = ad
		_setup_rewarded_callbacks(ad)
		rewarded_availability_changed.emit(is_rewarded_ready())
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_rewarded_loading = false
		rewarded_availability_changed.emit(false)
		_log_load_failure("rewarded", error)
		_schedule_rewarded_retry()
	_rewarded_loader.load(ad_unit_id, AdRequest.new(), callback)


func show_interstitial(on_finished: Callable = Callable()) -> bool:
	if not is_interstitial_ready():
		_invoke_deferred(on_finished)
		preload_interstitial()
		return false
	var ad = _interstitial_ad
	_interstitial_ad = null
	_active_interstitial_ad = ad
	_interstitial_completion = on_finished
	_interstitial_showing = true
	_fullscreen_showing = true
	interstitial_availability_changed.emit(false)
	fullscreen_started.emit("interstitial")
	_start_fullscreen_safety_timeout("interstitial", ad)
	ad.show()
	return true


func show_rewarded(on_reward: Callable, on_finished: Callable = Callable()) -> bool:
	if not is_rewarded_ready():
		_invoke_deferred(on_finished, [false])
		preload_rewarded()
		return false
	var ad = _rewarded_ad
	_rewarded_ad = null
	_active_rewarded_ad = ad
	_reward_completion = on_reward
	_reward_finished = on_finished
	_reward_session_id += 1
	_reward_granted_for_session = false
	_rewarded_showing = true
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
	callbacks.on_ad_dismissed_full_screen_content = func() -> void:
		_finish_interstitial(ad)
	callbacks.on_ad_failed_to_show_full_screen_content = func(error: AdError) -> void:
		_log_show_failure("interstitial", error)
		_finish_interstitial(ad)
	ad.full_screen_content_callback = callbacks


func _setup_rewarded_callbacks(ad) -> void:
	var callbacks := FullScreenContentCallback.new()
	callbacks.on_ad_dismissed_full_screen_content = func() -> void:
		_finish_rewarded(ad)
	callbacks.on_ad_failed_to_show_full_screen_content = func(error: AdError) -> void:
		_log_show_failure("rewarded", error)
		_finish_rewarded(ad)
	ad.full_screen_content_callback = callbacks


func _on_user_earned_reward(session_id: int, item) -> void:
	if not _rewarded_showing or session_id != _reward_session_id or _reward_granted_for_session:
		return
	_reward_granted_for_session = true
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
	fullscreen_finished.emit("rewarded")
	preload_rewarded()
	_invoke_deferred(completion, [earned])


func _start_fullscreen_safety_timeout(ad_format: String, ad) -> void:
	_fullscreen_generation += 1
	var generation := _fullscreen_generation
	if not is_inside_tree():
		return
	var timer := get_tree().create_timer(FULLSCREEN_SAFETY_TIMEOUT_SECONDS, true)
	timer.timeout.connect(func() -> void:
		if generation != _fullscreen_generation:
			return
		push_warning("AdManager: %s callback timeout; releasing the blocked transition" % ad_format)
		if ad_format == "interstitial":
			_finish_interstitial(ad)
		else:
			_finish_rewarded(ad)
	, CONNECT_ONE_SHOT)


func _schedule_interstitial_retry() -> void:
	_interstitial_retry_generation += 1
	var generation := _interstitial_retry_generation
	if not is_inside_tree():
		return
	var timer := get_tree().create_timer(LOAD_RETRY_DELAY_SECONDS, true)
	timer.timeout.connect(func() -> void:
		if generation == _interstitial_retry_generation:
			preload_interstitial()
	, CONNECT_ONE_SHOT)


func _schedule_rewarded_retry() -> void:
	_rewarded_retry_generation += 1
	var generation := _rewarded_retry_generation
	if not is_inside_tree():
		return
	var timer := get_tree().create_timer(LOAD_RETRY_DELAY_SECONDS, true)
	timer.timeout.connect(func() -> void:
		if generation == _rewarded_retry_generation:
			preload_rewarded()
	, CONNECT_ONE_SHOT)


func _invoke_deferred(callback: Callable, arguments: Array = []) -> void:
	if not callback.is_valid():
		return
	call_deferred("_invoke_callback", callback, arguments)


func _invoke_callback(callback: Callable, arguments: Array) -> void:
	if callback.is_valid():
		callback.callv(arguments)


func _log_load_failure(ad_format: String, error) -> void:
	var code := int(error.code) if error != null else -1
	var message := String(error.message) if error != null else "unknown"
	print("AdManager: %s load failed (%d): %s" % [ad_format, code, message])


func _log_show_failure(ad_format: String, error) -> void:
	var code := int(error.code) if error != null else -1
	var message := String(error.message) if error != null else "unknown"
	print("AdManager: %s show failed (%d): %s" % [ad_format, code, message])


func _exit_tree() -> void:
	if _interstitial_ad != null:
		_interstitial_ad.destroy()
	if _active_interstitial_ad != null:
		_active_interstitial_ad.destroy()
	if _rewarded_ad != null:
		_rewarded_ad.destroy()
	if _active_rewarded_ad != null:
		_active_rewarded_ad.destroy()
