class_name GemSpriteLayer
extends Node2D

const AssetCatalogType = preload("res://scripts/asset_catalog.gd")

var _sprites: Dictionary = {}
var _shadows: Dictionary = {}
## Last synchronized tier for each live piece. Appearance work is done once on
## creation/merge-tier change; the frame path only moves existing sprites.
var _appearance_levels: Dictionary = {}

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
			var shadow := Sprite2D.new()
			shadow.texture = AssetCatalogType.GEM_SOFT_SHADOW
			shadow.centered = true
			shadow.z_index = 0
			add_child(shadow)
			_shadows[piece.id] = shadow
			sprite = Sprite2D.new()
			sprite.centered = true
			sprite.z_index = 1
			add_child(sprite)
			_sprites[piece.id] = sprite
			_appearance_levels.erase(piece.id)
		if _appearance_levels.get(piece.id, -1) != piece.level:
			var texture := AssetCatalogType.gem_texture(piece.level)
			sprite.texture = texture
			# The runtime images are alpha-trimmed to their main bodies. Independent
			# axis scales map that visible box to this piece's calibrated simple body.
			var visual_diameter := piece.radius * 2.0 * float(GameConfig.GEM_VISUAL_BODY_SCALE.get(piece.level, 1.0))
			sprite.scale = Vector2(visual_diameter / texture.get_size().x, visual_diameter / texture.get_size().y)
			var shadow: Sprite2D = _shadows.get(piece.id)
			var body_diameter := piece.radius * 2.0
			shadow.position = piece.position + GameConfig.GEM_SHADOW_OFFSET.get(piece.level, Vector2(4.0, 7.0))
			shadow.scale = Vector2(body_diameter * GameConfig.GEM_SHADOW_WIDTH_MULTIPLIER / shadow.texture.get_size().x, body_diameter * GameConfig.GEM_SHADOW_HEIGHT_MULTIPLIER / shadow.texture.get_size().y)
			shadow.modulate = Color(1.0, 1.0, 1.0, float(GameConfig.GEM_SHADOW_OPACITY.get(piece.level, 0.4)))
			_appearance_levels[piece.id] = piece.level
		sprite.position = piece.position
		# Overlay state must never replace or dim a live gem texture. This layer
		# owns the exact texture/modulate values for every sync.
		sprite.modulate = Color.WHITE
		# Emerald and Diamond retain simple stable circular bodies; their artwork
		# remains presentation-only and never defines merge eligibility.
		sprite.visible = true
		var shadow: Sprite2D = _shadows.get(piece.id)
		shadow.position = piece.position + GameConfig.GEM_SHADOW_OFFSET.get(piece.level, Vector2(4.0, 7.0))
		shadow.visible = true
	for id in _sprites.keys():
		if not live_ids.has(id):
			var stale: Sprite2D = _sprites[id]
			stale.queue_free()
			_sprites.erase(id)
			_appearance_levels.erase(id)
			var stale_shadow: Sprite2D = _shadows.get(id)
			if stale_shadow != null:
				stale_shadow.queue_free()
				_shadows.erase(id)

func clear() -> void:
	for sprite in _sprites.values():
		sprite.queue_free()
	_sprites.clear()
	_appearance_levels.clear()
	for shadow in _shadows.values():
		shadow.queue_free()
	_shadows.clear()

func shadow_bounds(piece_id: int) -> Rect2:
	var shadow: Sprite2D = _shadows.get(piece_id)
	if shadow == null or shadow.texture == null:
		return Rect2()
	var size := shadow.texture.get_size() * shadow.scale
	return Rect2(shadow.position - size * 0.5, size)
