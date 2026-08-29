extends SceneTree

## Slices the supplied power sheets into trimmed runtime derivatives under
## `assets/runtime/ui/kit/`. Originals in `assets/ui_kit_source/` are never
## loaded at runtime, matching the existing UI-kit contract.
##
## Source rects were measured by scripts/dev/analyze_power_sheets.gd rather than
## eyeballed, and are asserted against the sheet size before use.
##
## Two source defects are corrected here:
##
## 1. Every sheet carries a red/magenta fringe along its alpha edges. A hard
##    alpha cut plus a one-pixel erosion removes it; blitting the source pixels
##    directly would ring every icon in red against the purple HUD.
## 2. Only bomb, hammer, and switch have pre-made tiles, and magnet has none.
##    Rather than mix a composited magnet with three baked tiles, all four are
##    composited onto the same empty frame so icon scale and placement are
##    identical across the row.

const BUTTONS_SHEET := "res://assets/ui_kit_source/sheet_power_buttons.png"
const ICONS_SHEET := "res://assets/ui_kit_source/sheet_power_icons.png"
const OUTPUT_DIR := "res://assets/runtime/ui/kit"

const BUTTONS_SHEET_SIZE := Vector2i(1448, 1086)
const ICONS_SHEET_SIZE := Vector2i(1536, 1024)

## The unadorned tile: gold frame, purple field, crest, and the bottom slot the
## count badge sits in.
const TILE_RECT := Rect2i(761, 455, 405, 407)
const TILE_OUTPUT_EDGE := 224

## Measured icon components, keyed by the power they represent. The rocket,
## gem ball, freeze, and target icons on the same sheet have no corresponding
## power and are deliberately not extracted.
const ICON_RECTS := {
	"bomb": Rect2i(75, 73, 308, 385),
	"hammer": Rect2i(819, 113, 281, 359),
	"magnet": Rect2i(54, 532, 354, 350),
	"switch": Rect2i(464, 574, 280, 293),
}
const ICON_OUTPUT_EDGE := 128

const ALPHA_CUT := 0.5
const ALPHA_CLEAR := 0.01

var failures: Array[String] = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest := {"version": 1, "alpha_cut": ALPHA_CUT, "entries": []}

	var buttons := _load(BUTTONS_SHEET, BUTTONS_SHEET_SIZE)
	if buttons != null:
		var tile := _prepare(buttons, TILE_RECT, TILE_OUTPUT_EDGE)
		_save(tile, "%s/power_tile.png" % OUTPUT_DIR, BUTTONS_SHEET, TILE_RECT, manifest.entries)

	var icons := _load(ICONS_SHEET, ICONS_SHEET_SIZE)
	if icons != null:
		for power in ICON_RECTS.keys():
			var rect: Rect2i = ICON_RECTS[power]
			var icon := _prepare(icons, rect, ICON_OUTPUT_EDGE)
			_save(icon, "%s/power_icon_%s.png" % [OUTPUT_DIR, power], ICONS_SHEET, rect, manifest.entries)

	if failures.is_empty():
		var file := FileAccess.open("%s/power_kit_manifest.json" % OUTPUT_DIR, FileAccess.WRITE)
		if file == null:
			failures.append("Unable to write the power kit manifest")
		else:
			file.store_string(JSON.stringify(manifest, "\t") + "\n")

	if failures.is_empty():
		print("POWER_KIT_ART_PREPARATION: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("POWER_KIT_ART_PREPARATION: FAIL (%d)" % failures.size())
	quit(1)


func _load(path: String, expected_size: Vector2i) -> Image:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		failures.append("Unable to load %s" % path)
		return null
	if image.get_size() != expected_size:
		# The measured rects are only valid for the sheet they were taken from.
		failures.append("%s is %s but the measured rects assume %s" % [path, image.get_size(), expected_size])
		return null
	if not image.detect_alpha():
		failures.append("%s must retain transparency" % path)
		return null
	return image


## Crop, de-fringe, trim to the remaining alpha, and scale to a square of
## `output_edge` on its longest side.
func _prepare(sheet: Image, rect: Rect2i, output_edge: int) -> Image:
	var image := sheet.get_region(rect)
	image.convert(Image.FORMAT_RGBA8)
	_hard_cut_alpha(image)
	_erode_alpha_edge(image)
	var bounds := _alpha_rect(image)
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		return null
	image = image.get_region(bounds)
	var scale := float(output_edge) / float(maxi(image.get_width(), image.get_height()))
	image.resize(
		maxi(1, int(round(image.get_width() * scale))),
		maxi(1, int(round(image.get_height() * scale))),
		Image.INTERPOLATE_LANCZOS
	)
	_hard_cut_alpha(image)
	return image


## The fringe is semi-transparent, so cutting everything below ALPHA_CUT to
## fully clear removes most of it and leaves the artwork itself untouched.
func _hard_cut_alpha(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a < ALPHA_CUT:
				image.set_pixel(x, y, Color(color.r, color.g, color.b, 0.0))


## One pass of erosion: any opaque pixel touching a cleared pixel is itself
## cleared. This removes the last opaque ring of red the hard cut leaves behind.
func _erode_alpha_edge(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var doomed: Array[Vector2i] = []
	var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for y in range(height):
		for x in range(width):
			if image.get_pixel(x, y).a <= ALPHA_CLEAR:
				continue
			for offset in offsets:
				var next := Vector2i(x, y) + offset
				if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
					continue
				if image.get_pixel(next.x, next.y).a <= ALPHA_CLEAR:
					doomed.append(Vector2i(x, y))
					break
	for point in doomed:
		var color := image.get_pixel(point.x, point.y)
		image.set_pixel(point.x, point.y, Color(color.r, color.g, color.b, 0.0))


func _alpha_rect(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= ALPHA_CLEAR:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _save(image: Image, path: String, source: String, rect: Rect2i, records: Array) -> void:
	if image == null:
		failures.append("Nothing visible remained after de-fringing %s" % path)
		return
	var error := image.save_png(path)
	if error != OK:
		failures.append("Unable to save %s (error %d)" % [path, error])
		return
	records.append({
		"source": source,
		"source_rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
		"runtime": path,
		"runtime_size": [image.get_width(), image.get_height()],
		"runtime_sha256": FileAccess.get_sha256(path),
	})
