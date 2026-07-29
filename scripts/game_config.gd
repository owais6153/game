class_name GameConfig
extends RefCounted

const VIEWPORT_SIZE := Vector2(720.0, 1280.0)
## Authoritative table layout. The supplied table is a trapezoid, so the same
## rail model is consumed by Sprite2D placement, collision containment, drag
## clamps, launcher spawn, and danger-line drawing.
const TABLE_TEXTURE_CENTER := Vector2(360.0, 650.0)
const TABLE_TEXTURE_SIZE := Vector2(1024.0, 1536.0)
const BOARD_LEFT := 0.0
const BOARD_RIGHT := 720.0
const BOARD_TOP := 224.0
const BOARD_BOTTOM := 1080.0
## Shallower top anchors match the calibrated runtime table derivative and the
## tropical camera better than the original aggressive trapezoid.
const TABLE_INNER_LEFT_TOP := 90.0
const TABLE_INNER_RIGHT_TOP := 630.0
const TABLE_INNER_LEFT_BOTTOM := 0.0
const TABLE_INNER_RIGHT_BOTTOM := 720.0
const DANGER_LINE_Y := 926.0
const LAUNCH_Y := 1008.0
## Largest gameplay radius. Individual values are calibrated to the visible
## main body of the alpha-trimmed runtime texture for each gem level.
const PIECE_RADIUS := 42.0
const GEM_COLLISION_RADIUS := {1: 42.0, 2: 42.0, 3: 32.0, 4: 42.0, 5: 33.0}
const VISIBLE_CONTACT_TOLERANCE := 1.0
# Gameplay balance v1 — all feel values live here. Keep simulation delta-based.
# The default/range notes are the approved safe tuning envelope for this prototype.
const DRAG_HIT_RADIUS_MULTIPLIER := 1.8 # default 1.8; safe 1.5–2.0
const LAUNCH_SPEED := 1160.0 # approved parity range 1120–1200
const VELOCITY_DAMPING_PER_SECOND := 235.0 # approved parity range 210–260
const SLEEP_SPEED := 11.0 # approved parity range 9–13
const SIDE_WALL_RESTITUTION := 0.16 # approved parity range 0.12–0.20
const TOP_WALL_RESTITUTION := 0.10 # approved parity range 0.08–0.14
const BOTTOM_WALL_RESTITUTION := 0.08 # approved parity range 0.06–0.12
const COLLISION_RESTITUTION := 0.34 # equal-mass normal impulse; approved parity range 0.28–0.42
const COLLISION_TANGENTIAL_FRICTION := 0.18 # contact-only rolling resistance; approved range 0.12–0.24
const MAX_PIECE_SPEED := 1200.0 # containment guard; preserves natural launch/collision speed
const CONTACT_EPSILON := 0.75
const SEPARATION_EPSILON := 0.10 # smaller correction avoids visible collision snapping
const MERGE_PRESENTATION_DURATION := 0.18 # shorter total presentation reduces dead time
const MERGE_SOURCE_PULL_DURATION := 0.11 # source convergence remains visible but soft
const MERGE_PULSE_SCALE := 1.18 # a compact bounce rather than an oversized pop
const MERGE_MOMENTUM_TRANSFER := 0.35 # bounded average of source momentum
const MERGE_MAX_SPAWN_SPEED := 260.0 # prevents an upgrade from shooting through a cluster
const CHAIN_PRESENTATION_STAGGER := 0.05 # visual cadence only; merge logic remains immediate
const NEXT_LAUNCHER_READY_DELAY := 0.04 # only after settled board and presentations complete
const MERGE_CHAIN_DEPTH_CAP := 6
const RESTART_RECT := Rect2(584.0, 42.0, 102.0, 48.0)
const SOUND_TOGGLE_RECT := Rect2(584.0, 94.0, 48.0, 28.0)
const VIBRATION_TOGGLE_RECT := Rect2(638.0, 94.0, 48.0, 28.0)
const OVERLAY_BUTTON_RECT := Rect2(220.0, 770.0, 280.0, 64.0)
const OVERLAY_FADE_DURATION := 0.18
## Rendering-only layout values. These never feed simulation or collision geometry.
const HUD_RECT := Rect2(20.0, 20.0, 680.0, 142.0)
const CURRENT_PREVIEW_RECT := Rect2(184.0, 28.0, 118.0, 52.0)
const NEXT_PREVIEW_RECT := Rect2(310.0, 28.0, 118.0, 52.0)
const PROGRESSION_START_X := 448.0
const PROGRESSION_STEP_X := 27.0
const PROGRESSION_Y := 54.0
const OVERLAY_RECT := Rect2(76.0, 398.0, 568.0, 484.0)
const SAFE_VISUAL_MARGIN := 24.0
const TARGET_LEVEL := 5
const DANGER_GRACE_DURATION := 0.75 # default 0.75 s; safe 0.65–0.90
const MERGE_SCORE_BY_RESULT_LEVEL := {
	2: 10,
	3: 25,
	4: 60,
	5: 150,
}
## Feedback routing is presentation-only. Values are safe for short Android UI
## cues and never feed simulation, score, or lifecycle code.
const AUDIO_SAMPLE_RATE := 22050.0
const AUDIO_MAX_CONCURRENT_PLAYERS := 3
const GEM_CONTACT_SOUND_THRESHOLD := 220.0
const WALL_CONTACT_SOUND_THRESHOLD := 290.0
const CONTACT_SOUND_COOLDOWN := 0.075
const AUDIO_COOLDOWN_BY_EVENT := {
	"gem_contact": CONTACT_SOUND_COOLDOWN, "wall_contact": 0.11, "launch": 0.05, "merge_2": 0.04, "merge_3": 0.04,
	"merge_4": 0.03, "merge_5": 0.03, "chain": 0.04, "win": 0.25,
	"fail": 0.25, "button": 0.05,
}
const AUDIO_TONES := {
	"launch": {"frequency": 640.0, "duration": 0.075, "volume": 0.18, "brightness": 0.38, "fall": 0.78},
	"gem_contact": {"frequency": 1240.0, "duration": 0.055, "volume": 0.17, "brightness": 0.82, "fall": 0.64},
	"wall_contact": {"frequency": 760.0, "duration": 0.065, "volume": 0.11, "brightness": 0.34, "fall": 0.58},
	"merge_2": {"frequency": 740.0, "duration": 0.14, "volume": 0.25, "brightness": 0.60, "fall": 1.16},
	"merge_3": {"frequency": 880.0, "duration": 0.15, "volume": 0.27, "brightness": 0.68, "fall": 1.20},
	"merge_4": {"frequency": 1046.0, "duration": 0.16, "volume": 0.29, "brightness": 0.76, "fall": 1.24},
	"merge_5": {"frequency": 1318.0, "duration": 0.19, "volume": 0.31, "brightness": 0.88, "fall": 1.30},
	"chain": {"frequency": 1568.0, "duration": 0.11, "volume": 0.18, "brightness": 0.92, "fall": 1.24},
	"win": {"frequency": 1318.0, "duration": 0.30, "volume": 0.34, "brightness": 0.96, "fall": 1.55},
	"fail": {"frequency": 523.0, "duration": 0.22, "volume": 0.18, "brightness": 0.33, "fall": 0.56},
	"button": {"frequency": 1180.0, "duration": 0.04, "volume": 0.10, "brightness": 0.55, "fall": 0.84},
}
const HAPTICS_BY_EVENT := {
	"launch": {"duration_ms": 18, "amplitude": 0.22},
	"merge": {"duration_ms": 30, "amplitude": 0.48},
	"chain": {"duration_ms": 46, "amplitude": 0.72},
	"win": {"duration_ms": 90, "amplitude": 1.0},
	"fail": {"duration_ms": 70, "amplitude": 0.82},
}

static func merge_score_for_result_level(level: int) -> int:
	return int(MERGE_SCORE_BY_RESULT_LEVEL.get(level, 0))

static func gem_name(level: int) -> String:
	match level:
		1: return "Pearl"
		2: return "Ruby"
		3: return "Emerald"
		4: return "Sapphire"
		5: return "Diamond"
		_: return "Unknown"

static func gem_collision_radius(level: int) -> float:
	return float(GEM_COLLISION_RADIUS.get(level, PIECE_RADIUS))

static func gem_color(level: int) -> Color:
	match level:
		1: return Color("f6ead0")
		2: return Color("d84355")
		3: return Color("20ae79")
		4: return Color("2e83e6")
		5: return Color("c8efff")
		_: return Color.WHITE

static func table_interpolation(y_position: float) -> float:
	return inverse_lerp(BOARD_TOP, BOARD_BOTTOM, clampf(y_position, BOARD_TOP, BOARD_BOTTOM))

static func table_left_at(y_position: float) -> float:
	return lerpf(TABLE_INNER_LEFT_TOP, TABLE_INNER_LEFT_BOTTOM, table_interpolation(y_position))

static func table_right_at(y_position: float) -> float:
	return lerpf(TABLE_INNER_RIGHT_TOP, TABLE_INNER_RIGHT_BOTTOM, table_interpolation(y_position))

static func table_playable_width_at(y_position: float) -> float:
	return table_right_at(y_position) - table_left_at(y_position)
