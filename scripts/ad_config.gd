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
const PRIVACY_POLICY_URL := "https://teckvertexlabs.vercel.app/privacy/majestic-gems"

## UMP TEST CONFIGURATION (debug builds only)
## 0 = disabled/real geography, 1 = force EEA, 2 = force not-EEA.
## Keep 0 for normal development. For a physical device, add the hashed test
## device ID printed by UMP before selecting 1 or 2. Release builds ignore both
## values even if a developer forgets to restore them.
const UMP_DEBUG_GEOGRAPHY_DISABLED := 0
const UMP_DEBUG_GEOGRAPHY_EEA := 1
const UMP_DEBUG_GEOGRAPHY_NOT_EEA := 2
const UMP_DEBUG_GEOGRAPHY := UMP_DEBUG_GEOGRAPHY_DISABLED
const UMP_TEST_DEVICE_HASHED_IDS: Array[String] = []


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


static func ump_debug_geography_for_current_build() -> int:
	return ump_debug_geography(OS.is_debug_build())


static func ump_debug_geography(debug_build: bool) -> int:
	if not debug_build:
		return UMP_DEBUG_GEOGRAPHY_DISABLED
	return clampi(
		UMP_DEBUG_GEOGRAPHY,
		UMP_DEBUG_GEOGRAPHY_DISABLED,
		UMP_DEBUG_GEOGRAPHY_NOT_EEA
	)


static func ump_test_device_hashed_ids_for_current_build() -> Array[String]:
	return ump_test_device_hashed_ids(OS.is_debug_build())


static func ump_test_device_hashed_ids(debug_build: bool) -> Array[String]:
	if not debug_build:
		return []
	return UMP_TEST_DEVICE_HASHED_IDS.duplicate()
