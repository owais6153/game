class_name ProjectedGameplayWorld
extends Node2D

const AssetCatalogType = preload("res://scripts/asset_catalog.gd")

var controller: Node
var table: Sprite2D
var gems: GemSpriteLayer

func setup(owner_controller: Node) -> void:
	controller = owner_controller
	table = Sprite2D.new()
	table.texture = AssetCatalogType.NEW_TABLE
	table.position = GameConfig.LOGICAL_TABLE_SIZE * 0.5
	table.scale = Vector2(GameConfig.LOGICAL_TABLE_SIZE.x / table.texture.get_size().x, GameConfig.LOGICAL_TABLE_SIZE.y / table.texture.get_size().y)
	table.z_index = -10
	add_child(table)
	gems = GemSpriteLayer.new()
	gems.z_index = 10
	add_child(gems)

func sync_gems(pieces: Array[GemPiece]) -> void:
	gems.sync_gems(pieces)
	queue_redraw()

func _draw() -> void:
	if controller == null:
		return
	var y := GameConfig.DANGER_LINE_Y
	draw_dashed_line(Vector2(GameConfig.table_left_at(y) + 8.0, y), Vector2(GameConfig.table_right_at(y) - 8.0, y), Color("f6bb42"), 3.0, 12.0)
	for presentation in controller.merge_presentations:
		controller.draw_merge_presentation_in_world(self, presentation)
