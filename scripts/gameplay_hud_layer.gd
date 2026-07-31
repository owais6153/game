class_name GameplayHudLayer
extends CanvasLayer

const AssetCatalogType = preload("res://scripts/asset_catalog.gd")
const ScoreFormatterType = preload("res://scripts/score_formatter.gd")
const SNAPSHOT_KEYS := ["level_number", "current_level", "next_level", "score", "target_level", "target_progress", "target_quantity", "target_collecting", "target_completed"]

signal settings_requested
signal resume_requested
signal restart_requested

var root_control: Control
var hud_margin: MarginContainer
var score_panel: Control
var score_label: Label
var progression_frames: Array[PanelContainer] = []
var progression_icons: Array[TextureRect] = []
var next_panel: Control
var next_icon: TextureRect
var level_label: Label
var target_panel: Control
var target_icon: TextureRect
var target_name_label: Label
var target_status_label: Label
var target_progress_bar: ProgressBar
var settings_button: TextureButton
var pause_blocker: Control
var pause_panel: NinePatchRect
var resume_button: TextureButton
var restart_button: TextureButton

var _built := false
var _snapshot: Dictionary = {}
var _font: Font
var _progress_style: StyleBoxFlat
var _progress_active_style: StyleBoxFlat
var _target_pulse_elapsed := -1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 40
	_build_once()
	_refresh_safe_margins()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_refresh_safe_margins):
		viewport.size_changed.connect(_refresh_safe_margins)

func _process(delta: float) -> void:
	if _target_pulse_elapsed < 0.0 or target_panel == null:
		return
	if is_inside_tree() and get_tree().paused:
		return
	_target_pulse_elapsed += delta
	var t := clampf(_target_pulse_elapsed / GameConfig.TARGET_PANEL_PULSE_DURATION, 0.0, 1.0)
	var pulse := 1.0 + sin(t * PI) * 0.08
	target_panel.pivot_offset = target_panel.size * 0.5
	target_panel.scale = Vector2.ONE * pulse
	if t >= 1.0:
		target_panel.scale = Vector2.ONE
		_target_pulse_elapsed = -1.0

func update_snapshot(snapshot: Dictionary) -> void:
	_build_once()
	if _snapshot_matches(snapshot):
		return
	var formatted_score := ScoreFormatterType.format(int(snapshot.get("score", 0)))
	if score_label.text != formatted_score:
		score_label.text = formatted_score
		score_label.add_theme_font_size_override("font_size", _score_font_size(formatted_score))
	var next_level := int(snapshot.get("next_level", 1))
	if int(_snapshot.get("next_level", -1)) != next_level:
		next_icon.texture = AssetCatalogType.gem_texture(next_level)
	var current_level := int(snapshot.get("current_level", 1))
	if int(_snapshot.get("current_level", -1)) != current_level:
		for index in range(progression_frames.size()):
			progression_frames[index].add_theme_stylebox_override("panel", _progress_active_style if index + 1 == current_level else _progress_style)
	var target_level := int(snapshot.get("target_level", 1))
	if int(_snapshot.get("target_level", -1)) != target_level:
		target_icon.texture = AssetCatalogType.gem_texture(target_level)
		target_name_label.text = AssetCatalogType.gem_name(target_level).to_upper()
	var level_number := int(snapshot.get("level_number", 1))
	level_label.text = "LEVEL %d" % level_number
	var quantity := maxi(1, int(snapshot.get("target_quantity", 1)))
	var progress := int(snapshot.get("target_progress", 0))
	var collecting := bool(snapshot.get("target_collecting", false))
	var completed := bool(snapshot.get("target_completed", false))
	target_progress_bar.max_value = quantity
	target_progress_bar.value = quantity if completed else mini(quantity, progress + (1 if collecting else 0))
	target_status_label.text = "COMPLETE" if completed else ("COLLECTING" if collecting else "MAKE ×%d" % quantity)
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
	pause_blocker.visible = true
	pause_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	if is_inside_tree():
		resume_button.grab_focus()

func hide_pause() -> void:
	if not _built:
		return
	pause_blocker.visible = false
	pause_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE

func is_pause_visible() -> bool:
	return _built and pause_blocker.visible

func pulse_target() -> void:
	_target_pulse_elapsed = 0.0

func target_collection_destination() -> Vector2:
	if target_icon == null or not target_icon.is_inside_tree():
		return GameConfig.TARGET_COLLECTION_DESTINATION
	return target_icon.get_global_rect().get_center()

func reset_presentation() -> void:
	hide_pause()
	_target_pulse_elapsed = -1.0
	if target_panel != null:
		target_panel.scale = Vector2.ONE

func layout_metrics() -> Dictionary:
	_build_once()
	return {
		"score": score_panel.get_global_rect(),
		"next": next_panel.get_global_rect(),
		"target": target_panel.get_global_rect(),
		"settings": settings_button.get_global_rect(),
		"pause": pause_panel.get_global_rect(),
	}

func _build_once() -> void:
	if _built:
		return
	_built = true
	_font = _make_ui_font()
	_progress_style = _make_progress_style(Color("f4ae32"), 3)
	_progress_active_style = _make_progress_style(Color("ff765f"), 5)
	root_control = Control.new()
	root_control.name = "GameplayUIRoot"
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_hud()
	_build_pause_popup()

func _build_hud() -> void:
	hud_margin = MarginContainer.new()
	hud_margin.name = "SafeHudMargin"
	hud_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud_margin.offset_bottom = 350.0
	hud_margin.add_theme_constant_override("margin_left", 24)
	hud_margin.add_theme_constant_override("margin_top", 24)
	hud_margin.add_theme_constant_override("margin_right", 24)
	root_control.add_child(hud_margin)
	var rows := VBoxContainer.new()
	rows.name = "HudRows"
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation", 8)
	hud_margin.add_child(rows)

	var main_row := HBoxContainer.new()
	main_row.name = "MainRow"
	main_row.custom_minimum_size = Vector2(0.0, 198.0)
	main_row.add_theme_constant_override("separation", 10)
	main_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_child(main_row)
	score_panel = _build_score_panel()
	score_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	main_row.add_child(score_panel)
	var progression_center := CenterContainer.new()
	progression_center.name = "ProgressionCenter"
	progression_center.custom_minimum_size = Vector2(276.0, 88.0)
	progression_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progression_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	progression_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_row.add_child(progression_center)
	progression_center.add_child(_build_progression_strip())
	next_panel = _build_next_panel()
	next_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	main_row.add_child(next_panel)

	var objective_row := HBoxContainer.new()
	objective_row.name = "ObjectiveRow"
	objective_row.custom_minimum_size = Vector2(0.0, 106.0)
	objective_row.alignment = BoxContainer.ALIGNMENT_CENTER
	objective_row.add_theme_constant_override("separation", 18)
	objective_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_child(objective_row)
	var level_slot := CenterContainer.new()
	level_slot.custom_minimum_size = Vector2(132.0, 88.0)
	level_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_row.add_child(level_slot)
	level_slot.add_child(_build_level_chip())
	target_panel = _build_target_panel()
	objective_row.add_child(target_panel)
	var settings_slot := CenterContainer.new()
	settings_slot.custom_minimum_size = Vector2(132.0, 88.0)
	settings_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_row.add_child(settings_slot)
	settings_button = TextureButton.new()
	settings_button.name = "SettingsButton"
	settings_button.custom_minimum_size = Vector2(88.0, 88.0)
	settings_button.ignore_texture_size = true
	settings_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	settings_button.texture_normal = _atlas(AssetCatalogType.HUD_BUTTON_SHEET, AssetCatalogType.HUD_SETTINGS_BUTTON_REGION)
	settings_button.tooltip_text = "Pause and settings"
	settings_button.focus_mode = Control.FOCUS_ALL
	settings_button.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_button.pressed.connect(func() -> void: settings_requested.emit())
	settings_slot.add_child(settings_button)

func _build_score_panel() -> Control:
	var panel := Control.new()
	panel.name = "ScorePanel"
	panel.custom_minimum_size = Vector2(188.0, 121.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var skin := TextureRect.new()
	skin.texture = _atlas(AssetCatalogType.HUD_BUTTON_SHEET, AssetCatalogType.HUD_SCORE_PANEL_REGION)
	skin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	skin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(skin)
	skin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	score_label = _label("0", 44, Color("633510"))
	score_label.name = "ScoreValue"
	margin.add_child(score_label)
	return panel

func _build_next_panel() -> Control:
	var panel := Control.new()
	panel.name = "NextPanel"
	panel.custom_minimum_size = Vector2(178.0, 198.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var skin := TextureRect.new()
	skin.texture = _atlas(AssetCatalogType.HUD_BUTTON_SHEET, AssetCatalogType.HUD_NEXT_PANEL_REGION)
	skin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	skin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(skin)
	skin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Keep a real contain box inside the supplied NEXT frame. The padding is
	# deliberately symmetric enough for wide, tall, and irregular gem artwork.
	margin.add_theme_constant_override("margin_left", 50)
	margin.add_theme_constant_override("margin_top", 90)
	margin.add_theme_constant_override("margin_right", 50)
	margin.add_theme_constant_override("margin_bottom", 34)
	panel.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var aspect := AspectRatioContainer.new()
	aspect.ratio = 1.0
	aspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(aspect)
	next_icon = _gem_texture_rect("NextGem")
	aspect.add_child(next_icon)
	return panel

func _build_progression_strip() -> HBoxContainer:
	var strip := HBoxContainer.new()
	strip.name = "ProgressionStrip"
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 0)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for tier in range(1, 6):
		var frame := PanelContainer.new()
		frame.name = "ProgressionSlot%d" % tier
		frame.custom_minimum_size = Vector2(48.0, 48.0)
		frame.add_theme_stylebox_override("panel", _progress_style)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var inset := MarginContainer.new()
		inset.add_theme_constant_override("margin_left", 5)
		inset.add_theme_constant_override("margin_top", 5)
		inset.add_theme_constant_override("margin_right", 5)
		inset.add_theme_constant_override("margin_bottom", 5)
		inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(inset)
		var icon := _gem_texture_rect("ProgressionGem%d" % tier)
		icon.texture = AssetCatalogType.gem_texture(tier)
		inset.add_child(icon)
		strip.add_child(frame)
		progression_frames.append(frame)
		progression_icons.append(icon)
		if tier < 5:
			var connector_center := CenterContainer.new()
			connector_center.custom_minimum_size = Vector2(12.0, 48.0)
			connector_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var connector := ColorRect.new()
			connector.custom_minimum_size = Vector2(12.0, 4.0)
			connector.color = Color("ed9d2e")
			connector.mouse_filter = Control.MOUSE_FILTER_IGNORE
			connector_center.add_child(connector)
			strip.add_child(connector_center)
	return strip

func _build_level_chip() -> Control:
	var chip := Control.new()
	chip.name = "LevelChip"
	chip.custom_minimum_size = Vector2(126.0, 50.0)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var skin := NinePatchRect.new()
	_configure_nine_patch(skin, _atlas(AssetCatalogType.HUD_BUTTON_SHEET, AssetCatalogType.HUD_GOAL_HEADER_REGION), 44, 20)
	chip.add_child(skin)
	skin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	level_label = _label("LEVEL 1", 20, Color.WHITE)
	level_label.add_theme_constant_override("outline_size", 5)
	level_label.add_theme_color_override("font_outline_color", Color("a84c3d"))
	chip.add_child(level_label)
	level_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return chip

func _build_target_panel() -> Control:
	var panel := Control.new()
	panel.name = "ActiveTargetPanel"
	panel.custom_minimum_size = Vector2(288.0, 104.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var body := NinePatchRect.new()
	body.name = "TargetBodySkin"
	_configure_nine_patch(body, _atlas(AssetCatalogType.HUD_BUTTON_SHEET, AssetCatalogType.HUD_WHITE_PANEL_REGION), 52, 32)
	panel.add_child(body)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var header := NinePatchRect.new()
	header.name = "TargetHeaderSkin"
	_configure_nine_patch(header, _atlas(AssetCatalogType.HUD_BUTTON_SHEET, AssetCatalogType.HUD_GOAL_HEADER_REGION), 44, 18)
	header.set_anchors_preset(Control.PRESET_CENTER_TOP)
	header.offset_left = -82.0
	header.offset_top = -4.0
	header.offset_right = 82.0
	header.offset_bottom = 39.0
	panel.add_child(header)
	var header_label := _label("GOAL", 22, Color.WHITE)
	header_label.add_theme_constant_override("outline_size", 5)
	header_label.add_theme_color_override("font_outline_color", Color("a84c3d"))
	header.add_child(header_label)
	header_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var content_margin := MarginContainer.new()
	content_margin.name = "TargetContentMargin"
	content_margin.add_theme_constant_override("margin_left", 18)
	content_margin.add_theme_constant_override("margin_top", 35)
	content_margin.add_theme_constant_override("margin_right", 18)
	content_margin.add_theme_constant_override("margin_bottom", 10)
	content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content_margin)
	content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_margin.add_child(row)
	var icon_slot := CenterContainer.new()
	icon_slot.custom_minimum_size = Vector2(70.0, 54.0)
	icon_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon_slot)
	var icon_aspect := AspectRatioContainer.new()
	icon_aspect.custom_minimum_size = Vector2(52.0, 52.0)
	icon_aspect.ratio = 1.0
	icon_aspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_slot.add_child(icon_aspect)
	target_icon = _gem_texture_rect("TargetGem")
	icon_aspect.add_child(target_icon)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.alignment = BoxContainer.ALIGNMENT_CENTER
	details.add_theme_constant_override("separation", 2)
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(details)
	target_name_label = _label("RUBY", 19, Color("603a24"))
	target_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	details.add_child(target_name_label)
	target_status_label = _label("MAKE ×1", 14, Color("bb654c"))
	target_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	details.add_child(target_status_label)
	target_progress_bar = ProgressBar.new()
	target_progress_bar.name = "TargetProgress"
	target_progress_bar.custom_minimum_size = Vector2(0.0, 9.0)
	target_progress_bar.show_percentage = false
	target_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var progress_background := StyleBoxFlat.new()
	progress_background.bg_color = Color("eadbc2")
	progress_background.corner_radius_top_left = 5
	progress_background.corner_radius_top_right = 5
	progress_background.corner_radius_bottom_left = 5
	progress_background.corner_radius_bottom_right = 5
	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = Color("ff765f")
	progress_fill.corner_radius_top_left = 5
	progress_fill.corner_radius_top_right = 5
	progress_fill.corner_radius_bottom_left = 5
	progress_fill.corner_radius_bottom_right = 5
	target_progress_bar.add_theme_stylebox_override("background", progress_background)
	target_progress_bar.add_theme_stylebox_override("fill", progress_fill)
	details.add_child(target_progress_bar)
	return panel

func _build_pause_popup() -> void:
	pause_blocker = Control.new()
	pause_blocker.name = "PauseInputBlocker"
	pause_blocker.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_blocker.visible = false
	root_control.add_child(pause_blocker)
	pause_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dimmer := ColorRect.new()
	dimmer.name = "PauseDimmer"
	dimmer.color = Color(0.03, 0.04, 0.07, 0.56)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_blocker.add_child(dimmer)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_blocker.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel = NinePatchRect.new()
	pause_panel.name = "PausePanel"
	pause_panel.custom_minimum_size = Vector2(438.0, 454.0)
	_configure_nine_patch(pause_panel, _atlas(AssetCatalogType.HUD_BUTTON_SHEET, AssetCatalogType.HUD_WHITE_PANEL_REGION), 64, 64)
	pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(pause_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 54)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_right", 54)
	margin.add_theme_constant_override("margin_bottom", 42)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_panel.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	var title := _label("PAUSE", 48, Color("ff665b"))
	title.custom_minimum_size = Vector2(0.0, 76.0)
	title.add_theme_constant_override("outline_size", 7)
	title.add_theme_color_override("font_outline_color", Color("fff3df"))
	column.add_child(title)
	var subtitle := _label("GAMEPLAY PAUSED", 17, Color("8a5d49"))
	column.add_child(subtitle)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 24.0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(spacer)
	resume_button = _textured_text_button("ResumeButton", _atlas(AssetCatalogType.HUD_BUTTON_SHEET, AssetCatalogType.HUD_GOAL_HEADER_REGION), "RESUME", Vector2(300.0, 82.0), 30)
	resume_button.pressed.connect(func() -> void: resume_requested.emit())
	column.add_child(resume_button)
	restart_button = TextureButton.new()
	restart_button.name = "PauseRestartButton"
	restart_button.custom_minimum_size = Vector2(300.0, 78.0)
	restart_button.ignore_texture_size = true
	restart_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	restart_button.texture_normal = _atlas(AssetCatalogType.HUD_RESTART_ART, AssetCatalogType.HUD_RESTART_BUTTON_REGION)
	restart_button.tooltip_text = "Restart level"
	restart_button.focus_mode = Control.FOCUS_ALL
	restart_button.mouse_filter = Control.MOUSE_FILTER_STOP
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	column.add_child(restart_button)

func _textured_text_button(node_name: String, texture: Texture2D, text: String, minimum: Vector2, font_size: int) -> TextureButton:
	var button := TextureButton.new()
	button.name = node_name
	button.custom_minimum_size = minimum
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_normal = texture
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	var label := _label(text, font_size, Color.WHITE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color("a84c3d"))
	button.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color(1.0, 0.96, 0.86, 0.75))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _make_ui_font() -> Font:
	var variation := FontVariation.new()
	variation.base_font = ThemeDB.fallback_font
	variation.variation_embolden = 0.72
	return variation

func _make_progress_style(border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff8e9")
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 24
	style.corner_radius_bottom_right = 24
	style.shadow_color = Color(0.32, 0.18, 0.05, 0.18)
	style.shadow_size = 3
	return style

func _configure_nine_patch(node: NinePatchRect, texture: Texture2D, horizontal_margin: int, vertical_margin: int) -> void:
	node.texture = texture
	node.set_patch_margin(SIDE_LEFT, horizontal_margin)
	node.set_patch_margin(SIDE_TOP, vertical_margin)
	node.set_patch_margin(SIDE_RIGHT, horizontal_margin)
	node.set_patch_margin(SIDE_BOTTOM, vertical_margin)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _atlas(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas

func _score_font_size(formatted: String) -> int:
	if formatted.length() <= 4:
		return 44
	if formatted.length() <= 6:
		return 39
	return 34

func _refresh_safe_margins() -> void:
	if hud_margin == null or not is_inside_tree():
		return
	var window_size := Vector2(DisplayServer.window_get_size())
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return
	var safe := DisplayServer.get_display_safe_area()
	var scale_to_canvas := Vector2(viewport_size.x / window_size.x, viewport_size.y / window_size.y)
	var safe_left := clampf(float(safe.position.x) * scale_to_canvas.x, 0.0, 80.0)
	var safe_top := clampf(float(safe.position.y) * scale_to_canvas.y, 0.0, 80.0)
	var safe_right := clampf(float(window_size.x - safe.end.x) * scale_to_canvas.x, 0.0, 80.0)
	hud_margin.add_theme_constant_override("margin_left", int(ceil(maxf(24.0, safe_left + 16.0))))
	hud_margin.add_theme_constant_override("margin_top", int(ceil(maxf(24.0, safe_top + 16.0))))
	hud_margin.add_theme_constant_override("margin_right", int(ceil(maxf(24.0, safe_right + 16.0))))
