extends SceneTree

## Focused presentation regression suite for the final gameplay UI/feel
## milestone. This runner exercises production scene APIs while keeping every
## assertion outside the runtime scene and simulation code.
const GameScene = preload("res://scenes/Game.tscn")
const GameplayHudLayerType = preload("res://scripts/gameplay_hud_layer.gd")
const GameplayEffectsLayerType = preload("res://scripts/gameplay_effects_layer.gd")
const ScoreFormatterType = preload("res://scripts/score_formatter.gd")
const AssetCatalogType = preload("res://scripts/asset_catalog.gd")
const GemPieceType = preload("res://scripts/gem_piece.gd")
const UiDesignSystemType = preload("res://scripts/ui_design_system.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var physics_before := _physics_signature()
	_test_score_formatter()
	await _test_control_hierarchy_and_contained_previews()
	await _test_pause_freeze_resume_and_restart_cleanup()
	await _test_duplicate_merge_is_exactly_once()
	await _test_late_collection_fade_and_body_cleanup()
	await _test_final_l8_event_order_and_single_overlay()
	await _test_responsive_hud_sizes()
	await _test_effect_counts_are_bounded()
	_assert(_physics_signature() == physics_before, "Focused presentation tests must not mutate table, rail, motion, contact, or collision constants")
	paused = false
	if failures.is_empty():
		print("GAMEPLAY_UI_FEEL_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _test_score_formatter() -> void:
	var cases := {
		0: "0",
		999: "999",
		1000: "1,000",
		9999: "9,999",
		10000: "10K",
		12500: "12.5K",
		125500: "125.5K",
		1000000: "1M",
		9876543210: "9.9B",
	}
	for raw_score in cases:
		_assert(ScoreFormatterType.format(int(raw_score)) == String(cases[raw_score]), "Score %s must format as %s, got %s" % [str(raw_score), cases[raw_score], ScoreFormatterType.format(int(raw_score))])
	# Formatting is a presentation operation; the exact integer remains intact.
	var exact_score := 9876543210
	ScoreFormatterType.format(exact_score)
	_assert(exact_score == 9876543210, "Score formatting must not replace or truncate the underlying integer")


func _test_control_hierarchy_and_contained_previews() -> void:
	var fixture := await _new_hud(Vector2i(720, 1600))
	var hud: GameplayHudLayer = fixture.hud
	hud.update_snapshot(_snapshot(125500, 2, 4, 7, 0, 1, false))
	await process_frame
	_assert(hud.root_control is Control and hud.hud_margin is MarginContainer, "Gameplay HUD must be a full Control tree rooted in a MarginContainer")
	_assert(hud.hud_margin.get_node("HudRows") is VBoxContainer, "Gameplay HUD rows must use a VBoxContainer")
	_assert(hud.hud_margin.get_node("HudRows/MainRow") is CenterContainer, "The merge path must own the enlarged centered top row")
	_assert(hud.hud_margin.get_node("HudRows/ScoreNextRow") is HBoxContainer, "Score and NEXT must use the responsive row below the merge path")
	_assert(hud.hud_margin.get_node("HudRows/ObjectiveRow") is HBoxContainer, "Level and Settings must use a responsive utility HBoxContainer")
	_assert(hud.target_panel.get_parent() == hud.target_anchor, "The active target must be independently anchored above the table")
	_assert(hud.target_panel.get_node("TargetContentSurface") is PanelContainer and hud.pause_panel is PanelContainer, "Target and Pause must share the simple native panel system")
	_assert(hud.next_icon.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "NEXT gem must use aspect-preserving contain scaling")
	_assert(hud.target_icon.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "Target gem must use aspect-preserving contain scaling")
	for icon in hud.progression_icons:
		_assert(icon.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "Every progression gem must use aspect-preserving contain scaling")
	_assert(hud.next_icon.texture == AssetCatalogType.gem_texture(4), "NEXT icon must match the authoritative next queue tier")
	_assert(hud.target_icon.texture == AssetCatalogType.gem_texture(7), "Target icon must match the one active target tier")
	hud.update_snapshot(_snapshot(125500, 2, 3, 8, 0, 1, false))
	_assert(hud.next_icon.texture == AssetCatalogType.gem_texture(3), "NEXT preview must replace stale queue artwork when identity changes")
	_assert(hud.target_icon.texture == AssetCatalogType.gem_texture(8), "Sequential target preview must replace stale target artwork when identity changes")
	_assert(hud.score_label.text == "125.5K", "HUD score must use the shared compact formatter")
	_assert(hud.score_label.get_combined_minimum_size().x <= hud.score_label.size.x + 1.0, "Formatted score text must fit its dynamic panel without clipping")
	var gameplay_buttons := _buttons_below(hud.hud_margin)
	_assert(gameplay_buttons.size() == 1 and gameplay_buttons[0] == hud.settings_button, "Normal gameplay HUD must expose only Settings, never Restart")
	_assert(hud.hud_margin.find_child("PauseRestartButton", true, false) == null, "Restart must exist only in the pause popup, not in the gameplay HUD")
	_assert(not hud.pause_blocker.visible and not hud.restart_button.is_visible_in_tree(), "Pause Restart must remain hidden during normal gameplay")
	await _dispose_viewport(fixture.viewport)


func _test_pause_freeze_resume_and_restart_cleanup() -> void:
	var controller = await _new_controller()
	var active = controller.get_active_piece()
	_assert(active != null, "Pause test must begin with one ready unlimited launcher")
	_assert(controller.gameplay_ui.settings_button.size.x >= 88.0 and controller.gameplay_ui.settings_button.size.y >= 88.0, "Settings must retain an Android-safe 88x88 design-pixel touch target")
	_assert(controller.gameplay_ui.settings_requested.get_connections().size() == 1, "Settings signal must connect exactly once")
	_assert(controller.gameplay_ui.resume_requested.get_connections().size() == 1, "Resume signal must connect exactly once")
	_assert(controller.gameplay_ui.restart_requested.get_connections().size() == 1, "Restart signal must connect exactly once")
	var frame_before := int(controller.process_frame_index)
	var position_before: Vector2 = active.position
	var velocity_before: Vector2 = active.velocity
	controller._on_settings_requested()
	_assert(paused and controller.gameplay_ui.is_pause_visible(), "Settings must pause gameplay and show the input-blocking popup")
	await process_frame
	await process_frame
	_assert(int(controller.process_frame_index) == frame_before, "Paused gameplay must not advance controller frames")
	_assert(active.position == position_before and active.velocity == velocity_before, "Paused gameplay must freeze simulation position and velocity")
	controller._on_resume_requested()
	_assert(not paused, "Resume must restore gameplay immediately while the lightweight popup exit animation finishes")
	await create_timer(UiDesignSystemType.POPUP_EXIT_DURATION + 0.03).timeout
	_assert(not controller.gameplay_ui.is_pause_visible(), "Resume must finish closing the popup after the shared exit duration")
	await process_frame
	_assert(int(controller.process_frame_index) > frame_before, "Controller processing must resume after Resume")

	# Seed every presentation/reset surface with stale state, then exercise the
	# production pause-popup Restart path.
	controller.score = 777
	controller.target_index = 1
	controller.target_progress = 1
	controller.danger_timers[8123] = 0.5
	controller.merge_presentations.append(_merge_event(8123, 7))
	controller.pending_target_presentations[8123] = true
	controller.effects_layer.begin_merge_feedback(_merge_event(8124, 2), 10)
	controller.result_overlay.present(false, controller.score)
	var ghost := Sprite2D.new()
	controller.effects_layer.add_child(ghost)
	controller.collection_in_progress = true
	controller.target_collection = {"result_id": 8125, "level": 7, "sprite": ghost, "start": Vector2(360.0, 720.0), "elapsed": 0.2}
	controller._on_settings_requested()
	controller._on_restart_requested()
	_assert(not paused and not controller.gameplay_ui.is_pause_visible(), "Pause-popup Restart must always leave the tree unpaused and popup closed")
	_assert(controller.score == 0 and controller.target_index == 0 and controller.target_progress == 0, "Restart must reset score and sequential-target state")
	_assert(controller.merge_presentations.is_empty() and controller.pending_target_presentations.is_empty(), "Restart must clear pending merge and target presentation gates")
	_assert(not controller.collection_in_progress and controller.target_collection.is_empty(), "Restart must cancel the target collection proxy")
	_assert(controller.effects_layer.active_effect_count() == 0 and not controller.result_overlay.visible_result, "Restart must clear reward effects and result overlay state")
	_assert(controller.danger_timers.is_empty(), "Restart must clear danger occupancy timers")
	_assert(controller.pieces.size() == 1 and controller.get_active_piece() != null and controller.lifecycle_name() == "READY_TO_AIM", "Restart must restore exactly one ready launcher without a finite counter")
	_assert(controller.gameplay_ui.score_label.text == "0", "Restart must refresh the HUD without a stale score")
	_assert(ghost.is_queued_for_deletion(), "Restart must queue any visual-only collection proxy for deletion")
	await process_frame
	_assert(not is_instance_valid(ghost), "Restart must leave no ghost collection node after the frame completes")
	await _dispose_controller(controller)


func _test_duplicate_merge_is_exactly_once() -> void:
	var controller = await _new_controller()
	var event := _merge_event(7001, 2)
	var duplicate_events: Array[Dictionary] = [event, event.duplicate(true)]
	controller._apply_confirmed_merge_events(duplicate_events)
	_assert(controller.score == GameConfig.merge_score_for_result_level(2), "Duplicate confirmed result ID must award score exactly once")
	_assert(controller.merge_presentations.size() == 1, "Duplicate confirmed result ID must create one merge presentation")
	_assert(controller.effects_layer.score_popups.size() == 1 and controller.effects_layer.merge_impacts.size() == 1, "Duplicate confirmed result ID must create one score popup and one impact")
	_assert(_count_name(controller.presentation_events_for_result(7001), "merge_confirmed") == 1, "Duplicate confirmed result ID must trace merge confirmation exactly once")
	var replay_events: Array[Dictionary] = [event.duplicate(true)]
	controller._apply_confirmed_merge_events(replay_events)
	_assert(controller.score == GameConfig.merge_score_for_result_level(2), "Replayed production event must not duplicate score")
	_assert(controller.merge_presentations.size() == 1 and controller.effects_layer.score_popups.size() == 1, "Replayed production event must not duplicate visuals")
	_assert(controller.processed_merge_result_ids.size() == 1, "Exactly-once guard must retain one processed merge result")
	await _dispose_controller(controller)


func _test_late_collection_fade_and_body_cleanup() -> void:
	var controller = await _new_controller()
	var result_id := 7101
	var result = _piece(result_id, 7, Vector2(360.0, 730.0))
	controller.pieces.append(result)
	controller.danger_timers[result_id] = 0.4
	var target_events: Array[Dictionary] = [_merge_event(result_id, 7)]
	controller._apply_confirmed_merge_events(target_events)
	# Passing the duration alone is insufficient: a target must first have one
	# synchronized visible frame.
	controller._update_merge_presentations(GameConfig.MERGE_PRESENTATION_DURATION + 0.01)
	_assert(not controller.collection_in_progress and controller.merge_presentations.size() == 1, "Target collection must wait for the result's first visible frame")
	controller._sync_gems_and_mark_visibility()
	controller._update_merge_presentations(0.0)
	_assert(controller.collection_in_progress, "Target collection must begin after visibility and merge presentation complete")
	_assert(result.consumed and not controller.pieces.any(func(piece): return piece.id == result_id), "Collected target must leave simulation occupancy before travel")
	_assert(not controller.danger_timers.has(result_id) and not controller.pending_target_presentations.has(result_id), "Collected target must leave danger and merge-registration state before travel")
	_assert(not controller.merge_service.has_pending_candidates(), "Collection cleanup must leave no merge candidate state")
	controller._sync_gems_and_mark_visibility()
	_assert(not controller.gem_sprite_layer._sprites.has(result_id), "Removed target body must have no live gameplay sprite after synchronization")
	var proxy: Sprite2D = controller.target_collection.sprite
	_assert(proxy != null and proxy.get_parent() == controller.effects_layer, "Collection travel must use a visual-only proxy in the effects layer")
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION * (GameConfig.TARGET_COLLECTION_FADE_START - 0.06))
	_assert(is_equal_approx(float(controller.target_collection.opacity), 1.0) and is_equal_approx(proxy.modulate.a, 1.0), "Collection gem must remain fully visible through the early travel path")
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION * 0.20)
	_assert(float(controller.target_collection.opacity) < 1.0 and float(controller.target_collection.opacity) > 0.15, "Collection fade must begin late and remain readable before arrival")
	_assert(not controller.pieces.any(func(piece): return piece.id == result_id), "Late fade must never restore an invisible physics body")
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION)
	_assert(not controller.collection_in_progress and controller.target_index == 1 and not controller.win_qualified, "First L7 arrival must activate only L8 after collection finishes")
	controller._refresh_hud()
	_assert(controller.gameplay_ui.target_icon.texture == AssetCatalogType.gem_texture(8), "HUD must switch from L7 to L8 only after collection completes")
	var expected: Array[String] = ["merge_confirmed", "result_created", "result_first_frame_visible", "merge_presentation_completed", "target_completed", "physics_body_removed", "collection_animation_started", "collection_animation_completed"]
	_assert(controller.presentation_events_for_result(result_id) == expected, "First target must preserve the exact visible-merge/cleanup/collection order")
	await process_frame
	_assert(not is_instance_valid(proxy), "Completed collection proxy must be freed")
	await _dispose_controller(controller)


func _test_final_l8_event_order_and_single_overlay() -> void:
	var controller = await _new_controller()
	_drive_target_to_arrival(controller, 7201, 7)
	_assert(controller.target_index == 1 and not controller.win_qualified, "L7 must advance to L8 without starting a result overlay")
	var result_id := 7202
	var final_result = _piece(result_id, 8, Vector2(360.0, 720.0))
	controller.pieces.append(final_result)
	var final_events: Array[Dictionary] = [_merge_event(result_id, 8)]
	controller._apply_confirmed_merge_events(final_events)
	controller._sync_gems_and_mark_visibility()
	controller._update_merge_presentations(GameConfig.MERGE_PRESENTATION_DURATION + 0.01)
	_assert(controller.collection_in_progress and not controller.win_qualified and not controller.result_overlay.visible_result, "Final win must not cover the L8 merge or collection travel")
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION + 0.01)
	var expected_before_overlay: Array[String] = ["merge_confirmed", "result_created", "result_first_frame_visible", "merge_presentation_completed", "target_completed", "physics_body_removed", "collection_animation_started", "collection_animation_completed", "final_target_confirmed"]
	_assert(controller.presentation_events_for_result(result_id) == expected_before_overlay, "Final L8 must preserve the exact pre-overlay event order")
	_assert(controller.win_qualified and not controller.win_presented and controller.result_overlay.present_count == 0, "Final collection must qualify victory but retain its celebration hold")
	controller._update_win_presentation(GameConfig.WIN_PRESENTATION_HOLD - 0.01)
	_assert(not controller.win_presented, "Win overlay must not start before the post-collection hold completes")
	controller._update_win_presentation(0.02)
	controller._update_win_presentation(GameConfig.WIN_PRESENTATION_HOLD + 1.0)
	controller._update_win_presentation(GameConfig.WIN_PRESENTATION_HOLD + 1.0)
	var expected_complete := expected_before_overlay.duplicate()
	expected_complete.append("win_overlay_started")
	_assert(controller.presentation_events_for_result(result_id) == expected_complete, "Win overlay start must be the sole event after final target confirmation")
	_assert(controller.win_presented and controller.result_overlay.visible_result and controller.result_overlay.present_count == 1, "Final win overlay must present exactly once")
	_assert(_count_name(controller.presentation_events_for_result(result_id), "win_overlay_started") == 1, "Final win trace must contain one overlay start")
	await _dispose_controller(controller)


func _test_responsive_hud_sizes() -> void:
	var sizes: Array[Vector2i] = [Vector2i(720, 1280), Vector2i(720, 1600), Vector2i(1080, 1920), Vector2i(1080, 2400)]
	for viewport_size in sizes:
		var fixture := await _new_hud(viewport_size)
		var hud: GameplayHudLayer = fixture.hud
		hud.update_snapshot(_snapshot(9876543210, 4, 3, 8, 0, 1, false))
		hud.show_pause()
		await process_frame
		var metrics := hud.layout_metrics()
		var bounds := Rect2(Vector2.ZERO, Vector2(float(viewport_size.x), float(viewport_size.y)))
		for metric_name in ["score", "next", "target", "settings", "pause"]:
			var rect: Rect2 = metrics[metric_name]
			_assert(bounds.encloses(rect), "%s must remain inside %dx%d at %s" % [metric_name, viewport_size.x, viewport_size.y, str(rect)])
		_assert(not (metrics.score as Rect2).intersects(metrics.next), "SCORE and NEXT must not overlap at %dx%d" % [viewport_size.x, viewport_size.y])
		_assert(not (metrics.target as Rect2).intersects(metrics.settings), "Active target and Settings must not overlap at %dx%d" % [viewport_size.x, viewport_size.y])
		_assert((metrics.settings as Rect2).size.x >= 88.0 and (metrics.settings as Rect2).size.y >= 88.0, "Settings touch target must stay at least 88x88 at %dx%d" % [viewport_size.x, viewport_size.y])
		_assert((metrics.pause as Rect2).get_center().distance_to(bounds.get_center()) <= 2.0, "Pause popup must remain centered at %dx%d" % [viewport_size.x, viewport_size.y])
		_assert(hud.score_label.get_combined_minimum_size().x <= hud.score_label.size.x + 1.0, "Very large score must fit at %dx%d" % [viewport_size.x, viewport_size.y])
		_assert((metrics.next as Rect2).encloses(hud.next_icon.get_global_rect()), "NEXT contain slot must stay inside its supplied panel at %dx%d" % [viewport_size.x, viewport_size.y])
		_assert((metrics.target as Rect2).encloses(hud.target_icon.get_global_rect()), "Target contain slot must stay inside its supplied panel at %dx%d" % [viewport_size.x, viewport_size.y])
		hud.hide_pause()
		await _dispose_viewport(fixture.viewport)


func _test_effect_counts_are_bounded() -> void:
	var layer: GameplayEffectsLayer = GameplayEffectsLayerType.new()
	root.add_child(layer)
	await process_frame
	for index in range(40):
		var event := _merge_event(8000 + index, 2 + index % 4)
		event.depth = index % 4
		layer.begin_merge_feedback(event, 10 + index)
	for index in range(10):
		layer.begin_target_arrival(Vector2(100.0 + index * 10.0, 140.0), 7)
	_assert(layer.score_popups.size() <= 12 and layer.merge_impacts.size() <= 12, "Crowded merge feedback must cap score popups and impact bursts")
	_assert(layer.target_arrivals.size() <= 4, "Target arrival feedback must retain a small bounded count")
	_assert(layer.active_effect_count() <= 28, "All transient gameplay effects must remain bounded")
	layer.update_effects(maxf(GameConfig.SCORE_POPUP_DURATION, GameConfig.MERGE_PRESENTATION_DURATION) + 1.0)
	_assert(layer.active_effect_count() == 0, "Expired transient effects must release all presentation records")
	layer.queue_free()
	await process_frame


func _new_controller():
	paused = false
	var controller = GameScene.instantiate()
	root.add_child(controller)
	await process_frame
	return controller


func _dispose_controller(controller) -> void:
	paused = false
	if is_instance_valid(controller):
		controller.queue_free()
	await process_frame


func _new_hud(viewport_size: Vector2i) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.name = "HudTestViewport_%dx%d" % [viewport_size.x, viewport_size.y]
	viewport.size = viewport_size
	viewport.disable_3d = true
	root.add_child(viewport)
	var hud: GameplayHudLayer = GameplayHudLayerType.new()
	viewport.add_child(hud)
	await process_frame
	await process_frame
	return {"viewport": viewport, "hud": hud}


func _dispose_viewport(viewport: SubViewport) -> void:
	if is_instance_valid(viewport):
		viewport.queue_free()
	await process_frame


func _piece(id: int, level: int, position: Vector2):
	return GemPieceType.new(id, level, position, GameConfig.gem_collision_radius(level))


func _merge_event(result_id: int, level: int) -> Dictionary:
	var midpoint := Vector2(360.0, 720.0)
	return {
		"first_position": midpoint + Vector2(-32.0, 0.0),
		"second_position": midpoint + Vector2(32.0, 0.0),
		"midpoint": midpoint,
		"level": level,
		"depth": 0,
		"result_id": result_id,
	}


func _snapshot(score: int, current_level: int, next_level: int, target_level: int, target_progress: int, target_quantity: int, collecting: bool) -> Dictionary:
	return {
		"level_number": 1,
		"current_level": current_level,
		"next_level": next_level,
		"score": score,
		"target_level": target_level,
		"target_progress": target_progress,
		"target_quantity": target_quantity,
		"target_collecting": collecting,
	}


func _drive_target_to_arrival(controller, result_id: int, level: int) -> void:
	controller.pieces.append(_piece(result_id, level, Vector2(360.0, 720.0)))
	var target_events: Array[Dictionary] = [_merge_event(result_id, level)]
	controller._apply_confirmed_merge_events(target_events)
	controller._sync_gems_and_mark_visibility()
	controller._update_merge_presentations(GameConfig.MERGE_PRESENTATION_DURATION + 0.01)
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION + 0.01)


func _buttons_below(node: Node) -> Array[BaseButton]:
	var buttons: Array[BaseButton] = []
	for child in node.get_children():
		if child is BaseButton:
			buttons.append(child)
		buttons.append_array(_buttons_below(child))
	return buttons


func _count_name(names: Array[String], expected: String) -> int:
	var count := 0
	for name in names:
		if name == expected:
			count += 1
	return count


func _physics_signature() -> Dictionary:
	return {
		"table_center": GameConfig.TABLE_TEXTURE_CENTER,
		"board_top": GameConfig.BOARD_TOP,
		"board_bottom": GameConfig.BOARD_BOTTOM,
		"rail_left_top": GameConfig.TABLE_INNER_LEFT_TOP,
		"rail_left_bottom": GameConfig.TABLE_INNER_LEFT_BOTTOM,
		"rail_right_top": GameConfig.TABLE_INNER_RIGHT_TOP,
		"rail_right_bottom": GameConfig.TABLE_INNER_RIGHT_BOTTOM,
		"launch_speed": GameConfig.LAUNCH_SPEED,
		"damping": GameConfig.VELOCITY_DAMPING_PER_SECOND,
		"collision_restitution": GameConfig.COLLISION_RESTITUTION,
		"contact_epsilon": GameConfig.CONTACT_EPSILON,
		"separation_epsilon": GameConfig.SEPARATION_EPSILON,
		"perspective_back": GameConfig.GEM_PERSPECTIVE_SCALE_BACK,
		"perspective_front": GameConfig.GEM_PERSPECTIVE_SCALE_FRONT,
	}
