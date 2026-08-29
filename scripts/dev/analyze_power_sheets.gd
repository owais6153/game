extends SceneTree

## One-off inspection helper: reports the connected alpha components of the
## supplied power/UI sheets so extraction rects can be chosen from measured
## data rather than guessed from a thumbnail.

const SHEETS := [
	"res://assets/ui_kit_source/sheet_power_buttons.png",
	"res://assets/ui_kit_source/sheet_power_icons.png",
	"res://assets/ui_kit_source/sheet_icons_v2.png",
]
const ALPHA_THRESHOLD := 0.5
const MIN_AREA := 2000


func _init() -> void:
	for path in SHEETS:
		_report(path)
	quit(0)


func _report(path: String) -> void:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		print("MISSING %s" % path)
		return
	var width := image.get_width()
	var height := image.get_height()
	print("\n=== %s  %dx%d  alpha=%s ===" % [path.get_file(), width, height, image.detect_alpha()])
	var visited := {}
	var components: Array = []
	for y in range(height):
		for x in range(width):
			var key := y * width + x
			if visited.has(key) or image.get_pixel(x, y).a < ALPHA_THRESHOLD:
				continue
			var rect := _flood(image, x, y, visited, width, height)
			if rect.size.x * rect.size.y >= MIN_AREA:
				components.append(rect)
	components.sort_custom(func(a: Rect2i, b: Rect2i) -> bool:
		if absi(a.position.y - b.position.y) > 40:
			return a.position.y < b.position.y
		return a.position.x < b.position.x
	)
	print("components: %d" % components.size())
	for index in range(components.size()):
		var rect: Rect2i = components[index]
		print("  [%02d] x=%4d y=%4d w=%4d h=%4d" % [index, rect.position.x, rect.position.y, rect.size.x, rect.size.y])


func _flood(image: Image, start_x: int, start_y: int, visited: Dictionary, width: int, height: int) -> Rect2i:
	var min_x := start_x
	var max_x := start_x
	var min_y := start_y
	var max_y := start_y
	var stack: Array[Vector2i] = [Vector2i(start_x, start_y)]
	visited[start_y * width + start_x] = true
	while not stack.is_empty():
		var point: Vector2i = stack.pop_back()
		min_x = mini(min_x, point.x)
		max_x = maxi(max_x, point.x)
		min_y = mini(min_y, point.y)
		max_y = maxi(max_y, point.y)
		var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		for offset in offsets:
			var next := point + offset
			if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height:
				continue
			var key := next.y * width + next.x
			if visited.has(key) or image.get_pixel(next.x, next.y).a < ALPHA_THRESHOLD:
				continue
			visited[key] = true
			stack.append(next)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
