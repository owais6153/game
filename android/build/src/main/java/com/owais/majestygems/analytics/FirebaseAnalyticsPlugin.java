package com.owais.majestygems.analytics;

import android.os.Bundle;

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
    private final FirebaseAnalytics firebaseAnalytics;

    public FirebaseAnalyticsPlugin(Godot godot) {
        super(godot);
        firebaseAnalytics = FirebaseAnalytics.getInstance(godot.getActivity());
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "FirebaseAnalytics";
    }

    @UsedByGodot
    public void log_event(String eventName, String parametersJson) {
        if (eventName == null || eventName.isEmpty()) {
            return;
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
        } catch (JSONException ignored) {
            // Do not let malformed optional analytics payloads affect the game.
        }
        firebaseAnalytics.logEvent(eventName, parameters);
    }
}
