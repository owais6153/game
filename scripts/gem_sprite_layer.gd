class_name GemSpriteLayer
extends Node2D

const AssetCatalogType = preload("res://scripts/asset_catalog.gd")

var _sprites: Dictionary = {}
var _shadows: Dictionary = {}
var _piece_visual_roots: Dictionary = {}
var _visual_containers: Dictionary = {}
var _impact_axes: Dictionary = {}
var _artwork_roots: Dictionary = {}
## Transient reward scale applied to the visual child only. The authoritative
## root scale, GemPiece radius, rail contact, and merge eligibility never read it.
var _presentation_scales: Dictionary = {}
var _presentation_offsets: Dictionary = {}
var _presentation_rotations: Dictionary = {}
var _presentation_elevated: Dictionary = {}
## Short contact squash applied to the same visual child and multiplied after
## reward scale. It never reaches the physics-mirroring root or live radius.
var _impact_scales: Dictionary = {}
var _impact_angles: Dictionary = {}
var _impact_offsets: Dictionary = {}
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
			# Impact deformation is aligned in world space while Artwork applies the
			# inverse rotation. Gems squash along the confirmed contact normal without
			# turning their supplied artwork sideways.
			var impact_axis := Node2D.new()
			impact_axis.name = "ImpactAxis"
			visual.add_child(impact_axis)
			_impact_axes[piece.id] = impact_axis
			var artwork := Node2D.new()
			artwork.name = "Artwork"
			impact_axis.add_child(artwork)
			_artwork_roots[piece.id] = artwork
			var shadow := Sprite2D.new()
			shadow.texture = AssetCatalogType.GEM_SOFT_SHADOW
			shadow.centered = true
			shadow.z_index = 0
			artwork.add_child(shadow)
			_shadows[piece.id] = shadow
			sprite = Sprite2D.new()
			sprite.centered = true
			sprite.z_index = 1
			artwork.add_child(sprite)
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
		var impact_axis: Node2D = _impact_axes.get(piece.id)
		var artwork: Node2D = _artwork_roots.get(piece.id)
		piece_visual_root.position = piece.position
		piece_visual_root.scale = Vector2.ONE * piece.perspective_scale
		piece_visual_root.z_index = GameConfig.gem_visual_z_index(piece.id, piece.position.y)
		# The root already carries the single shared visual/physics scale. Keep
		# this child at its calibrated base mapping to avoid double scaling.
		visual.scale = _vector_scale(_presentation_scales.get(piece.id, Vector2.ONE))
		visual.position = _presentation_offsets.get(piece.id, Vector2.ZERO)
		visual.rotation = float(_presentation_rotations.get(piece.id, 0.0))
		visual.z_index = 128 if bool(_presentation_elevated.get(piece.id, false)) else 0
		var impact_angle := float(_impact_angles.get(piece.id, 0.0))
		impact_axis.scale = _vector_scale(_impact_scales.get(piece.id, Vector2.ONE))
		impact_axis.position = _impact_offsets.get(piece.id, Vector2.ZERO)
		impact_axis.rotation = impact_angle
		artwork.rotation = -impact_angle
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
			_impact_axes.erase(id)
			_artwork_roots.erase(id)
			_appearance_levels.erase(id)
			_shadows.erase(id)
			_presentation_scales.erase(id)
			_presentation_offsets.erase(id)
			_presentation_rotations.erase(id)
			_presentation_elevated.erase(id)
			_impact_scales.erase(id)
			_impact_angles.erase(id)
			_impact_offsets.erase(id)

func set_presentation_scale(piece_id: int, multiplier: float) -> void:
	_presentation_scales[piece_id] = Vector2.ONE * clampf(multiplier, 0.48, 1.32)

func set_presentation_transform(piece_id: int, scale: Vector2, rotation: float, offset: Vector2, elevated: bool = false) -> void:
	_presentation_scales[piece_id] = Vector2(clampf(scale.x, 0.48, 1.32), clampf(scale.y, 0.48, 1.32))
	_presentation_rotations[piece_id] = clampf(rotation, -0.20, 0.20)
	_presentation_offsets[piece_id] = offset.limit_length(GameConfig.MERGE_RESULT_LIFT * 1.25)
	_presentation_elevated[piece_id] = elevated

func clear_presentation_scale(piece_id: int) -> void:
	_presentation_scales.erase(piece_id)
	_presentation_offsets.erase(piece_id)
	_presentation_rotations.erase(piece_id)
	_presentation_elevated.erase(piece_id)

func clear_presentation_scales() -> void:
	_presentation_scales.clear()
	_presentation_offsets.clear()
	_presentation_rotations.clear()
	_presentation_elevated.clear()

func set_impact_scale(piece_id: int, multiplier: float) -> void:
	_impact_scales[piece_id] = Vector2.ONE * clampf(multiplier, 0.82, 1.12)

func set_impact_transform(piece_id: int, scale: Vector2, normal: Vector2, offset: Vector2 = Vector2.ZERO) -> void:
	_impact_scales[piece_id] = Vector2(clampf(scale.x, 0.80, 1.16), clampf(scale.y, 0.80, 1.16))
	_impact_angles[piece_id] = normal.normalized().angle() if not normal.is_zero_approx() else 0.0
	_impact_offsets[piece_id] = offset.limit_length(GameConfig.IMPACT_VISUAL_KICK_DISTANCE)

func clear_impact_scale(piece_id: int) -> void:
	_impact_scales.erase(piece_id)
	_impact_angles.erase(piece_id)
	_impact_offsets.erase(piece_id)

func clear_impact_scales() -> void:
	_impact_scales.clear()
	_impact_angles.clear()
	_impact_offsets.clear()

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
	_impact_axes.clear()
	_artwork_roots.clear()
	_appearance_levels.clear()
	_shadows.clear()
	_presentation_scales.clear()
	_presentation_offsets.clear()
	_presentation_rotations.clear()
	_presentation_elevated.clear()
	_impact_scales.clear()
	_impact_angles.clear()
	_impact_offsets.clear()

func _vector_scale(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	return Vector2.ONE * float(value)

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
