class_name DailyMissionsOverlayLayer
extends CanvasLayer

## Daily missions popup, composed from the supplied UI kit. Presentation only:
## it renders the state the controller hands it and reports intent through
## signals. Mission rules, rewards, and persistence stay in the controller and
## DailyMissionService.

const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")
const UiKitType = preload("res://scripts/ui/ui_kit.gd")
const DailyMissionServiceType = preload("res://scripts/services/daily_mission_service.gd")
const PowerInventoryServiceType = preload("res://scripts/services/power_inventory_service.gd")

## Home sits on layer 60 and is the only entry point to this popup, so the
## popup has to sit above it or it opens behind the screen that launched it.
const OVERLAY_LAYER := 65

const CARD_SIZE := Vector2(0.0, 330.0)
const BADGE_HEIGHT := 96.0
const CHEST_ICON_SIZE := 88.0
## Claim sequence: the closed chest shakes, swells, swaps to the open art on a
## flash, then settles. Never an instant image swap.
const CHEST_SHAKE_STEPS := 6
const CHEST_SHAKE_DURATION := 0.055
const CHEST_SHAKE_ANGLE := 0.13
const CHEST_BURST_SCALE := 1.34
const CHEST_BURST_DURATION := 0.20
const CHEST_SETTLE_DURATION := 0.22

## Entrance mirrors the result overlay so every popup in the game moves the
## same way: the dim leads, then the panel overshoots once and settles.
const DIM_DURATION := 0.12
const ENTER_DELAY := 0.05
const ENTER_START_SCALE := 0.88
const ENTER_OVERSHOOT := 1.04
const ENTER_RISE := 0.18
const ENTER_SETTLE := 0.12
const EXIT_DURATION := 0.14
const REWARD_FLOAT_DURATION := 0.62

## Three mission cards have to share 720px. The shared GreenButton padding is
## tuned for full-width modal actions and forces these cards past the screen
## edge, so compact contexts carry their own tighter plate padding.
const COMPACT_BUTTON_CONTENT := Vector4(30.0, 20.0, 30.0, 22.0)

signal mission_claim_requested(index: int)
signal chest_claim_requested
signal ui_tap_requested

var root: Control
var panel: PanelContainer
var cards_row: HBoxContainer
var chest_button: Button
var chest_caption: Label
var chest_icon: TextureRect
var chest_reward_row: HBoxContainer
var coins_label: Label
var close_button: Button
var dim_rect: ColorRect
var _tween: Tween
var _chest_opening := false


func _ready() -> void:
	layer = OVERLAY_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


## Opening plays an entrance; a refresh after a claim deliberately does not, so
## claiming a reward never replays the whole popup animation under the player.
func present(state: Dictionary, coins: int) -> void:
	_build()
	var was_open := root.visible
	_refresh(state, coins)
	root.visible = true
	if not was_open:
		_start_entrance()


func dismiss() -> void:
	if root == null or not root.visible:
		return
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(panel, "scale", Vector2(0.92, 0.92), EXIT_DURATION)
	_tween.tween_property(panel, "modulate:a", 0.0, EXIT_DURATION)
	_tween.tween_property(dim_rect, "modulate:a", 0.0, EXIT_DURATION)
	_tween.chain().tween_callback(func() -> void:
		root.visible = false
		panel.scale = Vector2.ONE
		panel.modulate.a = 1.0
		dim_rect.modulate.a = 1.0)


## Dim leads, then the panel overshoots once and settles.
func _start_entrance() -> void:
	_kill_tween()
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(ENTER_START_SCALE, ENTER_START_SCALE)
	panel.modulate.a = 0.0
	dim_rect.modulate.a = 0.0
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(dim_rect, "modulate:a", 1.0, DIM_DURATION)
	_tween.parallel().tween_property(panel, "modulate:a", 1.0, DIM_DURATION + ENTER_RISE)
	_tween.parallel().tween_property(panel, "scale", Vector2(ENTER_OVERSHOOT, ENTER_OVERSHOOT), ENTER_RISE).set_delay(ENTER_DELAY)
	_tween.chain().set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(panel, "scale", Vector2.ONE, ENTER_SETTLE)


## Reward feedback for a confirmed claim: the card kicks, its badge pops, and a
## coin value floats off it. Called by the controller only after the claim has
## been persisted, so the celebration can never imply an unbanked reward.
func celebrate_claim(index: int, amount: int) -> void:
	if cards_row == null or index < 0 or index >= cards_row.get_child_count():
		return
	var card := cards_row.get_child(index) as Control
	if card == null:
		return
	card.pivot_offset = card.size * 0.5
	var kick := create_tween()
	kick.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	kick.tween_property(card, "scale", Vector2(1.07, 1.07), 0.13)
	kick.set_trans(Tween.TRANS_QUAD)
	kick.tween_property(card, "scale", Vector2.ONE, 0.17)

	var float_label := UiDesignSystemType.style_label(
		Label.new(), UiDesignSystemType.PANEL_TITLE_FONT_SIZE + 4, UiDesignSystemType.COLOR_GOLD_LIGHT)
	float_label.text = "+%d" % amount
	float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	float_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	float_label.size = Vector2(card.size.x, 40.0)
	float_label.global_position = card.global_position + Vector2(0.0, card.size.y * 0.42)
	root.add_child(float_label)
	var rise := create_tween().set_parallel(true)
	rise.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	rise.tween_property(float_label, "global_position:y", float_label.global_position.y - 78.0, REWARD_FLOAT_DURATION)
	rise.tween_property(float_label, "modulate:a", 0.0, REWARD_FLOAT_DURATION).set_delay(REWARD_FLOAT_DURATION * 0.45)
	rise.chain().tween_callback(float_label.queue_free)


## Narrows a kit button so it can live inside a card without forcing the row
## wider than the screen. Keeps the same plates, only the padding differs.
func _apply_compact_button(button: Button, key: String, disabled_key: String) -> void:
	button.add_theme_stylebox_override("normal", UiKitType.nine_patch_style(key, COMPACT_BUTTON_CONTENT))
	button.add_theme_stylebox_override("hover", UiKitType.nine_patch_style(key, COMPACT_BUTTON_CONTENT, UiDesignSystemType.STATE_HOVER))
	button.add_theme_stylebox_override("pressed", UiKitType.nine_patch_style(key, COMPACT_BUTTON_CONTENT, UiDesignSystemType.STATE_PRESSED))
	button.add_theme_stylebox_override("disabled", UiKitType.nine_patch_style(disabled_key, COMPACT_BUTTON_CONTENT, UiDesignSystemType.COLOR_DISABLED_PLATE))


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


func is_open() -> bool:
	return root != null and root.visible


func _build() -> void:
	if root != null:
		return
	root = Control.new()
	root.name = "DailyMissionsRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.theme = UiDesignSystemType.theme()
	root.visible = false
	add_child(root)

	dim_rect = ColorRect.new()
	dim_rect.color = UiDesignSystemType.COLOR_OVERLAY
	dim_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim_rect)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	panel = PanelContainer.new()
	panel.name = "DailyMissionsPanel"
	panel.custom_minimum_size = Vector2(688.0, 0.0)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", UiDesignSystemType.gameplay_modal_panel_style())
	# The header now straddles the panel edge instead of sitting inside it, using
	# the shared treatment so every titled popup in the game reads the same way.
	var title_column := UiDesignSystemType.popup_title_column("DAILY MISSIONS")
	center.add_child(title_column)
	title_column.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	# Clears the half of the title plate that overlaps into the panel.
	margin.add_theme_constant_override("margin_top", 54)
	margin.add_theme_constant_override("margin_bottom", 26)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)


	var subtitle := UiDesignSystemType.style_label(
		Label.new(), UiDesignSystemType.SMALL_FONT_SIZE, UiDesignSystemType.COLOR_GOLD_LIGHT)
	subtitle.text = "Complete all three to unlock the chest"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)

	cards_row = HBoxContainer.new()
	cards_row.name = "MissionCards"
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 16)
	column.add_child(cards_row)

	column.add_child(_chest_section())

	close_button = Button.new()
	close_button.name = "DailyMissionsCloseButton"
	close_button.text = "CLOSE"
	close_button.theme_type_variation = "SecondaryButton"
	close_button.custom_minimum_size = Vector2(0.0, UiDesignSystemType.BUTTON_HEIGHT)
	close_button.pressed.connect(func() -> void:
		ui_tap_requested.emit()
		dismiss())
	column.add_child(close_button)


## Gold ribbon header, matching the banner treatment used across the reference.
func _title_banner(text: String) -> Control:
	var banner := PanelContainer.new()
	banner.custom_minimum_size = Vector2(0.0, UiDesignSystemType.BANNER_HEIGHT)
	banner.add_theme_stylebox_override("panel", UiKitType.nine_patch_style("bar_gold_frame", Vector4(76.0, 12.0, 76.0, 14.0)))
	var label := UiDesignSystemType.style_label(
		Label.new(), UiDesignSystemType.POPUP_TITLE_FONT_SIZE, Color.WHITE)
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_child(label)
	return banner


func _chest_section() -> Control:
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiDesignSystemType.home_status_card_style())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	frame.add_child(row)

	chest_icon = UiKitType.texture_rect(UiKitType.BADGE_CHEST, CHEST_ICON_SIZE)
	chest_icon.name = "DailyChestIcon"
	row.add_child(chest_icon)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 2)
	row.add_child(copy)

	var heading := UiDesignSystemType.style_label(
		Label.new(), UiDesignSystemType.PANEL_TITLE_FONT_SIZE, Color.WHITE)
	heading.text = "DAILY CHEST"
	copy.add_child(heading)

	chest_caption = UiDesignSystemType.style_label(
		Label.new(), UiDesignSystemType.SMALL_FONT_SIZE, UiDesignSystemType.COLOR_TEXT_MUTED)
	# The power payout is longer than the old coin amount, so it wraps rather
	# than forcing the popup past the 720px design width.
	chest_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chest_caption.text = _chest_reward_caption()
	copy.add_child(chest_caption)

	chest_reward_row = HBoxContainer.new()
	chest_reward_row.name = "DailyChestRewardReveal"
	chest_reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
	chest_reward_row.add_theme_constant_override("separation", 10)
	chest_reward_row.visible = false
	chest_reward_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(chest_reward_row)

	chest_button = Button.new()
	chest_button.name = "DailyChestButton"
	chest_button.text = "CLAIM"
	chest_button.theme_type_variation = "GreenButton"
	chest_button.custom_minimum_size = Vector2(196.0, UiDesignSystemType.BUTTON_HEIGHT)
	chest_button.add_theme_font_size_override("font_size", UiDesignSystemType.SMALL_FONT_SIZE)
	_apply_compact_button(chest_button, "btn_green", "btn_green_off")
	chest_button.pressed.connect(func() -> void:
		ui_tap_requested.emit()
		chest_claim_requested.emit())
	row.add_child(chest_button)
	return frame


func _refresh(state: Dictionary, coins: int) -> void:
	for child in cards_row.get_children():
		child.queue_free()
	var missions: Array = state.get("missions", []) as Array
	for index in range(missions.size()):
		cards_row.add_child(_mission_card(missions[index] as Dictionary, index))

	var ready := DailyMissionServiceType.chest_ready(state)
	chest_button.text = "CLAIM" if ready else ("DONE" if bool(state.get("chest_claimed", false)) else "LOCKED")
	chest_button.disabled = not ready
	var claimed := bool(state.get("chest_claimed", false))
	chest_caption.text = "Collected today" if claimed else _chest_reward_caption()
	if chest_reward_row != null and not _chest_opening:
		chest_reward_row.visible = false
		for child in chest_reward_row.get_children():
			child.queue_free()
	if chest_icon != null and not _chest_opening:
		# The claim animation owns the texture while it runs; outside it the icon
		# simply reflects whether the chest for today is still closed.
		chest_icon.texture = UiKitType.BADGE_CHEST_OPEN if claimed else UiKitType.BADGE_CHEST
	if coins_label != null:
		coins_label.text = "%d" % coins


## One mission tile: badge, objective, progress, reward, and its claim action.
func _mission_card(mission: Dictionary, index: int) -> Control:
	var claimed := bool(mission.get("claimed", false))
	var progress := int(mission.get("progress", 0))
	var target := maxi(1, int(mission.get("target", 1)))
	var complete := progress >= target

	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	# Three cards share the row evenly; fixed widths made the row overflow the
	# panel as soon as a claim button carried a longer caption.
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", UiDesignSystemType.mission_card_style(index))

	var pad := MarginContainer.new()
	# Card contents were running to the rim; these keep the artwork frame clear.
	for side in ["left", "right"]:
		pad.add_theme_constant_override("margin_%s" % side, 16)
	pad.add_theme_constant_override("margin_top", 16)
	pad.add_theme_constant_override("margin_bottom", 16)
	card.add_child(pad)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	pad.add_child(column)

	var badge := UiKitType.texture_rect(
		UiKitType.badge("check" if claimed else String(mission.get("icon", "gems"))), BADGE_HEIGHT)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(badge)

	var label := UiDesignSystemType.style_label(
		Label.new(), UiDesignSystemType.SMALL_FONT_SIZE, Color.WHITE)
	label.text = String(mission.get("label", "Mission"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(label)

	column.add_child(_progress_row(progress, target))

	var reward_row := HBoxContainer.new()
	reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_row.add_theme_constant_override("separation", 6)
	column.add_child(reward_row)
	reward_row.add_child(UiKitType.texture_rect(UiKitType.ICON_COIN, 40.0))
	var reward := UiDesignSystemType.style_label(
		Label.new(), UiDesignSystemType.PANEL_TITLE_FONT_SIZE, UiDesignSystemType.COLOR_GOLD_LIGHT)
	reward.text = "%d" % int(mission.get("reward", 0))
	reward_row.add_child(reward)

	var claim := Button.new()
	claim.name = "MissionClaim%d" % index
	claim.theme_type_variation = "GreenButton"
	claim.custom_minimum_size = Vector2(0.0, UiDesignSystemType.BUTTON_HEIGHT)
	claim.add_theme_font_size_override("font_size", UiDesignSystemType.SMALL_FONT_SIZE)
	_apply_compact_button(claim, "btn_green", "btn_green_off")
	claim.text = "DONE" if claimed else "CLAIM"
	claim.disabled = claimed or not complete
	claim.pressed.connect(func() -> void:
		ui_tap_requested.emit()
		mission_claim_requested.emit(index))
	column.add_child(claim)
	return card


## Track, fill, and caption drawn as explicit anchored layers. A themed
## ProgressBar was tried first, but its fill is laid out by the container that
## owns it and collapsed to nothing inside these narrow cards.
func _progress_row(progress: int, target: int) -> Control:
	var track := PanelContainer.new()
	track.custom_minimum_size = Vector2(0.0, 36.0)
	track.add_theme_stylebox_override("panel", UiDesignSystemType.progress_background_style())

	var layers := Control.new()
	layers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layers.custom_minimum_size = Vector2(0.0, 26.0)
	track.add_child(layers)

	var ratio := clampf(float(progress) / float(maxi(1, target)), 0.0, 1.0)
	if ratio > 0.0:
		var fill := Panel.new()
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill.add_theme_stylebox_override("panel", UiDesignSystemType.progress_fill_style())
		layers.add_child(fill)
		fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fill.anchor_right = ratio
		fill.offset_right = 0.0

	var caption := UiDesignSystemType.style_label(
		Label.new(), UiDesignSystemType.SMALL_FONT_SIZE, Color.WHITE, false,
		UiDesignSystemType.TEXT_OUTLINE_SIZE_SMALL)
	caption.text = "%d/%d" % [mini(progress, target), target]
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layers.add_child(caption)
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return track


## Describes the chest payout from the service table rather than a hardcoded
## string, so retuning the reward cannot leave the caption lying.
func _chest_reward_caption() -> String:
	var parts: PackedStringArray = []
	for power in DailyMissionServiceType.CHEST_POWER_REWARD.keys():
		var count := int(DailyMissionServiceType.CHEST_POWER_REWARD[power])
		if count <= 0:
			continue
		parts.append("%d %s" % [count, PowerInventoryServiceType.label(String(power))])
	if parts.is_empty():
		return "Complete all three to unlock the chest"
	return "+ " + ", ".join(parts)


## The chest claim sequence. The controller calls this after the grant has been
## persisted, so the animation reports something that already happened and can
## never be mistaken for the reward itself.
##
## Beats: the closed chest rattles, swells as the lid gives, swaps to the open
## art at the peak under a gold flash, then settles back. An instant texture
## swap read as a bug rather than as opening a chest.
func play_chest_open(granted: Dictionary = {}) -> void:
	if chest_icon == null or _chest_opening:
		return
	_chest_opening = true
	chest_icon.texture = UiKitType.BADGE_CHEST
	chest_icon.pivot_offset = chest_icon.size * 0.5
	chest_icon.rotation = 0.0
	chest_icon.scale = Vector2.ONE
	var sequence := create_tween()
	for step in range(CHEST_SHAKE_STEPS):
		var angle := CHEST_SHAKE_ANGLE * (1.0 if step % 2 == 0 else -1.0)
		sequence.tween_property(chest_icon, "rotation", angle, CHEST_SHAKE_DURATION).set_trans(Tween.TRANS_SINE)
	sequence.tween_property(chest_icon, "rotation", 0.0, CHEST_SHAKE_DURATION)
	sequence.tween_property(chest_icon, "scale", Vector2.ONE * CHEST_BURST_SCALE, CHEST_BURST_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	sequence.tween_callback(func() -> void:
		if chest_icon != null:
			chest_icon.texture = UiKitType.BADGE_CHEST_OPEN
		_flash_chest()
		_reveal_chest_rewards(granted)
	)
	sequence.tween_property(chest_icon, "scale", Vector2.ONE, CHEST_SETTLE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sequence.tween_callback(func() -> void:
		_chest_opening = false
	)


## Presents the actual persisted payout as three staged power cards. The chest
## opening is the anticipation; these named icons are the answer to "what did I
## receive?" and remain visible until the popup closes.
func _reveal_chest_rewards(granted: Dictionary) -> void:
	if chest_reward_row == null:
		return
	for child in chest_reward_row.get_children():
		child.queue_free()
	chest_caption.text = "YOU RECEIVED"
	chest_reward_row.visible = true
	var reveal_index := 0
	for power_value in PowerInventoryServiceType.ALL:
		var power := String(power_value)
		var count := int(granted.get(power, 0))
		if count <= 0:
			continue
		var reward := VBoxContainer.new()
		reward.name = "ChestReward%s" % PowerInventoryServiceType.label(power).replace(" ", "")
		reward.alignment = BoxContainer.ALIGNMENT_CENTER
		reward.custom_minimum_size = Vector2(62.0, 82.0)
		reward.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := TextureRect.new()
		icon.texture = load("res://assets/runtime/ui/kit/power_icon_%s.png" % power) as Texture2D
		icon.custom_minimum_size = Vector2(54.0, 54.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		reward.add_child(icon)
		var amount := UiDesignSystemType.style_label(
			Label.new(), UiDesignSystemType.SMALL_FONT_SIZE, UiDesignSystemType.COLOR_GOLD_LIGHT)
		amount.text = "×%d %s" % [count, PowerInventoryServiceType.label(power)]
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward.add_child(amount)
		chest_reward_row.add_child(reward)
		reward.pivot_offset = reward.custom_minimum_size * 0.5
		reward.scale = Vector2.ONE * 0.2
		reward.modulate.a = 0.0
		var reveal := create_tween().set_parallel(true)
		reveal.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		reveal.tween_property(reward, "scale", Vector2.ONE * 1.12, 0.24).set_delay(float(reveal_index) * 0.14)
		reveal.tween_property(reward, "modulate:a", 1.0, 0.14).set_delay(float(reveal_index) * 0.14)
		reveal.chain().tween_property(reward, "scale", Vector2.ONE, 0.13)
		reveal_index += 1


## A short gold bloom behind the chest at the moment the lid opens. Deliberately
## a single expanding disc rather than a particle burst: this sits inside a
## popup, where a full effect would compete with the reward text beside it.
func _flash_chest() -> void:
	if chest_icon == null or not chest_icon.is_inside_tree():
		return
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.88, 0.46, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.size = Vector2.ONE * CHEST_ICON_SIZE * 1.6
	flash.pivot_offset = flash.size * 0.5
	flash.z_index = -1
	chest_icon.add_child(flash)
	flash.position = (chest_icon.size - flash.size) * 0.5
	flash.scale = Vector2.ONE * 0.4
	var bloom := create_tween()
	bloom.tween_property(flash, "color:a", 0.55, 0.10)
	bloom.parallel().tween_property(flash, "scale", Vector2.ONE * 1.25, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bloom.tween_property(flash, "color:a", 0.0, 0.24)
	bloom.tween_callback(func() -> void:
		if is_instance_valid(flash):
			flash.queue_free()
	)
