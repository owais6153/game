# Level map normal scroll, brand v7 icon, asset purge - 2026-09-07

Source commit at start: `126c8c4` (`build: deliver optimized 1.0.18 vc20 apk and aab`).
Tree was clean apart from one untracked supplied PNG at the repository root.

## Requests in this task

1. Use a normal scroll on the level select screen.
2. Remove Google Play Games Services entirely.
3. Check whether daily missions only change after 24 hours.
4. Find out why the old assets were still not deleted.
5. Push notifications reported working - no action.
6. Replace the supplied illustrated logo wherever the non-transparent logo was
   already used.
7. Build and test on the connected device, with authorization first.

## 1. Normal scroll

### What was actually wrong

The map had hand-rolled flick physics: its own scroll offset, a velocity, an
exponential friction curve, a glide step in `_process`, and a
`draw_set_transform` to shift content. That existed because a first attempt at a
`ScrollContainer` appeared not to scroll at all.

The container was never at fault. `LevelMapView` was `MOUSE_FILTER_STOP`, so a
drag starting on the custom-drawn map never reached the container. The
workaround added for that wrote `scroll_vertical` straight from each drag event
in whole pixels with no velocity, which is what "not smooth" was - the map
stepped while the finger moved and stopped dead the instant it lifted. The
rewrite that followed replaced the workaround rather than the cause.

### What it is now

- `LevelSelectOverlayLayer` owns a `ScrollContainer` (`scroll`), horizontal
  scrolling disabled, vertical scrollbar present but fully transparent because
  the map is full-bleed art and a visible bar reads as a rail down the path.
- `LevelMapView` is its content: `size_flags_horizontal = SIZE_EXPAND_FILL`, and
  `custom_minimum_size.y = content_height()`.
- The map is `MOUSE_FILTER_PASS` and its `_gui_input` handles only
  `InputEventScreenTouch` / `InputEventMouseButton`. It never touches a drag
  event and never calls `accept_event()` on one, so every gesture reaches the
  container.
- The container reports its viewport down through `set_window(top, height)` on
  `get_v_scroll_bar().value_changed` and on resize. The map draws only the slots
  inside that window and repaints only when the visible slot range changes, so
  the windowing that made the previous implementation cheap is retained.
- Removed: `_scroll`, `_velocity`, `_dragging`, `_apply_drag`, `_advance_glide`,
  `scroll_to_level`, `scroll_offset`, and the `FRICTION`, `MIN_GLIDE_SPEED`,
  `VELOCITY_BLEND`, `MIN_FRAME_DELTA`, `PAN_GESTURE_SCALE` constants.
- Added: `set_window()`, `invalidate()`, and a `top_inset` argument on
  `scroll_offset_for_level()` so the overlay can centre the player's level in
  the clear band between the floating header and the hero button.

### On the 186,000px content node

The previous implementation rejected the container partly because the map would
have to *be* its content, "a node 186,000px tall being re-laid-out on every
scroll". A `ScrollContainer` positions its child on scroll; it does not
re-measure it. Layout happens on configure and on resize. Drawing remains
windowed. The height costs a layout, not a repaint.

### Desktop note

Godot's `ScrollContainer` engages touch-drag scrolling only where a touchscreen
is available. On desktop the map scrolls with the wheel, not by dragging with
the mouse. That is standard engine behaviour and correct for a portrait Android
title; it is called out because it is a deliberate difference from the previous
hand-rolled implementation, which dragged on desktop too.

## 2. Google Play Games Services - nothing to remove

Already removed on 2026-08-28 at the product owner's request. Re-verified two
ways in this pass:

- Source: no `play-services-games` or `gms.games` Gradle dependency, no
  `PlayGamesPlugin`, no `play_games_service.gd`, `achievement_service.gd` or
  `play_games_ids.gd`, no manifest entry. The only `com.google.android.gms`
  string in any tracked manifest is AdMob's `APPLICATION_ID`.
- Shipped artifact: all three DEX files of
  `build/android/majestic-gems-release-v1.0.18-vc20.apk` were scanned. Neither
  `com/google/android/gms/games` nor `PlayGamesSdk` appears in any of them.
  `com/google/android/gms/ads` and `com/google/firebase` do, as intended.

The initial reading of the request was full Google Play Services removal, which
would have meant deleting AdMob and Firebase Analytics. That was checked with
the product owner before any change and corrected to Play **Games** Services
only. No SDK was removed.

## 3. Daily missions - they change at local midnight, not after 24 hours

`DailyMissionService.ensure_current_day()` and `needs_new_day()` both key on
`Time.get_date_string_from_system()`, the local calendar date. Consequences:

- The set rolls when the date changes, not 24 hours after the player saw it. A
  player who first opens the game at 23:50 gets a new set ten minutes later.
- It remains susceptible to device-clock changes, which the service documents as
  a deliberate V1 limitation pending server time.

This was a verification request, so the behaviour is reported and left
unchanged. A strict 24-hour roll would mean storing the issue timestamp rather
than a date string and comparing elapsed time, and is a behaviour change that
has not been authorized.

### Two suites that passed or failed depending on the date

Found while verifying the above. `run_retention_daily_missions_v2_tests` and
`run_mission_notification_v1_tests` hard-coded `"merge"` as the event they
recorded against `missions[0]`. The daily set is rolled from the date and the
easy pool contains a `target_complete` objective alongside two merge ones, so on
a day that rolled `target_complete` nothing advanced and nine assertions failed.
Both were failing on `main` before this task began, at the same counts.

The date cannot simply be pinned: `record()` calls `ensure_current_day(state)`
with no date argument and would roll a pinned state forward to today. Both
suites now read the type off the mission that actually rolled. Both pass.

## 4. Why the old assets were still there

Two separate reasons.

- The 1.0.18 pass deleted five PNGs but not their `.import` sidecars, leaving
  nine orphaned sidecars across `assets/runtime/ui/` and the repository root.
- `tests/run_branding_push_line_tests.gd` was still loading
  `majestic_gems_logo_v4.png`, `majestic_gems_app_icon_192_v5.png` and both
  `adaptive_*_v5.png`, and asserting their dimensions. Those four files were
  therefore still referenced and could not be deleted without the suite failing.
  It had been asserting the shape of art the game had not shipped since two
  brand refreshes earlier.

Deleted in this pass: fifteen runtime derivatives, nine orphan sidecars, and
`scripts/dev/prepare_majestic_gems_launcher_v2.gd`, whose only outputs were
those derivatives and which was fully superseded by `prepare_brand_refresh_v1.gd`.
Supplied sources under `assets/logo/` are all preserved, per the standing rule
that originals are kept and only derivatives are disposable. Full list in
`ASSET_INVENTORY.md`.

The suite now asserts the same shape contract against the live v6/v7 art.

## 5. Push notifications

Reported working by the product owner. No change made and none needed.

## 6. The v7 illustrated logo

Supplied as `ChatGPT Image Sep 7, 2026, 10_20_55 AM.png` at the repository root,
preserved as `assets/logo/majestic_gems_logo_with_background_source_v7.png`
(1254x1254, opaque).

It replaces the previous illustrated square in exactly the two roles that
variety held:

| Output | Consumer |
| --- | --- |
| `majestic_gems_app_icon_192_v7.png` | `launcher_icons/main_192x192`, `project.godot config/icon` |
| `majestic_gems_adaptive_background_v7.png` | `launcher_icons/adaptive_background_432x432` |
| `majestic_gems_adaptive_foreground_v7.png` | `launcher_icons/adaptive_foreground_432x432`, deliberately empty |

The transparent mark is untouched and remains v6, so Home
(`AssetCatalog.BRAND_LOGO`), the Android launch screen (`splash_screen/icon`)
and the engine boot splash (`boot_splash/image`) are unchanged. Baking an
illustrated background into any of those would show as a square over artwork
each already composites against.

### The adaptive surround had to change with the art

Only the middle 72 of an adaptive icon's 108dp is guaranteed to be displayed, so
the artwork sits at the 288px viewport and a ring fills the rest. The v6
generator built that ring by downsampling the whole illustration to 6x6 and
scaling it back up, dimmed to 0.55. On the v7 art that failed:

1. At 6x6 the ring averaged the illustration's outer sixth, which on this art
   includes the gold frame and brown wood. The result was a muddy band that read
   as a border around a pasted-on square.
2. At 16x16 enough structure survived that a ghost of the wordmark appeared in
   the ring, so the icon showed its logo twice - the exact failure the v6
   comments warned about for an un-blurred copy.

The surround is now an **edge extension**: each pixel outside the artwork takes
the colour of the nearest pixel on the artwork's edge, and the result is blurred
to soften the radial streaking. It cannot produce either failure, because the
only colour the ring ever contains is the one the artwork already ends on -
which on this art is its soft lilac bokeh. `SURROUND_DIM` moved 0.55 to 0.94 for
the same reason: at 0.55 the inner artwork was visibly brighter than its own
surround.

Verified with `scripts/dev/preview_adaptive_icon_masks.gd`, which composites the
icon under circle, squircle and rounded-square masks. The wordmark survives all
three. Output at `reports/brand-refresh-v6/adaptive-masks.png`.

## Tests

`tests/run_level_select_map_v1_tests.gd`:

- Replaced `_test_drag_scrolls_and_release_glides` (which asserted the
  hand-rolled momentum) with `_test_scroll_container_owns_scrolling`: the map is
  `MOUSE_FILTER_PASS`, declares its content height, leaves a drag and a
  travelled release unhandled so the container can scroll, and still claims a
  genuine tap. Run inside its own `SubViewport`, because the viewport's
  input-handled flag has no public reset and a tap in an earlier case would
  otherwise leave it set.
- Added `_test_overlay_scrolls_through_the_container`: the map is the
  container's content, horizontal scrolling is disabled, the screen opens on the
  player's own level through `scroll_vertical`, and the map's drawing window
  tracks the container's offset.

### The suite had been printing PASS with three dead cases

A GDScript runtime error aborts the case it occurs in but neither stops the
runner nor fails the process. `set_window()` and `overlay.scroll` had both been
deleted by the previous scroll rewrite without the tests being updated, so three
cases died on every run and the suite still reported green. Each case now
appends its name to a register and the runner fails on any missing signature.

Two further suites are green in the same false way and are **not** fixed here,
because both fail on overlay properties outside this task's scope:

- `run_game_flow_reward_splash_tests` - `HomeOverlayLayer.intro_objective_label`
- `run_no_ads_available_v1_tests` - `ResultOverlayLayer.actions_pending`

Both were confirmed to fail identically on clean `main` before this task.

## Scope

Gameplay is untouched. No file under `scripts/gameplay/` or `scripts/core/` is
modified: no simulation, `GameConfig`, launcher, aim, drag clamp, merge,
collision or scoring change. The complete modified set is the two level-select
UI scripts, four test scripts, two dev art scripts, `project.godot`,
`export_presets.cfg`, and the asset and documentation changes above.
