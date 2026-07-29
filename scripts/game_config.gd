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
const SOUND_TOGGLE_RECT := Rect2(584.0, 94.0, 48.0, 28.0)
const VIBRATION_TOGGLE_RECT := Rect2(638.0, 94.0, 48.0, 28.0)
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
## Feedback routing is presentation-only. Values are safe for short Android UI
## cues and never feed simulation, score, or lifecycle code.
const AUDIO_SAMPLE_RATE := 22050.0
const AUDIO_MAX_CONCURRENT_PLAYERS := 3
const COLLISION_SOUND_THRESHOLD := 170.0
const AUDIO_COOLDOWN_BY_EVENT := {
	"collision": 0.09, "launch": 0.04, "merge_2": 0.03, "merge_3": 0.03,
	"merge_4": 0.03, "merge_5": 0.03, "chain": 0.04, "win": 0.25,
	"fail": 0.25, "button": 0.05,
}
const AUDIO_TONES := {
	"launch": {"frequency": 380.0, "sweep": 1.55, "duration": 0.07, "volume": 0.38},
	"collision": {"frequency": 220.0, "sweep": 0.75, "duration": 0.05, "volume": 0.25},
	"merge_2": {"frequency": 520.0, "sweep": 1.20, "duration": 0.10, "volume": 0.36},
	"merge_3": {"frequency": 610.0, "sweep": 1.25, "duration": 0.11, "volume": 0.38},
	"merge_4": {"frequency": 720.0, "sweep": 1.30, "duration": 0.12, "volume": 0.40},
	"merge_5": {"frequency": 880.0, "sweep": 1.40, "duration": 0.16, "volume": 0.44},
	"chain": {"frequency": 980.0, "sweep": 1.35, "duration": 0.08, "volume": 0.32},
	"win": {"frequency": 740.0, "sweep": 1.65, "duration": 0.22, "volume": 0.48},
	"fail": {"frequency": 260.0, "sweep": 0.55, "duration": 0.20, "volume": 0.42},
	"button": {"frequency": 460.0, "sweep": 1.08, "duration": 0.04, "volume": 0.24},
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

static func gem_color(level: int) -> Color:
	match level:
		1: return Color("f6ead0")
		2: return Color("d84355")
		3: return Color("20ae79")
		4: return Color("2e83e6")
		5: return Color("c8efff")
		_: return Color.WHITE
