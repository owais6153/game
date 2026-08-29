class_name ProgressionSaveService
extends RefCounted

const SAVE_PATH := "user://infinite_progression.cfg"

static func load_progress() -> Dictionary:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return {"level_number": 1, "seed": LevelConfig.seed_for_level(1), "total_coins": 0, "daily_state": {}}
	var level_number := maxi(1, int(config.get_value("progress", "level_number", 1)))
	return {
		"level_number": level_number,
		"seed": int(config.get_value("progress", "seed", LevelConfig.seed_for_level(level_number))),
		"total_coins": maxi(0, int(config.get_value("progress", "total_coins", 0))),
		"daily_state": config.get_value("retention", "daily_state", {}),
		# Level types whose briefing the player has already been shown. Absent on
		# every pre-existing save, which correctly reads as "nothing seen yet".
		"seen_level_types": _string_array(config.get_value("tutorial", "seen_level_types", [])),
	}


## ConfigFile hands back whatever was stored, so a hand-edited or older save can
## yield a non-array. Normalising here keeps every caller free of the check.
static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for entry in (value as Array):
			result.append(String(entry))
	return result


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

static func save_progress(level_number: int, seed_value: int, total_coins: int, daily_state: Dictionary = {}) -> Error:
	var config := ConfigFile.new()
	# Preserve the daily section for legacy callers that only persist level/coin
	# state. This makes old saves and existing transactions forward-compatible.
	config.load(SAVE_PATH)
	config.set_value("progress", "level_number", maxi(1, level_number))
	config.set_value("progress", "seed", seed_value)
	config.set_value("progress", "total_coins", maxi(0, total_coins))
	if not daily_state.is_empty():
		config.set_value("retention", "daily_state", daily_state)
	return config.save(SAVE_PATH)

static func clear_progress() -> Error:
	if not FileAccess.file_exists(SAVE_PATH):
		return OK
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
