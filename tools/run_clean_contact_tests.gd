extends SceneTree

const GemPieceType = preload("res://scripts/gem_piece.gd")
const SimulationType = preload("res://scripts/board_simulation.gd")
const MergeType = preload("res://scripts/merge_service.gd")
const GameScene = preload("res://scenes/Game.tscn")
var failures: Array[String] = []

func _init() -> void:
	_test_contact_merges()
	_test_rejections()
	_test_one_piece_once_per_cycle()
	_test_contact_chain_merges()
	_test_distant_piece_does_not_chain()
	_test_chain_depth_cap()
	_test_merge_presentation_blocks_next_launcher()
	_test_unobstructed_top_border()
	_test_launcher_spawn_lifecycle()
	if failures.is_empty():
		print("CLEAN_CONTACT_TESTS: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _piece(id: int, level: int, at_position: Vector2) -> GemPiece:
	return GemPieceType.new(id, level, at_position, 35.0)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _resolve(items: Array[GemPiece]) -> Dictionary:
	var merger = MergeType.new()
	var simulation = SimulationType.new()
	simulation.step(items, 0.0, merger)
	return merger.resolve(items, 100)

func _test_contact_merges() -> void:
	var empty: Array[GemPiece] = []
	_assert(empty.is_empty(), "Board must start empty before the controller creates the launcher")
	var pearls: Array[GemPiece] = [_piece(1, 1, Vector2(300, 500)), _piece(2, 1, Vector2(360, 500))]
	var pearl_result := _resolve(pearls)
	_assert(pearl_result.pieces.size() == 1 and pearl_result.pieces[0].level == 2, "Contacting Pearl + Pearl must create one Ruby")
	var rubies: Array[GemPiece] = [_piece(1, 2, Vector2(300, 500)), _piece(2, 2, Vector2(360, 500))]
	var ruby_result := _resolve(rubies)
	_assert(ruby_result.pieces.size() == 1 and ruby_result.pieces[0].level == 3, "Contacting Ruby + Ruby must create one Emerald")

func _test_rejections() -> void:
	var distant: Array[GemPiece] = [_piece(1, 1, Vector2(200, 400)), _piece(2, 1, Vector2(500, 400))]
	_assert(_resolve(distant).pieces.size() == 2, "Distant Pearl/Pearl must not merge")
	var cross: Array[GemPiece] = [_piece(1, 1, Vector2(300, 400)), _piece(2, 2, Vector2(360, 400))]
	_assert(_resolve(cross).pieces.size() == 2, "Pearl + Ruby must not merge")

func _test_one_piece_once_per_cycle() -> void:
	var items: Array[GemPiece] = [_piece(1, 1, Vector2(300, 500)), _piece(2, 1, Vector2(360, 500)), _piece(3, 1, Vector2(420, 500))]
	_assert(_resolve(items).pieces.size() == 2, "A source piece must not merge twice in one cycle")

func _test_contact_chain_merges() -> void:
	var items: Array[GemPiece] = [_piece(1, 1, Vector2(300, 500)), _piece(2, 1, Vector2(360, 500)), _piece(3, 2, Vector2(330, 500))]
	var merger = MergeType.new()
	merger.capture_contact(items[0], items[1])
	var result := merger.resolve(items, 100)
	_assert(result.pieces.size() == 1 and result.pieces[0].level == 3, "A newly spawned Ruby physically contacting a Ruby must chain into Emerald")
	_assert(result.merge_count == 2 and result.chain_depth == 1, "A contact chain must record exactly one chained resolution")

func _test_distant_piece_does_not_chain() -> void:
	var items: Array[GemPiece] = [_piece(1, 1, Vector2(300, 500)), _piece(2, 1, Vector2(360, 500)), _piece(3, 2, Vector2(520, 500))]
	var merger = MergeType.new()
	merger.capture_contact(items[0], items[1])
	var result := merger.resolve(items, 100)
	_assert(result.pieces.size() == 2 and result.pieces.any(func(piece: GemPiece): return piece.level == 2), "A distant equal-level piece must not chain")

func _test_chain_depth_cap() -> void:
	var merger := MergeType.new()
	var items: Array[GemPiece] = [_piece(1, 1, Vector2(300, 500)), _piece(2, 1, Vector2(360, 500)), _piece(3, 2, Vector2(330, 500)), _piece(4, 3, Vector2(330, 500)), _piece(5, 4, Vector2(330, 500))]
	merger.capture_contact(items[0], items[1])
	var result := merger.resolve(items, 100)
	_assert(result.chain_depth <= GameConfig.MERGE_CHAIN_DEPTH_CAP, "Chain processing must remain capped")

func _test_merge_presentation_blocks_next_launcher() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	controller.merge_presentations.append({"first_position": Vector2(300, 500), "second_position": Vector2(360, 500), "midpoint": Vector2(330, 500), "level": 2, "depth": 0, "elapsed": 0.0})
	controller.launcher_state = controller.LauncherState.RESOLVING
	controller.active_piece_id = -1
	controller.pieces.clear()
	controller._process(0.01)
	_assert(controller.get_active_piece() == null, "Next launcher must wait while merge presentation is active")
	for frame in range(30): controller._process(1.0 / 60.0)
	_assert(controller.get_active_piece() != null, "Next launcher must spawn after merge presentation completes")

func _test_unobstructed_top_border() -> void:
	var simulation = SimulationType.new()
	var merger = MergeType.new()
	var shot := _piece(1, 1, Vector2(360, GameConfig.LAUNCH_Y))
	shot.velocity = Vector2(0, -GameConfig.LAUNCH_SPEED)
	var items: Array[GemPiece] = [shot]
	for index in range(500):
		simulation.step(items, 1.0 / 120.0, merger)
	_assert(shot.position.y >= GameConfig.BOARD_TOP + shot.radius, "Unobstructed shot must remain inside the top border")
	_assert(shot.velocity.length() < GameConfig.SLEEP_SPEED, "Unobstructed shot must settle")

func _test_launcher_spawn_lifecycle() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	_assert(controller.pieces.size() == 1 and controller.get_active_piece() != null, "Initial lifecycle state must contain exactly one active launcher")
	_assert(controller.lifecycle_name() == "READY_TO_AIM", "Initial launcher state must be READY_TO_AIM")
	var initial_next_level: int = controller.next_level
	controller.launch_active_piece()
	_assert(controller.lifecycle_name() == "SHOT_IN_FLIGHT", "Launching must enter SHOT_IN_FLIGHT")
	for frame in range(200):
		controller._process(1.0 / 60.0)
	_assert(controller.get_active_piece() != null, "Exactly one new active piece must exist after the first shot settles")
	_assert(_active_launcher_count(controller.pieces) == 1, "Active launcher count must never exceed one after settlement")
	_assert(controller.lifecycle_name() == "READY_TO_AIM", "Resolution must return to READY_TO_AIM")
	_assert(controller.next_level != initial_next_level, "Next queue must advance exactly once after the completed shot")
	var pieces_after_first_cycle: int = controller.pieces.size()
	var next_after_first_cycle: int = controller.next_level
	for frame in range(120):
		controller._process(1.0 / 60.0)
	_assert(controller.pieces.size() == pieces_after_first_cycle, "Idle frames must not spawn extra launcher pieces")
	_assert(controller.next_level == next_after_first_cycle, "Idle frames must not advance the next queue")
	controller.launch_active_piece()
	_assert(controller.lifecycle_name() == "SHOT_IN_FLIGHT", "Second launcher must be launchable normally")
	controller.restart()
	_assert(controller.pieces.size() == 1 and _active_launcher_count(controller.pieces) == 1, "Restart must leave exactly one active launcher")
	_assert(controller.lifecycle_name() == "READY_TO_AIM", "Restart must reset lifecycle to READY_TO_AIM")

func _active_launcher_count(items: Array[GemPiece]) -> int:
	var count := 0
	for item in items:
		if item.is_active_launcher and not item.consumed:
			count += 1
	return count
