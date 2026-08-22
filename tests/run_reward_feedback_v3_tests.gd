extends SceneTree

## Reward feedback v3. These tests protect the reward hierarchy
## (collision < normal merge < combo merge < final target < level complete),
## the staged final-target celebration, and the exactly-once reward contract.

const GameControllerType = preload("res://scripts/game_controller.gd")
const PieceType = preload("res://scripts/gem_piece.gd")
const ProgressionSaveServiceType = preload("res://scripts/progression_save_service.gd")
const SAVE_FILE := "user://infinite_progression.cfg"

const STEP := 1.0 / 60.0

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_merge_timeline_hierarchy()
	_test_normal_merge_scale_timeline()
	await _test_cosmetic_merge_effects()
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
	var final_target: Dictionary = GameConfig.merge_timeline(0, true)
	_assert(float(normal.ring_scale) < float(combo_1.ring_scale), "COMBO 1 must read stronger than an ordinary merge")
	_assert(float(combo_1.ring_scale) < float(combo_2.ring_scale), "COMBO 2 must read stronger than COMBO 1")
	_assert(float(combo_2.ring_scale) < float(combo_3.ring_scale), "COMBO 3+ must read stronger than COMBO 2")
	_assert(float(normal.pitch) < float(combo_1.pitch) and float(combo_1.pitch) < float(combo_2.pitch) and float(combo_2.pitch) < float(combo_3.pitch), "Combo SFX pitch must rise with chain depth")
	_assert(int(normal.mini_gems) == 3 and int(combo_1.mini_gems) == 3 and int(combo_2.mini_gems) == 5 and int(combo_3.mini_gems) == 5, "Mini-gem counts must follow the approved combo ladder")
	_assert(float(combo_3.hitstop) > float(normal.hitstop), "COMBO 3+ must use a longer hit-stop than a normal merge")
	_assert(float(final_target.hitstop) > float(combo_3.hitstop), "The final target must own the strongest hit-stop")
	_assert(float(final_target.duration) < float(normal.duration), "Final-target Phase A must hand the gem to the hero sequence early")
	_assert(is_equal_approx(float(final_target.duration), GameConfig.FINAL_TARGET_COLLECTION_OVERLAP_START), "Hero travel must begin exactly when Phase A ends")
	# The chain label ladder must not lend deep-chain wording to shallow chains.
	_assert(GameConfig.combo_label_text(1) == "COMBO 1" and GameConfig.combo_label_text(2) == "COMBO 2", "Low chains must use plain combo labels")
	_assert(GameConfig.combo_label_text(3) == "COMBO 3!", "COMBO 3 must stay a plain emphatic label")
	_assert(GameConfig.combo_label_text(4).contains("AMAZING") and GameConfig.combo_label_text(5).contains("PERFECT"), "Rare deep chains may use the escalated wording")
	# The two deliberate pauses of the celebration must survive retuning.
	_assert(is_equal_approx(GameConfig.HERO_HOLD_DURATION, 0.50), "The hero recognition hold must remain 500 ms")
	_assert(GameConfig.LEVEL_REWARD_COIN_TABLE_HOLD >= 0.35 and GameConfig.LEVEL_REWARD_COIN_TABLE_HOLD <= 0.40, "The visible coin hold must remain 350-400 ms")
	_assert(is_equal_approx(GameConfig.level_reward_collect_start(), GameConfig.LEVEL_REWARD_COIN_LAND_DURATION + GameConfig.LEVEL_REWARD_COIN_TABLE_HOLD), "Coin collection must begin exactly one landing plus one hold after the first wave")
	_assert(GameConfig.LEVEL_REWARD_COIN_COUNT >= 18 and GameConfig.LEVEL_REWARD_COIN_COUNT <= 25, "The level reward must stay inside the approved visible coin range")
	_assert(GameConfig.LEVEL_REWARD_COIN_COLLECT_WAVE_SIZE == 3 and GameConfig.LEVEL_REWARD_COIN_COLLECT_STAGGER <= 0.05, "Coins must be collected in small staggered waves")
	_assert(GameConfig.LEVEL_REWARD_COIN_FLIGHT_DURATION >= 0.30 and GameConfig.LEVEL_REWARD_COIN_FLIGHT_DURATION <= 0.42, "Each coin flight must stay inside the approved 300-420 ms window")


func _test_normal_merge_scale_timeline() -> void:
	var controller := GameControllerType.new()
	var timeline: Dictionary = GameConfig.MERGE_TIMELINE_NORMAL
	_assert(is_equal_approx(controller._merge_result_transform_for(0.0, timeline).uniform_scale, 0.0), "The result gem must stay hidden through the hit-stop and source pull")
	_assert(is_equal_approx(controller._merge_result_transform_for(0.109, timeline).uniform_scale, 0.0), "The result gem must appear only at the 110 ms reveal")
	_assert(is_equal_approx(controller._merge_result_transform_for(0.11, timeline).uniform_scale, 0.65), "The result gem must be revealed at 0.65 scale")
	_assert(is_equal_approx(controller._merge_result_transform_for(0.19, timeline).uniform_scale, 1.18), "The merge pop must peak at 1.18 at 190 ms")
	_assert(is_equal_approx(controller._merge_result_transform_for(0.30, timeline).uniform_scale, 0.96), "The merge must settle to 0.96 at 300 ms")
	_assert(is_equal_approx(controller._merge_result_transform_for(0.345, timeline).uniform_scale, 1.02), "The secondary settle must reach 1.02")
	_assert(is_equal_approx(controller._merge_result_transform_for(0.39, timeline).uniform_scale, 1.0), "The merge must return to 1.0 by 390 ms")
	_assert(is_equal_approx(controller._merge_result_transform_for(0.42, timeline).uniform_scale, 1.0), "The merge must stay at rest until the presentation ends")
	var hero: Dictionary = GameConfig.MERGE_TIMELINE_FINAL_TARGET
	_assert(is_equal_approx(controller._merge_result_transform_for(0.12, hero).uniform_scale, 0.65), "Final-target Phase A must reveal at 0.65")
	_assert(is_equal_approx(controller._merge_result_transform_for(0.18, hero).uniform_scale, 1.25), "Final-target Phase A must reach 1.25 before the hero travel")
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


func _test_cosmetic_merge_effects() -> void:
	var controller := _controller()
	await process_frame
	controller._on_home_level_intro_requested()
	controller._on_home_play_requested()
	var effects := controller.effects_layer
	var pieces_before := controller.pieces.size()
	# A non-target ordinary merge: mini gems and rings appear, no combo label.
	controller._apply_confirmed_merge_events([_merge_event(controller, 7001, 1, 0)])
	_assert(effects.active_mini_gem_count() == 3, "An ordinary merge must emit three cosmetic mini gems")
	_assert(effects.active_combo_label_count() == 0, "An ordinary merge must not show a combo label")
	_assert(controller.pieces.size() == pieces_before + 1, "Mini gems and rings must never add simulation bodies")
	# The hit-stop freezes only the confirmed result, and restores its momentum.
	var chained := _merge_event(controller, 7002, 1, 1)
	var result_piece: GemPiece = controller.pieces.back()
	result_piece.velocity = Vector2(0.0, -180.0)
	controller._apply_confirmed_merge_events([chained])
	_assert(result_piece.velocity == Vector2.ZERO, "The merge hit-stop must lock the confirmed result gem")
	_assert(effects.active_combo_label_count() == 1, "A chained merge must show exactly one combo label")
	controller._update_merge_hitstops(GameConfig.MERGE_HITSTOP_DURATION + 0.001)
	_assert(result_piece.velocity.is_equal_approx(Vector2(0.0, -180.0)), "The hit-stop must restore the exact merge momentum")
	_assert(controller.merge_hitstops.is_empty(), "The hit-stop must release itself")
	# Level boundaries must not leak temporary cosmetic nodes or records.
	controller.restart()
	_assert(effects.active_mini_gem_count() == 0 and effects.active_combo_label_count() == 0, "Restart must clear every temporary cosmetic record")
	_assert(not effects.has_active_level_reward() and not controller.final_celebration_active, "Restart must cancel any running celebration")
	paused = false
	controller.queue_free()
	await process_frame


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
	controller._update_merge_presentations(GameConfig.TARGET_COLLECTION_OVERLAP_START + 0.01)
	_assert(controller.collection_in_progress and not bool(controller.target_collection.get("hero", false)), "A non-final target must keep the existing compact collection")
	controller._update_target_collection(GameConfig.TARGET_COLLECTION_DURATION + 0.01)
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
	var counted_before_arrival := false
	var launcher_spawned := false
	var coins_seen := 0
	var coins_visible_at_hold := 0
	var win_before_coins := false
	while elapsed < 3.4:
		controller._process(STEP)
		elapsed += STEP
		if controller.get_active_piece() != null:
			launcher_spawned = true
		if elapsed < 1.25 and controller.presented_target_index != presented_index_before:
			counted_before_arrival = true
		if elapsed >= 1.60 and elapsed <= 2.05:
			coins_visible_at_hold = maxi(coins_visible_at_hold, effects.visible_level_reward_coin_count())
		coins_seen = maxi(coins_seen, effects.active_level_reward_coin_count())
		if controller.win_presented and effects.has_active_coin_flights():
			win_before_coins = true
		# Pointer input must be rejected for the whole celebration.
		controller._handle_pointer(Vector2(GameConfig.table_center_x(), GameConfig.launch_y()), true)
		if controller.dragging:
			failures.append("Input must remain locked while the final celebration runs")
			break

	_assert(not counted_before_arrival, "The target count must not complete before the hero gem reaches the HUD")
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
	_assert(GameConfig.final_celebration_duration() <= 3.1, "The celebration must remain responsive, not sluggish")
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
	while elapsed < 3.4:
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
