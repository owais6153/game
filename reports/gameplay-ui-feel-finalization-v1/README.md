# Gameplay UI Feel Finalization v1 Evidence

These PNGs were captured deterministically from the production `Game.tscn` presentation through `tools/capture_gameplay_ui_finalization.gd` using Godot 4.6.3's ANGLE renderer. The requested 720×1600 desktop window was capped by the available desktop display to 720×1061; exact 720×1600, 1080×1920, and 1080×2400 layout bounds are covered separately by `tools/run_gameplay_ui_feel_tests.gd`.

- `final-hud.png`: normal HUD with one ready unlimited launcher.
- `large-score.png`: compact `125.5K` score fit.
- `settings-popup.png`: modal pause dimmer, Resume, and supplied pause-only RESTART.
- `merge-impact.png`: contained result gem, impact rays/ring, and local score feedback.
- `target-collection-mid-flight.png`: opaque visual-only L7 proxy traveling from the table toward the active target.
- `target-collection-late-fade.png`: proxy at the target during the deliberately late fade phase.
- `final-target-before-win.png`: L8 collection visible before any result overlay.
- `win-overlay.png`: final overlay after collection and confirmation hold.
- `crowded-board.png`: 20-gem presentation stress fixture.

The report directory is ignored by Godot at runtime and is not packaged into the APK.
