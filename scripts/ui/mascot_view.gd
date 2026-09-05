class_name MascotView
extends Control

## The crowned-gem mascot, played as a mood dial rather than as a clip.
##
## The art is two eight-frame tracks that both begin on the same idle pose:
## frame 1 is neutral, frame 8 is the extreme. Callers do not pick a frame or
## start a clip - they set a mood and an intensity, and the view glides to it:
##
##   merge          happy 0.35
##   combo          happy 0.70
##   level won      happy 1.00
##   level failed   sad   1.00
##   level start    idle
##
## Two things make eight frames read as animation rather than as a slideshow.
##
## First, the position along a track is a float that is *eased* toward its
## target, so a jump from idle to "happiest" travels through every pose between
## instead of cutting. Second, the two frames either side of that float are
## cross-faded: the lower frame is drawn opaque and the upper one over it at the
## fractional alpha. Drawing both semi-transparent would be the obvious way and
## is wrong - the gold ring is identical in every frame, and two half-opaque
## copies leave it 75% opaque, so the whole mascot visibly dims mid-blend.

const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")

const MOOD_IDLE := "idle"
const MOOD_HAPPY := "happy"
const MOOD_SAD := "sad"

const FRAME_COUNT := 12

## How fast the dial travels, in track units per second. Tuned so idle to
## happiest takes a little under half a second: fast enough to feel like a
## reaction, slow enough that every frame is seen.
const GLIDE_SPEED := 2.15
## Below this the mascot is treated as idle, so a decayed reaction settles on
## the neutral pose rather than hovering a hair above it forever.
const IDLE_EPSILON := 0.004

## Idle breathing. Presentation only, and deliberately small - the mascot sits
## next to live gameplay and must never pull the eye away from the board.
##
## Switched off in popups via `breathing_enabled`: a popup already arrives on its
## own scale tween, and a second independent bounce on top of it reads as the
## mascot wobbling rather than as the popup landing.
const BREATH_PERIOD := 2.6
const BREATH_SCALE := 0.022
const BREATH_BOB := 0.010

static var _frames_cache: Dictionary = {}

## Where the dial is going, and where it is now.
var _mood := MOOD_HAPPY
var _target := 0.0
var _position := 0.0
var _breath := 0.0
## Set while a reaction is decaying back to idle on its own.
var _decay_delay := 0.0
## Popups turn this off. See the note on BREATH_PERIOD.
var breathing_enabled := true
## A mood change requested while the mascot was mid-expression, applied once the
## rewind to neutral lands.
var _pending_mood := ""
var _pending_intensity := 0.0
var _pending_hold := 0.0

signal reached_target


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_frames()
	set_process(true)


## Frames are shared across every mascot on screen - the HUD, a popup and the
## level screen can all be alive at once - so they are loaded once per run.
static func _load_frames() -> void:
	if not _frames_cache.is_empty():
		return
	for mood in [MOOD_HAPPY, MOOD_SAD]:
		var frames: Array[Texture2D] = []
		for index in range(1, FRAME_COUNT + 1):
			var path := "res://assets/runtime/character/mascot_%s_%d.png" % [mood, index]
			var texture: Texture2D = load(path)
			if texture == null:
				push_warning("MascotView: missing frame %s" % path)
				continue
			frames.append(texture)
		_frames_cache[mood] = frames


## The mascot's whole public surface. `intensity` runs 0 (idle) to 1 (extreme).
##
## `hold` is how long the reaction sits at full before falling back to idle by
## itself; 0 means it stays until something else changes it. Gameplay beats pass
## a hold so the mascot returns to neutral between merges, while a result popup
## passes none because the expression is the point of the screen.
func set_mood(mood: String, intensity: float, hold: float = 0.0, immediate: bool = false) -> void:
	var resolved := mood
	if mood == MOOD_IDLE or intensity <= 0.0:
		# Idle is not a third track, it is the neutral end of whichever track is
		# already showing. Switching tracks to reach neutral would cut the face.
		resolved = _mood
		intensity = 0.0
	if resolved != _mood:
		# A mood flip only cuts when the mascot is already at or near neutral,
		# where the two tracks share a pose. Mid-expression it rewinds through
		# neutral first, so happy never snaps straight to sad.
		if _position > IDLE_EPSILON and not immediate:
			_pending_mood = resolved
			_pending_intensity = intensity
			_pending_hold = hold
			_target = 0.0
			return
		_mood = resolved
	_target = clampf(intensity, 0.0, 1.0)
	_decay_delay = hold
	if immediate:
		_position = _target
	queue_redraw()

## Convenience for the neutral pose, used by the level-start screen.
func show_idle(immediate: bool = false) -> void:
	set_mood(MOOD_IDLE, 0.0, 0.0, immediate)


func current_frame() -> float:
	return _position * float(FRAME_COUNT - 1)


func current_mood() -> String:
	return _mood


func _process(delta: float) -> void:
	_breath = fmod(_breath + delta, BREATH_PERIOD)
	var moved := false

	if _decay_delay > 0.0 and is_equal_approx(_position, _target) and _target > 0.0:
		_decay_delay -= delta
		if _decay_delay <= 0.0:
			_target = 0.0

	if not is_equal_approx(_position, _target):
		var step := GLIDE_SPEED * delta
		_position = move_toward(_position, _target, step)
		moved = true
		if is_equal_approx(_position, _target):
			if _position <= IDLE_EPSILON and not _pending_mood.is_empty():
				# The rewind to neutral has landed, so the queued mood can take
				# over without the face ever cutting.
				_mood = _pending_mood
				_target = clampf(_pending_intensity, 0.0, 1.0)
				_decay_delay = _pending_hold
				_pending_mood = ""
			else:
				reached_target.emit()

	if moved or _breathing():
		queue_redraw()


## Breathing is only worth a redraw while the mascot is settled; during a glide
## the animation is already redrawing every frame.
func _breathing() -> bool:
	return breathing_enabled and is_visible_in_tree()


func _draw() -> void:
	var frames: Array = _frames_cache.get(_mood, [])
	if frames.is_empty():
		return
	var exact := current_frame()
	var lower := clampi(int(floor(exact)), 0, frames.size() - 1)
	var upper := clampi(lower + 1, 0, frames.size() - 1)
	var blend := clampf(exact - float(lower), 0.0, 1.0)

	var scale := 1.0
	var bob := 0.0
	if breathing_enabled:
		var phase := _breath / BREATH_PERIOD * TAU
		scale = 1.0 + sin(phase) * BREATH_SCALE
		bob = sin(phase * 2.0) * BREATH_BOB

	var edge := minf(size.x, size.y) * scale
	var centre := size * 0.5 + Vector2(0.0, bob * edge)
	var rect := Rect2(centre - Vector2(edge, edge) * 0.5, Vector2(edge, edge))

	# Base opaque, overlay at the fractional alpha. See the note at the top of
	# this file for why both are not simply drawn semi-transparent.
	draw_texture_rect(frames[lower], rect, false)
	if upper != lower and blend > 0.0:
		draw_texture_rect(frames[upper], rect, false, Color(1.0, 1.0, 1.0, blend))


## Rewinds to neutral and plays out to `intensity` in one call.
##
## Popups use this rather than `set_mood(..., immediate)`. Setting the mood
## immediately is what made the result screen appear with the expression already
## finished - there was nothing left to animate. Starting from frame 1 every time
## the popup opens guarantees the idle-to-happy or idle-to-sad run is actually
## seen, and seen from the beginning even if the previous popup left the mascot
## halfway up the other track.
func play_from_idle(mood: String, intensity: float) -> void:
	_pending_mood = ""
	_mood = mood if mood != MOOD_IDLE else _mood
	_position = 0.0
	_target = clampf(intensity, 0.0, 1.0)
	_decay_delay = 0.0
	queue_redraw()
