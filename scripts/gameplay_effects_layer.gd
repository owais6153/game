class_name GameplayEffectsLayer
extends Node2D

const ScoreFormatterType = preload("res://scripts/score_formatter.gd")
const CoinVisualsType = preload("res://scripts/coin_visuals.gd")

signal coin_flight_started(result_id: int)
signal coin_arrived(result_id: int, value: int, final_coin: bool)

var score_popups: Array[Dictionary] = []
var merge_impacts: Array[Dictionary] = []
var coin_rewards: Array[Dictionary] = []
var target_arrivals: Array[Dictionary] = []
var launch_impacts: Array[Dictionary] = []
var _coin_flights_started: Dictionary = {}
var _font: Font

func _ready() -> void:
	var variation := FontVariation.new()
	variation.base_font = ThemeDB.fallback_font
	variation.variation_embolden = 0.75
	_font = variation

func begin_merge_feedback(merge_event: Dictionary, awarded_coins: int, coin_destination: Vector2 = GameConfig.COIN_HUD_FALLBACK_DESTINATION) -> void:
	var delay := float(merge_event.get("depth", 0)) * GameConfig.CHAIN_PRESENTATION_STAGGER
	var midpoint: Vector2 = merge_event.get("midpoint", Vector2.ZERO)
	var result_id := int(merge_event.get("result_id", -1))
	var result_level := int(merge_event.get("level", 1))
	var major_reward := result_level >= GameConfig.MAJOR_REWARD_TIER
	merge_impacts.append({
		"result_id": result_id,
		"position": midpoint,
		"level": result_level,
		"elapsed": -delay,
		"duration": GameConfig.MAJOR_MERGE_EFFECT_DURATION if major_reward else GameConfig.MERGE_PRESENTATION_DURATION,
		"effect_scale": GameConfig.MAJOR_MERGE_EFFECT_SCALE if major_reward else 1.0,
		"spark_count": GameConfig.MAJOR_MERGE_SPARK_COUNT if major_reward else 8,
		"major_reward": major_reward,
	})
	if awarded_coins > 0:
		_spawn_coin_reward(result_id, midpoint, coin_destination, awarded_coins, delay, major_reward)
	_cap_effects()
	queue_redraw()

func _spawn_coin_reward(result_id: int, midpoint: Vector2, destination: Vector2, awarded_coins: int, delay: float, major_reward: bool) -> void:
	var coin_count := GameConfig.MAJOR_COIN_BURST_COUNT if major_reward else GameConfig.COIN_BURST_COUNT
	var burst_radius := GameConfig.MAJOR_COIN_BURST_RADIUS if major_reward else GameConfig.COIN_BURST_RADIUS
	var flight_duration := GameConfig.MAJOR_COIN_FLIGHT_DURATION if major_reward else GameConfig.COIN_FLIGHT_DURATION
	var base_value: int = int(awarded_coins / coin_count)
	var remainder := awarded_coins % coin_count
	for index in range(coin_count):
		var seed := result_id * 37 + index * 101
		var normalized := float(index) / maxf(1.0, float(coin_count - 1))
		var angle := -PI * 0.95 + normalized * PI * 1.90 + float(seed % 9 - 4) * 0.035
		var radius := burst_radius * (0.60 + float(seed % 7) * 0.055)
		var scatter := midpoint + Vector2.from_angle(angle) * radius + Vector2(0.0, -20.0 - float(index % 3) * 5.0)
		var lateral_arc := (-54.0 if index % 2 == 0 else 54.0) + float(seed % 5 - 2) * 13.0
		var control := (scatter + destination) * 0.5 + Vector2(lateral_arc, -96.0 - float(index % 4) * 13.0)
		coin_rewards.append({
			"result_id": result_id,
			"index": index,
			"count": coin_count,
			"value": base_value + (1 if index < remainder else 0),
			"start": midpoint,
			"scatter": scatter,
			"control": control,
			"destination": destination,
			"elapsed": -delay,
			"flight_duration": flight_duration,
			"arrived": false,
			"major_reward": major_reward,
		})

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
	for coin in coin_rewards:
		coin.elapsed = float(coin.get("elapsed", 0.0)) + delta
		var flight_start := GameConfig.COIN_BURST_DURATION + float(coin.index) * GameConfig.COIN_FLIGHT_STAGGER
		var result_id := int(coin.result_id)
		if float(coin.elapsed) >= GameConfig.COIN_BURST_DURATION and not _coin_flights_started.has(result_id):
			_coin_flights_started[result_id] = true
			coin_flight_started.emit(result_id)
		if not bool(coin.arrived) and float(coin.elapsed) >= flight_start + float(coin.flight_duration):
			coin.arrived = true
			var final_coin := int(coin.index) == int(coin.count) - 1
			coin_arrived.emit(result_id, int(coin.value), final_coin)
			if final_coin:
				_coin_flights_started.erase(result_id)
	for arrival in target_arrivals:
		arrival.elapsed = float(arrival.get("elapsed", 0.0)) + delta
	for launch in launch_impacts:
		launch.elapsed = float(launch.get("elapsed", 0.0)) + delta
	score_popups = score_popups.filter(func(item: Dictionary) -> bool: return float(item.elapsed) < float(item.get("duration", GameConfig.SCORE_POPUP_DURATION)))
	merge_impacts = merge_impacts.filter(func(item: Dictionary) -> bool: return float(item.elapsed) < float(item.get("duration", GameConfig.MERGE_PRESENTATION_DURATION)))
	coin_rewards = coin_rewards.filter(func(item: Dictionary) -> bool: return not bool(item.get("arrived", false)))
	target_arrivals = target_arrivals.filter(func(item: Dictionary) -> bool: return float(item.elapsed) < GameConfig.TARGET_PANEL_PULSE_DURATION)
	launch_impacts = launch_impacts.filter(func(item: Dictionary) -> bool: return float(item.elapsed) < 0.16)
	queue_redraw()

func clear() -> void:
	score_popups.clear()
	merge_impacts.clear()
	coin_rewards.clear()
	target_arrivals.clear()
	launch_impacts.clear()
	_coin_flights_started.clear()
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
	for coin in coin_rewards:
		coin.start += delta
		coin.scatter += delta
		coin.control += Vector2(delta.x, delta.y * 0.5)
		coin.destination += Vector2(delta.x, 0.0)
	for launch in launch_impacts:
		launch.position += delta
	queue_redraw()

func active_effect_count() -> int:
	return score_popups.size() + merge_impacts.size() + coin_rewards.size() + target_arrivals.size() + launch_impacts.size()

func active_coin_count() -> int:
	return coin_rewards.size()

func has_active_coin_flights() -> bool:
	return not coin_rewards.is_empty()

func has_merge_result(result_id: int) -> bool:
	return merge_impacts.any(func(item: Dictionary) -> bool: return int(item.get("result_id", -1)) == result_id and float(item.get("elapsed", -1.0)) >= 0.0)

func _draw() -> void:
	if _font == null:
		return
	for impact in merge_impacts:
		_draw_merge_impact(impact)
	for coin in coin_rewards:
		_draw_coin_reward(coin)
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
	var duration := float(effect.get("duration", GameConfig.MERGE_PRESENTATION_DURATION))
	var effect_scale := float(effect.get("effect_scale", 1.0))
	var spark_count := int(effect.get("spark_count", 8))
	var major_reward := bool(effect.get("major_reward", false))
	var t := clampf(elapsed / duration, 0.0, 1.0)
	var impact_t := clampf(elapsed / (0.30 if major_reward else 0.18), 0.0, 1.0)
	var center: Vector2 = effect.position
	var color := GameConfig.gem_color(int(effect.level)).lightened(0.28)
	color.a = 1.0 - t
	var gem_radius := GameConfig.gem_collision_radius(int(effect.level))
	var ring_radius := (gem_radius * 0.82 + 32.0 * impact_t) * effect_scale
	draw_arc(center, ring_radius, 0.0, TAU, 36 if major_reward else 28, color, 5.0 if major_reward else 3.5)
	if major_reward:
		var echo_color := Color(1.0, 0.88, 0.34, (1.0 - t) * 0.74)
		draw_arc(center, ring_radius * (0.58 + 0.24 * impact_t), 0.0, TAU, 32, echo_color, 3.0)
	for index in range(spark_count):
		var angle := float(index) * TAU / float(spark_count) + float(int(effect.result_id) % 7) * 0.07
		var direction := Vector2.from_angle(angle)
		var inner := center + direction * (gem_radius * 0.72 + 17.0 * impact_t) * effect_scale
		var outer := center + direction * (gem_radius * 1.02 + 34.0 * impact_t) * effect_scale
		var sparkle := Color("fff2a8") if index % 2 == 0 else color
		sparkle.a = (1.0 - impact_t) * 0.92
		draw_line(inner, outer, sparkle, 3.5 if major_reward else 2.5)

func _draw_score_popup(effect: Dictionary) -> void:
	var elapsed := float(effect.get("elapsed", -1.0))
	if elapsed < 0.0:
		return
	var duration := float(effect.get("duration", GameConfig.SCORE_POPUP_DURATION))
	var rise := float(effect.get("rise", GameConfig.SCORE_POPUP_RISE))
	var font_size := int(effect.get("font_size", 23))
	var t := clampf(elapsed / duration, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 3.0)
	var alpha := 1.0 if t <= 0.45 else 1.0 - smoothstep(0.45, 1.0, t)
	var origin: Vector2 = effect.position + Vector2(-80.0, -36.0 - rise * eased)
	var shadow := Color(0.24, 0.12, 0.05, alpha * 0.72)
	var foreground := Color(1.0, 0.94, 0.55, alpha)
	draw_string(_font, origin + Vector2(2.0, 3.0), String(effect.text), HORIZONTAL_ALIGNMENT_CENTER, 160.0, font_size, shadow)
	draw_string(_font, origin, String(effect.text), HORIZONTAL_ALIGNMENT_CENTER, 160.0, font_size, foreground)

func _draw_coin_reward(effect: Dictionary) -> void:
	var elapsed := float(effect.get("elapsed", -1.0))
	if elapsed < 0.0:
		return
	var index := int(effect.index)
	var burst_t := clampf(elapsed / GameConfig.COIN_BURST_DURATION, 0.0, 1.0)
	var flight_start := GameConfig.COIN_BURST_DURATION + float(index) * GameConfig.COIN_FLIGHT_STAGGER
	var position: Vector2
	var scale := 1.0
	var start: Vector2 = effect.start
	var scatter: Vector2 = effect.scatter
	var control: Vector2 = effect.control
	var destination: Vector2 = effect.destination
	if elapsed < GameConfig.COIN_BURST_DURATION:
		var outward := 1.0 - pow(1.0 - burst_t, 3.0)
		position = start.lerp(scatter, outward)
		scale = 0.42 + sin(burst_t * PI) * 0.82 + burst_t * 0.16
	elif elapsed < flight_start:
		var wait_t := (elapsed - GameConfig.COIN_BURST_DURATION) / maxf(0.001, flight_start - GameConfig.COIN_BURST_DURATION)
		position = scatter + Vector2(0.0, -sin(wait_t * PI) * 7.0)
		scale = 1.0 + sin(wait_t * PI) * 0.10
	else:
		var flight_t := clampf((elapsed - flight_start) / float(effect.flight_duration), 0.0, 1.0)
		var eased := smoothstep(0.0, 1.0, flight_t)
		var inverse := 1.0 - eased
		position = scatter * inverse * inverse + control * 2.0 * inverse * eased + destination * eased * eased
		scale = lerpf(1.06, 0.72, eased) * (1.0 + sin(flight_t * PI * 4.0) * 0.06)
	var spin := elapsed * 15.0 + float(index) * 0.73
	CoinVisualsType.draw_coin(self, position, GameConfig.COIN_DRAW_RADIUS * scale, 1.0, spin)

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
	while coin_rewards.size() > GameConfig.COIN_EFFECT_LIMIT:
		var removed: Dictionary = coin_rewards.pop_front()
		if not bool(removed.get("arrived", false)):
			var final_coin := int(removed.get("index", -1)) == int(removed.get("count", 0)) - 1
			coin_arrived.emit(int(removed.get("result_id", -1)), int(removed.get("value", 0)), final_coin)
			if final_coin:
				_coin_flights_started.erase(int(removed.get("result_id", -1)))
