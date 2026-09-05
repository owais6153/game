class_name GameSettingsService
extends RefCounted

const SAVE_PATH := "user://game_settings.cfg"

## Daily-reminder notifications default ON, matching how the rest of the
## retention loop behaves out of the box. Android 13+ still gates the actual
## delivery behind its own runtime permission, so "on" here means "the player
## has not opted out", not "notifications are definitely arriving".
static func defaults() -> Dictionary:
	return {
		"music_enabled": true,
		"sound_enabled": true,
		"vibration_enabled": false,
		"notifications_enabled": true,
	}

static func load_settings() -> Dictionary:
	var result := defaults()
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return result
	for key in result.keys():
		result[key] = bool(config.get_value("settings", key, result[key]))
	return result

## Preserves every key this call does not own.
##
## The previous version built a fresh ConfigFile and saved it, so it silently
## dropped any setting it did not take as a parameter - adding the notification
## preference to that would have meant a music toggle wiping it.
static func save_settings(music_enabled: bool, sound_enabled: bool, vibration_enabled: bool) -> Error:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("settings", "music_enabled", music_enabled)
	config.set_value("settings", "sound_enabled", sound_enabled)
	config.set_value("settings", "vibration_enabled", vibration_enabled)
	return config.save(SAVE_PATH)


## Separate from save_settings() so the notification toggle is never coupled to
## an audio change, and vice versa.
static func save_notifications_enabled(enabled: bool) -> Error:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("settings", "notifications_enabled", enabled)
	return config.save(SAVE_PATH)


static func notifications_enabled() -> bool:
	return bool(load_settings().get("notifications_enabled", true))

static func clear_settings() -> Error:
	if not FileAccess.file_exists(SAVE_PATH):
		return OK
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
