extends Node
## Lightweight Firebase Analytics bridge. All callers are safe on desktop and
## in tests: the Android plugin is optional and analytics never owns gameplay.

signal event_requested(event_name: String, parameters: Dictionary)

const NATIVE_SINGLETON := "FirebaseAnalytics"
const LOG_PREFIX := "[Analytics]"

var _bridge_checked := false
var _bridge_available := false


func _ready() -> void:
	print("%s Service available" % LOG_PREFIX)
	_refresh_bridge_state()


func log_event(event_name: String, parameters: Dictionary = {}) -> bool:
	print("%s %s requested" % [LOG_PREFIX, event_name])
	if not _is_valid_event_name(event_name):
		push_warning("%s Rejected invalid event name: %s" % [LOG_PREFIX, event_name])
		return false
	var safe_parameters := _firebase_parameters(parameters)
	event_requested.emit(event_name, safe_parameters.duplicate(true))
	var bridge = _native_bridge()
	if bridge == null:
		print("%s Native Firebase plugin unavailable; skipped %s" % [LOG_PREFIX, event_name])
		return false
	var accepted := bool(bridge.call("logEvent", event_name, JSON.stringify(safe_parameters)))
	if accepted:
		print("%s Sent %s" % [LOG_PREFIX, event_name])
	else:
		push_warning("%s Native bridge rejected %s" % [LOG_PREFIX, event_name])
	return accepted


func _native_bridge():
	_refresh_bridge_state()
	if not _bridge_available:
		return null
	print("%s Native Firebase plugin available" % LOG_PREFIX)
	var bridge = Engine.get_singleton(NATIVE_SINGLETON)
	if bridge == null or not bridge.has_method("logEvent"):
		_bridge_available = false
		push_warning("%s Firebase singleton exists but logEvent is unavailable" % LOG_PREFIX)
		return null
	return bridge


func _refresh_bridge_state() -> void:
	var available := Engine.has_singleton(NATIVE_SINGLETON)
	if not _bridge_checked or available != _bridge_available:
		print("%s Native Firebase plugin %s" % [LOG_PREFIX, "available" if available else "unavailable"])
	_bridge_checked = true
	_bridge_available = available


func _firebase_parameters(parameters: Dictionary) -> Dictionary:
	var sanitized := {}
	for raw_key in parameters:
		var key := String(raw_key)
		if not _is_valid_parameter_name(key):
			push_warning("%s Dropped invalid parameter name: %s" % [LOG_PREFIX, key])
			continue
		var value = parameters[raw_key]
		if value is bool or value is int or value is float or value is String or value is StringName:
			sanitized[key] = String(value) if value is StringName else value
		else:
			push_warning("%s Dropped non-primitive parameter: %s" % [LOG_PREFIX, key])
	return sanitized


func _is_valid_event_name(value: String) -> bool:
	return _is_valid_firebase_name(value, 40)


func _is_valid_parameter_name(value: String) -> bool:
	return _is_valid_firebase_name(value, 40)


func _is_valid_firebase_name(value: String, maximum_length: int) -> bool:
	if value.is_empty() or value.length() > maximum_length:
		return false
	var first := value.unicode_at(0)
	if not _is_ascii_letter(first):
		return false
	for index in range(1, value.length()):
		var character := value.unicode_at(index)
		if not _is_ascii_letter(character) and not (character >= 48 and character <= 57) and character != 95:
			return false
	return true


func _is_ascii_letter(character: int) -> bool:
	return (character >= 65 and character <= 90) or (character >= 97 and character <= 122)


func level_start(level: int) -> void:
	log_event("level_start", {"level_number": level})


func level_complete(level: int, score: int) -> void:
	log_event("level_complete", {"level_number": level, "score": score})


func level_fail(level: int, score: int) -> void:
	log_event("level_fail", {"level_number": level, "score": score})


func target_complete(level: int, target_index: int, target_tier: int) -> void:
	log_event("target_complete", {"level": level, "target_index": target_index, "target_tier": target_tier})


func merge(result_level: int, depth: int) -> void:
	log_event("merge", {"result_level": result_level, "depth": depth})


func rewarded_ad_shown() -> void:
	log_event("rewarded_ad_shown")


func rewarded_ad_completed() -> void:
	log_event("rewarded_ad_completed")


func interstitial_shown() -> void:
	log_event("interstitial_shown")
