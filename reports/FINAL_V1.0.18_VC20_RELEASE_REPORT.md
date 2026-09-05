# Final 1.0.18 (vc20) Optimization and Release

## Scope

This milestone packages the latest codebase under the product's canonical release identity: Android versionName `1.0.18`, versionCode `20`. Higher values assigned to intermediate APK iterations were test-version drift, not intended product releases.

The code candidate includes owned inertial level-map scrolling, viewport-sized virtual rendering, the border-verified v6 boot splash, and deterministic currency-test isolation already documented in the central project documents.

## Asset and package optimization

Static reachability checks found five legacy runtime branding derivatives with no shipped-code references and explicit Android-export exclusions:

- `assets/runtime/ui/majestic_gems_logo_v3.png`
- `assets/runtime/ui/majestic_gems_app_icon_192_v3.png`
- `assets/runtime/ui/majestic_gems_app_icon_192_v4.png`
- `assets/runtime/ui/majestic_gems_system_splash_1152_v4.png`
- `assets/runtime/ui/majestic_gems_system_splash_1152_v5.png`

Those runtime derivatives were removed. Supplied originals remain preserved under `assets/logo/`. Dynamically loaded `assets/runtime/ui/kit/` resources were deliberately retained because static filename search cannot prove them unused. The existing export filters continue excluding source art, reports, tests, development scripts, editor-only addons, reference audio, and superseded runtime families from the Android payload.

Superseded local APK artifacts with noncanonical version identities were removed from `build/android`; the final APK and AAB use `majestic-gems-release-v1.0.18-vc20` filenames.

## Validation and delivery

The final source state passed every repository suite: `FINAL_REGRESSION passed=38 failed=0 total=38`. This includes the focused level-map, performance-hygiene, save/economy, asset, UI/layout, gameplay lifecycle, merge/physics, audio/privacy, analytics, AdMob, notification, and power-system coverage.

Artifact hashes, sizes, timestamps, signing identity, embedded manifest values, Bundletool status, archive audit, and device status are recorded here after the final exports and mirrored in `BUILD_MANIFEST.md`.
