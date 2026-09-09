class_name TreasureVfx
extends Control

## The light show behind a treasure chest. Drawing only: it owns no reward, no
## texture and no layout, and the overlay above it is free to run with the whole
## effect switched off.
##
## Everything here is drawn in `_draw()` rather than built from nodes or
## particles for the same reason the level map is drawn: this sits on top of a
## live gameplay scene on low-end phones, and a Node2D-per-ray design would
## allocate and lay out a few hundred nodes for an effect that lasts a few
## seconds. One immediate-mode pass costs a draw call.
##
## The composition is three layers, back to front, and the order matters - the
## rays must never draw over the sparkles or the whole thing reads as flat:
##
##   1. A slow fan of god rays turning behind the chest.
##   2. Two breathing halos that give the rays somewhere to come from.
##   3. Sparkles orbiting on their own periods, so the ring never pulses in
##      lockstep and never looks like a loading spinner.
##
## `intensity` scales all three together. The overlay opens it from zero, kicks
## it past one at the moment the lid gives, and lets it fall back - which is
## what makes the burst read as the chest opening rather than as a light that
## was always on.

const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")

const RAY_COUNT := 16
## Half-width of a ray at its tip, in radians. Narrow enough that sixteen of
## them still leave dark gaps to turn through.
const RAY_HALF_ANGLE := 0.052
const RAY_SPIN_SPEED := 0.22
const RAY_INNER_RADIUS := 46.0

const HALO_COUNT := 2
const HALO_BREATH_PERIOD := 2.1

const SPARKLE_COUNT := 18
const SPARKLE_ORBIT_MIN := 0.62
const SPARKLE_ORBIT_MAX := 1.02

## Ceiling on the burst. The overlay drives `intensity` through a tween that
## overshoots; without a bound a mistimed tween could wash the reward card out.
const INTENSITY_MAX := 1.6

## How far the effect reaches, as a fraction of the smaller screen dimension.
const REACH := 0.62

var intensity := 0.0:
	set(value):
		intensity = clampf(value, 0.0, INTENSITY_MAX)
		queue_redraw()

## Where the chest sits, in this control's own space. The overlay pushes the
## chest's real centre down here rather than the effect assuming the middle of
## the screen, because the chest rides a container that moves as reward cards
## push it up.
var focus := Vector2.ZERO:
	set(value):
		focus = value
		queue_redraw()

var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	# Nothing to advance while the effect is off, so a dismissed overlay left in
	# the tree costs one comparison per frame instead of a full-screen repaint.
	if intensity <= 0.0:
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	if intensity <= 0.0 or size.x <= 0.0 or size.y <= 0.0:
		return
	var reach := minf(size.x, size.y) * REACH
	var gold := UiDesignSystemType.COLOR_GOLD_LIGHT
	_draw_rays(reach, gold)
	_draw_halos(reach, gold)
	_draw_sparkles(reach, gold)


## A fan of tapered triangles. Alternating rays are longer and brighter so the
## fan reads as depth rather than as a wheel of identical spokes.
func _draw_rays(reach: float, gold: Color) -> void:
	var spin := _time * RAY_SPIN_SPEED
	for index in range(RAY_COUNT):
		var angle := spin + TAU * float(index) / float(RAY_COUNT)
		var long_ray := index % 2 == 0
		var length := reach * (1.0 if long_ray else 0.72) * clampf(intensity, 0.0, 1.0)
		var alpha := (0.20 if long_ray else 0.12) * intensity
		if alpha <= 0.004 or length <= RAY_INNER_RADIUS:
			continue
		var tip := focus + Vector2(cos(angle), sin(angle)) * length
		var left := focus + Vector2(cos(angle - RAY_HALF_ANGLE), sin(angle - RAY_HALF_ANGLE)) * RAY_INNER_RADIUS
		var right := focus + Vector2(cos(angle + RAY_HALF_ANGLE), sin(angle + RAY_HALF_ANGLE)) * RAY_INNER_RADIUS
		draw_colored_polygon(PackedVector2Array([left, tip, right]), Color(gold, alpha))


## Two soft discs breathing on the same period at different radii. They are what
## the rays appear to emanate from; without them the fan hangs in space.
func _draw_halos(reach: float, gold: Color) -> void:
	var breath := 1.0 + sin(_time * TAU / HALO_BREATH_PERIOD) * 0.06
	for index in range(HALO_COUNT):
		var radius := reach * (0.46 - float(index) * 0.16) * breath * clampf(intensity, 0.0, 1.0)
		if radius <= 1.0:
			continue
		draw_circle(focus, radius, Color(gold, (0.10 + float(index) * 0.06) * intensity))


## Sparkles on independent orbits. The per-index period offsets are deliberate:
## a shared period makes eighteen dots contract and expand together, which reads
## as a progress spinner rather than as glinting treasure.
func _draw_sparkles(reach: float, gold: Color) -> void:
	for index in range(SPARKLE_COUNT):
		var phase := float(index) * 0.7391
		var orbit_speed := 0.38 + float(index % 5) * 0.09
		var angle := phase * TAU + _time * orbit_speed * (1.0 if index % 2 == 0 else -1.0)
		var bob := sin(_time * (1.4 + float(index % 3) * 0.5) + phase * TAU)
		var distance := reach * lerpf(SPARKLE_ORBIT_MIN, SPARKLE_ORBIT_MAX, absf(bob))
		var radius := (2.6 + absf(bob) * 3.4) * clampf(intensity, 0.0, 1.0)
		if radius <= 0.3:
			continue
		var point := focus + Vector2(cos(angle), sin(angle)) * distance
		draw_circle(point, radius, Color(gold, (0.34 + absf(bob) * 0.36) * minf(intensity, 1.0)))
		draw_circle(point, radius * 0.45, Color(1.0, 1.0, 1.0, 0.5 * minf(intensity, 1.0)))
