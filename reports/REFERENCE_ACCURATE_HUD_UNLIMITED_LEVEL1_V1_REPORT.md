# Reference-Accurate HUD + Unlimited Level 1 v1

## Baseline and scope

- Source baseline: `aebf1fb` / `reference-hud-unlimited-v1`.
- Scope is presentation, Level 1 regression coverage, and portrait background fill only. Table geometry, rails, perspective scaling, collision radii, contact-only merging, motion constants, danger behavior, audio/haptics, pause fundamentals, and restart fundamentals are unchanged.

## Supplied artwork and layout

- Reference source: `assets/ui/Generated image 1 (3).png`.
- HUD artwork is drawn directly from `assets/buttons/Generated image 10.png`: SCORE region `(632,358,360,232)`, NEXT region `(632,610,360,400)`, white target region `(38,620,550,190)`, and teal settings region `(276,832,180,180)`.
- Design-space layout: SCORE `(38,48,174,136)`, five gold-ring centers from `(252,111)` in 56 px steps, NEXT `(510,48,178,158)`, active GOAL `(258,198,204,70)`, and settings `(650,216,48,48)`. This increases the former 72 px panels to the reference-scale 136/158 px composition and keeps a clear gap above the fixed table.
- Score uses Godot's fallback bold-like system font at 43 px in the supplied cream panel; the panel label remains the actual rendered source art.
- Restart, S/V, shot count, target fractions, and developer-style controls are not drawn in the gameplay HUD.

## Preview and target behavior

- NEXT, the progression strip, and GOAL all use `min(slot_width/texture_width, slot_height/texture_height)` contain scaling. No preview uses a crop, circular mask, per-frame texture load, or image analysis.
- The GOAL card reads only the controller snapshot's active target. Level 1 displays L7, then changes to L8 only after the L7 collection flight completes. The merged target body is removed from `pieces`, danger timers, and merge candidates before that presentation flight, so it has no residual physics, collision, merge, or occupancy presence.
- The final result overlay remains gated behind the final L8 collection completion and existing win hold.

## Level 1 and unlimited launches

- Exactly two sequential targets: create L7 x1, then L8 x1.
- Launch bag: deterministic cyclic `[L1, L2, L1, L3, L2, L1, L4, L2, L3, L1]` with documented effective weights L1=4, L2=3, L3=2, L4=1. L7/L8 never launch directly; this avoids the previous repetitive same-line L1/L1/L2 behavior.
- There is no `shot_limit` configuration or production launcher-cap state. The focused regression advances 30 cycles and a further 60 cycles after restart; each produces only configured L1-L4. Only danger overflow fails a run, and only completion of both targets wins it.

## Portrait fill and validation

- `stretch/aspect="expand"` retains the stable 720x1280 gameplay design space. The supplied background now cover-scales uniformly to the current viewport, filling added portrait height without distorting HUD/table/gems or changing physics coordinates.
- Automated cover assertions pass for 720x1600, 1080x1920, and 1080x2400.
- Godot 4.6.3 headless import/parse: passed.
- `CLEAN_CONTACT_TESTS`: passed.
- `LEVEL_1_FLOW_TESTS`: passed, including target collection order, no residual target body, 30-cycle unlimited generation, and 60-cycle post-restart unlimited generation.
- `MOTION_PROFILE`: passed; no gameplay per-frame resource loads.
- `adb devices -l` did not complete in this environment; installation and on-device launch are not claimed.

## APK

- File: `build/android/reference-accurate-hud-unlimited-level1-v1.apk`.
- Fresh debug export: `100,754,358 bytes`, modified `2026-07-31 07:33:18 +05:00`, SHA-256 `DB6298720500B43D70A8F80260C6AB4D9CCED4A6BE5973F4963379F58F503CA7`.
- ZIP validation found `AndroidManifest.xml` and `classes.dex`; full delivery metadata is in `BUILD_MANIFEST.md`.
