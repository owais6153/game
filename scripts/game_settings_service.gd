class_name GameSettingsService
extends RefCounted

const SAVE_PATH := "user://game_settings.cfg"

static func defaults() -> Dictionary:
	return {"music_enabled": true, "sound_enabled": true, "vibration_enabled": true}

static func load_settings() -> Dictionary:
	var result := defaults()
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return result
	for key in result.keys():
		result[key] = bool(config.get_value("settings", key, result[key]))
	return result

static func save_settings(music_enabled: bool, sound_enabled: bool, vibration_enabled: bool) -> Error:
	var config := ConfigFile.new()
	config.set_value("settings", "music_enabled", music_enabled)
	config.set_value("settings", "sound_enabled", sound_enabled)
	config.set_value("settings", "vibration_enabled", vibration_enabled)
	return config.save(SAVE_PATH)

static func clear_settings() -> Error:
	if not FileAccess.file_exists(SAVE_PATH):
		return OK
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
