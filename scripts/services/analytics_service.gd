extends Node
## Lightweight Firebase Analytics bridge. All callers are safe on desktop and
## in tests: the Android plugin is optional and analytics never owns gameplay.

const NATIVE_SINGLETON := "FirebaseAnalytics"


func log_event(event_name: String, parameters: Dictionary = {}) -> void:
	if event_name.is_empty() or not Engine.has_singleton(NATIVE_SINGLETON):
		return
	var bridge = Engine.get_singleton(NATIVE_SINGLETON)
	if bridge == null or not bridge.has_method("log_event"):
		return
	bridge.log_event(event_name, JSON.stringify(parameters))


func level_start(level: int) -> void:
	log_event("level_start", {"level": level})


func level_complete(level: int, score: int) -> void:
	log_event("level_complete", {"level": level, "score": score})


func level_fail(level: int, score: int) -> void:
	log_event("level_fail", {"level": level, "score": score})


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
