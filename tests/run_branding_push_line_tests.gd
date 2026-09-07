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

## The shape contract every launcher derivative has to meet.
##
## Repointed from the v4/v5 derivatives, which had been superseded twice over
## but were still loaded here - so this suite was the only thing keeping four
## dead files in the repository, and it was asserting the dimensions of art the
## game had not shipped since two brand refreshes ago.
##
## The two sources are versioned separately because they are replaced
## separately: the transparent mark is still v6, the illustrated square is v7.
func _test_brand_assets() -> void:
	var logo := (load("res://assets/runtime/ui/majestic_gems_logo_v6.png") as Texture2D).get_image()
	var legacy_icon := (load("res://assets/runtime/ui/majestic_gems_app_icon_192_v7.png") as Texture2D).get_image()
	var adaptive_foreground := (load("res://assets/runtime/ui/majestic_gems_adaptive_foreground_v7.png") as Texture2D).get_image()
	var adaptive_background := (load("res://assets/runtime/ui/majestic_gems_adaptive_background_v7.png") as Texture2D).get_image()
	var opaque_source := Image.load_from_file(ProjectSettings.globalize_path("res://assets/logo/majestic_gems_logo_with_background_source_v7.png"))
	# Trimmed to its used rect and fitted to a 768 longest side, so the exact
	# height follows the mark's own aspect rather than being chosen.
	_assert(logo.get_size() == Vector2i(768, 765), "Transparent Home logo v6 must remain unchanged")
	_assert(logo.get_pixel(0, 0).a == 0.0, "The Home logo must stay transparent, or it will show as a square over the garden art")
	_assert(opaque_source != null and opaque_source.get_size() == Vector2i(1254, 1254) and opaque_source.get_pixel(0, 0).a == 1.0,
		"Supplied opaque background logo must be preserved in the semantic source folder")
	_assert(not FileAccess.file_exists("res://assets/logo/majestic_gems_logo_presentation_reference_v3.png"), "Retired opaque presentation source must be removed")
	_assert(legacy_icon.get_size() == Vector2i(192, 192), "Legacy launcher icon must be 192x192")
	_assert(legacy_icon.get_pixel(0, 0).a == 1.0, "The launcher icon is a fixed square with nothing to composite against, so it must be opaque")
	_assert(adaptive_foreground.get_size() == Vector2i(432, 432), "Adaptive foreground must be 432x432")
	_assert(adaptive_background.get_size() == Vector2i(432, 432), "Adaptive background must be 432x432")
	# The illustration is the whole icon: it is the background layer, and the
	# foreground is deliberately empty so the icon looks the same on every
	# Android version.
	_assert(adaptive_foreground.get_used_rect().size == Vector2i(0, 0), "Adaptive foreground must stay empty - the illustration is the background layer")
	_assert(adaptive_background.get_pixel(0, 0).a == 1.0 and adaptive_background.get_pixel(431, 431).a == 1.0,
		"Adaptive background must be fully opaque to its corners, or a launcher mask will cut into transparency")

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
