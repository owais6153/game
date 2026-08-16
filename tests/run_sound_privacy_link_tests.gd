extends SceneTree

const AudioFeedbackServiceType = preload("res://scripts/audio_feedback_service.gd")
const HomeOverlayType = preload("res://scripts/home_overlay_layer.gd")
const GameplayHudScene = preload("res://scenes/ui/GameplayHud.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_audio_service()
	await _test_privacy_link_relocation()
	_test_confirmed_event_routing_contract()
	if failures.is_empty():
		print("SOUND_PRIVACY_LINK_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("SOUND_PRIVACY_LINK_TESTS: FAIL (%d)" % failures.size())
	quit(1)


func _test_audio_service() -> void:
	var service := AudioFeedbackServiceType.new()
	root.add_child(service)
	await process_frame
	_assert(service.cached_stream_count() == 10, "Audio service must cache exactly ten active event streams")
	_assert(service._players.size() == GameConfig.AUDIO_MAX_CONCURRENT_PLAYERS, "Audio service must use the bounded shared voice pool")
	_assert(AudioServer.get_bus_index("Music") >= 0 and AudioServer.get_bus_index("SFX") >= 0, "Dedicated Music and SFX buses must load")
	var sfx_bus := AudioServer.get_bus_index("SFX")
	_assert(sfx_bus >= 0 and AudioServer.get_bus_effect_count(sfx_bus) == 1 and AudioServer.get_bus_effect(sfx_bus, 0) is AudioEffectLimiter, "SFX bus must own the clipping limiter")
	_assert(service._music_player.bus == "Music" and service._players.all(func(player: AudioStreamPlayer) -> bool: return player.bus == "SFX"), "Music and one-shots must route to their dedicated buses")
	_assert(is_equal_approx(service.music_volume_linear(), 0.035), "Background music must use the documented reduced gain")
	var expected_paths := {
		"gem_contact": "res://assets/runtime/audio/gems-colide.mp3",
		"wall_contact": "res://assets/runtime/audio/gems-rail-colide.mp3",
		"merge_basic": "res://assets/runtime/audio/merge-basic.mp3",
		"target_merge": "res://assets/runtime/audio/merge-target.mp3",
		"target_collect": "res://assets/runtime/audio/mixkit-fairy-arcade-sparkle-866.wav",
		"coin_reward": "res://assets/runtime/audio/supplied_coin_reward_v4.ogg",
		"target_complete": "res://assets/runtime/audio/mixkit-game-flute-bonus-2313.wav",
		"win": "res://assets/runtime/audio/mixkit-game-success-alert-2039.wav",
		"button": "res://assets/runtime/audio/mixkit-on-or-off-light-switch-tap-2585.wav",
	}
	for event_name in expected_paths:
		var stream: AudioStream = service.stream_for_event(event_name)
		_assert(stream != null and stream.resource_path == String(expected_paths[event_name]), "%s must resolve to its approved supplied stream" % event_name)
		_assert(stream != null and stream.get_length() > 0.0, "%s supplied stream must have playable duration" % event_name)
	_assert(service.stream_for_event("launch") is AudioStreamWAV, "Existing procedural launch/push identity must remain cached")
	service.clear_trace()
	service._clock = 1.0
	_assert(service.emit_event("gem_contact"), "First confirmed gem contact must play")
	_assert(not service.emit_event("gem_contact"), "Gem-contact cooldown must suppress immediate chatter")
	service._clock += GameConfig.CONTACT_SOUND_COOLDOWN + 0.001
	_assert(service.emit_event("gem_contact"), "Gem contact must recover after its bounded cooldown")
	var newest_player: AudioStreamPlayer = service._players[0]
	for player in service._players:
		if int(player.get_meta("play_serial", 0)) > int(newest_player.get_meta("play_serial", 0)):
			newest_player = player
	_assert(newest_player.pitch_scale >= 0.96 and newest_player.pitch_scale <= 1.04, "Gem-contact pitch variation must stay inside 0.96x..1.04x")
	for event_name in ["win", "target_complete", "target_merge", "merge_basic", "coin_reward"]:
		_assert(service._play_event(event_name, 1.0), "%s must fill one bounded priority voice" % event_name)
	_assert(not service._play_event("button", 1.0), "A quiet UI tap must not steal a fully occupied higher-priority voice pool")
	_assert(service._play_event("win", 1.0), "Level success must be able to replace a lower-priority occupied voice")
	service.queue_free()
	await process_frame


func _test_privacy_link_relocation() -> void:
	var home := HomeOverlayType.new()
	root.add_child(home)
	await process_frame
	home.present(1, 0, {})
	await process_frame
	var link := home.root_control.find_child("HomePrivacyPolicyLink", true, false) as LinkButton
	_assert(link != null, "Home must own a real Privacy Policy link")
	_assert(home.root_control.find_child("HomePrivacyPolicy", true, false) == null, "Home Settings must not retain the old Privacy Policy button")
	_assert(home.root_control.find_child("HomePrivacyActions", true, false) == null, "Home Settings must not retain the old privacy-policy row")
	_assert(home.settings_privacy_options_button != null, "Conditional UMP Privacy Options must remain in Home Settings")
	if link != null:
		var viewport_size := root.get_visible_rect().size
		var rect := link.get_global_rect()
		_assert(absf(rect.get_center().x - viewport_size.x * 0.5) <= 2.0, "Privacy Policy link must be horizontally centered")
		_assert(rect.end.y <= viewport_size.y and rect.position.y >= viewport_size.y - 90.0, "Privacy Policy link must sit inside the bottom safe area")
		var tap_state := {"count": 0}
		home.ui_tap_requested.connect(func() -> void: tap_state.count += 1)
		link.pressed.emit()
		_assert(int(tap_state.count) == 1, "One Privacy Policy press must request exactly one UI tap")
	var hud := GameplayHudScene.instantiate() as GameplayHudLayer
	root.add_child(hud)
	await process_frame
	_assert(hud.root_control.find_child("PausePrivacyPolicy", true, false) == null, "Pause Settings must not retain a Privacy Policy button")
	_assert(hud.root_control.find_child("PausePrivacyOptions", true, false) != null, "Pause Settings must retain conditional UMP Privacy Options")
	hud.queue_free()
	home.queue_free()
	await process_frame


func _test_confirmed_event_routing_contract() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/game_controller.gd")
	_assert(source.contains("audio_feedback.emit_event(\"target_merge\" if completes_active_target else \"merge_basic\")"), "Confirmed merges must choose exactly one normal/target stream")
	_assert(not source.contains("audio_feedback.emit_event(\"merge_%d\"") and not source.contains("audio_feedback.emit_event(\"chain\")"), "Legacy tier/chain sounds must not stack under supplied merge cues")
	_assert(source.contains("audio_feedback.emit_event(\"target_collect\")") and source.contains("audio_feedback.emit_event(\"target_complete\")"), "Target arrival and full objective completion must remain distinct events")
	_assert(source.contains("audio_feedback.emit_event(\"win\")"), "Level success must remain tied to final result presentation")
	_assert(not source.contains("audio_feedback.emit_event(\"fail\")"), "No lose/game-over sound may be routed")
	_assert(source.contains("merged_pairs.has(pair_key)"), "Collision audio must be suppressed for the exact contact pair that merges")
	var impact_capture := source.find("var collision_impacts := simulation.consume_collision_impacts()")
	var merge_resolution := source.find("var result := merge_service.resolve", impact_capture)
	var feedback_route := source.find("_route_collision_feedback(collision_impacts, result.presentation_events)", merge_resolution)
	_assert(impact_capture >= 0 and merge_resolution > impact_capture and feedback_route > merge_resolution, "Contact audio must route after confirmed merge resolution so merge contacts can be suppressed")
	var arrival_cue := source.find("audio_feedback.emit_event(\"target_collect\")")
	var progress_update := source.find("target_progress += 1", arrival_cue)
	var objective_cue := source.find("audio_feedback.emit_event(\"target_complete\")", progress_update)
	var objective_advance := source.find("target_index += 1", objective_cue)
	_assert(arrival_cue >= 0 and progress_update > arrival_cue and objective_cue > progress_update and objective_advance > objective_cue, "Sparkle must play at collection arrival and objective reward only after full progress")
	var result_present := source.find("if result_overlay.present(true")
	var win_cue := source.find("audio_feedback.emit_event(\"win\")", result_present)
	_assert(result_present >= 0 and win_cue > result_present, "Level-success cue must play only after the victory overlay is accepted")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
