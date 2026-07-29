# Changelog

## 18-Gem Chain v1

- Rolled back to the verified `new-table-shadow-contact-fix-v1` baseline before making this isolated change.
- Added a deterministic 18-tier source/runtime asset catalog and L1→L18 contact-merge bounds; L18 is terminal.
- Preserved baseline table, HUD, launcher flow, target, physics, score, fail/win, pause, restart, sound, and haptics behavior.

## Unreleased

- Delayed victory presentation until the spawned Diamond has synchronized and completed its merge pulse; qualification still blocks any launcher/spawn immediately.
- Moved results to a dedicated CanvasLayer backdrop so win/fail UI no longer changes gem textures or modulation.
- Applied a shallower runtime-only table perspective and narrowed physical contact tolerance while retaining contact-only merge rules.

- Calibrated the tropical table presentation and gem visible-contact physics: a shallower derived table now shares the authoritative rail model, runtime gem bodies are alpha-trimmed, and per-level simple colliders match their visible main bodies.
- Reduced contact tolerance from 1.5 px to 0.75 px; collision telemetry now carries the confirmed gem or rail contact point used for audio feedback and developer-only diagnostics.
- Added F8 calibration debug rendering (off by default) for physical rails, gem colliders, and recent confirmed contact points.

- Integrated supplied tropical background, coral table, and Pearl/Ruby/Emerald/Sapphire/Diamond runtime textures.
- Replaced live procedural gem drawing with presentation-only Sprite2D synchronization; merge ghosts and HUD previews now use the same supplied texture catalog.
- Centralized the supplied trapezoid table’s visual and physical layout so rail containment, launcher clamp, danger line, and spawn coordinates use matching geometry.
- Added asset inventory, runtime derivation documentation, clean-Diamond provenance, texture mapping, and table-layout regression coverage.

- Inset the physical gameplay table into a separate procedural crystal alcove background; visual rails and collision geometry now share centralized bounds.
- Replaced generic sine feedback with original runtime crystal/glass synthesis; gem and wall contacts are distinct, thresholded, and throttled while confirmed-event routing remains intact.

- Added lightweight procedural sound routing and Android haptic feedback for launch, meaningful impacts, confirmed level merges, chains, results, and buttons.
- Added compact session-only Sound (`S`) and Vibration (`V`) controls; both default to On and survive Replay/Retry without affecting gameplay.
- Added feedback routing regression coverage while preserving all simulation, merge, lifecycle, score, danger, result, and HUD checks.

- Added a compact Pearl -> Ruby -> Emerald -> Sapphire -> Diamond progression strip with the Diamond target highlighted.
- Replaced text-heavy current/next status with procedural gem previews and concise labels; cleaned score, chain, shots, and restart layout without changing gameplay state.
- Added controller HUD snapshots, visual queue/restart/layout regression coverage, and portrait safe-bound checks for representative device sizes.

- Tuned board width, gem scale, launch/damping, restitution, contact resistance, merge momentum handoff, merge presentation cadence, and launcher readiness toward the supplied comparison recordings.
- Preserved strict same-level current-contact merge eligibility, local contact-only chains, launcher lifecycle, score, win/fail, restart, and gem mapping.
- Added portrait board/scale and bounded merge-momentum regression coverage.
- Added `*.mp4` to `.gitignore`: the two WhatsApp recordings are local comparison inputs and must never be committed.

- Tuned centralized launch, damping, settle, collision/border response, merge presentation, chain display, and next-launcher pacing constants for smoother mobile feel without changing gameplay rules.
- Added balance regression coverage for launch timing, settling/no-jitter, representative frame-step stability, border containment, chain presentation cadence, existing contact-only merges, queue lifecycle, and danger grace behavior.

- Refined the procedural jewelry-table, gem silhouettes, gem facet/highlight treatment, HUD hierarchy, result overlay, and presentation-only merge pulse.
- Added fixed-canvas visual safe-bound regression coverage; gameplay coordinate, collision, merge, launcher, score, chain, danger, and outcome behavior remain unchanged.

- Added the first procedural gemstone visual prototype: level-specific Pearl, Ruby, Emerald, Sapphire, and Diamond silhouettes; soft highlights/shadows; a lightweight luxury jewelry-table board; and clearer HUD/overlay styling.
- Fixed one presentation-only merge-readability issue by drawing source ghosts behind the upgraded simulated gem. Merge eligibility, contact capture, chains, physics, queue timing, danger rules, and launcher lifecycle are unchanged.
- Added a regression test for the fixed level-to-procedural-gem visual mapping.

- Added the complete prototype level loop: confirmed-event scoring, same-resolution chain multipliers, Diamond target/win, settled danger-line fail timing, result overlays, and full Replay/Retry reset.
- Added controller-path regression coverage for score, chain reset, win spawn blocking, danger-line rules, and full reset alongside all prior movement, merge, animation, and launcher lifecycle tests.

- Hardened the AI handoff documentation with a reusable `docs/SESSION_HANDOFF_TEMPLATE.md` and an expanded codebase knowledge map. No gameplay behavior changed.

- Added lightweight presentation-only merge polish: source-gem pull/fade, midpoint pulse, glow, and ring burst.
- Added deterministic, capped, contact-based chain merges. Only a just-created gem can chain via real radius contact with an equal-level gem.
- Added chain, animation-lifecycle, and next-launcher presentation-gate regression coverage.
- Fixed the launcher lifecycle so a settled shot advances the queue and spawns exactly one next launcher instead of spawning repeatedly every frame.
- Added runtime controller-path regression coverage for first/second shots, idle-frame spawn prevention, queue advancement, active-launcher count, and restart.
- Implemented clean gameplay milestone 1: portrait board, horizontal launcher input, straight upward shots, top/side containment, settlement-gated queue, and minimal HUD.
- Added isolated current-step contact-only merge service for Pearl → Ruby → Emerald → Sapphire → Diamond.
- Added headless integration tests for valid contact merges, rejection cases, one-merge-per-cycle, and top-border settling.

## Baseline

- Initialized clean-room Godot rebuild governance and blank portrait baseline.
- Added Android ETC2/ASTC texture-import support through `[rendering/textures/vram_compression] import_etc2_astc=true` in `project.godot`.
- Exported and package-validated the standalone blank Android baseline APK.

## New table + shadow separation v1 (in progress)

- Replaced the active table with the newly supplied table and centralized its measured UI-reference layout in `GameConfig`.
- Replaced live gem artwork with non-destructive body-only derivatives; added independent presentation-only soft shadows.
- Added regression coverage that shadow proximity cannot trigger collision/merge behavior and that the old table is not active.
