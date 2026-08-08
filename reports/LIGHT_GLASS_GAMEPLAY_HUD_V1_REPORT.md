# Light Glass Gameplay HUD v1 Report

Date: 2026-08-08

## Scope

Presentation-only gameplay HUD update requested by the user. No gameplay/table/background changes.

## Implemented

- Coins top-left, Next top-right.
- Level below Coins, Settings below Next.
- Removed `MERGE PATH` heading.
- Progression strip centered immediately above Target.
- Target centered immediately above the table using `GameConfig.board_top()`.
- Light cyan/blue StyleBoxFancy glass styling based on the Fancy StyleBoxes Panel8 visual language.
- Shared glass treatment for primary/secondary buttons and Pause modal.
- Transparent gradients, layered rim/highlight, squircle corners, and soft shadow provide a frosted-glass appearance.

## Blur decision

No true backdrop blur was added. StyleBoxFancy does not blur framebuffer content by itself. Implementing real blur requires a screen-reading shader/backdrop capture and would introduce extra Android GL Compatibility cost/risk. This milestone therefore uses a transparent layered glassmorphism approximation only.

## Preserved

Table position/size/art, background, gem art, simulation, colliders, merge logic, launcher, target rules, scoring, audio/haptics, and gameplay animations were not intentionally modified. Existing target/coin destinations continue to resolve from live HUD control rectangles.

## Validation available in this uploaded workspace

- Source structure and references were inspected after editing.
- `MERGE PATH` literal is absent from gameplay HUD construction.
- No local `.git` directory was included, so `git status`, commit/tag creation, and push could not be performed from this ZIP.
- No Godot executable was available in the execution environment, so an engine parser/run/export and APK validation could not be truthfully claimed.
- Final device validation is still required in Godot 4.6.3 / Android.
