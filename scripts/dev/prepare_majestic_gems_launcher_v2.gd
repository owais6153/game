extends SceneTree

const SOURCE_PATH := "res://assets/logo/majestic_gems_logo_source_v2.png"
const LEGACY_PATH := "res://assets/runtime/ui/majestic_gems_app_icon_192_v2.png"
const FOREGROUND_PATH := "res://assets/runtime/ui/majestic_gems_adaptive_foreground_v2.png"
const BACKGROUND_PATH := "res://assets/runtime/ui/majestic_gems_adaptive_background_v2.png"
const LEGACY_SIZE := 192
const ADAPTIVE_SIZE := 432
const LEGACY_ART_EDGE := 134
const ADAPTIVE_ART_EDGE := 288
const BRAND_BACKGROUND := Color("1d0734")


func _init() -> void:
	var source := Image.load_from_file(SOURCE_PATH)
	if source == null or source.is_empty() or not source.detect_alpha():
		push_error("The supplied logo must be a non-empty transparent PNG: %s" % SOURCE_PATH)
		quit(1)
		return
	var used := source.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		push_error("The supplied logo contains no visible artwork: %s" % SOURCE_PATH)
		quit(1)
		return
	var logo := source.get_region(used)
	if not _save_padded_logo(logo, LEGACY_SIZE, LEGACY_ART_EDGE, LEGACY_PATH):
		quit(1)
		return
	if not _save_padded_logo(logo, ADAPTIVE_SIZE, ADAPTIVE_ART_EDGE, FOREGROUND_PATH):
		quit(1)
		return
	var background := Image.create(ADAPTIVE_SIZE, ADAPTIVE_SIZE, false, Image.FORMAT_RGBA8)
	background.fill(BRAND_BACKGROUND)
	if background.save_png(BACKGROUND_PATH) != OK:
		push_error("Unable to save adaptive background")
		quit(1)
		return
	print("MAJESTIC_GEMS_LAUNCHER_V2: PASS source=%s source_size=%s alpha_bounds=%s" % [SOURCE_PATH, source.get_size(), used])
	quit(0)


func _save_padded_logo(logo: Image, canvas_size: int, art_edge: int, destination: String) -> bool:
	var scaled := logo.duplicate()
	var scale := float(art_edge) / float(maxi(scaled.get_width(), scaled.get_height()))
	var size := Vector2i(maxi(1, roundi(scaled.get_width() * scale)), maxi(1, roundi(scaled.get_height() * scale)))
	scaled.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	var canvas := Image.create(canvas_size, canvas_size, false, Image.FORMAT_RGBA8)
	canvas.fill(Color.TRANSPARENT)
	canvas.blit_rect(scaled, Rect2i(Vector2i.ZERO, size), Vector2i((canvas_size - size.x) / 2, (canvas_size - size.y) / 2))
	if canvas.save_png(destination) != OK:
		push_error("Unable to save %s" % destination)
		return false
	return true
