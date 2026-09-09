class_name ProgressionSaveService
extends RefCounted

const SAVE_PATH := "user://infinite_progression.cfg"
const LevelStarsType = preload("res://scripts/core/level_stars.gd")

static func load_progress() -> Dictionary:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return {"level_number": 1, "highest_level": 1, "seed": LevelConfig.seed_for_level(1), "total_coins": 0, "daily_state": {}, "power_state": {}, "claimed_chests": [] as Array[int]}
	var level_number := maxi(1, int(config.get_value("progress", "level_number", 1)))
	return {
		"level_number": level_number,
		# The furthest level ever unlocked, which the level-select map reads as
		# the boundary between playable and locked. Absent on every save written
		# before level select existed; those players were always standing on
		# their furthest level, so it is exactly `level_number`. Clamped up to
		# `level_number` so a replay of an early level can never present the
		# rest of the map as locked.
		"highest_level": maxi(level_number, int(config.get_value("progress", "highest_level", level_number))),
		# Milestone chests already opened. Absent reads as "none opened yet",
		# which is correct for a save that predates them.
		"claimed_chests": _int_array(config.get_value("progress", "claimed_chests", [])),
		"seed": int(config.get_value("progress", "seed", LevelConfig.seed_for_level(level_number))),
		"total_coins": maxi(0, int(config.get_value("progress", "total_coins", 0))),
		"daily_state": config.get_value("retention", "daily_state", {}),
		# Absent on every pre-existing save, which PowerInventoryService.ensure_state
		# correctly reads as "no inventory yet" and resolves into the starter grant.
		"power_state": _dictionary(config.get_value("powers", "power_state", {})),
		# Level types whose briefing the player has already been shown. Absent on
		# every pre-existing save, which correctly reads as "nothing seen yet".
		"seen_level_types": _string_array(config.get_value("tutorial", "seen_level_types", [])),
		# Stars earned per level, keyed by level number. Absent on every save
		# written before stars existed, which correctly reads as "none earned" -
		# levels already cleared are not retroactively credited, because the game
		# has no record of how they were cleared and awarding three would make
		# the first star meaningless everywhere behind the player.
		"level_stars": _star_map(config.get_value("progress", "level_stars", {})),
	}


## Stars are stored as a `level -> count` Dictionary. ConfigFile hands back
## whatever was written, and keys survive a round trip as ints or as strings
## depending on how they were set, so both are normalised to int keys here and
## the count is clamped - a hand-edited save must not be able to inflate the
## total the level map prints.
static func _star_map(value: Variant) -> Dictionary:
	var result := {}
	if not (value is Dictionary):
		return result
	for key in (value as Dictionary).keys():
		var level := int(str(key).to_int()) if key is String else int(key)
		if level <= 0:
			continue
		result[level] = clampi(int((value as Dictionary)[key]), 0, LevelStarsType.MAX_STARS)
	return result


## Records the stars earned on one level. Monotonic: a replay that earns fewer
## stars never takes back what the player already has, which is what lets a
## player go back to an old level to try for a star they missed without risking
## the ones they hold.
##
## Separate from save_progress() so earning a star is never coupled to a coin
## transaction, and so a failed star write cannot roll back a banked reward.
static func save_level_stars(level_number: int, stars: int) -> Error:
	if level_number <= 0:
		return OK
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	var stored := _star_map(config.get_value("progress", "level_stars", {}))
	var earned := clampi(stars, 0, LevelStarsType.MAX_STARS)
	if int(stored.get(level_number, 0)) >= earned:
		return OK
	stored[level_number] = earned
	config.set_value("progress", "level_stars", stored)
	return config.save(SAVE_PATH)


## ConfigFile hands back whatever was stored, so a hand-edited or older save can
## yield a non-array. Normalising here keeps every caller free of the check.
static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for entry in (value as Array):
			result.append(String(entry))
	return result


## Milestone chest indices. Same normalisation contract as _string_array: a
## hand-edited or older save can hold anything at all.
static func _int_array(value: Variant) -> Array[int]:
	var result: Array[int] = []
	if value is Array:
		for entry in (value as Array):
			result.append(int(entry))
	return result


## ConfigFile hands back whatever was stored, so a hand-edited or older save can
## yield a non-dictionary where an inventory is expected.
static func _dictionary(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


## Persists power ownership alongside the coin balance in one write, because
## every power transaction moves both: a purchase spends coins for a power, and
## a rewarded grant leaves coins untouched but must not lose a concurrent coin
## change. Callers adopt the new inventory only after this returns OK.
static func save_power_state(power_state: Dictionary, total_coins: int) -> Error:
	var config := ConfigFile.new()
	# Preserve every other section; this write owns only powers and the balance.
	config.load(SAVE_PATH)
	config.set_value("powers", "power_state", power_state)
	config.set_value("progress", "total_coins", maxi(0, total_coins))
	return config.save(SAVE_PATH)


## Records that a level type's briefing has been shown. Separate from
## save_progress() so a briefing is never coupled to a coin transaction.
static func mark_level_type_seen(level_type: String) -> Error:
	if level_type.is_empty():
		return OK
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	var seen := _string_array(config.get_value("tutorial", "seen_level_types", []))
	if seen.has(level_type):
		return OK
	seen.append(level_type)
	config.set_value("tutorial", "seen_level_types", seen)
	return config.save(SAVE_PATH)

## `highest_level` only ever rises. Every caller passes the level the player is
## now standing on, and replaying an earlier level is an ordinary save of a
## lower `level_number` - so taking the maximum against what is already stored
## is what keeps a replay of level 5 from re-locking levels 6 through 40. Pass 0
## (the default) to derive it from `level_number`, which is what every caller
## that predates level select wants.
static func save_progress(level_number: int, seed_value: int, total_coins: int, daily_state: Dictionary = {}, highest_level: int = 0) -> Error:
	var config := ConfigFile.new()
	# Preserve the daily section for legacy callers that only persist level/coin
	# state. This makes old saves and existing transactions forward-compatible.
	config.load(SAVE_PATH)
	var stored_highest := int(config.get_value("progress", "highest_level", 0))
	config.set_value("progress", "level_number", maxi(1, level_number))
	config.set_value("progress", "highest_level", maxi(stored_highest, maxi(maxi(1, level_number), highest_level)))
	config.set_value("progress", "seed", seed_value)
	config.set_value("progress", "total_coins", maxi(0, total_coins))
	if not daily_state.is_empty():
		config.set_value("retention", "daily_state", daily_state)
	return config.save(SAVE_PATH)


## Records an opened milestone chest alongside the coin balance the grant left
## behind. Both move together for the same reason the daily chest couples them:
## a save that banked the coins but forgot the chest would pay out forever.
static func save_claimed_chest(chest_index: int, claimed_chests: Array[int], total_coins: int) -> Error:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	var stored := _int_array(config.get_value("progress", "claimed_chests", []))
	for entry in claimed_chests:
		if not stored.has(entry):
			stored.append(entry)
	if chest_index > 0 and not stored.has(chest_index):
		stored.append(chest_index)
	stored.sort()
	config.set_value("progress", "claimed_chests", stored)
	config.set_value("progress", "total_coins", maxi(0, total_coins))
	return config.save(SAVE_PATH)

static func clear_progress() -> Error:
	if not FileAccess.file_exists(SAVE_PATH):
		return OK
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


## Powers whose first-use tutorial has already been shown. Absent on every
## pre-existing save, which correctly reads as "nothing seen yet".
static func seen_power_tutorials() -> Array[String]:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	return _string_array(config.get_value("tutorial", "seen_power_tutorials", []))


## Separate from save_progress() so showing a tutorial is never coupled to a
## coin or inventory transaction.
static func mark_power_tutorial_seen(power: String) -> Error:
	if power.is_empty():
		return OK
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	var seen := _string_array(config.get_value("tutorial", "seen_power_tutorials", []))
	if seen.has(power):
		return OK
	seen.append(power)
	config.set_value("tutorial", "seen_power_tutorials", seen)
	return config.save(SAVE_PATH)
