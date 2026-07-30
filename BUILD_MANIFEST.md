# Build Manifest

## Level 1 Balance v1

- File: `level-1-balance-v1.apk`
- Path: `D:\Owais\game\build\android\level-1-balance-v1.apk`
- Size: `99,204,339` bytes
- Modified: `2026-07-30 09:48:03 +05:00`
- SHA-256: `72883265B690232655C6D62581D4CE3722F8F79007AAF831F83B20E4C576375A`
- Source baseline: `4ad1d51e09e0efce75d6842b0310880095ad349c` (`level-1-flow-v1`)
- Tag: `level-1-balance-v1`
- Validation: Godot 4.6.3 parse/import; `CLEAN_CONTACT_TESTS`, `GEM18_CHAIN_TESTS`, `LEVEL_1_FLOW_TESTS`, and `MOTION_PROFILE` passed. APK exists, is non-empty, and its ZIP contains `AndroidManifest.xml` and `classes.dex`.
- Device status: no connected device; installation and device timing are not claimed.

## 18-Gem Order v1

- File: `18-gem-order-v1.apk`
- Path: `D:\Owais\game\build\android\18-gem-order-v1.apk`
- Size: `99,187,450` bytes
- Modified: `2026-07-30 08:43:05 +05:00`
- SHA-256: `95E2279F9BE8DD762FCE196A86D0B6301CDE9001711E3B5AF2E25747AAF62752`
- Source commit: `3d7bb2e8b3d03dcf0bf7f2bb49cea9685cdcd194` (`chore: finalize 18-gem progression order`)
- Baseline tag: `18-gem-size-collision-fix-v1`
- Validation: Godot 4.6.3 headless import/parse; `CLEAN_CONTACT_TESTS: PASS`; `GEM18_CHAIN_TESTS: PASS`; `MOTION_PROFILE: PASS`; APK exists, is non-empty, and its ZIP contains `AndroidManifest.xml` and `classes.dex`.
- Device status: no connected Android device; no install or launch claimed.

## 18-Gem Size & Collision Fix v1

- File: `18-gem-size-collision-fix-v1.apk`
- Path: `D:\Owais\game\build\android\18-gem-size-collision-fix-v1.apk`
- Size: `99,187,450` bytes
- Modified: `2026-07-30 08:30:36 +05:00`
- SHA-256: `391A97C53874B783AE00A835F3A3C07EB6D75340686556B18E3B8C42999F7D8D`
- Source commit: `fc71e2dad781134948d1962dfe2a49ad0b6521fe` (`fix: calibrate 18-gem sizes and collisions`)
- Tag: `18-gem-size-collision-fix-v1`
- Validation: Godot 4.6.3 import/parse validation; `CLEAN_CONTACT_TESTS: PASS`; `GEM18_CHAIN_TESTS: PASS`; `MOTION_PROFILE: PASS`; APK exists, is non-empty, and its ZIP contains `AndroidManifest.xml` and `classes.dex`.
- Device status: no connected Android device; no install or launch claimed.

## 18-Gem Motion Smoothness Fix v1 — export blocked

- Requested file: `build/android/18-gem-motion-smoothness-fix-v1.apk`.
- Source commit: the commit tagged `18-gem-motion-smoothness-fix-v1` (`fix: restore smooth motion for 18-gem build`).
- Validation: Godot 4.6.3 import/parse validation; `CLEAN_CONTACT_TESTS: PASS`; `GEM18_CHAIN_TESTS: PASS`; `MOTION_PROFILE: PASS`.
- Export status: delivered as a fresh standalone debug APK using Godot's Android debug-signing path. The previous block was not a filename issue: release export reached signing but had no release keystore, and the earlier session lacked write access to the project cache/output.
- File: `18-gem-motion-smoothness-fix-v1.apk`
- Path: `D:\Owais\game\build\android\18-gem-motion-smoothness-fix-v1.apk`
- Size: `97,688,126` bytes
- Modified: `2026-07-30 05:35:02 +05:00`
- SHA-256: `E63CEE8EAA1AC1A6B3954EC2E94238EC76CE744ACEBDB3105B56CD9261518765`
- Source commit: `6953b4095b8924096a7d71445771cecbc893e30d`
- Source tag: `18-gem-motion-smoothness-fix-v1` (unchanged)
- Godot: `4.6.3.stable.official.7d41c59c4`
- Export preset/method: `Android`; `Godot_v4.6.3-stable_win64_console.exe --headless --path D:\Owais\game --export-debug Android build/android/18-gem-motion-smoothness-fix-v1.apk`
- Package validation: APK ZIP contains `AndroidManifest.xml`, `classes.dex`, and packaged project assets. No Android phone was connected, so device installation and launch are not claimed.

## 18-Gem Chain v1

- File: `18-gem-chain-v1.apk`
- Path: `D:\Owais\game\build\android\18-gem-chain-v1.apk`
- Size: 106,113,431 bytes
- Modified: 2026-07-30 04:37:06 +05:00
- SHA-256: `177E5F12A1E951DE32092801EA91B0354BD1969A1E9C69D30EFB1263AC05200F`
- Source commit: `13d9f24bf88e86ff0b887251e3964c29bd23eec4` (`feat: add isolated 18-gem merge chain`)
- Tag: `18-gem-chain-v1`
- Validation: Godot 4.6.3 parse/import validation, `CLEAN_CONTACT_TESTS: PASS`, and `GEM18_CHAIN_TESTS: PASS`.
- Device status: no device connected; no install or launch claimed.
## New Table Shadow Contact Fix v1

- File: `new-table-shadow-contact-fix-v1.apk`
- Path: `D:\Owais\game\build\android\new-table-shadow-contact-fix-v1.apk`
- Size: 76,113,263 bytes
- Modified: 2026-07-29 13:05:58 +05:00
- SHA-256: `713E25E53E10B36AFA88BB83C1CB3183A11CFA120B6493A1AEE57F29E2B41E19`
- Source commit: `0b562d5b85b0b4d0330ecd10da3f832408949ad9` (`fix: use new table and separate gem shadows from collision`)
- Tag: `new-table-shadow-contact-fix-v1`
- Validation: Godot 4.6.3 headless editor parse/import validation and `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug export completed and Godot verified the signed APK.
- Device status: no device was listed by `adb devices -l`; the APK was not installed or launched on a phone.

## Visual Sequencing + Contact v2 — export blocked

- Requested file: `build/android/visual-sequencing-contact-v2.apk`
- Source state: pending commit `fix: delay win presentation and align visible contacts`.
- Validation: Godot 4.6.3 import/parse validation and `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`).
- Export status: blocked. Godot's Android exporter rejected every tested valid output form (absolute Windows path, absolute slash path, project-relative path, and preset path) with `Invalid filename! Android APK requires the *.apk extension.` before compiling. No replacement or old APK was copied, and no device testing is claimed.

## Visual-Physics Calibration v1

- File: `visual-physics-calibration-v1.apk`
- Path: `D:\Owais\game\build\android\visual-physics-calibration-v1.apk`
- Size: 72,539,231 bytes
- Modified: 2026-07-29 10:58:56 +05:00
- Source commit: `8fdebd405c791eddf9188bd32e9f0de3b83cbd42` (`fix: align table perspective and visible gem collisions`)
- Tag: `visual-physics-calibration-v1`
- Validation: Godot 4.6.3 parse/import validation passed; `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug APK was physically verified.
- Device status: no connected device was used; no install or launch was attempted.

## Asset Integration — Background, Table, and Gems v1

- File: `asset-integration-background-table-gems-v1.apk`
- Path: `D:\Owais\game\build\android\asset-integration-background-table-gems-v1.apk`
- Size: 70,457,131 bytes
- Modified: 2026-07-29 10:24:35 +05:00
- Source commit: `7ac26f197d7768f13f8ea87c17e29b9893db4300` (`feat: integrate gameplay background table and gem assets`)
- Tag: `asset-integration-background-table-gems-v1`
- Validation: Godot 4.6.3 parse/import validation passed; `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug APK physically verified.
- Device status: `adb devices -l` found no connected device. No install or launch was attempted.

## Reference Table + Gem Audio v1

- File: `reference-table-gem-audio-v1.apk`
- Path: `D:\Owais\game\build\android\reference-table-gem-audio-v1.apk`
- Size: 27,748,993 bytes
- Modified: 2026-07-29 08:29:58 +05:00
- Source commit: `d2e99213f01005ba08ff1f9bd50a98ac11a967c7` (`feat: match reference table composition and gem audio`)
- Tag: `reference-table-gem-audio-v1`
- Validation: Godot 4.6.3 headless editor parse/import validation passed; `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); signed standalone Android debug export completed and the APK file was physically verified.
- Device status: ADB query did not complete in this session; no install or launch was attempted.

## Sound + Haptics v1

- File: `sound-haptics-v1.apk`
- Path: `D:\Owais\game\build\android\sound-haptics-v1.apk`
- Size: 27,744,897 bytes
- Modified: 2026-07-29 07:59:11 +05:00
- Source commit: `5245163722e2c34f86657aa25483f47d96e7fdfa` (`feat: add gameplay sound and haptic feedback`)
- Tag: `sound-haptics-v1`
- Validation: Godot 4.6.3 headless test suite passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug export completed and the APK file was physically verified.
- Device status: `adb devices -l` found no connected device. No install or launch was attempted.

## Progression HUD v1

- File: `progression-hud-v1.apk`
- Path: `D:\Owais\game\build\android\progression-hud-v1.apk`
- Size: 27,732,265 bytes
- Modified: 2026-07-29 07:42:27 +05:00
- Source commit: `2dc007575457fec112acabc51b7d6dcfb9f06462` (`feat: add gem progression preview and clean HUD`)
- Tag: `progression-hud-v1`
- Validation: Godot 4.6.3 parse/import validation passed; `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug export completed and the requested APK file was physically verified.
- Device status: `adb devices -l` found no connected device. No install or launch was attempted.

## Physics and Pacing Parity v1

- File: `physics-pacing-parity-v1.apk`
- Path: `D:\Owais\game\build\android\physics-pacing-parity-v1.apk`
- Size: 27,728,010 bytes
- Modified: 2026-07-29 07:25:11 +05:00
- Source commit: `3bba78f32f3994ff4d9b103cac3f8a2fd983e44b` (`chore: tune physics and pacing toward reference`)
- Tag: `physics-pacing-parity-v1`
- Validation: Godot 4.6.3 parse/import validation passed; `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug export completed and the requested APK file was physically verified.
- Device status: `adb devices -l` found no connected device. No install or launch was attempted.

## Gem Visual Refinement v1

- File: `gem-visual-refinement-v1.apk`
- Path: `D:\\Owais\\game\\build\\android\\gem-visual-refinement-v1.apk`
- Size: 27,723,914 bytes
- Modified: 2026-07-29 04:59:02 +05:00
- Source commit: `14d5de194e60dedf23c29e8c401e8c8b47e761a6` (`feat: refine gemstone visuals and responsive layout`)
- Tag: `gem-visual-refinement-v1`
- Validation: Godot 4.6.3 parse/import validation passed; `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug export completed and APK existence was verified.
- Device status: `adb devices` found no connected device. No install or launch was attempted.

## Gameplay Balance v1

- File: `gameplay-balance-v1.apk`
- Path: `D:\\Owais\\game\\build\\android\\gameplay-balance-v1.apk`
- Size: 27,728,010 bytes
- Modified: 2026-07-29 06:45:13 +05:00
- Source commit: `4bb5469456bf23480b569a15b9c44c7692e30257` (`chore: tune gameplay physics and pacing`)
- Tag: `gameplay-balance-v1`
- Validation: Godot 4.6.3 parse/import validation passed; `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug export completed and APK existence was verified.
- Device status: `adb devices -l` found no connected device. No install or launch was attempted.

## Gemstone Visual Prototype v1

- File: `gem-visual-prototype-v1.apk`
- Path: `D:\Owais\game\build\android\gem-visual-prototype-v1.apk`
- Size: 27,723,914 bytes
- Modified: 2026-07-29 04:40:27 +05:00
- Source commit: `561235ad45a6dbf50a3b8a018820656dae53cd53` (`feat: add first gemstone visual prototype`)
- Tag: `gem-visual-prototype-v1`
- Validation: Godot 4.6.3 parse/import validation passed; `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug export completed and APK existence was verified.
- Device status: no device install or launch was attempted in this session.

## Clean Contact Merge v3 — Playable Loop

- File: `clean-contact-merge-v3-playable-loop.apk`
- Path: `D:\Owais\game\build\android\clean-contact-merge-v3-playable-loop.apk`
- Size: 27,719,661 bytes
- Modified: 2026-07-29 04:16:50 +05:00
- Source commit: `2d982a8af80e0477caf2c8641f8543c28587a178` (`feat: add scoring win and fail gameplay loop`)
- Tag: `clean-contact-merge-v3-playable-loop`
- Validation: Godot 4.6.3 parse/import validation passed; `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug export completed and APK existence was verified.
- Device status: `adb devices` reported no connected device. The APK was not installed or launched on a phone.

Every APK record includes its filename, path, size, modified timestamp, source commit, tag, validation, and device status.

## Clean Contact Merge v2 — Chain Polish

- File: `clean-contact-merge-v2-chain-polish.apk`
- Path: `D:\Owais\game\build\android\clean-contact-merge-v2-chain-polish.apk`
- Size: 27,711,469 bytes
- Modified: 2026-07-29 03:44:48 +05:00
- Source commit: `10f8d59408cccd6287d308f5fc0ab0046326ea3a` (`feat: add smooth merge animation and contact chain merges`)
- Tag: `clean-contact-merge-v2-chain-polish`
- Validation: Godot 4.6.3 headless parse/import validation passed; `tools/run_clean_contact_tests.gd` passed (`CLEAN_CONTACT_TESTS: PASS`); standalone Android debug export completed and the APK file was physically verified.
- Device status: `adb devices` reported no connected device. The APK was not installed or launched on a phone.

## Clean Contact Merge v1 — Spawn Lifecycle Fix

- File: `clean-contact-merge-v1-spawn-fix.apk`
- Path: `D:\Owais\game\build\android\clean-contact-merge-v1-spawn-fix.apk`
- Size: 27,707,373 bytes
- Modified: 2026-07-29 03:23:14 +05:00
- Source commit: `53306bf1f9d96fbb6918380657dd611ed1a7a51e` (`fix: spawn exactly one launcher piece per shot cycle`)
- Tag: `clean-contact-merge-v1-spawn-fix`
- Validation: Godot 4.6.3 headless editor parse/import validation passed; `tools/run_clean_contact_tests.gd` passed, including the controller lifecycle regressions; standalone Android debug export completed.
- Device status: `adb devices` reported no connected device. The APK was not installed or launched on a phone.

## Clean Contact Merge v1

- File: `clean-contact-merge-v1.apk`
- Path: `D:\Owais\game\build\android\clean-contact-merge-v1.apk`
- Size: 27,707,373 bytes
- Modified: 2026-07-29 03:12:46 +05:00
- Source commit: `ac795736bbecb4ee83c346a2717276d66a2b483c` (`feat: build clean contact merge gameplay slice`)
- Tag: `clean-contact-merge-v1`
- Validation: Godot 4.6.3 headless editor parse/import validation passed; `tools/run_clean_contact_tests.gd` passed; standalone Android debug export completed and Godot verified the signed APK.
- Device status: `adb devices` reported no connected device. The APK was not installed or launched on a phone.

## Blank Android baseline

- File: `gem-merge-rebuild-baseline.apk`
- Path: `D:\Owais\game\build\android\gem-merge-rebuild-baseline.apk`
- Size: 27,690,009 bytes
- Modified: 2026-07-29 02:55:38 +05:00
- SHA-256: `B29D90C5E082CFEA0567EA488B831458B8107F15690838BE5F06355139A93A1F`
- Source commit: `ad1e2d720f615ce326da91ac15b5a303543b15d8` (`build: verify blank Android baseline export`).
- Tag: `blank-android-baseline-verified`.
# 18-Gem Progression Tested v1

- File: `18-gem-progression-tested-v1.apk`
- Path: `D:\Owais\game\build\android\18-gem-progression-tested-v1.apk`
- Size: `99,195,813` bytes
- Modified: `2026-07-30 08:55:02 +05:00`
- SHA-256: `44FB0D04CD65DB1C666A66258E308AE9853D33F26060D4D3C9C6C04B8318559A`
- Source commit: `306b0c69d3e7f8ecd49887420ea02c67386e61d0` (`test: validate complete 18-gem progression`)
- Tag: `18-gem-progression-tested-v1`
- Validation: Godot 4.6.3 import/parse, `GEM18_CHAIN_TESTS`, `CLEAN_CONTACT_TESTS`, development harness L14 four-step chain, L18 terminal path, and APK ZIP checks passed.
- Device status: no phone was connected; installation, visual manual checks, and device performance are not claimed.
# Level 1 Flow v1

- File: `level-1-flow-v1.apk`
- Path: `D:\\Owais\\game\\build\\android\\level-1-flow-v1.apk`
- Size: `99,200,243` bytes
- Modified: `2026-07-30 09:12:13 +05:00`
- SHA-256: `E7BDBBE6D1158F113F705980602A769DA64078194A61780E45D6AA4156616D9B`
- Source commit: `4ad1d51e09e0efce75d6842b0310880095ad349c` (`feat: add isolated level 1 flow`).
- Tag: `level-1-flow-v1`.
- Validation: Godot 4.6.3 parse/import plus `CLEAN_CONTACT_TESTS`, `GEM18_CHAIN_TESTS`, and `LEVEL_1_FLOW_TESTS` passed. APK/ZIP structure contains `AndroidManifest.xml` and `classes.dex`.
- Device status: no phone was connected; installation and launch were not attempted.
# Perspective Table View v1

- APK: `build/android/perspective-table-view-v1.apk`
- Build source commit: `5125a4c238d1c9963cad8d185d68491910892623`
- Tag: `perspective-table-view-v1`
- Size: `99,204,339 bytes`
- Modified: `2026-07-30 10:16:44 +05:00`
- SHA-256: `D4BDC9598A28DD5EEB494974215DD617DCDC6EDA9DDC341A93505732D4D77CEC`
- Validation: Godot parse/import, clean-contact, 18-gem chain, Level 1 flow, and motion profile passed. APK ZIP structure verified (`AndroidManifest.xml`, `classes.dex`).
- Device status: no device connected; not installed/tested on-device.
# Complete Perspective View & Variety v1

- File: `complete-perspective-view-variety-v1.apk`
- Path: `D:\Owais\game\build\android\complete-perspective-view-variety-v1.apk`
- Size: `99,204,339` bytes
- Modified: `2026-07-30 10:41:40 +05:00`
- SHA-256: `577F4E90610DD5A03CA849F890F65806DC75D6BE39BF4DF52569C95E478DABB9`
- Source baseline: `845a113` (`perspective-table-view-v1`); final source commit and tag follow this manifest update.
- Validation: Godot parse/import; `CLEAN_CONTACT_TESTS`, `GEM18_CHAIN_TESTS`, `LEVEL_1_FLOW_TESTS`, and `MOTION_PROFILE` passed. Fresh APK exists, is non-zero, and its ZIP contains `AndroidManifest.xml` and `classes.dex`.
- Device status: no connected device; no installation or launch claimed.
# Visible-Touch Table Alignment Fix v1

- File: `visible-touch-table-alignment-fix-v1.apk`
- Path: `D:\Owais\game\build\android\visible-touch-table-alignment-fix-v1.apk`
- Size: `99,204,339` bytes
- Modified: `2026-07-30 11:02:43 +05:00`
- SHA-256: `63238FE064B48BC57ECBBCD1EE522C17347C86CE5B96F57A71B764F00B5AE5DC`
- Source commit: `3316d2dcdebde9528885c882b2de385c26862c66` (`fix: restore visible-touch collision and table alignment`)
- Tag: `visible-touch-table-alignment-fix-v1`
- Validation: Godot 4.6.3 headless parse/import; `CLEAN_CONTACT_TESTS`, `GEM18_CHAIN_TESTS`, `LEVEL_1_FLOW_TESTS`, and `MOTION_PROFILE` passed. APK is non-empty and ZIP validation found `AndroidManifest.xml`, `classes.dex`, and arm64-v8a entries.
- Device status: no connected Android device; installation and launch were not attempted.
