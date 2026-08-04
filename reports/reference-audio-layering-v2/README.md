# Reference Audio + Reward Layering v2 evidence

These four 720×1600 PNGs were captured deterministically from production `Game.tscn` through `tools/capture_reference_audio_layering_v2.gd` using Godot 4.6.3's Compatibility renderer on ANGLE/Direct3D 11.

- `01-danger-colored-ready-guide.png`: the legal push guide shares the danger-line coral.
- `02-larger-coins-in-hud-foreground.png`: all four slightly larger coins draw above the target card while following the existing bounded route.
- `03-collected-gem-above-target-box.png`: the visual-only L5 proxy overlaps the target card in front; no target physics body remains.
- `04-l5-out-l7-in-target-handoff.png`: outgoing L5 is faded/top-left while incoming L7 is fading from the right; the sprites are prebuilt and reused.

Audio routing is verified by the headless suites and provenance record rather than inferred from silent screenshots.
