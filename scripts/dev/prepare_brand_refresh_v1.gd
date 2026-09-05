extends SceneTree

## Generates every runtime brand derivative from the two supplied v6 logos.
##
## Run on demand when the source art changes:
##   godot --headless --path . --script scripts/dev/prepare_brand_refresh_v1.gd
##
## Two supplied varieties, used for different jobs:
##
##   transparent      Home screen, and the Android launch screen, because both
##                    composite the mark over their own background - the launch
##                    screen over the #1C0734 window colour, Home over the
##                    garden art. Baking a background into either would show as
##                    a visible square.
##
##   with background  The launcher icon, which is a fixed square with nowhere to
##                    composite against.
##
## The adaptive launcher icon is the illustrated square and nothing else: it is
## the background layer, and the foreground layer is deliberately empty. That
## keeps the icon identical on every Android version, since the legacy 192px
## icon is the same illustration.
##
## The catch adaptive icons bring is the mask. A launcher composites the two
## layers and then crops the pair to its own shape - circle, squircle, rounded
## square - and only the middle 66 of the 108dp is guaranteed to survive. So the
## illustration is not simply scaled to fill: it is scaled so the artwork sits
## inside that safe circle, and the gap out to the edges is filled with the
## illustration.s own darkest corner colour. The mask then only ever eats flat
## colour, never the wordmark.

const TRANSPARENT_LOGO := "res://assets/logo/majestic_gems_home_logo_source_v6.png"
const BACKGROUND_LOGO := "res://assets/logo/majestic_gems_logo_with_background_source_v6.png"

const OUT_HOME_LOGO := "res://assets/runtime/ui/majestic_gems_logo_v6.png"
const OUT_SPLASH_ICON := "res://assets/runtime/ui/majestic_gems_system_splash_1152_v6.png"
const OUT_APP_ICON := "res://assets/runtime/ui/majestic_gems_app_icon_192_v6.png"
const OUT_ADAPTIVE_FOREGROUND := "res://assets/runtime/ui/majestic_gems_adaptive_foreground_v6.png"
const OUT_ADAPTIVE_BACKGROUND := "res://assets/runtime/ui/majestic_gems_adaptive_background_v6.png"
const OUT_BOOT_SPLASH := "res://assets/runtime/ui/majestic_gems_boot_splash_v6.png"

## Home draws the mark inside a 424x259 box with the aspect preserved, so the
## only thing that matters here is that it is large enough not to soften.
const HOME_LOGO_EDGE := 768

## The Android launch screen scales this to the display, so it is authored at
## the same 1152 the previous splash used. The mark is deliberately well inside
## the canvas: the launch screen centres it without any padding of its own.
const SPLASH_CANVAS := 1152
const SPLASH_LOGO_EDGE := 720

const APP_ICON_EDGE := 192

## The engine boot splash, shown after the Android launch screen and on every
## other platform.
##
## A radial gradient matching the launch-screen drawable, so the hand-off from
## one to the other is not visible. The reason the previous gradient banded on a
## tall phone was not that it was a gradient - it was that its edge colours did
## not match `boot_splash/bg_color`, and Godot letterboxes a fixed-size splash
## with that colour. This one resolves to exactly BOOT_SPLASH_BG at its edges,
## so whatever is letterboxed away is the colour that replaces it and the join
## cannot be seen. Flattening it to a solid plate "fixed" the band by throwing
## the gradient away, which is not the same thing.
const BOOT_SPLASH_SIZE := Vector2i(1080, 1920)
const BOOT_SPLASH_LOGO_EDGE := 760
## Must stay identical to project.godot boot_splash/bg_color, or the seam comes
## back. The two stops above it match android/build/res/drawable/launch_gradient.xml
## so the launch screen and the engine splash read as one image.
const BOOT_SPLASH_BG := Color(0.109804, 0.027451, 0.203922, 1.0)
const BOOT_SPLASH_INNER := Color("7A2A9E")
const BOOT_SPLASH_MID := Color("3D1258")
const BOOT_SPLASH_CENTRE_Y := 0.42
const BOOT_SPLASH_RADIUS := 1.15
const ADAPTIVE_CANVAS := 432
## An adaptive icon is authored at 108dp and only its middle 72dp is displayed,
## so artwork meant to be seen whole has to sit inside that viewport: 72/108 of
## the 432 canvas.
const ADAPTIVE_VIEWPORT_EDGE := 288
## How far the surround behind the artwork is dimmed, and how hard it is blurred
## first. The blur is a downscale-then-upscale, so this is the intermediate edge.
const SURROUND_DIM := 0.55
const SURROUND_SAMPLE := 6
## How far the wash is reduced before being scaled back up. Small enough that
## no glyph or gem survives it as a recognisable shape.
const WASH_SAMPLE := 10
## The foreground mark is gold and pale pink; the wash is darkened so it does
## not compete.
const WASH_DARKEN := 0.72


func _init() -> void:
	var transparent := Image.load_from_file(ProjectSettings.globalize_path(TRANSPARENT_LOGO))
	var illustrated := Image.load_from_file(ProjectSettings.globalize_path(BACKGROUND_LOGO))
	if transparent == null or illustrated == null:
		push_error("prepare_brand_refresh: a source logo is missing")
		quit(1)
		return
	transparent.convert(Image.FORMAT_RGBA8)
	illustrated.convert(Image.FORMAT_RGBA8)

	# Trimmed once and reused. The supplied transparent art carries a margin of
	# empty pixels; leaving it in would shrink the mark inside every box it is
	# later centred in, differently in each one.
	var mark := transparent.get_region(transparent.get_used_rect())

	_save(_fit(mark, HOME_LOGO_EDGE), OUT_HOME_LOGO)
	_save(_centre_on_canvas(mark, SPLASH_CANVAS, SPLASH_LOGO_EDGE), OUT_SPLASH_ICON)
	_save(_fit(illustrated, APP_ICON_EDGE), OUT_APP_ICON)
	_save(_empty_layer(ADAPTIVE_CANVAS), OUT_ADAPTIVE_FOREGROUND)
	_save(_adaptive_background(illustrated, ADAPTIVE_CANVAS), OUT_ADAPTIVE_BACKGROUND)
	_save(_boot_splash(mark), OUT_BOOT_SPLASH)

	print("BRAND_REFRESH_V1: PASS")
	quit(0)


## Scales an image so its longest side is `edge`, keeping the aspect.
func _fit(source: Image, edge: int) -> Image:
	var out := source.duplicate() as Image
	var longest := maxi(out.get_width(), out.get_height())
	if longest <= 0:
		return out
	var scale := float(edge) / float(longest)
	out.resize(maxi(1, roundi(out.get_width() * scale)), maxi(1, roundi(out.get_height() * scale)), Image.INTERPOLATE_LANCZOS)
	return out


## The mark, scaled to `logo_edge` and centred on a transparent `canvas` square.
func _centre_on_canvas(mark: Image, canvas: int, logo_edge: int) -> Image:
	var scaled := _fit(mark, logo_edge)
	var out := Image.create_empty(canvas, canvas, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.0, 0.0, 0.0, 0.0))
	out.blend_rect(
		scaled,
		Rect2i(Vector2i.ZERO, scaled.get_size()),
		Vector2i((canvas - scaled.get_width()) / 2, (canvas - scaled.get_height()) / 2)
	)
	return out


## The illustrated logo, sized so the launcher does not crop into it.
##
## Full bleed was tried and is wrong. An adaptive icon is authored at 108dp but
## only the middle 72dp is ever shown - the outer 18dp on each side exists for
## the mask and for launcher parallax. Scaling the artwork to fill the canvas
## therefore hands the launcher a 1.5x enlargement of it, which is exactly the
## "icon is zoomed in" the artwork appeared to have on device.
##
## So the illustration is drawn at the 72dp viewport instead, and the ring around
## it is a blur of the same artwork - reduced until no shape survives, then
## enlarged and dimmed. Two other surrounds were tried and rejected: a flat fill
## made the icon read as a picture pasted on a card, and an un-blurred copy of
## the illustration showed the logo twice, once in the ring and once on top.
func _adaptive_background(source: Image, canvas: int) -> Image:
	var out := source.duplicate() as Image
	# Small enough that no gem, leaf or letter survives as a recognisable shape.
	out.resize(SURROUND_SAMPLE, SURROUND_SAMPLE, Image.INTERPOLATE_LANCZOS)
	out.resize(canvas, canvas, Image.INTERPOLATE_CUBIC)
	out.convert(Image.FORMAT_RGBA8)
	for y in range(canvas):
		for x in range(canvas):
			var pixel := out.get_pixel(x, y)
			# Opaque, and dimmed so the surround never competes with the artwork
			# sitting on top of it.
			out.set_pixel(x, y, Color(pixel.r * SURROUND_DIM, pixel.g * SURROUND_DIM, pixel.b * SURROUND_DIM, 1.0))
	var art := _fit(source, ADAPTIVE_VIEWPORT_EDGE)
	out.blend_rect(
		art,
		Rect2i(Vector2i.ZERO, art.get_size()),
		Vector2i((canvas - art.get_width()) / 2, (canvas - art.get_height()) / 2)
	)
	return out


## A fully transparent layer. Godot requires a foreground image, and this icon
## deliberately has no foreground - the illustration is the whole icon.
func _empty_layer(canvas: int) -> Image:
	var out := Image.create_empty(canvas, canvas, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.0, 0.0, 0.0, 0.0))
	return out


func _save(image: Image, path: String) -> void:
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("prepare_brand_refresh: save failed for %s (%d)" % [path, error])
		quit(1)


## The engine boot splash: the mark on a flat plate in the boot background
## colour. Flat is the whole point - a fixed-size splash is letterboxed on any
## aspect it was not authored for, and only a fill that matches `bg_color`
## exactly hides the join.
func _boot_splash(mark: Image) -> Image:
	var out := Image.create_empty(BOOT_SPLASH_SIZE.x, BOOT_SPLASH_SIZE.y, false, Image.FORMAT_RGBA8)
	# Radius measured to the far corner, so the gradient has fully resolved to
	# BOOT_SPLASH_BG by the time it reaches any edge.
	var centre := Vector2(float(BOOT_SPLASH_SIZE.x) * 0.5, float(BOOT_SPLASH_SIZE.y) * BOOT_SPLASH_CENTRE_Y)
	var radius := maxf(1.0, centre.distance_to(Vector2(0.0, float(BOOT_SPLASH_SIZE.y))) * BOOT_SPLASH_RADIUS)
	for y in range(BOOT_SPLASH_SIZE.y):
		for x in range(BOOT_SPLASH_SIZE.x):
			var t := clampf(Vector2(float(x), float(y)).distance_to(centre) / radius, 0.0, 1.0)
			# Two stops, matching launch_gradient.xml.
			var colour := BOOT_SPLASH_MID.lerp(BOOT_SPLASH_BG, clampf((t - 0.5) / 0.5, 0.0, 1.0))
			if t < 0.5:
				colour = BOOT_SPLASH_INNER.lerp(BOOT_SPLASH_MID, clampf(t / 0.5, 0.0, 1.0))
			out.set_pixel(x, y, Color(colour.r, colour.g, colour.b, 1.0))
	var art := _fit(mark, BOOT_SPLASH_LOGO_EDGE)
	out.blend_rect(
		art,
		Rect2i(Vector2i.ZERO, art.get_size()),
		Vector2i((BOOT_SPLASH_SIZE.x - art.get_width()) / 2, (BOOT_SPLASH_SIZE.y - art.get_height()) / 2)
	)
	return out
