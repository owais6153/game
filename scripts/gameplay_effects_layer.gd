class_name GameplayEffectsLayer
extends Node2D

const ScoreFormatterType = preload("res://scripts/score_formatter.gd")

var score_popups: Array[Dictionary] = []
var merge_impacts: Array[Dictionary] = []
var target_arrivals: Array[Dictionary] = []
var launch_impacts: Array[Dictionary] = []
var _font: Font

func _ready() -> void:
	var variation := FontVariation.new()
	variation.base_font = ThemeDB.fallback_font
	variation.variation_embolden = 0.75
	_font = variation

func begin_merge_feedback(merge_event: Dictionary, awarded_score: int) -> void:
	var delay := float(merge_event.get("depth", 0)) * GameConfig.CHAIN_PRESENTATION_STAGGER
	var midpoint: Vector2 = merge_event.get("midpoint", Vector2.ZERO)
	var result_id := int(merge_event.get("result_id", -1))
	var result_level := int(merge_event.get("level", 1))
	merge_impacts.append({"result_id": result_id, "position": midpoint, "level": result_level, "elapsed": -delay})
	# Higher-tier score values remain governed by the approved score table. Do
	# not present a misleading "+0" reward when that table awards no points.
	if awarded_score > 0:
		score_popups.append({"result_id": result_id, "position": midpoint, "text": "+%s" % ScoreFormatterType.format(awarded_score), "elapsed": -delay})
	_cap_effects()
	queue_redraw()

func begin_target_arrival(position: Vector2, level: int) -> void:
	target_arrivals.append({"position": position, "level": level, "elapsed": 0.0})
	if target_arrivals.size() > 4:
		target_arrivals.pop_front()
	queue_redraw()

func begin_launch(position: Vector2, level: int) -> void:
	launch_impacts.append({"position": position, "level": level, "elapsed": 0.0})
	if launch_impacts.size() > 4:
		launch_impacts.pop_front()
	queue_redraw()

func update_effects(delta: float) -> void:
	for popup in score_popups:
		popup.elapsed = float(popup.get("elapsed", 0.0)) + delta
	for impact in merge_impacts:
		impact.elapsed = float(impact.get("elapsed", 0.0)) + delta
	for arrival in target_arrivals:
		arrival.elapsed = float(arrival.get("elapsed", 0.0)) + delta
	for launch in launch_impacts:
		launch.elapsed = float(launch.get("elapsed", 0.0)) + delta
	score_popups = score_popups.filter(func(item: Dictionary) -> bool: return float(item.elapsed) < GameConfig.SCORE_POPUP_DURATION)
	merge_impacts = merge_impacts.filter(func(item: Dictionary) -> bool: return float(item.elapsed) < GameConfig.MERGE_PRESENTATION_DURATION)
	target_arrivals = target_arrivals.filter(func(item: Dictionary) -> bool: return float(item.elapsed) < GameConfig.TARGET_PANEL_PULSE_DURATION)
	launch_impacts = launch_impacts.filter(func(item: Dictionary) -> bool: return float(item.elapsed) < 0.16)
	queue_redraw()

func clear() -> void:
	score_popups.clear()
	merge_impacts.clear()
	target_arrivals.clear()
	launch_impacts.clear()
	queue_redraw()

func shift_world_y(delta_y: float) -> void:
	shift_world(Vector2(0.0, delta_y))


func shift_world(delta: Vector2) -> void:
	if delta.is_zero_approx():
		return
	for popup in score_popups:
		popup.position += delta
	for impact in merge_impacts:
		impact.position += delta
	for launch in launch_impacts:
		launch.position += delta
	queue_redraw()

func active_effect_count() -> int:
	return score_popups.size() + merge_impacts.size() + target_arrivals.size() + launch_impacts.size()

func has_merge_result(result_id: int) -> bool:
	return merge_impacts.any(func(item: Dictionary) -> bool: return int(item.get("result_id", -1)) == result_id and float(item.get("elapsed", -1.0)) >= 0.0)

func _draw() -> void:
	if _font == null:
		return
	for impact in merge_impacts:
		_draw_merge_impact(impact)
	for popup in score_popups:
		_draw_score_popup(popup)
	for arrival in target_arrivals:
		_draw_target_arrival(arrival)
	for launch in launch_impacts:
		_draw_launch_impact(launch)

func _draw_merge_impact(effect: Dictionary) -> void:
	var elapsed := float(effect.get("elapsed", -1.0))
	if elapsed < 0.0:
		return
	var t := clampf(elapsed / GameConfig.MERGE_PRESENTATION_DURATION, 0.0, 1.0)
	var impact_t := clampf(elapsed / 0.18, 0.0, 1.0)
	var center: Vector2 = effect.position
	var color := GameConfig.gem_color(int(effect.level)).lightened(0.28)
	color.a = 1.0 - t
	var gem_radius := GameConfig.gem_collision_radius(int(effect.level))
	var ring_radius := gem_radius * 0.82 + 32.0 * impact_t
	draw_arc(center, ring_radius, 0.0, TAU, 28, color, 3.5)
	for index in range(8):
		var angle := float(index) * TAU / 8.0 + float(int(effect.result_id) % 7) * 0.07
		var direction := Vector2.from_angle(angle)
		var inner := center + direction * (gem_radius * 0.72 + 17.0 * impact_t)
		var outer := center + direction * (gem_radius * 1.02 + 34.0 * impact_t)
		var sparkle := Color("fff2a8") if index % 2 == 0 else color
		sparkle.a = (1.0 - impact_t) * 0.92
		draw_line(inner, outer, sparkle, 2.5)

func _draw_score_popup(effect: Dictionary) -> void:
	var elapsed := float(effect.get("elapsed", -1.0))
	if elapsed < 0.0:
		return
	var t := clampf(elapsed / GameConfig.SCORE_POPUP_DURATION, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 3.0)
	var alpha := 1.0 if t <= 0.45 else 1.0 - smoothstep(0.45, 1.0, t)
	var origin: Vector2 = effect.position + Vector2(-70.0, -36.0 - GameConfig.SCORE_POPUP_RISE * eased)
	var shadow := Color(0.24, 0.12, 0.05, alpha * 0.72)
	var foreground := Color(1.0, 0.94, 0.55, alpha)
	draw_string(_font, origin + Vector2(2.0, 3.0), String(effect.text), HORIZONTAL_ALIGNMENT_CENTER, 140.0, 23, shadow)
	draw_string(_font, origin, String(effect.text), HORIZONTAL_ALIGNMENT_CENTER, 140.0, 23, foreground)

func _draw_target_arrival(effect: Dictionary) -> void:
	var t := clampf(float(effect.elapsed) / GameConfig.TARGET_PANEL_PULSE_DURATION, 0.0, 1.0)
	var center: Vector2 = effect.position
	var color := GameConfig.gem_color(int(effect.level)).lightened(0.35)
	color.a = 1.0 - t
	draw_arc(center, 18.0 + t * 38.0, 0.0, TAU, 28, color, 3.0)
	for index in range(6):
		var direction := Vector2.from_angle(float(index) * TAU / 6.0)
		var sparkle_center := center + direction * (25.0 + t * 20.0)
		draw_circle(sparkle_center, 3.8 * (1.0 - t), Color(1.0, 0.91, 0.42, 1.0 - t))

func _draw_launch_impact(effect: Dictionary) -> void:
	var t := clampf(float(effect.elapsed) / 0.16, 0.0, 1.0)
	var center: Vector2 = effect.position
	var color := GameConfig.gem_color(int(effect.level)).lightened(0.32)
	color.a = (1.0 - t) * 0.80
	draw_arc(center, 14.0 + t * 30.0, 0.0, TAU, 24, color, 2.5)
	var trail_color := Color(1.0, 0.92, 0.46, (1.0 - t) * 0.72)
	draw_line(center + Vector2(-9.0, 18.0 + t * 10.0), center + Vector2(-9.0, 34.0 + t * 18.0), trail_color, 2.0)
	draw_line(center + Vector2(9.0, 18.0 + t * 10.0), center + Vector2(9.0, 34.0 + t * 18.0), trail_color, 2.0)

func _cap_effects() -> void:
	while score_popups.size() > 12:
		score_popups.pop_front()
	while merge_impacts.size() > 12:
		merge_impacts.pop_front()
