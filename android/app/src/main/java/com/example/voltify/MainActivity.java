package com.example.voltify;

import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.WindowManager;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "voltify/intent";
    private MethodChannel methodChannel;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // إعدادات لعرض الشاشة حتى لو الجهاز مقفول
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true);
            setTurnScreenOn(true);
        } else {
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON |
                    WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON |
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED |
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON);
        }

        // إضافة فلاج للسماح بعرض الـ Activity فوق التطبيقات
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED |
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD);

        // التحقق من الإنتينت عند بدء الـ Activity
        checkIntent(getIntent());
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        Log.d("MainActivity", "🔔 MethodChannel initialized");
        methodChannel.setMethodCallHandler((call, result) -> {
            if (call.method.equals("checkIntent")) {
                boolean shouldOpen = getIntent().getBooleanExtra("openAlarm", false);
                Log.d("MainActivity", "🔔 checkIntent called, openAlarm: " + shouldOpen);
                result.success(shouldOpen);
            } else {
                result.notImplemented();
            }
        });
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        checkIntent(intent);
    }

    private void checkIntent(Intent intent) {
        boolean shouldOpen = intent.getBooleanExtra("openAlarm", false);
        Log.d("MainActivity", "🔔 New intent received, openAlarm: " + shouldOpen);
        if (methodChannel != null) {
            new Handler(Looper.getMainLooper()).postDelayed(() -> {
                methodChannel.invokeMethod("onNewIntent", shouldOpen);
                Log.d("MainActivity", "🔔 Notified Flutter of new intent with openAlarm: " + shouldOpen);
            }, 100);
        } else {
            Log.e("MainActivity", "❌ MethodChannel is null, cannot notify Flutter");
        }
    }
}