extends SceneTree

const GameplayHudType = preload("res://scripts/gameplay_hud_layer.gd")
const EXPECTED_RADII := [36.0, 39.0, 42.0, 45.0, 48.0, 51.0, 54.0, 57.0]
const VIEWPORTS := [
	Vector2i(576, 1312),
	Vector2i(720, 1280),
	Vector2i(720, 1440),
	Vector2i(720, 1560),
	Vector2i(720, 1600),
	Vector2i(1080, 1920),
	Vector2i(1080, 2340),
	Vector2i(1080, 2400),
]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_tier_radius_progression()
	_test_responsive_table_geometry()
	for viewport_size in VIEWPORTS:
		await _test_hud_viewport(viewport_size, viewport_size == Vector2i(1080, 2400))
	if failures.is_empty():
		print("UI_SCALE_LAYOUT_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("UI_SCALE_LAYOUT_TESTS: FAIL (%d)" % failures.size())
	quit(1)


func _test_tier_radius_progression() -> void:
	var previous := 0.0
	for tier in range(1, 9):
		var radius := GameConfig.gem_collision_radius(tier)
		_assert(is_equal_approx(radius, EXPECTED_RADII[tier - 1]), "Tier %d radius must be %.1f" % [tier, EXPECTED_RADII[tier - 1]])
		_assert(radius > previous, "Tier %d must be larger than Tier %d" % [tier, tier - 1])
		previous = radius
	_assert(is_equal_approx(GameConfig.gem_collision_radius(8) / GameConfig.gem_collision_radius(1), 57.0 / 36.0), "L8/L1 endpoint scale must remain the bounded 1.583x ladder")
	_assert(GameConfig.PIECE_RADIUS == 57.0, "PIECE_RADIUS fallback must match the largest active tier")


func _test_responsive_table_geometry() -> void:
	for design_height in [1280.0, 1440.0, 1560.0, 1600.0]:
		GameConfig.configure_viewport(Vector2(720.0, design_height))
		var table_height := GameConfig.table_outer_bottom() - GameConfig.table_outer_top()
		_assert(is_equal_approx(GameConfig.table_center_x(), 360.0), "Table must stay horizontally centered at design height %.0f" % design_height)
		_assert(GameConfig.table_outer_top() >= 340.0, "Table must clear the compact top HUD at design height %.0f" % design_height)
		_assert(GameConfig.table_outer_bottom() <= design_height - 108.0, "Table must leave a bottom-safe merge-path lane at design height %.0f" % design_height)
		_assert(table_height / design_height >= 0.57, "Table must remain the dominant center surface at design height %.0f" % design_height)
		_assert(GameConfig.table_left_at(GameConfig.board_top()) >= 180.0 and GameConfig.table_right_at(GameConfig.board_top()) <= 540.0, "Back rails must stay centered and bounded")
		_assert(GameConfig.table_left_at(GameConfig.board_bottom()) >= 54.0 and GameConfig.table_right_at(GameConfig.board_bottom()) <= 666.0, "Front rails must stay inside horizontal safe margins")
		_assert(GameConfig.launch_y() < GameConfig.board_bottom(), "Launcher must remain inside the board")
		_assert(GameConfig.danger_line_y() < GameConfig.launch_y(), "Danger line must remain above the launcher")


func _test_hud_viewport(viewport_size: Vector2i, with_notch: bool) -> void:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var hud := GameplayHudType.new()
	viewport.add_child(hud)
	await process_frame
	if with_notch:
		hud.set_safe_insets_for_testing(Vector4(0.0, 88.0, 0.0, 104.0))
	hud.update_snapshot({
		"level_number": 3,
		"gem_identity_order": [1, 2, 3, 4, 5, 6, 7, 8],
		"current_level": 2,
		"next_level": 3,
		"coins": 39700,
		"score": 39700,
		"target_level": 5,
		"target_progress": 0,
		"target_quantity": 1,
		"target_index": 2,
		"target_total": 3,
		"target_collecting": false,
		"target_completed": false,
		"highest_level": 5,
		"music_enabled": true,
		"sound_enabled": true,
		"vibration_enabled": true,
	})
	await process_frame
	var metrics := hud.layout_metrics()
	var score_rect: Rect2 = metrics.score
	var target_rect: Rect2 = metrics.target
	var next_rect: Rect2 = metrics.next
	var settings_rect: Rect2 = metrics.settings
	var progression_rect: Rect2 = metrics.progression
	var center_tolerance := maxf(2.0, float(viewport_size.x) * 0.006)
	_assert(absf(target_rect.get_center().x - float(viewport_size.x) * 0.5) <= center_tolerance, "%s Target must remain horizontally centered (actual %.1f, expected %.1f)" % [viewport_size, target_rect.get_center().x, float(viewport_size.x) * 0.5])
	_assert(score_rect.end.x <= target_rect.position.x + 1.0, "%s Coins must not overlap Target" % viewport_size)
	_assert(target_rect.end.x <= next_rect.position.x + 1.0, "%s Target must not overlap Next" % viewport_size)
	_assert(next_rect.end.x <= settings_rect.position.x + 1.0, "%s Next must not overlap Settings" % viewport_size)
	_assert(score_rect.position.x >= -0.5 and settings_rect.end.x <= float(viewport_size.x) + 0.5, "%s top HUD must remain inside horizontal bounds" % viewport_size)
	_assert(progression_rect.position.x >= -0.5 and progression_rect.end.x <= float(viewport_size.x) + 0.5, "%s merge path must stay within screen width" % viewport_size)
	_assert(absf(progression_rect.get_center().x - float(viewport_size.x) * 0.5) <= center_tolerance, "%s merge path must remain centered" % viewport_size)
	var expected_bottom_clearance := 104.0 if with_notch else 0.0
	_assert(progression_rect.end.y <= float(viewport_size.y) - expected_bottom_clearance + 1.0, "%s merge path must clear the bottom safe area" % viewport_size)
	_assert(hud.root_control.find_child("LevelChip", true, false) == null, "%s Level box must be absent" % viewport_size)
	_assert(hud.target_icon.texture != null and hud.next_icon.texture != null, "%s Target and Next textures must resolve" % viewport_size)
	_assert(hud.progression_icons.size() == 8, "%s complete eight-gem path must remain present" % viewport_size)
	viewport.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
