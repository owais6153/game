extends SceneTree

## Measures rendered geometry rather than trusting configured values.
##
## The settings gear shipped visibly off-centre twice. Both times the numbers
## looked right: Godot lays a Button out as icon + text and reserves
## `h_separation` even when the text is empty, so `Button.icon` draws left of
## centre. Nothing in the old configuration exposed that - only the rendered
## rect does, which is what this suite checks.

const GameplayHudType = preload("res://scripts/ui/gameplay_hud_layer.gd")
const HomeOverlayType = preload("res://scripts/ui/home_overlay_layer.gd")
const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")

## Tighter than a pixel of rounding, looser than sub-pixel layout noise.
const CENTRE_TOLERANCE := 1.5
## The glyph must keep a visible ring of plate on every side, and must not be
## so small that the control reads as empty.
const MIN_PADDING_RATIO := 0.12
const MAX_PADDING_RATIO := 0.36

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_gameplay_settings_icon_is_centred()
	await _test_home_settings_icon_is_centred()
	await _test_no_hud_button_uses_a_bare_icon()
	if failures.is_empty():
		print("HUD_ALIGNMENT_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("HUD_ALIGNMENT_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


func _test_gameplay_settings_icon_is_centred() -> void:
	var hud := GameplayHudType.new()
	root.add_child(hud)
	await process_frame
	await process_frame
	_assert_centred(hud.settings_button, "gameplay settings")
	hud.queue_free()
	await process_frame


func _test_home_settings_icon_is_centred() -> void:
	var home := HomeOverlayType.new()
	root.add_child(home)
	await process_frame
	home.present(1, 0, {})
	await process_frame
	await process_frame
	_assert_centred(home.settings_button, "Home settings")
	home.queue_free()
	await process_frame


## An icon-only Button with `Button.icon` set is the exact defect. Catch it
## anywhere in the HUD, not just on the control that was reported.
func _test_no_hud_button_uses_a_bare_icon() -> void:
	var hud := GameplayHudType.new()
	root.add_child(hud)
	await process_frame
	for node in hud.root_control.find_children("*", "Button", true, false):
		var button := node as Button
		if button == null or button.icon == null:
			continue
		_assert(not button.text.is_empty(),
			"%s is icon-only via Button.icon, which draws off-centre; use centre_icon_in_button" % button.name)
	hud.queue_free()
	await process_frame


func _assert_centred(button: Button, label: String) -> void:
	if button == null:
		_assert(false, "%s button must exist" % label)
		return
	var icon := button.find_child("CentredIcon", true, false) as TextureRect
	if icon == null:
		_assert(false, "%s must place its glyph as a centred child, not Button.icon" % label)
		return
	var button_rect := button.get_global_rect()
	var icon_rect := icon.get_global_rect()
	_assert(button_rect.size.x > 0.0 and icon_rect.size.x > 0.0,
		"%s must have a laid-out rect to measure" % label)
	if button_rect.size.x <= 0.0 or icon_rect.size.x <= 0.0:
		return

	var offset := icon_rect.get_center() - button_rect.get_center()
	_assert(absf(offset.x) <= CENTRE_TOLERANCE,
		"%s glyph is %.1fpx off-centre horizontally" % [label, offset.x])
	_assert(absf(offset.y) <= CENTRE_TOLERANCE,
		"%s glyph is %.1fpx off-centre vertically" % [label, offset.y])

	# Even padding on every side, and enough of it to read as a framed control.
	var left := icon_rect.position.x - button_rect.position.x
	var right := button_rect.end.x - icon_rect.end.x
	var top := icon_rect.position.y - button_rect.position.y
	var bottom := button_rect.end.y - icon_rect.end.y
	_assert(absf(left - right) <= CENTRE_TOLERANCE and absf(top - bottom) <= CENTRE_TOLERANCE,
		"%s padding is uneven (l=%.1f r=%.1f t=%.1f b=%.1f)" % [label, left, right, top, bottom])
	var ratio := left / maxf(1.0, button_rect.size.x)
	_assert(ratio >= MIN_PADDING_RATIO and ratio <= MAX_PADDING_RATIO,
		"%s padding ratio %.2f is outside the readable range %.2f-%.2f"
			% [label, ratio, MIN_PADDING_RATIO, MAX_PADDING_RATIO])


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
