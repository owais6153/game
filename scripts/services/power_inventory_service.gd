class_name PowerInventoryService
extends RefCounted

## Local-only power ownership, purchase pricing, and rewarded-ad grant limits.
##
## Every public call is pure in exactly the same sense as DailyMissionService:
## the supplied state is never mutated and each result carries a freshly
## duplicated Dictionary. That is what lets the controller keep the previous
## inventory intact until persistence succeeds, so a failed save can never
## consume or grant a power. Presentation reads these values and never owns
## economy rules.
##
## Powers are the game's primary coin sink. Switch was previously a direct
## -100 coin action at the moment of use; it is now an owned power like the
## others, bought ahead of time or earned from a rewarded ad.

const BOMB := "bomb"
const MAGNET := "magnet"
const SWITCH := "switch"
const HAMMER := "hammer"

## Display order. The HUD, shop, and Not Enough Coins popup all read this, so
## the four powers always appear in the same left-to-right order everywhere.
const ALL: Array[String] = [BOMB, MAGNET, SWITCH, HAMMER]

## Prices sit against the established economy: a level win banks 100, the daily
## chest 180, and the existing escape hatches cost 300 (extra shots), 500
## (continue), and 800 (skip). Powers are deliberately priced between a single
## win and an escape hatch so stockpiling is a real decision rather than
## pocket change, and so the ordering matches how much each power can rescue:
## Switch nudges one shot, Magnet sets up one merge, Hammer removes one
## mistake, and Bomb clears a whole cluster.
const PURCHASE_COST := {
	SWITCH: 120,
	MAGNET: 200,
	HAMMER: 260,
	BOMB: 350,
}

## New players receive one of each so powers are discoverable in play rather
## than only in the shop, and so an early hard level is never gated behind a
## purchase the player cannot yet afford. Applied exactly once per save.
const STARTER_GRANT := 1

## Rewarded-ad grants are capped per power and overall per day. Without these
## caps a player could farm unlimited powers from ads and the coin sink — the
## entire point of the pricing above — would collapse.
const MAX_AD_GRANTS_PER_POWER_PER_DAY := 3
const MAX_AD_GRANTS_PER_DAY := 6

const LABELS := {
	BOMB: "Bomb",
	MAGNET: "Magnet",
	SWITCH: "Switch",
	HAMMER: "Hammer",
}

const DESCRIPTIONS := {
	BOMB: "Clears a cluster of gems around the spot you pick.",
	MAGNET: "Pulls matching gems toward your current gem.",
	SWITCH: "Changes your current gem to another one.",
	HAMMER: "Destroys one gem you choose.",
}


static func is_power(power: String) -> bool:
	return ALL.has(power)


## Normalises any stored, absent, or hand-edited state into a complete and
## valid inventory: clamps counts, applies the one-time starter grant, and
## rolls the rewarded-ad counters over when the date changes.
static func ensure_state(state: Dictionary, date_key: String = "") -> Dictionary:
	var today := date_key if not date_key.is_empty() else Time.get_date_string_from_system()
	var source := state if state != null else {}
	var stored_counts: Dictionary = source.get("counts", {}) if source.get("counts", {}) is Dictionary else {}
	var granted_starter := bool(source.get("granted_starter", false))
	var counts := {}
	for power in ALL:
		var owned := maxi(0, int(stored_counts.get(power, 0)))
		if not granted_starter:
			owned += STARTER_GRANT
		counts[power] = owned
	var stored_grants: Dictionary = source.get("ad_grants", {}) if source.get("ad_grants", {}) is Dictionary else {}
	var ad_grants := _empty_ad_grants(today)
	if String(stored_grants.get("date", "")) == today:
		var stored_by_power: Dictionary = stored_grants.get("by_power", {}) if stored_grants.get("by_power", {}) is Dictionary else {}
		var by_power := {}
		var total := 0
		for power in ALL:
			var granted := clampi(int(stored_by_power.get(power, 0)), 0, MAX_AD_GRANTS_PER_POWER_PER_DAY)
			by_power[power] = granted
			total += granted
		ad_grants["by_power"] = by_power
		# Trust the recomputed per-power sum over a stored total, so an edited
		# or truncated save can never hand back more grants than were taken.
		ad_grants["total"] = mini(total, MAX_AD_GRANTS_PER_DAY)
	return {
		"counts": counts,
		"ad_grants": ad_grants,
		"granted_starter": true,
	}


## True when the supplied state does not already match what ensure_state would
## produce, i.e. a save is required. Callers use this to persist the starter
## grant or a daily rollover exactly once.
static func needs_normalisation(state: Dictionary, date_key: String = "") -> bool:
	var source := state if state != null else {}
	if not bool(source.get("granted_starter", false)):
		return true
	var today := date_key if not date_key.is_empty() else Time.get_date_string_from_system()
	var stored_grants: Dictionary = source.get("ad_grants", {}) if source.get("ad_grants", {}) is Dictionary else {}
	# A fresh save has no grant record at all; that only needs writing once a
	# grant is actually taken, so an absent record on today's date is fine.
	if stored_grants.is_empty():
		return false
	return String(stored_grants.get("date", "")) != today


static func count(state: Dictionary, power: String) -> int:
	if not is_power(power):
		return 0
	var counts: Dictionary = state.get("counts", {}) if state.get("counts", {}) is Dictionary else {}
	return maxi(0, int(counts.get(power, 0)))


static func owns(state: Dictionary, power: String) -> bool:
	return count(state, power) > 0


static func purchase_cost(power: String) -> int:
	return int(PURCHASE_COST.get(power, 0))


static func label(power: String) -> String:
	return String(LABELS.get(power, power.capitalize()))


static func description(power: String) -> String:
	return String(DESCRIPTIONS.get(power, ""))


static func can_purchase(state: Dictionary, coins: int, power: String) -> bool:
	return is_power(power) and coins >= purchase_cost(power)


## Spends coins for one power. Returns the resulting inventory and balance
## without applying either; the caller persists first and only then adopts the
## result, matching the controller's existing rollback-safe coin contract.
static func purchase(state: Dictionary, coins: int, power: String) -> Dictionary:
	var result := ensure_state(state)
	if not can_purchase(result, coins, power):
		return {"state": result, "ok": false, "cost": purchase_cost(power), "resulting_coins": coins}
	var cost := purchase_cost(power)
	var counts: Dictionary = (result.get("counts", {}) as Dictionary).duplicate()
	counts[power] = int(counts.get(power, 0)) + 1
	result["counts"] = counts
	return {"state": result, "ok": true, "cost": cost, "resulting_coins": coins - cost}


static func ad_grants_taken(state: Dictionary, power: String) -> int:
	var ad_grants: Dictionary = state.get("ad_grants", {}) if state.get("ad_grants", {}) is Dictionary else {}
	var by_power: Dictionary = ad_grants.get("by_power", {}) if ad_grants.get("by_power", {}) is Dictionary else {}
	return maxi(0, int(by_power.get(power, 0)))


static func ad_grants_remaining(state: Dictionary, power: String) -> int:
	if not is_power(power):
		return 0
	var ad_grants: Dictionary = state.get("ad_grants", {}) if state.get("ad_grants", {}) is Dictionary else {}
	var total := maxi(0, int(ad_grants.get("total", 0)))
	return maxi(0, mini(
		MAX_AD_GRANTS_PER_POWER_PER_DAY - ad_grants_taken(state, power),
		MAX_AD_GRANTS_PER_DAY - total
	))


static func can_grant_from_ad(state: Dictionary, power: String, date_key: String = "") -> bool:
	return ad_grants_remaining(ensure_state(state, date_key), power) > 0


## Grants exactly one power for a completed rewarded ad. The caller must only
## invoke this from the reward callback, never from ad dismissal, so a
## cancelled or failed ad grants nothing and consumes no daily allowance.
static func grant_from_ad(state: Dictionary, power: String, date_key: String = "") -> Dictionary:
	var result := ensure_state(state, date_key)
	if ad_grants_remaining(result, power) <= 0:
		return {"state": result, "ok": false}
	var counts: Dictionary = (result.get("counts", {}) as Dictionary).duplicate()
	counts[power] = int(counts.get(power, 0)) + 1
	result["counts"] = counts
	var ad_grants: Dictionary = (result.get("ad_grants", {}) as Dictionary).duplicate(true)
	var by_power: Dictionary = ad_grants.get("by_power", {}) as Dictionary
	by_power[power] = int(by_power.get(power, 0)) + 1
	ad_grants["by_power"] = by_power
	ad_grants["total"] = int(ad_grants.get("total", 0)) + 1
	result["ad_grants"] = ad_grants
	return {"state": result, "ok": true}


## Spends one owned power. Returns ok=false when none are owned, so the caller
## can open the Not Enough Coins / rewarded-ad offer instead of failing silently.
static func consume(state: Dictionary, power: String) -> Dictionary:
	var result := ensure_state(state)
	if not owns(result, power):
		return {"state": result, "ok": false}
	var counts: Dictionary = (result.get("counts", {}) as Dictionary).duplicate()
	counts[power] = int(counts.get(power, 0)) - 1
	result["counts"] = counts
	return {"state": result, "ok": true}


static func _empty_ad_grants(date_key: String) -> Dictionary:
	var by_power := {}
	for power in ALL:
		by_power[power] = 0
	return {"date": date_key, "by_power": by_power, "total": 0}
