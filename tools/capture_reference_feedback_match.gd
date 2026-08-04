extends SceneTree

## Development-only visual proof for the corrective reference-feedback pass.
const GameScene = preload("res://scenes/Game.tscn")
const GemPieceType = preload("res://scripts/gem_piece.gd")
const OUTPUT_DIR := "res://reports/reference-feedback-match-v1/final-screenshots/"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var fixture := await _new_fixture(Vector2i(720, 1600))
	var controller = fixture.controller
	controller.coins = 400
	controller._refresh_hud()

	var ordinary := _piece(9801, 6, Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 420.0))
	controller.pieces.append(ordinary)
	var ordinary_events: Array[Dictionary] = [_event_for(ordinary)]
	controller._apply_confirmed_merge_events(ordinary_events)
	controller._sync_gems_and_mark_visibility()
	controller._update_merge_presentations(0.14)
	controller.effects_layer.update_effects(0.14)
	await _settle()
	await _capture(fixture.viewport, "01-rigid-merge-four-coin-cluster.png")

	controller._update_merge_presentations(0.40)
	controller.effects_layer.update_effects(1.08)
	controller._sync_gems_and_mark_visibility()
	await _settle()
	await _capture(fixture.viewport, "02-four-coins-one-compact-flight.png")

	controller.restart()
	controller.set_process(false)
	controller.coins = 400
	controller._refresh_hud()
	var target := _piece(9802, 5, Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 420.0))
	controller.pieces.append(target)
	var target_events: Array[Dictionary] = [_event_for(target)]
	controller._apply_confirmed_merge_events(target_events)
	controller._sync_gems_and_mark_visibility()
	controller._update_merge_presentations(GameConfig.MERGE_PRESENTATION_DURATION + 0.01)
	controller.effects_layer.update_effects(GameConfig.MERGE_PRESENTATION_DURATION + GameConfig.TARGET_COLLECTION_DURATION)
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION + 0.01)
	controller.effects_layer.update_effects(0.12)
	controller._sync_gems_and_mark_visibility()
	controller._refresh_hud()
	await _settle()
	await _capture(fixture.viewport, "03-target-check-with-four-coins.png")

	controller.effects_layer.update_effects(3.0)
	controller._refresh_hud()
	await _settle(GameConfig.COIN_COUNTER_PULSE_DURATION + 0.05)
	await _capture(fixture.viewport, "04-exact-coin-settlement.png")

	fixture.viewport.queue_free()
	await process_frame
	print("REFERENCE_FEEDBACK_MATCH_CAPTURE: PASS")
	quit(0)


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
		"first_position": piece.position + Vector2(-42.0, 0.0),
		"second_position": piece.position + Vector2(42.0, 0.0),
		"midpoint": piece.position,
		"level": piece.level,
		"depth": 0,
		"result_id": piece.id,
	}


func _settle(duration: float = 0.05) -> void:
	await create_timer(duration, true, false, true).timeout
	await process_frame
	await RenderingServer.frame_post_draw


func _capture(viewport: SubViewport, filename: String) -> void:
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var error := image.save_png(OUTPUT_DIR + filename)
	if error != OK:
		push_error("Unable to save reference feedback evidence %s (error %d)" % [filename, error])
