# Current State

**Phase:** Clean Gameplay Milestone 2 chain-merge polish delivered at commit `10f8d59408cccd6287d308f5fc0ab0046326ea3a`, tagged `clean-contact-merge-v2-chain-polish`.

## Verified Working Now

- This task began from clean commit `53306bf1f9d96fbb6918380657dd611ed1a7a51e`, tag `clean-contact-merge-v1-spawn-fix`, and delivered the confirmed standalone APK `build/android/clean-contact-merge-v2-chain-polish.apk` (27,711,469 bytes, 2026-07-29 03:44:48 +05:00).
- Empty board, one active launcher, drag/release, borders, visual-only danger line, and settlement-gated one-time queue advance remain covered by the headless suite.
- v2 preserves contact-only same-level merging, adds capped local contact chains, and uses presentation-only effects.

## Do Not Regress

- Only `SPAWNING_NEXT` can create a launcher; idle settled frames must not spawn.
- Never merge distant or cross-level gems, reuse stale pairs, or perform board-wide chain scanning.
- Presentation must never alter collision, positions, IDs, or merge candidates.
- Do not spawn a launcher until pieces are settled and merge presentation is complete.

The verified milestone source is commit `ac795736bbecb4ee83c346a2717276d66a2b483c`, tagged `clean-contact-merge-v1`. Its standalone APK is `build/android/clean-contact-merge-v1.apk` (27,707,373 bytes, built 2026-07-29 03:12:46 +05:00). Godot parse/import validation, headless integration tests, and Android export passed. No phone was connected, so device testing has not occurred.

Implemented scope: empty-board launcher, horizontal drag, negative-Y shot, visual-only danger line, top/side containment, settlement-gated next launcher, and current-contact-only gem merges. Do not modify merge behavior without a specific task and targeted regression tests. Chains, scoring, loss/win, sounds, menus, persistence, ads, and final art remain out of scope.

The verified spawn-lifecycle source is commit `53306bf1f9d96fbb6918380657dd611ed1a7a51e`, tagged `clean-contact-merge-v1-spawn-fix`. Its standalone APK is `build/android/clean-contact-merge-v1-spawn-fix.apk` (27,707,373 bytes, built 2026-07-29 03:23:14 +05:00). The launcher now follows `READY_TO_AIM → SHOT_IN_FLIGHT → RESOLVING → SPAWNING_NEXT → READY_TO_AIM`; one active launcher exists at a time and the queue advances once per completed shot. Headless parse/import validation and integration tests passed. No Android device was connected, so the APK has not been installed or tested on-device.
