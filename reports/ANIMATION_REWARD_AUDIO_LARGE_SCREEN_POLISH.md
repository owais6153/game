# Animation, Reward, Audio, and Large-Screen Polish

Date: 2026-08-18

## Video comparison

The root files were identified as `current-gameplay-ours.mp4` and `refrence.mp4`. Both files were decoded end to end with the repository's existing local FFmpeg binary. The Majestic Gems capture is 33.12 s at 576x1312/55.92 fps with 48 kHz mono audio; the reference is 59.24 s at 360x640/30 fps with 48 kHz stereo audio. Review used full-timeline 0.5 s contact sheets, focused 10 fps launch/merge/target/reward sequences, and complete audio waveforms. No conclusion is based on one screenshot.

### Animation findings

- Launch: Majestic Gems reacts immediately, removes the guide cleanly, and updates Next without delaying shot availability. The reference adds slightly more launcher/object motion, but the current launch is clearer and less busy. The current capture did not show a strong launch squash; the existing 0.16 s launch ring and 0.16 s Next fade/scale response are appropriate to retain.
- Collision: Majestic Gems reads heavier and more controlled. The reference's dense pile produces constant visible micro-motion, but also looks busier and lighter. The current capture's meaningful contacts had little visible deformation, confirming the need for the new bounded 0.11 s collision compression without changing physics.
- Merge: The reference makes merge moments more obvious through a fast result pop, white flash, and immediate coin shower. The captured Majestic Gems merge/target event already has a clear flash/ring and readable reveal, but the pre-task 0.36 s result beat felt softer and slower. The implemented 0.30 s sequence and 1.18x overshoot close that gap without rubber motion.
- Target collection: Majestic Gems already performs the safer production pattern: the confirmed result becomes a duplicate visual, follows a curved 0.40 s path to Target, fades/scales, triggers Target confirmation, then hands off to the next sequential objective. This is cleaner and more legible than moving a live physics body.
- Reward: The reference uses large, frequent multi-coin sprays. Majestic Gems uses four lightweight target-only coins, staggered arrivals, authoritative HUD reconciliation, and a final counter pulse. It is less spectacular but substantially less cluttered and better bounded for low-end devices; reward values remain unchanged.
- Level complete: The reference ends with its largest coin shower and a strong visual transition. The supplied Majestic Gems capture does not reach level completion, so direct video parity is not claimed. Code inspection confirms the existing final-target confirmation, coin-flight wait, 0.24 s hold, result cue, and 0.72 s collect/count-up flow remain intact.
- General motion: The reference feels more continuously alive because its board is already crowded and reward effects occur frequently. Majestic Gems is calmer by design. Target flight, Target handoff, Next entry, merge effects, coin arrivals, and HUD pulses already provide the right production motion hierarchy without adding idle loops or full-screen effects.

### Audio findings

- Majestic Gems measures -21.7 LUFS integrated with 14.7 LU range over the complete capture; the reference measures -11.5 LUFS with 6.3 LU range. Both screen recordings reach 0 dB sample peak, while true-peak analysis reports +0.5 dBTP for Majestic Gems and +4.5 dBTP for the reference. The reference is roughly 10 LU louder and visibly more compressed/clipped, so matching its absolute loudness would be a regression.
- Majestic Gems preserves more hierarchy and space: collisions remain subordinate, launch is brief, and the target merge/reward peak stands out clearly in the waveform. The reference maintains higher continuous energy but its frequent collision/coin layers compete more often.
- The remaining audio gap is perceived energy, not missing identities. The current supplied music, immediate merge attack, tiered target cue, supplied coin sound, collision filtering, and final success cue already form a coherent mix. No sound replacement or gain change was justified by this comparison.

Existing analyses in `REFERENCE_ANIMATION_AUDIO_POLISH_V4_REPORT.md`, `PHYSICS_REWARD_FEEDBACK_V1_REPORT.md`, `SOUND_MAPPING_CORRECTION_V2_REPORT.md`, and `MERGE_SOUND_SYNC_FIX_V3_REPORT.md` remain supporting evidence. The remaining code-level gaps were the 0.36 s merge outside the requested 0.25-0.32 s band and disabled collision visual micro-feedback.

## Animation tooling

- Global Tweens restored: YES (already present as `GlobalTweens` autoload before this task).
- Tween Composer restored: NO. Its source remains preserved in the repository, but the editor plugin is disabled and runtime code does not reference it. Current bounded effects are cleaner in existing controller/native tween paths.
- Godot compatibility: existing Global Tweens parses under Godot 4.6.3. New feedback uses built-in transforms only.
- Later correction: this package-size conclusion was wrong. `HomeOverlayLayer` preloads and instantiates Tween Composer for the Home logo, so excluding `tween_composer/*` removed a production Android dependency. The exclusion is removed by the last-AAB Home regression correction; this v2 APK must not be used as a valid Home-flow baseline.

## Final animation timings

- Merge: 0.30 s total; 0.07 s source pull; result 0.68x -> 1.18x over 0.15 s, then bounded settle.
- Collision: 0.11 s; 1.8-5.5% compression by impact strength; 0.10 s per-piece cooldown.
- Target collection: retained 0.40 s.
- Target card: retained 0.52 s pulse and 0.26 s transition start.
- Coins: retained four visuals, 0.16 s burst, 0.92/1.00 s flight, 0.08 s flight stagger, and 0.14 s HUD pulse.
- Level complete: existing result/reward flow retained; reward/progression/ad state was not changed.
- Next gem: retained 0.16 s spawn response and 0.02 s ready delay.

## Audio

No sound identity or mix value changed. The current supplied music, supplied coin cue, trimmed immediate ordinary-merge cue, tiered target merge cues, launch cue, gem/rail collision cues, target arrival, and final success cue were retained. Confirmed contact thresholds, 65/90 ms audio cooldowns, five priority voices, and the SFX limiter remain active. Merge-consumed contact pairs remain suppressed so collision audio does not double the merge cue. Music and SFX buses remain separate; UI taps intentionally share the priority-managed SFX bus rather than adding a third bus with no distinct processing need.

## Large screen

The project targets SDK 36, uses `canvas_items` with `expand`, keeps portrait phone orientation, and exports `package/app_category=2` (Godot's Game selection). AAPT proves the generated application has `android:appCategory=game`; the main activity has `screenOrientation=portrait`, `resizeableActivity=true`, and no `minAspectRatio` or `maxAspectRatio` restriction. Official Android 16 guidance says orientation/resizability/aspect restrictions are normally ignored on `sw600dp` large screens, but games declared through `android:appCategory` are an exception. The Play warning is triggered by the remaining portrait declaration even though resizability is already enabled; it is a compatibility recommendation, not evidence that the game category or resizable flag is missing.

Official references:

- https://developer.android.com/about/versions/16/behavior-changes-16
- https://developer.android.com/develop/adaptive-apps/guides/app-orientation-aspect-ratio-resizability
- https://developer.android.com/games/develop/multiplatform/support-large-screen-resizability

No manifest hack or temporary opt-out was added. The current adaptive path centers the authoritative fixed-width table in additional canvas width, cover-fills the tropical background, and leaves table X scale unchanged. Tests cover 1280x1280, 1600x1280, and 1920x1280 virtual wide canvases for centered table geometry, contained rails, and zero horizontal stretch. Phone portrait behavior remains unchanged. Emulator/device verification was unavailable, so tablet and foldable behavior is statically validated, not physically proven; the Play warning cannot be guaranteed to disappear without a new Play artifact upload, which was explicitly out of scope because no AAB was requested.

## Regression

- Godot 4.6.3 editor import/parse: PASS.
- `UI_SCALE_LAYOUT_TESTS: PASS` including timing bounds and wide containment.
- `SOUND_PRIVACY_LINK_TESTS: PASS` including contact throttling/mapping.
- `GAME_FLOW_REWARD_SPLASH_TESTS: PASS` including merge, target, reward, ads, and reset boundaries.
- The fresh audit rerun produced all three PASS sentinels. Each Windows runner then returned the repository's known post-sentinel teardown access violation (`-1073741819`); no assertion failed.
- Final APK export: PASS. `build/android/majestic-gems-animation-large-screen-polish-v2.apk`, 81,304,035 bytes, SHA-256 `9132197FB131F8367577573F9D01716AAB95875617975C707148E33174D4A1CA`.
- Package-size result: 16,676 bytes smaller than the first polish APK and 15,108 bytes smaller than the pre-polish immediate-merge source APK. Tween Composer entries: 0; Global Tweens entries: 2. Animation/package regression: NO.
- AAPT: package/version/API PASS; manifest confirms game category, portrait, and resizable activity.
- APK Signature Scheme v2: PASS with one Godot RSA-2048 debug signer.
- ADB: no connected device; install/launch/listening/haptics and physical large-screen behavior are not claimed.
- No AAB was generated. The release AAB preset was restored after the APK export.

## Scope freeze

No physics constant, collider, launch/aim rule, merge eligibility, target/progression rule, coin value, save format, gem asset, UI hierarchy, AdMob setting, UMP setting, or AAB/version metadata was changed.
