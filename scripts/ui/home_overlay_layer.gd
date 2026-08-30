class_name HomeOverlayLayer
extends CanvasLayer

const AssetCatalogType = preload("res://scripts/core/asset_catalog.gd")
const ScoreFormatterType = preload("res://scripts/core/score_formatter.gd")
const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")
const TweenComposerType = preload("res://tween_composer/tween_composer.gd")
const TweenSequenceType = preload("res://tween_composer/ConfigurationResources/tween_sequence_resource.gd")
const TweenStepCollectionType = preload("res://tween_composer/ConfigurationResources/tween_step_collection_resource.gd")
const TweenStepItemType = preload("res://tween_composer/ConfigurationResources/tween_step_item_resource.gd")
const UiKitType = preload("res://scripts/ui/ui_kit.gd")
const DailyMissionServiceType = preload("res://scripts/services/daily_mission_service.gd")
const ICON_SETTINGS = preload("res://assets/runtime/ui/kit/icon_gear.png")
## The Home shop entry point. A de-fringed derivative of the supplied stall art.

## A compact brand mark rather than a hero panel. Home is a game screen, so the
## logo identifies the game and then gets out of the way.
const LOGO_SIZE := Vector2(424.0, 259.0)
const ICON_PLAY = preload("res://assets/runtime/ui/icons/play_white.svg")
const ICON_CHECK = preload("res://assets/runtime/ui/icons/check_white.svg")
const ICON_BACK = preload("res://assets/runtime/ui/icons/back_lavender.svg")
const ICON_MUSIC = preload("res://assets/runtime/ui/icons/note_lavender.svg")
const ICON_SOUND = preload("res://assets/runtime/ui/icons/speaker_lavender.svg")
const ICON_SKIP = preload("res://assets/runtime/ui/icons/fast_forward_lavender.svg")

signal play_requested
signal level_intro_requested
signal skip_level_requested
signal home_requested
signal music_toggled(enabled: bool)
signal sound_toggled(enabled: bool)
signal privacy_policy_requested
signal privacy_options_requested
signal ui_tap_requested
signal exit_requested
signal daily_missions_requested
signal power_shop_requested

var root_control: Control
var home_backdrop: TextureRect
var home_wash: ColorRect
var safe_margin: MarginContainer
var top_controls_margin: MarginContainer
var content_panel: PanelContainer
var logo_rect: TextureRect
var level_label: Label
var coins_label: Label
var play_button: Button
var daily_button: Button
var daily_badges_row: HBoxContainer
var daily_status_label: Label
var tagline_label: Label
var settings_button: Button
var powers_button: Button
var privacy_link_margin: MarginContainer
var privacy_policy_link: LinkButton

var settings_blocker: Control
var settings_panel: PanelContainer
var settings_music_toggle: Button
var settings_sound_toggle: Button
var settings_privacy_options_button: Button

var level_intro_blocker: Control
var level_intro_panel: PanelContainer
var intro_level_label: Label
var intro_target_badge: Label
var intro_target_icon: TextureRect
var intro_objective_label: Label
var intro_start_button: Button
var intro_skip_button: Button

var exit_confirm_blocker: Control
var exit_confirm_panel: PanelContainer
var exit_cancel_button: Button
var exit_button: Button

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
		if handle_back_request():
			get_viewport().set_input_as_handled()


func handle_back_request() -> bool:
	if root_control == null or not root_control.visible:
		return false
	if exit_confirm_blocker != null and exit_confirm_blocker.visible:
		_hide_exit_confirmation()
		return true
	if settings_blocker != null and settings_blocker.visible:
		_hide_settings()
		return true
	if level_intro_blocker != null and level_intro_blocker.visible:
		# Level Ready never begins play from Back. It returns through the
		# controller-owned Home transition instead of trapping the player.
		home_requested.emit()
		return true
	return false

func present(level_number: int, coins: int, snapshot: Dictionary = {}) -> void:
	_build()
	# Establish the visible Home surface before optional snapshot/motion work.
	# If a presentation dependency ever fails, gameplay must not remain exposed
	# while the controller believes Home owns navigation.
	root_control.visible = true
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_home_stage_visible(true)
	settings_blocker.visible = false
	level_intro_blocker.visible = false
	exit_confirm_blocker.visible = false
	_current_level = level_number
	_current_coins = coins
	_snapshot = snapshot.duplicate(true)
	level_label.text = "LEVEL %d" % level_number
	coins_label.text = ScoreFormatterType.format(coins)
	play_button.text = "PLAY"
	play_button.tooltip_text = "Preview Level %d" % level_number
	_sync_settings_from_snapshot()
	_refresh_intro_content()
	_refresh_daily_card()
	_start_entrance()
	if play_button.is_inside_tree():
		play_button.grab_focus()


func present_level_intro(level_number: int, coins: int, snapshot: Dictionary = {}) -> void:
	present(level_number, coins, snapshot)
	_kill_tween()
	_kill_idle_tween()
	_set_home_stage_visible(false)
	_show_level_intro()


func update_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	_sync_settings_from_snapshot()
	_refresh_intro_content()
	_refresh_daily_card()

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
		"privacy_link": privacy_policy_link.get_global_rect(),
		"settings_popup": settings_panel.get_global_rect(),
		"level_intro": level_intro_panel.get_global_rect(),
		"exit_confirmation": exit_confirm_panel.get_global_rect(),
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

	home_backdrop = TextureRect.new()
	home_backdrop.name = "HomeTropicalBackdrop"
	home_backdrop.texture = AssetCatalogType.background_texture(0)
	home_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	home_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	home_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(home_backdrop)
	home_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	home_wash = ColorRect.new()
	home_wash.name = "HomeReadabilityWash"
	home_wash.color = Color(0.02, 0.25, 0.30, 0.12)
	home_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(home_wash)
	home_wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

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

	# The logo is branding, not gameplay, so it is a compact mark at the top of
	# the screen instead of a hero that owns half the layout. Every row below it
	# is something the player can act on.
	var hero := CenterContainer.new()
	hero.name = "LogoHero"
	hero.custom_minimum_size = Vector2(LOGO_SIZE.x, LOGO_SIZE.y)
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(hero)
	logo_rect = TextureRect.new()
	logo_rect.name = "MajesticGemsLogo"
	logo_rect.texture = AssetCatalogType.BRAND_LOGO
	logo_rect.custom_minimum_size = LOGO_SIZE
	logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(logo_rect)
	_logo_motion_composer = _attach_scale_loop(logo_rect, "HomeLogoBreath", 1.018, 2.10)

	# The tagline is retained as a hidden node so existing lookups keep working,
	# but it no longer occupies a row: the space belongs to the game.
	tagline_label = _label("A Majestic World of Gems", UiDesignSystemType.TAGLINE_FONT_SIZE, UiDesignSystemType.COLOR_GOLD_LIGHT)
	tagline_label.visible = false
	column.add_child(tagline_label)

	column.add_child(_build_daily_card())

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
	var level_caption := _label("CURRENT LEVEL", UiDesignSystemType.CAPTION_FONT_SIZE, UiDesignSystemType.COLOR_GOLD_LIGHT)
	level_col.add_child(level_caption)
	level_label = _label("LEVEL 1", UiDesignSystemType.PANEL_TITLE_FONT_SIZE + 4, Color.WHITE)
	level_label.add_theme_font_override("font", UiDesignSystemType.heavy_font())
	level_col.add_child(level_label)

	var coin_card := _home_status_card("CoinCard")
	coin_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(coin_card)
	var coin_row := HBoxContainer.new()
	coin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	coin_row.add_theme_constant_override("separation", 10)
	coin_card.add_child(coin_row)
	coin_row.add_child(UiKitType.texture_rect(UiKitType.ICON_COIN, 52.0))
	var coin_col := VBoxContainer.new()
	coin_col.alignment = BoxContainer.ALIGNMENT_CENTER
	coin_row.add_child(coin_col)
	coins_label = _label("0", UiDesignSystemType.PANEL_TITLE_FONT_SIZE + 4, Color.WHITE)
	coins_label.add_theme_font_override("font", UiDesignSystemType.heavy_font())
	coin_col.add_child(coins_label)

	play_button = Button.new()
	play_button.name = "HomePlayButton"
	play_button.text = "PLAY"
	# The hero variation carries its own ornamented plate, so the old glyph icon
	# would sit as a second, competing decoration inside the same button.
	play_button.theme_type_variation = "HeroButton"
	play_button.custom_minimum_size = Vector2(516.0, UiDesignSystemType.HERO_BUTTON_HEIGHT)
	play_button.focus_mode = Control.FOCUS_ALL
	play_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	play_button.pressed.connect(func() -> void: level_intro_requested.emit())
	_wire_button_motion(play_button)

	column.add_child(play_button)

	# The shop sits below PLAY in the same decorative banner the Daily Missions
	# header uses, so the two entry points read as one family and the hero button
	# keeps its full width.
	powers_button = Button.new()
	powers_button.name = "HomePowersButton"
	# Deliberately narrower and shorter than PLAY, on the plain secondary pill
	# rather than the ornamental gold frame: PLAY is the one hero action on this
	# screen and the shop must read as clearly subordinate to it.
	powers_button.custom_minimum_size = Vector2(360.0, UiDesignSystemType.BUTTON_HEIGHT)
	powers_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for state in ["normal", "hover", "pressed", "focus"]:
		powers_button.add_theme_stylebox_override(
			state, UiKitType.nine_patch_style("btn_pill_plain", Vector4(46.0, 10.0, 46.0, 12.0)))
	powers_button.focus_mode = Control.FOCUS_ALL
	powers_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	powers_button.tooltip_text = "Shop — buy powers"
	powers_button.pressed.connect(func() -> void:
		ui_tap_requested.emit()
		power_shop_requested.emit()
	)
	_wire_button_motion(powers_button)
	column.add_child(powers_button)

	# Caption only. The shop illustration read as a second competing focal point
	# beside PLAY and against the plate art, so the button carries just its word.
	var shop_caption := _label("SHOP", UiDesignSystemType.BODY_FONT_SIZE, Color.WHITE)
	shop_caption.name = "HomeShopCaption"
	shop_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shop_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	powers_button.add_child(shop_caption)
	shop_caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_build_top_settings_control()
	_build_privacy_policy_link()
	_build_settings_popup()
	_build_level_intro_popup()
	_build_exit_confirmation_popup()

func _build_top_settings_control() -> void:
	top_controls_margin = MarginContainer.new()
	top_controls_margin.name = "HomeTopControls"
	top_controls_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(top_controls_margin)
	# Historical placement: the literal top-right of the Home screen.
	top_controls_margin.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_controls_margin.offset_left = -96.0
	top_controls_margin.offset_top = 24.0
	top_controls_margin.offset_right = -18.0
	top_controls_margin.offset_bottom = 102.0
	settings_button = Button.new()
	settings_button.name = "HomeSettingsButton"
	settings_button.icon = ICON_SETTINGS
	settings_button.expand_icon = true
	settings_button.custom_minimum_size = Vector2(78.0, 78.0)
	settings_button.add_theme_stylebox_override("normal", UiDesignSystemType.utility_frame_style())
	settings_button.add_theme_stylebox_override("hover", UiDesignSystemType.utility_frame_style())
	settings_button.add_theme_stylebox_override("pressed", UiDesignSystemType.utility_frame_style())
	settings_button.self_modulate = Color("ead4ff")
	settings_button.focus_mode = Control.FOCUS_ALL
	settings_button.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_button.tooltip_text = "Settings"
	settings_button.pressed.connect(_show_settings)
	_wire_button_motion(settings_button)
	top_controls_margin.add_child(settings_button)

func _build_privacy_policy_link() -> void:
	privacy_link_margin = MarginContainer.new()
	privacy_link_margin.name = "HomePrivacyLinkMargin"
	privacy_link_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(privacy_link_margin)
	privacy_link_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	privacy_link_margin.grow_horizontal = Control.GROW_DIRECTION_BOTH
	privacy_link_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	privacy_link_margin.offset_top = -96.0
	privacy_link_margin.offset_bottom = 0.0
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	privacy_link_margin.add_child(center)
	privacy_policy_link = LinkButton.new()
	privacy_policy_link.name = "HomePrivacyPolicyLink"
	privacy_policy_link.text = "Privacy Policy"
	privacy_policy_link.underline = LinkButton.UNDERLINE_MODE_ALWAYS
	# LinkButton draws its text at the start of its own box. Giving it a fixed
	# 180px box centered the hit target but left the visible words 30px left of
	# screen center. Let the centered parent size the link to its text instead.
	privacy_policy_link.custom_minimum_size = Vector2(0.0, 46.0)
	privacy_policy_link.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	privacy_policy_link.focus_mode = Control.FOCUS_ALL
	privacy_policy_link.mouse_filter = Control.MOUSE_FILTER_STOP
	privacy_policy_link.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	privacy_policy_link.add_theme_font_override("font", UiDesignSystemType.font())
	privacy_policy_link.add_theme_font_size_override("font_size", 16)
	privacy_policy_link.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.94))
	privacy_policy_link.add_theme_color_override("font_hover_color", UiDesignSystemType.COLOR_BLUE_LIGHT)
	privacy_policy_link.add_theme_constant_override("outline_size", 4)
	privacy_policy_link.add_theme_color_override("font_outline_color", Color(0.02, 0.22, 0.28, 0.82))
	privacy_policy_link.tooltip_text = "Open the Majestic Gems Privacy Policy"
	privacy_policy_link.pressed.connect(func() -> void: privacy_policy_requested.emit())
	_wire_button_motion(privacy_policy_link)
	center.add_child(privacy_policy_link)

func _build_settings_popup() -> void:
	settings_blocker = _popup_blocker("HomeSettingsBlocker")
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings_blocker.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_panel = PanelContainer.new()
	settings_panel.name = "HomeSettingsPanel"
	settings_panel.custom_minimum_size = Vector2(520.0, 500.0)
	settings_panel.add_theme_stylebox_override("panel", UiDesignSystemType.gameplay_modal_panel_style())
	settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(settings_panel)
	var margin := _popup_margin(44, 34, 44, 34)
	settings_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	# Settings was the only modal still announcing itself with a bare label while
	# every other popup uses the gold ribbon.
	var title_banner := PanelContainer.new()
	title_banner.name = "SettingsTitleBanner"
	title_banner.custom_minimum_size = Vector2(0.0, UiDesignSystemType.BANNER_HEIGHT)
	title_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_banner.add_theme_stylebox_override("panel", UiKitType.nine_patch_style("bar_gold_frame", Vector4(76.0, 12.0, 76.0, 14.0)))
	column.add_child(title_banner)
	var title := _label("SETTINGS", UiDesignSystemType.POPUP_TITLE_FONT_SIZE, Color.WHITE)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_banner.add_child(title)
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
	settings_privacy_options_button = _button("HomePrivacyOptions", "PRIVACY OPTIONS", Vector2(400.0, UiDesignSystemType.BUTTON_HEIGHT), "SecondaryButton")
	settings_privacy_options_button.visible = false
	settings_privacy_options_button.pressed.connect(func() -> void: privacy_options_requested.emit())
	column.add_child(settings_privacy_options_button)
	var done := _button("HomeSettingsDone", "DONE", Vector2(400.0, UiDesignSystemType.BUTTON_HEIGHT), "")
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
	level_intro_panel.custom_minimum_size = Vector2(540.0, 700.0)
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
	intro_start_button = _button("StartLevelButton", "START GAME", Vector2(400.0, UiDesignSystemType.BUTTON_HEIGHT), "")
	intro_start_button.icon = ICON_PLAY
	intro_start_button.expand_icon = false
	intro_start_button.tooltip_text = "Start Level"
	intro_start_button.pressed.connect(func() -> void:
		_hide_level_intro()
		play_requested.emit()
	)
	column.add_child(intro_start_button)
	intro_skip_button = _button("LevelIntroSkipButton", "SKIP LEVEL  ·  %d COINS" % GameConfig.SKIP_LEVEL_COST, Vector2(400.0, UiDesignSystemType.BUTTON_HEIGHT), "SecondaryButton")
	intro_skip_button.icon = ICON_SKIP
	intro_skip_button.expand_icon = false
	intro_skip_button.tooltip_text = "Skip this level"
	intro_skip_button.pressed.connect(func() -> void: skip_level_requested.emit())
	column.add_child(intro_skip_button)


func _build_exit_confirmation_popup() -> void:
	exit_confirm_blocker = _popup_blocker("ExitConfirmationBlocker")
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	exit_confirm_blocker.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	exit_confirm_panel = PanelContainer.new()
	exit_confirm_panel.name = "ExitConfirmationPanel"
	exit_confirm_panel.custom_minimum_size = Vector2(520.0, 340.0)
	exit_confirm_panel.add_theme_stylebox_override("panel", UiDesignSystemType.gameplay_modal_panel_style())
	exit_confirm_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(exit_confirm_panel)
	var margin := _popup_margin(42, 30, 42, 32)
	exit_confirm_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)
	var title := _label("EXIT GAME?", 34, UiDesignSystemType.COLOR_BLUE_DEEP)
	title.custom_minimum_size = Vector2(0.0, 58.0)
	column.add_child(title)
	var message := _label("Your progress is saved.", 17, UiDesignSystemType.COLOR_TEXT_MUTED)
	message.custom_minimum_size = Vector2(0.0, 42.0)
	column.add_child(message)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	column.add_child(actions)
	exit_cancel_button = _button("ExitCancelButton", "CANCEL", Vector2(196.0, UiDesignSystemType.BUTTON_HEIGHT), "SecondaryButton")
	exit_cancel_button.pressed.connect(_hide_exit_confirmation)
	actions.add_child(exit_cancel_button)
	exit_button = _button("ExitGameButton", "EXIT", Vector2(196.0, UiDesignSystemType.BUTTON_HEIGHT), "")
	exit_button.pressed.connect(func() -> void:
		_hide_exit_confirmation()
		exit_requested.emit()
	)
	actions.add_child(exit_button)

func _set_home_stage_visible(visible: bool) -> void:
	for node in [home_backdrop, home_wash, safe_margin, top_controls_margin, privacy_link_margin]:
		if node != null:
			node.visible = visible

## Home's daily-missions section. It previews today's three objectives and their
## progress, then opens the full popup for claiming. Claim rules deliberately
## live in one place (the popup and controller), so this card only summarises.
func _build_daily_card() -> Control:
	daily_button = Button.new()
	daily_button.name = "HomeDailyMissionsButton"
	daily_button.flat = true
	# Taller than the old badge strip: each mission now carries its own card.
	daily_button.custom_minimum_size = Vector2(516.0, 296.0)
	daily_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	daily_button.pressed.connect(func() -> void: daily_missions_requested.emit())
	_wire_button_motion(daily_button)

	# No plate behind the widget. The mission cards carry their own colour, so a
	# second panel behind them only muddies the screen.
	var frame := Control.new()
	frame.name = "HomeDailyCardFrame"
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	daily_button.add_child(frame)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 8)
	frame.add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var banner := PanelContainer.new()
	banner.custom_minimum_size = Vector2(0.0, UiDesignSystemType.BANNER_HEIGHT)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_theme_stylebox_override("panel", UiKitType.nine_patch_style("bar_gold_frame", Vector4(76.0, 12.0, 76.0, 14.0)))
	column.add_child(banner)
	var heading := _label("DAILY MISSIONS", UiDesignSystemType.PANEL_TITLE_FONT_SIZE, Color.WHITE)
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_child(heading)

	daily_badges_row = HBoxContainer.new()
	daily_badges_row.name = "HomeDailyBadges"
	daily_badges_row.alignment = BoxContainer.ALIGNMENT_CENTER
	daily_badges_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	daily_badges_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	daily_badges_row.add_theme_constant_override("separation", DAILY_MINI_GAP)
	column.add_child(daily_badges_row)

	daily_status_label = _label("Tap to view today's missions", UiDesignSystemType.CAPTION_FONT_SIZE, UiDesignSystemType.COLOR_GOLD_LIGHT)
	column.add_child(daily_status_label)
	return daily_button


## Home's daily-missions preview. Each mission gets its own colourful mini-card
## in the same visual language as the popup this widget opens, so the two read
## as one feature rather than a bare badge strip next to a designed panel.
## Claim rules deliberately stay in the popup and controller; this only
## summarises.
const DAILY_MINI_CARD_SIZE := Vector2(0.0, 122.0)
const DAILY_MINI_BADGE_HEIGHT := 56.0
const DAILY_MINI_GAP := 12


const DAILY_STATUS_BADGE := 52.0
## Half the badge hangs outside the card corner, so the status reads at a glance
## from across the screen rather than as a detail inside the tile.
const DAILY_STATUS_OVERLAP := -DAILY_STATUS_BADGE * 0.5


func _refresh_daily_card() -> void:
	if daily_badges_row == null:
		return
	for child in daily_badges_row.get_children():
		child.queue_free()
	var state: Dictionary = _snapshot.get("daily_state", {}) as Dictionary
	var missions: Array = state.get("missions", []) as Array
	var claimable := 0
	for index in range(missions.size()):
		var mission: Dictionary = missions[index] as Dictionary
		var claimed := bool(mission.get("claimed", false))
		var target := maxi(1, int(mission.get("target", 1)))
		var progress := mini(int(mission.get("progress", 0)), target)
		if not claimed and progress >= target:
			claimable += 1
		daily_badges_row.add_child(_daily_mini_card(mission, index, progress, target, claimed))
	if daily_status_label == null:
		return
	if missions.is_empty():
		daily_status_label.text = "Tap to view today's missions"
	elif claimable > 0:
		daily_status_label.text = "%d reward%s ready to claim" % [claimable, "" if claimable == 1 else "s"]
	elif DailyMissionServiceType.chest_ready(state):
		daily_status_label.text = "Daily chest ready"
	else:
		daily_status_label.text = "Tap to view today's missions"


## One compact mission tile: the same tinted plate and gold rim the popup cards
## use, with the badge and progress only. The popup owns the full detail, so
## crowding the label and a claim button in here would just make it unreadable.
func _daily_mini_card(mission: Dictionary, index: int, progress: int, target: int, claimed: bool) -> Control:
	var card := PanelContainer.new()
	card.name = "HomeDailyCard%d" % index
	card.custom_minimum_size = DAILY_MINI_CARD_SIZE
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", UiDesignSystemType.mission_card_style(index))

	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		pad.add_theme_constant_override("margin_%s" % side, 10)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_bottom", 12)
	card.add_child(pad)

	# One stack so the corner badge can overlay the content. A PanelContainer
	# stretches every direct child, so the badge cannot hang off the card itself.
	var stack := Control.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(stack)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 6)
	stack.add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# The mission keeps its own identity badge at every stage; the corner badge
	# is the only thing that reports status, so the card never shows two checks.
	var badge := UiKitType.texture_rect(
		UiKitType.badge(String(mission.get("icon", "gems"))), DAILY_MINI_BADGE_HEIGHT)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(badge)

	# A completed-but-unclaimed mission is the one state worth calling out here,
	# because it is the reason to open the popup at all.
	var complete := progress >= target
	var progress_color := UiDesignSystemType.COLOR_GOLD_LIGHT if complete and not claimed else Color.WHITE
	var caption := _label("%d/%d" % [progress, target], UiDesignSystemType.CAPTION_FONT_SIZE, progress_color)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(caption)

	# A corner status badge, matching the power tiles: "+" while there is still
	# progress to make, and the circular check once the mission is done.
	var status := Control.new()
	status.name = "Status"
	status.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	status.offset_left = -DAILY_STATUS_BADGE - DAILY_STATUS_OVERLAP
	status.offset_right = -DAILY_STATUS_OVERLAP
	status.offset_top = DAILY_STATUS_OVERLAP
	status.offset_bottom = DAILY_STATUS_BADGE + DAILY_STATUS_OVERLAP
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.z_index = 1
	stack.add_child(status)
	var status_icon := UiKitType.texture_rect(
		UiKitType.ICON_CHECK if complete else UiKitType.ICON_PLUS, DAILY_STATUS_BADGE)
	status_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	status.add_child(status_icon)
	return card


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
	var row := HBoxContainer.new()
	row.name = "%sRow" % node_name
	row.custom_minimum_size = Vector2(400.0, 64.0)
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
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
		var global_tweens := get_node_or_null("/root/GlobalTweens")
		if global_tweens != null:
			global_tweens.call("energy_pulse", toggle, UiDesignSystemType.COLOR_BLUE_LIGHT, 0.16)
	)
	row.add_child(toggle)
	return toggle

func _setting_icon_texture(node_name: String) -> Texture2D:
	if node_name.contains("Music"):
		return ICON_MUSIC
	if node_name.contains("Sound"):
		return ICON_SOUND
	return ICON_SOUND

func _sync_settings_from_snapshot() -> void:
	if settings_music_toggle == null:
		return
	settings_music_toggle.set_pressed_no_signal(bool(_snapshot.get("music_enabled", true)))
	settings_sound_toggle.set_pressed_no_signal(bool(_snapshot.get("sound_enabled", true)))
	_sync_switch_label(settings_music_toggle)
	_sync_switch_label(settings_sound_toggle)


func set_privacy_options_available(available: bool) -> void:
	if settings_privacy_options_button != null:
		settings_privacy_options_button.visible = available

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
	# The target artwork is the identity. Player-facing gem names are omitted.
	intro_objective_label.text = "MERGE TARGET  ×  %d" % target_quantity

	if intro_skip_button != null:
		var skip_cost := int(_snapshot.get("skip_cost", GameConfig.SKIP_LEVEL_COST))
		intro_skip_button.text = "SKIP LEVEL  ·  %d COINS" % skip_cost
		# Never disabled: an unaffordable tap opens the watch-a-video offer.
		intro_skip_button.disabled = false
		intro_skip_button.tooltip_text = "Skip Level %d for %d coins" % [_current_level, skip_cost]

func _show_settings() -> void:
	_sync_settings_from_snapshot()
	_show_popup(settings_blocker, settings_panel)


func show_exit_confirmation() -> void:
	if root_control == null or not root_control.visible:
		return
	_show_popup(exit_confirm_blocker, exit_confirm_panel)
	if exit_cancel_button != null:
		exit_cancel_button.grab_focus()


func _hide_exit_confirmation() -> void:
	_hide_popup(exit_confirm_blocker)
	if play_button != null:
		play_button.grab_focus()

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
		var global_tweens := get_node_or_null("/root/GlobalTweens")
		if global_tweens != null:
			global_tweens.call("button_press", button, 0.055)
	)
	button.pressed.connect(func() -> void: ui_tap_requested.emit())

func _refresh_safe_margins() -> void:
	if safe_margin == null or not is_inside_tree():
		return
	var insets := _safe_insets()
	for container in [safe_margin]:
		if container == null:
			continue
		for entry in [["left", insets.x], ["top", insets.y], ["right", insets.z], ["bottom", insets.w]]:
			container.add_theme_constant_override("margin_%s" % entry[0], int(ceil(maxf(18.0, float(entry[1]) + UiDesignSystemType.SAFE_INSET_PADDING))))
	if privacy_link_margin != null:
		privacy_link_margin.add_theme_constant_override("margin_bottom", int(ceil(maxf(10.0, insets.w + 8.0))))

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
