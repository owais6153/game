extends SceneTree

## Slices the supplied mood sheet into the 16 runtime mascot frames.
##
## Run once, on demand, when the source art changes:
##   godot --headless --path . --script scripts/dev/slice_mascot_frames.gd
##
## The original sheet stays untouched under `assets/character/`; only trimmed
## derivatives are written to `assets/runtime/`, per the project's asset rule.
##
## Why this is not a plain grid crop
## ---------------------------------
## The coins are pitched 206.4px apart and are themselves ~206px wide, so
## neighbouring coins touch: a naive square crop carries a crescent of the next
## coin's gold rim into every frame. The measured geometry is
##
##   coin half-width   103 px      (alpha falls to ~0 at x-offset 104)
##   coin half-height  107 px      (alpha falls to ~0 at y-offset 108)
##   column pitch      206.4 px    (centres 112, 319, 525, 732, 938, 1144, 1351, 1557)
##   row centres       272 and 646
##
## so an elliptical mask at 103 x 107 keeps the whole character - the raised
## hands in the late happy frames sit inside it - and removes the neighbours
## completely.
##
## Frame registration matters more than the crop. The centres above are used as
## an evenly spaced grid rather than as per-frame bounding boxes, because a
## bounding box moves when the character raises its hands, and a crop that
## follows it would make the head jitter between frames. Every frame is written
## at the same size with the coin on the same centre, so playback reads as one
## character animating rather than as sixteen separate pictures.

const SOURCE := "res://assets/character/mascot_mood_sheet_source_v2.png"
const OUTPUT_DIR := "res://assets/runtime/character"

## Measured off the source. Changing the sheet means re-measuring these.
const COLUMN_CENTRES := [86.0, 211.0, 336.0, 461.0, 586.0, 711.0, 836.0, 961.0, 1086.0, 1211.0, 1336.0, 1461.0]
const ROW_CENTRES := [430.0, 617.0]
const ROW_NAMES := ["happy", "sad"]

const MASK_RADIUS_X := 68.0
const MASK_RADIUS_Y := 68.0
## Antialiasing band on the mask edge, so the cut does not add a hard staircase
## over art that is already smoothly antialiased.
const MASK_FEATHER := 1.5

## Square output, with a little clear margin so a frame can be scaled or given a
## glow at runtime without its own edge clipping.
const FRAME_SIZE := 160


func _init() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if source == null or source.is_empty():
		push_error("slice_mascot_frames: cannot load %s" % SOURCE)
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	print("MASCOT_SOURCE_ALPHA corner=%f between_rows=%f" % [source.get_pixel(0, 0).a, source.get_pixel(768, 525).a])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	var written := 0
	for row in range(ROW_CENTRES.size()):
		for column in range(COLUMN_CENTRES.size()):
			var frame := _cut(source, float(COLUMN_CENTRES[column]), float(ROW_CENTRES[row]))
			var path := "%s/mascot_%s_%d.png" % [OUTPUT_DIR, ROW_NAMES[row], column + 1]
			var error := frame.save_png(ProjectSettings.globalize_path(path))
			if error != OK:
				push_error("slice_mascot_frames: save failed for %s (%d)" % [path, error])
				quit(1)
				return
			written += 1
	print("MASCOT_SLICE: wrote %d frames to %s" % [written, OUTPUT_DIR])
	quit(0)


## One frame, centred on (`centre_x`, `centre_y`) and masked to the coin.
func _cut(source: Image, centre_x: float, centre_y: float) -> Image:
	var out := Image.create_empty(FRAME_SIZE, FRAME_SIZE, false, Image.FORMAT_RGBA8)
	var half := float(FRAME_SIZE) * 0.5
	for y in range(FRAME_SIZE):
		for x in range(FRAME_SIZE):
			var offset := Vector2(float(x) - half + 0.5, float(y) - half + 0.5)
			var coverage := _mask(offset)
			if coverage <= 0.0:
				continue
			var source_x := int(round(centre_x + offset.x))
			var source_y := int(round(centre_y + offset.y))
			if source_x < 0 or source_y < 0 or source_x >= source.get_width() or source_y >= source.get_height():
				continue
			var pixel := source.get_pixel(source_x, source_y)
			pixel.a *= coverage
			out.set_pixel(x, y, pixel)
	return out


## Elliptical coverage in 0..1. Distance is normalised against the two radii so
## one feather width applies evenly around an ellipse rather than being wider at
## the flatter ends.
func _mask(offset: Vector2) -> float:
	var normalised := Vector2(offset.x / MASK_RADIUS_X, offset.y / MASK_RADIUS_Y).length()
	if normalised <= 1.0:
		return 1.0
	var feather := MASK_FEATHER / minf(MASK_RADIUS_X, MASK_RADIUS_Y)
	return clampf(1.0 - (normalised - 1.0) / feather, 0.0, 1.0)
