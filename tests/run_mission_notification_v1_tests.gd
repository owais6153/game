extends SceneTree

## Coverage for the in-play daily-mission notification: it must fire on the
## transition to complete, exactly once, sit in the reward hierarchy between a
## combo and a met target, and never block the shot that earned it.

const GameScene = preload("res://scenes/Game.tscn")
const LevelConfigType = preload("res://scripts/core/level_config.gd")
const DailyMissionServiceType = preload("res://scripts/services/daily_mission_service.gd")
const GameplayHudType = preload("res://scripts/ui/gameplay_hud_layer.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_audio_sits_between_combo_and_target()
	await _test_notification_fires_once_on_completion()
	await _test_notification_never_blocks_gameplay()
	await _test_claiming_does_not_reannounce()
	if failures.is_empty():
		print("MISSION_NOTIFICATION_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("MISSION_NOTIFICATION_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


## The requested hierarchy is merge < combo < mission complete < target
## complete < level complete. Volume carries the punch; priority decides which
## cue survives a full voice pool.
func _test_audio_sits_between_combo_and_target() -> void:
	var tones: Dictionary = GameConfig.AUDIO_TONES
	var priority: Dictionary = GameConfig.AUDIO_PRIORITY_BY_EVENT
	_assert(tones.has("mission_complete"), "mission_complete must have its own tone")
	_assert(priority.has("mission_complete"), "mission_complete must have its own priority")
	var mission_volume := float((tones.get("mission_complete", {}) as Dictionary).get("volume", 0.0))
	_assert(mission_volume > float((tones.get("chain", {}) as Dictionary).get("volume", 1.0)),
		"a completed mission must sound bigger than a combo")
	_assert(mission_volume < float((tones.get("target_complete", {}) as Dictionary).get("volume", 0.0)),
		"a completed mission must sound smaller than a met target")
	_assert(int(priority.get("mission_complete", 0)) > int(priority.get("chain", 0)),
		"a completed mission must outrank a combo for a voice")
	_assert(int(priority.get("mission_complete", 0)) < int(priority.get("target_complete", 0)),
		"a completed mission must never steal the voice from a met target")
	_assert(int(priority.get("mission_complete", 0)) < int(priority.get("win", 0)),
		"a completed mission must never outrank level completion")


func _test_notification_fires_once_on_completion() -> void:
	var controller = await _start()
	var missions: Array = controller.daily_state.get("missions", []) as Array
	var merge_mission: Dictionary = missions[0] as Dictionary
	var target := int(merge_mission.get("target", 15))
	var label := String(merge_mission.get("label", ""))

	# One short of the target: progress, but no completion yet.
	controller._record_daily_progress("merge", target - 1)
	_assert(not controller.gameplay_ui.is_mission_toast_visible(),
		"partial progress must not announce a completion")

	controller._record_daily_progress("merge", 1)
	_assert(controller.gameplay_ui.is_mission_toast_visible(),
		"reaching the target must show the banner")
	# Visibility alone proves nothing: it is set synchronously, so a banner that
	# never animates would still report visible while rendering fully transparent.
	# Step the timeline and assert it actually becomes opaque and then leaves.
	var toast = controller.gameplay_ui.mission_toast
	_assert(is_equal_approx(toast.modulate.a, 0.0),
		"the banner must start transparent and fade in")
	controller.gameplay_ui.update_mission_toast(GameplayHudType.MISSION_TOAST_IN)
	_assert(is_equal_approx(toast.modulate.a, 1.0),
		"the banner must be fully opaque once its entrance completes (got %.2f)" % toast.modulate.a)
	_assert(toast.position.is_equal_approx(controller.gameplay_ui._mission_toast_settled),
		"the banner must arrive at its settled position")
	controller.gameplay_ui.update_mission_toast(GameplayHudType.MISSION_TOAST_HOLD + GameplayHudType.MISSION_TOAST_OUT)
	_assert(not controller.gameplay_ui.is_mission_toast_visible(),
		"the banner must leave on its own without any input")
	controller.gameplay_ui.show_mission_complete(label)
	_assert(controller.gameplay_ui.mission_toast_label.text == label,
		"the banner must name the mission that completed (expected '%s', got '%s')"
			% [label, controller.gameplay_ui.mission_toast_label.text])
	_assert(controller.gameplay_ui.mission_toast_title.text.contains("Daily Mission Complete"),
		"the banner must carry the completion headline")

	# Further merges on an already-complete mission must not re-announce.
	controller.gameplay_ui.mission_toast.visible = false
	controller._record_daily_progress("merge", 5)
	_assert(not controller.gameplay_ui.is_mission_toast_visible(),
		"an already-complete mission must not announce again")
	_free(controller)


## The banner is presentation only. It must not pause the tree, block the
## board, or interrupt a shot in flight.
func _test_notification_never_blocks_gameplay() -> void:
	var controller = await _start()
	var missions: Array = controller.daily_state.get("missions", []) as Array
	var target := int((missions[0] as Dictionary).get("target", 15))
	controller._record_daily_progress("merge", target)
	_assert(controller.gameplay_ui.is_mission_toast_visible(), "the banner must be showing for this check")

	var toast = controller.gameplay_ui.mission_toast
	_assert(toast.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"the banner must not intercept input")
	for child in toast.find_children("*", "Control", true, false):
		_assert((child as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE,
			"every node in the banner must ignore input (%s does not)" % child.name)
	_assert(not controller.get_tree().paused, "the banner must never pause the game")
	_assert(controller.app_flow_state == controller.AppFlowState.PLAYING,
		"the banner must not change the app flow state")
	# The banner must not cover the readouts the player needs mid-shot. Screen
	# rects, because the panels live under different parents.
	var toast_rect := Rect2(toast.position, toast.size)
	# The banner floats over the upper table because the limited-shots objective
	# stack now uses the centre-top band. It must stay clear of every persistent
	# readout and action while continuing to ignore board input.
	var guarded := {
		"shots counter": controller.gameplay_ui.shots_anchor,
		"target panel": controller.gameplay_ui.target_anchor,
	}
	for readout_name in guarded:
		var panel := guarded[readout_name] as Control
		if panel == null or not panel.visible:
			continue
		_assert(not toast_rect.intersects(panel.get_global_rect()),
			"the banner must not cover the %s" % readout_name)
	# It must also stay clear of the power row, which is a live control.
	for power in controller.gameplay_ui.power_tiles.keys():
		var tile := (controller.gameplay_ui.power_tiles[power] as Dictionary).get("button") as Button
		_assert(tile == null or not toast_rect.intersects(tile.get_global_rect()),
			"the banner must not cover the %s power button" % power)
	_free(controller)


## Claiming happens later, from the Home popup. It must not fire the in-play
## banner a second time for a mission that was already announced.
func _test_claiming_does_not_reannounce() -> void:
	var controller = await _start()
	var missions: Array = controller.daily_state.get("missions", []) as Array
	var target := int((missions[0] as Dictionary).get("target", 15))
	controller._record_daily_progress("merge", target)
	controller.gameplay_ui.mission_toast.visible = false

	controller._on_daily_missions_requested()
	controller._on_daily_mission_claim_requested(0)
	_assert(not controller.gameplay_ui.is_mission_toast_visible(),
		"claiming a reward must not replay the in-play completion banner")
	_free(controller)


func _start():
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	viewport.disable_3d = true
	root.add_child(viewport)
	var controller = GameScene.instantiate()
	viewport.add_child(controller)
	await process_frame
	controller.level_number = 4
	controller.level_seed = LevelConfigType.seed_for_level(4)
	controller.restart()
	controller._on_home_level_intro_requested()
	controller._on_home_play_requested()
	controller.set_process(false)
	# A clean mission set, so progress starts from zero regardless of any state
	# an earlier suite left in user://.
	controller.daily_state = DailyMissionServiceType.ensure_current_day({})
	return controller


func _free(controller) -> void:
	var viewport = controller.get_parent()
	if viewport != null:
		viewport.queue_free()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
