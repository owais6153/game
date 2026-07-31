# Video-Verified Unlimited Launcher + HUD v1

## Baseline and evidence

- Clean source baseline: `bfbd201` / `unlimited-launcher-runtime-proof-v1`.
- User evidence: `WhatsApp Video 2026-07-31 at 9.12.19 AM.mp4`, 30.03 seconds, 720 x 1600.
- At 23-24 seconds the green launcher fires. From 25-30 seconds no replacement appears; repeated touches at 26-29 seconds do nothing while score remains 400 and no win/failure overlay is present. This proves a launcher lifecycle deadlock rather than a numeric cap, danger failure, or victory.

## Root cause and unlimited-launch repair

- `LevelConfig.launcher_level_at()` was already cyclic through `posmod`; there is no `shot_limit` or `shot_count` state.
- The fired body remained the active launcher until `is_settled()`. Crowded contacts could keep it above the 11 px/s sleep threshold indefinitely.
- More critically, any unrelated board merge changed `SHOT_IN_FLIGHT` to `RESOLVING` while leaving that fired body active. `SPAWNING_NEXT` then refused to create a replacement because an active body existed and remained stuck forever.
- A successful release now has a centralized 0.30-second launcher-handoff delay. After lane clearance, the fired gem becomes a normal simulation body regardless of remaining velocity. Existing motion constants are unchanged.
- An unrelated merge no longer overwrites the in-flight state. Only consumption of the actual active shot may take that merge-driven transition.
- `SPAWNING_NEXT` defensively demotes a stale active marker before creating exactly one replacement. Target collection preserves any waiting/in-flight launcher marker, pauses input, and resumes generation after collection.
- Danger failure and final victory remain terminal. First-target collection is a temporary intentional pause, not a cap.

## HUD repairs from the video

- NEXT preview contain bounds changed from `96 x 82` to `76 x 66`, centered in the supplied NEXT cream area. Aspect ratio is preserved and no crop or circular mask is used.
- GOAL now uses the approved blank cream panel region `(38,620,550,190)` and red header region `(46,428,530,142)` from `assets/buttons/Generated image 10.png`. Layout is body `(253,222,214,74)`, header `(262,188,196,52)`, with a centered `54 x 50` contain box. The former hardcoded `+48,+3` gem offset is removed.
- Target collection ends at the centered GOAL body coordinate `(360,259)`.
- Settings uses the approved cog region `(276,832,180,180)` at `88 x 88` design pixels.
- Restart uses the literal supplied `RESTART` artwork from `assets/ui/Generated image 3.png`, region `(321,1128,300,100)`, drawn at native 3:1 ratio in `(472,231,138,46)`. Asset review confirmed there is no supplied circular restart/refresh icon; available arrow icons are BACK controls and are not reused.
- A local 360 x 640 render capture confirmed these elements remain within the top HUD, while the table stays bottom-aligned and the background has no black bars.

## Validation

- Godot 4.6.3 headless parse/import: passed.
- `CLEAN_CONTACT_TESTS`: passed, including NEXT/GOAL containment, centered collection destination, settings bounds, and RESTART asset/aspect assertions.
- `LEVEL_1_FLOW_TESTS`: passed, including cyclic generation, post-restart generation, a fired gem that remains moving, an unrelated merge during a shot, exactly one replacement, missing-marker recovery, target collection during a shot, and forty production `_process()` cycles.
- `GEM18_CHAIN_TESTS`: passed.
- `MOTION_PROFILE`: passed; zero per-gem callbacks and zero gameplay resource loads after initialization.
- Known Godot headless cleanup warnings followed successful test assertions.
- The optional ADB device query did not complete; installation and on-device launch are not claimed.

## APK

- File: `build/android/video-verified-unlimited-launcher-hud-v1.apk`
- Size: `102,335,924 bytes`
- Modified: `2026-07-31 09:38:41 +05:00`
- SHA-256: `F171F69976E0B13A8FB82E4329689553BD01C823913C731315FD056DD695782C`
- ZIP verification: `AndroidManifest.xml`, `classes.dex`, and `lib/arm64-v8a/libgodot_android.so` are present.

## Preserved systems

Table artwork/geometry, bottom anchoring, rails, perspective scaling, collision radii, contact-only merge eligibility, motion speed/damping/restitution/friction, score, L7 then L8 targets, launcher bag, danger semantics, audio, and haptics are unchanged.
