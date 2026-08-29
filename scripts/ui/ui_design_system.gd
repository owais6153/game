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
## Disabled controls keep their plate silhouette and are desaturated instead of
## swapping to the silver plate, whose wide caps collapse on narrow buttons.
const COLOR_DISABLED_PLATE := Color(0.62, 0.60, 0.66, 0.92)
const COLOR_OVERLAY := Color(0.025, 0.008, 0.05, 0.68)

# Dark amethyst glass palette matched to the supplied reference. Legacy token
# names remain stable so presentation consumers do not need layout changes.
const COLOR_BLUE_DEEP := Color("fff8ff")
const COLOR_BLUE := Color("a64df1")
const COLOR_BLUE_LIGHT := Color("ead0ff")
const COLOR_BLUE_PALE := Color("f8eeff")
const COLOR_GLASS_WHITE := Color(0.24, 0.07, 0.38, 0.90)
const COLOR_GLASS_BLUE := Color(0.38, 0.13, 0.58, 0.84)
## Every framed surface in the supplied art is rimmed in brass, not violet.
## Routing the shared border token to gold lifts each panel, card, and inset
## across all screens without touching their individual layouts.
const COLOR_GLASS_BORDER := Color("d9922f")
const COLOR_GOLD_RIM := Color("f2c14e")
const COLOR_GOLD_RIM_DEEP := Color("a9661c")
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
## Kit plates are authored at the exact height they are drawn at, so these are a
## contract, not a preference: drawing a kit button shorter overlaps its caps and
## crushes the plate. See UiKit.DRAWN_HEIGHT.
const BUTTON_HEIGHT := 96.0
const HERO_BUTTON_HEIGHT := 116.0
const BANNER_HEIGHT := 92.0
const ICON_BUTTON_SIZE := 76.0
const HUD_ICON_SIZE := 58.0
## Eight progression identities must remain individually legible without their
## silhouettes visually touching in the fixed-width HUD strip.
const PROGRESSION_ICON_SIZE := 56.0
const TARGET_ICON_SIZE := 60.0
const NEXT_ICON_SIZE := 48.0
const HEADER_HEIGHT := 172.0
const UTILITY_ROW_HEIGHT := 116.0
const TOP_HUD_HEIGHT := 122.0
const TOP_SETTINGS_SIZE := 64.0
const OBJECTIVE_STACK_GAP := 14.0
const OBJECTIVE_TABLE_GAP_MIN := 20.0
const OBJECTIVE_TABLE_GAP_MAX := 76.0
const PROGRESSION_HEIGHT := 78.0
## Coins retains the approved larger footprint. Next stays deliberately
## compact so the Settings control beneath it has a clean independent gap.
const SCORE_PANEL_SIZE := Vector2(164.25, 72.0)
const NEXT_PANEL_SIZE := Vector2(128.0, 150.0)
const TARGET_PANEL_SIZE := Vector2(340.0, 84.0)

## Type scale. These are canvas units at the 720x1280 design viewport, so they
## read roughly half as large on a 360dp phone. The previous scale topped out at
## 18px body copy, which rendered as ~9dp on device and was the main reason UI
## text looked undersized next to the artwork.
const TITLE_FONT_SIZE := 56
const POPUP_TITLE_FONT_SIZE := 50
const PANEL_TITLE_FONT_SIZE := 30
const BODY_FONT_SIZE := 27
const SMALL_FONT_SIZE := 23
## Long captions ("SKIP LEVEL · 800 COINS") have to clear the plates ornamental
## caps on a 720px screen, so the button face is a step below the title scale.
const BUTTON_FONT_SIZE := 32
const SCORE_FONT_SIZE := 52
const CAPTION_FONT_SIZE := 21
const TAGLINE_FONT_SIZE := 27

## Text is set over busy jewel artwork, so every label carries a dark outline.
const TEXT_OUTLINE_SIZE := 6
const TEXT_OUTLINE_SIZE_SMALL := 4
const COLOR_TEXT_OUTLINE := Color(0.06, 0.01, 0.11, 0.95)

const BUTTON_PRESS_DURATION := 0.07
const BUTTON_RELEASE_DURATION := 0.11
const VALUE_CHANGE_DURATION := 0.16
const ICON_SWAP_DURATION := 0.16
const TARGET_PULSE_DURATION := 0.22
const POPUP_ENTER_DURATION := 0.20
const POPUP_EXIT_DURATION := 0.14

const UiKitType = preload("res://scripts/ui/ui_kit.gd")

## Supplied typefaces. Nunito Sans carries all UI copy; Cinzel is the serif
## display face used for the brand tagline and screen titles.
const FONT_UI_SOURCE := preload("res://assets/runtime/fonts/NunitoSans-Variable.ttf")
const FONT_DISPLAY_SOURCE := preload("res://assets/runtime/fonts/Cinzel-Black.ttf")

## OpenType axis tag for weight. NunitoSans-Variable.ttf defaults this axis to
## 200 (ExtraLight); leaving it unset is what makes the face look spindly, so
## every variation below sets it explicitly.
const AXIS_WEIGHT := "wght"

static var _theme_cache: Theme
static var _font_cache: Font
static var _font_heavy_cache: Font
static var _font_display_cache: Font


static func theme() -> Theme:
	if _theme_cache != null:
		return _theme_cache
	var result := Theme.new()
	result.default_font = font()
	result.default_font_size = BODY_FONT_SIZE
	result.set_font("font", "Label", font())
	result.set_color("font_color", "Label", COLOR_TEXT)
	result.set_font_size("font_size", "Label", BODY_FONT_SIZE)
	# Every label sits over jewel artwork, so the dark outline is a theme-wide
	# default rather than something each screen has to remember.
	result.set_color("font_outline_color", "Label", COLOR_TEXT_OUTLINE)
	result.set_constant("outline_size", "Label", TEXT_OUTLINE_SIZE_SMALL)

	_configure_primary_button(result, "Button")
	result.set_type_variation("SecondaryButton", "Button")
	_configure_secondary_button(result, "SecondaryButton")
	result.set_type_variation("HeroButton", "Button")
	_configure_hero_button(result, "HeroButton")
	result.set_type_variation("GreenButton", "Button")
	_configure_green_button(result, "GreenButton")
	result.set_type_variation("IconButton", "Button")
	_configure_icon_button(result, "IconButton")
	result.set_type_variation("SettingsSwitch", "Button")
	_configure_settings_switch(result, "SettingsSwitch")

	result.set_stylebox("panel", "PanelContainer", panel_style())
	result.set_stylebox("background", "ProgressBar", progress_background_style())
	result.set_stylebox("fill", "ProgressBar", progress_fill_style())
	_theme_cache = result
	return _theme_cache


## Standard UI face. SemiBold, not ExtraBold: at 800 every label on screen —
## including running paragraph copy — rendered as a heavy block that was hard to
## read. Weight is now reserved for numbers and headings via heavy_font().
static func font() -> Font:
	if _font_cache != null:
		return _font_cache
	_font_cache = _weighted(FONT_UI_SOURCE, 620)
	return _font_cache


## Heaviest UI face: Nunito Sans Black. Reserved for score readouts, counters,
## and button captions that must survive a busy jewel background.
static func heavy_font() -> Font:
	if _font_heavy_cache != null:
		return _font_heavy_cache
	_font_heavy_cache = _weighted(FONT_UI_SOURCE, 1000)
	return _font_heavy_cache


## Serif display face: Cinzel Black. Brand tagline and screen titles only.
static func display_font() -> Font:
	if _font_display_cache != null:
		return _font_display_cache
	var variation := FontVariation.new()
	variation.base_font = FONT_DISPLAY_SOURCE
	_font_display_cache = variation
	return _font_display_cache


static func _weighted(source: FontFile, weight: int) -> FontVariation:
	var variation := FontVariation.new()
	variation.base_font = source
	variation.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag(AXIS_WEIGHT): weight}
	return variation


## Applies the project's outlined-text treatment to a Label so copy stays
## readable over artwork without each call site repeating four overrides.
static func style_label(label: Label, font_size: int, color: Color = COLOR_TEXT, use_display: bool = false, outline: int = -1) -> Label:
	label.add_theme_font_override("font", display_font() if use_display else font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", COLOR_TEXT_OUTLINE)
	label.add_theme_constant_override("outline_size", TEXT_OUTLINE_SIZE if outline < 0 else outline)
	return label


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

## A high-visibility jewel-game action frame paired with the 112px gameplay
## touch target. Its deep purple squircle, bright lavender-white rim, and large
## white swap glyph follow the approved lower-table reference treatment.
static func sink_action_button_style(hovered: bool = false, pressed: bool = false) -> StyleBox:
	var top := Color(0.72, 0.30, 0.96, 0.99)
	var bottom := Color(0.26, 0.055, 0.48, 0.99)
	if hovered:
		top = top.lightened(0.08)
		bottom = bottom.lightened(0.06)
	if pressed:
		top = Color(0.44, 0.14, 0.68, 0.99)
		bottom = Color(0.16, 0.025, 0.31, 0.99)
	var style := _frosted_glass_style(top, bottom, 32, 4, false, true) as StyleBoxFancy
	if style != null and not style.borders.is_empty():
		style.borders[0].color = Color("fff4ff") if not pressed else Color("dca6ff")
	style.content_margin_left = 20.0
	style.content_margin_top = 20.0
	style.content_margin_right = 20.0
	style.content_margin_bottom = 20.0
	return style


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

## Each mission card carries its own jewel hue with a brass rim, matching the
## three-colour card row in the supplied mockup. A single flat purple made the
## row read as one undifferentiated block.
const MISSION_CARD_TINTS := [
	[Color("a63fce"), Color("54137a")],
	[Color("2f86dd"), Color("143f78")],
	[Color("e0901f"), Color("8f4d0e")],
]

static func mission_card_style(index: int) -> StyleBox:
	var pair: Array = MISSION_CARD_TINTS[index % MISSION_CARD_TINTS.size()]
	var style := _frosted_glass_style(pair[0], pair[1], 26, 3, false, true) as StyleBoxFancy
	if style != null and not style.borders.is_empty():
		style.borders[0].color = COLOR_GOLD_RIM
	return style


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


## Reward progress reads green in the supplied art, distinct from the violet
## surfaces it sits on.
static func progress_fill_style() -> StyleBoxFlat:
	return _rounded_style(Color("5fc63a"), Color("2f7a18"), 2, 8, 0, Color.TRANSPARENT)


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
	# ON reads green and OFF reads inert, matching the affirmative/neutral split
	# the rest of the kit uses. Two violet states were hard to tell apart.
	var top := Color(0.44, 0.80, 0.26, 0.98) if enabled else Color(0.26, 0.24, 0.30, 0.94)
	var bottom := Color(0.16, 0.46, 0.09, 0.98) if enabled else Color(0.12, 0.11, 0.15, 0.94)
	if hover:
		top = top.lightened(0.05)
		bottom = bottom.lightened(0.05)
	var style := _frosted_glass_style(top, bottom, 22, 2, false, true)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

## Shared text treatment for every kit-backed button family.
static func _configure_button_text(target_theme: Theme, theme_type: StringName, tint: Color = Color.WHITE) -> void:
	target_theme.set_font("font", theme_type, heavy_font())
	target_theme.set_font_size("font_size", theme_type, BUTTON_FONT_SIZE)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		target_theme.set_color(state, theme_type, tint)
	target_theme.set_color("font_disabled_color", theme_type, Color(0.86, 0.83, 0.92, 0.82))
	target_theme.set_color("font_outline_color", theme_type, COLOR_TEXT_OUTLINE)
	target_theme.set_constant("outline_size", theme_type, TEXT_OUTLINE_SIZE)
	target_theme.set_stylebox("focus", theme_type, _focus_style())


## One button family, five states, ONE silhouette. Godot swaps the stylebox on
## hover/press, so if the states point at different textures the plate appears
## to morph mid-interaction — an earlier pass had the plain pill sprouting gem
## caps on hover and the settings gear turning into swap arrows, because
## `btn_square_swap` has its glyph painted into the artwork. States therefore
## differ only by tint, and press motion is carried by scale in
## `_wire_button_motion`, never by a texture change.
const STATE_HOVER := Color(1.14, 1.14, 1.14)
const STATE_PRESSED := Color(0.80, 0.78, 0.86)
## Secondary plates start recessed so the primary action still wins the page.
const STATE_SECONDARY := Color(0.72, 0.68, 0.80)
const STATE_SECONDARY_HOVER := Color(0.86, 0.82, 0.94)


static func _kit_button(
		target_theme: Theme,
		theme_type: StringName,
		key: String,
		content: Vector4,
		normal_tint: Color = Color.WHITE,
		hover_tint: Color = STATE_HOVER,
		disabled_key: String = "") -> void:
	target_theme.set_stylebox("normal", theme_type, UiKitType.nine_patch_style(key, content, normal_tint))
	target_theme.set_stylebox("hover", theme_type, UiKitType.nine_patch_style(key, content, hover_tint))
	target_theme.set_stylebox("pressed", theme_type, UiKitType.nine_patch_style(key, content, STATE_PRESSED))
	var off := disabled_key if not disabled_key.is_empty() else key
	target_theme.set_stylebox("disabled", theme_type, UiKitType.nine_patch_style(off, content, COLOR_DISABLED_PLATE))


## Primary actions wear the gem-capped pill from the supplied button sheet.
static func _configure_primary_button(target_theme: Theme, theme_type: StringName) -> void:
	_configure_button_text(target_theme, theme_type)
	_kit_button(target_theme, theme_type, "btn_pill_gem", Vector4(66.0, 20.0, 60.0, 22.0),
		Color.WHITE, STATE_HOVER, "btn_pill_gem_off")


## Secondary actions share the kit's material language but sit visually below
## the primary action rather than competing with it.
static func _configure_secondary_button(target_theme: Theme, theme_type: StringName) -> void:
	_configure_button_text(target_theme, theme_type, COLOR_LAVENDER_LIGHT)
	_kit_button(target_theme, theme_type, "btn_pill_plain", Vector4(46.0, 20.0, 44.0, 22.0),
		STATE_SECONDARY, STATE_SECONDARY_HOVER)


## The single hero call to action (Home's PLAY). Deliberately one per screen.
static func _configure_hero_button(target_theme: Theme, theme_type: StringName) -> void:
	_configure_button_text(target_theme, theme_type)
	target_theme.set_font_size("font_size", theme_type, TITLE_FONT_SIZE)
	_kit_button(target_theme, theme_type, "btn_hero_bright", Vector4(88.0, 26.0, 88.0, 28.0))


## Affirmative rewards (CLAIM, COLLECT, RETRY) use the kit's green plate so
## "take the coins" never reads as one more navigation choice.
static func _configure_green_button(target_theme: Theme, theme_type: StringName) -> void:
	_configure_button_text(target_theme, theme_type)
	# A tint cannot desaturate green, so the unavailable state uses a
	# luma-desaturated derivative of the same plate: identical silhouette,
	# unmistakably inert.
	_kit_button(target_theme, theme_type, "btn_green", Vector4(54.0, 20.0, 54.0, 22.0),
		Color.WHITE, STATE_HOVER, "btn_green_off")


## Square icon affordances (settings gear).
static func _configure_icon_button(target_theme: Theme, theme_type: StringName) -> void:
	_configure_button_text(target_theme, theme_type)
	_kit_button(target_theme, theme_type, "btn_square_small", Vector4(16.0, 14.0, 16.0, 16.0))


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


## Touch-first UI: the kit buttons already carry their own rim, and a keyboard
## focus ring drawn on top of that art reads as a rendering fault. Focus stays
## non-drawing while remaining a real focus target for accessibility.
static func _focus_style() -> StyleBoxFlat:
	var style := _rounded_style(Color.TRANSPARENT, Color.TRANSPARENT, 0, BUTTON_CORNER_RADIUS + 2, 0, Color.TRANSPARENT)
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
