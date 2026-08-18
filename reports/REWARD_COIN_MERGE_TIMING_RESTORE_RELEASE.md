# Reward, Coin, and Merge Timing Restore Release

## Scope and historical reference

Tester feedback requested the readable success cadence from a few hours earlier, after the target tick/checkmark had been removed. Git review identified `acb28a5` (`animation-audio-back-privacy-polish-source`) as the exact source for the requested merge, target-reward, coin, and result-hold timing. This task restores only that presentation timing on top of the newer collision-audio midpoint and Android Activity-owned Exit fixes.

The tick/checkmark remains removed. No gem, UI design, physics, table dimension, merge/target rule, difficulty, reward integer, save, AdMob, UMP, package name, or Home/navigation behavior changes.

## Final animation timing

| Presentation | Before | Restored |
| --- | ---: | ---: |
| Merge | 270 ms | 540 ms |
| Result reveal / merge chime | immediate | 200 ms |
| Target collection | 320 ms | 700 ms |
| Target confirmation + travel | compressed | 100 ms + 520 ms |
| Target card pulse | 380 ms | 220 ms |
| Coin start delay | none | 260 ms |
| Coin travel | 540/600 ms | 550/620 ms |
| Coin flight/spawn stagger | 45/15 ms | 80/80 ms |
| Four-coin visible bound | 855 ms | about 980 ms |
| Result hold | 240 ms | 420 ms |

Collision response remains 110 ms and Next remains 160 ms. Target travel starts 300 ms into merge settle, while coins start after 260 ms, so merge, target, particles, and coins overlap. Gameplay does not wait on these effects.

## Authority and regression protection

- Confirmed target progress and the unchanged reward integer commit once immediately.
- HUD target progress advances once at target-duplicate arrival.
- Presentation result IDs remain deduplicated.
- The target duplicate is presentation-only; it does not become a physics body.
- Launcher readiness remains independent of merge, target, coin, particle, and audio duration.
- Current midpoint gem/rail collision audio and spam protection are unchanged.
- Android Back/Exit, Privacy alignment, Home startup, AdMob/UMP, and save behavior are unchanged.

## Android release identity

The user confirmed Google Play's current uploaded version code is 3. Local tester APKs already used version code 4 / name 1.0.2, so this task permanently advances the preset to version code 5 / version name 1.0.3. The AAB uses the existing upload key; no signing key is created.

## Validation and artifacts

All eight project regression sentinels print PASS:

- `ANIMATION_AUDIO_BACK_PRIVACY_POLISH_TESTS`
- `GAME_FLOW_REWARD_SPLASH_TESTS`
- `REFERENCE_GAME_FEEL_V2_TESTS`
- `SOUND_PRIVACY_LINK_TESTS`
- `UI_SCALE_LAYOUT_TESTS`
- `SCENE_VARIETY_ASSETS_TESTS`
- `BRANDING_PUSH_LINE_TESTS`
- `ADMOB_INTEGRATION_TESTS`

The Windows Godot 4.6.3 console runner retains its known access violation during teardown after each PASS sentinel; no assertion failed. Artifact, signing, manifest, ABI, bundletool, and device-status results are recorded after export and mirrored in `BUILD_MANIFEST.md`.
