class_name GameplayEffectsLayer
extends Node2D

const ScoreFormatterType = preload("res://scripts/core/score_formatter.gd")
const CoinVisualsType = preload("res://scripts/presentation/coin_visuals.gd")
const AssetCatalogType = preload("res://scripts/core/asset_catalog.gd")
## Fixed sampling parameters for the level reward pile. They are cosmetic only.
const SCATTER_SEED := 20260822
const SCATTER_CANDIDATES := 12

signal coin_flight_started(result_id: int)
signal coin_arrived(result_id: int, value: int, final_coin: bool)
## Level-complete reward coins are a separate cosmetic channel so their staggered
## waves cannot be mistaken for the compact per-target coin group.
signal level_reward_wave_launched(wave_index: int)
signal level_reward_coin_arrived(value: int, final_coin: bool)
signal level_reward_finished

var score_popups: Array[Dictionary] = []
var merge_impacts: Array[Dictionary] = []
## Coloured fragments thrown outward by a merge. Presentation only.
var merge_shards: Array[Dictionary] = []
const MERGE_SHARD_LIMIT := 90
var coin_rewards: Array[Dictionary] = []
var launch_impacts: Array[Dictionary] = []
var combo_labels: Array[Dictionary] = []
var panel_sparkles: Array[Dictionary] = []
var reward_amounts: Array[Dictionary] = []
var level_reward_coins: Array[Dictionary] = []
var hero_effect: Dictionary = {}
var _level_reward_total := 0
var _level_reward_elapsed := 0.0
var _level_reward_waves_launched := 0
var _level_reward_wave_times: Array[float] = []
var _level_reward_active := false
var _coin_flights_started: Dictionary = {}
var _font: Font

func _ready() -> void:
	var variation := FontVariation.new()
	variation.base_font = ThemeDB.fallback_font
	variation.variation_embolden = 0.75
	_font = variation

func begin_merge_feedback(merge_event: Dictionary) -> void:
	var delay := float(merge_event.get("depth", 0)) * GameConfig.CHAIN_PRESENTATION_STAGGER
	var midpoint: Vector2 = merge_event.get("midpoint", Vector2.ZERO)
	var result_id := int(merge_event.get("result_id", -1))
	var result_level := int(merge_event.get("level", 1))
	var depth := int(merge_event.get("depth", 0))
	var final_target := bool(merge_event.get("final_target_completed", false))
	var target_merge := bool(merge_event.get("target_objective_completed", false))
	var timeline: Dictionary = merge_event.get("timeline", GameConfig.merge_timeline(depth, final_target, target_merge))
	var major_reward := result_level >= GameConfig.MAJOR_REWARD_TIER
	var ring_scale := float(timeline.get("ring_scale", 1.0)) * (GameConfig.MAJOR_MERGE_EFFECT_SCALE if major_reward else 1.0)
	merge_impacts.append({
		"result_id": result_id,
		"position": midpoint,
		"level": result_level,
		"elapsed": -delay,
		"ring_at": float(timeline.get("ring_at", 0.15)),
		"duration": float(timeline.get("duration", GameConfig.MERGE_PRESENTATION_DURATION)),
		"effect_scale": ring_scale,
		# An ordinary merge went from 8 sparks to 12: enough to read as an event
		# rather than a swap, still below the 14 a target merge throws.
		"spark_count": 14 if target_merge else (GameConfig.MAJOR_MERGE_SPARK_COUNT if major_reward else 12),
		"ring_layers": int(timeline.get("ring_layers", 1)),
		"ring_segments": int(timeline.get("ring_segments", 30)),
		"target_merge": target_merge,
		"major_reward": major_reward or final_target,
	})
	if depth > 0 and not final_target:
		# Clear the result gem's own overshoot so the label never sits on the art.
		var label_lift := minf(GameConfig.COMBO_LABEL_OFFSET_Y, -(GameConfig.gem_collision_radius(result_level) * 1.45 + 20.0))
		combo_labels.append({
			"position": midpoint + Vector2(0.0, label_lift),
			"text": GameConfig.combo_label_text(depth),
			"elapsed": -delay,
			"duration": GameConfig.COMBO_LABEL_DURATION,
		})
	if target_merge:
		var target_label_lift := minf(GameConfig.COMBO_LABEL_OFFSET_Y - 34.0, -(GameConfig.gem_collision_radius(result_level) * 1.75 + 42.0))
		combo_labels.append({
			"position": midpoint + Vector2(0.0, target_label_lift),
			"text": "TARGET ACHIEVED",
			"elapsed": -delay,
			"duration": GameConfig.TARGET_ACHIEVED_LABEL_DURATION,
		})
	_spawn_merge_shards(midpoint, result_level, major_reward or target_merge or final_target, delay)
	_cap_effects()
	queue_redraw()

## Coin flights are a target-completion reward, never ordinary merge feedback.
## Keeping this as a separate API prevents future merge presentation changes
## from accidentally restoring coins on every valid collision merge.
func begin_target_coin_reward(merge_event: Dictionary, awarded_coins: int, coin_destination: Vector2 = GameConfig.COIN_HUD_FALLBACK_DESTINATION) -> void:
	if awarded_coins <= 0:
		return
	var delay := GameConfig.COIN_REWARD_START_DELAY + float(merge_event.get("depth", 0)) * GameConfig.CHAIN_PRESENTATION_STAGGER
	var midpoint: Vector2 = merge_event.get("midpoint", Vector2.ZERO)
	var result_id := int(merge_event.get("result_id", -1))
	var major_reward := int(merge_event.get("level", 1)) >= GameConfig.MAJOR_REWARD_TIER
	_spawn_coin_reward(result_id, midpoint, coin_destination, awarded_coins, delay, major_reward)
	_cap_effects()
	queue_redraw()

func _spawn_coin_reward(result_id: int, midpoint: Vector2, destination: Vector2, awarded_coins: int, delay: float, major_reward: bool) -> void:
	var coin_count := GameConfig.MAJOR_COIN_BURST_COUNT if major_reward else GameConfig.COIN_BURST_COUNT
	var burst_radius := GameConfig.MAJOR_COIN_BURST_RADIUS if major_reward else GameConfig.COIN_BURST_RADIUS
	var flight_duration := GameConfig.MAJOR_COIN_FLIGHT_DURATION if major_reward else GameConfig.COIN_FLIGHT_DURATION
	var base_value: int = int(awarded_coins / coin_count)
	var remainder := awarded_coins % coin_count
	var cluster_offsets: Array[Vector2] = [
		Vector2(-0.55, -0.18),
		Vector2(-0.18, -0.64),
		Vector2(0.36, -0.42),
		Vector2(0.16, 0.12),
	]
	for index in range(coin_count):
		var scatter: Vector2 = midpoint + cluster_offsets[index] * burst_radius
		# Four coins follow one compact high arc, spaced like the supplied
		# reference. There are no screen-wide multi-lanes or permuted departures.
		var arc_height := 88.0 + float(index) * 9.0
		var control_a := Vector2(lerpf(scatter.x, destination.x, 0.32), minf(scatter.y, destination.y) - arc_height)
		var control_b := Vector2(lerpf(scatter.x, destination.x, 0.76), destination.y + 62.0 + float(index) * 8.0)
		coin_rewards.append({
			"result_id": result_id,
			"index": index,
			"count": coin_count,
			"flight_rank": index,
			"value": base_value + (1 if index < remainder else 0),
			"start": midpoint,
			"scatter_offset": cluster_offsets[index] * burst_radius,
			"scatter": scatter,
			"arc_height": arc_height,
			"control_a": control_a,
			"control_b": control_b,
			"destination": destination,
			"elapsed": -delay,
			"flight_duration": flight_duration,
			"spawn_delay": float(index) * GameConfig.COIN_SPAWN_STAGGER,
			"base_scale": 1.04 if major_reward else 1.0,
			"rotation": 0.0,
			"spin_speed": 0.0,
			"arrived": false,
			"major_reward": major_reward,
		})


func pending_target_coin_result_ids() -> Array[int]:
	var result_ids: Array[int] = []
	for coin in coin_rewards:
		if float(coin.get("elapsed", 0.0)) < 0.0:
			var result_id := int(coin.get("result_id", -1))
			if result_id >= 0 and not result_ids.has(result_id):
				result_ids.append(result_id)
	return result_ids


## Keep an unrevealed reward attached to the live result gem. The anchor freezes
## the instant the first token appears, so the whole group shares one truthful
## source even if the result moved during the configured pre-burst delay.
func reanchor_pending_target_coin_reward(result_id: int, position: Vector2) -> void:
	for coin in coin_rewards:
		if int(coin.get("result_id", -1)) != result_id or float(coin.get("elapsed", 0.0)) >= 0.0:
			continue
		var scatter_offset: Vector2 = coin.get("scatter_offset", Vector2.ZERO)
		var scatter := position + scatter_offset
		var destination: Vector2 = coin.get("destination", GameConfig.COIN_HUD_FALLBACK_DESTINATION)
		var arc_height := float(coin.get("arc_height", 88.0))
		coin.start = position
		coin.scatter = scatter
		coin.control_a = Vector2(lerpf(scatter.x, destination.x, 0.32), minf(scatter.y, destination.y) - arc_height)

## Soft expanding glow behind the held hero gem plus its single completion
## caption. Presentation-only: the target state is already authoritative.
func begin_hero_hold(center: Vector2, level: int) -> void:
	hero_effect = {
		"position": center,
		"level": level,
		"elapsed": 0.0,
		"duration": GameConfig.HERO_HOLD_DURATION + GameConfig.HERO_LAUNCH_ANTICIPATION_DURATION + GameConfig.HERO_FLIGHT_DURATION,
		"label_at": GameConfig.HERO_LABEL_AT,
		"label_shown": false,
	}
	queue_redraw()


func move_hero_hold(center: Vector2) -> void:
	if hero_effect.is_empty():
		return
	hero_effect.position = center


func end_hero_hold() -> void:
	hero_effect.clear()
	queue_redraw()


## Six small sparkles bounded to the target panel. The rest of the screen is
## intentionally left alone.
func burst_target_panel_sparkles(center: Vector2) -> void:
	for index in range(GameConfig.HERO_PANEL_SPARKLE_COUNT):
		panel_sparkles.append({
			"position": center,
			"direction": Vector2.from_angle(float(index) * TAU / float(GameConfig.HERO_PANEL_SPARKLE_COUNT) - PI * 0.5),
			"elapsed": -float(index) * 0.018,
			"duration": GameConfig.HERO_PANEL_SPARKLE_DURATION,
		})
	queue_redraw()


func show_reward_amount(center: Vector2, amount: int) -> void:
	if amount <= 0:
		return
	reward_amounts.append({
		"position": center,
		"text": "+%s" % ScoreFormatterType.format(amount),
		"elapsed": 0.0,
		"duration": GameConfig.REWARD_AMOUNT_DURATION,
	})
	while reward_amounts.size() > 2:
		reward_amounts.pop_front()
	queue_redraw()


## Level-complete coin reward. `awarded_coins` is only split for HUD counting;
## the authoritative economy value stays with the controller.
func begin_level_reward_coins(board_center: Vector2, awarded_coins: int, destination: Vector2) -> void:
	cancel_level_reward_coins()
	var count := GameConfig.LEVEL_REWARD_COIN_COUNT
	var base_value := int(awarded_coins / count)
	var remainder := awarded_coins % count
	var half_width := GameConfig.table_playable_width_at(board_center.y) * 0.5 * GameConfig.LEVEL_REWARD_COIN_SCATTER_HALF_WIDTH
	var half_height := GameConfig.LEVEL_REWARD_COIN_SCATTER_HALF_HEIGHT
	var scatter := _scatter_points(count, half_width, half_height)
	var collect_plan := GameConfig.level_reward_collect_plan(count)
	_level_reward_wave_times.clear()
	for index in range(count):
		var wave := int(index / GameConfig.LEVEL_REWARD_COIN_WAVE_SIZE)
		var spawn_at := float(wave) * GameConfig.LEVEL_REWARD_COIN_WAVE_STAGGER
		var plan: Dictionary = collect_plan[index]
		var collect_wave := int(plan.wave)
		var collect_at := float(plan.at)
		while _level_reward_wave_times.size() <= collect_wave:
			_level_reward_wave_times.append(collect_at)
		var rest: Vector2 = board_center + scatter[index]
		var lift := 46.0 + float(index % 5) * 7.0
		level_reward_coins.append({
			"index": index,
			"value": base_value + (1 if index < remainder else 0),
			"wave": collect_wave,
			"spawn_at": spawn_at,
			"land_at": spawn_at + GameConfig.LEVEL_REWARD_COIN_LAND_DURATION,
			"collect_at": collect_at,
			"arrive_at": collect_at + GameConfig.LEVEL_REWARD_COIN_FLIGHT_DURATION,
			"start": Vector2(lerpf(board_center.x, rest.x, 0.35), board_center.y - 26.0),
			"lift": lift,
			"rest": rest,
			"control": Vector2(lerpf(rest.x, destination.x, 0.34), minf(rest.y, destination.y) - 132.0 - float(index % 4) * 11.0),
			"destination": destination,
			"spin": float((index % 7) - 3) * 0.06,
			"arrived": false,
		})
	_level_reward_total = count
	_level_reward_elapsed = 0.0
	_level_reward_waves_launched = 0
	_level_reward_active = true
	queue_redraw()


## Deterministic best-candidate sampling. A fixed seed keeps the reward pile
## identical between runs, while the candidate pass spreads coins evenly across
## the controlled central band instead of clumping or forming lattice lines.
func _scatter_points(count: int, half_width: float, half_height: float) -> Array[Vector2]:
	var rng := RandomNumberGenerator.new()
	rng.seed = SCATTER_SEED
	var points: Array[Vector2] = []
	for index in range(count):
		var best := Vector2.ZERO
		var best_distance := -1.0
		for attempt in range(SCATTER_CANDIDATES):
			var candidate := Vector2(rng.randf_range(-half_width, half_width), rng.randf_range(-half_height, half_height))
			var nearest := INF
			for placed in points:
				nearest = minf(nearest, candidate.distance_squared_to(placed))
			if points.is_empty():
				nearest = INF
			if nearest > best_distance:
				best_distance = nearest
				best = candidate
		points.append(best)
	return points


func cancel_level_reward_coins() -> void:
	level_reward_coins.clear()
	_level_reward_total = 0
	_level_reward_elapsed = 0.0
	_level_reward_waves_launched = 0
	_level_reward_active = false


func has_active_level_reward() -> bool:
	return _level_reward_active


func active_level_reward_coin_count() -> int:
	return level_reward_coins.size()


func visible_level_reward_coin_count() -> int:
	var visible := 0
	for coin in level_reward_coins:
		if _level_reward_elapsed >= float(coin.spawn_at) and not bool(coin.arrived):
			visible += 1
	return visible


func level_reward_elapsed() -> float:
	return _level_reward_elapsed


func _update_level_reward_coins(delta: float) -> void:
	if not _level_reward_active:
		return
	_level_reward_elapsed += delta
	var expected_waves := 0
	for wave_at in _level_reward_wave_times:
		if _level_reward_elapsed < wave_at:
			break
		expected_waves += 1
	while _level_reward_waves_launched < expected_waves:
		level_reward_wave_launched.emit(_level_reward_waves_launched)
		_level_reward_waves_launched += 1
	var remaining: Array[Dictionary] = []
	for coin in level_reward_coins:
		if not bool(coin.arrived) and _level_reward_elapsed >= float(coin.arrive_at):
			coin.arrived = true
			var final_coin := int(coin.index) == _level_reward_total - 1
			level_reward_coin_arrived.emit(int(coin.value), final_coin)
			continue
		remaining.append(coin)
	level_reward_coins = remaining
	if level_reward_coins.is_empty():
		_level_reward_active = false
		level_reward_finished.emit()


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
	_update_merge_shards(delta)
	for coin in coin_rewards:
		coin.elapsed = float(coin.get("elapsed", 0.0)) + delta
		var flight_start := GameConfig.target_coin_flight_start(int(coin.flight_rank), int(coin.count))
		var result_id := int(coin.result_id)
		if float(coin.elapsed) >= flight_start and not _coin_flights_started.has(result_id):
			_coin_flights_started[result_id] = true
			coin_flight_started.emit(result_id)
		if not bool(coin.arrived) and float(coin.elapsed) >= flight_start + float(coin.flight_duration):
			coin.arrived = true
			var final_coin := int(coin.index) == int(coin.count) - 1
			coin_arrived.emit(result_id, int(coin.value), final_coin)
			if final_coin:
				_coin_flights_started.erase(result_id)
	for launch in launch_impacts:
		launch.elapsed = float(launch.get("elapsed", 0.0)) + delta
	for label in combo_labels:
		label.elapsed = float(label.get("elapsed", 0.0)) + delta
	for sparkle in panel_sparkles:
		sparkle.elapsed = float(sparkle.get("elapsed", 0.0)) + delta
	for amount in reward_amounts:
		amount.elapsed = float(amount.get("elapsed", 0.0)) + delta
	if not hero_effect.is_empty():
		hero_effect.elapsed = float(hero_effect.get("elapsed", 0.0)) + delta
	_update_level_reward_coins(delta)
	score_popups = score_popups.filter(func(item: Dictionary) -> bool: return float(item.elapsed) < float(item.get("duration", GameConfig.SCORE_POPUP_DURATION)))
	merge_impacts = merge_impacts.filter(func(item: Dictionary) -> bool: return float(item.elapsed) < float(item.get("duration", GameConfig.MERGE_PRESENTATION_DURATION)))
	coin_rewards = coin_rewards.filter(func(item: Dictionary) -> bool: return not bool(item.get("arrived", false)))
	launch_impacts = launch_impacts.filter(func(item: Dictionary) -> bool: return float(item.elapsed) < 0.16)
	combo_labels = combo_labels.filter(func(item: Dictionary) -> bool: return float(item.elapsed) < float(item.get("duration", GameConfig.COMBO_LABEL_DURATION)))
	panel_sparkles = panel_sparkles.filter(func(item: Dictionary) -> bool: return float(item.elapsed) < float(item.get("duration", GameConfig.HERO_PANEL_SPARKLE_DURATION)))
	reward_amounts = reward_amounts.filter(func(item: Dictionary) -> bool: return float(item.elapsed) < float(item.get("duration", GameConfig.REWARD_AMOUNT_DURATION)))
	queue_redraw()

func clear() -> void:
	score_popups.clear()
	merge_impacts.clear()
	merge_shards.clear()
	coin_rewards.clear()
	launch_impacts.clear()
	combo_labels.clear()
	panel_sparkles.clear()
	reward_amounts.clear()
	hero_effect.clear()
	cancel_level_reward_coins()
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
		coin.control_a += delta * 0.75
		coin.control_b += Vector2(delta.x, 0.0)
		coin.destination += Vector2(delta.x, 0.0)
	for launch in launch_impacts:
		launch.position += delta
	for label in combo_labels:
		label.position += delta
	for sparkle in panel_sparkles:
		sparkle.position += Vector2(delta.x, 0.0)
	for amount in reward_amounts:
		amount.position += Vector2(delta.x, 0.0)
	if not hero_effect.is_empty():
		hero_effect.position += delta
	for coin in level_reward_coins:
		coin.start += delta
		coin.rest += delta
		coin.control += delta * 0.75
		coin.destination += Vector2(delta.x, 0.0)
	queue_redraw()

func active_effect_count() -> int:
	return score_popups.size() + merge_impacts.size() + coin_rewards.size() + launch_impacts.size() + reward_amounts.size()

func active_coin_count() -> int:
	return coin_rewards.size()

func active_mini_gem_count() -> int:
	return 0

func active_combo_label_count() -> int:
	return combo_labels.size()

func has_active_coin_flights() -> bool:
	return not coin_rewards.is_empty() or _level_reward_active

func has_merge_result(result_id: int) -> bool:
	return merge_impacts.any(func(item: Dictionary) -> bool: return int(item.get("result_id", -1)) == result_id and float(item.get("elapsed", -1.0)) >= 0.0)

func _draw() -> void:
	if _font == null:
		return
	_draw_hero_effect()
	for impact in merge_impacts:
		_draw_merge_impact(impact)
	# After the ring so fragments read as thrown out of it, before the coins and
	# labels so reward text is never obscured.
	_draw_merge_shards()
	for coin in level_reward_coins:
		_draw_level_reward_coin(coin)
	for coin in coin_rewards:
		_draw_coin_reward(coin)
	for sparkle in panel_sparkles:
		_draw_panel_sparkle(sparkle)
	for amount in reward_amounts:
		_draw_reward_amount(amount)
	for popup in score_popups:
		_draw_score_popup(popup)
	for label in combo_labels:
		_draw_combo_label(label)
	for launch in launch_impacts:
		_draw_launch_impact(launch)

## A brighter ordinary ring and a bounded five-ring target variant share one
## lightweight draw path. No particle nodes or simulation objects are created.
func _draw_merge_impact(effect: Dictionary) -> void:
	var elapsed := float(effect.get("elapsed", -1.0))
	var ring_at := float(effect.get("ring_at", 0.15))
	if elapsed < ring_at:
		return
	var duration := float(effect.get("duration", GameConfig.MERGE_PRESENTATION_DURATION))
	var effect_scale := float(effect.get("effect_scale", 1.0))
	var spark_count := int(effect.get("spark_count", 6))
	var major_reward := bool(effect.get("major_reward", false))
	var target_merge := bool(effect.get("target_merge", false))
	var ring_layers := int(effect.get("ring_layers", 1))
	var ring_segments := int(effect.get("ring_segments", 30))
	var ring_span := maxf(0.12, duration - ring_at)
	var t := clampf((elapsed - ring_at) / ring_span, 0.0, 1.0)
	var expand := 1.0 - pow(1.0 - t, 2.4)
	var fade := 1.0 - t
	var center: Vector2 = effect.position
	var color := GameConfig.gem_color(int(effect.level)).lightened(0.28)
	color.a = fade
	var gem_radius := GameConfig.gem_collision_radius(int(effect.level))
	var ring_radius := (gem_radius * 0.62 + 46.0 * expand) * effect_scale
	for layer_index in range(ring_layers):
		var layer_t := float(layer_index) / float(maxi(1, ring_layers - 1))
		var layer_scale := 1.0 if ring_layers == 1 else lerpf(0.74, 1.18, layer_t) + (layer_t - 0.5) * 0.08 * expand
		var layer_alpha := 1.0 if ring_layers == 1 else lerpf(0.82, 0.30, layer_t)
		var layer_color := color
		if target_merge and layer_index > 0:
			layer_color = Color(1.0, 0.88, 0.38, fade * layer_alpha)
		else:
			layer_color.a *= layer_alpha
		var width := lerpf(4.8 if target_merge or major_reward else 3.8, 1.0, t) * (1.0 - float(layer_index) * 0.12)
		draw_arc(center, ring_radius * layer_scale, 0.0, TAU, ring_segments, layer_color, width)
	# A short, low-count spark ring keeps ordinary merges from reading as a burst.
	var spark_fade := maxf(0.0, 1.0 - t * 2.6)
	if spark_fade <= 0.0:
		return
	for index in range(spark_count):
		var seed := absi(int(effect.result_id) * 31 + index * 73)
		var angle := float(index) * TAU / float(spark_count) + float(int(effect.result_id) % 7) * 0.07 + float(seed % 11 - 5) * 0.025
		var direction := Vector2.from_angle(angle)
		var length_variation := 0.78 + float(seed % 7) * 0.065
		var inner := center + direction * (gem_radius * 0.78 + 14.0 * expand) * effect_scale
		var outer := center + direction * (gem_radius * 1.00 + 28.0 * expand) * effect_scale * length_variation
		var sparkle := Color("fff2a8") if index % 2 == 0 else color
		sparkle.a = spark_fade * 0.80
		draw_line(inner, outer, sparkle, 3.0 if major_reward else 2.0)


func _draw_combo_label(effect: Dictionary) -> void:
	var elapsed := float(effect.get("elapsed", -1.0))
	if elapsed < 0.0:
		return
	var duration := float(effect.get("duration", GameConfig.COMBO_LABEL_DURATION))
	var pop := GameConfig.COMBO_LABEL_POP_DURATION
	var settle := GameConfig.COMBO_LABEL_SETTLE_DURATION
	var scale := 1.0
	if elapsed <= pop:
		scale = lerpf(0.5, 1.2, 1.0 - pow(1.0 - clampf(elapsed / pop, 0.0, 1.0), 2.4))
	elif elapsed <= pop + settle:
		scale = lerpf(1.2, 1.0, smoothstep(0.0, 1.0, (elapsed - pop) / settle))
	var travel_t := clampf((elapsed - pop - settle) / maxf(0.001, duration - pop - settle), 0.0, 1.0)
	var rise := GameConfig.COMBO_LABEL_RISE * (1.0 - pow(1.0 - travel_t, 2.0))
	var alpha := 1.0 - smoothstep(0.55, 1.0, travel_t)
	var origin: Vector2 = effect.position + Vector2(0.0, -rise)
	var font_size := 30
	var text := String(effect.text)
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	draw_set_transform(origin, 0.0, Vector2.ONE * scale)
	draw_string(_font, Vector2(-width * 0.5 + 2.0, 3.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.24, 0.12, 0.05, alpha * 0.72))
	draw_string(_font, Vector2(-width * 0.5, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.94, 0.55, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## One soft expanding glow behind the held hero gem plus its single caption.
func _draw_hero_effect() -> void:
	if hero_effect.is_empty():
		return
	var elapsed := float(hero_effect.get("elapsed", 0.0))
	var center: Vector2 = hero_effect.position
	var level := int(hero_effect.get("level", 8))
	var gem_radius := GameConfig.gem_collision_radius(level)
	var glow_t := clampf(elapsed / 0.62, 0.0, 1.0)
	var glow := GameConfig.gem_color(level).lightened(0.42)
	glow.a = (1.0 - glow_t) * 0.34
	draw_circle(center, gem_radius * lerpf(1.05, 2.10, 1.0 - pow(1.0 - glow_t, 2.2)), glow)
	var ring := Color(1.0, 0.94, 0.62, (1.0 - glow_t) * 0.46)
	draw_arc(center, gem_radius * lerpf(1.18, 2.30, glow_t), 0.0, TAU, 44, ring, lerpf(4.0, 1.0, glow_t))
	var label_at := float(hero_effect.get("label_at", GameConfig.HERO_LABEL_AT))
	if elapsed < label_at:
		return
	var label_t := clampf((elapsed - label_at) / GameConfig.HERO_LABEL_DURATION, 0.0, 1.0)
	var label_scale := lerpf(0.72, 1.0, 1.0 - pow(1.0 - minf(label_t / 0.22, 1.0), 2.6))
	var alpha := 1.0 - smoothstep(0.70, 1.0, label_t)
	var text := GameConfig.HERO_LABEL_TEXT
	var font_size := 34
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	var origin := center + Vector2(0.0, gem_radius * 1.62 + 30.0)
	draw_set_transform(origin, 0.0, Vector2.ONE * label_scale)
	draw_string(_font, Vector2(-width * 0.5 + 2.0, 3.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.24, 0.12, 0.05, alpha * 0.74))
	draw_string(_font, Vector2(-width * 0.5, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.95, 0.60, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_panel_sparkle(effect: Dictionary) -> void:
	var elapsed := float(effect.get("elapsed", -1.0))
	if elapsed < 0.0:
		return
	var t := clampf(elapsed / float(effect.get("duration", GameConfig.HERO_PANEL_SPARKLE_DURATION)), 0.0, 1.0)
	var reach := lerpf(26.0, 54.0, 1.0 - pow(1.0 - t, 2.4))
	var center: Vector2 = effect.position
	var direction: Vector2 = effect.direction
	var color := Color(1.0, 0.95, 0.62, (1.0 - t) * 0.86)
	draw_line(center + direction * reach * 0.78, center + direction * reach, color, 2.4)


func _draw_reward_amount(effect: Dictionary) -> void:
	var elapsed := float(effect.get("elapsed", 0.0))
	var duration := float(effect.get("duration", GameConfig.REWARD_AMOUNT_DURATION))
	var t := clampf(elapsed / duration, 0.0, 1.0)
	var scale := 1.0
	if t < 0.20:
		scale = lerpf(GameConfig.REWARD_AMOUNT_START_SCALE, GameConfig.REWARD_AMOUNT_PEAK_SCALE, 1.0 - pow(1.0 - t / 0.20, 3.0))
	elif t < 0.38:
		scale = lerpf(GameConfig.REWARD_AMOUNT_PEAK_SCALE, 0.95, smoothstep(0.20, 0.38, t))
	elif t < 0.52:
		scale = lerpf(0.95, 1.0, smoothstep(0.38, 0.52, t))
	var alpha := 1.0 if t < 0.72 else 1.0 - smoothstep(0.72, 1.0, t)
	var center: Vector2 = effect.position
	var width := 260.0
	var font_size := int(round(38.0 * scale))
	var origin := center + Vector2(-width * 0.5, 0.0)
	draw_string(_font, origin + Vector2(3.0, 4.0), String(effect.text), HORIZONTAL_ALIGNMENT_CENTER, width, font_size, Color(0.18, 0.08, 0.02, alpha * 0.82))
	draw_string(_font, origin, String(effect.text), HORIZONTAL_ALIGNMENT_CENTER, width, font_size, Color(1.0, 0.87, 0.25, alpha))


## Reward coins land on a controlled central band of the board, wobble in place
## through the deliberate hold, then leave in staggered curved waves.
func _draw_level_reward_coin(effect: Dictionary) -> void:
	var elapsed := _level_reward_elapsed
	var spawn_at := float(effect.spawn_at)
	if elapsed < spawn_at:
		return
	var rest: Vector2 = effect.rest
	var position := rest
	var scale := 1.0
	var rotation := float(effect.spin)
	var shadow_alpha := 0.0
	var shadow_scale := 1.0
	var land_at := float(effect.land_at)
	var collect_at := float(effect.collect_at)
	if elapsed < land_at:
		var land_t := clampf((elapsed - spawn_at) / GameConfig.LEVEL_REWARD_COIN_LAND_DURATION, 0.0, 1.0)
		var eased := 1.0 - pow(1.0 - land_t, 2.2)
		var start: Vector2 = effect.start
		position = start.lerp(rest, eased) - Vector2(0.0, sin(land_t * PI) * float(effect.lift))
		# One small settle bounce as it touches the table.
		if land_t > 0.86:
			position.y -= sin((land_t - 0.86) / 0.14 * PI) * 7.0
		scale = lerpf(0.62, 1.0, eased)
		rotation = float(effect.spin) * (1.0 - land_t) * 6.0
		shadow_alpha = GameConfig.LEVEL_REWARD_COIN_SHADOW_OPACITY * eased
		shadow_scale = lerpf(0.72, 1.0, eased)
	elif elapsed < collect_at:
		var idle := (elapsed - land_at) * TAU * 0.9 + float(effect.index)
		position = rest + Vector2(sin(idle) * GameConfig.LEVEL_REWARD_COIN_IDLE_WOBBLE, 0.0)
		rotation = float(effect.spin) * sin(idle * 0.5) * 0.6
		shadow_alpha = GameConfig.LEVEL_REWARD_COIN_SHADOW_OPACITY
	else:
		var flight_t := clampf((elapsed - collect_at) / GameConfig.LEVEL_REWARD_COIN_FLIGHT_DURATION, 0.0, 1.0)
		var eased_flight := smoothstep(0.0, 1.0, flight_t)
		var inverse := 1.0 - eased_flight
		var control: Vector2 = effect.control
		var destination: Vector2 = effect.destination
		position = rest * inverse * inverse + control * 2.0 * inverse * eased_flight + destination * eased_flight * eased_flight
		scale = lerpf(1.0, 0.62, eased_flight)
		rotation = float(effect.spin) * eased_flight * 2.4
		shadow_alpha = GameConfig.LEVEL_REWARD_COIN_SHADOW_OPACITY * (1.0 - smoothstep(0.0, 0.28, flight_t))
	CoinVisualsType.draw_table_shadow(self, rest + GameConfig.LEVEL_REWARD_COIN_SHADOW_OFFSET, GameConfig.LEVEL_REWARD_COIN_DRAW_RADIUS, shadow_alpha, shadow_scale)
	CoinVisualsType.draw_coin(self, position, GameConfig.LEVEL_REWARD_COIN_DRAW_RADIUS * scale, 1.0, 0.0, rotation)

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
	var spawn_delay := float(effect.get("spawn_delay", 0.0))
	if elapsed < spawn_delay:
		return
	var index := int(effect.index)
	var burst_t := clampf((elapsed - spawn_delay) / maxf(0.001, GameConfig.COIN_BURST_DURATION - spawn_delay), 0.0, 1.0)
	var flight_start := GameConfig.target_coin_flight_start(int(effect.flight_rank), int(effect.count))
	var position: Vector2
	var scale := float(effect.get("base_scale", 1.0))
	var start: Vector2 = effect.start
	var scatter: Vector2 = effect.scatter
	var control_a: Vector2 = effect.control_a
	var control_b: Vector2 = effect.control_b
	var destination: Vector2 = effect.destination
	if elapsed < GameConfig.COIN_BURST_DURATION:
		var outward := 1.0 - pow(1.0 - burst_t, 2.6)
		var lift_control := start + Vector2((scatter.x - start.x) * 0.34, -34.0 - float(index) * 5.0)
		var inverse_burst := 1.0 - outward
		position = start * inverse_burst * inverse_burst + lift_control * 2.0 * inverse_burst * outward + scatter * outward * outward
		scale *= lerpf(0.38, 1.0, 1.0 - pow(1.0 - burst_t, 3.0)) + sin(burst_t * PI) * 0.16
	elif elapsed < flight_start:
		var wait_t := (elapsed - GameConfig.COIN_BURST_DURATION) / maxf(0.001, flight_start - GameConfig.COIN_BURST_DURATION)
		position = scatter + Vector2(sin(wait_t * PI * 2.0 + index) * 0.8, 0.0)
	else:
		var flight_t := clampf((elapsed - flight_start) / float(effect.flight_duration), 0.0, 1.0)
		var eased := smoothstep(0.0, 1.0, flight_t)
		var inverse := 1.0 - eased
		position = scatter * inverse * inverse * inverse + control_a * 3.0 * inverse * inverse * eased + control_b * 3.0 * inverse * eased * eased + destination * eased * eased * eased
		scale *= lerpf(1.0, 0.78, eased)
	var spin := 0.0
	var rotation := 0.0
	var target_shadow_alpha := GameConfig.TARGET_COIN_SHADOW_OPACITY * burst_t if elapsed < GameConfig.COIN_BURST_DURATION else GameConfig.TARGET_COIN_SHADOW_OPACITY
	if elapsed >= flight_start:
		target_shadow_alpha *= 1.0 - smoothstep(0.0, 0.30, clampf((elapsed - flight_start) / float(effect.flight_duration), 0.0, 1.0))
	var shadow_position := position if elapsed < GameConfig.COIN_BURST_DURATION else scatter
	CoinVisualsType.draw_table_shadow(self, shadow_position + GameConfig.TARGET_COIN_SHADOW_OFFSET, GameConfig.COIN_DRAW_RADIUS, target_shadow_alpha)
	CoinVisualsType.draw_coin(self, position, GameConfig.COIN_DRAW_RADIUS * scale, 1.0, spin, rotation)

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
	# Bounded like every other pool. A deep chain can spawn several bursts at
	# once, and shards are the highest-count effect on screen.
	while merge_shards.size() > MERGE_SHARD_LIMIT:
		merge_shards.pop_front()
	while combo_labels.size() > 4:
		combo_labels.pop_front()
	while panel_sparkles.size() > 12:
		panel_sparkles.pop_front()
	while coin_rewards.size() > GameConfig.COIN_EFFECT_LIMIT:
		var removed: Dictionary = coin_rewards.pop_front()
		if not bool(removed.get("arrived", false)):
			var final_coin := int(removed.get("index", -1)) == int(removed.get("count", 0)) - 1
			coin_arrived.emit(int(removed.get("result_id", -1)), int(removed.get("value", 0)), final_coin)
			if final_coin:
				_coin_flights_started.erase(int(removed.get("result_id", -1)))


## One-off prompt drawn in exactly the combo-label style: same font, colour,
## rise, duration and pop timing. Used to tell the player a targeted power is
## armed and waiting for a board tap, so the instruction reads as part of the
## same feedback language as Combo 1 rather than as a separate UI element.
func show_board_prompt(text: String, at_position: Vector2) -> void:
	combo_labels.append({
		"position": at_position + Vector2(0.0, GameConfig.COMBO_LABEL_OFFSET_Y),
		"text": text,
		"elapsed": 0.0,
		"duration": GameConfig.COMBO_LABEL_DURATION,
	})
	_cap_effects()
	queue_redraw()


## Coloured fragments thrown outward by a merge, falling under gravity.
##
## Spawned from the merged gem's own colour so the burst always reads as "that
## gem broke apart" rather than as a generic effect. Purely presentational: the
## shards never touch simulation, contact, or merge eligibility.
func _spawn_merge_shards(at_position: Vector2, level: int, major: bool, delay: float) -> void:
	var count := GameConfig.MERGE_SHARD_COUNT_MAJOR if major else GameConfig.MERGE_SHARD_COUNT_NORMAL
	var tint := GameConfig.gem_color(level)
	for index in range(count):
		# Spread evenly with a deterministic jitter, so a burst never clumps to
		# one side and never needs a random seed to look organic.
		var angle := TAU * (float(index) + 0.37 * float(index * index % 7)) / float(count)
		var speed := lerpf(GameConfig.MERGE_SHARD_SPEED.x, GameConfig.MERGE_SHARD_SPEED.y,
			float((index * 53) % 11) / 10.0)
		merge_shards.append({
			"position": at_position,
			"velocity": Vector2.from_angle(angle - PI * 0.5) * speed,
			"rotation": angle,
			"spin": GameConfig.MERGE_SHARD_SPIN * (1.0 if index % 2 == 0 else -1.0),
			"elapsed": -delay,
			"duration": GameConfig.MERGE_SHARD_DURATION,
			"tint": tint,
			"scale": 1.25 if major else 1.0,
		})


func _update_merge_shards(delta: float) -> void:
	for shard in merge_shards:
		shard.elapsed = float(shard.elapsed) + delta
		if float(shard.elapsed) < 0.0:
			continue
		var velocity: Vector2 = shard.velocity
		velocity.y += GameConfig.MERGE_SHARD_GRAVITY * delta
		shard.velocity = velocity
		shard.position = (shard.position as Vector2) + velocity * delta
		shard.rotation = float(shard.rotation) + float(shard.spin) * delta
	merge_shards = merge_shards.filter(func(shard: Dictionary) -> bool:
		return float(shard.elapsed) < float(shard.duration)
	)


func _draw_merge_shards() -> void:
	for shard in merge_shards:
		var elapsed := float(shard.elapsed)
		if elapsed < 0.0:
			continue
		var life := clampf(elapsed / maxf(0.001, float(shard.duration)), 0.0, 1.0)
		var tint: Color = shard.tint
		# Hold full opacity briefly so the burst registers, then fade out.
		tint.a = 1.0 - smoothstep(0.45, 1.0, life)
		var size: Vector2 = GameConfig.MERGE_SHARD_SIZE * float(shard.scale) * (1.0 - life * 0.35)
		var centre: Vector2 = shard.position
		var basis := Transform2D(float(shard.rotation), centre)
		# A four-point sliver reads as a chip of gem at this size; a quad reads
		# as a rectangle and a circle reads as a bubble.
		var points := PackedVector2Array([
			basis * Vector2(0.0, -size.y),
			basis * Vector2(size.x, 0.0),
			basis * Vector2(0.0, size.y),
			basis * Vector2(-size.x, 0.0),
		])
		draw_colored_polygon(points, tint)


func active_merge_shard_count() -> int:
	return merge_shards.size()
