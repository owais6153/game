extends SceneTree

## Development-only deterministic screenshot evidence at the exact physical
## resolutions requested for the production UI milestone. Gameplay renders in
## the project's fixed 720-wide design canvas, then the capture is sampled at
## the target device pixel size, matching canvas_items/expand behavior.
const GameScene = preload("res://scenes/Game.tscn")
const GemPieceType = preload("res://scripts/gem_piece.gd")
const UiDesignSystemType = preload("res://scripts/ui_design_system.gd")
const OUTPUT_DIR := "res://reports/production-ui-finalization-v1/final-screenshots/"
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(576, 1312),
	Vector2i(720, 1600),
	Vector2i(1080, 1920),
	Vector2i(1080, 2340),
	Vector2i(1080, 2400),
	Vector2i(540, 1320),
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for resolution in RESOLUTIONS:
		await _capture_responsive_set(resolution)
	await _capture_detailed_video_resolution_set()
	paused = false
	print("PRODUCTION_UI_FINALIZATION_CAPTURE: PASS")
	quit(0)


func _capture_responsive_set(resolution: Vector2i) -> void:
	var fixture := await _new_fixture(resolution)
	var controller = fixture.controller
	var directory := "%dx%d" % [resolution.x, resolution.y]
	await _settle_ui()
	await _capture(fixture, "%s/gameplay-empty-score-0.png" % directory)

	controller._on_settings_requested()
	await _settle_ui()
	await _capture(fixture, "%s/pause-popup.png" % directory)
	controller._on_restart_requested()
	controller.set_process(false)
	await _settle_ui(0.05)

	controller.score = 4720
	controller.result_overlay.present(true, controller.score)
	await _settle_ui()
	await _capture(fixture, "%s/win-popup.png" % directory)
	controller.result_overlay.dismiss()
	controller.failed = true
	controller.result_overlay.present(false, controller.score)
	await _settle_ui()
	await _capture(fixture, "%s/fail-popup.png" % directory)

	if resolution == Vector2i(1080, 2400):
		controller.result_overlay.dismiss()
		controller.failed = false
		controller.gameplay_ui.set_safe_insets_for_testing(Vector4(0.0, 72.0, 0.0, 48.0))
		controller.result_overlay.set_safe_insets_for_testing(Vector4(0.0, 72.0, 0.0, 48.0))
		controller._refresh_hud()
		await _settle_ui(0.05)
		await _capture(fixture, "%s/notch-safe-area.png" % directory)
	await _dispose_fixture(fixture)


func _capture_detailed_video_resolution_set() -> void:
	var resolution := Vector2i(576, 1312)
	var fixture := await _new_fixture(resolution)
	var controller = fixture.controller
	var directory := "576x1312/details"

	controller.score = 9999
	controller._refresh_hud()
	await _settle_ui()
	await _capture(fixture, "%s/score-9999.png" % directory)
	controller.score = 125500
	controller._refresh_hud()
	await _settle_ui()
	await _capture(fixture, "%s/score-125-5k.png" % directory)
	controller.score = 12500000
	controller._refresh_hud()
	await _settle_ui()
	await _capture(fixture, "%s/score-12-5m.png" % directory)

	controller.restart()
	controller.set_process(false)
	controller.target_index = 1
	controller._refresh_hud()
	await _settle_ui()
	await _capture(fixture, "%s/second-target.png" % directory)

	controller.gameplay_ui._on_settings_button_down()
	await _settle_ui(UiDesignSystemType.BUTTON_PRESS_DURATION + 0.02)
	await _capture(fixture, "%s/settings-pressed-state.png" % directory)
	controller.gameplay_ui._on_settings_button_up()
	await _settle_ui(UiDesignSystemType.BUTTON_RELEASE_DURATION + 0.02)

	controller.restart()
	controller.set_process(false)
	controller.pieces.clear()
	controller.active_piece_id = -1
	for index in range(20):
		var column := index % 5
		var row := index / 5
		var level := index % 6 + 1
		controller.pieces.append(_piece(9000 + index, level, Vector2(176.0 + column * 92.0, GameConfig.board_top() + 300.0 + row * 92.0)))
	controller.gem_sprite_layer.sync_gems(controller.pieces)
	controller._refresh_hud()
	controller.queue_redraw()
	await _settle_ui(0.05)
	await _capture(fixture, "%s/crowded-board.png" % directory)

	controller.restart()
	controller.set_process(false)
	_begin_target(controller, 7, 7100)
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION * 0.54)
	controller._sync_gems_and_mark_visibility()
	controller._refresh_hud()
	controller.queue_redraw()
	await _settle_ui(0.05)
	await _capture(fixture, "%s/target-collection-arrival.png" % directory)

	controller.restart()
	controller.set_process(false)
	controller._refresh_hud()
	await _settle_ui(0.05)
	await _capture(fixture, "%s/restart-state.png" % directory)
	await _dispose_fixture(fixture)


func _new_fixture(physical_resolution: Vector2i) -> Dictionary:
	paused = false
	var virtual_height := int(round(float(physical_resolution.y) * 720.0 / float(physical_resolution.x)))
	var viewport := SubViewport.new()
	viewport.name = "CaptureViewport_%dx%d" % [physical_resolution.x, physical_resolution.y]
	viewport.size = Vector2i(720, virtual_height)
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
	return {"viewport": viewport, "controller": controller, "physical_resolution": physical_resolution}


func _dispose_fixture(fixture: Dictionary) -> void:
	paused = false
	var viewport: SubViewport = fixture.viewport
	if is_instance_valid(viewport):
		viewport.queue_free()
	await process_frame


func _piece(id: int, level: int, position: Vector2) -> GemPiece:
	return GemPieceType.new(id, level, position, GameConfig.gem_collision_radius(level))


func _begin_target(controller, level: int, result_id: int) -> void:
	var result: GemPiece = _piece(result_id, level, Vector2(360.0, GameConfig.board_top() + 390.0))
	controller.pieces.append(result)
	var events: Array[Dictionary] = [{
		"first_position": result.position + Vector2(-44.0, 0.0),
		"second_position": result.position + Vector2(44.0, 0.0),
		"midpoint": result.position,
		"level": level,
		"depth": 0,
		"result_id": result_id,
		"score_delta": 640 if level == 7 else 1280,
	}]
	controller._apply_confirmed_merge_events(events)
	controller._sync_gems_and_mark_visibility()
	controller._update_merge_presentations(GameConfig.MERGE_PRESENTATION_DURATION + 0.01)
	controller.effects_layer.update_effects(GameConfig.MERGE_PRESENTATION_DURATION + 0.01)
	controller._refresh_hud()
	controller.queue_redraw()


func _settle_ui(duration: float = UiDesignSystemType.POPUP_ENTER_DURATION + 0.04) -> void:
	await create_timer(duration, true, false, true).timeout
	await process_frame
	await RenderingServer.frame_post_draw


func _capture(fixture: Dictionary, relative_path: String) -> void:
	var destination := OUTPUT_DIR + relative_path
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination.get_base_dir()))
	var viewport: SubViewport = fixture.viewport
	var physical_resolution: Vector2i = fixture.physical_resolution
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	if image.get_size() != physical_resolution:
		image.resize(physical_resolution.x, physical_resolution.y, Image.INTERPOLATE_LANCZOS)
	var error := image.save_png(destination)
	if error != OK:
		push_error("Unable to save production UI evidence %s (error %d)" % [destination, error])
