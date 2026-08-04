extends SceneTree

## Development-only visual proof for the reference scale correction. It uses
## production scene APIs and is excluded from Android exports with tools/*.
const GameScene = preload("res://scenes/Game.tscn")
const GemPieceType = preload("res://scripts/gem_piece.gd")
const OUTPUT_DIR := "res://reports/reference-scale-contrast-v1/final-screenshots/"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var fixture := await _new_fixture(Vector2i(720, 1600))
	var controller = fixture.controller
	controller.pieces.clear()
	controller.active_piece_id = -1
	var positions := [
		Vector2(210.0, GameConfig.board_top() + 170.0),
		Vector2(310.0, GameConfig.board_top() + 170.0),
		Vector2(410.0, GameConfig.board_top() + 170.0),
		Vector2(510.0, GameConfig.board_top() + 170.0),
		Vector2(190.0, GameConfig.board_top() + 330.0),
		Vector2(300.0, GameConfig.board_top() + 330.0),
		Vector2(420.0, GameConfig.board_top() + 330.0),
		Vector2(540.0, GameConfig.board_top() + 330.0),
	]
	for level in range(1, 9):
		controller.pieces.append(_piece(9800 + level, level, positions[level - 1]))
	controller.gem_sprite_layer.sync_gems(controller.pieces)
	_check(is_equal_approx(GameConfig.gem_collision_radius(8) / GameConfig.gem_collision_radius(1), 1.7), "L8/L1 scale contrast is not 1.70")
	await _settle()
	await _capture(fixture.viewport, "01-l1-l8-board-scale-ladder.png")

	controller.restart()
	controller.set_process(false)
	var ordinary := _piece(9900, 5, Vector2(GameConfig.table_center_x() - 120.0, GameConfig.board_top() + 430.0))
	var target := _piece(9901, 5, Vector2(GameConfig.table_center_x() + 70.0, GameConfig.board_top() + 430.0))
	controller.pieces.append(ordinary)
	controller.pieces.append(target)
	var events: Array[Dictionary] = [_event_for(target)]
	controller._apply_confirmed_merge_events(events)
	controller._sync_gems_and_mark_visibility()
	controller._update_merge_presentations(GameConfig.MERGE_PRESENTATION_DURATION + 0.01)
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION * 0.16)
	controller.effects_layer.update_effects(GameConfig.TARGET_COLLECTION_DURATION * 0.16)
	var proxy: Sprite2D = controller.target_collection.get("sprite")
	var base_scale: Vector2 = controller.target_collection.get("base_scale", Vector2.ONE)
	_check(proxy != null and absf(proxy.scale.x / base_scale.x - GameConfig.TARGET_COLLECTION_POP_SCALE) <= 0.01, "Target proxy did not reach its enlarged collection beat")
	_check(not controller.pieces.any(func(piece: GemPiece): return piece.id == target.id), "Target physics body remained during collection")
	await _settle()
	await _capture(fixture.viewport, "02-normal-l5-vs-target-reward-pop.png")

	print("REFERENCE_SCALE_CONTRAST_V1_PROOF | radii=30/33/36/39/42/45/48/51 ratio=1.70 target_pop=%.2f" % GameConfig.TARGET_COLLECTION_POP_SCALE)
	fixture.viewport.queue_free()
	await process_frame
	if failures.is_empty():
		print("REFERENCE_SCALE_CONTRAST_V1_CAPTURE: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _new_fixture(resolution: Vector2i) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.size = resolution
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	var controller = GameScene.instantiate()
	viewport.add_child(controller)
	await process_frame
	await process_frame
	controller.set_process(false)
	controller._refresh_hud()
	return {"viewport": viewport, "controller": controller}


func _piece(id: int, level: int, position: Vector2) -> GemPiece:
	return GemPieceType.new(id, level, position, GameConfig.gem_collision_radius(level))


func _event_for(piece: GemPiece) -> Dictionary:
	return {
		"first_position": piece.position + Vector2(-piece.radius, 0.0),
		"second_position": piece.position + Vector2(piece.radius, 0.0),
		"midpoint": piece.position,
		"level": piece.level,
		"depth": 0,
		"result_id": piece.id,
	}


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _settle(duration: float = 0.05) -> void:
	await create_timer(duration, true, false, false).timeout
	await process_frame
	RenderingServer.force_draw(false)


func _capture(viewport: SubViewport, filename: String) -> void:
	RenderingServer.force_draw(false)
	var image := viewport.get_texture().get_image()
	var error := image.save_png(OUTPUT_DIR + filename)
	if error != OK:
		failures.append("Unable to save %s (error %d)" % [filename, error])
