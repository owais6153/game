class_name StarRow
extends Control

## A row of level stars, drawn rather than assembled from textures.
##
## The kit has no star, and a star is one of the few shapes worth drawing: it
## needs an empty state, a filled state, and a state in between that can be
## animated per star while the row it sits in stays still. Three `TextureRect`s
## with a swap would give the first two and neither of the others.
##
## Every consumer is presentation: the level-start screen shows an empty row of
## what is being asked for, the result popup fills that row one star at a time,
## the level map draws a small row under each cleared node, and the level-select
## header draws one beside the running total. None of them owns a rule; they all
## render `LevelStars` output.
##
## ## Stars fill in sequence
##
## Two stars earned lights the first two, always. The row is a score out of
## three, not a checklist of which objectives were met - that is what the
## caption under it is for, and it is how the map and the header already read.
## Lighting the first and third with a gap between them was tried and is simply
## confusing: a player who earned two stars expects to see two, together.

const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")
const LevelStarsType = preload("res://scripts/core/level_stars.gd")

## Points per star, and how far the inner vertices sit from the centre. 0.45 is
## a conventional five-point star; much below it the shape reads as a splash and
## much above it as a pentagon.
const POINTS := 5
const INNER_RATIO := 0.45
## Stars sit point-up. Without this they are drawn point-right.
const ROTATION_OFFSET := -PI * 0.5

## The award: the star grows out of its own empty placeholder, overshoots a
## little, and settles back onto exactly the placeholder's size and position.
##
## It does not fly in from elsewhere and it does not spin. A star that arrives
## from off its slot has to be tracked by the eye before it can be read, and at
## three in a row that reads as busy rather than as earned. Growing in place
## keeps the row still and puts the whole of the motion on the one thing that
## changed.
const AWARD_START_SCALE := 0.15
const AWARD_PEAK_SCALE := 1.34
## Fraction of the award spent growing to the peak; the rest settles back.
const AWARD_RISE_SHARE := 0.55

## What the landing leaves behind: one expanding ring and a white bloom on the
## star itself. Both are brief - the star is the reward, not the effect.
const BURST_RING_WIDTH := 4.0
const BURST_RING_MAX := 2.1
const BURST_RAYS := 8
const BURST_RAY_INNER := 0.70
const BURST_RAY_OUTER := 1.65
const BURST_RAY_WIDTH := 2.5

## A lit star keeps a slow shimmer, so a finished row is not a static picture.
const SHIMMER_PERIOD := 2.2
const SHIMMER_SCALE := 0.030

const COLOR_FILLED := Color("ffd46d")
const COLOR_FILLED_RIM := Color("a9661c")
const COLOR_EMPTY := Color(0.32, 0.24, 0.44, 0.85)
const COLOR_EMPTY_RIM := Color(0.52, 0.42, 0.66, 0.75)

## Star radius and the gap between stars, both in design pixels.
var star_size := 34.0:
	set(value):
		star_size = maxf(4.0, value)
		custom_minimum_size = _measure()
		queue_redraw()

var spacing := 14.0:
	set(value):
		spacing = maxf(0.0, value)
		custom_minimum_size = _measure()
		queue_redraw()

var star_count := LevelStarsType.MAX_STARS:
	set(value):
		star_count = maxi(1, value)
		_resize_state()
		custom_minimum_size = _measure()
		queue_redraw()

## A lit shimmer runs only while this is on. The map, the header and the
## level-start screen draw static rows and leave it off.
var shimmer_enabled := false

## Lights the first `value` stars and clears the rest.
var filled := 0:
	set(value):
		# Resized here as well as in _ready(), because a caller may set this on a
		# row it has only just constructed - before the node has entered the tree
		# - and indexing an empty state array would be a runtime error.
		_resize_state()
		filled = clampi(value, 0, star_count)
		for index in range(star_count):
			_fill[index] = 1.0 if index < filled else 0.0
			_scale[index] = 1.0
			_burst[index] = 0.0
			_flash[index] = 0.0
		queue_redraw()

## Per-star animation state, all presentation. `_scale` is a multiplier on the
## resting size, so 1.0 is a settled star - not zero, which would read as a star
## still growing and is what once drew every un-animated star at arrival size.
var _fill: Array[float] = []
var _scale: Array[float] = []
var _burst: Array[float] = []
var _flash: Array[float] = []
var _shimmer := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resize_state()
	custom_minimum_size = _measure()
	set_process(true)


func _process(delta: float) -> void:
	if not shimmer_enabled or lit_count() <= 0:
		return
	_shimmer += delta
	queue_redraw()


## How many stars are currently lit. Counted from the per-star state rather than
## from a stored number, so it cannot drift from what is drawn.
func lit_count() -> int:
	var count := 0
	for value in _fill:
		if value >= 0.999:
			count += 1
	return count


func is_lit(index: int) -> bool:
	return index >= 0 and index < _fill.size() and _fill[index] >= 0.999


## Lands one star: it grows out of its own placeholder, overshoots, and settles
## back to exactly the placeholder's size. Returns the tween so a caller can
## chain the next star behind it.
func award(index: int, duration: float = 0.55) -> Tween:
	if index < 0 or index >= star_count:
		return null
	_resize_state()
	_fill[index] = 0.0
	_scale[index] = AWARD_START_SCALE
	_burst[index] = 0.0
	_flash[index] = 0.0
	var rise := duration * AWARD_RISE_SHARE
	var settle := duration - rise
	var tween := create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# Solid almost immediately: the growth is the animation, and fading through
	# it made the star look like it was resolving rather than appearing.
	tween.tween_method(_set_fill.bind(index), 0.0, 1.0, rise * 0.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_scale.bind(index), AWARD_START_SCALE, AWARD_PEAK_SCALE, rise) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Ring and bloom fire at the peak, so the impact reads as the star landing on
	# its slot rather than as something happening while it is still growing.
	tween.tween_method(_set_burst.bind(index), 0.0, 1.0, settle + 0.10).set_delay(rise) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_flash.bind(index), 1.0, 0.0, settle).set_delay(rise) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_method(_set_scale.bind(index), AWARD_PEAK_SCALE, 1.0, settle) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween


func _set_fill(value: float, index: int) -> void:
	_fill[index] = value
	queue_redraw()


func _set_scale(value: float, index: int) -> void:
	_scale[index] = value
	queue_redraw()


func _set_burst(value: float, index: int) -> void:
	_burst[index] = value
	queue_redraw()


func _set_flash(value: float, index: int) -> void:
	_flash[index] = value
	queue_redraw()


func _resize_state() -> void:
	var previous := _scale.size()
	_fill.resize(star_count)
	_scale.resize(star_count)
	_burst.resize(star_count)
	_flash.resize(star_count)
	# `resize` zero-fills, and zero is a star scaled to nothing. A star that has
	# never been awarded is at rest, not mid-award.
	for index in range(previous, star_count):
		_scale[index] = 1.0


## Deliberately tight: the box is the stars themselves, not the space the
## arrival sweeps through. `clip_contents` is off by default on Control and on
## every container these rows sit in, so the overshoot and the ring draw past
## these bounds without being cut - and reserving room for them made every
## static row about twice the height of the star inside it.
func _measure() -> Vector2:
	var width := float(star_count) * star_size + float(star_count - 1) * spacing
	return Vector2(width, star_size * 1.15)


func _draw() -> void:
	if star_count <= 0:
		return
	var total := float(star_count) * star_size + float(star_count - 1) * spacing
	var origin := (size.x - total) * 0.5 + star_size * 0.5
	var centre_y := size.y * 0.5
	for index in range(star_count):
		var centre := Vector2(origin + float(index) * (star_size + spacing), centre_y)
		var fill: float = _fill[index] if index < _fill.size() else 0.0
		var star_scale: float = _scale[index] if index < _scale.size() else 1.0
		var burst: float = _burst[index] if index < _burst.size() else 0.0
		var flash: float = _flash[index] if index < _flash.size() else 0.0

		# The empty placeholder is always drawn, and a star grows out of it, so
		# the slot is visible before, during and after the award.
		_draw_star(centre, star_size * 0.5, COLOR_EMPTY, COLOR_EMPTY_RIM)
		if fill <= 0.0:
			continue

		if burst > 0.0 and burst < 1.0:
			_draw_burst(centre, burst)

		if shimmer_enabled and fill >= 0.999 and is_equal_approx(star_scale, 1.0):
			star_scale = 1.0 + sin(_shimmer * TAU / SHIMMER_PERIOD + float(index) * 1.1) * SHIMMER_SCALE
		var radius := star_size * 0.5 * star_scale
		_draw_star(centre, radius, Color(COLOR_FILLED, fill), Color(COLOR_FILLED_RIM, fill))
		if flash > 0.0:
			_draw_star(centre, radius, Color(1.0, 1.0, 1.0, 0.70 * flash), Color(1.0, 1.0, 1.0, 0.0))


## The ring and short rays a landing star leaves behind. No filled disc: a solid
## circle behind a star reads as a badge the star is sitting on rather than as
## light coming off it.
func _draw_burst(centre: Vector2, burst: float) -> void:
	var fade := 1.0 - burst
	var ring := star_size * 0.5 * lerpf(0.9, BURST_RING_MAX, burst)
	draw_arc(centre, ring, 0.0, TAU, 28, Color(COLOR_FILLED, fade * 0.70), BURST_RING_WIDTH, true)
	var inner := star_size * 0.5 * lerpf(0.6, BURST_RAY_INNER, burst)
	var outer := star_size * 0.5 * lerpf(0.8, BURST_RAY_OUTER, burst)
	if outer <= inner:
		return
	for index in range(BURST_RAYS):
		var angle := ROTATION_OFFSET + TAU * float(index) / float(BURST_RAYS)
		var direction := Vector2(cos(angle), sin(angle))
		draw_line(centre + direction * inner, centre + direction * outer,
			Color(COLOR_FILLED, fade * 0.55), BURST_RAY_WIDTH, true)


func _draw_star(centre: Vector2, radius: float, fill: Color, rim: Color) -> void:
	var points := PackedVector2Array()
	for index in range(POINTS * 2):
		var angle := ROTATION_OFFSET + TAU * float(index) / float(POINTS * 2)
		var reach := radius if index % 2 == 0 else radius * INNER_RATIO
		points.append(centre + Vector2(cos(angle), sin(angle)) * reach)
	draw_colored_polygon(points, fill)
	if rim.a <= 0.0:
		return
	# Closing the outline explicitly; draw_polyline does not wrap.
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, rim, maxf(1.0, radius * 0.10), true)
