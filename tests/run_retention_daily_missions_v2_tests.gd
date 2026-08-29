extends SceneTree

## Regression coverage for the retention/daily-missions defects found in the V1
## implementation. Each test below fails against the previous behaviour.

const DailyMissionServiceType = preload("res://scripts/services/daily_mission_service.gd")
const ResultOverlayType = preload("res://scripts/ui/result_overlay_layer.gd")
const DailyMissionsOverlayType = preload("res://scripts/ui/daily_missions_overlay_layer.gd")
const HomeOverlayType = preload("res://scripts/ui/home_overlay_layer.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_service_is_pure()
	_test_progress_reports_change()
	_test_claim_does_not_mutate_until_persisted()
	_test_new_day_detection()
	await _test_result_overlay_restores_home_label()
	await _test_give_up_reaches_the_fail_screen()
	_test_daily_overlay_sits_above_home()
	if failures.is_empty():
		print("RETENTION_DAILY_MISSIONS_V2_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("RETENTION_DAILY_MISSIONS_V2_TESTS: FAIL (%d)" % failures.size())
	quit(1)


## The V1 service mutated the caller's Dictionary in place and returned the very
## same object, which made every change undetectable and every failed save
## unrecoverable.
func _test_service_is_pure() -> void:
	var state := DailyMissionServiceType.ensure_current_day({})
	var before_progress := int((state.missions[0] as Dictionary).get("progress", -1))
	var update := DailyMissionServiceType.record(state, "merge", 5)
	var returned: Dictionary = update.get("state", {}) as Dictionary
	_assert(int((state.missions[0] as Dictionary).get("progress", -1)) == before_progress,
		"record() must not mutate the state it was given")
	_assert(int((returned.missions[0] as Dictionary).get("progress", -1)) == before_progress + 5,
		"record() must return advanced progress in a new state")

	var claimable := DailyMissionServiceType.record(state, "merge", 999).get("state", {}) as Dictionary
	var claim := DailyMissionServiceType.claim_mission(claimable, 0)
	_assert(not bool((claimable.missions[0] as Dictionary).get("claimed", true)),
		"claim_mission() must not mark the caller's state claimed")
	_assert(bool(((claim.get("state", {}) as Dictionary).missions[0] as Dictionary).get("claimed", false)),
		"claim_mission() must return a state with the mission claimed")


## Progress persistence depended on comparing old and new state. With an aliased
## service that comparison was always false and nothing was ever saved.
func _test_progress_reports_change() -> void:
	var state := DailyMissionServiceType.ensure_current_day({})
	var first := DailyMissionServiceType.record(state, "merge", 3)
	_assert(bool(first.get("changed", false)), "Advancing a mission must report changed")
	var advanced: Dictionary = first.get("state", {}) as Dictionary
	var noop := DailyMissionServiceType.record(advanced, "level_complete", 0)
	_assert(not bool(noop.get("changed", true)), "A zero-amount record must report no change")
	var full := DailyMissionServiceType.record(advanced, "merge", 9999).get("state", {}) as Dictionary
	var capped := DailyMissionServiceType.record(full, "merge", 5)
	_assert(not bool(capped.get("changed", true)), "Recording past a completed target must report no change")


## A save failure must leave the player's reward intact rather than consuming it.
func _test_claim_does_not_mutate_until_persisted() -> void:
	var state := DailyMissionServiceType.record(
		DailyMissionServiceType.ensure_current_day({}), "merge", 9999).get("state", {}) as Dictionary
	var claim := DailyMissionServiceType.claim_mission(state, 0)
	_assert(bool(claim.get("ok", false)) and int(claim.get("reward", 0)) > 0, "A completed mission must be claimable")
	# Caller discards the result, simulating a failed save.
	var retry := DailyMissionServiceType.claim_mission(state, 0)
	_assert(bool(retry.get("ok", false)) and int(retry.get("reward", 0)) == int(claim.get("reward", 0)),
		"A discarded claim must remain claimable so a failed save never eats the reward")


func _test_new_day_detection() -> void:
	var today := DailyMissionServiceType.ensure_current_day({}, "2026-08-29")
	_assert(not DailyMissionServiceType.needs_new_day(today, "2026-08-29"), "Today's state must not request a new roll")
	_assert(DailyMissionServiceType.needs_new_day(today, "2026-08-30"), "A new date must request a fresh roll")
	_assert(DailyMissionServiceType.needs_new_day({}, "2026-08-29"), "Empty state must request a fresh roll")


## present_out_of_shots() relabels Home to GIVE UP; a later result screen must
## not inherit that wording.
func _test_result_overlay_restores_home_label() -> void:
	var overlay = ResultOverlayType.new()
	root.add_child(overlay)
	await process_frame
	overlay.present_out_of_shots(1000, 5, 300)
	_assert(overlay.home_button.text == "GIVE UP", "Out of shots must offer GIVE UP")
	overlay.dismiss()
	overlay.present(false, 1000, 3, 8, 0, false, false, 0)
	_assert(overlay.home_button.text == "HOME", "A later result screen must restore the HOME label")
	overlay.dismiss()
	overlay.queue_free()
	await process_frame


## Home is the only entry point to the daily popup, so the popup must sit above
## it. In V1 it was layered underneath and never became visible.
func _test_daily_overlay_sits_above_home() -> void:
	var home = HomeOverlayType.new()
	var daily = DailyMissionsOverlayType.new()
	root.add_child(home)
	root.add_child(daily)
	_assert(daily.layer > home.layer,
		"Daily missions (layer %d) must render above Home (layer %d)" % [daily.layer, home.layer])
	home.queue_free()
	daily.queue_free()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


## Declining the out-of-shots rescue must actually reach the fail screen.
## present() guards against double-presentation, and while rescue mode counted
## as "already visible" the guard swallowed the fail screen: GIVE UP looked
## completely dead while the level had already failed underneath.
func _test_give_up_reaches_the_fail_screen() -> void:
	var overlay = ResultOverlayType.new()
	root.add_child(overlay)
	await process_frame
	overlay.present_out_of_shots(1000, 5, 300)
	_assert(overlay.title_label.text == "OUT OF SHOTS", "Rescue screen must announce itself")
	_assert(overlay.home_button.text == "GIVE UP", "Rescue screen must offer GIVE UP")
	var declined := [false]
	overlay.extra_shots_declined.connect(func() -> void: declined[0] = true)
	overlay.home_button.emit_signal("pressed")
	await process_frame
	_assert(declined[0], "GIVE UP must report the decline")
	# The controller answers a decline by triggering failure, which presents the
	# fail result on this same overlay without dismissing first.
	var shown := overlay.present(false, 1000, 3, 8, 0, false, true, 800)
	_assert(shown, "The fail screen must present over a declined rescue")
	_assert(overlay.title_label.text == "TRY AGAIN", "Declining must land on the fail screen")
	_assert(overlay.home_button.text == "HOME", "The fail screen must restore the HOME label")
	_assert(overlay.skip_button.visible, "The fail screen must expose Skip Level")
	overlay.dismiss()
	overlay.queue_free()
	await process_frame
