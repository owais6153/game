# Purple Production HUD v1 Report

Date: 2026-08-08

## Outcome

The gameplay HUD has been polished into one production-ready purple hierarchy while gameplay remains frozen. MERGE PATH is the dominant top read; Level and Settings are compact header utilities; Coins and Next are smaller secondary panels; and Target is a separate high-priority card anchored immediately above the existing table.

Gem names and gem-name tooltips remain intentionally absent. Target identity is communicated by authoritative artwork, sequence, and numeric quantity progress, preventing the overflow reported on narrow portrait screens.

## Implementation

- Rebuilt `GameplayHudLayer` with responsive native Godot containers and a separate `TableTargetAnchor`.
- Centralized deep-purple, lavender, cream, and gold surfaces and dimensions in `UiDesignSystem` using `StyleBoxFlat`.
- Preserved all eight generated MERGE PATH icons and live controller-snapshot mappings.
- Added bounded presentation tweens for Settings press, smooth target progress, target confirmation pulse, Next refresh, and coin response.
- Added a dedicated deterministic capture route and responsive/state evidence under `reports/purple-production-hud-v1/`.
- Updated regression assertions for the new ownership tree, objective priority, artwork-only identity, and table-relative Target placement.

No generated bitmap panel was added. Existing gem and Settings artwork are reused unchanged.

## Gameplay boundary

This is rendering/HUD work only. It does not change board/table geometry, background selection, gem artwork, collision radii, physics, launcher state, queue rules, contact or merge eligibility, target generation, progression, balance, rewards, audio/haptic routing, danger timing, or result qualification.

## Validation

- `GEM18_CHAIN_TESTS`: PASS
- `CLEAN_CONTACT_TESTS`: PASS
- `GAMEPLAY_UI_FEEL_TESTS`: PASS
- `INFINITE_LEVEL_TESTS`: PASS
- `LEVEL_1_FLOW_TESTS`: PASS
- `PRODUCTION_FOUNDATION_TESTS`: PASS
- `PRODUCTION_UI_FINALIZATION_TESTS`: PASS
- `MOTION_PROFILE`: PASS, including crowded-board and pause samples with zero callback backlog, zero stream loads, bounded effects, and zero final node delta.
- `PURPLE_PRODUCTION_HUD_V1_CAPTURE`: PASS using Godot 4.6.3 Compatibility/ANGLE.

Validated capture sizes: 576x1312, 720x1600, 1080x1920, 1080x2340, 1080x2400, and 540x1320, plus simulated notch, Pause, crowded-board, target-transition, reward-flight, and danger states.

Godot headless rendering crashes with signal 11 in this environment. Visual validation therefore used the successful non-headless Compatibility/ANGLE route.

## APK delivery

- Source: `2b626434cf7116c6f36bed7d12438650c564fae1` / `purple-production-hud-v1-source`
- APK: `build/android/purple-production-hud-v1.apk`
- Size: 122,882,166 bytes
- SHA-256: `1FA79BBF64743CA3BE0F60E3478809556531299823AAA6653DD1291DE1B6BDEF`
- Export: Godot 4.6.3 headless Android debug preset; export, alignment, signing, and Godot verification completed successfully.
- Package audit: 415 entries, one Android manifest, 14 dex files, arm64 Godot runtime, and zero packaged source/report/build paths.
- Signature audit: APK Signature Schemes v2/v3 PASS with one RSA-2048 signer.
- Device status: `adb devices -l` returned no connected device. Installation, launch, physical safe-area/touch behavior, phone performance, listening, and haptics are not claimed.

## Files

- `scripts/gameplay_hud_layer.gd`
- `scripts/ui_design_system.gd`
- `tools/run_production_ui_finalization_tests.gd`
- `tools/run_gameplay_ui_feel_tests.gd`
- `tools/run_clean_contact_tests.gd`
- `tools/capture_purple_production_hud_v1.gd`
- `reports/purple-production-hud-v1/`
- Core milestone documentation listed in `AGENTS.md`

## Evidence

See [purple-production-hud-v1/README.md](purple-production-hud-v1/README.md).
