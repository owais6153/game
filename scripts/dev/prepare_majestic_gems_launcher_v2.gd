extends SceneTree

const SOURCE_PATH := "res://assets/logo/majestic_gems_logo_source_v3.png"
const RUNTIME_LOGO_PATH := "res://assets/runtime/ui/majestic_gems_logo_v3.png"
const LEGACY_PATH := "res://assets/runtime/ui/majestic_gems_app_icon_192_v3.png"
const FOREGROUND_PATH := "res://assets/runtime/ui/majestic_gems_adaptive_foreground_v3.png"
const BACKGROUND_PATH := "res://assets/runtime/ui/majestic_gems_adaptive_background_v3.png"
const SYSTEM_SPLASH_PATH := "res://assets/runtime/ui/majestic_gems_system_splash_1152_v4.png"
const LEGACY_SIZE := 192
const ADAPTIVE_SIZE := 432
const LEGACY_ART_EDGE := 134
const ADAPTIVE_ART_EDGE := 288
const SYSTEM_SPLASH_SIZE := 1152
const SYSTEM_SPLASH_ART_EDGE := 784
const BRAND_BACKGROUND := Color("1d0734")


func _init() -> void:
	var source := Image.load_from_file(SOURCE_PATH)
	if source == null or source.is_empty():
		push_error("The supplied logo must be a non-empty PNG: %s" % SOURCE_PATH)
		quit(1)
		return
	_make_black_background_transparent(source)
	var used := source.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		push_error("The supplied logo contains no visible artwork: %s" % SOURCE_PATH)
		quit(1)
		return
	var logo := source.get_region(used)
	if source.save_png(RUNTIME_LOGO_PATH) != OK:
		push_error("Unable to save runtime logo")
		quit(1)
		return
	if not _save_padded_logo(logo, LEGACY_SIZE, LEGACY_ART_EDGE, LEGACY_PATH):
		quit(1)
		return
	if not _save_padded_logo(logo, ADAPTIVE_SIZE, ADAPTIVE_ART_EDGE, FOREGROUND_PATH):
		quit(1)
		return
	if not _save_padded_logo(logo, SYSTEM_SPLASH_SIZE, SYSTEM_SPLASH_ART_EDGE, SYSTEM_SPLASH_PATH):
		quit(1)
		return
	var background := Image.create(ADAPTIVE_SIZE, ADAPTIVE_SIZE, false, Image.FORMAT_RGBA8)
	background.fill(BRAND_BACKGROUND)
	if background.save_png(BACKGROUND_PATH) != OK:
		push_error("Unable to save adaptive background")
		quit(1)
		return
	print("MAJESTIC_GEMS_LAUNCHER_V3: PASS source=%s source_size=%s alpha_bounds=%s" % [SOURCE_PATH, source.get_size(), used])
	quit(0)


## The supplied v3 logo has an opaque black studio backdrop. Only fully black
## pixels are removed; all non-black artwork and its anti-aliased edge pixels
## remain exactly as supplied. This makes the Home/fallback logo transparent
## without altering the preserved source asset.
func _make_black_background_transparent(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.r == 0.0 and pixel.g == 0.0 and pixel.b == 0.0:
				image.set_pixel(x, y, Color.TRANSPARENT)


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
