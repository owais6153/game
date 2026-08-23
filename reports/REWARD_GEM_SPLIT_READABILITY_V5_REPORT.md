# Reward Gem Split Readability V5 Report

Date: 2026-08-23

## Outcome

Reward gems no longer reveal from behind the merge result or become noticeable only after reaching a separate board position. A confirmed result now visibly releases complete real gem artwork from its own live position: the output begins at 0.48 scale above the result, fans outward with source recoil and a short color-matched tether, reaches 1.12, settles to 1.00, and then enters physics. Two-piece output uses different eligible tiers whenever possible, so the split reads as multiple gems instead of duplicate copies.

The first physical contact after release is now readable. New reward bodies remain visually held for 780 ms, launch at 135 px/s, and spend 650 ms resolving physical collisions without confirming another merge. Once grace expires they use the ordinary contact-only merge path. Existing hard bounds remain three generated pieces per player shot, no new generation above chain depth 2, and no reward creation above 24 live-plus-pending pieces.

Target reward staging is also corrected: unrevealed coins follow the live result gem rather than retaining a stale confirmation midpoint, every non-final four-coin group holds together for 1.20 s, the final 16-coin pile holds together for 1.00 s, and coin shadows follow current token positions. The final target gem holds at center for 1.05 s with `TARGET COMPLETE!` readable across the hold.

## Central tuning changes

| Setting | Before | After | Recorded safe range |
|---|---:|---:|---:|
| Reward start delay | 0.20 s | 0.28 s | 0.25-0.32 s |
| Visual split/physics hold | 0.34 s | 0.78 s | 0.70-0.85 s |
| Start/peak scale | 0.28 / 1.18 | 0.48 / 1.12 | 0.42-0.55 / 1.08-1.16 |
| Release impulse | 165 px/s | 135 px/s | 120-150 px/s |
| Post-release merge grace | 180 ms siblings only | 650 ms for any fresh-reward contact | 550-700 ms |
| Chain presentation spacing | 180 ms | 260 ms | 240-300 ms |
| Non-final target coin hold | 260 ms | 1.20 s | 1.00-1.40 s |
| Final coin-pile hold | 380 ms | 1.00 s | 0.90-1.20 s |
| Final hero/caption hold | 420 / 620 ms | 1.05 / 1.30 s | 0.95-1.20 / 1.20-1.40 s |
| Gem shadow opacity | 0.34 | 0.50 | 0.46-0.55 |
| Target/final coin shadow opacity | 0.32 | 0.46 | 0.42-0.50 |

All tuning remains centralized in `GameConfig`. Normal merge collision geometry, the 420 ms result timeline, gem radii, table rails, launcher behavior, authoritative score/coin changes, target rules, persistence, audio, and haptics were not retuned.

## Ownership and safety

- Reward objects remain persistent `GemPiece` instances created once in the controller and owned by `pieces`.
- Extraction scale/offset/elevation/tether and all shadows are presentation-only inside `GemSpriteLayer`.
- The activation gate and release grace change timing only; physical contact response still runs during grace, and ordinary merge eligibility returns automatically on expiry.
- Target-coin re-anchoring stops before reveal and cannot alter awarded value, target progress, or the result gem position.
- No asset was added or modified. The existing supplied runtime gem-shadow texture and existing coin artwork are reused.
- Audio/haptic services and confirmed-event mappings are unchanged.

## Regression coverage

`tests/run_reward_feedback_v3_tests.gd` now asserts:

- first-frame reward elevation and merge-origin offset;
- visible outward travel and growth rather than teleporting;
- cleanup of extraction records;
- distinct eligible tiers for multi-gem output;
- full visual activation hold and stored impulse release;
- physical collision before follow-up merge eligibility;
- expiry back to ordinary confirmed merging;
- unchanged shot/depth/population cascade bounds;
- live-result target-coin anchoring and complete group holds;
- final hero/caption timing, complete final pile visibility, input lock, exactly-once economy, persistence, and full reset;
- visibly exposed gem and coin shadow tuning.

All nine repository suites pass under Godot 4.6.3 headless: AdMob integration, animation/audio/Back/privacy, branding/push-line, game-flow/reward/splash, reference game feel, reward feedback, scene variety/assets, sound/privacy-link, and UI scale/layout. Godot returns process code 1 after these SceneTree test harnesses even when they print PASS; the explicit suite markers are the recorded results.

## Visual verification

Godot 4.6.3 GL Compatibility switched to ANGLE on Intel HD Graphics 620 and completed `REWARD_FEEDBACK_V3_CAPTURE: PASS`. The capture contains 33 PNGs under `reports/reward-gem-extraction-v5/screenshots/`.

Primary reviewed frames:

- `normal-576ms-gem-extracting-from-result.png`: one complete lower-tier gem visibly separating in front of the result.
- `combo2-1096ms-gem-extracting-from-result.png`: different red and blue sibling tiers splitting around the green result.
- `target-all-coins-table-hold.png`: all four coins held together directly below the current target result, with current-position shadows.
- `final-0900ms-phaseC-readable-label.png` and `final-1350ms-phaseC-center-hold.png`: the hero gem and caption remain legible at center.
- `final-2750ms-all-coins-table-hold.png` and `final-3350ms-all-coins-table-hold.png`: all 16 final coins remain together on the table.

The reviewed frames show the supplied gem shadow extending below gem silhouettes and dark contact ellipses below landed coins. No connected Android device validation is claimed yet.

## Delivery

Source commit/tag, full nine-suite validation, APK filename/hash/signature/ABI checks, connected-device status, and delivery commit/tag are recorded here when the milestone is finalized.
