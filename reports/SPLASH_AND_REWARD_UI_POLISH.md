# Splash and Reward UI Polish

Date: 2026-08-12 (Asia/Karachi)

## Outcome

The extra custom `StartupSplashLayer` and its controller wiring were removed. Mobile startup now enters the existing Home overlay directly. That one tree briefly presents its existing full-bleed background and logo, then reveals the Home controls; no intermediary scene or second custom CanvasLayer exists.

Level Complete keeps the existing light blue/glass modal shell, completed target gem, actions, and lifecycle. Only its reward hierarchy is corrected: `YOU EARNED` leads a large coin and reward amount, with a quieter `TOTAL` coin and bank value below.

## Splash implementation

- Exact background: `assets/runtime/backgrounds/level_bg_1.png`, reached through `AssetCatalog.background_texture(0)`.
- Exact logo: `assets/runtime/ui/majestic_gems_logo_v1.png`, reached through `AssetCatalog.BRAND_LOGO`.
- Cover/crop: the existing `HomeTropicalBackdrop` is a full-rect `TextureRect` with `STRETCH_KEEP_ASPECT_COVERED`. It preserves aspect ratio, centers the image, fills the viewport, and crops excess edges instead of stretching or letterboxing.
- Timing: the logo settles from 0.96 to 1.0 over 0.78 seconds, holds 0.10 seconds, then the Home content crossfades into its normal entrance. Controls appear within the 1-1.5 second budget.
- Android's platform-owned native launch surface remains configured; Godot's duplicate Android boot splash remains disabled. The removed layer is not replaced by another scene.

## Reward UI and animation

- Exact coin asset: `assets/runtime/effects/coin_reward_reference_v2.png` through `CoinIcon -> CoinVisuals -> AssetCatalog.COIN_REWARD`, identical to the top-left gameplay HUD.
- Normal Collect locks actions immediately, keeps `+reward` prominent, interpolates the popup total and top HUD from the pre-level bank to the authoritative final bank, then applies a short coin/total and HUD bounce before transition.
- Confirmed Double Coins returns to the same popup, pops `×2`, changes the earned row from the base reward to the doubled reward, interpolates the total/HUD, and only then permits progression.
- `WATCH AD ×2` clarifies the rewarded action. HOME remains visually secondary. No extra action or popup was added.
- No particle system or new visual asset was introduced.

## Files changed

- `scripts/game_controller.gd`
- `scripts/home_overlay_layer.gd`
- `scripts/result_overlay_layer.gd`
- removed `scripts/startup_splash_layer.gd` and UID
- `tests/run_game_flow_reward_splash_tests.gd`
- `tests/run_admob_integration_tests.gd`
- `export_presets.cfg`
- required specification, state, changelog, architecture, knowledge-base, manifest, and reports documentation

## Verification performed

- Existing screenshots reviewed before editing: the three newest project JPEGs are historical gameplay/result references; no new screenshot accompanied the request.
- Godot 4.6.3 whole-project import/parse: PASS, exit 0.
- `GAME_FLOW_REWARD_SPLASH_TESTS: PASS` before the known Windows teardown exit.
- `ADMOB_INTEGRATION_TESTS: PASS` before the known late mock rewarded-loader teardown callback.
- Regression assertions cover removal of the extra splash module, exact Home background path, centered aspect-cover mode, same-tree Home reveal, shared HUD `CoinIcon`, separated earned/total values, input locking, normal reward completion, x2 completion, and unchanged ad cadence/exactly-once behavior.

## APK

- File: `build/android/majestic-gems-splash-reward-ui-polish-debug.apk`
- Size: 53,369,788 bytes (50.90 MiB)
- Export timestamp: `2026-08-12T06:17:25.8474273+05:00`
- SHA-256: `1A500655BBCF5BC8AAE68F36983B46951C5C1C1C6449DBB8D759A7A826055827`
- Source commit: `c51cda96bf576a3a6bdaf3b04a4f9e8bf331e555` (`fix: unify startup and polish reward presentation`)
- Delivery tag: `splash-reward-ui-polish-v1`
- Package: `com.owais.majestygems`; version code `1`; version/application label `Majestic Gems`; min SDK `24`; target/compile SDK `36`.
- Payload: 926 ZIP entries, five DEX files, arm64-v8a Godot runtime only, zero forbidden report/test/tool/raw-source paths, and zero `startup_splash` payload entries.
- Signature: APK Signature Scheme v2 verifies with one RSA-2048 Godot debug signer. This is a test build, not a production signing claim.
- Export note: the stable APK was written before the outer Godot/Gradle wrapper reached its known command timeout. No Godot or Java export process remained afterward; the artifact itself passed checksum, manifest, payload, ABI, and signature inspection.

## Physical-device status

ADB device queries did not return within the validation window and the hung ADB process was stopped. No connected-device state, installation, or force-stopped cold launch is claimed. A physical cold launch is still required to judge native-to-Home continuity, crop on the target phone, and Google-served rewarded/interstitial presentation; none is inferred from export success.
