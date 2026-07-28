extends SceneTree

const GemPieceType = preload("res://scripts/gem_piece.gd")
const SimulationType = preload("res://scripts/board_simulation.gd")
const MergeType = preload("res://scripts/merge_service.gd")
var failures: Array[String] = []

func _init() -> void:
	_test_contact_merges()
	_test_rejections()
	_test_one_piece_once_per_cycle()
	_test_unobstructed_top_border()
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