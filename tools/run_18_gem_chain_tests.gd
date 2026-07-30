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
	_test_motion_regression_guards()
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

func _test_motion_regression_guards() -> void:
	# Texture lookup sits on the per-frame visual sync path. Every tier must be
	# an already-loaded resource, and no runtime-sized texture may exceed 256px.
	for level in range(1, GameConfig.MAX_GEM_LEVEL + 1):
		var first := AssetCatalogType.gem_texture(level)
		var second := AssetCatalogType.gem_texture(level)
		_assert(first != null and first == second, "Tier %d texture must come from the initialized cache" % level)
		_assert(maxi(first.get_width(), first.get_height()) <= 256, "Tier %d runtime texture must be mobile-sized" % level)
	var catalog_source := FileAccess.get_file_as_string("res://scripts/asset_catalog.gd")
	var sprite_layer_source := FileAccess.get_file_as_string("res://scripts/gem_sprite_layer.gd")
	_assert(not catalog_source.contains("var texture := load(") and not catalog_source.contains("ResourceLoader.load("), "Asset catalog must never load textures during gameplay")
	_assert(not sprite_layer_source.contains("_process") and not sprite_layer_source.contains("_physics_process"), "Sprite layer must not own a per-frame processing callback")
	_assert(not sprite_layer_source.contains("_alpha_bounds"), "Sprite layer must not calculate alpha bounds during gameplay")
	_assert(not sprite_layer_source.contains("perspective") and not sprite_layer_source.contains("table_interpolation"), "18-gem sprite layer must not add perspective or Y scaling")
	# Exact motion profile from new-table-shadow-contact-fix-v1; catalog size is
	# the only allowed physics-related extension.
	_assert(GameConfig.GEM_COLLISION_RADIUS[1] == 42.0 and GameConfig.GEM_COLLISION_RADIUS[2] == 42.0 and GameConfig.GEM_COLLISION_RADIUS[3] == 32.0 and GameConfig.GEM_COLLISION_RADIUS[4] == 42.0 and GameConfig.GEM_COLLISION_RADIUS[5] == 33.0, "Baseline collider values must be restored exactly")
	_assert(is_equal_approx(GameConfig.LAUNCH_SPEED, 1160.0) and is_equal_approx(GameConfig.VELOCITY_DAMPING_PER_SECOND, 235.0) and is_equal_approx(GameConfig.COLLISION_RESTITUTION, 0.34) and is_equal_approx(GameConfig.COLLISION_TANGENTIAL_FRICTION, 0.18), "Baseline motion constants must remain unchanged")
	var flight_piece := _piece(99, 7, Vector2(360.0, 700.0))
	var radius_before := flight_piece.radius
	flight_piece.velocity = Vector2(0.0, -GameConfig.LAUNCH_SPEED)
	SimulationType.new().step([flight_piece], 1.0 / 60.0, MergeType.new())
	_assert(is_equal_approx(flight_piece.radius, radius_before), "Flight and settling must never resize a physics body")
