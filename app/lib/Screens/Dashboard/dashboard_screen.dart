import 'package:flutter/material.dart';
import 'package:app/Screens/Project/projecthome_screen.dart';
import 'package:app/Screens/Quotes/quoteshome_screen.dart';
import 'package:app/Screens/Schedule/schedule_screen.dart';
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

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  int _completedToday = 0;
  String formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m == 0) {
      return "$h hr";
    }
    return "${h}hr ${m}m";
  }

  int _pendingToday = 0;
  double _weeklyCompletionRate = 0;
  double _studyHoursThisWeek = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([_loadTaskStats(), _loadStudyStats()]);
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
      return 'Wake and Win';
    }
    if (hour < 17) {
      return 'Not enough';
    }
    return 'Doesn\' achieve anything special';
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
                        '${formatHours(_studyHoursThisWeek)}',
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
                    if (unlocked) widget.onOpenTab(2);
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
                      _openLocked('Schedule', () => const ScheduleScreen()),
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
