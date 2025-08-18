// lib/notification/local_service.dart
import 'dart:typed_data';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/android_foreground_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class NotificationController {
  /// بيتنادى لما المستخدم يضغط على زر أو على الإشعار نفسه
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    if (action.buttonKeyPressed == 'STOP_ALARM') {
      await LocalService.stopRingingLoop();
      await LocalService.cancelAlarm();
    }
  }

  /// بيتنادى لما الإشعار يتقفل/يتسحب
  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction action,
  ) async {
    await LocalService.stopRingingLoop();
    await LocalService.cancelAlarm();
  }
}

class LocalService {
  static final AwesomeNotifications _awesome = AwesomeNotifications();
  static final AudioPlayer _player = AudioPlayer();

  static const String alarmChannelKey = 'charging_alarm_channel';
  static const int alarmNotificationId = 777; // ثابت
  static const int fgServiceNotiId = 7001; // إشعار الخدمة الأمامية

  /// call once (main.dart)
  static Future<void> initNotifications() async {
    await _awesome.initialize('resource://drawable/notification', [
      NotificationChannel(
        channelKey: alarmChannelKey,
        channelName: 'Charging Alarm',
        channelDescription: 'Persistent alarm when device starts charging',
        importance: NotificationImportance.Max,
        defaultColor: Colors.green,
        channelShowBadge: true,
        enableLights: true,
        ledColor: Colors.green,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1200, 500, 1500]),
        playSound: true,
        // يجب أن يكون لديك ملف alarm.mp3 أو alarm.wav في android/app/src/main/res/raw/
        soundSource: 'resource://raw/alarm',
        defaultRingtoneType: DefaultRingtoneType.Alarm,
        locked: true,
        criticalAlerts: true,
      ),
    ], debug: false);

    // Android 13+: لازم الإذن runtime
    if (!await _awesome.isNotificationAllowed()) {
      await _awesome.requestPermissionToSendNotifications();
    }

    // IMPORTANT: static/top-level handlers
    _awesome.setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onDismissActionReceivedMethod:
          NotificationController.onDismissActionReceivedMethod,
    );
  }

  /// إشعار بسيط (اختياري للاختبار)
  static Future<void> showBasicNotification() async {
    await _awesome.createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: alarmChannelKey,
        title: 'Charging Started',
        body: 'The Electricity is Back! ⚡',
        notificationLayout: NotificationLayout.Default,
        displayOnBackground: true,
        displayOnForeground: true,
      ),
    );
  }

  /// إشعار إنذار ثابت + زر إيقاف (لا يغلق تلقائياً)
  static Future<void> showPersistentAlarm() async {
    await _awesome.createNotification(
      content: NotificationContent(
        id: alarmNotificationId,
        channelKey: alarmChannelKey,
        title: '⚡ Power Restored',
        body: 'Electricity is ON – Tap Stop to silence.',
        category: NotificationCategory.Alarm,
        autoDismissible: false,
        locked: true,
        wakeUpScreen: true,
        fullScreenIntent: true, // لو مش محتاجه احذف السطر ده
        criticalAlert: true,
        displayOnForeground: true,
        displayOnBackground: true,
        notificationLayout: NotificationLayout.Default,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'STOP_ALARM',
          label: 'Stop',
          actionType: ActionType.SilentAction, // بدون فتح التطبيق
          color: Colors.red,
          autoDismissible: true,
        ),
      ],
    );
  }

  /// بدء رنّة متكررة عبر Foreground Service + just_audio
  static Future<void> startRingingLoop() async {
    // إشعار الخدمة الأمامية (يظهر كثابت)
    await AndroidForegroundService.startAndroidForegroundService(
      content: NotificationContent(
        id: fgServiceNotiId,
        channelKey: alarmChannelKey,
        title: 'Electricity is BACK ⚡',
        body: 'Tap STOP to silence',
        category: NotificationCategory.Alarm,
        autoDismissible: false,
        locked: true,
        displayOnBackground: true,
        displayOnForeground: true,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'STOP_ALARM',
          label: 'Stop',
          actionType: ActionType.SilentAction,
          autoDismissible: true,
        ),
      ],
      foregroundStartMode: ForegroundStartMode.stick,
      foregroundServiceType: ForegroundServiceType.mediaPlayback,
    );

    // شغّل ملف صوتي من الأصول وكرّره
    // ضيف الملف في pubspec: assets/sounds/alarm.mp3
    if (_player.playing) await _player.stop();
    await _player.setAsset('assets/sounds/alarm.mp3');
    await _player.setLoopMode(LoopMode.one);
    await _player.play();
  }

  static Future<void> stopRingingLoop() async {
    await _player.stop();
    await AndroidForegroundService.stopForeground(fgServiceNotiId);
  }

  static Future<void> cancelAlarm() async {
    await _awesome.cancel(alarmNotificationId);
  }

  static Future<void> cancelAll() async => _awesome.cancelAll();
}
