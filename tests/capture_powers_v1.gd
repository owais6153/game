extends SceneTree

## Renders the gameplay HUD power row across portrait sizes and inventory
## states, so the tiles, count badges, and the "+" affordance can be reviewed
## before the milestone is committed.

const GameScene = preload("res://scenes/Game.tscn")
const LevelConfigType = preload("res://scripts/core/level_config.gd")
const PowerInventoryServiceType = preload("res://scripts/services/power_inventory_service.gd")
const DailyMissionServiceType = preload("res://scripts/services/daily_mission_service.gd")
const GameplayHudType = preload("res://scripts/ui/gameplay_hud_layer.gd")

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
	await _capture_popups()
	await _capture_cinematics()
	await _capture_home()
	await _capture_shop()
	await _capture_opening_boards()
	await _capture_daily()
	await _capture_limited_shots()
	await _capture_mission_toast()
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
	controller._on_level_chosen(controller.highest_level)
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


## The three power popups, so the ad-offer path and the first-use tutorial can
## be reviewed without a device.
func _capture_popups() -> void:
	var cases := [
		{"name": "ad-offer", "power": PowerInventoryServiceType.BOMB, "mode": "offer_ready"},
		{"name": "ad-offer-capped", "power": PowerInventoryServiceType.MAGNET, "mode": "offer_capped"},
		{"name": "ad-result", "power": PowerInventoryServiceType.BOMB, "mode": "result"},
		{"name": "how-to", "power": PowerInventoryServiceType.HAMMER, "mode": "how_to"},
	]
	for case in cases:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(720, 1280)
		viewport.disable_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var controller = GameScene.instantiate()
		viewport.add_child(controller)
		await process_frame
		controller.level_number = 4
		controller.level_seed = LevelConfigType.seed_for_level(4)
		controller.restart()
		controller._on_home_level_intro_requested()
		controller._on_level_chosen(controller.highest_level)
		controller._on_home_play_requested()
		controller.set_process(false)
		controller.coins = 1240
		_populate_board(controller)
		controller.power_state = PowerInventoryServiceType.ensure_state({
			"counts": {"bomb": 0, "magnet": 0, "switch": 2, "hammer": 1},
			"granted_starter": true,
		})
		controller._refresh_hud()
		var power := String(case.power)
		match String(case.mode):
			"offer_ready":
				controller.power_overlay.present_ad_offer(power, true, false)
			"offer_capped":
				controller.power_overlay.present_ad_offer(power, false, true)
			"result":
				controller.power_state = PowerInventoryServiceType.grant_from_ad(controller.power_state, power).state
				controller.power_overlay.present_ad_result(power, true, PowerInventoryServiceType.count(controller.power_state, power))
			"how_to":
				controller.power_overlay.present_how_to(power)
		await process_frame
		await create_timer(0.6, true, false, true).timeout
		await RenderingServer.frame_post_draw
		var error := viewport.get_texture().get_image().save_png(OUTPUT_DIR + "popup-%s.png" % case.name)
		if error != OK:
			push_error("Unable to save popup capture %s (error %d)" % [case.name, error])
		viewport.queue_free()
		await process_frame


## Each power cinematic sampled at its announce, travel, and impact beats, so
## the four sequences can be compared without a device.
func _capture_cinematics() -> void:
	for power in PowerInventoryServiceType.ALL:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(720, 1280)
		viewport.disable_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var controller = GameScene.instantiate()
		viewport.add_child(controller)
		await process_frame
		controller.level_number = 4
		controller.level_seed = LevelConfigType.seed_for_level(4)
		controller.restart()
		controller._on_home_level_intro_requested()
		controller._on_level_chosen(controller.highest_level)
		controller._on_home_play_requested()
		controller.coins = 1240
		_populate_board(controller)
		controller._sync_gems_and_mark_visibility()
		controller._refresh_hud()
		# Drive the layer directly at a fixed step so each beat is sampled at the
		# same point of the sequence every run.
		var target := Vector2(360.0, GameConfig.danger_line_y() - 120.0)
		var cinematic = controller.power_cinematic
		cinematic.play(power, target, controller._viewport_centre())
		# Step the layer by hand only; its own _process would double the advance
		# and the sequence would already be over by the impact sample.
		cinematic.set_process(false)
		var beats := {"announce": 0.18, "travel": 0.50, "impact": 0.78}
		var elapsed := 0.0
		for beat_name in ["announce", "travel", "impact"]:
			var until: float = cinematic.DURATION * float(beats[beat_name])
			while elapsed < until:
				cinematic._process(1.0 / 60.0)
				elapsed += 1.0 / 60.0
			await process_frame
			await RenderingServer.frame_post_draw
			var error := viewport.get_texture().get_image().save_png(
				OUTPUT_DIR + "cinematic-%s-%s.png" % [power, beat_name]
			)
			if error != OK:
				push_error("Unable to save cinematic capture %s %s (error %d)" % [power, beat_name, error])
		viewport.queue_free()
		await process_frame


## The Home screen, so the daily-missions widget and the power shop can be
## reviewed against the popup they sit alongside.
func _capture_home() -> void:
	for resolution in [Vector2i(720, 1280), Vector2i(1080, 2340)]:
		var viewport := SubViewport.new()
		viewport.size = resolution
		viewport.disable_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var controller = GameScene.instantiate()
		viewport.add_child(controller)
		await process_frame
		controller.coins = 1240
		controller.power_state = PowerInventoryServiceType.ensure_state({
			"counts": {"bomb": 0, "magnet": 2, "switch": 5, "hammer": 1},
			"granted_starter": true,
		})
		controller._show_home()
		controller.set_process(false)
		await process_frame
		await create_timer(0.7, true, false, true).timeout
		await RenderingServer.frame_post_draw
		var error := viewport.get_texture().get_image().save_png(
			OUTPUT_DIR + "home-%dx%d.png" % [resolution.x, resolution.y]
		)
		if error != OK:
			push_error("Unable to save home capture (error %d)" % error)
		viewport.queue_free()
		await process_frame


## The Home power shop, including a row the player cannot afford so the "+"
## fallback is visible alongside the priced rows.
func _capture_shop() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var controller = GameScene.instantiate()
	viewport.add_child(controller)
	await process_frame
	# Enough for switch and magnet, short of hammer and bomb.
	controller.coins = 240
	controller.power_state = PowerInventoryServiceType.ensure_state({
		"counts": {"bomb": 0, "magnet": 2, "switch": 5, "hammer": 1},
		"granted_starter": true,
	})
	controller._show_home()
	controller.set_process(false)
	controller._on_power_shop_requested()
	await process_frame
	await create_timer(0.7, true, false, true).timeout
	await RenderingServer.frame_post_draw
	var error := viewport.get_texture().get_image().save_png(OUTPUT_DIR + "power-shop.png")
	if error != OK:
		push_error("Unable to save shop capture (error %d)" % error)
	viewport.queue_free()
	await process_frame


## Opening boards for a few levels, so the seeded layouts can be reviewed for
## readability and for the gap that keeps a route through.
func _capture_opening_boards() -> void:
	for level in [1, 4, 8, 14]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(720, 1280)
		viewport.disable_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var controller = GameScene.instantiate()
		viewport.add_child(controller)
		await process_frame
		controller.level_number = level
		controller.level_seed = LevelConfigType.seed_for_level(level)
		controller.restart()
		controller._on_home_level_intro_requested()
		controller._on_level_chosen(controller.highest_level)
		controller._on_home_play_requested()
		controller.set_process(false)
		controller._sync_gems_and_mark_visibility()
		controller._refresh_hud()
		await process_frame
		await create_timer(0.35, true, false, true).timeout
		await RenderingServer.frame_post_draw
		var error := viewport.get_texture().get_image().save_png(OUTPUT_DIR + "opening-level-%02d.png" % level)
		if error != OK:
			push_error("Unable to save opening board capture (error %d)" % error)
		viewport.queue_free()
		await process_frame


## The daily missions popup, so the chest reward and its open state can be
## reviewed alongside the mission cards.
func _capture_daily() -> void:
	for claimed in [false, true]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(720, 1280)
		viewport.disable_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var controller = GameScene.instantiate()
		viewport.add_child(controller)
		await process_frame
		controller.coins = 1240
		controller._show_home()
		controller.set_process(false)
		var state: Dictionary = controller.daily_state.duplicate(true)
		var missions: Array = state.get("missions", []) as Array
		for index in range(missions.size()):
			var mission: Dictionary = missions[index] as Dictionary
			mission["progress"] = int(mission.get("target", 1))
			mission["claimed"] = true
			missions[index] = mission
		state["missions"] = missions
		state["chest_claimed"] = claimed
		controller.daily_state = state
		controller._on_daily_missions_requested()
		await process_frame
		await create_timer(0.7, true, false, true).timeout
		await RenderingServer.frame_post_draw
		var suffix := "claimed" if claimed else "ready"
		var error := viewport.get_texture().get_image().save_png(OUTPUT_DIR + "daily-%s.png" % suffix)
		if error != OK:
			push_error("Unable to save daily capture (error %d)" % error)
		viewport.queue_free()
		await process_frame


## A limited-shots level, where the shots counter joins the objective stack.
## The stack is taller there, and the panels used to overlap the coins row.
func _capture_limited_shots() -> void:
	for resolution in [Vector2i(720, 1280), Vector2i(360, 640)]:
		var viewport := SubViewport.new()
		viewport.size = resolution
		viewport.disable_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var controller = GameScene.instantiate()
		viewport.add_child(controller)
		await process_frame
		controller.level_number = 4
		controller.level_seed = LevelConfigType.seed_for_level(4)
		controller.restart()
		controller._on_home_level_intro_requested()
		controller._on_level_chosen(controller.highest_level)
		controller._on_home_play_requested()
		controller.set_process(false)
		controller.coins = 650
		controller._sync_gems_and_mark_visibility()
		controller._refresh_hud()
		await process_frame
		await create_timer(0.4, true, false, true).timeout
		await RenderingServer.frame_post_draw
		var error := viewport.get_texture().get_image().save_png(
			OUTPUT_DIR + "limited-shots-%dx%d.png" % [resolution.x, resolution.y])
		if error != OK:
			push_error("Unable to save limited shots capture (error %d)" % error)
		viewport.queue_free()
		await process_frame


## The in-play mission-complete banner, so it can be checked for clearance
## above the board and legibility against the scenery.
func _capture_mission_toast() -> void:
	for resolution in [Vector2i(720, 1280), Vector2i(1080, 2340)]:
		var viewport := SubViewport.new()
		viewport.size = resolution
		viewport.disable_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var controller = GameScene.instantiate()
		viewport.add_child(controller)
		await process_frame
		controller.level_number = 4
		controller.level_seed = LevelConfigType.seed_for_level(4)
		controller.restart()
		controller._on_home_level_intro_requested()
		controller._on_level_chosen(controller.highest_level)
		controller._on_home_play_requested()
		controller.coins = 1240
		_populate_board(controller)
		controller._sync_gems_and_mark_visibility()
		controller._refresh_hud()
		# A clean mission set, so the merge mission is not already complete from an
		# earlier run - a stale user:// state would leave the banner unfired and the
		# capture silently blank.
		controller.daily_state = DailyMissionServiceType.ensure_current_day({})
		var missions: Array = controller.daily_state.get("missions", []) as Array
		var target := int((missions[0] as Dictionary).get("target", 15))
		controller._record_daily_progress("merge", target)
		controller.set_process(false)
		# Step the banner by hand to its settled beat: the controller drives it from
		# _process, which is now off, and the sample must be deterministic.
		controller.gameplay_ui.update_mission_toast(GameplayHudType.MISSION_TOAST_IN)
		await process_frame
		await RenderingServer.frame_post_draw
		var error := viewport.get_texture().get_image().save_png(
			OUTPUT_DIR + "mission-toast-%dx%d.png" % [resolution.x, resolution.y]
		)
		if error != OK:
			push_error("Unable to save mission toast capture (error %d)" % error)
		viewport.queue_free()
		await process_frame
