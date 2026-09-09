# Treasure Ceremony V1 — 2026-09-09

Scope: make every treasure in the game open the same way — fullscreen, on a tap,
paying out one reward at a time — and let a level win drop one before the win
popup.

---

## What was wrong

The game had two treasures and neither read as one.

The **daily chest** opened as an 88-pixel icon inside the daily-missions popup.
It rattled, swelled and swapped to its open art, which was a real animation, but
at that size and behind a `CLAIM` button it was a status indicator with a
flourish. The player never looked at it; they looked at the button they had to
press.

The **milestone chest** — the largest single reward in the game at 800 coins
plus four powers — had no animation at all. Tapping it on the level map
repainted the map. The chest changed to its opened state under the player's
finger and the coins appeared in the header. It was, in presentation terms, a
settings toggle.

Neither could be met anywhere else. A player who never opened the daily popup
and never scrolled back to a chest row simply did not meet a treasure.

## What was built

### One ceremony, three sources

`scripts/ui/treasure_overlay_layer.gd` (`TreasureOverlayLayer`, layer 70) is now
the only treasure presentation. Layer 70 puts it above daily missions (65), the
level map (61), Home (60), the result overlay (50) and the gameplay HUD (40) —
all of which can be the surface underneath depending on where the treasure came
from.

The sequence:

1. The dim leads, the chest drops in at 0.30 scale and overshoots to 1.10, and
   the light behind it opens from zero. The chest is sized against the shorter
   screen edge (56%, capped at 400px) so it dominates on a tall phone without
   crowding the reward card that will push up beneath it.
2. It waits under `TAP TO OPEN`, breathing at ±3.5% on a 1.5s period with the
   prompt pulsing on its own 0.9s period.
3. A tap rattles the lid eight times, swells it to 1.30, swaps to the open art
   **at the peak of the swell** under a burst of light, settles, and holds for
   300ms so the burst is seen before anything covers it.
4. Each reward then arrives alone — icon, amount, name — under `TAP TO CLAIM`,
   and leaves only when tapped, swelling to 1.34 and rising 150px as it fades.
   The next follows after a 140ms beat.
5. After the last claim the chest sinks, the dim clears, and
   `treasure_finished` fires.

Coins are one claim. Each granted power is one claim carrying its own count — a
2× Switch is one card, not two taps. Order is coins first, then powers in
`PowerInventoryService.ALL` order, the same order the shop, the HUD and the
daily reveal already use, so the same treasure always plays back identically.

The whole screen is the tap target. The chest and the card are not buttons: a
card that had to be hit exactly would turn a celebration into aiming practice,
and on a post-win drop the player's thumb is wherever their last shot left it.

### The light effect

`scripts/presentation/treasure_vfx.gd` (`TreasureVfx`) draws it, and owns
nothing else — no reward, no texture, no layout. Three layers back to front: a
sixteen-ray fan turning at 0.22 rad/s with alternating length and brightness so
it reads as depth rather than as a wheel; two halos breathing on one period at
different radii, which give the fan somewhere to come from; and eighteen
sparkles on independent orbit speeds and bob periods, because a shared period
makes eighteen dots contract together and reads as a loading spinner.

`intensity` is one dial. The overlay opens it to 0.55, spikes it to 1.55 the
instant the lid gives and decays it back over 0.55s — that spike is what makes
the burst read as the chest opening rather than as a light that was always on.
At zero the effect early-outs of `_process` entirely, so a dismissed overlay
left in the tree costs one comparison per frame.

It is immediate-mode drawing for the same reason the level map is: this sits
over a live scene on low-end phones, and a node-per-ray design would allocate
several hundred nodes for an effect lasting a few seconds.

### A treasure the win can drop

`scripts/core/treasure_drop.gd` (`TreasureDrop`) decides what a completed level
hands over.

- **Milestone.** Clearing a twentieth level hands over that chest immediately,
  before the win popup, instead of leaving it on the map to be noticed. 800
  coins plus the same power grant, unchanged. `claimed_chests` is consulted, so
  a chest already opened never drops again and a chest granted by a win shows as
  opened on the map.
- **Bonus.** Every other win rolls at 15% for 120 coins and one power.

Both are **pure functions of the level number**, for the same reason
`LevelConfig.seed_for_level()` is: the level screen promises that replaying
level 20 reproduces level 20, and a drop that consulted the clock or a live RNG
would quietly make a replay worse than the first clear. `_hash()` takes a salt
because whether a bonus drops and which power it pays are independent decisions;
sharing one bit pattern would make every bonus in the game pay the same power.

The milestone outranks the bonus, so clearing level 20 can never pay 120 instead
of 800 — asserted directly.

### The chest art is its own tap target

The daily popup's chest now carries an invisible `Button` sized to the art.
The `CLAIM` plate beside it stays, because it is what says `LOCKED` and `DONE`,
and its caption is now `OPEN`.

Every state on the tap target is an explicit `StyleBoxEmpty`. `flat = true`
suppresses only the draw call — `get_theme_stylebox("normal")` still returns the
shared gem plate, which would have drawn behind the chest and, at 92px of caps
against an 88px chest, been correctly flagged by
`run_ui_kit_polish_v1_tests._test_no_button_crushes_its_plate`.

---

## The two orderings that were the actual risk

### The treasure must not be mistaken for the level's reward

A milestone pays 800 coins into the same balance Level Complete reads as the
level's own reward (`coins - level_start_coins`). Granting it before that read
would have the popup announce a 900-coin level and Double Coins offer to match
900.

`_update_win_presentation()` captures `level_reward_for_completion` **once**,
before asking for a treasure, and `_grant_post_win_treasure()` raises
`level_start_coins` alongside `coins`. The difference is therefore invariant,
which also leaves the existing Retry-rollback contract untouched. Asserted in
the suite as an explicit `coins - level_start_coins == 100` after an 800-coin
milestone.

### The reward must be saved before the ceremony, not during it

Every path — daily, milestone, post-win — builds the complete resulting
inventory, balance and chest record, persists it, adopts it, and only then calls
`present()`. This is the atomicity rule the daily and milestone chests already
used, extended to the new path. A player who force-closes the app during the
animation keeps everything, and the ceremony is free to take as long as it
needs.

The regression asserts this **through the save file**, not through in-memory
state, because "persisted before presented" is the property that matters and
in-memory fields would pass either way.

## The win popup

`ResultOverlayLayer` is untouched. The treasure only delays `present()`, so the
popup's entrance and the mascot reaction it holds back until that entrance lands
run exactly as before.

That was asserted rather than assumed. The mascot frames are a static cache
shared by every instance, and the ceremony runs its own `PROCESS_MODE_ALWAYS`
layer with its own tweens, so `win_popup_mascot_still_reacts_after_a_treasure`
drives a complete ceremony to close and then checks the popup opens neutral,
reaches the happy track, and actually travels it (frame > 1.0 of 12).

---

## Tests

New: `tests/run_treasure_ceremony_v1_tests.gd`, six registered cases plus two
pure-function cases.

| Case | What it protects |
| --- | --- |
| `milestone_drop_rules` | 20 → chest 1, 40 → chest 2, the milestone coin amount, and that a claimed chest never re-pays |
| `bonus_drop_is_pure_and_bounded` | Stability across calls, 4–30% measured over 500 levels, ≥3 distinct powers, milestone always outranks bonus |
| `overlay_opens_on_tap_and_claims_one_reward_at_a_time` | Full sequence; taps mid-open ignored; **a reward held for 1.2s must still be waiting**; one `treasure_finished` |
| `overlay_declines_an_empty_treasure` | `present()` returns false so the post-win gate is never left waiting |
| `daily_chest_art_is_its_own_tap_target` | The tap target exists, is disabled when unearned, and requests the claim |
| `controller_grants_a_post_win_treasure_before_the_popup` | Coins/powers/chest **on disk** before the ceremony, the reward invariant, the popup gate, once-per-win |
| `controller_clears_drop_state_on_restart` | Flags cleared; a level with no drop never delays the popup |
| `win_popup_mascot_still_reacts_after_a_treasure` | The mascot travels its track after a full ceremony |

The "must still be waiting after 1.2s" assertion is the one that pins the whole
design. Auto-advance was the obvious implementation and is what the sequence
exists to reject.

### Updated because behaviour genuinely changed

`tests/run_reward_feedback_v3_tests.gd` drives a win to Level Complete and
measures the level's own coins exactly. It ran on whichever level the save
happened to hold, so a post-win treasure both added coins to the balance it
measured and held the popup it waited for — twelve assertions failed.

`_prepare_final_target()` now pins an **odd, treasure-free** level, chosen by
querying `TreasureDrop` rather than hardcoded, so the pin cannot drift if the
drop rules change. Odd because the every-two-levels interstitial cadence would
otherwise gate the transition those cases drive; treasure-free because a drop is
a separate reward in the same balance. No assertion was weakened.

`tests/run_ui_kit_polish_v1_tests.gd` correctly caught the chest tap target
inheriting the gem plate. The fix was in the source, not the test.

### Result

**All 39 suites pass, over two consecutive full passes.**

```
Pass 1 - suites: 39 FAILED: 0
Pass 2 - suites: 39 FAILED: 0
```

---

## Files

| File | Change |
| --- | --- |
| `scripts/core/treasure_drop.gd` | New. Pure drop rules. |
| `scripts/presentation/treasure_vfx.gd` | New. Drawing helper for the light effect. |
| `scripts/ui/treasure_overlay_layer.gd` | New. The ceremony. |
| `scripts/gameplay/game_controller.gd` | Overlay wiring, `_present_treasure()`, the post-win gate and grant, Back routing, flag resets. |
| `scripts/ui/daily_missions_overlay_layer.gd` | Chest tap target; `CLAIM` → `OPEN`; routes to the ceremony. |
| `tests/run_treasure_ceremony_v1_tests.gd` | New suite. |
| `tests/run_reward_feedback_v3_tests.gd` | Pinned to a treasure-free level. |

Simulation, merge, launcher, collision, table geometry, `GameConfig` and level
generation are untouched.

---

## Delivery status — read this before shipping

**No Android artifact was produced for this change.** The APKs and AABs in
`build/android/` are the `1.0.18 (vc20)` release and predate this work; they do
**not** contain the treasure ceremony. Nothing here has been validated on a
device.

Shipping it requires the standard steps: pick a version code strictly greater
than every code in `BUILD_MANIFEST.md`, persist it in `export_presets.cfg`,
export, verify the embedded manifest with Bundletool, and record the artifact.

## Residual risk

- **Device timing is unverified.** The sequence is tuned on desktop at 60fps.
  The tap-gated design means a slow frame delays a beat rather than skipping a
  reward, but the burst and the reward pop have not been watched on a low-end
  phone.
- **A four-reward milestone is four taps.** Measured at roughly 3.5 seconds of
  animation plus the player's own pace. Acceptable for a once-per-twenty-levels
  event and for the daily chest; it would not be acceptable at a higher
  frequency, which is part of why the bonus rate is 15% and pays two claims.
- **`treasure_kind` splits a historical series.** A milestone cleared after this
  change reports `treasure_drop`, not `milestone_chest_claim`. Comparing the old
  series across the boundary will read as milestone rewards collapsing to zero.
  Recorded in `ANALYTICS_EVENT_CATALOG.md`.
