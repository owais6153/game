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
		# The runtime images are alpha-trimmed to their main bodies. Independent
		# axis scales map that visible box to this piece's calibrated simple body,
		# preventing a fixed full-texture rectangle from creating invisible gaps.
		var visual_diameter := piece.radius * 2.0 * float(GameConfig.GEM_VISUAL_BODY_SCALE.get(piece.level, 1.0))
		sprite.scale = Vector2(visual_diameter / texture.get_size().x, visual_diameter / texture.get_size().y)
		# Overlay state must never replace or dim a live gem texture. This layer
		# owns the exact texture/modulate values for every sync.
		sprite.modulate = Color.WHITE
		# Emerald and Diamond retain simple stable circular bodies; their artwork
		# remains presentation-only and never defines merge eligibility.
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
