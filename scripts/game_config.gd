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
const LAUNCH_SPEED := 1050.0
const LINEAR_DAMPING := 2.7
const SLEEP_SPEED := 11.0
const CONTACT_EPSILON := 1.5
const SEPARATION_EPSILON := 0.25
const MERGE_PRESENTATION_DURATION := 0.22
const MERGE_SOURCE_PULL_DURATION := 0.12
const MERGE_PULSE_SCALE := 1.28
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
const DANGER_GRACE_DURATION := 0.75
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
