extends SceneTree

## Development-only deterministic evidence for the final production-parity pass.
## It captures the edge-lane guide and three phases of a confirmed major merge.
const GameScene = preload("res://scenes/Game.tscn")
const GemPieceType = preload("res://scripts/gem_piece.gd")
const OUTPUT_DIR := "res://reports/production-gameplay-parity-final-v1/final-screenshots/"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var fixture := await _new_fixture(Vector2i(720, 1600))
	var controller = fixture.controller
	await _settle()
	var active: GemPiece = controller.get_active_piece()
	active.position.x = GameConfig.table_right_at(active.position.y) - active.radius
	controller._sync_gems_and_mark_visibility()
	controller.queue_redraw()
	await _settle(0.03)
	await _capture(fixture.viewport, "01-contained-edge-aim-guide.png")

	controller.coins = 400
	controller._refresh_hud()
	var result := _piece(9601, 6, Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 410.0))
	controller.pieces.append(result)
	var event: Dictionary = {
		"first_position": result.position + Vector2(-48.0, 0.0),
		"second_position": result.position + Vector2(48.0, 0.0),
		"midpoint": result.position,
		"level": 6,
		"depth": 0,
		"result_id": result.id,
	}
	var events: Array[Dictionary] = [event]
	controller._apply_confirmed_merge_events(events)
	controller._sync_gems_and_mark_visibility()
	controller._update_merge_presentations(0.16)
	controller.effects_layer.update_effects(0.16)
	controller.queue_redraw()
	await _settle(0.03)
	await _capture(fixture.viewport, "02-major-merge-coin-burst.png")

	controller._update_merge_presentations(0.52)
	controller.effects_layer.update_effects(1.02)
	controller._sync_gems_and_mark_visibility()
	controller.queue_redraw()
	await _settle(0.03)
	await _capture(fixture.viewport, "03-staggered-coins-to-hud.png")

	controller.effects_layer.update_effects(3.0)
	controller._refresh_hud()
	controller.queue_redraw()
	await _settle(GameConfig.COIN_COUNTER_PULSE_DURATION + 0.04)
	await _capture(fixture.viewport, "04-collected-coin-total.png")

	fixture.viewport.queue_free()
	await process_frame
	print("PRODUCTION_GAMEPLAY_PARITY_FINAL_CAPTURE: PASS")
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
	controller.queue_redraw()
	return {"viewport": viewport, "controller": controller}


func _piece(id: int, level: int, position: Vector2) -> GemPiece:
	return GemPieceType.new(id, level, position, GameConfig.gem_collision_radius(level))


func _settle(duration: float = 0.05) -> void:
	await create_timer(duration, true, false, true).timeout
	await process_frame
	await RenderingServer.frame_post_draw


func _capture(viewport: SubViewport, filename: String) -> void:
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var error := image.save_png(OUTPUT_DIR + filename)
	if error != OK:
		push_error("Unable to save gameplay parity evidence %s (error %d)" % [filename, error])
