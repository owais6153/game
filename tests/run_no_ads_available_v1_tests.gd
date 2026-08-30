extends SceneTree

## Production currently has no ad inventory while the ad account is verified,
## so "no ads" is the normal path, not an edge case. Nothing may look broken,
## trap the player, or silently hand out a reward.

const GameControllerType = preload("res://scripts/gameplay/game_controller.gd")
const PowerInventoryServiceType = preload("res://scripts/services/power_inventory_service.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_power_ad_offer_explains_itself()
	await _test_power_ad_grants_nothing_without_the_earned_callback()
	await _test_level_complete_never_strands_the_player()
	await _test_repeated_taps_cannot_stack_requests()
	await _test_coin_route_survives_when_ads_do_not()
	if failures.is_empty():
		print("NO_ADS_AVAILABLE_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("NO_ADS_AVAILABLE_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


## Tapping "+" with no inventory must still open a panel that says something,
## rather than doing nothing at all.
func _test_power_ad_offer_explains_itself() -> void:
	var controller = await _start(DeadAdManager.new())
	controller._offer_power_ad("bomb")
	var overlay = controller.power_overlay
	_assert(overlay.is_open(), "an unavailable ad must still open an explanatory panel")
	_assert(overlay.mode == overlay.Mode.AD_OFFER, "it must be the offer panel")
	var body := String(overlay.body_label.text)
	_assert(not body.is_empty(), "the panel must explain the situation")
	# No technical vocabulary may reach a player.
	for banned in ["AdMob", "SDK", "verification", "error", "failed", "load", "null"]:
		_assert(not body.to_lower().contains(banned.to_lower()),
			"player-facing copy must not contain %s (got: %s)" % [banned, body])
	_assert(not overlay.primary_button.visible,
		"no WATCH button may be offered when there is no video to watch")
	_assert(overlay.secondary_button.visible,
		"the panel must always offer a way out")
	_free(controller)


## The reward may only ever come from the earned callback.
func _test_power_ad_grants_nothing_without_the_earned_callback() -> void:
	var manager := DeadAdManager.new()
	var controller = await _start(manager)
	var before := PowerInventoryServiceType.count(controller.power_state, "bomb")
	controller._on_power_ad_confirmed("bomb")
	_assert(PowerInventoryServiceType.count(controller.power_state, "bomb") == before,
		"an unavailable ad must grant nothing")
	_assert(controller.power_overlay.mode == controller.power_overlay.Mode.AD_RESULT,
		"a failed attempt must still report an outcome rather than going quiet")

	# A video that opens but is dismissed without earning must also grant nothing.
	var live := RecordingAdManager.new()
	var second = await _start(live)
	var owned := PowerInventoryServiceType.count(second.power_state, "bomb")
	second._on_power_ad_confirmed("bomb")
	_assert(live.completion.is_valid(), "a live manager must receive a completion")
	live.completion.callv([false])
	await process_frame
	_assert(PowerInventoryServiceType.count(second.power_state, "bomb") == owned,
		"dismissing a video without earning must grant nothing")
	_free(controller)
	_free(second)


## The defect this suite was written for: with no ad inventory the win screen
## kept app_flow_state at AD_SHOWING with its actions pending forever.
func _test_level_complete_never_strands_the_player() -> void:
	var controller = await _start(DeadAdManager.new())
	controller.won = true
	controller.level_reward_for_completion = 120
	controller._on_double_coins_requested()
	await process_frame
	_assert(controller.app_flow_state != controller.AppFlowState.AD_SHOWING,
		"an unavailable video must not leave the flow stuck in AD_SHOWING")
	_assert(not controller.result_overlay.actions_pending,
		"the win screen's actions must be re-enabled when no video opens")
	_free(controller)


## A player tapping impatiently must not queue several videos.
func _test_repeated_taps_cannot_stack_requests() -> void:
	var manager := RecordingAdManager.new()
	var controller = await _start(manager)
	controller._on_power_ad_confirmed("bomb")
	var first := manager.show_count
	controller._on_power_ad_confirmed("bomb")
	controller._on_power_ad_confirmed("bomb")
	_assert(manager.show_count == first,
		"repeated taps must not start another video while one is pending (started %d)" % manager.show_count)
	_free(controller)


## Coins are the alternative route and must keep working with ads dead.
func _test_coin_route_survives_when_ads_do_not() -> void:
	var controller = await _start(DeadAdManager.new())
	controller.coins = 5000
	controller.level_start_coins = 5000
	var before := PowerInventoryServiceType.count(controller.power_state, "bomb")
	_assert(controller._purchase_power("bomb"),
		"buying with coins must still work when no ad is available")
	_assert(PowerInventoryServiceType.count(controller.power_state, "bomb") == before + 1,
		"a coin purchase must grant the power")
	_free(controller)


func _start(manager: Node):
	var controller := GameControllerType.new()
	root.add_child(controller)
	await process_frame
	# After _ready, which would otherwise resolve the real AdManager autoload.
	controller.ad_manager = manager
	root.add_child(manager)
	controller.power_state = PowerInventoryServiceType.ensure_state({
		"counts": {"bomb": 0, "magnet": 0, "switch": 0, "hammer": 0},
		"granted_starter": true,
	})
	return controller


func _free(controller) -> void:
	if is_instance_valid(controller.ad_manager):
		controller.ad_manager.queue_free()
	controller.queue_free()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


## No inventory, ever - the current production situation.
class DeadAdManager extends Node:
	func is_rewarded_ready() -> bool: return false
	func is_interstitial_ready() -> bool: return false
	func is_privacy_options_available() -> bool: return false
	func is_fullscreen_showing() -> bool: return false
	func show_rewarded(_r: Callable, _f: Callable = Callable(), _c: Dictionary = {}) -> bool: return false
	func show_interstitial(_f: Callable = Callable(), _c: Dictionary = {}) -> bool: return false


## Reports ready and captures the callbacks without showing anything.
class RecordingAdManager extends Node:
	var reward := Callable()
	var completion := Callable()
	var show_count := 0
	func is_rewarded_ready() -> bool: return true
	func is_interstitial_ready() -> bool: return false
	func is_privacy_options_available() -> bool: return false
	func is_fullscreen_showing() -> bool: return show_count > 0
	func show_rewarded(on_reward: Callable, on_finished: Callable = Callable(), _c: Dictionary = {}) -> bool:
		reward = on_reward
		completion = on_finished
		show_count += 1
		return true
	func show_interstitial(_f: Callable = Callable(), _c: Dictionary = {}) -> bool: return false
