extends SceneTree

## Guards the interaction-polish contract for the supplied-art UI kit.
## Every case here failed against the first kit pass.

const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")
const UiKitType = preload("res://scripts/ui/ui_kit.gd")
const ScreenTransitionType = preload("res://scripts/ui/screen_transition_layer.gd")
const DailyMissionsOverlayType = preload("res://scripts/ui/daily_missions_overlay_layer.gd")
const DailyMissionServiceType = preload("res://scripts/services/daily_mission_service.gd")
const ResultOverlayType = preload("res://scripts/ui/result_overlay_layer.gd")
const LevelBriefingType = preload("res://scripts/ui/level_briefing_overlay_layer.gd")
const HomeOverlayType = preload("res://scripts/ui/home_overlay_layer.gd")

const BUTTON_VARIATIONS := ["Button", "SecondaryButton", "HeroButton", "GreenButton", "IconButton"]
const INTERACTIVE_STATES := ["normal", "hover", "pressed"]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_states_share_one_silhouette()
	_test_no_glyph_bearing_plate_as_a_state()
	_test_every_referenced_plate_exists()
	_test_disabled_plates_are_neutral()
	await _test_transition_cover_is_inert_when_idle()
	await _test_popup_animates()
	await _test_modals_fit_the_viewport()
	_test_plates_are_authored_at_their_drawn_height()
	await _test_no_button_crushes_its_plate()
	if failures.is_empty():
		print("UI_KIT_POLISH_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("UI_KIT_POLISH_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


## The core interaction defect: Godot swaps the stylebox on hover/press, so if
## the states point at different textures the plate morphs mid-interaction.
func _test_states_share_one_silhouette() -> void:
	var theme := UiDesignSystemType.theme()
	for variation in BUTTON_VARIATIONS:
		var textures: Array[String] = []
		for state in INTERACTIVE_STATES:
			var box := theme.get_stylebox(state, variation) as StyleBoxTexture
			if box == null or box.texture == null:
				failures.append("%s '%s' must supply a textured plate" % [variation, state])
				continue
			textures.append(box.texture.resource_path)
		if textures.size() == INTERACTIVE_STATES.size():
			var unique := {}
			for path in textures:
				unique[path] = true
			_assert(unique.size() == 1,
				"%s must use one silhouette across normal/hover/pressed, found %d: %s" % [variation, unique.size(), str(textures)])


## `btn_square_swap` has swap arrows painted into the artwork, so using it as an
## interaction state turned the settings gear into swap arrows on hover.
func _test_no_glyph_bearing_plate_as_a_state() -> void:
	var theme := UiDesignSystemType.theme()
	for variation in BUTTON_VARIATIONS:
		for state in ["normal", "hover", "pressed", "disabled"]:
			var box := theme.get_stylebox(state, variation) as StyleBoxTexture
			if box == null or box.texture == null:
				continue
			_assert(not box.texture.resource_path.contains("btn_square_swap"),
				"%s '%s' must not use the glyph-bearing swap plate" % [variation, state])


## A plate generated after the last import returns null from load(), and the
## button then silently draws nothing at all.
func _test_every_referenced_plate_exists() -> void:
	for key in UiKitType.NINE:
		var path: String = UiKitType.KIT % key
		_assert(ResourceLoader.exists(path), "Kit plate '%s' is referenced but not importable at %s" % [key, path])
	var theme := UiDesignSystemType.theme()
	for variation in BUTTON_VARIATIONS:
		for state in ["normal", "hover", "pressed", "disabled"]:
			var box := theme.get_stylebox(state, variation) as StyleBoxTexture
			_assert(box != null and box.texture != null,
				"%s '%s' resolved to an empty plate" % [variation, state])


## An unavailable reward must not still read as an affirmative green action.
func _test_disabled_plates_are_neutral() -> void:
	var theme := UiDesignSystemType.theme()
	var box := theme.get_stylebox("disabled", "GreenButton") as StyleBoxTexture
	if box == null or box.texture == null:
		failures.append("GreenButton disabled must supply a plate")
		return
	var image := box.texture.get_image()
	if image == null:
		return
	# Sample the plate body and confirm green no longer dominates.
	var greener := 0
	var samples := 0
	for y in range(int(image.get_height() * 0.35), int(image.get_height() * 0.65), 3):
		for x in range(int(image.get_width() * 0.35), int(image.get_width() * 0.65), 3):
			var c := image.get_pixel(x, y)
			if c.a < 0.5:
				continue
			samples += 1
			if c.g > c.r + 0.06 and c.g > c.b + 0.06:
				greener += 1
	_assert(samples > 0 and float(greener) / float(maxi(1, samples)) < 0.10,
		"GreenButton disabled plate must be desaturated, %d/%d sampled pixels still read green" % [greener, samples])


## The transition cover spans the whole screen above every layer; if it ate
## input while idle the game would be unplayable.
func _test_transition_cover_is_inert_when_idle() -> void:
	var layer = ScreenTransitionType.new()
	root.add_child(layer)
	await process_frame
	_assert(not layer.is_busy(), "A fresh transition layer must be idle")
	_assert(layer.cover != null and not layer.cover.visible, "Idle cover must be hidden")
	_assert(layer.cover.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Idle cover must not capture input")
	var ran := [false]
	layer.play(func() -> void: ran[0] = true)
	_assert(layer.is_busy(), "A running transition must report busy")
	await layer.transition_finished
	_assert(ran[0], "The transition must run its swap callable")
	_assert(not layer.cover.visible, "Cover must be hidden again once finished")
	_assert(layer.cover.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Cover must never capture input")
	layer.queue_free()
	await process_frame


## The popup previously appeared as an instant cut with no motion at all.
func _test_popup_animates() -> void:
	var overlay = DailyMissionsOverlayType.new()
	root.add_child(overlay)
	await process_frame
	var state := {"date": "2026-08-29", "missions": [], "chest_claimed": false}
	overlay.present(state, 100)
	await process_frame
	_assert(overlay.popup_shell.scale.x < 1.0 or overlay.popup_shell.modulate.a < 1.0,
		"Opening the popup must start from a scaled/faded entrance state")
	# The title plate is a sibling of the panel, so animating the panel alone
	# left the label fully opaque before the popup arrived and after it left.
	# The animated node must be their common parent.
	var banner: Node = overlay.popup_shell.get_node_or_null("PopupTitleBanner")
	_assert(banner != null, "The popup shell must own the title banner")
	_assert(overlay.panel.get_parent() == overlay.popup_shell,
		"The panel must sit inside the animated shell, not beside the title banner")
	_assert(is_equal_approx(overlay.panel.modulate.a, 1.0) and is_equal_approx(overlay.panel.scale.x, 1.0),
		"The panel must not be animated on its own; the shell carries the entrance")
	overlay.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


## Modal content must fit the narrowest supported screen. Increasing shared
## button padding has twice pushed a populated card row past the viewport edge,
## and a static screenshot is the only thing that caught it.
func _test_modals_fit_the_viewport() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	root.add_child(viewport)
	var overlay = DailyMissionsOverlayType.new()
	viewport.add_child(overlay)
	await process_frame
	var state := DailyMissionServiceType.ensure_current_day({})
	var missions: Array = state.get("missions", []) as Array
	# Longest realistic captions: a claimable reward and a locked one.
	if missions.size() >= 3:
		missions[1]["progress"] = int(missions[1].get("target", 1))
	state["missions"] = missions
	overlay.present(state, 5200)
	await process_frame
	await process_frame
	var rect: Rect2 = overlay.panel.get_global_rect()
	_assert(rect.position.x >= -1.0 and rect.end.x <= 721.0,
		"Daily missions panel must fit 720px, spans %.1f..%.1f" % [rect.position.x, rect.end.x])
	var row: Control = overlay.cards_row
	if row != null:
		var row_rect: Rect2 = row.get_global_rect()
		_assert(row_rect.position.x >= -1.0 and row_rect.end.x <= 721.0,
			"Mission card row must fit 720px, spans %.1f..%.1f" % [row_rect.position.x, row_rect.end.x])
	viewport.queue_free()
	await process_frame


## Nine-patch caps are drawn unstretched at their margin size. If a control is
## shorter than top+bottom margins the caps overlap and the plate visibly
## crushes - this is the exact defect that made buttons look stretched.
func _test_plates_are_authored_at_their_drawn_height() -> void:
	for key in UiKitType.DRAWN_HEIGHT:
		var expected: int = UiKitType.DRAWN_HEIGHT[key]
		var texture: Texture2D = load(UiKitType.KIT % key)
		_assert(texture != null and texture.get_height() == expected,
			"Plate '%s' must be authored at its drawn height %d, found %d" % [
				key, expected, 0 if texture == null else texture.get_height()])
		var margins: Array = UiKitType.NINE.get(key, [])
		if margins.size() == 4:
			_assert(int(margins[1]) + int(margins[3]) <= expected,
				"Plate '%s' vertical margins (%d+%d) must fit its %dpx height" % [
					key, int(margins[1]), int(margins[3]), expected])


## Every real button on every screen must clear its own plate's caps.
func _test_no_button_crushes_its_plate() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	root.add_child(viewport)
	var layers := [
		DailyMissionsOverlayType.new(),
		ResultOverlayType.new(),
		LevelBriefingType.new(),
		HomeOverlayType.new(),
	]
	for layer in layers:
		viewport.add_child(layer)
	await process_frame
	await process_frame
	for layer in layers:
		_check_buttons(layer)
	viewport.queue_free()
	await process_frame


func _check_buttons(node: Node) -> void:
	if node is Button:
		var button := node as Button
		var box := button.get_theme_stylebox("normal") as StyleBoxTexture
		if box != null and box.texture != null:
			var caps: float = box.get_texture_margin(SIDE_TOP) + box.get_texture_margin(SIDE_BOTTOM)
			var drawn: float = maxf(button.custom_minimum_size.y, button.size.y)
			_assert(caps <= 0.0 or drawn >= caps,
				"%s is %.0fpx tall but its plate's caps need %.0fpx - the plate will crush" % [
					button.name, drawn, caps])
	for child in node.get_children():
		_check_buttons(child)
