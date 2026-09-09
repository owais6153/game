extends SceneTree

## Slices the supplied star sheet into trimmed runtime derivatives under
## `assets/runtime/ui/kit/`. The original in `assets/ui_kit_source/` is never
## loaded at runtime, matching the existing UI-kit contract.
##
## Source rects were measured by walking the sheet's alpha columns rather than
## eyeballed, and are asserted against the sheet size before use.
##
## Three of the five variants on the sheet are extracted. The half gold/silver
## star and the small star have nothing that uses them, and are deliberately
## left out rather than shipped dormant - the same rule the power sheet follows
## for the icons that have no corresponding power.
##
## Unlike the power sheets, this art is **not** hard-cut or eroded. Those two
## passes exist to strip a red fringe the power sheets carry; this source has no
## fringe, and the glow variant is deliberately semi-transparent for most of its
## area. Cutting at 0.5 would delete the halo, and eroding would chew the
## anti-aliased edge off every star. Only sub-threshold noise is cleared, at the
## same 0.01 the gem derivatives use.

const SHEET := "res://assets/ui_kit_source/sheet_stars.png"
const SHEET_SIZE := Vector2i(1672, 941)
const OUTPUT_DIR := "res://assets/runtime/ui/kit"

## Measured alpha bounds of each variant, left to right across the sheet.
const STAR_RECTS := {
	# Plain gold star: the earned state.
	"star_filled": Rect2i(42, 315, 316, 299),
	# The same star wrapped in a soft halo. Drawn behind an earned star as a
	# bloom while it lands, then faded out.
	"star_glow": Rect2i(411, 293, 331, 331),
	# Gold outline: the placeholder a star grows out of.
	"star_empty": Rect2i(1151, 325, 298, 286),
}

## 256 on the longest edge, matching the gem derivatives. The largest a star is
## ever drawn is 78 design pixels on the result popup, which is about 117 real
## pixels on a 1080-wide phone, so this has headroom without carrying weight.
const OUTPUT_EDGE := 256

## Everything below this is treated as noise and cleared outright, so the
## trimmed bounds are the artwork's real bounds.
const ALPHA_CLEAR := 0.01

var failures: Array[String] = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var sheet := Image.load_from_file(SHEET)
	if sheet == null or sheet.is_empty():
		_fail("Unable to load %s" % SHEET)
		return
	if sheet.get_size() != SHEET_SIZE:
		_fail("%s is %s but the measured rects assume %s" % [SHEET, sheet.get_size(), SHEET_SIZE])
		return
	if not sheet.detect_alpha():
		_fail("%s must retain transparency" % SHEET)
		return

	var manifest := {"version": 1, "source": SHEET, "alpha_clear": ALPHA_CLEAR, "entries": []}
	for name in STAR_RECTS.keys():
		var rect: Rect2i = STAR_RECTS[name]
		var image := _prepare(sheet, rect)
		if image == null:
			_fail("%s trimmed to nothing" % name)
			continue
		var path := "%s/%s.png" % [OUTPUT_DIR, name]
		if image.save_png(path) != OK:
			_fail("Unable to write %s" % path)
			continue
		manifest.entries.append({
			"name": name,
			"source_rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
			"output": path,
			"size": [image.get_width(), image.get_height()],
		})
		print("wrote %s (%dx%d)" % [path, image.get_width(), image.get_height()])

	if failures.is_empty():
		var file := FileAccess.open("%s/star_kit_manifest.json" % OUTPUT_DIR, FileAccess.WRITE)
		if file == null:
			_fail("Unable to write the star kit manifest")
		else:
			file.store_string(JSON.stringify(manifest, "\t") + "\n")

	if failures.is_empty():
		print("STAR_KIT_ART_PREPARATION: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("STAR_KIT_ART_PREPARATION: FAIL (%d)" % failures.size())
	quit(1)


## Crop, clear sub-threshold noise, trim to the remaining alpha, and scale so
## the longest edge is OUTPUT_EDGE. Aspect ratio is preserved; a star is not
## square and squaring it would stretch it.
func _prepare(sheet: Image, rect: Rect2i) -> Image:
	var image := sheet.get_region(rect)
	image.convert(Image.FORMAT_RGBA8)
	_clear_noise(image)
	var bounds := _alpha_rect(image)
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		return null
	image = image.get_region(bounds)
	var scale := float(OUTPUT_EDGE) / float(maxi(image.get_width(), image.get_height()))
	image.resize(
		maxi(1, int(round(image.get_width() * scale))),
		maxi(1, int(round(image.get_height() * scale))),
		Image.INTERPOLATE_LANCZOS
	)
	return image


func _clear_noise(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a < ALPHA_CLEAR:
				image.set_pixel(x, y, Color(color.r, color.g, color.b, 0.0))


func _alpha_rect(image: Image) -> Rect2i:
	var left := image.get_width()
	var top := image.get_height()
	var right := -1
	var bottom := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= ALPHA_CLEAR:
				continue
			left = mini(left, x)
			right = maxi(right, x)
			top = mini(top, y)
			bottom = maxi(bottom, y)
	if right < left or bottom < top:
		return Rect2i()
	return Rect2i(left, top, right - left + 1, bottom - top + 1)


func _fail(message: String) -> void:
	failures.append(message)
	push_error(message)
	print("STAR_KIT_ART_PREPARATION: FAIL (%d)" % failures.size())
	quit(1)
