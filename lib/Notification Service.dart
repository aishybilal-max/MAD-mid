import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Reference implementation (flutter_local_notifications ^17.x).
/// Compare with / replace your existing notification file.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Channel settings cannot be changed later, which is why the id includes a version.
  static const String _channelId = 'seaside_reminders_v2';
  static const String _channelName = 'Task Reminders';
  static bool _ready = false;

  static Future<void> init() async {
    if (kIsWeb || _ready) return;

    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Karachi'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Reminders for your tasks',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
    _ready = true;
  }

  static NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
        ),
      );

  static Future<void> showTest() async {
    await init();
    await _plugin.show(
      0,
      'Test notification',
      'If you can see this, notifications are working',
      _details(),
    );
  }

  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    await init();
    if (when.isBefore(DateTime.now())) return;
    final date = tz.TZDateTime.from(when, tz.local);
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        date,
        _details(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // If exact alarm permission is missing, fall back to inexact
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        date,
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);
  static Future<void> cancelAll() => _plugin.cancelAll();
}