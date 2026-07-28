# Clean Contact Merge v3 Playable Loop Report

## Baseline

Built from the clean, verified `clean-contact-merge-v2-chain-polish` milestone at `10f8d59408cccd6287d308f5fc0ab0046326ea3a`. Its full parse/import and headless contact suite was rerun successfully before this work began.

## Systems added

- Confirmed-merge-only scoring and HUD score display.
- Sequence-based chain multiplier display, reset only once the next launcher is ready.
- Target: create Diamond (L5), with one-shot win state and Replay overlay.
- Settled non-active lower-zone danger timer with 0.75-second grace, one-shot fail state, and Retry overlay.
- Full reset for restart, replay, and retry.

## Score and chain rules

| Result | Base score |
| --- | ---: |
| Ruby (L2) | 10 |
| Emerald (L3) | 25 |
| Sapphire (L4) | 60 |
| Diamond (L5) | 150 |

Each confirmed merge in the same resolver sequence receives the next multiplier: x1, x2, x3, and so on. Non-merge collisions score zero. The chain display returns to x1 when settlement produces the next ready launcher.

## Danger rules

The danger line is never colliding. Only a settled, non-active board gem whose lower edge remains below it for `GameConfig.DANGER_GRACE_DURATION` (0.75 seconds) fails. Moving, bouncing, presentation-only, merged/disappeared, and active launcher gems do not fail the level.

## Files changed

- `scripts/game_config.gd`
- `scripts/game_controller.gd`
- `tools/run_clean_contact_tests.gd`
- Project documentation and build provenance files

## Validation

- Godot parse/import validation: pending final export validation.
- Headless controller/simulation integration suite: passed (`CLEAN_CONTACT_TESTS: PASS`).
- Android standalone APK: pending final export.

## Known limitations

The board still uses built-in circles and primitive overlays. There are no final gems, sound, ads, saves, progression, menus, or on-device verification in this milestone.

## Phone checklist

1. Make one Pearl merge and confirm score +10.
2. Trigger a physical Ruby chain and confirm the second merge scores with x2.
3. Create Diamond and verify win blocks launches until Replay.
4. Leave a settled non-active gem under the danger line for at least 0.75 seconds and verify Retry appears.
5. Cross the line while moving or with the active launcher and confirm no immediate fail.
6. Use Restart, Replay, and Retry; each must restore an empty board plus exactly one launcher.
