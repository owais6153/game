# Android Back, Idle Stability, Settings, and Splash Repair

Date: 2026-08-18

## Reported symptoms and causes

- Android Back was still routed by a gameplay-only callback. On Home it opened the hidden gameplay Pause layer instead of exiting; a second Back could unpause the board behind Home. Back handling now follows the authoritative `AppFlowState`: Home Settings closes first, bare Home exits cleanly, Level Ready returns Home, Playing toggles Pause, and result/reward/ad states ignore the gameplay pause route.
- Exit previously left AdMob retry timers and delayed loader callbacks eligible to repopulate state while the tree was shutting down. `AdManager.shutdown_for_exit()` now invalidates retry/fullscreen generations, clears completion callbacks, blocks new loads, and destroys cached ads before `SceneTree.quit()`.
- The Privacy Policy link used an implicit child-container width. Its margin and center containers now explicitly span the full viewport before centering the link, while retaining the bottom safe-area margin.
- Vibration was exposed in Home and Pause Settings although platform vibration is not a shipped feature. Both controls, snapshot fields, and signal wiring are removed. The retained feedback service is explicitly disabled as a no-op sink so confirmed-event architecture is unchanged.
- The Android system splash used the 432x432 adaptive-launcher derivative. It now uses `majestic_gems_system_splash_1152_v2.png`, a 1152x1152 transparent-canvas Lanczos derivative made from the preserved 1254x1254 supplied icon source. The approved blue splash background and single-splash configuration are unchanged.

## Coin economy audit

Coins are awarded only when a confirmed result completes the active target. The base reward by result tier is L2 `10`, L3 `25`, L4 `60`, L5 `150`, L6 `350`, L7 `800`, and L8 `1800`; ordinary merges award `0`. Same-resolution chain multipliers can multiply that target result. Level 1 has one L5 target (`150` base). Level 2 has L5+L6 (`500` base). Levels 3+ choose seeded L5-L8 targets: normally three targets, or two targets on levels divisible by four. Therefore later per-level base totals depend on that deterministic target set. Double Coins adds one exactly-once copy of the completed level reward.

## Regression audit

The game-flow suite covers all Back states and a paused idle-Home interval while always-processing timers run. AdMob coverage proves shutdown blocks delayed reloads. Privacy tests check full-width centering and verify no vibration switch exists. Splash size/path and the explicit reward table are asserted. The responsive layout, reference game feel/contact, branding/input, and scene-variety suites were also rerun; all reached their PASS sentinel.

The Godot 4.6.3 Windows console runner still returns its known post-sentinel access-violation code after each suite quits, including unchanged suites; no assertion failed in the logs. No Android device was connected, so physical idle duration, OEM Back behavior, and visual splash acceptance are not claimed.

## APK delivery

`build/android/majestic-gems-back-idle-settings-splash-repair.apk` is the fresh debug delivery from source commit/tag `159f9a8` / `android-back-idle-settings-splash-repair-source`. It is 82,149,382 bytes with SHA-256 `F60C5A6DBB9A17F37C3CC4C37E198DE23D33A338EA2B213FF10025297C79ED9B`. AAPT reports package `com.owais.majestygems`, version code `4`, version name `1.0.2`, min SDK 24, target/compile SDK 36, game category, and portrait support. Both ARM ABIs are present and APK Signature Scheme v2 verifies with one Godot RSA-2048 debug signer. The package includes the new 1152x1152 splash import. No AAB was created; the committed release AAB preset was restored after export.

## Scope

No physics, collision, merge eligibility, launcher pacing, target selection, reward values, progression, table geometry, or ad cadence changed.
