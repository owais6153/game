extends SceneTree

## Development-only render proof for the reward feedback v3 pass. It drives real
## confirmed merges through the production controller and photographs the normal
## merge, the combo merges, and every stage of the final-target celebration.

const GameScene = preload("res://scenes/Game.tscn")
const PieceType = preload("res://scripts/gem_piece.gd")
const OUTPUT_DIR := "res://reports/reward-feedback-v3/screenshots/"
const RESOLUTION := Vector2i(720, 1280)
const STEP := 1.0 / 60.0

var _viewport: SubViewport
var _controller: Node2D
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
	await _capture_final_target()
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
	_merge(4, depth, position)
	await _advance(0.05)
	await _shoot("%s-050ms-hitstop-pull" % label)
	await _advance(0.09)
	await _shoot("%s-140ms-reveal-pop" % label)
	await _advance(0.06)
	await _shoot("%s-200ms-ring-and-mini-gems" % label)
	await _advance(0.13)
	await _shoot("%s-330ms-settle" % label)
	await _advance(0.30)
	# Clear the board between samples so each stage reads on its own.
	_controller.pieces.clear()
	_controller.effects_layer.clear()
	await _advance(0.05)


func _capture_final_target() -> void:
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
		"final-0700ms-phaseC-label": 0.70,
		"final-1050ms-phaseD-flight": 1.05,
		"final-1300ms-phaseE-panel-impact": 1.30,
		"final-1700ms-coins-landing": 1.70,
		"final-1950ms-coin-table-hold": 1.95,
		"final-2300ms-coin-collection": 2.30,
		"final-2900ms-level-complete": 2.90,
		"final-3200ms-settled": 3.20,
		"final-3450ms-fully-settled": 3.45,
	}
	var elapsed := 0.0
	for name in checkpoints.keys():
		await _advance(float(checkpoints[name]) - elapsed)
		elapsed = float(checkpoints[name])
		await _shoot(name)
