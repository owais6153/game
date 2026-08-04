class_name GameConfig
extends RefCounted

const VIEWPORT_SIZE := Vector2(720.0, 1280.0)
## Authoritative table layout. The supplied table is a trapezoid, so the same
## rail model is consumed by Sprite2D placement, collision containment, drag
## clamps, launcher spawn, and danger-line drawing.
## Proven table rail model from `new-table-shadow-contact-fix-v1`, translated
## by the exact +116 px Y delta used when the table artwork was bottom-aligned.
## These points remain the sole source for rendering diagnostics, containment,
## launcher limits, and the danger-line width.
const TABLE_TEXTURE_CENTER := Vector2(360.0, 846.0)
const TABLE_TEXTURE_SIZE := Vector2(920.0, 810.0)
const TABLE_TEXTURE_RENDER_SCALE := Vector2(0.7826087, 1.1802469)
const BOARD_LEFT := 0.0
const BOARD_RIGHT := 720.0
const TABLE_BOTTOM_ALIGNMENT_DELTA_Y := 116.0
const BOARD_TOP := 416.0
const BOARD_BOTTOM := 1228.0
const TABLE_INNER_LEFT_TOP := 178.0
const TABLE_INNER_LEFT_BOTTOM := 44.0
const TABLE_INNER_RIGHT_TOP := 542.0
const TABLE_INNER_RIGHT_BOTTOM := 676.0
const DANGER_LINE_Y := 1046.0
const LAUNCH_Y := 1144.0
## Expanded portrait screens keep the HUD top-anchored but move the complete
## table coordinate system to the physical bottom. This offset is shared by
## artwork, rails, bounds, spawn, drag, danger, and depth interpolation.
static var portrait_bottom_offset_y := 0.0
static var viewport_center_offset_x := 0.0
## Largest gameplay radius. Individual values are calibrated to the visible
## main body of the alpha-trimmed runtime texture for each gem level.
const PIECE_RADIUS := 42.0
## These radii are calibrated to the opaque main body after runtime scaling.
## Gold rims, glows, shadows and transparent texture padding never add collision size.
## Restore the smooth baseline bodies exactly for the original five tiers.
## Catalog expansion does not change physics scale: tiers 6–18 use the
## baseline default radius until a separately scoped design/balance task says
## otherwise. These are fixed for a piece's entire lifetime.
const GEM_COLLISION_RADIUS := {1: 42.0, 2: 42.0, 3: 33.0, 4: 42.0, 5: 42.0, 6: 42.0, 7: 42.0, 8: 32.0, 9: 42.0, 10: 42.0, 11: 42.0, 12: 42.0, 13: 42.0, 14: 42.0, 15: 42.0, 16: 42.0, 17: 42.0, 18: 42.0}
## Runtime visual-body expansion maps the opaque gem body to the stable
## simple collider; it is a visual calibration only.
## Body-only textures are trimmed independently from their former baked
## shadows/glows. Their scale maps visible body edges directly to colliders.
## Derived at asset-preparation time from the solid alpha body. The tiny
## expansion maps the visible body edge to its existing fixed circle collider;
## it does not resize a piece or alter simulation values during play.
const GEM_VISUAL_BODY_SCALE := {1: 1.008, 2: 1.008, 3: 1.008, 4: 1.008, 5: 1.008, 6: 1.008, 7: 1.008, 8: 1.008, 9: 1.008, 10: 1.008, 11: 1.008, 12: 1.008, 13: 1.008, 14: 1.008, 15: 1.008, 16: 1.008, 17: 1.008, 18: 1.008}
## Presentation-only lower shadows. All 18 tiers use the same calibrated
## placement so a shadow cannot be mistaken for a physical body or contact.
const GEM_SHADOW_OFFSET := {1: Vector2(5.0, 23.0), 2: Vector2(5.0, 23.0), 3: Vector2(4.0, 19.0), 4: Vector2(5.0, 23.0), 5: Vector2(5.0, 23.0), 6: Vector2(5.0, 23.0), 7: Vector2(5.0, 23.0), 8: Vector2(4.0, 18.0), 9: Vector2(5.0, 23.0), 10: Vector2(5.0, 23.0), 11: Vector2(5.0, 23.0), 12: Vector2(5.0, 23.0), 13: Vector2(5.0, 23.0), 14: Vector2(5.0, 23.0), 15: Vector2(5.0, 23.0), 16: Vector2(5.0, 23.0), 17: Vector2(5.0, 23.0), 18: Vector2(5.0, 23.0)}
const GEM_SHADOW_OPACITY := {1: 0.36, 2: 0.40, 3: 0.34, 4: 0.36, 5: 0.40, 6: 0.36, 7: 0.42, 8: 0.38, 9: 0.36, 10: 0.36, 11: 0.36, 12: 0.36, 13: 0.36, 14: 0.36, 15: 0.36, 16: 0.36, 17: 0.36, 18: 0.36}
const GEM_SHADOW_WIDTH_MULTIPLIER := 0.96
const GEM_SHADOW_HEIGHT_MULTIPLIER := 0.43
const VISIBLE_CONTACT_TOLERANCE := 2.0
## One conservative table-depth scale is shared by every gem's visual root and
## simulation radius. It keeps rendered contact, rail containment, and merge
## eligibility in the same coordinate system.
const GEM_PERSPECTIVE_SCALE_BACK := 0.85
const GEM_PERSPECTIVE_SCALE_FRONT := 1.00
## CanvasItem z-index is bounded by Godot. Eight stable tie slots are enough
## for the visually indistinguishable equal-Y bucket; creation order remains
## the stable fallback for IDs that share a slot.
const GEM_VISUAL_Z_BUCKETS := 500
const GEM_VISUAL_Z_TIE_STRIDE := 8
# Gameplay balance v1 — all feel values live here. Keep simulation delta-based.
# The default/range notes are the approved safe tuning envelope for this prototype.
const DRAG_HIT_RADIUS_MULTIPLIER := 1.8 # default 1.8; safe 1.5–2.0
const LAUNCH_SPEED := 1160.0 # approved parity range 1120–1200
const VELOCITY_DAMPING_PER_SECOND := 185.0 # reference-parity range 175–205
const SLEEP_SPEED := 9.0 # stable-settle range 8–11
const SIDE_WALL_RESTITUTION := 0.24 # contained redirection range 0.20–0.28
const TOP_WALL_RESTITUTION := 0.22 # visible but controlled rebound range 0.18–0.25
const BOTTOM_WALL_RESTITUTION := 0.12 # containment-only range 0.10–0.14
## True coefficient of restitution used by the equal-mass impulse equation.
## This is intentionally a soft bounce: contact separates instead of retaining
## inward velocity, without turning the table into frictionless billiards.
const COLLISION_RESTITUTION := 0.30 # lively separating response range 0.26–0.34
const COLLISION_TANGENTIAL_FRICTION := 0.07 # applied once per approaching impact; range 0.05–0.10
const MAX_PIECE_SPEED := 1200.0 # containment guard; preserves natural launch/collision speed
const CONTACT_EPSILON := 0.20
const SEPARATION_EPSILON := 0.02 # keeps post-contact correction inside narrow merge tolerance
## Presentation-only reward cadence. Physics, colliders, contact eligibility,
## momentum, score values, and launcher handoff are intentionally unaffected.
const MERGE_PRESENTATION_DURATION := 0.68 # reference-paced emergence; presentation only
const MERGE_SOURCE_PULL_DURATION := 0.12
const MERGE_RESULT_START_SCALE := 0.52
const MERGE_RESULT_POP_SCALE := 1.26
const MERGE_RESULT_POP_DURATION := 0.30
const MERGE_RESULT_LIFT := 18.0
const MERGE_RESULT_TILT_RADIANS := 0.075
const MERGE_PULSE_SCALE := 1.20
const SCORE_POPUP_DURATION := 0.62
const SCORE_POPUP_RISE := 36.0
const MAJOR_REWARD_TIER := 6
const MAJOR_MERGE_EFFECT_DURATION := 0.78
const MAJOR_SCORE_POPUP_DURATION := 1.05
const MAJOR_SCORE_POPUP_RISE := 58.0
const MAJOR_MERGE_EFFECT_SCALE := 1.55
const MAJOR_MERGE_SPARK_COUNT := 16
## Reference-style run-coin reward. Coins scatter at the confirmed merge point,
## then fly to the HUD in bounded staggered arcs while the visible count rises.
const COIN_BURST_COUNT := 10
const MAJOR_COIN_BURST_COUNT := 14
const COIN_BURST_DURATION := 0.46
const COIN_FLIGHT_DURATION := 1.18
const MAJOR_COIN_FLIGHT_DURATION := 1.28
const COIN_FLIGHT_STAGGER := 0.065
const COIN_SPAWN_STAGGER := 0.018
const COIN_BURST_RADIUS := 82.0
const MAJOR_COIN_BURST_RADIUS := 106.0
const COIN_DRAW_RADIUS := 15.0
const COIN_COUNTER_PULSE_DURATION := 0.24
const COIN_EFFECT_LIMIT := 56
const COIN_HUD_FALLBACK_DESTINATION := Vector2(78.0, 244.0)
const AIM_GUIDE_WIDTH := 2.0
const AIM_GUIDE_ALPHA := 0.58
const IMPACT_VISUAL_DURATION := 0.22
const IMPACT_VISUAL_MIN_SCALE := 0.84
const IMPACT_VISUAL_CROSS_SCALE := 1.12
const IMPACT_VISUAL_OVERSHOOT_SCALE := 1.08
const IMPACT_VISUAL_KICK_DISTANCE := 5.0
const TARGET_COLLECTION_DURATION := 0.62
const TARGET_COLLECTION_FADE_START := 0.68
const TARGET_COLLECTION_POP_SCALE := 1.16
const TARGET_PANEL_PULSE_DURATION := 0.22
const PRESENTATION_EVENT_TRACE_LIMIT := 128
const MERGE_MOMENTUM_TRANSFER := 0.62 # bounded average of source momentum
const MERGE_MAX_SPAWN_SPEED := 420.0 # prevents an upgrade from shooting through a cluster
const CHAIN_PRESENTATION_STAGGER := 0.05 # visual cadence only; merge logic remains immediate
const NEXT_LAUNCHER_READY_DELAY := 0.04 # after bounded handoff and any presentation gate
## A released gem gives the launcher lane time to clear, then becomes a normal
## simulation body even if contacts keep it moving. This bounds replacement
## latency on crowded boards without changing any motion or collision value.
const LAUNCHER_HANDOFF_DELAY := 0.30
const MERGE_CHAIN_DEPTH_CAP := 6
const OVERLAY_BUTTON_RECT := Rect2(220.0, 770.0, 280.0, 64.0)
const OVERLAY_FADE_DURATION := 0.18
const RESULT_BACKDROP_OPACITY := 0.48
const WIN_PRESENTATION_HOLD := 0.32
## Rendering-only layout values. These never feed simulation or collision geometry.
## HUD measurements are in the fixed 720-wide design space, sampled from the
## supplied portrait reference: large SCORE left, five-ring ladder centered,
## and large NEXT right.  They are presentation-only.
const HUD_RECT := Rect2(24.0, 42.0, 672.0, 266.0)
const SCORE_PANEL_RECT := Rect2(38.0, 48.0, 174.0, 136.0)
const NEXT_PREVIEW_RECT := Rect2(510.0, 48.0, 178.0, 158.0)
const PROGRESSION_START_X := 252.0
const PROGRESSION_STEP_X := 56.0
const PROGRESSION_Y := 111.0
const PROGRESSION_SLOT_RADIUS := 23.0
const PROGRESSION_PREVIEW_BOUNDS := Vector2(37.0, 37.0)
const TARGET_PANEL_RECT := Rect2(253.0, 188.0, 214.0, 110.0)
const TARGET_HEADER_RECT := Rect2(262.0, 188.0, 196.0, 52.0)
const TARGET_BODY_RECT := Rect2(253.0, 222.0, 214.0, 74.0)
## The supplied L7/L8 artwork is intentionally allowed to use the generous
## cream portion of the GOAL card.  This is a presentation-only contain box:
## every source aspect ratio remains intact and no circular mask is applied.
const TARGET_PREVIEW_BOUNDS := Vector2(54.0, 50.0)
const RESTART_BUTTON_RECT := Rect2(472.0, 231.0, 138.0, 46.0)
const SETTINGS_BUTTON_RECT := Rect2(620.0, 206.0, 88.0, 88.0)
const TARGET_COLLECTION_DESTINATION := Vector2(360.0, 259.0)
const OVERLAY_RECT := Rect2(76.0, 398.0, 568.0, 484.0)
const SAFE_VISUAL_MARGIN := 24.0
const TARGET_LEVEL := 5
## Catalog-only extension. The baseline launcher, target, queue and HUD remain
## unchanged; this bounds merge eligibility for manually created higher tiers.
const MAX_GEM_LEVEL := 18
const DANGER_GRACE_DURATION := 0.75 # default 0.75 s; safe 0.65–0.90
const MERGE_COIN_REWARD_BY_RESULT_LEVEL := {
	2: 10,
	3: 25,
	4: 60,
	5: 150,
	6: 350,
	7: 800,
	8: 1800,
}
## Compatibility alias for older tests/tools. Production presents this exact
## confirmed-event value as run coins, not an abstract score.
const MERGE_SCORE_BY_RESULT_LEVEL := MERGE_COIN_REWARD_BY_RESULT_LEVEL
## Feedback routing is presentation-only. Values are safe for short Android UI
## cues and never feed simulation, score, or lifecycle code.
const AUDIO_SAMPLE_RATE := 22050.0
const AUDIO_MAX_CONCURRENT_PLAYERS := 3
const AUDIO_AMBIENCE_DURATION := 6.0
const AUDIO_AMBIENCE_VOLUME := 0.34
const GEM_CONTACT_SOUND_THRESHOLD := 170.0
const WALL_CONTACT_SOUND_THRESHOLD := 220.0
const CONTACT_SOUND_COOLDOWN := 0.075
const AUDIO_COOLDOWN_BY_EVENT := {
	"gem_contact": CONTACT_SOUND_COOLDOWN, "wall_contact": 0.11, "launch": 0.05, "merge_2": 0.04, "merge_3": 0.04,
	"merge_4": 0.03, "merge_5": 0.03, "merge_6": 0.03, "merge_7": 0.03, "merge_8": 0.03, "chain": 0.04, "win": 0.25,
	"target_collect": 0.16, "fail": 0.25, "button": 0.05,
	"coin_burst": 0.08, "coin_flight": 0.20, "coin_collect": 0.05,
}
const AUDIO_TONES := {
	"launch": {"frequency": 640.0, "duration": 0.075, "volume": 0.48, "brightness": 0.38, "fall": 0.78},
	"gem_contact": {"frequency": 1240.0, "duration": 0.055, "volume": 0.46, "brightness": 0.82, "fall": 0.64},
	"wall_contact": {"frequency": 760.0, "duration": 0.065, "volume": 0.32, "brightness": 0.34, "fall": 0.58},
	"merge_2": {"frequency": 740.0, "duration": 0.14, "volume": 0.56, "brightness": 0.60, "fall": 1.16},
	"merge_3": {"frequency": 880.0, "duration": 0.15, "volume": 0.60, "brightness": 0.68, "fall": 1.20},
	"merge_4": {"frequency": 1046.0, "duration": 0.16, "volume": 0.65, "brightness": 0.76, "fall": 1.24},
	"merge_5": {"frequency": 1318.0, "duration": 0.19, "volume": 0.70, "brightness": 0.88, "fall": 1.30},
	"merge_6": {"frequency": 1480.0, "duration": 0.24, "volume": 0.75, "brightness": 0.90, "fall": 1.32},
	"merge_7": {"frequency": 1661.0, "duration": 0.27, "volume": 0.80, "brightness": 0.92, "fall": 1.34},
	"merge_8": {"frequency": 1760.0, "duration": 0.30, "volume": 0.85, "brightness": 0.94, "fall": 1.36},
	"chain": {"frequency": 1568.0, "duration": 0.13, "volume": 0.70, "brightness": 0.92, "fall": 1.24},
	"target_collect": {"frequency": 1760.0, "duration": 0.22, "volume": 0.82, "brightness": 0.94, "fall": 1.34},
	"win": {"frequency": 1318.0, "duration": 0.34, "volume": 0.90, "brightness": 0.96, "fall": 1.55},
	"fail": {"frequency": 523.0, "duration": 0.24, "volume": 0.58, "brightness": 0.33, "fall": 0.56},
	"button": {"frequency": 1180.0, "duration": 0.04, "volume": 0.30, "brightness": 0.55, "fall": 0.84},
	"coin_burst": {"frequency": 820.0, "duration": 0.15, "volume": 0.72, "brightness": 0.88, "fall": 1.18},
	"coin_flight": {"frequency": 1160.0, "duration": 0.18, "volume": 0.42, "brightness": 0.70, "fall": 0.92},
	"coin_collect": {"frequency": 1760.0, "duration": 0.085, "volume": 0.58, "brightness": 0.96, "fall": 1.42},
}
const HAPTICS_BY_EVENT := {
	"launch": {"duration_ms": 18, "amplitude": 0.22},
	"merge": {"duration_ms": 30, "amplitude": 0.48},
	"major_merge": {"duration_ms": 42, "amplitude": 0.66},
	"chain": {"duration_ms": 46, "amplitude": 0.72},
	"target_collect": {"duration_ms": 52, "amplitude": 0.78},
	"win": {"duration_ms": 90, "amplitude": 1.0},
	"fail": {"duration_ms": 70, "amplitude": 0.82},
	"coin_collect": {"duration_ms": 16, "amplitude": 0.20},
}

static func merge_coin_reward_for_result_level(level: int) -> int:
	return int(MERGE_COIN_REWARD_BY_RESULT_LEVEL.get(level, 0))

static func merge_score_for_result_level(level: int) -> int:
	return merge_coin_reward_for_result_level(level)

static func gem_name(level: int) -> String:
	return AssetCatalog.gem_name(level)

static func gem_collision_radius(level: int) -> float:
	return float(GEM_COLLISION_RADIUS.get(level, PIECE_RADIUS))

static func gem_color(level: int) -> Color:
	match level:
		1: return Color("f6ead0")
		2: return Color("20242d")
		3: return Color("20ae79")
		4: return Color("55c7e8")
		5: return Color("b7d93a")
		6: return Color("e8549a")
		7: return Color("c8324c")
		8: return Color("4f70dc")
		_: return Color.WHITE

static func configure_portrait_bottom(viewport_height: float) -> void:
	viewport_center_offset_x = 0.0
	portrait_bottom_offset_y = maxf(0.0, viewport_height - VIEWPORT_SIZE.y)


static func configure_viewport(viewport_size: Vector2) -> void:
	viewport_center_offset_x = maxf(0.0, (viewport_size.x - VIEWPORT_SIZE.x) * 0.5)
	portrait_bottom_offset_y = maxf(0.0, viewport_size.y - VIEWPORT_SIZE.y)


static func table_center_x() -> float:
	return TABLE_TEXTURE_CENTER.x + viewport_center_offset_x


static func table_texture_center() -> Vector2:
	return TABLE_TEXTURE_CENTER + Vector2(viewport_center_offset_x, portrait_bottom_offset_y)

static func board_top() -> float:
	return BOARD_TOP + portrait_bottom_offset_y

static func board_bottom() -> float:
	return BOARD_BOTTOM + portrait_bottom_offset_y

static func danger_line_y() -> float:
	return DANGER_LINE_Y + portrait_bottom_offset_y

static func launch_y() -> float:
	return LAUNCH_Y + portrait_bottom_offset_y

static func table_interpolation(y_position: float) -> float:
	return inverse_lerp(board_top(), board_bottom(), clampf(y_position, board_top(), board_bottom()))

static func gem_perspective_scale_at(y_position: float) -> float:
	return lerpf(GEM_PERSPECTIVE_SCALE_BACK, GEM_PERSPECTIVE_SCALE_FRONT, table_interpolation(y_position))

static func gem_visual_scale_at(_level: int, y_position: float) -> float:
	return gem_perspective_scale_at(y_position)

static func gem_visual_z_index(piece_id: int, y_position: float) -> int:
	# Larger local Y is closer to the player and must draw above smaller local Y.
	# The stable piece ID breaks exact-Y ties without allocating/reparenting nodes.
	var y_bucket := int(round(table_interpolation(y_position) * GEM_VISUAL_Z_BUCKETS))
	return y_bucket * GEM_VISUAL_Z_TIE_STRIDE + posmod(piece_id, GEM_VISUAL_Z_TIE_STRIDE)

static func table_left_at(y_position: float) -> float:
	return viewport_center_offset_x + lerpf(TABLE_INNER_LEFT_TOP, TABLE_INNER_LEFT_BOTTOM, table_interpolation(y_position))

static func table_right_at(y_position: float) -> float:
	return viewport_center_offset_x + lerpf(TABLE_INNER_RIGHT_TOP, TABLE_INNER_RIGHT_BOTTOM, table_interpolation(y_position))

static func table_playable_width_at(y_position: float) -> float:
	return table_right_at(y_position) - table_left_at(y_position)


static func vertical_lane_top_y(x_position: float, radius: float = 0.0) -> float:
	# Find the first vertical point where the requested X (plus its optional
	# body margin) fits inside both sloped rails. Aim guides and launcher lanes
	# use this same authoritative geometry instead of escaping through the top.
	var top := board_top()
	var bottom := board_bottom()
	var left_top := table_left_at(top) + radius
	var right_top := table_right_at(top) - radius
	if x_position >= left_top and x_position <= right_top:
		return top
	var denominator := TABLE_INNER_LEFT_TOP - TABLE_INNER_LEFT_BOTTOM
	if x_position < left_top:
		var left_t := (TABLE_INNER_LEFT_TOP + viewport_center_offset_x + radius - x_position) / maxf(0.001, denominator)
		return lerpf(top, bottom, clampf(left_t, 0.0, 1.0))
	var right_t := (x_position - (TABLE_INNER_RIGHT_TOP + viewport_center_offset_x - radius)) / maxf(0.001, denominator)
	return lerpf(top, bottom, clampf(right_t, 0.0, 1.0))
