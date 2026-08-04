extends SceneTree

## Development-only proof for continuous-audio presentation layering. Audio is
## covered by headless routing tests; these frames prove foreground order and
## the L5 -> L7 target handoff without changing controller state authority.
const GameScene = preload("res://scenes/Game.tscn")
const GemPieceType = preload("res://scripts/gem_piece.gd")
const OUTPUT_DIR := "res://reports/reference-audio-layering-v2/final-screenshots/"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var fixture := await _new_fixture(Vector2i(720, 1600))
	var controller = fixture.controller
	controller.queue_redraw()
	await _settle()
	await _capture(fixture.viewport, "01-danger-colored-ready-guide.png")

	controller.coins = 400
	controller._refresh_hud()
	var reward := _piece(9901, 6, Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 430.0))
	controller.pieces.append(reward)
	var reward_events: Array[Dictionary] = [_event_for(reward)]
	controller._apply_confirmed_merge_events(reward_events)
	controller._sync_gems_and_mark_visibility()
	controller._update_merge_presentations(0.36)
	controller.effects_layer.update_effects(1.06)
	await _settle()
	await _capture(fixture.viewport, "02-larger-coins-in-hud-foreground.png")

	controller.restart()
	controller.set_process(false)
	controller.coins = 400
	controller._refresh_hud()
	var target := _piece(9902, 5, Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 430.0))
	controller.pieces.append(target)
	var target_events: Array[Dictionary] = [_event_for(target)]
	controller._apply_confirmed_merge_events(target_events)
	controller._sync_gems_and_mark_visibility()
	controller._update_merge_presentations(GameConfig.MERGE_PRESENTATION_DURATION + 0.01)
	controller._sync_gems_and_mark_visibility()
	controller.effects_layer.clear()
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION * 0.58)
	await _settle()
	await _capture(fixture.viewport, "03-collected-gem-above-target-box.png")

	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION)
	controller._sync_gems_and_mark_visibility()
	controller._refresh_hud()
	await _settle(0.36)
	controller.gameplay_ui.target_reward_overlay.reset()
	await _settle(0.10)
	print("TARGET_HANDOFF_PROOF | outgoing_visible=%s outgoing_alpha=%.3f incoming_visible=%s incoming_alpha=%.3f outgoing_x=%.1f incoming_x=%.1f" % [controller.gameplay_ui.target_swap_outgoing.visible, controller.gameplay_ui.target_swap_outgoing.modulate.a, controller.gameplay_ui.target_swap_incoming.visible, controller.gameplay_ui.target_swap_incoming.modulate.a, controller.gameplay_ui.target_swap_outgoing.position.x, controller.gameplay_ui.target_swap_incoming.position.x])
	await _capture(fixture.viewport, "04-l5-out-l7-in-target-handoff.png")

	fixture.viewport.queue_free()
	await process_frame
	print("REFERENCE_AUDIO_LAYERING_V2_CAPTURE: PASS")
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
	# Use scaled game time so HUD tweens and the capture timer advance together
	# even when an unfocused Windows render window is throttled.
	await create_timer(duration, true, false, false).timeout
	await process_frame
	await RenderingServer.frame_post_draw


func _capture(viewport: SubViewport, filename: String) -> void:
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var error := image.save_png(OUTPUT_DIR + filename)
	if error != OK:
		push_error("Unable to save reference audio/layering evidence %s (error %d)" % [filename, error])
