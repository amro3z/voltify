// lib/notification/local_service.dart
import 'dart:typed_data';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/android_foreground_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

// sound_mode (للسيطرة على وضع الرنين + إذن DND)
import 'package:flutter/services.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:sound_mode/permission_handler.dart' as sm_perm;

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

  // قناة جديدة لضمان وجود صوت من النظام
  static const String alarmChannelKey = 'charging_alarm_channel_v2';
  static const int alarmNotificationId = 777; // ثابت
  static const int fgServiceNotiId = 7001; // إشعار الخدمة الأمامية

  /// اطلب إذن DND Access (مرة واحدة عند تشغيل التطبيق)
  static Future<void> requestDndAccessIfNeeded() async {
    try {
      final granted = await sm_perm.PermissionHandler.permissionsGranted;
      if (!granted!) {
        await sm_perm.PermissionHandler.openDoNotDisturbSetting();
      }
    } catch (_) {
      // تجاهل الخطأ
    }
  }

  /// قبل تشغيل الرنّة: لو الموبايل Silent/Vibrate نحوله Normal
  static Future<void> _ensureAudible() async {
    try {
      final granted = await sm_perm.PermissionHandler.permissionsGranted;
      if (!granted!) {
        await sm_perm.PermissionHandler.openDoNotDisturbSetting();
        return;
      }

      // الحزمة بترجع String: 'normal'/'silent'/'vibrate' (أحيانًا فيها prefix)
      final rawStatus = await SoundMode.ringerModeStatus;
      final s = rawStatus.toString().toLowerCase();

      final isSilent = s.contains('silent');
      final isVibrate = s.contains('vibrate');

      if (isSilent || isVibrate) {
        try {
          await SoundMode.setSoundMode(RingerModeStatus.normal);
        } on PlatformException {
          await sm_perm.PermissionHandler.openDoNotDisturbSetting();
        }
      }
    } catch (_) {
      // نكمل من غير ما نكسر حاجة
    }
  }

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
        playSound: true, // لازم
        soundSource:
            'resource://raw/alarm', // ضع الملف في android/app/src/main/res/raw/alarm.mp3
        defaultRingtoneType: DefaultRingtoneType.Alarm, // Alarm stream
        locked: true,
        criticalAlerts: false, // مش هنكسر DND
      ),
    ], debug: false);

    // Android 13+: runtime permission
    if (!await _awesome.isNotificationAllowed()) {
      await _awesome.requestPermissionToSendNotifications();
    }

    _awesome.setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onDismissActionReceivedMethod:
          NotificationController.onDismissActionReceivedMethod,
    );
  }

  /// إشعار إنذار ثابت + زر إيقاف (صوت القناة يشتغل حتى لو التطبيق مقفول)
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
        fullScreenIntent: true,
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

  static Future<void> startRingingLoop() async {

    await _ensureAudible();

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

    // اضبط الجلسة على Alarm usage (عشان يرن في Silent)
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        androidAudioAttributes: AndroidAudioAttributes(
          usage: AndroidAudioUsage.alarm,
          contentType: AndroidAudioContentType.music,
        ),
        androidWillPauseWhenDucked: false,
      ),
    );

    // شغّل ملف صوتي من الأصول وكرّره (assets/sounds/alarm.mp3)
    if (_player.playing) await _player.stop();
    await _player.setAsset('assets/sounds/alarm.mp3');
    await _player.setLoopMode(LoopMode.one);
    await _player.setVolume(1.0);
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
