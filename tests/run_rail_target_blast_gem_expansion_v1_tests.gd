extends SceneTree

const AssetCatalogType = preload("res://scripts/core/asset_catalog.gd")
const ControllerType = preload("res://scripts/gameplay/game_controller.gd")
const MergeServiceType = preload("res://scripts/gameplay/merge_service.gd")
const PieceType = preload("res://scripts/core/gem_piece.gd")
const SimulationType = preload("res://scripts/gameplay/board_simulation.gd")

var failures: Array[String] = []


func _init() -> void:
	_test_new_gem_derivatives()
	_test_measured_rail_geometry_and_containment()
	_test_contact_telemetry_requires_physical_contact()
	_test_enlarged_target_contract()
	_test_target_blast_is_bounded_and_one_shot()
	_test_dense_wave_and_music_contract()
	if failures.is_empty():
		print("RAIL_TARGET_BLAST_GEM_EXPANSION_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("RAIL_TARGET_BLAST_GEM_EXPANSION_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


func _piece(id: int, level: int, position: Vector2, velocity := Vector2.ZERO) -> GemPiece:
	var piece := PieceType.new(id, level, position, GameConfig.gem_collision_radius(level))
	piece.velocity = velocity
	return piece


func _test_new_gem_derivatives() -> void:
	_assert(AssetCatalogType.GEM_IDENTITY_COUNT == 34, "The catalog must expose all 34 supplied identities")
	for identity in [33, 34]:
		var definition := AssetCatalogType.gem_definition(identity)
		_assert(String(definition.get("color_family", "")) == "pink" and String(definition.get("color_style", "")) == "gradient", "Gem %d metadata must match its inspected artwork" % identity)
		_assert(String(definition.get("rarity", "")) == "unique", "Gem %d must participate in the limited Unique pool" % identity)
		var texture: Texture2D = AssetCatalogType.GEM_TIER_TEXTURES.get(identity)
		_assert(texture != null, "Gem %d runtime derivative must preload" % identity)
		if texture == null:
			continue
		var image := texture.get_image()
		_assert(image != null and image.get_used_rect() == Rect2i(Vector2i.ZERO, image.get_size()), "Gem %d must be cropped to its exact alpha bounds" % identity)
		_assert(maxi(image.get_width(), image.get_height()) == 256, "Gem %d longest edge must be 256 px" % identity)
	_assert(String(AssetCatalogType.gem_entry(1).get("name", "x")).is_empty(), "Gem names must remain absent from player-facing data")


func _test_measured_rail_geometry_and_containment() -> void:
	_assert(GameConfig.BOARD_TOP == 454.0 and GameConfig.BOARD_BOTTOM == 1168.0, "Vertical colliders must use the measured shared opening")
	_assert(GameConfig.TABLE_INNER_LEFT_TOP == 140.0 and GameConfig.TABLE_INNER_RIGHT_TOP == 580.0, "Back rail colliders must use the measured inner lip")
	_assert(GameConfig.TABLE_INNER_LEFT_BOTTOM == 58.0 and GameConfig.TABLE_INNER_RIGHT_BOTTOM == 662.0, "Front rail colliders must use the measured inner lip")
	var simulation := SimulationType.new()
	var merger := MergeServiceType.new()
	var objective_radius := GameConfig.gem_collision_radius(8)
	for y in [GameConfig.board_top() + objective_radius, 650.0, 850.0, 1050.0, GameConfig.board_bottom() - objective_radius]:
		var left_piece := _piece(100 + int(y), 8, Vector2(-100.0, y))
		var right_piece := _piece(200 + int(y), 8, Vector2(900.0, y))
		var row_pieces: Array[GemPiece] = [left_piece, right_piece]
		simulation.step(row_pieces, 0.0, merger)
		_assert(is_equal_approx(left_piece.position.x - left_piece.radius, GameConfig.table_left_at(y)), "Left L8 contact must land on the shared rail at y %.0f" % y)
		_assert(is_equal_approx(right_piece.position.x + right_piece.radius, GameConfig.table_right_at(y)), "Right L8 contact must land on the shared rail at y %.0f" % y)


func _test_contact_telemetry_requires_physical_contact() -> void:
	var simulation := SimulationType.new()
	var merger := MergeServiceType.new()
	var separated := _piece(1, 1, Vector2(300.0, 700.0), Vector2(80.0, 0.0))
	var other := _piece(2, 2, Vector2(500.0, 700.0))
	var separated_pieces: Array[GemPiece] = [separated, other]
	simulation.step(separated_pieces, 1.0 / 60.0, merger)
	_assert(simulation.consume_collision_impacts().is_empty(), "Contact audio telemetry must not start before physical contact")
	var wall_piece := _piece(3, 1, Vector2(GameConfig.table_left_at(700.0) + 10.0, 700.0), Vector2(-300.0, 0.0))
	var wall_pieces: Array[GemPiece] = [wall_piece]
	simulation.step(wall_pieces, 1.0 / 30.0, merger)
	var impacts := simulation.consume_collision_impacts()
	_assert(impacts.size() == 1 and String(impacts[0].get("kind", "")) == "wall", "Rail audio telemetry must begin only from confirmed collider contact")


func _test_enlarged_target_contract() -> void:
	_assert(GameConfig.gem_collision_radius(6) == 56.0 and GameConfig.gem_collision_radius(7) == 61.0 and GameConfig.gem_collision_radius(8) == 66.0, "L6-L8 target bodies must use the enlarged physical ladder")
	_assert(GameConfig.TARGET_VISUAL_SCALE == 1.18, "Detached target collection art must receive the enlarged visual emphasis")


func _test_target_blast_is_bounded_and_one_shot() -> void:
	var controller := ControllerType.new()
	var result := _piece(10, 6, Vector2(360.0, 700.0))
	var near := _piece(11, 2, Vector2(460.0, 700.0))
	var outside := _piece(12, 2, Vector2(360.0 + GameConfig.TARGET_MERGE_BLAST_RADIUS + 1.0, 700.0))
	var launcher := _piece(13, 1, Vector2(360.0, 760.0))
	launcher.is_active_launcher = true
	controller.pieces = [result, near, outside, launcher]
	var pushed := controller._apply_target_merge_blast(result.position, result.id)
	_assert(pushed == 1 and near.velocity.x > 0.0 and near.velocity.length() <= GameConfig.TARGET_MERGE_BLAST_IMPULSE + 0.001, "One target blast must slightly push only nearby board gems away")
	_assert(result.velocity == Vector2.ZERO and outside.velocity == Vector2.ZERO and launcher.velocity == Vector2.ZERO, "Blast must exclude the result, distant gems, and active launcher")
	controller.free()


func _test_dense_wave_and_music_contract() -> void:
	_assert(int(GameConfig.MERGE_TIMELINE_TARGET.ring_layers) == 5 and int(GameConfig.MERGE_TIMELINE_FINAL_TARGET.ring_layers) == 5, "Every target wave must use five bounded rings")
	_assert(int(GameConfig.MERGE_TIMELINE_TARGET.ring_segments) == 52 and int(GameConfig.MERGE_TIMELINE_FINAL_TARGET.ring_segments) == 52, "Target circles must use the denser 52-segment contour")
	_assert(is_equal_approx(GameConfig.AUDIO_MUSIC_VOLUME, 0.07), "Music gain must be raised slightly from 0.06 to 0.07")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
