class_name TargetRewardOverlay
extends Control

## HUD-layer confirmation for a collected target. Gameplay owns qualification;
## this node only presents the already-confirmed event above the target card.
var _active := false
var _elapsed := 0.0
var _center := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func play(center: Vector2) -> void:
	_center = center
	_elapsed = 0.0
	_active = true
	set_process(true)
	queue_redraw()


func reset() -> void:
	_active = false
	_elapsed = 0.0
	set_process(false)
	queue_redraw()


func is_reward_active() -> bool:
	return _active


func reward_elapsed() -> float:
	return _elapsed


func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	if _elapsed >= GameConfig.TARGET_PANEL_PULSE_DURATION:
		reset()
		return
	queue_redraw()


func _draw() -> void:
	if not _active:
		return
	var t := clampf(_elapsed / GameConfig.TARGET_PANEL_PULSE_DURATION, 0.0, 1.0)
	var reveal := smoothstep(0.0, 0.16, t)
	var fade := 1.0 - smoothstep(0.72, 1.0, t)
	var pop := 0.72 + 0.36 * (1.0 - pow(1.0 - minf(t / 0.24, 1.0), 3.0))
	if t > 0.24:
		pop = lerpf(1.08, 1.0, smoothstep(0.24, 0.62, t))
	var ring_radius := lerpf(34.0, 54.0, smoothstep(0.08, 1.0, t))
	draw_circle(_center, 39.0 * pop, Color(0.33, 0.78, 0.25, 0.96 * fade))
	draw_arc(_center, ring_radius, 0.0, TAU, 40, Color(1.0, 0.83, 0.22, 0.92 * fade), 5.0, true)
	draw_arc(_center, ring_radius + 8.0, 0.0, TAU, 40, Color(1.0, 0.95, 0.61, 0.42 * fade), 3.0, true)
	var check_points := PackedVector2Array([
		_center + Vector2(-17.0, 0.0) * pop,
		_center + Vector2(-5.0, 13.0) * pop,
		_center + Vector2(20.0, -16.0) * pop,
	])
	draw_polyline(check_points, Color(0.12, 0.35, 0.09, 0.54 * reveal * fade), 13.0, true)
	draw_polyline(check_points, Color(1.0, 1.0, 0.92, reveal * fade), 8.0, true)
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var direction := Vector2(cos(angle), sin(angle))
		var start := _center + direction * lerpf(46.0, 64.0, t)
		var finish := start + direction * 13.0
		draw_line(start, finish, Color(1.0, 0.78, 0.18, 0.88 * fade), 4.0, true)
