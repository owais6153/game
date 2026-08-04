class_name HomeOverlayLayer
extends CanvasLayer

const UiDesignSystemType = preload("res://scripts/ui_design_system.gd")

signal play_requested

var root_control: Control
var level_label: Label
var coins_label: Label
var play_button: Button

func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func present(level_number: int, coins: int) -> void:
	_build()
	level_label.text = "LEVEL %d" % level_number
	coins_label.text = "COINS  %s" % ScoreFormatter.format(coins)
	root_control.visible = true
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	play_button.grab_focus()

func dismiss() -> void:
	if root_control != null:
		root_control.visible = false
		root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _build() -> void:
	if root_control != null:
		return
	root_control = Control.new()
	root_control.name = "HomeOverlayRoot"
	root_control.theme = UiDesignSystemType.theme()
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root_control)
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.12, 0.06, 0.03, 0.48)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(dimmer)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460.0, 430.0)
	panel.add_theme_stylebox_override("panel", UiDesignSystemType.simple_popup_panel_style())
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 40)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)
	column.add_child(_label("GEM MERGE", 48, UiDesignSystemType.COLOR_CORAL))
	column.add_child(_label("A NEW CHAIN EVERY LEVEL", 17, UiDesignSystemType.COLOR_TEXT_MUTED))
	level_label = _label("LEVEL 1", 30, UiDesignSystemType.COLOR_TEAL)
	column.add_child(level_label)
	coins_label = _label("COINS  0", 24, UiDesignSystemType.COLOR_GOLD)
	column.add_child(coins_label)
	play_button = Button.new()
	play_button.text = "CONTINUE"
	play_button.custom_minimum_size = Vector2(320.0, 78.0)
	play_button.pressed.connect(func() -> void: play_requested.emit())
	column.add_child(play_button)

func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UiDesignSystemType.font())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
