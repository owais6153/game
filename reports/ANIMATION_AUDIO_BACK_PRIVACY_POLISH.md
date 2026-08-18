# Animation, Audio, Back, and Privacy Polish

Date: 2026-08-18

## Scope and reference review

This pass changes presentation and navigation only. Gem art/identity, board dimensions, physics, merge and target rules, difficulty, rewards, saves, AdMob, UMP, package name, and production signing are unchanged.

The three supplied recordings were reviewed as timing and behavior references. In the 90.56-second Majestic Gems capture, an ordinary target merge completed its target/coin feedback in roughly 0.3-0.4 seconds and the final target reached the result overlay in roughly 1.0 second. In the 59.24-second reference capture, reward/coin motion remained readable for roughly 0.8-1.1 seconds and overlapped continued play. The 32.17-second Majestic Gems capture reproduced two navigation defects: Back on Home immediately backgrounded/terminated the app, and reopening could resume directly in gameplay instead of preserving the Home/level-intro flow. The reference is used only for rhythm; no proprietary art or audio was copied.

## Animation

| Feedback | Previous | Final | Notes |
| --- | ---: | ---: | --- |
| Collision response | 110 ms | 140 ms | Fast, subtle scale/shadow response; physics is untouched. |
| Merge | 270 ms | 540 ms | 0-100 ms contact, 100-200 ms pull/combine, reveal and chime at 200 ms, 200-380 ms pop, 380-540 ms settle. |
| Major merge tail | 360 ms | 620 ms | Lightweight sparkle tail; never gates simulation. |
| Target collection | 320 ms | 700 ms | 100 ms confirmation, 520 ms eased UI-duplicate travel, then arrival/hold. |
| Target card pulse | implicit/brief | 220 ms | Arrival pulse occurs with the target-success cue. |
| Coins | short simultaneous burst | 4 visuals over about 980 ms | Start at 260 ms, 80 ms stagger, 550 ms travel (620 ms for major reward), 180 ms counter pulse. |
| Final target to result flow | about 1.0 s in recording | about 1.66 s | Includes target travel, reward motion, and a 420 ms readable hold. |
| Next gem | 220 ms | 220 ms | Responsive fade/scale transition retained. |

Confirmed gameplay state remains authoritative. The merge presentation, target UI duplicate, particle tail, coin travel, audio, and Next transition overlap. Target presentation is queued exactly once per confirmed result and begins 300 ms into the merge; launcher readiness no longer waits for presentation completion. The real physics gem is removed at the confirmed target transition, while a visual duplicate completes the UI journey. No long serialized `await` chain was introduced.

The level reward lookup is unchanged: result levels 2-8 award 10, 25, 60, 150, 350, 800, and 1800 coins respectively. Four coin visuals represent the presentation only and do not determine the reward value.

## Audio

`AudioFeedbackService` remains the only runtime audio owner. It retains the bounded five-voice SFX pool, Music/SFX buses, limiter, initialization-time cache, and settings controls.

- Gem contact now uses `gem_collision_soft_v1.ogg`, a 280 ms non-destructive derivative with a softer attack, reduced 2.8 kHz presence, 5.2 kHz low-pass, and fade tail. Event gain is `0.18`, pitch is `0.94-1.00`, minimum impact is `195`, global cooldown is 120 ms, and per-contact cooldown is 140 ms.
- Rail contact now uses `rail_collision_soft_v1.ogg`, a 300 ms derivative with a rounder attack, reduced 2.3 kHz presence, 4.2 kHz low-pass, and fade tail. Event gain is `0.16`, pitch is `0.92-0.98`, minimum impact is `250`, and global/per-contact cooldown is 140 ms.
- Normal merge retains its approved immediate supplied identity at gain `0.70`, but the main chime is delayed to the 200 ms resulting-gem reveal instead of being fired at contact.
- Target arrival now has a separate generated soft harmonic crystal chime with a delayed shimmer at gain `0.82`. It is deliberately brighter and higher priority than collision cues without reusing their identity.
- Full target completion uses the 720 ms `target_complete_soft_v1.ogg` derivative of the preserved supplied fairy-sparkle source at gain `0.78`; it does not fire for every progress step.
- Intermediate coin arrivals use a short procedural tick at gain `0.38`; the final arrival uses the approved coin-reward cue at gain `0.72`.
- Accepted level completion remains the strongest short cue at gain `0.92`. Background music remains supportive at `0.06`.

Low-energy impacts are silent, repeat contacts are keyed by contact pair, exact merge pairs suppress collision audio, and five-player priority arbitration prevents contacts from stealing reward voices. The final priority/mix order is music, contact/rail, launch, merge, target arrival/coins, target completion, and level completion.

### Runtime derivative provenance

| Runtime derivative | Preserved source | SHA-256 |
| --- | --- | --- |
| `assets/runtime/audio/gem_collision_soft_v1.ogg` | `assets/sound/gems-colide.mp3` | `0671D9648211C0012E3BAB613D55ABB63734D451D000FE401AB4E3EF0B781871` |
| `assets/runtime/audio/rail_collision_soft_v1.ogg` | `assets/sound/gems-rail-colide.mp3` | `91857B7CC4EF0294A60CDD50158602771847F71E839BF1E501000BEFBE942850` |
| `assets/runtime/audio/target_complete_soft_v1.ogg` | `assets/sound/mixkit-fairy-arcade-sparkle-866.wav` | `2B0A07FAB59A84F4050148A449D7E9B6B85B4E0990114DEA9EB344048499171E` |

The original files are preserved. Final loudness/timbre still needs a manual phone-speaker listening pass because automated dummy-audio tests cannot prove perceived loudness.

## Back button

Proper Back functionality is **newly implemented, not restored**. Earlier controller code attempted to observe the window notification, but the project still used Godot's default Android auto-quit behavior. Consequently, the OS could terminate/background the Activity before the app's UI-state navigation was authoritative. This pass sets `application/config/quit_on_go_back=false`, receives `NOTIFICATION_WM_GO_BACK_REQUEST`, maps desktop Escape to the same dispatcher, and consumes duplicate platform events within 350 ms.

Godot documents `NOTIFICATION_WM_GO_BACK_REQUEST` as the Android Back request and documents `application/config/quit_on_go_back` as the default auto-exit switch: [Window notifications](https://docs.godotengine.org/en/4.6/classes/class_window.html) and [handling quit requests](https://docs.godotengine.org/en/4.0/tutorials/inputs/handling_quit_requests.html).

Deterministic behavior:

| Current state | Back result |
| --- | --- |
| Home exit confirmation | Close confirmation. |
| Home Settings | Close Settings and remain on Home. |
| Home level-intro popup | Return to Home without starting/resuming gameplay. |
| Pause/Settings during gameplay | Close it and resume the underlying game. |
| Active gameplay | Open the existing Pause/Settings overlay. |
| Level Ready | Return Home. |
| Level Complete/result modal | Consume Back; required progression/reward actions cannot be bypassed. |
| Bare Home | Show a lightweight Cancel/Exit confirmation; only explicit Exit shuts down ads and quits. |

The existing external Privacy Policy path remains an OS browser action, so system Back returns from the browser to the unchanged Home screen. Conditional native UMP Privacy Options remain owned by UMP. Automated state tests pass; no Android device was connected, so physical gesture/button verification is not claimed.

## Privacy alignment

The visible text was left-biased even though the link node's anchors were centered. The root cause was a fixed 180-pixel minimum-width `LinkButton` whose text layout remained left aligned inside that box. The fix removes the artificial width and applies centered shrink/container sizing, while retaining the original typography, location, safe-area calculation, URL action, and UI design.

Real Godot viewport captures verify balanced alignment and centered exit UI at the supplied-phone aspect and a taller supported portrait aspect:

- `reports/animation-audio-back-privacy-polish/home-privacy-576x1312.jpg`
- `reports/animation-audio-back-privacy-polish/home-exit-confirmation-576x1312.jpg`
- `reports/animation-audio-back-privacy-polish/home-privacy-720x1600.jpg`
- `reports/animation-audio-back-privacy-polish/home-exit-confirmation-720x1600.jpg`

Automated geometry coverage also checks 576x1312, 720x1280, 720x1600, and 1080x2400. The capture helper saved all four proof frames but the hidden Windows renderer later reported an access violation during teardown; the saved images were manually inspected and the independent layout tests pass.

## Regression evidence

Godot 4.6.3 headless reached all eight PASS sentinels:

- `ADMOB_INTEGRATION_TESTS: PASS`
- `ANIMATION_AUDIO_BACK_PRIVACY_POLISH_TESTS: PASS`
- `BRANDING_PUSH_LINE_TESTS: PASS`
- `GAME_FLOW_REWARD_SPLASH_TESTS: PASS`
- `REFERENCE_GAME_FEEL_V2_TESTS: PASS`
- `SCENE_VARIETY_ASSETS_TESTS: PASS`
- `SOUND_PRIVACY_LINK_TESTS: PASS`
- `UI_SCALE_LAYOUT_TESTS: PASS`

Coverage includes exactly-once merge result and reward records, immediate authoritative target progression with arrival-timed HUD progression, correct classification of a rapid later merge, target presentation queueing, unchanged coin values, overlap while the next launcher is ready, collision filtering/cooldowns, Back priority, result lock, exit confirmation, Privacy geometry, AdMob shutdown guards, and the Android auto-quit project setting. The Windows Godot console runner retains the repository's known post-PASS teardown access-violation code for every suite, including unchanged suites; no assertion failed.

The real main scene also remained alive on the paused Home state for more than three minutes in a headless idle soak with no error or unexpected-transition output, then was stopped manually. This is useful local stability evidence but is not a substitute for Android lifecycle/device testing.

Android APK evidence will be appended after the milestone build. AdMob, UMP, saves, package identity, production keys, gem assets, board dimensions, physics, rules, rewards, and economy were not modified.
