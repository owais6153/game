extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_brand_assets()
	_test_aim_guide_drag_path()
	if failures.is_empty():
		print("BRANDING_PUSH_LINE_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("BRANDING_PUSH_LINE_TESTS: FAIL (%d)" % failures.size())
	quit(1)

func _test_brand_assets() -> void:
	var logo := (load("res://assets/runtime/ui/majestic_gems_logo_v1.png") as Texture2D).get_image()
	var legacy_icon := (load("res://assets/runtime/ui/majestic_gems_app_icon_192_v2.png") as Texture2D).get_image()
	var adaptive_foreground := (load("res://assets/runtime/ui/majestic_gems_adaptive_foreground_v2.png") as Texture2D).get_image()
	var adaptive_background := (load("res://assets/runtime/ui/majestic_gems_adaptive_background_v2.png") as Texture2D).get_image()
	_assert(logo.get_size() == Vector2i(1536, 1024), "Home logo must retain the complete supplied 1536x1024 canvas")
	_assert(legacy_icon.get_size() == Vector2i(192, 192), "Legacy launcher icon must be 192x192")
	_assert(adaptive_foreground.get_size() == Vector2i(432, 432), "Adaptive foreground must be 432x432")
	_assert(adaptive_background.get_size() == Vector2i(432, 432), "Adaptive background must be 432x432")
	var used := adaptive_foreground.get_used_rect()
	_assert(used.size.x <= 288 and used.size.y <= 288, "Adaptive foreground artwork must remain inside the mask-safe padded area")
	_assert(adaptive_foreground.get_pixel(0, 0).a == 0.0 and adaptive_foreground.get_pixel(431, 431).a == 0.0, "Adaptive foreground corners must stay transparent")

func _test_aim_guide_drag_path() -> void:
	var active_position := Vector2(GameConfig.table_center_x(), GameConfig.launch_y())
	var active_radius := GameConfig.gem_collision_radius(1)
	var lane_top: float = GameConfig.vertical_lane_top_y(active_position.x, 5.0)
	var guide_midpoint := Vector2(active_position.x, (lane_top + 10.0 + active_position.y - active_radius - 10.0) * 0.5)
	_assert(GameConfig.aim_guide_contains(guide_midpoint, active_position, active_radius), "Visible push line midpoint must be draggable")
	_assert(not GameConfig.aim_guide_contains(guide_midpoint + Vector2(GameConfig.AIM_GUIDE_TOUCH_HALF_WIDTH + 1.0, 0.0), active_position, active_radius), "Push-line hit area must stay horizontally bounded")
	_assert(not GameConfig.aim_guide_contains(Vector2(active_position.x, lane_top - 1.0), active_position, active_radius), "Touch above the visible push line must not start a drag")
	var requested_x := GameConfig.table_right_at(active_position.y) + 100.0
	var clamped_x := GameConfig.launcher_drag_x(requested_x, active_position.y, active_radius)
	_assert(is_equal_approx(clamped_x, GameConfig.table_right_at(active_position.y) - active_radius), "Push-line drag must reuse the authoritative gem drag clamp")

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
