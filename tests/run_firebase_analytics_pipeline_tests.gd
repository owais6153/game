extends SceneTree

const GameControllerType = preload("res://scripts/gameplay/game_controller.gd")

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
	observed_events.clear()
	paused = false
	var controller := GameControllerType.new()
	root.add_child(controller)
	await process_frame
	controller._on_home_level_intro_requested()
	controller._on_home_play_requested()
	controller._on_home_play_requested()
	_assert(_event_count("level_start") == 1, "START GAME must emit level_start exactly once")
	var start_parameters := _first_parameters("level_start")
	_assert(start_parameters.has("level_number") and start_parameters.has("pattern"), "level_start must include level_number and the generated pattern")

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
	_assert(_event_count("level_start") == 2, "A playable retry must emit one new level_start")
	paused = false
	failed_controller.queue_free()
	await process_frame


func _test_android_bridge_contract() -> void:
	var project_source := FileAccess.get_file_as_string("res://project.godot")
	var manifest_source := FileAccess.get_file_as_string("res://android/build/src/main/AndroidManifest.xml")
	var java_source := FileAccess.get_file_as_string("res://android/build/src/main/java/com/owais/majestygems/analytics/FirebaseAnalyticsPlugin.java")
	_assert(project_source.contains("Analytics=\"*res://scripts/services/analytics_service.gd\""), "project.godot must register the Analytics Autoload")
	_assert(manifest_source.contains("org.godotengine.plugin.v2.FirebaseAnalytics") and manifest_source.contains("FirebaseAnalyticsPlugin"), "The Android manifest must register the Firebase v2 Godot plugin")
	_assert(java_source.contains("@UsedByGodot") and java_source.contains("boolean logEvent(") and java_source.contains("firebaseAnalytics.logEvent(eventName, parameters)"), "The native bridge must expose and forward the acknowledged logEvent method")


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
