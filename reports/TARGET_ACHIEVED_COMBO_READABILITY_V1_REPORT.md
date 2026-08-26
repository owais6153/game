# Target Achieved and Combo Readability V1

Date: 2026-08-26

## Scope

This source-only feedback milestone makes confirmed target completion and chain text readable during genuine gameplay. It does not alter table geometry, gem physics, merge eligibility, target qualification, rewards, layout, launcher behavior, or Android configuration.

## Changes

- The compact Target HUD now shows `ACHIEVED 1 / 1` while the authoritative target collection is active instead of the ambiguous `ARRIVING` wording.
- Every confirmed target merge adds a literal `TARGET ACHIEVED` presentation label through `GameplayEffectsLayer`.
- Combo-label lifetime increases from `0.48 s` to `1.10 s`; the target-achieved label lasts `1.40 s`.
- Local input-replay screenshot folders and capture logs are ignored by Git. They remain local review artifacts and are not production resources.

## Validation

- `tests/run_reward_feedback_v3_tests.gd` protects the configured lifetimes and confirms that a target merge creates the literal target-achieved label.
- `tests/run_ui_scale_layout_tests.gd` verifies that the authoritative collection snapshot visibly produces the `ACHIEVED` HUD state across the existing representative portrait layouts.
- Both focused suites print `PASS` under Godot 4.6.3 headless. The Windows runner still reports its known root-certificate-store error and exits with code 1 after the suite result, so the recorded evidence is the explicit suite PASS output rather than a zero process exit.
- No Android build or physical-device validation was requested or performed for this source-only feedback milestone.
