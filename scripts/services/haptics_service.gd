class_name HapticsService
extends RefCounted

## Android feedback boundary. It intentionally records successful requests so
## headless/editor validation can prove routing without a physical vibrator.
var enabled := true
var emitted_events: Array[String] = []
var allow_platform_vibration := true

func emit_event(event_name: String) -> bool:
	if not enabled:
		return false
	var mapping: Dictionary = GameConfig.HAPTICS_BY_EVENT.get(event_name, {})
	if mapping.is_empty():
		return false
	emitted_events.append(event_name)
	if allow_platform_vibration and OS.has_feature("mobile"):
		Input.vibrate_handheld(int(mapping.duration_ms), float(mapping.amplitude))
	return true

func clear_trace() -> void:
	emitted_events.clear()
