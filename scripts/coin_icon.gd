class_name CoinIcon
extends Control

const CoinVisualsType = preload("res://scripts/coin_visuals.gd")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var radius := maxf(3.0, minf(size.x, size.y) * 0.38)
	CoinVisualsType.draw_coin(self, size * 0.5, radius)
