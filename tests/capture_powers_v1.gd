extends SceneTree

## Renders the gameplay HUD power row across portrait sizes and inventory
## states, so the tiles, count badges, and the "+" affordance can be reviewed
## before the milestone is committed.

const GameScene = preload("res://scenes/Game.tscn")
const LevelConfigType = preload("res://scripts/core/level_config.gd")
const PowerInventoryServiceType = preload("res://scripts/services/power_inventory_service.gd")

const OUTPUT_DIR := "res://reports/powers-v1/screenshots/"
const RESOLUTIONS: Array[Vector2i] = [Vector2i(720, 1280), Vector2i(1080, 2340), Vector2i(720, 1600)]

## The three inventory states worth reviewing: a stocked player, a player who
## has run one power dry, and a player with nothing (every tile shows "+").
const STATES := [
	{"name": "stocked", "counts": {"bomb": 3, "magnet": 12, "switch": 1, "hammer": 7}},
	{"name": "mixed", "counts": {"bomb": 0, "magnet": 2, "switch": 0, "hammer": 1}},
	{"name": "empty", "counts": {"bomb": 0, "magnet": 0, "switch": 0, "hammer": 0}},
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for resolution in RESOLUTIONS:
		for state in STATES:
			await _capture(resolution, state)
	# One armed-targeting frame, to prove the selected tile reads as armed.
	await _capture(Vector2i(720, 1280), STATES[0], PowerInventoryServiceType.BOMB)
	print("POWERS_V1_CAPTURE: PASS")
	quit(0)


func _capture(resolution: Vector2i, state: Dictionary, armed: String = "") -> void:
	var viewport := SubViewport.new()
	viewport.name = "Powers_%dx%d_%s" % [resolution.x, resolution.y, state.name]
	viewport.size = resolution
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)
	var controller = GameScene.instantiate()
	viewport.add_child(controller)
	await process_frame
	controller.level_number = 4
	controller.level_seed = LevelConfigType.seed_for_level(4)
	controller.restart()
	controller._on_home_level_intro_requested()
	controller._on_home_play_requested()
	controller.set_process(false)
	controller.coins = 1240
	controller.power_state = PowerInventoryServiceType.ensure_state({
		"counts": state.counts,
		"granted_starter": true,
	})
	# A populated board is the only honest state to review the row in: magnet,
	# hammer, and bomb all correctly report themselves unusable on an empty
	# board, so an empty capture would show every owned tile dimmed.
	_populate_board(controller)
	controller._sync_gems_and_mark_visibility()
	if not armed.is_empty():
		# Go through the real request path so the capture can only reach a state
		# the player could actually reach.
		controller._on_power_requested(armed)
	controller._refresh_hud()
	controller.queue_redraw()
	await process_frame
	await create_timer(0.25, true, false, true).timeout
	await RenderingServer.frame_post_draw
	var suffix := "-armed-%s" % armed if not armed.is_empty() else ""
	var destination := OUTPUT_DIR + "%dx%d-%s%s.png" % [resolution.x, resolution.y, state.name, suffix]
	var error := viewport.get_texture().get_image().save_png(destination)
	if error != OK:
		push_error("Unable to save power capture %s (error %d)" % [destination, error])
	viewport.queue_free()
	await process_frame


## A settled cluster in the lower half of the table, deterministic so captures
## are comparable between runs.
func _populate_board(controller) -> void:
	var piece_id := 9000
	var rows := 4
	var columns := 5
	for row in range(rows):
		var y_position := GameConfig.danger_line_y() - 40.0 - float(row) * 78.0
		for column in range(columns):
			var level := 1 + ((row * columns + column) % 4)
			var radius := GameConfig.gem_collision_radius(level)
			var left := GameConfig.table_left_at(y_position) + radius
			var right := GameConfig.table_right_at(y_position) - radius
			var x_position := lerpf(left, right, float(column) / float(columns - 1))
			controller.pieces.append(GemPiece.new(piece_id, level, Vector2(x_position, y_position), radius))
			piece_id += 1
