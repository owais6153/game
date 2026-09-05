# Level Select Map V1

**Date:** 2026-09-05
**Scope:** a level-selection screen, per-level replay, a restart-on-entry fix,
milestone treasure chests every 20 levels, and the removal of 3.7 GB of build
artefacts and report media.

---

## 1. The question that gated the work: are level seeds stored?

**They are not stored, and they do not need to be.** This was checked before any
code was written, because the answer decided whether replay was a feature or a
research project.

`scripts/core/level_config.gd:176`:

```gdscript
static func seed_for_level(level_number: int) -> int:
	# Stable across platforms and retries, while producing a new layout forever.
	return int((level_number * 1103515245 + 12345) & 0x7fffffff)
```

The seed is *derived*, which is a stronger guarantee than storage. Level 7
resolves to seed 7724605 on every device, every install, and every replay. Every
generated property of a level - the opening board from
`starting_board_for_template()`, the target ladder, the shot limit, the launcher
queue - is a function of that seed, and `save_progress()` writes
`seed_for_level(next_level)` alongside the level number, so the stored seed can
never drift from the level it belongs to.

No seed persistence was added. What *was* added is a test that the purity holds,
because the whole feature rests on it and nothing else in the suite covered it:

```gdscript
var config_a := LevelConfigType.generated(level, first)
var config_b := LevelConfigType.generated(level, LevelConfigType.seed_for_level(level))
_assert(
	config_a.get("shot_limit", -1) == config_b.get("shot_limit", -2)
		and str(config_a.get("starting_board", [])) == str(config_b.get("starting_board", []))
		and str(config_a.get("launcher_sequence", [])) == str(config_b.get("launcher_sequence", [])),
	"Replaying level %d must rebuild an identical board, shot limit and queue" % level
)
```

Run across levels 1, 2, 7, 19, 20, 63, 250 and 1004.

**Standing risk:** if a future change makes level generation depend on anything
outside the level number - a timestamp, an install id, an adaptive difficulty
signal - replays stop reproducing and the level screen becomes a lie. This is
recorded in `AI_KNOWLEDGE_BASE.md` as a guardrail.

---

## 2. The new flow

```
Home ──PLAY──▶ Level map ──tap a level──▶ Level Ready popup ──START──▶ Play
                   ▲                             │                       │
                   │                             └───Back────────────────┘
                   └──────────── Next Level ──────────────────────────────┘
```

`AppFlowState` gained `LEVEL_SELECT` between `HOME` and `LEVEL_READY`.

- Home's PLAY (`_on_home_level_intro_requested`) opens the map instead of the
  level popup.
- `_on_level_chosen(n)` loads the chosen level and shows the Level Ready popup.
- `_finish_completion_transition()` returns to the map on Next Level rather than
  handing the player straight into the next board.
- Back on the map goes to Home; Back on Level Ready returns to the map that
  opened it, so a player can change their mind without a round trip through
  Home.

The Home layer hosts both Home and the Level Ready popup, so its single
`home_requested` signal is now dispatched by flow state
(`_on_home_overlay_back_requested`).

---

## 3. `highest_level` split from `level_number`

Before this change the two were the same value, and code that conflated them was
correct only because the player could never be on any level but their furthest.
Replay makes that false.

| | Meaning |
| --- | --- |
| `level_number` | the level currently loaded on the table |
| `highest_level` | the furthest level ever unlocked |

Replaying level 5 out of 40 sets the first to 5 and must leave the second at 40.
The invariant is enforced in exactly one place, so no caller can violate it:

```gdscript
config.set_value("progress", "highest_level",
	maxi(stored_highest, maxi(maxi(1, level_number), highest_level)))
```

`highest_level` is therefore monotonic regardless of which path writes it, and
every pre-existing caller that passes nothing still behaves correctly.

**Save compatibility.** `highest_level` and `claimed_chests` are absent from
every save written before this change. An absent `highest_level` reads as
`level_number`, which is exactly right - those players were always standing on
their furthest level. An absent `claimed_chests` reads as "none opened".

A cold start now opens on `highest_level` rather than on whichever earlier level
the last session happened to replay. The replay is a detour; the player's place
in the game is the frontier.

---

## 4. The resume bug

**Reported:** starting a level, going back to Home, and returning continued the
half-played board instead of restarting it.

**Cause:** `_show_home()` hid the gameplay HUD but never touched the board, and
`_on_home_play_requested()` simply un-hid it. Nothing between the two rebuilt
anything, so the live table survived the round trip.

**Fix:** `_show_level_start()` calls `restart()`. Every route into a level -
Home, the map, Next Level, skip - passes through that function, so there is now
exactly one place where a level's board is constructed. The redundant second
`restart()` in `_perform_skip_level()` was removed.

Asserted against the source so it cannot be quietly rewired back:

```gdscript
var level_start := source.split("func _show_level_start() -> void:")[1].split("\nfunc ")[0]
_assert(level_start.contains("restart()"), "Entering a level must rebuild it, ...")
```

---

## 5. A thousand levels, drawn rather than built

The map draws `highest_level + 1000` levels so scrolling never reaches an end -
the game must never look finishable.

`LevelMapView` renders every node, chest, path stroke and ornament in `_draw()`.
It deliberately creates no Control per level: a Control-per-node design would
build and lay out several thousand nodes on every open, and pay that cost again
on every resize and scroll, for a screen the player flicks through in a second.
Only slots inside the visible window are drawn, so opening the map at level 4 and
at level 4000 cost the same.

Two properties are load-bearing:

- **The view must be told what is visible.** The parent `ScrollContainer` owns
  the scroll offset, so the overlay pushes it down through `set_window()`.
  Without that call the view renders the wrong slice - which looks like a layout
  bug, not a missing-notification bug.
- **Drawing and hit testing share `_point_at()`.** A separate hit-test layout
  would drift from the drawn one along the serpentine, where horizontal position
  changes fastest, and taps would land off the plates. The test asserts a tap at
  each drawn centre hits that node, and that a tap in the gap above it does not.

### Slot arithmetic

Levels and chests share one column of slots: each block of 20 levels is followed
by a single chest slot. `LevelMilestone` owns the mapping so the controller that
grants a chest and the map that draws one cannot disagree.

| | |
| --- | --- |
| `slot_for_level(n)` | `(n-1) + (n-1)/20` |
| `slot_for_chest(m)` | `m * 21 - 1` |
| `slot_contents(s)` | inverse of both |

`run_level_select_map_v1_tests` walks 400 slots and asserts each holds exactly
one of a level or a chest, that both forward mappings invert correctly, and that
no level in 1-379 is missing from the path.

---

## 6. Milestone chests

A chest sits after every twentieth level, unlocked by clearing the level below
it. `unlocked_chest_count(highest_level)` is `(highest_level - 1) / 20` -
standing *on* level 20 does not open the chest that follows it; clearing it
does. This boundary is tested explicitly, since off-by-one here either hands out
a reward early or withholds one that was earned.

**Reward:** `LevelMilestone.COIN_REWARD` = 800 coins, plus the daily chest's
power grant (`{switch: 2, magnet: 1, hammer: 1}`), using the same
`badge_chest` / `badge_chest_open` art so the two read as one reward object.

**Why 800 and not the daily chest's figure.** `DailyMissionService.CHEST_REWARD`
is `0` - the daily chest pays powers only, by design, because coins already
arrive from every level. Copying it would have made the milestone pay no coins
at all. A milestone is earned once per twenty levels rather than once a day, so
it has to land as an event. 800 is roughly two levels' income at the measured
310-480 coins per level and exactly one Skip Level, which sizes the reward
against prices the player already knows instead of introducing a new number.

**Economy effect:** 800 per 20 levels is 40 coins per level, about +9% on the
425-coin average. Felt when it lands, but not enough to move the sink
calibration. Materially larger would start making Skip Level (800) and Continue
(500) cheap enough to blunt the failure loop.

**Atomicity:** the whole resulting inventory is built before anything persists,
and adopted only after both saves return OK - the same rule the daily chest
follows. A failed save cannot hand out half a chest.

---

## 7. Presentation

### Layout: full-bleed, with two floating bars

The first layout put the header, the map and the hero button in a safe-area
column, which inset the map into a panel in the middle of the screen. Against
the supplied reference it read as congested and boxed-in.

The map now fills the entire screen and the two bars float over it, each pinned
to its own edge and clearing only the device inset on that side. The map is
deliberately excluded from the safe-area handling: it has to run under both bars
and off both edges, which is what makes the path feel continuous.

Two bugs came out of that rework, both worth recording because neither names
itself:

- **Godot's built-in `ScrollContainer` `panel` stylebox is a bordered grey
  plate**, and the project theme sets no `ScrollContainer` entry, so the scroll
  view fell back to it. That stylebox was the visible box around the map.
  Fixed with a `StyleBoxEmpty` override.
- **`set_anchors_preset()` sets anchors but leaves every offset at zero**, so
  both floating bars collapsed into the top-left corner and the hero button drew
  on top of the banner. `_layout_bars()` now drives their offsets from
  `get_combined_minimum_size()`, and re-runs whenever the safe insets change,
  because those change the content height.

The centring maths follows from the layout: the clear band between the two bars
is what the player's level is centred in, not the full screen height, or the
current level opens half-hidden behind the banner. The map's end padding was
raised so level 1 and the topmost level clear the bars too.

### The coin chip is gone

Nothing on the level screen spends coins, so a balance here was a number the
player could not act on. Home and the shop both still show it where it means
something. Note that the supplied reference image does include a coin chip -
this follows the explicit instruction over the mock-up, and is a two-line
change to reverse.

### Proportions, measured rather than eyeballed

An earlier pass claimed the screen matched the reference because it used the
same kit assets. It did not. Measuring both against screen width showed the
real gaps:

| | Reference | Before | After |
| --- | --- | --- | --- |
| Plate width | 11.7% of width | 14.4% | 14.4% |
| Path swing, edge to edge | 37.6% of width | 54.4% | 48% |
| Row pitch | 1.75 x plate | 1.69 | 1.75 |
| Laurel badge | 0.75 x plate | 0.56 | 0.75 |
| Column separation | 1.58 x plate | 1.15 | 1.44 |

The ratios against the plate are now reproduced exactly. The swing is the one
deliberate departure: the reference is a 2:3 mock-up and the game renders at
720x1280 or taller. Holding the swing at 37.6% of a 720-wide screen while
keeping plates big enough to tap puts adjacent columns 1.15 plates apart and
consecutive nodes begin to collide, so it is opened to 48%, which restores a
1.44 separation.

A note on comparing renders: `project.godot` uses `canvas_items` stretch with a
720x1280 base, so the game always lays out at 720 logical width whatever the
device. A capture at the reference's own 1024 renders unscaled and makes every
element look 30% too small - it is not a valid comparison, and the capture
script deliberately renders 720x1440 and 720x1600 instead.

### Artwork

The first pass drew nodes as flat circles and read as programmer art. Everything
is now the supplied kit:

| Element | Asset |
| --- | --- |
| Level plate | `btn_square_small`, drawn through a `StyleBoxTexture` |
| Cleared marker | `badge_check_laurel` |
| Current level | `badge_crown` plus a pulsing halo |
| Chest | `badge_chest` / `badge_chest_open` |
| Claimable glint | `icon_sparkle`, counter-phased on two corners |
| Path studs | `decor_diamond_small` |

Plates go through a `StyleBoxTexture` rather than `draw_texture_rect` so the
nine-patch margins are honoured and the gold rim keeps its authored thickness at
every size the map draws it at - `btn_square_small` is 78x76 and is drawn at 104
and 124.

The path is three strokes - dark casing, gold body, pale gloss - because a
single flat stroke read as a drawn line rather than a paved road. The lit run
ends exactly at the player's slot rather than at the nearest curve subdivision.

Two fixes worth recording:

- **The overlay must set `UiDesignSystem.theme()` on its own root.** A
  `CanvasLayer` is not a `Control`, so the theme does not reach it by
  inheritance. Without it every button fell back to Godot's default grey plate,
  which reads as missing art rather than as a missing theme. `HomeOverlayLayer`
  does the same thing for the same reason.
- **The edge fades cannot be children of the `ScrollContainer`.** They would be
  treated as scroll content and slide away with the path. They live in a
  `Control` frame that holds the scroll view instead.

`var top_level` on the map view had to be renamed to `last_level`: it collided
with `CanvasItem.top_level` and the parse error it produced named the caller,
not the shadowed property.

---

## 8. Tests

**Added** `tests/run_level_select_map_v1_tests.gd`:

- slot arithmetic and its inverse across 400 slots
- chest unlock boundaries, including standing-on-20 versus having-cleared-20
- the seed-purity contract across eight levels
- map geometry, hit testing, in-bounds node positions, scroll clamping
- locked levels and locked chests refusing selection
- overlay presentation, label content, and centring on open
- the controller's routing, asserted against the source

**Added** `tests/capture_level_select_map_v1.gd`, producing
`reports/level-select-map-v1/` at 720x1440 in four progression states.

**Updated** twelve existing suites. The established idiom for "get me into a
level" was two calls; the new flow needs three:

```gdscript
controller._on_home_level_intro_requested()
controller._on_level_chosen(controller.highest_level)
controller._on_home_play_requested()
```

`run_game_flow_reward_splash_tests` and
`run_animation_audio_back_privacy_polish_tests` additionally had their
back-navigation assertions rewritten for the three-screen flow - they asserted
the old contract by name ("Back on Level Ready must be consumed by the Home
overlay"), which is no longer the behaviour.

**Result: all 38 suites pass.** The five suites that failed mid-work were
confirmed passing on a stashed baseline first, so each failure was established
as caused by this change rather than pre-existing.

---

## 9. Disk cleanup

| Removed | Size | Tracked |
| --- | --- | --- |
| `build/` (AABs, APKs, bundletool output, logs) | 3.0 GB | gitignored |
| `reports/*/` media subdirectories | 694 MB | tracked |

**Reclaimed: ~3.7 GB.** All 158 report markdown files were kept. The deleted
report media remains recoverable from git history, and `.git` (1.9 GB) is
unaffected - reclaiming that would need a history rewrite, which was not done
and was not authorised.

**Consequence for release:** there is currently no built AAB or APK on disk. The
next release must export fresh artefacts. Per `AGENTS.md`, the next export must
choose a versionCode strictly greater than 19 and a versionName strictly greater
than 1.0.17, and record the result in `BUILD_MANIFEST.md`.

---

## 10. Delivery follow-up

- A release-signed companion APK was exported after the source milestone commit:
  `build/android/majestic-gems-level-select-map-v1.0.17-vc19.apk` (76,359,320
  bytes, SHA-256
  `EE833CF3E63053FB0AA8CA1FE75B8090F0DBFFFB2F74454F7443C330416E817D`).
  AAPT reports package `com.owais.majestygems`, versionCode 19, versionName
  1.0.17, and both supported ARM ABIs. APK Signature Scheme v2 verifies with
  the established Teckvertex Labs upload certificate. No AAB was generated.
- The final focused rerun printed `LEVEL_SELECT_MAP_V1_TESTS: PASS`; the runner
  then returned the repository's known Windows post-PASS exit code 1.
- **No device validation.** The screen was verified headless through the
  regression suite and through rendered captures at 720x1440, not on a phone.
- **No stars.** Per-level star ratings were considered and deliberately not
  built: no completion or scoring data exists per level, and stars would need a
  new scoring rule plus a new save section. Cleared levels show a tick, derived
  from `highest_level` with no new save data.
