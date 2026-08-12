# Single Splash Correction

Date: 2026-08-12 (Asia/Karachi)

## Correction

The separate `StartupSplashLayer` was already deleted, but mobile still called `_show_home(true)`. That flag hid Home controls and ran a timed logo-only presentation over the Home background. It used the Home tree, but visually it was still a second splash.

That path is now removed completely. Mobile calls `_show_home()` normally, and the complete Home menu is visible immediately after Android's system launch splash. There is no splash scene, splash CanvasLayer, hidden-controls startup mode, or timed second phase.

## First splash constraint

The remaining first screen is Android's platform-owned system splash. On Android 12 and newer, the system API requires an opaque background color plus a constrained/mask-safe icon. It does not accept a CSS-style full-screen cover bitmap. Removing the color or using `level_bg_1.png` as a cover background would require another in-app surface, recreating the second splash the user requested removed.

The single native splash therefore retains:

- background color: Majestic sky blue `Color(0.188235, 0.611765, 0.847059, 1)`;
- icon: `assets/runtime/ui/majestic_gems_adaptive_foreground_v1.png`;
- Godot Android boot splash: disabled.

It then transitions directly to Home, whose existing full-screen background remains `assets/runtime/backgrounds/level_bg_1.png` with centered aspect-cover behavior.

## Files changed

- `scripts/game_controller.gd`
- `scripts/home_overlay_layer.gd`
- `tests/run_game_flow_reward_splash_tests.gd`
- `export_presets.cfg`
- required specification, state, changelog, architecture, knowledge-base, manifest, and reports documentation

## Verification

- Godot 4.6.3 whole-project import/parse: PASS, exit 0.
- `GAME_FLOW_REWARD_SPLASH_TESTS: PASS` before the known Windows teardown exit.
- Static/runtime assertions confirm no `_show_home(true)`, `startup_intro`, `_start_home_splash_intro`, `StartupSplashLayer`, or separate Godot Android boot splash.
- APK package, ABI, payload, removed-splash, forbidden-file, and signature checks: PASS.
- ADB device query timed out and its hung process was stopped. No physical-device launch is claimed.

## APK

- File: `build/android/majestic-gems-single-splash-correction-debug.apk`
- Size: 53,368,728 bytes (50.90 MiB)
- Export timestamp: `2026-08-12T06:44:06.4725555+05:00`
- SHA-256: `65575E1B14AF81E88608CB07BDFAB37604B2D5B1B014F340BFC5F6D467351840`
- Source commit: `852538c8cc9fcb3e324f4eb2c8e3d60e33216ce4` (`fix: remove remaining second splash state`)
- Delivery tag: `single-splash-correction-v1`
- Package: `com.owais.majestygems`; version code `1`; version/application label `Majestic Gems`; min SDK `24`; target/compile SDK `36`.
- Payload: 926 ZIP entries, five DEX files, arm64-v8a Godot runtime only, zero forbidden raw-source/report/test/tool paths, and zero `startup_splash` entries.
- Signature: APK Signature Scheme v2 verifies with one RSA-2048 Godot debug signer.
