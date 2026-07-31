class_name GemSpriteLayer
extends Node2D

const AssetCatalogType = preload("res://scripts/asset_catalog.gd")

var _sprites: Dictionary = {}
var _shadows: Dictionary = {}
var _piece_visual_roots: Dictionary = {}
var _visual_containers: Dictionary = {}
## Transient reward scale applied to the visual child only. The authoritative
## root scale, GemPiece radius, rail contact, and merge eligibility never read it.
var _presentation_scales: Dictionary = {}
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
			# The root mirrors the simulation position. The child remains at the
			# same fixed calibrated scale so visual bodies and collision bodies
			# begin contact at the same moment.
			var piece_visual_root := Node2D.new()
			piece_visual_root.name = "PieceVisualRoot_%d" % piece.id
			piece_visual_root.scale = Vector2.ONE
			add_child(piece_visual_root)
			_piece_visual_roots[piece.id] = piece_visual_root
			var visual := Node2D.new()
			visual.name = "Visual"
			piece_visual_root.add_child(visual)
			_visual_containers[piece.id] = visual
			var shadow := Sprite2D.new()
			shadow.texture = AssetCatalogType.GEM_SOFT_SHADOW
			shadow.centered = true
			shadow.z_index = 0
			visual.add_child(shadow)
			_shadows[piece.id] = shadow
			sprite = Sprite2D.new()
			sprite.centered = true
			sprite.z_index = 1
			visual.add_child(sprite)
			_sprites[piece.id] = sprite
			_appearance_levels.erase(piece.id)
		if _appearance_levels.get(piece.id, -1) != piece.level:
			var texture := AssetCatalogType.gem_texture(piece.level)
			sprite.texture = texture
			# The runtime images are alpha-trimmed to their main bodies. Independent
			# axis scales map that visible box to this piece's calibrated simple body.
			var visual_diameter := piece.base_radius * 2.0 * float(GameConfig.GEM_VISUAL_BODY_SCALE.get(piece.level, 1.0))
			sprite.scale = Vector2(visual_diameter / texture.get_size().x, visual_diameter / texture.get_size().y)
			var shadow: Sprite2D = _shadows.get(piece.id)
			var body_diameter := piece.base_radius * 2.0
			shadow.position = GameConfig.GEM_SHADOW_OFFSET.get(piece.level, Vector2(4.0, 7.0))
			shadow.scale = Vector2(body_diameter * GameConfig.GEM_SHADOW_WIDTH_MULTIPLIER / shadow.texture.get_size().x, body_diameter * GameConfig.GEM_SHADOW_HEIGHT_MULTIPLIER / shadow.texture.get_size().y)
			shadow.modulate = Color(1.0, 1.0, 1.0, float(GameConfig.GEM_SHADOW_OPACITY.get(piece.level, 0.4)))
			_appearance_levels[piece.id] = piece.level
		var piece_visual_root: Node2D = _piece_visual_roots.get(piece.id)
		var visual: Node2D = _visual_containers.get(piece.id)
		piece_visual_root.position = piece.position
		piece_visual_root.scale = Vector2.ONE * piece.perspective_scale
		piece_visual_root.z_index = GameConfig.gem_visual_z_index(piece.id, piece.position.y)
		# The root already carries the single shared visual/physics scale. Keep
		# this child at its calibrated base mapping to avoid double scaling.
		visual.scale = Vector2.ONE * float(_presentation_scales.get(piece.id, 1.0))
		sprite.position = Vector2.ZERO
		# Overlay state must never replace or dim a live gem texture. This layer
		# owns the exact texture/modulate values for every sync.
		sprite.modulate = Color.WHITE
		# Emerald and Diamond retain simple stable circular bodies; their artwork
		# remains presentation-only and never defines merge eligibility.
		sprite.visible = true
		var shadow: Sprite2D = _shadows.get(piece.id)
		shadow.position = GameConfig.GEM_SHADOW_OFFSET.get(piece.level, Vector2(4.0, 7.0))
		shadow.visible = true
	for id in _sprites.keys():
		if not live_ids.has(id):
			var stale: Sprite2D = _sprites[id]
			var stale_root: Node2D = _piece_visual_roots.get(id)
			if stale_root != null:
				stale_root.queue_free()
			else:
				stale.queue_free()
			_sprites.erase(id)
			_piece_visual_roots.erase(id)
			_visual_containers.erase(id)
			_appearance_levels.erase(id)
			_shadows.erase(id)
			_presentation_scales.erase(id)

func set_presentation_scale(piece_id: int, multiplier: float) -> void:
	_presentation_scales[piece_id] = clampf(multiplier, 0.70, 1.30)

func clear_presentation_scale(piece_id: int) -> void:
	_presentation_scales.erase(piece_id)

func clear_presentation_scales() -> void:
	_presentation_scales.clear()

func clear() -> void:
	for sprite in _sprites.values():
		var root: Node2D = _piece_visual_roots.get(_sprites.find_key(sprite))
		if root != null:
			root.queue_free()
		else:
			sprite.queue_free()
	_sprites.clear()
	_piece_visual_roots.clear()
	_visual_containers.clear()
	_appearance_levels.clear()
	_shadows.clear()
	_presentation_scales.clear()

func shadow_bounds(piece_id: int) -> Rect2:
	var shadow: Sprite2D = _shadows.get(piece_id)
	if shadow == null or shadow.texture == null:
		return Rect2()
	var root: Node2D = _piece_visual_roots.get(piece_id)
	var visual: Node2D = _visual_containers.get(piece_id)
	var perspective := root.scale.x if root != null else 1.0
	var position := root.position + shadow.position * perspective if root != null else shadow.position
	var size := shadow.texture.get_size() * shadow.scale * perspective
	return Rect2(position - size * 0.5, size)
