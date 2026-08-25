extends SceneTree

const HOME_SOURCE_PATH := "res://assets/logo/majestic_gems_home_logo_source_v4.png"
const ICON_SOURCE_PATH := "res://assets/logo/majestic_gems_logo_presentation_reference_v3.png"
const RUNTIME_LOGO_PATH := "res://assets/runtime/ui/majestic_gems_logo_v4.png"
const LEGACY_PATH := "res://assets/runtime/ui/majestic_gems_app_icon_192_v4.png"
const FOREGROUND_PATH := "res://assets/runtime/ui/majestic_gems_adaptive_foreground_v4.png"
const BACKGROUND_PATH := "res://assets/runtime/ui/majestic_gems_adaptive_background_v4.png"
const SYSTEM_SPLASH_PATH := "res://assets/runtime/ui/majestic_gems_system_splash_1152_v5.png"
const LEGACY_SIZE := 192
const ADAPTIVE_SIZE := 432
const LEGACY_ART_EDGE := 134
const ADAPTIVE_ART_EDGE := 288
const SYSTEM_SPLASH_SIZE := 1152
const SYSTEM_SPLASH_ART_EDGE := 784
const BRAND_BACKGROUND := Color("1d0734")


func _init() -> void:
	var home_source := Image.load_from_file(HOME_SOURCE_PATH)
	var icon_source := Image.load_from_file(ICON_SOURCE_PATH)
	if home_source == null or home_source.is_empty() or icon_source == null or icon_source.is_empty():
		push_error("The supplied Home logo and opaque icon artwork must be non-empty PNGs")
		quit(1)
		return
	var used := home_source.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		push_error("The supplied Home logo contains no visible artwork: %s" % HOME_SOURCE_PATH)
		quit(1)
		return
	var home_logo := home_source.get_region(used)
	if home_logo.save_png(RUNTIME_LOGO_PATH) != OK:
		push_error("Unable to save runtime logo")
		quit(1)
		return
	# Launcher/adaptive/splash stay opaque and use the supplied illustrated
	# presentation artwork. The transparent Home lockup is never used here.
	if not _save_padded_logo(icon_source, LEGACY_SIZE, LEGACY_ART_EDGE, LEGACY_PATH, true):
		quit(1)
		return
	if not _save_padded_logo(icon_source, ADAPTIVE_SIZE, ADAPTIVE_ART_EDGE, FOREGROUND_PATH, true):
		quit(1)
		return
	if not _save_padded_logo(icon_source, SYSTEM_SPLASH_SIZE, SYSTEM_SPLASH_ART_EDGE, SYSTEM_SPLASH_PATH, true):
		quit(1)
		return
	var background := Image.create(ADAPTIVE_SIZE, ADAPTIVE_SIZE, false, Image.FORMAT_RGBA8)
	background.fill(BRAND_BACKGROUND)
	if background.save_png(BACKGROUND_PATH) != OK:
		push_error("Unable to save adaptive background")
		quit(1)
		return
	print("MAJESTIC_GEMS_LAUNCHER_V4: PASS home_source=%s icon_source=%s alpha_bounds=%s" % [HOME_SOURCE_PATH, ICON_SOURCE_PATH, used])
	quit(0)


func _save_padded_logo(logo: Image, canvas_size: int, art_edge: int, destination: String, opaque_canvas: bool = false) -> bool:
	var scaled := logo.duplicate()
	scaled.convert(Image.FORMAT_RGBA8)
	var scale := float(art_edge) / float(maxi(scaled.get_width(), scaled.get_height()))
	var size := Vector2i(maxi(1, roundi(scaled.get_width() * scale)), maxi(1, roundi(scaled.get_height() * scale)))
	scaled.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	var canvas := Image.create(canvas_size, canvas_size, false, Image.FORMAT_RGBA8)
	canvas.fill(BRAND_BACKGROUND if opaque_canvas else Color.TRANSPARENT)
	canvas.blit_rect(scaled, Rect2i(Vector2i.ZERO, size), Vector2i((canvas_size - size.x) / 2, (canvas_size - size.y) / 2))
	if canvas.save_png(destination) != OK:
		push_error("Unable to save %s" % destination)
		return false
	return true
