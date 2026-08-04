extends SceneTree

## Development-only frame proof for the reference animation/audio polish.
## Production controller APIs drive every frame; this tool adds no runtime
## behavior and is excluded from Android exports with the existing tools rule.
const GameScene = preload("res://scenes/Game.tscn")
const GemPieceType = preload("res://scripts/gem_piece.gd")
const OUTPUT_DIR := "res://reports/reference-animation-audio-polish-v4/final-screenshots/"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var fixture := await _new_fixture(Vector2i(720, 1600))
	var controller = fixture.controller

	var ordinary := _piece(9961, 4, Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 430.0))
	controller.pieces.append(ordinary)
	var ordinary_events: Array[Dictionary] = [_event_for(ordinary)]
	controller._apply_confirmed_merge_events(ordinary_events)
	controller._sync_gems_and_mark_visibility()
	controller._update_merge_presentations(0.10)
	controller.effects_layer.update_effects(0.10)
	_check(controller.effects_layer.active_coin_count() == 0, "Ordinary merge created coin records")
	_check(controller.effects_layer.merge_impacts[0].has("splash_duration"), "Ordinary merge has no reference splash record")
	await _settle()
	await _capture(fixture.viewport, "01-ordinary-merge-color-splash.png")

	controller.restart()
	controller.set_process(false)
	var target := _piece(9962, 5, Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 430.0))
	controller.pieces.append(target)
	var target_events: Array[Dictionary] = [_event_for(target)]
	controller._apply_confirmed_merge_events(target_events)
	controller._sync_gems_and_mark_visibility()
	controller._update_merge_presentations(0.16)
	controller.effects_layer.update_effects(0.16)
	controller._refresh_hud()
	_check(controller.effects_layer.active_coin_count() == 4, "Target reward did not create exactly four coins")
	_check(controller.audio_feedback.emitted_events.count("coin_reward") == 1, "Target reward did not route one supplied coin cue")
	await _settle()
	await _capture(fixture.viewport, "02-target-merge-four-coin-pop.png")

	controller._update_merge_presentations(0.20)
	controller._update_target_collection(0.24)
	controller.effects_layer.update_effects(0.55)
	await _settle()
	await _capture(fixture.viewport, "03-coins-and-target-foreground-flight.png")

	controller._update_target_collection(0.40)
	controller.effects_layer.update_effects(0.40)
	controller._refresh_hud()
	_check(controller.gameplay_ui.target_reward_overlay.is_reward_active(), "Completed target has no visible success check")
	_check(controller.gameplay_ui.target_swap_outgoing.position.distance_to(controller.gameplay_ui.target_swap_incoming.position) < 0.1, "Target handoff is not centered")
	await _settle()
	await _capture(fixture.viewport, "04-completed-target-check-hold.png")

	await _settle(GameConfig.TARGET_SWAP_START_DELAY + 0.10)
	await _capture(fixture.viewport, "05-completed-target-fade-out.png")
	await _settle(GameConfig.TARGET_SWAP_OUTGOING_FADE_DURATION + GameConfig.TARGET_SWAP_GAP_DURATION + GameConfig.TARGET_SWAP_INCOMING_FADE_DURATION * 0.55)
	await _capture(fixture.viewport, "06-next-target-fade-in.png")

	print("REFERENCE_ANIMATION_AUDIO_POLISH_V4_PROOF | merge=quick_splash coins=4 target_check=held target_swap=centered_fade music_gain=%.2f coin_audio_events=%d" % [controller.audio_feedback.music_volume_linear(), controller.audio_feedback.emitted_events.count("coin_reward")])
	fixture.viewport.queue_free()
	await process_frame
	if failures.is_empty():
		print("REFERENCE_ANIMATION_AUDIO_POLISH_V4_CAPTURE: PASS")
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
