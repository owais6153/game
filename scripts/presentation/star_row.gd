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

const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")
const LevelStarsType = preload("res://scripts/core/level_stars.gd")

## Points per star, and how far the inner vertices sit from the centre. 0.45 is
## a conventional five-point star; much below it the shape reads as a splash and
## much above it as a pentagon.
const POINTS := 5
const INNER_RATIO := 0.45
## Stars sit point-up. Without this they are drawn point-right.
const ROTATION_OFFSET := -PI * 0.5

## How far an awarding star swells before settling. Applied per star, so a star
## can pop inside a row that is not moving.
const POP_SCALE := 1.55
## Ring left behind by a star as it lands.
const BURST_RING_WIDTH := 4.0
const BURST_RING_MAX := 2.4

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

## How many stars are lit. Setting this directly is the static case - the level
## map and the level-start screen both use it; the result popup calls
## `award()` instead so each star arrives on its own.
var filled := 0:
	set(value):
		# Resized here as well as in _ready(), because a caller may set `filled`
		# on a row it has only just constructed - before the node has entered the
		# tree - and indexing an empty state array would be a runtime error.
		_resize_state()
		filled = clampi(value, 0, star_count)
		for index in range(star_count):
			_fill[index] = 1.0 if index < filled else 0.0
			_pop[index] = 0.0
			_burst[index] = 0.0
		queue_redraw()

## Per-star animation state, all presentation.
var _fill: Array[float] = []
var _pop: Array[float] = []
var _burst: Array[float] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resize_state()
	custom_minimum_size = _measure()


## Lights one star with a pop and a ring. Returns the tween so a caller can
## chain the next star behind it; `LevelStars` decides which stars are lit, this
## only decides how they arrive.
func award(index: int, duration: float = 0.42) -> Tween:
	if index < 0 or index >= star_count:
		return null
	_resize_state()
	filled = maxi(filled, index + 1)
	_fill[index] = 0.0
	_pop[index] = 0.0
	_burst[index] = 0.0
	var tween := create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(func(value: float) -> void:
		_fill[index] = value
		queue_redraw(), 0.0, 1.0, duration * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(value: float) -> void:
		_burst[index] = value
		queue_redraw(), 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Overshoot then settle, driven as one method so the star's scale is a single
	# value the draw pass reads rather than a transform on a node inside a row.
	tween.tween_method(func(value: float) -> void:
		_pop[index] = value
		queue_redraw(), 0.0, 1.0, duration * 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_method(func(value: float) -> void:
		_pop[index] = value
		queue_redraw(), 1.0, 0.0, duration * 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tween


func _resize_state() -> void:
	_fill.resize(star_count)
	_pop.resize(star_count)
	_burst.resize(star_count)


func _measure() -> Vector2:
	var width := float(star_count) * star_size + float(star_count - 1) * spacing
	# Room for the pop and the ring, so an awarding star is never clipped by the
	# container that owns the row.
	return Vector2(width * 1.05, star_size * BURST_RING_MAX * 0.62)


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
		var burst: float = _burst[index] if index < _burst.size() else 0.0
		if burst > 0.0 and burst < 1.0:
			var ring := star_size * 0.5 * lerpf(0.8, BURST_RING_MAX, burst)
			draw_arc(centre, ring, 0.0, TAU, 28,
				Color(COLOR_FILLED, (1.0 - burst) * 0.7), BURST_RING_WIDTH, true)
		var radius := star_size * 0.5 * lerpf(1.0, POP_SCALE, pop)
		# The empty plate is always drawn, so a partly-filled star reads as a
		# star being filled rather than as a star growing out of nothing.
		_draw_star(centre, star_size * 0.5, COLOR_EMPTY, COLOR_EMPTY_RIM)
		if fill > 0.0:
			var colour := Color(COLOR_FILLED, fill)
			_draw_star(centre, radius, colour, Color(COLOR_FILLED_RIM, fill))


func _draw_star(centre: Vector2, radius: float, fill: Color, rim: Color) -> void:
	var points := PackedVector2Array()
	for index in range(POINTS * 2):
		var angle := ROTATION_OFFSET + TAU * float(index) / float(POINTS * 2)
		var reach := radius if index % 2 == 0 else radius * INNER_RATIO
		points.append(centre + Vector2(cos(angle), sin(angle)) * reach)
	draw_colored_polygon(points, fill)
	# Closing the outline explicitly; draw_polyline does not wrap.
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, rim, maxf(1.0, radius * 0.10), true)
