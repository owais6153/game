extends SceneTree

const BACKGROUND_COUNT := 19
const TABLE_COUNT := 10
const BACKGROUND_SIZE := Vector2i(720, 1280)
const TABLE_SIZE := Vector2i(920, 810)


func _init() -> void:
	var failures: Array[String] = []
	for index in range(BACKGROUND_COUNT):
		var number := index + 1
		var source := "res://assets/source/backgrounds/scene_bg_%02d_source.png" % number
		var runtime := "res://assets/runtime/backgrounds/scene_bg_%02d.webp" % number
		_process_image(source, runtime, BACKGROUND_SIZE, 0.82, false, failures)
	for index in range(TABLE_COUNT):
		var number := index + 1
		var source := "res://assets/source/tables/table_%02d_source.png" % number
		var runtime := "res://assets/runtime/tables/table_%02d.webp" % number
		_process_image(source, runtime, TABLE_SIZE, 0.90, true, failures)
	if failures.is_empty():
		print("REGENERATED_SCENE_ASSET_PREPARATION: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("REGENERATED_SCENE_ASSET_PREPARATION: FAIL (%d)" % failures.size())
	quit(1)


func _process_image(source_path: String, runtime_path: String, target_size: Vector2i, quality: float, require_alpha: bool, failures: Array[String]) -> void:
	var image := Image.new()
	var load_error := image.load(source_path)
	if load_error != OK:
		failures.append("Unable to load %s (error %d)" % [source_path, load_error])
		return
	if require_alpha:
		var corner_alpha := image.get_pixel(0, 0).a
		if corner_alpha > 0.01:
			failures.append("Table source lacks transparent corners: %s" % source_path)
	image.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	var save_error := image.save_webp(runtime_path, true, quality)
	if save_error != OK:
		failures.append("Unable to save %s (error %d)" % [runtime_path, save_error])
