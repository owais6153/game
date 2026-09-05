extends SceneTree

## Renders the level screen at a phone resolution in several progression states,
## so the map's artwork can be reviewed without a device: an early player with no
## chest in reach, a player standing on a claimable chest, and one deep enough
## that both an opened and an unopened chest are on screen at once.

const GameScene := preload("res://scenes/Game.tscn")
const OUTPUT_DIR := "res://reports/level-select-map-v1"
## Two frames per state: a real tall phone, and the supplied reference's own
## 1024x1536 so the two can be compared side by side without aspect ratio
## accounting for the difference.
const RESOLUTIONS := [Vector2i(720, 1440), Vector2i(720, 1600)]

const STATES := [
	{"name": "early-level-6", "highest": 6, "chests": []},
	{"name": "chest-ready-level-21", "highest": 21, "chests": []},
	{"name": "chest-opened-level-46", "highest": 46, "chests": [1, 2]},
	{"name": "deep-level-317", "highest": 317, "chests": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]},
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for state in STATES:
		for resolution in RESOLUTIONS:
			await _capture(state, resolution)
	print("LEVEL_SELECT_MAP_V1_CAPTURE: PASS")
	quit(0)


func _capture(state: Dictionary, resolution: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.name = "LevelSelect_%s_%d" % [state.name, resolution.x]
	viewport.size = resolution
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)

	var controller = GameScene.instantiate()
	viewport.add_child(controller)
	await process_frame

	controller.highest_level = int(state.highest)
	controller.claimed_chests = _ints(state.chests)
	controller.coins = 4650
	controller._show_level_select()
	# Two frames: the first lays the scroll out, the second lets the deferred
	# centring and the map's own redraw land before the image is taken.
	await process_frame
	await process_frame
	await process_frame

	var image := viewport.get_texture().get_image()
	image.save_png("%s/%s-%dx%d.png" % [OUTPUT_DIR, state.name, resolution.x, resolution.y])
	print("captured %s at %dx%d" % [state.name, resolution.x, resolution.y])
	viewport.queue_free()
	await process_frame


func _ints(values: Array) -> Array[int]:
	var result: Array[int] = []
	for value in values:
		result.append(int(value))
	return result
