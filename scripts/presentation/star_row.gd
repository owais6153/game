class_name StarRow
extends Control

## A row of level stars, drawn from the supplied star art.
##
## Every consumer is presentation: the level-start screen shows an empty row of
## what is being asked for, the result popup fills that row one star at a time,
## the level map draws a small row under each cleared node, and the level-select
## header draws one beside the running total. None of them owns a rule; they all
## render `LevelStars` output.
##
## The three textures come from one supplied sheet, sliced by
## `scripts/dev/prepare_star_kit_art.gd`. They are drawn here rather than
## mounted as `TextureRect` children because a star has to be scaled, bloomed
## and burst individually while the row it sits in stays perfectly still - three
## child nodes with their own transforms would move the row's layout every time
## one of them overshot.
##
## ## Stars fill in sequence
##
## Two stars earned lights the first two, always. The row is a score out of
## three, not a checklist of which objectives were met - that is what the
## caption under it is for, and it is how the map and the header already read.
## Lighting the first and third with a gap between them was tried and is simply
## confusing: a player who earned two stars expects to see two, together.

const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")
const UiKitType = preload("res://scripts/ui/ui_kit.gd")
const LevelStarsType = preload("res://scripts/core/level_stars.gd")

## The award: the star grows out of its own empty placeholder, overshoots hard,
## and settles back onto exactly the placeholder's size and position.
##
## It does not fly in from elsewhere and it does not spin. A star that arrives
## from off its slot has to be tracked by the eye before it can be read, and at
## three in a row that reads as busy rather than as earned. Growing in place
## keeps the row still and puts the whole of the motion on the one thing that
## changed - which is also what lets the overshoot be this large without the
## screen feeling like it is shaking.
const AWARD_START_SCALE := 0.10
const AWARD_PEAK_SCALE := 1.62
## Fraction of the award spent growing to the peak; the rest settles back.
const AWARD_RISE_SHARE := 0.46
## A small secondary bounce after the settle, so the star lands with weight
## instead of easing politely into place.
const AWARD_BOUNCE_SCALE := 1.08
const AWARD_BOUNCE_SHARE := 0.22

## The supplied glow star, drawn behind an earned one as it lands. It carries
## its own halo, so at this multiple of the star size it reads as light coming
## off the star rather than as a second star behind it.
const GLOW_SCALE := 1.85
const GLOW_PEAK_ALPHA := 0.95

## What the landing leaves behind: an expanding ring and a short ray burst.
const BURST_RING_WIDTH := 5.0
const BURST_RING_MAX := 2.4
const BURST_RAYS := 10
const BURST_RAY_INNER := 0.75
const BURST_RAY_OUTER := 1.95
const BURST_RAY_WIDTH := 3.5

## A lit star keeps a slow shimmer, so a finished row is not a static picture.
const SHIMMER_PERIOD := 2.2
const SHIMMER_SCALE := 0.030

## Tint of the ring and rays, taken from the supplied art's own gold.
const COLOR_BURST := Color("ffd46d")

## Star height and the gap between stars, both in design pixels. Height rather
## than width: the supplied stars are wider than they are tall, and sizing by
## height is what keeps a row of them on one baseline.
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
			_glow[index] = 0.0
		queue_redraw()

## Per-star animation state, all presentation. `_scale` is a multiplier on the
## resting size, so 1.0 is a settled star - not zero, which would read as a star
## still growing and is what once drew every un-animated star at arrival size.
var _fill: Array[float] = []
var _scale: Array[float] = []
var _burst: Array[float] = []
var _glow: Array[float] = []
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


## Lands one star: it grows out of its own placeholder, overshoots, bounces once
## and settles onto exactly the placeholder's size. Returns the tween so a
## caller can chain the next star behind it.
func award(index: int, duration: float = 0.62) -> Tween:
	if index < 0 or index >= star_count:
		return null
	_resize_state()
	_fill[index] = 0.0
	_scale[index] = AWARD_START_SCALE
	_burst[index] = 0.0
	_glow[index] = 0.0
	var rise := duration * AWARD_RISE_SHARE
	var bounce := duration * AWARD_BOUNCE_SHARE
	var settle := maxf(0.05, duration - rise - bounce)
	var tween := create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# Solid almost immediately: the growth is the animation, and fading through
	# it made the star look like it was resolving rather than appearing.
	tween.tween_method(_set_fill.bind(index), 0.0, 1.0, rise * 0.45) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_scale.bind(index), AWARD_START_SCALE, AWARD_PEAK_SCALE, rise) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# The bloom rises with the star and fades over the whole settle, so the light
	# outlives the motion rather than snapping off with it.
	tween.tween_method(_set_glow.bind(index), 0.0, 1.0, rise) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Ring and rays fire at the peak, so the impact reads as the star landing on
	# its slot rather than as something happening while it is still growing.
	tween.tween_method(_set_burst.bind(index), 0.0, 1.0, settle + bounce).set_delay(rise) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_glow.bind(index), 1.0, 0.0, settle + bounce).set_delay(rise) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_method(_set_scale.bind(index), AWARD_PEAK_SCALE, AWARD_BOUNCE_SCALE, settle) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_method(_set_scale.bind(index), AWARD_BOUNCE_SCALE, 1.0, bounce) \
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


func _set_glow(value: float, index: int) -> void:
	_glow[index] = value
	queue_redraw()


func _resize_state() -> void:
	var previous := _scale.size()
	_fill.resize(star_count)
	_scale.resize(star_count)
	_burst.resize(star_count)
	_glow.resize(star_count)
	# `resize` zero-fills, and zero is a star scaled to nothing. A star that has
	# never been awarded is at rest, not mid-award.
	for index in range(previous, star_count):
		_scale[index] = 1.0


## Deliberately tight: the box is the stars themselves, not the space the
## arrival sweeps through. `clip_contents` is off by default on Control and on
## every container these rows sit in, so the overshoot, the bloom and the ring
## draw past these bounds without being cut - and reserving room for them made
## every static row about twice the height of the star inside it.
func _measure() -> Vector2:
	var width := float(star_count) * _star_width() + float(star_count - 1) * spacing
	return Vector2(width, star_size * 1.10)


## The supplied star is wider than it is tall, so a row laid out on height alone
## would overlap. Slot width follows the art's own aspect.
func _star_width() -> float:
	var texture := UiKitType.STAR_FILLED
	if texture == null or texture.get_height() <= 0:
		return star_size
	return star_size * float(texture.get_width()) / float(texture.get_height())


func _draw() -> void:
	if star_count <= 0:
		return
	var slot := _star_width()
	var total := float(star_count) * slot + float(star_count - 1) * spacing
	var origin := (size.x - total) * 0.5 + slot * 0.5
	var centre_y := size.y * 0.5
	for index in range(star_count):
		var centre := Vector2(origin + float(index) * (slot + spacing), centre_y)
		var fill: float = _fill[index] if index < _fill.size() else 0.0
		var star_scale: float = _scale[index] if index < _scale.size() else 1.0
		var burst: float = _burst[index] if index < _burst.size() else 0.0
		var glow: float = _glow[index] if index < _glow.size() else 0.0

		# The empty placeholder is always drawn, and a star grows out of it, so
		# the slot is visible before, during and after the award.
		_draw_texture(UiKitType.STAR_EMPTY, centre, star_size, Color(1.0, 1.0, 1.0, 1.0))
		if fill <= 0.0:
			continue

		if shimmer_enabled and fill >= 0.999 and is_equal_approx(star_scale, 1.0):
			star_scale = 1.0 + sin(_shimmer * TAU / SHIMMER_PERIOD + float(index) * 1.1) * SHIMMER_SCALE

		if glow > 0.0:
			_draw_texture(UiKitType.STAR_GLOW, centre, star_size * GLOW_SCALE * star_scale,
				Color(1.0, 1.0, 1.0, GLOW_PEAK_ALPHA * glow))
		if burst > 0.0 and burst < 1.0:
			_draw_burst(centre, burst)
		_draw_texture(UiKitType.STAR_FILLED, centre, star_size * star_scale,
			Color(1.0, 1.0, 1.0, fill))


## Draws one kit texture centred on `centre` at `height`, preserving its aspect.
func _draw_texture(texture: Texture2D, centre: Vector2, height: float, modulate: Color) -> void:
	if texture == null or texture.get_height() <= 0 or height <= 0.0:
		return
	var width := height * float(texture.get_width()) / float(texture.get_height())
	draw_texture_rect(texture, Rect2(centre - Vector2(width, height) * 0.5, Vector2(width, height)),
		false, modulate)


## The ring and short rays a landing star leaves behind. No filled disc: a solid
## circle behind a star reads as a badge the star is sitting on rather than as
## light coming off it - the supplied glow texture does that job.
func _draw_burst(centre: Vector2, burst: float) -> void:
	var fade := 1.0 - burst
	var radius := star_size * 0.5
	draw_arc(centre, radius * lerpf(0.9, BURST_RING_MAX, burst), 0.0, TAU, 30,
		Color(COLOR_BURST, fade * 0.75), BURST_RING_WIDTH, true)
	var inner := radius * lerpf(0.6, BURST_RAY_INNER, burst)
	var outer := radius * lerpf(0.8, BURST_RAY_OUTER, burst)
	if outer <= inner:
		return
	for index in range(BURST_RAYS):
		var angle := -PI * 0.5 + TAU * float(index) / float(BURST_RAYS)
		var direction := Vector2(cos(angle), sin(angle))
		draw_line(centre + direction * inner, centre + direction * outer,
			Color(COLOR_BURST, fade * 0.60), BURST_RAY_WIDTH, true)
