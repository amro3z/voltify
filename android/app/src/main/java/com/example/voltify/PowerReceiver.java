package com.example.voltify;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.*;
import android.os.Build;
import android.util.Log;
import androidx.core.app.NotificationCompat;
import java.io.*;

public class PowerReceiver extends BroadcastReceiver {
    private static final String NOTIFICATION_CHANNEL_ID = "voltify_channel";

    @Override
    public void onReceive(Context context, Intent intent) {
        Log.d("PowerReceiver", "\uD83D\uDCE5 onReceive triggered");

        if (intent == null) return;

        String action = intent.getAction();
        Log.d("PowerReceiver", "\uD83D\uDCC1 Action received: " + action);

        if (Intent.ACTION_POWER_CONNECTED.equals(action)) {
            boolean isRunning = false;
            try {
                File stateFile = new File(context.getFilesDir(), "state.txt");
                if (stateFile.exists()) {
                    BufferedReader br = new BufferedReader(new FileReader(stateFile));
                    String value = br.readLine();
                    br.close();
                    isRunning = "1".equals(value);
                }
            } catch (Exception e) {
                Log.d("PowerReceiver", "❌ Error reading state file: " + e.getMessage());
            }

            if (isRunning) {
                Intent launch = new Intent(context, MainActivity.class);
                launch.setAction(Intent.ACTION_MAIN);
                launch.addCategory(Intent.CATEGORY_LAUNCHER);
                launch.putExtra("openAlarm", true);
                launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK |
                        Intent.FLAG_ACTIVITY_CLEAR_TOP |
                        Intent.FLAG_ACTIVITY_NO_ANIMATION |
                        Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS);

                NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    NotificationChannel channel = new NotificationChannel(
                            NOTIFICATION_CHANNEL_ID,
                            "Voltify Notifications",
                            NotificationManager.IMPORTANCE_HIGH);
                    channel.enableVibration(true);
                    channel.setLockscreenVisibility(NotificationCompat.VISIBILITY_PUBLIC);
                    notificationManager.createNotificationChannel(channel);
                }

                PendingIntent pendingIntent = PendingIntent.getActivity(
                        context,
                        0,
                        launch,
                        PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
                );

                NotificationCompat.Builder builder = new NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
                        .setSmallIcon(android.R.drawable.ic_dialog_alert)
                        .setContentTitle("Power Restored")
                        .setContentText("Voltify is opening...")
                        .setPriority(NotificationCompat.PRIORITY_HIGH)
                        .setAutoCancel(true)
                        .setFullScreenIntent(pendingIntent, true)
                        .setContentIntent(pendingIntent)
                        .setVisibility(NotificationCompat.VISIBILITY_PUBLIC);

                notificationManager.notify(1, builder.build());
                context.startActivity(launch);
            }
        }
    }
}