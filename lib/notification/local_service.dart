import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class LocalService {
  static final AwesomeNotifications _awesome = AwesomeNotifications();
  static const String alarmChannelKey = 'charging_alarm_channel';
  static const int alarmNotificationId = 777; // ثابت للتحكم

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
        soundSource: 'resource://raw/sound',
        defaultRingtoneType: DefaultRingtoneType.Alarm,
        locked: true, // يمنع السحب
        criticalAlerts: true,
        

      ),
    ], debug: false);

    if (!await _awesome.isNotificationAllowed()) {
      await _awesome.requestPermissionToSendNotifications();
    }

    // الاستماع لضغط زر الإيقاف
    _awesome.setListeners(
      onActionReceivedMethod: (received) async {
        if (received.buttonKeyPressed == 'STOP_ALARM') {
          await cancelAlarm();
        }
      },
    );
  }

  /// إشعار أساسي (غير متكرر ولا مستمر)
  static Future<void> showBasicNotification() async {
    await _awesome.createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: alarmChannelKey,
        title: 'Charging Started',
        body: 'The Electricity is Back!⚡',
        notificationLayout: NotificationLayout.Default,
        displayOnBackground: true,
        displayOnForeground: true,
      ),
    );
  }

  /// إشعار إنذار مستمر لا ينغلق ويكرر الصوت و يهز حتى يضغط المستخدم (Alarm Style)
  static Future<void> showPersistentAlarm() async {
    await _awesome.createNotification(
      content: NotificationContent(
        id: alarmNotificationId,
        channelKey: alarmChannelKey,
        title: '⚡ Power Restored',
        body: 'Electricity is ON – Tap Stop to silence.',
        category: NotificationCategory.Alarm,
        autoDismissible: false, // لا يُغلق بالسحب
        locked: true, // لا يمكن إزالته إلا بتفاعل
        wakeUpScreen: true,
        fullScreenIntent: true,
        criticalAlert: true,
        displayOnForeground: true,
        displayOnBackground: true,
        backgroundColor: Colors.black,
        color: Colors.greenAccent,
        notificationLayout: NotificationLayout.Default,
        // تكرار الصوت عبر loopSound (مدعوم في القناة بالتشغيل) + صوت Alarm
        // لو احتجت تكرار إضافي يمكنك جدولة تحديثات لكن غالباً هذا يكفي.
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'STOP_ALARM',
          label: 'Stop',
          color: Colors.red,
          autoDismissible: true,
        ),
      ],
    );
  }

  /// إيقاف الإنذار المستمر
  static Future<void> cancelAlarm() async {
    await _awesome.cancel(alarmNotificationId);
  }

  /// للإلغاء الكلي (جميع الإشعارات)
  static Future<void> cancelAll() async => _awesome.cancelAll();
}
