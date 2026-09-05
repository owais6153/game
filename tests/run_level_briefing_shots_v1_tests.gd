extends SceneTree

## Covers the first-run level briefing and the limited-shots counter panel.

const GameScene = preload("res://scenes/Game.tscn")
const ProgressionSaveServiceType = preload("res://scripts/services/progression_save_service.gd")
const LevelBriefingType = preload("res://scripts/ui/level_briefing_overlay_layer.gd")
const GameplayHudType = preload("res://scripts/ui/gameplay_hud_layer.gd")
const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_seen_level_types_persist()
	await _test_briefing_shows_once_per_type()
	await _test_shots_panel_is_centred_and_legible()
	if failures.is_empty():
		print("LEVEL_BRIEFING_SHOTS_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("LEVEL_BRIEFING_SHOTS_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


## The record must survive a restart, or the briefing re-teaches on every launch.
func _test_seen_level_types_persist() -> void:
	ProgressionSaveServiceType.clear_progress()
	_assert(ProgressionSaveServiceType.load_progress().get("seen_level_types", []).is_empty(),
		"A fresh save must have seen no level types")
	ProgressionSaveServiceType.mark_level_type_seen("limited_shots")
	var seen: Array = ProgressionSaveServiceType.load_progress().get("seen_level_types", [])
	_assert(seen.has("limited_shots"), "A shown briefing must persist")
	# Recording twice must not duplicate, and must not disturb coin/level state.
	ProgressionSaveServiceType.mark_level_type_seen("limited_shots")
	ProgressionSaveServiceType.save_progress(7, 1234, 900)
	var after: Dictionary = ProgressionSaveServiceType.load_progress()
	var after_seen: Array = after.get("seen_level_types", [])
	_assert(after_seen.size() == 1, "Recording a type twice must not duplicate it")
	_assert(int(after.get("total_coins", 0)) == 900 and int(after.get("level_number", 0)) == 7,
		"A coin/level save must preserve the briefing record")
	ProgressionSaveServiceType.clear_progress()


func _test_briefing_shows_once_per_type() -> void:
	ProgressionSaveServiceType.clear_progress()
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	root.add_child(viewport)
	var controller = GameScene.instantiate()
	viewport.add_child(controller)
	await process_frame
	controller.set_process(false)
	controller.seen_level_types.clear()

	controller.level_config["level_type"] = "limited_shots"
	controller.level_config["shot_limit"] = 36
	controller._present_level_briefing_if_due()
	await process_frame
	_assert(controller.level_briefing.is_open(), "A first-time level type must open its briefing")
	_assert(controller.level_briefing.title_label.text == "LIMITED SHOTS",
		"The briefing must describe the level type actually being started")
	_assert(controller.level_briefing.body_label.text.contains("36"),
		"The limited-shots briefing must state the real shot limit")
	controller.level_briefing.dismiss()
	# dismiss() is animated; wait for it to actually close rather than assuming a
	# single frame is enough.
	await controller.level_briefing.dismissed
	_assert(not controller.level_briefing.is_open(), "Dismiss must close the briefing")

	# Same type again: must not re-teach.
	controller._present_level_briefing_if_due()
	await process_frame
	_assert(not controller.level_briefing.is_open(), "A seen level type must not brief again")

	# A different type is still unseen and must brief.
	controller.level_config["level_type"] = "normal"
	controller._present_level_briefing_if_due()
	await process_frame
	_assert(controller.level_briefing.is_open(), "An unseen level type must still brief")
	_assert(controller.level_briefing.title_label.text == "HOW TO PLAY",
		"The normal-level briefing must be its own copy")
	_assert(ProgressionSaveServiceType.load_progress().get("seen_level_types", []).size() == 2,
		"Both shown briefings must be recorded")
	viewport.queue_free()
	await process_frame
	ProgressionSaveServiceType.clear_progress()


## The counter previously sat as a small label beside Coins. It must now be part
## of the centred objective stack and large enough to read as it ticks down.
func _test_shots_panel_is_centred_and_legible() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	root.add_child(viewport)
	var hud = GameplayHudType.new()
	viewport.add_child(hud)
	await process_frame

	var panel := hud.root_control.find_child("ShotsPanel", true, false) as Control
	_assert(panel != null, "The limited-shots counter must exist as a framed panel")
	# The counter moved out of the centred objective stack and under Coins, so the
	# middle of the HUD could carry the Target plate and its mascot. It must be in
	# the left column and must NOT be back in the stack.
	var stack := hud.root_control.find_child("TableObjectiveStack", true, false) as Control
	_assert(stack != null and not stack.is_ancestor_of(panel),
		"The counter must sit under Coins, not back in the centred objective stack")
	var coins_slot := hud.root_control.find_child("CoinsSlot", true, false) as Control
	_assert(coins_slot != null and coins_slot.is_ancestor_of(panel),
		"The counter must live in the left column beneath Coins")

	hud.update_snapshot({"limited_shots": false, "shots_remaining": 0})
	await process_frame
	_assert(not hud.shots_anchor.visible, "Normal levels must not show a shots counter")

	hud.update_snapshot({"limited_shots": true, "shots_remaining": 12})
	await process_frame
	_assert(hud.shots_anchor.visible, "Limited-shots levels must show the counter")
	_assert(hud.shots_label.text == "12", "The counter must show the remaining shots")
	# The counter is a compact pill under Coins now, not a full-width plate, so it
	# no longer carries score-sized type. What still has to hold is that the number
	# dominates its own card: large in absolute terms, and clearly bigger than the
	# caption under it.
	var size: int = hud.shots_label.get_theme_font_size("font_size")
	var caption := hud.root_control.find_child("ShotsCaption", true, false) as Label
	_assert(size >= 34, "The count must stay large enough to read at a glance, got %d" % size)
	_assert(caption != null and size > caption.get_theme_font_size("font_size") + 8,
		"The count must clearly dominate its caption")

	# Left-aligned under Coins now, and clear of the Target plate in the middle.
	await process_frame
	var rect := panel.get_global_rect()
	var score_rect := (hud.root_control.find_child("ScorePanel", true, false) as Control).get_global_rect() if hud.root_control.find_child("ScorePanel", true, false) != null else Rect2()
	_assert(rect.get_center().x < 360.0,
		"The counter must sit in the left column, found centre x=%.1f" % rect.get_center().x)
	var target := hud.root_control.find_child("ActiveTargetPanel", true, false) as Control
	_assert(target != null and not rect.intersects(target.get_global_rect()),
		"The counter must not overlap the Target plate")
	if score_rect.size.y > 0.0:
		_assert(rect.position.y >= score_rect.end.y - 1.0,
			"The counter must sit below the Coins card, not beside it")

	# Running low must be visually distinct.
	hud.update_snapshot({"limited_shots": true, "shots_remaining": 2})
	await process_frame
	_assert(hud.shots_label.get_theme_color("font_color") != Color.WHITE,
		"A low shot count must change colour as a warning")
	viewport.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
