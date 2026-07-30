class_name HudRenderer
extends RefCounted

const AssetCatalogType = preload("res://scripts/asset_catalog.gd")

## Presentation-only HUD. It consumes one controller snapshot and never owns
## queue, target, score, or outcome state.
static func draw(controller: CanvasItem, snapshot: Dictionary, font: Font) -> void:
	_draw_panel(controller, GameConfig.HUD_RECT, Color("211b2d"), Color("c6a65a"))
	_draw_score_block(controller, snapshot, font)
	_draw_queue_preview(controller, GameConfig.CURRENT_PREVIEW_RECT, int(snapshot.current_level), "NOW", font)
	_draw_queue_preview(controller, GameConfig.NEXT_PREVIEW_RECT, int(snapshot.next_level), "NEXT", font)
	_draw_target(controller, snapshot, font)
	_draw_restart(controller, font)
	_draw_feedback_toggles(controller, bool(snapshot.sound_enabled), bool(snapshot.vibration_enabled), font)

static func _draw_panel(controller: CanvasItem, rect: Rect2, fill: Color, border: Color) -> void:
	controller.draw_rect(rect, fill, true)
	controller.draw_rect(rect, border, false, 2.0)

static func _draw_score_block(controller: CanvasItem, snapshot: Dictionary, font: Font) -> void:
	controller.draw_string(font, Vector2(42.0, 44.0), "LEVEL %d" % int(snapshot.level_number), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("b9a77b"))
	controller.draw_string(font, Vector2(42.0, 67.0), "SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("b9a77b"))
	controller.draw_string(font, Vector2(42.0, 96.0), str(int(snapshot.score)), HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color("fff4d5"))
	controller.draw_string(font, Vector2(42.0, 119.0), "x%d CHAIN" % int(snapshot.chain_multiplier), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("d7e9df"))

static func _draw_queue_preview(controller: CanvasItem, rect: Rect2, level: int, label: String, font: Font) -> void:
	_draw_panel(controller, rect, Color("171927"), Color("725d86"))
	var entry := AssetCatalogType.gem_entry(level)
	controller.draw_texture_rect(entry.texture, Rect2(rect.position + Vector2(7.0, 8.0), Vector2(34.0, 34.0)), false)
	controller.draw_string(font, Vector2(rect.position.x + 46.0, rect.position.y + 18.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("b9a77b"))
	controller.draw_string(font, Vector2(rect.position.x + 46.0, rect.position.y + 39.0), String(entry.name), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 52.0, 13, Color("fff4d5"))

static func _draw_target(controller: CanvasItem, snapshot: Dictionary, font: Font) -> void:
	var rect := Rect2(438.0, 28.0, 132.0, 74.0)
	_draw_panel(controller, rect, Color("171927"), Color("d8b46d"))
	var entry := AssetCatalogType.gem_entry(int(snapshot.target_level))
	controller.draw_texture_rect(entry.texture, Rect2(rect.position + Vector2(8.0, 21.0), Vector2(34.0, 34.0)), false)
	controller.draw_string(font, rect.position + Vector2(48.0, 20.0), "TARGET %d/%d" % [int(snapshot.target_index) + 1, int(snapshot.target_total)], HORIZONTAL_ALIGNMENT_LEFT, 78.0, 10, Color("b9a77b"))
	controller.draw_string(font, rect.position + Vector2(48.0, 40.0), String(entry.name), HORIZONTAL_ALIGNMENT_LEFT, 80.0, 12, Color("fff4d5"))
	controller.draw_string(font, rect.position + Vector2(48.0, 61.0), "%d / %d" % [int(snapshot.target_progress), int(snapshot.target_quantity)], HORIZONTAL_ALIGNMENT_LEFT, 80.0, 14, Color("d7e9df"))

static func _draw_restart(controller: CanvasItem, font: Font) -> void:
	controller.draw_rect(GameConfig.RESTART_RECT, Color("5a3f68"), true)
	controller.draw_rect(GameConfig.RESTART_RECT, Color("d8b46d"), false, 2.0)
	controller.draw_string(font, GameConfig.RESTART_RECT.position + Vector2(16.0, 33.0), "Restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)

static func _draw_feedback_toggles(controller: CanvasItem, sound_enabled: bool, vibration_enabled: bool, font: Font) -> void:
	_draw_toggle(controller, GameConfig.SOUND_TOGGLE_RECT, "S", sound_enabled, font)
	_draw_toggle(controller, GameConfig.VIBRATION_TOGGLE_RECT, "V", vibration_enabled, font)

static func _draw_toggle(controller: CanvasItem, rect: Rect2, label: String, enabled: bool, font: Font) -> void:
	var fill := Color("285b4c") if enabled else Color("46364d")
	controller.draw_rect(rect, fill, true)
	controller.draw_rect(rect, Color("d8b46d"), false, 1.0)
	controller.draw_string(font, rect.position + Vector2(17.0, 20.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
