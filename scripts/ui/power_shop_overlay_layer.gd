class_name PowerShopOverlayLayer
extends CanvasLayer

## The Home-screen power shop. Presentation only: it renders the inventory and
## balance the controller hands it and reports intent through signals. Prices,
## affordability, and persistence stay in the controller and
## PowerInventoryService.
##
## Buy buttons are never disabled when the player cannot afford them. An
## unaffordable power shows the "+" affordance and routes to the rewarded-ad
## offer instead, which is the same rule the gameplay HUD tiles follow.

const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")
const UiKitType = preload("res://scripts/ui/ui_kit.gd")
const PowerInventoryServiceType = preload("res://scripts/services/power_inventory_service.gd")

## Above Home (60) and its daily popup (65) is not needed — the shop is opened
## from Home and is the only thing on screen while it is up.
const OVERLAY_LAYER := 66

const PANEL_WIDTH := 620.0
const ROW_HEIGHT := 116.0
const ROW_ICON := 76.0

const DIM_DURATION := 0.12
const ENTER_DELAY := 0.05
const ENTER_START_SCALE := 0.88
const ENTER_OVERSHOOT := 1.04
const ENTER_RISE := 0.18
const ENTER_SETTLE := 0.12
const EXIT_DURATION := 0.14

signal purchase_requested(power: String)
signal ad_requested(power: String)
signal closed
signal ui_tap_requested

var root: Control
var dim_rect: ColorRect
var panel: PanelContainer
var rows_column: VBoxContainer
var coins_label: Label
var close_button: Button
var visible_shop := false
var power_rows: Dictionary = {}
var _tween: Tween
var _coins := 0
var _counts: Dictionary = {}


func _ready() -> void:
	layer = OVERLAY_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_set_visible(false)


func is_open() -> bool:
	return visible_shop


## Opening plays an entrance; a refresh after a purchase deliberately does not,
## so buying never replays the whole popup animation under the player.
func present(counts: Dictionary, coins: int) -> void:
	_build()
	var was_open := visible_shop
	_counts = counts.duplicate(true)
	_coins = coins
	_refresh()
	if was_open:
		return
	visible_shop = true
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


func close() -> void:
	if not visible_shop:
		return
	visible_shop = false
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(panel, "modulate:a", 0.0, EXIT_DURATION)
	_tween.parallel().tween_property(dim_rect, "color:a", 0.0, EXIT_DURATION)
	_tween.finished.connect(func() -> void:
		_set_visible(false)
	)
	closed.emit()


func handle_back_request() -> bool:
	if not visible_shop:
		return false
	close()
	return true


func _refresh() -> void:
	if coins_label != null:
		coins_label.text = str(_coins)
	for power in power_rows.keys():
		var row: Dictionary = power_rows[power]
		var owned_label := row.get("owned") as Label
		var buy := row.get("buy") as Button
		var price_label := row.get("price") as Label
		var plus_icon := row.get("plus") as TextureRect
		if owned_label == null or buy == null or price_label == null or plus_icon == null:
			continue
		var owned := maxi(0, int(_counts.get(power, 0)))
		var cost := PowerInventoryServiceType.purchase_cost(power)
		owned_label.text = "Owned: %d" % owned
		var affordable := _coins >= cost
		# Never disabled. An unaffordable price swaps the coin cost for the "+"
		# and routes to the rewarded-ad offer instead of presenting a dead button.
		var cost_row := price_label.get_parent() as Control
		if cost_row != null:
			cost_row.visible = affordable
		price_label.text = str(cost)
		plus_icon.visible = not affordable
		buy.text = "BUY" if affordable else "GET"
		buy.tooltip_text = (
			"Buy 1 %s for %d coins" % [PowerInventoryServiceType.label(power), cost]
			if affordable
			else "Not enough coins — watch a short video for 1 %s" % PowerInventoryServiceType.label(power)
		)


func _set_visible(value: bool) -> void:
	if root != null:
		root.visible = value
		root.mouse_filter = Control.MOUSE_FILTER_STOP if value else Control.MOUSE_FILTER_IGNORE


func _build() -> void:
	if root != null:
		return
	root = Control.new()
	root.name = "PowerShopRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiDesignSystemType.theme()
	add_child(root)

	dim_rect = ColorRect.new()
	dim_rect.name = "Dim"
	dim_rect.color = Color(0.04, 0.01, 0.09, 0.0)
	dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim_rect)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(centre)

	var title_column := UiDesignSystemType.popup_title_column("POWERS")
	centre.add_child(title_column)
	panel = PanelContainer.new()
	panel.name = "PowerShopPanel"
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	panel.add_theme_stylebox_override("panel", UiDesignSystemType.gameplay_modal_panel_style())
	title_column.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	# Room at the top for the overlapping title banner.
	margin.add_theme_constant_override("margin_top", 56)
	margin.add_theme_constant_override("margin_bottom", 26)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var balance_row := HBoxContainer.new()
	balance_row.alignment = BoxContainer.ALIGNMENT_CENTER
	balance_row.add_theme_constant_override("separation", 8)
	column.add_child(balance_row)
	balance_row.add_child(UiKitType.texture_rect(UiKitType.ICON_COIN, 44.0))
	coins_label = UiDesignSystemType.style_label(Label.new(), 34, UiDesignSystemType.COLOR_GOLD_LIGHT)
	coins_label.name = "PowerShopCoins"
	coins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	balance_row.add_child(coins_label)

	rows_column = VBoxContainer.new()
	rows_column.name = "PowerShopRows"
	rows_column.add_theme_constant_override("separation", 10)
	column.add_child(rows_column)
	for index in range(PowerInventoryServiceType.ALL.size()):
		rows_column.add_child(_build_row(PowerInventoryServiceType.ALL[index], index))

	close_button = Button.new()
	close_button.name = "PowerShopCloseButton"
	close_button.theme_type_variation = "SecondaryButton"
	close_button.text = "CLOSE"
	close_button.pressed.connect(func() -> void:
		ui_tap_requested.emit()
		close()
	)
	column.add_child(close_button)


## One shop row: the power's art and name on the left, what you own beneath it,
## and the buy action on the right.
func _build_row(power: String, index: int) -> Control:
	var card := PanelContainer.new()
	card.name = "PowerShopRow%s" % power.capitalize()
	card.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	card.add_theme_stylebox_override("panel", UiDesignSystemType.mission_card_style(index))

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_top", 10)
	pad.add_theme_constant_override("margin_bottom", 10)
	card.add_child(pad)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	pad.add_child(row)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = load("res://assets/runtime/ui/kit/power_icon_%s.png" % power) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2.ONE * ROW_ICON
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.alignment = BoxContainer.ALIGNMENT_CENTER
	text_column.add_theme_constant_override("separation", 2)
	row.add_child(text_column)

	var name_label := UiDesignSystemType.style_label(
		Label.new(), UiDesignSystemType.PANEL_TITLE_FONT_SIZE, Color.WHITE)
	name_label.text = PowerInventoryServiceType.label(power).to_upper()
	text_column.add_child(name_label)

	var owned_label := UiDesignSystemType.style_label(
		Label.new(), UiDesignSystemType.CAPTION_FONT_SIZE, UiDesignSystemType.COLOR_GOLD_LIGHT)
	owned_label.name = "Owned"
	text_column.add_child(owned_label)

	var buy := Button.new()
	buy.name = "PowerShopBuy%s" % power.capitalize()
	buy.theme_type_variation = "GreenButton"
	buy.custom_minimum_size = Vector2(168.0, 0.0)
	buy.add_theme_font_size_override("font_size", UiDesignSystemType.SMALL_FONT_SIZE)
	buy.pressed.connect(func() -> void:
		ui_tap_requested.emit()
		# The balance is the authority on which action the tap means, so the
		# price and the "+" can never disagree with what the button does.
		if _coins >= PowerInventoryServiceType.purchase_cost(power):
			purchase_requested.emit(power)
		else:
			ad_requested.emit(power)
	)
	row.add_child(buy)

	var cost_column := VBoxContainer.new()
	cost_column.alignment = BoxContainer.ALIGNMENT_CENTER
	cost_column.custom_minimum_size = Vector2(78.0, 0.0)
	cost_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(cost_column)

	var cost_row := HBoxContainer.new()
	cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cost_row.add_theme_constant_override("separation", 4)
	cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_column.add_child(cost_row)
	cost_row.add_child(UiKitType.texture_rect(UiKitType.ICON_COIN, 32.0))
	var price_label := UiDesignSystemType.style_label(
		Label.new(), UiDesignSystemType.SMALL_FONT_SIZE, UiDesignSystemType.COLOR_GOLD_LIGHT)
	price_label.name = "Price"
	cost_row.add_child(price_label)

	var plus_icon := UiKitType.texture_rect(UiKitType.ICON_PLUS, 44.0)
	plus_icon.name = "Plus"
	plus_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cost_column.add_child(plus_icon)

	power_rows[power] = {
		"card": card,
		"buy": buy,
		"owned": owned_label,
		"price": price_label,
		"plus": plus_icon,
	}
	return card
