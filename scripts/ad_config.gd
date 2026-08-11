class_name AdConfig
extends RefCounted

## Google-owned Android test units. Debug builds always use these IDs.
const DEBUG_INTERSTITIAL_AD_UNIT_ID := "ca-app-pub-3940256099942544/1033173712"
const DEBUG_REWARDED_AD_UNIT_ID := "ca-app-pub-3940256099942544/5224354917"

## RELEASE CONFIGURATION
## Paste the two production ad-unit IDs between these quotes before exporting a
## release build. Keep production IDs centralized here and nowhere else.
const INTERSTITIAL_AD_UNIT_ID := ""
const REWARDED_AD_UNIT_ID := ""

const INTERSTITIAL_LEVEL_INTERVAL := 2


static func interstitial_ad_unit_id(debug_build: bool) -> String:
	return DEBUG_INTERSTITIAL_AD_UNIT_ID if debug_build else INTERSTITIAL_AD_UNIT_ID.strip_edges()


static func rewarded_ad_unit_id(debug_build: bool) -> String:
	return DEBUG_REWARDED_AD_UNIT_ID if debug_build else REWARDED_AD_UNIT_ID.strip_edges()


static func is_configured_for_current_build() -> bool:
	return not current_interstitial_ad_unit_id().is_empty() or not current_rewarded_ad_unit_id().is_empty()


static func current_interstitial_ad_unit_id() -> String:
	return interstitial_ad_unit_id(OS.is_debug_build())


static func current_rewarded_ad_unit_id() -> String:
	return rewarded_ad_unit_id(OS.is_debug_build())


static func should_show_interstitial_after_level(completed_level: int) -> bool:
	return completed_level > 0 and completed_level % INTERSTITIAL_LEVEL_INTERVAL == 0
