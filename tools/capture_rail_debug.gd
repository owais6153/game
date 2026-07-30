extends SceneTree

## Development-only capture harness. It reads the same GameConfig table
## interpolation used by BoardSimulation and GameController's F8 overlay.
const GameScene := preload("res://scenes/Game.tscn")
const GemPieceType := preload("res://scripts/gem_piece.gd")
const OUTPUT_DIR := "res://reports/restored-working-table-rails-v1/screenshots"

var controller

func _init() -> void:
	call_deferred("_capture_all")

func _capture_all() -> void:
	controller = GameScene.instantiate()
	root.add_child(controller)
	controller.debug_calibration_enabled = true
	await process_frame
	await process_frame
	_capture("rail-overlay-full.png")

	controller.pieces.clear()
	var left := GemPieceType.new(201, 1, Vector2(GameConfig.table_left_at(GameConfig.LAUNCH_Y) + GameConfig.gem_collision_radius(1), GameConfig.LAUNCH_Y), GameConfig.gem_collision_radius(1))
	left.is_active_launcher = true
	controller.pieces.append(left)
	controller.active_piece_id = left.id
	controller.gem_sprite_layer.sync_gems(controller.pieces)
	controller.queue_redraw()
	await process_frame
	_capture("rail-overlay-left.png")

	controller.pieces.clear()
	var right := GemPieceType.new(202, 1, Vector2(GameConfig.table_right_at(GameConfig.LAUNCH_Y) - GameConfig.gem_collision_radius(1), GameConfig.LAUNCH_Y), GameConfig.gem_collision_radius(1))
	right.is_active_launcher = true
	controller.pieces.append(right)
	controller.active_piece_id = right.id
	controller.gem_sprite_layer.sync_gems(controller.pieces)
	controller.queue_redraw()
	await process_frame
	_capture("rail-overlay-right.png")
	quit(0)

func _capture(filename: String) -> void:
	var image := root.get_texture().get_image()
	image.save_png("%s/%s" % [OUTPUT_DIR, filename])
