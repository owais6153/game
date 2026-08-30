class_name PowerCinematicLayer
extends Node2D

## The full-screen moment a power gets when it is spent. Presentation only: it
## never reads or writes gameplay state, and the board effect has already been
## applied by the time a sequence starts.
##
## Every power runs the same three beats so the row feels like one system —
## the power announces itself large, travels down into the spot it acts on, and
## lands with an impact — but each beat is drawn differently per power, because
## a bomb and a magnet should not read as the same event.
##
## The supplied assets/vfx/ illustrations are single static frames, so they
## cannot carry the travel or the impact. The icon art is used for the hero
## sprite, where a still image is exactly right, and everything that has to move
## is drawn procedurally here.

const PowerInventoryServiceType = preload("res://scripts/services/power_inventory_service.gd")

## Beat boundaries as fractions of the whole sequence. Announce, travel, impact.
const ANNOUNCE_END := 0.18
const TARGET_ARRIVE := 0.32
const TRAVEL_END := 0.74

## Targeted powers visibly brace over the chosen gem before impact. The longer
## beat is still tap-skippable for returning players.
const DURATION := 1.65
const SKIP_TO_IMPACT_AT := TRAVEL_END

const HERO_SCREEN_SCALE := 0.62
const BACKDROP_ALPHA := 0.46
const RAY_COUNT := 14
const DEBRIS_COUNT := 14

## Per-power identity. `tint` colours the rays, ring, and debris; `spin` is the
## hero sprite's rotation across the announce beat; `rays` picks the backdrop
## treatment so the four powers never read as the same burst.
const STYLE := {
	"bomb": {
		"tint": Color(1.0, 0.62, 0.22, 1.0),
		"flash": Color(1.0, 0.86, 0.55, 1.0),
		"spin": 0.0,
		"rays": "shards",
		"ring_scale": 1.0,
		"shake": 7.0,
		"brightness": 1.30,
		"debris_scale": 1.24,
	},
	"hammer": {
		"tint": Color(0.72, 0.86, 1.0, 1.0),
		"flash": Color(0.94, 0.98, 1.0, 1.0),
		# The hammer cocks back before it falls, so the swing reads as a strike.
		"spin": -0.55,
		"rays": "lightning",
		"ring_scale": 0.82,
		"shake": 9.0,
		"brightness": 1.24,
		"debris_scale": 1.16,
	},
	"magnet": {
		"tint": Color(1.0, 0.36, 0.44, 1.0),
		"flash": Color(0.72, 0.86, 1.0, 1.0),
		"spin": 0.0,
		# Magnet pulls inward, so its rays converge instead of radiating.
		"rays": "inrush",
		"ring_scale": 0.7,
		"shake": 0.0,
		"brightness": 1.0,
		"debris_scale": 1.0,
	},
	"switch": {
		"tint": Color(0.86, 0.44, 1.0, 1.0),
		"flash": Color(1.0, 0.92, 0.62, 1.0),
		# A full turn, matching the icon's own circular arrows.
		"spin": TAU,
		"rays": "swirl",
		"ring_scale": 0.66,
		"shake": 0.0,
		"brightness": 1.0,
		"debris_scale": 1.0,
	},
}

signal impact_reached(power: String)
signal finished(power: String)

var active := false
var power := ""
var elapsed := 0.0
var origin := Vector2.ZERO
var screen_centre := Vector2.ZERO
var shake_offset := Vector2.ZERO

var _hero: Sprite2D
var _rng := RandomNumberGenerator.new()
var _debris: Array[Dictionary] = []
var _impact_announced := false


func _ready() -> void:
	# Above the gems, below the HUD, and never interactive.
	z_index = 40
	_hero = Sprite2D.new()
	_hero.name = "PowerHero"
	_hero.visible = false
	add_child(_hero)
	set_process(false)


## `at_position` is in the same board space the gems use, so the sequence lands
## exactly where the power acted.
func play(power_name: String, at_position: Vector2, viewport_centre: Vector2) -> void:
	if not STYLE.has(power_name):
		return
	power = power_name
	origin = at_position
	screen_centre = viewport_centre
	elapsed = 0.0
	active = true
	_impact_announced = false
	shake_offset = Vector2.ZERO
	_rng.seed = int(abs(at_position.x * 7919.0 + at_position.y * 104729.0)) + power_name.hash()
	_build_debris()
	var texture := load("res://assets/runtime/ui/kit/power_icon_%s.png" % power_name) as Texture2D
	if texture != null:
		_hero.texture = texture
		_hero.visible = true
	set_process(true)
	queue_redraw()


## A tap during the announce or travel beat jumps straight to the impact, so a
## player who has seen it a hundred times is never held up.
func skip_to_impact() -> void:
	if not active or elapsed >= DURATION * SKIP_TO_IMPACT_AT:
		return
	elapsed = DURATION * SKIP_TO_IMPACT_AT


func is_playing() -> bool:
	return active


func stop() -> void:
	active = false
	elapsed = 0.0
	shake_offset = Vector2.ZERO
	if _hero != null:
		_hero.visible = false
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	var progress := clampf(elapsed / DURATION, 0.0, 1.0)
	_update_hero(progress)
	_update_shake(progress)
	# Applied to this layer only, so an impact never displaces the simulation.
	position = shake_offset
	if not _impact_announced and progress >= TRAVEL_END:
		_impact_announced = true
		impact_reached.emit(power)
	if progress >= 1.0:
		var finished_power := power
		stop()
		finished.emit(finished_power)
		return
	queue_redraw()


## The hero sprite is the through-line: it announces at screen centre, then
## travels into the target while shrinking to roughly gem size.
func _update_hero(progress: float) -> void:
	if _hero == null or _hero.texture == null:
		return
	var style: Dictionary = STYLE[power]
	if progress < ANNOUNCE_END:
		var t := progress / ANNOUNCE_END
		var eased := 1.0 - pow(1.0 - t, 3.0)
		_hero.position = screen_centre
		_hero.scale = Vector2.ONE * lerpf(0.35, HERO_SCREEN_SCALE, eased) * _hero_base_scale()
		_hero.rotation = lerpf(0.0, float(style.spin), eased)
		_hero.modulate.a = clampf(t * 2.2, 0.0, 1.0)
	elif progress < TRAVEL_END:
		var targeted := power == PowerInventoryServiceType.BOMB or power == PowerInventoryServiceType.HAMMER
		if progress >= TARGET_ARRIVE:
			var hold_t := (progress - TARGET_ARRIVE) / (TRAVEL_END - TARGET_ARRIVE)
			if not targeted:
				# Magnet and Switch now arrive on the same fast beat as the targeted
				# powers. Their longer cinematic time is filled with active orbiting
				# and tightening motion at the destination, never a slow screen drift.
				var orbit_radius := lerpf(34.0, 8.0, hold_t)
				var orbit_speed := 20.0 if power == PowerInventoryServiceType.MAGNET else 15.0
				var orbit := Vector2.from_angle(elapsed * orbit_speed) * orbit_radius
				_hero.position = origin + orbit
				_hero.scale = Vector2.ONE * (0.16 + sin(hold_t * PI * 5.0) * 0.014) * _hero_base_scale()
				_hero.rotation = elapsed * (8.0 if power == PowerInventoryServiceType.SWITCH else -4.0)
				_hero.modulate.a = 1.0
				return
			# Hold directly over the selected gem and visibly tremble/cock before
			# the impact signal changes the board. Hammer receives the strongest
			# wind-up; Bomb pulses like a fuse about to go.
			var shake_strength := (7.0 if power == PowerInventoryServiceType.HAMMER else 4.5) * sin(hold_t * PI)
			_hero.position = origin + Vector2(sin(elapsed * 38.0), cos(elapsed * 31.0)) * shake_strength
			_hero.scale = Vector2.ONE * (0.19 + sin(hold_t * PI * 3.0) * 0.018) * _hero_base_scale()
			_hero.rotation = sin(elapsed * 22.0) * (0.24 if power == PowerInventoryServiceType.HAMMER else 0.08)
			_hero.modulate.a = 1.0
		else:
			var t := clampf((progress - ANNOUNCE_END) / (TARGET_ARRIVE - ANNOUNCE_END), 0.0, 1.0)
			# Every power crosses the screen in the same short, decisive beat. The
			# quartic ease preserves high visible speed while landing cleanly.
			var eased := 1.0 - pow(1.0 - t, 4.0)
			_hero.position = screen_centre.lerp(origin, eased)
			_hero.scale = Vector2.ONE * lerpf(HERO_SCREEN_SCALE, 0.19 if targeted else 0.16, eased) * _hero_base_scale()
			_hero.rotation = lerpf(float(style.spin), 0.0, eased)
			_hero.modulate.a = 1.0
	else:
		var t := (progress - TRAVEL_END) / (1.0 - TRAVEL_END)
		_hero.position = origin
		_hero.scale = Vector2.ONE * lerpf(0.16, 0.34, t) * _hero_base_scale()
		_hero.modulate.a = 1.0 - t


func _hero_base_scale() -> float:
	if _hero == null or _hero.texture == null:
		return 1.0
	# Normalise every icon to the same on-screen size regardless of its source
	# resolution, so no power announces itself larger than the others.
	return 480.0 / float(maxi(1, _hero.texture.get_width()))


## Only the two destructive powers shake, and only briefly on the impact beat.
## Magnet and switch never shake: nothing was destroyed.
func _update_shake(progress: float) -> void:
	var amount := float(STYLE[power].shake)
	if amount <= 0.0 or progress < TRAVEL_END:
		shake_offset = Vector2.ZERO
		return
	var decay := 1.0 - (progress - TRAVEL_END) / (1.0 - TRAVEL_END)
	shake_offset = Vector2(
		_rng.randf_range(-amount, amount),
		_rng.randf_range(-amount, amount)
	) * decay * decay


func _build_debris() -> void:
	_debris.clear()
	for index in range(DEBRIS_COUNT):
		var angle := _rng.randf_range(0.0, TAU)
		_debris.append({
			"angle": angle,
			"distance": _rng.randf_range(70.0, 210.0),
			"size": _rng.randf_range(9.0, 22.0),
			"spin": _rng.randf_range(-6.0, 6.0),
		})


func _draw() -> void:
	if not active:
		return
	var progress := clampf(elapsed / DURATION, 0.0, 1.0)
	var style: Dictionary = STYLE[power]
	if progress < TRAVEL_END:
		_draw_backdrop(progress, style)
	else:
		_draw_impact((progress - TRAVEL_END) / (1.0 - TRAVEL_END), style)


## The announce beat's backdrop. Each power gets its own treatment so the
## moment is identifiable before the icon even reads.
func _draw_backdrop(progress: float, style: Dictionary) -> void:
	var fade := 1.0
	if progress < ANNOUNCE_END:
		fade = clampf(progress / (ANNOUNCE_END * 0.6), 0.0, 1.0)
	else:
		fade = 1.0 - (progress - ANNOUNCE_END) / (TRAVEL_END - ANNOUNCE_END)
	if fade <= 0.01:
		return
	var tint: Color = style.tint
	var centre := screen_centre
	var kind := String(style.rays)
	var brightness := float(style.get("brightness", 1.0))
	fade = minf(1.0, fade * brightness)
	var spin := elapsed * 1.6
	match kind:
		"lightning":
			# Jagged forks, drawn from the centre outward.
			for index in range(RAY_COUNT):
				var angle := TAU * float(index) / float(RAY_COUNT) + spin * 0.25
				_draw_fork(centre, angle, 360.0, tint, fade)
		"inrush":
			# Streaks converging on the centre: the magnet pulls, it does not push.
			for index in range(RAY_COUNT * 2):
				var angle := TAU * float(index) / float(RAY_COUNT * 2) + spin * 0.4
				var inner := lerpf(340.0, 90.0, progress / TRAVEL_END)
				var outer := inner + 130.0
				draw_line(
					centre + Vector2.from_angle(angle) * outer,
					centre + Vector2.from_angle(angle) * inner,
					Color(tint.r, tint.g, tint.b, 0.5 * fade),
					4.0
				)
		"swirl":
			# Arcs chasing each other around the centre.
			for index in range(6):
				var base := TAU * float(index) / 6.0 + spin
				_draw_arc_streak(centre, base, 150.0 + float(index) * 26.0, tint, fade)
		_:
			# "shards": broad triangular rays for the bomb.
			for index in range(RAY_COUNT):
				var angle := TAU * float(index) / float(RAY_COUNT) + spin * 0.15
				var width := 0.055
				var length := 420.0
				draw_colored_polygon(
					PackedVector2Array([
						centre,
						centre + Vector2.from_angle(angle - width) * length,
						centre + Vector2.from_angle(angle + width) * length,
					]),
					Color(tint.r, tint.g, tint.b, BACKDROP_ALPHA * fade)
				)


func _draw_fork(centre: Vector2, angle: float, length: float, tint: Color, fade: float) -> void:
	var direction := Vector2.from_angle(angle)
	var normal := direction.orthogonal()
	var points := PackedVector2Array()
	points.append(centre)
	var segments := 4
	for step in range(1, segments + 1):
		var along := length * float(step) / float(segments)
		var jitter := sin(float(step) * 2.3 + angle * 5.0 + elapsed * 9.0) * 26.0
		points.append(centre + direction * along + normal * jitter)
	# A wide soft stroke with a bright core, so the fork reads as lightning
	# rather than as a thin grey scratch over the table art.
	draw_polyline(points, Color(tint.r, tint.g, tint.b, 0.34 * fade), 11.0)
	draw_polyline(points, Color(tint.r, tint.g, tint.b, 0.85 * fade), 5.0)
	draw_polyline(points, Color(1.0, 1.0, 1.0, 0.9 * fade), 2.0)


func _draw_arc_streak(centre: Vector2, base_angle: float, radius: float, tint: Color, fade: float) -> void:
	var points := PackedVector2Array()
	for step in range(9):
		var angle := base_angle + float(step) * 0.13
		points.append(centre + Vector2.from_angle(angle) * radius)
	draw_polyline(points, Color(tint.r, tint.g, tint.b, 0.62 * fade), 6.0)


## The impact beat: a flash, an expanding ring, and debris thrown outward. This
## is the only part that draws at the target rather than at screen centre.
func _draw_impact(t: float, style: Dictionary) -> void:
	var tint: Color = style.tint
	var flash: Color = style.flash
	var ring_scale := float(style.ring_scale)
	var brightness := float(style.get("brightness", 1.0))
	var debris_scale := float(style.get("debris_scale", 1.0))

	# A brief white-hot flash that decays fast, so it punctuates rather than blinds.
	var flash_alpha := minf(1.0, pow(1.0 - t, 2.6) * 0.92 * brightness)
	if flash_alpha > 0.01:
		draw_circle(origin, lerpf(44.0, 168.0, t) * ring_scale, Color(flash.r, flash.g, flash.b, flash_alpha * 0.5))
		draw_circle(origin, lerpf(24.0, 92.0, t) * ring_scale, Color(flash.r, flash.g, flash.b, flash_alpha))

	# The shockwave ring, thinning as it grows.
	var ring_radius := lerpf(20.0, 250.0 * ring_scale, 1.0 - pow(1.0 - t, 2.5))
	var ring_alpha := 1.0 - t
	if ring_alpha > 0.01:
		draw_arc(origin, ring_radius, 0.0, TAU, 48, Color(tint.r, tint.g, tint.b, minf(1.0, ring_alpha * brightness)), lerpf(20.0 * brightness, 3.0, t), true)
		draw_arc(origin, ring_radius * 0.72, 0.0, TAU, 40, Color(flash.r, flash.g, flash.b, minf(1.0, ring_alpha * 0.55 * brightness)), lerpf(11.0 * brightness, 2.0, t), true)

	# Magnet reverses its debris: fragments rush inward and vanish at the gem.
	var inward := String(style.rays) == "inrush"
	for fragment in _debris:
		var travel := float(fragment.distance) * (1.0 - pow(1.0 - t, 2.0))
		var distance := float(fragment.distance) - travel if inward else travel
		var point := origin + Vector2.from_angle(float(fragment.angle)) * distance
		var size := float(fragment.size) * debris_scale * (t if inward else 1.0 - t * 0.65)
		var alpha := (t if inward else 1.0 - t) * 0.95
		if alpha <= 0.01 or size <= 0.3:
			continue
		var spin := float(fragment.spin) * t
		var corners := PackedVector2Array()
		for corner in range(4):
			var angle := spin + TAU * float(corner) / 4.0
			corners.append(point + Vector2.from_angle(angle) * size)
		draw_colored_polygon(corners, Color(tint.r, tint.g, tint.b, alpha))
