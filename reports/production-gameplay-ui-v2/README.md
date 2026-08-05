# Production Gameplay UI V2 Evidence

All PNGs were rendered from the production `Game.tscn` with Godot 4.6.3 Compatibility/ANGLE through `tools/capture_production_gameplay_ui_v2.gd` and then visually inspected.

## Responsive captures

- `responsive/576x1312/`: current available recording aspect/resolution, normal gameplay and Pause.
- `responsive/720x1600/`: standard portrait, normal gameplay and Pause.
- `responsive/1080x1920/`: wide portrait, normal gameplay and Pause.
- `responsive/1080x2340/`: tall portrait, normal gameplay and Pause.
- `responsive/1080x2400/`: tall portrait, normal gameplay, Pause, and simulated notch/safe area.
- `responsive/540x1320/`: narrow-tall Android portrait, normal gameplay and Pause.

## State captures

- `states/large-coins-active-target.png`: maximum signed 64-bit total, target name, quantity, progress, and card balance.
- `states/target-transition.png`: existing delayed target handoff with synchronized outgoing copy/art.
- `states/coin-flight-and-target-collection.png`: four target-only coins and collected gem above the table/HUD, traveling toward live destinations.
- `states/aim-guide-danger-warning.png`: ready-state themed direction guide and near-line warning state.
- `states/crowded-board.png`: normalized presentation shadows and stable gem/UI z-order.

`production-gameplay-ui-v2-walkthrough.avi` is a local 9-second, 30 FPS deterministic walkthrough generated through `tools/record_production_gameplay_ui_v2.gd`. AVI evidence remains excluded from Git by the repository's media policy; the file is retained locally beside this README.
