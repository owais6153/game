# Google Play Production Checklist

This is an implementation-alignment checklist, not legal advice. Verify every answer in Play Console against the production AAB and current published policy before submission.

## App identity and release

- Package is `com.owais.majestygems`; confirm the Play application uses this exact package.
- Confirm Play accepts the existing upload certificate and Play App Signing is enabled.
- Upload only an AAB whose embedded version code/name are newer than every prior upload.
- Review automated pre-launch, device-catalog, native-code, and policy results before rollout.

## App content declarations

- Ads: answer **Yes**. The app contains rewarded and interstitial ads through Google Mobile Ads/AdMob.
- Privacy policy: confirm `https://teckvertexlabs.vercel.app/privacy/majestic-gems` is public, current, app-specific, and matches Firebase Analytics, AdMob/UMP, identifiers, retention/deletion, and contact practices. The same URL is linked in-app.
- Target audience: confirm the intended age groups. Current code sets UMP `tag_for_under_age_of_consent=false` and does not implement a neutral age screen or child-directed ad-request treatment. Do not declare a child/mixed-child audience unless the app and ad configuration are separately brought into Families compliance.
- Complete the content-rating questionnaire accurately, including ads and game content. Confirm served ad content is appropriate for the resulting rating.
- App access: no login is implemented; confirm reviewers can reach Home, gameplay, results, and ad choices without credentials.

## Data safety

- Do not declare that no data is collected: Firebase Analytics and Google Mobile Ads are packaged.
- Review the current Firebase Analytics and Google Mobile Ads SDK disclosure pages, then declare all applicable collection/sharing and purposes, including analytics, advertising/marketing, diagnostics where applicable, approximate location/IP-derived handling where applicable, app activity/interactions, device or other identifiers (including advertising ID where used), and Firebase installation identifiers.
- Confirm whether each item is required or optional, whether it is shared under Play's definitions, whether transport is encrypted, retention/deletion behavior, and whether users can request deletion. These answers depend on account-side configuration and the published privacy policy, not code inspection alone.
- Custom gameplay events contain level, attempt, shot, gem/target, reward, balance, placement, and failure metadata. They do not contain player names, email, free-form text, contacts, precise location, or account IDs.

## Consent and advertising

- In AdMob Privacy & messaging, publish the applicable UMP messages for every served region and verify the production App ID is attached.
- Verify Google consent mode/account settings if relying on UMP to interpret analytics/ad consent choices.
- On a test device in a regulated region/debug geography, verify consent presentation, `canRequestAds()` gating, Privacy Options availability when required, consent withdrawal, and fail-open gameplay when ads remain unavailable.
- Confirm production interstitial and rewarded unit IDs belong to this app and are active. Do not use live production ads for developer click testing.
- Verify rewarded early close grants nothing, earned callback grants exactly once, interstitials occur only after approved completed-level cadence, and ad failures continue gameplay.

## Store and release operations

- Confirm store listing name, icon, screenshots, description, contact details, category, and privacy URL match Majestic Gems.
- Complete production-access/closed-test answers using the factual summary in the production-readiness report; do not claim crashes or device tests that did not occur.
- Review target API and 64-bit/device support warnings shown by Play for the uploaded artifact.
- Install the Play-generated build on representative arm64 and, if still supported, armeabi-v7a devices; verify startup, Home, gameplay, audio, lifecycle, ads/consent, saves, and analytics DebugView.
