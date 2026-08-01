# Production UI Polish v4 evidence

`final-screenshots/` contains 36 real Godot 4.6.3 Compatibility/ANGLE renders:

- gameplay, Pause, Win, and Fail at 576 x 1312, 720 x 1600, 1080 x 1920, 1080 x 2340, 1080 x 2400, and narrow/tall 540 x 1320;
- simulated notch/safe-area state at 1080 x 2400;
- score 9,999, 125.5K, and 12.5M;
- current/next/target change, second target, Settings pressed, crowded board, target arrival, restart, and the reported 1,300-score reproduction;
- a direct 1000 x 1280 canvas proving the table artwork, launcher, live gems, and rail system remain horizontally centered together.

The deterministic 335-frame walkthrough is stored locally as `updated-gameplay-ui-walkthrough.avi` (11.17 seconds at 30 fps; SHA-256 `B90A4CDFE15866C53E3F1D112D81165B63D4151DE5619EE29806D0D6B8958904`). Playback automation was stopped with Escape before a complete assisted playback review; the individual production states and transitions were separately reviewed through the real-render evidence set and automated timing/state coverage.

Evidence and recording files are development-only and excluded from Android export.
