class_name GameplayHudLayer
extends CanvasLayer

const AssetCatalogType = preload("res://scripts/core/asset_catalog.gd")
const ScoreFormatterType = preload("res://scripts/core/score_formatter.gd")
const CoinIconType = preload("res://scripts/presentation/coin_icon.gd")
const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")
const TargetRewardOverlayType = preload("res://scripts/presentation/target_reward_overlay.gd")
const ICON_SETTINGS = preload("res://assets/runtime/ui/kit/icon_gear.png")
const ICON_PLAY = preload("res://assets/runtime/ui/icons/play_white.svg")
const ICON_RESTART = preload("res://assets/runtime/ui/icons/restart_lavender.svg")
const ICON_HOME = preload("res://assets/runtime/ui/icons/home_lavender.svg")
const ICON_MUSIC = preload("res://assets/runtime/ui/icons/note_lavender.svg")
const ICON_SOUND = preload("res://assets/runtime/ui/icons/speaker_lavender.svg")
const PowerInventoryServiceType = preload("res://scripts/services/power_inventory_service.gd")
const POWER_TILE = preload("res://assets/runtime/ui/kit/power_tile.png")
## Any modal must outrank every content z_index on the same canvas layer.
const MODAL_Z_INDEX := 100
const DECOR_DIAMOND = preload("res://assets/runtime/ui/kit/decor_diamond.png")
const POWER_ICONS := {
	"bomb": preload("res://assets/runtime/ui/kit/power_icon_bomb.png"),
	"magnet": preload("res://assets/runtime/ui/kit/power_icon_magnet.png"),
	"switch": preload("res://assets/runtime/ui/kit/power_icon_switch.png"),
	"hammer": preload("res://assets/runtime/ui/kit/power_icon_hammer.png"),
}
const ICON_SKIP = preload("res://assets/runtime/ui/icons/fast_forward_lavender.svg")
const SHOTS_PANEL_SIZE := Vector2(300.0, 82.0)
const SHOTS_PULSE_SCALE := 1.28
const SHOTS_PULSE_DURATION := 0.26

const SNAPSHOT_KEYS := ["level_number", "gem_identity_order", "current_level", "next_level", "coins", "score", "power_counts", "power_actionable", "pending_power_target", "skip_cost", "skip_enabled", "target_level", "target_progress", "target_quantity", "target_index", "target_total", "target_collecting", "target_completed", "highest_level", "music_enabled", "sound_enabled", "limited_shots", "shots_remaining"]

signal settings_requested
signal resume_requested
signal restart_requested
signal home_requested
signal music_toggled(enabled: bool)
signal sound_toggled(enabled: bool)
signal privacy_options_requested
signal ui_tap_requested
## Emitted when a power tile is tapped while the player owns at least one.
signal power_requested(power: String)
## Emitted when the "+" affordance on an empty power tile is tapped. A power at
## zero is never disabled — it offers a rewarded ad for one instead.
signal power_ad_requested(power: String)
signal skip_level_requested

var root_control: Control
var hud_canvas: Control
var hud_margin: MarginContainer
var objective_stack_anchor: MarginContainer
var progression_center: CenterContainer
var target_anchor: CenterContainer
var score_panel: Control
var score_label: Label
var shots_label: Label
var shots_anchor: CenterContainer
var shots_panel: PanelContainer
var _shots_shown := -1
var _shots_tween: Tween
var coin_icon: CoinIcon
var progression_frames: Array[Control] = []
var progression_icons: Array[TextureRect] = []
var next_panel: Control
var next_icon: TextureRect
## One entry per power, keyed by power name: {button, count_label, plus_icon}.
var power_tiles: Dictionary = {}
var pause_skip_button: Button
var sink_buttons_anchor: MarginContainer
var mission_toast: PanelContainer
var mission_toast_title: Label
var mission_toast_label: Label
var mission_toast_icon: TextureRect
var _mission_toast_elapsed := 0.0
var _mission_toast_active := false
var _mission_toast_settled := Vector2.ZERO
var target_panel: Control
var target_header_label: Label
var target_icon: TextureRect
var target_status_label: Label
var reward_foreground_host: Node2D
var target_swap_outgoing: Sprite2D
var target_swap_incoming: Sprite2D
var target_reward_overlay: Control
var settings_button: Button
var pause_blocker: Control
var pause_dimmer: ColorRect
var pause_safe_margin: MarginContainer
var pause_panel: PanelContainer
var resume_button: Button
var restart_button: Button
var home_button: Button
var music_toggle: Button
var sound_toggle: Button
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
var _target_icon_tween: Tween
var _target_number_tween: Tween
var _settings_tween: Tween
var _pause_tween: Tween
var _authoritative_coins := 0
var _displayed_coins := 0
var _queued_coin_rewards := 0
var _displayed_target_progress := 0
var _displayed_target_maximum := 1


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
	# The controller configures the shared table geometry after child HUD nodes
	# enter the tree. Re-read it on every authoritative snapshot so tall-screen
	# objective placement cannot remain stuck at the baseline startup position.
	_refresh_safe_margins()
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
	_refresh_power_tiles(snapshot)
	if pause_skip_button != null:
		# Never disabled: when the player cannot afford it, the tap opens the
		# watch-a-video offer instead of doing nothing.
		pause_skip_button.disabled = false
		pause_skip_button.tooltip_text = "Skip this level for %d coins" % int(snapshot.get("skip_cost", GameConfig.SKIP_LEVEL_COST))

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
		target_state = "ACHIEVED  %d / %d" % [target_quantity, target_quantity]
	elif bool(snapshot.get("target_completed", false)):
		target_state = "COMPLETE  %d / %d" % [target_quantity, target_quantity]
	var target_bar_value := target_quantity if bool(snapshot.get("target_completed", false)) else target_progress
	var target_level := int(snapshot.get("target_level", 1))
	if int(_snapshot.get("target_level", -1)) != target_level:
		var previous_texture := target_icon.texture
		var next_texture := AssetCatalogType.gem_texture(target_level)
		target_icon.texture = next_texture
		if had_snapshot:
			_animate_target_swap(previous_texture, next_texture, target_header, target_state, target_quantity, target_bar_value)
		else:
			_apply_target_state(target_header, target_state, target_quantity, target_bar_value)
	else:
		_apply_target_state(target_header, target_state, target_quantity, target_bar_value)

	var level_number := int(snapshot.get("level_number", 1))
	_apply_shots_state(
		bool(snapshot.get("limited_shots", false)),
		maxi(0, int(snapshot.get("shots_remaining", 0))))
	if music_toggle != null:
		music_toggle.set_pressed_no_signal(bool(snapshot.get("music_enabled", true)))
	if sound_toggle != null:
		sound_toggle.set_pressed_no_signal(bool(snapshot.get("sound_enabled", true)))
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


func acknowledge_target_progress() -> void:
	pulse_target()
	if target_icon == null:
		return
	_kill_tween(_target_icon_tween)
	target_icon.pivot_offset = _node_center(target_icon)
	if not is_inside_tree():
		target_icon.scale = Vector2.ONE
		target_icon.modulate = Color.WHITE
		return
	target_icon.scale = Vector2.ONE
	target_icon.modulate = Color.WHITE
	_target_icon_tween = create_tween().set_parallel(true)
	_target_icon_tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_target_icon_tween.tween_property(target_icon, "scale", Vector2.ONE * 1.10, UiDesignSystemType.TARGET_PULSE_DURATION * 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_target_icon_tween.tween_property(target_icon, "modulate", Color(1.18, 1.12, 0.72, 1.0), UiDesignSystemType.TARGET_PULSE_DURATION * 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_target_icon_tween.chain().set_parallel(true)
	_target_icon_tween.tween_property(target_icon, "scale", Vector2.ONE, UiDesignSystemType.TARGET_PULSE_DURATION * 0.58).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_target_icon_tween.tween_property(target_icon, "modulate", Color.WHITE, UiDesignSystemType.TARGET_PULSE_DURATION * 0.58).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## The panel compresses just before the hero target gem reaches it, so the
## impact reads as an arrival instead of an unmotivated pulse.
func anticipate_target_panel() -> void:
	_build_once()
	_kill_tween(_target_pulse_tween)
	target_panel.pivot_offset = _node_center(target_panel)
	if not is_inside_tree():
		target_panel.scale = Vector2.ONE * GameConfig.HERO_PANEL_ANTICIPATION_SCALE
		return
	_target_pulse_tween = create_tween()
	_target_pulse_tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_target_pulse_tween.tween_property(target_panel, "scale", Vector2.ONE * GameConfig.HERO_PANEL_ANTICIPATION_SCALE, GameConfig.HERO_PANEL_ANTICIPATION_LEAD).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func impact_target_panel() -> void:
	_build_once()
	if target_reward_overlay != null:
		target_reward_overlay.play(target_collection_destination())
	_kill_tween(_target_pulse_tween)
	target_panel.pivot_offset = _node_center(target_panel)
	_energy_pulse(target_panel)
	if not is_inside_tree():
		target_panel.scale = Vector2.ONE
		return
	_target_pulse_tween = create_tween()
	_target_pulse_tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_target_pulse_tween.tween_property(target_panel, "scale", Vector2.ONE * GameConfig.HERO_PANEL_IMPACT_SCALE, GameConfig.HERO_PANEL_IMPACT_RISE).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_target_pulse_tween.tween_property(target_panel, "scale", Vector2.ONE * GameConfig.HERO_PANEL_RECOIL_SCALE, GameConfig.HERO_PANEL_IMPACT_RECOIL).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_target_pulse_tween.tween_property(target_panel, "scale", Vector2.ONE, GameConfig.HERO_PANEL_IMPACT_SETTLE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Restrained container punch used once per collected coin wave.
func punch_coin_counter() -> void:
	_build_once()
	_kill_tween(_coin_icon_tween)
	coin_icon.pivot_offset = _node_center(coin_icon)
	score_label.pivot_offset = _node_center(score_label)
	if not is_inside_tree():
		coin_icon.scale = Vector2.ONE
		score_label.scale = Vector2.ONE
		return
	coin_icon.scale = Vector2.ONE * GameConfig.COIN_COUNTER_WAVE_PUNCH_SCALE
	score_label.scale = Vector2.ONE * GameConfig.COIN_COUNTER_WAVE_PUNCH_SCALE
	_coin_icon_tween = create_tween().set_parallel(true)
	_coin_icon_tween.tween_property(coin_icon, "scale", Vector2.ONE, GameConfig.COIN_COUNTER_PULSE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_coin_icon_tween.tween_property(score_label, "scale", Vector2.ONE, GameConfig.COIN_COUNTER_PULSE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func final_coin_counter_impact() -> void:
	_build_once()
	_kill_tween(_coin_icon_tween)
	coin_icon.pivot_offset = _node_center(coin_icon)
	score_label.pivot_offset = _node_center(score_label)
	if not is_inside_tree():
		coin_icon.scale = Vector2.ONE
		score_label.scale = Vector2.ONE
		return
	coin_icon.scale = Vector2.ONE
	score_label.scale = Vector2.ONE
	_coin_icon_tween = create_tween().set_parallel(true)
	_coin_icon_tween.tween_property(coin_icon, "scale", Vector2.ONE * GameConfig.COIN_COUNTER_FINAL_PUNCH_SCALE, 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_coin_icon_tween.tween_property(score_label, "scale", Vector2.ONE * GameConfig.COIN_COUNTER_FINAL_PUNCH_SCALE, 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_coin_icon_tween.chain().set_parallel(true)
	_coin_icon_tween.tween_property(coin_icon, "scale", Vector2.ONE * GameConfig.COIN_COUNTER_FINAL_RECOIL_SCALE, 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_coin_icon_tween.tween_property(score_label, "scale", Vector2.ONE * GameConfig.COIN_COUNTER_FINAL_RECOIL_SCALE, 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_coin_icon_tween.chain().set_parallel(true)
	_coin_icon_tween.tween_property(coin_icon, "scale", Vector2.ONE, 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_coin_icon_tween.tween_property(score_label, "scale", Vector2.ONE, 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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


## `punch` is disabled for staggered level-reward waves so the container is
## punched once per wave instead of once per coin. The value math is identical.
func collect_coin_chunk(value: int, final_coin: bool = false, punch: bool = true) -> void:
	if value <= 0:
		return
	_queued_coin_rewards = maxi(0, _queued_coin_rewards - value)
	_displayed_coins = mini(_authoritative_coins, _displayed_coins + value)
	if final_coin and _queued_coin_rewards == 0:
		_displayed_coins = _authoritative_coins
	_set_coin_label(_displayed_coins)
	if punch:
		_animate_coin_change()


func displayed_coin_value() -> int:
	return _displayed_coins


func pending_coin_value() -> int:
	return _queued_coin_rewards


## Called once as Level Complete is about to present. The reward-coin
## celebration already delivers this level's earnings into this counter in real
## time as each coin lands, so by the time this runs the HUD is normally already
## at `final_total`. It must never be forced back down to `previous_total` here
## — that produced a visible drop right as the modal opened. Only correct the
## display forward if some coins genuinely have not landed yet (a path that
## skipped the live celebration, e.g. a direct/debug snapshot).
func prepare_completion_reward_display(previous_total: int, final_total: int) -> void:
	_kill_tween(_completion_coin_tween)
	_authoritative_coins = maxi(previous_total, final_total)
	_queued_coin_rewards = 0
	_displayed_coins = clampi(_displayed_coins, previous_total, final_total)
	_set_coin_label(_displayed_coins)


## Historically the moment the whole level's reward first appeared in the HUD.
## With the reward-coin celebration, the value is usually already fully
## delivered by the time this is called (on COLLECT, or on a rewarded double-
## coins grant): if so, this only confirms the label — it must not re-animate
## or otherwise imply the reward was granted a second time. It still animates
## forward when `final_total` is genuinely higher than what has landed so far
## (the double-coins bonus case).
func animate_completion_reward(final_total: int, duration: float = 0.72) -> void:
	_kill_tween(_completion_coin_tween)
	var start := _displayed_coins
	_authoritative_coins = maxi(_authoritative_coins, final_total)
	if start >= final_total:
		_displayed_coins = final_total
		_set_coin_label(_displayed_coins)
		return
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
	for tween in [_score_tween, _coin_icon_tween, _completion_coin_tween, _next_tween, _target_swap_tween, _target_pulse_tween, _target_progress_tween, _target_icon_tween, _target_number_tween, _settings_tween]:
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
	_displayed_target_progress = 0
	_displayed_target_maximum = 1
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
	# Must outrank every content z_index on this layer, including the mission
	# banner at 40, which would otherwise draw straight through the pause modal.
	pause_blocker.z_index = MODAL_Z_INDEX


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

	# Keep the top safe-area row utility-only. Target and the merge path live in
	# their own table-adjacent stack so intrinsic card widths can never overlap.
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
	utility_row.name = "TopUtilityRow"
	utility_row.custom_minimum_size = Vector2(0.0, UiDesignSystemType.TOP_HUD_HEIGHT)
	utility_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	utility_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	utility_row.add_theme_constant_override("separation", 8)
	utility_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_margin.add_child(utility_row)

	var left_slot := HBoxContainer.new()
	left_slot.name = "CoinsSlot"
	left_slot.custom_minimum_size = Vector2(UiDesignSystemType.SCORE_PANEL_SIZE.x, UiDesignSystemType.TOP_HUD_HEIGHT)
	left_slot.alignment = BoxContainer.ALIGNMENT_BEGIN
	left_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	utility_row.add_child(left_slot)
	score_panel = _build_score_panel()
	# Coins and Next share one top baseline even though their card heights differ.
	score_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	left_slot.add_child(score_panel)

	var utility_spacer := Control.new()
	utility_spacer.name = "TopUtilitySpacer"
	utility_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	utility_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	utility_row.add_child(utility_spacer)

	var right_slot := VBoxContainer.new()
	right_slot.name = "NextSettingsSlot"
	right_slot.custom_minimum_size = Vector2(UiDesignSystemType.NEXT_PANEL_SIZE.x, UiDesignSystemType.NEXT_PANEL_SIZE.y + 12.0 + UiDesignSystemType.TOP_SETTINGS_SIZE)
	right_slot.alignment = BoxContainer.ALIGNMENT_BEGIN
	right_slot.add_theme_constant_override("separation", 12)
	right_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	utility_row.add_child(right_slot)
	next_panel = _build_next_panel()
	next_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	right_slot.add_child(next_panel)
	var settings_row := HBoxContainer.new()
	settings_row.name = "SettingsRow"
	settings_row.alignment = BoxContainer.ALIGNMENT_END
	settings_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_slot.add_child(settings_row)
	settings_button = _build_settings_button()
	settings_button.custom_minimum_size = Vector2.ONE * UiDesignSystemType.TOP_SETTINGS_SIZE
	settings_row.add_child(settings_button)

	# Counter -> Target -> complete merge path -> table. The centred stack may
	# use the empty space between the corner utilities; reserving the full top-HUD
	# height pushed the path down over the table on short portrait screens.
	objective_stack_anchor = MarginContainer.new()
	objective_stack_anchor.name = "TableObjectiveAnchor"
	objective_stack_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_stack_anchor.set_anchors_preset(Control.PRESET_TOP_LEFT)
	objective_stack_anchor.offset_left = 0.0
	objective_stack_anchor.offset_right = UiDesignSystemType.DESIGN_WIDTH
	hud_canvas.add_child(objective_stack_anchor)
	var objective_stack := VBoxContainer.new()
	objective_stack.name = "TableObjectiveStack"
	objective_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_stack.add_theme_constant_override("separation", UiDesignSystemType.OBJECTIVE_STACK_GAP)
	objective_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_stack_anchor.add_child(objective_stack)
	# Limited-shots levels put their counter at the top of the centred objective
	# stack, in the same framed language as the Target panel. It previously lived
	# as a 72px label wedged beside Coins, where the number was too small to read
	# and shared nothing with the rest of the HUD.
	shots_anchor = CenterContainer.new()
	shots_anchor.name = "ShotsSlot"
	shots_anchor.custom_minimum_size = Vector2(0.0, SHOTS_PANEL_SIZE.y)
	shots_anchor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shots_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shots_anchor.visible = false
	objective_stack.add_child(shots_anchor)
	shots_anchor.add_child(_build_shots_panel())

	target_anchor = CenterContainer.new()
	target_anchor.name = "TargetSlot"
	target_anchor.custom_minimum_size = Vector2(0.0, UiDesignSystemType.TARGET_PANEL_SIZE.y)
	target_anchor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_stack.add_child(target_anchor)
	target_panel = _build_target_panel()
	target_anchor.add_child(target_panel)
	progression_center = CenterContainer.new()
	progression_center.name = "ProgressionCenter"
	progression_center.custom_minimum_size = Vector2(0.0, UiDesignSystemType.PROGRESSION_HEIGHT)
	progression_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progression_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_stack.add_child(progression_center)
	progression_center.add_child(_build_progression_group())

	# The only live-board economy action intentionally overlaps the table's
	# lower frame as one prominent jewel-game swap button with a text
	# caption under each — no price/coin clutter, cost shown only as a
	# transient popup at the moment of spending. Anchored/re-measured against
	# GameConfig.table_outer_bottom() in _refresh_safe_margins(), exactly like
	# the objective stack above.
	sink_buttons_anchor = MarginContainer.new()
	sink_buttons_anchor.name = "SinkButtonsAnchor"
	sink_buttons_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sink_buttons_anchor.set_anchors_preset(Control.PRESET_TOP_LEFT)
	sink_buttons_anchor.offset_left = 0.0
	sink_buttons_anchor.offset_right = UiDesignSystemType.DESIGN_WIDTH
	hud_canvas.add_child(sink_buttons_anchor)
	var sink_center := CenterContainer.new()
	sink_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sink_buttons_anchor.add_child(sink_center)
	var sink_row := HBoxContainer.new()
	sink_row.name = "SinkButtonsRow"
	sink_row.alignment = BoxContainer.ALIGNMENT_CENTER
	sink_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sink_center.add_child(sink_row)
	sink_row.add_theme_constant_override("separation", POWER_TILE_GAP)
	for power in PowerInventoryServiceType.ALL:
		sink_row.add_child(_build_power_tile(power))
	_build_mission_toast()
## Four tiles plus their gaps and captions must fit the 720px design width.
## The earlier framed tile carried a built-in name pill and count slot that were
## too small for the text and numbers at this size, so the row now uses the
## plain square plate: the icon gets the whole tile, the name sits under it, and
## the count rides the corner where it always has room.
## Sized so the whole row fits below the table rather than overlapping it.
## The table ends at ~1454 in design space and the screen at 1600, so the row
## plus its caption and margins must stay inside ~146px.
const POWER_TILE_SIZE := 92.0
const POWER_TILE_GAP := 18
const POWER_CAPTION_GAP := 4
const POWER_CAPTION_HEIGHT := 14.0
## The icon fills the plate, inset only enough to clear the bevelled border.
const POWER_ICON_INSET := 14.0
## The count badge overlaps the plate's top-right corner rather than sitting
## inside it, so a two-digit count never collides with the artwork.
const POWER_BADGE_SIZE := 46.0
const POWER_BADGE_OVERLAP := 12.0
## Clearance below the power row. 18 left only ~16 real pixels under the
## captions on a 360x640 screen, which read as clipped text against the screen
## edge. Sized so the captions keep visible breathing room at every portrait
## size, including aspects shorter than 16:9.
const POWER_ROW_BOTTOM_PADDING := 12.0
const POWER_TILE_ARMED_SCALE := 1.14
const POWER_TILE_ARMED_MODULATE := Color(1.34, 1.24, 0.94, 1.0)
## A power that cannot act right now is dimmed but never disabled.
const POWER_TILE_IDLE_MODULATE := Color(1.0, 1.0, 1.0, 0.5)
## An owned, usable power at rest. Previously full white, which put four framed
## gold tiles at the same visual weight as the gems they sit under and pulled
## focus off the board. Calm enough to recede, bright enough to read as live.
const POWER_TILE_RESTING_MODULATE := Color(0.94, 0.94, 0.98, 0.88)


## One power tile: the plain square plate, a large power icon, a caption beneath
## it, and a corner count badge that becomes the "+" affordance at zero. The
## tile is never disabled — an empty power offers a rewarded ad instead of going
## dead, which is the whole point of the coin-sink change.
func _build_power_tile(power: String) -> Control:
	var column := VBoxContainer.new()
	column.name = "%sPowerColumn" % power.capitalize()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", POWER_CAPTION_GAP)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var button := Button.new()
	button.name = "%sPowerButton" % power.capitalize()
	button.custom_minimum_size = Vector2.ONE * POWER_TILE_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# The plate is a nine-patch, so it stays crisp at whatever tile size the
	# row settles on instead of smearing a fixed-composition frame.
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, UiKit.nine_patch_style("btn_square_small"))
	# The plate art carries the entire visual state. A focus ring would draw a
	# second, competing border over it, which read as a stuck selection.
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = "%s — %s" % [
		PowerInventoryServiceType.label(power),
		PowerInventoryServiceType.description(power),
	]
	column.add_child(button)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = POWER_ICONS.get(power, POWER_ICONS[PowerInventoryServiceType.BOMB])
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = POWER_ICON_INSET
	icon.offset_right = -POWER_ICON_INSET
	icon.offset_top = POWER_ICON_INSET
	icon.offset_bottom = -POWER_ICON_INSET
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)

	# Anchored to the plate's top-right and pushed outward, so it overlaps the
	# corner. Controls do not clip children, so the overflow renders correctly.
	var badge := Control.new()
	badge.name = "Badge"
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	badge.offset_left = -POWER_BADGE_SIZE + POWER_BADGE_OVERLAP
	badge.offset_right = POWER_BADGE_OVERLAP
	badge.offset_top = -POWER_BADGE_OVERLAP
	badge.offset_bottom = POWER_BADGE_SIZE - POWER_BADGE_OVERLAP
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(badge)

	var count_plate := PanelContainer.new()
	count_plate.name = "CountPlate"
	count_plate.set_anchors_preset(Control.PRESET_FULL_RECT)
	count_plate.add_theme_stylebox_override("panel", UiDesignSystemType.power_count_badge_style())
	count_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(count_plate)

	var count_label := _label("0", 26, Color("fff6d2"))
	count_label.name = "Count"
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_color_override("font_shadow_color", Color(0.16, 0.05, 0.24, 1.0))
	count_label.add_theme_constant_override("shadow_offset_x", 1)
	count_label.add_theme_constant_override("shadow_offset_y", 2)
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count_plate.add_child(count_label)

	var plus_icon := TextureRect.new()
	plus_icon.name = "Plus"
	plus_icon.texture = UiKit.ICON_PLUS
	plus_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plus_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	plus_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	plus_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(plus_icon)

	var caption := _label(PowerInventoryServiceType.label(power).to_upper(), 18, Color("e6d4ff"))
	caption.name = "Caption"
	caption.custom_minimum_size = Vector2(0.0, POWER_CAPTION_HEIGHT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_shadow_color", Color(0.16, 0.05, 0.24, 1.0))
	caption.add_theme_constant_override("shadow_offset_x", 1)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(caption)

	# button_down rather than pressed: a targeted power starts its drag the
	# moment the finger lands, so the player can carry it straight to a gem.
	button.button_down.connect(func() -> void:
		ui_tap_requested.emit()
		# The count is the authority on which action the press means, so the two
		# affordances can never disagree with what the badge is showing.
		if int(_power_count(_snapshot, power)) > 0:
			power_requested.emit(power)
		else:
			power_ad_requested.emit(power)
	)

	power_tiles[power] = {
		"button": button,
		"column": column,
		"icon": icon,
		"caption": caption,
		"count_label": count_label,
		"count_plate": count_plate,
		"plus_icon": plus_icon,
	}
	return column


func _power_count(snapshot: Dictionary, power: String) -> int:
	var counts: Dictionary = snapshot.get("power_counts", {}) if snapshot.get("power_counts", {}) is Dictionary else {}
	return maxi(0, int(counts.get(power, 0)))


## Keeps every tile's badge, dimming, and armed highlight in step with the
## controller snapshot. Ownership drives the badge; actionability drives only
## the dimming, never the disabled flag.
func _refresh_power_tiles(snapshot: Dictionary) -> void:
	var actionable: Dictionary = snapshot.get("power_actionable", {}) if snapshot.get("power_actionable", {}) is Dictionary else {}
	var armed := String(snapshot.get("pending_power_target", ""))
	for power in power_tiles.keys():
		var tile: Dictionary = power_tiles[power]
		var button := tile.get("button") as Button
		var column := tile.get("column") as Control
		var count_plate := tile.get("count_plate") as Control
		var count_label := tile.get("count_label") as Label
		var plus_icon := tile.get("plus_icon") as TextureRect
		if button == null or column == null or count_plate == null or count_label == null or plus_icon == null:
			continue
		var owned := _power_count(snapshot, power)
		# The disc and the "+" are alternates in the same corner slot: exactly
		# one is ever visible, so the badge can never show both or neither.
		count_plate.visible = owned > 0
		plus_icon.visible = owned <= 0
		if owned > 0:
			count_label.text = str(owned)
		# Three states, and the armed one has to be unmistakable: the player is
		# about to spend a power on their next tap. Scale alone was too subtle
		# across four tiles, so armed also brightens well above the others.
		var can_act := bool(actionable.get(power, false))
		if power == armed:
			column.modulate = POWER_TILE_ARMED_MODULATE
		elif can_act or owned <= 0:
			# Live but unused. At zero owned the tile stays at the same resting
			# weight rather than going dead: the tap still opens the rewarded-ad
			# offer, and the green "+" already carries that affordance.
			column.modulate = POWER_TILE_RESTING_MODULATE
		else:
			column.modulate = POWER_TILE_IDLE_MODULATE
		# Scaling the whole column keeps the caption locked to its plate.
		var target_scale := POWER_TILE_ARMED_SCALE if power == armed else 1.0
		if not is_equal_approx(column.scale.x, target_scale):
			column.pivot_offset = Vector2(POWER_TILE_SIZE, POWER_TILE_SIZE + POWER_CAPTION_HEIGHT) * 0.5
			column.scale = Vector2.ONE * target_scale


## Called by the controller when a targeted power is armed or cancelled, so the
## HUD reflects targeting immediately rather than waiting for the next snapshot.
func set_power_targeting(power: String) -> void:
	var snapshot := _snapshot.duplicate(true)
	snapshot["pending_power_target"] = power
	_snapshot = snapshot
	_refresh_power_tiles(snapshot)


## A transient "-100"-style cost readout matching the gameplay combo labels
## (GameplayEffectsLayer._draw_combo_label) as closely as a Control can: same
## font size, same gold-on-dark-shadow coloring, and the same
## GameConfig.COMBO_LABEL_* pop/settle/rise/fade timing. A price only ever
## appears momentarily at the moment of spending, never permanently.
func _show_sink_cost_popup(anchor_button: Button, cost: int) -> void:
	if anchor_button == null or not anchor_button.is_inside_tree():
		return
	const COMBO_LABEL_FONT_SIZE := 30
	const COMBO_LABEL_GOLD := Color(1.0, 0.94, 0.55, 1.0)
	const COMBO_LABEL_SHADOW := Color(0.24, 0.12, 0.05, 1.0)
	var popup := _label("-%d" % cost, COMBO_LABEL_FONT_SIZE, COMBO_LABEL_GOLD)
	popup.add_theme_color_override("font_shadow_color", COMBO_LABEL_SHADOW)
	popup.add_theme_constant_override("shadow_offset_x", 2)
	popup.add_theme_constant_override("shadow_offset_y", 3)
	popup.z_index = 25
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(popup)
	await get_tree().process_frame
	if not is_instance_valid(popup):
		return
	var button_center := anchor_button.get_global_rect().get_center()
	popup.pivot_offset = popup.size * 0.5
	var start_position := button_center - popup.size * 0.5 - Vector2(0.0, anchor_button.size.y * 0.5 + 10.0)
	popup.global_position = start_position
	popup.scale = Vector2.ONE * 0.5
	popup.modulate.a = 1.0
	var pop_duration := GameConfig.COMBO_LABEL_POP_DURATION
	var settle_duration := GameConfig.COMBO_LABEL_SETTLE_DURATION
	var total_duration := GameConfig.COMBO_LABEL_DURATION
	var travel_duration := maxf(0.001, total_duration - pop_duration - settle_duration)
	var tween := create_tween()
	tween.tween_property(popup, "scale", Vector2.ONE * 1.2, pop_duration).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "scale", Vector2.ONE, settle_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(popup, "global_position:y", start_position.y - GameConfig.COMBO_LABEL_RISE, travel_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Matches _draw_combo_label's alpha = 1 - smoothstep(0.55, 1.0, travel_t):
	# the fade only starts 55% of the way through the post-settle travel.
	tween.parallel().tween_property(popup, "modulate:a", 0.0, travel_duration * 0.45).set_delay(travel_duration * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(popup):
			popup.queue_free()
	)


## One circular icon button plus its text caption, stacked. The button is
## sized so its visible icon (after sink_action_button_style's padding) is at
## least as large as the smallest gem on the table (tier 1's 36px collision
## radius, i.e. a 72px-diameter gem) — this is a primary action, not a small
## utility icon, and must read clearly on a real phone screen.
const SINK_BUTTON_SIZE := 112.0

func _build_sink_button(action_name: String, icon: Texture2D, caption_text: String, tooltip_text_value: String) -> Dictionary:
	var button := Button.new()
	button.name = "%sSinkButton" % action_name
	button.custom_minimum_size = Vector2.ONE * SINK_BUTTON_SIZE
	button.icon = icon
	button.expand_icon = true
	button.add_theme_stylebox_override("normal", UiDesignSystemType.sink_action_button_style())
	button.add_theme_stylebox_override("hover", UiDesignSystemType.sink_action_button_style(true, false))
	button.add_theme_stylebox_override("pressed", UiDesignSystemType.sink_action_button_style(false, true))
	button.add_theme_stylebox_override("disabled", UiDesignSystemType.sink_action_button_style())
	button.add_theme_stylebox_override("focus", UiDesignSystemType.sink_action_button_style(true, false))
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.self_modulate = Color("ead4ff")
	button.tooltip_text = tooltip_text_value
	var stack := VBoxContainer.new()
	stack.name = "%sSinkStack" % action_name
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 6)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var button_center := CenterContainer.new()
	button_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button_center.add_child(button)
	stack.add_child(button_center)
	var caption := _label(caption_text, 17, UiDesignSystemType.COLOR_TEXT)
	caption.add_theme_constant_override("outline_size", 4)
	caption.add_theme_color_override("font_outline_color", Color(0.08, 0.015, 0.14, 0.9))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.custom_minimum_size = Vector2(SINK_BUTTON_SIZE + 28.0, 24.0)
	stack.add_child(caption)
	return {"button": button, "stack": stack}


func _build_score_panel() -> Control:
	var panel := PanelContainer.new()
	panel.name = "ScorePanel"
	panel.custom_minimum_size = UiDesignSystemType.SCORE_PANEL_SIZE
	panel.add_theme_stylebox_override("panel", UiDesignSystemType.secondary_hud_panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(center)
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
	score_label.add_theme_constant_override("outline_size", 3)
	score_label.add_theme_color_override("font_outline_color", Color(0.08, 0.015, 0.14, 0.96))
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
	_decorate_panel_ends(panel)
	var column := VBoxContainer.new()
	column.name = "NextContent"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 3)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(column)
	var heading := _label("NEXT", 18, UiDesignSystemType.COLOR_TEXT_MUTED)
	heading.name = "NextHeading"
	heading.custom_minimum_size = Vector2(0.0, 26.0)
	column.add_child(heading)
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
	panel.custom_minimum_size = Vector2(620.0, UiDesignSystemType.PROGRESSION_HEIGHT)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", UiDesignSystemType.progression_panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_decorate_panel_ends(panel)
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
			connector_center.custom_minimum_size = Vector2(12.0, UiDesignSystemType.PROGRESSION_ICON_SIZE)
			connector_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var connector := _label("›", 22, UiDesignSystemType.COLOR_BLUE_DEEP)
			connector.custom_minimum_size = Vector2(12.0, 24.0)
			connector_center.add_child(connector)
			strip.add_child(connector_center)
	return panel


## Limited-shots readout. Framed like the Target panel so the two objective
## surfaces read as one system, with the count set large enough to be legible
## at a glance and to register when it ticks down.
func _build_shots_panel() -> Control:
	shots_panel = PanelContainer.new()
	shots_panel.name = "ShotsPanel"
	shots_panel.custom_minimum_size = SHOTS_PANEL_SIZE
	shots_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shots_panel.add_theme_stylebox_override("panel", UiDesignSystemType.target_panel_style())

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shots_panel.add_child(row)

	var caption := _label("SHOTS LEFT", UiDesignSystemType.SMALL_FONT_SIZE, UiDesignSystemType.COLOR_GOLD_LIGHT)
	caption.name = "ShotsCaption"
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(caption)

	shots_label = _label("0", UiDesignSystemType.SCORE_FONT_SIZE, Color.WHITE)
	shots_label.name = "ShotsRemainingLabel"
	shots_label.add_theme_font_override("font", UiDesignSystemType.heavy_font())
	shots_label.custom_minimum_size = Vector2(84.0, 0.0)
	shots_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(shots_label)
	return shots_panel


## Pulses the count whenever it actually changes so a spent shot is noticed.
func _apply_shots_state(limited: bool, remaining: int) -> void:
	if shots_anchor == null or shots_label == null:
		return
	var visibility_changed := shots_anchor.visible != limited
	shots_anchor.visible = limited
	if visibility_changed:
		# The stack is a different height with the counter in it, so the anchor has
		# to be re-measured or the panels overlap the row above.
		_refresh_safe_margins()
	if not limited:
		_shots_shown = -1
		return
	if remaining == _shots_shown:
		return
	var had_previous := _shots_shown >= 0
	_shots_shown = remaining
	shots_label.text = "%d" % remaining
	# Running low is a warning, not decoration; it shares the fail-state coral.
	shots_label.add_theme_color_override("font_color",
		UiDesignSystemType.COLOR_CORAL_LIGHT if remaining <= 3 else Color.WHITE)
	if not had_previous:
		return
	if _shots_tween != null and _shots_tween.is_valid():
		_shots_tween.kill()
	shots_label.pivot_offset = shots_label.size * 0.5
	shots_label.scale = Vector2(SHOTS_PULSE_SCALE, SHOTS_PULSE_SCALE)
	_shots_tween = create_tween()
	_shots_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_shots_tween.tween_property(shots_label, "scale", Vector2.ONE, SHOTS_PULSE_DURATION)


func _build_target_panel() -> Control:
	var panel := PanelContainer.new()
	panel.name = "ActiveTargetPanel"
	panel.custom_minimum_size = UiDesignSystemType.TARGET_PANEL_SIZE
	panel.add_theme_stylebox_override("panel", UiDesignSystemType.target_panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_decorate_panel_ends(panel)
	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 16)
	content_margin.add_theme_constant_override("margin_top", 10)
	content_margin.add_theme_constant_override("margin_right", 16)
	content_margin.add_theme_constant_override("margin_bottom", 10)
	content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content_margin)
	var row := HBoxContainer.new()
	row.name = "TargetContentRow"
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_margin.add_child(row)
	var icon_slot := CenterContainer.new()
	icon_slot.name = "TargetGemCenter"
	icon_slot.custom_minimum_size = Vector2(68.0, 60.0)
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
	details.add_theme_constant_override("separation", 0)
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(details)
	target_header_label = _label("TARGET  1 / 1", 17, UiDesignSystemType.COLOR_TEXT_MUTED)
	target_header_label.name = "TargetHeader"
	target_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	details.add_child(target_header_label)
	target_status_label = _label("0 / 1", 25, UiDesignSystemType.COLOR_BLUE_DEEP)
	target_status_label.name = "TargetProgressText"
	target_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	target_status_label.add_theme_constant_override("outline_size", 3)
	target_status_label.add_theme_color_override("font_outline_color", Color(0.08, 0.015, 0.14, 0.96))
	details.add_child(target_status_label)
	return panel


func _build_settings_button() -> Button:
	var button := Button.new()
	button.name = "SettingsButton"
	button.custom_minimum_size = Vector2.ONE * UiDesignSystemType.TOP_SETTINGS_SIZE
	UiDesignSystemType.centre_icon_in_button(button, ICON_SETTINGS, UiDesignSystemType.TOP_SETTINGS_SIZE)
	button.add_theme_stylebox_override("normal", UiDesignSystemType.utility_frame_style())
	button.add_theme_stylebox_override("hover", UiDesignSystemType.utility_frame_style())
	button.add_theme_stylebox_override("pressed", UiDesignSystemType.utility_frame_style())
	button.tooltip_text = "Pause"
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.self_modulate = Color("ead4ff")
	button.pressed.connect(func() -> void: settings_requested.emit())
	button.pressed.connect(func() -> void: ui_tap_requested.emit())
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
	pause_panel.custom_minimum_size = Vector2(520.0, 560.0)
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
	privacy_options_button = _button("PausePrivacyOptions", "PRIVACY OPTIONS", Vector2(424.0, 56.0), "SecondaryButton")
	privacy_options_button.visible = false
	privacy_options_button.pressed.connect(func() -> void: privacy_options_requested.emit())
	column.add_child(privacy_options_button)
	resume_button = _button("ResumeButton", "RESUME", Vector2(424.0, 82.0), "")
	resume_button.icon = ICON_PLAY
	resume_button.expand_icon = false
	resume_button.tooltip_text = "Continue playing"
	resume_button.pressed.connect(func() -> void: resume_requested.emit())
	column.add_child(resume_button)
	pause_skip_button = _button("PauseSkipLevelButton", "SKIP LEVEL  ·  %d COINS" % GameConfig.SKIP_LEVEL_COST, Vector2(424.0, 68.0), "SecondaryButton")
	pause_skip_button.icon = ICON_SKIP
	pause_skip_button.expand_icon = false
	pause_skip_button.tooltip_text = "Skip this level for %d coins" % GameConfig.SKIP_LEVEL_COST
	pause_skip_button.pressed.connect(func() -> void: skip_level_requested.emit())
	column.add_child(pause_skip_button)
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
	var row := HBoxContainer.new()
	row.name = "%sRow" % node_name
	row.custom_minimum_size = Vector2(424.0, 62.0)
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
		_energy_pulse(toggle)
	)
	row.add_child(toggle)
	return toggle


func _setting_icon_texture(node_name: String) -> Texture2D:
	if node_name.contains("Music"):
		return ICON_MUSIC
	if node_name.contains("Sound"):
		return ICON_SOUND
	return ICON_SOUND


func _wire_button_motion(button: BaseButton) -> void:
	if button == null:
		return
	button.button_down.connect(func() -> void:
		button.pivot_offset = button.size * 0.5
		var tween_service := get_node_or_null("/root/GlobalTweens")
		if tween_service != null:
			tween_service.button_press(button, 0.055)
	)
	button.pressed.connect(func() -> void: ui_tap_requested.emit())


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
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color(0.07, 0.01, 0.13, 0.94))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _decorate_header_label(label: Label) -> void:
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", UiDesignSystemType.COLOR_PURPLE_DEEP)


func _score_font_size(formatted: String) -> int:
	if formatted.length() <= 4:
		return 38
	if formatted.length() <= 6:
		return 34
	return 30


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


func _animate_target_swap(previous_texture: Texture2D, next_texture: Texture2D, next_header: String, next_state: String, next_maximum: int, next_value: int) -> void:
	_kill_tween(_target_swap_tween)
	if previous_texture == null or next_texture == null or not is_inside_tree():
		_apply_target_state(next_header, next_state, next_maximum, next_value)
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
	_target_swap_tween.tween_callback(_apply_target_state.bind(next_header, next_state, next_maximum, next_value)).set_delay(incoming_delay)
	_target_swap_tween.tween_property(target_swap_incoming, "modulate:a", 1.0, GameConfig.TARGET_SWAP_INCOMING_FADE_DURATION).set_delay(incoming_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_target_swap_tween.tween_property(target_panel, "modulate:a", 1.0, GameConfig.TARGET_SWAP_INCOMING_FADE_DURATION).set_delay(incoming_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_target_swap_tween.finished.connect(_finish_target_swap)


func _apply_target_state(header: String, state: String, maximum: int, value: int) -> void:
	target_header_label.text = header
	_set_target_progress(maximum, value, state)


func _set_target_progress(maximum: int, value: int, state: String) -> void:
	_kill_tween(_target_progress_tween)
	_kill_tween(_target_number_tween)
	var clamped_value := clampi(value, 0, maximum)
	var animate_up := not _snapshot.is_empty() \
		and is_inside_tree() \
		and maximum == _displayed_target_maximum \
		and clamped_value > _displayed_target_progress
	if not animate_up:
		_displayed_target_progress = clamped_value
		_displayed_target_maximum = maximum
		target_status_label.text = _target_status_text_clean(state, clamped_value, maximum)
		target_status_label.scale = Vector2.ONE
		return
	var start_value := _displayed_target_progress
	_displayed_target_maximum = maximum
	target_status_label.scale = Vector2.ONE * 0.90
	_target_number_tween = create_tween().set_parallel(true)
	_target_number_tween.tween_method(func(progress: float) -> void:
		_displayed_target_progress = clampi(int(round(progress)), 0, maximum)
		target_status_label.text = _target_status_text_clean(state, _displayed_target_progress, maximum)
	, float(start_value), float(clamped_value), UiDesignSystemType.VALUE_CHANGE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_target_number_tween.tween_property(target_status_label, "scale", Vector2.ONE, UiDesignSystemType.VALUE_CHANGE_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _target_status_text(state: String, value: int, maximum: int) -> String:
	if state.begins_with("COMPLETE"):
		return "COMPLETE  â€¢  %d / %d" % [value, maximum]
	if state.begins_with("ACHIEVED"):
		return "ACHIEVED  %d / %d" % [value, maximum]
	if state.begins_with("ARRIVING"):
		return "ARRIVING  â€¢  %d / %d" % [value, maximum]
	return "%d / %d" % [value, maximum]


func _target_status_text_clean(state: String, value: int, maximum: int) -> String:
	if state.begins_with("COMPLETE"):
		return "COMPLETE  %d / %d" % [value, maximum]
	if state.begins_with("ACHIEVED"):
		return "ACHIEVED  %d / %d" % [value, maximum]
	if state.begins_with("ARRIVING"):
		return "ARRIVING  %d / %d" % [value, maximum]
	return "%d / %d" % [value, maximum]


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

	if objective_stack_anchor != null:
		objective_stack_anchor.offset_left = 0.0
		objective_stack_anchor.offset_right = UiDesignSystemType.DESIGN_WIDTH
		objective_stack_anchor.add_theme_constant_override("margin_left", left_margin)
		objective_stack_anchor.add_theme_constant_override("margin_right", right_margin)
		# The shots counter lives in this same stack on limited-shots levels. It was
		# missing from the height, so the stack was taller than the space reserved
		# for it and pushed up into the coins/Next/settings row.
		var stack_height := UiDesignSystemType.TARGET_PANEL_SIZE.y + UiDesignSystemType.OBJECTIVE_STACK_GAP + UiDesignSystemType.PROGRESSION_HEIGHT
		if shots_anchor != null and shots_anchor.visible:
			stack_height += SHOTS_PANEL_SIZE.y + float(UiDesignSystemType.OBJECTIVE_STACK_GAP)
		var tall_t := clampf((design_height - GameConfig.VIEWPORT_SIZE.y) / GameConfig.TABLE_TALL_SCALE_REFERENCE_EXTRA, 0.0, 1.0)
		var table_gap := lerpf(UiDesignSystemType.OBJECTIVE_TABLE_GAP_MIN, UiDesignSystemType.OBJECTIVE_TABLE_GAP_MAX, tall_t)
		# The stack is narrow enough to sit between Coins and Next. Requiring it to
		# begin below the complete utility row made the shots card force Target and
		# the merge path onto the table at 16:9. Keep only a small safe-top floor;
		# measured intersection tests protect the corner controls.
		var minimum_top := top_margin + 32.0
		var objective_top := maxf(minimum_top, GameConfig.table_outer_top() - table_gap - stack_height)
		objective_stack_anchor.offset_top = objective_top
		objective_stack_anchor.offset_bottom = objective_top + stack_height

	if sink_buttons_anchor != null:
		sink_buttons_anchor.offset_left = 0.0
		sink_buttons_anchor.offset_right = UiDesignSystemType.DESIGN_WIDTH
		sink_buttons_anchor.add_theme_constant_override("margin_left", left_margin)
		sink_buttons_anchor.add_theme_constant_override("margin_right", right_margin)
		# The power tiles carry their own name and count inside the frame, so the
		# row is exactly one tile tall with no caption line beneath it.
		var sink_row_height := POWER_TILE_SIZE + float(POWER_CAPTION_GAP) + POWER_CAPTION_HEIGHT
		# The tiles are taller than the single button they replaced and carry
		# their name and count inside the frame, so the row needs real clearance
		# from the screen edge rather than the bare safe-area minimum.
		var sink_bottom_margin := maxf(base_margin + POWER_ROW_BOTTOM_PADDING, insets.w * inverse_scale + UiDesignSystemType.SAFE_INSET_PADDING)
		# Strictly below the table, not across its lower frame. Overlapping the
		# table put four buttons inside the area the player drags across to aim,
		# so shots were being turned into accidental power taps.
		var sink_top := clampf(
			GameConfig.table_outer_bottom() + 6.0,
			GameConfig.board_bottom() + 4.0,
			design_height - sink_row_height - sink_bottom_margin
		)
		sink_buttons_anchor.offset_top = sink_top
		sink_buttons_anchor.offset_bottom = sink_top + sink_row_height
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


## Non-blocking "mission complete" banner.
##
## Sits at the very top of the HUD canvas, above the coin card, and never
## intercepts input: every node in it is MOUSE_FILTER_IGNORE, nothing pauses the
## tree, and the board underneath stays fully playable while it is on screen.
## Missions can complete back to back, so a second call replaces the first
## rather than stacking banners down the screen.
const MISSION_TOAST_SIZE := Vector2(536.0, 84.0)
const MISSION_TOAST_ICON := 54.0
const MISSION_TOAST_HOLD := 2.1
const MISSION_TOAST_RISE := 26.0
const MISSION_TOAST_IN := 0.26
const MISSION_TOAST_OUT := 0.30
const MISSION_TOAST_TOP_INSET := 10.0

func _build_mission_toast() -> void:
	mission_toast = PanelContainer.new()
	mission_toast.name = "MissionCompleteToast"
	mission_toast.custom_minimum_size = MISSION_TOAST_SIZE
	mission_toast.size = MISSION_TOAST_SIZE
	mission_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_toast.add_theme_stylebox_override(
		"panel", UiKit.nine_patch_style("bar_gold_frame", Vector4(76.0, 12.0, 76.0, 12.0)))
	# Above the coin card and the objective stack, below the pause modal.
	mission_toast.z_index = 40
	mission_toast.modulate.a = 0.0
	mission_toast.visible = false
	hud_canvas.add_child(mission_toast)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_toast.add_child(row)

	# The same laurel check the daily-missions popup marks a claimed mission
	# with, so the two read as one system.
	mission_toast_icon = UiKit.texture_rect(UiKit.badge("check"), MISSION_TOAST_ICON)
	mission_toast_icon.name = "MissionToastIcon"
	row.add_child(mission_toast_icon)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)

	mission_toast_title = _label("Daily Mission Complete!", UiDesignSystemType.SMALL_FONT_SIZE, UiDesignSystemType.COLOR_GOLD_LIGHT)
	mission_toast_title.name = "MissionToastTitle"
	mission_toast_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(mission_toast_title)

	mission_toast_label = _label("", UiDesignSystemType.CAPTION_FONT_SIZE, Color.WHITE)
	mission_toast_label.name = "MissionToastLabel"
	mission_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(mission_toast_label)


## Shows the banner for one completed mission. Safe to call mid-shot: it only
## animates its own node and never touches gameplay state.
## One reusable top banner. Daily-mission completions and rewarded-ad grants
## both use it, so an earned thing is announced the same way wherever it came
## from, and neither needs a popup the player has to dismiss.
func show_banner(title: String, subtitle: String, icon: Texture2D = null) -> void:
	if mission_toast == null or mission_toast_label == null:
		return
	mission_toast_title.text = title
	mission_toast_label.text = subtitle
	if mission_toast_icon != null:
		mission_toast_icon.texture = icon if icon != null else UiKit.badge("check")
	_position_mission_toast()
	mission_toast.visible = true
	mission_toast.pivot_offset = mission_toast.size * 0.5
	# Restarting resets the clock, so a second completion replaces the first
	# with a full entrance rather than inheriting a half-faded one.
	_mission_toast_elapsed = 0.0
	_mission_toast_active = true
	_apply_mission_toast_frame()


## Advances the banner. Driven by an explicit delta rather than a Tween so it
## steps identically in play, in tests, and in offscreen captures - the same
## reason GameplayEffectsLayer and the power cinematic own their own timelines.
func update_mission_toast(delta: float) -> void:
	if not _mission_toast_active:
		return
	_mission_toast_elapsed += delta
	_apply_mission_toast_frame()


func _apply_mission_toast_frame() -> void:
	if mission_toast == null:
		return
	var rise_out := MISSION_TOAST_IN + MISSION_TOAST_HOLD
	var total := rise_out + MISSION_TOAST_OUT
	var settled := _mission_toast_settled
	if _mission_toast_elapsed >= total:
		_mission_toast_active = false
		mission_toast.visible = false
		mission_toast.modulate.a = 0.0
		return
	if _mission_toast_elapsed < MISSION_TOAST_IN:
		# Overshoot on the way in, so it arrives with a little weight.
		var t := _mission_toast_elapsed / MISSION_TOAST_IN
		var eased := 1.0 - pow(1.0 - t, 3.0)
		mission_toast.position = settled.lerp(settled - Vector2(0.0, MISSION_TOAST_RISE), 1.0 - eased)
		mission_toast.scale = Vector2.ONE * lerpf(0.92, 1.0, eased)
		mission_toast.modulate.a = clampf(t * 1.6, 0.0, 1.0)
	elif _mission_toast_elapsed < rise_out:
		mission_toast.position = settled
		mission_toast.scale = Vector2.ONE
		mission_toast.modulate.a = 1.0
	else:
		var out_t := (_mission_toast_elapsed - rise_out) / MISSION_TOAST_OUT
		mission_toast.position = settled.lerp(settled - Vector2(0.0, MISSION_TOAST_RISE), out_t)
		mission_toast.scale = Vector2.ONE
		mission_toast.modulate.a = 1.0 - out_t


func show_mission_complete(mission_label: String) -> void:
	show_banner("Daily Mission Complete!", mission_label, UiKit.badge("check"))


func is_mission_toast_visible() -> bool:
	return mission_toast != null and mission_toast.visible


## Floats just inside the upper table for its short life. The limited-shots
## objective stack now uses the centre-top band, so a full-width top banner
## would cover Shots and Target. This surface ignores input and never moves HUD
## or simulation geometry.
func _position_mission_toast() -> void:
	if mission_toast == null:
		return
	_mission_toast_settled = Vector2(
		(UiDesignSystemType.DESIGN_WIDTH - MISSION_TOAST_SIZE.x) * 0.5,
		GameConfig.table_outer_top() + MISSION_TOAST_TOP_INSET
	)
	mission_toast.position = _mission_toast_settled


## The tile artwork for one power, so other layers can reuse it without
## duplicating the preload table.
func power_icon_texture(power: String) -> Texture2D:
	return POWER_ICONS.get(power, null)


## A pair of small kit diamonds pinned to a panel's left and right edges.
##
## Deliberately restrained: two 30px marks per panel, straddling the border so
## they read as part of the frame rather than as content competing with the gem,
## the count, or the target readout inside. Purely decorative and input-inert.
const PANEL_DECOR_SIZE := 30.0

func _decorate_panel_ends(panel: Control) -> void:
	if panel == null:
		return
	# PanelContainer is a Container: it lays out every direct child to fill its
	# content rect and overrides their anchors, which is why anchoring the
	# diamonds directly to it dropped both of them in the middle of the panel,
	# on top of the target text and the gem strip. One plain Control absorbs that
	# layout, and the diamonds anchor freely inside it.
	var overlay := Control.new()
	overlay.name = "PanelDecor"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(overlay)
	var half := PANEL_DECOR_SIZE * 0.5
	# PanelContainer sizes the overlay to its *content* rect, which is inset by
	# the stylebox margin. Without compensating for that inset the diamonds sat
	# fully inside the panel instead of straddling its visible border.
	var style := panel.get_theme_stylebox("panel")
	var inset_left := style.get_margin(SIDE_LEFT) if style != null else 0.0
	var inset_right := style.get_margin(SIDE_RIGHT) if style != null else 0.0
	for side in [-1, 1]:
		var diamond := TextureRect.new()
		diamond.name = "PanelDecorLeft" if side < 0 else "PanelDecorRight"
		diamond.texture = DECOR_DIAMOND
		diamond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		diamond.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Straddling the border, so the pair reads as part of the frame rather
		# than as content sitting inside the panel.
		diamond.set_anchors_preset(Control.PRESET_CENTER_LEFT if side < 0 else Control.PRESET_CENTER_RIGHT)
		diamond.offset_top = -half
		diamond.offset_bottom = half
		var outset := inset_left if side < 0 else inset_right
		var centre := -outset if side < 0 else outset
		diamond.offset_left = centre - half
		diamond.offset_right = centre + half
		overlay.add_child(diamond)
