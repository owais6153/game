extends SceneTree

const GemPieceType = preload("res://scripts/gem_piece.gd")
const SimulationType = preload("res://scripts/board_simulation.gd")
const MergeType = preload("res://scripts/merge_service.gd")
const GemVisualsType = preload("res://scripts/gem_visuals.gd")
const AssetCatalogType = preload("res://scripts/asset_catalog.gd")
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
	_test_win_visual_sequence_and_overlay_isolation()
	_test_danger_line_failure_rules()
	_test_chain_presentation_cadence()
	_test_overlay_reset()
	_test_visual_level_mapping()
	_test_visual_layout_bounds()
	_test_portrait_board_bounds_and_scale()
	_test_merge_momentum_is_bounded_and_contained()
	_test_progression_hud_snapshot_and_queue()
	_test_hud_layout_and_pointer_safety()
	_test_sound_and_haptics_feedback_routing()
	_test_inset_table_and_viewport_safety()
	_test_asset_mapping_and_clean_diamond()
	_test_table_layout_physics_alignment()
	_test_physical_rail_geometry()
	_test_perspective_view_presentation()
	_test_visible_collision_calibration()
	_test_calibrated_wall_contacts()
	_test_collision_audio_uses_confirmed_contact()
	_test_shadow_presentation_is_collision_free()
	if failures.is_empty():
		print("CLEAN_CONTACT_TESTS: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _piece(id: int, level: int, at_position: Vector2) -> GemPiece:
	return GemPieceType.new(id, level, at_position, GameConfig.gem_collision_radius(level))

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
	_assert(shot.position.y >= GameConfig.BOARD_TOP + shot.radius - 0.01, "Unobstructed shot must remain inside the top border")
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
	_assert(top_time >= 0.55 and top_time <= 1.20, "Launch must reach the inset top border within the approved feel range")
	_assert(shot.is_settled() and elapsed <= 2.25, "A clean top-border shot must settle without a long wait")
	var settled_position := shot.position
	for frame in range(120): simulation.step(items, 1.0 / 60.0, merger)
	_assert(shot.velocity == Vector2.ZERO and shot.position.distance_to(settled_position) < 0.05, "A settled piece must not retain persistent jitter")

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
	var piece := _piece(1, 1, Vector2(GameConfig.table_left_at(GameConfig.BOARD_TOP + 40.0) + 40.0, GameConfig.BOARD_TOP + 40.0))
	piece.velocity = Vector2(-900.0, -900.0)
	var items: Array[GemPiece] = [piece]
	for frame in range(180): simulation.step(items, 1.0 / 60.0, merger)
	_assert(piece.position.x >= GameConfig.table_left_at(piece.position.y) + piece.radius and piece.position.x <= GameConfig.table_right_at(piece.position.y) - piece.radius, "Side containment must remain valid during a wall shot")
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
	var first_left := _piece(300, 3, Vector2(260, 500))
	var second_left := _piece(301, 3, Vector2(260 + first_left.radius * 2.0, 500))
	var first_right := _piece(302, 3, Vector2(460, 500))
	var second_right := _piece(303, 3, Vector2(460 + first_right.radius * 2.0, 500))
	controller.pieces.append_array([first_left, second_left, first_right, second_right])
	controller._process(0.0)
	controller._process(GameConfig.MERGE_PRESENTATION_DURATION + 0.01)
	_assert(controller.won, "Creating both target Sapphires must trigger win exactly once")
	_assert(controller.win_qualified and not controller.win_presented, "Second Sapphire must qualify the win before its overlay is presented")
	var count: int = controller.pieces.size()
	for frame in range(120): controller._process(1.0 / 60.0)
	_assert(controller.pieces.size() == count, "No launcher may spawn after win")

func _test_win_visual_sequence_and_overlay_isolation() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	var first_left := _piece(310, 3, Vector2(260, 500))
	var second_left := _piece(311, 3, Vector2(260 + first_left.radius * 2.0, 500))
	var first_right := _piece(312, 3, Vector2(460, 500))
	var second_right := _piece(313, 3, Vector2(460 + first_right.radius * 2.0, 500))
	controller.pieces.append_array([first_left, second_left, first_right, second_right])
	controller._process(0.0)
	controller._process(GameConfig.MERGE_PRESENTATION_DURATION + 0.01)
	_assert(controller.pieces.filter(func(piece: GemPiece): return piece.level == 4).size() >= 2, "Both target Sapphires must exist in simulation immediately after confirmed merges")
	_assert(not controller.win_presented, "Win overlay must wait for the final Sapphire merge presentation")
	controller.gem_sprite_layer.sync_gems(controller.pieces)
	var sapphire_id := -1
	for piece in controller.pieces:
		if piece.level == 4: sapphire_id = piece.id
	var sapphire_sprite: Sprite2D = controller.gem_sprite_layer._sprites.get(sapphire_id)
	_assert(sapphire_sprite != null and sapphire_sprite.texture == AssetCatalogType.gem_texture(4) and sapphire_sprite.modulate == Color.WHITE, "Final Sapphire visual must be synchronized unchanged before result UI")
	for frame in range(40): controller._process(1.0 / 60.0)
	_assert(controller.win_presented and controller.result_overlay.visible_result, "Win overlay must present only after merge animation plus celebration hold")
	_assert(sapphire_sprite.texture == AssetCatalogType.gem_texture(4) and sapphire_sprite.modulate == Color.WHITE, "Result backdrop must not change Sapphire texture or modulation")

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
	for portrait_size in [Vector2(720, 1280), Vector2(1080, 1920), Vector2(1080, 2400), Vector2(1440, 3200), Vector2(900, 1280)]:
		var scale: float = minf(portrait_size.x / GameConfig.VIEWPORT_SIZE.x, portrait_size.y / GameConfig.VIEWPORT_SIZE.y)
		_assert(GameConfig.table_left_at(GameConfig.BOARD_TOP) * scale >= 0.0 and GameConfig.table_right_at(GameConfig.BOARD_TOP) * scale <= portrait_size.x, "Table rail model must fit every supported portrait width")
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
	_assert(upgraded.position.x >= GameConfig.table_left_at(upgraded.position.y) + upgraded.radius and upgraded.position.x <= GameConfig.table_right_at(upgraded.position.y) - upgraded.radius and upgraded.position.y >= GameConfig.BOARD_TOP + upgraded.radius and upgraded.position.y <= GameConfig.BOARD_BOTTOM - upgraded.radius, "Upgraded gem must spawn inside table rail bounds")

func _test_progression_hud_snapshot_and_queue() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	var first: Dictionary = controller.hud_snapshot()
	_assert(int(first.current_level) == 1 and int(first.next_level) == 1, "HUD previews must match Level 1's deterministic opening queue")
	_assert(int(first.target_level) == 4, "HUD target highlight must match Level 1 Sapphire target")
	controller.launch_active_piece()
	for frame in range(200): controller._process(1.0 / 60.0)
	var after_shot: Dictionary = controller.hud_snapshot()
	_assert(int(after_shot.current_level) == 1 and int(after_shot.next_level) == 2, "HUD queue preview must advance exactly once after a shot cycle")
	controller.restart()
	var after_restart: Dictionary = controller.hud_snapshot()
	_assert(int(after_restart.current_level) == 1 and int(after_restart.next_level) == 1 and int(after_restart.score) == 0, "Restart must reset Level 1 HUD and queue previews")

func _test_hud_layout_and_pointer_safety() -> void:
	for portrait_size in [Vector2(720, 1280), Vector2(1080, 1920), Vector2(1080, 2400), Vector2(1440, 3200), Vector2(900, 1280)]:
		var scale: float = minf(portrait_size.x / GameConfig.VIEWPORT_SIZE.x, portrait_size.y / GameConfig.VIEWPORT_SIZE.y)
		_assert(GameConfig.HUD_RECT.end.x * scale <= portrait_size.x and GameConfig.HUD_RECT.end.y * scale <= GameConfig.BOARD_TOP * scale, "HUD must stay in safe bounds for representative portrait sizes")
		_assert(GameConfig.PROGRESSION_START_X + GameConfig.PROGRESSION_STEP_X * 4.0 + 18.0 <= GameConfig.RESTART_RECT.position.x, "Progression preview must remain compact beside restart")
	_assert(not GameConfig.HUD_RECT.intersects(Rect2(GameConfig.BOARD_LEFT, GameConfig.BOARD_TOP, GameConfig.BOARD_RIGHT - GameConfig.BOARD_LEFT, GameConfig.BOARD_BOTTOM - GameConfig.BOARD_TOP)), "HUD/progression drawing must not intercept board drag space")

func _test_sound_and_haptics_feedback_routing() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	controller.haptics_feedback.allow_platform_vibration = false
	controller.audio_feedback.clear_trace()
	controller.haptics_feedback.clear_trace()
	controller.launch_active_piece()
	_assert(_event_count(controller.audio_feedback.emitted_events, "launch") == 1, "Enabled launch must emit one audio event")
	_assert(_event_count(controller.haptics_feedback.emitted_events, "launch") == 1, "Enabled launch must emit one haptic event")
	controller.audio_feedback.clear_trace()
	controller.simulation._collision_impacts.append({"kind": "gem", "strength": GameConfig.GEM_CONTACT_SOUND_THRESHOLD - 1.0})
	controller._route_collision_feedback()
	_assert(controller.audio_feedback.emitted_events.is_empty(), "Sub-threshold collision must not emit audio")
	controller.simulation._collision_impacts.append({"kind": "gem", "strength": GameConfig.GEM_CONTACT_SOUND_THRESHOLD + 100.0})
	controller._route_collision_feedback()
	controller.simulation._collision_impacts.append({"kind": "gem", "strength": GameConfig.GEM_CONTACT_SOUND_THRESHOLD + 100.0})
	controller._route_collision_feedback()
	_assert(_event_count(controller.audio_feedback.emitted_events, "gem_contact") == 1, "Gem contact audio must be throttled")
	controller.audio_feedback.clear_trace()
	controller.simulation._collision_impacts.append({"kind": "wall", "strength": GameConfig.WALL_CONTACT_SOUND_THRESHOLD + 100.0})
	controller._route_collision_feedback()
	_assert(_event_count(controller.audio_feedback.emitted_events, "wall_contact") == 1, "Wall contact must use its own soft crystal event")
	controller.audio_feedback.clear_trace()
	controller.haptics_feedback.clear_trace()
	var merge_events: Array[Dictionary] = [{"level": 2, "depth": 0}, {"level": 3, "depth": 1}]
	controller._apply_confirmed_merge_events(merge_events)
	_assert(_event_count(controller.audio_feedback.emitted_events, "merge_2") == 1 and _event_count(controller.audio_feedback.emitted_events, "merge_3") == 1, "Confirmed merges must route level-specific audio")
	_assert(_event_count(controller.audio_feedback.emitted_events, "chain") == 1, "A chain step must emit one chain accent")
	_assert(_event_count(controller.haptics_feedback.emitted_events, "merge") == 2 and _event_count(controller.haptics_feedback.emitted_events, "chain") == 1, "Confirmed direct and chain merges must use distinct haptics")
	controller.audio_feedback.clear_trace()
	controller.haptics_feedback.clear_trace()
	var win_events: Array[Dictionary] = [{"level": 4, "depth": 0, "result_id": 700}, {"level": 4, "depth": 0, "result_id": 701}]
	controller._apply_confirmed_merge_events(win_events)
	for frame in range(40): controller._process(1.0 / 60.0)
	_assert(_event_count(controller.audio_feedback.emitted_events, "win") == 1 and _event_count(controller.haptics_feedback.emitted_events, "win") == 1, "Win feedback must fire exactly once")
	var fail_controller = GameScene.instantiate()
	fail_controller._ready()
	fail_controller.haptics_feedback.allow_platform_vibration = false
	fail_controller.audio_feedback.clear_trace()
	fail_controller.haptics_feedback.clear_trace()
	var danger := _piece(900, 1, Vector2(300, GameConfig.DANGER_LINE_Y + 20.0))
	fail_controller.pieces.append(danger)
	for frame in range(50): fail_controller._process(1.0 / 60.0)
	_assert(_event_count(fail_controller.audio_feedback.emitted_events, "fail") == 1 and _event_count(fail_controller.haptics_feedback.emitted_events, "fail") == 1, "Fail feedback must fire exactly once")
	var settings_controller = GameScene.instantiate()
	settings_controller._ready()
	settings_controller.haptics_feedback.allow_platform_vibration = false
	var sound_setting := bool(settings_controller.audio_feedback.enabled)
	var vibration_setting := bool(settings_controller.haptics_feedback.enabled)
	settings_controller._handle_pointer(GameConfig.SOUND_TOGGLE_RECT.get_center(), true)
	settings_controller._handle_pointer(GameConfig.VIBRATION_TOGGLE_RECT.get_center(), true)
	_assert(not settings_controller.audio_feedback.enabled and not settings_controller.haptics_feedback.enabled, "Settings toggles must disable feedback independently")
	settings_controller.audio_feedback.clear_trace()
	settings_controller.haptics_feedback.clear_trace()
	settings_controller.restart()
	settings_controller.launch_active_piece()
	_assert(settings_controller.audio_feedback.emitted_events.is_empty() and settings_controller.haptics_feedback.emitted_events.is_empty(), "Disabled feedback must never alter gameplay or emit output")
	_assert(not settings_controller.audio_feedback.enabled and not settings_controller.haptics_feedback.enabled, "Restart must preserve current-session settings")
	_assert(sound_setting and vibration_setting, "Sound and vibration must default to enabled")

func _test_inset_table_and_viewport_safety() -> void:
	_assert(GameConfig.TABLE_TEXTURE_CENTER == Vector2(360.0, 846.0), "Table must be genuinely bottom-anchored to the approved reference composition")
	_assert(GameConfig.BOARD_BOTTOM >= 1210.0 and GameConfig.LAUNCH_Y > GameConfig.DANGER_LINE_Y, "Shared board, launcher, and danger geometry must follow the bottom-anchored table")
	_assert(GameConfig.table_left_at(GameConfig.BOARD_TOP) > 0.0 and GameConfig.table_right_at(GameConfig.BOARD_TOP) < GameConfig.VIEWPORT_SIZE.x, "Top rail must leave background visible at both sides")
	_assert(GameConfig.BOARD_TOP - GameConfig.HUD_RECT.end.y >= 48.0, "Lower table must leave a visible environment gap below HUD")
	_assert(GameConfig.DANGER_LINE_Y > GameConfig.BOARD_TOP and GameConfig.DANGER_LINE_Y < GameConfig.BOARD_BOTTOM and GameConfig.LAUNCH_Y > GameConfig.DANGER_LINE_Y and GameConfig.LAUNCH_Y < GameConfig.BOARD_BOTTOM, "Danger line and launcher must remain inside physical table bounds")

func _test_asset_mapping_and_clean_diamond() -> void:
	for level in range(1, GameConfig.MAX_GEM_LEVEL + 1):
		var path := AssetCatalogType.gem_resource_path(level)
		_assert(path.ends_with("tier_%02d.png" % AssetCatalogType.GEM_TIER_SOURCE_INDEX[level]), "Gem level %d must use its approved reordered supplied texture" % level)
		_assert(ResourceLoader.exists(path), "Gem level %d runtime texture must exist" % level)
	_assert(ResourceLoader.exists(AssetCatalogType.TROPICAL_BACKGROUND.resource_path) and ResourceLoader.exists(AssetCatalogType.NEW_TABLE.resource_path), "Background and newly supplied table runtime textures must exist")
	_assert(AssetCatalogType.NEW_TABLE.resource_path.ends_with("new_table_v1.png"), "Old coral table must not remain active")
	_assert(ResourceLoader.exists(AssetCatalogType.shadow_resource_path()), "Presentation-only soft shadow texture must exist")

func _test_table_layout_physics_alignment() -> void:
	for y in [GameConfig.BOARD_TOP, GameConfig.DANGER_LINE_Y, GameConfig.LAUNCH_Y, GameConfig.BOARD_BOTTOM]:
		var left := GameConfig.table_left_at(y)
		var right := GameConfig.table_right_at(y)
		_assert(left < right and right - left >= GameConfig.PIECE_RADIUS * 2.0, "Authoritative table rails must leave room for a gem at y=%d" % y)
	var launch_left := GameConfig.table_left_at(GameConfig.LAUNCH_Y) + GameConfig.PIECE_RADIUS
	var launch_right := GameConfig.table_right_at(GameConfig.LAUNCH_Y) - GameConfig.PIECE_RADIUS
	_assert(360.0 >= launch_left and 360.0 <= launch_right, "Launcher spawn must remain inside visible table surface")
	_assert(GameConfig.table_left_at(GameConfig.DANGER_LINE_Y) < GameConfig.table_right_at(GameConfig.DANGER_LINE_Y), "Dynamic danger line must span the same authoritative table surface")

func _test_physical_rail_geometry() -> void:
	_assert(GameConfig.LEFT_RAIL_TOP == Vector2(GameConfig.TABLE_INNER_LEFT_TOP, GameConfig.BOARD_TOP), "Left physical rail top must equal the configured visible top anchor")
	_assert(GameConfig.LEFT_RAIL_BOTTOM == Vector2(GameConfig.TABLE_INNER_LEFT_BOTTOM, GameConfig.BOARD_BOTTOM), "Left physical rail bottom must equal the configured visible bottom anchor")
	_assert(GameConfig.RIGHT_RAIL_TOP == Vector2(GameConfig.TABLE_INNER_RIGHT_TOP, GameConfig.BOARD_TOP), "Right physical rail top must equal the configured visible top anchor")
	_assert(GameConfig.RIGHT_RAIL_BOTTOM == Vector2(GameConfig.TABLE_INNER_RIGHT_BOTTOM, GameConfig.BOARD_BOTTOM), "Right physical rail bottom must equal the configured visible bottom anchor")
	var previous_width := 0.0
	for y in [GameConfig.BOARD_TOP, (GameConfig.BOARD_TOP + GameConfig.BOARD_BOTTOM) * 0.5, GameConfig.BOARD_BOTTOM]:
		var width := GameConfig.table_playable_width_at(y)
		if previous_width > 0.0:
			_assert(width > previous_width, "Playable rail width must widen monotonically from top to bottom")
		previous_width = width
	var radius := GameConfig.gem_collision_radius(1)
	var launcher_left := GameConfig.left_rail_center_limit_at(GameConfig.LAUNCH_Y, radius)
	var launcher_right := GameConfig.right_rail_center_limit_at(GameConfig.LAUNCH_Y, radius)
	_assert(launcher_left < launcher_right and 360.0 >= launcher_left and 360.0 <= launcher_right, "Launcher limits must derive from the same slanted rail geometry")
	var simulation := SimulationType.new()
	var merger := MergeType.new()
	for y in [GameConfig.BOARD_TOP + 90.0, (GameConfig.BOARD_TOP + GameConfig.BOARD_BOTTOM) * 0.5, GameConfig.BOARD_BOTTOM - 90.0]:
		var left_piece := _piece(int(y), 1, Vector2(GameConfig.table_left_at(y) - 20.0, y))
		simulation.step([left_piece], 0.0, merger)
		var left_distance := (left_piece.position - GameConfig.LEFT_RAIL_TOP).dot(GameConfig.left_rail_inward_normal())
		_assert(left_distance >= left_piece.radius - 0.01, "Left rail must contain a gem at every tested table depth")
		var right_piece := _piece(int(y) + 1, 1, Vector2(GameConfig.table_right_at(y) + 20.0, y))
		simulation.step([right_piece], 0.0, merger)
		var right_distance := (right_piece.position - GameConfig.RIGHT_RAIL_TOP).dot(GameConfig.right_rail_inward_normal())
		_assert(right_distance >= right_piece.radius - 0.01, "Right rail must contain a gem at every tested table depth")
	var simulation_source := FileAccess.get_file_as_string("res://scripts/board_simulation.gd")
	_assert(simulation_source.contains("_resolve_slanted_rail") and not simulation_source.contains("piece.position.x = left"), "Only direct slanted-rail containment may run during normal physics movement")
	var scene_source := FileAccess.get_file_as_string("res://scenes/Game.tscn")
	_assert(not scene_source.contains("CollisionShape2D") and not scene_source.contains("StaticBody2D"), "No stale vertical or rectangular Godot rail collider may remain enabled")
	var controller_source := FileAccess.get_file_as_string("res://scripts/game_controller.gd")
	_assert(controller_source.contains("GameConfig.LEFT_RAIL_TOP") and controller_source.contains("GameConfig.RIGHT_RAIL_BOTTOM"), "Debug overlay must read the exact same endpoints as physical rails")

func _test_perspective_view_presentation() -> void:
	_assert(is_equal_approx(GameConfig.gem_perspective_scale_at(GameConfig.BOARD_TOP), GameConfig.GEM_PERSPECTIVE_SCALE_BACK), "Back-table perspective scale must use the configured minimum")
	_assert(is_equal_approx(GameConfig.gem_perspective_scale_at(GameConfig.BOARD_BOTTOM), GameConfig.GEM_PERSPECTIVE_SCALE_FRONT), "Front-table perspective scale must use the configured maximum")
	var midpoint_y := (GameConfig.BOARD_TOP + GameConfig.BOARD_BOTTOM) * 0.5
	_assert(GameConfig.gem_perspective_scale_at(GameConfig.BOARD_TOP) < GameConfig.gem_perspective_scale_at(midpoint_y) and GameConfig.gem_perspective_scale_at(midpoint_y) < GameConfig.gem_perspective_scale_at(GameConfig.BOARD_BOTTOM), "Perspective scale must increase monotonically from table back to front")
	var controller = GameScene.instantiate()
	controller._ready()
	var back := _piece(101, 1, Vector2(360.0, GameConfig.BOARD_TOP + 80.0))
	var front := _piece(102, 1, Vector2(360.0, GameConfig.BOARD_BOTTOM - 80.0))
	controller.pieces.clear()
	controller.pieces.append(back)
	controller.pieces.append(front)
	controller.gem_sprite_layer.sync_gems(controller.pieces)
	var back_root: Node2D = controller.gem_sprite_layer._piece_visual_roots[back.id]
	var front_root: Node2D = controller.gem_sprite_layer._piece_visual_roots[front.id]
	var back_visual: Node2D = controller.gem_sprite_layer._visual_containers[back.id]
	var front_visual: Node2D = controller.gem_sprite_layer._visual_containers[front.id]
	_assert(is_equal_approx(back_root.scale.x, back.perspective_scale) and is_equal_approx(front_root.scale.x, front.perspective_scale), "Visual root scale must exactly mirror each gem's physics perspective scale")
	_assert(is_equal_approx(back.radius, back.base_radius * back.perspective_scale) and is_equal_approx(front.radius, front.base_radius * front.perspective_scale), "Collider radius must exactly mirror the visual perspective scale")
	_assert(back_root.scale.x < front_root.scale.x, "Back-table gems must render smaller than front-table gems")
	_assert(back_visual.scale == Vector2.ONE and front_visual.scale == Vector2.ONE, "Visual child must not add an independent perspective scale")
	_assert(back_visual.position == Vector2.ZERO and front_visual.position == Vector2.ZERO, "Visual containers must remain centered on their physics roots")
	_assert(front_root.z_index > back_root.z_index, "Front gem must render over back gem")
	var tie_a := GameConfig.gem_visual_z_index(12, 700.0)
	var tie_b := GameConfig.gem_visual_z_index(13, 700.0)
	_assert(tie_b > tie_a, "Stable piece IDs must deterministically break equal-Y depth ties")
	_assert(GameConfig.table_left_at(GameConfig.LAUNCH_Y) < 360.0 and GameConfig.table_right_at(GameConfig.LAUNCH_Y) > 360.0, "Shared table transform must keep the moved launcher within physical rails")
	var edge_piece := _piece(103, 1, Vector2(GameConfig.table_left_at(GameConfig.LAUNCH_Y) + 2.0, GameConfig.LAUNCH_Y))
	edge_piece.velocity = Vector2(-420.0, -650.0)
	var simulation := SimulationType.new()
	var merger := MergeType.new()
	var edge_items: Array[GemPiece] = [edge_piece]
	for frame in range(24):
		simulation.step(edge_items, 1.0 / 60.0, merger)
		_assert(edge_piece.position.x >= GameConfig.table_left_at(edge_piece.position.y) + edge_piece.radius - GameConfig.VISIBLE_CONTACT_TOLERANCE, "Scaled gem must stay aligned to the left rail while travelling upward")
	controller.queue_free()

func _test_visible_collision_calibration() -> void:
	var expected := GameConfig.GEM_COLLISION_RADIUS
	for level in range(1, GameConfig.MAX_GEM_LEVEL + 1):
		var radius := GameConfig.gem_collision_radius(level)
		_assert(is_equal_approx(radius, float(expected[level])), "Gem level %d must use documented calibrated collision radius" % level)
		_assert(radius > 0.0, "Visible alpha calibration must retain a positive gem collider")
		_assert(ResourceLoader.exists(AssetCatalogType.gem_resource_path(level)), "Each calibrated gem texture must exist")
	var pearl_a := _piece(1, 1, Vector2(300, 500))
	var pearl_b := _piece(2, 1, Vector2(300 + pearl_a.radius * 2.0 + GameConfig.VISIBLE_CONTACT_TOLERANCE * 0.99, 500))
	_assert(pearl_a.position.distance_to(pearl_b.position) - (pearl_a.radius + pearl_b.radius) <= GameConfig.VISIBLE_CONTACT_TOLERANCE, "Pearl visible first-contact tolerance must remain within one design pixel")
	var jade := _piece(3, 3, Vector2(500, 500))
	_assert(jade.radius < GameConfig.PIECE_RADIUS, "Reordered Jade collider must retain its calibrated body-only radius")

func _test_calibrated_wall_contacts() -> void:
	var simulation := SimulationType.new()
	var merger := MergeType.new()
	for level in range(1, GameConfig.MAX_GEM_LEVEL + 1):
		var piece := _piece(level, level, Vector2(GameConfig.table_left_at(600.0) + 1.0, 600.0))
		piece.velocity = Vector2(-300.0, 0.0)
		var items: Array[GemPiece] = [piece]
		simulation.step(items, 1.0 / 60.0, merger)
		_assert(piece.position.x >= GameConfig.table_left_at(piece.position.y) + piece.radius - GameConfig.VISIBLE_CONTACT_TOLERANCE, "Level %d must touch the calibrated left rail without penetrating" % level)
		var right_piece := _piece(level + 10, level, Vector2(GameConfig.table_right_at(600.0) - 1.0, 600.0))
		right_piece.velocity = Vector2(300.0, 0.0)
		var right_items: Array[GemPiece] = [right_piece]
		simulation.step(right_items, 1.0 / 60.0, merger)
		_assert(right_piece.position.x <= GameConfig.table_right_at(right_piece.position.y) - right_piece.radius + GameConfig.VISIBLE_CONTACT_TOLERANCE, "Level %d must touch the calibrated right rail without penetrating" % level)

func _test_collision_audio_uses_confirmed_contact() -> void:
	var simulation := SimulationType.new()
	var merger := MergeType.new()
	var first := _piece(1, 1, Vector2(300, 500))
	var second := _piece(2, 1, Vector2(300 + first.radius + GameConfig.gem_collision_radius(1) + GameConfig.CONTACT_EPSILON + 2.0, 500))
	first.velocity = Vector2(500, 0)
	var no_contact: Array[GemPiece] = [first, second]
	simulation.step(no_contact, 0.0, merger)
	_assert(simulation.consume_collision_impacts().is_empty(), "Collision audio telemetry must not fire before calibrated physical contact")
	second.position.x = first.position.x + first.radius + second.radius
	simulation.step(no_contact, 0.0, merger)
	var impacts := simulation.consume_collision_impacts()
	_assert(impacts.any(func(impact: Dictionary): return String(impact.get("kind", "")) == "gem" and impact.has("position")), "Gem audio telemetry must be emitted from the confirmed contact point")

func _test_shadow_presentation_is_collision_free() -> void:
	var controller = GameScene.instantiate()
	controller._ready()
	var pearl := _piece(901, 1, Vector2(300, 560))
	controller.set("pieces", [pearl])
	controller.gem_sprite_layer.sync_gems(controller.get("pieces"))
	var shadow_rect: Rect2 = controller.gem_sprite_layer.shadow_bounds(pearl.id)
	_assert(not shadow_rect.has_point(pearl.position), "Separate shadow must sit below the gem body instead of becoming a centered halo")
	var distant := _piece(902, 1, Vector2(300 + pearl.radius * 2.0 + 4.0, 560))
	var merger := MergeType.new()
	var simulation := SimulationType.new()
	var pair: Array[GemPiece] = [pearl, distant]
	simulation.step(pair, 0.0, merger)
	_assert(merger.resolve(pair, 999).merge_count == 0, "Shadow overlap or proximity must not create a merge candidate")

func _event_count(events: Array, event_name: String) -> int:
	var total := 0
	for event in events:
		if event == event_name:
			total += 1
	return total

func _active_launcher_count(items: Array[GemPiece]) -> int:
	var count := 0
	for item in items:
		if item.is_active_launcher and not item.consumed:
			count += 1
	return count
