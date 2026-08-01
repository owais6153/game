class_name GameplayHudLayer
extends CanvasLayer

const AssetCatalogType = preload("res://scripts/asset_catalog.gd")
const ScoreFormatterType = preload("res://scripts/score_formatter.gd")
const UiDesignSystemType = preload("res://scripts/ui_design_system.gd")
const SNAPSHOT_KEYS := ["level_number", "current_level", "next_level", "score", "target_level", "target_progress", "target_quantity", "target_index", "target_total", "target_collecting", "target_completed", "highest_level"]

signal settings_requested
signal resume_requested
signal restart_requested

var root_control: Control
var hud_canvas: Control
var hud_margin: MarginContainer
var progression_center: CenterContainer
var target_anchor: CenterContainer
var score_panel: Control
var score_label: Label
var progression_frames: Array[PanelContainer] = []
var progression_icons: Array[TextureRect] = []
var next_panel: Control
var next_icon: TextureRect
var level_chip: Control
var level_label: Label
var target_panel: Control
var target_header_label: Label
var target_icon: TextureRect
var settings_button: TextureButton
var pause_blocker: Control
var pause_dimmer: ColorRect
var pause_safe_margin: MarginContainer
var pause_panel: NinePatchRect
var resume_button: Button
var restart_button: Button

var _built := false
var _snapshot: Dictionary = {}
var _progress_style: StyleBoxFlat
var _progress_reached_style: StyleBoxFlat
var _progress_active_style: StyleBoxFlat
var _layout_scale := 1.0
var _safe_insets_override := Vector4(-1.0, -1.0, -1.0, -1.0)
var _score_tween: Tween
var _next_tween: Tween
var _target_swap_tween: Tween
var _target_pulse_tween: Tween
var _settings_tween: Tween
var _pause_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 40
	_build_once()
	_refresh_safe_margins()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_refresh_safe_margins):
		viewport.size_changed.connect(_refresh_safe_margins)


func _unhandled_input(event: InputEvent) -> void:
	# The HUD processes while the tree is paused, so Android Back/Escape closes
	# the modal first instead of falling through to an immediate app exit.
	if pause_blocker != null and pause_blocker.visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		resume_requested.emit()
		if get_viewport() != null:
			get_viewport().set_input_as_handled()


func update_snapshot(snapshot: Dictionary) -> void:
	_build_once()
	if _snapshot_matches(snapshot):
		return
	var had_snapshot := not _snapshot.is_empty()
	var formatted_score := ScoreFormatterType.format(int(snapshot.get("score", 0)))
	if score_label.text != formatted_score:
		score_label.text = formatted_score
		score_label.add_theme_font_size_override("font_size", _score_font_size(formatted_score))
		if had_snapshot:
			_animate_score_change()

	var next_level := int(snapshot.get("next_level", 1))
	if int(_snapshot.get("next_level", -1)) != next_level:
		next_icon.texture = AssetCatalogType.gem_texture(next_level)
		next_icon.tooltip_text = "Next: %s" % AssetCatalogType.gem_name(next_level)
		if had_snapshot:
			_animate_next_swap()

	var current_level := int(snapshot.get("current_level", 1))
	var highest_level := int(snapshot.get("highest_level", 1))
	if int(_snapshot.get("current_level", -1)) != current_level or int(_snapshot.get("highest_level", -1)) != highest_level:
		for index in range(progression_frames.size()):
			var tier := index + 1
			var style := _progress_style
			if tier == current_level:
				style = _progress_active_style
			elif tier <= mini(highest_level, progression_frames.size()):
				style = _progress_reached_style
			progression_frames[index].add_theme_stylebox_override("panel", style)

	var target_level := int(snapshot.get("target_level", 1))
	if int(_snapshot.get("target_level", -1)) != target_level:
		var target_name := AssetCatalogType.gem_name(target_level)
		target_icon.texture = AssetCatalogType.gem_texture(target_level)
		target_icon.tooltip_text = "Target: %s" % target_name
		if had_snapshot:
			_animate_target_swap()

	var level_number := int(snapshot.get("level_number", 1))
	level_label.text = "LEVEL %d" % level_number
	target_header_label.text = "TARGET"
	_snapshot = snapshot.duplicate()


func _snapshot_matches(snapshot: Dictionary) -> bool:
	if _snapshot.is_empty():
		return false
	for key in SNAPSHOT_KEYS:
		if _snapshot.get(key) != snapshot.get(key):
			return false
	return true


func show_pause() -> void:
	_build_once()
	if pause_blocker.visible:
		return
	_kill_tween(_pause_tween)
	pause_blocker.visible = true
	pause_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_panel.pivot_offset = _node_center(pause_panel)
	pause_panel.scale = Vector2.ONE * 0.92
	pause_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	pause_dimmer.color = Color(UiDesignSystemType.COLOR_OVERLAY.r, UiDesignSystemType.COLOR_OVERLAY.g, UiDesignSystemType.COLOR_OVERLAY.b, 0.0)
	if is_inside_tree():
		_pause_tween = create_tween().set_parallel(true)
		_pause_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_pause_tween.tween_property(pause_panel, "scale", Vector2.ONE, UiDesignSystemType.POPUP_ENTER_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_pause_tween.tween_property(pause_panel, "modulate:a", 1.0, UiDesignSystemType.POPUP_ENTER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_pause_tween.tween_property(pause_dimmer, "color:a", UiDesignSystemType.COLOR_OVERLAY.a, UiDesignSystemType.POPUP_ENTER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		resume_button.grab_focus()
	else:
		pause_panel.scale = Vector2.ONE
		pause_panel.modulate = Color.WHITE
		pause_dimmer.color = UiDesignSystemType.COLOR_OVERLAY


func hide_pause(animated: bool = true) -> void:
	if not _built or not pause_blocker.visible:
		return
	_kill_tween(_pause_tween)
	if not animated or not is_inside_tree():
		_finish_hide_pause()
		return
	_pause_tween = create_tween().set_parallel(true)
	_pause_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_pause_tween.tween_property(pause_panel, "scale", Vector2.ONE * 0.96, UiDesignSystemType.POPUP_EXIT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_pause_tween.tween_property(pause_panel, "modulate:a", 0.0, UiDesignSystemType.POPUP_EXIT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_pause_tween.tween_property(pause_dimmer, "color:a", 0.0, UiDesignSystemType.POPUP_EXIT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_pause_tween.finished.connect(_finish_hide_pause, CONNECT_ONE_SHOT)


func is_pause_visible() -> bool:
	return _built and pause_blocker.visible


func pulse_target() -> void:
	_build_once()
	_kill_tween(_target_pulse_tween)
	target_panel.pivot_offset = _node_center(target_panel)
	target_panel.scale = Vector2.ONE
	if not is_inside_tree():
		return
	_target_pulse_tween = create_tween()
	_target_pulse_tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_target_pulse_tween.tween_property(target_panel, "scale", Vector2.ONE * 1.055, UiDesignSystemType.TARGET_PULSE_DURATION * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_target_pulse_tween.tween_property(target_panel, "scale", Vector2.ONE, UiDesignSystemType.TARGET_PULSE_DURATION * 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func target_collection_destination() -> Vector2:
	if target_icon == null or not target_icon.is_inside_tree():
		return GameConfig.TARGET_COLLECTION_DESTINATION
	return target_icon.get_global_rect().get_center()


func reset_presentation() -> void:
	hide_pause(false)
	for tween in [_score_tween, _next_tween, _target_swap_tween, _target_pulse_tween, _settings_tween]:
		_kill_tween(tween)
	if score_label != null:
		score_label.scale = Vector2.ONE
	if next_icon != null:
		next_icon.scale = Vector2.ONE
		next_icon.modulate = Color.WHITE
	if target_icon != null:
		target_icon.scale = Vector2.ONE
		target_icon.modulate = Color.WHITE
	if target_panel != null:
		target_panel.scale = Vector2.ONE
	if settings_button != null:
		settings_button.scale = Vector2.ONE


func set_safe_insets_for_testing(insets: Vector4) -> void:
	_safe_insets_override = insets
	_refresh_safe_margins()


func layout_metrics() -> Dictionary:
	_build_once()
	return {
		"score": score_panel.get_global_rect(),
		"progression": progression_center.get_global_rect(),
		"next": next_panel.get_global_rect(),
		"level": level_chip.get_global_rect(),
		"target": target_panel.get_global_rect(),
		"settings": settings_button.get_global_rect(),
		"pause": pause_panel.get_global_rect(),
		"hud": hud_margin.get_global_rect(),
	}


func _build_once() -> void:
	if _built:
		return
	_built = true
	_progress_style = UiDesignSystemType.progression_style(UiDesignSystemType.COLOR_GOLD, 3)
	_progress_reached_style = UiDesignSystemType.progression_style(UiDesignSystemType.COLOR_TEAL, 3, Color("f2ffff"))
	_progress_active_style = UiDesignSystemType.progression_style(UiDesignSystemType.COLOR_CORAL, 5, Color("fff1e8"))
	root_control = Control.new()
	root_control.name = "GameplayUIRoot"
	root_control.theme = UiDesignSystemType.theme()
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_hud()
	_build_pause_popup()


func _build_hud() -> void:
	hud_canvas = Control.new()
	hud_canvas.name = "HudDesignCanvas"
	hud_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_canvas.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hud_canvas.offset_right = UiDesignSystemType.DESIGN_WIDTH
	hud_canvas.offset_bottom = 326.0
	root_control.add_child(hud_canvas)

	hud_margin = MarginContainer.new()
	hud_margin.name = "SafeHudMargin"
	hud_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_canvas.add_child(hud_margin)
	hud_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rows := VBoxContainer.new()
	rows.name = "HudRows"
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation", UiDesignSystemType.ROW_GAP)
	hud_margin.add_child(rows)

	var main_row := HBoxContainer.new()
	main_row.name = "MainRow"
	main_row.custom_minimum_size = Vector2(0.0, 128.0)
	main_row.add_theme_constant_override("separation", 6)
	main_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_child(main_row)
	score_panel = _build_score_panel()
	main_row.add_child(score_panel)
	progression_center = CenterContainer.new()
	progression_center.name = "ProgressionCenter"
	progression_center.custom_minimum_size = Vector2(396.0, 128.0)
	progression_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progression_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_row.add_child(progression_center)
	progression_center.add_child(_build_progression_group())
	next_panel = _build_next_panel()
	main_row.add_child(next_panel)

	var objective_row := HBoxContainer.new()
	objective_row.name = "ObjectiveRow"
	objective_row.custom_minimum_size = Vector2(0.0, 96.0)
	objective_row.add_theme_constant_override("separation", UiDesignSystemType.ITEM_GAP)
	objective_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_child(objective_row)
	var level_slot := CenterContainer.new()
	level_slot.name = "LevelSlot"
	level_slot.custom_minimum_size = Vector2(116.0, 96.0)
	level_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_row.add_child(level_slot)
	level_chip = _build_level_chip()
	level_slot.add_child(level_chip)
	var utility_spacer := Control.new()
	utility_spacer.name = "UtilitySpacer"
	utility_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	utility_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_row.add_child(utility_spacer)
	var settings_slot := CenterContainer.new()
	settings_slot.name = "SettingsSlot"
	settings_slot.custom_minimum_size = Vector2(88.0, 96.0)
	settings_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_row.add_child(settings_slot)
	settings_button = _build_settings_button()
	settings_slot.add_child(settings_button)

	target_anchor = CenterContainer.new()
	target_anchor.name = "TableTargetAnchor"
	target_anchor.custom_minimum_size = Vector2(UiDesignSystemType.DESIGN_WIDTH, 148.0)
	target_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_canvas.add_child(target_anchor)
	target_panel = _build_target_panel()
	target_anchor.add_child(target_panel)


func _build_score_panel() -> Control:
	var panel := _build_hud_card("ScorePanel", "SCORE")
	var margin := MarginContainer.new()
	margin.name = "ScoreContentMargin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	score_label = _label("0", UiDesignSystemType.SCORE_FONT_SIZE, UiDesignSystemType.COLOR_TEXT)
	score_label.name = "ScoreValue"
	score_label.custom_minimum_size = Vector2(0.0, 62.0)
	column.add_child(score_label)
	return panel


func _build_next_panel() -> Control:
	var panel := _build_hud_card("NextPanel", "NEXT")
	var margin := MarginContainer.new()
	margin.name = "NextContentMargin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(center)
	var aspect := AspectRatioContainer.new()
	aspect.name = "NextGemAspect"
	aspect.custom_minimum_size = Vector2(60.0, 60.0)
	aspect.ratio = 1.0
	aspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(aspect)
	next_icon = _gem_texture_rect("NextGem")
	aspect.add_child(next_icon)
	return panel


func _build_hud_card(node_name: String, title: String) -> Control:
	var panel := Control.new()
	panel.name = node_name
	panel.custom_minimum_size = Vector2(122.0, 122.0)
	panel.clip_contents = true
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var inner := PanelContainer.new()
	inner.name = "ContentSurface"
	inner.add_theme_stylebox_override("panel", UiDesignSystemType.simple_hud_panel_style())
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(inner)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_top = 18.0
	var badge := _build_label_badge("%sBadge" % title.to_pascal_case(), title, 100.0, 44.0)
	badge.set_anchors_preset(Control.PRESET_CENTER_TOP)
	badge.offset_left = -50.0
	badge.offset_right = 50.0
	panel.add_child(badge)
	return panel


func _build_progression_group() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "ProgressionPanel"
	panel.custom_minimum_size = Vector2(396.0, 122.0)
	panel.add_theme_stylebox_override("panel", UiDesignSystemType.progression_panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var group := VBoxContainer.new()
	group.name = "ProgressionGroup"
	group.alignment = BoxContainer.ALIGNMENT_CENTER
	group.add_theme_constant_override("separation", 7)
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(group)
	var heading := _label("MERGE PATH", 19, UiDesignSystemType.COLOR_TEAL_DARK)
	heading.name = "ProgressionHeading"
	heading.custom_minimum_size = Vector2(0.0, 26.0)
	heading.add_theme_constant_override("outline_size", 2)
	heading.add_theme_color_override("font_outline_color", Color.WHITE)
	group.add_child(heading)
	var strip := HBoxContainer.new()
	strip.name = "ProgressionStrip"
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 0)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(strip)
	for tier in range(1, 9):
		var frame := PanelContainer.new()
		frame.name = "ProgressionSlot%d" % tier
		frame.custom_minimum_size = Vector2(42.0, 42.0)
		frame.add_theme_stylebox_override("panel", _progress_style)
		frame.tooltip_text = AssetCatalogType.gem_name(tier)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var inset := MarginContainer.new()
		inset.add_theme_constant_override("margin_left", 3)
		inset.add_theme_constant_override("margin_top", 3)
		inset.add_theme_constant_override("margin_right", 3)
		inset.add_theme_constant_override("margin_bottom", 3)
		inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(inset)
		var icon := _gem_texture_rect("ProgressionGem%d" % tier)
		icon.texture = AssetCatalogType.gem_texture(tier)
		inset.add_child(icon)
		strip.add_child(frame)
		progression_frames.append(frame)
		progression_icons.append(icon)
		if tier < 8:
			var connector_center := CenterContainer.new()
			connector_center.custom_minimum_size = Vector2(6.0, 42.0)
			connector_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var connector := ColorRect.new()
			connector.custom_minimum_size = Vector2(6.0, 4.0)
			connector.color = UiDesignSystemType.COLOR_GOLD
			connector.mouse_filter = Control.MOUSE_FILTER_IGNORE
			connector_center.add_child(connector)
			strip.add_child(connector_center)
	return panel


func _build_level_chip() -> Control:
	var chip := _build_label_badge("LevelChip", "LEVEL 1", 116.0, 58.0)
	level_label = chip.get_node("Label") as Label
	return chip


func _build_target_panel() -> Control:
	var panel := Control.new()
	panel.name = "ActiveTargetPanel"
	panel.custom_minimum_size = Vector2(178.0, 148.0)
	panel.clip_contents = true
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var inner := PanelContainer.new()
	inner.name = "TargetContentSurface"
	inner.add_theme_stylebox_override("panel", UiDesignSystemType.simple_hud_panel_style())
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(inner)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_top = 18.0
	var badge := _build_label_badge("TargetBadge", "TARGET", 120.0, 44.0)
	badge.set_anchors_preset(Control.PRESET_CENTER_TOP)
	badge.offset_left = -60.0
	badge.offset_right = 60.0
	panel.add_child(badge)
	target_header_label = badge.get_node("Label") as Label
	var content_margin := MarginContainer.new()
	content_margin.name = "TargetContentMargin"
	content_margin.add_theme_constant_override("margin_left", 24)
	content_margin.add_theme_constant_override("margin_top", 50)
	content_margin.add_theme_constant_override("margin_right", 24)
	content_margin.add_theme_constant_override("margin_bottom", 12)
	content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content_margin)
	content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var icon_slot := CenterContainer.new()
	icon_slot.name = "TargetGemCenter"
	icon_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_margin.add_child(icon_slot)
	var icon_aspect := AspectRatioContainer.new()
	icon_aspect.custom_minimum_size = Vector2(80.0, 80.0)
	icon_aspect.ratio = 1.0
	icon_aspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_slot.add_child(icon_aspect)
	target_icon = _gem_texture_rect("TargetGem")
	icon_aspect.add_child(target_icon)
	return panel


func _build_label_badge(node_name: String, text: String, width: float, height: float) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.name = node_name
	badge.custom_minimum_size = Vector2(width, height)
	badge.add_theme_stylebox_override("panel", UiDesignSystemType.level_badge_style())
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := _label(text, 20, Color.WHITE)
	label.name = "Label"
	_decorate_header_label(label)
	badge.add_child(label)
	return badge


func _build_settings_button() -> TextureButton:
	var button := TextureButton.new()
	button.name = "SettingsButton"
	button.custom_minimum_size = Vector2.ONE * UiDesignSystemType.MIN_TOUCH_TARGET
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	var icon_texture := UiDesignSystemType.atlas(AssetCatalogType.HUD_BUTTON_SHEET, AssetCatalogType.HUD_SETTINGS_BUTTON_REGION)
	button.texture_normal = icon_texture
	button.texture_hover = icon_texture
	button.texture_pressed = icon_texture
	button.texture_disabled = icon_texture
	button.tooltip_text = "Pause"
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(func() -> void: settings_requested.emit())
	button.button_down.connect(_on_settings_button_down)
	button.button_up.connect(_on_settings_button_up)
	return button


func _build_pause_popup() -> void:
	pause_blocker = Control.new()
	pause_blocker.name = "PauseInputBlocker"
	pause_blocker.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_blocker.visible = false
	root_control.add_child(pause_blocker)
	pause_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_dimmer = ColorRect.new()
	pause_dimmer.name = "PauseDimmer"
	pause_dimmer.color = UiDesignSystemType.COLOR_OVERLAY
	pause_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_blocker.add_child(pause_dimmer)
	pause_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_safe_margin = MarginContainer.new()
	pause_safe_margin.name = "PauseSafeArea"
	pause_safe_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_blocker.add_child(pause_safe_margin)
	pause_safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_safe_margin.add_child(center)
	pause_panel = NinePatchRect.new()
	pause_panel.name = "PausePanel"
	pause_panel.custom_minimum_size = Vector2(438.0, 468.0)
	UiDesignSystemType.configure_nine_patch(pause_panel, UiDesignSystemType.atlas(AssetCatalogType.HUD_BUTTON_SHEET, AssetCatalogType.HUD_WHITE_PANEL_REGION), 64, 64)
	pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(pause_panel)
	var margin := MarginContainer.new()
	margin.name = "PauseContentMargin"
	margin.add_theme_constant_override("margin_left", 52)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_right", 52)
	margin.add_theme_constant_override("margin_bottom", 42)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_panel.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.name = "PauseActions"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	var title := _label("PAUSED", 46, UiDesignSystemType.COLOR_CORAL)
	title.name = "PauseTitle"
	title.custom_minimum_size = Vector2(0.0, 66.0)
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", UiDesignSystemType.COLOR_CREAM)
	column.add_child(title)
	var subtitle := _label("TAKE A BREATHER", 16, UiDesignSystemType.COLOR_TEXT_MUTED)
	subtitle.name = "PauseSubtitle"
	subtitle.custom_minimum_size = Vector2(0.0, 28.0)
	column.add_child(subtitle)
	var divider_center := CenterContainer.new()
	divider_center.custom_minimum_size = Vector2(0.0, 2.0)
	divider_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(divider_center)
	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(210.0, 2.0)
	divider.color = Color(UiDesignSystemType.COLOR_GOLD, 0.55)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider_center.add_child(divider)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 6.0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(spacer)
	resume_button = _button("ResumeButton", "RESUME", Vector2(310.0, 76.0), "")
	resume_button.tooltip_text = "Continue playing"
	resume_button.pressed.connect(func() -> void: resume_requested.emit())
	column.add_child(resume_button)
	restart_button = _button("PauseRestartButton", "RESTART", Vector2(310.0, 76.0), "SecondaryButton")
	restart_button.tooltip_text = "Restart Level 1"
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	column.add_child(restart_button)


func _button(node_name: String, text: String, minimum: Vector2, variation: StringName) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = minimum
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	if not variation.is_empty():
		button.theme_type_variation = variation
	return button


func _gem_texture_rect(node_name: String) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = node_name
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


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


func _decorate_header_label(label: Label) -> void:
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", UiDesignSystemType.COLOR_CORAL_DARK)


func _score_font_size(formatted: String) -> int:
	if formatted.length() <= 4:
		return 34
	if formatted.length() <= 6:
		return 30
	return 26


func _animate_score_change() -> void:
	_kill_tween(_score_tween)
	score_label.pivot_offset = _node_center(score_label)
	score_label.scale = Vector2.ONE * 0.90
	if not is_inside_tree():
		score_label.scale = Vector2.ONE
		return
	_score_tween = create_tween()
	_score_tween.tween_property(score_label, "scale", Vector2.ONE, UiDesignSystemType.VALUE_CHANGE_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _animate_next_swap() -> void:
	_kill_tween(_next_tween)
	next_icon.pivot_offset = _node_center(next_icon)
	next_icon.scale = Vector2.ONE * 0.82
	next_icon.modulate = Color(1.0, 1.0, 1.0, 0.35)
	if not is_inside_tree():
		next_icon.scale = Vector2.ONE
		next_icon.modulate = Color.WHITE
		return
	_next_tween = create_tween().set_parallel(true)
	_next_tween.tween_property(next_icon, "scale", Vector2.ONE, UiDesignSystemType.ICON_SWAP_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_next_tween.tween_property(next_icon, "modulate:a", 1.0, UiDesignSystemType.ICON_SWAP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _animate_target_swap() -> void:
	_kill_tween(_target_swap_tween)
	target_icon.pivot_offset = _node_center(target_icon)
	target_icon.scale = Vector2.ONE * 0.84
	target_icon.modulate = Color(1.0, 1.0, 1.0, 0.30)
	if not is_inside_tree():
		target_icon.scale = Vector2.ONE
		target_icon.modulate = Color.WHITE
		return
	_target_swap_tween = create_tween().set_parallel(true)
	_target_swap_tween.tween_property(target_icon, "scale", Vector2.ONE, UiDesignSystemType.ICON_SWAP_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_target_swap_tween.tween_property(target_icon, "modulate:a", 1.0, UiDesignSystemType.ICON_SWAP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_settings_button_down() -> void:
	_animate_settings_scale(0.92, UiDesignSystemType.BUTTON_PRESS_DURATION)


func _on_settings_button_up() -> void:
	_animate_settings_scale(1.0, UiDesignSystemType.BUTTON_RELEASE_DURATION)


func _animate_settings_scale(value: float, duration: float) -> void:
	_kill_tween(_settings_tween)
	settings_button.pivot_offset = _node_center(settings_button)
	if not is_inside_tree():
		settings_button.scale = Vector2.ONE * value
		return
	_settings_tween = create_tween()
	_settings_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_settings_tween.tween_property(settings_button, "scale", Vector2.ONE * value, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _finish_hide_pause() -> void:
	pause_blocker.visible = false
	pause_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_panel.scale = Vector2.ONE
	pause_panel.modulate = Color.WHITE
	pause_dimmer.color = UiDesignSystemType.COLOR_OVERLAY


func _refresh_safe_margins() -> void:
	if hud_margin == null or not is_inside_tree():
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_layout_scale = minf(1.0, viewport_size.x / UiDesignSystemType.DESIGN_WIDTH)
	hud_canvas.scale = Vector2.ONE * _layout_scale
	hud_canvas.position = Vector2(maxf(0.0, (viewport_size.x - UiDesignSystemType.DESIGN_WIDTH * _layout_scale) * 0.5), 0.0)
	var insets := _safe_insets()
	var base_margin := UiDesignSystemType.HUD_NARROW_MARGIN if viewport_size.x < UiDesignSystemType.DESIGN_WIDTH else UiDesignSystemType.HUD_MARGIN
	var inverse_scale := 1.0 / maxf(0.01, _layout_scale)
	hud_margin.add_theme_constant_override("margin_left", int(ceil(maxf(base_margin, insets.x * inverse_scale + UiDesignSystemType.SAFE_INSET_PADDING))))
	hud_margin.add_theme_constant_override("margin_top", int(ceil(maxf(base_margin, insets.y * inverse_scale + UiDesignSystemType.SAFE_INSET_PADDING))))
	hud_margin.add_theme_constant_override("margin_right", int(ceil(maxf(base_margin, insets.z * inverse_scale + UiDesignSystemType.SAFE_INSET_PADDING))))
	var design_height := viewport_size.y * inverse_scale
	var board_top := GameConfig.BOARD_TOP + maxf(0.0, design_height - GameConfig.VIEWPORT_SIZE.y)
	var target_y := maxf(178.0, board_top - target_anchor.custom_minimum_size.y - UiDesignSystemType.TARGET_TABLE_GAP)
	target_anchor.position = Vector2(0.0, target_y)
	target_anchor.size = Vector2(UiDesignSystemType.DESIGN_WIDTH, target_anchor.custom_minimum_size.y)
	_apply_safe_margin(pause_safe_margin, insets)


func _safe_insets() -> Vector4:
	if _safe_insets_override.x >= 0.0:
		return _safe_insets_override
	if get_viewport() != get_tree().root:
		return Vector4.ZERO
	return UiDesignSystemType.safe_insets(get_viewport().get_visible_rect().size, Vector2(DisplayServer.window_get_size()), DisplayServer.get_display_safe_area())


func _apply_safe_margin(margin: MarginContainer, insets: Vector4) -> void:
	if margin == null:
		return
	margin.add_theme_constant_override("margin_left", int(ceil(maxf(16.0, insets.x + UiDesignSystemType.SAFE_INSET_PADDING))))
	margin.add_theme_constant_override("margin_top", int(ceil(maxf(16.0, insets.y + UiDesignSystemType.SAFE_INSET_PADDING))))
	margin.add_theme_constant_override("margin_right", int(ceil(maxf(16.0, insets.z + UiDesignSystemType.SAFE_INSET_PADDING))))
	margin.add_theme_constant_override("margin_bottom", int(ceil(maxf(16.0, insets.w + UiDesignSystemType.SAFE_INSET_PADDING))))


func _node_center(control: Control) -> Vector2:
	var node_size := control.size
	if node_size == Vector2.ZERO:
		node_size = control.custom_minimum_size
	return node_size * 0.5


func _kill_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
