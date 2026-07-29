class_name GameConfig
extends RefCounted

const VIEWPORT_SIZE := Vector2(720.0, 1280.0)
const BOARD_LEFT := 56.0
const BOARD_RIGHT := 664.0
const BOARD_TOP := 150.0
const BOARD_BOTTOM := 1170.0
const DANGER_LINE_Y := 1010.0
const LAUNCH_Y := 1100.0
const PIECE_RADIUS := 35.0
# Gameplay balance v1 — all feel values live here. Keep simulation delta-based.
# The default/range notes are the approved safe tuning envelope for this prototype.
const DRAG_HIT_RADIUS_MULTIPLIER := 1.8 # default 1.8; safe 1.5–2.0
const LAUNCH_SPEED := 1100.0 # default 1100 px/s; safe 1000–1180
const VELOCITY_DAMPING_PER_SECOND := 285.0 # default 285 px/s²; safe 250–330
const SLEEP_SPEED := 9.0 # default 9 px/s; safe 7–12
const SIDE_WALL_RESTITUTION := 0.20 # default 0.20; safe 0.15–0.25
const TOP_WALL_RESTITUTION := 0.14 # default 0.14; safe 0.10–0.20
const BOTTOM_WALL_RESTITUTION := 0.10 # default 0.10; safe 0.08–0.14
const COLLISION_RESTITUTION := 0.48 # equal-mass normal impulse; safe 0.40–0.58
const CONTACT_EPSILON := 1.5
const SEPARATION_EPSILON := 0.15 # default 0.15 px; safe 0.10–0.30
const MERGE_PRESENTATION_DURATION := 0.20 # default 0.20 s; safe 0.16–0.26
const MERGE_SOURCE_PULL_DURATION := 0.10 # default 0.10 s; safe 0.08–0.14
const MERGE_PULSE_SCALE := 1.22 # default 1.22; safe 1.15–1.30
const CHAIN_PRESENTATION_STAGGER := 0.07 # default 0.07 s; safe 0.05–0.10
const NEXT_LAUNCHER_READY_DELAY := 0.08 # default 0.08 s; safe 0.05–0.12
const MERGE_CHAIN_DEPTH_CAP := 6
const RESTART_RECT := Rect2(520.0, 58.0, 150.0, 54.0)
const OVERLAY_BUTTON_RECT := Rect2(220.0, 770.0, 280.0, 64.0)
const OVERLAY_FADE_DURATION := 0.18
## Rendering-only layout values. These never feed simulation or collision geometry.
const HUD_RECT := Rect2(30.0, 20.0, 660.0, 112.0)
const HUD_PRIMARY_RECT := Rect2(44.0, 36.0, 300.0, 42.0)
const HUD_SECONDARY_RECT := Rect2(44.0, 84.0, 452.0, 34.0)
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
