import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'myvault_reminders';
  static const String _channelName = 'MyVault Reminders';
  static const String _channelDescription =
      'Task, schedule, and study reminders from MyVault';

  static const int dailySummaryId = 900000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    if (kIsWeb) {
      debugPrint("Notifications not implemented for Web yet.");
      _initialized = true;
      return;
    }

    if (!(Platform.isAndroid || Platform.isIOS || Platform.isWindows)) {
      debugPrint(
        "Notifications not implemented for ${Platform.operatingSystem}",
      );
      _initialized = true;
      return;
    }

    try {
      tz_data.initializeTimeZones();
      final TimezoneInfo timezoneInfo =
          await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint("Timezone Error: $e");
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const windowsInit = WindowsInitializationSettings(
      appName: 'MyVault',
      appUserModelId: 'com.example.myvault',
      guid: '12345678-1234-1234-1234-123456789012',
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
        windows: windowsInit,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );

      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    _initialized = true;
  }

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    windows: WindowsNotificationDetails(),
  );

  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!_initialized) await init();
    if (when.isBefore(DateTime.now())) return;

    final tzWhen = tz.TZDateTime.from(when, tz.local);

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzWhen,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('NotificationService: failed to schedule "$title": $e');
    }
  }

  Future<void> scheduleDailySummary({
    required String body,
    int hour = 8,
    int minute = 0,
  }) async {
    if (!_initialized) await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        id: dailySummaryId,
        title: 'MyVault — Today',
        body: body,
        scheduledDate: scheduled,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('NotificationService: failed to schedule daily summary: $e');
    }
  }

  Future<void> showNow({required String title, required String body}) async {
    if (!_initialized) await init();
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  bool get supportsExactAlarms => !kIsWeb && Platform.isAndroid;
}


// Notification button
// ElevatedButton(
//   onPressed: () async {
//     await NotificationService.instance.showNow(
//       title: 'Test Notification',
//       body: 'Agar yeh dikhe toh sab sahi hai',
//     );
//   },
//   child: const Text('Test Notification Bhejo'),
// ),