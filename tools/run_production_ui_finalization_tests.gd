extends SceneTree

## Development-only regression suite for the production UI milestone. It
## validates the reusable presentation scenes without changing simulation data.
const GameScene = preload("res://scenes/Game.tscn")
const GameplayHudScene = preload("res://scenes/ui/GameplayHud.tscn")
const ResultOverlayScene = preload("res://scenes/ui/ResultOverlay.tscn")
const AssetCatalogType = preload("res://scripts/asset_catalog.gd")
const ScoreFormatterType = preload("res://scripts/score_formatter.gd")
const UiDesignSystemType = preload("res://scripts/ui_design_system.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_score_formatting()
	await _test_hud_architecture_and_catalog_mapping()
	await _test_score_fit_and_state_updates()
	await _test_popup_composition_and_states()
	await _test_responsive_layouts()
	await _test_safe_areas()
	await _test_mobile_back_and_duplicate_guards()
	await _test_update_stability()
	paused = false
	if failures.is_empty():
		print("PRODUCTION_UI_FINALIZATION_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _test_score_formatting() -> void:
	var cases: Array[Dictionary] = [
		{"value": 0, "text": "0"},
		{"value": 9, "text": "9"},
		{"value": 99, "text": "99"},
		{"value": 999, "text": "999"},
		{"value": 1000, "text": "1,000"},
		{"value": 9999, "text": "9,999"},
		{"value": 10000, "text": "10K"},
		{"value": 125500, "text": "125.5K"},
		{"value": 999999, "text": "1M"},
		{"value": 1000000, "text": "1M"},
		{"value": 12500000, "text": "12.5M"},
		{"value": 9223372036854775807, "text": "9.2Qi"},
	]
	for entry in cases:
		var exact_value: int = entry.value
		var formatted := ScoreFormatterType.format(exact_value)
		_assert(formatted == String(entry.text), "Coin total %s must format as %s, got %s" % [str(exact_value), entry.text, formatted])
		_assert(exact_value == int(entry.value), "Formatting must not mutate the exact coin value")


func _test_hud_architecture_and_catalog_mapping() -> void:
	var fixture := await _new_hud(Vector2i(720, 1600))
	var hud: GameplayHudLayer = fixture.hud
	_assert(hud is CanvasLayer, "Gameplay HUD must remain outside the gameplay/table Node2D transform in a CanvasLayer")
	_assert(hud.root_control.theme == UiDesignSystemType.theme(), "Gameplay HUD must use the shared cached production Theme")
	_assert(hud.hud_margin is MarginContainer, "HUD safe-area root must be a MarginContainer")
	_assert(hud.hud_margin.get_node("HudRows") is VBoxContainer, "HUD rows must be container-driven")
	_assert(hud.hud_margin.get_node("HudRows/MainRow") is CenterContainer, "The enlarged merge path must own the centered top row")
	_assert(hud.hud_margin.get_node("HudRows/ScoreNextRow") is HBoxContainer, "COINS and NEXT must share the lower responsive card row")
	_assert(hud.hud_margin.get_node("HudRows/ObjectiveRow") is HBoxContainer, "Level and Settings must share a responsive utility HBoxContainer")
	_assert(hud.target_panel.get_parent() == hud.target_anchor, "Target must use its own responsive table-adjacent anchor")
	_assert(hud.score_panel.get_node("ContentSurface") is PanelContainer and hud.next_panel.get_node("ContentSurface") is PanelContainer, "COINS and NEXT must use the same simple scalable panel system")
	_assert(hud.score_panel.get_node("CoinsBadge") is PanelContainer and hud.next_panel.get_node("NextBadge") is PanelContainer, "COINS and NEXT labels must use the Level badge language")
	_assert(hud.coin_icon is Control and hud.coin_icon.get_parent().name == "CoinValueRow", "COINS must pair its value with the dedicated procedural coin icon")
	_assert(hud.target_panel.get_node("TargetContentSurface") is PanelContainer and hud.pause_panel is PanelContainer, "Target and Pause must use the same simple native panel system")
	_assert(hud.next_icon.get_parent() is AspectRatioContainer and hud.target_icon.get_parent() is AspectRatioContainer, "Dynamic gem previews must use aspect-preserving slots")
	_assert(hud.progression_icons.size() == 8, "Level 1 must show its complete readable eight-tier gameplay path")
	for tier in range(1, 9):
		_assert(hud.progression_icons[tier - 1].texture == AssetCatalogType.gem_texture(tier), "Progression tier %d must come from the authoritative gem catalog" % tier)
		_assert(hud.progression_frames[tier - 1] is MarginContainer, "Progression tier %d must preserve its source silhouette without a circular panel frame" % tier)
	_assert(_buttons_below(hud.hud_margin) == [hud.settings_button], "Normal gameplay must expose only the Settings/Pause button")
	_assert(hud.hud_margin.find_child("PauseRestartButton", true, false) == null, "Restart must not exist in the gameplay HUD")
	_assert(hud.hud_margin.find_child("ShotCounter", true, false) == null, "No finite shot counter may return to Level 1")
	for tier in range(1, 19):
		hud.update_snapshot(_snapshot(0, tier, maxi(1, 19 - tier), tier, 0, 4, 0, 2, false, false, tier))
		_assert(hud.next_icon.texture == AssetCatalogType.gem_texture(maxi(1, 19 - tier)), "NEXT tier %d must map through AssetCatalog" % maxi(1, 19 - tier))
		_assert(hud.target_icon.texture == AssetCatalogType.gem_texture(tier), "Target tier %d must map through AssetCatalog" % tier)
	_assert(hud.target_header_label.text == "TARGET", "Target label must stay simple and must not expose sequential counters")
	_assert(hud.target_panel.find_child("TargetName", true, false) == null, "Target card must not display the gem name")
	_assert(hud.target_panel.find_child("TargetProgressText", true, false) == null, "Target card must not display progress copy")
	_assert(hud.target_panel.find_child("TargetProgressBar", true, false) == null, "Target card must not display a progress bar")
	await _dispose_viewport(fixture.viewport)


func _test_score_fit_and_state_updates() -> void:
	var fixture := await _new_hud(Vector2i(720, 1600))
	var hud: GameplayHudLayer = fixture.hud
	var scores: Array[int] = [0, 9, 99, 999, 1000, 9999, 10000, 125500, 999999, 1000000, 12500000, 9223372036854775807]
	for score in scores:
		hud.update_snapshot(_snapshot(score, 2, 4, 7, 0, 1, 0, 2, false, false, 4))
		await process_frame
		_assert(hud.score_label.text == ScoreFormatterType.format(score), "HUD must display the shared coin format for %s" % str(score))
		_assert(hud.score_label.get_combined_minimum_size().x <= hud.score_label.size.x + 1.0, "Coin total %s must fit without clipping" % str(score))
		_assert(hud.score_panel.get_global_rect().encloses(hud.score_label.get_global_rect()), "Coin total %s must remain inside its responsive card" % str(score))
		_assert(hud.score_label.get_global_rect().end.y <= hud.score_panel.get_global_rect().end.y - 14.0, "Coin total %s must retain visible bottom breathing room" % str(score))
	hud.update_snapshot(_snapshot(125500, 2, 4, 7, 0, 1, 0, 2, false, false, 4))
	var texture_before := hud.next_icon.texture
	hud.update_snapshot(_snapshot(125500, 2, 3, 8, 0, 1, 1, 2, false, false, 4))
	_assert(texture_before != hud.next_icon.texture and hud.next_icon.texture == AssetCatalogType.gem_texture(3), "NEXT artwork must update immediately with the queue identity")
	_assert(hud.target_header_label.text == "TARGET", "Sequential state must not add counters to the Target label")
	await _dispose_viewport(fixture.viewport)


func _test_popup_composition_and_states() -> void:
	var fixture := await _new_hud(Vector2i(720, 1600))
	var hud: GameplayHudLayer = fixture.hud
	hud.show_pause()
	hud.show_pause()
	await process_frame
	_assert(hud.pause_blocker.visible and hud.pause_dimmer.mouse_filter == Control.MOUSE_FILTER_STOP, "Pause must dim and block all gameplay input")
	_assert(hud.pause_blocker.find_children("PausePanel", "PanelContainer", true, false).size() == 1, "Fast repeated taps must never duplicate the simple Pause popup")
	_assert(hud.resume_button.text == "RESUME" and hud.restart_button.text == "RESTART", "Pause actions must be explicit")
	_assert(hud.resume_button.custom_minimum_size.y >= 72.0 and hud.restart_button.custom_minimum_size.y >= 72.0, "Pause actions must retain mobile-sized touch targets")
	for button in [hud.resume_button, hud.restart_button]:
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			_assert(button.get_theme_stylebox(state) != null, "%s must provide a %s state" % [button.name, state])
	hud._on_settings_button_down()
	await create_timer(UiDesignSystemType.BUTTON_PRESS_DURATION + 0.02).timeout
	_assert(hud.settings_button.scale.x < 0.97, "Settings must expose visible press feedback")
	hud._on_settings_button_up()
	hud.hide_pause(false)

	var result_fixture := await _new_result(Vector2i(720, 1600))
	var result: ResultOverlayLayer = result_fixture.result
	_assert(result.root_control.theme == UiDesignSystemType.theme(), "Result UI must use the same production Theme as gameplay")
	_assert(result.panel is PanelContainer, "Win and Fail must use the same simple native panel system as gameplay")
	_assert(result.present(true, 125500), "First result presentation must succeed")
	_assert(not result.present(true, 125500) and result.present_count == 1, "Repeated final-state signals must not duplicate overlays")
	_assert(result.title_label.text == "LEVEL COMPLETE" and result.retry_button.text == "NEXT LEVEL" and result.score_label.text == "COINS  125.5K", "Win must use success-specific copy, coin total, and a valid forward-only action")
	_assert(result.result_icon.visible and not result.fail_badge.visible, "Win must show the final target artwork without failure art")
	result.dismiss()
	_assert(result.present(false, 9999), "Fail result must present after dismissal")
	_assert(result.title_label.text == "TRY AGAIN" and result.retry_button.text == "RETRY", "Fail must use clear recovery copy")
	_assert(not result.result_icon.visible and result.fail_badge.visible, "Fail must replace the prior empty art void with intentional failure art")
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		_assert(result.retry_button.get_theme_stylebox(state) != null, "Result action must provide a %s state" % state)
	await _dispose_viewport(result_fixture.viewport)
	await _dispose_viewport(fixture.viewport)


func _test_responsive_layouts() -> void:
	var sizes: Array[Vector2i] = [
		Vector2i(576, 1312),
		Vector2i(720, 1600),
		Vector2i(1080, 1920),
		Vector2i(1080, 2340),
		Vector2i(1080, 2400),
		Vector2i(540, 1320),
	]
	for viewport_size in sizes:
		var fixture := await _new_hud(viewport_size)
		var hud: GameplayHudLayer = fixture.hud
		hud.update_snapshot(_snapshot(9223372036854775807, 4, 3, 8, 0, 1, 1, 2, false, false, 5))
		hud.show_pause()
		await process_frame
		var metrics := hud.layout_metrics()
		var bounds := Rect2(Vector2.ZERO, Vector2(viewport_size))
		for key in ["score", "progression", "next", "level", "target", "settings", "pause"]:
			_assert(bounds.encloses(metrics[key]), "%s must remain inside %dx%d" % [key, viewport_size.x, viewport_size.y])
		_assert(not (metrics.score as Rect2).intersects(metrics.progression), "COINS and merge path must not overlap at %s" % str(viewport_size))
		_assert(not (metrics.progression as Rect2).intersects(metrics.next), "Merge path and NEXT must not overlap at %s" % str(viewport_size))
		_assert(not (metrics.level as Rect2).intersects(metrics.target), "Level and table-adjacent target must not overlap at %s" % str(viewport_size))
		_assert(not (metrics.target as Rect2).intersects(metrics.settings), "Table-adjacent target and Settings must not overlap at %s" % str(viewport_size))
		_assert((metrics.next as Rect2).grow(-10.0).encloses(hud.next_icon.get_global_rect()), "NEXT gem must remain visibly inset inside its card at %s" % str(viewport_size))
		_assert((metrics.target as Rect2).grow(-8.0).encloses(hud.target_icon.get_global_rect()), "Target gem must remain visibly inset inside its panel at %s (panel=%s icon=%s)" % [str(viewport_size), str(metrics.target), str(hud.target_icon.get_global_rect())])
		_assert(absf((metrics.level as Rect2).get_center().y - (metrics.settings as Rect2).get_center().y) <= 2.0, "Level and Settings must align as the top utility row at %s" % str(viewport_size))
		var design_scale := minf(1.0, float(viewport_size.x) / UiDesignSystemType.DESIGN_WIDTH)
		var design_height := float(viewport_size.y) / design_scale
		var board_top_design := GameConfig.BOARD_TOP + maxf(0.0, design_height - GameConfig.VIEWPORT_SIZE.y)
		var board_top_physical := board_top_design * design_scale
		_assert((metrics.target as Rect2).end.y <= board_top_physical - UiDesignSystemType.TARGET_TABLE_GAP * design_scale + 1.0, "Target card must remain immediately above the table at %s" % str(viewport_size))
		var minimum_physical_touch := 64.0 if viewport_size.x < 720 else 88.0
		_assert((metrics.settings as Rect2).size.x >= minimum_physical_touch and (metrics.settings as Rect2).size.y >= minimum_physical_touch, "Settings touch target must remain usable at %s" % str(viewport_size))
		_assert(hud.score_label.get_combined_minimum_size().x <= hud.score_label.size.x + 1.0, "Maximum coin total must fit at %s" % str(viewport_size))
		_assert((metrics.pause as Rect2).get_center().distance_to(bounds.get_center()) <= 2.0, "Pause must remain centered at %s" % str(viewport_size))
		await _dispose_viewport(fixture.viewport)


func _test_safe_areas() -> void:
	var fixture := await _new_hud(Vector2i(720, 1600))
	var hud: GameplayHudLayer = fixture.hud
	var insets := Vector4(24.0, 72.0, 24.0, 48.0)
	hud.set_safe_insets_for_testing(insets)
	hud.update_snapshot(_snapshot(12500000, 2, 4, 7, 0, 1, 0, 2, false, false, 4))
	hud.show_pause()
	await process_frame
	await process_frame
	var metrics := hud.layout_metrics()
	_assert((metrics.score as Rect2).position.y >= insets.y + UiDesignSystemType.SAFE_INSET_PADDING - 1.0, "Top HUD must clear a simulated notch")
	_assert((metrics.settings as Rect2).end.x <= 720.0 - insets.z - UiDesignSystemType.SAFE_INSET_PADDING + 1.0, "Settings must clear the right safe inset (settings=%s)" % str(metrics.settings))
	var safe_rect := Rect2(Vector2(insets.x + 10.0, insets.y + 10.0), Vector2(720.0 - insets.x - insets.z - 20.0, 1600.0 - insets.y - insets.w - 20.0))
	_assert(safe_rect.encloses(metrics.pause), "Pause must fit completely inside a notched device safe area")
	_assert((metrics.pause as Rect2).get_center().distance_to(safe_rect.get_center()) <= 2.0, "Pause must center within the safe area, not the obstructed screen")

	var result_fixture := await _new_result(Vector2i(720, 1600))
	var result: ResultOverlayLayer = result_fixture.result
	result.set_safe_insets_for_testing(insets)
	result.present(false, 10000)
	await process_frame
	var result_metrics := result.layout_metrics()
	_assert(safe_rect.encloses(result_metrics.panel), "Result popup must fit inside the same simulated safe area")
	_assert((result_metrics.panel as Rect2).get_center().distance_to(safe_rect.get_center()) <= 2.0, "Result popup must center within the safe area")
	await _dispose_viewport(result_fixture.viewport)
	await _dispose_viewport(fixture.viewport)


func _test_mobile_back_and_duplicate_guards() -> void:
	paused = false
	var controller = GameScene.instantiate()
	root.add_child(controller)
	await process_frame
	controller._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_assert(paused and controller.gameplay_ui.is_pause_visible(), "Android Back during play must open Pause instead of exiting")
	controller._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_assert(not paused, "Android Back while paused must resume immediately")
	await create_timer(UiDesignSystemType.POPUP_EXIT_DURATION + 0.03).timeout
	_assert(not controller.gameplay_ui.is_pause_visible(), "Android Back must close Pause first")
	controller.failed = true
	controller.result_overlay.present(false, 1000)
	controller._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_assert(controller.result_overlay.visible_result and not controller.gameplay_ui.is_pause_visible(), "Android Back must not dismiss or click through a result overlay")
	_assert(controller.gameplay_ui.settings_requested.get_connections().size() == 1, "Settings signal must be connected once")
	_assert(controller.gameplay_ui.resume_requested.get_connections().size() == 1, "Resume signal must be connected once")
	_assert(controller.gameplay_ui.restart_requested.get_connections().size() == 1, "Restart signal must be connected once")
	controller.queue_free()
	await process_frame
	paused = false


func _test_update_stability() -> void:
	var fixture := await _new_hud(Vector2i(720, 1600))
	var hud: GameplayHudLayer = fixture.hud
	var theme_before := UiDesignSystemType.theme()
	var font_before := UiDesignSystemType.font()
	var node_count_before := _descendant_count(hud)
	for index in range(500):
		hud.update_snapshot(_snapshot(index * 43721, index % 5 + 1, index % 4 + 1, 7 + index % 2, index % 2, 1, index % 2, 2, false, false, mini(5, index % 5 + 1)))
	_assert(_descendant_count(hud) == node_count_before, "Rapid coin, queue, and target changes must not rebuild UI nodes")
	_assert(UiDesignSystemType.theme() == theme_before and UiDesignSystemType.font() == font_before, "Theme and font resources must remain cached")
	_assert(hud.next_icon.texture == AssetCatalogType.gem_texture(499 % 4 + 1), "Rapid updates must finish with the current queue artwork")
	await _dispose_viewport(fixture.viewport)


func _new_hud(viewport_size: Vector2i) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.disable_3d = true
	root.add_child(viewport)
	var hud: GameplayHudLayer = GameplayHudScene.instantiate()
	viewport.add_child(hud)
	await process_frame
	await process_frame
	return {"viewport": viewport, "hud": hud}


func _new_result(viewport_size: Vector2i) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.disable_3d = true
	root.add_child(viewport)
	var result: ResultOverlayLayer = ResultOverlayScene.instantiate()
	viewport.add_child(result)
	await process_frame
	await process_frame
	return {"viewport": viewport, "result": result}


func _dispose_viewport(viewport: SubViewport) -> void:
	if is_instance_valid(viewport):
		viewport.queue_free()
	await process_frame


func _snapshot(score: int, current_level: int, next_level: int, target_level: int, target_progress: int, target_quantity: int, target_index: int, target_total: int, collecting: bool, completed: bool, highest_level: int) -> Dictionary:
	return {
		"level_number": 1,
		"current_level": current_level,
		"next_level": next_level,
		"score": score,
		"coins": score,
		"target_level": target_level,
		"target_progress": target_progress,
		"target_quantity": target_quantity,
		"target_index": target_index,
		"target_total": target_total,
		"target_collecting": collecting,
		"target_completed": completed,
		"highest_level": highest_level,
	}


func _buttons_below(node: Node) -> Array[BaseButton]:
	var result: Array[BaseButton] = []
	for child in node.get_children():
		if child is BaseButton:
			result.append(child)
		result.append_array(_buttons_below(child))
	return result


func _descendant_count(node: Node) -> int:
	var count := 1
	for child in node.get_children():
		count += _descendant_count(child)
	return count
