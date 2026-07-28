extends Node2D

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, Vector2(720, 1280)), Color("18283f"))
	draw_string(font, Vector2(95, 610), "Gem Merge Rebuild Baseline", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)

func _ready() -> void:
	queue_redraw()
