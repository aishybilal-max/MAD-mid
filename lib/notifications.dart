import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';
import 'web_notify_stub.dart' if (dart.library.html) 'web_notify_web.dart';

/// Notification sounds the user can pick from (system sounds, no extra files).
const Map<String, String> kSounds = {
  'dragon': 'Dragon Alert',
  'default': 'Default',
  'notification': 'Chime',
  'ringtone': 'Ringtone',
  'alarm': 'Alarm',
  'silent': 'Silent',
};

/// To use your own Dragon sound on Android:
/// 1) copy the mp3 to android/app/src/main/res/raw/dragon_alert.mp3
///    (lowercase letters, numbers and _ only)
/// 2) change false to true below, then uninstall and reinstall the app.
const bool _useRawDragon = false;

class Notifier {
  static final FlutterLocalNotificationsPlugin _p = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  // A channel's sound cannot change after creation, so every sound has its own
  // channel and the id carries a version (v2).
  static String _channelId(String sound) => 'seaside_v2_$sound';

  // Notification id scheme: taskId * 100 + slot
  //   slot 0       -> once / daily
  //   slot 1..7    -> weekly (weekday number)
  //   slot 10..29  -> every-N-days occurrences
  static int _base(int taskId) => taskId * 100;
  static const int _testId = 2147480000;

  // ------------------------------------------------------------------ init
  static Future<void> init() async {
    if (_ready || kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      _setLocalZone();
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _p.initialize(settings);
      _ready = true;
    } catch (_) {
      return; // notifications unavailable on this platform; the app still works
    }
    try {
      final android = _p.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      // Channels first, so they always exist
      for (final e in kSounds.entries) {
        await android?.createNotificationChannel(_channel(e.key, e.value));
      }
      // Permission dialog must not block app start-up
      unawaited(android?.requestNotificationsPermission());
    } catch (_) {}
  }

  /// Finds the phone's timezone without an extra package (by matching the offset).
  static void _setLocalZone() {
    final offset = DateTime.now().timeZoneOffset;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    bool matches(tz.Location l) =>
        Duration(milliseconds: l.timeZone(nowMs).offset) == offset;
    try {
      final khi = tz.getLocation('Asia/Karachi');
      if (matches(khi)) {
        tz.setLocalLocation(khi);
        return;
      }
    } catch (_) {}
    for (final l in tz.timeZoneDatabase.locations.values) {
      if (matches(l)) {
        tz.setLocalLocation(l);
        return;
      }
    }
  }

  // --------------------------------------------------------------- sounds
  static AndroidNotificationSound? _soundFor(String s) {
    switch (s) {
      case 'dragon':
        return _useRawDragon
            ? const RawResourceAndroidNotificationSound('dragon_alert')
            : const UriAndroidNotificationSound('content://settings/system/alarm_alert');
      case 'notification':
        return const UriAndroidNotificationSound('content://settings/system/notification_sound');
      case 'ringtone':
        return const UriAndroidNotificationSound('content://settings/system/ringtone');
      case 'alarm':
        return const UriAndroidNotificationSound('content://settings/system/alarm_alert');
      default:
        return null; // system default
    }
  }

  static AndroidNotificationChannel _channel(String key, String label) {
    final silent = key == 'silent';
    return AndroidNotificationChannel(
      _channelId(key),
      'Reminders - $label',
      description: 'Task reminders ($label)',
      importance: Importance.max,
      playSound: !silent,
      sound: _soundFor(key),
      enableVibration: !silent,
      audioAttributesUsage: (key == 'dragon' || key == 'alarm')
          ? AudioAttributesUsage.alarm
          : AudioAttributesUsage.notification,
    );
  }

  static NotificationDetails _details(String sound, String body) {
    final silent = sound == 'silent';
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId(sound),
        'Reminders - ${kSounds[sound] ?? sound}',
        channelDescription: 'Task reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: !silent,
        sound: _soundFor(sound),
        enableVibration: !silent,
        category: AndroidNotificationCategory.reminder,
        styleInformation: BigTextStyleInformation(body),
        audioAttributesUsage: (sound == 'dragon' || sound == 'alarm')
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
      ),
      iOS: DarwinNotificationDetails(presentSound: !silent),
    );
  }

  // ------------------------------------------------------------ low level
  static Future<void> _zoned(
    int id,
    String title,
    String body,
    DateTime when,
    String sound, {
    DateTimeComponents? match,
  }) async {
    final date = tz.TZDateTime.from(when, tz.local);
    final details = _details(sound, body);
    for (final mode in [
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ]) {
      try {
        await _p.zonedSchedule(
          id,
          title,
          body,
          date,
          details,
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: match,
        );
        return;
      } catch (_) {
        // no exact-alarm permission: fall back to inexact
      }
    }
  }

  // ---------------------------------------------------------------- public
  static Future<void> cancelFor(int taskId) async {
    if (!_ready) return;
    final b = _base(taskId);
    for (var s = 0; s <= 7; s++) {
      await _p.cancel(b + s);
    }
    for (var s = 10; s < 30; s++) {
      await _p.cancel(b + s);
    }
  }

  static Future<void> schedule(Task t, String sound) async {
    if (!_ready || t.id == null) return;
    await cancelFor(t.id!);
    if (t.completed || !t.notify) return;

    final b = _base(t.id!);
    final title = t.title;
    final body = t.description.trim().isNotEmpty
        ? t.description.trim()
        : 'It is time for this task (${t.category})';
    final now = DateTime.now();
    final h = t.dueAt.hour, m = t.dueAt.minute;
    // Repeating tasks only start from their due date
    final dueStart = DateTime(t.dueAt.year, t.dueAt.month, t.dueAt.day);
    final from = now.isAfter(dueStart) ? now : dueStart;

    switch (t.repeat) {
      case RepeatType.none:
        if (t.dueAt.isAfter(now)) {
          await _zoned(b, title, body, t.dueAt, sound);
        }
        break;

      case RepeatType.daily:
        var d = DateTime(from.year, from.month, from.day, h, m);
        if (!d.isAfter(from)) d = DateTime(d.year, d.month, d.day + 1, h, m);
        await _zoned(b, title, body, d, sound, match: DateTimeComponents.time);
        break;

      case RepeatType.weekly:
        for (final wd in t.repeatDays) {
          var d = DateTime(from.year, from.month, from.day, h, m);
          for (var i = 0; i < 8; i++) {
            if (d.weekday == wd && d.isAfter(from)) break;
            d = DateTime(d.year, d.month, d.day + 1, h, m);
          }
          await _zoned(b + wd, title, body, d, sound,
              match: DateTimeComponents.dayOfWeekAndTime);
        }
        break;

      case RepeatType.interval:
        var slot = 10;
        for (var i = 0; i < 120 && slot < 30; i++) {
          final day = DateTime(from.year, from.month, from.day + i);
          if (!t.occursOn(day)) continue;
          final at = DateTime(day.year, day.month, day.day, h, m);
          if (!at.isAfter(now)) continue;
          await _zoned(b + slot, title, body, at, sound);
          slot++;
        }
        break;
    }
  }

  /// Sends a test notification right now. Returns a message to show the user.
  static Future<String> showTest(String sound) async {
    const title = 'Test notification';
    const body = 'If you can see this, notifications are working.';
    if (kIsWeb) return WebNotify.show(title, body);

    if (!_ready) await init();
    if (!_ready) return 'Notifications could not start on this device.';
    try {
      final android = _p.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      var enabled = await android?.areNotificationsEnabled();
      if (enabled == false) {
        enabled = await android?.requestNotificationsPermission();
      }
      if (enabled == false) {
        return 'Notifications are blocked. Open Settings > Apps > Seaside Tasks > Notifications and turn them on.';
      }
      await _p.show(_testId, title, body, _details(sound, body));
      return 'Test notification sent. Pull down the status bar if you do not see it.';
    } catch (e) {
      return 'Notification failed: $e';
    }
  }

  /// Schedules a notification 10 seconds from now. Returns a message.
  static Future<String> scheduleTest(String sound) async {
    const title = 'Scheduled test';
    const body = 'The 10 second scheduled notification is working.';
    if (kIsWeb) {
      Timer(const Duration(seconds: 10), () => WebNotify.show(title, body));
      return 'A browser notification will appear in 10 seconds. Keep this tab open.';
    }

    if (!_ready) await init();
    if (!_ready) return 'Notifications could not start on this device.';
    try {
      final android = _p.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (await android?.areNotificationsEnabled() == false) {
        return 'Notifications are blocked. Open Settings > Apps > Seaside Tasks > Notifications and turn them on.';
      }
      final exact = await android?.canScheduleExactNotifications();
      if (exact == false) {
        await android?.requestExactAlarmsPermission();
      }
      await _zoned(_testId + 1, title, body,
          DateTime.now().add(const Duration(seconds: 10)), sound);
      if (exact == false) {
        return 'Scheduled, but exact alarms are off, so it may arrive late. Turn on Settings > Apps > Seaside Tasks > Alarms & reminders.';
      }
      return 'A notification will appear in 10 seconds. You can send the app to the background.';
    } catch (e) {
      return 'Scheduling failed: $e';
    }
  }
}
