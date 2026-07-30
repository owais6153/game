extends SceneTree

## Offline asset-preparation utility. It runs alpha analysis once and creates
## non-destructive runtime derivatives; gameplay never reads pixels or bounds.
const SOURCE_DIRECTORY := "res://assets/runtime/gems18"
const OUTPUT_DIRECTORY := "res://assets/runtime/gems18/calibrated"
const MANIFEST_PATH := OUTPUT_DIRECTORY + "/calibration_manifest.json"
const ALPHA_THRESHOLD := 128
const PADDING := 1

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	var entries: Array[Dictionary] = []
	for level in range(1, 19):
		var source_path := "%s/tier_%02d.png" % [SOURCE_DIRECTORY, level]
		var image := Image.load_from_file(ProjectSettings.globalize_path(source_path))
		if image == null or image.is_empty():
			push_error("Missing runtime gem: %s" % source_path)
			quit(1)
			return
		var body_bounds := _alpha_bounds(image)
		if body_bounds.size.x <= 0 or body_bounds.size.y <= 0:
			push_error("No solid alpha body in %s" % source_path)
			quit(1)
			return
		var crop := _padded(body_bounds, image.get_size())
		var calibrated := image.get_region(crop)
		var output_path := "%s/tier_%02d.png" % [OUTPUT_DIRECTORY, level]
		if calibrated.save_png(ProjectSettings.globalize_path(output_path)) != OK:
			push_error("Could not save calibrated runtime gem: %s" % output_path)
			quit(1)
			return
		var texture_size := calibrated.get_size()
		var body_in_output := body_bounds.position - crop.position
		var body_max := maxf(body_bounds.size.x, body_bounds.size.y)
		var texture_max := maxf(texture_size.x, texture_size.y)
		entries.append({
			"tier": level,
			"runtime_texture": output_path,
			"visible_body_bounds": [body_in_output.x, body_in_output.y, body_bounds.size.x, body_bounds.size.y],
			"texture_size": [texture_size.x, texture_size.y],
			"display_scale": snappedf(texture_max / body_max, 0.001),
			"processing": "solid alpha crop at threshold %d with %dpx antialias padding; source PNG unchanged; no shadow or glow enters the physical body" % [ALPHA_THRESHOLD, PADDING],
		})
	var file := FileAccess.open(ProjectSettings.globalize_path(MANIFEST_PATH), FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "alpha_threshold": ALPHA_THRESHOLD, "padding": PADDING, "entries": entries}, "\t") + "\n")
	print("GEM18_CALIBRATION_PREP: PASS")
	quit(0)

func _alpha_bounds(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a8 >= ALPHA_THRESHOLD:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1) if max_x >= min_x else Rect2i()

func _padded(bounds: Rect2i, image_size: Vector2i) -> Rect2i:
	var left := maxi(0, bounds.position.x - PADDING)
	var top := maxi(0, bounds.position.y - PADDING)
	var right := mini(image_size.x, bounds.end.x + PADDING)
	var bottom := mini(image_size.y, bounds.end.y + PADDING)
	return Rect2i(left, top, right - left, bottom - top)
