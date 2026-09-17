import 'package:app/core/services/motivation_service.dart';
import 'package:app/core/services/notification_service.dart';
import 'package:app/core/services/storage_service.dart';

class DailyReminderService {
  DailyReminderService._();

  static const int _taskBaseId = 910000;
  static const int _moneyBaseId = 920000;
  static const int _scheduleBaseId = 930000;

  static const List<(int, int)> _taskTimes = [
    (6, 0),
    (8, 0),
    (11, 30),
    (14, 0),
    (16, 0),
  ];
  static const List<(int, int)> _moneyTimes = [
    (8, 0),
    (12, 0),
    (16, 0),
    (20, 0),
  ];

  static Future<void> schedule() async {
    final notification = NotificationService.instance;

    await notification.init();

    final now = DateTime.now();
    final motivation = await MotivationService.getRandomMessage();

    await _syncTasks(now, motivation);
    await _syncMoney(now, motivation);
    await _syncSchedule(now);
  }

  static Future<void> _syncTasks(DateTime now, String motivation) async {
    final tasks = await StorageService.readMap('tasks');

    final todayKey = '${now.year}-${now.month}-${now.day}';

    final rawTodayTasks = tasks[todayKey];

    final todayTasks = rawTodayTasks is List ? rawTodayTasks : <dynamic>[];

    final hasDailyTask = todayTasks.isNotEmpty;

    final hasPendingDailyTask = todayTasks.any(
      (task) => task is Map && task['isDone'] != true,
    );

    final weeklyTasks = await StorageService.readMap('weekly_tasks');

    final weekKey = _weeklyTaskKey(now);

    final rawWeeklyTasks = weeklyTasks[weekKey];

    final currentWeekTasks = rawWeeklyTasks is List
        ? rawWeeklyTasks
        : <dynamic>[];

    final hasWeeklyTask = currentWeekTasks.isNotEmpty;

    final hasPendingWeeklyTask = currentWeekTasks.any(
      (task) => task is Map && task['isDone'] != true,
    );

    final messages = <String>[];

    if (!hasDailyTask) {
      messages.add("You haven't set today's task yet.");
    } else if (hasPendingDailyTask) {
      messages.add("You still have today's task pending.");
    }

    if (!hasWeeklyTask) {
      messages.add("You haven't set this week's task yet.");
    } else if (hasPendingWeeklyTask) {
      messages.add("You still have this week's task pending.");
    }

    if (messages.isEmpty) {
      await _cancelSlots(_taskBaseId, _taskTimes.length);
      return;
    }

    final body = '${messages.join(' ')} $motivation';

    await _scheduleSlots(
      baseId: _taskBaseId,
      times: _taskTimes,
      title: 'MyVault — Tasks',
      body: body,
    );
  }

  static Future<void> _syncMoney(DateTime now, String motivation) async {
    final weeks = await StorageService.readList('weekly_money');

    final weekNumber = _moneyWeekNumber(now);

    Map<String, dynamic>? currentWeek;

    for (final week in weeks) {
      if (week['week_number'] == weekNumber) {
        currentWeek = week;
        break;
      }
    }

    final budget = ((currentWeek?['weekly_budget'] as num?) ?? 0).toDouble();

    final hasBudget = budget > 0;

    double spent = 0;

    final spending = (currentWeek?['spending'] as List?) ?? const [];

    for (final item in spending) {
      if (item is Map) {
        spent += ((item['amount'] as num?) ?? 0).toDouble();
      }
    }

    final messages = <String>[];

    if (!hasBudget) {
      messages.add("You haven't set this week's budget yet.");
    } else if (spent > budget) {
      messages.add("You've gone over this week's budget.");
    }

    if (messages.isEmpty) {
      await _cancelSlots(_moneyBaseId, _moneyTimes.length);
      return;
    }

    final body = '${messages.join(' ')} $motivation';

    await _scheduleSlots(
      baseId: _moneyBaseId,
      times: _moneyTimes,
      title: 'MyVault — Money',
      body: body,
    );
  }

  static Future<void> _syncSchedule(DateTime now) async {
    final events = await StorageService.readList('schedule_events');

    final todayKey = _dateKey(now);

    final todayEvents = events.where((event) {
      return event['date']?.toString() == todayKey && event['isDone'] != true;
    }).toList();

    await _cancelSlots(_scheduleBaseId, 30);

    if (todayEvents.isEmpty) {
      return;
    }

    var notificationIndex = 0;

    for (final event in todayEvents) {
      final start = _parseTime(event['start']?.toString());

      if (start == null) {
        continue;
      }

      final eventTime = DateTime(
        now.year,
        now.month,
        now.day,
        start.hour,
        start.minute,
      );

      final title = event['title']?.toString().trim().isNotEmpty == true
          ? event['title'].toString()
          : 'Your schedule';

      final reminders = <Duration>[
        const Duration(hours: 2),
        const Duration(hours: 1),
        const Duration(minutes: 15),
      ];

      for (final offset in reminders) {
        final reminderTime = eventTime.subtract(offset);

        if (!reminderTime.isAfter(now)) {
          continue;
        }

        if (notificationIndex >= 30) {
          break;
        }

        final id = _scheduleBaseId + notificationIndex++;

        final offsetText = offset.inMinutes == 15
            ? '15 minutes'
            : '${offset.inHours} hour${offset.inHours == 1 ? '' : 's'}';
        await NotificationService.instance.scheduleAt(
          id: id,
          title: 'MyVault — Schedule',
          body: '$title starts in $offsetText.',
          when: reminderTime,
        );
      }

      if (notificationIndex >= 30) {
        break;
      }
    }
  }

  static Future<void> _scheduleSlots({
    required int baseId,
    required List<(int, int)> times,
    required String title,
    required String body,
  }) async {
    await _cancelSlots(baseId, times.length);

    final now = DateTime.now();

    for (var i = 0; i < times.length; i++) {
      final (hour, minute) = times[i];

      final when = DateTime(now.year, now.month, now.day, hour, minute);

      if (!when.isAfter(now)) {
        continue;
      }

      await NotificationService.instance.scheduleAt(
        id: baseId + i,
        title: title,
        body: body,
        when: when,
      );
    }
  }

  static Future<void> _cancelSlots(int baseId, int count) async {
    for (var i = 0; i < count; i++) {
      await NotificationService.instance.cancel(baseId + i);
    }
  }

  static Future<void> cancelAll() async {
    await _cancelSlots(_taskBaseId, 10);
    await _cancelSlots(_moneyBaseId, 10);
    await _cancelSlots(_scheduleBaseId, 30);
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _weeklyTaskKey(DateTime date) {
    final year = date.year;
    final firstJan = DateTime(year, 1, 1);

    final difference = (DateTime.thursday - firstJan.weekday) % 7;

    final firstThursday = firstJan.add(Duration(days: difference));

    int weekNumber;

    if (date.isBefore(firstThursday)) {
      weekNumber = 1;
    } else {
      final daysDiff = date.difference(firstThursday).inDays;

      weekNumber = (daysDiff ~/ 7) + 1;
    }

    return 'Week-$weekNumber ($year)';
  }

  static int _moneyWeekNumber(DateTime date) {
    return ((date.difference(DateTime(date.year, 1, 1)).inDays) ~/ 7) + 1;
  }

  static _TimeValue? _parseTime(String? value) {
    if (value == null) return null;

    final parts = value.split(':');

    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return null;
    }

    return _TimeValue(hour, minute);
  }
}

class _TimeValue {
  final int hour;
  final int minute;

  const _TimeValue(this.hour, this.minute);
}
