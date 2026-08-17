# Animation, Reward, Audio, and Large-Screen Polish

Date: 2026-08-18

## Video comparison

The intended root files were identified as `current-gameplay-ours.mp4` and `refrence.mp4`. A fresh full-playback comparison could not be completed: FFmpeg/FFprobe were unavailable on PATH and the Windows computer-use native pipe was unavailable. No single-frame judgment is claimed. Existing frame/audio analyses in `REFERENCE_ANIMATION_AUDIO_POLISH_V4_REPORT.md`, `PHYSICS_REWARD_FEEDBACK_V1_REPORT.md`, `SOUND_MAPPING_CORRECTION_V2_REPORT.md`, and `MERGE_SOUND_SYNC_FIX_V3_REPORT.md` were used as supporting evidence.

Those verified milestones already supply target collection flight, Target pulse/handoff, four target-only coin visuals, coin counter arrivals/pulse, next-gem spawn response, continuous music, immediate ordinary-merge attack, tiered target merge cues, collision thresholds/cooldowns, and priority-limited SFX voices. The remaining code-level gaps were a 0.36 s merge outside the requested 0.25-0.32 s band and disabled collision visual micro-feedback.

## Animation tooling

- Global Tweens restored: YES (already present as `GlobalTweens` autoload before this task).
- Tween Composer restored: NO. Its former idle use was deliberately removed, current bounded effects are cleaner in existing controller/native tween paths, and the export excludes `tweens/*`.
- Godot compatibility: existing Global Tweens parses under Godot 4.6.3. New feedback uses built-in transforms only.
- Packaging impact: no new plugin, image, particle texture, shader, or sound asset was added. Expected incremental payload is code-only and negligible.

## Final animation timings

- Merge: 0.30 s total; 0.07 s source pull; result 0.68x -> 1.18x over 0.15 s, then bounded settle.
- Collision: 0.11 s; 1.8-5.5% compression by impact strength; 0.10 s per-piece cooldown.
- Target collection: retained 0.40 s.
- Target card: retained 0.52 s pulse and 0.26 s transition start.
- Coins: retained four visuals, 0.16 s burst, 0.92/1.00 s flight, 0.08 s flight stagger, and 0.14 s HUD pulse.
- Level complete: existing result/reward flow retained; reward/progression/ad state was not changed.
- Next gem: retained 0.16 s spawn response and 0.02 s ready delay.

## Audio

No sound identity or mix value changed. The current supplied music, supplied coin cue, trimmed immediate ordinary-merge cue, tiered target merge cues, launch cue, gem/rail collision cues, target arrival, and final success cue were retained. Confirmed contact thresholds, 65/90 ms audio cooldowns, five priority voices, and the SFX limiter remain active. Merge-consumed contact pairs remain suppressed so collision audio does not double the merge cue.

## Large screen

The project targets SDK 36, uses `canvas_items` with `expand`, keeps portrait phone orientation, and exports `package/app_category=2` (Game). Official Android 16 guidance says orientation/resizability/aspect restrictions are normally ignored on `sw600dp` large screens, but games declared through `android:appCategory` are an exception. The Play message is therefore best treated as a compatibility recommendation, not proof that the game category is absent.

No manifest hack or temporary opt-out was added. The current adaptive path centers the authoritative fixed-width table in additional canvas width, cover-fills the tropical background, and leaves table X scale unchanged. Tests cover 1280x1280, 1600x1280, and 1920x1280 virtual wide canvases for centered table geometry, contained rails, and zero horizontal stretch. Phone portrait behavior remains unchanged. Emulator/device verification was unavailable, so tablet and foldable behavior is statically validated, not physically proven; the Play warning cannot be guaranteed to disappear without a new Play artifact upload, which was explicitly out of scope because no AAB was requested.

## Regression

- Godot 4.6.3 editor import/parse: PASS.
- `UI_SCALE_LAYOUT_TESTS: PASS` including timing bounds and wide containment.
- `SOUND_PRIVACY_LINK_TESTS: PASS` including contact throttling/mapping.
- `GAME_FLOW_REWARD_SPLASH_TESTS: PASS` including merge, target, reward, ads, and reset boundaries.
- The suite wrapper returned exit 1 after all PASS sentinels because of the repository's existing teardown condition; no test assertion failed.
- APK export: PASS. `build/android/majestic-gems-animation-large-screen-polish.apk`, 81,320,711 bytes, SHA-256 `DAC8A7210CD5BADA6F1D6862613877ED61C8FEBB25BDDA31596FE7F647714B7E`.
- AAPT: package/version/API PASS; manifest confirms game category, portrait, and resizable activity.
- APK Signature Scheme v2: PASS with one Godot RSA-2048 debug signer.
- ADB: no connected device; install/launch/listening/haptics and physical large-screen behavior are not claimed.
- No AAB was generated. The release AAB preset was restored after the APK export.

## Scope freeze

No physics constant, collider, launch/aim rule, merge eligibility, target/progression rule, coin value, save format, gem asset, UI hierarchy, AdMob setting, UMP setting, or AAB/version metadata was changed.
