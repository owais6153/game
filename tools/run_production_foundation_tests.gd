extends SceneTree

const GameScene = preload("res://scenes/Game.tscn")
const LevelConfigType = preload("res://scripts/level_config.gd")
const GameSettingsServiceType = preload("res://scripts/game_settings_service.gd")
const AssetCatalogType = preload("res://scripts/asset_catalog.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_branding_configuration()
	_test_difficulty_progression()
	_test_settings_persistence()
	await _test_runtime_settings_and_shared_gem_shape()
	if failures.is_empty():
		print("PRODUCTION_FOUNDATION_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _test_branding_configuration() -> void:
	var expected_icon := "res://assets/runtime/ui/gem_rush_app_icon_v1.png"
	_check(String(ProjectSettings.get_setting("application/config/name")) == "Gem Rush", "Application name must use the player-facing Gem Rush brand")
	_check(String(ProjectSettings.get_setting("application/config/icon")) == expected_icon, "Launcher icon must use the Gem Rush logo asset")
	_check(String(ProjectSettings.get_setting("application/boot_splash/image")) == expected_icon, "Boot splash must use the Gem Rush logo instead of Godot branding")
	_check(ResourceLoader.exists(expected_icon), "Runtime Gem Rush icon must exist")

func _test_difficulty_progression() -> void:
	var level_1 := LevelConfigType.generated(1, LevelConfigType.seed_for_level(1))
	var level_2 := LevelConfigType.generated(2, LevelConfigType.seed_for_level(2))
	_check((level_1.target_sequence as Array) == [{"tier": 5, "quantity": 1}], "Level 1 must teach the loop with one L5 target")
	_check((level_2.target_sequence as Array) == [{"tier": 5, "quantity": 1}, {"tier": 6, "quantity": 1}], "Level 2 must introduce L5 then L6")
	_check(String(level_1.difficulty_band) == "INTRO" and String(level_2.difficulty_band) == "EASY", "Opening levels must use the two gentlest launcher bands")
	for level_number in range(3, 81):
		var config := LevelConfigType.generated(level_number, LevelConfigType.seed_for_level(level_number))
		var expected_count := 2 if posmod(level_number, 4) == 0 else 3
		var targets: Array = config.target_sequence
		_check(targets.size() == expected_count, "Level %d must use its two/three target cadence" % level_number)
		for target in targets:
			_check(int((target as Dictionary).tier) >= 5 and int((target as Dictionary).tier) <= 8, "Mature targets must stay inside reachable L5-L8")
		var launchers: Array = config.launcher_sequence
		_check(launchers.has(3) and launchers.has(4), "Level %d must retain helpful L3/L4 launches" % level_number)
	_check(String(LevelConfigType.generated(80, LevelConfigType.seed_for_level(80)).difficulty_band) == "EXPERT", "Long-run difficulty must cap instead of scaling toward impossibility")

func _test_settings_persistence() -> void:
	var previous := GameSettingsServiceType.load_settings()
	var save_error := GameSettingsServiceType.save_settings(false, true, false)
	var loaded := GameSettingsServiceType.load_settings()
	_check(save_error == OK, "Settings service must save successfully")
	_check(not bool(loaded.music_enabled) and bool(loaded.sound_enabled) and not bool(loaded.vibration_enabled), "Music, sound FX, and vibration must persist independently")
	GameSettingsServiceType.save_settings(bool(previous.music_enabled), bool(previous.sound_enabled), bool(previous.vibration_enabled))

func _test_runtime_settings_and_shared_gem_shape() -> void:
	var controller = GameScene.instantiate()
	root.add_child(controller)
	await process_frame
	controller._on_music_toggled(false)
	_check(not controller.audio_feedback.music_enabled, "Music toggle must stop only persistent background music")
	controller.audio_feedback.clear_trace()
	controller.audio_feedback.emit_event("button")
	_check(controller.audio_feedback.emitted_events.has("button"), "Sound FX must remain active when music is disabled")
	controller._on_sound_toggled(false)
	controller.audio_feedback.clear_trace()
	controller.audio_feedback.emit_event("button")
	_check(controller.audio_feedback.emitted_events.is_empty(), "Sound FX toggle must mute one-shots independently")
	controller._on_vibration_toggled(false)
	var saved := GameSettingsServiceType.load_settings()
	_check(not bool(saved.music_enabled) and not bool(saved.sound_enabled) and not bool(saved.vibration_enabled), "In-game settings changes must persist immediately")
	var active = controller.get_active_piece()
	controller.gem_sprite_layer.sync_gems(controller.pieces)
	var sprite: Sprite2D = controller.gem_sprite_layer._sprites.get(active.id)
	_check(sprite != null and sprite.texture == AssetCatalogType.gem_texture(active.level), "Table gem must use the same authoritative texture as target/merge UI")
	_check(sprite != null and is_equal_approx(sprite.scale.x, sprite.scale.y), "Table gems must preserve the same undistorted silhouette as merge and target gems")
	# Restore friendly defaults so this test never leaves the developer run muted.
	GameSettingsServiceType.save_settings(true, true, true)
	controller.queue_free()
	await process_frame
