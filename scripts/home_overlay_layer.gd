class_name HomeOverlayLayer
extends CanvasLayer

const AssetCatalogType = preload("res://scripts/asset_catalog.gd")
const ScoreFormatterType = preload("res://scripts/score_formatter.gd")
const UiDesignSystemType = preload("res://scripts/ui_design_system.gd")
const TweenComposerType = preload("res://tween_composer/tween_composer.gd")
const TweenSequenceType = preload("res://tween_composer/ConfigurationResources/tween_sequence_resource.gd")
const TweenStepCollectionType = preload("res://tween_composer/ConfigurationResources/tween_step_collection_resource.gd")
const TweenStepItemType = preload("res://tween_composer/ConfigurationResources/tween_step_item_resource.gd")
const ICON_SETTINGS = preload("res://assets/runtime/ui/icons/cog_blue.svg")
const ICON_PLAY = preload("res://assets/runtime/ui/icons/play_white.svg")
const ICON_CHECK = preload("res://assets/runtime/ui/icons/check_white.svg")
const ICON_BACK = preload("res://assets/runtime/ui/icons/back_navy.svg")
const ICON_MUSIC = preload("res://assets/runtime/ui/icons/note_navy.svg")
const ICON_SOUND = preload("res://assets/runtime/ui/icons/speaker_navy.svg")
const ICON_VIBRATION = preload("res://assets/runtime/ui/icons/vibration_navy.svg")

signal play_requested
signal music_toggled(enabled: bool)
signal sound_toggled(enabled: bool)
signal vibration_toggled(enabled: bool)

var root_control: Control
var safe_margin: MarginContainer
var top_controls_margin: MarginContainer
var content_panel: PanelContainer
var logo_rect: TextureRect
var level_label: Label
var coins_label: Label
var play_button: Button
var tagline_label: Label
var settings_button: TextureButton

var settings_blocker: Control
var settings_panel: PanelContainer
var settings_music_toggle: Button
var settings_sound_toggle: Button
var settings_vibration_toggle: Button

var level_intro_blocker: Control
var level_intro_panel: PanelContainer
var intro_level_label: Label
var intro_target_badge: Label
var intro_target_icon: TextureRect
var intro_objective_label: Label
var intro_start_button: Button

var _current_level := 1
var _current_coins := 0
var _snapshot: Dictionary = {}
var _entrance_tween: Tween
var _idle_tween: Tween
var _popup_tween: Tween
var _logo_motion_composer: Node
var _safe_insets_override := Vector4(-1.0, -1.0, -1.0, -1.0)

func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_refresh_safe_margins()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_refresh_safe_margins):
		viewport.size_changed.connect(_refresh_safe_margins)

func _unhandled_input(event: InputEvent) -> void:
	if not root_control.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if settings_blocker != null and settings_blocker.visible:
			_hide_settings()
			get_viewport().set_input_as_handled()
		elif level_intro_blocker != null and level_intro_blocker.visible:
			_hide_level_intro()
			get_viewport().set_input_as_handled()

func present(level_number: int, coins: int, snapshot: Dictionary = {}) -> void:
	_build()
	_current_level = level_number
	_current_coins = coins
	_snapshot = snapshot.duplicate(true)
	level_label.text = "LEVEL %d" % level_number
	coins_label.text = ScoreFormatterType.format(coins)
	play_button.text = "PLAY"
	play_button.tooltip_text = "Preview Level %d" % level_number
	_sync_settings_from_snapshot()
	_refresh_intro_content()
	settings_blocker.visible = false
	level_intro_blocker.visible = false
	root_control.visible = true
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	_start_entrance()
	if play_button.is_inside_tree():
		play_button.grab_focus()

func dismiss() -> void:
	_kill_tween()
	_kill_idle_tween()
	_kill_popup_tween()
	if root_control != null:
		root_control.visible = false
		root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_safe_insets_for_testing(insets: Vector4) -> void:
	_safe_insets_override = insets
	_refresh_safe_margins()

func layout_metrics() -> Dictionary:
	_build()
	return {
		"panel": content_panel.get_global_rect(),
		"logo": logo_rect.get_global_rect(),
		"button": play_button.get_global_rect(),
		"settings": settings_button.get_global_rect(),
		"settings_popup": settings_panel.get_global_rect(),
		"level_intro": level_intro_panel.get_global_rect(),
	}

func _build() -> void:
	if root_control != null:
		return
	root_control = Control.new()
	root_control.name = "HomeOverlayRoot"
	root_control.theme = UiDesignSystemType.theme()
	root_control.visible = false
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root_control)
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var backdrop := TextureRect.new()
	backdrop.name = "HomeTropicalBackdrop"
	backdrop.texture = AssetCatalogType.background_texture(0)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var wash := ColorRect.new()
	wash.name = "HomeReadabilityWash"
	wash.color = Color(0.02, 0.25, 0.30, 0.12)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(wash)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	safe_margin = MarginContainer.new()
	safe_margin.name = "HomeSafeArea"
	safe_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(safe_margin)
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.name = "HomeCenter"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_margin.add_child(center)

	content_panel = PanelContainer.new()
	content_panel.name = "HomeContentPanel"
	content_panel.custom_minimum_size = Vector2(560.0, 980.0)
	content_panel.add_theme_stylebox_override("panel", UiDesignSystemType.home_stage_style())
	content_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(content_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 18)
	content_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)

	var hero := CenterContainer.new()
	hero.name = "LogoHero"
	hero.custom_minimum_size = Vector2(540.0, 470.0)
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(hero)
	logo_rect = TextureRect.new()
	logo_rect.name = "CrystalMagicLogo"
	logo_rect.texture = AssetCatalogType.BRAND_LOGO
	logo_rect.custom_minimum_size = Vector2(540.0, 470.0)
	logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(logo_rect)
	_logo_motion_composer = _attach_scale_loop(logo_rect, "HomeLogoBreath", 1.018, 2.10)

	tagline_label = _label("A TROPICAL GEM ADVENTURE", 17, Color.WHITE)
	tagline_label.custom_minimum_size = Vector2(0.0, 34.0)
	tagline_label.add_theme_constant_override("outline_size", 6)
	tagline_label.add_theme_color_override("font_outline_color", Color(0.02, 0.30, 0.34, 0.85))
	column.add_child(tagline_label)

	var status_row := HBoxContainer.new()
	status_row.name = "HomePlayerStatus"
	status_row.custom_minimum_size = Vector2(492.0, 94.0)
	status_row.alignment = BoxContainer.ALIGNMENT_CENTER
	status_row.add_theme_constant_override("separation", 16)
	column.add_child(status_row)

	var level_card := _home_status_card("LevelCard")
	level_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(level_card)
	var level_col := VBoxContainer.new()
	level_col.alignment = BoxContainer.ALIGNMENT_CENTER
	level_card.add_child(level_col)
	var level_caption := _label("CURRENT LEVEL", 13, UiDesignSystemType.COLOR_TEXT_MUTED)
	level_col.add_child(level_caption)
	level_label = _label("LEVEL 1", 28, UiDesignSystemType.COLOR_BLUE_DEEP)
	level_col.add_child(level_label)

	var coin_card := _home_status_card("CoinCard")
	coin_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(coin_card)
	var coin_row := HBoxContainer.new()
	coin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	coin_row.add_theme_constant_override("separation", 10)
	coin_card.add_child(coin_row)
	var coin := TextureRect.new()
	coin.texture = AssetCatalogType.COIN_REWARD
	coin.custom_minimum_size = Vector2(42.0, 42.0)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_row.add_child(coin)
	var coin_col := VBoxContainer.new()
	coin_col.alignment = BoxContainer.ALIGNMENT_CENTER
	coin_row.add_child(coin_col)
	var coin_caption := _label("COINS", 13, UiDesignSystemType.COLOR_TEXT_MUTED)
	coin_col.add_child(coin_caption)
	coins_label = _label("0", 28, UiDesignSystemType.COLOR_BLUE_DEEP)
	coin_col.add_child(coins_label)

	play_button = Button.new()
	play_button.name = "HomePlayButton"
	play_button.text = "PLAY"
	play_button.icon = ICON_PLAY
	play_button.expand_icon = false
	play_button.custom_minimum_size = Vector2(492.0, 94.0)
	play_button.focus_mode = Control.FOCUS_ALL
	play_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	play_button.pressed.connect(_show_level_intro)
	_wire_button_motion(play_button)
	column.add_child(play_button)

	_build_top_settings_control()
	_build_settings_popup()
	_build_level_intro_popup()

func _build_top_settings_control() -> void:
	top_controls_margin = MarginContainer.new()
	top_controls_margin.name = "HomeTopControls"
	top_controls_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(top_controls_margin)
	top_controls_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_controls_margin.add_child(row)
	var frame := PanelContainer.new()
	frame.name = "HomeSettingsFrame"
	frame.custom_minimum_size = Vector2(94.0, 94.0)
	# HBoxContainer fills children on its cross axis unless they explicitly shrink.
	# Without this, the 94px settings card stretched into a full-height glass rail.
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	frame.size_flags_horizontal = Control.SIZE_SHRINK_END
	frame.add_theme_stylebox_override("panel", UiDesignSystemType.utility_frame_style())
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(frame)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(center)
	settings_button = TextureButton.new()
	settings_button.name = "HomeSettingsButton"
	settings_button.texture_normal = ICON_SETTINGS
	settings_button.texture_hover = ICON_SETTINGS
	settings_button.texture_pressed = ICON_SETTINGS
	settings_button.ignore_texture_size = true
	settings_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	settings_button.custom_minimum_size = Vector2(78.0, 78.0)
	settings_button.focus_mode = Control.FOCUS_ALL
	settings_button.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_button.tooltip_text = "Settings"
	settings_button.pressed.connect(_show_settings)
	_wire_button_motion(settings_button)
	center.add_child(settings_button)

func _build_settings_popup() -> void:
	settings_blocker = _popup_blocker("HomeSettingsBlocker")
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings_blocker.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_panel = PanelContainer.new()
	settings_panel.name = "HomeSettingsPanel"
	settings_panel.custom_minimum_size = Vector2(500.0, 520.0)
	settings_panel.add_theme_stylebox_override("panel", UiDesignSystemType.gameplay_modal_panel_style())
	settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(settings_panel)
	var margin := _popup_margin(44, 34, 44, 34)
	settings_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	var title := _label("SETTINGS", 34, UiDesignSystemType.COLOR_BLUE_DEEP)
	title.custom_minimum_size = Vector2(0, 58)
	column.add_child(title)
	var subtitle := _label("MAKE CRYSTAL MAGIC YOURS", 14, UiDesignSystemType.COLOR_TEXT_MUTED)
	subtitle.custom_minimum_size = Vector2(0, 30)
	column.add_child(subtitle)
	settings_music_toggle = _setting_switch_row(column, "MUSIC", "HomeMusicToggle")
	settings_music_toggle.toggled.connect(func(enabled: bool) -> void:
		_sync_switch_label(settings_music_toggle)
		music_toggled.emit(enabled)
	)
	settings_sound_toggle = _setting_switch_row(column, "SOUND FX", "HomeSoundToggle")
	settings_sound_toggle.toggled.connect(func(enabled: bool) -> void:
		_sync_switch_label(settings_sound_toggle)
		sound_toggled.emit(enabled)
	)
	settings_vibration_toggle = _setting_switch_row(column, "VIBRATION", "HomeVibrationToggle")
	settings_vibration_toggle.toggled.connect(func(enabled: bool) -> void:
		_sync_switch_label(settings_vibration_toggle)
		vibration_toggled.emit(enabled)
	)
	var done := _button("HomeSettingsDone", "DONE", Vector2(400.0, 82.0), "")
	done.icon = ICON_CHECK
	done.expand_icon = false
	done.pressed.connect(_hide_settings)
	column.add_child(done)

func _build_level_intro_popup() -> void:
	level_intro_blocker = _popup_blocker("LevelIntroBlocker")
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_intro_blocker.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	level_intro_panel = PanelContainer.new()
	level_intro_panel.name = "LevelIntroPanel"
	level_intro_panel.custom_minimum_size = Vector2(520.0, 600.0)
	level_intro_panel.add_theme_stylebox_override("panel", UiDesignSystemType.gameplay_modal_panel_style())
	level_intro_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(level_intro_panel)
	var margin := _popup_margin(48, 34, 48, 36)
	level_intro_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	var eyebrow := _label("READY FOR", 15, UiDesignSystemType.COLOR_TEXT_MUTED)
	column.add_child(eyebrow)
	intro_level_label = _label("LEVEL 1", 38, UiDesignSystemType.COLOR_BLUE_DEEP)
	intro_level_label.custom_minimum_size = Vector2(0, 60)
	column.add_child(intro_level_label)
	intro_target_badge = _label("TARGET 1 / 1", 18, Color.WHITE)
	intro_target_badge.custom_minimum_size = Vector2(210, 48)
	intro_target_badge.add_theme_stylebox_override("normal", UiDesignSystemType.target_badge_style())
	column.add_child(intro_target_badge)
	intro_target_icon = TextureRect.new()
	intro_target_icon.name = "LevelIntroTargetGem"
	intro_target_icon.custom_minimum_size = Vector2(132, 132)
	intro_target_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	intro_target_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	intro_target_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(intro_target_icon)
	intro_objective_label = _label("MERGE THE TARGET GEM", 24, UiDesignSystemType.COLOR_TEXT)
	intro_objective_label.custom_minimum_size = Vector2(400, 70)
	intro_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(intro_objective_label)
	intro_start_button = _button("StartLevelButton", "START GAME", Vector2(400.0, 88.0), "")
	intro_start_button.icon = ICON_PLAY
	intro_start_button.expand_icon = false
	intro_start_button.tooltip_text = "Start Level"
	intro_start_button.pressed.connect(func() -> void:
		_hide_level_intro()
		play_requested.emit()
	)
	column.add_child(intro_start_button)
	var cancel := _button("LevelIntroCancel", "BACK", Vector2(400.0, 68.0), "SecondaryButton")
	cancel.icon = ICON_BACK
	cancel.expand_icon = false
	cancel.pressed.connect(_hide_level_intro)
	column.add_child(cancel)

func _home_status_card(node_name: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = node_name
	card.custom_minimum_size = Vector2(0.0, 94.0)
	card.add_theme_stylebox_override("panel", UiDesignSystemType.home_status_card_style())
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card

func _popup_blocker(node_name: String) -> Control:
	var blocker := Control.new()
	blocker.name = node_name
	blocker.process_mode = Node.PROCESS_MODE_ALWAYS
	blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blocker.visible = false
	root_control.add_child(blocker)
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dimmer := ColorRect.new()
	dimmer.color = UiDesignSystemType.COLOR_OVERLAY
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.add_child(dimmer)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return blocker

func _popup_margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return margin

func _setting_switch_row(parent: VBoxContainer, text: String, node_name: String) -> Button:
	var frame := PanelContainer.new()
	frame.name = "%sRow" % node_name
	frame.custom_minimum_size = Vector2(400.0, 64.0)
	frame.add_theme_stylebox_override("panel", UiDesignSystemType.setting_row_style())
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(frame)
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, 64.0)
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
		GlobalTweens.energy_pulse(toggle, UiDesignSystemType.COLOR_BLUE_LIGHT, 0.16)
	)
	row.add_child(toggle)
	return toggle

func _setting_icon_texture(node_name: String) -> Texture2D:
	if node_name.contains("Music"):
		return ICON_MUSIC
	if node_name.contains("Sound"):
		return ICON_SOUND
	return ICON_VIBRATION

func _sync_settings_from_snapshot() -> void:
	if settings_music_toggle == null:
		return
	settings_music_toggle.set_pressed_no_signal(bool(_snapshot.get("music_enabled", true)))
	settings_sound_toggle.set_pressed_no_signal(bool(_snapshot.get("sound_enabled", true)))
	settings_vibration_toggle.set_pressed_no_signal(bool(_snapshot.get("vibration_enabled", true)))
	_sync_switch_label(settings_music_toggle)
	_sync_switch_label(settings_sound_toggle)
	_sync_switch_label(settings_vibration_toggle)

func _sync_switch_label(toggle: Button) -> void:
	if toggle != null:
		toggle.text = "ON" if toggle.button_pressed else "OFF"

func _refresh_intro_content() -> void:
	if intro_level_label == null:
		return
	intro_level_label.text = "LEVEL %d" % _current_level
	var target_level := int(_snapshot.get("target_level", 1))
	var target_index := int(_snapshot.get("target_index", 0)) + 1
	var target_total := maxi(1, int(_snapshot.get("target_total", 1)))
	var target_quantity := maxi(1, int(_snapshot.get("target_quantity", 1)))
	intro_target_badge.text = "TARGET %d / %d" % [target_index, target_total]
	intro_target_icon.texture = AssetCatalogType.gem_texture(target_level)
	var gem_name := AssetCatalogType.gem_name(target_level).to_upper()
	intro_objective_label.text = "MERGE %d × %s" % [target_quantity, gem_name]

func _show_settings() -> void:
	_sync_settings_from_snapshot()
	_show_popup(settings_blocker, settings_panel)

func _hide_settings() -> void:
	_hide_popup(settings_blocker)
	if settings_button != null:
		settings_button.grab_focus()

func _show_level_intro() -> void:
	_refresh_intro_content()
	_show_popup(level_intro_blocker, level_intro_panel)
	if intro_start_button != null:
		intro_start_button.grab_focus()

func _hide_level_intro() -> void:
	_hide_popup(level_intro_blocker)
	if play_button != null:
		play_button.grab_focus()

func _show_popup(blocker: Control, panel: Control) -> void:
	_kill_popup_tween()
	blocker.visible = true
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2.ONE * 0.92
	panel.modulate = Color(1, 1, 1, 0)
	_popup_tween = create_tween().set_parallel(true)
	_popup_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_popup_tween.tween_property(panel, "scale", Vector2.ONE, UiDesignSystemType.POPUP_ENTER_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_popup_tween.tween_property(panel, "modulate:a", 1.0, UiDesignSystemType.POPUP_ENTER_DURATION * 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _hide_popup(blocker: Control) -> void:
	if blocker != null:
		blocker.visible = false
		blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE

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

func _start_entrance() -> void:
	_kill_tween()
	content_panel.pivot_offset = content_panel.size * 0.5
	content_panel.scale = Vector2.ONE * 0.94
	content_panel.modulate = Color(1, 1, 1, 0)
	if not is_inside_tree():
		content_panel.scale = Vector2.ONE
		content_panel.modulate = Color.WHITE
		return
	_entrance_tween = create_tween().set_parallel(true)
	_entrance_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_entrance_tween.tween_property(content_panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_entrance_tween.tween_property(content_panel, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_entrance_tween.finished.connect(_start_idle_motion, CONNECT_ONE_SHOT)

func _start_idle_motion() -> void:
	_kill_idle_tween()
	if not is_inside_tree() or root_control == null or not root_control.visible:
		return
	logo_rect.pivot_offset = logo_rect.size * 0.5
	play_button.pivot_offset = play_button.size * 0.5
	_restart_motion_composer(_logo_motion_composer)


func _attach_scale_loop(target: Control, sequence_name: String, scale_factor: float, duration: float) -> Node:
	var sequence = TweenSequenceType.new()
	sequence.sequence_name = sequence_name
	sequence.tween_duration = duration
	sequence.loop = true
	sequence.loop_repetitions = 0
	sequence.persist_tween_information = true
	var steps = TweenStepCollectionType.new()
	steps.tween_name = sequence_name
	var grow = TweenStepItemType.new()
	grow.step_name = "Ease Out"
	grow.tween_property = 2 # TweenStepItem.TweenOptions.SCALE
	grow.relative_value = false
	grow.transition = Tween.TRANS_SINE
	grow.easing = Tween.EASE_IN_OUT
	grow.duration_ratio = 1.0
	grow.target_value = Vector3(scale_factor, scale_factor, 1.0)
	steps.step_collection.append(grow)
	var settle = TweenStepItemType.new()
	settle.step_name = "Ease Home"
	settle.tween_property = 2 # TweenStepItem.TweenOptions.SCALE
	settle.relative_value = false
	settle.transition = Tween.TRANS_SINE
	settle.easing = Tween.EASE_IN_OUT
	settle.duration_ratio = 1.0
	settle.target_value = Vector3(1.0, 1.0, 1.0)
	steps.step_collection.append(settle)
	sequence.tween_steps = steps
	var composer = TweenComposerType.new()
	composer.name = "%sTweenComposer" % sequence_name
	composer.tween_sequence = sequence
	composer.autostart = false
	composer.set_pause_mode = Tween.TWEEN_PAUSE_PROCESS
	target.add_child(composer)
	return composer


func _restart_motion_composer(composer: Node) -> void:
	if composer == null or not is_instance_valid(composer):
		return
	composer.reset_tween()
	composer.play_tween()


func _reset_motion_composer(composer: Node) -> void:
	if composer != null and is_instance_valid(composer):
		composer.reset_tween()


func _wire_button_motion(button: BaseButton) -> void:
	if button == null:
		return
	button.button_down.connect(func() -> void:
		button.pivot_offset = button.size * 0.5
		GlobalTweens.button_press(button, 0.055)
	)

func _refresh_safe_margins() -> void:
	if safe_margin == null or not is_inside_tree():
		return
	var insets := _safe_insets()
	for container in [safe_margin, top_controls_margin]:
		if container == null:
			continue
		for entry in [["left", insets.x], ["top", insets.y], ["right", insets.z], ["bottom", insets.w]]:
			container.add_theme_constant_override("margin_%s" % entry[0], int(ceil(maxf(18.0, float(entry[1]) + UiDesignSystemType.SAFE_INSET_PADDING))))

func _safe_insets() -> Vector4:
	if _safe_insets_override.x >= 0.0:
		return _safe_insets_override
	if get_viewport() != get_tree().root:
		return Vector4.ZERO
	return UiDesignSystemType.safe_insets(get_viewport().get_visible_rect().size, Vector2(DisplayServer.window_get_size()), DisplayServer.get_display_safe_area())

func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UiDesignSystemType.font())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color(1, 0.97, 0.88, 0.72))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _kill_tween() -> void:
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()

func _kill_idle_tween() -> void:
	if _idle_tween != null and _idle_tween.is_valid():
		_idle_tween.kill()
	_reset_motion_composer(_logo_motion_composer)
	if logo_rect != null:
		logo_rect.scale = Vector2.ONE
		logo_rect.rotation = 0.0
	if play_button != null:
		play_button.scale = Vector2.ONE

func _kill_popup_tween() -> void:
	if _popup_tween != null and _popup_tween.is_valid():
		_popup_tween.kill()
