extends SceneTree

## Coverage for the 1.0.17 defect fixes and the analytics integrity rules.
##
## Three areas, all of them things that were wrong in production or would be
## easy to get wrong again:
##
##  - the power shop's coin balance, which could show more than the economy
##    would spend and refuse a Buy without saying anything;
##  - the shooter drag zone, which only responded on the gem itself;
##  - the analytics contract, where a duplicated or premature event silently
##    corrupts every funnel built on it.

const GameControllerType = preload("res://scripts/gameplay/game_controller.gd")
const ProgressionSaveServiceType = preload("res://scripts/services/progression_save_service.gd")
const PowerInventoryServiceType = preload("res://scripts/services/power_inventory_service.gd")
const PowerShopOverlayType = preload("res://scripts/ui/power_shop_overlay_layer.gd")
const GameConfigType = preload("res://scripts/core/game_config.gd")

var failures: Array[String] = []
var observed_events: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var analytics := root.get_node_or_null("Analytics")
	if analytics != null:
		analytics.event_requested.connect(_on_event_requested)
	_test_drag_zone_geometry()
	await _test_shop_balance_and_purchases()
	await _test_input_drag_area()
	await _test_analytics_integrity()
	if failures.is_empty():
		print("SHOP_INPUT_ANALYTICS_V1_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("SHOP_INPUT_ANALYTICS_V1_TESTS: FAIL (%d)" % failures.size())
	quit(1)


# --- Input geometry ---------------------------------------------------------

## Pure geometry, checked without a controller so a failure here points at the
## zone definition rather than at input plumbing.
func _test_drag_zone_geometry() -> void:
	var danger_y := GameConfigType.danger_line_y()
	var centre_x := GameConfigType.table_center_x()
	# The reported bug: swiping the felt below the line did nothing.
	_assert(GameConfigType.shooter_drag_zone_contains(Vector2(centre_x, danger_y + 40.0)),
		"a press just below the danger line must start a shooter drag")
	_assert(GameConfigType.shooter_drag_zone_contains(Vector2(centre_x, GameConfigType.launch_y())),
		"a press at the launcher height must start a shooter drag")
	# Above the line stays available to the board and to power targeting.
	_assert(not GameConfigType.shooter_drag_zone_contains(Vector2(centre_x, danger_y - 60.0)),
		"a press above the danger line must not start a shooter drag")
	# Near the rails: the zone follows the sloped rails plus a thumb allowance.
	var probe_y := danger_y + 30.0
	var left := GameConfigType.table_left_at(probe_y)
	var right := GameConfigType.table_right_at(probe_y)
	_assert(GameConfigType.shooter_drag_zone_contains(Vector2(left + 6.0, probe_y)),
		"a press just inside the left rail must start a drag")
	_assert(GameConfigType.shooter_drag_zone_contains(Vector2(right - 6.0, probe_y)),
		"a press just inside the right rail must start a drag")
	_assert(not GameConfigType.shooter_drag_zone_contains(Vector2(left - 400.0, probe_y)),
		"a press far outside the table must not start a drag")


# --- Shop -------------------------------------------------------------------

func _test_shop_balance_and_purchases() -> void:
	var snapshot := _backup_save_file()
	var controller = await _start_controller()
	var power := PowerInventoryServiceType.ALL[0]
	var price := PowerInventoryServiceType.purchase_cost(power)

	# The production defect: the display balance carried unresolved in-attempt
	# earnings while only the banked balance could be spent.
	controller.level_start_coins = price - 1
	controller.coins = price + 5000
	_assert(controller.spendable_coins() == price - 1,
		"the authoritative balance must be the banked one, not the display one")

	controller._on_power_shop_requested()
	_assert(controller.power_shop.is_open(), "the shop must open")
	_assert(controller.power_shop._coins == controller.spendable_coins(),
		"the shop must open showing the authoritative balance, not the display balance")

	# A Buy the bank cannot cover must be refused *and say so*.
	observed_events.clear()
	var owned_before: int = PowerInventoryServiceType.count(controller.power_state, power)
	controller._on_power_purchase_requested(power)
	_assert(PowerInventoryServiceType.count(controller.power_state, power) == owned_before,
		"an unaffordable purchase must not grant the power")
	_assert(_event_count("power_purchase_attempt") == 1, "a refused Buy must still report the attempt")
	_assert(_event_count("power_purchase_failed") == 1, "a refused Buy must report the failure")
	_assert(_event_count("power_purchase_success") == 0, "a refused Buy must not report success")
	_assert(String(_first_parameters("power_purchase_failed").get("failure_reason", "")) == "insufficient_coins",
		"the failure must name its reason")
	_assert(controller.power_shop.feedback_label != null and controller.power_shop.feedback_label.visible,
		"a refused Buy must show the player a reason rather than doing nothing")

	# Coins changing while the popup is open must reach the popup immediately.
	controller._credit_banked_coins(price * 4)
	_assert(controller.power_shop._coins == controller.spendable_coins(),
		"an open shop must refresh when the balance changes underneath it")

	# Bring the two balances into step before measuring the purchase, so the
	# assertions below describe the purchase rather than the artificial
	# divergence this test set up above to reproduce the original defect.
	controller.coins = controller.level_start_coins

	# An affordable purchase moves coins and inventory together.
	observed_events.clear()
	var balance_before: int = controller.spendable_coins()
	owned_before = PowerInventoryServiceType.count(controller.power_state, power)
	controller._on_power_purchase_requested(power)
	_assert(PowerInventoryServiceType.count(controller.power_state, power) == owned_before + 1,
		"an affordable purchase must grant exactly one power")
	_assert(controller.spendable_coins() == balance_before - price,
		"an affordable purchase must debit exactly the price")
	_assert(controller.coins == controller.spendable_coins(),
		"both balances must stay in step once there are no unresolved earnings")
	_assert(_event_count("power_purchase_success") == 1, "a completed purchase must report success exactly once")
	_assert(_event_count("power_purchase_failed") == 0, "a completed purchase must not also report failure")
	_assert(controller.power_shop._coins == controller.spendable_coins(),
		"the shop must show the new balance immediately after a purchase")
	_assert(int(controller.power_shop._counts.get(power, 0)) == owned_before + 1,
		"the shop must show the new inventory immediately after a purchase")

	# A double tap must buy once. The lock is released synchronously, so this
	# reproduces the re-entrant case rather than two sequential taps.
	observed_events.clear()
	balance_before = controller.spendable_coins()
	owned_before = PowerInventoryServiceType.count(controller.power_state, power)
	controller.power_purchase_locked = true
	controller._on_power_purchase_requested(power)
	controller.power_purchase_locked = false
	_assert(PowerInventoryServiceType.count(controller.power_state, power) == owned_before,
		"a re-entrant Buy must not purchase a second power")
	_assert(controller.spendable_coins() == balance_before,
		"a re-entrant Buy must not debit twice")
	_assert(_event_count("power_purchase_success") == 0,
		"a re-entrant Buy must not report a second success")

	_free(controller)
	_restore_save_file(snapshot)


# --- Input ------------------------------------------------------------------

func _test_input_drag_area() -> void:
	var snapshot := _backup_save_file()
	var controller = await _start_controller()
	controller._on_home_level_intro_requested()
	controller._on_level_chosen(controller.highest_level)
	controller._on_home_play_requested()
	await process_frame
	await process_frame

	var active = controller.get_active_piece()
	if active == null:
		_assert(false, "a launcher gem must be available to drag")
		_free(controller)
		_restore_save_file(snapshot)
		return

	# Directly on the gem: the behaviour that already worked. Cleared directly
	# rather than through a release, because releasing launches the gem and would
	# leave the later checks with no settled launcher to drag.
	controller.dragging = false
	controller._handle_pointer(active.position, true)
	_assert(controller.dragging, "pressing the shooter gem must start a drag")
	controller.dragging = false

	# Beside the gem, below the danger line: the reported bug.
	var beside := Vector2(active.position.x - 220.0, GameConfigType.danger_line_y() + 50.0)
	controller.dragging = false
	controller._handle_pointer(beside, true)
	_assert(controller.dragging,
		"pressing the table beside the shooter must start a drag")

	# The gem follows horizontally and stays inside the rails.
	controller.move_active_to(beside.x)
	var expected := GameConfigType.launcher_drag_x(beside.x, active.position.y, active.radius)
	_assert(is_equal_approx(active.position.x, expected),
		"the shooter must follow the pointer horizontally")

	# Dragging far past the rail must clamp, not escape the table.
	controller.move_active_to(-5000.0)
	_assert(active.position.x >= GameConfigType.table_left_at(active.position.y),
		"the shooter must clamp inside the left rail")
	controller.move_active_to(5000.0)
	_assert(active.position.x <= GameConfigType.table_right_at(active.position.y),
		"the shooter must clamp inside the right rail")
	controller.dragging = false

	# Above the danger line must not grab the shooter, so board interaction and
	# power targeting keep their presses.
	#
	# Probed well away from the launcher's x, because the aim guide is a vertical
	# strip that legitimately extends above the line directly over the gem and
	# has always been grabbable. That behaviour predates the drag-zone widening
	# and is deliberately preserved; what must stay free is the rest of the board.
	var above_board := Vector2(
		active.position.x + GameConfigType.AIM_GUIDE_TOUCH_HALF_WIDTH + 120.0,
		GameConfigType.danger_line_y() - 120.0)
	controller.dragging = false
	controller._handle_pointer(above_board, true)
	_assert(not controller.dragging,
		"pressing the board above the danger line must not start a shooter drag")

	# A popup owns the screen. The overlay's own full-rect dim consumes presses
	# before _unhandled_input, and the controller must not grab one either.
	controller.dragging = false
	controller._on_power_shop_requested()
	_assert(controller.power_shop.is_open(), "the shop must open for the popup check")
	_assert(controller.power_shop.root.mouse_filter == Control.MOUSE_FILTER_STOP,
		"an open popup must consume presses before they reach the board")
	controller.power_shop.close()

	_free(controller)
	_restore_save_file(snapshot)


# --- Analytics integrity ----------------------------------------------------

func _test_analytics_integrity() -> void:
	var snapshot := _backup_save_file()
	observed_events.clear()
	var controller = await _start_controller()

	controller._on_home_level_intro_requested()
	controller._on_level_chosen(controller.highest_level)
	controller._on_home_play_requested()
	# Re-entering must not restart the attempt's reporting.
	controller._on_home_play_requested()
	controller._emit_level_start_analytics_once()
	_assert(_event_count("level_start") == 1, "level_start must fire exactly once per attempt")

	var start_parameters := _first_parameters("level_start")
	for key in ["level_template_id", "layout_id", "difficulty_band", "queue_band", "target_structure", "generator_version"]:
		_assert(start_parameters.has(key), "level_start must carry the stable identifier %s" % key)
	_assert(start_parameters.size() <= 25,
		"level_start carries %d parameters; GA4 accepts 25" % start_parameters.size())

	# Aggregates must reflect real play, and an attempt-ending event must carry
	# them exactly once.
	controller.attempt_analytics.record_shot()
	controller.attempt_analytics.record_merge(0)
	controller.attempt_analytics.record_shot()
	controller.attempt_analytics.record_merge(0)
	controller.attempt_analytics.record_merge(2)
	var summary: Dictionary = controller.attempt_analytics.summary()
	_assert(int(summary.shots_used) == 2, "the aggregate must count every shot")
	_assert(int(summary.total_merges) == 3, "the aggregate must count every merge")
	_assert(int(summary.total_chains) == 1, "a depth-2 merge is one chain")
	_assert(int(summary.max_chain_depth) == 2, "the aggregate must track the deepest chain")
	_assert(int(summary.combo_2_count) == 1, "a depth-2 merge is one combo 2")
	_assert(int(summary.shot_merge_percent) == 100, "both shots merged, so the rate is 100%")

	# Failure fires once, and a later abandon must not double-count it.
	observed_events.clear()
	controller._trigger_failure("danger_line")
	controller._trigger_failure("danger_line")
	_assert(_event_count("level_fail") == 1, "level_fail must fire exactly once per attempt")
	var fail_parameters := _first_parameters("level_fail")
	_assert(fail_parameters.has("shots_used") and fail_parameters.has("total_merges"),
		"level_fail must carry the attempt aggregates")
	_assert(fail_parameters.size() <= 25,
		"level_fail carries %d parameters; GA4 accepts 25" % fail_parameters.size())
	controller._emit_level_abandon_if_in_progress("home")
	_assert(_event_count("level_abandon") == 0,
		"a failed attempt must not also report an abandon")

	_free(controller)
	_restore_save_file(snapshot)


# --- Harness ----------------------------------------------------------------

func _start_controller():
	paused = false
	var controller := GameControllerType.new()
	root.add_child(controller)
	await process_frame
	return controller


func _free(controller) -> void:
	if is_instance_valid(controller):
		controller.queue_free()


func _on_event_requested(event_name: String, parameters: Dictionary) -> void:
	observed_events.append({"name": event_name, "parameters": parameters})


func _event_count(event_name: String) -> int:
	var count := 0
	for event in observed_events:
		if String(event.name) == event_name:
			count += 1
	return count


func _first_parameters(event_name: String) -> Dictionary:
	for event in observed_events:
		if String(event.name) == event_name:
			return event.parameters as Dictionary
	return {}


func _backup_save_file() -> Dictionary:
	var path := ProjectSettings.globalize_path(ProgressionSaveServiceType.SAVE_PATH)
	if not FileAccess.file_exists(path):
		return {"existed": false, "bytes": PackedByteArray()}
	var file := FileAccess.open(path, FileAccess.READ)
	return {"existed": true, "bytes": file.get_buffer(file.get_length())}


func _restore_save_file(snapshot: Dictionary) -> void:
	var path := ProjectSettings.globalize_path(ProgressionSaveServiceType.SAVE_PATH)
	if not bool(snapshot.get("existed", false)):
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(snapshot.get("bytes", PackedByteArray()))


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
