// lib/notification/local_service.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/android_foreground_service.dart';
import 'package:flutter/material.dart';

import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

// للتحكم في وضع الرنين + إذن عدم الإزعاج (DND)
import 'package:flutter/services.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:sound_mode/permission_handler.dart' as sm_perm;

class NotificationController {
  /// يتم استدعاؤها عند الضغط على زر من داخل الإشعار أو الضغط على الإشعار نفسه
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    // زر إيقاف
    if (action.buttonKeyPressed == 'STOP_ALARM') {
      await LocalService.stopRingingLoop();
      await LocalService.cancelAlarm();
      return;
    }
    if (action.channelKey == LocalService.alarmChannelKey &&
        action.buttonKeyPressed == null) {
      await LocalService.stopRingingLoop();
      await LocalService.cancelAlarm();
    }
  }

  /// يتندّى لما الإشعار يتقفل/يتسحب
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

  // غيّر المفتاح لو سبق جرّبت قناة قديمة عشان تتأكد إعدادات القناة تتطبّق فعلاً
  static const String alarmChannelKey = 'charging_alarm_channel_v6';
  static const int alarmNotificationId = 777; // إشعار المنبّه
  static const int fgServiceNotiId = 7001; // إشعار الخدمة الأمامية

  static StreamSubscription<AudioInterruptionEvent>? _intSub;
  static StreamSubscription<void>? _noisySub;

  /// طلب إذن DND (مرة واحدة)
  static Future<void> requestDndAccessIfNeeded() async {
    try {
      final granted = await sm_perm.PermissionHandler.permissionsGranted;
      if (!(granted ?? false)) {
        await sm_perm.PermissionHandler.openDoNotDisturbSetting();
      }
    } catch (_) {}
  }

  /// قبل التشغيل: لو الموبايل Silent/Vibrate نحوله Normal (قد يتطلب إذن DND من بعض الأجهزة)
  static Future<void> _ensureAudible() async {
    try {
      final granted = await sm_perm.PermissionHandler.permissionsGranted;
      if (!(granted ?? false)) {
        await sm_perm.PermissionHandler.openDoNotDisturbSetting();
        return;
      }
      final raw = await SoundMode.ringerModeStatus;
      final s = raw.toString().toLowerCase();
      if (s.contains('silent') || s.contains('vibrate')) {
        try {
          await SoundMode.setSoundMode(RingerModeStatus.normal);
        } on PlatformException {
          await sm_perm.PermissionHandler.openDoNotDisturbSetting();
        }
      }
    } catch (_) {}
  }

  /// تهيئة القناة + الليسنرز
  static Future<void> initNotifications({bool background = false}) async {
    await _awesome.initialize(
      'resource://drawable/notification', // أيقونة صغيرة (أبيض/شفاف)
      [
        NotificationChannel(
          channelKey: alarmChannelKey,
          channelName: 'Charging Alarm',
          channelDescription: 'Persistent alarm when device starts charging',
          importance: NotificationImportance.Max, // أعلى أولوية
          defaultColor: Colors.green,
          channelShowBadge: true,
          enableLights: true,
          ledColor: Colors.green,
          enableVibration: true,
          playSound: true,
          soundSource:
              'resource://raw/alarm', 
          defaultRingtoneType:
              DefaultRingtoneType.Alarm,
          locked: true, 
          criticalAlerts: false,
          vibrationPattern: Int64List.fromList([0, 900, 400, 1100, 400, 1300]),
        ),
      ],
      debug: false,
    );
    if (!background && !await _awesome.isNotificationAllowed()) {
      await _awesome.requestPermissionToSendNotifications(
        permissions: const [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Vibration,
          NotificationPermission.Light,
          NotificationPermission.OverrideDnD,
        ],
      );
    }

    _awesome.setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onDismissActionReceivedMethod:
          NotificationController.onDismissActionReceivedMethod,
    );
  }

  static Future<void> openChannelSettings() async {
    try {
      await _awesome.showNotificationConfigPage();
    } catch (_) {}
  }

  static Future<void> showPersistentAlarm() async {
    await _awesome.createNotification(
      content: NotificationContent(
        id: alarmNotificationId,
        channelKey: alarmChannelKey,
        title: '⚡ Power Restored',
        body: 'Electricity is BACK — Tap Stop to silence.',
        category: NotificationCategory.Alarm,
        autoDismissible: false,
        locked: true,
        wakeUpScreen: true,
        fullScreenIntent: true,
        displayOnForeground: true,
        displayOnBackground: true,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'STOP_ALARM',
          label: 'Stop',
          actionType: ActionType.SilentAction, // يتنفّذ في الخلفية
          autoDismissible: true,
          color: Colors.red,
        ),
      ],
    );
    print("Persistent alarm shown");
  }

  /// تشغيل اللوب الطويل على “Alarm stream” ويرجع تلقائي بعد أي مقاطعة
  static Future<void> startRingingLoop() async {
    await _ensureAudible();

    // Foreground service: علشان أندرويد ما يوقفش الصوت في الخلفية
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

    // جهّز الجلسة كمنبّه (Alarm) عشان يتأثّر من سلّم “منبّه” الجهاز
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        androidAudioAttributes: AndroidAudioAttributes(
          usage: AndroidAudioUsage.alarm, // الأهم
          contentType:
              AndroidAudioContentType.sonification, // أفضل من music للمنبّهات
        ),
        androidWillPauseWhenDucked: false,
      ),
    );
    await session.setActive(true);

    // مقاطعات النظام: نكمّل تلقائي بعد انتهاء المقاطعة
    await _intSub?.cancel();
    _intSub = session.interruptionEventStream.listen((event) async {
      if (event.begin) {
        if (event.type != AudioInterruptionType.duck) {
          try {
            await _player.pause();
          } catch (_) {}
        }
      } else {
        try {
          await session.setActive(true);
          if (!_player.playing) await _player.play();
        } catch (_) {}
      }
    });

    await _noisySub?.cancel();
    _noisySub = session.becomingNoisyEventStream.listen((_) async {
      try {
        await session.setActive(true);
        if (!_player.playing) await _player.play();
      } catch (_) {}
    });

    // شغّل ملف الصوت من الأصول وكرّره
    if (_player.playing) {
      try {
        await _player.stop();
      } catch (_) {}
    }
    await _player.setAsset('assets/sounds/alarm.mp3');
    await _player.setLoopMode(LoopMode.one);
    await _player.setVolume(1.0); // يتأثّر من Alarm volume
    await _player.play();
  }

  /// إيقاف اللوب + الخدمة الأمامية + تنظيف الليسنرز
  static Future<void> stopRingingLoop() async {
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await AndroidForegroundService.stopForeground(fgServiceNotiId);
    } catch (_) {}
    try {
      await _intSub?.cancel();
    } catch (_) {}
    try {
      await _noisySub?.cancel();
    } catch (_) {}
    _intSub = null;
    _noisySub = null;
  }

  /// إلغاء إشعار المنبّه
  static Future<void> cancelAlarm() async {
    try {
      await _awesome.cancel(alarmNotificationId);
    } catch (_) {}
  }

  /// إلغاء كل إشعارات Awesome
  static Future<void> cancelAll() async {
    try {
      await _awesome.cancelAll();
    } catch (_) {}
  }
}
