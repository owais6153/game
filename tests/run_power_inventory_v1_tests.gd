extends SceneTree

## Coverage for the power inventory foundation: purity, the one-time starter
## grant, the rewarded-ad daily caps that protect the coin sink, and the
## rollback-safe purchase/consume contract the controller depends on.

const PowerInventoryServiceType = preload("res://scripts/services/power_inventory_service.gd")
const ProgressionSaveServiceType = preload("res://scripts/services/progression_save_service.gd")

const TODAY := "2026-08-29"
const TOMORROW := "2026-08-30"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_service_is_pure()
	_test_starter_grant_applies_once()
	_test_state_is_normalised_from_hostile_saves()
	_test_purchase_respects_balance_and_price_order()
	_test_consume_reports_empty_inventory()
	_test_ad_grants_are_capped_per_power_and_per_day()
	_test_ad_grants_reset_next_day()
	_test_legacy_saves_load_without_power_state()
	if failures.is_empty():
		print("POWER_INVENTORY_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("POWER_INVENTORY_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


## The controller adopts a returned inventory only after persistence succeeds,
## which is only safe while no call mutates the state it was handed.
func _test_service_is_pure() -> void:
	var state := PowerInventoryServiceType.ensure_state({}, TODAY)
	var before := PowerInventoryServiceType.count(state, PowerInventoryServiceType.BOMB)

	var consumed := PowerInventoryServiceType.consume(state, PowerInventoryServiceType.BOMB)
	_assert(PowerInventoryServiceType.count(state, PowerInventoryServiceType.BOMB) == before,
		"consume() must not mutate the state it was given")
	_assert(PowerInventoryServiceType.count(consumed.state, PowerInventoryServiceType.BOMB) == before - 1,
		"consume() must return the decremented count in a new state")

	var purchased := PowerInventoryServiceType.purchase(state, 10000, PowerInventoryServiceType.BOMB)
	_assert(PowerInventoryServiceType.count(state, PowerInventoryServiceType.BOMB) == before,
		"purchase() must not mutate the state it was given")
	_assert(PowerInventoryServiceType.count(purchased.state, PowerInventoryServiceType.BOMB) == before + 1,
		"purchase() must return the incremented count in a new state")

	var granted := PowerInventoryServiceType.grant_from_ad(state, PowerInventoryServiceType.BOMB, TODAY)
	_assert(PowerInventoryServiceType.ad_grants_taken(state, PowerInventoryServiceType.BOMB) == 0,
		"grant_from_ad() must not mutate the state it was given")
	_assert(PowerInventoryServiceType.ad_grants_taken(granted.state, PowerInventoryServiceType.BOMB) == 1,
		"grant_from_ad() must record the grant in a new state")


## A new player must be able to discover powers in play, but re-normalising an
## existing save must never top the inventory back up.
func _test_starter_grant_applies_once() -> void:
	var fresh := PowerInventoryServiceType.ensure_state({}, TODAY)
	for power in PowerInventoryServiceType.ALL:
		_assert(PowerInventoryServiceType.count(fresh, power) == PowerInventoryServiceType.STARTER_GRANT,
			"a fresh inventory must grant one %s" % power)
	_assert(PowerInventoryServiceType.needs_normalisation({}, TODAY),
		"a fresh inventory must report that it needs persisting")

	var spent: Dictionary = PowerInventoryServiceType.consume(fresh, PowerInventoryServiceType.BOMB).state
	_assert(PowerInventoryServiceType.count(spent, PowerInventoryServiceType.BOMB) == 0,
		"spending the starter bomb must leave none owned")
	var reloaded := PowerInventoryServiceType.ensure_state(spent, TODAY)
	_assert(PowerInventoryServiceType.count(reloaded, PowerInventoryServiceType.BOMB) == 0,
		"re-normalising must not re-grant a spent starter power")
	_assert(not PowerInventoryServiceType.needs_normalisation(reloaded, TODAY),
		"an already-normalised inventory must not request a redundant save")


## ConfigFile hands back whatever was stored, so an older or hand-edited save
## can supply wrong types, negative counts, or an inflated grant total.
func _test_state_is_normalised_from_hostile_saves() -> void:
	var hostile := {
		"counts": {"bomb": -5, "magnet": "3", "nonsense": 99},
		"ad_grants": {"date": TODAY, "by_power": {"bomb": 999}, "total": -40},
		"granted_starter": true,
	}
	var state := PowerInventoryServiceType.ensure_state(hostile, TODAY)
	_assert(PowerInventoryServiceType.count(state, PowerInventoryServiceType.BOMB) == 0,
		"a negative stored count must clamp to zero, not stay negative")
	_assert(PowerInventoryServiceType.count(state, PowerInventoryServiceType.MAGNET) == 3,
		"a numeric string count must coerce to its integer value")
	_assert(not (state.get("counts", {}) as Dictionary).has("nonsense"),
		"an unknown power must not survive normalisation")
	_assert(PowerInventoryServiceType.ad_grants_taken(state, PowerInventoryServiceType.BOMB)
			== PowerInventoryServiceType.MAX_AD_GRANTS_PER_POWER_PER_DAY,
		"an inflated stored grant count must clamp to the per-power daily cap")
	_assert(PowerInventoryServiceType.ad_grants_remaining(state, PowerInventoryServiceType.BOMB) == 0,
		"a power already at its cap must offer no further grants")


func _test_purchase_respects_balance_and_price_order() -> void:
	var state := PowerInventoryServiceType.ensure_state({}, TODAY)
	var bomb_cost := PowerInventoryServiceType.purchase_cost(PowerInventoryServiceType.BOMB)

	var broke := PowerInventoryServiceType.purchase(state, bomb_cost - 1, PowerInventoryServiceType.BOMB)
	_assert(not bool(broke.ok), "purchasing without enough coins must fail")
	_assert(int(broke.resulting_coins) == bomb_cost - 1,
		"a failed purchase must leave the balance untouched")
	_assert(PowerInventoryServiceType.count(broke.state, PowerInventoryServiceType.BOMB)
			== PowerInventoryServiceType.count(state, PowerInventoryServiceType.BOMB),
		"a failed purchase must not grant the power")

	var exact := PowerInventoryServiceType.purchase(state, bomb_cost, PowerInventoryServiceType.BOMB)
	_assert(bool(exact.ok), "purchasing with exactly the price must succeed")
	_assert(int(exact.resulting_coins) == 0, "an exact purchase must spend the full price")

	# The ordering encodes how much each power can rescue; a future price edit
	# that breaks it would silently invert the intended sink hierarchy.
	_assert(PowerInventoryServiceType.purchase_cost(PowerInventoryServiceType.SWITCH)
			< PowerInventoryServiceType.purchase_cost(PowerInventoryServiceType.MAGNET)
			and PowerInventoryServiceType.purchase_cost(PowerInventoryServiceType.MAGNET)
			< PowerInventoryServiceType.purchase_cost(PowerInventoryServiceType.HAMMER)
			and PowerInventoryServiceType.purchase_cost(PowerInventoryServiceType.HAMMER)
			< PowerInventoryServiceType.purchase_cost(PowerInventoryServiceType.BOMB),
		"power prices must stay ordered switch < magnet < hammer < bomb")
	_assert(not PowerInventoryServiceType.can_purchase(state, 999999, "not_a_power"),
		"an unknown power must never be purchasable")


func _test_consume_reports_empty_inventory() -> void:
	var empty := PowerInventoryServiceType.ensure_state({"granted_starter": true}, TODAY)
	for power in PowerInventoryServiceType.ALL:
		_assert(PowerInventoryServiceType.count(empty, power) == 0,
			"an already-granted save with no counts must own no %s" % power)
		var attempt := PowerInventoryServiceType.consume(empty, power)
		_assert(not bool(attempt.ok),
			"consuming an unowned %s must report failure so the HUD can offer an ad" % power)
		_assert(PowerInventoryServiceType.count(attempt.state, power) == 0,
			"a failed consume must never drive the count negative")


## Without these caps a player could farm unlimited powers from rewarded ads and
## the purchase prices would stop mattering at all.
func _test_ad_grants_are_capped_per_power_and_per_day() -> void:
	var state := PowerInventoryServiceType.ensure_state({}, TODAY)
	var per_power := PowerInventoryServiceType.MAX_AD_GRANTS_PER_POWER_PER_DAY
	for index in range(per_power):
		var grant := PowerInventoryServiceType.grant_from_ad(state, PowerInventoryServiceType.BOMB, TODAY)
		_assert(bool(grant.ok), "grant %d of %d for one power must succeed" % [index + 1, per_power])
		state = grant.state
	_assert(not PowerInventoryServiceType.can_grant_from_ad(state, PowerInventoryServiceType.BOMB, TODAY),
		"a power at its per-power daily cap must offer no further grants")
	_assert(PowerInventoryServiceType.can_grant_from_ad(state, PowerInventoryServiceType.MAGNET, TODAY),
		"one power hitting its cap must not block a different power")

	var total_cap := PowerInventoryServiceType.MAX_AD_GRANTS_PER_DAY
	var taken := per_power
	for power in [PowerInventoryServiceType.MAGNET, PowerInventoryServiceType.SWITCH, PowerInventoryServiceType.HAMMER]:
		while taken < total_cap and PowerInventoryServiceType.can_grant_from_ad(state, power, TODAY):
			state = PowerInventoryServiceType.grant_from_ad(state, power, TODAY).state
			taken += 1
	_assert(taken == total_cap, "the daily total cap must be reachable across powers")
	for power in PowerInventoryServiceType.ALL:
		_assert(not PowerInventoryServiceType.can_grant_from_ad(state, power, TODAY),
			"the daily total cap must block %s even below its per-power cap" % power)
	var refused := PowerInventoryServiceType.grant_from_ad(state, PowerInventoryServiceType.SWITCH, TODAY)
	_assert(not bool(refused.ok), "a grant past the daily total cap must report failure")
	_assert(PowerInventoryServiceType.count(refused.state, PowerInventoryServiceType.SWITCH)
			== PowerInventoryServiceType.count(state, PowerInventoryServiceType.SWITCH),
		"a refused grant must not hand out the power anyway")


func _test_ad_grants_reset_next_day() -> void:
	var state := PowerInventoryServiceType.ensure_state({}, TODAY)
	for _index in range(PowerInventoryServiceType.MAX_AD_GRANTS_PER_POWER_PER_DAY):
		state = PowerInventoryServiceType.grant_from_ad(state, PowerInventoryServiceType.BOMB, TODAY).state
	var owned_before := PowerInventoryServiceType.count(state, PowerInventoryServiceType.BOMB)

	_assert(PowerInventoryServiceType.needs_normalisation(state, TOMORROW),
		"a date rollover must report that the reset needs persisting")
	var tomorrow := PowerInventoryServiceType.ensure_state(state, TOMORROW)
	_assert(PowerInventoryServiceType.ad_grants_taken(tomorrow, PowerInventoryServiceType.BOMB) == 0,
		"grant counters must reset on a new day")
	_assert(PowerInventoryServiceType.can_grant_from_ad(tomorrow, PowerInventoryServiceType.BOMB, TOMORROW),
		"a new day must offer grants again")
	_assert(PowerInventoryServiceType.count(tomorrow, PowerInventoryServiceType.BOMB) == owned_before,
		"a date rollover must reset the counters without touching owned powers")


## Every existing player's save predates the powers section entirely.
func _test_legacy_saves_load_without_power_state() -> void:
	var progress := ProgressionSaveServiceType.load_progress()
	_assert(progress.has("power_state"),
		"load_progress() must always supply a power_state key")
	_assert(progress.get("power_state") is Dictionary,
		"power_state must load as a Dictionary even when absent from the save")
	var state := PowerInventoryServiceType.ensure_state(progress.get("power_state", {}) as Dictionary, TODAY)
	for power in PowerInventoryServiceType.ALL:
		_assert(PowerInventoryServiceType.count(state, power) >= 0,
			"a legacy save must normalise into a valid %s count" % power)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
