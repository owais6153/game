extends SceneTree

const TRANSPARENT_LOGO := "res://assets/logo/majestic_gems_home_logo_source_v6.png"
const BACKGROUND_LOGO := "res://assets/logo/majestic_gems_logo_with_background_source_v6.png"
const MASCOT := "res://assets/character/mascot_full_source_v2.png"
const RUNTIME_LOGO := "res://assets/runtime/ui/majestic_gems_logo_v5.png"
const RUNTIME_BACKGROUND_LOGO := "res://assets/runtime/ui/majestic_gems_logo_with_background_v6.png"
const SPLASH := "res://assets/runtime/ui/majestic_gems_gradient_logo_splash_v1.png"
const SYSTEM_ICON := "res://assets/runtime/ui/majestic_gems_system_splash_logo_v1.png"

func _init() -> void:
	var transparent := Image.load_from_file(TRANSPARENT_LOGO)
	var background := Image.load_from_file(BACKGROUND_LOGO)
	var mascot := Image.load_from_file(MASCOT)
	if transparent == null or background == null or mascot == null:
		push_error("Brand refresh source missing")
		quit(1)
		return
	# The two supplied logos are copied pixel-for-pixel into runtime; transparent
	# replaces transparent and illustrated-background replaces background.
	transparent.save_png(RUNTIME_LOGO)
	background.save_png(RUNTIME_BACKGROUND_LOGO)

	var splash := Image.create_empty(720, 1280, false, Image.FORMAT_RGBA8)
	for y in range(1280):
		for x in range(720):
			var uv := Vector2(float(x) / 720.0, float(y) / 1280.0)
			var centre := Vector2(0.5, 0.45)
			var d := (uv - centre).length()
			var glow := clampf(1.0 - d / 0.62, 0.0, 1.0)
			glow = glow * glow
			var top := Color("130529")
			var middle := Color("b20ba7")
			var colour := top.lerp(middle, glow * 0.92)
			colour = colour.lerp(Color("080015"), smoothstep(0.72, 1.0, uv.y) * 0.62)
			splash.set_pixel(x, y, colour)
	var logo_used := transparent.get_used_rect()
	var cut := transparent.get_region(logo_used)
	var scale := 430.0 / float(maxi(cut.get_width(), cut.get_height()))
	cut.resize(roundi(cut.get_width() * scale), roundi(cut.get_height() * scale), Image.INTERPOLATE_LANCZOS)
	splash.blend_rect(cut, Rect2i(Vector2i.ZERO, cut.get_size()), Vector2i((720 - cut.get_width()) / 2, 540 - cut.get_height() / 2))
	splash.save_png(SPLASH)

	var icon := Image.create_empty(1152, 1152, false, Image.FORMAT_RGBA8)
	icon.fill(Color.TRANSPARENT)
	var icon_logo := transparent.get_region(logo_used)
	var icon_scale := 650.0 / float(maxi(icon_logo.get_width(), icon_logo.get_height()))
	icon_logo.resize(roundi(icon_logo.get_width() * icon_scale), roundi(icon_logo.get_height() * icon_scale), Image.INTERPOLATE_LANCZOS)
	icon.blend_rect(icon_logo, Rect2i(Vector2i.ZERO, icon_logo.get_size()), Vector2i((1152 - icon_logo.get_width()) / 2, (1152 - icon_logo.get_height()) / 2))
	icon.save_png(SYSTEM_ICON)
	print("BRAND_REFRESH_V1: PASS")
	quit(0)
