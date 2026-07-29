extends SceneTree

const GemPieceType = preload("res://scripts/gem_piece.gd")
const SimulationType = preload("res://scripts/board_simulation.gd")
const MergeType = preload("res://scripts/merge_service.gd")
const GemVisualsType = preload("res://scripts/gem_visuals.gd")
const GameScene = preload("res://scenes/Game.tscn")
var failures: Array[String] = []

func _init() -> void:
	_test_contact_merges()
	_test_rejections()
	_test_one_piece_once_per_cycle()
	_test_contact_chain_merges()
	_test_distant_piece_does_not_chain()
	_test_chain_depth_cap()
	_test_merge_presentation_blocks_next_launcher()
	_test_unobstructed_top_border()
	_test_launch_timing_and_settling()
	_test_frame_step_stability()
	_test_border_containment()
	_test_launcher_spawn_lifecycle()
	_test_score_and_chain_runtime_path()
	_test_win_stops_spawning()
	_test_danger_line_failure_rules()
	_test_chain_presentation_cadence()
	_test_overlay_reset()
	_test_visual_level_mapping()
	_test_visual_layout_bounds()
	_test_portrait_board_bounds_and_scale()
	_test_merge_momentum_is_bounded_and_contained()
	_test_progression_hud_snapshot_and_queue()
	_test_hud_layout_and_pointer_safety()
	if failures.is_empty():
		print("CLEAN_CONTACT_TESTS: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _piece(id: int, level: int, at_position: Vector2) -> GemPiece:
	return GemPieceType.new(id, level, at_position, GameConfig.PIECE_RADIUS)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _resolve(items: Array[GemPiece]) -> Dictionary:
	var merger = MergeType.new()
	var simulation = SimulationType.new()
	simulation.step(items, 0.0, merger)
	return merger.resolve(items, 100)

func _test_contact_merges() -> void:
	var empty: Array[GemPiece] = []
	_assert(empty.is_empty(), "Board must start empty before the controller creates the launcher")
	var pearls: Array[GemPiece] = [_piece(1, 1, Vector2(300, 500)), _piece(2, 1, Vector2(360, 500))]
	var pearl_result := _resolve(pearls)
	_assert(pearl_result.pieces.size() == 1 and pearl_result.pieces[0].level == 2, "Contacting Pearl + Pearl must create one Ruby")
	var rubies: Array[GemPiece] = [_piece(1, 2, Vector2(300, 500)), _piece(2, 2, Vector2(360, 500))]
	var ruby_result := _resolve(rubies)
	_assert(ruby_result.pieces.size() == 1 and ruby_result.pieces[0].level == 3, "Contacting Ruby + Ruby must create one Emerald")

func _test_rejections() -> void:
	var distant: Array[GemPiece] = [_piece(1, 1, Vector2(200, 400)), _piece(2, 1, Vector2(500, 400))]
	_assert(_resolve(distant).pieces.size() == 2, "Distant Pearl/Pearl must not merge")
	var cross: Array[GemPiece] = [_piece(1, 1, Vector2(300, 400)), _piece(2, 2, Vector2(360, 400))]
	_assert(_resolve(cross).pieces.size() == 2, "Pearl + Ruby must not merge")

func _test_one_piece_once_per_cycle() -> void:
	var items: Array[GemPiece] = [_piece(1, 1, Vector2(300, 500)), _piece(2, 1, Vector2(360, 500)), _piece(3, 1, Vector2(420, 500))]
	_assert(_resolve(items).pieces.size() == 2, "A source piece must not merge twice in one cycle")

func _test_contact_chain_merges() -> void:
	var items: Array[GemPiece] = [_piece(1, 1, Vector2(300, 500)), _piece(2, 1, Vector2(360, 500)), _piece(3, 2, Vector2(330, 500))]
	var merger = MergeType.new()
	merger.capture_contact(items[0], items[1])
	var result := merger.resolve(items, 100)
	_assert(result.pieces.size() == 1 and result.pieces[0].level == 3, "A newly spawned Ruby physically contacting a Ruby must chain into Emerald")
	_assert(result.merge_count == 2 and result.chain_depth == 1, "A contact chain must record exactly one chained resolution")

func _test_distant_piece_does_not_chain() -> void:
	var items: Array[GemPiece] = [_piece(1, 1, Vector2(300, 500)), _piece(2, 1, Vector2(360, 500)), _piece(3, 2, Vector2(520, 500))]
	var merger = MergeType.new()
	merger.capture_contact(items[0], items[1])
	var result := merger.resolve(items, 100)
	_assert(result.pieces.size() == 2 and result.pieces.any(func(piece: GemPiece): return piece.level == 2), "A distant equal-level piece must not chain")

func _test_chain_depth_cap() -> void:
	var merger := MergeType.new()
	var items: Array[GemPiece] = [_piece(1, 1, Vector2(300, 500)), _piece(2, 1, Vector2(360, 500)), _piece(3, 2, Vector2(330, 500)), _piece(4, 3, Vector2(330, 500)), _piece(5, 4, Vector2(330, 500))]
	merger.capture_contact(items[0], items[1])
	var result := merger.resolve(items, 100)
	_assert(result.chain_depth <= GameConfig.MERGE_CHAIN_DEPTH_CAP, "Chain processing must remain capped")

func _test_merge_presentation_blocks_next_launcher() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	controller.merge_presentations.append({"first_position": Vector2(300, 500), "second_position": Vector2(360, 500), "midpoint": Vector2(330, 500), "level": 2, "depth": 0, "elapsed": 0.0})
	controller.launcher_state = controller.LauncherState.RESOLVING
	controller.active_piece_id = -1
	controller.pieces.clear()
	controller._process(0.01)
	_assert(controller.get_active_piece() == null, "Next launcher must wait while merge presentation is active")
	for frame in range(30): controller._process(1.0 / 60.0)
	_assert(controller.get_active_piece() != null, "Next launcher must spawn after merge presentation completes")

func _test_unobstructed_top_border() -> void:
	var simulation = SimulationType.new()
	var merger = MergeType.new()
	var shot := _piece(1, 1, Vector2(360, GameConfig.LAUNCH_Y))
	shot.velocity = Vector2(0, -GameConfig.LAUNCH_SPEED)
	var items: Array[GemPiece] = [shot]
	for index in range(500):
		simulation.step(items, 1.0 / 120.0, merger)
	_assert(shot.position.y >= GameConfig.BOARD_TOP + shot.radius, "Unobstructed shot must remain inside the top border")
	_assert(shot.velocity.length() < GameConfig.SLEEP_SPEED, "Unobstructed shot must settle")

func _test_launch_timing_and_settling() -> void:
	var simulation := SimulationType.new()
	var merger := MergeType.new()
	var shot := _piece(1, 1, Vector2(360, GameConfig.LAUNCH_Y))
	shot.velocity = Vector2(0, -GameConfig.LAUNCH_SPEED)
	var items: Array[GemPiece] = [shot]
	var top_time := -1.0
	var elapsed := 0.0
	for frame in range(600):
		simulation.step(items, 1.0 / 120.0, merger)
		elapsed += 1.0 / 120.0
		if top_time < 0.0 and is_equal_approx(shot.position.y, GameConfig.BOARD_TOP + shot.radius):
			top_time = elapsed
		if shot.is_settled(): break
	_assert(top_time >= 0.70 and top_time <= 1.30, "Launch must reach the top border within the approved feel range")
	_assert(shot.is_settled() and elapsed <= 2.25, "A clean top-border shot must settle without a long wait")
	var settled_position := shot.position
	for frame in range(120): simulation.step(items, 1.0 / 60.0, merger)
	_assert(shot.velocity == Vector2.ZERO and shot.position.distance_to(settled_position) < 0.01, "A settled piece must not retain persistent jitter")

func _test_frame_step_stability() -> void:
	var fine_sim := SimulationType.new()
	var coarse_sim := SimulationType.new()
	var fine_merger := MergeType.new()
	var coarse_merger := MergeType.new()
	var fine := _piece(1, 1, Vector2(360, GameConfig.LAUNCH_Y))
	var coarse := _piece(1, 1, Vector2(360, GameConfig.LAUNCH_Y))
	fine.velocity = Vector2(0, -GameConfig.LAUNCH_SPEED)
	coarse.velocity = Vector2(0, -GameConfig.LAUNCH_SPEED)
	var fine_items: Array[GemPiece] = [fine]
	var coarse_items: Array[GemPiece] = [coarse]
	for frame in range(120): fine_sim.step(fine_items, 1.0 / 120.0, fine_merger)
	for frame in range(60): coarse_sim.step(coarse_items, 1.0 / 60.0, coarse_merger)
	_assert(fine.position.distance_to(coarse.position) < 18.0, "Representative frame steps must keep launch movement predictably close")

func _test_border_containment() -> void:
	var simulation := SimulationType.new()
	var merger := MergeType.new()
	var piece := _piece(1, 1, Vector2(GameConfig.BOARD_LEFT + 40.0, GameConfig.BOARD_TOP + 40.0))
	piece.velocity = Vector2(-900.0, -900.0)
	var items: Array[GemPiece] = [piece]
	for frame in range(180): simulation.step(items, 1.0 / 60.0, merger)
	_assert(piece.position.x >= GameConfig.BOARD_LEFT + piece.radius and piece.position.x <= GameConfig.BOARD_RIGHT - piece.radius, "Side containment must remain valid during a wall shot")
	_assert(piece.position.y >= GameConfig.BOARD_TOP + piece.radius and piece.position.y <= GameConfig.BOARD_BOTTOM - piece.radius, "Top/bottom containment must remain valid during a wall shot")

func _test_launcher_spawn_lifecycle() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	_assert(controller.pieces.size() == 1 and controller.get_active_piece() != null, "Initial lifecycle state must contain exactly one active launcher")
	_assert(controller.lifecycle_name() == "READY_TO_AIM", "Initial launcher state must be READY_TO_AIM")
	var initial_next_level: int = controller.next_level
	controller.launch_active_piece()
	_assert(controller.lifecycle_name() == "SHOT_IN_FLIGHT", "Launching must enter SHOT_IN_FLIGHT")
	for frame in range(200):
		controller._process(1.0 / 60.0)
	_assert(controller.get_active_piece() != null, "Exactly one new active piece must exist after the first shot settles")
	_assert(_active_launcher_count(controller.pieces) == 1, "Active launcher count must never exceed one after settlement")
	_assert(controller.lifecycle_name() == "READY_TO_AIM", "Resolution must return to READY_TO_AIM")
	_assert(controller.next_level != initial_next_level, "Next queue must advance exactly once after the completed shot")
	var pieces_after_first_cycle: int = controller.pieces.size()
	var next_after_first_cycle: int = controller.next_level
	for frame in range(120):
		controller._process(1.0 / 60.0)
	_assert(controller.pieces.size() == pieces_after_first_cycle, "Idle frames must not spawn extra launcher pieces")
	_assert(controller.next_level == next_after_first_cycle, "Idle frames must not advance the next queue")
	controller.launch_active_piece()
	_assert(controller.lifecycle_name() == "SHOT_IN_FLIGHT", "Second launcher must be launchable normally")
	controller.restart()
	_assert(controller.pieces.size() == 1 and _active_launcher_count(controller.pieces) == 1, "Restart must leave exactly one active launcher")
	_assert(controller.lifecycle_name() == "READY_TO_AIM", "Restart must reset lifecycle to READY_TO_AIM")

func _test_score_and_chain_runtime_path() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	controller.pieces.append(_piece(100, 1, Vector2(300, 500)))
	controller.pieces.append(_piece(101, 1, Vector2(360, 500)))
	controller._process(0.0)
	_assert(controller.score == 10, "A confirmed Pearl merge must award the Ruby score once")
	_assert(controller.chain_multiplier == 1, "A single confirmed merge must use x1")
	var no_merge_score: int = controller.score
	controller.pieces.append(_piece(102, 1, Vector2(160, 500)))
	controller.pieces.append(_piece(103, 2, Vector2(220, 500)))
	controller._process(0.0)
	_assert(controller.score == no_merge_score, "Collision without a valid merge must award zero score")
	var chain_controller = GameScene.instantiate()
	chain_controller._ready()
	var confirmed_events: Array[Dictionary] = []
	confirmed_events.append({"level": 2})
	confirmed_events.append({"level": 3})
	chain_controller._apply_confirmed_merge_events(confirmed_events)
	_assert(chain_controller.score == 60, "Pearl merge plus Ruby chain must score 10 + (25 x2)")
	_assert(chain_controller.chain_multiplier == 2, "A two-merge resolution must end at x2")
	chain_controller.merge_presentations.clear()
	chain_controller.launcher_state = chain_controller.LauncherState.RESOLVING
	chain_controller.get_active_piece().is_active_launcher = false
	chain_controller.active_piece_id = -1
	chain_controller._process(GameConfig.NEXT_LAUNCHER_READY_DELAY + 0.01)
	chain_controller._process(0.01)
	_assert(chain_controller.chain_multiplier == 1, "Next-shot readiness must reset the chain multiplier")

func _test_win_stops_spawning() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	controller.pieces.append(_piece(300, 4, Vector2(300, 500)))
	controller.pieces.append(_piece(301, 4, Vector2(360, 500)))
	controller._process(0.0)
	_assert(controller.won, "Creating Diamond must trigger win exactly once")
	var count: int = controller.pieces.size()
	for frame in range(120): controller._process(1.0 / 60.0)
	_assert(controller.pieces.size() == count, "No launcher may spawn after win")

func _test_danger_line_failure_rules() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	var danger := _piece(400, 1, Vector2(300, GameConfig.DANGER_LINE_Y + 20.0))
	controller.pieces.append(danger)
	for frame in range(50): controller._process(1.0 / 60.0)
	_assert(controller.failed, "A settled non-active board gem below the danger line must fail after grace")
	var moving_controller = GameScene.instantiate()
	moving_controller._ready()
	var moving := _piece(401, 1, Vector2(300, GameConfig.DANGER_LINE_Y + 20.0))
	moving.velocity = Vector2(0.0, -400.0)
	moving_controller.pieces.append(moving)
	for frame in range(20): moving_controller._process(1.0 / 60.0)
	_assert(not moving_controller.failed, "A temporary moving danger-line crossing must not fail")
	var active_controller = GameScene.instantiate()
	active_controller._ready()
	for frame in range(60): active_controller._process(1.0 / 60.0)
	_assert(not active_controller.failed, "The active launcher must never trigger danger failure")

func _test_chain_presentation_cadence() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	var chain_events: Array[Dictionary] = [{"level": 2, "depth": 0}, {"level": 3, "depth": 1}]
	controller._apply_confirmed_merge_events(chain_events)
	_assert(controller.merge_presentations.size() == 2, "Two confirmed chain events must create two presentation records")
	_assert(is_equal_approx(controller.merge_presentations[0].elapsed, 0.0), "The first chain visual must start immediately")
	_assert(is_equal_approx(controller.merge_presentations[1].elapsed, -GameConfig.CHAIN_PRESENTATION_STAGGER), "Each later chain visual must use the approved display stagger")
	for frame in range(24): controller._update_merge_presentations(1.0 / 60.0)
	_assert(controller.merge_presentations.is_empty(), "A two-step chain presentation must complete within the approved pacing window")

func _test_overlay_reset() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	controller.score = 235
	controller.chain_multiplier = 3
	controller.won = true
	controller.danger_timers[99] = 1.0
	controller.restart()
	_assert(not controller.won and not controller.failed and controller.score == 0 and controller.chain_multiplier == 1, "Replay or Retry must clear outcome, score, and chain state")
	_assert(controller.danger_timers.is_empty() and controller.shot_count == 0, "Replay or Retry must clear danger timers and shots")
	_assert(controller.pieces.size() == 1 and _active_launcher_count(controller.pieces) == 1, "Replay or Retry must restore empty board plus one launcher")

func _test_visual_level_mapping() -> void:
	var expected := ["round pearl with soft highlight", "faceted ruby", "emerald-cut gem", "faceted sapphire", "multi-facet diamond"]
	for level in range(1, 6):
		_assert(GemVisualsType.visual_style_name(level) == expected[level - 1], "Gem level %d must keep its assigned procedural visual style" % level)

func _test_visual_layout_bounds() -> void:
	_assert(GameConfig.HUD_RECT.position.x >= 0.0 and GameConfig.HUD_RECT.end.x <= GameConfig.VIEWPORT_SIZE.x, "HUD must remain inside the design viewport")
	_assert(GameConfig.HUD_RECT.position.y >= 0.0 and GameConfig.HUD_RECT.end.y <= GameConfig.BOARD_TOP, "HUD must stay above the gameplay board")
	_assert(GameConfig.OVERLAY_RECT.position.x >= GameConfig.SAFE_VISUAL_MARGIN and GameConfig.OVERLAY_RECT.end.x <= GameConfig.VIEWPORT_SIZE.x - GameConfig.SAFE_VISUAL_MARGIN, "Overlay must remain within visual safe margins")
	_assert(GameConfig.OVERLAY_BUTTON_RECT.position.y >= GameConfig.OVERLAY_RECT.position.y and GameConfig.OVERLAY_BUTTON_RECT.end.y <= GameConfig.OVERLAY_RECT.end.y, "Overlay action must fit within its panel")
	_assert(GameConfig.RESTART_RECT.end.x <= GameConfig.HUD_RECT.end.x and GameConfig.RESTART_RECT.position.y >= GameConfig.HUD_RECT.position.y, "Restart control must remain inside the HUD")

func _test_portrait_board_bounds_and_scale() -> void:
	for portrait_size in [Vector2(720, 1280), Vector2(1080, 1920), Vector2(1440, 2560)]:
		var scale: float = portrait_size.x / GameConfig.VIEWPORT_SIZE.x
		_assert(GameConfig.BOARD_LEFT * scale >= 0.0 and GameConfig.BOARD_RIGHT * scale <= portrait_size.x, "Board must fit every supported portrait width")
		_assert(GameConfig.BOARD_TOP * scale >= GameConfig.HUD_RECT.end.y * scale and GameConfig.BOARD_BOTTOM * scale <= portrait_size.y, "Board must remain below HUD and inside every supported portrait height")
		_assert(GameConfig.PIECE_RADIUS * 2.0 <= (GameConfig.BOARD_RIGHT - GameConfig.BOARD_LEFT) * 0.20, "Gem scale must leave horizontal cluster room")

func _test_merge_momentum_is_bounded_and_contained() -> void:
	var first := _piece(1, 1, Vector2(300, 500))
	var second := _piece(2, 1, Vector2(360, 500))
	first.velocity = Vector2(900, -600)
	second.velocity = Vector2(900, -600)
	var merger := MergeType.new()
	merger.capture_contact(first, second)
	var result := merger.resolve([first, second], 100)
	var upgraded: GemPiece = result.pieces[0]
	_assert(upgraded.velocity.length() <= GameConfig.MERGE_MAX_SPAWN_SPEED + 0.01, "Upgraded-gem momentum must remain bounded")
	_assert(upgraded.position.x >= GameConfig.BOARD_LEFT + upgraded.radius and upgraded.position.x <= GameConfig.BOARD_RIGHT - upgraded.radius and upgraded.position.y >= GameConfig.BOARD_TOP + upgraded.radius and upgraded.position.y <= GameConfig.BOARD_BOTTOM - upgraded.radius, "Upgraded gem must spawn inside board bounds")

func _test_progression_hud_snapshot_and_queue() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	var first: Dictionary = controller.hud_snapshot()
	_assert(int(first.current_level) == 1 and int(first.next_level) == 2, "HUD previews must match the initial current/next queue")
	_assert(int(first.target_level) == 5, "HUD target highlight must remain Diamond (L5)")
	controller.launch_active_piece()
	for frame in range(200): controller._process(1.0 / 60.0)
	var after_shot: Dictionary = controller.hud_snapshot()
	_assert(int(after_shot.current_level) == 2 and int(after_shot.next_level) == 1, "HUD queue preview must advance exactly once after a shot cycle")
	controller.restart()
	var after_restart: Dictionary = controller.hud_snapshot()
	_assert(int(after_restart.current_level) == 1 and int(after_restart.next_level) == 2 and int(after_restart.score) == 0, "Restart must reset HUD and queue previews")

func _test_hud_layout_and_pointer_safety() -> void:
	for portrait_size in [Vector2(720, 1280), Vector2(1080, 1920), Vector2(1080, 2400), Vector2(1440, 3200), Vector2(900, 1280)]:
		var scale: float = portrait_size.x / GameConfig.VIEWPORT_SIZE.x
		_assert(GameConfig.HUD_RECT.end.x * scale <= portrait_size.x and GameConfig.HUD_RECT.end.y * scale <= GameConfig.BOARD_TOP * scale, "HUD must stay in safe bounds for representative portrait sizes")
		_assert(GameConfig.PROGRESSION_START_X + GameConfig.PROGRESSION_STEP_X * 4.0 + 18.0 <= GameConfig.RESTART_RECT.position.x, "Progression preview must remain compact beside restart")
	_assert(not GameConfig.HUD_RECT.intersects(Rect2(GameConfig.BOARD_LEFT, GameConfig.BOARD_TOP, GameConfig.BOARD_RIGHT - GameConfig.BOARD_LEFT, GameConfig.BOARD_BOTTOM - GameConfig.BOARD_TOP)), "HUD/progression drawing must not intercept board drag space")

func _active_launcher_count(items: Array[GemPiece]) -> int:
	var count := 0
	for item in items:
		if item.is_active_launcher and not item.consumed:
			count += 1
	return count
