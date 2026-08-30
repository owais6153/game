# Production Polish V1 - milestones 1-3

> Superseding status (2026-08-30): the later merge/combo/target, onboarding,
> analytics, performance, HUD-hierarchy, power, and audio passes are complete.
> The remaining-work statement below describes this historical milestone only.
> Current evidence is in `FINAL_HUD_VFX_AUDIO_TEST_CANDIDATE.md`.

Scope delivered in this pass: HUD alignment, ad-unavailability robustness, and
limited-shot feasibility. Milestones 4+ (merge/combo/target feedback, onboarding
audit, analytics audit, performance pass) are **not** started.

## 1. Settings button padding

**Root cause.** Godot lays a `Button` out as icon + text and reserves
`h_separation` between them *even when the text is empty*. An icon-only button
therefore draws its glyph left of centre. Measured on the device at 720x1600 the
gear sat ~16px left of the plate centre and clipped the left border, with a wide
gap on the right. `expand_icon` does not fix this - it stretches the glyph to the
full rect and removes the padding entirely - and neither does any `icon_max_width`
value, which is why two numeric attempts failed.

**Fix.** `UiDesignSystem.centre_icon_in_button()` places the glyph as a full-rect
child `TextureRect` with a symmetric inset, taking Button's icon/text layout out
of the equation. Applied to the gameplay HUD and Home settings controls.

**Verification.** `tests/run_hud_alignment_v1_tests.gd` measures *rendered*
`get_global_rect()` centres and per-side padding rather than configured values,
and additionally fails any HUD button that is icon-only via `Button.icon`. It was
confirmed to fail against the previous implementation.

**Not verified on device.** The handset went to sleep with the notification shade
focused partway through re-testing and could not be woken over ADB, so the
post-fix device screenshot was not captured. The pre-fix device screenshot that
diagnosed the defect is in the scratchpad. This needs one look on hardware.

## 2. Ads unavailable (production currently has no fill)

**Trap bug found and fixed.** In the level-complete double-coins path, when
`show_rewarded` returned false the code logged the failure and returned without
resolving the flow. `app_flow_state` stayed `AD_SHOWING` and the win screen's
actions stayed pending, stranding the player on a dead screen. This is the
*normal* outcome when there is no ad inventory, i.e. exactly the current
production situation.

**Stacked-request bug found and fixed.** Neither the power nor the coin rewarded
path guarded against repeated taps, so an impatient player started several
videos. Both now bail while a request is pending or a fullscreen ad is showing,
and `coin_action_pending` was added to mirror `power_ad_pending`.

**Reward integrity.** Rewards are granted only from the earned-reward callback.
`run_no_ads_available_v1_tests` asserts that an unavailable ad grants nothing and
that a video dismissed with `earned = false` grants nothing.

**Player-facing copy** is asserted to contain none of: AdMob, SDK, verification,
error, failed, load, null. When no video exists the panel explains the situation,
hides the WATCH action rather than dangling it, and always offers a way out. The
coin purchase route is asserted to keep working with ads dead.

## 3. Limited-shot validation

`scripts/core/level_solver.gd` computes two bounds:

- **Material floor.** Merging is strictly tier N + N -> N+1, so every gem is a
  power of two in tier-1 equivalents and merging conserves the total; a tier-T
  target costs exactly 2^(T-1). Because all values are powers of two, any multiset
  summing to at least 2^(T-1) can be carried up into one tier-T gem.
- **Greedy play-out.** Adds each shot, carries everything upward, collects
  targets, and grants bonus gems under the real `BONUS_GEM_BUDGET_PER_SHOT` cap.
  Assumes perfect placement, so it is an upper bound: if it fails, nobody can win.

**Finding: every shipped limited-shot level was unwinnable.**

| level | targets | perfect-play shots needed | shots granted |
| --- | --- | --- | --- |
| 4 | 1xT6 1xT7 1xT8 | 46 | 40 |
| 7 | 2xT6 1xT7 1xT8 | 57 | 38 |
| 13 | 2xT6 2xT7 1xT8 | 57 | 34 |
| 19 | 3xT6 2xT7 1xT8 | 69 | 30 |
| 25 | 3xT6 2xT7 1xT8 | 79 | 30 |

The old limit came from a fixed 40 -> 30 ladder that never referenced the
targets. This is a regression introduced earlier in this same body of work, when
limited shots moved to level 4 and target quantities began scaling, without
either change being checked against the other.

**Fix.** The limit is now derived per level: `LevelSolver.minimum_shots()` plays
the level out, and the granted limit is that floor times a margin that starts at
1.70 and decays to 1.30 by level ~34. Every limited level now completes with
20-38 spare shots under perfect play.

**Caveat, stated plainly.** Because the targets genuinely need 46-79 shots, the
derived limits are now large (79-113). "Limited shots" is currently a safety net
rather than real pressure. Making the limit feel tight requires *reducing target
quantities on limited levels*, which is a balance decision I have not taken.

## Backlog (deliberately not implemented)

- Reduce limited-level target quantities so shot limits can be tightened into a
  range that creates real pressure.
- Milestones 4+: merge/combo/target feedback hierarchy, onboarding audit,
  analytics audit, performance pass, HUD hierarchy calming.
