extends SceneTree

const GameplayHudType = preload("res://scripts/ui/gameplay_hud_layer.gd")
const UiDesignSystemType = preload("res://scripts/ui/ui_design_system.gd")
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
	_assert(GameConfig.MERGE_PRESENTATION_DURATION >= 0.40 and GameConfig.MERGE_PRESENTATION_DURATION <= 0.45, "Merge presentation must retain the approved readable 400-450 ms window")
	_assert(GameConfig.MERGE_SOURCE_PULL_DURATION >= 0.05 and GameConfig.MERGE_SOURCE_PULL_DURATION <= 0.08, "Merge source impact/pull must retain the approved combination phase")
	_assert(GameConfig.MERGE_RESULT_POP_SCALE >= 1.22 and GameConfig.MERGE_RESULT_POP_SCALE <= 1.26, "Merge result overshoot must remain readable and controlled")
	_assert(GameConfig.COIN_FLIGHT_DURATION >= 0.45 and GameConfig.MAJOR_COIN_FLIGHT_DURATION <= 0.70, "Coin reward flights must preserve the fast reference rhythm")
	_assert(GameConfig.TARGET_COLLECTION_DURATION >= 0.60 and GameConfig.TARGET_COLLECTION_DURATION <= 0.80, "Target collection must retain the restored readable duration")
	_assert(GameConfig.COLLISION_VISUAL_DURATION <= 0.15, "Collision micro-feedback must remain short")
	_assert(GameConfig.COLLISION_VISUAL_MAX_COMPRESSION <= 0.06, "Collision deformation must remain subtle")
	_assert(GameConfig.COLLISION_VISUAL_COOLDOWN >= 0.08 and GameConfig.COLLISION_VISUAL_COOLDOWN <= 0.15, "Collision visual cooldown must prevent chatter")


func _test_fixed_table_geometry() -> void:
	_assert(is_equal_approx(GameConfig.TABLE_LAYOUT_BASE_TOP, 420.0), "Table top must match the supplied portrait composition")
	_assert(is_equal_approx(GameConfig.TABLE_LAYOUT_BASE_BOTTOM, 1215.0), "Table bottom must match the supplied portrait composition")
	_assert(is_equal_approx(GameConfig.BOARD_TOP, 455.0), "Board top must remain inset from the visible back rail")
	_assert(is_equal_approx(GameConfig.BOARD_BOTTOM, 1165.0), "Board bottom must remain inset from the visible front rail")
	_assert(is_equal_approx(GameConfig.TABLE_INNER_LEFT_TOP, 130.0) and is_equal_approx(GameConfig.TABLE_INNER_RIGHT_TOP, 590.0), "Back physics rails must follow the measured supplied-table opening")
	_assert(is_equal_approx(GameConfig.TABLE_INNER_LEFT_BOTTOM, 54.0) and is_equal_approx(GameConfig.TABLE_INNER_RIGHT_BOTTOM, 666.0), "Front physics rails must follow the measured supplied-table opening")
	_assert(is_equal_approx(GameConfig.DANGER_LINE_Y, 1015.0), "Danger line must remain inside the recalibrated playfield")
	_assert(is_equal_approx(GameConfig.LAUNCH_Y, 1095.0), "Launcher must remain inside the recalibrated playfield")
	_assert(GameConfig.TABLE_TEXTURE_SIZE == Vector2(720.0, 1280.0), "Supplied table derivatives must preserve the full portrait composition")
	_assert(GameConfig.TABLE_TEXTURE_RENDER_SCALE.is_equal_approx(Vector2(0.9583333, 0.752)), "Supplied table art must use the measured shared transform")
	GameConfig.configure_viewport(GameConfig.VIEWPORT_SIZE)
	_assert(GameConfig.table_texture_render_scale().is_equal_approx(GameConfig.TABLE_TEXTURE_RENDER_SCALE), "Runtime table art must use the fixed supplied-art transform")


func _test_regenerated_table_art_alignment() -> void:
	GameConfig.configure_viewport(GameConfig.VIEWPORT_SIZE)
	var center := GameConfig.table_texture_center()
	var scale := GameConfig.table_texture_render_scale()
	for index in range(AssetCatalog.LEVEL_TABLES.size()):
		var image := AssetCatalog.table_texture(index).get_image()
		_assert(image != null and image.get_size() == Vector2i(720, 1280), "Table %d must load on the shared portrait canvas" % (index + 1))
		if image == null:
			continue
		for y_world in [GameConfig.board_top(), GameConfig.board_bottom()]:
			var row := clampi(roundi((y_world - center.y) / scale.y + image.get_height() * 0.5), 0, image.get_height() - 1)
			var bounds := _row_alpha_bounds(image, row, 0.04)
			_assert(bounds.x >= 0.0 and bounds.y > bounds.x, "Table %d must contain visible rail pixels at y %.0f" % [index + 1, y_world])
			if bounds.x < 0.0:
				continue
			var art_left := center.x + (bounds.x - image.get_width() * 0.5) * scale.x
			var art_right := center.x + (bounds.y - image.get_width() * 0.5) * scale.x
			var left_inset := GameConfig.table_left_at(y_world) - art_left
			var right_inset := art_right - GameConfig.table_right_at(y_world)
			_assert(left_inset >= 0.0 and left_inset <= 70.0, "Table %d left physics rail must stay just inside visible art at y %.0f" % [index + 1, y_world])
			_assert(right_inset >= 0.0 and right_inset <= 70.0, "Table %d right physics rail must stay just inside visible art at y %.0f" % [index + 1, y_world])


func _row_alpha_bounds(image: Image, row: int, threshold: float) -> Vector2:
	var first := -1
	var last := -1
	for x in range(image.get_width()):
		if image.get_pixel(x, row).a >= threshold:
			if first < 0:
				first = x
			last = x
	return Vector2(first, last)

func _test_responsive_table_geometry() -> void:
	for design_height in [1280.0, 1440.0, 1560.0, 1600.0]:
		GameConfig.configure_viewport(Vector2(720.0, design_height))
		var table_height := GameConfig.table_outer_bottom() - GameConfig.table_outer_top()
		_assert(is_equal_approx(GameConfig.table_center_x(), 360.0), "Table must stay horizontally centered at design height %.0f" % design_height)
		_assert(GameConfig.table_outer_top() >= 410.0, "Table must clear the table-adjacent objective stack at design height %.0f" % design_height)
		_assert(GameConfig.table_outer_bottom() <= design_height - 60.0, "Table must remain inside the lower safe composition at design height %.0f" % design_height)
		_assert(table_height / design_height >= 0.57, "Table must remain the dominant center surface at design height %.0f" % design_height)
		_assert(GameConfig.table_left_at(GameConfig.board_top()) >= 120.0 and GameConfig.table_right_at(GameConfig.board_top()) <= 600.0, "Back rails must stay centered and bounded")
		_assert(GameConfig.table_left_at(GameConfig.board_bottom()) >= 48.0 and GameConfig.table_right_at(GameConfig.board_bottom()) <= 672.0, "Front rails must stay inside horizontal safe margins")
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
	_assert(hud.root_control.find_child("TargetName", true, false) == null, "%s gem names must not exist in the HUD tree" % viewport_size)
	_assert(UiDesignSystemType.COLOR_GLASS_BORDER.b > UiDesignSystemType.COLOR_GLASS_BORDER.g and UiDesignSystemType.COLOR_GLASS_BORDER.r > UiDesignSystemType.COLOR_GLASS_BORDER.g, "%s HUD border must use the amethyst reference palette" % viewport_size)
	_assert(UiDesignSystemType.COLOR_GLASS_WHITE.get_luminance() < 0.35, "%s HUD surfaces must remain dark purple glass" % viewport_size)
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
