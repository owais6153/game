extends SceneTree

const ResultOverlayType = preload("res://scripts/ui/result_overlay_layer.gd")
const HomeOverlayType = preload("res://scripts/ui/home_overlay_layer.gd")
const DailyOverlayType = preload("res://scripts/ui/daily_missions_overlay_layer.gd")
const LevelConfigType = preload("res://scripts/core/level_config.gd")
const PowerCinematicType = preload("res://scripts/presentation/power_cinematic_layer.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_failure_copy_uses_authoritative_reason()
	await _test_home_status_polish_and_copy_cleanup()
	await _test_treasure_names_every_granted_power()
	_test_limited_shot_targets_are_shorter()
	_test_targeted_power_has_a_windup()
	if failures.is_empty():
		print("PLAYER_FEEDBACK_REPAIR_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("PLAYER_FEEDBACK_REPAIR_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


func _test_failure_copy_uses_authoritative_reason() -> void:
	var overlay = ResultOverlayType.new()
	root.add_child(overlay)
	await process_frame
	overlay.present(false, 100, 4, 7, 0, false, false, 0, false, 0, 100, "out_of_shots")
	_assert(overlay.subtitle_label.text == "YOU RAN OUT OF SHOTS",
		"an out-of-shots failure must never blame the danger line")
	overlay.dismiss()
	overlay.present(false, 100, 4, 7, 0, false, false, 0, false, 0, 100, "danger_line")
	_assert(overlay.subtitle_label.text.contains("DANGER LINE"),
		"a real danger failure must retain its specific explanation")
	overlay.queue_free()
	await process_frame


func _test_home_status_polish_and_copy_cleanup() -> void:
	var overlay = HomeOverlayType.new()
	root.add_child(overlay)
	await process_frame
	overlay.present(4, 1250, {"daily_state": {"missions": []}})
	for card in [overlay.level_label.get_parent().get_parent(), overlay.coins_label.get_parent().get_parent().get_parent()]:
		_assert((card as Node).get_node_or_null("PanelDecor") != null,
			"both Home status cards must carry the in-game edge decorators")
	_assert(not _tree_contains_text(overlay.root_control, "CURRENT LEVEL"),
		"Home must not render the redundant CURRENT LEVEL label")
	_assert(not _tree_contains_text(overlay.root_control, "Tap to view"),
		"Home must not render Tap to view missions copy")
	var spacer := overlay.root_control.find_child("DailyStatusSpacer", true, false) as Control
	_assert(spacer != null and spacer.custom_minimum_size.y >= 20.0,
		"Daily Missions must have extra breathing room before the status HUD")
	overlay.queue_free()
	await process_frame


func _test_treasure_names_every_granted_power() -> void:
	var overlay = DailyOverlayType.new()
	root.add_child(overlay)
	await process_frame
	overlay.present({"missions": [], "chest_claimed": true}, 0)
	overlay._reveal_chest_rewards({"switch": 2, "magnet": 1, "hammer": 1})
	_assert(overlay.chest_caption.text == "YOU RECEIVED",
		"the treasure opening must lead with an explicit reward reveal")
	_assert(overlay.chest_reward_row.visible and overlay.chest_reward_row.get_child_count() == 3,
		"the reveal must show each granted power as its own staged reward")
	_assert(_tree_contains_text(overlay.chest_reward_row, "×2 Switch")
		and _tree_contains_text(overlay.chest_reward_row, "×1 Magnet")
		and _tree_contains_text(overlay.chest_reward_row, "×1 Hammer"),
		"the reveal must name and count the complete persisted payout")
	overlay.queue_free()
	await process_frame


func _test_limited_shot_targets_are_shorter() -> void:
	for level in [4, 7, 10, 25, 40]:
		var config := LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))
		var targets: Array = config.get("target_sequence", []) as Array
		_assert(targets.size() == 2,
			"limited level %d must use two achievable targets" % level)
		for target_value in targets:
			var target: Dictionary = target_value as Dictionary
			_assert(int(target.get("tier", 8)) <= 7 and int(target.get("quantity", 0)) == 1,
				"limited level %d must avoid repeated or top-tier objectives" % level)


func _test_targeted_power_has_a_windup() -> void:
	_assert(PowerCinematicType.DURATION >= 1.5,
		"the power cinematic must be long enough to read as a deliberate strike")
	_assert(PowerCinematicType.TARGET_ARRIVE < PowerCinematicType.TRAVEL_END,
		"hammer and bomb must visibly brace over the selected gem before impact")


func _tree_contains_text(node: Node, fragment: String) -> bool:
	if node is Label and String((node as Label).text).contains(fragment):
		return true
	if node is Button and String((node as Button).text).contains(fragment):
		return true
	for child in node.get_children():
		if _tree_contains_text(child, fragment):
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
