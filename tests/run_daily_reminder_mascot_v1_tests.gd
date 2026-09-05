extends SceneTree

## Two features that ship together but are independent: the daily-missions
## reminder, and the mood mascot.
##
## Both are tested at the layer where the decisions actually live. The reminder's
## native scheduler cannot run here, so every rule it obeys - whether to fire,
## when, and what it says - is a pure function that can. The mascot's frame
## blending is likewise arithmetic, not rendering.

const NotificationServiceType = preload("res://scripts/services/notification_service.gd")
const GameSettingsServiceType = preload("res://scripts/services/game_settings_service.gd")
const DailyMissionServiceType = preload("res://scripts/services/daily_mission_service.gd")
const MascotViewType = preload("res://scripts/ui/mascot_view.gd")
const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_reminder_only_when_something_is_outstanding()
	_test_reminder_respects_the_setting()
	_test_reminder_timing()
	_test_reminder_copy()
	_test_reminder_degrades_without_the_plugin()
	_test_settings_persist_independently()
	await _test_mascot_frames_exist_and_register()
	await _test_mascot_glides_through_every_frame()
	await _test_mascot_never_cuts_between_moods()
	if failures.is_empty():
		print("DAILY_REMINDER_MASCOT_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("DAILY_REMINDER_MASCOT_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


## The rule the whole feature rests on: a reminder on a day the player has
## already finished everything trains them to ignore the next one.
func _test_reminder_only_when_something_is_outstanding() -> void:
	var on := {"notifications_enabled": true}
	_assert(not NotificationServiceType.should_remind(on, _state([])),
		"A day with no missions must not schedule a reminder")
	_assert(NotificationServiceType.should_remind(on, _state([false, false, false])),
		"Three unclaimed missions must schedule a reminder")
	_assert(NotificationServiceType.should_remind(on, _state([true, true, false])),
		"One unclaimed mission must still schedule a reminder")
	_assert(not NotificationServiceType.should_remind(on, _state([true, true, true], true)),
		"Everything claimed, including the chest, must schedule nothing")

	# All missions claimed but the chest not: still a reason to open the game.
	var chest_waiting := _state([true, true, true], false)
	_assert(NotificationServiceType.should_remind(on, chest_waiting),
		"An unopened chest must still be worth a reminder")
	_assert(NotificationServiceType.unclaimed_count(chest_waiting) == 1,
		"An unopened chest must count as exactly one outstanding item")
	_assert(NotificationServiceType.unclaimed_count(_state([false, true, false])) == 2,
		"Outstanding count must be the number of unclaimed missions")


func _test_reminder_respects_the_setting() -> void:
	var off := {"notifications_enabled": false}
	_assert(not NotificationServiceType.should_remind(off, _state([false, false, false])),
		"Reminders turned off must never schedule, however much is outstanding")
	# Absent key reads as opted in, matching the service default.
	_assert(NotificationServiceType.should_remind({}, _state([false])),
		"A missing preference must default to reminders on")


func _test_reminder_timing() -> void:
	var morning := {"hour": 9, "minute": 30, "second": 0}
	var expected := (NotificationServiceType.REMINDER_HOUR - 9) * 3600 - 30 * 60
	_assert(NotificationServiceType.seconds_until_next_reminder(morning) == expected,
		"A morning reschedule must target this evening")

	var late := {"hour": 22, "minute": 0, "second": 0}
	var overnight := NotificationServiceType.seconds_until_next_reminder(late)
	_assert(overnight == (24 - 22 + NotificationServiceType.REMINDER_HOUR) * 3600,
		"After the reminder hour it must target tomorrow, got %d" % overnight)

	# Exactly on the hour must roll forward a day rather than return zero, or a
	# claim at 19:00:00 would fire an alarm immediately.
	var on_the_dot := {"hour": NotificationServiceType.REMINDER_HOUR, "minute": 0, "second": 0}
	_assert(NotificationServiceType.seconds_until_next_reminder(on_the_dot) == 24 * 3600,
		"At exactly the reminder minute the next one must be tomorrow")

	for hour in range(0, 24):
		var delay := NotificationServiceType.seconds_until_next_reminder({"hour": hour, "minute": 0, "second": 0})
		_assert(delay > 0 and delay <= 24 * 3600,
			"Delay from %02d:00 must be inside one day, got %d" % [hour, delay])


func _test_reminder_copy() -> void:
	_assert(NotificationServiceType.reminder_body(1).begins_with("1 mission left"),
		"One outstanding mission must not be pluralised")
	_assert(NotificationServiceType.reminder_body(3).begins_with("3 missions left"),
		"Several outstanding missions must be pluralised")
	_assert(NotificationServiceType.reminder_body(0).is_empty(),
		"Nothing outstanding must produce no body")
	_assert(not NotificationServiceType.reminder_title().is_empty(),
		"The reminder must carry a title")


## Desktop, and any Android build without the plugin, must run normally and just
## never schedule. A hard dependency here would take the game down with it.
func _test_reminder_degrades_without_the_plugin() -> void:
	_assert(not NotificationServiceType.is_available(),
		"The plugin must report unavailable in a headless test run")
	var decision := NotificationServiceType.refresh(
		{"notifications_enabled": true}, _state([false, false]), {"hour": 12, "minute": 0, "second": 0})
	_assert(bool(decision.get("scheduled", false)),
		"refresh() must still report the decision it would have made")
	_assert(not bool(decision.get("delivered_to_plugin", true)),
		"refresh() must report that nothing reached a plugin")
	_assert(int(decision.get("outstanding", 0)) == 2,
		"refresh() must report the outstanding count it decided on")


## The notification preference and the audio settings are written by separate
## calls; neither may drop the other. save_settings() used to rebuild the file
## from scratch, which would have silently wiped the new key.
func _test_settings_persist_independently() -> void:
	GameSettingsServiceType.clear_settings()
	_assert(bool(GameSettingsServiceType.defaults().get("notifications_enabled", false)),
		"Reminders must default to on")

	GameSettingsServiceType.save_notifications_enabled(false)
	_assert(not GameSettingsServiceType.notifications_enabled(),
		"Turning reminders off must persist")

	GameSettingsServiceType.save_settings(false, true, true)
	_assert(not GameSettingsServiceType.notifications_enabled(),
		"Saving audio settings must not resurrect the notification preference")
	var settings := GameSettingsServiceType.load_settings()
	_assert(not bool(settings.get("music_enabled", true)) and bool(settings.get("sound_enabled", false)),
		"Audio settings must still round-trip alongside the notification key")

	GameSettingsServiceType.save_notifications_enabled(true)
	_assert(GameSettingsServiceType.notifications_enabled() and not bool(GameSettingsServiceType.load_settings().get("music_enabled", true)),
		"Turning reminders back on must not disturb the audio settings")
	GameSettingsServiceType.clear_settings()


func _test_mascot_frames_exist_and_register() -> void:
	var sizes := {}
	for mood in ["happy", "sad"]:
		for index in range(1, MascotViewType.FRAME_COUNT + 1):
			var path := "res://assets/runtime/character/mascot_%s_%d.png" % [mood, index]
			var texture: Texture2D = load(path)
			_assert(texture != null, "Missing mascot frame %s" % path)
			if texture != null:
				sizes[str(texture.get_size())] = true
	# Every frame the same size is what stops the character jittering between
	# poses; a per-frame trim would have produced sixteen different sizes.
	_assert(sizes.size() == 1,
		"Every mascot frame must share one size for the animation to register, found %d: %s" % [sizes.size(), str(sizes.keys())])


func _test_mascot_glides_through_every_frame() -> void:
	var mascot = MascotViewType.new()
	root.add_child(mascot)
	mascot.size = Vector2(200.0, 200.0)
	await process_frame

	mascot.show_idle(true)
	_assert(is_zero_approx(mascot.current_frame()), "Idle must sit on the first frame")

	# A jump to the extreme must travel, not cut: sample the frame across the
	# glide and require that the middle of the track is actually visited.
	mascot.set_mood(MascotViewType.MOOD_HAPPY, 1.0)
	var seen_middle := false
	var seen_frames := 0
	for _step in range(120):
		await process_frame
		var frame: float = mascot.current_frame()
		if frame > 1.0 and frame < float(MascotViewType.FRAME_COUNT - 1) - 1.0:
			seen_middle = true
		seen_frames += 1
		if is_equal_approx(frame, float(MascotViewType.FRAME_COUNT - 1)):
			break
	_assert(seen_middle, "The mascot must pass through the middle of the track, not cut to the end")
	_assert(is_equal_approx(mascot.current_frame(), float(MascotViewType.FRAME_COUNT - 1)),
		"The mascot must reach the last frame, got %f" % mascot.current_frame())

	mascot.queue_free()
	await process_frame


## Happy and sad are separate tracks that only share the neutral pose, so a
## direct swap mid-expression would visibly cut the face. It must rewind first.
func _test_mascot_never_cuts_between_moods() -> void:
	var mascot = MascotViewType.new()
	root.add_child(mascot)
	mascot.size = Vector2(200.0, 200.0)
	await process_frame

	mascot.set_mood(MascotViewType.MOOD_HAPPY, 1.0, 0.0, true)
	_assert(mascot.current_mood() == MascotViewType.MOOD_HAPPY, "Immediate set must adopt the mood")

	mascot.set_mood(MascotViewType.MOOD_SAD, 1.0)
	_assert(mascot.current_mood() == MascotViewType.MOOD_HAPPY,
		"A mood flip mid-expression must not switch track immediately")

	var rewound := false
	for _step in range(240):
		await process_frame
		if mascot.current_mood() == MascotViewType.MOOD_SAD:
			rewound = true
			break
	_assert(rewound, "The mascot must reach the sad track after rewinding through neutral")

	mascot.queue_free()
	await process_frame


func _state(claimed_flags: Array, chest_claimed: bool = false) -> Dictionary:
	var missions := []
	for flag in claimed_flags:
		missions.append({"claimed": bool(flag), "target": 1, "progress": 1})
	return {"date": "2026-09-05", "missions": missions, "chest_claimed": chest_claimed}


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
