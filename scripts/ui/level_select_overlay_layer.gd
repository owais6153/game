class_name LevelSelectOverlayLayer
extends CanvasLayer

## The level screen: the map the player lands on between Home and a level.
##
## The flow is Home -> PLAY -> here -> tap a level -> Level Ready popup -> play,
## and winning returns here rather than straight into the next level, so the
## player always sees the path they are climbing.
##
## The screen owns no progression rules. It is handed the furthest level and the
## opened chests and renders exactly that; unlocking, granting and saving all
## stay in the controller, so the map can never disagree with the save.

const AssetCatalogType = preload("res://scripts/core/asset_catalog.gd")
const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")
const UiKitType = preload("res://scripts/ui/ui_kit.gd")
const LevelMapViewType = preload("res://scripts/ui/level_map_view.gd")
const LevelMilestoneType = preload("res://scripts/core/level_milestone.gd")
const ICON_BACK = preload("res://assets/runtime/ui/icons/back_lavender.svg")
const MascotViewType = preload("res://scripts/ui/mascot_view.gd")

signal level_chosen(level_number: int)
signal chest_claim_requested(chest_index: int)
signal home_requested
signal ui_tap_requested

## How far past the player's furthest level the map keeps drawing. A thousand
## levels is far enough that scrolling never reaches an end, which is the whole
## point: the game must never look finishable.
const LEVELS_AHEAD := 1000

## Header geometry, measured off the supplied reference as a fraction of its
## 1024x1536 frame. The bar is 7.2% of screen height and the back button is
## square at that same height, so the two read as one row rather than as a small
## button parked beside a tall plate.
const BAR_HEIGHT := 96.0
const TITLE_FONT_SIZE := 38
const SUBTITLE_FONT_SIZE := 24
## Clear space each bar keeps from its screen edge before device safe insets are
## added. The reference leaves about 3.6% of height above the header and below
## the hero button; at the previous 12px both bars looked pinned on.
const BAR_EDGE_GAP := 38.0

var root_control: Control
var backdrop: TextureRect
var wash: ColorRect
## The two floating bars. They are anchored to the screen edges independently
## rather than sharing one safe-area container, because the map behind them must
## stay full-bleed.
var header_margin: MarginContainer
var footer_margin: MarginContainer
var scroll: ScrollContainer
var map_view: LevelMapView
var title_label: Label
var subtitle_label: Label
var back_button: Button
## Idle mascot in the header, on the right where the coin chip used to be.
var mascot: MascotView
var play_button: Button

var _highest_level := 1
var _coins := 0
var _claimed_chests: Array[int] = []
var _entrance_tween: Tween
var _safe_insets_override := Vector4(-1.0, -1.0, -1.0, -1.0)
## Set while the map is being scrolled to the player's level, so the resulting
## scroll notification is not mistaken for the player browsing.
var _centring := false


func _ready() -> void:
	# Between Home (60) and the Level Ready popup, which the Home layer owns and
	# must keep drawing over this map.
	layer = 61
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_refresh_safe_margins()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_on_viewport_resized):
		viewport.size_changed.connect(_on_viewport_resized)
	root_control.hide()


## Back on the level screen always means Home. There is nothing to dismiss here,
## so trapping the player would be the only other outcome. Escape and the
## Android back gesture are routed by the controller, which owns app flow, so
## this layer deliberately does not listen for them itself.
func handle_back_request() -> bool:
	if root_control == null or not root_control.visible:
		return false
	home_requested.emit()
	return true


func is_open() -> bool:
	return root_control != null and root_control.visible


func present(highest_level: int, coins: int, claimed_chests: Array[int]) -> void:
	_highest_level = maxi(1, highest_level)
	_coins = maxi(0, coins)
	_claimed_chests = claimed_chests.duplicate()
	if map_view != null:
		map_view.configure(_highest_level, _claimed_chests, LEVELS_AHEAD)
	_refresh_labels()
	root_control.show()
	_refresh_safe_margins()
	# The map's height is only known after the configure above has propagated
	# through the ScrollContainer's layout, so centring waits a frame.
	call_deferred("_centre_on_current_level")
	_play_entrance()


func dismiss() -> void:
	_kill_tween()
	if root_control != null:
		root_control.hide()


## Applied without re-centring the map, so a coin change while the player is
## browsing level 300 does not yank them back to their own level.
func update_state(highest_level: int, coins: int, claimed_chests: Array[int]) -> void:
	_highest_level = maxi(1, highest_level)
	_coins = maxi(0, coins)
	_claimed_chests = claimed_chests.duplicate()
	if map_view != null:
		map_view.configure(_highest_level, _claimed_chests, LEVELS_AHEAD)
	_refresh_labels()


func _refresh_labels() -> void:
	if title_label != null:
		title_label.text = "LEVEL %d" % _highest_level
	if subtitle_label != null:
		var next_chest := LevelMilestoneType.unlocked_chest_count(_highest_level) + 1
		var remaining := LevelMilestoneType.level_for_chest(next_chest) - _highest_level + 1
		subtitle_label.text = "Next chest in %d %s" % [remaining, "level" if remaining == 1 else "levels"]
	if play_button != null:
		play_button.text = "PLAY LEVEL %d" % _highest_level


## The map runs the full height of the screen, but the top and bottom of it are
## under the two floating bars. Centring therefore targets the clear band
## between them, or the player's own level opens half-hidden behind the banner.
func _centre_on_current_level() -> void:
	if scroll == null or map_view == null:
		return
	var header_height := header_margin.size.y if header_margin != null else 0.0
	var footer_height := footer_margin.size.y if footer_margin != null else 0.0
	var clear_band := maxf(1.0, scroll.size.y - header_height - footer_height)
	var offset := map_view.scroll_offset_for_level(_highest_level, clear_band)
	_centring = true
	# Shift by the header so the centre of the clear band, not the centre of the
	# full screen, is what lands on the player's level.
	scroll.scroll_vertical = int(round(maxf(0.0, offset - header_height)))
	_centring = false
	_push_window()


## The map draws only what is on screen, so it has to be told what that is
## every time the scroll or the viewport moves.
func _push_window() -> void:
	if scroll == null or map_view == null:
		return
	var top := float(scroll.scroll_vertical)
	map_view.set_window(top, top + scroll.size.y)


func _on_viewport_resized() -> void:
	_refresh_safe_margins()
	_push_window()


func _build() -> void:
	root_control = Control.new()
	root_control.name = "LevelSelectRoot"
	# A CanvasLayer is not a Control, so the theme does not reach this screen by
	# inheritance the way it would inside the main tree. Home sets it on its own
	# root for the same reason; without it every button here falls back to
	# Godot's default grey plate.
	root_control.theme = UiDesignSystemType.theme()
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	backdrop = TextureRect.new()
	backdrop.name = "LevelSelectBackdrop"
	backdrop.texture = AssetCatalogType.background_texture(0)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	# Stops taps, so a miss between two level nodes never falls through to
	# whatever the controller left behind this screen.
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Light. The garden art is the screen here, not a backdrop behind a panel, so
	# the wash only has to keep the path's gold legible - at the heavier value
	# Home uses, the artwork went flat and grey.
	wash = ColorRect.new()
	wash.name = "LevelSelectWash"
	wash.color = Color(0.05, 0.01, 0.10, 0.20)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(wash)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# The map is the whole screen. The header and the hero button float over it
	# at the two edges rather than taking rows out of a column, so the path runs
	# edge to edge and the artwork is never boxed into a panel in the middle.
	scroll = ScrollContainer.new()
	scroll.name = "LevelSelectScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = false
	# Touch panning needs a little travel before it takes over, or a tap that
	# wobbles by a pixel starts a scroll and the map twitches under the finger.
	scroll.scroll_deadzone = 8
	# Godot's built-in ScrollContainer panel is a bordered grey plate, and the
	# project theme does not override it - that stylebox is what drew a visible
	# box around the map.
	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	root_control.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# The scrollbar would sit on top of the artwork and never be dragged on a
	# phone; the flick gesture is the real control.
	var bar := scroll.get_v_scroll_bar()
	if bar != null:
		bar.modulate = Color(1.0, 1.0, 1.0, 0.0)
		bar.value_changed.connect(_on_scrolled)

	map_view = LevelMapViewType.new()
	map_view.name = "LevelMapView"
	map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_view.level_selected.connect(_on_level_selected)
	map_view.chest_selected.connect(_on_chest_selected)
	scroll.add_child(map_view)

	# Soft scrims under the two floating bars. They are not a frame around the
	# map - they only stop a level plate from colliding with the banner or the
	# hero button as it scrolls behind them.
	_add_edge_fade(root_control, true)
	_add_edge_fade(root_control, false)

	# Both bars respect the device's safe insets on their own, so neither is
	# pushed inward by a shared margin container the map would also inherit.
	header_margin = MarginContainer.new()
	header_margin.name = "LevelSelectHeaderArea"
	header_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(header_margin)
	header_margin.add_child(_build_header())

	footer_margin = MarginContainer.new()
	footer_margin.name = "LevelSelectFooterArea"
	footer_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(footer_margin)

	play_button = Button.new()
	play_button.name = "LevelSelectPlayButton"
	play_button.text = "PLAY LEVEL 1"
	play_button.theme_type_variation = "HeroButton"
	play_button.custom_minimum_size = Vector2(0.0, UiDesignSystemType.HERO_BUTTON_HEIGHT)
	play_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	play_button.pressed.connect(func() -> void: _on_level_selected(_highest_level))
	_wire_button_motion(play_button)
	footer_margin.add_child(play_button)


## A vertical gradient pinned to the top or bottom edge of the scroll view,
## fading to the screen's own ground colour. Input passes straight through it.
func _add_edge_fade(host: Control, at_top: bool) -> void:
	var gradient := Gradient.new()
	# Nearly opaque where it meets the screen edge, clear where it meets the map.
	# The map is full-bleed, so without this a level plate is guillotined by the
	# top of the screen and another one peeks out below the hero button. The
	# gradient is long enough that it still reads as the path fading away rather
	# than as a bar: only the last few pixels are actually solid.
	var solid := Color(0.05, 0.01, 0.10, 0.96)
	var clear := Color(0.05, 0.01, 0.10, 0.0)
	gradient.set_color(0, solid if at_top else clear)
	gradient.set_color(1, clear if at_top else solid)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	texture.width = 4
	texture.height = 128

	var fade := TextureRect.new()
	fade.name = "LevelMapFadeTop" if at_top else "LevelMapFadeBottom"
	fade.texture = texture
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(fade)
	fade.set_anchors_preset(Control.PRESET_TOP_WIDE if at_top else Control.PRESET_BOTTOM_WIDE)
	fade.anchor_left = 0.0
	fade.anchor_right = 1.0
	fade.offset_left = 0.0
	fade.offset_right = 0.0
	if at_top:
		fade.anchor_top = 0.0
		fade.anchor_bottom = 0.0
		fade.offset_top = 0.0
		fade.offset_bottom = 210.0
	else:
		fade.anchor_top = 1.0
		fade.anchor_bottom = 1.0
		fade.offset_top = -250.0
		fade.offset_bottom = 0.0


## Back and the coin balance flank a banner naming the level the player is on.
## Nothing else: every other affordance belongs to Home or to the level popup.
func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.name = "LevelSelectHeader"
	header.add_theme_constant_override("separation", UiDesignSystemType.ITEM_GAP)
	header.custom_minimum_size = Vector2(0.0, BAR_HEIGHT)

	back_button = Button.new()
	back_button.name = "LevelSelectBackButton"
	back_button.theme_type_variation = "IconButton"
	back_button.custom_minimum_size = Vector2(BAR_HEIGHT, BAR_HEIGHT)
	back_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_button.pressed.connect(func() -> void: home_requested.emit())
	_wire_button_motion(back_button)
	UiDesignSystemType.centre_icon_in_button(back_button, ICON_BACK, BAR_HEIGHT)
	header.add_child(back_button)

	var banner := PanelContainer.new()
	banner.name = "LevelSelectBanner"
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_theme_stylebox_override("panel", UiKitType.nine_patch_style("bar_gold_frame", Vector4(76.0, 10.0, 76.0, 12.0)))
	header.add_child(banner)
	var banner_column := VBoxContainer.new()
	banner_column.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_column.add_theme_constant_override("separation", 0)
	banner_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(banner_column)
	title_label = _label("LEVEL 1", TITLE_FONT_SIZE, Color.WHITE)
	title_label.add_theme_font_override("font", UiDesignSystemType.heavy_font())
	banner_column.add_child(title_label)
	subtitle_label = _label("", SUBTITLE_FONT_SIZE, UiDesignSystemType.COLOR_GOLD_LIGHT)
	banner_column.add_child(subtitle_label)

	# No coin chip. The level screen spends nothing, so a balance here is a
	# number the player cannot act on; Home and the shop both show it where it
	# means something. The mascot takes that corner instead, idle, so the screen
	# has the same three-part header as everywhere else: back, title, character.
	var mascot_slot := CenterContainer.new()
	mascot_slot.name = "LevelSelectMascotSlot"
	mascot_slot.custom_minimum_size = Vector2(BAR_HEIGHT, BAR_HEIGHT)
	mascot_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(mascot_slot)
	mascot = MascotViewType.new()
	mascot.name = "LevelSelectMascot"
	mascot.custom_minimum_size = Vector2(BAR_HEIGHT, BAR_HEIGHT)
	mascot_slot.add_child(mascot)

	return header


func _on_scrolled(_value: float) -> void:
	if _centring:
		return
	_push_window()


func _on_level_selected(level_number: int) -> void:
	if level_number <= 0 or level_number > _highest_level:
		return
	ui_tap_requested.emit()
	level_chosen.emit(level_number)


func _on_chest_selected(chest_index: int) -> void:
	if _claimed_chests.has(chest_index):
		return
	ui_tap_requested.emit()
	chest_claim_requested.emit(chest_index)


func _play_entrance() -> void:
	_kill_tween()
	if not is_inside_tree():
		return
	root_control.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_entrance_tween = create_tween()
	_entrance_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_entrance_tween.tween_property(root_control, "modulate:a", 1.0, 0.18)


func _kill_tween() -> void:
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()
	if root_control != null:
		root_control.modulate = Color.WHITE


func _wire_button_motion(button: BaseButton) -> void:
	if button == null:
		return
	button.button_down.connect(func() -> void:
		button.pivot_offset = button.size * 0.5
		var global_tweens := get_node_or_null("/root/GlobalTweens")
		if global_tweens != null:
			global_tweens.call("button_press", button, 0.055)
	)
	button.pressed.connect(func() -> void: ui_tap_requested.emit())


func set_safe_insets_override(insets: Vector4) -> void:
	_safe_insets_override = insets
	_refresh_safe_margins()


## Each bar hugs its own screen edge, clearing only the device inset on that
## side. The map is deliberately left out of this: it must run under both bars
## and off both edges.
func _refresh_safe_margins() -> void:
	if header_margin == null or footer_margin == null or not is_inside_tree():
		return
	var insets := _safe_insets()
	var side := int(ceil(maxf(16.0, maxf(insets.x, insets.z) + UiDesignSystemType.SAFE_INSET_PADDING)))
	for container in [header_margin, footer_margin]:
		container.add_theme_constant_override("margin_left", side)
		container.add_theme_constant_override("margin_right", side)
	header_margin.add_theme_constant_override("margin_top", int(ceil(maxf(BAR_EDGE_GAP, insets.y + BAR_EDGE_GAP))))
	header_margin.add_theme_constant_override("margin_bottom", 0)
	footer_margin.add_theme_constant_override("margin_top", 0)
	footer_margin.add_theme_constant_override("margin_bottom", int(ceil(maxf(BAR_EDGE_GAP, insets.w + BAR_EDGE_GAP))))
	_layout_bars()


## Pins each bar to its edge at exactly the height its content needs.
##
## An anchor preset alone is not enough: it sets the anchors but leaves every
## offset at zero, so both bars collapsed to the top-left corner and the hero
## button ended up drawn over the banner. The heights also move whenever the
## safe insets change, so this runs after every margin update rather than once
## at build time.
func _layout_bars() -> void:
	if header_margin == null or footer_margin == null:
		return
	for bar in [header_margin, footer_margin]:
		bar.anchor_left = 0.0
		bar.anchor_right = 1.0
		bar.offset_left = 0.0
		bar.offset_right = 0.0

	header_margin.anchor_top = 0.0
	header_margin.anchor_bottom = 0.0
	header_margin.offset_top = 0.0
	header_margin.offset_bottom = header_margin.get_combined_minimum_size().y

	footer_margin.anchor_top = 1.0
	footer_margin.anchor_bottom = 1.0
	footer_margin.offset_top = -footer_margin.get_combined_minimum_size().y
	footer_margin.offset_bottom = 0.0


func _safe_insets() -> Vector4:
	if _safe_insets_override.x >= 0.0:
		return _safe_insets_override
	if get_viewport() != get_tree().root:
		return Vector4.ZERO
	return UiDesignSystemType.safe_insets(
		get_viewport().get_visible_rect().size,
		Vector2(DisplayServer.window_get_size()),
		DisplayServer.get_display_safe_area()
	)


func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UiDesignSystemType.font())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", UiDesignSystemType.TEXT_OUTLINE_SIZE_SMALL)
	label.add_theme_color_override("font_outline_color", UiDesignSystemType.COLOR_PURPLE_DEEP)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
