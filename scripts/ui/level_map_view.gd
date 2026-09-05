class_name LevelMapView
extends Control

## The scrolling level path. Every node, chest and connecting curve is drawn
## directly rather than built as child Controls, because the map spans a
## thousand levels ahead of the player: a Control per node would mean building
## and laying out several thousand of them on every open, and Godot would carry
## that cost on every resize and scroll for a screen the player flicks through
## in a second.
##
## Drawing instead costs only the slots inside the visible window, so opening
## the map at level 4 and opening it at level 4000 cost the same.
##
## The node geometry is shared by drawing and by hit testing - both go through
## `_point_at()` - so what the player taps is always what they see, including
## halfway along the curve where the serpentine is steepest.

const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")
const UiKitType = preload("res://scripts/ui/ui_kit.gd")
const LevelMilestoneType = preload("res://scripts/core/level_milestone.gd")

signal level_selected(level_number: int)
signal chest_selected(chest_index: int)

## Vertical distance between consecutive slots.
##
## Every size below is derived from the supplied reference, measured off its
## 1024x1536 frame and expressed as ratios rather than copied as pixels:
##
##   row pitch          1.75 x plate
##   laurel badge       0.75 x plate
##   column separation  1.58 x plate
##   path swing         37.6% of screen width, edge to edge
##
## The ratios to the plate are reproduced exactly. The swing is not, and cannot
## be: the reference is a 2:3 mock-up and the game renders at 720x1280 or taller
## (1:1.78 and beyond). Holding the swing at 37.6% of a 720-wide screen while
## keeping plates big enough to tap puts adjacent columns 1.15 plates apart, and
## consecutive nodes start colliding. The swing is therefore opened to 48% of
## width, which restores a 1.44 column separation - near the reference's 1.58 -
## and is the one deliberate departure from the mock-up.
const ROW_HEIGHT := 182.0
## Clearance below the first level node and above the last, so neither is ever
## flush against the end of the scroll.
const BOTTOM_PAD := 210.0
const TOP_PAD := 250.0

## Plates are the kit's own `btn_square_small` art rather than drawn circles, so
## a level node carries the same bevel, gold rim and gloss as every button in
## the game. They are drawn through a StyleBoxTexture so the nine-patch margins
## are honoured and the rim never smears when the plate is scaled up.
const NODE_PLATE := 104.0
const CURRENT_PLATE := 122.0
const CHEST_PLATE := 150.0
## Hit radii, derived from the plates above. Half the plate is the plate's edge.
const NODE_RADIUS := NODE_PLATE * 0.5
const CHEST_RADIUS := CHEST_PLATE * 0.5
## Taps are forgiving: a finger that lands just off the plate still counts.
const TAP_SLOP := 14.0
## How far a finger may travel between press and release and still count as a
## tap rather than as the start of a flick.
const TAP_MOVE_TOLERANCE := 12.0

## Ornament sizes, all quoted as the drawn width; heights follow each texture's
## own aspect so nothing in the kit is stretched.
const LAUREL_WIDTH := 78.0
const CROWN_WIDTH := 68.0
const SPARKLE_WIDTH := 46.0
const STUD_WIDTH := 24.0
## Outline weight on the level numbers, drawn in a single pass.
const NUMBER_OUTLINE_SIZE := 6
## Extra rows drawn beyond the visible window. See _visible_slot_range.
const BLEED_ROWS := 2

## Flick physics. Friction is per second and applied exponentially, so the glide
## feels the same whatever the frame rate; below MIN_GLIDE_SPEED it stops rather
## than creeping for ever.
const FRICTION := 0.06
const MIN_GLIDE_SPEED := 12.0
const VELOCITY_BLEND := 0.65
const MIN_FRAME_DELTA := 1.0 / 240.0
## Trackpad and mouse-wheel pan events are reported in notches, not pixels.
const PAN_GESTURE_SCALE := 40.0

## Plate drop shadow: how far below the plate it sits, and how much larger it is
## drawn so it reads as a soft spread rather than as a hard offset copy.
const SHADOW_DROP := 0.085
const SHADOW_SPREAD := 1.04

## Horizontal swing of the path, as a fraction of the available width and as a
## hard ceiling for wide screens, where an unbounded swing would throw the nodes
## into the margins.
const SWING_RATIO := 0.24
const SWING_MAX := 200.0
## Slots per full left-right-left cycle of the path.
const SWING_PERIOD := 6.0

## Curve subdivisions per slot. The path is a sine, so straight segments between
## node centres would read as a zigzag of hard corners.
const CURVE_STEPS := 7
## The path is three strokes: a dark casing, the gold body, and a pale gloss
## line. One flat stroke read as a drawn line rather than as a paved road.
const PATH_CASING_WIDTH := 26.0
const PATH_WIDTH := 17.0
const PATH_GLOSS_WIDTH := 5.0

const DECOR_DIAMOND_SMALL = preload("res://assets/runtime/ui/kit/decor_diamond_small.png")
const AssetCatalogType = preload("res://scripts/core/asset_catalog.gd")

## Loose gems scattered in the empty half of the map, opposite whichever way the
## path is leaning. Decoration only - they are drawn, never hit-tested, and the
## scatter is derived from the slot index so it is identical every time the
## screen opens rather than reshuffling under the player.
const SCATTER_PER_SLOT := 2
const SCATTER_MIN_SIZE := 34.0
const SCATTER_MAX_SIZE := 62.0
## Kept away from the path so a decorative gem is never mistaken for a node.
const SCATTER_PATH_CLEARANCE := 118.0
const SCATTER_ALPHA := 0.30

var highest_level := 1
var last_level := 1
var claimed_chests: Array[int] = []

var _slot_count := 1
## Content-space Y of the top of the viewport, plus the flick physics.
var _scroll := 0.0
var _velocity := 0.0
var _dragging := false
var _pulse := 0.0
## Press tracking, so a flick across a level plate scrolls instead of selecting.
var _press_position := Vector2.ZERO
var _press_active := false

## Built once. A StyleBoxTexture per state costs nothing to draw but would be
## wasteful to rebuild for every plate on every frame of the pulse.
var _plate_cleared: StyleBox
var _plate_current: StyleBox
var _plate_locked: StyleBox
var _plate_chest: StyleBox
var _plate_chest_locked: StyleBox
var _plate_shadow: StyleBox
## Own canvas item for the halos and sparkles, so the static map underneath is
## not repainted every frame just to animate them.
var _animated_layer: Control
## Measured text sizes, keyed by "size:text". get_string_size shapes the string
## to measure it and was costing about a millisecond per repaint across the
## visible numbers; the answer only depends on the digits and the size, and both
## repeat constantly as the map scrolls.
var _measure_cache: Dictionary = {}
## The slot range the current painting covers, so a scroll that stays inside it
## costs nothing.
var _drawn_range := Vector2i(-1, -1)


## PASS, not STOP. The map fills the ScrollContainer, and a child that stops
## input never lets the container see the drag - which is exactly why the level
## map would not scroll. PASS lets this view read the tap and still hands the
## gesture on, so the flick works.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_plates()
	_animated_layer = Control.new()
	_animated_layer.name = "LevelMapAnimation"
	_animated_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Behind the map, not over it. A child canvas item draws after its parent by
	# default, which would put the halos on top of the plates they sit behind.
	_animated_layer.show_behind_parent = true
	_animated_layer.draw.connect(_draw_animated_layer)
	add_child(_animated_layer)
	_match_animation_layer()
	resized.connect(_match_animation_layer)
	set_process(true)


## The animation layer shares the map.s coordinate space, so the halo positions
## it draws are the same _point_at values the plates were drawn at.
func _match_animation_layer() -> void:
	if _animated_layer != null:
		_animated_layer.position = Vector2.ZERO
		_animated_layer.size = size


## Cleared plates sit slightly recessed and the current one is lifted, so the
## player's own level is the brightest thing on the path without needing a
## different silhouette from the levels around it.
func _build_plates() -> void:
	if _plate_current != null:
		return
	_plate_cleared = UiKitType.nine_patch_style("btn_square_small", Vector4.ZERO, Color(0.90, 0.86, 0.98))
	_plate_current = UiKitType.nine_patch_style("btn_square_small", Vector4.ZERO, Color(1.16, 1.12, 1.20))
	_plate_locked = UiKitType.nine_patch_style("btn_square_small", Vector4.ZERO, Color(0.50, 0.46, 0.58, 0.94))
	_plate_chest = UiKitType.nine_patch_style("btn_square_small", Vector4.ZERO, Color(1.10, 1.06, 1.16))
	_plate_chest_locked = UiKitType.nine_patch_style("btn_square_small", Vector4.ZERO, Color(0.50, 0.46, 0.58, 0.94))

	# The drop shadow is the plate art again, dark and offset - not a blurred
	# StyleBoxFlat.
	#
	# A StyleBoxFlat with shadow_size rebuilds a shadow mesh every time it is
	# drawn, and this is drawn once per visible node, eighteen times a repaint.
	# Reusing the plate's own nine-patch is a plain textured draw and reads the
	# same, because the plate art already has soft edges. A draw_circle was tried
	# before either and was worse: a hard grey disc poking out past the corners
	# of a rounded square.
	_plate_shadow = UiKitType.nine_patch_style("btn_square_small", Vector4.ZERO, Color(0.03, 0.0, 0.07, 0.38))


func _process(delta: float) -> void:
	_pulse = fmod(_pulse + delta, TAU)
	_advance_glide(delta)
	# Only the animation layer repaints per frame. The map itself is expensive -
	# a dozen nine-patched plates, their laurels, the path strokes, the scattered
	# gems, and a hundred-odd draw_string calls for the outlined numbers - and
	# repainting all of it sixty times a second just to breathe one halo is what
	# made scrolling stutter.
	if _animated_layer != null:
		_animated_layer.queue_redraw()


## The moving parts, on their own canvas item: the current level's breathing
## halo and a claimable chest's glinting sparkles. Everything static stays in
## `_draw`, which only repaints when the visible slot range changes.
func _draw_animated_layer() -> void:
	if _animated_layer == null or _slot_count <= 0:
		return
	var range_slots := _visible_slot_range()
	if range_slots.y < range_slots.x:
		return
	_animated_layer.draw_set_transform(Vector2(0.0, -_scroll))
	var canvas := _animated_layer.get_canvas_item()
	for slot in range(range_slots.x, range_slots.y + 1):
		var contents := LevelMilestoneType.slot_contents(slot)
		var chest_index := int(contents.get("chest", 0))
		var centre := _point_at(float(slot))
		if chest_index > 0:
			if chest_index > LevelMilestoneType.unlocked_chest_count(highest_level):
				continue
			if claimed_chests.has(chest_index):
				continue
			var chest_halo := CHEST_PLATE * 0.62 + 22.0 + sin(_pulse * 2.0 + float(chest_index)) * 7.0
			_animated_layer.draw_circle(centre, chest_halo, Color(UiDesignSystemType.COLOR_GOLD_LIGHT, 0.20))
			_animated_layer.draw_circle(centre, chest_halo * 0.80, Color(UiDesignSystemType.COLOR_GOLD_LIGHT, 0.16))
			for index in range(2):
				# Clear of the plate corners, because this layer draws behind the
				# plate and a sparkle any closer in would be hidden by it.
				var offset := Vector2(CHEST_PLATE * (0.60 if index == 0 else -0.60), -CHEST_PLATE * 0.56)
				var twinkle := 0.55 + 0.45 * sin(_pulse * 3.0 + float(index) * PI)
				var edge := SPARKLE_WIDTH
				var rect := Rect2(centre + offset - Vector2(edge, edge) * 0.5, Vector2(edge, edge))
				UiKitType.ICON_SPARKLE.draw_rect(canvas, rect, false, Color(1.0, 1.0, 1.0, twinkle))
			continue
		if int(contents.get("level", 0)) != highest_level:
			continue
		var halo := CURRENT_PLATE * 0.62 + 18.0 + sin(_pulse * 2.4) * 5.0
		_animated_layer.draw_circle(centre, halo, Color(UiDesignSystemType.COLOR_GOLD_LIGHT, 0.22))
		_animated_layer.draw_circle(centre, halo * 0.82, Color(UiDesignSystemType.COLOR_GOLD_LIGHT, 0.16))


## `levels_ahead` is how far beyond the player's furthest level the path keeps
## going. It exists so the map never shows an end: the player can always scroll
## up into levels they have not reached.
func configure(new_highest_level: int, new_claimed_chests: Array[int], levels_ahead: int) -> void:
	highest_level = maxi(1, new_highest_level)
	claimed_chests = new_claimed_chests.duplicate()
	last_level = highest_level + maxi(0, levels_ahead)
	_slot_count = LevelMilestoneType.slot_count_through(last_level)
	# Deliberately does not set custom_minimum_size. This control is the viewport,
	# not the content: sizing it to content_height() is what made it a node
	# 186,000px tall back when a ScrollContainer owned the scrolling.
	_scroll = clampf(_scroll, 0.0, max_scroll())
	_drawn_range = Vector2i(-1, -1)
	queue_redraw()


func content_height() -> float:
	return BOTTOM_PAD + TOP_PAD + float(maxi(0, _slot_count - 1)) * ROW_HEIGHT


## The visible slice of the map, in this control's own coordinates. The parent
## ScrollContainer owns the scroll offset, so it has to tell us; without it we
## would redraw a thousand levels to show eight.
## Redraws only when the window has actually moved onto different slots.
##
## This fires on every scroll event, and a flick produces a great many of them.
## Repainting the whole visible path - plates, laurels, crown, path strokes,
## studs and scattered gems - for a two-pixel change was the stutter: the work
## is identical until the slot range changes, so the redraw is not.
## Furthest the map can be scrolled: everything below the viewport.
func max_scroll() -> float:
	return maxf(0.0, content_height() - size.y)


## Moves the map by a finger delta and records the speed for the release glide.
func _apply_drag(relative_y: float) -> void:
	var before := _scroll
	_scroll = clampf(_scroll - relative_y, 0.0, max_scroll())
	var moved := _scroll - before
	var delta := maxf(get_process_delta_time(), MIN_FRAME_DELTA)
	# Blended rather than taken raw, so one jittery event cannot throw the glide.
	_velocity = lerpf(_velocity, moved / delta, VELOCITY_BLEND)
	if not is_equal_approx(before, _scroll):
		_refresh_visible()


## Repaints only when the visible slot range has actually changed. Between those
## points the drawn content is identical and simply moves with the transform.
func _refresh_visible() -> void:
	if _drawn_range != _visible_slot_range():
		queue_redraw()
	if _animated_layer != null:
		_animated_layer.queue_redraw()


## Position of a fractional slot. Drawing walks it in CURVE_STEPS increments to
## trace the path; hit testing evaluates it at whole slots. Slot 0 sits at the
## bottom, so the path climbs as the level number rises.
func _point_at(slot: float) -> Vector2:
	var swing := minf(size.x * SWING_RATIO, SWING_MAX)
	var x := size.x * 0.5 + sin(slot * TAU / SWING_PERIOD) * swing
	var y := content_height() - BOTTOM_PAD - slot * ROW_HEIGHT
	return Vector2(x, y)


## Scroll offset that puts a level in the middle of a viewport `viewport_height`
## tall, clamped so the map never scrolls past either end.
func scroll_offset_for_level(level_number: int, viewport_height: float) -> float:
	var centre := _point_at(float(LevelMilestoneType.slot_for_level(level_number))).y
	return clampf(centre - viewport_height * 0.5, 0.0, maxf(0.0, content_height() - viewport_height))


func _slot_in_window(slot: int) -> bool:
	var y := _point_at(float(slot)).y
	return y >= _scroll - ROW_HEIGHT and y <= _scroll + size.y + ROW_HEIGHT


## Inclusive slot range covering the window plus BLEED_ROWS on each side.
##
## The bleed is generous on purpose. The map repaints only when this range
## changes, so a wider range means fewer repaints during a flick - at one row of
## bleed the range changed every 182px of travel, which during a fast scroll is
## several full repaints a second and each one was a visible hitch.
func _visible_slot_range() -> Vector2i:
	var height := content_height()
	var lowest := int(floor((height - BOTTOM_PAD - (_scroll + size.y)) / ROW_HEIGHT)) - BLEED_ROWS
	var highest := int(ceil((height - BOTTOM_PAD - _scroll) / ROW_HEIGHT)) + BLEED_ROWS
	return Vector2i(maxi(0, lowest), mini(_slot_count - 1, maxi(0, highest)))


func _draw() -> void:
	if _slot_count <= 0:
		return
	var range_slots := _visible_slot_range()
	if range_slots.y < range_slots.x:
		return
	_drawn_range = range_slots
	# Everything below is authored in content space. Shifting once here is what
	# lets the whole map scroll without this control being content-sized.
	draw_set_transform(Vector2(0.0, -_scroll))
	_draw_scatter(range_slots)
	_draw_path(range_slots)
	for slot in range(range_slots.x, range_slots.y + 1):
		var contents := LevelMilestoneType.slot_contents(slot)
		var chest_index := int(contents.get("chest", 0))
		if chest_index > 0:
			_draw_chest(slot, chest_index)
		else:
			_draw_level(slot, int(contents.get("level", 0)))


## One polyline per state change. The path behind the player is gold and lit;
## ahead of them it is unlit stone, which is what makes progress legible at a
## glance without reading a single number.
func _draw_path(range_slots: Vector2i) -> void:
	var lit: PackedVector2Array = []
	var unlit: PackedVector2Array = []
	var start := maxf(0.0, float(range_slots.x) - 1.0)
	var finish := minf(float(_slot_count - 1), float(range_slots.y) + 1.0)
	var step := 1.0 / float(CURVE_STEPS)
	var cursor := start
	# The lit run always ends at the player's own slot, so the two polylines meet
	# exactly under the current node rather than at the nearest subdivision.
	var boundary := float(LevelMilestoneType.slot_for_level(highest_level))
	while cursor <= finish + step * 0.5:
		var slot := minf(cursor, finish)
		var point := _point_at(slot)
		if slot <= boundary:
			lit.append(point)
		if slot >= boundary:
			unlit.append(point)
		cursor += step
	# Casing, body, gloss - in that order, so each stroke sits inside the one
	# before it and the path reads as a raised road rather than a stroke.
	if unlit.size() >= 2:
		draw_polyline(unlit, Color(0.06, 0.02, 0.11, 0.85), PATH_CASING_WIDTH, true)
		draw_polyline(unlit, Color(0.30, 0.21, 0.44, 0.95), PATH_WIDTH, true)
		draw_polyline(unlit, Color(0.44, 0.33, 0.60, 0.55), PATH_GLOSS_WIDTH, true)
	if lit.size() >= 2:
		draw_polyline(lit, Color(0.28, 0.13, 0.03, 0.85), PATH_CASING_WIDTH, true)
		draw_polyline(lit, UiDesignSystemType.COLOR_GOLD, PATH_WIDTH, true)
		draw_polyline(lit, UiDesignSystemType.COLOR_GOLD_LIGHT, PATH_GLOSS_WIDTH, true)
	_draw_path_studs(range_slots)


## A kit diamond set into the path midway between each pair of nodes. It breaks
## up what would otherwise be a long unbroken ribbon and ties the path to the
## same gem language as the rest of the screen.
func _draw_path_studs(range_slots: Vector2i) -> void:
	var boundary := float(LevelMilestoneType.slot_for_level(highest_level))
	for slot in range(range_slots.x, range_slots.y + 1):
		var midpoint := float(slot) + 0.5
		if midpoint > float(_slot_count - 1):
			continue
		var lit := midpoint <= boundary
		_draw_texture_centred(
			DECOR_DIAMOND_SMALL,
			_point_at(midpoint),
			STUD_WIDTH,
			Color(1.0, 1.0, 1.0, 0.95) if lit else Color(0.52, 0.46, 0.62, 0.80)
		)


func _draw_level(slot: int, level_number: int) -> void:
	if level_number <= 0:
		return
	var centre := _point_at(float(slot))
	var cleared := level_number < highest_level
	var current := level_number == highest_level
	var locked := level_number > highest_level

	var edge := CURRENT_PLATE if current else NODE_PLATE
	var plate := _plate_locked
	var text_colour := Color(0.80, 0.74, 0.88)
	if current:
		plate = _plate_current
		text_colour = Color.WHITE
	elif cleared:
		plate = _plate_cleared
		text_colour = UiDesignSystemType.COLOR_TEXT

	if current:
		# The breathing halo is drawn on the animation layer, not here - see
		# _draw_animated_layer.
		# The crown marks the frontier, matching how the reference map crowns the
		# level the player is standing on.
		_draw_texture_centred(UiKitType.BADGE_CROWN, centre + Vector2(0.0, -edge * 0.68), CROWN_WIDTH)

	_draw_plate(plate, centre, edge)
	_draw_centred_number(centre, str(level_number), text_colour)

	if cleared:
		# The kit's laurelled tick, the same mark a completed daily mission wears.
		_draw_texture_centred(UiKitType.BADGE_CHECK_LAUREL, centre + Vector2(edge * 0.40, -edge * 0.40), LAUREL_WIDTH)


func _draw_chest(slot: int, chest_index: int) -> void:
	var centre := _point_at(float(slot))
	var unlocked := chest_index <= LevelMilestoneType.unlocked_chest_count(highest_level)
	var claimed := claimed_chests.has(chest_index)

	_draw_plate(_plate_chest if unlocked else _plate_chest_locked, centre, CHEST_PLATE)

	# The same chest art the daily missions screen uses, in the same two states,
	# so an opened chest looks opened wherever the player meets one.
	var texture: Texture2D = UiKitType.BADGE_CHEST_OPEN if claimed else UiKitType.BADGE_CHEST
	_draw_texture_centred(
		texture,
		centre,
		CHEST_PLATE * 0.68,
		Color.WHITE if unlocked else Color(0.58, 0.52, 0.66, 0.88)
	)



## Nine-patched so the plate's gold rim keeps its authored thickness at every
## size the map draws it at.
func _draw_plate(plate: StyleBox, centre: Vector2, edge: float) -> void:
	if plate == null:
		return
	if _plate_shadow != null:
		var shadow_edge := edge * SHADOW_SPREAD
		_plate_shadow.draw(get_canvas_item(), Rect2(
			centre - Vector2(shadow_edge, shadow_edge) * 0.5 + Vector2(0.0, edge * SHADOW_DROP),
			Vector2(shadow_edge, shadow_edge)
		))
	plate.draw(get_canvas_item(), Rect2(centre - Vector2(edge, edge) * 0.5, Vector2(edge, edge)))


## Draws a kit texture centred on `centre` at `width`, keeping its own aspect so
## none of the supplied art is ever stretched.
func _draw_texture_centred(texture: Texture2D, centre: Vector2, width: float, tint: Color = Color.WHITE) -> void:
	if texture == null:
		return
	var source := texture.get_size()
	if source.x <= 0.0:
		return
	var drawn := Vector2(width, width * source.y / source.x)
	draw_texture_rect(texture, Rect2(centre - drawn * 0.5, drawn), false, tint)


func _draw_centred_number(centre: Vector2, text: String, colour: Color) -> void:
	var font := UiDesignSystemType.heavy_font()
	var font_size := 38 if text.length() <= 3 else (32 if text.length() == 4 else 26)
	var measured := _measure(font, text, font_size)
	var origin := centre - Vector2(measured.x * 0.5, -measured.y * 0.32)
	# One outline pass, not eight.
	#
	# This used to ring the glyphs with eight offset draw_string calls, which
	# meant nine text batches per number and, with a dozen numbers on screen,
	# over a hundred per repaint. That was the single biggest cost in the map's
	# draw and the main reason a flick stuttered. draw_string_outline does the
	# same job in one call, using the font's own outline pass.
	font.draw_string_outline(
		get_canvas_item(), origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
		font_size, NUMBER_OUTLINE_SIZE, UiDesignSystemType.COLOR_PURPLE_DEEP
	)
	font.draw_string(get_canvas_item(), origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, colour)




## Selection happens on release, and only if the finger barely moved.
##
## Acting on press made every attempt to flick the map open a level instead: the
## first event of a scroll gesture is a press on whatever node is under the
## finger. Comparing press and release positions separates a tap from a drag.
## Scrolling is owned here, not by a ScrollContainer.
##
## Two things were wrong with the container. It required this view to BE the
## content, which for a thousand levels meant a node 186,000px tall inside a
## container that re-laid it out on every scroll. And because a drag starting on
## a custom-drawn child was not reliably claimed by the container, a handler had
## been added that wrote `scroll_vertical` directly from each drag event - whole
## pixels, no velocity, dead stop the instant the finger lifted. That is what
## "not smooth" was: not frame rate, but a scroll with no momentum and integer
## steps.
##
## Owning the offset keeps this control exactly viewport-sized, makes content
## height irrelevant, and puts the flick physics here where they can be tuned.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag or (event is InputEventMouseMotion and _dragging):
		_apply_drag(event.relative.y)
		accept_event()
		return
	if event is InputEventPanGesture:
		_apply_drag(-event.delta.y * PAN_GESTURE_SCALE)
		accept_event()
		return
	if not (event is InputEventScreenTouch or event is InputEventMouseButton):
		return
	if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		_press_position = event.position
		_press_active = true
		_dragging = true
		# Catching a moving map is how a player stops it, so a press kills the
		# glide rather than fighting it.
		_velocity = 0.0
		return
	_dragging = false
	if not _press_active:
		return
	_press_active = false
	if event.position.distance_to(_press_position) > TAP_MOVE_TOLERANCE:
		# The finger travelled: this was a flick, not a choice. The velocity built
		# up during the drag carries on from here.
		return
	_velocity = 0.0
	var hit := slot_at_position(event.position)
	if hit < 0:
		return
	var contents := LevelMilestoneType.slot_contents(hit)
	var chest_index := int(contents.get("chest", 0))
	if chest_index > 0:
		if chest_index <= LevelMilestoneType.unlocked_chest_count(highest_level):
			chest_selected.emit(chest_index)
			accept_event()
		return
	var level_number := int(contents.get("level", 0))
	# A locked level is not an error worth reporting - the plate already reads as
	# unreachable - so the tap is simply left for the ScrollContainer to treat as
	# the start of a flick.
	if level_number > 0 and level_number <= highest_level:
		level_selected.emit(level_number)
		accept_event()


## Slot whose plate contains `point`, or -1. `point` arrives in this control.s
## own space, so it is lifted into content space before it is compared. Only slots near the window are
## considered, which is both faster and correct: a tap can only land on
## something the player can see.
func slot_at_position(point: Vector2) -> int:
	var content_point := point + Vector2(0.0, _scroll)
	var range_slots := _visible_slot_range()
	for slot in range(range_slots.x, range_slots.y + 1):
		var contents := LevelMilestoneType.slot_contents(slot)
		var radius := CHEST_RADIUS if int(contents.get("chest", 0)) > 0 else NODE_RADIUS
		if content_point.distance_to(_point_at(float(slot))) <= radius + TAP_SLOP:
			return slot
	return -1


## Decorative gems behind the path, filling the empty side of each row.
##
## Positions come from a slot-seeded RNG rather than a stored list, so nothing
## has to be allocated for a thousand levels and the same slot always scatters
## the same way - a map that reshuffled its decoration on every scroll would
## shimmer. They are drawn before the path and well below full opacity so they
## read as background, and they are never hit-tested: only levels and chests
## are tappable.
func _draw_scatter(range_slots: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	for slot in range(maxi(0, range_slots.x - 1), range_slots.y + 2):
		if slot >= _slot_count:
			break
		rng.seed = int(slot) * 7919 + 104729
		var anchor := _point_at(float(slot))
		for index in range(SCATTER_PER_SLOT):
			# Placed on the far side of the screen from the path, so the gap the
			# serpentine leaves is what gets filled.
			var away := -signf(anchor.x - size.x * 0.5)
			if is_zero_approx(away):
				away = 1.0 if index % 2 == 0 else -1.0
			var spread := rng.randf_range(SCATTER_PATH_CLEARANCE, maxf(SCATTER_PATH_CLEARANCE, size.x * 0.44))
			var point := Vector2(
				clampf(anchor.x + away * spread, 40.0, size.x - 40.0),
				anchor.y + rng.randf_range(-ROW_HEIGHT * 0.42, ROW_HEIGHT * 0.42)
			)
			var edge := rng.randf_range(SCATTER_MIN_SIZE, SCATTER_MAX_SIZE)
			# Anything that lands too near the path is dropped rather than nudged:
			# nudging would pile them along a line just outside the clearance.
			if absf(point.x - _point_at(float(slot)).x) < SCATTER_PATH_CLEARANCE * 0.8:
				continue
			var texture := AssetCatalogType.gem_texture(rng.randi_range(1, 8))
			_draw_texture_centred(texture, point, edge, Color(1.0, 1.0, 1.0, SCATTER_ALPHA))


## Cached text measurement. See `_measure_cache`.
func _measure(font: Font, text: String, font_size: int) -> Vector2:
	var key := "%d:%s" % [font_size, text]
	var cached = _measure_cache.get(key)
	if cached != null:
		return cached
	var measured := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	_measure_cache[key] = measured
	return measured


## Carries a released flick on and brings it to rest.
##
## Exponential friction rather than a fixed deceleration, so the glide reads the
## same on a 60Hz and a 120Hz screen.
func _advance_glide(delta: float) -> void:
	if _dragging or absf(_velocity) < MIN_GLIDE_SPEED:
		if not _dragging and not is_zero_approx(_velocity):
			_velocity = 0.0
		return
	var before := _scroll
	_scroll = clampf(_scroll + _velocity * delta, 0.0, max_scroll())
	_velocity *= pow(FRICTION, delta)
	if is_equal_approx(before, _scroll):
		# Hit an end; nothing left to carry.
		_velocity = 0.0
		return
	_refresh_visible()


## Puts `level_number` in the middle of a `clear_height` band. Used on open, so
## the player's own level is what the screen lands on.
func scroll_to_level(level_number: int, clear_height: float, top_inset: float = 0.0) -> void:
	var centre := _point_at(float(LevelMilestoneType.slot_for_level(level_number))).y
	_velocity = 0.0
	_scroll = clampf(centre - clear_height * 0.5 - top_inset, 0.0, max_scroll())
	_drawn_range = Vector2i(-1, -1)
	queue_redraw()
	if _animated_layer != null:
		_animated_layer.queue_redraw()


func scroll_offset() -> float:
	return _scroll
