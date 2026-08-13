# Google Play Closed Testing Release AAB

Date: 2026-08-13 (Asia/Karachi)

## Deliverable

- Path: `D:\Owais\game\build\android\majestic-gems-closed-test.aab`
- Raw bundle size: 47,475,500 bytes (45.28 MiB)
- Modified: 2026-08-13T10:09:17.3928442+05:00
- SHA-256: `700CA075051FB62F4356B62C477CADD5DD428056DAB44D5B6635741409649912`
- Source configuration commit: `6d72e238063ecceafb89abf778fefb36cf8c5c1b`

## Release identity and signing

- Package/application ID: `com.owais.majestygems`
- versionCode: `1`
- versionName: `Majestic Gems`
- Build: Godot 4.6.3 Gradle release Android App Bundle
- Signing: user-provided upload keystore and alias; not the Godot debug keystore. The keystore and password-bearing `.godot/export_credentials.cfg` are ignored and were not committed.
- Signature verification: `jarsigner` reported `jar verified`; the bundle uses the Teckvertex Labs RSA-2048 upload certificate and not the known Godot debug certificate.

## Android configuration

- Compile SDK: 36
- Target SDK: 36
- Minimum SDK: 24
- ABI: arm64-v8a only
- Gradle export: enabled
- Native-library compression: enabled
- Manifest permissions include Internet, network state, and advertising ID access required by the integrated Google Mobile Ads SDK.
- The release manifest contains no `android:debuggable` attribute, so the application uses Android's non-debuggable default.

## AdMob and UMP

- The bundle manifest contains exactly one Google Mobile Ads application-ID metadata entry and it matches the requested Majestic Gems production App ID.
- The compiled `ad_config.gdc` extracted from the AAB resolves the requested production interstitial and rewarded IDs when its release branch is evaluated.
- Google demo IDs remain dormant debug constants for debug APK safety; the compiled release branch does not select them.
- Existing monetization behavior is unchanged: interstitial consideration after every second completed level and Double Coins only after one confirmed rewarded callback.
- UMP is in production mode. Forced geography evaluates to `0`/disabled for release, the release test-device list has zero entries, and the temporary physical-device hash is absent from the bundle.
- No consent reset call or forced/custom consent form behavior is present. The official UMP update/form flow and patched native `can_request_ads()` bridge remain packaged.
- Privacy policy: `https://teckvertexlabs.vercel.app/privacy/majestic-gems`

## Verification performed

- Focused `run_admob_integration_tests.gd`: `ADMOB_INTEGRATION_TESTS: PASS`. Godot then reported the previously documented late Poing mock callback during teardown; no assertion failed.
- Godot release export: PASS, exit 0.
- Bundle ZIP read: PASS, 937 entries.
- Bundletool `validate`: PASS, exit 0.
- Bundletool manifest dump: package, versions, SDKs, Internet permission, AdMob metadata, Poing AdMob/UMP registrations, and non-debuggable status verified from the generated AAB.
- JAR signature cryptographic verification: PASS. Standard self-signed upload-certificate/no-timestamp warnings do not invalidate the verified bundle.
- Packaged compiled-config probe: production interstitial PASS, production rewarded PASS, forced geography `0`, release UMP test-device count `0`.
- Packaged search: temporary UMP hash absent; consent reset markers absent; privacy-policy URL present; native `can_request_ads()` symbol present in packaged DEX.
- Failure safety remains covered by the focused suite: unavailable interstitial completes progression, unavailable rewarded restores the normal path without granting a bonus, and ads cannot start until authoritative UMP permission permits them.

## Known limitations

- An AAB is not directly installable. This artifact was not installed on the connected device and no Play-generated split APK/device delivery test is claimed.
- Play Console history was not accessible. versionCode `1` is suitable for the stated first upload; if Play Console reports it was already used, increment the versionCode and rebuild rather than reusing it.
- Google Play, AdMob account verification, consent-message delivery, ad serving, and the required closed-testing participation period are external services and cannot be completed by the local export.

## Manual Play Console handoff

1. Confirm Play App Signing is enabled and that Play accepts this upload certificate.
2. Upload `majestic-gems-closed-test.aab` to the Closed testing track and review Play's automated bundle checks.
3. Add the intended tester list, satisfy the required tester participation period, add release notes, and roll out the closed-test release.
4. Complete or verify the store listing, Ads declaration, app access, content rating, target audience (13+), privacy-policy URL, and Data safety answers. The Data safety declaration must accurately cover Google Mobile Ads/UMP and advertising identifiers.
5. Install the Play-delivered build from the tester opt-in link and verify first launch, official UMP behavior in applicable regions, Privacy Options availability where required, unavailable-ad fallbacks, interstitial cadence, and exactly-once rewarded coins.
