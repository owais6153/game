extends SceneTree

## Development-only render proof for the reward feedback v3 pass. It drives real
## confirmed merges through the production controller and photographs the normal
## merge, the combo merges, and every stage of the final-target celebration.

const GameScene = preload("res://scenes/Game.tscn")
const PieceType = preload("res://scripts/core/gem_piece.gd")
const OUTPUT_DIR := "res://reports/reward-gem-simultaneous-physics-v6/screenshots/"
const RESOLUTION := Vector2i(720, 1280)
const STEP := 1.0 / 60.0

var _viewport: SubViewport
var _controller: Node2D
var _display: TextureRect
var _next_id := 9000


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await _build()
	await _capture_merge_stages("normal", 0)
	await _capture_merge_stages("combo1", 1)
	await _capture_merge_stages("combo2", 2)
	await _capture_merge_stages("combo3", 3)
	await _capture_real_bonus_merge()
	await _capture_non_final_target_coin_hold()
	await _capture_final_target()
	_display.queue_free()
	_viewport.queue_free()
	await process_frame
	print("REWARD_FEEDBACK_V3_CAPTURE: PASS")
	quit(0)


func _build() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "RewardFeedbackCapture"
	_viewport.size = RESOLUTION
	_viewport.disable_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	_display = TextureRect.new()
	_display.name = "RewardFeedbackMovieDisplay"
	_display.texture = _viewport.get_texture()
	_display.position = Vector2.ZERO
	_display.size = Vector2(RESOLUTION)
	_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root.add_child(_display)
	_controller = GameScene.instantiate()
	_viewport.add_child(_controller)
	await process_frame
	await process_frame
	_controller._on_home_level_intro_requested()
	_controller._on_home_play_requested()
	# The capture drives the controller by hand so timing is exact and repeatable.
	_controller.set_process(false)
	paused = false
	await process_frame


func _merge(level: int, depth: int, position: Vector2) -> void:
	_next_id += 1
	_controller.pieces.append(PieceType.new(_next_id, level, position, GameConfig.gem_collision_radius(level)))
	var events: Array[Dictionary] = [{
		"result_id": _next_id,
		"source_ids": [_next_id + 10000, _next_id + 20000],
		"level": level,
		"first_position": position - Vector2(44.0, 0.0),
		"second_position": position + Vector2(44.0, 0.0),
		"midpoint": position,
		"depth": depth,
	}]
	_controller._apply_confirmed_merge_events(events)


func _advance(seconds: float) -> void:
	var remaining := seconds
	while remaining > 0.0:
		_controller._process(STEP)
		remaining -= STEP
	await process_frame


func _shoot(name: String) -> void:
	_controller.queue_redraw()
	await create_timer(0.05, true, false, true).timeout
	await RenderingServer.frame_post_draw
	var image := _viewport.get_texture().get_image()
	var error := image.save_png(OUTPUT_DIR + name + ".png")
	if error != OK:
		push_error("Unable to save reward proof %s (error %d)" % [name, error])


func _capture_merge_stages(label: String, depth: int) -> void:
	var position := Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 220.0)
	# Each hierarchy sample represents a fresh player shot. Production resets this
	# budget in launch_active_piece(); the capture has no launcher gesture.
	_controller.bonus_spawn_budget_remaining = GameConfig.BONUS_GEM_BUDGET_PER_SHOT
	_merge(4, depth, position)
	await _advance(0.05)
	await _shoot("%s-050ms-hitstop-pull" % label)
	var timeline: Dictionary = GameConfig.merge_timeline(depth, false)
	var reveal_at := float(timeline.reveal) + float(depth) * GameConfig.CHAIN_PRESENTATION_STAGGER
	var simultaneous_checkpoint := reveal_at + 0.03
	await _advance(simultaneous_checkpoint - 0.05)
	var reward_stage := "ring-bonus-limit" if depth > GameConfig.BONUS_REWARD_MAX_CHAIN_DEPTH else "result-and-rewards-pop-together"
	await _shoot("%s-%03dms-%s" % [label, int(round(simultaneous_checkpoint * 1000.0)), reward_stage])
	var motion_checkpoint := reveal_at + 0.16
	await _advance(motion_checkpoint - simultaneous_checkpoint)
	await _shoot("%s-%03dms-immediate-physics" % [label, int(round(motion_checkpoint * 1000.0))])
	var settle_checkpoint := maxf(
		GameConfig.MERGE_PRESENTATION_DURATION + float(depth) * GameConfig.CHAIN_PRESENTATION_STAGGER,
		reveal_at + GameConfig.BONUS_VISUAL_BURST_DURATION
	)
	await _advance(maxf(0.0, settle_checkpoint - motion_checkpoint))
	await _shoot("%s-%03dms-settle" % [label, int(round(settle_checkpoint * 1000.0))])
	await _advance(0.30)
	# Clear the board between samples so each stage reads on its own.
	_controller.pieces.clear()
	_controller.effects_layer.clear()
	await _advance(0.05)


func _capture_real_bonus_merge() -> void:
	_controller.pieces.clear()
	_controller.pending_bonus_spawns.clear()
	_controller.bonus_spawn_history.clear()
	_controller.bonus_spawn_budget_remaining = GameConfig.BONUS_GEM_BUDGET_PER_SHOT
	var position := Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 310.0)
	_merge(4, 0, position)
	await _advance(float(GameConfig.MERGE_TIMELINE_NORMAL.reveal) + 0.03)
	var history: Dictionary = _controller.bonus_spawn_history.back()
	var bonus_id := int((history.piece_ids as Array)[0])
	var bonus: GemPiece = _controller._live_piece(bonus_id)
	await _advance(0.65)
	await _shoot("bonus-real-gem-still-on-board")
	# Isolate the persistent reward, place a normal equal-tier board gem at
	# confirmed physical contact, and resolve through the production services.
	_controller.pieces.clear()
	_controller.pieces.append(bonus)
	bonus.velocity = Vector2.ZERO
	bonus.bonus_event_id = -1
	bonus.bonus_merge_grace_remaining = 0.0
	bonus.position = Vector2(GameConfig.table_center_x() - bonus.radius, GameConfig.board_top() + 360.0)
	var other := PieceType.new(_controller.next_piece_id, bonus.level, bonus.position + Vector2(bonus.radius * 2.0 - 0.5, 0.0), GameConfig.gem_collision_radius(bonus.level))
	_controller.next_piece_id += 1
	other.velocity = Vector2(-40.0, 0.0)
	_controller.pieces.append(other)
	_controller.simulation.step(_controller.pieces, STEP, _controller.merge_service)
	var resolved: Dictionary = _controller.merge_service.resolve(_controller.pieces, _controller.next_piece_id)
	_controller.pieces = resolved.pieces
	_controller.next_piece_id = resolved.next_id
	_controller._apply_confirmed_merge_events(resolved.presentation_events)
	await _advance(0.14)
	await _shoot("bonus-real-gem-participates-in-merge")
	await _advance(0.35)
	_controller.pieces.clear()
	_controller.pending_bonus_spawns.clear()
	await _advance(0.05)


func _capture_non_final_target_coin_hold() -> void:
	_controller.pieces.clear()
	_controller.pending_bonus_spawns.clear()
	_controller.effects_layer.clear()
	_controller.bonus_spawn_budget_remaining = GameConfig.BONUS_GEM_BUDGET_PER_SHOT
	_controller.target_index = 0
	_controller.presented_target_index = 0
	_controller.target_progress = _controller.active_target_quantity() - 1
	_controller.presented_target_progress = _controller.target_progress
	var position := Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 280.0)
	_merge(_controller.active_target_tier(), 0, position)
	var hold_capture_at := GameConfig.COIN_REWARD_START_DELAY \
		+ GameConfig.target_coin_flight_start(0, GameConfig.COIN_BURST_COUNT) \
		- GameConfig.TARGET_COIN_TABLE_HOLD * 0.5
	await _advance(hold_capture_at)
	await _shoot("target-all-coins-table-hold")
	await _advance(GameConfig.TARGET_COIN_TABLE_HOLD + GameConfig.MAJOR_COIN_FLIGHT_DURATION)
	_controller.pieces.clear()
	_controller.pending_bonus_spawns.clear()
	_controller.effects_layer.clear()
	await _advance(0.05)


func _capture_final_target() -> void:
	_controller.bonus_spawn_budget_remaining = GameConfig.BONUS_GEM_BUDGET_PER_SHOT
	var sequence: Array = _controller.target_sequence()
	_controller.target_index = sequence.size() - 1
	_controller.presented_target_index = _controller.target_index
	_controller.target_progress = _controller.active_target_quantity() - 1
	_controller.presented_target_progress = _controller.target_progress
	var tier: int = _controller.active_target_tier()
	var position := Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 210.0)
	_merge(tier, 0, position)
	var checkpoints := {
		"final-0150ms-phaseA-reveal": 0.15,
		"final-0300ms-phaseB-travel": 0.30,
		"final-0500ms-phaseC-hero-peak": 0.50,
		"final-0900ms-phaseC-readable-label": 0.90,
		"final-1350ms-phaseC-center-hold": 1.35,
		"final-1520ms-phaseD-anticipation": 1.52,
		"final-1700ms-phaseD-flight": 1.70,
		"final-1900ms-phaseE-panel-impact": 1.90,
		"final-2200ms-coins-landed": 2.20,
		"final-2750ms-all-coins-table-hold": 2.75,
		"final-3350ms-all-coins-table-hold": 3.35,
		"final-3700ms-coin-collection": 3.70,
		"final-4300ms-level-complete": 4.30,
		"final-4650ms-settled": 4.65,
	}
	var elapsed := 0.0
	for name in checkpoints.keys():
		await _advance(float(checkpoints[name]) - elapsed)
		elapsed = float(checkpoints[name])
		await _shoot(name)
