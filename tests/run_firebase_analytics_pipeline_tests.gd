extends SceneTree

const GameControllerType = preload("res://scripts/gameplay/game_controller.gd")
const ProgressionSaveServiceType = preload("res://scripts/services/progression_save_service.gd")
const PowerInventoryServiceType = preload("res://scripts/services/power_inventory_service.gd")

var failures: Array[String] = []
var observed_events: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var analytics := root.get_node_or_null("Analytics")
	_assert(analytics != null, "Analytics must be registered as an Autoload")
	if analytics != null:
		analytics.event_requested.connect(_on_event_requested)
		_test_parameter_sanitizing(analytics)
	await _test_live_gameplay_hooks()
	_test_android_bridge_contract()
	if failures.is_empty():
		print("FIREBASE_ANALYTICS_PIPELINE_TESTS: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("FIREBASE_ANALYTICS_PIPELINE_TESTS: FAIL (%d)" % failures.size())
	quit(1)


func _test_parameter_sanitizing(analytics: Node) -> void:
	observed_events.clear()
	analytics.log_event("schema_probe", {"integer_value": 7, "float_value": 1.5, "bool_value": true, "text_value": "ok", "bad_value": []})
	_assert(observed_events.size() == 1, "A valid custom event must reach the service request boundary")
	if observed_events.size() == 1:
		var parameters: Dictionary = observed_events[0].parameters
		_assert(parameters.size() == 4 and not parameters.has("bad_value"), "Only Firebase-compatible primitive parameters may cross the bridge")


func _test_live_gameplay_hooks() -> void:
	var save_snapshot := _backup_save_file()
	observed_events.clear()
	paused = false
	var controller := GameControllerType.new()
	root.add_child(controller)
	await process_frame
	_assert(_event_count("level_start") == 0, "Home/scene setup must not emit level_start before the player starts an attempt")
	controller._on_home_level_intro_requested()
	controller._on_home_play_requested()
	controller._on_home_play_requested()
	_assert(_event_count("level_start") == 1, "START GAME must emit level_start exactly once")
	var start_parameters := _first_parameters("level_start")
	_assert(start_parameters.has("level_number") and start_parameters.has("pattern") and int(start_parameters.get("attempt_number", 0)) == 1, "level_start must include level, pattern, and the true attempt number")

	# Seeded from the configured costs rather than fixed literals so retuning
	# GameConfig.SKIP_LEVEL_COST cannot silently leave this suite red.
	var skip_cost := GameConfig.SKIP_LEVEL_COST
	var seed_coins := skip_cost + 200
	controller.coins = seed_coins
	controller.level_start_coins = seed_coins

	# Switch is a power now, not a coin action. It must spend one owned power
	# and no coins at all; the old -100 behaviour is gone.
	# Seed the inventory explicitly: this suite shares user:// with the powers
	# suite, so relying on the starter grant would make it order-dependent.
	controller.power_state = PowerInventoryServiceType.ensure_state({"counts": {"switch": 2}, "granted_starter": true})
	var owned_before := PowerInventoryServiceType.count(controller.power_state, PowerInventoryServiceType.SWITCH)
	_assert(owned_before > 0, "The seeded inventory must leave a Switch power available to spend")
	var active_before_switch := controller.get_active_piece()
	_assert(active_before_switch != null, "A fresh READY_TO_AIM state must have a spawned active launcher piece")
	var prior_active_level := active_before_switch.level if active_before_switch != null else -1
	controller._on_power_requested(PowerInventoryServiceType.SWITCH)
	controller._on_power_requested(PowerInventoryServiceType.SWITCH)
	# Powers apply on the cinematic impact beat now, so the sequence has to be
	# advanced before the result can be observed.
	if controller.power_cinematic != null and controller.power_cinematic.is_playing():
		controller.power_cinematic.skip_to_impact()
		for _step in range(10):
			controller.power_cinematic._process(1.0 / 60.0)
			if not controller.power_cinematic.is_playing():
				break
	_assert(controller.coins == seed_coins and controller.level_start_coins == seed_coins,
		"Switch must no longer deduct coins now that it is an owned power")
	_assert(PowerInventoryServiceType.count(controller.power_state, PowerInventoryServiceType.SWITCH) == owned_before - 1,
		"Double taps must spend exactly one Switch power")
	var active_after_switch := controller.get_active_piece()
	_assert(active_after_switch != null and active_after_switch.id == active_before_switch.id, "Switch must change the current launcher piece in place, not replace or remove it")
	_assert(active_after_switch.level != prior_active_level and (controller.level_config.get("launcher_sequence", []) as Array).has(active_after_switch.level), "Switch must select a different tier from the existing weighted launcher sequence for the current gem")
	_assert(active_after_switch.radius == GameConfig.gem_collision_radius(active_after_switch.level) * active_after_switch.perspective_scale, "Switch must keep the current gem's collision radius consistent with its new tier")
	_assert(_event_count("coin_spent") == 0, "Spending a power must emit no coin_spent event")
	_assert(_event_count("power_used") == 1 and String(_first_parameters("power_used").get("power", "")) == PowerInventoryServiceType.SWITCH,
		"Double taps must spend once and emit one contextual power_used event")
	var persisted_powers := PowerInventoryServiceType.ensure_state(ProgressionSaveServiceType.load_progress().get("power_state", {}) as Dictionary)
	_assert(PowerInventoryServiceType.count(persisted_powers, PowerInventoryServiceType.SWITCH) == owned_before - 1,
		"Spending a power must persist the decremented inventory immediately")
	_assert(int(ProgressionSaveServiceType.load_progress().total_coins) == seed_coins, "Spending a power must leave the banked balance untouched")

	_assert(controller.gameplay_ui.root_control.find_child("SkipSinkButton", true, false) == null, "The live board must not expose a Skip Level button")
	_assert(controller.gameplay_ui.pause_skip_button != null and controller.gameplay_ui.pause_skip_button.tooltip_text.contains(str(skip_cost)), "Pause must expose the centrally configured skip cost")
	_assert(controller.home_overlay.intro_skip_button != null and controller.home_overlay.intro_skip_button.text.contains("%d COINS" % skip_cost), "Level Ready must expose the centrally configured skip cost")
	_assert(controller.result_overlay.skip_button != null, "The Failed overlay must own a dedicated Skip Level action")
	var level_before_skip := controller.level_number
	controller._on_skip_level_requested()
	controller._on_skip_level_requested()
	_assert(controller.level_number == level_before_skip + 1, "Skip Level must advance exactly one level per confirmed request, ignoring the double tap")
	_assert(controller.coins == seed_coins - skip_cost and controller.level_start_coins == seed_coins - skip_cost, "Skip Level must atomically deduct its configured cost from displayed and banked coins")
	_assert(_event_count("level_skipped") == 1, "Double taps must spend once and emit one level_skipped event")
	_assert(_event_count("coin_spent") == 1 and String(_first_parameters("coin_spent").get("reason", "")) == "skip_level", "Skip Level must be the only coin_spent event now that Switch costs a power")
	_assert(_event_count("level_complete") == 0 and _event_count("level_start") == 1, "Skip Level must never emit level_complete and must not itself emit a new level_start")
	_assert(int(ProgressionSaveServiceType.load_progress().total_coins) == seed_coins - skip_cost, "Skip Level must persist the resulting banked balance and advanced level atomically")

	for tier_value in [6, 7, 8]:
		var tier: int = int(tier_value)
		var event_id: int = 1000 + tier
		var confirmed_events: Array[Dictionary] = [{
			"first_position": Vector2(300.0, 600.0),
			"second_position": Vector2(360.0, 600.0),
			"midpoint": Vector2(330.0, 600.0),
			"level": tier,
			"depth": 0,
			"source_ids": [event_id - 2, event_id - 1],
			"result_id": event_id,
		}]
		controller._apply_confirmed_merge_events(confirmed_events)
	_assert(_event_count("merge") == 3, "Each accepted confirmed merge result must emit one merge event")
	_assert(_event_count("target_complete") == 3, "Each completed target must emit target_complete exactly once")
	_assert(_event_count("level_complete") == 1, "The final target must emit level_complete exactly once")
	_assert(_event_count("coin_earned") == 3, "Each confirmed target reward must emit one bounded coin_earned event")
	var merge_parameters := _first_parameters("merge")
	_assert(merge_parameters.has("level_number") and merge_parameters.has("merged_gem_id") and merge_parameters.has("merged_gem_type") and bool(merge_parameters.get("involved_target", false)), "merge must carry level, gem identity/type, and target involvement")
	var target_parameters := _first_parameters("target_complete")
	_assert(target_parameters.has("target_index") and target_parameters.has("target_gem_id") and target_parameters.has("target_gem_type"), "target_complete must carry target index and gem identity/type")
	controller._qualify_win_if_target_complete()
	_assert(_event_count("level_complete") == 1, "Repeated win qualification must not duplicate level_complete")
	paused = false
	controller.queue_free()
	await process_frame

	observed_events.clear()
	var failed_controller := GameControllerType.new()
	root.add_child(failed_controller)
	await process_frame
	failed_controller._on_home_level_intro_requested()
	failed_controller._on_home_play_requested()
	failed_controller._trigger_failure()
	failed_controller._trigger_failure()
	_assert(_event_count("level_fail") == 1, "A genuine danger failure must emit level_fail exactly once")
	_assert(String(_first_parameters("level_fail").get("fail_reason", "")) == "danger_line", "level_fail must include its authoritative reason")
	failed_controller._on_restart_requested()
	_assert(_event_count("retry") == 1, "A real retry must emit retry exactly once")
	_assert(_event_count("level_start") == 2, "A playable retry must emit one new level_start")
	failed_controller.won = true
	failed_controller.level_reward_for_completion = 200
	failed_controller.ad_manager = null
	failed_controller._on_double_coins_requested()
	_assert(_event_count("rewarded_ad_requested") == 1 and _event_count("rewarded_ad_failed") == 1, "A rewarded intent must emit requested then failed when the manager is unavailable")
	failed_controller.completion_action_pending = false
	failed_controller.completion_transition_consumed = false
	failed_controller.completion_reward_resolved = true
	failed_controller.level_number = 2
	failed_controller._begin_completion_transition("play")
	_assert(_event_count("interstitial_requested") == 1 and _event_count("interstitial_failed") == 1, "A scheduled interstitial intent must emit requested then failed when the manager is unavailable")
	paused = false
	failed_controller.queue_free()
	await process_frame
	_restore_save_file(save_snapshot)


func _test_android_bridge_contract() -> void:
	var project_source := FileAccess.get_file_as_string("res://project.godot")
	var export_source := FileAccess.get_file_as_string("res://export_presets.cfg")
	var manifest_source := FileAccess.get_file_as_string("res://android/build/src/main/AndroidManifest.xml")
	var java_source := FileAccess.get_file_as_string("res://android/build/src/main/java/com/owais/majestygems/analytics/FirebaseAnalyticsPlugin.java")
	_assert(project_source.contains("Analytics=\"*res://scripts/services/analytics_service.gd\""), "project.godot must register the Analytics Autoload")
	_assert(export_source.contains("addons/at-icons/*") and export_source.contains("@icons picker.html"), "The @icons editor addon and picker must stay excluded from Android exports")
	_assert(manifest_source.contains("org.godotengine.plugin.v2.FirebaseAnalytics") and manifest_source.contains("FirebaseAnalyticsPlugin"), "The Android manifest must register the Firebase v2 Godot plugin")
	_assert(java_source.contains("@UsedByGodot") and java_source.contains("List<String> getPluginMethods()") and java_source.contains("Collections.singletonList(\"logEvent\")") and java_source.contains("boolean logEvent(") and java_source.contains("firebaseAnalytics.logEvent(eventName, parameters)"), "The native bridge must explicitly register, expose, and forward the acknowledged logEvent method")


func _on_event_requested(event_name: String, parameters: Dictionary) -> void:
	observed_events.append({"name": event_name, "parameters": parameters.duplicate(true)})


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


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


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
