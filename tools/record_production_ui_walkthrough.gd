extends SceneTree

## Development-only deterministic recording driver used for the milestone's
## end-to-end UI animation review. It does not join the runtime scene or export.
const GameScene = preload("res://scenes/Game.tscn")
const GemPieceType = preload("res://scripts/gem_piece.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var controller = GameScene.instantiate()
	root.add_child(controller)
	await process_frame
	controller.set_process(false)
	controller._refresh_hud()
	await _hold(1.0)

	controller.score = 9999
	controller._refresh_hud()
	await _hold(0.75)
	controller.score = 12550000
	controller._refresh_hud()
	await _hold(0.75)

	controller.gameplay_ui._on_settings_button_down()
	await _hold(0.09)
	controller.gameplay_ui._on_settings_button_up()
	controller._on_settings_requested()
	await _hold(1.45)
	controller._on_resume_requested()
	await _hold(0.35)

	controller.restart()
	controller.set_process(false)
	_begin_target(controller, 7, 9701)
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION * 0.50)
	controller._refresh_hud()
	await _hold(0.65)
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION * 0.52)
	controller._refresh_hud()
	await _hold(0.75)

	controller.score = 4720
	controller._refresh_hud()
	_begin_target(controller, 8, 9702)
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION * 0.54)
	controller._refresh_hud()
	await _hold(0.65)
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION * 0.48)
	controller._update_win_presentation(GameConfig.WIN_PRESENTATION_HOLD + 0.01)
	controller._refresh_hud()
	await _hold(1.75)

	controller._on_restart_requested()
	controller.set_process(false)
	await _hold(0.65)
	controller.score = 4720
	controller.failed = true
	controller.result_overlay.present(false, controller.score)
	await _hold(1.75)
	controller.result_overlay.dismiss()
	await _hold(0.35)
	print("PRODUCTION_UI_WALKTHROUGH_RECORDING: PASS")
	quit(0)


func _begin_target(controller, level: int, result_id: int) -> void:
	var result := GemPieceType.new(result_id, level, Vector2(360.0, GameConfig.board_top() + 390.0), GameConfig.gem_collision_radius(level))
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
	controller._update_merge_presentations(GameConfig.MERGE_PRESENTATION_DURATION + 0.01)
	controller.effects_layer.update_effects(GameConfig.MERGE_PRESENTATION_DURATION + 0.01)
	controller._refresh_hud()
	controller.queue_redraw()


func _hold(duration: float) -> void:
	await create_timer(duration, true, false, true).timeout
