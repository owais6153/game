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
	_test_unlimited_launcher_through_real_process_loop()
	_test_missing_active_marker_recovers_without_cap()
	_test_restart_hud_control()
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
	launched.velocity = Vector2.ZERO
	var unrelated_moving_piece := _piece(9001, 1, Vector2(360.0, GameConfig.BOARD_TOP + 100.0))
	unrelated_moving_piece.velocity = Vector2(180.0, 0.0)
	controller.pieces.append(unrelated_moving_piece)
	controller._advance_launcher_lifecycle()
	controller._advance_launcher_lifecycle(GameConfig.NEXT_LAUNCHER_READY_DELAY + 0.01)
	controller._advance_launcher_lifecycle()
	_assert(controller.get_active_piece() != null and controller.lifecycle_name() == "READY_TO_AIM", "A moving board gem must never block the next unlimited launcher")
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

func _test_restart_hud_control() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	controller.next_queue_index = 37
	controller._handle_pointer(GameConfig.RESTART_BUTTON_RECT.get_center(), true)
	_assert(controller.next_queue_index == 1 and controller.get_active_piece() != null and controller.lifecycle_name() == "READY_TO_AIM", "Supplied restart icon must reset to one ready unlimited launcher")
	controller.queue_free()

func _complete_target(controller, level: int, id: int) -> void:
	var result := _piece(id, level, Vector2(360, 720))
	controller.pieces.append(result)
	var events: Array[Dictionary] = []
	events.append({"level": level, "depth": 0, "result_id": id})
	controller._apply_confirmed_merge_events(events)
	controller._update_merge_presentations(GameConfig.MERGE_PRESENTATION_DURATION + 0.01)
	_assert(controller.collection_in_progress, "Confirmed target must begin collection only after merge presentation")
	_assert(controller.pieces.filter(func(piece): return piece.id == id).is_empty(), "Collected target body must leave the live simulation before its fly-to-HUD animation")
	controller._update_target_collection(0.60)

func _test_sequential_target_completion() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	_complete_target(controller, 7, 1001)
	_assert(controller.target_index == 1 and controller.target_progress == 0 and not controller.win_qualified, "Collected L7 must advance to the L8 target without victory")
	_complete_target(controller, 8, 1002)
	_assert(controller.target_index == 2 and controller.win_qualified and not controller.win_presented, "Collected L8 must qualify only after collection animation")
	controller._update_win_presentation(GameConfig.WIN_PRESENTATION_HOLD + 0.01)
	_assert(controller.win_presented, "Win overlay must follow final collection completion")
	controller.restart()
	_assert(controller.target_index == 0 and controller.target_progress == 0 and not controller.collection_in_progress, "Restart must restore target sequence safely")
	controller.queue_free()
