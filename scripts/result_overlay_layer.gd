class_name ResultOverlayLayer
extends CanvasLayer

const AssetCatalogType = preload("res://scripts/asset_catalog.gd")
const ScoreFormatterType = preload("res://scripts/score_formatter.gd")
const UiDesignSystemType = preload("res://scripts/ui_design_system.gd")
const ICON_RETRY = preload("res://assets/runtime/ui/icons/restart_white.svg")
const ICON_HOME = preload("res://assets/runtime/ui/icons/home_navy.svg")

signal retry_requested
signal collect_requested
signal double_coins_requested
signal home_requested
signal reward_animation_finished

## Dedicated result UI. It owns only its backdrop and panel; gameplay roots,
## gem sprites, simulation state, and reward timing are never modified here.
var visible_result := false
var result_won := false
var result_score := 0
var level_reward := 0
var present_count := 0

var root_control: Control
var dimmer: ColorRect
var safe_margin: MarginContainer
var panel: PanelContainer
var title_label: Label
var celebration_label: Label
var subtitle_label: Label
var result_icon: TextureRect
var fail_badge: PanelContainer
var score_label: Label
var transition_label: Label
var retry_button: Button
var double_button: Button
var home_button: Button
var _rewarded_available := false
var _actions_pending := false
var _reward_resolved := false
var _reward_doubled := false
var _double_request_in_flight := false
var _displayed_total := 0
var _total_tween: Tween
var _entrance_tween: Tween
var _safe_insets_override := Vector4(-1.0, -1.0, -1.0, -1.0)


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_refresh_safe_margins()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_refresh_safe_margins):
		viewport.size_changed.connect(_refresh_safe_margins)


func _unhandled_input(event: InputEvent) -> void:
	# Result actions are explicit buttons. Consume Android Back/Escape while the
	# modal is present so a completed/failed run cannot exit accidentally.
	if visible_result and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if get_viewport() != null:
			get_viewport().set_input_as_handled()


func present(won: bool, score: int, level_number: int = 1, result_tier: int = 8, level_reward_amount: int = 0, rewarded_available: bool = false) -> bool:
	_build_ui()
	if visible_result:
		return false
	visible_result = true
	result_won = won
	result_score = score
	level_reward = maxi(0, level_reward_amount)
	_displayed_total = maxi(0, score - level_reward) if won else score
	_rewarded_available = rewarded_available
	_actions_pending = false
	_reward_resolved = false
	_reward_doubled = false
	_double_request_in_flight = false
	present_count += 1
	title_label.text = "LEVEL COMPLETE" if won else "TRY AGAIN"
	celebration_label.visible = won
	subtitle_label.text = "LEVEL %d COMPLETE" % level_number if won else "THE TABLE REACHED THE DANGER LINE"
	result_icon.visible = won
	result_icon.texture = AssetCatalogType.gem_texture(result_tier) if won else null
	fail_badge.visible = not won
	_refresh_reward_copy()
	transition_label.text = "LEVEL %d  →  LEVEL %d" % [level_number, level_number + 1] if won else "LEVEL %d • READY TO RETRY" % level_number
	retry_button.text = "COLLECT" if won else "RETRY"
	retry_button.icon = null if won else ICON_RETRY
	retry_button.tooltip_text = "Collect this level's coins" if won else "Retry Level %d" % level_number
	double_button.visible = won
	double_button.tooltip_text = "Watch a rewarded ad to double this level's coins" if rewarded_available else "Rewarded ad unavailable; Collect still works"
	_refresh_action_state()
	root_control.visible = true
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	_start_entrance()
	if retry_button.is_inside_tree():
		retry_button.grab_focus()
	return true


func dismiss() -> void:
	visible_result = false
	_actions_pending = false
	_kill_total_tween()
	_kill_entrance_tween()
	if root_control != null:
		root_control.visible = false
		root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if panel != null:
		panel.scale = Vector2.ONE
		panel.modulate = Color.WHITE
	if dimmer != null:
		dimmer.color = UiDesignSystemType.COLOR_OVERLAY


func set_safe_insets_for_testing(insets: Vector4) -> void:
	_safe_insets_override = insets
	_refresh_safe_margins()


func layout_metrics() -> Dictionary:
	_build_ui()
	return {
		"panel": panel.get_global_rect(),
		"button": retry_button.get_global_rect(),
		"double_button": double_button.get_global_rect(),
		"icon": result_icon.get_global_rect(),
		"fail_badge": fail_badge.get_global_rect(),
	}


func _build_ui() -> void:
	if root_control != null:
		return
	root_control = Control.new()
	root_control.name = "ResultOverlayRoot"
	root_control.theme = UiDesignSystemType.theme()
	root_control.visible = false
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer = ColorRect.new()
	dimmer.name = "ResultDimmer"
	dimmer.color = UiDesignSystemType.COLOR_OVERLAY
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(dimmer)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_margin = MarginContainer.new()
	safe_margin.name = "ResultSafeArea"
	safe_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(safe_margin)
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.name = "ResultCenter"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_margin.add_child(center)

	# Results deliberately use the exact same frosted-glass modal language as
	# Pause and Home Settings. Win/fail changes content, never the shell styling.
	panel = PanelContainer.new()
	panel.name = "ResultPanel"
	panel.custom_minimum_size = Vector2(520.0, 690.0)
	panel.add_theme_stylebox_override("panel", UiDesignSystemType.gameplay_modal_panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "ResultContentMargin"
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 34)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.name = "ResultContent"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)

	title_label = _label("LEVEL COMPLETE", UiDesignSystemType.POPUP_TITLE_FONT_SIZE, UiDesignSystemType.COLOR_BLUE_DEEP)
	title_label.name = "ResultTitle"
	title_label.custom_minimum_size = Vector2(0.0, 58.0)
	title_label.add_theme_constant_override("outline_size", 5)
	title_label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.92))
	column.add_child(title_label)

	celebration_label = _label("✦", 22, UiDesignSystemType.COLOR_BLUE)
	celebration_label.name = "CelebrationAccents"
	celebration_label.custom_minimum_size = Vector2(0.0, 24.0)
	column.add_child(celebration_label)

	subtitle_label = _label("LEVEL COMPLETE", 16, UiDesignSystemType.COLOR_TEXT_MUTED)
	subtitle_label.name = "ResultSubtitle"
	subtitle_label.custom_minimum_size = Vector2(0.0, 36.0)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(subtitle_label)

	var art_slot := CenterContainer.new()
	art_slot.name = "ResultArtSlot"
	art_slot.custom_minimum_size = Vector2(132.0, 132.0)
	art_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(art_slot)

	var icon_aspect := AspectRatioContainer.new()
	icon_aspect.name = "ResultGemSlot"
	icon_aspect.custom_minimum_size = Vector2(118.0, 118.0)
	icon_aspect.ratio = 1.0
	icon_aspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_slot.add_child(icon_aspect)
	result_icon = TextureRect.new()
	result_icon.name = "ResultGem"
	result_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_aspect.add_child(result_icon)

	fail_badge = PanelContainer.new()
	fail_badge.name = "FailBadge"
	fail_badge.custom_minimum_size = Vector2(104.0, 104.0)
	fail_badge.add_theme_stylebox_override("panel", UiDesignSystemType.level_badge_style())
	fail_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_slot.add_child(fail_badge)
	var fail_mark := _label("!", 58, UiDesignSystemType.COLOR_BLUE_DEEP)
	fail_mark.name = "FailMark"
	fail_mark.add_theme_constant_override("outline_size", 0)
	fail_badge.add_child(fail_mark)
	fail_badge.visible = false

	var reward_card := PanelContainer.new()
	reward_card.name = "ResultRewardCard"
	reward_card.custom_minimum_size = Vector2(424.0, 74.0)
	reward_card.add_theme_stylebox_override("panel", UiDesignSystemType.home_status_card_style())
	reward_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(reward_card)
	score_label = _label("COINS  0", 20, UiDesignSystemType.COLOR_BLUE_DEEP)
	score_label.name = "ResultScore"
	score_label.custom_minimum_size = Vector2(0.0, 66.0)
	reward_card.add_child(score_label)

	transition_label = _label("LEVEL 1  →  LEVEL 2", 16, UiDesignSystemType.COLOR_TEXT_MUTED)
	transition_label.name = "ResultTransition"
	transition_label.custom_minimum_size = Vector2(0.0, 32.0)
	column.add_child(transition_label)

	var action_row := HBoxContainer.new()
	action_row.name = "ResultActionRow"
	action_row.custom_minimum_size = Vector2(424.0, 82.0)
	action_row.add_theme_constant_override("separation", 12)
	action_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(action_row)

	retry_button = Button.new()
	retry_button.name = "ResultActionButton"
	retry_button.text = "COLLECT"
	retry_button.custom_minimum_size = Vector2(206.0, 82.0)
	retry_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retry_button.focus_mode = Control.FOCUS_ALL
	retry_button.expand_icon = false
	retry_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	retry_button.mouse_filter = Control.MOUSE_FILTER_STOP
	retry_button.pressed.connect(_on_action_pressed)
	_wire_button_motion(retry_button)
	action_row.add_child(retry_button)

	double_button = Button.new()
	double_button.name = "ResultDoubleCoinsButton"
	double_button.text = "DOUBLE COINS"
	double_button.custom_minimum_size = Vector2(206.0, 82.0)
	double_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	double_button.focus_mode = Control.FOCUS_ALL
	double_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	double_button.mouse_filter = Control.MOUSE_FILTER_STOP
	double_button.pressed.connect(_on_double_pressed)
	_wire_button_motion(double_button)
	action_row.add_child(double_button)

	home_button = Button.new()
	home_button.name = "ResultHomeButton"
	home_button.text = "HOME"
	home_button.icon = ICON_HOME
	home_button.expand_icon = false
	home_button.theme_type_variation = "SecondaryButton"
	home_button.custom_minimum_size = Vector2(424.0, 72.0)
	home_button.focus_mode = Control.FOCUS_ALL
	home_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	home_button.mouse_filter = Control.MOUSE_FILTER_STOP
	home_button.pressed.connect(func() -> void: home_requested.emit())
	_wire_button_motion(home_button)
	column.add_child(home_button)

func _on_action_pressed() -> void:
	if _actions_pending:
		return
	if result_won:
		if not _reward_resolved:
			_actions_pending = true
			_refresh_action_state()
			collect_requested.emit()
	else:
		retry_requested.emit()


func _on_double_pressed() -> void:
	if not result_won or _actions_pending or _reward_resolved or _double_request_in_flight or not _rewarded_available:
		return
	_double_request_in_flight = true
	double_coins_requested.emit()


func set_rewarded_available(available: bool) -> void:
	_rewarded_available = available
	if double_button != null:
		double_button.tooltip_text = "Watch a rewarded ad to double this level's coins" if available else "Rewarded ad unavailable; Collect still works"
	_refresh_action_state()


func set_actions_pending(pending: bool) -> void:
	_actions_pending = pending
	if not pending and not _reward_resolved:
		_double_request_in_flight = false
	_refresh_action_state()


func resolve_reward(updated_score: int, doubled: bool) -> void:
	if _reward_resolved:
		return
	_reward_resolved = true
	_reward_doubled = doubled
	_double_request_in_flight = false
	result_score = updated_score
	_animate_reward_resolution(updated_score, doubled)
	_refresh_action_state()


func _refresh_reward_copy() -> void:
	if score_label == null:
		return
	if result_won:
		var shown_reward := level_reward * (2 if _reward_doubled else 1)
		var reward_copy := "REWARD +%s" % ScoreFormatterType.format(shown_reward)
		if _reward_resolved:
			reward_copy += "  COLLECTED"
		score_label.text = "%s  |  TOTAL %s" % [reward_copy, ScoreFormatterType.format(_displayed_total)]
	else:
		score_label.text = "COINS  %s" % ScoreFormatterType.format(result_score)


func _refresh_action_state() -> void:
	if retry_button == null or double_button == null or home_button == null:
		return
	retry_button.disabled = _actions_pending
	home_button.disabled = _actions_pending
	double_button.disabled = _actions_pending or not _rewarded_available or _reward_resolved
	double_button.visible = result_won and not _reward_resolved
	if _reward_resolved:
		retry_button.text = "COLLECTED"
		retry_button.icon = null
		retry_button.visible = false
	elif result_won:
		retry_button.text = "COLLECT"
		retry_button.icon = null
		retry_button.visible = true
	else:
		retry_button.visible = true
	if _reward_doubled:
		double_button.text = "DOUBLED"
	elif _rewarded_available:
		double_button.text = "DOUBLE COINS"
	else:
		double_button.text = "AD UNAVAILABLE"


func _animate_reward_resolution(target: int, doubled: bool) -> void:
	_kill_total_tween()
	var start := _displayed_total
	_total_tween = create_tween()
	_total_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if doubled:
		_reward_doubled = false
		celebration_label.text = "Ã—2"
		celebration_label.visible = true
		celebration_label.pivot_offset = _node_center(celebration_label)
		celebration_label.scale = Vector2.ONE * 0.55
		celebration_label.modulate.a = 0.0
		_total_tween.tween_property(celebration_label, "scale", Vector2.ONE * 1.18, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_total_tween.parallel().tween_property(celebration_label, "modulate:a", 1.0, 0.10)
		_total_tween.tween_interval(0.08)
		_total_tween.tween_callback(func() -> void:
			_reward_doubled = true
			_refresh_reward_copy()
		)
	else:
		_reward_doubled = false
		celebration_label.text = "âœ¦"
	_total_tween.tween_method(func(value: float) -> void:
		_displayed_total = int(round(value))
		_refresh_reward_copy()
	, float(start), float(target), 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_total_tween.tween_callback(func() -> void:
		_displayed_total = target
		_refresh_reward_copy()
		score_label.pivot_offset = _node_center(score_label)
		score_label.scale = Vector2.ONE * 1.08
	)
	_total_tween.tween_property(score_label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_total_tween.tween_callback(func() -> void: reward_animation_finished.emit())


func _kill_total_tween() -> void:
	if _total_tween != null and _total_tween.is_valid():
		_total_tween.kill()
	_total_tween = null


func _start_entrance() -> void:
	_kill_entrance_tween()
	panel.pivot_offset = _node_center(panel)
	if not is_inside_tree():
		panel.scale = Vector2.ONE
		panel.modulate = Color.WHITE
		dimmer.color = UiDesignSystemType.COLOR_OVERLAY
		return
	panel.scale = Vector2.ONE * 0.90
	panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	dimmer.color = Color(UiDesignSystemType.COLOR_OVERLAY.r, UiDesignSystemType.COLOR_OVERLAY.g, UiDesignSystemType.COLOR_OVERLAY.b, 0.0)
	_entrance_tween = create_tween().set_parallel(true)
	_entrance_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_entrance_tween.tween_property(panel, "scale", Vector2.ONE, UiDesignSystemType.POPUP_ENTER_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_entrance_tween.tween_property(panel, "modulate:a", 1.0, UiDesignSystemType.POPUP_ENTER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_entrance_tween.tween_property(dimmer, "color:a", UiDesignSystemType.COLOR_OVERLAY.a, UiDesignSystemType.POPUP_ENTER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if result_won:
		title_label.pivot_offset = _node_center(title_label)
		result_icon.pivot_offset = _node_center(result_icon)
		title_label.scale = Vector2.ONE * 0.82
		result_icon.scale = Vector2.ONE * 0.72
		result_icon.modulate = Color(1.18, 1.18, 1.18, 0.0)
		_entrance_tween.tween_property(title_label, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_entrance_tween.tween_property(result_icon, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.04)
		_entrance_tween.tween_property(result_icon, "modulate", Color.WHITE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(0.04)


func _refresh_safe_margins() -> void:
	if safe_margin == null or not is_inside_tree():
		return
	var insets := _safe_insets()
	safe_margin.add_theme_constant_override("margin_left", int(ceil(maxf(16.0, insets.x + UiDesignSystemType.SAFE_INSET_PADDING))))
	safe_margin.add_theme_constant_override("margin_top", int(ceil(maxf(16.0, insets.y + UiDesignSystemType.SAFE_INSET_PADDING))))
	safe_margin.add_theme_constant_override("margin_right", int(ceil(maxf(16.0, insets.z + UiDesignSystemType.SAFE_INSET_PADDING))))
	safe_margin.add_theme_constant_override("margin_bottom", int(ceil(maxf(16.0, insets.w + UiDesignSystemType.SAFE_INSET_PADDING))))


func _safe_insets() -> Vector4:
	if _safe_insets_override.x >= 0.0:
		return _safe_insets_override
	if get_viewport() != get_tree().root:
		return Vector4.ZERO
	return UiDesignSystemType.safe_insets(get_viewport().get_visible_rect().size, Vector2(DisplayServer.window_get_size()), DisplayServer.get_display_safe_area())


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UiDesignSystemType.font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.78))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _wire_button_motion(button: BaseButton) -> void:
	if button == null:
		return
	button.button_down.connect(func() -> void:
		button.pivot_offset = button.size * 0.5
		var global_tweens := get_node_or_null("/root/GlobalTweens")
		if global_tweens != null:
			global_tweens.call("button_press", button, 0.055)
	)


func _node_center(control: Control) -> Vector2:
	var node_size := control.size
	if node_size == Vector2.ZERO:
		node_size = control.custom_minimum_size
	return node_size * 0.5


func _kill_entrance_tween() -> void:
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()
