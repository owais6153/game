extends SceneTree

const GameScene = preload("res://scenes/Game.tscn")
const GemPieceType = preload("res://scripts/gem_piece.gd")

func _init() -> void:
	var controller = GameScene.instantiate()
	get_root().add_child(controller)
	await process_frame
	_capture("launcher_bottom")
	controller.pieces.clear()
	controller.pieces.append(GemPieceType.new(41, 1, Vector2(180, 150), GameConfig.gem_collision_radius(1)))
	controller.pieces.append(GemPieceType.new(42, 3, Vector2(360, 414), GameConfig.gem_collision_radius(3)))
	controller.pieces.append(GemPieceType.new(43, 5, Vector2(540, 710), GameConfig.gem_collision_radius(5)))
	controller.gameplay_world.sync_gems(controller.pieces)
	await process_frame
	_capture("projected_depth_contact")
	controller.pieces.clear()
	var target = GemPieceType.new(99, 4, Vector2(360, 380), GameConfig.gem_collision_radius(4))
	controller.pieces.append(target)
	controller.gameplay_world.sync_gems(controller.pieces)
	await process_frame
	_capture("final_result_before_overlay")
	controller.queue_free()
	quit(0)

func _capture(name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("res://reports/shared-perspective-win-sequence-fix-v1/screenshots/%s.png" % name)
