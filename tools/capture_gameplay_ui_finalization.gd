extends SceneTree

## Development-only deterministic evidence capture. It has no scene, autoload,
## export UI, or production input reference.
const GameScene = preload("res://scenes/Game.tscn")
const GemPieceType = preload("res://scripts/gem_piece.gd")
const OUTPUT_DIR := "res://reports/gameplay-ui-feel-finalization-v1/"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var controller = GameScene.instantiate()
	root.add_child(controller)
	await process_frame
	controller.set_process(false)
	controller._refresh_hud()
	await _capture("final-hud.png")

	controller.score = 125500
	controller._refresh_hud()
	await _capture("large-score.png")

	controller._on_settings_requested()
	await _capture("settings-popup.png")
	controller._on_resume_requested()

	controller.restart()
	controller.set_process(false)
	var merge_result: GemPiece = _piece(7001, 2, Vector2(360.0, GameConfig.board_top() + 330.0))
	controller.pieces.append(merge_result)
	var merge_events: Array[Dictionary] = [{"first_position": merge_result.position + Vector2(-45.0, 0.0), "second_position": merge_result.position + Vector2(45.0, 0.0), "midpoint": merge_result.position, "level": 2, "depth": 0, "result_id": merge_result.id, "score_delta": 10}]
	controller._apply_confirmed_merge_events(merge_events)
	controller._sync_gems_and_mark_visibility()
	controller._update_merge_presentations(0.07)
	controller.effects_layer.update_effects(0.07)
	controller._sync_gems_and_mark_visibility()
	controller._refresh_hud()
	controller.queue_redraw()
	await _capture("merge-impact.png")

	controller.restart()
	controller.set_process(false)
	_begin_target(controller, 7, 7100)
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION * 0.52)
	controller._sync_gems_and_mark_visibility()
	controller._refresh_hud()
	controller.queue_redraw()
	await _capture("target-collection-mid-flight.png")
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION * 0.26)
	controller._sync_gems_and_mark_visibility()
	controller._refresh_hud()
	controller.queue_redraw()
	await _capture("target-collection-late-fade.png")

	controller.restart()
	controller.set_process(false)
	controller.target_index = 1
	_begin_target(controller, 8, 7200)
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION * 0.58)
	controller._sync_gems_and_mark_visibility()
	controller._refresh_hud()
	controller.queue_redraw()
	await _capture("final-target-before-win.png")
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION * 0.42)
	controller._update_win_presentation(GameConfig.WIN_PRESENTATION_HOLD + 0.01)
	controller._refresh_hud()
	await _capture("win-overlay.png")

	controller.restart()
	controller.set_process(false)
	controller.pieces.clear()
	controller.active_piece_id = -1
	for index in range(20):
		var column := index % 5
		var row := index / 5
		var level := (index % 6) + 1
		controller.pieces.append(_piece(8000 + index, level, Vector2(176.0 + column * 92.0, GameConfig.board_top() + 300.0 + row * 92.0)))
	controller.gem_sprite_layer.sync_gems(controller.pieces)
	controller._refresh_hud()
	controller.queue_redraw()
	await _capture("crowded-board.png")

	print("GAMEPLAY_UI_EVIDENCE_CAPTURE: PASS")
	quit(0)

func _piece(id: int, level: int, position: Vector2) -> GemPiece:
	return GemPieceType.new(id, level, position, GameConfig.gem_collision_radius(level))

func _begin_target(controller, level: int, result_id: int) -> void:
	var result: GemPiece = _piece(result_id, level, Vector2(360.0, GameConfig.board_top() + 390.0))
	controller.pieces.append(result)
	var events: Array[Dictionary] = [{"first_position": result.position + Vector2(-44.0, 0.0), "second_position": result.position + Vector2(44.0, 0.0), "midpoint": result.position, "level": level, "depth": 0, "result_id": result_id, "score_delta": 640 if level == 7 else 1280}]
	controller._apply_confirmed_merge_events(events)
	controller._sync_gems_and_mark_visibility()
	controller._update_merge_presentations(GameConfig.MERGE_PRESENTATION_DURATION + 0.01)
	controller.effects_layer.update_effects(GameConfig.MERGE_PRESENTATION_DURATION + 0.01)
	controller._refresh_hud()
	controller.queue_redraw()

func _capture(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(OUTPUT_DIR + filename)
	if error != OK:
		push_error("Unable to save evidence %s (error %d)" % [filename, error])
