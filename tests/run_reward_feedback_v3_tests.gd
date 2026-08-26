extends SceneTree

## Reward feedback v3. These tests protect the reward hierarchy
## (collision < normal merge < combo merge < final target < level complete),
## the staged final-target celebration, and the exactly-once reward contract.

const GameControllerType = preload("res://scripts/gameplay/game_controller.gd")
const GameplayEffectsLayerType = preload("res://scripts/presentation/gameplay_effects_layer.gd")
const PieceType = preload("res://scripts/core/gem_piece.gd")
const ProgressionSaveServiceType = preload("res://scripts/services/progression_save_service.gd")
const SAVE_FILE := "user://infinite_progression.cfg"

const STEP := 1.0 / 60.0

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_merge_timeline_hierarchy()
	_test_normal_merge_scale_timeline()
	await _test_real_bonus_merge_rewards()
	await _test_bonus_cascade_limits()
	_test_bonus_release_grace()
	await _test_non_final_target_keeps_standard_collection()
	await _test_final_target_celebration()
	await _test_hud_coin_counter_continuity()
	if failures.is_empty():
		print("REWARD_FEEDBACK_V3_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("REWARD_FEEDBACK_V3_TESTS: FAIL (%d)" % failures.size())
	quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _test_merge_timeline_hierarchy() -> void:
	var normal: Dictionary = GameConfig.merge_timeline(0, false)
	var combo_1: Dictionary = GameConfig.merge_timeline(1, false)
	var combo_2: Dictionary = GameConfig.merge_timeline(2, false)
	var combo_3: Dictionary = GameConfig.merge_timeline(3, false)
	var combo_4: Dictionary = GameConfig.merge_timeline(4, false)
	var final_target: Dictionary = GameConfig.merge_timeline(0, true)
	_assert(float(normal.ring_scale) < float(combo_1.ring_scale), "COMBO 1 must read stronger than an ordinary merge")
	_assert(float(combo_1.ring_scale) < float(combo_2.ring_scale), "COMBO 2 must read stronger than COMBO 1")
	_assert(float(combo_2.ring_scale) < float(combo_3.ring_scale), "COMBO 3+ must read stronger than COMBO 2")
	_assert(float(combo_3.ring_scale) < float(combo_4.ring_scale), "COMBO 4+ must read stronger than COMBO 3")
	_assert(float(normal.pitch) < float(combo_1.pitch) and float(combo_1.pitch) < float(combo_2.pitch) and float(combo_2.pitch) < float(combo_3.pitch) and float(combo_3.pitch) < float(combo_4.pitch), "Combo SFX pitch must rise with chain depth")
	_assert(float(normal.radial_intensity) < float(combo_1.radial_intensity) and float(combo_1.radial_intensity) < float(combo_2.radial_intensity) and float(combo_2.radial_intensity) < float(combo_3.radial_intensity), "The one radial shader must escalate through its configured intensity")
	_assert(GameConfig.bonus_gem_count(0) == 1 and GameConfig.bonus_gem_count(1) == 1 and GameConfig.bonus_gem_count(2) == 2 and GameConfig.bonus_gem_count(3) == 2 and GameConfig.bonus_gem_count(4) == 3, "Real bonus-gem counts must follow the approved combo ladder")
	_assert(GameConfig.BONUS_GEM_BUDGET_PER_SHOT == 3, "A single shot must stop after three generated reward pieces")
	_assert(GameConfig.BONUS_BOARD_PIECE_CAP >= 20 and GameConfig.BONUS_BOARD_PIECE_CAP <= 28, "Crowded-board reward spawning must have a hard population cap")
	_assert(GameConfig.BONUS_REWARD_MAX_CHAIN_DEPTH == 2, "COMBO 3+ may celebrate but must not generate another reward tier")
	_assert(is_equal_approx(GameConfig.BONUS_VISUAL_BURST_DURATION, GameConfig.MERGE_PRESENTATION_DURATION - GameConfig.MERGE_REVEAL_START), "Reward siblings must use the result's complete reveal-to-settle interval")
	_assert(GameConfig.CHAIN_PRESENTATION_STAGGER >= 0.24, "Chain tiers must remain slow enough to read")
	_assert(float(combo_3.hitstop) > float(normal.hitstop), "COMBO 3+ must use a longer hit-stop than a normal merge")
	_assert(float(final_target.hitstop) > float(combo_3.hitstop), "The final target must own the strongest hit-stop")
	_assert(is_equal_approx(float(final_target.duration), float(normal.duration)), "Final-target merge feedback must finish before collection travel")
	_assert(is_equal_approx(GameConfig.FINAL_TARGET_COLLECTION_OVERLAP_START - float(final_target.duration), 0.12), "Hero travel must follow the complete merge with a 120 ms readable hold")
	# The chain label ladder must not lend deep-chain wording to shallow chains.
	_assert(GameConfig.combo_label_text(1) == "COMBO 1" and GameConfig.combo_label_text(2) == "COMBO 2", "Low chains must use plain combo labels")
	_assert(GameConfig.combo_label_text(3) == "COMBO 3!", "COMBO 3 must stay a plain emphatic label")
	_assert(GameConfig.combo_label_text(4).contains("AMAZING") and GameConfig.combo_label_text(5).contains("PERFECT"), "Rare deep chains may use the escalated wording")
	_assert(GameConfig.COMBO_LABEL_DURATION >= 1.0, "Combo text must remain readable across low-frame-rate capture and play")
	_assert(GameConfig.TARGET_ACHIEVED_LABEL_DURATION >= GameConfig.COMBO_LABEL_DURATION, "Target-achieved feedback must remain at least as readable as combo text")
	var effects := GameplayEffectsLayerType.new()
	effects.begin_merge_feedback({"result_id": 77, "midpoint": Vector2(360.0, 620.0), "level": 6, "depth": 1, "target_objective_completed": true, "final_target_completed": false})
	_assert(effects.combo_labels.any(func(label: Dictionary) -> bool: return String(label.get("text", "")) == "TARGET ACHIEVED"), "A confirmed target merge must create a literal TARGET ACHIEVED label")
	effects.free()
	# The two deliberate pauses of the celebration must survive retuning.
	_assert(GameConfig.HERO_HOLD_DURATION >= 0.95 and GameConfig.HERO_LABEL_DURATION >= 0.90, "The final-target gem and caption must remain readable at center")
	_assert(GameConfig.LEVEL_REWARD_COIN_TABLE_HOLD >= 0.95, "The full final coin pile must remain on the table for a readable hold")
	_assert(GameConfig.LEVEL_REWARD_COIN_COUNT == GameConfig.COIN_BURST_COUNT, "The final target must use the same visible coin quantity as earlier targets")
	_assert(GameConfig.LEVEL_REWARD_COIN_DRAW_RADIUS >= 18.0 and GameConfig.LEVEL_REWARD_COIN_SCATTER_HALF_WIDTH <= 0.40, "Reward coins must be larger and concentrated in a compact central pile")
	var collect_plan := GameConfig.level_reward_collect_plan()
	_assert(collect_plan.size() == GameConfig.COIN_BURST_COUNT and int(collect_plan[0].wave) == 0 and int(collect_plan[2].wave) == 1, "Four final coins must collect in two compact waves")
	_assert(float(collect_plan.back().at) - float(collect_plan.front().at) <= 0.10, "The four reward coins must arrive as one fast confirmation group")
	_assert(GameConfig.LEVEL_REWARD_COIN_FLIGHT_DURATION >= 0.30 and GameConfig.LEVEL_REWARD_COIN_FLIGHT_DURATION <= 0.42, "Each coin flight must stay inside the approved 300-420 ms window")
	_assert(GameConfig.TARGET_COIN_TABLE_HOLD >= 1.0 and GameConfig.target_coin_flight_start(0, GameConfig.COIN_BURST_COUNT) - float(GameConfig.COIN_BURST_COUNT - 1) * GameConfig.COIN_SPAWN_STAGGER >= GameConfig.TARGET_COIN_TABLE_HOLD, "Every target coin group must remain together on the table for a readable hold")
	_assert(float(GameConfig.GEM_SHADOW_OPACITY[1]) >= 0.46, "Gem contact shadows must be unmistakably visible on the table")
	_assert(GameConfig.TARGET_COIN_SHADOW_OPACITY > 0.0 and GameConfig.TARGET_COIN_SHADOW_OPACITY <= 0.25 and GameConfig.LEVEL_REWARD_COIN_SHADOW_OPACITY > 0.0 and GameConfig.LEVEL_REWARD_COIN_SHADOW_OPACITY <= 0.25, "Target and final coins must use light table-contact shadows")


func _test_normal_merge_scale_timeline() -> void:
	var controller := GameControllerType.new()
	var timeline: Dictionary = GameConfig.MERGE_TIMELINE_NORMAL
	_assert(is_equal_approx(controller._merge_result_transform_for(0.0, timeline).uniform_scale, 0.0), "The result gem must stay hidden through the hit-stop and source pull")
	_assert(is_equal_approx(controller._merge_result_transform_for(0.119, timeline).uniform_scale, 0.0), "The result gem must appear only at the 120 ms impact frame")
	_assert(is_equal_approx(controller._merge_result_transform_for(0.12, timeline).uniform_scale, 0.65), "The result gem must be revealed at 0.65 scale")
	_assert(is_equal_approx(controller._merge_result_transform_for(0.21, timeline).uniform_scale, 1.24), "The normal merge pop must peak at 1.24")
	_assert(is_equal_approx(controller._merge_result_transform_for(0.29, timeline).uniform_scale, 0.93), "The merge must recoil to 0.93")
	_assert(is_equal_approx(controller._merge_result_transform_for(0.365, timeline).uniform_scale, 1.05), "The secondary settle must reach 1.05")
	_assert(is_equal_approx(controller._merge_result_transform_for(0.42, timeline).uniform_scale, 1.0), "The merge must return to 1.0 by 420 ms")
	var hero: Dictionary = GameConfig.MERGE_TIMELINE_FINAL_TARGET
	_assert(is_equal_approx(controller._merge_result_transform_for(0.10, hero).uniform_scale, 0.60), "Final-target Phase A must reveal at 0.60")
	_assert(is_equal_approx(controller._merge_result_transform_for(0.18, hero).uniform_scale, 1.40), "Final-target merge must reach the strongest 1.40 peak")
	_assert(is_equal_approx(controller._merge_result_transform_for(0.27, hero).uniform_scale, 0.96), "Final-target merge must recoil before its final settle")
	_assert(is_equal_approx(controller._merge_result_transform_for(0.42, hero).uniform_scale, 1.0), "Final-target merge must settle fully before the table-position hold")
	controller.free()


func _controller() -> GameControllerType:
	paused = false
	var controller := GameControllerType.new()
	root.add_child(controller)
	return controller


func _merge_event(controller: GameControllerType, result_id: int, level: int, depth: int) -> Dictionary:
	var midpoint := Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 200.0)
	var piece := PieceType.new(result_id, level, midpoint, GameConfig.gem_collision_radius(level))
	controller.pieces.append(piece)
	return {
		"result_id": result_id,
		"source_ids": [result_id + 1000, result_id + 2000],
		"level": level,
		"first_position": midpoint - Vector2(40.0, 0.0),
		"second_position": midpoint + Vector2(40.0, 0.0),
		"midpoint": midpoint,
		"depth": depth,
	}


func _test_real_bonus_merge_rewards() -> void:
	var controller := _controller()
	await process_frame
	controller._on_home_level_intro_requested()
	controller._on_home_play_requested()
	var pieces_before := controller.pieces.size()
	controller._apply_confirmed_merge_events([_merge_event(controller, 7001, 4, 0)])
	_assert(controller.pending_bonus_spawns.size() == 1, "Every ordinary merge must schedule its real bonus gameplay gem")
	var timeline: Dictionary = GameConfig.MERGE_TIMELINE_NORMAL
	var reveal := float(timeline.reveal)
	_assert(is_equal_approx(float(controller.pending_bonus_spawns[0].remaining), reveal), "A reward must be scheduled for the result's exact reveal frame")
	controller._update_pending_bonus_spawns(reveal + 0.001)
	_assert(controller.pieces.size() == pieces_before + 2, "An ordinary merge must leave its result plus one real bonus piece in simulation")
	var bonus: GemPiece = controller.pieces.back()
	_assert((controller.bonus_spawn_history.back().piece_ids as Array).has(bonus.id) and bonus.level <= 2, "The bonus must be a lower-tier real GemPiece selected from result tier N-2 or below")
	_assert(bonus.velocity.length() > 0.0 and bonus.radius > 0.0, "A bonus must own real launch velocity on its first visible frame")
	_assert(not controller.gem_sprite_layer._presentation_offsets.has(bonus.id), "A bonus must render at its real body instead of sliding from a fake origin")
	_assert(not bool(controller.gem_sprite_layer._presentation_elevated.get(bonus.id, false)), "A reward sibling must use the same ordinary gem draw path as the result")
	var initial_scale: Vector2 = controller.gem_sprite_layer._presentation_scales.get(bonus.id, Vector2.ZERO)
	_assert(is_equal_approx(initial_scale.x, controller._bonus_result_scale_for(0.001, timeline)), "A bonus must begin at the same pop phase as the result")
	controller._update_piece_visual_feedbacks(0.089)
	var peak_scale: Vector2 = controller.gem_sprite_layer._presentation_scales.get(bonus.id, Vector2.ZERO)
	_assert(is_equal_approx(peak_scale.x, controller._merge_result_transform_for(0.21, timeline).uniform_scale), "The result and reward sibling must reach the same normal-merge peak together")
	controller._update_piece_visual_feedbacks(GameConfig.BONUS_VISUAL_BURST_DURATION)
	_assert(not controller.gem_sprite_layer._presentation_scales.has(bonus.id), "The shared pop must clear after both gems settle")
	_assert(controller.effects_layer.active_mini_gem_count() == 0, "No fading cosmetic mini-gem substitute may remain")
	var merge_result: GemPiece = controller._live_piece(7001)
	var overlap_clearance := bonus.position.distance_to(merge_result.position) - bonus.radius - merge_result.radius
	_assert(overlap_clearance >= 0.0, "The real bonus must not spawn inside its result gem")
	var isolated: Array[GemPiece] = [bonus]
	var isolated_merger := ContactMergeService.new()
	var visible_position := bonus.position
	controller.simulation.step(isolated, STEP, isolated_merger)
	_assert(not bonus.position.is_equal_approx(visible_position) and bonus.velocity.length() > 0.0, "Reward physics must move the real body during its first visible simulation step")
	for _frame in range(180):
		controller.simulation.step(isolated, STEP, isolated_merger)
	_assert(controller._live_piece(bonus.id) == bonus, "A bonus gameplay gem must still exist several seconds later")
	_assert(bonus.bonus_event_id == -1 and is_equal_approx(bonus.bonus_merge_grace_remaining, 0.0), "The tiny grace must expire without permanently marking the bonus gem")
	# The hit-stop freezes only the confirmed result, and restores its momentum.
	var chained := _merge_event(controller, 7002, 4, 1)
	var result_piece: GemPiece = controller.pieces.back()
	result_piece.velocity = Vector2(0.0, -180.0)
	controller._apply_confirmed_merge_events([chained])
	_assert(result_piece.velocity == Vector2.ZERO, "The merge hit-stop must lock the confirmed result gem")
	_assert(controller.effects_layer.active_combo_label_count() == 1, "A chained merge must show exactly one combo label")
	controller._update_merge_hitstops(GameConfig.COMBO_1_HITSTOP_DURATION + 0.001)
	_assert(result_piece.velocity.is_equal_approx(Vector2(0.0, -180.0)), "The hit-stop must restore the exact merge momentum")
	_assert(controller.merge_hitstops.is_empty(), "The hit-stop must release itself")
	# Level boundaries must not leak temporary cosmetic nodes or records.
	controller.restart()
	_assert(controller.pending_bonus_spawns.is_empty() and controller.bonus_spawn_history.is_empty(), "Restart must clear every delayed bonus record")
	_assert(controller.effects_layer.active_combo_label_count() == 0, "Restart must clear temporary combo labels")
	_assert(not controller.effects_layer.has_active_level_reward() and not controller.final_celebration_active, "Restart must cancel any running celebration")
	paused = false
	controller.queue_free()
	await process_frame


func _test_bonus_cascade_limits() -> void:
	var controller := _controller()
	await process_frame
	controller._on_home_level_intro_requested()
	controller._on_home_play_requested()
	controller._schedule_bonus_gems({"result_id": 8999, "level": 6, "midpoint": Vector2.ZERO, "depth": 2})
	var split_levels: Array = controller.pending_bonus_spawns[0].levels
	_assert(split_levels.size() == 2 and split_levels[0] != split_levels[1], "A multi-gem split must use distinct visible tiers when eligible tiers allow it")
	controller._update_pending_bonus_spawns(float(GameConfig.MERGE_TIMELINE_NORMAL.reveal) + float(GameConfig.CHAIN_PRESENTATION_STAGGER) * 2.0 + 0.001)
	var sibling_ids: Array = controller.bonus_spawn_history.back().piece_ids as Array
	_assert(sibling_ids.size() == 2, "A combo-2 reward must create both sibling gems in one spawn event")
	var first_feedback: Dictionary = controller.piece_visual_feedbacks[sibling_ids[0]]
	var second_feedback: Dictionary = controller.piece_visual_feedbacks[sibling_ids[1]]
	_assert(is_equal_approx(float(first_feedback.elapsed), float(second_feedback.elapsed)) and is_equal_approx(float(first_feedback.duration), float(second_feedback.duration)), "All reward siblings must begin on the same frame with the same pop phase")
	var first_sibling: GemPiece = controller._live_piece(int(sibling_ids[0]))
	var second_sibling: GemPiece = controller._live_piece(int(sibling_ids[1]))
	_assert(first_sibling.velocity.length() > 0.0 and second_sibling.velocity.length() > 0.0, "Every sibling must have active physics immediately")
	controller.pieces.clear()
	controller.piece_visual_feedbacks.clear()
	controller.gem_sprite_layer.clear_presentation_scales()
	controller.pending_bonus_spawns.clear()
	controller.bonus_spawn_budget_remaining = GameConfig.BONUS_GEM_BUDGET_PER_SHOT
	for depth in [0, 1, 2, 3, 4]:
		controller._schedule_bonus_gems({
			"result_id": 9000 + depth,
			"level": 6,
			"midpoint": Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 180.0),
			"depth": depth,
		})
	var reserved := 0
	for pending in controller.pending_bonus_spawns:
		reserved += (pending.get("levels", []) as Array).size()
	_assert(reserved == GameConfig.BONUS_GEM_BUDGET_PER_SHOT, "One shot must never schedule more real reward pieces than its fixed budget")
	_assert(controller.bonus_spawn_budget_remaining == 0, "The shot budget must be exhausted deterministically")
	controller.pending_bonus_spawns.clear()
	controller.bonus_spawn_budget_remaining = GameConfig.BONUS_GEM_BUDGET_PER_SHOT
	while controller.pieces.size() < GameConfig.BONUS_BOARD_PIECE_CAP:
		var id := 10000 + controller.pieces.size()
		controller.pieces.append(PieceType.new(id, 1, Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 220.0), GameConfig.gem_collision_radius(1)))
	controller._schedule_bonus_gems({"result_id": 9999, "level": 6, "midpoint": Vector2.ZERO, "depth": 4})
	_assert(controller.pending_bonus_spawns.is_empty(), "A crowded board at the population cap must not schedule more reward pieces")
	controller.queue_free()
	await process_frame


func _test_bonus_release_grace() -> void:
	var simulation := BoardSimulation.new()
	var merger := ContactMergeService.new()
	var first := PieceType.new(8101, 1, Vector2(300.0, 600.0), GameConfig.gem_collision_radius(1))
	var second := PieceType.new(8102, 1, Vector2(300.0 + first.radius * 1.8, 600.0), GameConfig.gem_collision_radius(1))
	for piece in [first, second]:
		piece.bonus_event_id = 99
		piece.bonus_merge_grace_remaining = float(GameConfig.BONUS_MERGE_GRACE_MS) / 1000.0
	var pair: Array[GemPiece] = [first, second]
	simulation.step(pair, STEP, merger)
	_assert(not merger.has_pending_candidates(), "Fresh bonus pieces must collide without immediately merging during release grace")
	simulation.step(pair, float(GameConfig.BONUS_MERGE_GRACE_MS) / 1000.0 + STEP, merger)
	_assert(merger.has_pending_candidates(), "Same-event bonus pieces must become completely normal merge candidates after grace")
	merger.clear()
	var existing := PieceType.new(8103, 1, first.position + Vector2(first.radius * 1.8, 0.0), GameConfig.gem_collision_radius(1))
	first.bonus_merge_grace_remaining = float(GameConfig.BONUS_MERGE_GRACE_MS) / 1000.0
	first.bonus_event_id = 100
	var mixed: Array[GemPiece] = [first, existing]
	first.velocity = Vector2(80.0, 0.0)
	simulation.step(mixed, STEP, merger)
	_assert(not simulation.consume_collision_impacts().is_empty(), "A newly visible bonus gem must collide physically during merge grace")
	_assert(not merger.has_pending_candidates(), "Immediate physical contact must not bypass the short readability grace")
	first.position = Vector2(300.0, 600.0)
	existing.position = first.position + Vector2(first.radius * 1.8, 0.0)
	first.velocity = Vector2.ZERO
	existing.velocity = Vector2.ZERO
	simulation.step(mixed, float(GameConfig.BONUS_MERGE_GRACE_MS) / 1000.0 + STEP, merger)
	var resolved := merger.resolve(mixed, 8200)
	_assert(int(resolved.merge_count) == 1, "A bonus gem must merge normally after its post-release readability grace")
	_assert((resolved.presentation_events[0].source_ids as Array).has(first.id), "The real bonus gem must participate in the confirmed gameplay merge")


func _prepare_final_target(controller: GameControllerType, final_target: bool) -> void:
	var sequence := controller.target_sequence()
	if final_target:
		controller.target_index = sequence.size() - 1
	else:
		controller.target_index = 0
	controller.presented_target_index = controller.target_index
	controller.target_progress = controller.active_target_quantity() - 1
	controller.presented_target_progress = controller.target_progress


func _test_non_final_target_keeps_standard_collection() -> void:
	var controller := _controller()
	await process_frame
	controller._on_home_level_intro_requested()
	controller._on_home_play_requested()
	if controller.target_sequence().size() < 2:
		paused = false
		controller.queue_free()
		await process_frame
		return
	_prepare_final_target(controller, false)
	var expected_index := controller.presented_target_index + 1
	controller._apply_confirmed_merge_events([_merge_event(controller, 7100, controller.active_target_tier(), 0)])
	_assert(not controller.final_celebration_active, "A non-final target must not start the level celebration")
	_assert(not controller.win_qualified, "A non-final target must not qualify the win")
	var moving_result: GemPiece = controller._live_piece(7100)
	moving_result.position += Vector2(34.0, 18.0)
	controller._sync_pending_target_coin_origins()
	for coin in controller.effects_layer.coin_rewards:
		var coin_start: Vector2 = coin.start
		_assert(coin_start.is_equal_approx(moving_result.position), "Unrevealed target coins must originate at the result gem's current position")
	var first_coin_flight_at := GameConfig.target_coin_flight_start(0, GameConfig.COIN_BURST_COUNT)
	controller.effects_layer.update_effects(GameConfig.COIN_REWARD_START_DELAY + first_coin_flight_at - 0.01)
	_assert(controller.effects_layer.active_coin_count() == GameConfig.COIN_BURST_COUNT and controller.effects_layer._coin_flights_started.is_empty(), "All target coins must remain on the table together through the configured hold")
	controller.effects_layer.update_effects(0.02)
	_assert(controller.effects_layer._coin_flights_started.has(7100), "Target coin flight state must begin only when the first held coin actually leaves")
	controller._update_merge_presentations(GameConfig.TARGET_COLLECTION_OVERLAP_START + 0.01)
	_assert(controller.collection_in_progress and bool(controller.target_collection.get("hero", false)), "Every target must use the shared center-and-HUD collection sequence")
	controller._update_target_collection(GameConfig.HERO_TRAVEL_DURATION + GameConfig.HERO_HOLD_DURATION + GameConfig.HERO_LAUNCH_ANTICIPATION_DURATION + GameConfig.HERO_FLIGHT_DURATION + 0.01)
	_assert(controller.presented_target_index == expected_index, "A non-final target must still advance the HUD on arrival")
	paused = false
	controller.queue_free()
	await process_frame


func _test_final_target_celebration() -> void:
	var controller := _controller()
	await process_frame
	controller._on_home_level_intro_requested()
	controller._on_home_play_requested()
	_prepare_final_target(controller, true)
	var target_tier := controller.active_target_tier()
	var expected_reward := GameConfig.target_coin_reward_for_result_level(target_tier)
	var coins_before := controller.coins
	var presented_index_before := controller.presented_target_index
	var event := _merge_event(controller, 7200, target_tier, 0)
	controller._apply_confirmed_merge_events([event])
	# Applying the identical confirmed result twice must never double-reward.
	controller._apply_confirmed_merge_events([event])
	_assert(controller.coins == coins_before + expected_reward, "The final target reward must be awarded exactly once")
	_assert(controller.win_qualified and controller.final_celebration_active, "The final target must qualify the win and lock the celebration state")
	_assert(controller.final_celebration_coins == expected_reward, "The celebration must animate the exact authoritative reward")
	_assert(controller.effects_layer.active_coin_count() == 0, "The final target must not also fire the compact per-target coin group")

	var effects := controller.effects_layer
	var elapsed := 0.0
	var count_changed_at := -1.0
	var launcher_spawned := false
	var coins_seen := 0
	var coins_visible_at_hold := 0
	var win_before_coins := false
	var hero_arrival_at := GameConfig.FINAL_TARGET_COLLECTION_OVERLAP_START \
		+ GameConfig.HERO_TRAVEL_DURATION \
		+ GameConfig.HERO_HOLD_DURATION \
		+ GameConfig.HERO_LAUNCH_ANTICIPATION_DURATION \
		+ GameConfig.HERO_FLIGHT_DURATION
	while elapsed < 5.0:
		controller._process(STEP)
		elapsed += STEP
		if controller.get_active_piece() != null:
			launcher_spawned = true
		if count_changed_at < 0.0 and controller.presented_target_index != presented_index_before:
			count_changed_at = elapsed
		if elapsed >= 2.25 and elapsed <= 3.10:
			coins_visible_at_hold = maxi(coins_visible_at_hold, effects.visible_level_reward_coin_count())
		coins_seen = maxi(coins_seen, effects.active_level_reward_coin_count())
		if controller.win_presented and effects.has_active_coin_flights():
			win_before_coins = true
		# Pointer input must be rejected for the whole celebration.
		controller._handle_pointer(Vector2(GameConfig.table_center_x(), GameConfig.launch_y()), true)
		if controller.dragging:
			failures.append("Input must remain locked while the final celebration runs")
			break

	_assert(count_changed_at < 0.0 or count_changed_at >= hero_arrival_at - 0.08, "The target count must not complete before the hero gem reaches the HUD (changed %.3f, expected %.3f)" % [count_changed_at, hero_arrival_at])
	_assert(controller.presented_target_index == presented_index_before + 1, "The target count must advance once the hero gem arrives")
	_assert(not launcher_spawned, "No shooter gem may spawn during the final celebration")
	_assert(coins_seen == GameConfig.LEVEL_REWARD_COIN_COUNT, "The level reward must spawn the approved visible coin count")
	_assert(coins_visible_at_hold >= GameConfig.LEVEL_REWARD_COIN_COUNT, "Every reward coin must be visible on the table during the hold")
	_assert(not win_before_coins, "Level Complete must not appear while reward coins are still travelling")
	_assert(controller.win_presented, "Level Complete must appear once the reward animation finishes")
	_assert(not controller.final_celebration_active and not effects.has_active_level_reward(), "The celebration state must clear itself")
	_assert(controller.coins == coins_before + expected_reward, "The stored economy value must stay mathematically exact")
	_assert(controller.gameplay_ui.pending_coin_value() == 0, "Every reward coin must be accounted for in the HUD counter")
	# The whole hero-to-settled celebration must stay inside the approved budget.
	_assert(GameConfig.final_celebration_duration() <= 4.8, "The celebration must remain bounded after the longer readable holds")
	paused = false
	controller.queue_free()
	await process_frame


## Real on-disk progress. This test drives the actual COLLECT/transition/reload
## flow, so the developer's own save must be preserved exactly as found.
func _backup_save_file() -> Dictionary:
	var path := ProjectSettings.globalize_path(SAVE_FILE)
	if not FileAccess.file_exists(path):
		return {"existed": false, "bytes": PackedByteArray()}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"existed": false, "bytes": PackedByteArray()}
	var bytes := file.get_buffer(file.get_length())
	file.close()
	return {"existed": true, "bytes": bytes}


func _restore_save_file(snapshot: Dictionary) -> void:
	var path := ProjectSettings.globalize_path(SAVE_FILE)
	if not bool(snapshot.get("existed", false)):
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_buffer(snapshot.get("bytes", PackedByteArray()))
	file.close()


## Regression for the reported HUD-drop bug: once the final-target reward coins
## begin landing in the HUD, the counter must never fall back to the pre-level
## balance — not when the last coin arrives, not when Level Complete opens or
## settles, not on COLLECT, not across the level transition, and not after the
## scene is torn down and the save is reloaded.
func _test_hud_coin_counter_continuity() -> void:
	var save_snapshot := _backup_save_file()
	var controller := _controller()
	await process_frame
	controller._on_home_level_intro_requested()
	controller._on_home_play_requested()
	# Fix the level number so the interstitial cadence (every 2 levels) never
	# gates the transition this test drives deterministically.
	controller.level_number = 1
	_prepare_final_target(controller, true)
	var hud := controller.gameplay_ui
	var target_tier := controller.active_target_tier()
	var expected_reward := GameConfig.target_coin_reward_for_result_level(target_tier)
	var balance_before := controller.coins
	var expected_final := balance_before + expected_reward
	controller._apply_confirmed_merge_events([_merge_event(controller, 7300, target_tier, 0)])
	_assert(controller.coins == expected_final, "balance_before + target_reward must equal the new authoritative balance")
	_assert(controller.final_celebration_active, "The final target must start the celebration state")

	var effects := controller.effects_layer
	var elapsed := 0.0
	var seen_coins_active := false
	var displayed_after_last_coin := -1
	var displayed_at_win_presented := -1
	var win_presented_seen := false
	while elapsed < 5.0:
		controller._process(STEP)
		elapsed += STEP
		if effects.has_active_coin_flights():
			seen_coins_active = true
		elif seen_coins_active and displayed_after_last_coin < 0:
			# The frame the last reward coin lands and the flight channel empties.
			displayed_after_last_coin = hud.displayed_coin_value()
			_assert(displayed_after_last_coin == expected_final, "HUD must already read the final balance the instant the last coin arrives")
		if controller.win_presented and not win_presented_seen:
			win_presented_seen = true
			displayed_at_win_presented = hud.displayed_coin_value()
			_assert(displayed_at_win_presented == expected_final, "HUD must not drop when Level Complete opens")

	_assert(win_presented_seen, "Level Complete must present once the celebration finishes")
	_assert(hud.displayed_coin_value() == expected_final, "HUD must still read the final balance once Level Complete has settled")
	_assert(controller.coins == expected_final, "The authoritative balance must not have changed merely by settling")

	# COLLECT must not re-grant the reward or re-animate/drop the counter.
	controller._on_collect_requested()
	_assert(controller.coins == expected_final, "COLLECT must not grant the reward a second time")
	_assert(hud.displayed_coin_value() == expected_final, "HUD must remain at the final balance after COLLECT")
	var saved_after_collect := ProgressionSaveServiceType.load_progress()
	_assert(int(saved_after_collect.total_coins) == expected_final, "COLLECT must persist the exact authoritative balance")

	# Drive the same transition COLLECT's reward-card tween normally triggers.
	var level_before_transition := controller.level_number
	controller._on_reward_animation_finished()
	await process_frame
	await process_frame
	_assert(controller.level_number == level_before_transition + 1, "The level transition must advance exactly once")
	_assert(controller.coins == expected_final, "The level transition must not change the authoritative balance")
	_assert(hud.displayed_coin_value() == expected_final, "HUD must still read the final balance after the level transition")

	# Leaving and re-entering (a fresh controller reloading the save) must not
	# lose or duplicate the reward.
	paused = false
	controller.queue_free()
	await process_frame
	var reloaded := _controller()
	await process_frame
	_assert(reloaded.coins == expected_final, "Reloading the save must preserve the exact authoritative balance")
	_assert(reloaded.gameplay_ui.displayed_coin_value() == expected_final, "A freshly loaded scene must show the same balance, not a stale or reset one")
	paused = false
	reloaded.queue_free()
	await process_frame

	_restore_save_file(save_snapshot)
