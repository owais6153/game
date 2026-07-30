# Physics and Pacing Parity v1 Report

## Baseline and scope

- Starting verified source: `4bb5469456bf23480b569a15b9c44c7692e30257` / `gameplay-balance-v1`.
- Scope: board proportions, collision feel, merge presentation/momentum, and pacing only.
- Explicitly preserved: current-step same-level contact-only merges, cross-level/distant rejection, local contact-only chains, one-launcher lifecycle, scoring, win/fail, restart, and Pearl -> Ruby -> Emerald -> Sapphire -> Diamond mapping.

## Video comparison evidence

Both root-level MP4 inputs were opened locally in Movies & TV for review and are excluded from Git.

| Recording | Role | Native metadata | Evidence used |
| --- | --- | --- | --- |
| `WhatsApp Video 2026-07-28 at 2.47.02 AM.mp4` | Target/reference | 1:19, 1280x576, 23.99 fps, 1,743 kbps | Wider table composition, compact cluster/push expectation, quick continuous shot cadence. |
| `WhatsApp Video 2026-07-29 at 6.53.59 AM.mp4` | Current build | 0:38, 720x1624, 23.99 fps, 354 kbps | Portrait fixed-canvas game, previous narrow/tall presentation and slower resolution rhythm. |

The recordings are user-supplied reference evidence only; no video or image asset was imported into the game. The local viewer did not expose frame-export capability, so the report records direct local opening plus Windows metadata rather than claiming saved frame extraction.

## Constants changed

| Area | Before | After | Reason |
| --- | ---: | ---: | --- |
| Board horizontal bounds | 56..664 | 30..690 | More lateral room for compact clusters. |
| Top / bottom / danger / launch Y | 150 / 1170 / 1010 / 1100 | 144 / 1166 / 1006 / 1102 | Preserves portrait gameplay room while aligning the wider board. |
| Gem radius | 35 | 42 | Stronger table occupancy without changing level/rule semantics. |
| Launch speed / damping | 1100 / 285 | 1160 / 235 | Faster clear shot with less premature slowdown. |
| Normal collision restitution | 0.48 | 0.34 | Softer push and less ping-pong. |
| Tangential contact resistance | none | 0.18 | Controlled rolling/sliding and compact settling. |
| Wall restitution (side/top/bottom) | .20/.14/.10 | .16/.10/.08 | Containment with less wall bounce. |
| Separation epsilon | .15 | .10 | Less visible post-contact snap. |
| Merge source/presentation | .10/.20 s | .11/.18 s | Smoother inward read with less total wait. |
| Merge momentum handoff | zero | 35%, capped 260 px/s | Keeps an upgraded gem connected to its impact but bounded. |
| Chain stagger / ready delay | .07/.08 s | .05/.04 s | Faster rhythm without allowing early/duplicate spawns. |

## Runtime/debug coverage

The headless controller/simulation suite exercises: top shot, side-wall containment, direct same-level merge, contact chain, launcher cardinality/idle frames, score/win/fail/reset, plus new portrait scale and bounded-momentum cases. The deterministic physics scenarios represent the requested two-piece, cluster, consecutive-shot, and settled-board safety checks; no connected phone was available for subjective touch/FPS review.

## Validation and delivery

- Godot 4.6.3 parse/import validation: passed.
- Headless suite: passed after parity changes (`CLEAN_CONTACT_TESTS: PASS`).
- Android standalone APK: `D:\Owais\game\build\android\physics-pacing-parity-v1.apk`, 27,728,010 bytes, modified 2026-07-29 07:25:11 +05:00.
- Source commit/tag: `3bba78f32f3994ff4d9b103cac3f8a2fd983e44b` / `physics-pacing-parity-v1`.
- Device status: `adb devices -l` found no connected device; no install or launch was attempted.

## Remaining differences and phone checklist

- The game remains procedural and asset-free; this task did not add sounds, haptics, external gem art, progression, ads, saves, or a UI redesign.
- On phone: test a top shot, side-wall shot, direct merge, chain merge, 10 consecutive shots, and a crowded cluster. Confirm no long wait, jitter, duplicate launcher, distant merge, or cross-level merge.
