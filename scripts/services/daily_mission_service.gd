class_name DailyMissionService
extends RefCounted

## Local-only, deterministic daily missions. The service deliberately has no
## timers or polling: callers invoke ensure_current_day() at startup and record
## confirmed controller events as they happen. Device-clock changes can affect
## this V1 by design; server time is outside this sprint.
##
## Every public call is pure: the supplied state is never mutated and each
## result carries a freshly duplicated Dictionary. Callers therefore keep the
## previous state intact until a save succeeds, which is what makes the
## "deduct or grant only after persistence" rule in the controller possible.

const MISSION_COUNT := 3
## The daily chest pays powers rather than coins. Coins already arrive from every
## level win and every mission claim, so another coin payout added nothing the
## player could not already get; powers are the one reward the daily loop can
## grant that is not otherwise purchasable without spending.
##
## Two of the cheaper powers plus one premium power: enough to be worth the
## three missions, well short of removing the reason to buy any.
const CHEST_POWER_REWARD := {"switch": 2, "magnet": 1, "hammer": 1}
## Retained so an in-flight save or an older analytics row still resolves.
const CHEST_REWARD := 0
## Matches LevelConfig.FIRST_LIMITED_SHOTS_LEVEL. Held locally so this pure
## service keeps no dependency on level generation.
const LIMITED_SHOTS_UNLOCK_LEVEL := 4

static func ensure_current_day(state: Dictionary, date_key: String = "", unlocked_level: int = 1) -> Dictionary:
	var today := date_key if not date_key.is_empty() else Time.get_date_string_from_system()
	if String(state.get("date", "")) == today and (state.get("missions", []) as Array).size() == MISSION_COUNT:
		return state.duplicate(true)
	return {
		"date": today,
		"missions": _missions_for_day(today, unlocked_level),
		"chest_claimed": false,
	}


## True when the supplied state does not describe today's mission set, i.e. a
## fresh roll is required. Callers use this to persist and report the roll once.
static func needs_new_day(state: Dictionary, date_key: String = "") -> bool:
	var today := date_key if not date_key.is_empty() else Time.get_date_string_from_system()
	return String(state.get("date", "")) != today or (state.get("missions", []) as Array).size() != MISSION_COUNT

static func record(state: Dictionary, event_type: String, amount: int = 1) -> Dictionary:
	var result := ensure_current_day(state)
	var changed := needs_new_day(state)
	if amount <= 0:
		return {"state": result, "changed": changed}
	var missions: Array = result.get("missions", []) as Array
	for index in range(missions.size()):
		var mission: Dictionary = (missions[index] as Dictionary).duplicate(true)
		if bool(mission.get("claimed", false)) or String(mission.get("type", "")) != event_type:
			continue
		var target := int(mission.get("target", 1))
		var before := int(mission.get("progress", 0))
		var after := mini(target, before + amount)
		if after == before:
			continue
		mission["progress"] = after
		missions[index] = mission
		changed = true
	result["missions"] = missions
	return {"state": result, "changed": changed}

static func claim_mission(state: Dictionary, index: int) -> Dictionary:
	var result := ensure_current_day(state)
	var missions: Array = result.get("missions", []) as Array
	if index < 0 or index >= missions.size():
		return {"state": result, "reward": 0, "ok": false}
	var mission: Dictionary = (missions[index] as Dictionary).duplicate(true)
	if bool(mission.get("claimed", false)) or int(mission.get("progress", 0)) < int(mission.get("target", 1)):
		return {"state": result, "reward": 0, "ok": false}
	mission["claimed"] = true
	missions[index] = mission
	result["missions"] = missions
	return {"state": result, "reward": int(mission.get("reward", 0)), "ok": true, "mission": mission}

static func claim_chest(state: Dictionary) -> Dictionary:
	var result := ensure_current_day(state)
	if bool(result.get("chest_claimed", false)) or not all_missions_claimed(result):
		return {"state": result, "reward": 0, "ok": false}
	result["chest_claimed"] = true
	return {"state": result, "reward": CHEST_REWARD, "powers": CHEST_POWER_REWARD.duplicate(), "ok": true}

static func all_missions_claimed(state: Dictionary) -> bool:
	var missions: Array = state.get("missions", []) as Array
	return missions.size() == MISSION_COUNT and missions.all(func(mission: Dictionary) -> bool: return bool(mission.get("claimed", false)))

static func chest_ready(state: Dictionary) -> bool:
	return all_missions_claimed(state) and not bool(state.get("chest_claimed", false))

static func _missions_for_day(date_key: String, unlocked_level: int = 1) -> Array:
	# One easy, one medium, one challenging, drawn from pools rather than a fixed
	# triple so the day-to-day set varies instead of reading as the same three
	# grind counters forever. Every objective is built from a confirmed
	# controller event, and each pool is gated by what the player can actually
	# reach, so a mission is never impossible for the account it is rolled for.
	var date_value := date_key.replace("-", "").to_int()
	var easy := [
		{"type": "merge", "target": 15, "reward": 45, "label": "Merge 15 Gems", "icon": "gems"},
		{"type": "merge", "target": 25, "reward": 55, "label": "Merge 25 Gems", "icon": "gems"},
		{"type": "target_complete", "target": 3, "reward": 50, "label": "Complete 3 Targets", "icon": "medal"},
	]
	var medium := [
		{"type": "level_complete", "target": 3, "reward": 90, "label": "Complete 3 Levels", "icon": "crown"},
		{"type": "coins_earned", "target": 500, "reward": 90, "label": "Earn 500 Coins", "icon": "coinbag"},
		{"type": "combo", "target": 8, "reward": 95, "label": "Make 8 Combos", "icon": "flame"},
		{"type": "power_used", "target": 3, "reward": 85, "label": "Use 3 Powers", "icon": "shield"},
	]
	var challenging := [
		{"type": "high_tier", "target": 1, "reward": 140, "label": "Create 1 High-Tier Gem", "icon": "medal"},
		{"type": "no_power_complete", "target": 1, "reward": 130, "label": "Finish a Level Without Powers", "icon": "shield"},
	]
	# Limited-shot levels do not exist before FIRST_LIMITED_SHOTS_LEVEL, so the
	# objective is only offered once the player can actually meet it.
	if unlocked_level >= LIMITED_SHOTS_UNLOCK_LEVEL:
		challenging.append({"type": "limited_complete", "target": 1, "reward": 150, "label": "Beat a Limited-Shots Level", "icon": "timer"})
	return [
		_roll(easy, date_value, 0, "easy"),
		_roll(medium, date_value, 1, "medium"),
		_roll(challenging, date_value, 2, "challenging"),
	]


## Deterministic pick: the same date always yields the same set, so a reload
## cannot reroll a day into easier objectives.
static func _roll(pool: Array, date_value: int, slot: int, difficulty: String) -> Dictionary:
	# Mixed rather than divided. Dividing by a power of seven left the index
	# almost constant across a month - consecutive dates differ by one, so the
	# quotient only moved every 49 days and the "variety" never actually varied.
	var mixed := (date_value + slot * 7919) * 2654435761
	var chosen: Dictionary = (pool[posmod(mixed >> 11, pool.size())] as Dictionary).duplicate(true)
	chosen["progress"] = 0
	chosen["claimed"] = false
	chosen["difficulty"] = difficulty
	return chosen
