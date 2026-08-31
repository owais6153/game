# Low-end performance, rescue softlock, and merge presentation — v1

Target device for every measurement in this report: **vivo Y21A (V2149)**, MediaTek
Helio P22 (MT6762V/CB), PowerVR Rogue GE8320, 3806 MB RAM, Android 11, connected
over adb. This is the device the stalls were reported on; the Camon 40 Pro
absorbed the same work and is why the problem looked intermittent.

## 1. What was actually wrong

Two independent causes, both real, found by measuring rather than inspection.

### 1a. Texture memory — the device was starved

`dumpsys meminfo` on the shipped build, sitting on the Home screen:

```
GL mtrack   139654 kB      TOTAL PSS  404197 kB
```

140 MB of GPU texture memory on a phone reporting **64 MB free RAM**. The cause
was `AssetCatalog`: all ten 720x1280 backgrounds and all ten tables were held in
`const … preload(…)` arrays, so 70 MB of scene art stayed resident permanently
for the one background and one table a level can show. Every texture in the
project also imported as lossless/lossy — both of which decompress to RGBA8 in
VRAM — so nothing was compressed on the GPU at all.

On a unified-memory tile renderer under that much pressure the driver evicts and
re-uploads textures, which is felt as stalls rather than as a low frame rate.

### 1b. The collision sweep was O(N²) — the crowded-table stall

`BoardSimulation._step_subframe` tested every gem against every other gem, and
did it `COLLISION_SEPARATION_PASSES` (7) times per substep, with up to
`MAX_SIMULATION_SUBSTEPS` (8) substeps in a frame. At 40 gems that is
`780 × 7 × 8 ≈ 43,000` `_resolve_pair` calls inside a single frame, in GDScript.

`_resolve_bounds` — entered once per gem per substep and again inside every
overlapping pair — re-derived the same four rail values through
`GameConfig.table_left_at/table_right_at/board_top/board_bottom` on every call,
roughly ten static calls to recompute numbers that cannot change during a frame.

This is why the stall tracked *crowding*, and why it showed up on merges and
pushes specifically: those are exactly the moments with the most gems in contact.

## 2. What changed

### Texture memory
- `assets/runtime/backgrounds/*` and `assets/runtime/tables/*` now import with
  `compress/mode=2` (VRAM compressed). The device reports
  `GL_KHR_texture_compression_astc_ldr` and is OpenGL ES 3.2, so ETC2/ASTC is
  safe here. A background drops 3.52 MB → 0.44 MB, a table → 0.88 MB.
- `AssetCatalog.LEVEL_BACKGROUNDS` / `LEVEL_TABLES` are now path arrays.
  `background_texture()` / `table_texture()` resolve through `_scene_texture()`,
  a most-recently-used cache bounded at two entries per kind, so a level swap
  reuses what is already loaded and everything else is released.

### Simulation
- `_candidate_pairs()` — a sweep-and-prune broad phase on the vertical axis,
  built once per subframe. A uniform grid was tried first and pruned badly:
  one cell size has to be sized to the largest gem on the board, which on a
  mixed board swallows most of the table in a single neighbourhood.
- `_resolve_bounds` / perspective scale now read table geometry cached for the
  frame (`_cache_table_geometry`), evaluating the same expressions GameConfig
  does rather than re-entering it thousands of times.
- The stabilization sweeps stop as soon as one of them separates no overlap and
  applies no impulse, since the board is then unchanged and every later sweep
  would repeat that. A settled table costs one sweep instead of seven.

**None of this is allowed to change the board**, and that is enforced rather
than asserted — see §4.

### Level entry
`GameConfig.LEVEL_ENTRY_PRESENTATION_ENABLED` is now `false`. The briefing popup
already shows the table behind it, so fading and sliding the table in on START
GAME read as the table disappearing and coming back. The board is simply present
now. This also removes a full-screen fade from the first half-second of every
level.

### Merge presentation

**The burst was never visible.** Its sprites were created with
`z_index = -4096`. Godot treats a child's `z_index` as relative to its parent, so
inside a gem layer at z 10 they resolved to about -4086 — below the table sprite
at -10 — and every merge burst was drawn behind opaque table art. The only merge
feedback that has ever reached the screen is the thin ring arcs the effects layer
draws at z 0.

This is why the effect could not be fixed by tuning. Two full passes raising
brightness, duration and scale changed nothing on screen, because the thing being
tuned was not being drawn. It was caught by pulling a screen recording off the
device and stepping through a merge frame by frame: the bright element hugged the
gem and died in ~3 frames while the shader was configured for a 0.78 s, 2.1x
expansion. Both could not be true unless the shader was not drawing.

The burst now draws **above** the gems (`MERGE_BURST_Z_INDEX`). Below them it
read as something happening behind the board rather than to the gem that merged,
and the gem art occluded most of it; the material is additive, so drawing on top
lights the gem rather than hiding it.

With it actually visible, the design settled over three device-verified passes:

- The radial spark crown is **removed**. Short lines flung off the merge read as
  debris rather than as one deliberate effect, and each cost a separate
  primitive.
- Rotation **rides on the ring** rather than filling the interior disc. Sampling
  the swirl across the whole disc with few, broad lobes produced a shape that
  read literally as a spinning fan blade.
- Everything is masked to zero before the quad's edge. Left alive at the
  boundary, the haze was sliced off square by the sprite bounds and read as the
  effect being *cropped* rather than fading.
- A wide soft bloom was tried and reverted: it read as an opaque milky cloud that
  covered the result gem and its neighbours. Louder, but less readable, which is
  the opposite of the goal.
- Duration is **matched to the sound**, not chosen by eye.
  `merge-target-immediate.ogg` peaks at 0.10-0.15 s and is ~20 dB down by 0.30 s,
  measured with a 50 ms-window RMS scan. `MERGE_RADIAL_DURATION` is 0.30 s. A
  0.78 s version was tried and read as wrong precisely because it outlasted its
  own cue threefold.
- Size stays close to the gem's own footprint (`MERGE_RADIAL_END_SCALE` 1.05).
- Per-gem variety: `MERGE_BURST_FAMILY_STYLE` gives each colour family its own
  swirl arm count and rotation direction, and `MERGE_BURST_TIER_SPARKLE` plus a
  brighter accent make objective-tier merges escalate over the commons.

`tests/run_merge_burst_presentation_v1_tests.gd` pins the parts that can regress
silently: the burst's effective z must be above the table and above every gem
while staying inside the engine's 4096 ceiling, the duration must stay inside the
cue's envelope, the tier ladder must survive the intensity clamp (a 1.0 clamp had
been flattening every tier above ordinary), and colour families must not collapse
onto one shape.

### Bugs
- **Rescue softlock (production blocker).** `ResultOverlayLayer._on_action_pressed`
  sets `_actions_pending` and disables every button so a double tap cannot buy
  twice — in rescue mode that includes GIVE UP. When the controller declined the
  request without dismissing the popup (not enough coins, or a failed save)
  nothing cleared the flag. The player could not buy, could not give up, and
  could not reach Home. Added `clear_pending_actions()` and called it on every
  declining path.
- **No offer when the player cannot pay.** Out-of-shots showed only "NOT ENOUGH
  COINS" on a button that then looked broken. It now offers a rewarded video,
  matching Skip and the powers (`COIN_ACTION_EXTRA_SHOTS`). The same dead end on
  CONTINUE was fixed the same way (`COIN_ACTION_CONTINUE`). When there is no ad
  fill the offer panel states the price and closes cleanly — it never dangles a
  video that cannot play.
- **Blast destroyed objective gems.** `POWER_BOMB_MAX_CLEARED_TIER := 4`. Tiers
  above it are pushed by the blast but never removed, so the power cannot delete
  the progress the level is asking the player to build.

## 3. Measured results (same device, same build path)

Both builds were measured with the same script (`cold start → settle 20 s → read
Home → enter a level → settle 8 s → read gameplay`), on the same device, in the
same session. The baseline is an APK exported from HEAD in a clean worktree, not
a remembered number.

Comparing readings taken at different moments after launch is meaningless here —
the ad SDK and overlays keep allocating for several seconds — which is exactly
the mistake that produced an earlier, wrong "17 MB" figure for this build. That
reading was taken ~2 s after launch, before the app had settled, and is not
comparable to anything.

| | baseline (HEAD) | optimized |
|---|---|---|
| GL texture memory, Home | 139.7 MB | **79.3 MB** |
| GL texture memory, in play | 143.3 MB | **82.9 MB** |
| Total PSS, Home | 404.2 MB | 390.1 MB |
| Total PSS, in play | 411.4 MB | 401.9 MB |

A consistent **~60 MB (42%) reduction in GPU texture memory**, which is the
figure the scene-art change is responsible for. Total PSS moves far less because
it is dominated by code, the ad SDK, and the Java heap; PSS also varies between
runs as the ad SDK settles, so the GL figure is the meaningful one.

The ~79 MB that remains at Home is larger than this project's own preloads
account for (gems 8.4 MB, UI kit 7 MB, effects and fonts under 1 MB). The
remainder sits outside the scene-art path — the ad SDK and the Android/EGL
surfaces — and was not investigated here. It is the obvious next place to look
if more headroom is wanted.

Simulation cost per frame, crowded board, interleaved best-of-7 (desktop, so the
*ratio* is the meaningful figure — the phone's CPU is far slower and the absolute
numbers scale up with it):

| gems | baseline | optimized | speedup |
|---|---|---|---|
| 10 | 0.740 ms | 0.185 ms | 4.00x |
| 20 | 2.616 ms | 0.598 ms | 4.38x |
| 30 | 5.691 ms | 1.225 ms | 4.64x |
| 40 | 9.149 ms | 1.848 ms | 4.95x |
| 55 | 13.416 ms | 2.107 ms | **6.37x** |

On-device frame times, driven through real gameplay via adb (`[PERF]` telemetry,
see §5), at 17-20 gems: median **18.06 ms**, p90 19.44 ms, p99 22.67 ms, worst
frame ~30 ms. No stalls. Typical play sits around 10-15 gems because merges keep
clearing the board; at that range the median is a locked 16.67 ms.

## 4. Verification

`tests/run_broad_phase_equivalence_v1_tests.gd` (new) proves the simulation
change is a pure optimization, not a retune:

- Every pair within contact range must appear in the candidate list
  (brute-force checked against all pairs, 120 boards).
- Candidates must stay in the ascending index order the nested loops resolved
  pairs in — a relaxation sweep is order-dependent.
- 48 chaotic boards × 90 frames must end on **byte-identical** piece positions,
  velocities and radii, **and identical contact telemetry**, versus
  `tools/bench/board_simulation_baseline.gd` — the pre-optimization simulation
  kept verbatim for this comparison.

An earlier grid-based attempt failed this suite at high density, which is how the
missing pairs were caught rather than shipped.

`tests/run_rescue_softlock_blast_safety_v1_tests.gd` (new) covers the softlock
(both in the overlay alone and through the controller with a zero balance, then
that GIVE UP still ends the attempt) and the blast tier rule (objective gems
survive a blast centred on them; commons in the same radius are still cleared).

Full suite: **35 suites, all passing.** Three test corrections were needed and
are called out because they change what is being asserted:

- `run_scene_variety_assets_tests` and `run_ui_scale_layout_tests` sampled pixels
  from table art that is now GPU-compressed; they decompress the CPU-side copy
  first. The rail-alignment check still measures the shipped texture, so it also
  confirms compression did not shift the table geometry.
- `run_gem_pattern_feedback_v1_tests` asserted three targets on every level and
  was **failing at HEAD before any of this work** — limited-shot levels
  deliberately ask for two (see `LevelConfig.generated`). It now checks the rule
  that exists.

One change was **reverted** rather than kept: limiting the Home logo texture to
768 px would have saved a further 4.5 MB, but `run_branding_push_line_tests`
explicitly pins that brand asset at 1536x1024 and the logo was outside the scope
of this task. It remains available as a further saving if wanted.

## 5. Performance telemetry

`scripts/services/performance_probe.gd` prints frame-time percentiles with a
script/render split every two seconds. It is gated behind
`GameConfig.PERFORMANCE_TELEMETRY_ENABLED`, **which ships `false`** — it was set
`true` only for the measurement builds above. It exists because
`dumpsys gfxinfo` cannot see inside a Godot GLSurfaceView, so the numbers have to
come from the running game.

Note for future device work on this phone: `log.tag` is `E`, so Godot `print()`
output is filtered out of logcat until `adb shell setprop log.tag.godot V` is
set.

## 6. Not claimed

- A general "the game is bug-free" claim. The audit here was targeted: the
  pending/locked-flag class of softlock across every overlay action, and the
  paths where a player who cannot pay is left without an offer. Those are fixed
  and covered by tests. Other areas were exercised but not exhaustively proven.
- A before/after **frame-time** table on the device. Texture memory was measured
  on both builds under an identical protocol (§3), and the simulation speedup is
  measured directly with a bit-identical-output guarantee, but the baseline APK
  was not driven through a matching instrumented play session, so no before/after
  fps comparison is claimed.
- That the remaining ~79 MB of GPU memory is optimal. It is outside the scene-art
  path and was not investigated.
