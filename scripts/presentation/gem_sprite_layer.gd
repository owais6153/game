class_name GemSpriteLayer
extends Node2D

const AssetCatalogType = preload("res://scripts/core/asset_catalog.gd")
const RADIAL_POOL_SIZE := 8
## One additive quad carries the whole merge burst: an expanding ring, a
## rotating swirl, and a soft smoke bloom, all evaluated per pixel. This is
## deliberately a shader rather than more draw_arc/draw_line primitives — the
## radial spark lines it replaces cost a primitive each and read as loose debris
## ("shred") rather than as one deliberate effect. Cost here is a single bounded
## quad per merge regardless of how elaborate the motion looks, which is what
## keeps it affordable on low-end hardware.
##
## The timing is matched to the merge sound rather than chosen by eye: the cue's
## energy is gone inside a third of a second, so the burst arrives and clears in
## the same window. See GameConfig.MERGE_RADIAL_DURATION.
##
## Style uniforms give each gem family its own character; see
## GameConfig.merge_burst_style().
const RADIAL_SHADER_CODE := """
shader_type canvas_item;
render_mode unshaded, blend_add;
uniform vec4 tint : source_color = vec4(0.5, 0.9, 1.0, 1.0);
uniform vec4 accent : source_color = vec4(1.0, 0.95, 0.75, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float intensity : hint_range(0.0, 2.0) = 0.35;
// Number of swirl arms. Low tiers get a simple wave, objective gems a denser
// rosette, so a player can tell what merged without reading the gem.
uniform float arms : hint_range(0.0, 16.0) = 7.0;
// Signed rotation speed. The sign alternates by gem family so neighbouring
// families never look like the same effect recoloured.
uniform float spin = 2.4;
// Extra bloom and a bright rim for objective-tier merges.
uniform float sparkle : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - vec2(1.0);
	float d = length(p);
	float angle = atan(p.y, p.x);

	// Snap out, then straight back off. An earlier version held near full
	// brightness for most of the window, which made the burst linger well past
	// its own sound cue. It reads better as a hit that arrives and clears.
	float edge_t = 1.0 - pow(1.0 - progress, 3.0);
	float fade = pow(1.0 - progress, 1.4);

	// Everything must be gone before the quad's edge. Anything still alive at
	// d = 1 gets sliced off square by the sprite bounds, which reads as the
	// effect being cropped rather than fading.
	float bounds = smoothstep(0.94, 0.62, d);

	// One crisp expanding ring is the shape of the effect. A wide soft front was
	// tried and read as a smear; the board is sharp faceted art and the burst
	// has to look deliberate next to it, not like a blur.
	float expanding_edge = mix(0.10, 0.70, edge_t);
	float thickness = mix(0.10, 0.20, edge_t);
	float ring = smoothstep(expanding_edge + thickness, expanding_edge, d)
		* smoothstep(expanding_edge - thickness, expanding_edge, d);

	// Rotation rides ON the ring rather than filling the disc. Sampling the
	// swirl across the whole interior produced broad lobes that read as a
	// spinning fan blade; modulating the ring instead makes the same rotation
	// look like light travelling around a shockwave.
	float wound = angle * arms + spin * progress * 9.4247780;
	float swirl = 0.55 + 0.45 * sin(wound);
	float ring_light = ring * swirl;

	// A tight inner glow that stays close to the result gem.
	float core = smoothstep(0.34, 0.0, d) * pow(1.0 - progress, 2.2);

	// A brief flash at the instant of the merge, giving the burst a hard onset
	// the eye is drawn to before the ring takes over.
	float flash = smoothstep(0.30, 0.0, d) * pow(1.0 - clamp(progress / 0.20, 0.0, 1.0), 2.0);

	vec3 colour = mix(tint.rgb, accent.rgb, clamp(swirl * 0.55 + sparkle * 0.35, 0.0, 1.0));
	// Only a touch of white, and only at the onset. Pushed harder the effect
	// desaturates into grey smoke and stops reading as a gem.
	colour = mix(colour, vec3(1.0), clamp(flash * 0.45, 0.0, 1.0));
	float alpha = (ring * 0.34 + ring_light * (0.70 + sparkle * 0.40)
		+ core * 0.45 + flash * 0.60) * fade * intensity * bounds;
	COLOR = vec4(colour, alpha * tint.a);
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
		# Above the gems; see GameConfig.MERGE_BURST_Z_INDEX. This was -4096,
		# which is relative to the parent layer and resolved below the table
		# sprite, so every burst was drawn behind opaque table art and the
		# effect was never visible at all.
		sprite.z_index = GameConfig.MERGE_BURST_Z_INDEX
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
	var style := _burst_style(level)
	_radial_bursts.append({
		"slot": slot,
		"position": position,
		"level": level,
		# Ceiling is above 1 on purpose: the objective and combo tiers are tuned
		# brighter than an ordinary merge, and a 1.0 clamp silently flattened that
		# escalation back to the ordinary level.
		"intensity": clampf(intensity, 0.0, GameConfig.MERGE_RADIAL_INTENSITY_CEILING),
		"elapsed": -delay,
		"arms": float(style.arms),
		"spin": float(style.spin),
		"sparkle": float(style.sparkle),
		"accent": style.accent as Color,
	})


## Resolves the burst character for one merge result.
##
## Two things vary. The gem's own colour family picks the swirl shape and its
## rotation direction, so families read as different effects rather than one
## effect recoloured. The tier picks how bright and dense it is, so the
## objective gems the level is asking for land harder than the commons the
## player merges constantly. Both tables live in GameConfig.
func _burst_style(level: int) -> Dictionary:
	var identity := AssetCatalogType.identity_for_local_tier(level)
	var family := String(AssetCatalogType.gem_definition(identity).get("color_family", ""))
	var family_style: Dictionary = GameConfig.MERGE_BURST_FAMILY_STYLE.get(family, GameConfig.MERGE_BURST_DEFAULT_STYLE)
	var is_target := level >= GameConfig.MERGE_BURST_TARGET_TIER
	return {
		"arms": float(family_style.get("arms", 4.0)) + (1.0 if is_target else 0.0),
		"spin": float(family_style.get("spin", 1.8)),
		"sparkle": float(GameConfig.MERGE_BURST_TIER_SPARKLE.get(level, 0.0)),
		"accent": GameConfig.MERGE_BURST_ACCENT_TARGET if is_target else GameConfig.MERGE_BURST_ACCENT_COMMON,
	}


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
		material.set_shader_parameter("accent", burst.get("accent", GameConfig.MERGE_BURST_ACCENT_COMMON))
		material.set_shader_parameter("arms", float(burst.get("arms", 4.0)))
		material.set_shader_parameter("spin", float(burst.get("spin", 1.8)))
		material.set_shader_parameter("sparkle", float(burst.get("sparkle", 0.0)))
		active.append(burst)
	_radial_bursts = active


func shift_reward_effects(delta: Vector2) -> void:
	for burst in _radial_bursts:
		burst.position += delta
	queue_redraw()

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

func clear_presentation_scale(piece_id: int) -> void:
	_presentation_scales.erase(piece_id)
	_presentation_offsets.erase(piece_id)
	_presentation_rotations.erase(piece_id)
	_presentation_elevated.erase(piece_id)
	queue_redraw()

func clear_presentation_scales() -> void:
	_presentation_scales.clear()
	_presentation_offsets.clear()
	_presentation_rotations.clear()
	_presentation_elevated.clear()
	queue_redraw()

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
	queue_redraw()

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
