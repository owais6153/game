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
	_draw_queue_preview(controller, GameConfig.NEXT_PREVIEW_RECT, int(snapshot.next_level))
	_draw_progression(controller, snapshot, font)
	_draw_active_target(controller, snapshot, font)
	_draw_restart_button(controller)
	_draw_settings_button(controller)

static func _draw_panel(controller: CanvasItem, rect: Rect2, fill: Color, border: Color) -> void:
	controller.draw_rect(rect, fill, true)
	controller.draw_rect(rect, border, false, 2.0)

static func _draw_score_block(controller: CanvasItem, snapshot: Dictionary, font: Font) -> void:
	var rect := GameConfig.SCORE_PANEL_RECT
	controller.draw_texture_rect_region(AssetCatalogType.HUD_BUTTON_SHEET, rect, AssetCatalogType.HUD_SCORE_PANEL_REGION)
	controller.draw_string(font, rect.position + Vector2(15.0, 106.0), str(int(snapshot.score)), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 30.0, 43, Color("5b351e"))

static func _draw_progression(controller: CanvasItem, snapshot: Dictionary, font: Font) -> void:
	var start := Vector2(GameConfig.PROGRESSION_START_X, GameConfig.PROGRESSION_Y)
	for tier in range(1, 6):
		var entry := AssetCatalogType.gem_entry(tier)
		var center := start + Vector2((tier - 1) * GameConfig.PROGRESSION_STEP_X, 0.0)
		controller.draw_circle(center, GameConfig.PROGRESSION_SLOT_RADIUS, Color("fff7e7"))
		controller.draw_arc(center, GameConfig.PROGRESSION_SLOT_RADIUS, 0.0, TAU, 28, Color("f4ae32"), 2.5)
		_draw_contained_texture(controller, entry.texture, center, GameConfig.PROGRESSION_PREVIEW_BOUNDS)
		if tier < 5:
			controller.draw_line(center + Vector2(24.0, 0.0), center + Vector2(32.0, 0.0), Color("ed9d2e"), 3.0)

static func _draw_queue_preview(controller: CanvasItem, rect: Rect2, level: int) -> void:
	controller.draw_texture_rect_region(AssetCatalogType.HUD_BUTTON_SHEET, rect, AssetCatalogType.HUD_NEXT_PANEL_REGION)
	var entry := AssetCatalogType.gem_entry(level)
	# Fit square, tall, wide, and irregular supplied gems inside NEXT without
	# stretching or circular masking.
	_draw_contained_texture(controller, entry.texture, rect.get_center() + Vector2(0.0, 19.0), Vector2(96.0, 82.0))

static func _draw_active_target(controller: CanvasItem, snapshot: Dictionary, font: Font) -> void:
	# One card reads only the current snapshot target: L8 is not shown before
	# the L7 collection flight has completed.
	controller.draw_texture_rect_region(AssetCatalogType.HUD_BUTTON_SHEET, GameConfig.TARGET_BODY_RECT, AssetCatalogType.HUD_GOAL_BODY_REGION)
	controller.draw_texture_rect_region(AssetCatalogType.HUD_BUTTON_SHEET, GameConfig.TARGET_HEADER_RECT, AssetCatalogType.HUD_GOAL_HEADER_REGION)
	controller.draw_string(font, GameConfig.TARGET_HEADER_RECT.position + Vector2(12.0, 32.0), "GOAL", HORIZONTAL_ALIGNMENT_CENTER, GameConfig.TARGET_HEADER_RECT.size.x - 24.0, 19, Color.WHITE)
	var entry := AssetCatalogType.gem_entry(int(snapshot.target_level))
	_draw_contained_texture(controller, entry.texture, GameConfig.TARGET_BODY_RECT.get_center() + Vector2(48.0, 3.0), GameConfig.TARGET_PREVIEW_BOUNDS)

static func _draw_restart_button(controller: CanvasItem) -> void:
	controller.draw_texture_rect_region(AssetCatalogType.HUD_REPLAY_ART, GameConfig.RESTART_BUTTON_RECT, AssetCatalogType.HUD_RESTART_BUTTON_REGION)

static func _draw_settings_button(controller: CanvasItem) -> void:
	controller.draw_texture_rect_region(AssetCatalogType.HUD_BUTTON_SHEET, GameConfig.SETTINGS_BUTTON_RECT, AssetCatalogType.HUD_SETTINGS_BUTTON_REGION)

static func _draw_contained_texture(controller: CanvasItem, texture: Texture2D, center: Vector2, bounds: Vector2) -> void:
	if texture == null:
		return
	var source_size := texture.get_size()
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return
	var scale := minf(bounds.x / source_size.x, bounds.y / source_size.y)
	var size := source_size * scale
	controller.draw_texture_rect(texture, Rect2(center - size * 0.5, size), false)
