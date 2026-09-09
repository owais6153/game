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
## ## Lit state is per star, not a count
##
## `_fill` is the authority for which stars are lit, and `award()` touches only
## the index it is given. This was a real bug first time round: `award()` raised
## a `filled` *count*, so awarding the third star of a `[earned, missed, earned]`
## result lit all three and the popup said "2 of 3 stars" over a full row.
## A count cannot express a gap, and a gap is the normal case.

const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")
const LevelStarsType = preload("res://scripts/core/level_stars.gd")

## Points per star, and how far the inner vertices sit from the centre. 0.45 is
## a conventional five-point star; much below it the shape reads as a splash and
## much above it as a pentagon.
const POINTS := 5
const INNER_RATIO := 0.45
## Stars sit point-up. Without this they are drawn point-right.
const ROTATION_OFFSET := -PI * 0.5

## The award. A star drops in from well above its final size and spins down into
## place, rather than simply scaling up: the arrival is the reward, so it needs
## somewhere to arrive from.
const AWARD_START_SCALE := 2.9
const AWARD_START_SPIN := -1.25
## Overshoot the settle so the star lands with weight.
const AWARD_SETTLE_SCALE := 1.18

## What the landing leaves behind: an expanding ring, a short burst of rays, and
## a white flash on the star itself.
const BURST_RING_WIDTH := 5.0
const BURST_RING_MAX := 2.9
const BURST_RAYS := 10
const BURST_RAY_INNER := 0.62
const BURST_RAY_OUTER := 2.05
const BURST_RAY_WIDTH := 3.0

## A lit star keeps a slow shimmer, so a finished row is not a static picture.
const SHIMMER_PERIOD := 2.2
const SHIMMER_SCALE := 0.035

const COLOR_FILLED := Color("ffd46d")
const COLOR_FILLED_RIM := Color("a9661c")
const COLOR_EMPTY := Color(0.32, 0.24, 0.44, 0.85)
const COLOR_EMPTY_RIM := Color(0.52, 0.42, 0.66, 0.75)
const COLOR_GLOW := Color("ffb43a")

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

## A lit shimmer runs only while this is on. The map and the level-start screen
## draw static rows and leave it off.
var shimmer_enabled := false

## Lights the first `value` stars and clears the rest. The static case - the
## map, the header and the level-start screen. The result popup calls `award()`
## per star instead, because it has to express a gap.
var filled := 0:
	set(value):
		# Resized here as well as in _ready(), because a caller may set this on a
		# row it has only just constructed - before the node has entered the tree
		# - and indexing an empty state array would be a runtime error.
		_resize_state()
		filled = clampi(value, 0, star_count)
		for index in range(star_count):
			_fill[index] = 1.0 if index < filled else 0.0
			_pop[index] = 0.0
			_spin[index] = 0.0
			_burst[index] = 0.0
			_flash[index] = 0.0
		queue_redraw()

## Per-star animation state, all presentation.
var _fill: Array[float] = []
var _pop: Array[float] = []
var _spin: Array[float] = []
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


## Lands one star. Touches only `index` - a star the player did not earn stays
## empty even when a later one is awarded.
##
## Returns the tween so a caller can chain the next star behind it. `LevelStars`
## decides which stars are lit; this only decides how they arrive.
func award(index: int, duration: float = 0.55) -> Tween:
	if index < 0 or index >= star_count:
		return null
	_resize_state()
	_fill[index] = 0.0
	_pop[index] = 0.0
	_spin[index] = 0.0
	_burst[index] = 0.0
	_flash[index] = 0.0
	var tween := create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# The star becomes solid quickly, then keeps moving. Fading it in over the
	# whole arrival made it look like it was resolving rather than landing.
	tween.tween_method(_set_fill.bind(index), 0.0, 1.0, duration * 0.30) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Scale and spin share one timeline, so the star stops turning exactly as it
	# reaches its size.
	tween.tween_method(_set_pop.bind(index), 0.0, 1.0, duration * 0.62) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_spin.bind(index), 1.0, 0.0, duration * 0.62) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Ring and rays run the full length so the impact outlives the arrival.
	tween.tween_method(_set_burst.bind(index), 0.0, 1.0, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# A brief white bloom at the moment of landing.
	tween.tween_method(_set_flash.bind(index), 1.0, 0.0, duration * 0.45) \
		.set_delay(duration * 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tween


func _set_fill(value: float, index: int) -> void:
	_fill[index] = value
	queue_redraw()


func _set_pop(value: float, index: int) -> void:
	_pop[index] = value
	queue_redraw()


func _set_spin(value: float, index: int) -> void:
	_spin[index] = value
	queue_redraw()


func _set_burst(value: float, index: int) -> void:
	_burst[index] = value
	queue_redraw()


func _set_flash(value: float, index: int) -> void:
	_flash[index] = value
	queue_redraw()


func _resize_state() -> void:
	_fill.resize(star_count)
	_pop.resize(star_count)
	_spin.resize(star_count)
	_burst.resize(star_count)
	_flash.resize(star_count)


func _measure() -> Vector2:
	var width := float(star_count) * star_size + float(star_count - 1) * spacing
	# Room for the arrival scale and the ring, so a landing star is never clipped
	# by the container that owns the row.
	return Vector2(width * 1.06, star_size * BURST_RING_MAX * 0.66)


func _draw() -> void:
	if star_count <= 0:
		return
	var total := float(star_count) * star_size + float(star_count - 1) * spacing
	var origin := (size.x - total) * 0.5 + star_size * 0.5
	var centre_y := size.y * 0.5
	for index in range(star_count):
		var centre := Vector2(origin + float(index) * (star_size + spacing), centre_y)
		var fill: float = _fill[index] if index < _fill.size() else 0.0
		var pop: float = _pop[index] if index < _pop.size() else 0.0
		var spin: float = _spin[index] if index < _spin.size() else 0.0
		var burst: float = _burst[index] if index < _burst.size() else 0.0
		var flash: float = _flash[index] if index < _flash.size() else 0.0

		# The empty plate is always drawn, so a star being filled reads as a star
		# being filled rather than as one growing out of nothing.
		_draw_star(centre, star_size * 0.5, 0.0, COLOR_EMPTY, COLOR_EMPTY_RIM)
		if fill <= 0.0:
			continue

		if burst > 0.0 and burst < 1.0:
			_draw_burst(centre, burst)

		# `pop` runs 0 -> 1 as the star travels from its arrival size down to
		# rest; a settled star sits at 1 and only shimmers.
		var arrival := lerpf(AWARD_START_SCALE, 1.0, pop) if pop < 1.0 else 1.0
		var settle := 1.0
		if shimmer_enabled and fill >= 0.999 and pop >= 1.0:
			settle = 1.0 + sin(_shimmer * TAU / SHIMMER_PERIOD + float(index) * 1.1) * SHIMMER_SCALE
		var radius := star_size * 0.5 * arrival * settle
		var rotation := AWARD_START_SPIN * spin

		# A soft glow under a lit star gives the gold something to sit on.
		draw_circle(centre, radius * 1.05, Color(COLOR_GLOW, 0.20 * fill))
		_draw_star(centre, radius, rotation, Color(COLOR_FILLED, fill), Color(COLOR_FILLED_RIM, fill))
		if flash > 0.0:
			_draw_star(centre, radius, rotation, Color(1.0, 1.0, 1.0, 0.75 * flash), Color(1.0, 1.0, 1.0, 0.0))


## The ring and the ray burst a landing star leaves behind.
func _draw_burst(centre: Vector2, burst: float) -> void:
	var fade := 1.0 - burst
	var ring := star_size * 0.5 * lerpf(0.85, BURST_RING_MAX, burst)
	draw_arc(centre, ring, 0.0, TAU, 30, Color(COLOR_FILLED, fade * 0.75), BURST_RING_WIDTH, true)
	var inner := star_size * 0.5 * lerpf(0.5, BURST_RAY_INNER, burst)
	var outer := star_size * 0.5 * lerpf(0.7, BURST_RAY_OUTER, burst)
	if outer <= inner:
		return
	for index in range(BURST_RAYS):
		var angle := ROTATION_OFFSET + TAU * float(index) / float(BURST_RAYS)
		var direction := Vector2(cos(angle), sin(angle))
		draw_line(centre + direction * inner, centre + direction * outer,
			Color(COLOR_FILLED, fade * 0.60), BURST_RAY_WIDTH, true)


func _draw_star(centre: Vector2, radius: float, rotation: float, fill: Color, rim: Color) -> void:
	var points := PackedVector2Array()
	for index in range(POINTS * 2):
		var angle := ROTATION_OFFSET + rotation + TAU * float(index) / float(POINTS * 2)
		var reach := radius if index % 2 == 0 else radius * INNER_RATIO
		points.append(centre + Vector2(cos(angle), sin(angle)) * reach)
	draw_colored_polygon(points, fill)
	if rim.a <= 0.0:
		return
	# Closing the outline explicitly; draw_polyline does not wrap.
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, rim, maxf(1.0, radius * 0.10), true)
