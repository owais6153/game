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
const RESTART_RECT := Rect2(520.0, 58.0, 150.0, 54.0)

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