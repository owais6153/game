class_name GameConfig
extends RefCounted

const VIEWPORT_SIZE := Vector2(720.0, 1280.0)
const BOARD_LEFT := 30.0
const BOARD_RIGHT := 690.0
const BOARD_TOP := 144.0
const BOARD_BOTTOM := 1166.0
const DANGER_LINE_Y := 1006.0
const LAUNCH_Y := 1102.0
const PIECE_RADIUS := 42.0
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
const CONTACT_EPSILON := 1.5
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
const OVERLAY_BUTTON_RECT := Rect2(220.0, 770.0, 280.0, 64.0)
const OVERLAY_FADE_DURATION := 0.18
## Rendering-only layout values. These never feed simulation or collision geometry.
const HUD_RECT := Rect2(20.0, 14.0, 680.0, 116.0)
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

static func gem_color(level: int) -> Color:
	match level:
		1: return Color("f6ead0")
		2: return Color("d84355")
		3: return Color("20ae79")
		4: return Color("2e83e6")
		5: return Color("c8efff")
		_: return Color.WHITE
