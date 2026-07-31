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

static func _draw_queue_preview(controller: CanvasItem, rect: Rect2, level: int, label: String, font: Font) -> void:
	controller.draw_texture_rect_region(AssetCatalogType.HUD_BUTTON_SHEET, rect, AssetCatalogType.HUD_NEXT_PANEL_REGION)
	var entry := AssetCatalogType.gem_entry(level)
	controller.draw_texture_rect(entry.texture, Rect2(rect.get_center() - Vector2(28.0, 4.0), Vector2(56.0, 56.0)), false)
