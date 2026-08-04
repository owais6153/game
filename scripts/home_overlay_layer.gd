class_name HomeOverlayLayer
extends CanvasLayer

const AssetCatalogType = preload("res://scripts/asset_catalog.gd")
const ScoreFormatterType = preload("res://scripts/score_formatter.gd")
const UiDesignSystemType = preload("res://scripts/ui_design_system.gd")

signal play_requested

var root_control: Control
var safe_margin: MarginContainer
var content_panel: PanelContainer
var logo_rect: TextureRect
var level_label: Label
var coins_label: Label
var play_button: Button
var tagline_label: Label
var _entrance_tween: Tween
var _safe_insets_override := Vector4(-1.0, -1.0, -1.0, -1.0)

func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_refresh_safe_margins()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_refresh_safe_margins):
		viewport.size_changed.connect(_refresh_safe_margins)

func present(level_number: int, coins: int) -> void:
	_build()
	level_label.text = "LEVEL %d" % level_number
	coins_label.text = ScoreFormatterType.format(coins)
	play_button.text = "PLAY" if level_number <= 1 and coins <= 0 else "CONTINUE"
	play_button.tooltip_text = "%s Level %d" % ["Start" if play_button.text == "PLAY" else "Continue", level_number]
	root_control.visible = true
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	_start_entrance()
	if play_button.is_inside_tree():
		play_button.grab_focus()

func dismiss() -> void:
	_kill_tween()
	if root_control != null:
		root_control.visible = false
		root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_safe_insets_for_testing(insets: Vector4) -> void:
	_safe_insets_override = insets
	_refresh_safe_margins()

func layout_metrics() -> Dictionary:
	_build()
	return {"panel": content_panel.get_global_rect(), "logo": logo_rect.get_global_rect(), "button": play_button.get_global_rect()}

func _build() -> void:
	if root_control != null:
		return
	root_control = Control.new()
	root_control.name = "HomeOverlayRoot"
	root_control.theme = UiDesignSystemType.theme()
	root_control.visible = false
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root_control)
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dimmer := ColorRect.new()
	dimmer.name = "HomeBackdrop"
	dimmer.color = Color(0.02, 0.035, 0.055, 0.72)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(dimmer)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var glow := ColorRect.new()
	glow.name = "HomeWarmGlow"
	glow.color = Color(0.95, 0.55, 0.14, 0.10)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(glow)
	glow.set_anchors_preset(Control.PRESET_TOP_WIDE)
	glow.offset_bottom = 620.0
	safe_margin = MarginContainer.new()
	safe_margin.name = "HomeSafeArea"
	safe_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(safe_margin)
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.name = "HomeCenter"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_margin.add_child(center)
	content_panel = PanelContainer.new()
	content_panel.name = "HomeContentPanel"
	content_panel.custom_minimum_size = Vector2(520.0, 820.0)
	content_panel.add_theme_stylebox_override("panel", UiDesignSystemType.hero_screen_panel_style())
	content_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(content_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 34)
	content_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 13)
	margin.add_child(column)
	var hero := PanelContainer.new()
	hero.name = "LogoHero"
	hero.custom_minimum_size = Vector2(452.0, 354.0)
	hero.clip_contents = true
	hero.add_theme_stylebox_override("panel", UiDesignSystemType.logo_frame_style())
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(hero)
	logo_rect = TextureRect.new()
	logo_rect.name = "GemRushLogo"
	logo_rect.texture = AssetCatalogType.BRAND_LOGO
	logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(logo_rect)
	tagline_label = _label("BUILD THE CHAIN.  CLAIM THE GEMS.", 17, UiDesignSystemType.COLOR_TEXT_MUTED)
	tagline_label.custom_minimum_size = Vector2(0.0, 32.0)
	column.add_child(tagline_label)
	var progress_card := PanelContainer.new()
	progress_card.name = "ContinueCard"
	progress_card.custom_minimum_size = Vector2(452.0, 136.0)
	progress_card.add_theme_stylebox_override("panel", UiDesignSystemType.continue_card_style())
	column.add_child(progress_card)
	var progress_margin := MarginContainer.new()
	progress_margin.add_theme_constant_override("margin_left", 24)
	progress_margin.add_theme_constant_override("margin_top", 14)
	progress_margin.add_theme_constant_override("margin_right", 24)
	progress_margin.add_theme_constant_override("margin_bottom", 14)
	progress_card.add_child(progress_margin)
	var progress_row := HBoxContainer.new()
	progress_row.alignment = BoxContainer.ALIGNMENT_CENTER
	progress_row.add_theme_constant_override("separation", 22)
	progress_margin.add_child(progress_row)
	var level_column := VBoxContainer.new()
	level_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_column.add_child(_label("CURRENT JOURNEY", 14, UiDesignSystemType.COLOR_TEXT_MUTED))
	level_label = _label("LEVEL 1", 31, UiDesignSystemType.COLOR_CORAL)
	level_column.add_child(level_label)
	progress_row.add_child(level_column)
	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(2.0, 70.0)
	divider.color = Color(UiDesignSystemType.COLOR_GOLD, 0.45)
	progress_row.add_child(divider)
	var coin_column := VBoxContainer.new()
	coin_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coin_column.add_child(_label("COINS", 14, UiDesignSystemType.COLOR_TEXT_MUTED))
	coins_label = _label("0", 31, UiDesignSystemType.COLOR_TEAL)
	coin_column.add_child(coins_label)
	progress_row.add_child(coin_column)
	play_button = Button.new()
	play_button.name = "HomePlayButton"
	play_button.text = "PLAY"
	play_button.custom_minimum_size = Vector2(452.0, 82.0)
	play_button.focus_mode = Control.FOCUS_ALL
	play_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	play_button.pressed.connect(func() -> void: play_requested.emit())
	column.add_child(play_button)
	var hint := _label("8 RANDOM GEMS  •  A NEW PATH EVERY LEVEL", 14, UiDesignSystemType.COLOR_TEXT_MUTED)
	hint.custom_minimum_size = Vector2(0.0, 28.0)
	column.add_child(hint)

func _start_entrance() -> void:
	_kill_tween()
	content_panel.pivot_offset = content_panel.size * 0.5
	content_panel.scale = Vector2.ONE * 0.94
	content_panel.modulate = Color(1, 1, 1, 0)
	if not is_inside_tree():
		content_panel.scale = Vector2.ONE
		content_panel.modulate = Color.WHITE
		return
	_entrance_tween = create_tween().set_parallel(true)
	_entrance_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_entrance_tween.tween_property(content_panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_entrance_tween.tween_property(content_panel, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _refresh_safe_margins() -> void:
	if safe_margin == null or not is_inside_tree():
		return
	var insets := _safe_insets()
	for entry in [["left", insets.x], ["top", insets.y], ["right", insets.z], ["bottom", insets.w]]:
		safe_margin.add_theme_constant_override("margin_%s" % entry[0], int(ceil(maxf(18.0, float(entry[1]) + UiDesignSystemType.SAFE_INSET_PADDING))))

func _safe_insets() -> Vector4:
	if _safe_insets_override.x >= 0.0:
		return _safe_insets_override
	if get_viewport() != get_tree().root:
		return Vector4.ZERO
	return UiDesignSystemType.safe_insets(get_viewport().get_visible_rect().size, Vector2(DisplayServer.window_get_size()), DisplayServer.get_display_safe_area())

func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UiDesignSystemType.font())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color(1, 0.97, 0.88, 0.72))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _kill_tween() -> void:
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()
