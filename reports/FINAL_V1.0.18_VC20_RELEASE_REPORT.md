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

## Artifacts

- APK: `build/android/majestic-gems-release-v1.0.18-vc20.apk`, 89,678,524 bytes, SHA-256 `640309FAAD804E9B8E154F1B82CC6CA06D52DB029341A2E253D1DA5412192004`.
- AAB: `build/android/majestic-gems-release-v1.0.18-vc20.aab`, 89,540,155 bytes, SHA-256 `3B647507616AC697097A0D9030D0C591047BE0926596399E6FB393A95EDC8D67`.
- Source: commit `9eacdff`, tag `final-v1.0.18-vc20-source`; clean at export.

Bundletool 1.18.3 validates the AAB and reports package `com.owais.majestygems`, versionCode `20`, versionName `1.0.18`, min SDK 24, target/compile SDK 36. AAPT2 independently reports the same APK identity. Both include `arm64-v8a` and `armeabi-v7a` and no x86 libraries. The AAB contains 1,250 archive entries and the APK 1,241; neither contains tests, reports, development scripts, or the five retired branding derivatives.

The APK verifies under Signature Scheme v2 and the AAB JAR signature verifies with the existing upload certificate: `CN=Muhammad Owais Khan, OU=Development, O=Teckvertex Labs, L=Karachi, ST=Sindh, C=PK`, certificate SHA-256 `e3ba3287a50af4ac49c07cbcb2e4f10940ad519642cb24f21bcf856b3f3bce14`.

`adb devices -l` returned no connected device. Installation, launch, Firebase DebugView, native notification behavior, phone performance, and physical visual acceptance were not tested and are not claimed.
