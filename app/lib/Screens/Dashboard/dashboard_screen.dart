import 'package:flutter/material.dart';
import 'package:app/Screens/Project/projecthome_screen.dart';
import 'package:app/Screens/Quotes/quoteshome_screen.dart';
import 'package:app/Screens/Schedule.dart/Schedule_homepage.dart';
import 'package:app/Screens/Task/constant_goals_screen.dart';
import 'package:app/Screens/Values/valueshome_screen.dart';
import 'package:app/core/models/task_model.dart';
import 'package:app/core/services/storage_service.dart';
import 'package:app/core/utils/responsive.dart';
import 'package:app/core/widgets/common_widgets.dart';
import 'package:app/core/widgets/pin_gate.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int> onOpenTab;
  const DashboardScreen({super.key, required this.onOpenTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _AgendaItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _AgendaItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  int _completedToday = 0;
  int _pendingToday = 0;
  double _weeklyCompletionRate = 0;
  double _studyHoursThisWeek = 0;
  // List<_AgendaItem> _agenda = [];
  static const List<String> _weekDays = [
    'Thurs',
    'Fri',
    'Sat',
    'Sun',
    'Mon',
    'Tues',
    'Wed',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([
      _loadTaskStats(),
      _loadStudyStats(),
      // _loadScheduleAgenda(),
    ]);
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadTaskStats() async {
    final allTasks = await StorageService.readMap('tasks');
    final now = DateTime.now();
    final todayKey = dayKeyFor(now);

    int completed = 0;
    int pending = 0;
    int weeklyTotal = 0;
    int weeklyDone = 0;

    allTasks.forEach((key, value) {
      if (value is! List) return;
      final tasks = value
          .whereType<Map>()
          .map((e) => TaskItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (key == todayKey) {
        for (final t in tasks) {
          if (t.isDone) {
            completed++;
          } else {
            pending++;
          }
        }
      }

      // crude "this week" check: was this day's key within the last 7 days?
      final parts = key.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          final date = DateTime(y, m, d);
          if (now.difference(date).inDays < 7 && !date.isAfter(now)) {
            weeklyTotal += tasks.length;
            weeklyDone += tasks.where((t) => t.isDone).length;
          }
        }
      }
    });

    _completedToday = completed;
    _pendingToday = pending;
    _weeklyCompletionRate = weeklyTotal == 0
        ? 0
        : (weeklyDone / weeklyTotal) * 100;
  }

  Future<void> _loadStudyStats() async {
    final raw = await StorageService.readList('study_sessions');
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    int minutes = 0;
    for (final item in raw) {
      final date = DateTime.tryParse(item['date']?.toString() ?? '');
      if (date == null) continue;
      if (!date.isBefore(startOfWeek)) {
        minutes += (item['durationMinutes'] is int)
            ? item['durationMinutes'] as int
            : int.tryParse(item['durationMinutes']?.toString() ?? '') ?? 0;
      }
    }
    _studyHoursThisWeek = minutes / 60.0;
  }

  DateTime? _dateForDayName(String name) {
    const order = _weekDays;
    final today = DateTime.now();
    final diff = (today.weekday - DateTime.thursday) % 7;
    final startOfWeek = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: diff));
    final index = order.indexOf(name);
    if (index == -1) return null;
    return startOfWeek.add(Duration(days: index));
  }

  // Future<void> _loadScheduleAgenda() async {
  //   final raw = await StorageService.readLegacyFile('weekly_schedule.txt');
  //   final agenda = <_AgendaItem>[];

  //   if (raw is Map) {
  //     final now = DateTime.now();
  //     final upcoming = <MapEntry<DateTime, Map<String, dynamic>>>[];

  //     for (final day in _weekDays) {
  //       final items = raw[day];
  //       if (items is! List) continue;
  //       final dayDate = _dateForDayName(day);
  //       if (dayDate == null) continue;

  //       for (final item in items) {
  //         if (item is! Map) continue;
  //         final map = Map<String, dynamic>.from(item);
  //         if (map['isDone'] == true) continue;
  //         final startMinute = (map['startMinute'] is int)
  //             ? map['startMinute'] as int
  //             : int.tryParse(map['startMinute']?.toString() ?? '') ?? 0;
  //         final occursAt = DateTime(
  //           dayDate.year,
  //           dayDate.month,
  //           dayDate.day,
  //         ).add(Duration(minutes: startMinute));
  //         if (occursAt.isAfter(now)) {
  //           upcoming.add(MapEntry(occursAt, map));
  //         }
  //       }
  //     }

  //     upcoming.sort((a, b) => a.key.compareTo(b.key));
  //     for (final entry in upcoming.take(3)) {
  //       final categoryName = entry.value['category']?.toString() ?? 'other';
  //       final hour = entry.key.hour;
  //       final minute = entry.key.minute.toString().padLeft(2, '0');
  //       final period = hour >= 12 ? 'PM' : 'AM';
  //       final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  //       agenda.add(
  //         _AgendaItem(
  //           title: entry.value['title']?.toString() ?? 'Schedule item',
  //           subtitle: '$hour12:$minute $period',
  //           icon: Icons.calendar_month_rounded,
  //           color: _colorForCategory(categoryName),
  //         ),
  //       );
  //     }
  //   }

  //   _agenda = agenda;
  // }

  Color _colorForCategory(String name) {
    switch (name) {
      case 'study':
        return Color(0xFF1E88E5);
      case 'project':
        return Color(0xFF8E24AA);
      case 'personal':
        return Color(0xFF00897B);
      case 'fitness':
        return Color(0xFFEF6C00);
      default:
        return Color(0xFF607D8B);
    }
  }

  Future<void> _openLocked(String name, Widget Function() builder) async {
    final unlocked = await ensureSectionUnlocked(context, sectionName: name);
    if (!unlocked || !mounted) {
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => builder()));
    if (mounted) {
      _load();
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final columns = Responsive.gridColumns(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ResponsiveContent(
        child: ListView(
          padding: EdgeInsets.all(12),
          children: [
            Text(
              "${_greeting()},👋",
              style: TextStyle(
                fontSize: 25,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            InkWell(
              onTap: () {
                _openLocked('Constant Goals', () => ConstantGoalsScreen());
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outline, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Daily Tasks",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _openLocked(
                          'Constant Goals',
                          () => ConstantGoalsScreen(),
                        );
                      },
                      icon: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Container(
            //   padding: EdgeInsets.all(16),
            //   child: Column(
            //     children: [
            //       SectionHeading(
            //         title: 'Today\'s Agenda',
            //         subtitle: _agenda.isEmpty
            //             ? 'Nothing scheduled - Plan the day.'
            //             : 'Next ${_agenda.length} upcoming events',
            //       ),
            //       SizedBox(height: 10),
            //       if (_agenda.isEmpty)
            //         Container(
            //           padding: EdgeInsets.all(10),
            //           decoration: BoxDecoration(
            //             borderRadius: BorderRadius.circular(14),
            //             border: Border.all(
            //               color: scheme.outlineVariant.withValues(alpha: 0.25),
            //               width: 1.5,
            //             ),
            //           ),
            //           child: Row(
            //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //             children: [
            //               Text(
            //                 'No upcoming schedule blocks for the rest of the day.',
            //                 style: TextStyle(color: scheme.onSurfaceVariant),
            //               ),
            //               IconButton(
            //                 onPressed: () {
            //                   _openLocked(
            //                     'Constant Goals',
            //                     () => ScheduleHomepage(),
            //                   );
            //                 },
            //                 icon: Icon(
            //                   Icons.arrow_forward_ios_rounded,
            //                   size: 16,
            //                   color: scheme.onSurfaceVariant,
            //                 ),
            //               ),
            //             ],
            //           ),
            //         )
            //       else
            //         ..._agenda.map(
            //           (item) => Container(
            //             margin: EdgeInsets.only(bottom: 8),
            //             padding: EdgeInsets.all(12),
            //             decoration: BoxDecoration(
            //               color: scheme.surface.withValues(alpha: 0.7),
            //               borderRadius: BorderRadius.circular(14),
            //               border: Border.all(
            //                 color: scheme.outlineVariant.withValues(
            //                   alpha: 0.25,
            //                 ),
            //               ),
            //             ),
            //             child: Row(
            //               children: [
            //                 Container(
            //                   padding: const EdgeInsets.all(8),
            //                   decoration: BoxDecoration(
            //                     color: item.color.withValues(alpha: 0.16),
            //                     borderRadius: BorderRadius.circular(10),
            //                   ),
            //                   child: Icon(
            //                     item.icon,
            //                     color: item.color,
            //                     size: 18,
            //                   ),
            //                 ),
            //                 const SizedBox(width: 12),
            //                 Expanded(
            //                   child: Text(
            //                     item.title,
            //                     maxLines: 1,
            //                     overflow: TextOverflow.ellipsis,
            //                     style: const TextStyle(
            //                       fontWeight: FontWeight.w600,
            //                     ),
            //                   ),
            //                 ),
            //                 Text(
            //                   item.subtitle,
            //                   style: TextStyle(color: scheme.onSurfaceVariant),
            //                 ),
            //               ],
            //             ),
            //           ),
            //         ),
            //     ],
            //   ),
            // ),
            SizedBox(height: 20),
            Text(
              'Here is your day at a glance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            SizedBox(height: 16),
            GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.26),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.green,
                              size: 25,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Completed today',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$_completedToday',
                        style: TextStyle(
                          fontSize: 30,
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.26),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pending_actions_rounded,
                              color: Colors.orange,
                              size: 25,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Pending today',
                              style: TextStyle(
                                fontSize: 14,
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$_pendingToday',
                        style: TextStyle(
                          fontSize: 30,
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.26),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bar_chart_rounded,
                              color: Colors.blue,
                              size: 25,
                            ),
                            SizedBox(width: 8),

                            Text(
                              'Weekly completion',
                              style: TextStyle(
                                fontSize: 14,
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_weeklyCompletionRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 30,
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.26),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school_rounded,
                              color: Colors.purple,
                              size: 25,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Study hours',
                              style: TextStyle(
                                fontSize: 14,
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_studyHoursThisWeek.toStringAsFixed(1)}h',
                        style: TextStyle(
                          fontSize: 30,
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            SectionHeading(title: 'Quick Actions'),
            SizedBox(height: 10),
            GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3.6,
              children: [
                QuickActionTile(
                  icon: Icons.task_alt_rounded,
                  label: 'Tasks',
                  color: Colors.teal,
                  onTap: () => widget.onOpenTab(1),
                ),
                QuickActionTile(
                  icon: Icons.school_rounded,
                  label: 'Study Tracker',
                  color: Colors.blue,
                  locked: true,
                  onTap: () async {
                    final unlocked = await ensureSectionUnlocked(
                      context,
                      sectionName: 'Study Tracker',
                    );
                    if (unlocked) widget.onOpenTab(3);
                  },
                ),
                QuickActionTile(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Money',
                  color: Colors.green,
                  locked: true,
                  onTap: () async {
                    final unlocked = await ensureSectionUnlocked(
                      context,
                      sectionName: 'Money',
                    );
                    if (unlocked) widget.onOpenTab(3);
                  },
                ),
                QuickActionTile(
                  icon: Icons.calendar_month_rounded,
                  label: 'Schedule',
                  color: Colors.indigo,
                  locked: true,
                  onTap: () =>
                      _openLocked('Schedule', () => const ScheduleHomepage()),
                ),
                QuickActionTile(
                  icon: Icons.folder_copy_outlined,
                  label: 'Projects',
                  color: Colors.deepOrange,
                  locked: true,
                  onTap: () =>
                      _openLocked('Projects', () => const Projecthome()),
                ),
                QuickActionTile(
                  icon: Icons.format_quote_rounded,
                  label: 'Quotes',
                  color: Colors.pink,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Quoteshome()),
                  ),
                ),
                QuickActionTile(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Values',
                  color: Colors.amber,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Valueshome()),
                  ),
                ),
                QuickActionTile(
                  icon: Icons.flag_circle_outlined,
                  label: 'Goals',
                  color: Colors.cyan,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConstantGoalsScreen(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
