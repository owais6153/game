# AdMob Integration v1 Report

Date: 2026-08-11 (Asia/Karachi)

## Scope and implementation

- Plugin: Poing Studios Godot AdMob `v5.0.0`, GDScript API, Android Gradle package installed under `addons/admob/`.
- Application ID: `project.godot`, `[admob]`, `general/android/app_id` (`ca-app-pub-4605895178658062~1516881747`).
- Runtime owner: `scripts/ad_manager.gd`, registered as `/root/AdManager` in `project.godot`.
- Unit/cadence configuration: `scripts/ad_config.gd`.
- Controller boundary: `scripts/game_controller.gd`; result presentation: `scripts/result_overlay_layer.gd`.

The manager initializes Mobile Ads once, independently preloads interstitial and rewarded objects, reports readiness, rejects overlapping fullscreen requests, destroys consumed objects, reloads after dismissal/show failure, retries failed loads after 15 seconds, and releases a missing fullscreen callback after a 180-second safety timeout. An unavailable format invokes its completion without blocking progression.

## Ad-unit configuration

Debug Android exports always select Google's published test units:

- Interstitial: `ca-app-pub-3940256099942544/1033173712`
- Rewarded: `ca-app-pub-3940256099942544/5224354917`

Production units are intentionally not invented. Before a release export, paste the real values only into these exact constants in `scripts/ad_config.gd`:

- `INTERSTITIAL_AD_UNIT_ID := ""`
- `REWARDED_AD_UNIT_ID := ""`

An empty release constant makes that format unavailable and fail open. No production ad-unit ID exists elsewhere in the project.

## User flows and safeguards

Interstitials are considered only when Collect/Home leaves a qualified Level Complete state. `AdConfig.should_show_interstitial_after_level()` returns true for completed levels 2, 4, 6, and so on. Failure, Retry, active gameplay, Pause, Settings, launch, collision, merge, and target events do not call the manager.

The completed result shows the confirmed level reward, total coins, Collect, and Double Coins. Collect follows normal progression immediately when no eligible/ready interstitial exists. Double Coins disables concurrent result actions and shows rewarded inventory only when ready. The base reward is never re-awarded; one extra identical amount is persisted only from `OnUserEarnedRewardListener`. The manager's session/reward flag and the controller's bonus flag independently reject duplicate or stale callbacks. Early close, unavailable inventory, and show failure add zero coins and restore Collect.

A rewarded completion on an even level can be followed by that level's scheduled interstitial. This is the direct composition of the two requested policies and remains exactly-once/non-overlapping.

## Validation evidence

- Godot 4.6.3 headless editor import and whole-project script/class parse: PASS, exit 0.
- `ADMOB_INTEGRATION_TESTS: PASS`: debug/release ID routing, 2-level cadence, unavailable fail-open callbacks, initialization/preload, fullscreen duplicate rejection, dismissal/failure completion, reload, confirmed reward exactly once, early close with no reward, result pending/disabled behavior, and failure Retry fallback.
- `BRANDING_PUSH_LINE_TESTS: PASS`: existing branding and launcher input regression marker reached.
- Runner limitation: both `-s` test processes reach PASS, then Godot 4.6.3 on this Windows host exits during teardown with `0xC0000005`; no failed assertion precedes the teardown. The editor parse process exits cleanly.
- APK export/package/signature validation: pending final export.
- Connected-device status: `adb devices -l` did not return within 60 seconds and the orphaned diagnostic process was stopped. Installation, Google-served test-ad rendering, physical close/resume behavior, rewarded video completion, and real-device interstitial cadence are not claimed.

## Delivered build

- APK: pending final export.
- Source commit/tag: pending final milestone commit.
- Delivery tag: `admob-integration-v1` (to be created after validation).

## Limitations and release checklist

This milestone is not a Play Store release configuration because both production ad-unit placeholders are blank and the generated APK is debug-signed. Before release: paste the two production unit IDs in `scripts/ad_config.gd`, create a release-signed export, verify consent/privacy requirements for target regions, and complete the manual device checklist below.

Manual device checklist still required: confirm the Google TEST AD label for both formats; complete one rewarded ad and verify exactly one matching bonus; close one rewarded ad early and verify zero bonus plus usable Collect; complete levels 1-4 and verify interstitials only after 2 and 4; background/resume during each format; confirm no overlapping ad, frozen result input, duplicate coin, or stuck transition; confirm the next ad reloads after each consumption.
