extends SceneTree

const BACKGROUND_COUNT := 10
const TABLE_COUNT := 10
const GEM_COUNT := 34
const SCENE_RUNTIME_SIZE := Vector2i(720, 1280)
const GEM_MAX_EDGE := 256
const ALPHA_THRESHOLD := 0.01
const UI_ICON_TINT := Color("ead4ff")


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/runtime/backgrounds"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/runtime/tables"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/runtime/gems"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/runtime/ui/icons"))
	var manifest := {
		"version": 1,
		"alpha_threshold": ALPHA_THRESHOLD,
		"backgrounds": [],
		"tables": [],
		"gems": [],
		"ui": [],
	}
	var failures: Array[String] = []
	for index in range(1, BACKGROUND_COUNT + 1):
		_process_scene_image(
			"res://assets/backgrounds/background_%02d.png" % index,
			"res://assets/runtime/backgrounds/scene_bg_%02d.webp" % index,
			0.84,
			false,
			manifest.backgrounds,
			failures
		)
	for index in range(1, TABLE_COUNT + 1):
		_process_scene_image(
			"res://assets/tables/table_%02d.png" % index,
			"res://assets/runtime/tables/table_%02d.webp" % index,
			0.92,
			true,
			manifest.tables,
			failures
		)
	for index in range(1, GEM_COUNT + 1):
		_process_gem(
			"res://assets/gems/gem_%02d.png" % index,
			"res://assets/runtime/gems/gem_%02d.png" % index,
			manifest.gems,
			failures
		)
	_process_tinted_icon("res://assets/ui/icons/cog_blue_crisp.png", "res://assets/runtime/ui/icons/cog_lavender_crisp.png", manifest.ui, failures)
	if failures.is_empty():
		var manifest_path := "res://assets/runtime/art_refresh_manifest.json"
		var file := FileAccess.open(manifest_path, FileAccess.WRITE)
		if file == null:
			failures.append("Unable to write %s" % manifest_path)
		else:
			file.store_string(JSON.stringify(manifest, "\t") + "\n")
	if failures.is_empty():
		print("SUPPLIED_ART_REFRESH_PREPARATION: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("SUPPLIED_ART_REFRESH_PREPARATION: FAIL (%d)" % failures.size())
	quit(1)


func _process_scene_image(source_path: String, runtime_path: String, quality: float, require_alpha: bool, records: Array, failures: Array[String]) -> void:
	var image := Image.load_from_file(source_path)
	if image == null or image.is_empty():
		failures.append("Unable to load %s" % source_path)
		return
	if require_alpha and not image.detect_alpha():
		failures.append("Table source must retain transparency: %s" % source_path)
		return
	var source_size := image.get_size()
	var alpha_rect := _alpha_rect(image, ALPHA_THRESHOLD) if require_alpha else Rect2i(Vector2i.ZERO, source_size)
	image.resize(SCENE_RUNTIME_SIZE.x, SCENE_RUNTIME_SIZE.y, Image.INTERPOLATE_LANCZOS)
	var error := image.save_webp(runtime_path, true, quality)
	if error != OK:
		failures.append("Unable to save %s (error %d)" % [runtime_path, error])
		return
	records.append(_record(source_path, runtime_path, source_size, SCENE_RUNTIME_SIZE, alpha_rect))


func _process_gem(source_path: String, runtime_path: String, records: Array, failures: Array[String]) -> void:
	var image := Image.load_from_file(source_path)
	if image == null or image.is_empty():
		failures.append("Unable to load %s" % source_path)
		return
	if not image.detect_alpha():
		failures.append("Gem source must retain transparency: %s" % source_path)
		return
	var source_size := image.get_size()
	var alpha_rect := _alpha_rect(image, ALPHA_THRESHOLD)
	if alpha_rect.size.x <= 0 or alpha_rect.size.y <= 0:
		failures.append("Gem source has no visible alpha: %s" % source_path)
		return
	image = image.get_region(alpha_rect)
	var scale := float(GEM_MAX_EDGE) / float(maxi(image.get_width(), image.get_height()))
	var runtime_size := Vector2i(
		maxi(1, int(round(image.get_width() * scale))),
		maxi(1, int(round(image.get_height() * scale)))
	)
	image.resize(runtime_size.x, runtime_size.y, Image.INTERPOLATE_LANCZOS)
	_clear_low_alpha(image)
	var runtime_rect := _alpha_rect(image, ALPHA_THRESHOLD)
	if runtime_rect.position != Vector2i.ZERO or runtime_rect.size != runtime_size:
		failures.append("Gem derivative retains transparent edge space: %s -> %s inside %s" % [runtime_path, runtime_rect, runtime_size])
		return
	var error := image.save_png(runtime_path)
	if error != OK:
		failures.append("Unable to save %s (error %d)" % [runtime_path, error])
		return
	records.append(_record(source_path, runtime_path, source_size, runtime_size, alpha_rect))

func _process_tinted_icon(source_path: String, runtime_path: String, records: Array, failures: Array[String]) -> void:
	var image := Image.load_from_file(source_path)
	if image == null or image.is_empty():
		failures.append("Unable to load %s" % source_path)
		return
	var source_size := image.get_size()
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var source_color := image.get_pixel(x, y)
			if source_color.a <= 0.0:
				continue
			var shade := lerpf(0.72, 1.0, source_color.get_luminance())
			image.set_pixel(x, y, Color(UI_ICON_TINT.r * shade, UI_ICON_TINT.g * shade, UI_ICON_TINT.b * shade, source_color.a))
	var error := image.save_png(runtime_path)
	if error != OK:
		failures.append("Unable to save %s (error %d)" % [runtime_path, error])
		return
	records.append(_record(source_path, runtime_path, source_size, source_size, _alpha_rect(image, ALPHA_THRESHOLD)))

func _record(source_path: String, runtime_path: String, source_size: Vector2i, runtime_size: Vector2i, alpha_rect: Rect2i) -> Dictionary:
	return {
		"source": source_path,
		"runtime": runtime_path,
		"source_sha256": FileAccess.get_sha256(source_path),
		"runtime_sha256": FileAccess.get_sha256(runtime_path),
		"source_size": [source_size.x, source_size.y],
		"runtime_size": [runtime_size.x, runtime_size.y],
		"alpha_rect": [alpha_rect.position.x, alpha_rect.position.y, alpha_rect.size.x, alpha_rect.size.y],
	}


func _clear_low_alpha(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a < ALPHA_THRESHOLD:
				color.a = 0.0
				image.set_pixel(x, y, color)


func _alpha_rect(image: Image, threshold: float) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a < threshold:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
