class_name ResultOverlayLayer
extends CanvasLayer

const AssetCatalogType = preload("res://scripts/asset_catalog.gd")
const ScoreFormatterType = preload("res://scripts/score_formatter.gd")

signal retry_requested

## Dedicated result UI. It owns only its backdrop and panel; gameplay roots,
## gem sprites, and simulation state are never modulated or reparented.
var visible_result := false
var result_won := false
var result_score := 0
var present_count := 0

var root_control: Control
var dimmer: ColorRect
var panel: NinePatchRect
var title_label: Label
var subtitle_label: Label
var result_icon: TextureRect
var score_label: Label
var retry_button: TextureButton
var _font: Font
var _entrance_tween: Tween

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func present(won: bool, score: int) -> bool:
	_build_ui()
	if visible_result:
		return false
	visible_result = true
	result_won = won
	result_score = score
	present_count += 1
	title_label.text = "LEVEL COMPLETE" if won else "TRY AGAIN"
	subtitle_label.text = "FINAL TARGET COLLECTED" if won else "THE TABLE OVERFLOWED"
	result_icon.visible = won
	result_icon.texture = AssetCatalogType.gem_texture(8) if won else null
	score_label.text = "SCORE  %s" % ScoreFormatterType.format(score)
	root_control.visible = true
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	_start_entrance()
	return true

func dismiss() -> void:
	visible_result = false
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()
	if root_control != null:
		root_control.visible = false
		root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if panel != null:
		panel.scale = Vector2.ONE
		panel.modulate = Color.WHITE

func _build_ui() -> void:
	if root_control != null:
		return
	var variation := FontVariation.new()
	variation.base_font = ThemeDB.fallback_font
	variation.variation_embolden = 0.72
	_font = variation
	root_control = Control.new()
	root_control.name = "ResultOverlayRoot"
	root_control.visible = false
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer = ColorRect.new()
	dimmer.name = "ResultDimmer"
	dimmer.color = Color(0.025, 0.03, 0.06, GameConfig.RESULT_BACKDROP_OPACITY)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(dimmer)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = NinePatchRect.new()
	panel.name = "ResultPanel"
	panel.custom_minimum_size = Vector2(506.0, 536.0)
	_configure_nine_patch(panel, _atlas(AssetCatalogType.HUD_BUTTON_SHEET, AssetCatalogType.HUD_WHITE_PANEL_REGION), 64)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 58)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_right", 58)
	margin.add_theme_constant_override("margin_bottom", 46)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 10)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	title_label = _label("LEVEL COMPLETE", 39, Color("ff665b"))
	title_label.custom_minimum_size = Vector2(0.0, 62.0)
	title_label.add_theme_constant_override("outline_size", 6)
	title_label.add_theme_color_override("font_outline_color", Color("fff3df"))
	column.add_child(title_label)
	subtitle_label = _label("FINAL TARGET COLLECTED", 16, Color("9c674e"))
	column.add_child(subtitle_label)
	var icon_aspect := AspectRatioContainer.new()
	icon_aspect.name = "ResultGemSlot"
	icon_aspect.custom_minimum_size = Vector2(154.0, 154.0)
	icon_aspect.ratio = 1.0
	icon_aspect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_aspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(icon_aspect)
	result_icon = TextureRect.new()
	result_icon.name = "ResultGem"
	result_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_aspect.add_child(result_icon)
	score_label = _label("SCORE  0", 31, Color("198d98"))
	score_label.custom_minimum_size = Vector2(0.0, 56.0)
	column.add_child(score_label)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 10.0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(spacer)
	retry_button = TextureButton.new()
	retry_button.name = "RetryButton"
	retry_button.custom_minimum_size = Vector2(326.0, 86.0)
	retry_button.ignore_texture_size = true
	retry_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	retry_button.texture_normal = _atlas(AssetCatalogType.HUD_BUTTON_SHEET, AssetCatalogType.HUD_GOAL_HEADER_REGION)
	retry_button.focus_mode = Control.FOCUS_ALL
	retry_button.mouse_filter = Control.MOUSE_FILTER_STOP
	retry_button.pressed.connect(func() -> void: retry_requested.emit())
	column.add_child(retry_button)
	var retry_label := _label("RETRY", 31, Color.WHITE)
	retry_label.add_theme_constant_override("outline_size", 6)
	retry_label.add_theme_color_override("font_outline_color", Color("a84c3d"))
	retry_button.add_child(retry_label)
	retry_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _start_entrance() -> void:
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()
	panel.pivot_offset = panel.size * 0.5
	if not is_inside_tree():
		panel.scale = Vector2.ONE
		panel.modulate = Color.WHITE
		dimmer.color.a = GameConfig.RESULT_BACKDROP_OPACITY
		return
	panel.scale = Vector2.ONE * 0.88
	panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var dim_color := dimmer.color
	dimmer.color = Color(dim_color.r, dim_color.g, dim_color.b, 0.0)
	_entrance_tween = create_tween().set_parallel(true)
	_entrance_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_entrance_tween.tween_property(panel, "scale", Vector2.ONE, GameConfig.OVERLAY_FADE_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_entrance_tween.tween_property(panel, "modulate:a", 1.0, GameConfig.OVERLAY_FADE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_entrance_tween.tween_property(dimmer, "color:a", GameConfig.RESULT_BACKDROP_OPACITY, GameConfig.OVERLAY_FADE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

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

func _configure_nine_patch(node: NinePatchRect, texture: Texture2D, margin: int) -> void:
	node.texture = texture
	node.set_patch_margin(SIDE_LEFT, margin)
	node.set_patch_margin(SIDE_TOP, margin)
	node.set_patch_margin(SIDE_RIGHT, margin)
	node.set_patch_margin(SIDE_BOTTOM, margin)

func _atlas(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas
