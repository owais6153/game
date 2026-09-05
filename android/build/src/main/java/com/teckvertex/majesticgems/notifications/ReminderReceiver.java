package com.teckvertex.majesticgems.notifications;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

import androidx.core.app.NotificationCompat;

/**
 * Posts the reminder when its alarm fires, and opens the game when it is tapped.
 *
 * The alarm carries its own title and body rather than recomputing them here.
 * Mission state can change between scheduling and firing, but the GDScript side
 * reschedules on every change - including cancelling when the last mission is
 * claimed - so whatever is pending is by construction still accurate.
 */
public class ReminderReceiver extends BroadcastReceiver {

    public static final String EXTRA_TITLE = "majestic_title";
    public static final String EXTRA_BODY = "majestic_body";
    public static final String EXTRA_CHANNEL = "majestic_channel";
    public static final String EXTRA_ID = "majestic_id";

    @Override
    public void onReceive(Context context, Intent intent) {
        if (context == null || intent == null) {
            return;
        }
        String title = intent.getStringExtra(EXTRA_TITLE);
        String body = intent.getStringExtra(EXTRA_BODY);
        String channelId = intent.getStringExtra(EXTRA_CHANNEL);
        int id = intent.getIntExtra(EXTRA_ID, 1001);
        if (title == null || title.isEmpty() || channelId == null || channelId.isEmpty()) {
            return;
        }

        MajesticNotifications.ensureChannel(context, channelId, "Daily missions");

        Intent launch = context.getPackageManager()
                .getLaunchIntentForPackage(context.getPackageName());
        PendingIntent contentIntent = null;
        if (launch != null) {
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
            int flags = PendingIntent.FLAG_UPDATE_CURRENT;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                flags |= PendingIntent.FLAG_IMMUTABLE;
            }
            contentIntent = PendingIntent.getActivity(context, id, launch, flags);
        }

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, channelId)
                .setSmallIcon(android.R.drawable.star_on)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(new NotificationCompat.BigTextStyle().bigText(body))
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setAutoCancel(true);
        if (contentIntent != null) {
            builder.setContentIntent(contentIntent);
        }

        NotificationManager manager =
                (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager == null) {
            return;
        }
        try {
            manager.notify(id, builder.build());
        } catch (SecurityException denied) {
            // POST_NOTIFICATIONS was revoked between scheduling and firing.
            // Nothing to recover: the reminder is optional by design.
        }
    }
}
