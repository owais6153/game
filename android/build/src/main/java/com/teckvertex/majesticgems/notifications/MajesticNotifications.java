package com.teckvertex.majesticgems.notifications;

import android.Manifest;
import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.Arrays;
import java.util.List;

/**
 * Local scheduled notifications for the daily-missions reminder.
 *
 * Deliberately dumb: it schedules, cancels, and reports permission state. Every
 * decision about whether a reminder is warranted, when it should land and what
 * it should say is made in GDScript (NotificationService), so that logic is
 * covered by the regression suite instead of living in native code that only a
 * device can exercise.
 *
 * Local rather than push: the reminder is about state the device already knows,
 * so there is no server, no account, and it works offline.
 */
public class MajesticNotifications extends GodotPlugin {

    private static final String PLUGIN_NAME = "MajesticNotifications";
    /** Must match NotificationService.PLUGIN_NAME on the GDScript side. */
    private static final int PERMISSION_REQUEST_CODE = 9631;

    public MajesticNotifications(Godot godot) {
        super(godot);
    }

    @NonNull
    @Override
    public String getPluginName() {
        return PLUGIN_NAME;
    }

    /**
     * Schedules the reminder `delaySeconds` from now, replacing any reminder
     * already pending under the same id.
     *
     * FLAG_UPDATE_CURRENT with a stable id is what makes a reschedule replace
     * rather than stack: the GDScript side re-evaluates on every mission change,
     * so this is called far more often than once a day.
     */
    @UsedByGodot
    public void schedule(int id, int delaySeconds, String title, String body,
                         String channelId, String channelName) {
        Context context = getActivity();
        if (context == null) {
            return;
        }
        ensureChannel(context, channelId, channelName);

        AlarmManager alarms = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
        if (alarms == null) {
            return;
        }
        long triggerAt = System.currentTimeMillis() + Math.max(0L, (long) delaySeconds * 1000L);

        // Inexact on purpose. A missions reminder does not need to land on the
        // second, and setExactAndAllowWhileIdle needs SCHEDULE_EXACT_ALARM on
        // Android 12+, which Play grants only to alarms and timers - asking for
        // it here would risk the listing for no player-visible benefit.
        alarms.set(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent(context, id, title, body, channelId));
    }

    @UsedByGodot
    public void cancel(int id) {
        Context context = getActivity();
        if (context == null) {
            return;
        }
        AlarmManager alarms = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
        if (alarms != null) {
            alarms.cancel(pendingIntent(context, id, "", "", ""));
        }
    }

    /**
     * Android 13+ will silently drop every notification until POST_NOTIFICATIONS
     * is granted. Below 13 it is granted by manifest.
     */
    @UsedByGodot
    public boolean hasPermission() {
        Context context = getActivity();
        if (context == null) {
            return false;
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return true;
        }
        return ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
                == PackageManager.PERMISSION_GRANTED;
    }

    @UsedByGodot
    public void requestPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return;
        }
        if (getActivity() == null || hasPermission()) {
            return;
        }
        ActivityCompat.requestPermissions(getActivity(),
                new String[]{Manifest.permission.POST_NOTIFICATIONS}, PERMISSION_REQUEST_CODE);
    }

    /**
     * GDScript calls this through `has_method`/`call`, which resolve snake_case
     * against the Java names above; these two aliases keep both spellings
     * working so the service does not have to care.
     */
    @UsedByGodot
    public boolean has_permission() {
        return hasPermission();
    }

    @UsedByGodot
    public void request_permission() {
        requestPermission();
    }

    private PendingIntent pendingIntent(Context context, int id, String title, String body, String channelId) {
        Intent intent = new Intent(context, ReminderReceiver.class);
        intent.putExtra(ReminderReceiver.EXTRA_TITLE, title);
        intent.putExtra(ReminderReceiver.EXTRA_BODY, body);
        intent.putExtra(ReminderReceiver.EXTRA_CHANNEL, channelId);
        intent.putExtra(ReminderReceiver.EXTRA_ID, id);
        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags |= PendingIntent.FLAG_IMMUTABLE;
        }
        return PendingIntent.getBroadcast(context, id, intent, flags);
    }

    /** Creating an existing channel is a no-op, so this is safe to repeat. */
    static void ensureChannel(Context context, String channelId, String channelName) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return;
        }
        NotificationManager manager =
                (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager == null) {
            return;
        }
        NotificationChannel channel = new NotificationChannel(
                channelId, channelName, NotificationManager.IMPORTANCE_DEFAULT);
        channel.setShowBadge(true);
        manager.createNotificationChannel(channel);
    }

    @NonNull
    @Override
    public List<String> getPluginMethods() {
        return Arrays.asList("schedule", "cancel", "hasPermission", "requestPermission", "has_permission", "request_permission");
    }
}
