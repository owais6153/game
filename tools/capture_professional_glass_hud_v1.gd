extends SceneTree

## Deterministic, development-only visual evidence for Professional Glass HUD
## v1. This script never joins the exported project or changes runtime rules.
const GameScene = preload("res://scenes/Game.tscn")
const GemPieceType = preload("res://scripts/gem_piece.gd")
const UiDesignSystemType = preload("res://scripts/ui_design_system.gd")
const OUTPUT_DIR := "res://reports/professional-glass-hud-v1/"
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
		await _capture_resolution(resolution)
	await _capture_detail_states()
	paused = false
	print("PROFESSIONAL_GLASS_HUD_V1_CAPTURE: PASS")
	quit(0)


func _capture_resolution(resolution: Vector2i) -> void:
	var fixture := await _new_fixture(resolution)
	var controller = fixture.controller
	var directory := "responsive/%dx%d" % [resolution.x, resolution.y]
	await _settle()
	await _capture(fixture, "%s/normal-gameplay.png" % directory)
	controller._on_settings_requested()
	await _settle()
	await _capture(fixture, "%s/pause-popup.png" % directory)
	controller._on_resume_requested()
	await _settle(UiDesignSystemType.POPUP_EXIT_DURATION + 0.03)
	if resolution == Vector2i(1080, 2400):
		controller.gameplay_ui.set_safe_insets_for_testing(Vector4(0.0, 96.0, 0.0, 56.0))
		controller._refresh_hud()
		await _settle(0.05)
		await _capture(fixture, "%s/notch-safe-area.png" % directory)
	await _dispose(fixture)


func _capture_detail_states() -> void:
	var fixture := await _new_fixture(Vector2i(576, 1312))
	var controller = fixture.controller
	var base_snapshot: Dictionary = controller.hud_snapshot()

	base_snapshot.coins = 9223372036854775807
	base_snapshot.score = 9223372036854775807
	base_snapshot.target_level = 8
	base_snapshot.target_progress = 2
	base_snapshot.target_quantity = 3
	base_snapshot.target_index = 1
	base_snapshot.target_total = 3
	controller.gameplay_ui.update_snapshot(base_snapshot)
	await _settle(0.05)
	await _capture(fixture, "states/large-coins-active-target.png")

	var next_target_snapshot := base_snapshot.duplicate(true)
	next_target_snapshot.target_level = 7
	next_target_snapshot.target_progress = 0
	next_target_snapshot.target_quantity = 2
	next_target_snapshot.target_index = 2
	controller.gameplay_ui.update_snapshot(next_target_snapshot)
	await _settle(GameConfig.TARGET_SWAP_START_DELAY + 0.06)
	await _capture(fixture, "states/target-transition.png")

	controller.restart()
	controller.set_process(false)
	var target_tier: int = controller.active_target_tier()
	_begin_target(controller, target_tier, 9701)
	controller.effects_layer.update_effects(GameConfig.COIN_BURST_DURATION + GameConfig.MAJOR_COIN_FLIGHT_DURATION * 0.42)
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION * 0.56)
	controller._sync_gems_and_mark_visibility()
	controller._refresh_hud()
	controller.queue_redraw()
	await _settle(0.05)
	await _capture(fixture, "states/coin-flight-and-target-collection.png")

	controller.restart()
	controller.set_process(false)
	controller.pieces.clear()
	controller.active_piece_id = -1
	for index in range(24):
		var column := index % 5
		var row := index / 5
		var tier := index % 8 + 1
		controller.pieces.append(_piece(9800 + index, tier, Vector2(176.0 + column * 92.0, GameConfig.board_top() + 255.0 + row * 82.0)))
	controller.gem_sprite_layer.sync_gems(controller.pieces)
	controller._refresh_hud()
	controller.queue_redraw()
	await _settle(0.05)
	await _capture(fixture, "states/crowded-board.png")

	controller.pieces.clear()
	var warning_y := GameConfig.danger_line_y() - GameConfig.gem_collision_radius(3) - 12.0
	controller.pieces.append(_piece(9901, 3, Vector2(GameConfig.table_center_x(), warning_y)))
	var launcher := _piece(9902, 2, Vector2(GameConfig.table_center_x(), GameConfig.launch_y()))
	launcher.is_active_launcher = true
	controller.pieces.append(launcher)
	controller.active_piece_id = launcher.id
	controller.launcher_state = controller.LauncherState.READY_TO_AIM
	controller.gem_sprite_layer.sync_gems(controller.pieces)
	controller.queue_redraw()
	await _settle(0.05)
	await _capture(fixture, "states/aim-guide-danger-warning.png")
	await _dispose(fixture)


func _new_fixture(physical_resolution: Vector2i) -> Dictionary:
	paused = false
	var virtual_height := int(round(float(physical_resolution.y) * 720.0 / float(physical_resolution.x)))
	var viewport := SubViewport.new()
	viewport.name = "PurpleHudCapture_%dx%d" % [physical_resolution.x, physical_resolution.y]
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
	controller.queue_redraw()
	return {"viewport": viewport, "controller": controller, "physical_resolution": physical_resolution}


func _dispose(fixture: Dictionary) -> void:
	paused = false
	var viewport: SubViewport = fixture.viewport
	if is_instance_valid(viewport):
		viewport.queue_free()
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
	controller._update_merge_presentations(GameConfig.MERGE_PRESENTATION_DURATION + 0.01)
	controller._refresh_hud()
	controller.queue_redraw()


func _settle(duration: float = UiDesignSystemType.POPUP_ENTER_DURATION + 0.04) -> void:
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
		push_error("Unable to save purple HUD evidence %s (error %d)" % [destination, error])

