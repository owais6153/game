extends SceneTree

const GameScene = preload("res://scenes/Game.tscn")
const GemPieceType = preload("res://scripts/gem_piece.gd")
const LevelConfigType = preload("res://scripts/level_config.gd")
const AssetCatalogType = preload("res://scripts/asset_catalog.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_catalog_identity()
	_test_level_sequence()
	_test_unlimited_launcher()
	_test_unlimited_launcher_after_restart()
	_test_unlimited_launcher_while_board_moves()
	_test_unrelated_merge_during_shot_cannot_deadlock_launcher()
	_test_unlimited_launcher_through_real_process_loop()
	_test_missing_active_marker_recovers_without_cap()
	_test_target_collection_during_shot_preserves_unlimited_flow()
	_test_pause_settings_restart_preserves_unlimited_flow()
	_test_sequential_target_completion()
	if failures.is_empty():
		print("LEVEL_1_FLOW_TESTS: PASS")
		quit(0)
	for failure in failures:
		push_error(failure)
	quit(1)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _piece(id: int, level: int, position: Vector2) -> GemPiece:
	return GemPieceType.new(id, level, position, GameConfig.gem_collision_radius(level))

func _test_catalog_identity() -> void:
	var ids := {}
	for tier in range(1, 19):
		var entry := AssetCatalogType.gem_entry(tier)
		_assert(int(entry.tier) == tier, "Catalog tier must round-trip")
		_assert(not String(entry.id).is_empty() and not ids.has(entry.id), "All catalog IDs must be unique")
		_assert(not String(entry.name).is_empty() and entry.texture != null, "Every catalog entry needs a name and texture")
		_assert(entry.texture.resource_path == AssetCatalogType.gem_texture(tier).resource_path, "HUD and runtime must share one texture source")
		_assert(int(AssetCatalogType.GEM_TIER_SOURCE_INDEX[tier]) == int(entry.texture.resource_path.get_file().trim_suffix(".png").trim_prefix("tier_")), "Tier, name, and runtime icon must share the approved source identity")
		ids[entry.id] = true

func _test_level_sequence() -> void:
	var config := LevelConfigType.level_1()
	var sequence: Array = config.target_sequence
	_assert(sequence.size() == 2, "Level 1 must define exactly two sequential targets")
	_assert(int(sequence[0].tier) == 7 and int(sequence[0].quantity) == 1 and int(sequence[1].tier) == 8 and int(sequence[1].quantity) == 1, "Level 1 must require exactly L7 then L8")
	_assert((config.spawnable_tiers as Array).size() == 4 and (config.launcher_sequence as Array).size() >= 8, "Level 1 needs controlled low-tier variety rather than a straight-line L1/L1 loop")
	_assert(not config.has("shot_limit"), "Level 1 must not define a shot limit")
	_assert(int(config.active_tier_max) == 8, "Level 1 must permit L7 then L8 objectives without direct high-tier launches")

func _test_unlimited_launcher() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	for index in range(30):
		var active = controller.get_active_piece()
		_assert(active != null and [1, 2, 3, 4].has(active.level), "Unlimited queue must keep producing configured low tiers")
		active.is_active_launcher = false
		controller.active_piece_id = -1
		controller.launcher_state = controller.LauncherState.SPAWNING_NEXT
		controller._advance_launcher_lifecycle()
	controller.queue_free()

func _test_unlimited_launcher_after_restart() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	controller.restart()
	for index in range(60):
		var active = controller.get_active_piece()
		_assert(active != null and [1, 2, 3, 4].has(active.level), "Restart must not restore a hidden finite launch limit")
		active.is_active_launcher = false
		controller.active_piece_id = -1
		controller.launcher_state = controller.LauncherState.SPAWNING_NEXT
		controller._advance_launcher_lifecycle()
	controller.queue_free()

func _test_unlimited_launcher_while_board_moves() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	var launched = controller.get_active_piece()
	controller.launch_active_piece()
	launched.velocity = Vector2(220.0, -180.0)
	var unrelated_moving_piece := _piece(9001, 1, Vector2(360.0, GameConfig.BOARD_TOP + 100.0))
	unrelated_moving_piece.velocity = Vector2(180.0, 0.0)
	controller.pieces.append(unrelated_moving_piece)
	controller._advance_launcher_lifecycle(GameConfig.LAUNCHER_HANDOFF_DELAY + 0.01)
	controller._advance_launcher_lifecycle(GameConfig.NEXT_LAUNCHER_READY_DELAY + 0.01)
	controller._advance_launcher_lifecycle()
	_assert(controller.get_active_piece() != null and controller.lifecycle_name() == "READY_TO_AIM", "A moving board gem must never block the next unlimited launcher")
	_assert(launched.is_moving() and not launched.is_active_launcher, "The fired gem may keep moving but must become a normal board body after bounded handoff")
	controller.queue_free()

func _test_unrelated_merge_during_shot_cannot_deadlock_launcher() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	var fired = controller.get_active_piece()
	controller.launch_active_piece()
	# Force a different pair to merge while the fired launcher remains live.
	controller.pieces.append(_piece(9001, 2, Vector2(300.0, GameConfig.board_top() + 120.0)))
	controller.pieces.append(_piece(9002, 2, Vector2(380.0, GameConfig.board_top() + 120.0)))
	controller._process(1.0 / 60.0)
	_assert(controller.lifecycle_name() == "SHOT_IN_FLIGHT" and controller.get_active_piece() == fired, "An unrelated merge must not overwrite the in-flight launcher state")
	var next_ready := false
	for frame in range(90):
		controller._process(1.0 / 60.0)
		var replacement = controller.get_active_piece()
		if replacement != null and replacement != fired and controller.lifecycle_name() == "READY_TO_AIM":
			next_ready = true
			break
	var active_count: int = controller.pieces.filter(func(piece): return piece.is_active_launcher and not piece.consumed).size()
	_assert(next_ready, "An unrelated merge during a live shot must still produce the next launcher")
	_assert(active_count == 1 and not fired.is_active_launcher, "Launcher handoff must leave exactly one active launcher")
	controller.queue_free()

func _test_unlimited_launcher_through_real_process_loop() -> void:
	# Drive the production `_process` path instead of changing launcher state
	# directly. This catches a hidden lifecycle gate that would make a live
	# build appear to run out of shots despite having no numeric cap.
	var controller = GameScene.instantiate()
	controller._ready()
	for shot_number in range(40):
		var launched = controller.get_active_piece()
		_assert(launched != null and controller.lifecycle_name() == "READY_TO_AIM", "Shot %d must start with a ready launcher" % (shot_number + 1))
		if launched == null:
			break
		var launched_id: int = launched.id
		controller.launch_active_piece()
		var next_ready := false
		for frame in range(480):
			controller._process(1.0 / 60.0)
			var replacement = controller.get_active_piece()
			if replacement != null and replacement.id != launched_id and controller.lifecycle_name() == "READY_TO_AIM":
				next_ready = true
				break
		_assert(next_ready and not controller.failed and not controller.win_qualified, "Shot %d must produce another ready launcher through the real process loop" % (shot_number + 1))
		# Isolate launcher continuity from normal board-capacity/danger pressure.
		var ready_piece = controller.get_active_piece()
		if ready_piece != null:
			controller.pieces.clear()
			controller.pieces.append(ready_piece)
			controller.danger_timers.clear()
	controller.queue_free()

func _test_missing_active_marker_recovers_without_cap() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	var initial = controller.get_active_piece()
	_assert(initial != null, "Recovery test must begin with a ready launcher")
	if initial != null:
		initial.is_active_launcher = false
		controller.active_piece_id = -1
		controller._advance_launcher_lifecycle()
		controller._advance_launcher_lifecycle()
		_assert(controller.get_active_piece() != null and controller.lifecycle_name() == "READY_TO_AIM", "A missing active marker must regenerate the unlimited launcher")
	controller.queue_free()

func _test_target_collection_during_shot_preserves_unlimited_flow() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	var fired = controller.get_active_piece()
	controller.launch_active_piece()
	var target_result := _piece(9100, 7, Vector2(360.0, 720.0))
	controller.pieces.append(target_result)
	var events: Array[Dictionary] = [{"level": 7, "depth": 0, "result_id": 9100}]
	controller._apply_confirmed_merge_events(events)
	controller._sync_gems_and_mark_visibility()
	controller._update_merge_presentations(GameConfig.MERGE_PRESENTATION_DURATION + 0.01)
	_assert(controller.collection_in_progress and controller.get_active_piece() == fired, "Target collection must pause without discarding the in-flight launcher marker")
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION + 0.01)
	controller._advance_launcher_lifecycle(GameConfig.LAUNCHER_HANDOFF_DELAY + 0.01)
	controller._advance_launcher_lifecycle(GameConfig.NEXT_LAUNCHER_READY_DELAY + 0.01)
	controller._advance_launcher_lifecycle()
	_assert(controller.get_active_piece() != null and controller.get_active_piece() != fired and controller.lifecycle_name() == "READY_TO_AIM", "Launcher generation must resume after first-target collection")
	controller.queue_free()

func _test_pause_settings_restart_preserves_unlimited_flow() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	var launcher_before_pointer = controller.get_active_piece()
	controller.next_queue_index = 37
	controller.launcher_handoff_elapsed = 99.0
	controller.score = 1250
	# The former gameplay-HUD restart rectangle is deliberately inert. Restart
	# is available only inside the settings/pause popup.
	controller._handle_pointer(GameConfig.RESTART_BUTTON_RECT.get_center(), true)
	controller._handle_pointer(GameConfig.RESTART_BUTTON_RECT.get_center(), false)
	_assert(controller.next_queue_index == 37 and controller.score == 1250 and controller.get_active_piece() == launcher_before_pointer, "Gameplay input must not expose the obsolete restart hit region")

	controller.gameplay_ui.settings_button.pressed.emit()
	_assert(controller.gameplay_ui.is_pause_visible(), "Settings must open the input-blocking pause popup")
	controller.gameplay_ui.restart_button.pressed.emit()
	_assert(not controller.gameplay_ui.is_pause_visible(), "Pause-popup Restart must close the popup")
	_assert(controller.next_queue_index == 1 and controller.score == 0 and controller.get_active_piece() != null and controller.lifecycle_name() == "READY_TO_AIM", "Pause-popup Restart must reset to one ready unlimited launcher")
	_assert(is_zero_approx(controller.launcher_handoff_elapsed), "Restart must clear launcher handoff timing without restoring a cap")
	for index in range(80):
		var active = controller.get_active_piece()
		_assert(active != null and [1, 2, 3, 4].has(active.level), "Pause-popup Restart must preserve unlimited configured launches (%d)" % (index + 1))
		if active == null:
			break
		active.is_active_launcher = false
		controller.active_piece_id = -1
		controller.launcher_state = controller.LauncherState.SPAWNING_NEXT
		controller._advance_launcher_lifecycle()
	controller.queue_free()

func _complete_target(controller, level: int, id: int) -> void:
	var result := _piece(id, level, Vector2(360, 720))
	controller.pieces.append(result)
	var events: Array[Dictionary] = []
	events.append({"level": level, "depth": 0, "result_id": id})
	controller._apply_confirmed_merge_events(events)
	# A target cannot enter collection until its merge result has synchronized
	# into the Sprite2D layer for at least one rendered frame.
	controller._sync_gems_and_mark_visibility()
	controller._update_merge_presentations(GameConfig.MERGE_PRESENTATION_DURATION + 0.01)
	_assert(controller.collection_in_progress, "Confirmed target must begin collection only after merge presentation")
	_assert(controller.pieces.filter(func(piece): return piece.id == id).is_empty(), "Collected target body must leave the live simulation before its fly-to-HUD animation")
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION + 0.01)

func _assert_event_order(controller, result_id: int, expected: Array[String]) -> void:
	var actual: Array[String] = controller.presentation_events_for_result(result_id)
	var previous_index := -1
	for event_name in expected:
		var event_index := actual.find(event_name, previous_index + 1)
		_assert(event_index >= 0, "Result %d must trace %s (actual: %s)" % [result_id, event_name, str(actual)])
		if event_index >= 0:
			previous_index = event_index

func _test_sequential_target_completion() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	var waiting_launcher = controller.get_active_piece()
	_complete_target(controller, 7, 1001)
	_assert_event_order(controller, 1001, ["merge_confirmed", "result_created", "result_first_frame_visible", "merge_presentation_completed", "target_completed", "physics_body_removed", "collection_animation_started", "collection_animation_completed"])
	_assert(controller.target_index == 1 and controller.target_progress == 0 and not controller.win_qualified, "Collected L7 must advance to the L8 target without victory")
	_assert(controller.get_active_piece() == waiting_launcher and controller.lifecycle_name() == "READY_TO_AIM", "First target collection must preserve the waiting unlimited launcher")
	_complete_target(controller, 8, 1002)
	_assert(controller.target_index == 2 and controller.win_qualified and not controller.win_presented, "Collected L8 must qualify only after collection animation")
	controller._update_win_presentation(GameConfig.WIN_PRESENTATION_HOLD + 0.01)
	_assert(controller.win_presented, "Win overlay must follow final collection completion")
	_assert_event_order(controller, 1002, ["merge_confirmed", "result_created", "result_first_frame_visible", "merge_presentation_completed", "target_completed", "physics_body_removed", "collection_animation_started", "collection_animation_completed", "final_target_confirmed", "win_overlay_started"])
	controller.restart()
	_assert(controller.target_index == 0 and controller.target_progress == 0 and not controller.collection_in_progress, "Restart must restore target sequence safely")
	controller.queue_free()
