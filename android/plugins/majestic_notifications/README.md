# Majestic Notifications plugin

Local scheduled notification for the daily-missions reminder.

## What is here

| File | Role |
| --- | --- |
| `MajesticNotifications.java` | The Godot plugin singleton. Schedules, cancels, reports and requests permission. |
| `ReminderReceiver.java` | Posts the notification when the alarm fires; taps open the game. |

All of the *decisions* live in `scripts/services/notification_service.gd`:
whether a reminder is warranted, when it lands, and what it says. This layer is
deliberately dumb so the interesting behaviour is covered by
`tests/run_daily_reminder_v1_tests.gd` rather than requiring a device.

## Wiring it into a build

The plugin is compiled into the current custom build template. Its authoritative
Java sources are mirrored into `android/build/src/main/java`, and the manifest
registers both the Godot singleton and alarm receiver.

No gradle module and no `.aar` are involved: the sources sit directly in the
build template's own source set, and the manifest carries all three pieces of
registration:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<meta-data
    android:name="org.godotengine.plugin.v2.MajesticNotifications"
    android:value="com.teckvertex.majesticgems.notifications.MajesticNotifications" />
<receiver
    android:name="com.teckvertex.majesticgems.notifications.ReminderReceiver"
    android:exported="false" />
```

**This directory is the reference copy, not the one that compiles.** Only
`android/build` is on the gradle source path, so the two cannot collide - but
they can silently diverge. Edit the `android/build` copy and mirror it here.

Desktop and any Android package built without the custom template still degrade
to a tested no-op when the singleton is absent.

## Deliberate choices

- **Inexact alarms.** `AlarmManager.set()` rather than
  `setExactAndAllowWhileIdle()`. Exact alarms need `SCHEDULE_EXACT_ALARM` on
  Android 12+, which Play grants only to alarm and timer apps; a missions
  reminder does not need second accuracy and the permission would put the
  listing at risk for no player-visible gain.
- **One stable notification id.** `FLAG_UPDATE_CURRENT` with a fixed id makes a
  reschedule replace the pending alarm. The GDScript side reschedules on every
  mission-state change, so without this the alarms would stack.
- **The alarm carries its own copy.** Title and body are baked into the
  `PendingIntent` instead of being recomputed at fire time, because the
  scheduler already cancels the alarm when the last mission is claimed.

## Not done

- **No boot receiver.** Alarms do not survive a reboot, so a device restarted
  before 19:00 misses that day's reminder and gets one again the next time the
  game runs and reschedules. Fixing this needs `RECEIVE_BOOT_COMPLETED` plus a
  receiver that re-reads the saved state outside the engine.
- **Placeholder small icon.** `android.R.drawable.star_on` stands in for a real
  monochrome notification icon, which has to be authored as a white-on-
  transparent silhouette at the five density buckets.
- Physical delivery timing still requires a connected Android device; build and
  packaged-manifest validation do not prove an OEM delivered the alarm.
