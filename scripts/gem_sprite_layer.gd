class_name GemSpriteLayer
extends Node2D

const AssetCatalogType = preload("res://scripts/asset_catalog.gd")

var _sprites: Dictionary = {}

## Synchronizes presentation-only Sprite2D nodes to simulation entities. The
## sprites never write positions, radii, IDs, velocities, or merge candidates.
func sync_gems(pieces: Array[GemPiece]) -> void:
	var live_ids: Dictionary = {}
	for piece in pieces:
		if piece.consumed:
			continue
		live_ids[piece.id] = true
		var sprite: Sprite2D = _sprites.get(piece.id)
		if sprite == null:
			sprite = Sprite2D.new()
			sprite.centered = true
			sprite.z_index = 1
			add_child(sprite)
			_sprites[piece.id] = sprite
		var texture := AssetCatalogType.gem_texture(piece.level)
		sprite.texture = texture
		sprite.position = piece.position
		var longest_side := maxf(texture.get_size().x, texture.get_size().y)
		var size_scale := (piece.radius * 2.0 * AssetCatalogType.visual_scale(piece.level)) / longest_side
		sprite.scale = Vector2.ONE * size_scale
		# Emerald deliberately stays rectangular and centered; no collision shape
		# is derived from any sprite silhouette.
		sprite.visible = true
	for id in _sprites.keys():
		if not live_ids.has(id):
			var stale: Sprite2D = _sprites[id]
			stale.queue_free()
			_sprites.erase(id)

func clear() -> void:
	for sprite in _sprites.values():
		sprite.queue_free()
	_sprites.clear()
