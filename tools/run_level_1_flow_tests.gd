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
		ids[entry.id] = true

func _test_level_sequence() -> void:
	var config := LevelConfigType.level_1()
	var sequence: Array = config.target_sequence
	_assert(sequence.size() == 2, "Level 1 must define exactly two sequential targets")
	_assert(int(sequence[0].tier) == 3 and int(sequence[1].tier) == 4, "Level 1 target order must be L3 then L4")
	_assert(not config.has("shot_limit"), "Level 1 must not define a shot limit")

func _test_unlimited_launcher() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	for index in range(30):
		var active = controller.get_active_piece()
		_assert(active != null and [1, 2].has(active.level), "Unlimited queue must keep producing configured low tiers")
		active.is_active_launcher = false
		controller.active_piece_id = -1
		controller.launcher_state = controller.LauncherState.SPAWNING_NEXT
		controller._advance_launcher_lifecycle()
	_assert(controller.shot_count == 0, "No production shot counter may advance")
	controller.queue_free()

func _complete_target(controller, level: int, id: int) -> void:
	var result := _piece(id, level, Vector2(360, 720))
	controller.pieces.append(result)
	var events: Array[Dictionary] = []
	events.append({"level": level, "depth": 0, "result_id": id})
	controller._apply_confirmed_merge_events(events)
	controller._update_merge_presentations(GameConfig.MERGE_PRESENTATION_DURATION + 0.01)
	_assert(controller.collection_in_progress, "Confirmed target must begin collection only after merge presentation")
	controller._update_target_collection(0.60)

func _test_sequential_target_completion() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	_complete_target(controller, 3, 1001)
	_assert(controller.target_index == 1 and controller.target_progress == 0 and not controller.win_qualified, "Intermediate target must advance without victory")
	_complete_target(controller, 4, 1002)
	_assert(controller.target_index == 2 and controller.win_qualified and not controller.win_presented, "Final target must qualify only after collection animation")
	controller._update_win_presentation(GameConfig.WIN_PRESENTATION_HOLD + 0.01)
	_assert(controller.win_presented, "Win overlay must follow final collection completion")
	controller.restart()
	_assert(controller.target_index == 0 and controller.target_progress == 0 and not controller.collection_in_progress, "Restart must restore target sequence safely")
	controller.queue_free()
