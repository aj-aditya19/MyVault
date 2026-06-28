import 'package:app/Screens/Task/constant_goals_screen.dart';
import 'package:app/Screens/Task/daily_checkin_screen.dart';
import 'package:app/Screens/Task/dailyhistory.dart';
import 'package:app/Screens/Task/task_form_sheet.dart';
import 'package:app/core/models/task_model.dart';
import 'package:app/core/services/notification_service.dart';
import 'package:app/core/services/storage_service.dart';
import 'package:app/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum _StatusFilter { all, pending, completed }

class DailyTask extends StatefulWidget {
  const DailyTask({super.key});

  @override
  State<DailyTask> createState() => _DailyTaskState();
}

class _DailyTaskState extends State<DailyTask> {
  static const _boxName = 'tasks';
  static final _uuid = Uuid();

  Map<String, List<TaskItem>> _allTasks = {};
  bool _loading = true;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  TaskPriority? _priorityFilter;
  _StatusFilter _statusFilter = _StatusFilter.all;

  String get _todayKey => dayKeyFor(DateTime.now());

  List<TaskItem> get _todayTasks => _allTasks[_todayKey] ?? [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final raw = await StorageService.readMap(_boxName);
    final parsed = <String, List<TaskItem>>{};
    bool needsMigrationSave = false;

    raw.forEach((dayKey, value) {
      if (value is! List) return;
      final tasks = <TaskItem>[];
      for (final item in value) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        if (map.containsKey('id')) {
          tasks.add(TaskItem.fromJson(map));
        } else {
          // legacy entry from the old DailyTask screen - give it a stable id.
          tasks.add(TaskItem.fromLegacy(map, dayKey, _uuid.v4()));
          needsMigrationSave = true;
        }
      }
      parsed[dayKey] = tasks;
    });

    setState(() {
      _allTasks = parsed;
      _loading = false;
    });

    if (needsMigrationSave) await _persist();
  }

  Future<void> _persist() async {
    final payload = <String, dynamic>{
      for (final entry in _allTasks.entries)
        entry.key: entry.value.map((t) => t.toJson()).toList(),
    };
    await StorageService.write(_boxName, payload);
  }

  Future<void> _syncReminder(TaskItem task) async {
    await NotificationService.instance.cancel(task.notificationId);
    if (!task.isDone && task.reminderAt != null) {
      await NotificationService.instance.scheduleAt(
        id: task.notificationId,
        title: 'Task reminder',
        body: task.title,
        when: task.reminderAt!,
      );
    }
  }

  Future<void> _openTaskForm({TaskItem? existing}) async {
    final result = await showTaskFormSheet(
      context,
      existing: existing,
      dayKey: _todayKey,
    );
    if (result == null) return;

    setState(() {
      final list = List<TaskItem>.from(_allTasks[_todayKey] ?? []);
      if (existing == null) {
        list.add(result);
      } else {
        final index = list.indexWhere((t) => t.id == result.id);
        if (index == -1) {
          list.add(result);
        } else {
          list[index] = result;
        }
      }
      _allTasks[_todayKey] = list;
    });

    await _persist();
    await _syncReminder(result);
  }

  Future<void> _toggleTask(TaskItem task) async {
    final updated = task.copyWith(
      isDone: !task.isDone,
      completedAt: !task.isDone ? DateTime.now() : null,
      clearCompletedAt: task.isDone,
    );

    setState(() {
      final list = List<TaskItem>.from(_allTasks[_todayKey] ?? []);
      final index = list.indexWhere((t) => t.id == task.id);
      if (index != -1) list[index] = updated;
      _allTasks[_todayKey] = list;
    });

    await _persist();
    await _syncReminder(updated);
  }

  Future<void> _deleteTask(TaskItem task) async {
    setState(() {
      final list = List<TaskItem>.from(_allTasks[_todayKey] ?? []);
      list.removeWhere((t) => t.id == task.id);
      _allTasks[_todayKey] = list;
    });
    await _persist();
    await NotificationService.instance.cancel(task.notificationId);
  }

  List<TaskItem> get _filteredTasks {
    var tasks = List<TaskItem>.from(_todayTasks);

    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      tasks = tasks
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                t.tags.any((tag) => tag.toLowerCase().contains(q)),
          )
          .toList();
    }

    if (_priorityFilter != null) {
      tasks = tasks.where((t) => t.priority == _priorityFilter).toList();
    }

    switch (_statusFilter) {
      case _StatusFilter.pending:
        tasks = tasks.where((t) => !t.isDone).toList();
      case _StatusFilter.completed:
        tasks = tasks.where((t) => t.isDone).toList();
      case _StatusFilter.all:
        break;
    }

    tasks.sort((a, b) {
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      final priorityCompare = a.priority.index.compareTo(b.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      return (a.dueDate ?? DateTime(2100)).compareTo(
        b.dueDate ?? DateTime(2100),
      );
    });

    return tasks;
  }

  ({int completed, int pending, double weeklyRate}) get _stats {
    final today = _todayTasks;
    final completed = today.where((t) => t.isDone).length;
    final pending = today.length - completed;

    int weeklyTotal = 0;
    int weeklyDone = 0;
    final now = DateTime.now();

    _allTasks.forEach((key, tasks) {
      final parts = key.split('-');
      if (parts.length != 3) return;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y == null || m == null || d == null) return;
      final date = DateTime(y, m, d);
      if (now.difference(date).inDays < 7 && !date.isAfter(now)) {
        weeklyTotal += tasks.length;
        weeklyDone += tasks.where((t) => t.isDone).length;
      }
    });

    final rate = weeklyTotal == 0 ? 0.0 : (weeklyDone / weeklyTotal) * 100;
    return (completed: completed, pending: pending, weeklyRate: rate);
  }

  String _dueLabel(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final diff = dueDay.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 0) return '${-diff}d overdue';
    return '${due.day}/${due.month}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final dayNumber = now.difference(DateTime(now.year, 1, 1)).inDays + 1;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _stats;
    final filtered = _filteredTasks;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Day: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '$dayNumber/365'),
                  ],
                ),
                style: const TextStyle(fontSize: 16),
              ),
              FilledButton.icon(
                onPressed: () => _openTaskForm(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Task'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              final isTablet = constraints.maxWidth > 600;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isDesktop ? 3 : 3,
                childAspectRatio: isDesktop ? 2.3 : 0.9,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  StatCard(
                    icon: Icons.check_circle_outline_rounded,
                    value: '${stats.completed}',
                    label: 'Completed today',
                    color: Colors.green,
                  ),
                  StatCard(
                    icon: Icons.pending_actions_rounded,
                    value: '${stats.pending}',
                    label: 'Pending',
                    color: Colors.orange,
                  ),
                  StatCard(
                    icon: Icons.percent_rounded,
                    value: '${stats.weeklyRate.toStringAsFixed(0)}%',
                    label: 'Weekly completion',
                    color: Colors.purple,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Dailyhistory()),
                ),
                icon: const Icon(Icons.history_rounded),
                label: const Text('History'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DailyCheckinScreen(),
                  ),
                ),
                icon: const Icon(Icons.monitor_heart_outlined),
                label: const Text('Daily Check-in'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Search tasks or tags...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _statusFilter == _StatusFilter.all,
                  onSelected: (_) =>
                      setState(() => _statusFilter = _StatusFilter.all),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Pending'),
                  selected: _statusFilter == _StatusFilter.pending,
                  onSelected: (_) =>
                      setState(() => _statusFilter = _StatusFilter.pending),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Completed'),
                  selected: _statusFilter == _StatusFilter.completed,
                  onSelected: (_) =>
                      setState(() => _statusFilter = _StatusFilter.completed),
                ),
                const SizedBox(width: 12),
                ...TaskPriority.values.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(p.label),
                      avatar: CircleAvatar(backgroundColor: p.color, radius: 6),
                      selected: _priorityFilter == p,
                      onSelected: (selected) {
                        setState(() => _priorityFilter = selected ? p : null);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      _todayTasks.isEmpty
                          ? 'No tasks yet today - tap "Add Task" to start.'
                          : 'No tasks match your filters.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final task = filtered[index];
                      return Dismissible(
                        key: ValueKey(task.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: scheme.error.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.only(bottom: 7),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteTask(task),
                        child: _TaskTile(
                          task: task,
                          dueLabel: task.dueDate != null
                              ? _dueLabel(task.dueDate!)
                              : null,
                          onToggle: () => _toggleTask(task),
                          onTap: () => _openTaskForm(existing: task),
                          onDelete: () => _deleteTask(task),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskItem task;
  final String? dueLabel;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TaskTile({
    required this.task,
    required this.dueLabel,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOverdue =
        dueLabel != null && dueLabel!.contains('overdue') && !task.isDone;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: task.isDone
              ? Colors.green.withValues(alpha: 0.14)
              : scheme.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: task.isDone
                ? Colors.green.withValues(alpha: 0.4)
                : scheme.outlineVariant.withValues(alpha: 0.26),
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              color: Colors.black12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 40,
              margin: const EdgeInsets.only(right: 10, top: 2),
              decoration: BoxDecoration(
                color: task.priority.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            GestureDetector(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.only(top: 2, right: 8),
                child: Icon(
                  task.isDone
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: task.isDone ? Colors.green : Colors.grey,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: task.isDone
                          ? Colors.green.shade800
                          : scheme.onSurface,
                      decoration: task.isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (task.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        task.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (dueLabel != null ||
                      task.tags.isNotEmpty ||
                      task.reminderAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (dueLabel != null)
                            _Badge(
                              icon: Icons.event_rounded,
                              label: dueLabel!,
                              color: isOverdue ? scheme.error : scheme.primary,
                            ),
                          if (task.reminderAt != null)
                            _Badge(
                              icon: Icons.alarm_rounded,
                              label: 'Reminder',
                              color: Colors.amber.shade800,
                            ),
                          ...task.tags.map(
                            (tag) => _Badge(
                              icon: Icons.label_outline_rounded,
                              label: tag,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
