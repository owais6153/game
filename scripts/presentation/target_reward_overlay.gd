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
	var reveal := 1.0 - pow(1.0 - minf(t / 0.13, 1.0), 3.0)
	var fade := 1.0 - smoothstep(0.82, 1.0, t)
	var pop := lerpf(0.72, 1.10, reveal)
	if t > 0.18:
		pop = lerpf(1.10, 1.0, smoothstep(0.18, 0.34, t))
	# Completion reads through arrival energy and card response, without a
	# generic success glyph obscuring the target artwork.
	var glow := Color(0.68, 0.95, 1.0, 0.62 * reveal * fade)
	var radius := lerpf(24.0, 47.0, minf(t / 0.42, 1.0)) * pop
	draw_arc(_center, radius, 0.0, TAU, 40, glow, 5.0)
	var inner := Color(1.0, 0.96, 0.64, 0.44 * reveal * fade)
	draw_arc(_center, radius * 0.72, 0.0, TAU, 32, inner, 3.0)
	for index in range(8):
		var direction := Vector2.from_angle(float(index) * TAU / 8.0)
		draw_line(_center + direction * radius * 0.82, _center + direction * radius * 1.12, glow, 2.5)
