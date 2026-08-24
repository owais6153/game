# Rail, Target Blast AAB v1.0.6

## Delivery

- AAB: `build/android/majestic-gems-rail-target-blast-v1.0.6-vc8.aab`
- Release identity: versionName `1.0.6`, versionCode `8`
- Source: `15071b8` / `rail-target-blast-v1.0.6-vc8-source`
- SHA-256: `54D92F90D0D81A637E3DDDEF5B20AEA4EC5A5E7E65A369D85BD9412B1EA6390E`

## Validation

Godot 4.6.3 exported the configured signed release AAB. Bundletool 1.18.3 validation passed. The embedded base manifest confirms package `com.owais.majestygems`, versionCode 8, versionName 1.0.6, min SDK 24, target/compile SDK 36, and dual ARM support. The archive contains 1,004 entries, the `arm64-v8a` and `armeabi-v7a` Godot/C++ library pairs, and the 34-gem runtime catalog including `gem_33` and `gem_34`; it contains no root `tests/`, `reports/`, or `scripts/dev/` entries.

`RAIL_TARGET_BLAST_GEM_EXPANSION_V1_TESTS` passed before export. The gameplay source is otherwise unchanged from the prior rail/target/blast milestone, whose eleven repository suites are recorded as passing. `jarsigner -verify -certs` completed successfully; its standard JarInputStream signed-entry notices were retained as non-fatal bundle-format output.

## Device status

No device validation is claimed. An AAB is intended for Play split delivery and is not directly installable; this delivery was not uploaded to Play in this task.
