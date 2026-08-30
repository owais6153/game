extends SceneTree

## Long-session hygiene. Everything here is a container or node pool that grows
## during play; each must be bounded, cleaned up, or cleared on restart.

const GameScene = preload("res://scenes/Game.tscn")
const LevelConfigType = preload("res://scripts/core/level_config.gd")
const PowerInventoryServiceType = preload("res://scripts/services/power_inventory_service.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_collision_history_is_bounded()
	await _test_repeated_power_use_leaks_nothing()
	_test_bounded_pools_are_configured()
	if failures.is_empty():
		print("PERFORMANCE_HYGIENE_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("PERFORMANCE_HYGIENE_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


## The contact-cooldown map was only ever written to. Gem ids are never reused,
## so a long level accumulated one dead entry per gem that ever touched
## anything, none of which could be read again.
func _test_collision_history_is_bounded() -> void:
	var controller = await _start()
	var threshold: int = controller.COLLISION_HISTORY_PRUNE_THRESHOLD
	# Far more distinct gem ids than could ever be on cooldown at once.
	for piece_id in range(threshold * 20):
		controller.collision_visual_clock += GameConfig.COLLISION_VISUAL_COOLDOWN * 2.0
		controller._begin_collision_visual(9000 + piece_id, Vector2.UP, 800.0)
	_assert(controller.collision_visual_last_at.size() <= threshold + 2,
		"the contact-cooldown map must stay bounded (grew to %d over %d contacts)"
			% [controller.collision_visual_last_at.size(), threshold * 20])
	# Pruning must not break the cooldown it exists to enforce.
	controller.collision_visual_last_at.clear()
	controller.collision_visual_clock = 100.0
	controller._begin_collision_visual(1, Vector2.UP, 800.0)
	var feedback_count = controller.piece_visual_feedbacks.size()
	controller._begin_collision_visual(1, Vector2.UP, 800.0)
	_assert(controller.piece_visual_feedbacks.size() == feedback_count,
		"a second contact inside the cooldown must still be suppressed")
	_free(controller)


func _test_repeated_power_use_leaks_nothing() -> void:
	var controller = await _start()
	var before = _node_count(controller)
	var orphans_before := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	for _cycle in range(10):
		controller.power_state = PowerInventoryServiceType.ensure_state({
			"counts": {"bomb": 9, "magnet": 9, "switch": 9, "hammer": 9},
			"granted_starter": true,
		})
		for power in PowerInventoryServiceType.ALL:
			controller._on_power_requested(power)
			if not controller.pending_power_target.is_empty():
				controller._resolve_power_target(Vector2(360.0, GameConfig.danger_line_y() - 120.0))
			if controller.power_cinematic != null and controller.power_cinematic.is_playing():
				controller.power_cinematic.skip_to_impact()
				for _step in range(12):
					controller.power_cinematic._process(1.0 / 60.0)
			controller.power_request_locked = false
		await process_frame
	var after = _node_count(controller)
	_assert(after <= before + 8,
		"repeated power use must not accumulate nodes (%d -> %d)" % [before, after])
	_assert(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) <= orphans_before,
		"repeated power use must not orphan nodes")
	_free(controller)


## Caps that stop unbounded growth by construction.
func _test_bounded_pools_are_configured() -> void:
	_assert(GameConfig.PRESENTATION_EVENT_TRACE_LIMIT > 0,
		"the presentation trace must be capped")
	_assert(GameConfig.AUDIO_MAX_CONCURRENT_PLAYERS > 0 and GameConfig.AUDIO_MAX_CONCURRENT_PLAYERS <= 24,
		"the audio voice pool must be bounded and modest")
	_assert(GameConfig.BONUS_BOARD_PIECE_CAP > 0,
		"bonus spawns must respect a board population cap")
	_assert(GameConfig.BONUS_GEM_BUDGET_PER_SHOT > 0,
		"bonus spawns must respect a per-shot budget")


func _start():
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1600)
	viewport.disable_3d = true
	root.add_child(viewport)
	var controller = GameScene.instantiate()
	viewport.add_child(controller)
	await process_frame
	controller.level_number = 6
	controller.level_seed = LevelConfigType.seed_for_level(6)
	controller.restart()
	controller._on_home_level_intro_requested()
	controller._on_home_play_requested()
	controller.set_process(false)
	return controller


func _free(controller) -> void:
	var viewport = controller.get_parent()
	if viewport != null:
		viewport.queue_free()


func _node_count(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _node_count(child)
	return total


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
