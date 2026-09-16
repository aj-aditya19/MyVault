// import 'package:app/core/models/task_model.dart';
// import 'package:app/core/services/motivation_service.dart';
// import 'package:app/core/services/notification_service.dart';
// import 'package:app/core/services/storage_service.dart';

// /// Schedules repeating, per-category reminder notifications instead of one
// /// combined daily summary:
// ///   - Task     → 6:00, 8:00, 12:00
// ///   - Money    → 6:00, 12:00, 19:00
// ///   - Schedule → 6:00, 7:00, 8:00
// ///
// /// Each time-slot only actually notifies when there's something to nag
// /// about for that category (nothing set, or set but not finished). Once
// /// everything in a category is done, that category's remaining slots for
// /// today are cancelled so it stays quiet.
// ///
// /// Local notifications can't re-run this check at the exact moment they
// /// fire — that needs a background service Android/iOS don't hand to plain
// /// Flutter apps for free. What actually shows is whatever was true the
// /// last time `schedule()` ran: on app open, on app resume, and right after
// /// you save a task, budget, or schedule event. Opening the app now and
// /// then through the day keeps these accurate.
// class DailyReminderService {
//   DailyReminderService._();

//   static const List<int> _taskHours = [6, 8, 12];
//   static const List<int> _moneyHours = [6, 12, 19];
//   static const List<int> _scheduleHours = [6, 7, 8];

//   static const int _taskBaseId = 910000;
//   static const int _moneyBaseId = 920000;
//   static const int _scheduleBaseId = 930000;

//   static Future<void> schedule() async {
//     final today = DateTime.now();
//     final message = await MotivationService.getRandomMessage();

//     // ---- Task: today's daily task + this week's weekly task ----
//     final tasks = await StorageService.readMap('tasks');
//     final todayTasks = tasks[dayKeyFor(today)] is List
//         ? tasks[dayKeyFor(today)] as List
//         : const [];
//     final hasDailyTask = todayTasks.isNotEmpty;
//     final hasPendingDailyTask = todayTasks.any(
//       (item) => item is Map && item['isDone'] != true,
//     );

//     final weeklyTasks = await StorageService.readMap('weekly_tasks');
//     final thisWeekTasks = weeklyTasks[_weeklyTaskKey(today)] is List
//         ? weeklyTasks[_weeklyTaskKey(today)] as List
//         : const [];
//     final hasWeeklyTask = thisWeekTasks.isNotEmpty;
//     final hasPendingWeeklyTask = thisWeekTasks.any(
//       (item) => item is Map && item['isDone'] != true,
//     );

//     final taskAlerts = <String>[];
//     if (!hasDailyTask) taskAlerts.add("you haven't set today's task");
//     if (hasDailyTask && hasPendingDailyTask) {
//       taskAlerts.add("today's task is not completed");
//     }
//     if (!hasWeeklyTask) taskAlerts.add("you haven't set this week's task");
//     if (hasWeeklyTask && hasPendingWeeklyTask) {
//       taskAlerts.add("this week's task is not completed");
//     }

//     await _syncCategory(
//       baseId: _taskBaseId,
//       hours: _taskHours,
//       alerts: taskAlerts,
//       title: 'MyVault — Task',
//       message: message,
//     );

//     // ---- Money: this week's budget ----
//     final weeks = await StorageService.readList('weekly_money');
//     final moneyWeekNumber = _moneyWeekNumber(today);
//     final currentWeekMatches = weeks
//         .where((week) => week['week_number'] == moneyWeekNumber)
//         .toList();
//     final currentWeek = currentWeekMatches.isEmpty
//         ? null
//         : currentWeekMatches.first;
//     final budget = ((currentWeek?['weekly_budget'] as num?) ?? 0).toDouble();
//     final hasBudget = budget > 0;

//     double spent = 0;
//     final spending = (currentWeek?['spending'] as List?) ?? const [];
//     for (final item in spending) {
//       if (item is Map) {
//         spent += ((item['amount'] as num?) ?? 0).toDouble();
//       }
//     }
//     final budgetExceeded = hasBudget && spent > budget;

//     final moneyAlerts = <String>[];
//     if (!hasBudget) moneyAlerts.add("you haven't set this week's budget");
//     if (budgetExceeded) {
//       moneyAlerts.add("you've gone over this week's budget");
//     }

//     await _syncCategory(
//       baseId: _moneyBaseId,
//       hours: _moneyHours,
//       alerts: moneyAlerts,
//       title: 'MyVault — Money',
//       message: message,
//     );

//     // ---- Schedule: today's events + this week's events ----
//     final scheduleEvents = await StorageService.readList('schedule_events');
//     final todayKey = _scheduleDateKey(today);
//     final weekDates = _weekDateKeys(today);

//     final todayEvents = scheduleEvents
//         .where((e) => e['date']?.toString() == todayKey)
//         .toList();
//     final thisWeekEvents = scheduleEvents
//         .where((e) => weekDates.contains(e['date']?.toString()))
//         .toList();

//     final hasScheduleToday = todayEvents.isNotEmpty;
//     final hasPendingScheduleToday = todayEvents.any((e) => e['isDone'] != true);
//     final hasScheduleThisWeek = thisWeekEvents.isNotEmpty;

//     final scheduleAlerts = <String>[];
//     if (!hasScheduleToday) {
//       scheduleAlerts.add("you haven't set today's schedule");
//     }
//     if (hasScheduleToday && hasPendingScheduleToday) {
//       scheduleAlerts.add("today's schedule is not completed");
//     }
//     if (!hasScheduleThisWeek) {
//       scheduleAlerts.add("you haven't planned this week's schedule");
//     }

//     await _syncCategory(
//       baseId: _scheduleBaseId,
//       hours: _scheduleHours,
//       alerts: scheduleAlerts,
//       title: 'MyVault — Schedule',
//       message: message,
//     );
//   }

//   /// Cancels every reminder slot across all three categories — used when
//   /// the user turns notifications off entirely from Settings.
//   static Future<void> cancelAll() async {
//     for (final baseId in [_taskBaseId, _moneyBaseId, _scheduleBaseId]) {
//       for (var i = 0; i < 3; i++) {
//         await NotificationService.instance.cancel(baseId + i);
//       }
//     }
//   }

//   /// For one category: if there's nothing to nag about, cancel that
//   /// category's slots so it stays quiet today. Otherwise (re)schedule each
//   /// slot with the current alert text — this also overwrites any stale
//   /// text left over from before the user fixed something.
//   static Future<void> _syncCategory({
//     required int baseId,
//     required List<int> hours,
//     required List<String> alerts,
//     required String title,
//     required String message,
//   }) async {
//     if (alerts.isEmpty) {
//       for (var i = 0; i < hours.length; i++) {
//         await NotificationService.instance.cancel(baseId + i);
//       }
//       return;
//     }

//     final joined = _join(alerts);
//     final body = '${joined[0].toUpperCase()}${joined.substring(1)}. $message';

//     for (var i = 0; i < hours.length; i++) {
//       await NotificationService.instance.scheduleRecurringAt(
//         id: baseId + i,
//         title: title,
//         body: body,
//         hour: hours[i],
//         minute: 0,
//       );
//     }
//   }

//   /// Fires an immediate notification right now instead of waiting for the
//   /// next scheduled slot — handy for a "check now" button.
//   static Future<void> checkNow() async {
//     await schedule();
//     final today = DateTime.now();
//     final tasks = await StorageService.readMap('tasks');
//     final todayTasks = tasks[dayKeyFor(today)] is List
//         ? tasks[dayKeyFor(today)] as List
//         : const [];
//     if (todayTasks.isEmpty) {
//       await NotificationService.instance.showNow(
//         title: 'MyVault',
//         body: "You haven't set today's task yet.",
//       );
//     }
//   }

//   static String _join(List<String> parts) {
//     if (parts.length == 1) return parts.first;
//     return '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}';
//   }

//   // Matches scheduleDateKey() in schedule_event_model.dart.
//   static String _scheduleDateKey(DateTime date) =>
//       '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

//   // All 7 date keys (Monday–Sunday) of the week containing [date].
//   static List<String> _weekDateKeys(DateTime date) {
//     final monday = date.subtract(Duration(days: date.weekday - 1));
//     return List.generate(
//       7,
//       (i) => _scheduleDateKey(monday.add(Duration(days: i))),
//     );
//   }

//   // Matches the simple day-count week number used by the Money/weekly.dart
//   // screen (NOT an ISO week number).
//   static int _moneyWeekNumber(DateTime date) =>
//       ((date.difference(DateTime(date.year, 1, 1)).inDays) ~/ 7) + 1;

//   // Matches the "first Thursday" ISO-ish week key used by
//   // Task/weekly.dart's currentWeekKey.
//   static String _weeklyTaskKey(DateTime date) {
//     final year = date.year;
//     final firstJan = DateTime(year, 1, 1);
//     final difference = (DateTime.thursday - firstJan.weekday) % 7;
//     final firstThursday = firstJan.add(Duration(days: difference));

//     int weekNumber;
//     if (date.isBefore(firstThursday)) {
//       weekNumber = 1;
//     } else {
//       final daysDiff = date.difference(firstThursday).inDays;
//       weekNumber = (daysDiff ~/ 7) + 1;
//     }
//     return 'Week-$weekNumber ($year)';
//   }
// }
