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
const COLOR_GLASS := Color(0.20, 0.06, 0.34, 0.88)
const COLOR_GLASS_SOFT := Color(0.34, 0.12, 0.52, 0.76)
const COLOR_GLASS_HIGHLIGHT := Color(0.92, 0.70, 1.0, 0.90)
const COLOR_TEXT := Color("fff8ff")
const COLOR_TEXT_MUTED := Color("d8bde9")
const COLOR_TRACK := Color(0.08, 0.02, 0.14, 0.70)
const COLOR_DISABLED := Color("b9afa1")
const COLOR_OVERLAY := Color(0.025, 0.008, 0.05, 0.68)

# Dark amethyst glass palette matched to the supplied reference. Legacy token
# names remain stable so presentation consumers do not need layout changes.
const COLOR_BLUE_DEEP := Color("fff8ff")
const COLOR_BLUE := Color("a64df1")
const COLOR_BLUE_LIGHT := Color("ead0ff")
const COLOR_BLUE_PALE := Color("f8eeff")
const COLOR_GLASS_WHITE := Color(0.24, 0.07, 0.38, 0.90)
const COLOR_GLASS_BLUE := Color(0.38, 0.13, 0.58, 0.84)
const COLOR_GLASS_BORDER := Color(0.74, 0.31, 0.92, 0.92)
const COLOR_GLASS_SHADOW := Color(0.02, 0.0, 0.06, 0.52)

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
const HUD_ICON_SIZE := 58.0
## Eight progression identities must remain individually legible without their
## silhouettes visually touching in the fixed-width HUD strip.
const PROGRESSION_ICON_SIZE := 56.0
const TARGET_ICON_SIZE := 60.0
const NEXT_ICON_SIZE := 54.0
const HEADER_HEIGHT := 172.0
const UTILITY_ROW_HEIGHT := 116.0
const TOP_HUD_HEIGHT := 122.0
const TOP_SETTINGS_SIZE := 64.0
const OBJECTIVE_STACK_GAP := 14.0
const OBJECTIVE_TABLE_GAP_MIN := 20.0
const OBJECTIVE_TABLE_GAP_MAX := 76.0
const PROGRESSION_HEIGHT := 78.0
## Coins retains the approved larger footprint. Next receives one additional
## 10% emphasis pass while remaining secondary to the centered Target.
const SCORE_PANEL_SIZE := Vector2(164.25, 72.0)
const NEXT_PANEL_SIZE := Vector2(141.075, 123.75)
const TARGET_PANEL_SIZE := Vector2(340.0, 84.0)

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
	result.set_type_variation("SettingsSwitch", "Button")
	_configure_settings_switch(result, "SettingsSwitch")

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
	return _rounded_style(COLOR_GLASS_WHITE, COLOR_GLASS_BORDER, PANEL_BORDER_WIDTH, PANEL_CORNER_RADIUS, 8, COLOR_GLASS_SHADOW)


static func hud_content_style() -> StyleBoxFlat:
	return _rounded_style(Color(0.24, 0.07, 0.38, 0.94), COLOR_GLASS_BORDER, 2, 22, 3, COLOR_GLASS_SHADOW)


static func simple_hud_panel_style() -> StyleBoxFlat:
	return _rounded_style(Color(0.22, 0.06, 0.35, 0.97), COLOR_GLASS_BORDER, 2, 22, 5, COLOR_GLASS_SHADOW)


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


static func _frosted_glass_style(top: Color, bottom: Color, radius: int, border_width: int = 2, _strong_shadow: bool = false, _gloss: bool = false) -> StyleBox:
	# Keep one restrained dark-amethyst surface. The former white gloss border
	# made nested cards and utility buttons look like stacked glass plates.
	var style := StyleBoxFancy.new()
	style.color = Color.WHITE
	style.texture = _glass_gradient(top, bottom)
	style.set_corner_radius_all(radius)
	style.set_corner_curvature_all(2.0) # Panel8 squircle curvature.
	style.shadow_enabled = false
	style.shadow_color = Color.TRANSPARENT
	style.shadow_blur = 0
	style.shadow_offset = Vector2.ZERO
	style.shadow_spread = Vector2.ZERO
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
	return style


static func secondary_hud_panel_style() -> StyleBox:
	var style := _frosted_glass_style(Color(0.28, 0.08, 0.44, 0.90), Color(0.12, 0.03, 0.22, 0.88), 26, 2, false, true)
	style.content_margin_left = 14.0
	style.content_margin_top = 7.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 7.0
	return style


static func hud_shell_style() -> StyleBox:
	var style := _frosted_glass_style(Color(0.31, 0.09, 0.48, 0.88), Color(0.10, 0.02, 0.20, 0.86), 34, 2, true, true)
	style.content_margin_left = HUD_SHELL_PADDING
	style.content_margin_top = HUD_SHELL_PADDING
	style.content_margin_right = HUD_SHELL_PADDING
	style.content_margin_bottom = HUD_SHELL_PADDING
	return style


static func progression_inset_style() -> StyleBox:
	var style := _frosted_glass_style(Color(0.34, 0.10, 0.50, 0.78), Color(0.11, 0.03, 0.21, 0.80), 26, 1, false, false)
	style.content_margin_left = 10.0
	style.content_margin_top = 3.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 3.0
	return style


static func card_header_style() -> StyleBox:
	var style := _frosted_glass_style(Color(0.31, 0.09, 0.49, 0.96), Color(0.13, 0.03, 0.25, 0.96), 18, 2, false, true)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	return style


static func target_panel_style() -> StyleBox:
	var style := _frosted_glass_style(Color(0.32, 0.09, 0.48, 0.91), Color(0.11, 0.025, 0.21, 0.90), 30, 3, true, true)
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style


static func target_badge_style() -> StyleBox:
	var style := _frosted_glass_style(Color(0.38, 0.11, 0.58, 0.98), Color(0.16, 0.035, 0.29, 0.98), 20, 2, false, true)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	return style


static func utility_frame_style() -> StyleBox:
	return _frosted_glass_style(Color(0.34, 0.10, 0.52, 0.92), Color(0.12, 0.025, 0.23, 0.92), 32, 2, false, true)


static func setting_row_style() -> StyleBox:
	var style := _frosted_glass_style(Color(0.30, 0.09, 0.46, 0.86), Color(0.11, 0.025, 0.22, 0.86), 16, 1, false, false)
	style.content_margin_left = 14.0
	style.content_margin_right = 10.0
	return style


static func gameplay_modal_panel_style() -> StyleBox:
	var style := _frosted_glass_style(Color(0.31, 0.09, 0.48, 0.96), Color(0.09, 0.02, 0.18, 0.96), 38, 3, true, true)
	return style


static func simple_popup_panel_style() -> StyleBoxFlat:
	var style := _rounded_style(Color(0.19, 0.045, 0.31, 0.98), COLOR_GLASS_BORDER, 3, 30, 9, COLOR_GLASS_SHADOW)
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style

static func hero_screen_panel_style() -> StyleBoxFlat:
	var style := _rounded_style(Color(0.17, 0.035, 0.29, 0.985), COLOR_PURPLE_LIGHT, 4, 38, 14, Color(0.02, 0.0, 0.05, 0.58))
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style

static func home_stage_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	return style


static func home_status_card_style() -> StyleBox:
	var style := _frosted_glass_style(Color(0.32, 0.09, 0.48, 0.88), Color(0.11, 0.025, 0.21, 0.88), 24, 2, false, true)
	style.content_margin_left = 16.0
	style.content_margin_top = 10.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 10.0
	return style

static func floating_status_style() -> StyleBoxFlat:
	return _rounded_style(Color(0.23, 0.06, 0.37, 0.96), COLOR_GLASS_BORDER, 3, 28, 8, COLOR_GLASS_SHADOW)

static func logo_frame_style() -> StyleBoxFlat:
	return _rounded_style(Color("16081f"), COLOR_PURPLE_LIGHT, 3, 30, 7, COLOR_GLASS_SHADOW)

static func continue_card_style() -> StyleBoxFlat:
	return _rounded_style(Color(0.22, 0.055, 0.36, 0.96), COLOR_GLASS_BORDER, 2, 24, 4, COLOR_GLASS_SHADOW)


static func progression_panel_style() -> StyleBox:
	var style := _frosted_glass_style(Color(0.33, 0.10, 0.49, 0.93), Color(0.10, 0.025, 0.20, 0.93), 27, 3, true, true)
	style.content_margin_left = 12.0
	style.content_margin_top = 7.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 7.0
	return style


static func level_badge_style() -> StyleBox:
	var style := _frosted_glass_style(Color(0.38, 0.11, 0.58, 0.94), Color(0.14, 0.03, 0.26, 0.92), 22, 2, false, true)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	return style


static func progression_style(border: Color, border_width: int, background: Color = COLOR_GLASS_WHITE) -> StyleBoxFlat:
	return _rounded_style(background, border, border_width, 26, 4, COLOR_GLASS_SHADOW)


static func progress_background_style() -> StyleBoxFlat:
	return _rounded_style(Color(0.04, 0.01, 0.08, 0.72), Color(0.53, 0.20, 0.73, 0.78), 1, 6, 0, Color.TRANSPARENT)


static func progress_fill_style() -> StyleBoxFlat:
	return _rounded_style(Color("b65cff"), Color(0, 0, 0, 0), 0, 6, 0, Color.TRANSPARENT)


static func fail_badge_style() -> StyleBoxFlat:
	return _rounded_style(Color(0.28, 0.055, 0.32, 0.98), COLOR_CORAL_LIGHT, 5, 58, 7, COLOR_GLASS_SHADOW)


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



static func _configure_settings_switch(target_theme: Theme, theme_type: StringName) -> void:
	target_theme.set_font("font", theme_type, font())
	target_theme.set_font_size("font_size", theme_type, 17)
	target_theme.set_color("font_color", theme_type, COLOR_BLUE_DEEP)
	target_theme.set_color("font_hover_color", theme_type, COLOR_BLUE_DEEP)
	target_theme.set_color("font_pressed_color", theme_type, Color.WHITE)
	target_theme.set_color("font_focus_color", theme_type, COLOR_BLUE_DEEP)
	target_theme.set_color("font_outline_color", theme_type, Color(0.07, 0.01, 0.13, 0.94))
	target_theme.set_constant("outline_size", theme_type, 1)
	target_theme.set_stylebox("normal", theme_type, _switch_style(false))
	target_theme.set_stylebox("hover", theme_type, _switch_style(false, true))
	target_theme.set_stylebox("pressed", theme_type, _switch_style(true))
	target_theme.set_stylebox("hover_pressed", theme_type, _switch_style(true, true))
	target_theme.set_stylebox("focus", theme_type, _focus_style())


static func _switch_style(enabled: bool, hover: bool = false) -> StyleBox:
	var top := Color(0.60, 0.25, 0.88, 0.98) if enabled else Color(0.30, 0.10, 0.44, 0.94)
	var bottom := Color(0.28, 0.07, 0.50, 0.98) if enabled else Color(0.11, 0.025, 0.21, 0.94)
	if hover:
		top = top.lightened(0.05)
		bottom = bottom.lightened(0.05)
	var style := _frosted_glass_style(top, bottom, 22, 2, false, true)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

static func _configure_primary_button(target_theme: Theme, theme_type: StringName) -> void:
	target_theme.set_font("font", theme_type, font())
	target_theme.set_font_size("font_size", theme_type, BUTTON_FONT_SIZE)
	target_theme.set_color("font_color", theme_type, Color.WHITE)
	target_theme.set_color("font_hover_color", theme_type, Color.WHITE)
	target_theme.set_color("font_pressed_color", theme_type, Color.WHITE)
	target_theme.set_color("font_focus_color", theme_type, Color.WHITE)
	target_theme.set_color("font_disabled_color", theme_type, Color(1, 1, 1, 0.70))
	target_theme.set_color("font_outline_color", theme_type, Color(0.07, 0.01, 0.13, 0.98))
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
	target_theme.set_color("font_outline_color", theme_type, Color(0.07, 0.01, 0.13, 0.96))
	target_theme.set_constant("outline_size", theme_type, 2)
	target_theme.set_stylebox("normal", theme_type, _button_style(true, false))
	target_theme.set_stylebox("hover", theme_type, _button_style(true, true))
	target_theme.set_stylebox("pressed", theme_type, _button_style(false, false))
	target_theme.set_stylebox("disabled", theme_type, _button_style(true, false))
	target_theme.set_stylebox("focus", theme_type, _focus_style())


static func _button_style(light: bool, hover: bool) -> StyleBox:
	var top := Color(0.38, 0.13, 0.56, 0.94) if light else Color(0.62, 0.25, 0.91, 0.98)
	var bottom := Color(0.14, 0.04, 0.26, 0.94) if light else Color(0.30, 0.07, 0.52, 0.98)
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


static func _rounded_style(background: Color, border: Color, border_width: int, radius: int, _shadow_size: int, _shadow_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color.TRANSPARENT
	style.shadow_size = 0
	style.shadow_offset = Vector2.ZERO
	return style
