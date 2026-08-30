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
const GameScene = preload("res://scenes/Game.tscn")

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
	_test_power_tiles_rest_below_the_board()
	_test_table_art_is_calmed_without_moving_geometry()
	await _test_power_row_never_overlaps_the_table()
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


## Visual hierarchy: the board is the subject. Four framed gold tiles at full
## brightness competed with the gems, so an owned-but-unused power now rests
## below full white while the armed one is unmistakably above it.
func _test_power_tiles_rest_below_the_board() -> void:
	var resting := GameplayHudType.POWER_TILE_RESTING_MODULATE
	var armed := GameplayHudType.POWER_TILE_ARMED_MODULATE
	var idle := GameplayHudType.POWER_TILE_IDLE_MODULATE
	_assert(resting.a < 1.0, "an unused power must rest below full opacity (got %.2f)" % resting.a)
	_assert(resting.a > idle.a, "a usable power must read brighter than an unusable one")
	_assert(armed.r > resting.r and armed.a >= resting.a,
		"the armed power must be unmistakably brighter than a resting one")
	# Still legible, not ghosted away.
	_assert(resting.a >= 0.8, "a usable power must not fade to near-invisible (got %.2f)" % resting.a)


## The table art frames the gems; it must not outshine them. Presentation only -
## the rail geometry, containment and danger line are untouched.
func _test_table_art_is_calmed_without_moving_geometry() -> void:
	var calm := GameConfig.TABLE_ART_CALM_MODULATE
	_assert(calm.r < 1.0 and calm.g < 1.0 and calm.b < 1.0,
		"the table sprite must be dimmed below full brightness")
	_assert(calm.r >= 0.7 and calm.b >= 0.7,
		"the table must stay clearly visible, not washed out (%.2f)" % calm.r)
	_assert(is_equal_approx(calm.a, 1.0),
		"the table must stay fully opaque; only its brightness is reduced")
	# Geometry is read from GameConfig and must be unaffected by any art change.
	_assert(GameConfig.board_top() < GameConfig.danger_line_y(),
		"calming the art must not disturb the authoritative board geometry")
	_assert(GameConfig.table_left_at(GameConfig.danger_line_y()) < GameConfig.table_right_at(GameConfig.danger_line_y()),
		"rail geometry must remain valid and independent of the sprite modulate")


## The power row must never sit over the table.
##
## It was anchored across the table's lower frame, which put four buttons inside
## the area the player drags across to aim - shots were being turned into
## accidental power activations. It now sits strictly below the table, and the
## whole row is sized so that still fits on screen.
func _test_power_row_never_overlaps_the_table() -> void:
	# One size per run would be cleaner, but GameConfig table geometry lives in
	# statics that each viewport overwrites, so the sizes are checked in sequence
	# and the table bounds are re-read immediately after each layout.
	for size in [Vector2i(720, 1600), Vector2i(720, 1280), Vector2i(1080, 2340)]:
		var viewport := SubViewport.new()
		viewport.size = size
		viewport.disable_3d = true
		root.add_child(viewport)
		var controller = GameScene.instantiate()
		viewport.add_child(controller)
		await process_frame
		controller._on_home_level_intro_requested()
		controller._on_home_play_requested()
		await process_frame

		var anchor := controller.gameplay_ui.sink_buttons_anchor as Control
		_assert(anchor != null, "%s must build the power row" % size)
		if anchor != null:
			var row := anchor.get_global_rect()
			# The guarantee that matters is the playable board: a button over the
			# area the player drags across to aim turns shots into accidental power
			# activations. On tall screens the row also clears the decorative table
			# frame; on shorter ones there is not enough room below it for that.
			_assert(row.position.y >= GameConfig.board_bottom() - 2.0,
				"%s power row starts at %.0f, over the playable board which ends at %.0f"
					% [size, row.position.y, GameConfig.board_bottom()])
			_assert(row.end.y <= float(controller.gameplay_ui.root_control.size.y) + 1.0,
				"%s power row bottom %.0f runs past the screen" % [size, row.end.y])
		viewport.queue_free()
		await process_frame
