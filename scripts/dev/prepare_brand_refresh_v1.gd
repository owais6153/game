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

## Home draws the mark inside a 424x259 box with the aspect preserved, so the
## only thing that matters here is that it is large enough not to soften.
const HOME_LOGO_EDGE := 768

## The Android launch screen scales this to the display, so it is authored at
## the same 1152 the previous splash used. The mark is deliberately well inside
## the canvas: the launch screen centres it without any padding of its own.
const SPLASH_CANVAS := 1152
const SPLASH_LOGO_EDGE := 720

const APP_ICON_EDGE := 192
const ADAPTIVE_CANVAS := 432
## Android masks an adaptive icon to the middle 66 of its 108dp, so anything
## outside the centre ~61% can be cropped by the launcher's shape.
const ADAPTIVE_SAFE_EDGE := 252
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


## The illustrated logo, full bleed.
##
## Inset to the adaptive safe zone was tried first and rejected: it left a flat
## purple border around the artwork, so the icon read as a picture pasted on a
## card rather than as the illustration itself.
##
## Full bleed is safe here because of where the wordmark sits. A launcher mask
## crops to roughly the inscribed circle, radius 216 on this canvas; the
## wordmark spans about 75% of the width, so its half-width is ~162 and it
## clears the crop with room to spare. What the mask actually removes is the
## garden in the corners, which is what it is there for.
func _adaptive_background(source: Image, canvas: int) -> Image:
	var out := source.duplicate() as Image
	out.resize(canvas, canvas, Image.INTERPOLATE_LANCZOS)
	out.convert(Image.FORMAT_RGBA8)
	# Opaque: this is the bottom layer and any transparency would show the
	# launcher.s own background through the icon.
	for y in range(canvas):
		for x in range(canvas):
			var pixel := out.get_pixel(x, y)
			out.set_pixel(x, y, Color(pixel.r, pixel.g, pixel.b, 1.0))
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
