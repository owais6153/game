extends SceneTree

## Level select: the map's slot arithmetic, its unlock and chest rules, and the
## controller flow that now routes every entry into a level through it.
##
## The seed guarantee is tested here rather than assumed, because the whole
## point of the screen is that an earlier level can be replayed: if
## seed_for_level ever stopped being a pure function of the level number, a
## replay would silently hand the player a different board than the one they
## remember, and nothing else in the suite would notice.

const LevelMilestoneType = preload("res://scripts/core/level_milestone.gd")
const LevelConfigType = preload("res://scripts/core/level_config.gd")
const LevelMapViewType = preload("res://scripts/ui/level_map_view.gd")
const LevelSelectType = preload("res://scripts/ui/level_select_overlay_layer.gd")
const GameControllerType = preload("res://scripts/gameplay/game_controller.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_milestone_slot_arithmetic()
	_test_chest_unlock_rules()
	_test_seeds_are_pure_functions_of_level()
	await _test_map_view_geometry_and_hit_testing()
	await _test_map_view_locks_future_levels()
	await _test_mobile_drag_scrolls_the_container()
	await _test_overlay_presents_and_centres()
	_test_controller_flow_wiring()
	if failures.is_empty():
		print("LEVEL_SELECT_MAP_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("LEVEL_SELECT_MAP_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


## Levels and chests share one column of slots. If the two mappings ever drift,
## a chest draws on top of a level node.
func _test_milestone_slot_arithmetic() -> void:
	_assert(LevelMilestoneType.slot_for_level(1) == 0, "Level 1 must occupy the first slot")
	_assert(LevelMilestoneType.slot_for_level(20) == 19, "Level 20 must sit directly below the first chest")
	_assert(LevelMilestoneType.slot_for_chest(1) == 20, "Chest 1 must take the slot after level 20")
	_assert(LevelMilestoneType.slot_for_level(21) == 21, "Level 21 must resume above the first chest")
	_assert(LevelMilestoneType.slot_for_chest(2) == 41, "Chest 2 must take the slot after level 40")
	_assert(LevelMilestoneType.slot_for_level(40) == 40, "Level 40 must sit directly below the second chest")

	# Every slot must round-trip: exactly one occupant, and the inverse mapping
	# must agree with the forward one.
	var seen_levels := {}
	var seen_chests := {}
	for slot in range(0, 400):
		var contents := LevelMilestoneType.slot_contents(slot)
		var level := int(contents.get("level", 0))
		var chest := int(contents.get("chest", 0))
		_assert((level > 0) != (chest > 0), "Slot %d must hold exactly one of a level or a chest" % slot)
		if level > 0:
			_assert(LevelMilestoneType.slot_for_level(level) == slot, "slot_for_level(%d) must invert slot_contents(%d)" % [level, slot])
			seen_levels[level] = true
		else:
			_assert(LevelMilestoneType.slot_for_chest(chest) == slot, "slot_for_chest(%d) must invert slot_contents(%d)" % [chest, slot])
			seen_chests[chest] = true
	for level in range(1, 380):
		_assert(seen_levels.has(level), "Level %d must appear on the map" % level)


func _test_chest_unlock_rules() -> void:
	_assert(LevelMilestoneType.chest_for_level(20) == 1, "Clearing level 20 must unlock chest 1")
	_assert(LevelMilestoneType.chest_for_level(40) == 2, "Clearing level 40 must unlock chest 2")
	_assert(LevelMilestoneType.chest_for_level(19) == 0, "A non-milestone level must unlock no chest")
	_assert(LevelMilestoneType.chest_for_level(21) == 0, "A non-milestone level must unlock no chest")

	# `highest_level` is the furthest playable level, so the last CLEARED level is
	# the one below it. Standing on 20 means 20 is not yet beaten.
	_assert(LevelMilestoneType.unlocked_chest_count(1) == 0, "A new player has no chests")
	_assert(LevelMilestoneType.unlocked_chest_count(20) == 0, "Standing on level 20 must not open the chest that follows it")
	_assert(LevelMilestoneType.unlocked_chest_count(21) == 1, "Clearing level 20 must open exactly one chest")
	_assert(LevelMilestoneType.unlocked_chest_count(41) == 2, "Clearing level 40 must open exactly two chests")
	_assert(LevelMilestoneType.unlocked_chest_count(60) == 2, "Standing on level 60 must not open the third chest early")


## The contract the whole replay feature rests on.
func _test_seeds_are_pure_functions_of_level() -> void:
	for level in [1, 2, 7, 19, 20, 63, 250, 1004]:
		var first := LevelConfigType.seed_for_level(level)
		var second := LevelConfigType.seed_for_level(level)
		_assert(first == second, "seed_for_level(%d) must be stable across calls" % level)
		var config_a := LevelConfigType.generated(level, first)
		var config_b := LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))
		_assert(
			config_a.get("shot_limit", -1) == config_b.get("shot_limit", -2)
				and str(config_a.get("starting_board", [])) == str(config_b.get("starting_board", []))
				and str(config_a.get("launcher_sequence", [])) == str(config_b.get("launcher_sequence", [])),
			"Replaying level %d must rebuild an identical board, shot limit and queue" % level
		)
	_assert(
		LevelConfigType.seed_for_level(7) != LevelConfigType.seed_for_level(8),
		"Different levels must not share a seed"
	)


func _test_map_view_geometry_and_hit_testing() -> void:
	var map := LevelMapViewType.new()
	root.add_child(map)
	map.size = Vector2(720.0, 1280.0)
	map.configure(25, [] as Array[int], 1000)
	await process_frame

	_assert(map.last_level == 1025, "The map must draw 1000 levels beyond the player's furthest")
	_assert(map.content_height() > 1280.0, "A thousand-level map must be taller than one screen")

	# What the player taps has to be what they see, so hit testing is asked to
	# find the node at the exact point the drawing code would place it.
	map.set_window(0.0, map.content_height())
	for level in [1, 5, 20, 25]:
		var slot := LevelMilestoneType.slot_for_level(level)
		var centre := map._point_at(float(slot))
		_assert(map.slot_at_position(centre) == slot, "A tap on level %d's plate must hit level %d" % [level, level])
		_assert(
			map.slot_at_position(centre + Vector2(0.0, LevelMapViewType.ROW_HEIGHT * 0.5)) != slot,
			"A tap in the gap above level %d must not hit it" % level
		)
	var chest_slot := LevelMilestoneType.slot_for_chest(1)
	_assert(map.slot_at_position(map._point_at(float(chest_slot))) == chest_slot, "A tap on the chest must hit the chest")

	# Nodes must stay inside the screen no matter how wide the swing goes.
	for slot in range(0, 60):
		var point := map._point_at(float(slot))
		_assert(
			point.x - LevelMapViewType.NODE_RADIUS >= 0.0 and point.x + LevelMapViewType.NODE_RADIUS <= map.size.x,
			"Slot %d must stay within the map's width" % slot
		)

	var centred := map.scroll_offset_for_level(25, 1280.0)
	_assert(centred >= 0.0 and centred <= map.content_height() - 1280.0, "Centring must stay inside the scrollable range")
	_assert(map.scroll_offset_for_level(1, 1280.0) >= 0.0, "Centring on level 1 must not scroll past the bottom")

	map.queue_free()
	await process_frame


func _test_map_view_locks_future_levels() -> void:
	var map := LevelMapViewType.new()
	root.add_child(map)
	map.size = Vector2(720.0, 1280.0)
	map.configure(10, [] as Array[int], 1000)
	map.set_window(0.0, map.content_height())
	await process_frame


	var chosen: Array[int] = []
	var chests: Array[int] = []
	map.level_selected.connect(func(value: int) -> void: chosen.append(value))
	map.chest_selected.connect(func(value: int) -> void: chests.append(value))

	_tap(map, LevelMilestoneType.slot_for_level(4))
	_tap(map, LevelMilestoneType.slot_for_level(10))
	_assert(chosen == _ints([4, 10]), "Cleared and current levels must both be selectable, got %s" % str(chosen))

	_tap(map, LevelMilestoneType.slot_for_level(11))
	_tap(map, LevelMilestoneType.slot_for_level(400))
	_assert(chosen == _ints([4, 10]), "A level beyond the player's furthest must not be selectable")

	# The first chest follows level 20, which a player standing on level 10 has
	# not reached.
	_tap(map, LevelMilestoneType.slot_for_chest(1))
	_assert(chests.is_empty(), "A locked chest must not be claimable")

	map.configure(21, [] as Array[int], 1000)
	map.set_window(0.0, map.content_height())
	_tap(map, LevelMilestoneType.slot_for_chest(1))
	_assert(chests == _ints([1]), "Clearing level 20 must make chest 1 claimable")

	# A flick that starts on a playable plate must scroll, not select.
	var before := chosen.size()
	_drag(map, LevelMilestoneType.slot_for_level(4))
	_assert(chosen.size() == before, "A drag across a level must scroll, not open it")
	_assert(map.mouse_filter == Control.MOUSE_FILTER_PASS,
		"The map must pass input through so the ScrollContainer can scroll")

	map.queue_free()
	await process_frame


func _test_mobile_drag_scrolls_the_container() -> void:
	var scroll := ScrollContainer.new()
	scroll.size = Vector2(720.0, 1280.0)
	root.add_child(scroll)
	var map := LevelMapViewType.new()
	map.size = Vector2(720.0, 1280.0)
	map.configure(25, [] as Array[int], 1000)
	scroll.add_child(map)
	await process_frame
	scroll.scroll_vertical = 500
	var drag := InputEventScreenDrag.new()
	drag.position = Vector2(360.0, 640.0)
	drag.relative = Vector2(0.0, -120.0)
	map._gui_input(drag)
	_assert(scroll.scroll_vertical == 620,
		"An Android finger drag must directly move the level ScrollContainer")
	scroll.queue_free()
	await process_frame


func _test_overlay_presents_and_centres() -> void:
	var overlay := LevelSelectType.new()
	root.add_child(overlay)
	await process_frame
	_assert(not overlay.is_open(), "The level screen must start hidden")

	overlay.present(21, 1450, [1] as Array[int])
	await process_frame
	await process_frame
	_assert(overlay.is_open(), "present() must show the level screen")
	_assert(overlay.title_label.text == "LEVEL 21", "The banner must name the player's furthest level")
	_assert(overlay.play_button.text == "PLAY LEVEL 21", "The hero button must offer the player's furthest level")
	_assert(overlay.map_view.highest_level == 21, "The map must be configured with the furthest level")
	_assert(overlay.map_view.claimed_chests == _ints([1]), "Opened chests must reach the map")

	# The chest line must report the chest that is actually sitting on the path,
	# not a countdown to the next one. Standing on 21 with chest 1 unopened, the
	# old wording read "Next chest in 20 levels" - which talks the player out of
	# collecting a reward they have already earned.
	overlay.update_state(21, 1450, _ints([]))
	_assert(overlay.subtitle_label.text.to_lower().contains("ready"),
		"An unopened earned chest must be announced, got '%s'" % overlay.subtitle_label.text)
	overlay.update_state(21, 1450, _ints([1]))
	_assert(overlay.subtitle_label.text == "Next chest in 20 levels",
		"With every earned chest opened the line must count down to the next, got '%s'" % overlay.subtitle_label.text)
	overlay.update_state(20, 1450, _ints([]))
	_assert(overlay.subtitle_label.text == "Next chest in 1 level",
		"One level short of a chest must read as singular, got '%s'" % overlay.subtitle_label.text)
	overlay.update_state(1, 1450, _ints([]))
	_assert(overlay.subtitle_label.text == "Next chest in 20 levels",
		"A new player must see the full countdown, got '%s'" % overlay.subtitle_label.text)
	overlay.update_state(21, 1450, _ints([1]))

	# The map opens on the player, not at the bottom of a thousand-level path.
	_assert(overlay.scroll.scroll_vertical > 0, "The map must scroll to the player's level on open")

	var chosen: Array[int] = []
	overlay.level_chosen.connect(func(value: int) -> void: chosen.append(value))
	overlay.play_button.pressed.emit()
	_assert(chosen == _ints([21]), "The hero button must choose the player's furthest level")

	# An already-opened chest must not be claimable a second time.
	var claims: Array[int] = []
	overlay.chest_claim_requested.connect(func(value: int) -> void: claims.append(value))
	overlay._on_chest_selected(1)
	_assert(claims.is_empty(), "An opened chest must not be claimable again")

	overlay.dismiss()
	_assert(not overlay.is_open(), "dismiss() must hide the level screen")
	overlay.queue_free()
	await process_frame


## The controller's own routing, checked against the source so the flow cannot
## be quietly rewired back to skipping the map.
func _test_controller_flow_wiring() -> void:
	_assert(
		GameControllerType.AppFlowState.has("LEVEL_SELECT"),
		"The controller must own a level-select flow state"
	)
	var source := FileAccess.get_file_as_string("res://scripts/gameplay/game_controller.gd")
	_assert(
		source.contains("func _on_home_level_intro_requested() -> void:")
			and source.split("func _on_home_level_intro_requested() -> void:")[1].split("func ")[0].contains("_show_level_select()"),
		"Home PLAY must open the level map, not the level popup"
	)
	var level_start := source.split("func _show_level_start() -> void:")[1].split("\nfunc ")[0]
	_assert(
		level_start.contains("restart()"),
		"Entering a level must rebuild it, so leaving for Home cannot resume a half-played table"
	)
	var completion := source.split("func _finish_completion_transition() -> void:")[1].split("\nfunc ")[0]
	_assert(
		completion.contains("_show_level_select()"),
		"Next Level must return to the map"
	)
	_assert(
		completion.contains("highest_level = maxi(highest_level, level_number)"),
		"Winning must never lower the map's unlocked boundary"
	)


## Selection happens on release now, so a tap is press then release at the same
## point. A press alone is the start of a scroll and must select nothing.
func _tap(map: Control, slot: int) -> void:
	var at: Vector2 = map._point_at(float(slot))
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = at
	map._gui_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = at
	map._gui_input(release)


## A press, a move, and a release: a flick across the map, which must scroll
## rather than opening whatever level happened to be under the finger.
func _drag(map: Control, slot: int) -> void:
	var at: Vector2 = map._point_at(float(slot))
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = at
	map._gui_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = at + Vector2(0.0, 90.0)
	map._gui_input(release)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


## `[1, 2] as Array[int]` binds looser than `==`, so comparisons build their
## expected array through this instead.
func _ints(values: Array) -> Array[int]:
	var result: Array[int] = []
	for value in values:
		result.append(int(value))
	return result
