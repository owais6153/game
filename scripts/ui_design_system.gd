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
const COLOR_TEXT := Color("5f3923")
const COLOR_TEXT_MUTED := Color("986650")
const COLOR_TRACK := Color("cbb89b")
const COLOR_DISABLED := Color("b9afa1")
const COLOR_OVERLAY := Color(0.025, 0.04, 0.06, 0.52)

const HUD_MARGIN := 24
const HUD_NARROW_MARGIN := 16
const SAFE_INSET_PADDING := 10
const ROW_GAP := 10
const ITEM_GAP := 8
const PANEL_PADDING := 16
const PANEL_CORNER_RADIUS := 26
const PANEL_BORDER_WIDTH := 2
const BUTTON_CORNER_RADIUS := 24
const BUTTON_BORDER_WIDTH := 3
const MIN_TOUCH_TARGET := 88.0
const TARGET_TABLE_GAP := 46.0

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
	return _rounded_style(Color(1.0, 0.984, 0.93, 0.97), Color("e5b74f"), 2, 22, 5, Color(0.10, 0.20, 0.22, 0.22))


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

static func logo_frame_style() -> StyleBoxFlat:
	return _rounded_style(Color("19150f"), Color("f6c555"), 3, 30, 7, Color(0.25, 0.10, 0.01, 0.30))

static func continue_card_style() -> StyleBoxFlat:
	return _rounded_style(Color("fffaf0"), Color("e7bd64"), 2, 24, 4, Color(0.10, 0.12, 0.15, 0.18))


static func progression_panel_style() -> StyleBoxFlat:
	var style := _rounded_style(Color(1.0, 0.976, 0.91, 0.96), Color("e5b74f"), 2, 22, 5, Color(0.10, 0.20, 0.22, 0.22))
	style.content_margin_left = 9.0
	style.content_margin_top = 8.0
	style.content_margin_right = 9.0
	style.content_margin_bottom = 9.0
	return style


static func level_badge_style() -> StyleBoxFlat:
	var style := _rounded_style(COLOR_CORAL, COLOR_GOLD_LIGHT, 3, 22, 5, Color(0.24, 0.10, 0.04, 0.22))
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	return style


static func progression_style(border: Color, border_width: int, background: Color = COLOR_CREAM) -> StyleBoxFlat:
	return _rounded_style(background, border, border_width, 26, 4, Color(0.24, 0.12, 0.03, 0.20))


static func progress_background_style() -> StyleBoxFlat:
	return _rounded_style(COLOR_TRACK, Color("a98d68"), 1, 6, 0, Color.TRANSPARENT)


static func progress_fill_style() -> StyleBoxFlat:
	return _rounded_style(COLOR_CORAL, Color(0, 0, 0, 0), 0, 6, 0, Color.TRANSPARENT)


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
	target_theme.set_color("font_outline_color", theme_type, COLOR_CORAL_DARK)
	target_theme.set_constant("outline_size", theme_type, 4)
	target_theme.set_stylebox("normal", theme_type, _button_style(COLOR_CORAL, COLOR_CORAL_DARK, 7))
	target_theme.set_stylebox("hover", theme_type, _button_style(COLOR_CORAL_LIGHT, COLOR_CORAL_DARK, 9))
	target_theme.set_stylebox("pressed", theme_type, _button_style(COLOR_CORAL_DARK, Color("b43d37"), 3))
	target_theme.set_stylebox("disabled", theme_type, _button_style(COLOR_DISABLED, Color("91877a"), 0))
	target_theme.set_stylebox("focus", theme_type, _focus_style())


static func _configure_secondary_button(target_theme: Theme, theme_type: StringName) -> void:
	target_theme.set_font("font", theme_type, font())
	target_theme.set_font_size("font_size", theme_type, BUTTON_FONT_SIZE)
	target_theme.set_color("font_color", theme_type, COLOR_CORAL_DARK)
	target_theme.set_color("font_hover_color", theme_type, COLOR_CORAL_DARK)
	target_theme.set_color("font_pressed_color", theme_type, Color.WHITE)
	target_theme.set_color("font_focus_color", theme_type, COLOR_CORAL_DARK)
	target_theme.set_color("font_disabled_color", theme_type, COLOR_DISABLED)
	target_theme.set_color("font_outline_color", theme_type, Color(1, 1, 1, 0.75))
	target_theme.set_constant("outline_size", theme_type, 2)
	target_theme.set_stylebox("normal", theme_type, _button_style(COLOR_CREAM, COLOR_CORAL, 5))
	target_theme.set_stylebox("hover", theme_type, _button_style(Color("fffdf5"), COLOR_CORAL_LIGHT, 7))
	target_theme.set_stylebox("pressed", theme_type, _button_style(COLOR_CORAL, COLOR_CORAL_DARK, 2))
	target_theme.set_stylebox("disabled", theme_type, _button_style(Color("ece7de"), COLOR_DISABLED, 0))
	target_theme.set_stylebox("focus", theme_type, _focus_style())


static func _button_style(background: Color, border: Color, shadow_size: int) -> StyleBoxFlat:
	var style := _rounded_style(background, border, BUTTON_BORDER_WIDTH, BUTTON_CORNER_RADIUS, shadow_size, Color(0.28, 0.10, 0.04, 0.24))
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style


static func _focus_style() -> StyleBoxFlat:
	var style := _rounded_style(Color.TRANSPARENT, COLOR_GOLD_LIGHT, 4, BUTTON_CORNER_RADIUS + 2, 0, Color.TRANSPARENT)
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
