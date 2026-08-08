class_name UiDesignSystem
extends RefCounted

## Shared production UI tokens and cached Theme resource. Values in this file
## are presentation-only and must never enter simulation or table geometry.

const DESIGN_WIDTH := 720.0

const COLOR_CREAM := Color("fff9ec")
const COLOR_CREAM_DEEP := Color("f3e5cc")
const COLOR_CORAL := Color("ff715f")
const COLOR_CORAL_LIGHT := Color("ff8d7e")
const COLOR_CORAL_DARK := Color("d84d43")
const COLOR_TEAL := Color("1699a5")
const COLOR_TEAL_DARK := Color("08727e")
const COLOR_GOLD := Color("f4ae32")
const COLOR_GOLD_LIGHT := Color("ffd46d")
const COLOR_PURPLE_DEEP := Color("35134f")
const COLOR_PURPLE_DARK := Color("42166f")
const COLOR_PURPLE := Color("6930aa")
const COLOR_PURPLE_LIGHT := Color("9b62da")
const COLOR_PURPLE_VIVID := Color("7f3dcc")
const COLOR_LAVENDER := Color("d8c0ee")
const COLOR_LAVENDER_LIGHT := Color("f0e3fb")
const COLOR_GLASS := Color(0.34, 0.12, 0.56, 0.76)
const COLOR_GLASS_SOFT := Color(0.54, 0.30, 0.74, 0.62)
const COLOR_GLASS_HIGHLIGHT := Color(0.94, 0.84, 1.0, 0.84)
const COLOR_TEXT := Color("173451")
const COLOR_TEXT_MUTED := Color("55758d")
const COLOR_TRACK := Color(0.18, 0.12, 0.24, 0.34)
const COLOR_DISABLED := Color("b9afa1")
const COLOR_OVERLAY := Color(0.025, 0.04, 0.06, 0.56)

# Light frosted-glass gameplay palette, adapted from StyleBoxFancy demo Panel8.
const COLOR_BLUE_DEEP := Color("123f78")
const COLOR_BLUE := Color("3f9ed8")
const COLOR_BLUE_LIGHT := Color("9de8fb")
const COLOR_BLUE_PALE := Color("eafaff")
const COLOR_GLASS_WHITE := Color(0.97, 0.995, 1.0, 0.78)
const COLOR_GLASS_BLUE := Color(0.60, 0.90, 0.98, 0.72)
const COLOR_GLASS_BORDER := Color(0.78, 0.95, 1.0, 0.88)
const COLOR_GLASS_SHADOW := Color(0.04, 0.18, 0.34, 0.28)

const HUD_MARGIN := 24
const HUD_NARROW_MARGIN := 16
const SAFE_INSET_PADDING := 10
const ROW_GAP := 12
const ITEM_GAP := 8
const PANEL_PADDING := 16
const HUD_SHELL_PADDING := 8
const SMALL_GAP := 6
const LARGE_GAP := 16
const PANEL_CORNER_RADIUS := 26
const PANEL_BORDER_WIDTH := 2
const BUTTON_CORNER_RADIUS := 24
const BUTTON_BORDER_WIDTH := 3
const MIN_TOUCH_TARGET := 88.0
const TARGET_TABLE_GAP := 28.0
const HUD_ICON_SIZE := 58.0
const PROGRESSION_ICON_SIZE := 48.0
const TARGET_ICON_SIZE := 72.0
const NEXT_ICON_SIZE := 52.0
const HEADER_HEIGHT := 172.0
const UTILITY_ROW_HEIGHT := 116.0
const TOP_UTILITY_HEIGHT := 96.0
const TOP_STATUS_HEIGHT := 64.0
const TOP_ROW_GAP := 8.0
const TOP_HUD_HEIGHT := TOP_UTILITY_HEIGHT + TOP_STATUS_HEIGHT + TOP_ROW_GAP
const PROGRESSION_HEIGHT := 54.0
const OBJECTIVE_GAP := 14.0
const SCORE_PANEL_SIZE := Vector2(156.0, 96.0)
const NEXT_PANEL_SIZE := Vector2(132.0, 96.0)
const TARGET_PANEL_SIZE := Vector2(336.0, 112.0)

const TITLE_FONT_SIZE := 42
const POPUP_TITLE_FONT_SIZE := 40
const PANEL_TITLE_FONT_SIZE := 21
const BODY_FONT_SIZE := 18
const SMALL_FONT_SIZE := 15
const BUTTON_FONT_SIZE := 28
const SCORE_FONT_SIZE := 44

const BUTTON_PRESS_DURATION := 0.07
const BUTTON_RELEASE_DURATION := 0.11
const VALUE_CHANGE_DURATION := 0.16
const ICON_SWAP_DURATION := 0.16
const TARGET_PULSE_DURATION := 0.22
const POPUP_ENTER_DURATION := 0.20
const POPUP_EXIT_DURATION := 0.14

static var _theme_cache: Theme
static var _font_cache: Font


static func theme() -> Theme:
	if _theme_cache != null:
		return _theme_cache
	var result := Theme.new()
	result.default_font = font()
	result.default_font_size = BODY_FONT_SIZE
	result.set_font("font", "Label", font())
	result.set_color("font_color", "Label", COLOR_TEXT)
	result.set_font_size("font_size", "Label", BODY_FONT_SIZE)

	_configure_primary_button(result, "Button")
	result.set_type_variation("SecondaryButton", "Button")
	_configure_secondary_button(result, "SecondaryButton")

	result.set_stylebox("panel", "PanelContainer", panel_style())
	result.set_stylebox("background", "ProgressBar", progress_background_style())
	result.set_stylebox("fill", "ProgressBar", progress_fill_style())
	_theme_cache = result
	return _theme_cache


static func font() -> Font:
	if _font_cache != null:
		return _font_cache
	var variation := FontVariation.new()
	variation.base_font = ThemeDB.fallback_font
	variation.variation_embolden = 0.72
	_font_cache = variation
	return _font_cache


static func panel_style() -> StyleBoxFlat:
	return _rounded_style(COLOR_CREAM, Color("e9c88a"), PANEL_BORDER_WIDTH, PANEL_CORNER_RADIUS, 8, Color(0.18, 0.10, 0.04, 0.22))


static func hud_content_style() -> StyleBoxFlat:
	return _rounded_style(Color("fffdf7"), Color("e3c27b"), 2, 22, 3, Color(0.22, 0.12, 0.04, 0.16))


static func simple_hud_panel_style() -> StyleBoxFlat:
	return _rounded_style(Color(1.0, 0.985, 0.95, 0.97), COLOR_LAVENDER, 2, 22, 5, Color(0.10, 0.03, 0.18, 0.24))


static func _glass_gradient(top: Color, bottom: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CUBIC
	gradient.offsets = PackedFloat32Array([0.0, 0.52, 1.0])
	gradient.colors = PackedColorArray([top, top.lerp(bottom, 0.38), bottom])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	return texture


static func _glass_highlight_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0.88), Color(1, 1, 1, 0.30), Color(1, 1, 1, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	return texture


static func _frosted_glass_style(top: Color, bottom: Color, radius: int, border_width: int = 2, strong_shadow: bool = false, gloss: bool = true) -> StyleBox:
	# StyleBoxFancy cannot blur the framebuffer by itself. This uses translucent
	# layered gradients, a bright rim and soft shadow to create a mobile-safe
	# frosted-glass approximation without a screen-sampling shader.
	var style := StyleBoxFancy.new()
	style.color = Color.WHITE
	style.texture = _glass_gradient(top, bottom)
	style.set_corner_radius_all(radius)
	style.set_corner_curvature_all(2.0) # Panel8 squircle curvature.
	style.shadow_enabled = true
	style.shadow_color = COLOR_GLASS_SHADOW if not strong_shadow else Color(0.04, 0.16, 0.32, 0.38)
	style.shadow_blur = 9 if not strong_shadow else 13
	style.shadow_offset = Vector2(0.0, 4.0)
	style.shadow_spread = Vector2(1.0, 1.0)
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.5
	var rim := StyleBorder.new()
	rim.color = COLOR_GLASS_BORDER
	rim.blend = true
	rim.width_left = border_width
	rim.width_top = border_width
	rim.width_right = border_width
	rim.width_bottom = border_width
	style.borders.append(rim)
	if gloss:
		var highlight := StyleBorder.new()
		highlight.color = Color.WHITE
		highlight.blend = true
		highlight.texture = _glass_highlight_texture()
		highlight.ignore_stack = true
		highlight.width_top = 16
		highlight.inset_left = 5
		highlight.inset_right = 5
		style.borders.append(highlight)
	return style


static func secondary_hud_panel_style() -> StyleBox:
	var style := _frosted_glass_style(Color(0.98, 1.0, 1.0, 0.82), Color(0.72, 0.92, 0.98, 0.74), 26, 2, false, true)
	style.content_margin_left = 14.0
	style.content_margin_top = 7.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 7.0
	return style


static func hud_shell_style() -> StyleBox:
	var style := _frosted_glass_style(Color(1.0, 1.0, 1.0, 0.72), Color(0.82, 0.95, 1.0, 0.66), 34, 2, true, true)
	style.content_margin_left = HUD_SHELL_PADDING
	style.content_margin_top = HUD_SHELL_PADDING
	style.content_margin_right = HUD_SHELL_PADDING
	style.content_margin_bottom = HUD_SHELL_PADDING
	return style


static func progression_inset_style() -> StyleBox:
	var style := _frosted_glass_style(Color(1.0, 1.0, 1.0, 0.56), Color(0.80, 0.95, 1.0, 0.52), 26, 1, false, false)
	style.content_margin_left = 10.0
	style.content_margin_top = 3.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 3.0
	return style


static func card_header_style() -> StyleBox:
	var style := _frosted_glass_style(Color(0.36, 0.78, 0.96, 0.92), Color(0.15, 0.48, 0.78, 0.92), 18, 1, false, true)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	return style


static func target_panel_style() -> StyleBox:
	# Strongest Panel8-inspired surface: light cyan glass fading into clean blue.
	var style := _frosted_glass_style(Color(0.89, 0.99, 1.0, 0.88), Color(0.39, 0.74, 0.94, 0.84), 30, 3, true, true)
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style


static func target_badge_style() -> StyleBox:
	var style := _frosted_glass_style(Color(0.30, 0.70, 0.94, 0.96), Color(0.09, 0.36, 0.68, 0.96), 20, 2, false, true)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	return style


static func utility_frame_style() -> StyleBox:
	return _frosted_glass_style(Color(0.98, 1.0, 1.0, 0.84), Color(0.69, 0.91, 0.98, 0.78), 32, 2, false, true)


static func setting_row_style() -> StyleBox:
	var style := _frosted_glass_style(Color(1.0, 1.0, 1.0, 0.72), Color(0.82, 0.95, 1.0, 0.62), 16, 1, false, false)
	style.content_margin_left = 14.0
	style.content_margin_right = 10.0
	return style


static func gameplay_modal_panel_style() -> StyleBox:
	var style := _frosted_glass_style(Color(1.0, 1.0, 1.0, 0.90), Color(0.78, 0.94, 1.0, 0.84), 38, 3, true, true)
	return style


static func simple_popup_panel_style() -> StyleBoxFlat:
	var style := _rounded_style(Color("fffaf0"), Color("e5b74f"), 3, 30, 9, Color(0.06, 0.16, 0.18, 0.28))
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style

static func hero_screen_panel_style() -> StyleBoxFlat:
	var style := _rounded_style(Color(1.0, 0.975, 0.90, 0.985), Color("f5bf42"), 4, 38, 14, Color(0.0, 0.03, 0.06, 0.42))
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style

static func home_stage_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	return style

static func floating_status_style() -> StyleBoxFlat:
	return _rounded_style(Color(1.0, 0.985, 0.94, 0.96), Color("efb64b"), 3, 28, 8, Color(0.02, 0.12, 0.16, 0.30))

static func logo_frame_style() -> StyleBoxFlat:
	return _rounded_style(Color("19150f"), Color("f6c555"), 3, 30, 7, Color(0.25, 0.10, 0.01, 0.30))

static func continue_card_style() -> StyleBoxFlat:
	return _rounded_style(Color("fffaf0"), Color("e7bd64"), 2, 24, 4, Color(0.10, 0.12, 0.15, 0.18))


static func progression_panel_style() -> StyleBox:
	var style := _frosted_glass_style(Color(1.0, 1.0, 1.0, 0.42), Color(0.80, 0.95, 1.0, 0.34), 24, 1, false, false)
	style.content_margin_left = 8.0
	style.content_margin_top = 3.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 3.0
	return style


static func level_badge_style() -> StyleBox:
	var style := _frosted_glass_style(Color(0.98, 1.0, 1.0, 0.88), Color(0.65, 0.90, 0.98, 0.80), 22, 2, false, true)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	return style


static func progression_style(border: Color, border_width: int, background: Color = COLOR_CREAM) -> StyleBoxFlat:
	return _rounded_style(background, border, border_width, 26, 4, Color(0.24, 0.12, 0.03, 0.20))


static func progress_background_style() -> StyleBoxFlat:
	return _rounded_style(Color(0.12, 0.32, 0.48, 0.18), Color(0.56, 0.86, 0.96, 0.62), 1, 6, 0, Color.TRANSPARENT)


static func progress_fill_style() -> StyleBoxFlat:
	return _rounded_style(COLOR_BLUE, Color(0, 0, 0, 0), 0, 6, 0, Color.TRANSPARENT)


static func fail_badge_style() -> StyleBoxFlat:
	return _rounded_style(Color("fff0e7"), COLOR_CORAL, 5, 58, 7, Color(0.30, 0.10, 0.05, 0.20))


static func atlas(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = texture
	atlas_texture.region = region
	return atlas_texture


static func configure_nine_patch(node: NinePatchRect, texture: Texture2D, horizontal_margin: int, vertical_margin: int) -> void:
	node.texture = texture
	node.set_patch_margin(SIDE_LEFT, horizontal_margin)
	node.set_patch_margin(SIDE_TOP, vertical_margin)
	node.set_patch_margin(SIDE_RIGHT, horizontal_margin)
	node.set_patch_margin(SIDE_BOTTOM, vertical_margin)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE


static func safe_insets(viewport_size: Vector2, window_size: Vector2, safe_rect: Rect2i) -> Vector4:
	if window_size.x <= 0.0 or window_size.y <= 0.0 or safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
		return Vector4.ZERO
	var scale_to_canvas := Vector2(viewport_size.x / window_size.x, viewport_size.y / window_size.y)
	return Vector4(
		clampf(float(safe_rect.position.x) * scale_to_canvas.x, 0.0, 120.0),
		clampf(float(safe_rect.position.y) * scale_to_canvas.y, 0.0, 120.0),
		clampf(float(window_size.x - safe_rect.end.x) * scale_to_canvas.x, 0.0, 120.0),
		clampf(float(window_size.y - safe_rect.end.y) * scale_to_canvas.y, 0.0, 160.0)
	)


static func _configure_primary_button(target_theme: Theme, theme_type: StringName) -> void:
	target_theme.set_font("font", theme_type, font())
	target_theme.set_font_size("font_size", theme_type, BUTTON_FONT_SIZE)
	target_theme.set_color("font_color", theme_type, Color.WHITE)
	target_theme.set_color("font_hover_color", theme_type, Color.WHITE)
	target_theme.set_color("font_pressed_color", theme_type, Color.WHITE)
	target_theme.set_color("font_focus_color", theme_type, Color.WHITE)
	target_theme.set_color("font_disabled_color", theme_type, Color(1, 1, 1, 0.70))
	target_theme.set_color("font_outline_color", theme_type, COLOR_BLUE_DEEP)
	target_theme.set_constant("outline_size", theme_type, 3)
	target_theme.set_stylebox("normal", theme_type, _button_style(false, false))
	target_theme.set_stylebox("hover", theme_type, _button_style(false, true))
	target_theme.set_stylebox("pressed", theme_type, _button_style(true, false))
	target_theme.set_stylebox("disabled", theme_type, _button_style(true, false))
	target_theme.set_stylebox("focus", theme_type, _focus_style())


static func _configure_secondary_button(target_theme: Theme, theme_type: StringName) -> void:
	# Secondary actions deliberately share the same glass language as primary
	# buttons; only their fill is lighter so the modal hierarchy remains clear.
	target_theme.set_font("font", theme_type, font())
	target_theme.set_font_size("font_size", theme_type, BUTTON_FONT_SIZE)
	target_theme.set_color("font_color", theme_type, COLOR_BLUE_DEEP)
	target_theme.set_color("font_hover_color", theme_type, COLOR_BLUE_DEEP)
	target_theme.set_color("font_pressed_color", theme_type, COLOR_BLUE_DEEP)
	target_theme.set_color("font_focus_color", theme_type, COLOR_BLUE_DEEP)
	target_theme.set_color("font_disabled_color", theme_type, COLOR_DISABLED)
	target_theme.set_color("font_outline_color", theme_type, Color(1, 1, 1, 0.76))
	target_theme.set_constant("outline_size", theme_type, 2)
	target_theme.set_stylebox("normal", theme_type, _button_style(true, false))
	target_theme.set_stylebox("hover", theme_type, _button_style(true, true))
	target_theme.set_stylebox("pressed", theme_type, _button_style(false, false))
	target_theme.set_stylebox("disabled", theme_type, _button_style(true, false))
	target_theme.set_stylebox("focus", theme_type, _focus_style())


static func _button_style(light: bool, hover: bool) -> StyleBox:
	var top := Color(0.98, 1.0, 1.0, 0.90) if light else Color(0.39, 0.80, 0.97, 0.96)
	var bottom := Color(0.68, 0.91, 0.98, 0.84) if light else Color(0.11, 0.43, 0.75, 0.96)
	if hover:
		top = top.lightened(0.06)
		bottom = bottom.lightened(0.08)
	var style := _frosted_glass_style(top, bottom, BUTTON_CORNER_RADIUS, BUTTON_BORDER_WIDTH, true, true)
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style


static func _focus_style() -> StyleBoxFlat:
	var style := _rounded_style(Color.TRANSPARENT, COLOR_BLUE_LIGHT, 4, BUTTON_CORNER_RADIUS + 2, 0, Color.TRANSPARENT)
	style.expand_margin_left = 4.0
	style.expand_margin_top = 4.0
	style.expand_margin_right = 4.0
	style.expand_margin_bottom = 4.0
	style.draw_center = false
	return style


static func _rounded_style(background: Color, border: Color, border_width: int, radius: int, shadow_size: int, shadow_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = shadow_color
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0.0, 3.0)
	return style
