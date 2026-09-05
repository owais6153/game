extends SceneTree

const GameControllerType = preload("res://scripts/gameplay/game_controller.gd")
const PowerCinematicType = preload("res://scripts/presentation/power_cinematic_layer.gd")
const PowerInventoryServiceType = preload("res://scripts/services/power_inventory_service.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_fast_travel_with_long_active_hold()
	await _test_level_entry_and_table_shake_are_presentation_only()
	if failures.is_empty():
		print("POWER_MOTION_LEVEL_ENTRY_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("POWER_MOTION_LEVEL_ENTRY_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


func _test_fast_travel_with_long_active_hold() -> void:
	var layer := PowerCinematicType.new()
	root.add_child(layer)
	await process_frame
	_assert(is_equal_approx(PowerCinematicType.DURATION, 1.65), "Power cinematic must retain its approved 1.65-second duration")
	_assert(PowerCinematicType.TARGET_ARRIVE < 0.34 and PowerCinematicType.TRAVEL_END >= 0.74, "Every power must arrive quickly, then retain a readable active wind-up")
	var centre := Vector2(360.0, 520.0)
	var target := Vector2(240.0, 940.0)
	for power in PowerInventoryServiceType.ALL:
		layer.play(power, target, centre)
		layer.elapsed = PowerCinematicType.DURATION * 0.25
		layer._update_hero(0.25)
		_assert(layer._hero.position.distance_to(target) < centre.distance_to(target) * 0.12, "%s must cross the screen decisively instead of drifting for most of the cinematic" % power)
		layer.elapsed = PowerCinematicType.DURATION * 0.50
		layer._update_hero(0.50)
		_assert(layer._hero.position.distance_to(target) <= 36.0, "%s must stay actively moving at the action point before impact" % power)
		layer.stop()
	layer.queue_free()
	await process_frame


func _test_level_entry_and_table_shake_are_presentation_only() -> void:
	paused = false
	var controller := GameControllerType.new()
	root.add_child(controller)
	await process_frame
	controller._on_home_level_intro_requested()
	controller._on_level_chosen(controller.highest_level)
	controller._on_home_play_requested()
	var body_positions: Array[Vector2] = []
	if GameConfig.LEVEL_ENTRY_PRESENTATION_ENABLED:
		_assert(controller.level_entry_active, "Starting a playable level must begin the table-entry reveal")
		_assert(controller.table_sprite.modulate.a <= 0.01 and controller.gem_sprite_layer.modulate.a <= 0.01, "Table and gems must begin the level entry faded out")
		controller._update_level_entry_presentation(GameConfig.LEVEL_ENTRY_PRESENTATION_DURATION * 0.45)
		_assert(is_zero_approx(controller.level_entry_elapsed), "Table entry must not advance invisibly behind the shared screen cover")
		controller.screen_transition.reset()
		for piece in controller.pieces:
			body_positions.append(piece.position)
		controller._update_level_entry_presentation(GameConfig.LEVEL_ENTRY_PRESENTATION_DURATION * 0.45)
		_assert(controller.table_sprite.position.y > GameConfig.table_texture_center().y, "Level entry must visibly rise into its authoritative table position")
		_assert(controller.table_sprite.modulate.a > 0.0, "Level entry must fade the table in while it rises")
		_assert(_positions_match(controller, body_positions), "Level entry presentation must not move simulation bodies")
		controller._update_level_entry_presentation(GameConfig.LEVEL_ENTRY_PRESENTATION_DURATION)
	else:
		# The entrance is switched off: the briefing popup already shows the
		# table behind it, so fading it in on START GAME read as the table
		# disappearing and coming back. With the flag off the board must simply
		# be present and fully opaque from the moment the level starts, and it
		# must stay that way when the presentation update is pumped.
		_assert(not controller.level_entry_active, "With the entrance disabled, starting a level must not begin a reveal")
		_assert(is_equal_approx(controller.table_sprite.modulate.a, GameConfig.TABLE_ART_CALM_MODULATE.a), "The table must be fully visible the moment a level starts")
		_assert(is_equal_approx(controller.gem_sprite_layer.modulate.a, 1.0), "Gems must be fully visible the moment a level starts")
		_assert(controller.table_sprite.position.is_equal_approx(GameConfig.table_texture_center()), "The table must start on its authoritative geometry, not offset for an entrance")
		controller.screen_transition.reset()
		for piece in controller.pieces:
			body_positions.append(piece.position)
		controller._update_level_entry_presentation(GameConfig.LEVEL_ENTRY_PRESENTATION_DURATION)
		_assert(_positions_match(controller, body_positions), "Level entry presentation must not move simulation bodies")
	_assert(not controller.level_entry_active and controller.table_sprite.position.is_equal_approx(GameConfig.table_texture_center()), "Level entry must finish exactly on authoritative table geometry")
	_assert(is_equal_approx(controller.table_sprite.modulate.a, GameConfig.TABLE_ART_CALM_MODULATE.a) and is_equal_approx(controller.gem_sprite_layer.modulate.a, 1.0), "Level entry must restore final table and gem opacity")
	controller._start_table_impact_feedback(PowerInventoryServiceType.HAMMER)
	controller._update_table_impact_feedback(0.025)
	_assert(not controller.table_impact_offset.is_zero_approx(), "A power impact must produce a subtle table response")
	_assert(controller.table_impact_offset.length() <= float(GameConfig.POWER_TABLE_SHAKE_AMPLITUDE.hammer), "Table impact must remain inside the central subtle-amplitude bound")
	_assert(_positions_match(controller, body_positions), "Power table shake must not move simulation bodies")
	controller._update_table_impact_feedback(GameConfig.POWER_TABLE_SHAKE_DURATION)
	_assert(controller.table_impact_offset.is_zero_approx() and controller.table_sprite.position.is_equal_approx(GameConfig.table_texture_center()), "Power table shake must settle exactly back to authoritative geometry")
	paused = false
	controller.queue_free()
	await process_frame


func _positions_match(controller, expected: Array[Vector2]) -> bool:
	if controller.pieces.size() != expected.size():
		return false
	for index in range(expected.size()):
		if not controller.pieces[index].position.is_equal_approx(expected[index]):
			return false
	return true


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
