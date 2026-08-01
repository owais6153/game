# Initial Production UI Audit

Baseline: `e7a028d` / `gameplay-ui-feel-finalization-v1`  
Audit date: 2026-08-01  
Primary recording size: 576 x 1312 portrait

The audit used both project-root recordings, all six supplied UI compositions, both supplied button sheets, every active HUD atlas region, all 18 catalog gem derivatives, the runtime background/table assets, the scene tree, UI scripts, project stretch settings, and real-render baseline captures. `/mnt/data` copies were not available in this Windows workspace; the byte-identifiable project-root copies were inspected instead.

## Videos inspected

| Recording | Duration / stream | SHA-256 |
| --- | --- | --- |
| `WhatsApp Video 2026-08-01 at 4.03.38 AM.mp4` | 188.28 s, 576 x 1312, 24 fps | `F7598CF3E622E4729697823AEDD551CC880B83DB6BBC6D48C16BFAD83DFDC532` |
| `WhatsApp Video 2026-08-01 at 4.06.58 AM.mp4` | 6.41 s, 576 x 1312, about 24 fps | `8CDEDF0AB7515DEDC62E9921A4A2FA557CD8CD72D721F11E5F34C5DE1E8E1B87` |

Contact sheets are in `baseline-video-frames/`; the long recording was sampled over its complete 188-second duration and at one-second detail around opening and ending states. The pause recording was sampled every 250 ms. Recording overlays and phone status elements were treated as external capture UI, not game UI.

## Supported portrait canvases recorded before editing

- Project design viewport: 720 x 1280.
- Project mode: `canvas_items` with `expand`, portrait orientation.
- Required validation sizes: 576 x 1312, 720 x 1600, 1080 x 1920, 1080 x 2340, 1080 x 2400, plus a narrow/tall 540 x 1320 device.
- Baseline safe-area handling: no reusable design-token abstraction or deterministic notch override existed.

## Findings and dispositions

| ID | Classification | Initial issue | Evidence / impact | Production disposition |
| --- | --- | --- | --- | --- |
| A01 | layout, hierarchy | SCORE and NEXT used visibly different proportions and did not balance the top row. | Both recordings and baseline screenshots. | Rebuilt as equal 176 x 150 responsive NinePatch cards in one `HBoxContainer`. |
| A02 | typography, hierarchy | SCORE title/value hierarchy was weak; the small panel made larger values risky. | Baseline score 9,999 and 12.5M captures. | Dynamic title/value structure, adaptive font size, grouping/compact formatter, overflow tests through signed 64-bit maximum. |
| A03 | state, asset | NEXT preview depended on UI update discipline and had no explicit catalog-mapping regression. | Queue changes in long recording. | One `AssetCatalog.gem_texture(next_level)` path, stale-swap animation, all-tier mapping tests. |
| A04 | accessibility/readability | Five progression gems and their spacing were too small to parse quickly. | Long recording at 576 px width. | Five active Level 1 tiers retained, enlarged to 48 px slots with connectors, heading, reached/current border states, and no 18-tier crowding. |
| A05 | hierarchy | Target was not the clearest objective; the label and `MAKE x1` treatment did not expose progress well. | Both gameplay recording and supplied gameplay reference. | 340 x 108 target card with target index, catalog name/icon, numeric progress, progress bar, ARRIVING/COMPLETE states, and aligned collection destination. |
| A06 | layout, hierarchy | Level badge and settings felt detached from the objective system. | Gameplay recording. | Level, target, and Settings now share a single responsive objective row with consistent spacing. |
| A07 | responsiveness | Top elements sat close to screen edges and had no deterministic notch test. | 576 x 1312 capture and source inspection. | Safe-area margins, narrow-width scaling, simulated 24/72/24/48 insets, and exact-size screenshots. |
| A08 | layout | HUD/table separation depended on fixed source rectangles rather than a reusable container tree. | Source hierarchy inspection. | HUD is a dedicated layer-40 `CanvasLayer` with safe margin and container rows; table transform remains isolated. |
| A09 | typography | UI mixed dynamic fallback text with baked labels and scattered font sizing. No project font file exists. | Complete font/asset inventory. | One cached emboldened fallback `FontVariation`; shared type sizes/colors; dynamic text is never baked into new assets. |
| A10 | technical implementation | Presentation colors, padding, radii, shadows, touch sizes, and animation timing were scattered. | HUD/result source inspection. | Added cached `UiDesignSystem` theme/tokens with shared colors, sizes, spacing, styles, safe padding, and timings. |
| A11 | input, state | Settings lacked visible press feedback and Android Back had no explicit mobile notification route. | Short pause recording and input source. | 88 px design touch target, scale feedback, focus support, Back opens/closes Pause first and cannot dismiss results. |
| A12 | layout, state | Pause was functional but visually small/temporary; Restart used a baked asset rather than the same interactive style system. | Short recording and baseline pause capture. | Larger centered modal, 52% dim, title/subtitle/divider, primary Resume and secondary Restart, complete normal/hover/pressed/disabled/focus states. |
| A13 | state | Repeated fast pause/result presentation needed explicit duplicate protection. | Source audit. | Visibility/present-count guards and regression tests ensure one popup and one connection per route. |
| A14 | layout, hierarchy | Fail retained the result art slot while hiding its icon, leaving a large empty void and debug-like composition. | Baseline fail screenshot. | Purposeful coral exclamation badge occupies the shared art slot; score and Retry spacing match Win. |
| A15 | copy, hierarchy | Win used retry-oriented copy and weak result hierarchy. | Baseline win screenshot. | `LEVEL COMPLETE`, completion subtitle, final target art, formatted score, and valid `REPLAY`; no invalid Level 2 destination. |
| A16 | animation | Popup and value changes were abrupt or inconsistent. | Frame-by-frame pause review. | Shared fast tween durations for score, NEXT, target swap/pulse, settings press, and modal scale/fade enter/exit. |
| A17 | performance | UI created no formal guarantee against resource creation/node rebuilding during rapid updates. | Source audit. | Preloads only, cached theme/font/style resources, event-only updates, 500-update node-stability test, no HUD `_process`. |
| A18 | asset | Existing panel/button sheets required correct slicing; replacing them would risk an art-style mismatch. | 1024 x 1536 ARGB sheet inspection. | Retained approved sheet and used AtlasTexture/NinePatch slicing; no new raster art required. |
| A19 | asset | Six supplied UI reference images are 941 x 1672 RGB compositions, not runtime panels and have no alpha. | Asset metadata inspection. | Preserved as reference-only; dynamic production panels remain Control-based. |
| A20 | responsiveness | Popups, long score text, target text, and touch targets were not proven over all requested aspect ratios. | Baseline only represented the current desktop canvas. | Exact-resolution captures and layout assertions cover six portrait canvases plus simulated notch/navigation insets. |
| A21 | technical implementation | Result and HUD were code-created types without reusable PackedScene entry points. | Scene hierarchy audit. | Added `scenes/ui/GameplayHud.tscn` and `ResultOverlay.tscn`; controller preloads/instantiates them once. |
| A22 | state | Exit animation made the old test assume the modal vanished in the same call. | Regression compatibility run. | Production remains immediately unpaused while the 140 ms visual exit completes; test now asserts both phases. |
| A23 | technical implementation | `project.godot` contained a malformed BOM-derived key in the initial dirty worktree. | Initial `git diff`. | Canonicalized the file while preserving 720 x 1280, expand stretch, portrait, compatibility renderer, and texture settings. |

No gameplay defect was found that required a simulation, balance, table, rail, perspective, collider, merge, reward, sound, or haptic change. Android Back routing is the only controller edit beyond scene instantiation, and it changes UI state only.

## Cross-screen consistency result

Pause, Win, and Fail now use the same cream panel, safe-area centering, dimmer opacity, typography family, corner/shadow language, score formatter, and primary action style. Win and Fail retain state-specific iconography and copy. Normal gameplay exposes only Settings; Restart is restricted to Pause.
