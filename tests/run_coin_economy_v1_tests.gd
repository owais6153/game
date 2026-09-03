extends SceneTree

## The coin economy must stay in proportion to its sinks.
##
## It had not been: one level paid 2,950 coins while the most expensive sink was
## Skip Level at 800 and the priciest power was 350, so a player owned every
## power several times over before finishing the first level and coins meant
## nothing. Every sink and mission reward had been tuned against an income
## roughly ten times smaller than the one actually being paid. Nothing in the
## suite noticed, because each number was only ever asserted on its own.

const GameConfigType = preload("res://scripts/core/game_config.gd")
const LevelConfigType = preload("res://scripts/core/level_config.gd")
const PowerInventoryServiceType = preload("res://scripts/services/power_inventory_service.gd")
const DailyMissionServiceType = preload("res://scripts/services/daily_mission_service.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_a_power_costs_about_a_level()
	_test_escape_hatches_stay_expensive()
	_test_rewards_rise_with_tier()
	_test_a_day_of_missions_is_worth_less_than_grinding_levels()
	if failures.is_empty():
		print("COIN_ECONOMY_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("COIN_ECONOMY_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


func _level_income(level: int) -> int:
	var config := LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))
	var total := 0
	for entry in (config.get("target_sequence", []) as Array):
		var target: Dictionary = entry as Dictionary
		total += GameConfigType.target_coin_reward_for_result_level(int(target.get("tier", 6))) \
			* maxi(1, int(target.get("quantity", 1)))
	return total


## Buying a power has to be a decision, not a rounding error.
func _test_a_power_costs_about_a_level() -> void:
	var income := _level_income(1)
	_assert(income > 0, "a level must pay something")
	for power in PowerInventoryServiceType.ALL:
		var cost := PowerInventoryServiceType.purchase_cost(power)
		var levels := float(cost) / float(income)
		_assert(levels >= 0.2,
			"%s costs only %.2f of a level's income - too cheap to matter" % [power, levels])
		_assert(levels <= 2.0,
			"%s costs %.2f levels - too far out of reach" % [power, levels])


## Skip and the rescues must stay the expensive options, or they stop being
## meaningful choices.
func _test_escape_hatches_stay_expensive() -> void:
	var income := _level_income(1)
	var priciest_power := 0
	for power in PowerInventoryServiceType.ALL:
		priciest_power = maxi(priciest_power, PowerInventoryServiceType.purchase_cost(power))
	_assert(GameConfigType.SKIP_LEVEL_COST > priciest_power,
		"Skip Level must cost more than the priciest power")
	_assert(GameConfigType.CONTINUE_COST > GameConfigType.EXTRA_SHOTS_COST,
		"a full continue must cost more than a handful of extra shots")
	_assert(float(GameConfigType.SKIP_LEVEL_COST) / float(income) >= 1.0,
		"Skip Level must cost at least a level's income, or skipping pays for itself")
	# And nothing may be so expensive it is unreachable in a sensible session.
	_assert(float(GameConfigType.SKIP_LEVEL_COST) / float(income) <= 4.0,
		"Skip Level must stay reachable within a few levels")


func _test_rewards_rise_with_tier() -> void:
	var previous := 0
	for tier in range(2, 9):
		var reward := GameConfigType.target_coin_reward_for_result_level(tier)
		_assert(reward > previous,
			"tier %d must pay more than tier %d (%d vs %d)" % [tier, tier - 1, reward, previous])
		previous = reward
	# Later levels ask for more, so they must pay more. Compared as an average
	# over a window rather than level-to-level: from 1.0.17 a given level may be
	# a short limited round or a long climb depending on its template, so any
	# single pair of levels can legitimately run the wrong way. What must hold is
	# that income rises across the run.
	var early_income := 0
	var late_income := 0
	for level in range(1, 21):
		early_income += _level_income(level)
		late_income += _level_income(level + 60)
	_assert(late_income > early_income,
		"later levels must pay more overall (%d early, %d late)" % [early_income, late_income])


## Missions should reward returning, without replacing play as the main source.
func _test_a_day_of_missions_is_worth_less_than_grinding_levels() -> void:
	var daily := 0
	for entry in (DailyMissionServiceType.ensure_current_day({}, "2026-09-04", 99).get("missions", []) as Array):
		daily += int((entry as Dictionary).get("reward", 0))
	var income := _level_income(1)
	_assert(daily > 0, "a day of missions must pay something")
	_assert(daily < income * 3,
		"a day of missions (%d) must not dwarf playing levels (%d each)" % [daily, income])
	_assert(daily >= income / 4,
		"a day of missions (%d) must be worth coming back for against %d a level" % [daily, income])


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
