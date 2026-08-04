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
	# The reference holds one unmistakable green check over the completed
	# target. Rings, filled discs, and spark spokes made this beat look generic
	# and hid the target artwork instead of confirming it.
	var check_points := PackedVector2Array([
		_center + Vector2(-22.0, 1.0) * pop,
		_center + Vector2(-7.0, 17.0) * pop,
		_center + Vector2(26.0, -20.0) * pop,
	])
	draw_polyline(check_points, Color(0.10, 0.39, 0.08, 0.78 * reveal * fade), 16.0, true)
	draw_polyline(check_points, Color(0.43, 0.92, 0.20, reveal * fade), 11.0, true)
	draw_polyline(check_points, Color(0.78, 1.0, 0.58, 0.72 * reveal * fade), 4.0, true)
