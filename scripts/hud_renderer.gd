class_name HudRenderer
extends RefCounted

const AssetCatalogType = preload("res://scripts/asset_catalog.gd")

## Presentation-only HUD. It consumes one controller snapshot and never owns
## queue, target, score, or outcome state.
static func draw(controller: CanvasItem, snapshot: Dictionary, font: Font) -> void:
	# Layout follows the approved gameplay reference: score on the left,
	# progression centered, and the next-piece card on the right. It deliberately
	# avoids the former dark developer-style strip.
	_draw_score_block(controller, snapshot, font)
	_draw_queue_preview(controller, GameConfig.NEXT_PREVIEW_RECT, int(snapshot.next_level), "NEXT", font)
	_draw_progression(controller, snapshot, font)
	_draw_target(controller, snapshot, font)
	_draw_restart(controller, font)
	_draw_feedback_toggles(controller, bool(snapshot.sound_enabled), bool(snapshot.vibration_enabled), font)

static func _draw_panel(controller: CanvasItem, rect: Rect2, fill: Color, border: Color) -> void:
	controller.draw_rect(rect, fill, true)
	controller.draw_rect(rect, border, false, 2.0)

static func _draw_score_block(controller: CanvasItem, snapshot: Dictionary, font: Font) -> void:
	var rect := GameConfig.SCORE_PANEL_RECT
	controller.draw_texture_rect_region(AssetCatalogType.HUD_BUTTON_SHEET, rect, AssetCatalogType.HUD_SCORE_PANEL_REGION)
	controller.draw_string(font, rect.position + Vector2(16.0, 61.0), str(int(snapshot.score)), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 32.0, 27, Color("5b351e"))

static func _draw_progression(controller: CanvasItem, snapshot: Dictionary, font: Font) -> void:
	var start := Vector2(264.0, 58.0)
	for tier in range(1, 6):
		var entry := AssetCatalogType.gem_entry(tier)
		var center := start + Vector2((tier - 1) * 48.0, 0.0)
		controller.draw_circle(center, 21.0, Color("fff7e7"))
		controller.draw_arc(center, 21.0, 0.0, TAU, 24, Color("f4ae32"), 2.0)
		controller.draw_texture_rect(entry.texture, Rect2(center - Vector2(15.0, 15.0), Vector2(30.0, 30.0)), false)
		if tier < 5:
			controller.draw_line(center + Vector2(22.0, 0.0), center + Vector2(26.0, 0.0), Color("ed9d2e"), 3.0)
	controller.draw_string(font, Vector2(264.0, 97.0), "LEVEL %d" % int(snapshot.level_number), HORIZONTAL_ALIGNMENT_CENTER, 192.0, 11, Color("8e5f39"))

static func _draw_queue_preview(controller: CanvasItem, rect: Rect2, level: int, label: String, font: Font) -> void:
	controller.draw_texture_rect_region(AssetCatalogType.HUD_BUTTON_SHEET, rect, AssetCatalogType.HUD_NEXT_PANEL_REGION)
	var entry := AssetCatalogType.gem_entry(level)
	controller.draw_texture_rect(entry.texture, Rect2(rect.get_center() - Vector2(28.0, 4.0), Vector2(56.0, 56.0)), false)

static func _draw_target(controller: CanvasItem, snapshot: Dictionary, font: Font) -> void:
	var rect := GameConfig.TARGET_PANEL_RECT
	controller.draw_texture_rect_region(AssetCatalogType.HUD_BUTTON_SHEET, rect, AssetCatalogType.HUD_WHITE_PANEL_REGION)
	var entry := AssetCatalogType.gem_entry(int(snapshot.target_level))
	controller.draw_texture_rect(entry.texture, Rect2(rect.position + Vector2(8.0, 21.0), Vector2(34.0, 34.0)), false)
	controller.draw_string(font, rect.position + Vector2(48.0, 20.0), "TARGET %d/%d" % [int(snapshot.target_index) + 1, int(snapshot.target_total)], HORIZONTAL_ALIGNMENT_LEFT, 78.0, 10, Color("e85d50"))
	controller.draw_string(font, rect.position + Vector2(48.0, 40.0), String(entry.name), HORIZONTAL_ALIGNMENT_LEFT, 80.0, 12, Color("5b351e"))
	controller.draw_string(font, rect.position + Vector2(48.0, 61.0), "%d / %d" % [int(snapshot.target_progress), int(snapshot.target_quantity)], HORIZONTAL_ALIGNMENT_LEFT, 80.0, 14, Color("168a9a"))

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
