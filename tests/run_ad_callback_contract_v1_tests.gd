extends SceneTree

## Locks the rewarded-ad completion contract.
##
## AdManager._finish_rewarded invokes the completion via `callv([earned])`, so a
## completion declared with no parameter fails the call and its whole body is
## skipped. That is silent: the reward is still granted by the separate reward
## callback, so the inventory changes while the popup that reports it never
## opens. It shipped that way, and "I never see the reward popup after watching
## an ad" was the symptom.

const GameControllerType = preload("res://scripts/gameplay/game_controller.gd")
const AdManagerType = preload("res://scripts/services/ad_manager.gd")
const PowerInventoryServiceType = preload("res://scripts/services/power_inventory_service.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_completions_accept_the_earned_flag()
	await _test_dismissal_reports_the_result()
	if failures.is_empty():
		print("AD_CALLBACK_CONTRACT_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("AD_CALLBACK_CONTRACT_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


## Every completion handed to show_rewarded must survive being called the way
## AdManager actually calls it, with one argument.
func _test_completions_accept_the_earned_flag() -> void:
	var recorder := RewardedRecorder.new()
	root.add_child(recorder)
	var controller := GameControllerType.new()
	root.add_child(controller)
	await process_frame
	# After _ready, which resolves the real /root/AdManager autoload and would
	# otherwise overwrite the recorder.
	controller.ad_manager = recorder
	# Seeded explicitly: the rewarded daily cap lives in user://, so repeated
	# runs would otherwise exhaust the allowance and make this suite
	# order-dependent.
	controller.power_state = PowerInventoryServiceType.ensure_state({
		"counts": {"bomb": 0, "magnet": 0, "switch": 0, "hammer": 0},
		"granted_starter": true,
	})

	# Route every rewarded entry point through the recorder.
	controller._on_power_ad_confirmed("bomb")
	_assert(recorder.completion.is_valid(), "the power ad must hand AdManager a completion")
	_assert_callable_accepts(recorder.completion, "the power-ad completion")

	recorder.reset()
	controller._on_coin_ad_confirmed("extra_shots")
	if recorder.completion.is_valid():
		_assert_callable_accepts(recorder.completion, "the coin-action completion")

	controller.queue_free()
	recorder.queue_free()
	await process_frame


## The end-to-end behaviour the arity bug broke: after a completed video the
## player must land on the result panel, not be left staring at the offer.
func _test_dismissal_reports_the_result() -> void:
	var recorder := RewardedRecorder.new()
	root.add_child(recorder)
	var controller := GameControllerType.new()
	root.add_child(controller)
	await process_frame
	# After _ready, which resolves the real /root/AdManager autoload and would
	# otherwise overwrite the recorder.
	controller.ad_manager = recorder
	# Seeded explicitly: the rewarded daily cap lives in user://, so repeated
	# runs would otherwise exhaust the allowance and make this suite
	# order-dependent.
	controller.power_state = PowerInventoryServiceType.ensure_state({
		"counts": {"bomb": 0, "magnet": 0, "switch": 0, "hammer": 0},
		"granted_starter": true,
	})

	controller._on_power_ad_confirmed("bomb")
	_assert(controller.power_overlay.mode == controller.power_overlay.Mode.AD_OFFER
			or recorder.reward.is_valid(),
		"confirming the offer must start a video")

	# Drive AdManager's real order: reward first, then dismissal with the flag.
	if recorder.reward.is_valid():
		recorder.reward.call(null)
	if recorder.completion.is_valid():
		recorder.completion.callv([true])
	await process_frame

	_assert(controller.power_overlay.mode == controller.power_overlay.Mode.AD_RESULT,
		"a completed video must leave the player on the result panel, not the offer")
	controller.queue_free()
	recorder.queue_free()
	await process_frame


func _assert_callable_accepts(callable: Callable, label: String) -> void:
	# callv with one argument is exactly what _finish_rewarded does.
	var before := failures.size()
	callable.callv([true])
	_assert(failures.size() == before, "%s must not fail when called with the earned flag" % label)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


## Minimal stand-in for AdManager that captures the callbacks instead of
## showing anything, so the contract can be exercised without ad inventory.
class RewardedRecorder extends Node:
	var reward := Callable()
	var completion := Callable()

	func reset() -> void:
		reward = Callable()
		completion = Callable()

	func is_rewarded_ready() -> bool:
		return true

	func is_interstitial_ready() -> bool:
		return false

	func is_privacy_options_available() -> bool:
		return false

	func is_fullscreen_showing() -> bool:
		return false

	func show_rewarded(on_reward: Callable, on_finished: Callable = Callable(), _context: Dictionary = {}) -> bool:
		reward = on_reward
		completion = on_finished
		return true
