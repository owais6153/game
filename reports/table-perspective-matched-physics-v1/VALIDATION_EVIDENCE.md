# Table Perspective Matched Physics v1 — Validation Evidence

This delivery uses the deterministic headless simulation suite. No device was connected, and no screenshots are claimed.

## Automated evidence

- `CLEAN_CONTACT_TESTS: PASS`: validates table-local perspective scale bounds and monotonicity, equal visual/physics scale, rail containment with the scaled radius, same-tier contact merge, and different-tier non-merge contact.
- `GEM18_CHAIN_TESTS: PASS`: validates every L1–L18 transition, terminal L18 behavior, and contact-only chain safety.
- `LEVEL_1_FLOW_TESTS: PASS`: validates the existing Level 1 launcher and resolution lifecycle.
- `MOTION_PROFILE: PASS`: confirms no per-gem process callbacks and zero gameplay resource loads after initialization.

## Performance profile

| Scenario | Average process time | Worst process time |
| --- | ---: | ---: |
| Empty-board launch | 0.038 ms | 0.143 ms |
| Repeated launch | 0.054 ms | 1.159 ms |
| 10 active gems | 0.286 ms | 0.706 ms |
| 20 active gems | 0.639 ms | 2.046 ms |
| Crowded-board merge path | 0.630 ms | 1.682 ms |

The requested bottom/middle/top scale, center/left/right rail travel, and visual-contact checks are represented by deterministic fixtures. They must still be visually confirmed by installing the APK on the target phone.
