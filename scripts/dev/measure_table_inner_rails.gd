extends SceneTree

const SAMPLE_WORLD_ROWS: Array[float] = []
const TEXTURE_CENTER := Vector2(360.0, 844.0)
const TEXTURE_SCALE := Vector2(0.9583333, 0.752)


func _init() -> void:
	for table_index in range(1, 11):
		var path := "res://assets/runtime/tables/table_%02d.webp" % table_index
		var image := Image.load_from_file(path)
		if image == null or image.is_empty():
			push_error("Unable to load %s" % path)
			continue
		print("TABLE %02d" % table_index)
		print("  center_y top=%s bottom=%s" % [_vertical_edge_candidates(image, 360, 60, 210), _vertical_edge_candidates(image, 360, 1020, 1150)])
		for world_y in SAMPLE_WORLD_ROWS:
			var row := clampi(roundi((world_y - TEXTURE_CENTER.y) / TEXTURE_SCALE.y + image.get_height() * 0.5), 0, image.get_height() - 1)
			var left_candidates := _edge_candidates(image, row, 55, 210, true)
			var right_candidates := _edge_candidates(image, row, 510, 665, false)
			print("  y=%4d row=%4d left=%s right=%s" % [int(world_y), row, left_candidates, right_candidates])
	quit()


func _edge_candidates(image: Image, row: int, start_x: int, end_x: int, ascending: bool) -> Array:
	var scores: Array[Dictionary] = []
	for x in range(start_x + 3, end_x - 3):
		var before := _mean_color(image, row, x - 3, x - 1)
		var after := _mean_color(image, row, x + 1, x + 3)
		var difference := Vector3(before.r - after.r, before.g - after.g, before.b - after.b).length()
		scores.append({"x": x, "score": difference})
	scores.sort_custom(func(first: Dictionary, second: Dictionary) -> bool: return float(first.score) > float(second.score))
	var accepted: Array = []
	for candidate in scores:
		if accepted.size() >= 5:
			break
		var far_enough := true
		for prior in accepted:
			if absi(int(prior["px"]) - int(candidate["x"])) < 7:
				far_enough = false
				break
		if far_enough:
			var texture_x := int(candidate["x"])
			var world_x := TEXTURE_CENTER.x + (float(texture_x) - image.get_width() * 0.5) * TEXTURE_SCALE.x
			accepted.append({"px": texture_x, "world": snappedf(world_x, 0.1), "score": snappedf(float(candidate["score"]), 0.001)})
	if not ascending:
		accepted.sort_custom(func(first: Dictionary, second: Dictionary) -> bool: return int(first["px"]) > int(second["px"]))
	return accepted


func _vertical_edge_candidates(image: Image, column: int, start_y: int, end_y: int) -> Array:
	var scores: Array[Dictionary] = []
	for y in range(start_y + 3, end_y - 3):
		var before := _mean_vertical_color(image, column, y - 3, y - 1)
		var after := _mean_vertical_color(image, column, y + 1, y + 3)
		var difference := Vector3(before.r - after.r, before.g - after.g, before.b - after.b).length()
		scores.append({"y": y, "score": difference})
	scores.sort_custom(func(first: Dictionary, second: Dictionary) -> bool: return float(first["score"]) > float(second["score"]))
	var accepted: Array = []
	for candidate in scores:
		if accepted.size() >= 5:
			break
		var far_enough := true
		for prior in accepted:
			if absi(int(prior["px"]) - int(candidate["y"])) < 7:
				far_enough = false
				break
		if far_enough:
			var texture_y := int(candidate["y"])
			var world_y := TEXTURE_CENTER.y + (float(texture_y) - image.get_height() * 0.5) * TEXTURE_SCALE.y
			accepted.append({"px": texture_y, "world": snappedf(world_y, 0.1), "score": snappedf(float(candidate["score"]), 0.001)})
	return accepted


func _mean_color(image: Image, row: int, start_x: int, end_x: int) -> Color:
	var total := Color(0.0, 0.0, 0.0, 0.0)
	var count := 0
	for x in range(start_x, end_x + 1):
		total += image.get_pixel(x, row)
		count += 1
	return total / float(maxi(1, count))


func _mean_vertical_color(image: Image, column: int, start_y: int, end_y: int) -> Color:
	var total := Color(0.0, 0.0, 0.0, 0.0)
	var count := 0
	for y in range(start_y, end_y + 1):
		total += image.get_pixel(column, y)
		count += 1
	return total / float(maxi(1, count))
