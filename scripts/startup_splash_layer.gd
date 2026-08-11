class_name StartupSplashLayer
extends CanvasLayer

const AssetCatalogType = preload("res://scripts/asset_catalog.gd")

signal finished

const HOLD_DURATION := 1.05
const FADE_DURATION := 0.20

var root_control: Control
var logo: TextureRect
var _tween: Tween
var _finished := false


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func play() -> void:
	_build()
	_finished = false
	root_control.visible = true
	root_control.modulate = Color.WHITE
	logo.pivot_offset = logo.size * 0.5 if logo.size != Vector2.ZERO else logo.custom_minimum_size * 0.5
	logo.scale = Vector2.ONE * 0.96
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(logo, "scale", Vector2.ONE, HOLD_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_interval(HOLD_DURATION)
	_tween.tween_property(root_control, "modulate:a", 0.0, FADE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(_finish)


func skip_for_testing() -> void:
	_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if root_control != null:
		root_control.visible = false
	finished.emit()


func _build() -> void:
	if root_control != null:
		return
	root_control = Control.new()
	root_control.name = "StartupSplashRoot"
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.visible = false
	add_child(root_control)
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.name = "MajesticSplashBackground"
	background.color = Color(0.188235, 0.611765, 0.847059, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo = TextureRect.new()
	logo.name = "MajesticGemsSplashLogo"
	logo.texture = AssetCatalogType.BRAND_LOGO
	logo.custom_minimum_size = Vector2(560.0, 420.0)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(logo)
