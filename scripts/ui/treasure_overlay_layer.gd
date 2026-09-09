class_name TreasureOverlayLayer
extends CanvasLayer

## The fullscreen treasure ceremony. One chest, one tap to open it, then one
## tap per reward.
##
## Every treasure in the game arrives here - the daily chest, the twenty-level
## milestone chest, and the bonus chest a level win sometimes drops - so a
## treasure looks and feels the same wherever the player meets one. Before this
## layer existed the daily chest opened as an 88px icon inside a popup and the
## milestone chest paid out with no animation at all, which made the largest
## reward in the game the least noticeable thing on screen.
##
## The layer is presentation only, and the boundary is load-bearing rather than
## stylistic: the controller grants and **persists** the reward before calling
## `present()`, so what runs here reports something that already happened. A
## player who force-closes the app mid-ceremony keeps the reward. Nothing in
## this file may grant, consume, or modify coins or powers.
##
## The one rule the sequence must keep is that a reward leaves the screen only
## when the player taps it. An auto-advancing reveal was the obvious design and
## is worse: the player's eye is still on the coin pile when the powers flash
## past, and there is nothing they did to earn the feeling of having claimed it.

const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")
const UiKitType = preload("res://scripts/ui/ui_kit.gd")
const PowerInventoryServiceType = preload("res://scripts/services/power_inventory_service.gd")
const TreasureVfxType = preload("res://scripts/presentation/treasure_vfx.gd")

## Above every other surface. The treasure can open over the daily popup (65),
## the level map (61) and, on a post-win drop, over the gameplay HUD (40) with
## the result overlay (50) still to come, so it has to outrank all of them.
const OVERLAY_LAYER := 70

## Chest size as a fraction of the shorter screen edge, and its ceiling. The
## chest has to dominate - it is the only thing on screen worth looking at -
## without crowding the reward card that pushes up beneath it.
const CHEST_SCREEN_FRACTION := 0.56
const CHEST_MAX_SIZE := 400.0
const REWARD_ICON_SIZE := 104.0

## Entrance: the dim leads, then the chest drops in and overshoots once. Matches
## the popup entrance language used everywhere else, only slower and larger,
## because this arrives on its own rather than as an answer to a button.
const DIM_DURATION := 0.18
const CHEST_ENTER_DURATION := 0.34
const CHEST_ENTER_START_SCALE := 0.30
const CHEST_ENTER_OVERSHOOT := 1.10
const CHEST_SETTLE_DURATION := 0.16

## The idle beckon while the chest waits to be tapped. Small on purpose: a chest
## that bounces hard reads as a button, and this one is meant to read as
## treasure sitting there.
const IDLE_PERIOD := 1.5
const IDLE_SCALE := 0.035
const PROMPT_PULSE_PERIOD := 0.9

## Opening: rattle, swell, then the lid gives on a flash and the light behind it
## kicks. The texture swap happens at the peak of the swell, never on its own.
const OPEN_SHAKE_STEPS := 8
const OPEN_SHAKE_DURATION := 0.045
const OPEN_SHAKE_ANGLE := 0.10
const OPEN_BURST_SCALE := 1.30
const OPEN_BURST_DURATION := 0.18
const OPEN_SETTLE_DURATION := 0.24
## Held after the lid opens so the burst is seen before the first reward covers
## it. Without this the card and the flash arrive on the same frame.
const OPEN_HOLD := 0.30

## One reward's arrival and its claim.
const REWARD_ENTER_DURATION := 0.30
const REWARD_ENTER_START_SCALE := 0.24
const REWARD_ENTER_OVERSHOOT := 1.10
const REWARD_SETTLE_DURATION := 0.14
const REWARD_CLAIM_DURATION := 0.30
const REWARD_CLAIM_RISE := 150.0
const REWARD_CLAIM_SCALE := 1.34
## Beat between one reward leaving and the next arriving. Long enough to read as
## two separate gifts, short enough that four rewards do not feel like a queue.
const REWARD_GAP := 0.14

const EXIT_DURATION := 0.26

## Light level the effect holds while the chest waits, and the spike it takes at
## the moment the lid gives.
const VFX_IDLE_INTENSITY := 0.55
const VFX_BURST_INTENSITY := 1.55
const VFX_BURST_DECAY := 0.55

## The lid giving, and each reward being claimed. Presentation signals only -
## every reward was granted and saved before the ceremony opened. The controller
## listens to them so the cues stay behind the audio and haptic services rather
## than being played from a UI layer.
##
## `reward_claimed` carries a 1-based ordinal so the claim cue can rise through
## the sequence instead of repeating one note.
signal chest_opened
signal reward_claimed(ordinal: int)

## Fired once the last reward has been claimed and the overlay has closed.
## The controller waits on this before presenting whatever comes next - on a
## post-win drop, that is the win popup.
signal treasure_finished
signal ui_tap_requested

enum Phase {
	CLOSED,
	## Chest shut, waiting for the tap that opens it.
	READY,
	## Lid giving. Taps are ignored; skipping this would skip the flash.
	OPENING,
	## A reward is on screen waiting to be claimed.
	REWARD,
	## Between rewards, or on the way out.
	BUSY,
}

var root: Control
var dim_rect: ColorRect
var vfx: TreasureVfx
var column: VBoxContainer
var chest_icon: TextureRect
var reward_host: MarginContainer
var prompt_label: Label
var title_label: Label

## The rewards still to be claimed, in claim order, each
## `{texture, amount_text, name_text}`.
var _queue: Array[Dictionary] = []
var _card: Control
var _phase := Phase.CLOSED
var _tween: Tween
var _idle_time := 0.0
## How many rewards have been claimed this ceremony, so the claim cue can rise
## with each one instead of repeating a single note.
var _claimed_count := 0


func _ready() -> void:
	layer = OVERLAY_LAYER
	# The post-win drop opens while the tree is paused behind a result flow, and
	# the daily/milestone drops open over paused menus. A treasure that stopped
	# animating because something else paused would strand the player on a tap
	# prompt that never answers.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	set_process(true)
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_relayout):
		viewport.size_changed.connect(_relayout)


func is_open() -> bool:
	return root != null and root.visible


## Back is swallowed while a treasure is open. There is no decision to answer
## here and no way to decline a reward, so the only alternatives are dropping
## the player out of an unfinished ceremony or skipping rewards they have
## already been granted.
func handle_back_request() -> bool:
	return is_open()


## Opens the ceremony for an already-granted, already-persisted reward.
##
## Returns false when nothing was handed over, so a caller can carry straight on
## to whatever it was going to do next rather than waiting on a
## `treasure_finished` that would never arrive.
func present(coins: int, powers: Dictionary, title: String = "TREASURE") -> bool:
	if root == null:
		_build()
	if is_open():
		return false
	_queue = _build_queue(coins, powers)
	if _queue.is_empty():
		return false
	_claimed_count = 0
	title_label.text = title
	_clear_card()
	_relayout()
	chest_icon.texture = UiKitType.BADGE_CHEST
	chest_icon.rotation = 0.0
	chest_icon.modulate = Color.WHITE
	prompt_label.text = "TAP TO OPEN"
	prompt_label.modulate.a = 0.0
	root.visible = true
	_phase = Phase.BUSY
	_start_entrance()
	return true


## Advances the idle beckon on the chest and the breathing prompt. Both are
## driven here rather than from looping tweens so that a phase change cancels
## them by simply not being in that phase any more - a looping tween has to be
## found and killed, and the one that was missed is what left the chest pulsing
## under an open lid.
func _process(delta: float) -> void:
	if not is_open():
		return
	_idle_time += delta
	if _phase == Phase.READY and chest_icon != null:
		var breath := 1.0 + sin(_idle_time * TAU / IDLE_PERIOD) * IDLE_SCALE
		chest_icon.scale = Vector2(breath, breath)
	if prompt_label != null and (_phase == Phase.READY or _phase == Phase.REWARD):
		prompt_label.modulate.a = 0.62 + 0.38 * (0.5 + 0.5 * sin(_idle_time * TAU / PROMPT_PULSE_PERIOD))
	if vfx != null and chest_icon != null and chest_icon.is_inside_tree():
		vfx.focus = chest_icon.get_global_rect().get_center() - vfx.global_position


## One tap target for the whole screen. The chest and the reward card are not
## buttons: a card that had to be hit exactly would turn a celebration into
## aiming practice, and on a post-win drop the player's thumb is wherever the
## last shot left it.
func _on_root_input(event: InputEvent) -> void:
	var tapped := false
	if event is InputEventScreenTouch:
		tapped = not (event as InputEventScreenTouch).pressed
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		tapped = not mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	if not tapped:
		return
	root.accept_event()
	handle_tap()


## The tap the ceremony advances on, exposed so the sequence can be driven
## without synthesising input events.
func handle_tap() -> void:
	match _phase:
		Phase.READY:
			ui_tap_requested.emit()
			_open_chest()
		Phase.REWARD:
			ui_tap_requested.emit()
			_claim_current_reward()
		_:
			pass


## Coins first, then powers in the shared display order, so the sequence always
## runs biggest-to-smallest and two treasures with the same contents always play
## back the same way. Each power is one card carrying its count rather than one
## card per unit: three taps for three Switches is a queue, not a haul.
func _build_queue(coins: int, powers: Dictionary) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	if coins > 0:
		items.append({
			"texture": UiKitType.ICON_COIN,
			"amount_text": "+%d" % coins,
			"name_text": "COINS",
		})
	for power_value in PowerInventoryServiceType.ALL:
		var power := String(power_value)
		var count := int(powers.get(power, 0))
		if count <= 0:
			continue
		items.append({
			"texture": _power_texture(power),
			"amount_text": "×%d" % count,
			"name_text": PowerInventoryServiceType.label(power).to_upper(),
		})
	return items


func _power_texture(power: String) -> Texture2D:
	return load("res://assets/runtime/ui/kit/power_icon_%s.png" % power) as Texture2D


func _start_entrance() -> void:
	_kill_tween()
	dim_rect.modulate.a = 0.0
	chest_icon.pivot_offset = chest_icon.size * 0.5
	chest_icon.scale = Vector2.ONE * CHEST_ENTER_START_SCALE
	chest_icon.modulate.a = 0.0
	title_label.modulate.a = 0.0
	if vfx != null:
		vfx.intensity = 0.0
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(dim_rect, "modulate:a", 1.0, DIM_DURATION)
	_tween.parallel().tween_property(chest_icon, "modulate:a", 1.0, DIM_DURATION)
	_tween.parallel().tween_property(title_label, "modulate:a", 1.0, DIM_DURATION + 0.1)
	if vfx != null:
		_tween.parallel().tween_property(vfx, "intensity", VFX_IDLE_INTENSITY, DIM_DURATION + CHEST_ENTER_DURATION)
	_tween.parallel().tween_property(chest_icon, "scale", Vector2.ONE * CHEST_ENTER_OVERSHOOT, CHEST_ENTER_DURATION) \
		.set_trans(Tween.TRANS_BACK)
	_tween.chain().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(chest_icon, "scale", Vector2.ONE, CHEST_SETTLE_DURATION)
	_tween.tween_callback(func() -> void:
		_idle_time = 0.0
		_phase = Phase.READY)


## Rattle, swell, lid gives on a flash, settle. The texture swap sits at the
## peak of the swell and never on its own - an instant swap reads as a bug
## rather than as a chest opening, which is the lesson the daily chest already
## learned at icon size.
func _open_chest() -> void:
	_phase = Phase.OPENING
	prompt_label.text = ""
	prompt_label.modulate.a = 0.0
	_kill_tween()
	chest_icon.pivot_offset = chest_icon.size * 0.5
	chest_icon.scale = Vector2.ONE
	_tween = create_tween()
	for step in range(OPEN_SHAKE_STEPS):
		var angle := OPEN_SHAKE_ANGLE * (1.0 if step % 2 == 0 else -1.0)
		_tween.tween_property(chest_icon, "rotation", angle, OPEN_SHAKE_DURATION).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(chest_icon, "rotation", 0.0, OPEN_SHAKE_DURATION)
	_tween.tween_property(chest_icon, "scale", Vector2.ONE * OPEN_BURST_SCALE, OPEN_BURST_DURATION) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(_burst_open)
	_tween.tween_property(chest_icon, "scale", Vector2.ONE, OPEN_SETTLE_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_interval(OPEN_HOLD)
	_tween.tween_callback(_advance_reward)


func _burst_open() -> void:
	if chest_icon != null:
		chest_icon.texture = UiKitType.BADGE_CHEST_OPEN
	chest_opened.emit()
	if vfx == null:
		return
	vfx.intensity = VFX_BURST_INTENSITY
	var decay := create_tween()
	decay.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	decay.tween_property(vfx, "intensity", VFX_IDLE_INTENSITY, VFX_BURST_DECAY)


## Presents the next reward, or closes when the queue is empty.
func _advance_reward() -> void:
	_clear_card()
	if _queue.is_empty():
		_finish()
		return
	var item: Dictionary = _queue.pop_front()
	_card = _reward_card(item)
	reward_host.add_child(_card)
	prompt_label.text = "TAP TO CLAIM"
	_phase = Phase.BUSY
	# The card's size is only known once the container has laid it out, and its
	# pivot has to be its own centre or the pop happens about the top-left
	# corner. Deferring one frame is what makes the scale read as a pop.
	_card.scale = Vector2.ZERO
	_card.modulate.a = 0.0
	call_deferred("_animate_card_in")


func _animate_card_in() -> void:
	if _card == null or not is_instance_valid(_card):
		return
	_card.pivot_offset = _card.size * 0.5
	_card.scale = Vector2.ONE * REWARD_ENTER_START_SCALE
	var enter := create_tween()
	enter.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	enter.tween_property(_card, "scale", Vector2.ONE * REWARD_ENTER_OVERSHOOT, REWARD_ENTER_DURATION)
	enter.parallel().tween_property(_card, "modulate:a", 1.0, REWARD_ENTER_DURATION * 0.6)
	enter.chain().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	enter.tween_property(_card, "scale", Vector2.ONE, REWARD_SETTLE_DURATION)
	enter.tween_callback(func() -> void:
		_idle_time = 0.0
		_phase = Phase.REWARD)


## The claim: the card swells and rises away rather than simply vanishing, so
## the reward reads as going somewhere - into the balance the player is about to
## see - instead of being dismissed.
func _claim_current_reward() -> void:
	if _card == null or not is_instance_valid(_card):
		_advance_reward()
		return
	_phase = Phase.BUSY
	prompt_label.text = ""
	prompt_label.modulate.a = 0.0
	_claimed_count += 1
	reward_claimed.emit(_claimed_count)
	var card := _card
	_card = null
	card.pivot_offset = card.size * 0.5
	var claim := create_tween().set_parallel(true)
	claim.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	claim.tween_property(card, "scale", Vector2.ONE * REWARD_CLAIM_SCALE, REWARD_CLAIM_DURATION)
	claim.tween_property(card, "position:y", card.position.y - REWARD_CLAIM_RISE, REWARD_CLAIM_DURATION)
	claim.tween_property(card, "modulate:a", 0.0, REWARD_CLAIM_DURATION).set_delay(REWARD_CLAIM_DURATION * 0.3)
	claim.chain().tween_interval(REWARD_GAP)
	claim.chain().tween_callback(func() -> void:
		if is_instance_valid(card):
			card.queue_free()
		_advance_reward())


func _finish() -> void:
	_phase = Phase.BUSY
	prompt_label.text = ""
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(chest_icon, "scale", Vector2.ONE * 0.82, EXIT_DURATION)
	_tween.tween_property(chest_icon, "modulate:a", 0.0, EXIT_DURATION)
	_tween.tween_property(title_label, "modulate:a", 0.0, EXIT_DURATION)
	_tween.tween_property(dim_rect, "modulate:a", 0.0, EXIT_DURATION)
	if vfx != null:
		_tween.tween_property(vfx, "intensity", 0.0, EXIT_DURATION)
	_tween.chain().tween_callback(_close)


func _close() -> void:
	_clear_card()
	_phase = Phase.CLOSED
	if root != null:
		root.visible = false
	if chest_icon != null:
		chest_icon.scale = Vector2.ONE
		chest_icon.modulate = Color.WHITE
		chest_icon.rotation = 0.0
	if vfx != null:
		vfx.intensity = 0.0
	treasure_finished.emit()


func _clear_card() -> void:
	if _card != null and is_instance_valid(_card):
		_card.queue_free()
	_card = null
	if reward_host == null:
		return
	for child in reward_host.get_children():
		child.queue_free()


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


func _reward_card(item: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.name = "TreasureRewardCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.add_theme_stylebox_override("panel", UiDesignSystemType.gameplay_modal_panel_style())

	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		pad.add_theme_constant_override("margin_%s" % side, 34)
	for side in ["top", "bottom"]:
		pad.add_theme_constant_override("margin_%s" % side, 22)
	card.add_child(pad)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	pad.add_child(row)

	var icon := TextureRect.new()
	icon.texture = item.get("texture") as Texture2D
	icon.custom_minimum_size = Vector2(REWARD_ICON_SIZE, REWARD_ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var copy := VBoxContainer.new()
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 2)
	row.add_child(copy)

	var amount := UiDesignSystemType.style_label(
		Label.new(), UiDesignSystemType.SCORE_FONT_SIZE, UiDesignSystemType.COLOR_GOLD_LIGHT)
	amount.name = "TreasureRewardAmount"
	amount.text = String(item.get("amount_text", ""))
	copy.add_child(amount)

	var reward_name := UiDesignSystemType.style_label(
		Label.new(), UiDesignSystemType.BODY_FONT_SIZE, UiDesignSystemType.COLOR_TEXT_MUTED)
	reward_name.name = "TreasureRewardName"
	reward_name.text = String(item.get("name_text", ""))
	copy.add_child(reward_name)
	return card


func _build() -> void:
	if root != null:
		return
	root = Control.new()
	root.name = "TreasureRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# The whole screen is the tap target, and it must also block the surface
	# underneath: on a post-win drop the gameplay board is still live below.
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.theme = UiDesignSystemType.theme()
	root.visible = false
	root.gui_input.connect(_on_root_input)
	add_child(root)

	dim_rect = ColorRect.new()
	dim_rect.name = "TreasureDim"
	# Deeper than the shared popup dim. This is the only thing on screen and the
	# gold effect behind the chest needs somewhere dark to read against.
	dim_rect.color = Color(0.02, 0.006, 0.045, 0.90)
	dim_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim_rect)

	vfx = TreasureVfxType.new()
	vfx.name = "TreasureVfx"
	vfx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(vfx)

	var center := CenterContainer.new()
	center.name = "TreasureCenter"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	column = VBoxContainer.new()
	column.name = "TreasureColumn"
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 26)
	center.add_child(column)

	title_label = UiDesignSystemType.style_label(
		Label.new(), UiDesignSystemType.POPUP_TITLE_FONT_SIZE, UiDesignSystemType.COLOR_GOLD_LIGHT, true)
	title_label.name = "TreasureTitle"
	title_label.text = "TREASURE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(title_label)

	chest_icon = TextureRect.new()
	chest_icon.name = "TreasureChest"
	chest_icon.texture = UiKitType.BADGE_CHEST
	chest_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chest_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chest_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chest_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(chest_icon)

	# Holds at most one reward card. It carries no minimum height, so the column
	# is compact while the chest waits and the chest lifts as a card arrives -
	# the lift is the layout, not a second animation to keep in sync.
	reward_host = MarginContainer.new()
	reward_host.name = "TreasureRewardHost"
	reward_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(reward_host)

	prompt_label = UiDesignSystemType.style_label(
		Label.new(), UiDesignSystemType.PANEL_TITLE_FONT_SIZE, Color.WHITE)
	prompt_label.name = "TreasurePrompt"
	prompt_label.text = "TAP TO OPEN"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(prompt_label)

	_relayout()


## The chest is sized against the shorter screen edge rather than the design
## canvas, so it stays the hero of the screen on a tall phone and does not run
## into the reward card on a short one.
func _relayout() -> void:
	if chest_icon == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size if get_viewport() != null else Vector2(720.0, 1280.0)
	var edge := minf(viewport_size.x, viewport_size.y)
	var chest_size := minf(edge * CHEST_SCREEN_FRACTION, CHEST_MAX_SIZE)
	chest_icon.custom_minimum_size = Vector2(chest_size, chest_size)
	chest_icon.pivot_offset = Vector2(chest_size, chest_size) * 0.5
