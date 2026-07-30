extends SceneTree

const GemPieceType = preload("res://scripts/gem_piece.gd")
const MergeType = preload("res://scripts/merge_service.gd")
const SimulationType = preload("res://scripts/board_simulation.gd")
const AssetCatalogType = preload("res://scripts/asset_catalog.gd")

const EXPECTED_SOURCE_INDEX := {
	1: 16, 2: 4, 3: 5, 4: 8, 5: 2, 6: 7, 7: 1, 8: 3, 9: 11,
	10: 9, 11: 6, 12: 10, 13: 14, 14: 15, 15: 18, 16: 12, 17: 13, 18: 17,
}
const EXPECTED_NAMES := ["Pearl", "Obsidian", "Jade", "Aquamarine", "Peridot", "Pink Tourmaline", "Ruby", "Sapphire", "Emerald", "Watermelon Tourmaline", "Morganite", "Garnet", "Amethyst", "Citrine", "Orange Sapphire", "Royal Sapphire", "Diamond", "Blue Diamond"]

var failures: Array[String] = []

func _init() -> void:
	_test_catalog_and_textures()
	_test_calibrated_body_manifest()
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
	_assert(AssetCatalogType.GEM_TIER_SOURCE_INDEX == EXPECTED_SOURCE_INDEX, "Catalog order must match the final approved source-asset order")
	_assert(EXPECTED_NAMES.size() == GameConfig.MAX_GEM_LEVEL, "Final gem names must cover all tiers")
	var paths := {}
	for level in range(1, GameConfig.MAX_GEM_LEVEL + 1):
		_assert(GameConfig.gem_name(level) == EXPECTED_NAMES[level - 1], "Tier %d must have its final display name" % level)
		var path := AssetCatalogType.gem_resource_path(level)
		_assert(path.ends_with("tier_%02d.png" % EXPECTED_SOURCE_INDEX[level]), "Tier %d must map to its approved visual asset" % level)
		_assert(not paths.has(path), "Each catalog tier must map to one unique visual asset")
		paths[path] = true
		_assert(ResourceLoader.exists(path), "Tier %d texture must load" % level)
		_assert(GameConfig.gem_collision_radius(level) > 0.0, "Tier %d needs a positive body collider" % level)
		_assert(GameConfig.GEM_VISUAL_BODY_SCALE.has(level), "Tier %d needs an asset-prepared visual body scale" % level)
		_assert(GameConfig.GEM_SHADOW_OFFSET.has(level) and GameConfig.GEM_SHADOW_OPACITY.has(level), "Tier %d needs a separate calibrated visual shadow" % level)

func _test_calibrated_body_manifest() -> void:
	var path := "res://assets/runtime/gems18/calibrated/calibration_manifest.json"
	_assert(FileAccess.file_exists(path), "Calibrated 18-gem body manifest must exist")
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	_assert(parsed is Dictionary, "Calibrated body manifest must parse")
	if not parsed is Dictionary:
		return
	var entries: Array = parsed.get("entries", [])
	_assert(entries.size() == GameConfig.MAX_GEM_LEVEL, "Calibrated body manifest must include all 18 tiers")
	for entry in entries:
		var level := int(entry.get("tier", 0))
		var body: Array = entry.get("visible_body_bounds", [])
		var texture_size: Array = entry.get("texture_size", [])
		_assert(level >= 1 and level <= GameConfig.MAX_GEM_LEVEL, "Calibrated manifest tier must be valid")
		_assert(body.size() == 4 and body[2] > 0 and body[3] > 0, "Tier %d needs a positive measured visible body" % level)
		_assert(texture_size.size() == 2 and texture_size[0] <= 256 and texture_size[1] <= 256, "Tier %d calibrated runtime texture must stay mobile-sized" % level)
		_assert(str(entry.get("runtime_texture", "")).contains("/calibrated/tier_%02d.png" % level), "Tier %d must use its calibrated derivative" % level)
		_assert(AssetCatalogType.gem_resource_path(level).contains("/calibrated/tier_%02d.png" % EXPECTED_SOURCE_INDEX[level]), "Tier %d catalog must preload its approved calibrated derivative" % level)

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
	_assert(GameConfig.GEM_COLLISION_RADIUS[1] == 42.0 and GameConfig.GEM_COLLISION_RADIUS[3] == 33.0 and GameConfig.GEM_COLLISION_RADIUS[8] == 32.0, "Reordered tiers must retain their asset-calibrated collider values")
	_assert(is_equal_approx(GameConfig.LAUNCH_SPEED, 1160.0) and is_equal_approx(GameConfig.VELOCITY_DAMPING_PER_SECOND, 235.0) and is_equal_approx(GameConfig.COLLISION_RESTITUTION, 0.34) and is_equal_approx(GameConfig.COLLISION_TANGENTIAL_FRICTION, 0.18), "Baseline motion constants must remain unchanged")
	var flight_piece := _piece(99, 7, Vector2(360.0, 700.0))
	var radius_before := flight_piece.radius
	flight_piece.velocity = Vector2(0.0, -GameConfig.LAUNCH_SPEED)
	SimulationType.new().step([flight_piece], 1.0 / 60.0, MergeType.new())
	_assert(is_equal_approx(flight_piece.radius, radius_before), "Flight and settling must never resize a physics body")
