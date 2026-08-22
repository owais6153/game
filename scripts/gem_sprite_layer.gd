class_name GemSpriteLayer
extends Node2D

const AssetCatalogType = preload("res://scripts/asset_catalog.gd")
const RADIAL_POOL_SIZE := 8
const RADIAL_SHADER_CODE := """
shader_type canvas_item;
render_mode unshaded, blend_add;
uniform vec4 tint : source_color = vec4(0.5, 0.9, 1.0, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.35;
void fragment() {
	vec2 p = UV * 2.0 - vec2(1.0);
	float d = length(p);
	float expanding_edge = mix(0.18, 0.92, progress);
	float ring = smoothstep(expanding_edge + 0.14, expanding_edge, d) * smoothstep(expanding_edge - 0.18, expanding_edge, d);
	float core = smoothstep(0.82, 0.0, d) * (1.0 - progress);
	float fade = 1.0 - smoothstep(0.0, 1.0, progress);
	float alpha = (ring * 0.78 + core * 0.42) * fade * intensity;
	COLOR = vec4(tint.rgb, alpha * tint.a);
}
"""

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
## Bounded, presentation-only contact response. It is applied below the
## simulation-mirroring root and is never read by physics or merge logic.
var _impact_scales: Dictionary = {}
var _impact_angles: Dictionary = {}
var _impact_offsets: Dictionary = {}
## Last synchronized tier for each live piece. Appearance work is done once on
## creation/merge-tier change; the frame path only moves existing sprites.
var _appearance_levels: Dictionary = {}
var _radial_bursts: Array[Dictionary] = []
var _radial_pool: Array[Sprite2D] = []


func _ready() -> void:
	_build_radial_pool()


func _build_radial_pool() -> void:
	if not _radial_pool.is_empty():
		return
	var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)
	var shader := Shader.new()
	shader.code = RADIAL_SHADER_CODE
	for index in range(RADIAL_POOL_SIZE):
		var sprite := Sprite2D.new()
		sprite.name = "MergeRadialBurst_%d" % index
		sprite.texture = texture
		sprite.centered = true
		sprite.z_index = -4096
		sprite.visible = false
		var material := ShaderMaterial.new()
		material.shader = shader
		sprite.material = material
		add_child(sprite)
		_radial_pool.append(sprite)


func begin_merge_radial(position: Vector2, level: int, intensity: float, delay: float = 0.0) -> void:
	_build_radial_pool()
	var slot := -1
	var used: Dictionary = {}
	for burst in _radial_bursts:
		used[int(burst.slot)] = true
	for index in range(_radial_pool.size()):
		if not used.has(index):
			slot = index
			break
	if slot < 0:
		var oldest: Dictionary = _radial_bursts.pop_front()
		slot = int(oldest.slot)
	var node := _radial_pool[slot]
	node.visible = false
	_radial_bursts.append({
		"slot": slot,
		"position": position,
		"level": level,
		"intensity": clampf(intensity, 0.0, 1.0),
		"elapsed": -delay,
	})


func update_reward_effects(delta: float) -> void:
	if _radial_bursts.is_empty():
		return
	var active: Array[Dictionary] = []
	for burst in _radial_bursts:
		burst.elapsed = float(burst.elapsed) + delta
		var node := _radial_pool[int(burst.slot)]
		if float(burst.elapsed) < 0.0:
			node.visible = false
			active.append(burst)
			continue
		var t := clampf(float(burst.elapsed) / GameConfig.MERGE_RADIAL_DURATION, 0.0, 1.0)
		if t >= 1.0:
			node.visible = false
			continue
		var eased := 1.0 - pow(1.0 - t, 2.4)
		var radial_scale := lerpf(GameConfig.MERGE_RADIAL_START_SCALE, GameConfig.MERGE_RADIAL_END_SCALE, eased)
		var gem_radius := GameConfig.gem_collision_radius(int(burst.level))
		node.position = burst.position
		node.scale = Vector2.ONE * gem_radius * 2.0 * radial_scale
		node.visible = true
		var material := node.material as ShaderMaterial
		material.set_shader_parameter("progress", t)
		material.set_shader_parameter("intensity", float(burst.intensity))
		material.set_shader_parameter("tint", GameConfig.gem_color(int(burst.level)).lightened(0.22))
		active.append(burst)
	_radial_bursts = active


func shift_reward_effects(delta: Vector2) -> void:
	for burst in _radial_bursts:
		burst.position += delta

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
			# Every renderer preserves the supplied silhouette. A single uniform scale
			# matches the merge proxy, TARGET/NEXT previews, and result artwork.
			var visual_diameter := piece.base_radius * 2.0 * float(GameConfig.GEM_VISUAL_BODY_SCALE.get(piece.level, 1.0))
			var texture_longest_side := maxf(texture.get_size().x, texture.get_size().y)
			sprite.scale = Vector2.ONE * (visual_diameter / texture_longest_side)
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

## The reward pass reveals a merge result from zero and overshoots to 1.30, so
## the bound spans the full presentation range. It remains presentation-only.
const PRESENTATION_SCALE_MIN := 0.0
const PRESENTATION_SCALE_MAX := 1.45

func set_presentation_scale(piece_id: int, multiplier: float) -> void:
	_presentation_scales[piece_id] = Vector2.ONE * clampf(multiplier, PRESENTATION_SCALE_MIN, PRESENTATION_SCALE_MAX)

func set_presentation_transform(piece_id: int, scale: Vector2, rotation: float, offset: Vector2, elevated: bool = false) -> void:
	var uniform_scale := clampf((scale.x + scale.y) * 0.5, PRESENTATION_SCALE_MIN, PRESENTATION_SCALE_MAX)
	_presentation_scales[piece_id] = Vector2.ONE * uniform_scale
	_presentation_rotations[piece_id] = 0.0
	_presentation_offsets[piece_id] = offset.limit_length(24.0)
	_presentation_elevated[piece_id] = elevated

## A newly rewarded gameplay piece is already at a collision-safe simulation
## position. This visual-only offset initially draws it at the confirmed merge
## center, then the controller eases it onto that authoritative position.
func set_bonus_spawn_transform(piece_id: int, multiplier: float, offset: Vector2) -> void:
	_presentation_scales[piece_id] = Vector2.ONE * clampf(multiplier, PRESENTATION_SCALE_MIN, PRESENTATION_SCALE_MAX)
	_presentation_rotations[piece_id] = 0.0
	_presentation_offsets[piece_id] = offset.limit_length(180.0)
	_presentation_elevated[piece_id] = false

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
	clear_impact_scale(piece_id)

func set_impact_transform(piece_id: int, scale: Vector2, normal: Vector2, offset: Vector2 = Vector2.ZERO) -> void:
	var safe_normal := normal.normalized() if normal.length_squared() > 0.0001 else Vector2.RIGHT
	_impact_scales[piece_id] = Vector2(
		clampf(scale.x, 0.92, 1.08),
		clampf(scale.y, 0.92, 1.08)
	)
	_impact_angles[piece_id] = safe_normal.angle()
	_impact_offsets[piece_id] = offset.limit_length(2.0)

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
	_radial_bursts.clear()
	for sprite in _radial_pool:
		sprite.visible = false

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
