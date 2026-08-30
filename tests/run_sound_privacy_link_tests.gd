extends SceneTree

const AudioFeedbackServiceType = preload("res://scripts/services/audio_feedback_service.gd")
const HomeOverlayType = preload("res://scripts/ui/home_overlay_layer.gd")
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
	# 18 original identities, one impact tone per power, the shared charge cue
	# that leads every power cinematic, and the mission-complete rung of the
	# reward hierarchy. The bound still matters: it is
	# what stops the cache growing an unbounded stream per gameplay event.
	_assert(service.cached_stream_count() == 24, "Audio service must cache the bounded contact, merge, target, coin, power, result, and UI identities")
	_assert(service._players.size() == GameConfig.AUDIO_MAX_CONCURRENT_PLAYERS, "Audio service must use the bounded shared voice pool")
	_assert(AudioServer.get_bus_index("Music") >= 0 and AudioServer.get_bus_index("SFX") >= 0, "Dedicated Music and SFX buses must load")
	var sfx_bus := AudioServer.get_bus_index("SFX")
	_assert(sfx_bus >= 0 and AudioServer.get_bus_effect_count(sfx_bus) == 1 and AudioServer.get_bus_effect(sfx_bus, 0) is AudioEffectLimiter, "SFX bus must own the clipping limiter")
	_assert(service._music_player.bus == "Music" and service._players.all(func(player: AudioStreamPlayer) -> bool: return player.bus == "SFX"), "Music and one-shots must route to their dedicated buses")
	_assert(is_equal_approx(service.music_volume_linear(), 0.07), "Background music must use the slightly raised documented gain")
	_assert(is_equal_approx(float(GameConfig.AUDIO_TONES.gem_contact.volume), 0.46) and is_equal_approx(float(GameConfig.AUDIO_TONES.gem_contact.frequency), 1240.0), "Gem contact must restore the original procedural crystal identity and gain")
	_assert(is_equal_approx(float(GameConfig.AUDIO_TONES.wall_contact.volume), 0.32) and is_equal_approx(float(GameConfig.AUDIO_TONES.wall_contact.frequency), 760.0), "Rail contact must restore the original procedural crystal identity and gain")
	_assert(is_equal_approx(GameConfig.GEM_CONTACT_SOUND_THRESHOLD, 170.0) and is_equal_approx(GameConfig.WALL_CONTACT_SOUND_THRESHOLD, 220.0), "Contact thresholds must restore the original tuning")
	_assert(is_equal_approx(float(GameConfig.AUDIO_TONES.normal_merge.volume), 0.70), "Ordinary merge must clearly exceed collision gain")
	_assert(float(GameConfig.AUDIO_TONES.target_collect.volume) > float(GameConfig.AUDIO_TONES.normal_merge.volume), "Target arrival must be more rewarding than an ordinary merge")
	_assert(is_equal_approx(float(GameConfig.AUDIO_TONES.button.volume), 0.32), "UI-tap replacement gain must be lowered to 0.32")
	_assert(is_equal_approx(float(GameConfig.AUDIO_TONES.win.volume), 0.92), "Final success must remain the strongest short supplied cue")
	var expected_paths := {
		"normal_merge": "res://assets/runtime/audio/merge-target-immediate.ogg",
		"coin_reward": "res://assets/runtime/audio/supplied_coin_reward_v4.ogg",
		"target_complete": "res://assets/runtime/audio/target_complete_soft_v1.ogg",
		"win": "res://assets/runtime/audio/merge-basic.mp3",
		"button": "res://assets/runtime/audio/mixkit-on-or-off-light-switch-tap-2585.wav",
	}
	for event_name in expected_paths:
		var stream: AudioStream = service.stream_for_event(event_name)
		_assert(stream != null and stream.resource_path == String(expected_paths[event_name]), "%s must resolve to its approved supplied stream" % event_name)
		_assert(stream != null and stream.get_length() > 0.0, "%s supplied stream must have playable duration" % event_name)
	for event_name in ["gem_contact", "wall_contact"]:
		var stream: AudioStream = service.stream_for_event(event_name)
		_assert(stream is AudioStreamWAV and stream.resource_path.is_empty(), "%s must restore its original generated crystal stream rather than a later supplied file" % event_name)
	_assert(service.stream_for_event("normal_merge").get_length() < 1.60, "Normal-merge runtime derivative must remove the supplied MP3's half-second leading silence")
	for event_name in ["launch", "merge_2", "merge_8", "chain", "target_collect", "coin_tick"]:
		_assert(service.stream_for_event(event_name) is AudioStreamWAV, "%s must retain its original procedural identity" % event_name)
	_assert(service.stream_for_event("target_complete") != null and service.stream_for_event("target_merge") == null, "Target completion must own one distinct richer cue")
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
	_assert(is_equal_approx(newest_player.pitch_scale, 1.0), "Original procedural gem contact must keep its fixed pitch")
	for event_name in ["win", "merge_8", "chain", "normal_merge", "coin_reward"]:
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
		_assert(rect.size.x < 150.0, "Privacy Policy visible text must not sit left-aligned inside the old oversized 180px box")
		_assert(home.privacy_link_margin.anchor_left == 0.0 and home.privacy_link_margin.anchor_right == 1.0 and home.privacy_link_margin.offset_left == 0.0 and home.privacy_link_margin.offset_right == 0.0, "Privacy Policy container must span the full screen before centering its link")
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
	_assert(hud.root_control.find_child("VibrationToggle", true, false) == null and home.root_control.find_child("HomeVibrationToggle", true, false) == null, "Unsupported vibration switches must be absent from both settings screens")
	hud.queue_free()
	home.queue_free()
	await process_frame


func _test_confirmed_event_routing_contract() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/gameplay/game_controller.gd")
	_assert(source.contains("merge_event.merge_sound_event = \"merge_%d\" % result_level if completes_active_target else \"normal_merge\""), "Confirmed merges must retain their distinct sound identities")
	var merge_classified := source.find("var completes_active_target := result_level == active_target_tier()")
	var merge_identity := source.find("merge_event.merge_sound_event =", merge_classified)
	var reveal_guard := source.find("GameConfig.MERGE_REVEAL_SOUND_AT", merge_identity)
	# Matched on the argument rather than the whole call, so reformatting the
	# emit across lines cannot fail a contract that is still satisfied.
	var merge_cue := source.find("String(presentation.get(\"merge_sound_event\"", reveal_guard)
	_assert(merge_classified >= 0 and merge_identity > merge_classified and reveal_guard > merge_identity and merge_cue > reveal_guard, "Merge sound must align once with the restored 200 ms result reveal")
	# Reward feedback v3 keeps the same confirmed chain event and adds only a
	# bounded presentation pitch for the combo hierarchy.
	_assert(source.contains("audio_feedback.emit_event(\"chain\", 1.0, float(timeline.get(\"pitch\", 1.0)))"), "Original chain feedback must be restored")
	_assert(source.contains("audio_feedback.emit_event(\"target_collect\")"), "Target arrival must retain its original cue")
	_assert(source.contains("audio_feedback.emit_event(\"target_complete\")"), "Every completed target must own a richer reward cue")
	var reward_cue := source.find("audio_feedback.emit_event(\"target_complete\")")
	var collection_cue := source.find("audio_feedback.emit_event(\"target_collect\")", reward_cue)
	_assert(reward_cue >= 0 and collection_cue > reward_cue, "Target audio must sequence merge, then reward, then visible collection arrival")
	_assert(source.contains("audio_feedback.emit_event(\"win\")"), "Level success must remain tied to final result presentation")
	_assert(not source.contains("audio_feedback.emit_event(\"fail\")"), "No lose/game-over sound may be routed")
	_assert(source.contains("merged_pairs.has(pair_key)"), "Collision audio must be suppressed for the exact contact pair that merges")
	var impact_capture := source.find("var collision_impacts := simulation.consume_collision_impacts()")
	var merge_resolution := source.find("var result := merge_service.resolve", impact_capture)
	var feedback_route := source.find("_route_collision_feedback(collision_impacts, result.presentation_events)", merge_resolution)
	_assert(impact_capture >= 0 and merge_resolution > impact_capture and feedback_route > merge_resolution, "Contact audio must route after confirmed merge resolution so merge contacts can be suppressed")
	var arrival_cue := source.find("audio_feedback.emit_event(\"target_collect\")")
	var progress_update := source.find("target_progress += 1", arrival_cue)
	var objective_advance := source.find("target_index += 1", progress_update)
	_assert(arrival_cue >= 0 and progress_update > arrival_cue and objective_advance > progress_update, "Original target-arrival cue must play before confirmed progress advances")
	var result_present := source.find("if result_overlay.present(true")
	var win_cue := source.find("audio_feedback.emit_event(\"win\")", result_present)
	_assert(result_present >= 0 and win_cue > result_present, "Level-success cue must play only after the victory overlay is accepted")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
