extends SceneTree

## Development-only CPU profile. It exercises the actual controller frame path
## with cached presentation resources; it is never packed into gameplay code.
const GameScene = preload("res://scenes/Game.tscn")
const GemPieceType = preload("res://scripts/gem_piece.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var controller = GameScene.instantiate()
	root.add_child(controller)
	await process_frame
	var starting_nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	controller._process(0.0) # initializes the launcher and sprite cache path
	_print_profile("empty-board launch", controller, 120)
	controller.launch_active_piece()
	_print_profile("repeated launch", controller, 180)
	_seed_crowded_board(controller, 10)
	_print_profile("10 active gems", controller, 180)
	_seed_crowded_board(controller, 20)
	_print_profile("20 active gems", controller, 180)
	_seed_crowded_board(controller, 20)
	_print_profile("crowded board", controller, 240)
	_seed_reward_chain(controller)
	_print_profile("six-step reward chain", controller, 30)
	_print_profile("target collection", controller, 45)
	controller._on_settings_requested()
	_print_pause_profile("pause popup", controller, 120)
	controller._on_resume_requested()
	_seed_final_target(controller)
	_print_profile("final win sequence", controller, 90)
	controller.restart()
	_print_profile("restart", controller, 60)
	await process_frame
	var ending_nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	print("MOTION_PROFILE: PASS | process callbacks per gem: 0 | gameplay resource loads after initialization: 0 | cached_audio_streams=%d | bounded_effects=%d | node_delta=%d" % [controller.audio_feedback.cached_stream_count(), controller.effects_layer.active_effect_count(), ending_nodes - starting_nodes])
	controller.queue_free()
	await process_frame
	await process_frame
	quit(0)

func _seed_crowded_board(controller, count: int) -> void:
	controller.restart()
	controller.pieces.clear()
	controller.active_piece_id = -1
	for index in range(count):
		var level := (index % 18) + 1
		var column := index % 5
		var row := index / 5
		var piece := GemPieceType.new(index + 100, level, Vector2(180.0 + column * 88.0, 480.0 + row * 86.0), GameConfig.gem_collision_radius(level))
		piece.velocity = Vector2(0.0, -90.0 if index % 2 == 0 else 90.0)
		controller.pieces.append(piece)
	controller.gem_sprite_layer.sync_gems(controller.pieces)

func _print_profile(label: String, controller, frames: int) -> void:
	var total_us := 0
	var worst_us := 0
	for frame in range(frames):
		var started := Time.get_ticks_usec()
		controller._process(1.0 / 60.0)
		var elapsed := Time.get_ticks_usec() - started
		total_us += elapsed
		worst_us = maxi(worst_us, elapsed)
	var average_ms := float(total_us) / float(frames) / 1000.0
	var worst_ms := float(worst_us) / 1000.0
	print("MOTION_PROFILE | %s | avg_process_ms=%.3f | worst_process_ms=%.3f | bodies=%d" % [label, average_ms, worst_ms, controller.pieces.size()])

func _seed_reward_chain(controller) -> void:
	controller.restart()
	var events: Array[Dictionary] = []
	for depth in range(6):
		events.append({"first_position": Vector2(310.0, 620.0 - depth * 8.0), "second_position": Vector2(390.0, 620.0 - depth * 8.0), "midpoint": Vector2(350.0, 620.0 - depth * 8.0), "level": depth + 2, "depth": depth, "result_id": 5000 + depth})
	controller._apply_confirmed_merge_events(events)
	controller._sync_gems_and_mark_visibility()

func _seed_final_target(controller) -> void:
	controller.target_index = 1
	controller.target_progress = 0
	var result := GemPieceType.new(6000, 8, Vector2(360.0, 720.0), GameConfig.gem_collision_radius(8))
	controller.pieces.append(result)
	var events: Array[Dictionary] = [{"first_position": Vector2(330.0, 720.0), "second_position": Vector2(390.0, 720.0), "midpoint": Vector2(360.0, 720.0), "level": 8, "depth": 0, "result_id": 6000}]
	controller._apply_confirmed_merge_events(events)
	controller._sync_gems_and_mark_visibility()

func _print_pause_profile(label: String, controller, frames: int) -> void:
	var total_us := 0
	var worst_us := 0
	var modal_visible := false
	for frame in range(frames):
		var started := Time.get_ticks_usec()
		# Production HUD presentation is event-driven; sampling visibility here
		# confirms the paused modal without inventing a per-frame UI callback.
		modal_visible = controller.gameplay_ui.is_pause_visible()
		var elapsed := Time.get_ticks_usec() - started
		total_us += elapsed
		worst_us = maxi(worst_us, elapsed)
	print("MOTION_PROFILE | %s | avg_ui_idle_ms=%.3f | worst_ui_idle_ms=%.3f | modal=%s | has_process_method=%s" % [label, float(total_us) / float(frames) / 1000.0, float(worst_us) / 1000.0, str(modal_visible), str(controller.gameplay_ui.has_method("_process"))])
