# Player Feedback and Limited-Shots Repair V1

Date: 2026-08-31

Baseline: `b4b896f` / `final-hud-vfx-audio-test-candidate-apk`

## Player-reported defects and causes

1. `ResultOverlayLayer.present()` hardcoded the danger-line sentence for every failed result. The controller already knew `out_of_shots`, but did not pass it through.
2. Daily Treasure persisted the correct power bundle, refreshed the popup to `Collected today`, and only then animated the chest. The reward existed but its identities/counts disappeared at the exact moment the player needed confirmation.
3. Bomb and Hammer correctly delayed gameplay until cinematic impact, but their 1.08-second shared travel had no readable hold over the selected gem.
4. Merge shards maintained a separate high-count record/update/draw path. The user requested that path removed and the merge wave itself made denser.
5. Home's status cards used the base style but not the edge decorators already used in gameplay. The screen also carried redundant `CURRENT LEVEL` and idle `Tap to view today's missions` copy.
6. Limited-shot levels retained the full three-target L6/L7/L8 objective and scaled quantities. Solver feasibility did not mean the rounds felt achievable in real play.

## Delivered behavior

- Failure copy is keyed from the controller-owned reason.
- Treasure opening reveals every saved grant as a staged power icon with name and quantity, under `YOU RECEIVED`.
- Bomb/Hammer arrive at the chosen gem, shake/brace, then apply at the unchanged impact signal. Total duration is 1.65 seconds and remains skippable.
- All shard constants, storage, update, cap, and polygon drawing are removed. The remaining merge-impact record draws 3-6 delayed wavefronts, 12-30 deterministic rays, and the existing tier core in exact result color.
- Home Level/Coins panels receive two restrained 30px edge diamonds. Redundant labels are removed and a 20px mission/status gap is explicit.
- Limited-shot target sequence is one L6 then one L7. The solver still derives the budget, but `LIMITED_SHOTS_MINIMUM = 24` prevents a reduced objective from reducing shots below a full launcher cycle. Normal target generation is unchanged.

## Scope boundaries

- No board geometry, collider, restitution, damping, launch velocity, contact capture, merge eligibility, score/reward integer, persistence ordering, ad rule, or audio/haptic routing changed.
- Treasure presentation receives an already-persisted grant dictionary and cannot mutate inventory.
- Home and result changes remain presentation-only and consume controller state.

## Validation

- Godot 4.6.3 headless editor import/class registration: PASS. The sandbox still reports its environment-only root-certificate/editor-settings warnings.
- `PLAYER_FEEDBACK_REPAIR_V1_TESTS`: PASS.
- `MERGE_PHYSICS_V1_TESTS`: PASS.
- `POWERS_GAMEPLAY_V1_TESTS`: PASS.
- `LEVEL_DIFFICULTY_V1_TESTS`: PASS after enforcing the 24-shot minimum discovered by the suite.
- Some Windows test processes return the repository's known post-PASS access violation (`-1073741819`) after printing the PASS sentinel; no assertion failed before those sentinels.
- The legacy multi-frame capture stalled before writing any file and was stopped; a focused fallback confirmed that this headless session uses Godot's dummy renderer and therefore exposes no viewport texture. No blank or stale screenshot is claimed as new visual proof. Device visual acceptance remains outstanding.

The debug APK preset keeps the existing non-Play test identity `17 / 1.0.15` and writes a distinct milestone filename. No AAB is produced and the release AAB identity remains unchanged.

## Artifact and delivery

- Source commit/tag: `10b744a` / `player-feedback-limited-shots-repair-v1-source`.
- APK: `build/android/majestic-gems-player-feedback-repair-v1.0.15-vc17.apk`.
- Size: 114,504,049 bytes.
- Timestamp: 2026-08-31 02:26:01 +05:00.
- SHA-256: `903012F1786A1A7B87894D31EADF32302A519712470F18ECC35A86992BAD79F4`.
- AAPT: package `com.owais.majestygems`, versionCode 17, versionName 1.0.15, min SDK 24, target/compile SDK 36, both ARM ABIs.
- Signature: APK Signature Scheme v2 PASS with one Godot RSA-2048 debug signer.
- Device: ADB reports connected V2149 `34385676890001M`; no install/launch or physical acceptance was performed.
