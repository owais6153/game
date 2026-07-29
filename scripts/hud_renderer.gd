class_name HudRenderer
extends RefCounted

const GemVisualsType = preload("res://scripts/gem_visuals.gd")

## Presentation-only HUD renderer. It receives a snapshot from GameController and
## must never mutate simulation, queue, lifecycle, score, or outcome state.
static func draw(controller: CanvasItem, snapshot: Dictionary, font: Font) -> void:
	_draw_panel(controller, GameConfig.HUD_RECT, Color("211b2d"), Color("c6a65a"))
	_draw_score_block(controller, snapshot, font)
	_draw_queue_preview(controller, GameConfig.CURRENT_PREVIEW_RECT, int(snapshot.current_level), "NOW", font)
	_draw_queue_preview(controller, GameConfig.NEXT_PREVIEW_RECT, int(snapshot.next_level), "NEXT", font)
	_draw_progression(controller, int(snapshot.target_level), int(snapshot.highest_level), font)
	_draw_restart(controller, font)

static func _draw_panel(controller: CanvasItem, rect: Rect2, fill: Color, border: Color) -> void:
	controller.draw_rect(rect, fill, true)
	controller.draw_rect(rect, border, false, 2.0)

static func _draw_score_block(controller: CanvasItem, snapshot: Dictionary, font: Font) -> void:
	controller.draw_string(font, Vector2(42.0, 49.0), "SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("b9a77b"))
	controller.draw_string(font, Vector2(42.0, 76.0), str(int(snapshot.score)), HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color("fff4d5"))
	controller.draw_string(font, Vector2(42.0, 104.0), "x%d  CHAIN   •   %d SHOTS" % [int(snapshot.chain_multiplier), int(snapshot.shot_count)], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("d7e9df"))

static func _draw_queue_preview(controller: CanvasItem, rect: Rect2, level: int, label: String, font: Font) -> void:
	_draw_panel(controller, rect, Color("171927"), Color("725d86"))
	GemVisualsType.draw_gem(controller, level, rect.position + Vector2(24.0, 28.0), 17.0, 1.0, 0.78)
	controller.draw_string(font, Vector2(rect.position.x + 46.0, rect.position.y + 18.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("b9a77b"))
	controller.draw_string(font, Vector2(rect.position.x + 46.0, rect.position.y + 39.0), GameConfig.gem_name(level), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 52.0, 13, Color("fff4d5"))

static func _draw_progression(controller: CanvasItem, target_level: int, highest_level: int, font: Font) -> void:
	for level in range(1, 6):
		var center := Vector2(GameConfig.PROGRESSION_START_X + (level - 1) * GameConfig.PROGRESSION_STEP_X, GameConfig.PROGRESSION_Y)
		var is_target := level == target_level
		var is_reached := level <= highest_level
		var ring_color := Color("f6d77e") if is_target else Color("685c72")
		var ring_width := 2.5 if is_target else 1.0
		controller.draw_circle(center, 18.0, Color("332b42"), true)
		controller.draw_arc(center, 18.0, 0.0, TAU, 18, ring_color, ring_width, true)
		GemVisualsType.draw_gem(controller, level, center, 13.0, 1.0 if is_reached else 0.58, 0.64)
		if level < 5:
			var next_center := Vector2(GameConfig.PROGRESSION_START_X + level * GameConfig.PROGRESSION_STEP_X, GameConfig.PROGRESSION_Y)
			controller.draw_line(center + Vector2(20.0, 0.0), next_center - Vector2(20.0, 0.0), Color("846f4b"), 1.5)
	controller.draw_string(font, Vector2(GameConfig.PROGRESSION_START_X, GameConfig.PROGRESSION_Y + 34.0), "MAKE DIAMOND", HORIZONTAL_ALIGNMENT_LEFT, 152.0, 10, Color("d7e9df"))

static func _draw_restart(controller: CanvasItem, font: Font) -> void:
	controller.draw_rect(GameConfig.RESTART_RECT, Color("5a3f68"), true)
	controller.draw_rect(GameConfig.RESTART_RECT, Color("d8b46d"), false, 2.0)
	controller.draw_string(font, GameConfig.RESTART_RECT.position + Vector2(16.0, 33.0), "Restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
