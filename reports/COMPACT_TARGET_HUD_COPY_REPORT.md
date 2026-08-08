# Compact Target HUD Copy

## Scope

Removed visible gem names from the gameplay HUD because they overflow in narrow portrait layouts. The target, Merge Path, and Next controls continue to use the authoritative gem textures; target sequence and quantity progress remain visible.

## Implementation

- Hid the compact target name label while retaining its existing state node for transition compatibility.
- Removed gem-name tooltips from Merge Path slots, Next, and Target artwork.
- Left `AssetCatalog`, progression mapping, target logic, and gameplay coordinates unchanged.

## Validation

- Updated `tools/run_production_ui_finalization_tests.gd` to assert that target gem names are not rendered during initial and sequential target transitions.
- `git diff --check`: PASS.
- Godot production UI finalization suite: BLOCKED by Godot 4.6.3 headless engine crash (signal 11), reproduced with both the default and `gl_compatibility` renderers before test output.
- Existing standalone APK check: `build/android/production-gameplay-ui-v2.apk` exists and is non-empty; it predates this copy-only patch and is not claimed as a fresh delivery APK.
- Device status: no connected Android device; no install or launch claimed.
