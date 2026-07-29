class_name ResultOverlayLayer
extends Node2D

## Dedicated UI layer. It dims only with its own backdrop draw and never
## changes gameplay-root or gem Sprite2D modulation.
var visible_result := false
var result_won := false
var result_score := 0

func present(won: bool, score: int) -> void:
	visible_result = true
	result_won = won
	result_score = score
	queue_redraw()

func dismiss() -> void:
	visible_result = false
	queue_redraw()

func _draw() -> void:
	if not visible_result:
		return
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, GameConfig.VIEWPORT_SIZE), Color(0.02, 0.02, 0.05, GameConfig.RESULT_BACKDROP_OPACITY), true)
	draw_rect(GameConfig.OVERLAY_RECT, Color("1b1427", 0.97), true)
	draw_rect(GameConfig.OVERLAY_RECT, Color("f1cd78"), false, 3.0)
	var title := "You created a Diamond!" if result_won else "Table overflowed"
	var button := "Replay" if result_won else "Retry"
	draw_string(font, Vector2(132.0, 548.0), title, HORIZONTAL_ALIGNMENT_CENTER, 456.0, 33, Color.WHITE)
	draw_string(font, Vector2(132.0, 612.0), "Score: %d" % result_score, HORIZONTAL_ALIGNMENT_CENTER, 456.0, 26, Color("fff0bb"))
	draw_rect(GameConfig.OVERLAY_BUTTON_RECT, Color("5a3f68"), true)
	draw_rect(GameConfig.OVERLAY_BUTTON_RECT, Color("d8b46d"), false, 2.0)
	draw_string(font, Vector2(220.0, 811.0), button, HORIZONTAL_ALIGNMENT_CENTER, 280.0, 24, Color.WHITE)
