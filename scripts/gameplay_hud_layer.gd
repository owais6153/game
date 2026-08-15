class_name GameplayHudLayer
extends CanvasLayer

const AssetCatalogType = preload("res://scripts/asset_catalog.gd")
const ScoreFormatterType = preload("res://scripts/score_formatter.gd")
const CoinIconType = preload("res://scripts/coin_icon.gd")
const UiDesignSystemType = preload("res://scripts/ui_design_system.gd")
const TargetRewardOverlayType = preload("res://scripts/target_reward_overlay.gd")
const ICON_SETTINGS = preload("res://assets/runtime/ui/icons/cog_blue_crisp.png")
const ICON_PLAY = preload("res://assets/runtime/ui/icons/play_white.svg")
const ICON_RESTART = preload("res://assets/runtime/ui/icons/restart_navy.svg")
const ICON_HOME = preload("res://assets/runtime/ui/icons/home_navy.svg")
const ICON_MUSIC = preload("res://assets/runtime/ui/icons/note_navy.svg")
const ICON_SOUND = preload("res://assets/runtime/ui/icons/speaker_navy.svg")
const ICON_VIBRATION = preload("res://assets/runtime/ui/icons/vibration_navy.svg")
const SNAPSHOT_KEYS := ["level_number", "gem_identity_order", "current_level", "next_level", "coins", "score", "target_level", "target_progress", "target_quantity", "target_index", "target_total", "target_collecting", "target_completed", "highest_level", "music_enabled", "sound_enabled", "vibration_enabled"]

signal settings_requested
signal resume_requested
signal restart_requested
signal home_requested
signal music_toggled(enabled: bool)
signal sound_toggled(enabled: bool)
signal vibration_toggled(enabled: bool)
signal privacy_policy_requested
signal privacy_options_requested

var root_control: Control
var hud_canvas: Control
var hud_margin: MarginContainer
var bottom_progression_anchor: MarginContainer
var progression_center: CenterContainer
var target_anchor: CenterContainer
var score_panel: Control
var score_label: Label
var coin_icon: CoinIcon
var progression_frames: Array[Control] = []
var progression_icons: Array[TextureRect] = []
var next_panel: Control
var next_icon: TextureRect
var target_panel: Control
var target_header_label: Label
var target_icon: TextureRect
var target_name_label: Label
var target_status_label: Label
var target_progress_bar: ProgressBar
var reward_foreground_host: Node2D
var target_swap_outgoing: Sprite2D
var target_swap_incoming: Sprite2D
var target_reward_overlay: Control
var settings_button: TextureButton
var pause_blocker: Control
var pause_dimmer: ColorRect
var pause_safe_margin: MarginContainer
var pause_panel: PanelContainer
var resume_button: Button
var restart_button: Button
var home_button: Button
var music_toggle: Button
var sound_toggle: Button
var vibration_toggle: Button
var privacy_options_button: Button

var _built := false
var _snapshot: Dictionary = {}
var _layout_scale := 1.0
var _safe_insets_override := Vector4(-1.0, -1.0, -1.0, -1.0)
var _score_tween: Tween
var _coin_icon_tween: Tween
var _completion_coin_tween: Tween
var _next_tween: Tween
var _target_swap_tween: Tween
var _target_pulse_tween: Tween
var _target_progress_tween: Tween
var _settings_tween: Tween
var _pause_tween: Tween
var _authoritative_coins := 0
var _displayed_coins := 0
var _queued_coin_rewards := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 40
	_build_once()
	_refresh_safe_margins()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_refresh_safe_margins):
		viewport.size_changed.connect(_refresh_safe_margins)


func _unhandled_input(event: InputEvent) -> void:
	# The HUD processes while the tree is paused, so Android Back/Escape closes
	# the modal first instead of falling through to an immediate app exit.
	if pause_blocker != null and pause_blocker.visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		resume_requested.emit()
		if get_viewport() != null:
			get_viewport().set_input_as_handled()


func update_snapshot(snapshot: Dictionary) -> void:
	_build_once()
	if _snapshot_matches(snapshot):
		return
	var had_snapshot := not _snapshot.is_empty()
	var authoritative_coins := int(snapshot.get("coins", snapshot.get("score", 0)))
	if not had_snapshot or authoritative_coins < _authoritative_coins:
		_authoritative_coins = authoritative_coins
		_displayed_coins = authoritative_coins
		_queued_coin_rewards = 0
		_set_coin_label(_displayed_coins)
	elif authoritative_coins != _authoritative_coins:
		var unregistered_gain := authoritative_coins - _authoritative_coins
		_authoritative_coins = authoritative_coins
		# Direct/debug snapshot updates have no flight registration and therefore
		# snap safely. Production merge rewards register before the snapshot, so
		# their count changes only as the animated coins arrive.
		if _queued_coin_rewards < unregistered_gain:
			_displayed_coins = authoritative_coins
			_queued_coin_rewards = 0
			_set_coin_label(_displayed_coins)
			if had_snapshot:
				_animate_coin_change()

	var identity_order: Array = snapshot.get("gem_identity_order", []) as Array
	if _snapshot.get("gem_identity_order", []) != identity_order:
		for index in range(mini(8, progression_icons.size())):
			var local_tier := index + 1
			progression_icons[index].texture = AssetCatalogType.gem_texture(local_tier)

	var next_level := int(snapshot.get("next_level", 1))
	if int(_snapshot.get("next_level", -1)) != next_level:
		next_icon.texture = AssetCatalogType.gem_texture(next_level)
		if had_snapshot:
			_animate_next_swap()

	var current_level := int(snapshot.get("current_level", 1))
	var highest_level := int(snapshot.get("highest_level", 1))
	if int(_snapshot.get("current_level", -1)) != current_level or int(_snapshot.get("highest_level", -1)) != highest_level:
		for index in range(progression_frames.size()):
			var tier := index + 1
			var icon := progression_icons[index]
			var slot := progression_frames[index]
			if tier == current_level:
				icon.modulate = Color.WHITE
				slot.scale = Vector2.ONE * 1.10
			elif tier <= mini(highest_level, progression_frames.size()):
				icon.modulate = Color.WHITE
				slot.scale = Vector2.ONE
			else:
				icon.modulate = Color(1.0, 1.0, 1.0, 0.82)
				slot.scale = Vector2.ONE

	var target_progress := int(snapshot.get("target_progress", 0))
	var target_quantity := maxi(1, int(snapshot.get("target_quantity", 1)))
	var target_index := int(snapshot.get("target_index", 0))
	var target_total := maxi(1, int(snapshot.get("target_total", 1)))
	var target_header := "TARGET  %d / %d" % [mini(target_index + 1, target_total), target_total]
	var target_state := "%d / %d" % [mini(target_progress, target_quantity), target_quantity]
	if bool(snapshot.get("target_collecting", false)):
		target_state = "ARRIVING  •  %s" % target_state
	elif bool(snapshot.get("target_completed", false)):
		target_state = "COMPLETE  •  %d / %d" % [target_quantity, target_quantity]
	var target_bar_value := target_quantity if bool(snapshot.get("target_completed", false)) else target_progress
	var target_level := int(snapshot.get("target_level", 1))
	if int(_snapshot.get("target_level", -1)) != target_level:
		var target_name := AssetCatalogType.gem_name(target_level)
		var previous_texture := target_icon.texture
		var next_texture := AssetCatalogType.gem_texture(target_level)
		target_icon.texture = next_texture
		if had_snapshot:
			_animate_target_swap(previous_texture, next_texture, target_name.to_upper(), target_header, target_state, target_quantity, target_bar_value)
		else:
			_apply_target_state(target_name.to_upper(), target_header, target_state, target_quantity, target_bar_value)
	else:
		_apply_target_state(target_name_label.text, target_header, target_state, target_quantity, target_bar_value)

	var level_number := int(snapshot.get("level_number", 1))
	if music_toggle != null:
		music_toggle.set_pressed_no_signal(bool(snapshot.get("music_enabled", true)))
	if sound_toggle != null:
		sound_toggle.set_pressed_no_signal(bool(snapshot.get("sound_enabled", true)))
	if vibration_toggle != null:
		vibration_toggle.set_pressed_no_signal(bool(snapshot.get("vibration_enabled", true)))
	_sync_pause_switch_labels()
	if restart_button != null:
		restart_button.tooltip_text = "Restart Level %d with the same gem chain" % level_number
	_snapshot = snapshot.duplicate()


func _snapshot_matches(snapshot: Dictionary) -> bool:
	if _snapshot.is_empty():
		return false
	for key in SNAPSHOT_KEYS:
		if _snapshot.get(key) != snapshot.get(key):
			return false
	return true


func show_pause() -> void:
	_build_once()
	if pause_blocker.visible:
		return
	_kill_tween(_pause_tween)
	pause_blocker.visible = true
	pause_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_panel.pivot_offset = _node_center(pause_panel)
	pause_panel.scale = Vector2.ONE * 0.92
	pause_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	pause_dimmer.color = Color(UiDesignSystemType.COLOR_OVERLAY.r, UiDesignSystemType.COLOR_OVERLAY.g, UiDesignSystemType.COLOR_OVERLAY.b, 0.0)
	if is_inside_tree():
		_pause_tween = create_tween().set_parallel(true)
		_pause_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_pause_tween.tween_property(pause_panel, "scale", Vector2.ONE, UiDesignSystemType.POPUP_ENTER_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_pause_tween.tween_property(pause_panel, "modulate:a", 1.0, UiDesignSystemType.POPUP_ENTER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_pause_tween.tween_property(pause_dimmer, "color:a", UiDesignSystemType.COLOR_OVERLAY.a, UiDesignSystemType.POPUP_ENTER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		resume_button.grab_focus()
	else:
		pause_panel.scale = Vector2.ONE
		pause_panel.modulate = Color.WHITE
		pause_dimmer.color = UiDesignSystemType.COLOR_OVERLAY


func hide_pause(animated: bool = true) -> void:
	if not _built or not pause_blocker.visible:
		return
	_kill_tween(_pause_tween)
	if not animated or not is_inside_tree():
		_finish_hide_pause()
		return
	_pause_tween = create_tween().set_parallel(true)
	_pause_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_pause_tween.tween_property(pause_panel, "scale", Vector2.ONE * 0.96, UiDesignSystemType.POPUP_EXIT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_pause_tween.tween_property(pause_panel, "modulate:a", 0.0, UiDesignSystemType.POPUP_EXIT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_pause_tween.tween_property(pause_dimmer, "color:a", 0.0, UiDesignSystemType.POPUP_EXIT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_pause_tween.finished.connect(_finish_hide_pause, CONNECT_ONE_SHOT)


func is_pause_visible() -> bool:
	return _built and pause_blocker.visible


func pulse_target() -> void:
	_build_once()
	if target_reward_overlay != null:
		target_reward_overlay.play(target_collection_destination())
	_kill_tween(_target_pulse_tween)
	target_panel.pivot_offset = _node_center(target_panel)
	target_panel.scale = Vector2.ONE
	_energy_pulse(target_panel)
	if not is_inside_tree():
		return
	_target_pulse_tween = create_tween()
	_target_pulse_tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_target_pulse_tween.tween_property(target_panel, "scale", Vector2.ONE * 1.07, UiDesignSystemType.TARGET_PULSE_DURATION * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_target_pulse_tween.tween_property(target_panel, "scale", Vector2.ONE, UiDesignSystemType.TARGET_PULSE_DURATION * 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func target_collection_destination() -> Vector2:
	if target_icon == null or not target_icon.is_inside_tree():
		return GameConfig.TARGET_COLLECTION_DESTINATION
	return target_icon.get_global_rect().get_center()


func attach_reward_foreground(item: Node2D) -> void:
	_build_once()
	if item == null or item.get_parent() == reward_foreground_host:
		return
	reward_foreground_host.add_child(item)


func coin_collection_destination() -> Vector2:
	if coin_icon == null or not coin_icon.is_inside_tree():
		return GameConfig.COIN_HUD_FALLBACK_DESTINATION
	return coin_icon.get_global_rect().get_center()


func begin_coin_reward(amount: int) -> void:
	if amount <= 0:
		return
	_queued_coin_rewards += amount
	_authoritative_coins += amount


func collect_coin_chunk(value: int, final_coin: bool = false) -> void:
	if value <= 0:
		return
	_queued_coin_rewards = maxi(0, _queued_coin_rewards - value)
	_displayed_coins = mini(_authoritative_coins, _displayed_coins + value)
	if final_coin and _queued_coin_rewards == 0:
		_displayed_coins = _authoritative_coins
	_set_coin_label(_displayed_coins)
	_animate_coin_change()


func displayed_coin_value() -> int:
	return _displayed_coins


func pending_coin_value() -> int:
	return _queued_coin_rewards


func prepare_completion_reward_display(previous_total: int, final_total: int) -> void:
	_kill_tween(_completion_coin_tween)
	_authoritative_coins = maxi(previous_total, final_total)
	_displayed_coins = maxi(0, previous_total)
	_queued_coin_rewards = 0
	_set_coin_label(_displayed_coins)


func animate_completion_reward(final_total: int, duration: float = 0.72) -> void:
	_kill_tween(_completion_coin_tween)
	var start := _displayed_coins
	_authoritative_coins = maxi(_authoritative_coins, final_total)
	if not is_inside_tree():
		_displayed_coins = final_total
		_set_coin_label(_displayed_coins)
		_animate_coin_change()
		return
	_completion_coin_tween = create_tween()
	_completion_coin_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_completion_coin_tween.tween_method(func(value: float) -> void:
		_displayed_coins = int(round(value))
		_set_coin_label(_displayed_coins)
	, float(start), float(final_total), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_completion_coin_tween.tween_callback(func() -> void:
		_displayed_coins = final_total
		_set_coin_label(_displayed_coins)
		_animate_coin_change()
	)


func reset_presentation() -> void:
	hide_pause(false)
	for tween in [_score_tween, _coin_icon_tween, _completion_coin_tween, _next_tween, _target_swap_tween, _target_pulse_tween, _target_progress_tween, _settings_tween]:
		_kill_tween(tween)
	if score_label != null:
		score_label.scale = Vector2.ONE
	if coin_icon != null:
		coin_icon.scale = Vector2.ONE
	_queued_coin_rewards = 0
	if next_icon != null:
		next_icon.scale = Vector2.ONE
		next_icon.modulate = Color.WHITE
	if target_icon != null:
		target_icon.scale = Vector2.ONE
		target_icon.modulate = Color.WHITE
	if target_swap_outgoing != null:
		target_swap_outgoing.visible = false
	if target_swap_incoming != null:
		target_swap_incoming.visible = false
	if target_reward_overlay != null:
		target_reward_overlay.reset()
	if target_panel != null:
		target_panel.scale = Vector2.ONE
	if settings_button != null:
		settings_button.scale = Vector2.ONE
	# Restart is a hard presentation boundary. Clearing the cached snapshot makes
	# the next authoritative state render directly instead of crossfading from a
	# target/queue that belonged to the discarded run.
	_snapshot.clear()


func set_safe_insets_for_testing(insets: Vector4) -> void:
	_safe_insets_override = insets
	_refresh_safe_margins()


func layout_metrics() -> Dictionary:
	_build_once()
	return {
		"score": score_panel.get_global_rect(),
		"progression": progression_center.get_global_rect(),
		"next": next_panel.get_global_rect(),
		"target": target_panel.get_global_rect(),
		"settings": settings_button.get_global_rect(),
		"pause": pause_panel.get_global_rect(),
		"hud": hud_margin.get_global_rect(),
	}


func _build_once() -> void:
	if _built:
		return
	_built = true
	root_control = Control.new()
	root_control.name = "GameplayUIRoot"
	root_control.theme = UiDesignSystemType.theme()
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_hud()
	_build_reward_foreground()
	target_reward_overlay = TargetRewardOverlayType.new()
	target_reward_overlay.name = "TargetRewardOverlay"
	target_reward_overlay.z_index = 20
	root_control.add_child(target_reward_overlay)
	target_reward_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_pause_popup()
	pause_blocker.z_index = 30


func _build_reward_foreground() -> void:
	reward_foreground_host = Node2D.new()
	reward_foreground_host.name = "RewardForegroundHost"
	reward_foreground_host.z_index = 10
	root_control.add_child(reward_foreground_host)
	target_swap_outgoing = Sprite2D.new()
	target_swap_outgoing.name = "OutgoingTargetGem"
	target_swap_outgoing.z_index = 5
	target_swap_outgoing.visible = false
	reward_foreground_host.add_child(target_swap_outgoing)
	target_swap_incoming = Sprite2D.new()
	target_swap_incoming.name = "IncomingTargetGem"
	target_swap_incoming.z_index = 6
	target_swap_incoming.visible = false
	reward_foreground_host.add_child(target_swap_incoming)


func _build_hud() -> void:
	hud_canvas = Control.new()
	hud_canvas.name = "HudDesignCanvas"
	hud_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_canvas.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hud_canvas.offset_right = UiDesignSystemType.DESIGN_WIDTH
	hud_canvas.offset_bottom = GameConfig.VIEWPORT_SIZE.y
	root_control.add_child(hud_canvas)

	# One compact, balanced top row: Coins / centered Target / Next + Settings.
	# Equal-width side slots keep Target centered independently of side content.
	hud_margin = MarginContainer.new()
	hud_margin.name = "SafeHudMargin"
	hud_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_canvas.add_child(hud_margin)
	# Use explicit design-canvas geometry instead of relying on anchors here.
	# These controls are created before the first layout pass, and anchor-based
	# sizing can otherwise collapse the runtime containers to their minimum width.
	hud_margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hud_margin.offset_left = 0.0
	hud_margin.offset_top = 0.0
	hud_margin.offset_right = UiDesignSystemType.DESIGN_WIDTH
	hud_margin.offset_bottom = UiDesignSystemType.TOP_HUD_HEIGHT
	var utility_row := HBoxContainer.new()
	utility_row.name = "TopObjectiveRow"
	utility_row.custom_minimum_size = Vector2(0.0, UiDesignSystemType.TOP_HUD_HEIGHT)
	utility_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	utility_row.alignment = BoxContainer.ALIGNMENT_CENTER
	utility_row.add_theme_constant_override("separation", 0)
	utility_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_margin.add_child(utility_row)

	var left_slot := HBoxContainer.new()
	left_slot.name = "CoinsSlot"
	left_slot.custom_minimum_size = Vector2(UiDesignSystemType.TOP_SIDE_SLOT_WIDTH, UiDesignSystemType.TOP_HUD_HEIGHT)
	left_slot.alignment = BoxContainer.ALIGNMENT_BEGIN
	left_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	utility_row.add_child(left_slot)
	score_panel = _build_score_panel()
	score_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	left_slot.add_child(score_panel)

	target_anchor = CenterContainer.new()
	target_anchor.name = "TargetSlot"
	target_anchor.custom_minimum_size = Vector2(UiDesignSystemType.TARGET_PANEL_SIZE.x, UiDesignSystemType.TOP_HUD_HEIGHT)
	target_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	utility_row.add_child(target_anchor)
	target_panel = _build_target_panel()
	target_anchor.add_child(target_panel)

	var right_slot := HBoxContainer.new()
	right_slot.name = "NextSettingsSlot"
	right_slot.custom_minimum_size = Vector2(UiDesignSystemType.TOP_SIDE_SLOT_WIDTH, UiDesignSystemType.TOP_HUD_HEIGHT)
	right_slot.alignment = BoxContainer.ALIGNMENT_END
	right_slot.add_theme_constant_override("separation", 6)
	right_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	utility_row.add_child(right_slot)
	next_panel = _build_next_panel()
	next_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right_slot.add_child(next_panel)
	var settings_frame := PanelContainer.new()
	settings_frame.name = "SettingsFrame"
	settings_frame.custom_minimum_size = Vector2.ONE * UiDesignSystemType.TOP_SETTINGS_SIZE
	settings_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	settings_frame.add_theme_stylebox_override("panel", UiDesignSystemType.utility_frame_style())
	settings_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_slot.add_child(settings_frame)
	var settings_center := CenterContainer.new()
	settings_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings_frame.add_child(settings_center)
	settings_button = _build_settings_button()
	settings_button.custom_minimum_size = Vector2.ONE * UiDesignSystemType.TOP_SETTINGS_SIZE
	settings_center.add_child(settings_button)

	# The full eight-gem merge path is a separate bottom-safe presentation region.
	bottom_progression_anchor = MarginContainer.new()
	bottom_progression_anchor.name = "BottomProgressionAnchor"
	bottom_progression_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_progression_anchor.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bottom_progression_anchor.offset_left = 0.0
	bottom_progression_anchor.offset_right = UiDesignSystemType.DESIGN_WIDTH
	hud_canvas.add_child(bottom_progression_anchor)
	progression_center = CenterContainer.new()
	progression_center.name = "ProgressionCenter"
	progression_center.custom_minimum_size = Vector2(0.0, UiDesignSystemType.PROGRESSION_HEIGHT)
	progression_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progression_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_progression_anchor.add_child(progression_center)
	progression_center.add_child(_build_progression_group())


func _build_score_panel() -> Control:
	var panel := PanelContainer.new()
	panel.name = "ScorePanel"
	panel.custom_minimum_size = UiDesignSystemType.SCORE_PANEL_SIZE
	panel.add_theme_stylebox_override("panel", UiDesignSystemType.secondary_hud_panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.name = "ScoreContent"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 4)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(column)
	column.add_child(_build_card_heading("COINS", "CoinsHeading", 124.0))
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(center)
	var row := HBoxContainer.new()
	row.name = "CoinValueRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", UiDesignSystemType.SMALL_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(row)
	coin_icon = CoinIconType.new()
	coin_icon.name = "CoinIcon"
	coin_icon.custom_minimum_size = Vector2(34.0, 34.0)
	coin_icon.pivot_offset = Vector2(17.0, 17.0)
	row.add_child(coin_icon)
	score_label = _label("0", 42, UiDesignSystemType.COLOR_BLUE_DEEP)
	score_label.add_theme_constant_override("outline_size", 2)
	score_label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.82))
	score_label.name = "CoinValue"
	score_label.custom_minimum_size = Vector2(94.0, 46.0)
	row.add_child(score_label)
	return panel


func _build_next_panel() -> Control:
	var panel := PanelContainer.new()
	panel.name = "NextPanel"
	panel.custom_minimum_size = UiDesignSystemType.NEXT_PANEL_SIZE
	panel.add_theme_stylebox_override("panel", UiDesignSystemType.secondary_hud_panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.name = "NextContent"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 3)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(column)
	column.add_child(_build_card_heading("NEXT", "NextHeading", 86.0))
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(center)
	var aspect := AspectRatioContainer.new()
	aspect.name = "NextGemAspect"
	aspect.custom_minimum_size = Vector2.ONE * UiDesignSystemType.NEXT_ICON_SIZE
	aspect.ratio = 1.0
	aspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(aspect)
	next_icon = _gem_texture_rect("NextGem")
	aspect.add_child(next_icon)
	return panel


func _build_progression_group() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "ProgressionPanel"
	panel.custom_minimum_size = Vector2(580.0, UiDesignSystemType.PROGRESSION_HEIGHT)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", UiDesignSystemType.progression_panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var strip := HBoxContainer.new()
	strip.name = "ProgressionStrip"
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 0)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(strip)
	for tier in range(1, 9):
		var frame := MarginContainer.new()
		frame.name = "ProgressionSlot%d" % tier
		frame.custom_minimum_size = Vector2(UiDesignSystemType.PROGRESSION_ICON_SIZE, UiDesignSystemType.PROGRESSION_ICON_SIZE)
		frame.pivot_offset = Vector2.ONE * UiDesignSystemType.PROGRESSION_ICON_SIZE * 0.5
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_theme_constant_override("margin_left", 2)
		frame.add_theme_constant_override("margin_top", 2)
		frame.add_theme_constant_override("margin_right", 2)
		frame.add_theme_constant_override("margin_bottom", 2)
		var icon := _gem_texture_rect("ProgressionGem%d" % tier)
		icon.texture = AssetCatalogType.gem_texture(tier)
		frame.add_child(icon)
		strip.add_child(frame)
		progression_frames.append(frame)
		progression_icons.append(icon)
		if tier < 8:
			var connector_center := CenterContainer.new()
			connector_center.custom_minimum_size = Vector2(11.0, UiDesignSystemType.PROGRESSION_ICON_SIZE)
			connector_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var connector := _label("›", 20, UiDesignSystemType.COLOR_BLUE_DEEP)
			connector.custom_minimum_size = Vector2(11.0, 22.0)
			connector_center.add_child(connector)
			strip.add_child(connector_center)
	return panel


func _build_target_panel() -> Control:
	var panel := Control.new()
	panel.name = "ActiveTargetPanel"
	panel.custom_minimum_size = UiDesignSystemType.TARGET_PANEL_SIZE
	panel.clip_contents = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var inner := PanelContainer.new()
	inner.name = "TargetContentSurface"
	inner.add_theme_stylebox_override("panel", UiDesignSystemType.target_panel_style())
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(inner)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var badge := PanelContainer.new()
	badge.name = "TargetBadge"
	badge.custom_minimum_size = Vector2(170.0, 36.0)
	badge.add_theme_stylebox_override("panel", UiDesignSystemType.target_badge_style())
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_label := _label("TARGET  1 / 1", 20, Color.WHITE)
	badge_label.name = "Label"
	_decorate_header_label(badge_label)
	badge.add_child(badge_label)
	badge.set_anchors_preset(Control.PRESET_CENTER_TOP)
	badge.offset_left = -85.0
	badge.offset_right = 85.0
	badge.offset_top = 0.0
	badge.offset_bottom = 36.0
	panel.add_child(badge)
	target_header_label = badge.get_node("Label") as Label
	var content_margin := MarginContainer.new()
	content_margin.name = "TargetContentMargin"
	content_margin.add_theme_constant_override("margin_left", 16)
	content_margin.add_theme_constant_override("margin_top", 34)
	content_margin.add_theme_constant_override("margin_right", 16)
	content_margin.add_theme_constant_override("margin_bottom", 10)
	content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content_margin)
	content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var row := HBoxContainer.new()
	row.name = "TargetContentRow"
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_margin.add_child(row)
	var icon_slot := CenterContainer.new()
	icon_slot.name = "TargetGemCenter"
	icon_slot.custom_minimum_size = Vector2(84.0, 76.0)
	icon_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon_slot)
	var icon_aspect := AspectRatioContainer.new()
	icon_aspect.custom_minimum_size = Vector2.ONE * UiDesignSystemType.TARGET_ICON_SIZE
	icon_aspect.ratio = 1.0
	icon_aspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_slot.add_child(icon_aspect)
	target_icon = _gem_texture_rect("TargetGem")
	icon_aspect.add_child(target_icon)
	var details := VBoxContainer.new()
	details.name = "TargetDetails"
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.alignment = BoxContainer.ALIGNMENT_CENTER
	details.add_theme_constant_override("separation", 3)
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(details)
	target_name_label = _label("TARGET GEM", 20, UiDesignSystemType.COLOR_TEXT)
	target_name_label.name = "TargetName"
	# The target artwork is self-identifying. Keep the legacy node for state and
	# transition compatibility, but do not render gem names in the compact HUD.
	target_name_label.visible = false
	target_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	details.add_child(target_name_label)
	target_status_label = _label("0 / 1", 22, UiDesignSystemType.COLOR_BLUE_DEEP)
	target_status_label.name = "TargetProgressText"
	target_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	target_status_label.add_theme_constant_override("outline_size", 1)
	target_status_label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.72))
	details.add_child(target_status_label)
	target_progress_bar = ProgressBar.new()
	target_progress_bar.name = "TargetProgressBar"
	target_progress_bar.custom_minimum_size = Vector2(0.0, 14.0)
	target_progress_bar.show_percentage = false
	target_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(target_progress_bar)
	return panel


func _build_card_heading(text: String, node_name: String, width: float) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.name = node_name
	badge.custom_minimum_size = Vector2(width, 34.0)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.add_theme_stylebox_override("panel", UiDesignSystemType.card_header_style())
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var heading := _label(text, 16, Color.WHITE)
	heading.name = "Label"
	_decorate_header_label(heading)
	badge.add_child(heading)
	return badge


func _build_settings_button() -> TextureButton:
	var button := TextureButton.new()
	button.name = "SettingsButton"
	button.custom_minimum_size = Vector2.ONE * UiDesignSystemType.MIN_TOUCH_TARGET
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_normal = ICON_SETTINGS
	button.texture_hover = ICON_SETTINGS
	button.texture_pressed = ICON_SETTINGS
	button.texture_disabled = ICON_SETTINGS
	button.tooltip_text = "Pause"
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.self_modulate = Color.WHITE
	button.pressed.connect(func() -> void: settings_requested.emit())
	button.button_down.connect(_on_settings_button_down)
	button.button_up.connect(_on_settings_button_up)
	return button


func _build_pause_popup() -> void:
	pause_blocker = Control.new()
	pause_blocker.name = "PauseInputBlocker"
	pause_blocker.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_blocker.visible = false
	root_control.add_child(pause_blocker)
	pause_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_dimmer = ColorRect.new()
	pause_dimmer.name = "PauseDimmer"
	pause_dimmer.color = UiDesignSystemType.COLOR_OVERLAY
	pause_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_blocker.add_child(pause_dimmer)
	pause_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_safe_margin = MarginContainer.new()
	pause_safe_margin.name = "PauseSafeArea"
	pause_safe_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_blocker.add_child(pause_safe_margin)
	pause_safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_safe_margin.add_child(center)
	pause_panel = PanelContainer.new()
	pause_panel.name = "PausePanel"
	pause_panel.custom_minimum_size = Vector2(520.0, 760.0)
	pause_panel.add_theme_stylebox_override("panel", UiDesignSystemType.gameplay_modal_panel_style())
	pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(pause_panel)
	var margin := MarginContainer.new()
	margin.name = "PauseContentMargin"
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 34)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.name = "PauseActions"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	var title := _label("GAME PAUSED", UiDesignSystemType.POPUP_TITLE_FONT_SIZE, UiDesignSystemType.COLOR_BLUE_DEEP)
	title.name = "PauseTitle"
	title.custom_minimum_size = Vector2(0.0, 58.0)
	title.add_theme_constant_override("outline_size", 5)
	title.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.92))
	column.add_child(title)
	var pause_gem := TextureRect.new()
	pause_gem.name = "PauseGemAccent"
	pause_gem.texture = AssetCatalogType.gem_texture(8)
	pause_gem.custom_minimum_size = Vector2(96.0, 96.0)
	pause_gem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pause_gem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pause_gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(pause_gem)
	var subtitle := _label("SETTINGS", 15, UiDesignSystemType.COLOR_TEXT_MUTED)
	subtitle.name = "PauseSubtitle"
	subtitle.custom_minimum_size = Vector2(0.0, 28.0)
	column.add_child(subtitle)
	music_toggle = _setting_toggle(column, "MUSIC", "MusicToggle")
	music_toggle.toggled.connect(func(enabled: bool) -> void:
		_sync_switch_label(music_toggle)
		music_toggled.emit(enabled)
	)
	sound_toggle = _setting_toggle(column, "SOUND FX", "SoundToggle")
	sound_toggle.toggled.connect(func(enabled: bool) -> void:
		_sync_switch_label(sound_toggle)
		sound_toggled.emit(enabled)
	)
	vibration_toggle = _setting_toggle(column, "VIBRATION", "VibrationToggle")
	vibration_toggle.toggled.connect(func(enabled: bool) -> void:
		_sync_switch_label(vibration_toggle)
		vibration_toggled.emit(enabled)
	)
	var privacy_row := HBoxContainer.new()
	privacy_row.name = "PausePrivacyActions"
	privacy_row.custom_minimum_size = Vector2(424.0, 56.0)
	privacy_row.add_theme_constant_override("separation", 12)
	column.add_child(privacy_row)
	var privacy_policy := _button("PausePrivacyPolicy", "PRIVACY POLICY", Vector2(0.0, 56.0), "SecondaryButton")
	privacy_policy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	privacy_policy.pressed.connect(func() -> void: privacy_policy_requested.emit())
	privacy_row.add_child(privacy_policy)
	privacy_options_button = _button("PausePrivacyOptions", "PRIVACY OPTIONS", Vector2(0.0, 56.0), "SecondaryButton")
	privacy_options_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	privacy_options_button.visible = false
	privacy_options_button.pressed.connect(func() -> void: privacy_options_requested.emit())
	privacy_row.add_child(privacy_options_button)
	resume_button = _button("ResumeButton", "RESUME", Vector2(424.0, 82.0), "")
	resume_button.icon = ICON_PLAY
	resume_button.expand_icon = false
	resume_button.tooltip_text = "Continue playing"
	resume_button.pressed.connect(func() -> void: resume_requested.emit())
	column.add_child(resume_button)
	var utility_row := HBoxContainer.new()
	utility_row.custom_minimum_size = Vector2(424.0, 72.0)
	utility_row.alignment = BoxContainer.ALIGNMENT_CENTER
	utility_row.add_theme_constant_override("separation", 14)
	column.add_child(utility_row)
	restart_button = _button("PauseRestartButton", "RESTART", Vector2(0.0, 72.0), "SecondaryButton")
	restart_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart_button.icon = ICON_RESTART
	restart_button.expand_icon = false
	restart_button.tooltip_text = "Restart with the same gem chain"
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	utility_row.add_child(restart_button)
	home_button = _button("PauseHomeButton", "HOME", Vector2(0.0, 72.0), "SecondaryButton")
	home_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home_button.icon = ICON_HOME
	home_button.expand_icon = false
	home_button.tooltip_text = "Return to home"
	home_button.pressed.connect(func() -> void: home_requested.emit())
	utility_row.add_child(home_button)


func _button(node_name: String, text: String, minimum: Vector2, variation: StringName) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = minimum
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	if not variation.is_empty():
		button.theme_type_variation = variation
	_wire_button_motion(button)
	return button


func _setting_toggle(parent: VBoxContainer, text: String, node_name: String) -> Button:
	var frame := PanelContainer.new()
	frame.name = "%sRow" % node_name
	frame.custom_minimum_size = Vector2(424.0, 62.0)
	frame.add_theme_stylebox_override("panel", UiDesignSystemType.setting_row_style())
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(frame)
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, 62.0)
	row.add_theme_constant_override("separation", 16)
	frame.add_child(row)
	var icon := TextureRect.new()
	icon.name = "%sIcon" % node_name
	icon.texture = _setting_icon_texture(node_name)
	icon.custom_minimum_size = Vector2(28.0, 28.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var label := _label(text, 18, UiDesignSystemType.COLOR_TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var toggle := Button.new()
	toggle.name = node_name
	toggle.toggle_mode = true
	toggle.button_pressed = true
	toggle.theme_type_variation = "SettingsSwitch"
	toggle.custom_minimum_size = Vector2(108.0, 50.0)
	toggle.focus_mode = Control.FOCUS_ALL
	toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_sync_switch_label(toggle)
	_wire_button_motion(toggle)
	toggle.toggled.connect(func(_enabled: bool) -> void:
		_energy_pulse(toggle)
	)
	row.add_child(toggle)
	return toggle


func _setting_icon_texture(node_name: String) -> Texture2D:
	if node_name.contains("Music"):
		return ICON_MUSIC
	if node_name.contains("Sound"):
		return ICON_SOUND
	return ICON_VIBRATION


func _wire_button_motion(button: BaseButton) -> void:
	if button == null:
		return
	button.button_down.connect(func() -> void:
		button.pivot_offset = button.size * 0.5
		var tween_service := get_node_or_null("/root/GlobalTweens")
		if tween_service != null:
			tween_service.button_press(button, 0.055)
	)


func _energy_pulse(control: Control) -> void:
	var tween_service := get_node_or_null("/root/GlobalTweens")
	if tween_service != null:
		tween_service.energy_pulse(control, UiDesignSystemType.COLOR_BLUE_LIGHT, 0.16)


func _sync_switch_label(toggle: Button) -> void:
	if toggle != null:
		toggle.text = "ON" if toggle.button_pressed else "OFF"


func _sync_pause_switch_labels() -> void:
	_sync_switch_label(music_toggle)
	_sync_switch_label(sound_toggle)
	_sync_switch_label(vibration_toggle)


func set_privacy_options_available(available: bool) -> void:
	if privacy_options_button != null:
		privacy_options_button.visible = available


func _gem_texture_rect(node_name: String) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = node_name
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UiDesignSystemType.font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color(1.0, 0.96, 0.86, 0.76))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _decorate_header_label(label: Label) -> void:
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", UiDesignSystemType.COLOR_CORAL_DARK)


func _score_font_size(formatted: String) -> int:
	if formatted.length() <= 4:
		return 34
	if formatted.length() <= 6:
		return 30
	return 26


func _animate_score_change() -> void:
	_animate_coin_change()


func _set_coin_label(value: int) -> void:
	var formatted := ScoreFormatterType.format(value)
	if score_label.text == formatted:
		return
	score_label.text = formatted
	score_label.add_theme_font_size_override("font_size", _score_font_size(formatted))


func _animate_coin_change() -> void:
	_kill_tween(_score_tween)
	_kill_tween(_coin_icon_tween)
	score_label.pivot_offset = _node_center(score_label)
	coin_icon.pivot_offset = _node_center(coin_icon)
	score_label.scale = Vector2.ONE * 1.13
	coin_icon.scale = Vector2.ONE * 1.14
	coin_icon.rotation = 0.0
	if not is_inside_tree():
		score_label.scale = Vector2.ONE
		coin_icon.scale = Vector2.ONE
		coin_icon.rotation = 0.0
		return
	_score_tween = create_tween()
	_score_tween.tween_property(score_label, "scale", Vector2.ONE, GameConfig.COIN_COUNTER_PULSE_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_coin_icon_tween = create_tween().set_parallel(true)
	_coin_icon_tween.tween_property(coin_icon, "scale", Vector2.ONE, GameConfig.COIN_COUNTER_PULSE_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_coin_icon_tween.tween_property(coin_icon, "rotation", 0.0, GameConfig.COIN_COUNTER_PULSE_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _animate_next_swap() -> void:
	_kill_tween(_next_tween)
	next_icon.pivot_offset = _node_center(next_icon)
	next_icon.scale = Vector2.ONE * 0.82
	next_icon.modulate = Color(1.0, 1.0, 1.0, 0.35)
	if not is_inside_tree():
		next_icon.scale = Vector2.ONE
		next_icon.modulate = Color.WHITE
		return
	_next_tween = create_tween().set_parallel(true)
	_next_tween.tween_property(next_icon, "scale", Vector2.ONE, UiDesignSystemType.ICON_SWAP_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_next_tween.tween_property(next_icon, "modulate:a", 1.0, UiDesignSystemType.ICON_SWAP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _animate_target_swap(previous_texture: Texture2D, next_texture: Texture2D, next_name: String, next_header: String, next_state: String, next_maximum: int, next_value: int) -> void:
	_kill_tween(_target_swap_tween)
	if previous_texture == null or next_texture == null or not is_inside_tree():
		_apply_target_state(next_name, next_header, next_state, next_maximum, next_value)
		_finish_target_swap()
		return
	var icon_rect := target_icon.get_global_rect()
	var center := reward_foreground_host.to_local(icon_rect.get_center())
	var fitted_size := icon_rect.size
	_prepare_target_ghost(target_swap_outgoing, previous_texture, center, fitted_size, 1.0)
	_prepare_target_ghost(target_swap_incoming, next_texture, center, fitted_size, GameConfig.TARGET_SWAP_INCOMING_SCALE)
	target_swap_incoming.modulate.a = 0.0
	target_icon.modulate.a = 0.0
	target_panel.modulate = Color.WHITE
	_target_swap_tween = create_tween().set_parallel(true)
	_target_swap_tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	var outgoing_duration := GameConfig.TARGET_SWAP_OUTGOING_FADE_DURATION
	_target_swap_tween.tween_property(target_swap_outgoing, "modulate:a", 0.0, outgoing_duration).set_delay(GameConfig.TARGET_SWAP_START_DELAY).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_target_swap_tween.tween_property(target_panel, "modulate:a", 0.0, outgoing_duration).set_delay(GameConfig.TARGET_SWAP_START_DELAY).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var incoming_delay := GameConfig.TARGET_SWAP_START_DELAY + outgoing_duration + GameConfig.TARGET_SWAP_GAP_DURATION
	_target_swap_tween.tween_callback(_apply_target_state.bind(next_name, next_header, next_state, next_maximum, next_value)).set_delay(incoming_delay)
	_target_swap_tween.tween_property(target_swap_incoming, "modulate:a", 1.0, GameConfig.TARGET_SWAP_INCOMING_FADE_DURATION).set_delay(incoming_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_target_swap_tween.tween_property(target_panel, "modulate:a", 1.0, GameConfig.TARGET_SWAP_INCOMING_FADE_DURATION).set_delay(incoming_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_target_swap_tween.finished.connect(_finish_target_swap)


func _apply_target_state(target_name: String, header: String, state: String, maximum: int, value: int) -> void:
	target_name_label.text = target_name
	target_header_label.text = header
	target_status_label.text = state
	_set_target_progress(maximum, value)


func _set_target_progress(maximum: int, value: int) -> void:
	_kill_tween(_target_progress_tween)
	target_progress_bar.max_value = maximum
	var clamped_value := clampi(value, 0, maximum)
	if _snapshot.is_empty() or not is_inside_tree() or is_equal_approx(target_progress_bar.value, float(clamped_value)):
		target_progress_bar.value = clamped_value
		return
	_target_progress_tween = create_tween()
	_target_progress_tween.tween_property(target_progress_bar, "value", float(clamped_value), UiDesignSystemType.VALUE_CHANGE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _prepare_target_ghost(sprite: Sprite2D, texture: Texture2D, center: Vector2, fitted_size: Vector2, scale_multiplier: float) -> void:
	sprite.texture = texture
	sprite.position = center
	sprite.scale = _target_ghost_scale(texture, fitted_size) * scale_multiplier
	sprite.modulate = Color.WHITE
	sprite.visible = true


func _target_ghost_scale(texture: Texture2D, fitted_size: Vector2) -> Vector2:
	var texture_size := texture.get_size()
	var fit := minf(fitted_size.x / maxf(texture_size.x, 1.0), fitted_size.y / maxf(texture_size.y, 1.0))
	return Vector2.ONE * fit


func _finish_target_swap() -> void:
	if target_icon != null:
		target_icon.scale = Vector2.ONE
		target_icon.modulate = Color.WHITE
	if target_panel != null:
		target_panel.modulate = Color.WHITE
	if target_swap_outgoing != null:
		target_swap_outgoing.visible = false
	if target_swap_incoming != null:
		target_swap_incoming.visible = false


func _on_settings_button_down() -> void:
	_animate_settings_scale(0.94, UiDesignSystemType.BUTTON_PRESS_DURATION)


func _on_settings_button_up() -> void:
	_animate_settings_scale(1.0, UiDesignSystemType.BUTTON_RELEASE_DURATION)


func _animate_settings_scale(value: float, duration: float) -> void:
	_kill_tween(_settings_tween)
	settings_button.pivot_offset = _node_center(settings_button)
	if not is_inside_tree():
		settings_button.scale = Vector2.ONE * value
		return
	_settings_tween = create_tween()
	_settings_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_settings_tween.tween_property(settings_button, "scale", Vector2.ONE * value, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _finish_hide_pause() -> void:
	pause_blocker.visible = false
	pause_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_panel.scale = Vector2.ONE
	pause_panel.modulate = Color.WHITE
	pause_dimmer.color = UiDesignSystemType.COLOR_OVERLAY


func _refresh_safe_margins() -> void:
	if hud_margin == null or not is_inside_tree():
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_layout_scale = minf(1.0, viewport_size.x / UiDesignSystemType.DESIGN_WIDTH)
	var design_height := viewport_size.y / maxf(_layout_scale, 0.01)
	hud_canvas.offset_bottom = design_height
	hud_canvas.scale = Vector2.ONE * _layout_scale
	hud_canvas.position = Vector2(maxf(0.0, (viewport_size.x - UiDesignSystemType.DESIGN_WIDTH * _layout_scale) * 0.5), 0.0)
	var insets := _safe_insets()
	var base_margin := UiDesignSystemType.HUD_NARROW_MARGIN if viewport_size.x < UiDesignSystemType.DESIGN_WIDTH else UiDesignSystemType.HUD_MARGIN
	var inverse_scale := 1.0 / maxf(0.01, _layout_scale)
	var left_margin := int(ceil(maxf(base_margin, insets.x * inverse_scale + UiDesignSystemType.SAFE_INSET_PADDING)))
	var top_margin := int(ceil(maxf(base_margin, insets.y * inverse_scale + UiDesignSystemType.SAFE_INSET_PADDING)))
	var right_margin := int(ceil(maxf(base_margin, insets.z * inverse_scale + UiDesignSystemType.SAFE_INSET_PADDING)))
	var bottom_margin := int(ceil(maxf(base_margin, insets.w * inverse_scale + UiDesignSystemType.SAFE_INSET_PADDING)))

	# IMPORTANT: force the runtime header to the complete design width.  Using
	# only MarginContainer theme margins left the parent at its minimum width on
	# some layouts, which pulled Next/Settings toward Coins/Level.
	hud_margin.offset_left = 0.0
	hud_margin.offset_top = 0.0
	hud_margin.offset_right = UiDesignSystemType.DESIGN_WIDTH
	hud_margin.offset_bottom = top_margin + UiDesignSystemType.TOP_HUD_HEIGHT
	hud_margin.add_theme_constant_override("margin_left", left_margin)
	hud_margin.add_theme_constant_override("margin_top", top_margin)
	hud_margin.add_theme_constant_override("margin_right", right_margin)

	if bottom_progression_anchor != null:
		bottom_progression_anchor.offset_left = 0.0
		bottom_progression_anchor.offset_right = UiDesignSystemType.DESIGN_WIDTH
		bottom_progression_anchor.add_theme_constant_override("margin_left", left_margin)
		bottom_progression_anchor.add_theme_constant_override("margin_right", right_margin)
		bottom_progression_anchor.offset_top = design_height - bottom_margin - UiDesignSystemType.PROGRESSION_HEIGHT
		bottom_progression_anchor.offset_bottom = design_height - bottom_margin
	_apply_safe_margin(pause_safe_margin, insets)


func _safe_insets() -> Vector4:
	if _safe_insets_override.x >= 0.0:
		return _safe_insets_override
	if get_viewport() != get_tree().root:
		return Vector4.ZERO
	return UiDesignSystemType.safe_insets(get_viewport().get_visible_rect().size, Vector2(DisplayServer.window_get_size()), DisplayServer.get_display_safe_area())


func _apply_safe_margin(margin: MarginContainer, insets: Vector4) -> void:
	if margin == null:
		return
	margin.add_theme_constant_override("margin_left", int(ceil(maxf(16.0, insets.x + UiDesignSystemType.SAFE_INSET_PADDING))))
	margin.add_theme_constant_override("margin_top", int(ceil(maxf(16.0, insets.y + UiDesignSystemType.SAFE_INSET_PADDING))))
	margin.add_theme_constant_override("margin_right", int(ceil(maxf(16.0, insets.z + UiDesignSystemType.SAFE_INSET_PADDING))))
	margin.add_theme_constant_override("margin_bottom", int(ceil(maxf(16.0, insets.w + UiDesignSystemType.SAFE_INSET_PADDING))))


func _node_center(control: Control) -> Vector2:
	var node_size := control.size
	if node_size == Vector2.ZERO:
		node_size = control.custom_minimum_size
	return node_size * 0.5


func _kill_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
