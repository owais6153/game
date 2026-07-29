extends SceneTree

const GemPieceType = preload("res://scripts/gem_piece.gd")
const MergeType = preload("res://scripts/merge_service.gd")
const SimulationType = preload("res://scripts/board_simulation.gd")
const AssetCatalogType = preload("res://scripts/asset_catalog.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_catalog_and_textures()
	_test_adjacent_merges()
	_test_terminal_tier()
	_test_rejections_and_shadows()
	_test_fixed_table_config()
	if failures.is_empty():
		print("GEM18_CHAIN_TESTS: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _piece(id: int, level: int, position: Vector2) -> GemPiece:
	return GemPieceType.new(id, level, position, GameConfig.gem_collision_radius(level))

func _resolve(items: Array[GemPiece]) -> Dictionary:
	var merger := MergeType.new()
	var simulation := SimulationType.new()
	simulation.step(items, 0.0, merger)
	return merger.resolve(items, 1000)

func _test_catalog_and_textures() -> void:
	_assert(GameConfig.MAX_GEM_LEVEL == 18, "Catalog must have exactly 18 tiers")
	for level in range(1, GameConfig.MAX_GEM_LEVEL + 1):
		_assert(GameConfig.gem_name(level) != "Unknown", "Tier %d must have a deterministic name" % level)
		var path := AssetCatalogType.gem_resource_path(level)
		_assert(path.ends_with("tier_%02d.png" % level), "Tier %d must map to its own normalized texture" % level)
		_assert(ResourceLoader.exists(path), "Tier %d texture must load" % level)
		_assert(GameConfig.gem_collision_radius(level) > 0.0, "Tier %d needs a positive body collider" % level)

func _test_adjacent_merges() -> void:
	for level in range(1, GameConfig.MAX_GEM_LEVEL):
		var first := _piece(1, level, Vector2(280.0, 500.0))
		var second := _piece(2, level, Vector2(280.0 + first.radius + GameConfig.gem_collision_radius(level), 500.0))
		var result := _resolve([first, second])
		_assert(result.pieces.size() == 1 and result.pieces[0].level == level + 1, "L%d + L%d must create exactly L%d" % [level, level, level + 1])

func _test_terminal_tier() -> void:
	var first := _piece(1, 18, Vector2(280.0, 500.0))
	var second := _piece(2, 18, Vector2(280.0 + first.radius + GameConfig.gem_collision_radius(18), 500.0))
	var result := _resolve([first, second])
	_assert(result.pieces.size() == 2, "L18 must be terminal and never merge further")

func _test_rejections_and_shadows() -> void:
	var distant: Array[GemPiece] = [_piece(1, 7, Vector2(200.0, 500.0)), _piece(2, 7, Vector2(560.0, 500.0))]
	_assert(_resolve(distant).pieces.size() == 2, "Distant same-tier pieces must never merge")
	var mixed: Array[GemPiece] = [_piece(1, 7, Vector2(280.0, 500.0)), _piece(2, 8, Vector2(280.0 + GameConfig.gem_collision_radius(7) + GameConfig.gem_collision_radius(8), 500.0))]
	_assert(_resolve(mixed).pieces.size() == 2, "Different tiers must never merge")
	_assert(ResourceLoader.exists(AssetCatalogType.shadow_resource_path()), "Separate visual shadow must remain available")
	_assert(GameConfig.VISIBLE_CONTACT_TOLERANCE == 2.0, "Baseline visible-contact tolerance must remain unchanged")

func _test_fixed_table_config() -> void:
	_assert(GameConfig.TABLE_TEXTURE_CENTER == Vector2(360.0, 730.0), "Table placement must remain baseline-equivalent")
	_assert(GameConfig.TABLE_INNER_LEFT_TOP == 178.0 and GameConfig.TABLE_INNER_RIGHT_TOP == 542.0, "Table rail config must remain baseline-equivalent")
	_assert(GameConfig.TARGET_LEVEL == 5, "Baseline target flow must remain unchanged")
