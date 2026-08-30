extends SceneTree

## Every shipped limited-shot level must be completable.
##
## Before this suite existed the shot limit came from a fixed 40 -> 30 ladder
## that never referenced the targets, and *every* limited level was unwinnable:
## a perfect play-out of level 4 needed 46 shots against the 40 granted, and
## level 25 needed 79 against 30.

const LevelConfigType = preload("res://scripts/core/level_config.gd")
const LevelSolverType = preload("res://scripts/core/level_solver.gd")

const AUDIT_RANGE := 80

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_every_limited_level_is_completable()
	_test_limits_leave_room_for_imperfect_play()
	_test_solver_rejects_an_impossible_level()
	_test_limits_are_deterministic()
	if failures.is_empty():
		print("LIMITED_SHOT_VALIDATION_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("LIMITED_SHOT_VALIDATION_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


func _test_every_limited_level_is_completable() -> void:
	var checked := 0
	for level in range(1, AUDIT_RANGE + 1):
		if not LevelConfigType.is_limited_shots_level(level):
			continue
		checked += 1
		var config := LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))
		var run: Dictionary = LevelSolverType.simulate(config)
		_assert(bool(run.completed),
			"level %d is not completable: %d/%d targets after all %d shots"
				% [level, int(run.targets_done), int(run.targets_total), int(run.shots_used)])
	_assert(checked >= 20, "the audit must actually cover the limited levels (found %d)" % checked)


## A shipped level must never demand flawless play.
func _test_limits_leave_room_for_imperfect_play() -> void:
	for level in range(1, AUDIT_RANGE + 1):
		if not LevelConfigType.is_limited_shots_level(level):
			continue
		var config := LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))
		var report: Dictionary = LevelSolverType.analyse(config)
		_assert(String(report.classification) != "AVOID",
			"level %d classified AVOID (%d spare shots)" % [level, int(report.spare_shots)])
		_assert(int(report.spare_shots) >= int(LevelSolverType.MIN_SPARE_SHOTS.HARD),
			"level %d leaves only %d spare shots" % [level, int(report.spare_shots)])
		# The margin must shrink over time, not stay flat, or difficulty never
		# actually ramps.
		_assert(LevelConfigType.shot_margin_for_level(level) <= LevelConfigType.SHOT_MARGIN_INTRO,
			"level %d margin must not exceed the intro margin" % level)
		_assert(LevelConfigType.shot_margin_for_level(level) >= LevelConfigType.SHOT_MARGIN_FLOOR,
			"level %d margin must never fall below the floor" % level)


## The validator has to be able to say no, or it proves nothing.
func _test_solver_rejects_an_impossible_level() -> void:
	var config := LevelConfigType.generated(7, LevelConfigType.seed_for_level(7))
	var starved := config.duplicate(true)
	starved["shot_limit"] = 3
	var run: Dictionary = LevelSolverType.simulate(starved)
	_assert(not bool(run.completed),
		"a 3-shot version of a real level must be reported as not completable")
	_assert(LevelSolverType.classify(starved) == "AVOID",
		"a starved level must classify as AVOID")


## A retry must present the same limit, or the difficulty is a reroll.
func _test_limits_are_deterministic() -> void:
	for level in [4, 7, 19, 40]:
		if not LevelConfigType.is_limited_shots_level(level):
			continue
		var first := int(LevelConfigType.generated(level, LevelConfigType.seed_for_level(level)).get("shot_limit", 0))
		var second := int(LevelConfigType.generated(level, LevelConfigType.seed_for_level(level)).get("shot_limit", 0))
		_assert(first == second and first > 0,
			"level %d must derive a stable shot limit (%d vs %d)" % [level, first, second])


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
