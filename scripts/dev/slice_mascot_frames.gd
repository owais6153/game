extends SceneTree

## Slices the supplied mood sheet into the 24 runtime mascot frames.
##
## Run once, on demand, when the source art changes:
##   godot --headless --path . --script scripts/dev/slice_mascot_frames.gd
##
## The original sheet stays untouched under `assets/character/`; only trimmed
## derivatives are written to `assets/runtime/`, per the project's asset rule.
##
## Sheet layout
## ------------
## Four rows of six. Each mood is *two* rows read left to right, so a track is
## twelve frames long:
##
##   rows 0-1  idle -> happiest  ->  mascot_happy_1 .. mascot_happy_12
##   rows 2-3  idle -> saddest   ->  mascot_sad_1   .. mascot_sad_12
##
## Frame 1 of each track is the same neutral pose, which is what lets the view
## treat idle as the bottom end of whichever track is currently showing.
##
## Measured geometry
## -----------------
## Read off the sheet by scanning alpha outward from a coin centre in column 0,
## which carries no hands in any row and is therefore the bare ring:
##
##   coin radius     ~111 px    (alpha falls to ~0 at offset 112)
##   column pitch     236.8 px  (six centres, 129.5 through 1313)
##   row centres      154.0, 406.5, 663.5, 913.0
##
## Unlike the two earlier sheets these coins do not touch - the pitch is 236.8
## against a 222px coin - so the mask is only clearing the faint glow fringe
## rather than separating overlapping neighbours. It is kept because that fringe
## would otherwise read as a square halo once a frame is drawn over artwork.
##
## Frame registration matters more than the crop. The centres above are used as
## an evenly spaced grid rather than as per-frame bounding boxes, because a
## bounding box moves when the character raises its hands, and a crop that
## followed it would make the head jitter between frames. Every frame is written
## at the same size with the coin on the same centre, so playback reads as one
## character animating rather than as twenty-four separate pictures.

const SOURCE := "res://assets/character/mascot_mood_sheet_source_v3.png"
const OUTPUT_DIR := "res://assets/runtime/character"

const COLUMNS := 6
const COLUMN_FIRST_CENTRE := 129.5
const COLUMN_PITCH := 236.8
## Two rows per mood, in playback order.
const TRACKS := {
	"happy": [154.0, 406.5],
	"sad": [663.5, 913.0],
}

const MASK_RADIUS_X := 112.0
const MASK_RADIUS_Y := 112.0
## Antialiasing band on the mask edge, so the cut does not add a hard staircase
## over art that is already smoothly antialiased.
const MASK_FEATHER := 1.5

## Square output, with a little clear margin so a frame can be scaled or given a
## glow at runtime without its own edge clipping. The coin fills ~0.92 of the
## frame, matching the proportion the earlier sheets produced - change it and
## the mascot silently resizes in every slot that draws it.
const FRAME_SIZE := 240


func _init() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if source == null or source.is_empty():
		push_error("slice_mascot_frames: cannot load %s" % SOURCE)
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	var written := 0
	for mood in TRACKS:
		var frame_number := 1
		for centre_y in TRACKS[mood]:
			for column in range(COLUMNS):
				var centre_x := COLUMN_FIRST_CENTRE + COLUMN_PITCH * float(column)
				var frame := _cut(source, centre_x, float(centre_y))
				var path := "%s/mascot_%s_%d.png" % [OUTPUT_DIR, mood, frame_number]
				var error := frame.save_png(ProjectSettings.globalize_path(path))
				if error != OK:
					push_error("slice_mascot_frames: save failed for %s (%d)" % [path, error])
					quit(1)
					return
				frame_number += 1
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
