# Game Flow + Reward Experience + Splash Polish

Date: 2026-08-12 (Asia/Karachi)

## Outcome

Old flow: Home -> Level Start over Home -> Play -> gameplay -> Level Complete -> Collect/Double -> resolved Level Complete with `NEXT LEVEL` -> optional interstitial -> Level Start -> Play.

New flow: Home -> game screen + Level Ready -> Start -> gameplay -> Level Complete -> Collect/Double -> reward animation -> optional interstitial -> game screen + next Level Ready -> Start.

The intermediate resolved/`NEXT LEVEL` popup state and signal were removed. One popup now represents the reward decision, and the result closes automatically only after its visual feedback finishes.

## Flow-state architecture

`GameController.AppFlowState` records `STARTUP`, `HOME`, `LEVEL_READY`, `PLAYING`, `LEVEL_COMPLETE`, `REWARD_PROCESSING`, and `AD_SHOWING`. It prevents ad, reward, Home, and Level Ready transitions from being inferred from unrelated UI visibility. Simulation and all verified gameplay systems remain unchanged.

Home PLAY emits a controller request. The controller reveals the existing gameplay HUD/table, hides every Home-specific backdrop/logo/status/settings surface, and presents the Level Ready panel. The panel contains Level, target, and START GAME only. START GAME dismisses it and unpauses play.

## Normal Collect

Collect locks reward inputs immediately and resolves the already-authoritative base reward exactly once. The Level Complete popup stays visible while its reward total interpolates over 0.72 seconds and settles with a short pulse. The top gameplay coin HUD simultaneously interpolates from the pre-level bank to the exact final controller total, then bounces. When the overlay emits `reward_animation_finished`, the controller closes it, runs an eligible interstitial, and presents Level Ready.

## Double Coins lifecycle

The existing Level Complete instance survives fullscreen rewarded playback. Only the SDK earned callback persists one extra base reward, protected by the existing manager session guard plus controller `rewarded_bonus_granted`. The callback does not start UI animation or navigation.

After rewarded dismissal, a successful session returns to that same popup and runs `+base -> x2 -> +double`, the total interpolation, and the top-HUD count-up. Early close, unavailable inventory, or show failure grants zero bonus, returns state to `LEVEL_COMPLETE`, restores Collect, restores Double when inventory is ready, and never progresses.

## Interstitial placement

The unchanged cadence is levels 2, 4, 6, and so on. The request occurs only after reward animation completion and after Level Complete has closed. Interstitial completion resets/prepares the generated next level and opens Level Ready; it never starts play. Unavailable inventory invokes the same completion immediately.

## Result polish

The existing light tropical/glass/blue modal remains. Added presentation is bounded: quick title pop, completed-gem scale/fade emphasis, existing sparkle accent, 0.72-second reward interpolation, x2 pop for earned rewarded sessions, and a final reward/HUD bounce. No heavy image or particle asset was added.

## Startup and splash audit

- Android launch screen: Android 12+ system splash from `export_presets.cfg`, Majestic blue with the padded existing adaptive foreground.
- Godot Android boot splash: disabled; it does not add a duplicate Android phase.
- Custom game splash: new `StartupSplashLayer`, same blue, existing `AssetCatalog.BRAND_LOGO`, aspect-preserved 560x420 contain region, 1.05-second hold and 0.20-second fade.
- Main Menu: existing Home overlay after the custom splash emits `finished`.

Android controls the native system splash duration/masking, so exact OEM transition timing cannot be guaranteed. Matching color and existing branding reduce the visible jump. Physical cold-launch acceptance remains required.

## Files changed

- `scripts/game_controller.gd`
- `scripts/home_overlay_layer.gd`
- `scripts/result_overlay_layer.gd`
- `scripts/gameplay_hud_layer.gd`
- `scripts/startup_splash_layer.gd`
- `tests/run_admob_integration_tests.gd`
- `tests/run_game_flow_reward_splash_tests.gd`
- `project.godot`
- `export_presets.cfg`
- `GAME_SPEC.md`, `CURRENT_STATE.md`, `CHANGELOG.md`, `ARCHITECTURE.md`, `AI_KNOWLEDGE_BASE.md`, `BUILD_MANIFEST.md`, and `reports/README.md`

## Validation performed

- Godot 4.6.3 whole-project import/parse: PASS, exit 0.
- `GAME_FLOW_REWARD_SPLASH_TESTS: PASS` before the known Windows teardown exit.
- `ADMOB_INTEGRATION_TESTS: PASS` before a late mock rewarded-loader callback during teardown.
- `BRANDING_PUSH_LINE_TESTS: PASS` before the known Windows teardown exit.
- Main-scene headless smoke: no script/runtime error output before the known teardown exit.
- Latest supplied video identified: `WhatsApp Video 2026-08-12 at 4.12.02 AM.mp4`. Direct visual replay was not available because FFmpeg/Python were absent and Windows capture failed at the system screenshot interface; implementation therefore uses the user-described observed flow plus current-source/state evidence. No video-review claim is made.

## APK

- File: `build/android/majestic-gems-flow-reward-splash-polish-debug.apk`
- Size: 53,370,111 bytes (50.90 MiB)
- Export timestamp: `2026-08-12T04:41:43.6371289+05:00`
- SHA-256: `06A5C78AF3DE4A63BBE2107A074E0B0C22D363A0B129D7F8DD20D5B58C999265`
- Source commit: `48399b568449b53be3b4b4c0a4b47ac967bf057d` (`feat: streamline reward flow and polish startup`)
- Delivery tag: `game-flow-reward-splash-polish-v1`
- Package audit: `com.owais.majestygems`, application label/version name `Majestic Gems`, version code `1`, min SDK `24`, target/compile SDK `36`.
- Payload audit: 928 ZIP entries, five DEX files, arm64-v8a Godot runtime only, and no packaged `reports/`, `tests/`, `tools/`, raw `.gd`, `.tscn`, or `.md` payloads.
- Signing audit: APK Signature Scheme v2 verifies with one RSA-2048 Godot debug signer. This is a validation build, not a store-release signing claim.
- Ad configuration: Google debug interstitial and rewarded unit IDs remain selected for debug exports; production unit IDs remain intentionally blank.
- Export-process note: the stable APK was fully written before the outer Godot/Gradle wrapper exceeded the command timeout. The two identified orphaned build processes were stopped; artifact hash, manifest, payload, ABI, and signature checks pass.

## Known limitations / physical-device checklist

No connected Android device was available at implementation time. Still required: force-stop cold launch; verify native-to-custom splash continuity/logo scale/no flash; verify Home PLAY reveals game screen before Level Ready; normal Collect count-up and automatic Level Ready; rewarded test-ad success/early close/background-resume; even-level interstitial after reward feedback; unavailable-ad fail-open; and no duplicate reward/modal after lifecycle restoration.
