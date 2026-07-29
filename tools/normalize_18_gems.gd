extends SceneTree

## Creates non-destructive body-only runtime derivatives from the 18 user
## supplied alpha PNGs. Source files under assets/gems are never modified.
const SOURCE_DIR := "res://assets/gems"
const OUTPUT_DIR := "res://assets/runtime/gems18"
const MANIFEST_PATH := "res://assets/runtime/gems18/normalization_manifest.json"
const SOURCE_PREFIX := "ChatGPT Image Jul 29, 2026, 11_"
const ALPHA_THRESHOLD := 20
const PADDING := 2

func _init() -> void:
	var files: Array[String] = []
	var dir := DirAccess.open(SOURCE_DIR)
	if dir == null:
		push_error("18-gem source directory is missing")
		quit(1)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.begins_with(SOURCE_PREFIX) and file_name.ends_with(".png"):
			files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	files.sort()
	if files.size() != 18:
		push_error("Expected 18 selected PNGs; found %d" % files.size())
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var entries: Array[Dictionary] = []
	for index in files.size():
		var source_path := "%s/%s" % [SOURCE_DIR, files[index]]
		var image := Image.load_from_file(source_path)
		if image == null or image.is_empty():
			push_error("Could not load %s" % source_path)
			quit(1)
			return
		image.convert(Image.FORMAT_RGBA8)
		# This selected Moonstone source contains a fully opaque neutral backdrop.
		# Its actual circular stone is centered in the source. The body-only runtime
		# derivative removes that external backdrop/halo while retaining the gem's
		# internal facets and highlights; the source original remains untouched.
		if files[index] == "ChatGPT Image Jul 29, 2026, 11_04_21 PM (10).png":
			_mask_moonstone_backdrop(image)
		var bounds := _alpha_bounds(image)
		if bounds.size.x <= 0 or bounds.size.y <= 0:
			push_error("No visible alpha body in %s" % source_path)
			quit(1)
			return
		var crop := _padded(bounds, image.get_size())
		var runtime := image.get_region(crop)
		var runtime_path := "%s/tier_%02d.png" % [OUTPUT_DIR, index + 1]
		var save_error := runtime.save_png(runtime_path)
		if save_error != OK:
			push_error("Could not save %s" % runtime_path)
			quit(1)
			return
		entries.append({"tier": index + 1, "source": source_path, "runtime": runtime_path, "source_size": [image.get_width(), image.get_height()], "alpha_bounds": [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y], "runtime_size": [runtime.get_width(), runtime.get_height()], "processing": "RGBA8 alpha-body trim with 2px anti-alias padding; no internal facets/highlights altered; separate runtime shadow remains presentation-only."})
	var manifest := JSON.stringify({"version": 1, "alpha_threshold": ALPHA_THRESHOLD, "padding": PADDING, "entries": entries}, "\t")
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	manifest_file.store_string(manifest + "\n")
	print("GEM18_NORMALIZATION: PASS")
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

func _mask_moonstone_backdrop(image: Image) -> void:
	var center := Vector2(512.0, 505.0)
	var solid_radius := 334.0
	var feather := 12.0
	for y in image.get_height():
		for x in image.get_width():
			var distance := Vector2(float(x), float(y)).distance_to(center)
			if distance <= solid_radius:
				continue
			var pixel := image.get_pixel(x, y)
			var alpha_multiplier := clampf(1.0 - (distance - solid_radius) / feather, 0.0, 1.0)
			pixel.a *= alpha_multiplier
			image.set_pixel(x, y, pixel)
