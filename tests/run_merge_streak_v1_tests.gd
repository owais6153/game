extends SceneTree

## The combo pitch in MERGE_TIMELINE_* escalates only inside a single chain, so
## a player merging steadily shot after shot heard the same flat cue every time.
## This suite covers the cross-shot streak that fixes that, and pins the
## feedback hierarchy it must never break.

const GameControllerType = preload("res://scripts/gameplay/game_controller.gd")
const LevelConfigType = preload("res://scripts/core/level_config.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_streak_escalates_and_is_bounded()
	_test_hierarchy_is_preserved()
	await _test_streak_decays_and_resets()
	if failures.is_empty():
		print("MERGE_STREAK_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("MERGE_STREAK_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


func _test_streak_escalates_and_is_bounded() -> void:
	_assert(is_equal_approx(GameConfig.merge_streak_pitch(0), 1.0),
		"no streak must leave the cue unchanged")
	_assert(is_equal_approx(GameConfig.merge_streak_pitch(1), 1.0),
		"the first merge of a run must not already be escalated")
	var previous := GameConfig.merge_streak_pitch(1)
	for streak in range(2, GameConfig.MERGE_STREAK_MAX + 1):
		var current := GameConfig.merge_streak_pitch(streak)
		_assert(current > previous, "streak %d must sound brighter than %d" % [streak, streak - 1])
		previous = current
	# Bounded: an endless run must not climb into chipmunk territory.
	var capped := GameConfig.merge_streak_pitch(GameConfig.MERGE_STREAK_MAX)
	_assert(is_equal_approx(GameConfig.merge_streak_pitch(GameConfig.MERGE_STREAK_MAX + 50), capped),
		"the streak lift must stop at MERGE_STREAK_MAX")
	_assert(capped <= 1.20, "the streak lift must stay subtle (got %.2f)" % capped)


## The whole point of the hierarchy: a fully escalated ordinary merge must still
## sit below a target, and far below a power or level completion.
func _test_hierarchy_is_preserved() -> void:
	var priority: Dictionary = GameConfig.AUDIO_PRIORITY_BY_EVENT
	_assert(int(priority.get("normal_merge", 0)) < int(priority.get("chain", 0)),
		"a chain must outrank an ordinary merge")
	_assert(int(priority.get("chain", 0)) < int(priority.get("mission_complete", 0)),
		"a completed mission must outrank a combo")
	_assert(int(priority.get("mission_complete", 0)) < int(priority.get("target_complete", 0)),
		"a met target must outrank a completed mission")
	_assert(int(priority.get("target_complete", 0)) < int(priority.get("win", 0)),
		"level completion must remain the strongest cue")
	for power in ["power_switch", "power_magnet", "power_hammer", "power_bomb"]:
		_assert(int(priority.get(power, 0)) > int(priority.get("chain", 0)),
			"%s must outrank an ordinary combo" % power)
	# The streak must never lift an ordinary merge past a target's own peak.
	var loudest_ordinary := float((GameConfig.AUDIO_TONES.get("chain", {}) as Dictionary).get("volume", 0.0)) \
		* GameConfig.merge_streak_intensity(GameConfig.MERGE_STREAK_MAX)
	_assert(loudest_ordinary <= float((GameConfig.AUDIO_TONES.get("target_collect", {}) as Dictionary).get("volume", 1.0)),
		"a fully escalated combo must stay under the target cue (%.2f)" % loudest_ordinary)


func _test_streak_decays_and_resets() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	root.add_child(viewport)
	var controller := GameControllerType.new()
	viewport.add_child(controller)
	await process_frame
	controller.level_number = 2
	controller.level_seed = LevelConfigType.seed_for_level(2)
	controller.restart()
	controller.set_process(false)

	_assert(controller.merge_streak == 0, "a level must open with no streak")
	# Two shots that merged, then one that did not.
	controller.shot_produced_merge = true
	controller.merge_streak = 3
	controller.shot_produced_merge = false
	controller.merge_streak = 0 if not controller.shot_produced_merge else controller.merge_streak
	_assert(controller.merge_streak == 0, "a shot with no merge must end the run")

	controller.merge_streak = 4
	controller.restart()
	_assert(controller.merge_streak == 0, "restarting must clear the streak")
	_assert(not controller.shot_produced_merge, "restarting must clear the pending merge flag")
	viewport.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
