extends SceneTree

## Missions were a fixed triple, so every day read as the same grind counters.
## They are now rolled from pools. This suite covers the two things that can go
## wrong with that: a set that never varies, and a set that asks for something
## the account cannot reach.

const DailyMissionServiceType = preload("res://scripts/services/daily_mission_service.gd")
const LevelConfigType = preload("res://scripts/core/level_config.gd")

## Every objective must be driven by an event the controller actually records.
const RECORDED_EVENTS := [
	"merge", "combo", "high_tier", "coins_earned",
	"level_complete", "limited_complete", "no_power_complete", "target_complete", "power_used",
]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_every_mission_type_is_actually_recorded()
	_test_sets_vary_across_days()
	_test_rolls_are_deterministic()
	_test_locked_content_is_never_asked_for()
	_test_rewards_scale_with_difficulty()
	if failures.is_empty():
		print("DAILY_MISSION_VARIETY_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("DAILY_MISSION_VARIETY_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


## A mission whose event is never recorded can never be completed.
func _test_every_mission_type_is_actually_recorded() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/gameplay/game_controller.gd")
	for day in _sample_days():
		for entry in DailyMissionServiceType.ensure_current_day({}, day, 99).get("missions", []):
			var mission: Dictionary = entry as Dictionary
			var type := String(mission.get("type", ""))
			_assert(RECORDED_EVENTS.has(type),
				"mission type '%s' is not in the recorded-event list" % type)
			_assert(source.contains("_record_daily_progress(\"%s\"" % type),
				"nothing in the controller records '%s', so the mission is uncompletable" % type)


func _test_sets_vary_across_days() -> void:
	var seen := {}
	for day in _sample_days():
		var labels := PackedStringArray()
		for entry in DailyMissionServiceType.ensure_current_day({}, day, 99).get("missions", []):
			labels.append(String((entry as Dictionary).get("label", "")))
		seen["/".join(labels)] = true
	_assert(seen.size() >= 3,
		"the daily set must vary across days (only %d distinct sets in 30 days)" % seen.size())


## A reload must not be able to reroll a day into easier objectives.
func _test_rolls_are_deterministic() -> void:
	for day in _sample_days():
		var first := JSON.stringify(DailyMissionServiceType.ensure_current_day({}, day, 99).get("missions", []))
		var second := JSON.stringify(DailyMissionServiceType.ensure_current_day({}, day, 99).get("missions", []))
		_assert(first == second, "the mission set for %s must be stable" % day)


## The player cannot beat a limited-shots level before one exists.
func _test_locked_content_is_never_asked_for() -> void:
	for level in range(1, LevelConfigType.FIRST_LIMITED_SHOTS_LEVEL):
		for day in _sample_days():
			for entry in DailyMissionServiceType.ensure_current_day({}, day, level).get("missions", []):
				_assert(String((entry as Dictionary).get("type", "")) != "limited_complete",
					"level %d cannot reach a limited-shots level, so that mission must not be offered" % level)
	# And it must become reachable once it exists, or the pool entry is dead.
	var offered := false
	for day in _sample_days():
		for entry in DailyMissionServiceType.ensure_current_day({}, day, 99).get("missions", []):
			if String((entry as Dictionary).get("type", "")) == "limited_complete":
				offered = true
	_assert(offered, "the limited-shots mission must actually be reachable at a high level")


func _test_rewards_scale_with_difficulty() -> void:
	for day in _sample_days():
		var missions: Array = DailyMissionServiceType.ensure_current_day({}, day, 99).get("missions", []) as Array
		_assert(missions.size() == DailyMissionServiceType.MISSION_COUNT,
			"a day must roll exactly %d missions" % DailyMissionServiceType.MISSION_COUNT)
		var easy := int((missions[0] as Dictionary).get("reward", 0))
		var medium := int((missions[1] as Dictionary).get("reward", 0))
		var hard := int((missions[2] as Dictionary).get("reward", 0))
		_assert(easy < medium and medium < hard,
			"rewards must rise with difficulty on %s (%d/%d/%d)" % [day, easy, medium, hard])
		for entry in missions:
			var mission: Dictionary = entry as Dictionary
			_assert(int(mission.get("progress", -1)) == 0, "a rolled mission must start at zero progress")
			_assert(not bool(mission.get("claimed", true)), "a rolled mission must start unclaimed")
			_assert(not String(mission.get("label", "")).is_empty(), "a rolled mission must carry a label")


func _sample_days() -> Array[String]:
	var days: Array[String] = []
	for index in range(30):
		days.append("2026-09-%02d" % (index + 1))
	return days


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
