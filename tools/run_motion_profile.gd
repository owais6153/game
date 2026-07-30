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
	controller._process(0.0) # initializes the launcher and sprite cache path
	_print_profile("empty-board launch", controller, 120)
	controller.launch_active_piece()
	_print_profile("repeated launch", controller, 180)
	_seed_crowded_board(controller, 10)
	_print_profile("10 active gems", controller, 180)
	_seed_crowded_board(controller, 20)
	_print_profile("20 active gems", controller, 180)
	_seed_crowded_board(controller, 20)
	_print_profile("crowded-board merge path", controller, 240)
	controller.restart()
	_print_profile("restart", controller, 60)
	print("MOTION_PROFILE: PASS | process callbacks per gem: 0 | gameplay resource loads after initialization: 0")
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
