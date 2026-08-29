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

static func ensure_current_day(state: Dictionary, date_key: String = "") -> Dictionary:
	var today := date_key if not date_key.is_empty() else Time.get_date_string_from_system()
	if String(state.get("date", "")) == today and (state.get("missions", []) as Array).size() == MISSION_COUNT:
		return state.duplicate(true)
	return {
		"date": today,
		"missions": _missions_for_day(today),
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

static func _missions_for_day(date_key: String) -> Array:
	# One easy, one medium, and one lightly challenging objective. All are
	# confirmed events that the controller already observes; no locked tier is
	# requested because every generated level can legitimately create local L6.
	var date_value := date_key.replace("-", "").to_int()
	var medium_complete := date_value % 2 == 0
	return [
		{"type": "merge", "target": 15, "progress": 0, "reward": 45, "claimed": false, "label": "Merge 15 Gems", "difficulty": "easy", "icon": "gems"},
		{"type": "level_complete" if medium_complete else "coins_earned", "target": 3 if medium_complete else 500, "progress": 0, "reward": 90, "claimed": false, "label": "Complete 3 Levels" if medium_complete else "Earn 500 Coins", "difficulty": "medium", "icon": "crown" if medium_complete else "coinbag"},
		{"type": "high_tier", "target": 1, "progress": 0, "reward": 140, "claimed": false, "label": "Create 1 High-Tier Gem", "difficulty": "challenging", "icon": "medal"},
	]
