class_name PowerOverlayLayer
extends CanvasLayer

## Popups that sit in front of the live board for the power economy and the
## first-time targeting tutorial. Presentation only: it renders the state the
## controller hands it and reports intent through signals. Ownership, ad
## eligibility, and persistence stay in the controller and PowerInventoryService.
##
## The rewarded-ad path is deliberately three steps rather than one. Tapping the
## plus opens an offer the player can decline; only confirming plays the ad; and
## the same popup then reports what was granted. Launching an ad straight from
## the tile gave the player no way out and no confirmation of what they earned.

const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")
const UiKitType = preload("res://scripts/ui/ui_kit.gd")
const PowerInventoryServiceType = preload("res://scripts/services/power_inventory_service.gd")

## Above the gameplay HUD but below the result overlay, which owns the screen
## whenever a level has actually ended.
const OVERLAY_LAYER := 55

const PANEL_WIDTH := 560.0
const ICON_SIZE := 168.0

## Matches the daily-missions and result overlays so every popup in the game
## moves the same way: the dim leads, then the panel overshoots once and settles.
const DIM_DURATION := 0.12
const ENTER_DELAY := 0.05
const ENTER_START_SCALE := 0.88
const ENTER_OVERSHOOT := 1.04
const ENTER_RISE := 0.18
const ENTER_SETTLE := 0.12
const EXIT_DURATION := 0.14
const REWARD_POP_SCALE := 1.22
const REWARD_POP_DURATION := 0.26
const REWARD_RAY_COUNT := 12

signal ad_confirmed(power: String)
signal how_to_acknowledged(power: String)
signal closed
signal ui_tap_requested

enum Mode { NONE, AD_OFFER, AD_RESULT, HOW_TO }

var root: Control
var dim_rect: ColorRect
var panel: PanelContainer
var icon_rect: TextureRect
var title_label: Label
var body_label: Label
var primary_button: Button
var secondary_button: Button
var mode: int = Mode.NONE
var active_power := ""
var _tween: Tween


func _ready() -> void:
	layer = OVERLAY_LAYER
	# The board pauses under a modal, so the popup must keep processing to run
	# its own entrance and reward animations.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_set_visible(false)


func is_open() -> bool:
	return mode != Mode.NONE


## Step one of the rewarded-ad path: an offer the player can decline.
## An unavailable ad still shows the offer and explains why it cannot play,
## rather than silently doing nothing when the player taps.
func present_ad_offer(power: String, ad_ready: bool, daily_cap_reached: bool) -> void:
	_build()
	mode = Mode.AD_OFFER
	active_power = power
	var power_label := PowerInventoryServiceType.label(power)
	icon_rect.texture = _icon_for(power)
	title_label.text = "Out of %s" % power_label.to_upper()
	if daily_cap_reached:
		body_label.text = "You have claimed every free %s for today. Come back tomorrow, or buy more with coins." % power_label
		primary_button.visible = false
	elif not ad_ready:
		body_label.text = "No video is ready right now. Try again in a moment, or buy %s with coins." % power_label
		primary_button.visible = false
	else:
		body_label.text = "Watch a short video to get 1 %s." % power_label
		primary_button.visible = true
		primary_button.text = "WATCH VIDEO"
	secondary_button.text = "CLOSE"
	_present()


## Step three: the same popup reports what the completed ad granted, so the
## player always sees which power they earned.
func present_ad_result(power: String, granted: bool, owned: int) -> void:
	_build()
	mode = Mode.AD_RESULT
	active_power = power
	var power_label := PowerInventoryServiceType.label(power)
	icon_rect.texture = _icon_for(power)
	if granted:
		title_label.text = "+1 %s" % power_label.to_upper()
		body_label.text = "You now have %d." % owned
	else:
		# Cancelled, failed, or dismissed early. Nothing was granted and no
		# daily allowance was consumed, and the player is told exactly that.
		title_label.text = "No reward"
		body_label.text = "The video did not finish, so no %s was added." % power_label
	primary_button.visible = false
	secondary_button.text = "CONTINUE"
	_present()
	if granted:
		_play_reward_celebration()


## Shown once per power, the first time a targeted power is armed, because
## "select, then tap the board" is not discoverable from the tile alone.
func present_how_to(power: String) -> void:
	_build()
	mode = Mode.HOW_TO
	active_power = power
	var power_label := PowerInventoryServiceType.label(power)
	icon_rect.texture = _icon_for(power)
	title_label.text = "USING %s" % power_label.to_upper()
	body_label.text = "%s\n\nDrag it onto the gem you want, or tap the board after selecting it. Tap %s again to cancel." % [
		PowerInventoryServiceType.description(power),
		power_label,
	]
	primary_button.visible = false
	secondary_button.text = "GOT IT"
	_present()


func close() -> void:
	if mode == Mode.NONE:
		return
	var finished_mode := mode
	var finished_power := active_power
	mode = Mode.NONE
	active_power = ""
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(panel, "modulate:a", 0.0, EXIT_DURATION)
	_tween.parallel().tween_property(dim_rect, "color:a", 0.0, EXIT_DURATION)
	_tween.finished.connect(func() -> void:
		_set_visible(false)
	)
	if finished_mode == Mode.HOW_TO:
		how_to_acknowledged.emit(finished_power)
	closed.emit()


## Back must dismiss the popup rather than falling through to Pause or Home.
func handle_back_request() -> bool:
	if mode == Mode.NONE:
		return false
	close()
	return true


func _present() -> void:
	_set_visible(true)
	panel.modulate.a = 1.0
	dim_rect.color.a = 0.0
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2.ONE * ENTER_START_SCALE
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(dim_rect, "color:a", 0.62, DIM_DURATION)
	_tween.tween_interval(ENTER_DELAY)
	_tween.tween_property(panel, "scale", Vector2.ONE * ENTER_OVERSHOOT, ENTER_RISE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(panel, "scale", Vector2.ONE, ENTER_SETTLE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _set_visible(value: bool) -> void:
	if root != null:
		root.visible = value
		root.mouse_filter = Control.MOUSE_FILTER_STOP if value else Control.MOUSE_FILTER_IGNORE


func _icon_for(power: String) -> Texture2D:
	return load("res://assets/runtime/ui/kit/power_icon_%s.png" % power) as Texture2D


func _build() -> void:
	if root != null:
		return
	root = Control.new()
	root.name = "PowerOverlayRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiDesignSystemType.theme()
	add_child(root)

	dim_rect = ColorRect.new()
	dim_rect.name = "Dim"
	dim_rect.color = Color(0.04, 0.01, 0.09, 0.0)
	dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	# The dim blocks the board underneath, which is what makes this modal.
	dim_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim_rect)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(centre)

	panel = PanelContainer.new()
	panel.name = "PowerPanel"
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	panel.add_theme_stylebox_override("panel", UiDesignSystemType.gameplay_modal_panel_style())
	centre.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)

	var icon_centre := CenterContainer.new()
	column.add_child(icon_centre)
	icon_rect = TextureRect.new()
	icon_rect.name = "PowerIcon"
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2.ONE * ICON_SIZE
	icon_centre.add_child(icon_rect)

	title_label = UiDesignSystemType.style_label(Label.new(), 40, Color("ffe9a8"), true)
	title_label.name = "Title"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title_label)

	body_label = UiDesignSystemType.style_label(Label.new(), 24, Color("e6d4ff"))
	body_label.name = "Body"
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.custom_minimum_size = Vector2(PANEL_WIDTH - 68.0, 0.0)
	column.add_child(body_label)

	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	column.add_child(actions)

	primary_button = Button.new()
	primary_button.name = "PowerAdConfirmButton"
	primary_button.theme_type_variation = "GreenButton"
	primary_button.pressed.connect(func() -> void:
		ui_tap_requested.emit()
		# The controller owns the ad call; the popup stays open underneath so it
		# can report the result into the same panel when the ad returns.
		ad_confirmed.emit(active_power)
	)
	actions.add_child(primary_button)

	secondary_button = Button.new()
	secondary_button.name = "PowerCloseButton"
	secondary_button.theme_type_variation = "SecondaryButton"
	secondary_button.pressed.connect(func() -> void:
		ui_tap_requested.emit()
		close()
	)
	actions.add_child(secondary_button)


## Earning a power has to read as a reward, not as a receipt. A plain scale pop
## was not enough: the player has just watched a video and comes back needing to
## see what they got.
##
## Rays bloom out behind the icon, the icon lands with an overshoot, and the
## title punches in after it, so the reward arrives in stages rather than all at
## once. Deliberately smaller than the gameplay power cinematic — this is a
## popup, and the panel behind it still has to stay readable.
func _play_reward_celebration() -> void:
	if icon_rect == null or not icon_rect.is_inside_tree():
		return
	_spawn_reward_rays()
	icon_rect.pivot_offset = icon_rect.size * 0.5
	icon_rect.scale = Vector2.ONE * 0.45
	icon_rect.rotation = -0.22
	var pop := create_tween()
	pop.tween_property(icon_rect, "scale", Vector2.ONE * REWARD_POP_SCALE, REWARD_POP_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.parallel().tween_property(icon_rect, "rotation", 0.0, REWARD_POP_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(icon_rect, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if title_label != null:
		title_label.pivot_offset = title_label.size * 0.5
		title_label.scale = Vector2.ONE * 0.7
		title_label.modulate.a = 0.0
		var title_tween := create_tween()
		title_tween.tween_interval(REWARD_POP_DURATION * 0.6)
		title_tween.tween_property(title_label, "modulate:a", 1.0, 0.12)
		title_tween.parallel().tween_property(title_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## A short burst of gold rays behind the power icon. Drawn as rotating Line2D
## spokes rather than particles so it stays crisp at any popup size and cannot
## spill outside the panel.
func _spawn_reward_rays() -> void:
	var rays := Control.new()
	rays.name = "RewardRays"
	rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rays.z_index = -1
	rays.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_rect.add_child(rays)
	var centre := icon_rect.size * 0.5
	for index in range(REWARD_RAY_COUNT):
		var spoke := Line2D.new()
		var angle := TAU * float(index) / float(REWARD_RAY_COUNT)
		spoke.add_point(centre + Vector2.from_angle(angle) * (ICON_SIZE * 0.34))
		spoke.add_point(centre + Vector2.from_angle(angle) * (ICON_SIZE * 0.92))
		spoke.width = 7.0
		spoke.default_color = Color(1.0, 0.86, 0.42, 0.0)
		rays.add_child(spoke)
		var fade := create_tween()
		fade.tween_property(spoke, "default_color:a", 0.75, 0.14).set_delay(float(index) * 0.012)
		fade.tween_property(spoke, "default_color:a", 0.0, 0.42)
	var spin := create_tween()
	rays.pivot_offset = centre
	spin.tween_property(rays, "rotation", 0.42, 0.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	spin.tween_callback(func() -> void:
		if is_instance_valid(rays):
			rays.queue_free()
	)
