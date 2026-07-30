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
	_test_merge_result_contract()
	_test_duplicate_and_simultaneous_contact_safety()
	_test_chain_determinism_and_cleanup()
	_test_controller_merge_score_and_launcher_guard()
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
	_assert(result.merge_count == 0 and result.next_id == 1000, "L18 must not allocate a nonexistent L19 result")
	_assert(result.presentation_events.is_empty(), "L18 must not emit a merge event")

func _test_rejections_and_shadows() -> void:
	var distant: Array[GemPiece] = [_piece(1, 7, Vector2(200.0, 500.0)), _piece(2, 7, Vector2(560.0, 500.0))]
	_assert(_resolve(distant).pieces.size() == 2, "Distant same-tier pieces must never merge")
	var mixed: Array[GemPiece] = [_piece(1, 7, Vector2(280.0, 500.0)), _piece(2, 8, Vector2(280.0 + GameConfig.gem_collision_radius(7) + GameConfig.gem_collision_radius(8), 500.0))]
	_assert(_resolve(mixed).pieces.size() == 2, "Different tiers must never merge")
	_assert(ResourceLoader.exists(AssetCatalogType.shadow_resource_path()), "Separate visual shadow must remain available")
	_assert(GameConfig.VISIBLE_CONTACT_TOLERANCE == 2.0, "Baseline visible-contact tolerance must remain unchanged")

func _test_merge_result_contract() -> void:
	for level in range(1, GameConfig.MAX_GEM_LEVEL):
		var first := _piece(10, level, Vector2(280.0, 500.0))
		var second := _piece(11, level, Vector2(280.0 + first.radius + GameConfig.gem_collision_radius(level), 500.0))
		first.velocity = Vector2(120.0, -40.0)
		second.velocity = Vector2(80.0, 20.0)
		var merger := MergeType.new()
		merger.capture_contact(first, second)
		var result := merger.resolve([first, second], 700)
		var upgraded: GemPiece = result.pieces[0]
		var event: Dictionary = result.presentation_events[0]
		_assert(upgraded.level == level + 1 and upgraded.radius == GameConfig.gem_collision_radius(level + 1), "L%d result must use its exact tier and collider" % level)
		_assert(upgraded.position == Vector2(280.0 + first.radius, 500.0), "L%d result must spawn at the source midpoint" % level)
		_assert(upgraded.velocity.length() <= GameConfig.MERGE_MAX_SPAWN_SPEED + 0.01 and upgraded.velocity.is_finite(), "L%d result must inherit only bounded valid momentum" % level)
		_assert(String(event.result_texture_path) == AssetCatalogType.gem_resource_path(level + 1), "L%d result must map its approved texture" % level)
		_assert(is_equal_approx(float(event.result_radius), upgraded.radius), "L%d event metadata must retain collider mapping" % level)
		_assert(is_equal_approx(float(event.result_visual_scale), float(GameConfig.GEM_VISUAL_BODY_SCALE[level + 1])), "L%d result must retain display scale mapping" % level)
		_assert(event.result_shadow_offset == GameConfig.GEM_SHADOW_OFFSET[level + 1] and is_equal_approx(float(event.result_shadow_opacity), float(GameConfig.GEM_SHADOW_OPACITY[level + 1])), "L%d result must retain visual-only shadow mapping" % level)
		_assert(first.consumed and second.consumed and not result.pieces.has(first) and not result.pieces.has(second), "L%d sources must be consumed and removed exactly once" % level)

func _test_duplicate_and_simultaneous_contact_safety() -> void:
	var first := _piece(1, 4, Vector2(300, 500))
	var second := _piece(2, 4, Vector2(384, 500))
	var merger := MergeType.new()
	# The simulation can report the same contact in either orientation or across
	# narrow-phase passes; one pair must still produce exactly one upgraded gem.
	merger.capture_contact(first, second)
	merger.capture_contact(second, first)
	merger.capture_contact(first, second)
	var result := merger.resolve([first, second], 100)
	_assert(result.merge_count == 1 and result.pieces.size() == 1 and result.presentation_events.size() == 1, "Duplicate contact reports must resolve one merge once")
	var center := _piece(10, 6, Vector2(360, 500))
	var left := _piece(11, 6, Vector2(276, 500))
	var right := _piece(12, 6, Vector2(444, 500))
	var simultaneous := MergeType.new()
	simultaneous.capture_contact(center, left)
	simultaneous.capture_contact(center, right)
	var simultaneous_result := simultaneous.resolve([center, left, right], 200)
	_assert(simultaneous_result.merge_count == 1 and simultaneous_result.pieces.size() == 2 and simultaneous_result.presentation_events.size() == 1, "Simultaneous contacts sharing one source must not duplicate a result or reward")

func _test_chain_determinism_and_cleanup() -> void:
	# Two L1s create L2 directly touching an existing L2, which must then create
	# exactly one L3. Reversing input order must yield the same state.
	var a := _piece(1, 1, Vector2(300, 500))
	var b := _piece(2, 1, Vector2(384, 500))
	var existing := _piece(3, 2, Vector2(342, 500))
	var merger := MergeType.new()
	merger.capture_contact(a, b)
	var forward := merger.resolve([a, b, existing], 100)
	_assert(forward.merge_count == 2 and forward.pieces.size() == 1 and forward.pieces[0].level == 3 and forward.presentation_events.size() == 2, "A local physical chain must resolve exactly L1->L2->L3")
	_assert(forward.presentation_events[0].depth == 0 and forward.presentation_events[1].depth == 1, "Chain events must retain deterministic depths")
	var ra := _piece(1, 1, Vector2(300, 500))
	var rb := _piece(2, 1, Vector2(384, 500))
	var rexisting := _piece(3, 2, Vector2(342, 500))
	var reversed_merger := MergeType.new()
	reversed_merger.capture_contact(rb, ra)
	var reversed := reversed_merger.resolve([rexisting, rb, ra], 100)
	_assert(reversed.merge_count == forward.merge_count and reversed.pieces.size() == forward.pieces.size() and reversed.pieces[0].level == forward.pieces[0].level, "Chain output must not depend on source-array ordering")
	_assert(a.consumed and b.consumed and existing.consumed and not merger.has_pending_candidates(), "Consumed sources and pending contacts must be cleaned after a chain")

func _test_controller_merge_score_and_launcher_guard() -> void:
	var controller_scene := load("res://scenes/Game.tscn") as PackedScene
	var controller = controller_scene.instantiate()
	controller._ready()
	var direct_events: Array[Dictionary] = []
	direct_events.append({"level": 2, "depth": 0})
	controller._apply_confirmed_merge_events(direct_events)
	_assert(controller.score == GameConfig.merge_score_for_result_level(2), "Score must increment once for one confirmed merge")
	var no_events: Array[Dictionary] = []
	controller._apply_confirmed_merge_events(no_events)
	_assert(controller.score == GameConfig.merge_score_for_result_level(2), "Empty/non-confirmed merge events must not award score")
	_assert(controller.get_active_piece() != null and controller.pieces.filter(func(piece: GemPiece) -> bool: return piece.is_active_launcher).size() == 1, "Merge validation must preserve the one-active-launcher invariant")
	controller.queue_free()

func _test_fixed_table_config() -> void:
	_assert(GameConfig.TABLE_TEXTURE_CENTER == Vector2(360.0, 770.0), "Table placement must use the approved lower composition")
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
	_assert(sprite_layer_source.contains("gem_perspective_scale_at") and sprite_layer_source.contains("gem_visual_z_index"), "Sprite layer must use the bounded presentation-only perspective and stable depth ordering")
	_assert(not sprite_layer_source.contains("ResourceLoader.load("), "Perspective path must not load resources during gameplay")
	# Exact motion profile from new-table-shadow-contact-fix-v1; catalog size is
	# the only allowed physics-related extension.
	_assert(GameConfig.GEM_COLLISION_RADIUS[1] == 42.0 and GameConfig.GEM_COLLISION_RADIUS[3] == 33.0 and GameConfig.GEM_COLLISION_RADIUS[8] == 32.0, "Reordered tiers must retain their asset-calibrated collider values")
	_assert(is_equal_approx(GameConfig.LAUNCH_SPEED, 1160.0) and is_equal_approx(GameConfig.VELOCITY_DAMPING_PER_SECOND, 235.0) and is_equal_approx(GameConfig.COLLISION_RESTITUTION, 0.34) and is_equal_approx(GameConfig.COLLISION_TANGENTIAL_FRICTION, 0.18), "Baseline motion constants must remain unchanged")
	var flight_piece := _piece(99, 7, Vector2(360.0, 700.0))
	var radius_before := flight_piece.radius
	flight_piece.velocity = Vector2(0.0, -GameConfig.LAUNCH_SPEED)
	SimulationType.new().step([flight_piece], 1.0 / 60.0, MergeType.new())
	_assert(is_equal_approx(flight_piece.radius, radius_before), "Flight and settling must never resize a physics body")
