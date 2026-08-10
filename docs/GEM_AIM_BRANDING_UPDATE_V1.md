# Gem Aim Branding Update V1

- Current game name: **Gem Aim**.
- Home logo source: `res://assets/runtime/gem-aim-logo.png` (user supplied; no crop/re-generation).
- Project/app icon source: `res://assets/runtime/gem-aim-icon.png` (user supplied).
- Android main launcher derivative: `res://assets/runtime/ui/gem_aim_app_icon_192.png`.
- Android native splash icon: `res://assets/runtime/ui/gem_aim_system_splash_icon.png`, created only by contain-resizing/padding the supplied transparent logo; no artwork change.
- Adaptive icon layers are disabled so the launcher falls back to the supplied square icon instead of recomposing/cropping the branding.
- Obsolete `crystal_magic_*` runtime UI assets were removed from the delivered project and are also excluded by the Android export preset.
- The Android export remains `export_filter="all_resources"` with exclusions, preserving the runtime-safe configuration that produced a working APK.
