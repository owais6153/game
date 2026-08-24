class_name ProgressionSaveService
extends RefCounted

const SAVE_PATH := "user://infinite_progression.cfg"

static func load_progress() -> Dictionary:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return {"level_number": 1, "seed": LevelConfig.seed_for_level(1), "total_coins": 0}
	var level_number := maxi(1, int(config.get_value("progress", "level_number", 1)))
	return {
		"level_number": level_number,
		"seed": int(config.get_value("progress", "seed", LevelConfig.seed_for_level(level_number))),
		"total_coins": maxi(0, int(config.get_value("progress", "total_coins", 0))),
	}

static func save_progress(level_number: int, seed_value: int, total_coins: int) -> Error:
	var config := ConfigFile.new()
	config.set_value("progress", "level_number", maxi(1, level_number))
	config.set_value("progress", "seed", seed_value)
	config.set_value("progress", "total_coins", maxi(0, total_coins))
	return config.save(SAVE_PATH)

static func clear_progress() -> Error:
	if not FileAccess.file_exists(SAVE_PATH):
		return OK
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
