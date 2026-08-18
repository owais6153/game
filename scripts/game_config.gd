class_name GameConfig
extends RefCounted

const VIEWPORT_SIZE := Vector2(720.0, 1280.0)
## Authoritative table layout. The supplied table is a trapezoid, so the same
## rail model is consumed by Sprite2D placement, collision containment, drag
## clamps, launcher spawn, and danger-line drawing.
## The reference composition reserves a compact utility row plus a visible
## Target/path stack above the table. The table remains the dominant center
## surface and every visual/physics landmark is transformed together.
const TABLE_LAYOUT_BASE_TOP := 400.0
const TABLE_LAYOUT_BASE_BOTTOM := 1185.0
const TABLE_TEXTURE_CENTER := Vector2(360.0, 792.5)
const TABLE_TEXTURE_SIZE := Vector2(920.0, 810.0)
const TABLE_TEXTURE_RENDER_SCALE := Vector2(0.7391304, 0.9691358)
const BOARD_LEFT := 0.0
const BOARD_RIGHT := 720.0
const TABLE_BOTTOM_ALIGNMENT_DELTA_Y := 0.0
const BOARD_TOP := 440.0
const BOARD_BOTTOM := 1110.0
const TABLE_INNER_LEFT_TOP := 188.0
const TABLE_INNER_LEFT_BOTTOM := 62.0
const TABLE_INNER_RIGHT_TOP := 532.0
const TABLE_INNER_RIGHT_BOTTOM := 658.0
const DANGER_LINE_Y := 960.0
const DANGER_LINE_COLOR := Color("e85f52")
## Presentation-only guide/warning values. They never enter input, collision,
## overflow detection, timing, or solver decisions.
const AIM_GUIDE_WIDTH := 2.0
const AIM_GUIDE_ALPHA := 0.44
const AIM_GUIDE_TOUCH_HALF_WIDTH := 28.0
const DANGER_WARNING_NEAR_DISTANCE := 76.0
const DANGER_WARNING_PULSE_HZ := 1.65
const LAUNCH_Y := 1042.0
## Expanded portrait screens distribute extra height between the scenery above
## the table and a bounded vertical table stretch. The complete table model is
## transformed together; HUD geometry remains presentation-only and independent.
const TABLE_EXTRA_TOP_OFFSET_SHARE := 0.40
const TABLE_TALL_SCALE_MAX := 1.22
const TABLE_TALL_SCALE_REFERENCE_EXTRA := 320.0
static var portrait_bottom_offset_y := 0.0
static var viewport_center_offset_x := 0.0
static var table_vertical_scale_y := 1.0
## Largest active gameplay radius. L1-L8 keep a controlled three-pixel step,
## with a larger readable L1 baseline and a bounded 1.583x L8/L1 endpoint.
const PIECE_RADIUS := 57.0
## One authoritative radius drives both the alpha-trimmed visual body and its
## simple circle collider. Gold rims, glows, shadows and transparent texture
## padding never add collision size. L9-L18 remain outside the current level
## and retain their earlier 42px fallback. Values stay fixed for a lifetime.
const GEM_COLLISION_RADIUS := {1: 36.0, 2: 39.0, 3: 42.0, 4: 45.0, 5: 48.0, 6: 51.0, 7: 54.0, 8: 57.0, 9: 42.0, 10: 42.0, 11: 42.0, 12: 42.0, 13: 42.0, 14: 42.0, 15: 42.0, 16: 42.0, 17: 42.0, 18: 42.0}
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
const GEM_SHADOW_OPACITY := {1: 0.32, 2: 0.32, 3: 0.32, 4: 0.32, 5: 0.32, 6: 0.32, 7: 0.32, 8: 0.32, 9: 0.32, 10: 0.32, 11: 0.32, 12: 0.32, 13: 0.32, 14: 0.32, 15: 0.32, 16: 0.32, 17: 0.32, 18: 0.32}
const GEM_SHADOW_WIDTH_MULTIPLIER := 0.92
const GEM_SHADOW_HEIGHT_MULTIPLIER := 0.38
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
const LAUNCH_SPEED := 1200.0 # fast-feel pass: top of previously approved 1120–1200 range
const VELOCITY_DAMPING_PER_SECOND := 195.0 # quicker settle after the faster launch; prior range 175–205
const SLEEP_SPEED := 10.0 # snappier handoff while staying inside prior stable-settle range 8–11
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
const MAX_SIMULATION_SUBSTEPS := 8
const MAX_SUBSTEP_RADIUS_FRACTION := 0.45 # swept-step guard; never changes contact distance
## Presentation-only reward cadence. Physics, colliders, contact eligibility,
## momentum, score values, and launcher handoff are intentionally unaffected.
const MERGE_PRESENTATION_DURATION := 0.27
const MERGE_SOURCE_PULL_DURATION := 0.06
const MERGE_RESULT_START_SCALE := 0.64
const MERGE_RESULT_POP_SCALE := 1.26
const MERGE_RESULT_POP_DURATION := 0.14
const MERGE_PULSE_SCALE := 1.22
const COLLISION_VISUAL_DURATION := 0.11
const COLLISION_VISUAL_MAX_COMPRESSION := 0.055
const COLLISION_VISUAL_COOLDOWN := 0.10
const SCORE_POPUP_DURATION := 0.46
const SCORE_POPUP_RISE := 36.0
const MAJOR_REWARD_TIER := 6
const MAJOR_MERGE_EFFECT_DURATION := 0.36
const MAJOR_SCORE_POPUP_DURATION := 0.78
const MAJOR_SCORE_POPUP_RISE := 58.0
const MAJOR_MERGE_EFFECT_SCALE := 1.18
const MAJOR_MERGE_SPARK_COUNT := 12
## The supplied reference visibly uses four rigid coin tokens. They form one
## compact cluster, then travel as one readable staggered group to the HUD.
const COIN_BURST_COUNT := 4
const MAJOR_COIN_BURST_COUNT := 4
const COIN_BURST_DURATION := 0.12
const COIN_FLIGHT_DURATION := 0.54
const MAJOR_COIN_FLIGHT_DURATION := 0.60
const COIN_FLIGHT_STAGGER := 0.045
const COIN_SPAWN_STAGGER := 0.015
const COIN_BURST_RADIUS := 48.0
const MAJOR_COIN_BURST_RADIUS := 52.0
const COIN_DRAW_RADIUS := 17.0
const COIN_COUNTER_PULSE_DURATION := 0.18
const COIN_EFFECT_LIMIT := 32
const COIN_HUD_FALLBACK_DESTINATION := Vector2(92.0, 78.0)
const TARGET_COLLECTION_DURATION := 0.32
const TARGET_COLLECTION_FADE_START := 0.88
const TARGET_COLLECTION_POP_SCALE := 1.24
const TARGET_PANEL_PULSE_DURATION := 0.38
const TARGET_SWAP_START_DELAY := 0.12
const TARGET_SWAP_OUTGOING_FADE_DURATION := 0.10
const TARGET_SWAP_GAP_DURATION := 0.02
const TARGET_SWAP_INCOMING_FADE_DURATION := 0.12
const TARGET_SWAP_OUTGOING_OFFSET := Vector2.ZERO
const TARGET_SWAP_INCOMING_OFFSET := Vector2.ZERO
const TARGET_SWAP_INCOMING_SCALE := 1.0
const PRESENTATION_EVENT_TRACE_LIMIT := 128
const MERGE_MOMENTUM_TRANSFER := 0.62 # bounded average of source momentum
const MERGE_MAX_SPAWN_SPEED := 420.0 # prevents an upgrade from shooting through a cluster
const CHAIN_PRESENTATION_STAGGER := 0.03 # faster visual cadence only; merge logic remains immediate
const NEXT_LAUNCHER_READY_DELAY := 0.02
## A released gem gives the launcher lane time to clear, then becomes a normal
## simulation body even if contacts keep it moving. This bounds replacement
## latency on crowded boards without changing any motion or collision value.
const LAUNCHER_HANDOFF_DELAY := 0.22
const MERGE_CHAIN_DEPTH_CAP := 6
const OVERLAY_BUTTON_RECT := Rect2(220.0, 770.0, 280.0, 64.0)
const OVERLAY_FADE_DURATION := 0.14
const RESULT_BACKDROP_OPACITY := 0.48
const WIN_PRESENTATION_HOLD := 0.24
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
const TARGET_COLLECTION_DESTINATION := Vector2(360.0, 82.0)
const OVERLAY_RECT := Rect2(76.0, 398.0, 568.0, 484.0)
const SAFE_VISUAL_MARGIN := 24.0
const TARGET_LEVEL := 5
## Catalog-only extension. The baseline launcher, target, queue and HUD remain
## unchanged; this bounds merge eligibility for manually created higher tiers.
const MAX_GEM_LEVEL := 18
const DANGER_GRACE_DURATION := 0.75 # default 0.75 s; safe 0.65–0.90
## These values are awarded only when a confirmed result fulfills the active
## target. Ordinary merges advance the board without changing run coins.
const TARGET_COIN_REWARD_BY_RESULT_LEVEL := {
	2: 10,
	3: 25,
	4: 60,
	5: 150,
	6: 350,
	7: 800,
	8: 1800,
}
## Compatibility aliases for older tools. Production calls the target-named
## accessor so reward ownership stays explicit.
const MERGE_COIN_REWARD_BY_RESULT_LEVEL := TARGET_COIN_REWARD_BY_RESULT_LEVEL
const MERGE_SCORE_BY_RESULT_LEVEL := TARGET_COIN_REWARD_BY_RESULT_LEVEL
## Feedback routing is presentation-only. Only the explicitly approved contact,
## normal-merge, UI, and win events use supplied replacements; all other event
## identities retain the established procedural or approved supplied cues.
const AUDIO_MAX_CONCURRENT_PLAYERS := 5
const AUDIO_SAMPLE_RATE := 22050.0
## Corrective mix v2: raised moderately from 0.035 while remaining below the
## original 0.10 service gain and below gameplay feedback.
const AUDIO_MUSIC_VOLUME := 0.06
const AUDIO_TONES := {
	"launch": {"frequency": 640.0, "duration": 0.075, "volume": 0.48, "brightness": 0.38, "fall": 0.78},
	"gem_contact": {"volume": 0.23},
	"wall_contact": {"volume": 0.24},
	"normal_merge": {"volume": 0.70},
	"merge_2": {"frequency": 740.0, "duration": 0.14, "volume": 0.56, "brightness": 0.60, "fall": 1.16},
	"merge_3": {"frequency": 880.0, "duration": 0.15, "volume": 0.60, "brightness": 0.68, "fall": 1.20},
	"merge_4": {"frequency": 1046.0, "duration": 0.16, "volume": 0.65, "brightness": 0.76, "fall": 1.24},
	"merge_5": {"frequency": 1318.0, "duration": 0.19, "volume": 0.70, "brightness": 0.88, "fall": 1.30},
	"merge_6": {"frequency": 1480.0, "duration": 0.24, "volume": 0.75, "brightness": 0.90, "fall": 1.32},
	"merge_7": {"frequency": 1661.0, "duration": 0.27, "volume": 0.80, "brightness": 0.92, "fall": 1.34},
	"merge_8": {"frequency": 1760.0, "duration": 0.30, "volume": 0.85, "brightness": 0.94, "fall": 1.36},
	"chain": {"frequency": 1568.0, "duration": 0.13, "volume": 0.70, "brightness": 0.92, "fall": 1.24},
	"target_collect": {"frequency": 1046.0, "duration": 0.48, "volume": 0.82, "brightness": 0.46, "fall": 0.82},
	"target_complete": {"volume": 0.78},
	"coin_tick": {"frequency": 1244.0, "duration": 0.09, "volume": 0.38, "brightness": 0.34, "fall": 1.18},
	"coin_reward": {"volume": 0.72},
	"win": {"volume": 0.92},
	"button": {"volume": 0.32},
}
const GEM_CONTACT_SOUND_THRESHOLD := 182.5
const WALL_CONTACT_SOUND_THRESHOLD := 235.0
const CONTACT_SOUND_COOLDOWN := 0.0925
const PER_CONTACT_SOUND_COOLDOWN := 0.12
const AUDIO_COOLDOWN_BY_EVENT := {
	"gem_contact": CONTACT_SOUND_COOLDOWN,
	"wall_contact": 0.115,
	"launch": 0.05,
	"normal_merge": 0.04,
	"merge_2": 0.04,
	"merge_3": 0.04,
	"merge_4": 0.03,
	"merge_5": 0.03,
	"merge_6": 0.03,
	"merge_7": 0.03,
	"merge_8": 0.03,
	"chain": 0.04,
	"target_collect": 0.16,
	"target_complete": 0.30,
	"coin_tick": 0.07,
	"coin_reward": 0.20,
	"win": 0.25,
	"button": 0.08,
}
const AUDIO_PITCH_RANGE_BY_EVENT := {
	"gem_contact": Vector2(0.95, 1.02),
	"wall_contact": Vector2(0.95, 1.01),
}
const AUDIO_PRIORITY_BY_EVENT := {
	"button": 10,
	"wall_contact": 20,
	"gem_contact": 30,
	"launch": 40,
	"target_collect": 50,
	"coin_tick": 55,
	"coin_reward": 60,
	"target_complete": 85,
	"normal_merge": 70,
	"merge_2": 70,
	"merge_3": 71,
	"merge_4": 72,
	"merge_5": 73,
	"merge_6": 74,
	"merge_7": 75,
	"merge_8": 76,
	"chain": 75,
	"win": 100,
}
## Compatibility only for the retired extracted-event service. Production
## does not route these reference slices to movement, contact, or rewards.
const AUDIO_EVENT_VOLUME := {
	"launch": 1.0,
	"gem_contact": 1.0,
	"wall_contact": 0.86,
	"merge_reward": 1.0,
	"target_reward": 1.0,
	"fail": 0.86,
	"button": 0.78,
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
	return target_coin_reward_for_result_level(level)

static func target_coin_reward_for_result_level(level: int) -> int:
	return int(TARGET_COIN_REWARD_BY_RESULT_LEVEL.get(level, 0))

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
	_configure_table_height(viewport_height)


static func configure_viewport(viewport_size: Vector2) -> void:
	viewport_center_offset_x = maxf(0.0, (viewport_size.x - VIEWPORT_SIZE.x) * 0.5)
	_configure_table_height(viewport_size.y)


static func _configure_table_height(viewport_height: float) -> void:
	var extra_height := maxf(0.0, viewport_height - VIEWPORT_SIZE.y)
	portrait_bottom_offset_y = extra_height * TABLE_EXTRA_TOP_OFFSET_SHARE
	var tall_t := clampf(extra_height / TABLE_TALL_SCALE_REFERENCE_EXTRA, 0.0, 1.0)
	table_vertical_scale_y = lerpf(1.0, TABLE_TALL_SCALE_MAX, tall_t)


static func table_center_x() -> float:
	return TABLE_TEXTURE_CENTER.x + viewport_center_offset_x


static func table_texture_center() -> Vector2:
	return Vector2(table_center_x(), _table_y(TABLE_TEXTURE_CENTER.y))


static func table_texture_render_scale() -> Vector2:
	return Vector2(TABLE_TEXTURE_RENDER_SCALE.x, TABLE_TEXTURE_RENDER_SCALE.y * table_vertical_scale_y)


static func table_outer_top() -> float:
	return _table_y(TABLE_LAYOUT_BASE_TOP)


static func table_outer_bottom() -> float:
	return _table_y(TABLE_LAYOUT_BASE_BOTTOM)

static func board_top() -> float:
	return _table_y(BOARD_TOP)

static func board_bottom() -> float:
	return _table_y(BOARD_BOTTOM)

static func danger_line_y() -> float:
	return _table_y(DANGER_LINE_Y)

static func launch_y() -> float:
	return _table_y(LAUNCH_Y)


static func _table_y(base_y: float) -> float:
	return TABLE_LAYOUT_BASE_TOP + portrait_bottom_offset_y + (base_y - TABLE_LAYOUT_BASE_TOP) * table_vertical_scale_y

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

static func launcher_drag_x(requested_x: float, y_position: float, radius: float) -> float:
	return clampf(requested_x, table_left_at(y_position) + radius, table_right_at(y_position) - radius)

static func aim_guide_contains(pointer: Vector2, active_position: Vector2, active_radius: float) -> bool:
	var lane_top := vertical_lane_top_y(active_position.x, 5.0)
	var start_y := lane_top + 10.0
	var finish_y := active_position.y - active_radius - 10.0
	if start_y >= finish_y - 8.0:
		return false
	return absf(pointer.x - active_position.x) <= AIM_GUIDE_TOUCH_HALF_WIDTH and pointer.y >= start_y and pointer.y <= finish_y


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
