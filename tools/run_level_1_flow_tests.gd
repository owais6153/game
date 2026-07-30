extends SceneTree

const GameScene = preload("res://scenes/Game.tscn")
const GemPieceType = preload("res://scripts/gem_piece.gd")
const LevelConfigType = preload("res://scripts/level_config.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_level_data()
	_test_launcher_range_and_queue()
	_test_target_counting_and_win_sequence()
	_test_restart_and_fail()
	if failures.is_empty():
		print("LEVEL_1_FLOW_TESTS: PASS")
		quit(0)
	for failure in failures:
		push_error(failure)
	quit(1)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _piece(id: int, level: int, position: Vector2) -> GemPiece:
	return GemPieceType.new(id, level, position, GameConfig.gem_collision_radius(level))

func _test_level_data() -> void:
	var config := LevelConfigType.level_1()
	_assert(int(config.active_tier_max) - int(config.active_tier_min) + 1 == 8, "Level 1 must configure exactly eight contiguous tiers")
	_assert(int(config.active_tier_min) == 1 and int(config.active_tier_max) == 8, "Level 1 must use L1-L8")
	_assert(int(config.target_tier) >= int(config.active_tier_min) and int(config.target_tier) <= int(config.active_tier_max), "Target must belong to the active range")
	_assert(int(config.target_tier) == 4 and int(config.target_quantity) == 2, "Level 1 must require two L4 results from its one target type")
	for tier in config.spawnable_tiers:
		_assert(int(tier) >= int(config.active_tier_min) and int(tier) <= int(config.active_tier_max), "Launcher tier must stay in active range")
	_assert((config.spawn_weights as Dictionary).has(1) and (config.spawn_weights as Dictionary).has(2), "Early target must be achievable from low launcher tiers")

func _test_launcher_range_and_queue() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	for index in range(12):
		var active = controller.get_active_piece()
		_assert(active != null and [1, 2].has(active.level), "Launcher must never produce a tier outside Level 1's configured low-tier range")
		controller.active_piece_id = -1
		active.is_active_launcher = false
		controller.launcher_state = controller.LauncherState.SPAWNING_NEXT
		controller._advance_launcher_lifecycle()
	var snapshot: Dictionary = controller.hud_snapshot()
	_assert(int(snapshot.current_level) in [1, 2] and int(snapshot.next_level) in [1, 2], "Current and next previews must use the configured queue")
	controller.queue_free()

func _test_target_counting_and_win_sequence() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	var non_target_events: Array[Dictionary] = [{"level": 5, "depth": 0, "result_id": 100}]
	controller._apply_confirmed_merge_events(non_target_events)
	_assert(controller.target_progress == 0 and not controller.win_qualified, "Non-target confirmed merge must not increment Level 1 target progress")
	var target_events: Array[Dictionary] = [{"level": 4, "depth": 0, "result_id": 101}]
	controller._apply_confirmed_merge_events(target_events)
	_assert(controller.target_progress == 1 and not controller.win_qualified, "First confirmed target result must increment progress without qualifying win")
	var second_target_events: Array[Dictionary] = [{"level": 4, "depth": 0, "result_id": 102}]
	controller._apply_confirmed_merge_events(second_target_events)
	_assert(controller.target_progress == 2 and controller.win_qualified and not controller.win_presented, "Second confirmed target result must qualify win without presenting it early")
	controller._apply_confirmed_merge_events(target_events)
	_assert(controller.target_progress == 2, "One confirmed merge result must count toward target once")
	controller.merge_presentations.clear()
	controller._update_win_presentation(GameConfig.WIN_PRESENTATION_HOLD + 0.01)
	_assert(controller.win_presented, "Win overlay must wait for final target merge presentation/hold")
	controller.queue_free()

func _test_restart_and_fail() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	var target_events: Array[Dictionary] = [{"level": 4, "depth": 0, "result_id": 200}, {"level": 4, "depth": 0, "result_id": 201}]
	controller._apply_confirmed_merge_events(target_events)
	controller.restart()
	_assert(controller.target_progress == 0 and not controller.win_qualified and controller.get_active_piece() != null, "Restart must reset Level 1 target state and launcher")
	var danger := _piece(900, 1, Vector2(300, GameConfig.DANGER_LINE_Y + 20.0))
	controller.pieces.append(danger)
	for frame in range(50):
		controller._process(1.0 / 60.0)
	_assert(controller.failed, "Existing danger-line failure must remain unchanged")
	controller.queue_free()
