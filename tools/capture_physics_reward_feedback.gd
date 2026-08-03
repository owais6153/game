extends SceneTree

## Development-only deterministic evidence for the physics/reward feedback
## milestone. It has no production scene, autoload, or input reference.
const GameScene = preload("res://scenes/Game.tscn")
const GemPieceType = preload("res://scripts/gem_piece.gd")
const OUTPUT_DIR := "res://reports/physics-reward-feedback-v1/"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var controller = GameScene.instantiate()
	root.add_child(controller)
	await process_frame
	controller.set_process(false)
	_seed_major_merge(controller, 6, 6100)
	await _capture("major-l6-reward.png")

	controller.restart()
	controller.set_process(false)
	_seed_major_merge(controller, 7, 7100)
	await _capture("major-l7-target-reward.png")

	controller.restart()
	controller.set_process(false)
	controller.target_index = 1
	_seed_major_merge(controller, 8, 8100)
	await _capture("major-l8-target-reward.png")
	print("PHYSICS_REWARD_FEEDBACK_CAPTURE: PASS")
	quit(0)

func _seed_major_merge(controller, level: int, result_id: int) -> void:
	var position := Vector2(GameConfig.table_center_x(), GameConfig.board_top() + 310.0)
	var result: GemPiece = GemPieceType.new(result_id, level, position, GameConfig.gem_collision_radius(level))
	controller.pieces.append(result)
	var events: Array[Dictionary] = [{
		"first_position": position + Vector2(-44.0, 0.0),
		"second_position": position + Vector2(44.0, 0.0),
		"midpoint": position,
		"level": level,
		"depth": 0,
		"result_id": result_id,
	}]
	controller._apply_confirmed_merge_events(events)
	controller._sync_gems_and_mark_visibility()
	controller._update_merge_presentations(0.16)
	controller.effects_layer.update_effects(0.16)
	controller._sync_gems_and_mark_visibility()
	controller._refresh_hud()
	controller.queue_redraw()

func _capture(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(OUTPUT_DIR + filename)
	if error != OK:
		push_error("Unable to save %s (error %d)" % [filename, error])
		quit(1)

