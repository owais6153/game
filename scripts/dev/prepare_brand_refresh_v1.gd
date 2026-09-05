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
## Godot fits this image inside the window and fills the remainder with
## `boot_splash/bg_color`, so a band appears wherever the image edge is not that
## colour. The fix is not to remove the gradient - it is to guarantee the image
## has faded to exactly BOOT_SPLASH_BG along its whole border.
##
## The falloff is therefore elliptical and scaled to the NEAREST edge, not to the
## far corner. Reaching bg_color at the corners is not enough: the previous pass
## did that and still banded, because along the top edge centre - the shortest
## distance from the centre - the gradient was only about 57% resolved and was
## sitting at #3D1258 against a #1C0734 fill. `_assert_border_is_bg` proves the
## whole border matches before the file is written.
const BOOT_SPLASH_SIZE := Vector2i(1080, 2400)
const BOOT_SPLASH_LOGO_EDGE := 760
## Must stay identical to project.godot boot_splash/bg_color and to
## splash_screen/background_color, or the letterbox stops matching and the seam
## comes back.
##
## Deliberately a rich purple, not the near-black it was. Requiring the border to
## equal bg_color is what makes the letterbox invisible, but with bg_color set to
## #1C0734 that forced the gradient to fade to near-black at every edge and the
## splash read as a dim vignette. Raising bg_color into the brand purple keeps the
## guarantee and lets the whole screen stay saturated.
##
## The three stops sit close together on purpose. A wide spread was tried first
## and read as a spotlight - a bright violet blob in the upper middle falling away
## to a much darker frame, nothing like the even plum a splash like this wants.
## The lift from edge to centre is now about one shade, so the screen reads as one
## rich colour that happens to be lit, rather than as a lamp pointed at a wall.
## Sampled from the reference splash the artwork was approved against, rather
## than estimated by eye - three attempts at estimating produced a spotlight, a
## flat plate and a cold violet, none of them the warm magenta glow that was
## actually wanted. The reference peaks at #67086b around 57% height and falls
## to #1d0531 at the top and #0c011d at the bottom.
const BOOT_SPLASH_EDGE := Color("130529")
const BOOT_SPLASH_GLOW := Color("b20ba7")
const BOOT_SPLASH_FLOOR := Color("080015")
const GLOW_CENTRE := Vector2(0.5, 0.45)
const GLOW_RADIUS := 0.62
const GLOW_STRENGTH := 0.92
const FLOOR_START := 0.72
const FLOOR_STRENGTH := 0.62
## Width of the forced match to BOOT_SPLASH_BG, as a fraction of the canvas.
const BORDER_FADE := 0.035
const BOOT_SPLASH_BG := Color(0.078431, 0.011765, 0.164706, 1.0)
## Shapes the falloff. At 1.0 the light fades evenly from the middle and the
## screen reads as a spotlight; at 1.0 with stops this close it reads as flat.
## Squaring it holds the lit area broad across the middle and puts the whole
## fall to the edge colour in the outer third, which is the soft vertical band
## the reference has.
const BOOT_SPLASH_FALLOFF := 2.0
const BOOT_SPLASH_CENTRE_Y := 0.45
const BOOT_SPLASH_RADIUS := 1.15

## 4x4 ordered dither matrix. See the note where it is used.
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
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
	var splash := _boot_splash(mark)
	_assert_border_is_bg(splash)
	_save(splash, OUT_BOOT_SPLASH)

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
	var width := float(BOOT_SPLASH_SIZE.x)
	var height := float(BOOT_SPLASH_SIZE.y)
	for y in range(BOOT_SPLASH_SIZE.y):
		for x in range(BOOT_SPLASH_SIZE.x):
			# Distance in NORMALISED space, not pixels. Both axes run 0..1 whatever
			# the canvas is, so on a tall canvas the same normalised distance covers
			# more pixels vertically - which is what makes the glow a tall oval
			# rather than a circle, and is why it reads as a lit screen instead of a
			# spotlight.
			var uv := Vector2(float(x) / width, float(y) / height)
			var glow := clampf(1.0 - (uv - GLOW_CENTRE).length() / GLOW_RADIUS, 0.0, 1.0)
			glow = glow * glow
			var colour := BOOT_SPLASH_EDGE.lerp(BOOT_SPLASH_GLOW, glow * GLOW_STRENGTH)
			# An extra darkening toward the bottom, so the screen is grounded rather
			# than symmetrical.
			colour = colour.lerp(BOOT_SPLASH_FLOOR, smoothstep(FLOOR_START, 1.0, uv.y) * FLOOR_STRENGTH)
			# Forced to exactly BOOT_SPLASH_BG in the last few percent, because Godot
			# letterboxes this image with that colour and any difference is a band.
			# The values either side are close, so the fade itself is invisible.
			var to_edge := minf(minf(uv.x, 1.0 - uv.x), minf(uv.y, 1.0 - uv.y))
			colour = colour.lerp(BOOT_SPLASH_BG, 1.0 - smoothstep(0.0, BORDER_FADE, to_edge))
			# Dithered before it is quantised to 8 bits. A gradient this large moves
			# through very few distinct byte values over hundreds of pixels, so
			# without this it quantises into visible concentric rings - which is what
			# a "non-smooth gradient" is. A sub-step offset breaks the ring edges up
			# into noise the eye reads as continuous.
			var noise := (float(BAYER[(y % 4) * 4 + (x % 4)]) + 0.5) / 16.0 - 0.5
			var step := noise / 255.0
			out.set_pixel(x, y, Color(
				clampf(colour.r + step, 0.0, 1.0),
				clampf(colour.g + step, 0.0, 1.0),
				clampf(colour.b + step, 0.0, 1.0),
				1.0
			))
	var art := _fit(mark, BOOT_SPLASH_LOGO_EDGE)
	out.blend_rect(
		art,
		Rect2i(Vector2i.ZERO, art.get_size()),
		Vector2i((BOOT_SPLASH_SIZE.x - art.get_width()) / 2, (BOOT_SPLASH_SIZE.y - art.get_height()) / 2)
	)
	return out


## Refuses to write a splash whose border is not exactly the letterbox colour.
##
## This is the whole contract. Godot fills whatever the image does not cover
## with `boot_splash/bg_color`, so any border pixel that differs shows up as a
## band on some aspect ratio - and which aspect decides whether anyone notices,
## which is why it shipped twice.
func _assert_border_is_bg(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var worst := 0.0
	for x in range(width):
		for y in [0, height - 1]:
			worst = maxf(worst, _difference(image.get_pixel(x, y), BOOT_SPLASH_BG))
	for y in range(height):
		for x in [0, width - 1]:
			worst = maxf(worst, _difference(image.get_pixel(x, y), BOOT_SPLASH_BG))
	# One 8-bit step of rounding is expected; anything more is a visible seam.
	if worst > 1.5 / 255.0:
		push_error("prepare_brand_refresh: splash border differs from bg_color by %.4f - it will band" % worst)
		quit(1)
		return
	print("BOOT_SPLASH_BORDER: matches bg_color (worst channel delta %.5f)" % worst)


func _difference(a: Color, b: Color) -> float:
	return maxf(maxf(absf(a.r - b.r), absf(a.g - b.g)), absf(a.b - b.b))
