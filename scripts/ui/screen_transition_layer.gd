class_name ScreenTransitionLayer
extends CanvasLayer

## Shared screen-to-screen transition. Navigation used to be an instant cut,
## which made every hand-off between Home, gameplay, and the result overlays
## read as a jump rather than a move.
##
## Presentation only. The swap is applied synchronously on the calling frame and
## only the reveal is animated, so navigation stays readable to its callers.
## Simulation, merge, launcher, and collision state are untouched here.

## Above every gameplay and popup layer (HUD 40, Result 50, Home 60, Daily 65)
## so the cover is never partially occluded by the screens it is hiding.
const TRANSITION_LAYER := 90

const COVER_HOLD := 0.04
const COVER_OUT := 0.30

signal transition_covered
signal transition_finished

var cover: ColorRect
var _tween: Tween
var _busy := false


func _ready() -> void:
	layer = TRANSITION_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func is_busy() -> bool:
	return _busy


func _build() -> void:
	if cover != null:
		return
	cover = ColorRect.new()
	cover.name = "ScreenTransitionCover"
	cover.color = Color(0.055, 0.014, 0.10, 1.0)
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Fully transparent and click-through until a transition actually runs;
	# a cover that swallows input while idle would silently break the game.
	cover.modulate = Color(1.0, 1.0, 1.0, 0.0)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.visible = false
	add_child(cover)


## Applies `swap` immediately, then reveals the new screen from behind the cover.
##
## The swap is deliberately synchronous. An earlier version deferred it to the
## covered midpoint of a fade-out/fade-in, which turned every navigation call
## into an async operation: callers (and three test suites) could no longer read
## `app_flow_state` after asking to navigate. Screen state must settle on the
## calling frame; only the reveal is animated.
##
## Safe to call with an invalid callable; the cover still resolves so a
## presentation failure can never strand the player behind an opaque screen.
func play(swap: Callable = Callable()) -> void:
	_build()
	if swap.is_valid():
		swap.call()
	_kill()
	_busy = true
	cover.visible = true
	# The cover is above everything, so it must never take input even mid-reveal.
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.modulate.a = 1.0
	transition_covered.emit()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_tween.tween_interval(COVER_HOLD)
	_tween.tween_property(cover, "modulate:a", 0.0, COVER_OUT)
	_tween.tween_callback(func() -> void:
		cover.visible = false
		_busy = false
		transition_finished.emit())


## Immediately clears any in-flight cover. Used when the tree is reset.
func reset() -> void:
	_kill()
	_busy = false
	if cover != null:
		cover.visible = false
		cover.modulate.a = 0.0
		cover.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _kill() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
