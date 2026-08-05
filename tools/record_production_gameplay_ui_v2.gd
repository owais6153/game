extends SceneTree

## Development-only deterministic walkthrough driver. Run with Godot's
## `--write-movie` option; it does not join the exported project.
const GameScene = preload("res://scenes/Game.tscn")
const GemPieceType = preload("res://scripts/gem_piece.gd")
const FPS := 30.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var controller = GameScene.instantiate()
	root.add_child(controller)
	await process_frame
	controller.set_process(false)
	controller._refresh_hud()
	await _hold(controller, 1.0)

	controller.coins = 125500
	controller._refresh_hud()
	await _hold(controller, 0.8)
	controller._on_settings_requested()
	await _hold(controller, 1.2)
	controller._on_resume_requested()
	await _hold(controller, 0.35)

	controller.restart()
	controller.set_process(false)
	_begin_target(controller, controller.active_target_tier(), 9971)
	await _advance_feedback(controller, 2.55)

	controller.restart()
	controller.set_process(false)
	controller.pieces.clear()
	controller.active_piece_id = -1
	for index in range(22):
		var column := index % 5
		var row := index / 5
		controller.pieces.append(_piece(9980 + index, index % 8 + 1, Vector2(176.0 + column * 92.0, GameConfig.board_top() + 255.0 + row * 84.0)))
	controller.gem_sprite_layer.sync_gems(controller.pieces)
	controller.queue_redraw()
	await _hold(controller, 1.0)

	controller.pieces.clear()
	var warning := _piece(10020, 3, Vector2(GameConfig.table_center_x(), GameConfig.danger_line_y() - GameConfig.gem_collision_radius(3) - 10.0))
	var launcher := _piece(10021, 2, Vector2(GameConfig.table_center_x(), GameConfig.launch_y()))
	launcher.is_active_launcher = true
	controller.pieces.append(warning)
	controller.pieces.append(launcher)
	controller.active_piece_id = launcher.id
	controller.launcher_state = controller.LauncherState.READY_TO_AIM
	controller.gem_sprite_layer.sync_gems(controller.pieces)
	await _hold(controller, 1.0)

	controller._on_settings_requested()
	await _hold(controller, 1.0)
	paused = false
	controller.queue_free()
	await process_frame
	print("PRODUCTION_GAMEPLAY_UI_V2_RECORDING: PASS")
	quit(0)


func _hold(controller, duration: float) -> void:
	var frames := ceili(duration * FPS)
	for _index in range(frames):
		controller.queue_redraw()
		await process_frame


func _advance_feedback(controller, duration: float) -> void:
	var delta := 1.0 / FPS
	var frames := ceili(duration * FPS)
	for _index in range(frames):
		controller._update_merge_presentations(delta)
		controller.effects_layer.update_effects(delta)
		controller._update_target_collection(delta)
		controller._sync_gems_and_mark_visibility()
		controller._refresh_hud()
		controller.queue_redraw()
		await process_frame


func _piece(id: int, level: int, position: Vector2) -> GemPiece:
	return GemPieceType.new(id, level, position, GameConfig.gem_collision_radius(level))


func _begin_target(controller, level: int, result_id: int) -> void:
	var result := _piece(result_id, level, Vector2(360.0, GameConfig.board_top() + 390.0))
	controller.pieces.append(result)
	var events: Array[Dictionary] = [{
		"first_position": result.position + Vector2(-44.0, 0.0),
		"second_position": result.position + Vector2(44.0, 0.0),
		"midpoint": result.position,
		"level": level,
		"depth": 0,
		"result_id": result_id,
	}]
	controller._apply_confirmed_merge_events(events)
	controller._sync_gems_and_mark_visibility()
	controller._refresh_hud()
	controller.queue_redraw()
