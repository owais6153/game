package com.owais.majestygems.analytics;

import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;

import com.google.firebase.analytics.FirebaseAnalytics;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.Iterator;

/** Android-only Firebase Analytics adapter exposed as Engine.get_singleton("FirebaseAnalytics"). */
public final class FirebaseAnalyticsPlugin extends GodotPlugin {
    private static final String TAG = "MajestyAnalytics";
    private final Godot godotInstance;
    private FirebaseAnalytics firebaseAnalytics;

    public FirebaseAnalyticsPlugin(Godot godot) {
        super(godot);
        godotInstance = godot;
        ensureFirebaseAnalytics();
        Log.i(TAG, firebaseAnalytics != null
                ? "Firebase Analytics bridge registered"
                : "Firebase Analytics bridge registered; Activity initialization deferred");
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "FirebaseAnalytics";
    }

    @UsedByGodot
    public boolean logEvent(String eventName, String parametersJson) {
        if (!ensureFirebaseAnalytics()) {
            Log.w(TAG, "Rejected custom event because Firebase Analytics is unavailable: " + eventName);
            return false;
        }
        if (eventName == null || eventName.isEmpty()) {
            Log.w(TAG, "Rejected empty custom event name");
            return false;
        }
        final Bundle parameters = new Bundle();
        try {
            final JSONObject json = new JSONObject(parametersJson == null ? "{}" : parametersJson);
            final Iterator<String> keys = json.keys();
            while (keys.hasNext()) {
                final String key = keys.next();
                final Object value = json.get(key);
                if (value instanceof Boolean) {
                    parameters.putLong(key, (Boolean) value ? 1L : 0L);
                } else if (value instanceof Integer || value instanceof Long) {
                    parameters.putLong(key, ((Number) value).longValue());
                } else if (value instanceof Number) {
                    parameters.putDouble(key, ((Number) value).doubleValue());
                } else if (value != JSONObject.NULL) {
                    parameters.putString(key, String.valueOf(value));
                }
            }
        } catch (JSONException exception) {
            Log.e(TAG, "Rejected malformed parameters for " + eventName, exception);
            return false;
        }
        try {
            firebaseAnalytics.logEvent(eventName, parameters);
            Log.i(TAG, "Forwarded custom event to Firebase: " + eventName);
            return true;
        } catch (RuntimeException exception) {
            Log.e(TAG, "Firebase rejected custom event: " + eventName, exception);
            return false;
        }
    }

    private boolean ensureFirebaseAnalytics() {
        if (firebaseAnalytics != null) {
            return true;
        }
        try {
            if (godotInstance.getActivity() == null) {
                return false;
            }
            firebaseAnalytics = FirebaseAnalytics.getInstance(godotInstance.getActivity());
            Log.i(TAG, "Firebase Analytics native instance available");
            return true;
        } catch (RuntimeException exception) {
            Log.e(TAG, "Firebase Analytics bridge initialization failed", exception);
            return false;
        }
    }
}
