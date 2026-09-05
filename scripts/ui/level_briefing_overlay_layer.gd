class_name LevelBriefingOverlayLayer
extends CanvasLayer

## One-time explainer for each level type. Shown the first time the player
## starts a level of a given type and never again once that type is recorded as
## seen, so a returning player is not re-taught rules they already know.
##
## Presentation only: it renders the copy it is handed and reports dismissal.
## Whether a briefing is due, and recording that it was shown, belong to the
## controller and ProgressionSaveService.

## Above gameplay and the result overlay, below nothing else it must not cover.
const OVERLAY_LAYER := 70

const DIM_DURATION := 0.12
const ENTER_DELAY := 0.05
const ENTER_START_SCALE := 0.88
const ENTER_OVERSHOOT := 1.04
const ENTER_RISE := 0.18
const ENTER_SETTLE := 0.12
const EXIT_DURATION := 0.14

const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")
const UiKitType = preload("res://scripts/ui/ui_kit.gd")
const MascotViewType = preload("res://scripts/ui/mascot_view.gd")

## Big enough that the mascot, not the prose, is the first thing read.
const MASCOT_SIZE := 260.0

signal dismissed
signal ui_tap_requested

var root: Control
var dim_rect: ColorRect
var panel: PanelContainer
## The animated node: title banner plus panel. See UiDesignSystem.popup_shell.
var popup_shell: Control
var title_label: Label
var badge_slot: CenterContainer
var body_label: Label
var start_button: Button
var mascot: MascotView
var _tween: Tween


func _ready() -> void:
	layer = OVERLAY_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func is_open() -> bool:
	return root != null and root.visible


## `briefing` supplies title, body, and badge name. See GameController.
func present(briefing: Dictionary) -> void:
	_build()
	title_label.text = String(briefing.get("title", "HOW TO PLAY"))
	body_label.text = String(briefing.get("body", ""))
	# The briefing is the calm screen before a level starts, so the mascot sits
	# neutral here. The old kit badge said nothing the title did not already say.
	mascot.show_idle(true)
	start_button.text = String(briefing.get("action", "GOT IT"))
	root.visible = true
	_start_entrance()


func dismiss() -> void:
	if root == null or not root.visible:
		return
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(popup_shell, "scale", Vector2(0.92, 0.92), EXIT_DURATION)
	_tween.tween_property(popup_shell, "modulate:a", 0.0, EXIT_DURATION)
	_tween.tween_property(dim_rect, "modulate:a", 0.0, EXIT_DURATION)
	_tween.chain().tween_callback(func() -> void:
		root.visible = false
		popup_shell.scale = Vector2.ONE
		popup_shell.modulate.a = 1.0
		dim_rect.modulate.a = 1.0
		dismissed.emit())


func _build() -> void:
	if root != null:
		return
	root = Control.new()
	root.name = "LevelBriefingRoot"
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
	panel.name = "LevelBriefingPanel"
	panel.custom_minimum_size = Vector2(596.0, 0.0)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", UiDesignSystemType.gameplay_modal_panel_style())
	popup_shell = UiDesignSystemType.popup_shell("HOW TO PLAY", panel)
	center.add_child(popup_shell)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	# Clears the half of the title plate that overlaps into the panel.
	margin.add_theme_constant_override("margin_top", 58)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	margin.add_child(column)

	# The heading is the shared half-out plate from the shell, not a second
	# banner inside the body.
	title_label = UiDesignSystemType.popup_shell_label(popup_shell)

	badge_slot = CenterContainer.new()
	badge_slot.custom_minimum_size = Vector2(0.0, MASCOT_SIZE)
	badge_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(badge_slot)
	mascot = MascotViewType.new()
	mascot.custom_minimum_size = Vector2(MASCOT_SIZE, MASCOT_SIZE)
	# See the result popup: the panel already has an entrance scale of its own.
	mascot.breathing_enabled = false
	badge_slot.add_child(mascot)

	# Running prose, so this is the one place that deliberately uses the lighter
	# UI weight with generous line spacing rather than the heavy display face.
	body_label = UiDesignSystemType.style_label(
		Label.new(), UiDesignSystemType.BODY_FONT_SIZE, UiDesignSystemType.COLOR_LAVENDER_LIGHT,
		false, UiDesignSystemType.TEXT_OUTLINE_SIZE_SMALL)
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_constant_override("line_spacing", 10)
	column.add_child(body_label)

	start_button = Button.new()
	start_button.name = "LevelBriefingStartButton"
	start_button.text = "GOT IT"
	start_button.theme_type_variation = "GreenButton"
	start_button.custom_minimum_size = Vector2(0.0, UiDesignSystemType.BUTTON_HEIGHT)
	start_button.pressed.connect(func() -> void:
		ui_tap_requested.emit()
		dismiss())
	column.add_child(start_button)


func _start_entrance() -> void:
	_kill_tween()
	popup_shell.pivot_offset = popup_shell.size * 0.5
	popup_shell.scale = Vector2(ENTER_START_SCALE, ENTER_START_SCALE)
	popup_shell.modulate.a = 0.0
	dim_rect.modulate.a = 0.0
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(dim_rect, "modulate:a", 1.0, DIM_DURATION)
	_tween.parallel().tween_property(popup_shell, "modulate:a", 1.0, DIM_DURATION + ENTER_RISE)
	_tween.parallel().tween_property(popup_shell, "scale", Vector2(ENTER_OVERSHOOT, ENTER_OVERSHOOT), ENTER_RISE).set_delay(ENTER_DELAY)
	_tween.chain().set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(popup_shell, "scale", Vector2.ONE, ENTER_SETTLE)


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
