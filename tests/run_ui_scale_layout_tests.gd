extends SceneTree

const GameplayHudType = preload("res://scripts/gameplay_hud_layer.gd")
const UiDesignSystemType = preload("res://scripts/ui_design_system.gd")
const EXPECTED_RADII := [36.0, 39.0, 42.0, 45.0, 48.0, 51.0, 54.0, 57.0]
## Offline RGB-distance measurements of the regenerated 920x810 runtime table
## canvases. These are presentation-only proof points, never gameplay inputs.
const TABLE_TOP_FIELD_LEFT_X := [238.0, 228.0, 239.0, 236.0, 238.0, 235.0, 234.0, 233.0, 236.0, 234.0]
const TABLE_TOP_FIELD_RIGHT_X := [688.0, 691.0, 685.0, 689.0, 689.0, 684.0, 687.0, 690.0, 689.0, 691.0]
const TABLE_DANGER_FIELD_LEFT_X := [115.0, 113.0, 118.0, 115.0, 114.0, 116.0, 116.0, 110.0, 114.0, 112.0]
const TABLE_DANGER_FIELD_RIGHT_X := [817.0, 819.0, 817.0, 817.0, 818.0, 811.0, 817.0, 820.0, 818.0, 817.0]
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
	_test_feedback_polish_contract()
	_test_fixed_table_geometry()
	_test_regenerated_table_art_alignment()
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


func _test_feedback_polish_contract() -> void:
	_assert(GameConfig.MERGE_PRESENTATION_DURATION >= 0.25 and GameConfig.MERGE_PRESENTATION_DURATION <= 0.32, "Merge presentation must complete inside the requested 250-320 ms window")
	_assert(GameConfig.MERGE_SOURCE_PULL_DURATION <= 0.07, "Merge source impact/pull must remain brief")
	_assert(GameConfig.MERGE_RESULT_POP_SCALE >= 1.22 and GameConfig.MERGE_RESULT_POP_SCALE <= 1.30, "Merge result overshoot must be clearly visible and controlled")
	_assert(GameConfig.COIN_FLIGHT_DURATION >= 0.45 and GameConfig.MAJOR_COIN_FLIGHT_DURATION <= 0.70, "Coin reward flights must preserve the fast reference rhythm")
	_assert(GameConfig.TARGET_COLLECTION_DURATION >= 0.28 and GameConfig.TARGET_COLLECTION_DURATION <= 0.40, "Target collection must remain quick")
	_assert(GameConfig.COLLISION_VISUAL_DURATION <= 0.15, "Collision micro-feedback must remain short")
	_assert(GameConfig.COLLISION_VISUAL_MAX_COMPRESSION <= 0.06, "Collision deformation must remain subtle")
	_assert(GameConfig.COLLISION_VISUAL_COOLDOWN >= 0.08 and GameConfig.COLLISION_VISUAL_COOLDOWN <= 0.15, "Collision visual cooldown must prevent chatter")


func _test_fixed_table_geometry() -> void:
	_assert(is_equal_approx(GameConfig.TABLE_LAYOUT_BASE_TOP, 400.0), "Table top must remain fixed")
	_assert(is_equal_approx(GameConfig.TABLE_LAYOUT_BASE_BOTTOM, 1185.0), "Table bottom must remain fixed")
	_assert(is_equal_approx(GameConfig.BOARD_TOP, 440.0), "Board top must remain fixed")
	_assert(is_equal_approx(GameConfig.BOARD_BOTTOM, 1110.0), "Board bottom must remain fixed")
	_assert(is_equal_approx(GameConfig.TABLE_INNER_LEFT_TOP, 188.0) and is_equal_approx(GameConfig.TABLE_INNER_RIGHT_TOP, 532.0), "Back physics rails must remain intact")
	_assert(is_equal_approx(GameConfig.TABLE_INNER_LEFT_BOTTOM, 62.0) and is_equal_approx(GameConfig.TABLE_INNER_RIGHT_BOTTOM, 658.0), "Front physics rails must remain intact")
	_assert(is_equal_approx(GameConfig.DANGER_LINE_Y, 960.0), "Danger-line position must remain fixed")
	_assert(is_equal_approx(GameConfig.LAUNCH_Y, 1042.0), "Launcher position must remain fixed")
	_assert(GameConfig.TABLE_TEXTURE_RENDER_SCALE.is_equal_approx(Vector2(0.7391304, 0.9691358)), "Regenerated table art must use the unstretched shared transform")
	GameConfig.configure_viewport(GameConfig.VIEWPORT_SIZE)
	var render_scale := GameConfig.table_texture_render_scale()
	_assert(render_scale.is_equal_approx(GameConfig.TABLE_TEXTURE_RENDER_SCALE), "Runtime table art must use the fixed unstretched transform")


func _test_regenerated_table_art_alignment() -> void:
	GameConfig.configure_viewport(GameConfig.VIEWPORT_SIZE)
	var center_x := GameConfig.table_texture_center().x
	var half_texture_width := GameConfig.TABLE_TEXTURE_SIZE.x * 0.5
	var scale_x := GameConfig.table_texture_render_scale().x
	var danger_y := GameConfig.danger_line_y()
	var danger_left := GameConfig.table_left_at(danger_y) + 8.0
	var danger_right := GameConfig.table_right_at(danger_y) - 8.0
	for index in range(TABLE_TOP_FIELD_LEFT_X.size()):
		var top_left: float = center_x + (float(TABLE_TOP_FIELD_LEFT_X[index]) - half_texture_width) * scale_x
		var top_right: float = center_x + (float(TABLE_TOP_FIELD_RIGHT_X[index]) - half_texture_width) * scale_x
		var measured_danger_left: float = center_x + (float(TABLE_DANGER_FIELD_LEFT_X[index]) - half_texture_width) * scale_x
		var measured_danger_right: float = center_x + (float(TABLE_DANGER_FIELD_RIGHT_X[index]) - half_texture_width) * scale_x
		_assert(absf(top_left - GameConfig.table_left_at(GameConfig.board_top())) <= 10.0, "Table %d left back rail must match fixed physics" % (index + 1))
		_assert(absf(top_right - GameConfig.table_right_at(GameConfig.board_top())) <= 10.0, "Table %d right back rail must match fixed physics" % (index + 1))
		_assert(absf(measured_danger_left - danger_left) <= 10.0, "Table %d left danger endpoint must meet its visible inner rail" % (index + 1))
		_assert(absf(measured_danger_right - danger_right) <= 10.0, "Table %d right danger endpoint must meet its visible inner rail" % (index + 1))


func _test_responsive_table_geometry() -> void:
	for design_height in [1280.0, 1440.0, 1560.0, 1600.0]:
		GameConfig.configure_viewport(Vector2(720.0, design_height))
		var table_height := GameConfig.table_outer_bottom() - GameConfig.table_outer_top()
		_assert(is_equal_approx(GameConfig.table_center_x(), 360.0), "Table must stay horizontally centered at design height %.0f" % design_height)
		_assert(GameConfig.table_outer_top() >= 390.0, "Table must clear the table-adjacent objective stack at design height %.0f" % design_height)
		_assert(GameConfig.table_outer_bottom() <= design_height - 72.0, "Table must remain inside the lower safe composition at design height %.0f" % design_height)
		_assert(table_height / design_height >= 0.57, "Table must remain the dominant center surface at design height %.0f" % design_height)
		_assert(GameConfig.table_left_at(GameConfig.board_top()) >= 180.0 and GameConfig.table_right_at(GameConfig.board_top()) <= 540.0, "Back rails must stay centered and bounded")
		_assert(GameConfig.table_left_at(GameConfig.board_bottom()) >= 54.0 and GameConfig.table_right_at(GameConfig.board_bottom()) <= 666.0, "Front rails must stay inside horizontal safe margins")
		_assert(GameConfig.launch_y() < GameConfig.board_bottom(), "Launcher must remain inside the board")
		_assert(GameConfig.danger_line_y() < GameConfig.launch_y(), "Danger line must remain above the launcher")
	for wide_size in [Vector2(1280.0, 1280.0), Vector2(1600.0, 1280.0), Vector2(1920.0, 1280.0)]:
		GameConfig.configure_viewport(wide_size)
		_assert(is_equal_approx(GameConfig.table_center_x(), wide_size.x * 0.5), "%s wide/resizable table must remain centered" % wide_size)
		_assert(GameConfig.table_left_at(GameConfig.board_bottom()) > 0.0 and GameConfig.table_right_at(GameConfig.board_bottom()) < wide_size.x, "%s wide/resizable rails must remain contained" % wide_size)
		_assert(is_equal_approx(GameConfig.table_texture_render_scale().x, GameConfig.TABLE_TEXTURE_RENDER_SCALE.x), "%s wide/resizable table must not stretch horizontally" % wide_size)


func _test_hud_viewport(viewport_size: Vector2i, with_notch: bool) -> void:
	var layout_scale := minf(1.0, float(viewport_size.x) / UiDesignSystemType.DESIGN_WIDTH)
	var design_height := float(viewport_size.y) / maxf(layout_scale, 0.01)
	GameConfig.configure_viewport(Vector2(UiDesignSystemType.DESIGN_WIDTH, design_height))
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
	_assert(not score_rect.intersects(next_rect) and not score_rect.intersects(settings_rect) and not next_rect.intersects(settings_rect), "%s top utilities must not overlap each other" % viewport_size)
	_assert(not score_rect.intersects(target_rect) and not next_rect.intersects(target_rect) and not settings_rect.intersects(target_rect), "%s table-adjacent Target must not overlap top utilities" % viewport_size)
	_assert(target_rect.end.y <= progression_rect.position.y + 1.0, "%s Target must sit above the merge path" % viewport_size)
	_assert(settings_rect.position.y >= next_rect.end.y - 1.0, "%s Settings must sit below Next" % viewport_size)
	_assert(absf(score_rect.position.y - next_rect.position.y) <= center_tolerance, "%s Coins and Next must share the same top baseline" % viewport_size)
	_assert(settings_rect.get_center().x >= next_rect.get_center().x - 1.0, "%s Settings must remain aligned to the right-side Next card" % viewport_size)
	_assert(next_rect.size.x >= UiDesignSystemType.NEXT_PANEL_SIZE.x * layout_scale - 1.0, "%s Next must retain its enlarged width" % viewport_size)
	_assert(next_rect.size.y >= UiDesignSystemType.NEXT_PANEL_SIZE.y * layout_scale - 1.0, "%s Next must retain its enlarged height" % viewport_size)
	_assert(target_rect.size.x > next_rect.size.x * 2.0, "%s Target must remain more prominent than Next" % viewport_size)
	_assert(score_rect.position.x >= -0.5 and settings_rect.end.x <= float(viewport_size.x) + 0.5, "%s top HUD must remain inside horizontal bounds" % viewport_size)
	_assert(progression_rect.position.x >= -0.5 and progression_rect.end.x <= float(viewport_size.x) + 0.5, "%s merge path must stay within screen width" % viewport_size)
	_assert(absf(progression_rect.get_center().x - float(viewport_size.x) * 0.5) <= center_tolerance, "%s merge path must remain centered" % viewport_size)
	var table_top_screen := GameConfig.table_outer_top() * layout_scale
	_assert(progression_rect.end.y <= table_top_screen - UiDesignSystemType.OBJECTIVE_TABLE_GAP_MIN * layout_scale + 1.0, "%s merge path must sit visibly above the table" % viewport_size)
	_assert(progression_rect.end.y < float(viewport_size.y) * 0.66, "%s merge path must remain in the gameplay sightline instead of the navigation edge" % viewport_size)
	_assert(progression_rect.size.y >= UiDesignSystemType.PROGRESSION_HEIGHT * layout_scale - 1.0, "%s merge path must retain its emphasized height" % viewport_size)
	_assert(hud.root_control.find_child("LevelChip", true, false) == null, "%s Level box must be absent" % viewport_size)
	_assert(hud.target_icon.texture != null and hud.next_icon.texture != null, "%s Target and Next textures must resolve" % viewport_size)
	var coin_value := hud.root_control.find_child("CoinValue", true, false) as Label
	var target_progress := hud.root_control.find_child("TargetProgressText", true, false) as Label
	_assert(coin_value != null and coin_value.get_theme_constant("outline_size") >= 3, "%s coin text must retain the stronger contrast outline" % viewport_size)
	_assert(target_progress != null and target_progress.get_theme_constant("outline_size") >= 3, "%s target text must retain the stronger contrast outline" % viewport_size)
	_assert(hud.progression_icons.size() == 8, "%s complete eight-gem path must remain present" % viewport_size)
	viewport.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
