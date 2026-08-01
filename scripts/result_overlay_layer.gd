class_name ResultOverlayLayer
extends CanvasLayer

const AssetCatalogType = preload("res://scripts/asset_catalog.gd")
const ScoreFormatterType = preload("res://scripts/score_formatter.gd")
const UiDesignSystemType = preload("res://scripts/ui_design_system.gd")

signal retry_requested

## Dedicated result UI. It owns only its backdrop and panel; gameplay roots,
## gem sprites, simulation state, and reward timing are never modified here.
var visible_result := false
var result_won := false
var result_score := 0
var present_count := 0

var root_control: Control
var dimmer: ColorRect
var safe_margin: MarginContainer
var panel: NinePatchRect
var title_label: Label
var celebration_label: Label
var subtitle_label: Label
var result_icon: TextureRect
var fail_badge: PanelContainer
var score_label: Label
var retry_button: Button
var _entrance_tween: Tween
var _safe_insets_override := Vector4(-1.0, -1.0, -1.0, -1.0)


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_refresh_safe_margins()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_refresh_safe_margins):
		viewport.size_changed.connect(_refresh_safe_margins)


func _unhandled_input(event: InputEvent) -> void:
	# Result actions are explicit buttons. Consume Android Back/Escape while the
	# modal is present so a completed/failed run cannot exit accidentally.
	if visible_result and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if get_viewport() != null:
			get_viewport().set_input_as_handled()


func present(won: bool, score: int) -> bool:
	_build_ui()
	if visible_result:
		return false
	visible_result = true
	result_won = won
	result_score = score
	present_count += 1
	title_label.text = "LEVEL COMPLETE" if won else "TRY AGAIN"
	celebration_label.visible = won
	subtitle_label.text = "BOTH TARGETS COLLECTED" if won else "THE TABLE REACHED THE DANGER LINE"
	result_icon.visible = won
	result_icon.texture = AssetCatalogType.gem_texture(8) if won else null
	fail_badge.visible = not won
	score_label.text = "SCORE  %s" % ScoreFormatterType.format(score)
	retry_button.text = "REPLAY" if won else "RETRY"
	retry_button.tooltip_text = "Replay Level 1" if won else "Retry Level 1"
	root_control.visible = true
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	_start_entrance()
	if retry_button.is_inside_tree():
		retry_button.grab_focus()
	return true


func dismiss() -> void:
	visible_result = false
	_kill_entrance_tween()
	if root_control != null:
		root_control.visible = false
		root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if panel != null:
		panel.scale = Vector2.ONE
		panel.modulate = Color.WHITE
	if dimmer != null:
		dimmer.color = UiDesignSystemType.COLOR_OVERLAY


func set_safe_insets_for_testing(insets: Vector4) -> void:
	_safe_insets_override = insets
	_refresh_safe_margins()


func layout_metrics() -> Dictionary:
	_build_ui()
	return {
		"panel": panel.get_global_rect(),
		"button": retry_button.get_global_rect(),
		"icon": result_icon.get_global_rect(),
		"fail_badge": fail_badge.get_global_rect(),
	}


func _build_ui() -> void:
	if root_control != null:
		return
	root_control = Control.new()
	root_control.name = "ResultOverlayRoot"
	root_control.theme = UiDesignSystemType.theme()
	root_control.visible = false
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer = ColorRect.new()
	dimmer.name = "ResultDimmer"
	dimmer.color = UiDesignSystemType.COLOR_OVERLAY
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(dimmer)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_margin = MarginContainer.new()
	safe_margin.name = "ResultSafeArea"
	safe_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(safe_margin)
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.name = "ResultCenter"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_margin.add_child(center)
	panel = NinePatchRect.new()
	panel.name = "ResultPanel"
	panel.custom_minimum_size = Vector2(480.0, 548.0)
	UiDesignSystemType.configure_nine_patch(panel, UiDesignSystemType.atlas(AssetCatalogType.HUD_BUTTON_SHEET, AssetCatalogType.HUD_WHITE_PANEL_REGION), 64, 64)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.name = "ResultContentMargin"
	margin.add_theme_constant_override("margin_left", 52)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_right", 52)
	margin.add_theme_constant_override("margin_bottom", 42)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.name = "ResultContent"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 8)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	title_label = _label("LEVEL COMPLETE", 37, UiDesignSystemType.COLOR_CORAL)
	title_label.name = "ResultTitle"
	title_label.custom_minimum_size = Vector2(0.0, 58.0)
	title_label.add_theme_constant_override("outline_size", 6)
	title_label.add_theme_color_override("font_outline_color", UiDesignSystemType.COLOR_CREAM)
	column.add_child(title_label)
	celebration_label = _label("•  ✦  •", 20, UiDesignSystemType.COLOR_GOLD)
	celebration_label.name = "CelebrationAccents"
	celebration_label.custom_minimum_size = Vector2(0.0, 22.0)
	column.add_child(celebration_label)
	subtitle_label = _label("BOTH TARGETS COLLECTED", 16, UiDesignSystemType.COLOR_TEXT_MUTED)
	subtitle_label.name = "ResultSubtitle"
	subtitle_label.custom_minimum_size = Vector2(0.0, 38.0)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(subtitle_label)
	var art_slot := CenterContainer.new()
	art_slot.name = "ResultArtSlot"
	art_slot.custom_minimum_size = Vector2(170.0, 170.0)
	art_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(art_slot)
	var icon_aspect := AspectRatioContainer.new()
	icon_aspect.name = "ResultGemSlot"
	icon_aspect.custom_minimum_size = Vector2(158.0, 158.0)
	icon_aspect.ratio = 1.0
	icon_aspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_slot.add_child(icon_aspect)
	result_icon = TextureRect.new()
	result_icon.name = "ResultGem"
	result_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_aspect.add_child(result_icon)
	fail_badge = PanelContainer.new()
	fail_badge.name = "FailBadge"
	fail_badge.custom_minimum_size = Vector2(116.0, 116.0)
	fail_badge.add_theme_stylebox_override("panel", UiDesignSystemType.fail_badge_style())
	fail_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_slot.add_child(fail_badge)
	var fail_mark := _label("!", 62, UiDesignSystemType.COLOR_CORAL_DARK)
	fail_mark.name = "FailMark"
	fail_mark.add_theme_constant_override("outline_size", 0)
	fail_badge.add_child(fail_mark)
	fail_badge.visible = false
	score_label = _label("SCORE  0", 29, UiDesignSystemType.COLOR_TEAL)
	score_label.name = "ResultScore"
	score_label.custom_minimum_size = Vector2(0.0, 52.0)
	column.add_child(score_label)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 6.0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(spacer)
	retry_button = Button.new()
	retry_button.name = "ResultActionButton"
	retry_button.text = "REPLAY"
	retry_button.custom_minimum_size = Vector2(320.0, 78.0)
	retry_button.focus_mode = Control.FOCUS_ALL
	retry_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	retry_button.mouse_filter = Control.MOUSE_FILTER_STOP
	retry_button.pressed.connect(func() -> void: retry_requested.emit())
	column.add_child(retry_button)


func _start_entrance() -> void:
	_kill_entrance_tween()
	panel.pivot_offset = _node_center(panel)
	if not is_inside_tree():
		panel.scale = Vector2.ONE
		panel.modulate = Color.WHITE
		dimmer.color = UiDesignSystemType.COLOR_OVERLAY
		return
	panel.scale = Vector2.ONE * 0.90
	panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	dimmer.color = Color(UiDesignSystemType.COLOR_OVERLAY.r, UiDesignSystemType.COLOR_OVERLAY.g, UiDesignSystemType.COLOR_OVERLAY.b, 0.0)
	_entrance_tween = create_tween().set_parallel(true)
	_entrance_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_entrance_tween.tween_property(panel, "scale", Vector2.ONE, UiDesignSystemType.POPUP_ENTER_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_entrance_tween.tween_property(panel, "modulate:a", 1.0, UiDesignSystemType.POPUP_ENTER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_entrance_tween.tween_property(dimmer, "color:a", UiDesignSystemType.COLOR_OVERLAY.a, UiDesignSystemType.POPUP_ENTER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _refresh_safe_margins() -> void:
	if safe_margin == null or not is_inside_tree():
		return
	var insets := _safe_insets()
	safe_margin.add_theme_constant_override("margin_left", int(ceil(maxf(16.0, insets.x + UiDesignSystemType.SAFE_INSET_PADDING))))
	safe_margin.add_theme_constant_override("margin_top", int(ceil(maxf(16.0, insets.y + UiDesignSystemType.SAFE_INSET_PADDING))))
	safe_margin.add_theme_constant_override("margin_right", int(ceil(maxf(16.0, insets.z + UiDesignSystemType.SAFE_INSET_PADDING))))
	safe_margin.add_theme_constant_override("margin_bottom", int(ceil(maxf(16.0, insets.w + UiDesignSystemType.SAFE_INSET_PADDING))))


func _safe_insets() -> Vector4:
	if _safe_insets_override.x >= 0.0:
		return _safe_insets_override
	if get_viewport() != get_tree().root:
		return Vector4.ZERO
	return UiDesignSystemType.safe_insets(get_viewport().get_visible_rect().size, Vector2(DisplayServer.window_get_size()), DisplayServer.get_display_safe_area())


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UiDesignSystemType.font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color(1.0, 0.96, 0.86, 0.76))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _node_center(control: Control) -> Vector2:
	var node_size := control.size
	if node_size == Vector2.ZERO:
		node_size = control.custom_minimum_size
	return node_size * 0.5


func _kill_entrance_tween() -> void:
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()
