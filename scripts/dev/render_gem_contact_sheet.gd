extends SceneTree

const AssetCatalogType = preload("res://scripts/core/asset_catalog.gd")
const OUTPUT_PATH := "res://reports/contact-sheet-all-gems.png"
const SHEET_SIZE := Vector2i(1440, 1900)
const COLUMNS := 6
const CELL_SIZE := Vector2(210.0, 180.0)
const LEFT_MARGIN := 92.0
const TOP_MARGIN := 138.0

const GROUPS := [
	{"title": "COMMON  ·  CIRCLE  ·  SOLID", "ids": [1, 2, 3, 4, 5, 8, 11, 12, 13, 14, 15], "accent": Color("6bd5ff")},
	{"title": "COMMON  ·  CIRCLE  ·  GRADIENT", "ids": [29], "accent": Color("6bd5ff")},
	{"title": "COMMON  ·  ROUNDED SQUARE  ·  SOLID", "ids": [6, 7, 9, 10, 16, 17, 18, 19, 20, 26], "accent": Color("72e7b3")},
	{"title": "UNIQUE  ·  CIRCLE  ·  GRADIENT", "ids": [21, 22, 23, 27, 28, 33], "accent": Color("f6bdff")},
	{"title": "UNIQUE  ·  ROUNDED SQUARE  ·  GRADIENT", "ids": [24, 25, 30, 31, 32, 34], "accent": Color("ffc66d")},
]


func _init() -> void:
	call_deferred("_render")


func _render() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var viewport := SubViewport.new()
	viewport.size = SHEET_SIZE
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var sheet := GemContactSheet.new()
	sheet.size = Vector2(SHEET_SIZE)
	viewport.add_child(sheet)
	await process_frame
	await RenderingServer.frame_post_draw
	var error := viewport.get_texture().get_image().save_png(OUTPUT_PATH)
	viewport.queue_free()
	if error == OK:
		print("GEM_CONTACT_SHEET: PASS -> %s" % OUTPUT_PATH)
		quit(0)
		return
	push_error("Unable to save %s (error %d)" % [OUTPUT_PATH, error])
	quit(1)


class GemContactSheet extends Control:
	var font: Font = ThemeDB.fallback_font

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, Vector2(SHEET_SIZE)), Color("10061d"), true)
		draw_rect(Rect2(0.0, 0.0, SHEET_SIZE.x, 98.0), Color("30114f"), true)
		draw_string(font, Vector2(LEFT_MARGIN, 57.0), "MAJESTIC GEMS · ACTIVE GEM CONTACT SHEET", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("fff7ff"))
		draw_string(font, Vector2(LEFT_MARGIN, 88.0), "34 active runtime gems · grouped by rarity, shape, and color treatment · no player-facing gem names", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("dbc8f4"))
		var cursor_y := TOP_MARGIN
		for group in GROUPS:
			var ids: Array = group["ids"]
			var accent: Color = group["accent"]
			draw_string(font, Vector2(LEFT_MARGIN, cursor_y + 27.0), String(group["title"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, accent)
			draw_line(Vector2(LEFT_MARGIN, cursor_y + 41.0), Vector2(SHEET_SIZE.x - LEFT_MARGIN, cursor_y + 41.0), Color(accent, 0.36), 2.0)
			cursor_y += 55.0
			for index in range(ids.size()):
				var identity := int(ids[index])
				var column := index % COLUMNS
				var row := index / COLUMNS
				var cell_origin := Vector2(LEFT_MARGIN + float(column) * CELL_SIZE.x, cursor_y + float(row) * CELL_SIZE.y)
				_draw_gem(identity, cell_origin, accent)
			cursor_y += ceil(float(ids.size()) / float(COLUMNS)) * CELL_SIZE.y + 22.0

	func _draw_gem(identity: int, cell_origin: Vector2, accent: Color) -> void:
		var card := Rect2(cell_origin, Vector2(184.0, 158.0))
		draw_style_box(_card_style(accent), card)
		var texture := AssetCatalogType.GEM_TIER_TEXTURES.get(identity) as Texture2D
		if texture != null:
			var source_size := texture.get_size()
			var scale := minf(112.0 / source_size.x, 112.0 / source_size.y)
			var draw_size := source_size * scale
			var draw_position := card.get_center() - draw_size * 0.5 + Vector2(0.0, -10.0)
			draw_texture_rect(texture, Rect2(draw_position, draw_size), false)
		draw_string(font, Vector2(card.position.x + 14.0, card.end.y - 15.0), "GEM %02d" % identity, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("fff8ff"))

	func _card_style(accent: Color) -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("210b35")
		style.border_color = Color(accent, 0.72)
		style.set_border_width_all(2)
		style.set_corner_radius_all(16)
		return style
