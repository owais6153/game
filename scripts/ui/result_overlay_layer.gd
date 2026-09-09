class_name ResultOverlayLayer
extends CanvasLayer

const AssetCatalogType = preload("res://scripts/core/asset_catalog.gd")
const ScoreFormatterType = preload("res://scripts/core/score_formatter.gd")
const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")
const CoinIconType = preload("res://scripts/presentation/coin_icon.gd")
const UiKitType = preload("res://scripts/ui/ui_kit.gd")
const MascotViewType = preload("res://scripts/ui/mascot_view.gd")
const StarRowType = preload("res://scripts/presentation/star_row.gd")
const LevelStarsType = preload("res://scripts/core/level_stars.gd")

## Deliberately large. The mascot is the first thing the eye should land on
## when a result appears.
const MASCOT_SIZE := 300.0
## Star row on Level Complete. Large: the stars are the new headline of the
## screen and have to read from arm's length.
const STAR_SIZE := 78.0
const STAR_SPACING := 26.0
## One star lands, its caption is read, then the next. Slower than a reward
## reveal on purpose - three stars arriving in half a second is a flicker, not
## an award.
const STAR_AWARD_DURATION := 0.55
const STAR_AWARD_GAP := 0.26
## After the popup has settled and the mascot has begun to react.
const STAR_SEQUENCE_DELAY := MASCOT_REACTION_DELAY + 0.18
const ICON_RETRY = preload("res://assets/runtime/ui/icons/restart_white.svg")
const ICON_HOME = preload("res://assets/runtime/ui/icons/home_lavender.svg")
const ICON_SKIP = preload("res://assets/runtime/ui/icons/fast_forward_lavender.svg")
## Level Complete entrance. The dim leads the panel, then the panel overshoots
## once and settles: 0.86 -> 1.04 -> 1.0 across roughly 310 ms.
const PANEL_DIM_DURATION := 0.14
const PANEL_ENTER_DELAY := 0.07
const PANEL_ENTER_START_SCALE := 0.86
const PANEL_ENTER_OVERSHOOT_SCALE := 1.04
const PANEL_ENTER_RISE := 0.19
const PANEL_ENTER_SETTLE := 0.12
## When the mascot starts its run: after the panel has settled and, on a win,
## after the mascot itself has faded in.
const MASCOT_REACTION_DELAY := PANEL_ENTER_DELAY + PANEL_ENTER_RISE + PANEL_ENTER_SETTLE + 0.06

signal retry_requested
signal collect_requested
signal double_coins_requested
signal home_requested
signal skip_level_requested
signal reward_animation_finished
signal ui_tap_requested
signal extra_shots_requested
signal extra_shots_declined
signal continue_requested
## One star has landed, and the whole sequence has finished. Presentation
## signals only - the stars were banked by the controller before this popup
## opened.
signal star_awarded(index: int)
signal stars_finished

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
## The animated node: title banner plus panel. See UiDesignSystem.popup_shell.
var popup_shell: Control
## The expression this popup will play, held until the entrance finishes.
var _queued_mascot_mood := ""
var _queued_mascot_intensity := 0.0
var title_label: Label
var celebration_label: Label
var subtitle_label: Label
## Replaces the old target-gem icon and fail badge. Win, loss and the rescue
## offer are all told by the mascot's expression.
var mascot: MascotView
var star_row: StarRow
var star_caption: Label
var reward_card: VBoxContainer
var earned_label: Label
var reward_row: HBoxContainer
var reward_coin_icon: Control
var reward_value_label: Label
var total_row: HBoxContainer
var total_caption_label: Label
var total_coin_icon: Control
var score_label: Label
var transition_label: Label
var retry_button: Button
var double_button: Button
var home_button: Button
var skip_button: Button
var continue_button: Button
var _rescue_mode := false
var _continue_available := false
var _continue_cost := 0
var _skip_available := false
var _skip_cost := 0
var _rewarded_available := false
var _actions_pending := false
var _reward_resolved := false
var _reward_doubled := false
var _double_request_in_flight := false
var _displayed_total := 0
var _total_tween: Tween
var _entrance_tween: Tween
var _star_tween: Tween
var _stars_pending := false
var _star_results: Array[bool] = []
var _star_objectives: Array = []
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


func present(won: bool, score: int, level_number: int = 1, result_tier: int = 8, level_reward_amount: int = 0, rewarded_available: bool = false, skip_available: bool = false, skip_cost: int = 0, continue_available: bool = false, continue_cost: int = 0, _coin_balance: int = 0, fail_reason: String = "danger_line", star_award: Dictionary = {}) -> bool:
	_build_ui()
	# The guard exists to stop the same result being presented twice. It must not
	# block a genuine mode change: declining the out-of-shots rescue calls
	# straight through to _trigger_failure(), and while rescue mode still counted
	# as "already visible" the fail screen never rendered — GIVE UP looked dead
	# while the level had in fact already failed underneath.
	if visible_result and not _rescue_mode:
		return false
	if _rescue_mode:
		_kill_entrance_tween()
	visible_result = true
	result_won = won
	result_score = score
	level_reward = maxi(0, level_reward_amount)
	_displayed_total = maxi(0, score - level_reward) if won else score
	_rewarded_available = rewarded_available
	_skip_available = skip_available
	_skip_cost = skip_cost
	_continue_available = continue_available
	_continue_cost = continue_cost
	_rescue_mode = false
	_actions_pending = false
	_reward_resolved = false
	_reward_doubled = false
	_double_request_in_flight = false
	present_count += 1
	title_label.text = "LEVEL COMPLETE" if won else "TRY AGAIN"
	celebration_label.visible = won
	celebration_label.text = "✦"
	celebration_label.modulate = Color.WHITE
	if won:
		subtitle_label.text = "LEVEL %d COMPLETE" % level_number
	elif fail_reason == "out_of_shots":
		subtitle_label.text = "YOU RAN OUT OF SHOTS"
	else:
		subtitle_label.text = "THE TABLE REACHED THE DANGER LINE"
	# Held neutral here and played once the popup has finished arriving - see
	# _queue_mascot_reaction. Starting the expression during the entrance meant
	# most of it ran while the panel was still scaling up and half transparent.
	_queued_mascot_mood = MascotViewType.MOOD_HAPPY if won else MascotViewType.MOOD_SAD
	_queued_mascot_intensity = 1.0
	mascot.show_idle(true)
	_prepare_star_award(won, star_award)
	reward_card.custom_minimum_size = Vector2(424.0, 132.0 if won else 74.0)
	_refresh_reward_copy()
	transition_label.text = "LEVEL %d  →  LEVEL %d" % [level_number, level_number + 1] if won else "LEVEL %d • READY TO RETRY" % level_number
	retry_button.text = "COLLECT" if won else "RETRY"
	# The kit plates are already ornamented; a small glyph beside the caption
	# competed with the gem caps and read as a rendering artifact.
	retry_button.icon = null
	retry_button.tooltip_text = "Collect this level's coins" if won else "Retry Level %d" % level_number
	# present_out_of_shots() relabels Home to "GIVE UP"; restore it here so a
	# later win/fail screen never inherits the rescue wording.
	home_button.text = "HOME"
	double_button.visible = won
	double_button.tooltip_text = "Watch a rewarded ad to double this level's coins" if rewarded_available else "Rewarded ad unavailable; Collect still works"
	skip_button.text = "SKIP LEVEL  ·  %d COINS" % _skip_cost
	skip_button.tooltip_text = "Skip Level %d for %d coins" % [level_number, _skip_cost]
	continue_button.text = "CONTINUE  ·  %d COINS" % _continue_cost
	_refresh_action_state()
	root_control.visible = true
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	_start_entrance()
	if retry_button.is_inside_tree():
		retry_button.grab_focus()
	return true

func present_out_of_shots(coin_balance: int, shots_added: int, cost: int) -> bool:
	_build_ui()
	if visible_result:
		return false
	visible_result = true
	_rescue_mode = true
	result_won = false
	result_score = coin_balance
	level_reward = 0
	_displayed_total = coin_balance
	_actions_pending = false
	# The rescue offer is mid-level: nothing has been earned yet, so the star row
	# has nothing to say and would only crowd the decision.
	_prepare_star_award(false, {})
	title_label.text = "OUT OF SHOTS"
	celebration_label.visible = false
	subtitle_label.text = "ADD %d SHOTS AND CONTINUE THIS ATTEMPT" % shots_added
	# The rescue offer is a setback, not a loss, so the mascot is downcast rather
	# than at the bottom of the sad track.
	_queued_mascot_mood = MascotViewType.MOOD_SAD
	_queued_mascot_intensity = 0.6
	mascot.show_idle(true)
	reward_card.custom_minimum_size = Vector2(424.0, 74.0)
	# The coin card directly above already shows the balance; repeating it here
	# was redundant. This slot doubles as the purchase-feedback line.
	transition_label.text = "YOUR ATTEMPT CONTINUES WHERE YOU LEFT OFF"
	retry_button.text = "+%d SHOTS  ·  %d COINS" % [shots_added, cost]
	retry_button.icon = null
	home_button.text = "GIVE UP"
	_skip_available = false
	_continue_available = false
	_refresh_reward_copy()
	_refresh_action_state()
	root_control.visible = true
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	_start_entrance()
	return true

func show_purchase_feedback(message: String) -> void:
	if visible_result:
		transition_label.text = message


## Re-arms the overlay's buttons after a request that ended without dismissing
## it.
##
## _on_action_pressed sets _actions_pending and disables every button so a
## double tap cannot buy twice. In rescue mode that also disables GIVE UP. If
## the controller then answers the request without dismissing the overlay — the
## player could not afford the shots, or persistence failed — nothing cleared
## the flag, so the rescue popup was left with a dead buy button AND a dead GIVE
## UP: the level could not be paid for, abandoned, or exited. Every controller
## path that declines a request must call this.
## True while the popup is the out-of-shots rescue offer rather than a win or
## fail result. The rescue offer has a real decline action (GIVE UP), so Back can
## be answered there; a win screen must still route through Collect.
func is_rescue_mode() -> bool:
	return visible_result and _rescue_mode


func clear_pending_actions() -> void:
	if not _actions_pending:
		return
	_actions_pending = false
	_refresh_action_state()


func dismiss() -> void:
	visible_result = false
	_actions_pending = false
	_kill_total_tween()
	_kill_entrance_tween()
	_kill_star_tween()
	_stars_pending = false
	if root_control != null:
		root_control.visible = false
		root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if panel != null:
		popup_shell.scale = Vector2.ONE
		popup_shell.modulate = Color.WHITE
	if reward_card != null:
		reward_card.modulate = Color.WHITE
	if mascot != null:
		mascot.scale = Vector2.ONE
		mascot.modulate = Color.WHITE
	if title_label != null:
		title_label.scale = Vector2.ONE
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
		"icon": mascot.get_global_rect(),
		"fail_badge": mascot.get_global_rect(),
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
	panel.custom_minimum_size = Vector2(520.0, 620.0)
	panel.add_theme_stylebox_override("panel", UiDesignSystemType.gameplay_modal_panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_shell = UiDesignSystemType.popup_shell("LEVEL COMPLETE", panel)
	center.add_child(popup_shell)

	var margin := MarginContainer.new()
	margin.name = "ResultContentMargin"
	margin.add_theme_constant_override("margin_left", 48)
	# Clears the half of the title plate that overlaps into the panel.
	margin.add_theme_constant_override("margin_top", 58)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 34)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.name = "ResultContent"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)

	# The heading is the shared half-out plate carried by the shell, the same one
	# every other popup wears, rather than a second banner inside the body.
	title_label = UiDesignSystemType.popup_shell_label(popup_shell)

	celebration_label = _label("✦", 18, UiDesignSystemType.COLOR_BLUE)
	celebration_label.name = "CelebrationAccents"
	celebration_label.custom_minimum_size = Vector2(0.0, 18.0)
	column.add_child(celebration_label)

	subtitle_label = _label("LEVEL COMPLETE", UiDesignSystemType.SMALL_FONT_SIZE, UiDesignSystemType.COLOR_TEXT_MUTED)
	subtitle_label.name = "ResultSubtitle"
	subtitle_label.custom_minimum_size = Vector2(0.0, 28.0)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(subtitle_label)

	var art_slot := CenterContainer.new()
	art_slot.name = "ResultArtSlot"
	art_slot.custom_minimum_size = Vector2(MASCOT_SIZE, MASCOT_SIZE)
	art_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(art_slot)

	# The result screen used to show the target gem on a win and a timer badge on
	# a loss. Neither told the player anything the title and the reward card did
	# not already say, so the slot now carries the mascot instead: the whole point
	# of the screen is how it went, and a face says that faster than an icon.
	mascot = MascotViewType.new()
	mascot.name = "ResultMascot"
	mascot.custom_minimum_size = Vector2(MASCOT_SIZE, MASCOT_SIZE)
	# The popup carries its own entrance scale; a breathing loop on top of it
	# reads as the mascot wobbling rather than as the popup landing.
	mascot.breathing_enabled = false
	art_slot.add_child(mascot)

	# Between the mascot and the reward card: the stars land first, then the
	# coins they were earned alongside. Hidden entirely on a loss, where there
	# are no stars to report and the row would only take space from the retry
	# decision.
	star_row = StarRowType.new()
	star_row.name = "ResultStarRow"
	star_row.star_size = STAR_SIZE
	star_row.spacing = STAR_SPACING
	star_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(star_row)

	star_caption = UiDesignSystemType.style_label(
		Label.new(), UiDesignSystemType.SMALL_FONT_SIZE, UiDesignSystemType.COLOR_GOLD_LIGHT)
	star_caption.name = "ResultStarCaption"
	star_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	star_caption.custom_minimum_size = Vector2(424.0, 34.0)
	star_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(star_caption)

	reward_card = VBoxContainer.new()
	reward_card.name = "ResultRewardCard"
	reward_card.custom_minimum_size = Vector2(424.0, 132.0)
	reward_card.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_card.add_theme_constant_override("separation", 3)
	reward_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(reward_card)
	var reward_column := VBoxContainer.new()
	reward_column.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_column.add_theme_constant_override("separation", 3)
	reward_card.add_child(reward_column)
	earned_label = _label("YOU EARNED", UiDesignSystemType.CAPTION_FONT_SIZE, UiDesignSystemType.COLOR_TEXT_MUTED)
	earned_label.name = "RewardCaption"
	earned_label.custom_minimum_size = Vector2(0.0, 22.0)
	reward_column.add_child(earned_label)
	reward_row = HBoxContainer.new()
	reward_row.name = "EarnedCoinRow"
	reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_row.add_theme_constant_override("separation", 10)
	reward_column.add_child(reward_row)
	reward_coin_icon = CoinIconType.new()
	reward_coin_icon.name = "EarnedCoinIcon"
	reward_coin_icon.custom_minimum_size = Vector2(50.0, 50.0)
	reward_row.add_child(reward_coin_icon)
	reward_value_label = _label("+0", UiDesignSystemType.SCORE_FONT_SIZE, UiDesignSystemType.COLOR_BLUE_DEEP)
	reward_value_label.name = "EarnedCoinValue"
	reward_value_label.custom_minimum_size = Vector2(120.0, 50.0)
	reward_row.add_child(reward_value_label)
	total_row = HBoxContainer.new()
	total_row.name = "TotalCoinRow"
	total_row.alignment = BoxContainer.ALIGNMENT_CENTER
	total_row.add_theme_constant_override("separation", 7)
	reward_column.add_child(total_row)
	total_caption_label = _label("TOTAL", UiDesignSystemType.CAPTION_FONT_SIZE, UiDesignSystemType.COLOR_TEXT_MUTED)
	total_caption_label.custom_minimum_size = Vector2(62.0, 28.0)
	total_row.add_child(total_caption_label)
	total_coin_icon = CoinIconType.new()
	total_coin_icon.name = "TotalCoinIcon"
	total_coin_icon.custom_minimum_size = Vector2(28.0, 28.0)
	total_row.add_child(total_coin_icon)
	score_label = _label("0", UiDesignSystemType.PANEL_TITLE_FONT_SIZE + 6, UiDesignSystemType.COLOR_BLUE_DEEP)
	score_label.name = "ResultScore"
	score_label.custom_minimum_size = Vector2(94.0, 30.0)
	total_row.add_child(score_label)

	transition_label = _label("LEVEL 1  →  LEVEL 2", UiDesignSystemType.SMALL_FONT_SIZE, UiDesignSystemType.COLOR_TEXT_MUTED)
	transition_label.name = "ResultTransition"
	transition_label.custom_minimum_size = Vector2(0.0, 32.0)
	column.add_child(transition_label)

	# Stacked, not side by side: the kit plates carry wide ornamental caps, so two
	# captioned buttons sharing a row overflowed the panel on 720px-wide screens.
	var action_row := VBoxContainer.new()
	action_row.name = "ResultActionRow"
	action_row.custom_minimum_size = Vector2(424.0, UiDesignSystemType.BUTTON_HEIGHT)
	action_row.add_theme_constant_override("separation", 16)
	action_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(action_row)

	retry_button = Button.new()
	retry_button.name = "ResultActionButton"
	retry_button.text = "COLLECT"
	# Affirmative primary: collecting coins, retrying, or buying shots is always
	# the green action, so it never reads as one more navigation choice.
	retry_button.theme_type_variation = "GreenButton"
	retry_button.custom_minimum_size = Vector2(424.0, UiDesignSystemType.BUTTON_HEIGHT)
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
	double_button.custom_minimum_size = Vector2(424.0, UiDesignSystemType.BUTTON_HEIGHT)
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
	home_button.expand_icon = false
	home_button.theme_type_variation = "SecondaryButton"
	home_button.custom_minimum_size = Vector2(424.0, UiDesignSystemType.BUTTON_HEIGHT)
	home_button.focus_mode = Control.FOCUS_ALL
	home_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	home_button.mouse_filter = Control.MOUSE_FILTER_STOP
	home_button.pressed.connect(_on_home_pressed)
	_wire_button_motion(home_button)
	column.add_child(home_button)

	skip_button = Button.new()
	skip_button.name = "ResultSkipLevelButton"
	skip_button.text = "SKIP LEVEL"
	skip_button.expand_icon = false
	skip_button.theme_type_variation = "SecondaryButton"
	skip_button.custom_minimum_size = Vector2(424.0, UiDesignSystemType.BUTTON_HEIGHT)
	skip_button.focus_mode = Control.FOCUS_ALL
	skip_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	skip_button.mouse_filter = Control.MOUSE_FILTER_STOP
	skip_button.pressed.connect(func() -> void: skip_level_requested.emit())
	_wire_button_motion(skip_button)
	column.add_child(skip_button)
	column.move_child(skip_button, home_button.get_index())

	continue_button = Button.new()
	continue_button.name = "ResultContinueButton"
	# A paid rescue is not navigation; it keeps the primary gem plate.

	continue_button.custom_minimum_size = Vector2(424.0, UiDesignSystemType.BUTTON_HEIGHT)
	continue_button.pressed.connect(func() -> void: continue_requested.emit())
	_wire_button_motion(continue_button)
	column.add_child(continue_button)

func _on_action_pressed() -> void:
	if _actions_pending:
		return
	if _rescue_mode:
		_actions_pending = true
		_refresh_action_state()
		extra_shots_requested.emit()
		return
	if result_won:
		if not _reward_resolved:
			_actions_pending = true
			_refresh_action_state()
			collect_requested.emit()
	else:
		retry_requested.emit()

func _on_home_pressed() -> void:
	if _rescue_mode:
		extra_shots_declined.emit()
	else:
		home_requested.emit()


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
	if score_label == null or reward_value_label == null:
		return
	if result_won:
		var shown_reward := level_reward * (2 if _reward_doubled else 1)
		earned_label.visible = true
		reward_row.visible = true
		total_caption_label.text = "TOTAL"
		reward_value_label.text = "+%s" % ScoreFormatterType.format(shown_reward)
		score_label.text = ScoreFormatterType.format(_displayed_total)
	else:
		earned_label.visible = false
		reward_row.visible = false
		total_caption_label.text = "COINS"
		score_label.text = ScoreFormatterType.format(result_score)


## Stars earned this attempt, and the ones the player already held.
##
## Nothing here decides anything: the controller has already evaluated and
## banked the result, and this only replays it. The row starts with the stars
## the player already had lit, so a replay animates only what the attempt
## actually added rather than re-awarding what they came in with.
func _prepare_star_award(won: bool, star_award: Dictionary) -> void:
	if star_row == null:
		return
	_star_results.clear()
	for entry in (star_award.get("results", []) as Array):
		_star_results.append(bool(entry))
	_star_objectives = (star_award.get("objectives", []) as Array).duplicate()
	var show_stars := won and not _star_results.is_empty()
	star_row.visible = show_stars
	star_caption.visible = show_stars
	# A loss has no star sequence to wait for, so its actions are live from the
	# first frame exactly as before.
	if star_row != null:
		star_row.shimmer_enabled = false
	_stars_pending = show_stars
	if not show_stars:
		star_caption.text = ""
		return
	# The row always starts empty and lights exactly the stars this attempt
	# earned, so the row and the tally under it can never disagree.
	#
	# It deliberately does not pre-light the stars the player already held.
	# Storage is a *count*, not a set, so "two stars already" cannot say which
	# two - pre-lighting the first two would claim a star the player may not
	# have, and on a `[earned, missed, earned]` result it lit a star that was
	# just missed while the caption said "2 of 3".
	star_row.filled = 0
	star_caption.text = ""


## Runs after the popup has settled. One star lands, its objective is named
## under it, then the next; the actions unlock only once the last one has
## landed, so a player who taps COLLECT the instant the popup opens still sees
## what they earned.
func _play_star_award() -> void:
	if star_row == null or not _stars_pending:
		return
	var pending: Array[int] = []
	for index in range(_star_results.size()):
		if _star_results[index] and not star_row.is_lit(index):
			pending.append(index)
	if pending.is_empty():
		_finish_star_award()
		return
	_kill_star_tween()
	_star_tween = create_tween()
	_star_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for index in pending:
		_star_tween.tween_callback(func() -> void:
			if star_row != null:
				star_row.award(index, STAR_AWARD_DURATION)
			if star_caption != null and index < _star_objectives.size():
				star_caption.text = String((_star_objectives[index] as Dictionary).get("text", ""))
			star_awarded.emit(index))
		_star_tween.tween_interval(STAR_AWARD_DURATION + STAR_AWARD_GAP)
	_star_tween.tween_callback(_finish_star_award)


func _finish_star_award() -> void:
	_stars_pending = false
	var earned := 0
	for result in _star_results:
		if result:
			earned += 1
	if star_caption != null:
		# Full marks gets its own line. "3 of 3 stars" is a tally; a perfect
		# level deserves to be told it was perfect.
		star_caption.text = "PERFECT!" if earned >= LevelStarsType.MAX_STARS \
			else "%d of %d stars" % [earned, LevelStarsType.MAX_STARS]
		_punch_star_caption()
	if star_row != null:
		# The settled row keeps a slow shimmer, so a finished award is not a
		# static picture sitting above a live button.
		star_row.shimmer_enabled = true
	_refresh_action_state()
	stars_finished.emit()


## A short kick on the tally as it appears, so the line reads as the conclusion
## of the sequence rather than as a label that was always there.
func _punch_star_caption() -> void:
	if star_caption == null or not star_caption.is_inside_tree():
		return
	star_caption.pivot_offset = _node_center(star_caption)
	star_caption.scale = Vector2.ONE * 0.7
	star_caption.modulate.a = 0.0
	var punch := create_tween().set_parallel(true)
	punch.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	punch.tween_property(star_caption, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	punch.tween_property(star_caption, "scale", Vector2.ONE * 1.12, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	punch.chain().tween_property(star_caption, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _kill_star_tween() -> void:
	if _star_tween != null and _star_tween.is_valid():
		_star_tween.kill()
	_star_tween = null


func _refresh_action_state() -> void:
	if retry_button == null or double_button == null or home_button == null or skip_button == null or continue_button == null:
		return
	if _rescue_mode:
		retry_button.visible = true
		retry_button.disabled = _actions_pending
		double_button.visible = false
		skip_button.visible = false
		continue_button.visible = false
		home_button.disabled = _actions_pending
		return
	# The star sequence gates the two reward actions. COLLECT is the end of the
	# level, and offering it before the player has been shown what they earned is
	# how a fast tap skips the award entirely.
	#
	# HOME is deliberately not gated. It is an escape hatch rather than a reward
	# action, and its plate has no distinct disabled art - a proof capture caught
	# it rendering exactly as it does when live while refusing taps, which is a
	# worse outcome than simply leaving the exit available.
	retry_button.disabled = _actions_pending or _stars_pending
	home_button.disabled = _actions_pending
	double_button.disabled = _actions_pending or _stars_pending or not _rewarded_available or _reward_resolved
	double_button.visible = result_won and not _reward_resolved
	skip_button.visible = not result_won
	# Affordability no longer disables Skip; the controller offers a video when
	# the player cannot pay.
	skip_button.disabled = _actions_pending
	continue_button.visible = not result_won and _continue_available
	continue_button.disabled = _actions_pending
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
		double_button.text = "WATCH AD ×2"
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
			reward_row.pivot_offset = _node_center(reward_row)
			reward_row.scale = Vector2.ONE * 1.14
		)
		_total_tween.tween_property(reward_row, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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
		total_row.pivot_offset = _node_center(total_row)
		total_row.scale = Vector2.ONE * 1.10
		reward_coin_icon.pivot_offset = _node_center(reward_coin_icon)
		reward_coin_icon.scale = Vector2.ONE * 1.12
	)
	_total_tween.tween_property(total_row, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_total_tween.parallel().tween_property(reward_coin_icon, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_total_tween.tween_callback(func() -> void: reward_animation_finished.emit())


func _kill_total_tween() -> void:
	if _total_tween != null and _total_tween.is_valid():
		_total_tween.kill()
	_total_tween = null


func _start_entrance() -> void:
	_kill_entrance_tween()
	popup_shell.pivot_offset = _node_center(popup_shell)
	if not is_inside_tree():
		popup_shell.scale = Vector2.ONE
		popup_shell.modulate = Color.WHITE
		dimmer.color = UiDesignSystemType.COLOR_OVERLAY
		return
	popup_shell.scale = Vector2.ONE * PANEL_ENTER_START_SCALE
	popup_shell.modulate = Color(1.0, 1.0, 1.0, 0.0)
	dimmer.color = Color(UiDesignSystemType.COLOR_OVERLAY.r, UiDesignSystemType.COLOR_OVERLAY.g, UiDesignSystemType.COLOR_OVERLAY.b, 0.0)
	_entrance_tween = create_tween().set_parallel(true)
	_entrance_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# The gameplay background dims first; the panel then arrives on the settled dim.
	_entrance_tween.tween_property(dimmer, "color:a", UiDesignSystemType.COLOR_OVERLAY.a, PANEL_DIM_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_entrance_tween.tween_property(popup_shell, "scale", Vector2.ONE * PANEL_ENTER_OVERSHOOT_SCALE, PANEL_ENTER_RISE).set_delay(PANEL_ENTER_DELAY).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_entrance_tween.tween_property(popup_shell, "scale", Vector2.ONE, PANEL_ENTER_SETTLE).set_delay(PANEL_ENTER_DELAY + PANEL_ENTER_RISE).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_entrance_tween.tween_property(popup_shell, "modulate:a", 1.0, PANEL_ENTER_RISE).set_delay(PANEL_ENTER_DELAY).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# The expression starts only once the popup has finished arriving and is fully
	# opaque. Playing it during the entrance meant most of the idle-to-happy run
	# happened behind a panel that was still scaling up and half transparent.
	_entrance_tween.tween_callback(_play_queued_mascot_reaction).set_delay(MASCOT_REACTION_DELAY)
	_entrance_tween.tween_callback(_play_star_award).set_delay(STAR_SEQUENCE_DELAY)
	if result_won:
		# Reveal hierarchy: title, then the completed target gem, then the reward
		# card and its actions. The layout and artwork itself are unchanged.
		title_label.pivot_offset = _node_center(title_label)
		mascot.pivot_offset = _node_center(mascot)
		reward_card.pivot_offset = _node_center(reward_card)
		title_label.scale = Vector2.ONE * 0.82
		# Fade only. The scale-with-overshoot this used to run was a second bounce
		# on top of the panel's own entrance.
		mascot.scale = Vector2.ONE
		mascot.modulate = Color(1.18, 1.18, 1.18, 0.0)
		reward_card.modulate = Color(1.0, 1.0, 1.0, 0.0)
		# The reveal overlaps the panel's own rise so the whole modal is settled
		# inside the approved celebration budget.
		var reveal_base := PANEL_ENTER_DELAY + 0.07
		_entrance_tween.tween_property(title_label, "scale", Vector2.ONE, 0.18).set_delay(reveal_base).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_entrance_tween.tween_property(mascot, "modulate", Color.WHITE, 0.18).set_delay(reveal_base + 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_entrance_tween.tween_property(reward_card, "modulate:a", 1.0, 0.18).set_delay(reveal_base + 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		reward_card.modulate = Color.WHITE


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
	button.pressed.connect(func() -> void: ui_tap_requested.emit())


func _node_center(control: Control) -> Vector2:
	var node_size := control.size
	if node_size == Vector2.ZERO:
		node_size = control.custom_minimum_size
	return node_size * 0.5


func _kill_entrance_tween() -> void:
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()


## Starts the expression the popup queued at present() time.
##
## Split out from the entrance tween so it is callable directly in tests, and so
## the queue can be consumed exactly once: a re-present before the delay elapses
## replaces the queued mood rather than playing both.
func _play_queued_mascot_reaction() -> void:
	if mascot == null or _queued_mascot_mood.is_empty():
		return
	mascot.play_from_idle(_queued_mascot_mood, _queued_mascot_intensity)
	_queued_mascot_mood = ""
