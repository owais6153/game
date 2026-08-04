extends SceneTree

## Development-only visual proof for the target-only reward correction. The
## production controller is used directly; no capture-only gameplay behavior is
## injected into runtime scripts.
const GameScene = preload("res://scenes/Game.tscn")
const GemPieceType = preload("res://scripts/gem_piece.gd")
const OUTPUT_DIR := "res://reports/reference-target-reward-correction-v3/final-screenshots/"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var fixture := await _new_fixture(Vector2i(720, 1600))
	var controller = fixture.controller
	controller.queue_redraw()
	await _settle()
	await _capture(fixture.viewport, "01-ready-without-push-guide.png")

	var ordinary := _piece(9951, 6, Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 430.0))
	controller.pieces.append(ordinary)
	var ordinary_events: Array[Dictionary] = [_event_for(ordinary)]
	controller._apply_confirmed_merge_events(ordinary_events)
	controller._sync_gems_and_mark_visibility()
	controller._update_merge_presentations(0.24)
	controller.effects_layer.update_effects(0.24)
	controller._refresh_hud()
	_check(controller.coins == 0, "Ordinary L6 merge changed target-only coins")
	_check(controller.effects_layer.active_coin_count() == 0, "Ordinary L6 merge created coin records")
	await _settle()
	await _capture(fixture.viewport, "02-ordinary-merge-without-coins.png")

	controller.restart()
	controller.set_process(false)
	var target := _piece(9952, 5, Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 430.0))
	controller.pieces.append(target)
	var target_events: Array[Dictionary] = [_event_for(target)]
	controller._apply_confirmed_merge_events(target_events)
	controller._sync_gems_and_mark_visibility()
	controller._update_merge_presentations(0.18)
	controller.effects_layer.update_effects(0.18)
	controller._refresh_hud()
	_check(controller.coins == GameConfig.target_coin_reward_for_result_level(5), "Active L5 target did not award its exact coins")
	_check(controller.effects_layer.active_coin_count() == 4, "Active L5 target did not create exactly four coins")
	await _settle()
	await _capture(fixture.viewport, "03-target-achievement-four-coin-burst.png")

	controller.effects_layer.update_effects(1.08)
	await _settle()
	await _capture(fixture.viewport, "04-target-coins-in-foreground-flight.png")

	print("TARGET_ONLY_REWARD_PROOF | ordinary_total=0 ordinary_coin_records=0 target_total=%d target_coin_records=4 push_guide=false" % controller.coins)
	fixture.viewport.queue_free()
	await process_frame
	if failures.is_empty():
		print("REFERENCE_TARGET_REWARD_CORRECTION_V3_CAPTURE: PASS")
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
		"first_position": piece.position + Vector2(-42.0, 0.0),
		"second_position": piece.position + Vector2(42.0, 0.0),
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
	await RenderingServer.frame_post_draw


func _capture(viewport: SubViewport, filename: String) -> void:
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var error := image.save_png(OUTPUT_DIR + filename)
	if error != OK:
		failures.append("Unable to save %s (error %d)" % [filename, error])
