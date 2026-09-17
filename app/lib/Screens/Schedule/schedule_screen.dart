import 'package:flutter/material.dart';

import 'package:app/core/models/schedule_event_model.dart';
import 'package:app/core/services/daily_reminder_service.dart';
import 'package:app/core/services/storage_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const String _boxName = 'schedule_events';
  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const List<String> _weekdayShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  List<ScheduleEvent> _events = [];
  bool _loading = true;

  String _viewMode = 'week';
  DateTime _selectedDate = _startOfDay(DateTime.now());
  DateTime _anchor = _startOfDay(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _mondayOf(DateTime d) =>
      _startOfDay(d).subtract(Duration(days: d.weekday - 1));

  DateTime get _today => _startOfDay(DateTime.now());

  Future<void> _load() async {
    final raw = await StorageService.readList(_boxName);
    final events =
        raw
            .whereType<Map>()
            .map((e) => ScheduleEvent.fromJson(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    setState(() {
      _events = events;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    _events.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    await StorageService.write(
      _boxName,
      _events.map((e) => e.toJson()).toList(),
    );
    await DailyReminderService.schedule();
  }

  List<ScheduleEvent> _eventsOn(DateTime day) {
    final key = scheduleDateKey(day);
    return _events.where((e) => scheduleDateKey(e.date) == key).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
  }

  String _eventStatus(ScheduleEvent e) {
    if (e.isDone) return 'Completed';
    final now = DateTime.now();
    if (now.isAfter(e.endDateTime)) return 'Missed';
    if (now.isAfter(e.startDateTime) && now.isBefore(e.endDateTime)) {
      return 'In Progress';
    }
    return 'Upcoming';
  }

  Color _statusColor(String status, ColorScheme scheme) {
    switch (status) {
      case 'Completed':
        return const Color(0xFF22C55E);
      case 'In Progress':
        return scheme.primary;
      case 'Missed':
        return scheme.error;
      default:
        return scheme.onSurfaceVariant;
    }
  }

  Future<void> _toggleDone(String id) async {
    final index = _events.indexWhere((e) => e.id == id);
    if (index == -1) return;
    setState(() => _events[index].isDone = !_events[index].isDone);
    await _persist();
  }

  Future<void> _deleteEvent(String id) async {
    setState(() => _events.removeWhere((e) => e.id == id));
    await _persist();
  }

  Future<void> _openEventForm({
    ScheduleEvent? existing,
    DateTime? defaultDate,
  }) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final subtitleController = TextEditingController(
      text: existing?.subtitle ?? '',
    );
    DateTime date = existing?.date ?? defaultDate ?? _selectedDate;
    TimeOfDay start = existing?.start ?? const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay end = existing?.end ?? const TimeOfDay(hour: 10, minute: 0);
    ScheduleCategory category = existing?.category ?? ScheduleCategory.other;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: dialogContext,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setDialogState(() => date = picked);
            }

            Future<void> pickStart() async {
              final picked = await showTimePicker(
                context: dialogContext,
                initialTime: start,
              );
              if (picked != null) setDialogState(() => start = picked);
            }

            Future<void> pickEnd() async {
              final picked = await showTimePicker(
                context: dialogContext,
                initialTime: end,
              );
              if (picked != null) setDialogState(() => end = picked);
            }

            return AlertDialog(
              backgroundColor: scheme.surface,
              surfaceTintColor: scheme.surfaceTint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(existing == null ? 'Add Event' : 'Edit Event'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: subtitleController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ScheduleCategory>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: ScheduleCategory.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(c.icon, size: 16, color: c.color),
                                  const SizedBox(width: 8),
                                  Text(c.label),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => category = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: pickDate,
                      icon: const Icon(Icons.event_outlined),
                      label: Text('${date.day}/${date.month}/${date.year}'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: pickStart,
                            icon: const Icon(Icons.schedule_outlined),
                            label: Text(start.format(dialogContext)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('to'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: pickEnd,
                            icon: const Icon(Icons.schedule_outlined),
                            label: Text(end.format(dialogContext)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                if (existing != null)
                  TextButton(
                    onPressed: () async {
                      await _deleteEvent(existing.id);
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, false);
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: scheme.error),
                    child: const Text('Delete'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;
                    final startM = start.hour * 60 + start.minute;
                    final endM = end.hour * 60 + end.minute;
                    if (endM <= startM) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('End time must be after start time.'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !mounted) return;
    final title = titleController.text.trim();
    if (title.isEmpty) return;

    setState(() {
      if (existing == null) {
        _events.add(
          ScheduleEvent(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: title,
            subtitle: subtitleController.text.trim(),
            date: date,
            start: start,
            end: end,
            category: category,
          ),
        );
      } else {
        existing
          ..title = title
          ..subtitle = subtitleController.text.trim()
          ..date = date
          ..start = start
          ..end = end
          ..category = category;
      }
      _selectedDate = date;
      _anchor = date;
    });
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEventForm(defaultDate: _selectedDate),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNavRow(scheme),
                    const SizedBox(height: 12),
                    Expanded(child: _buildBody(scheme)),
                  ],
                ),
              ),
            ),
    );
  }

  String _navLabel() {
    if (_viewMode == 'week') {
      final monday = _mondayOf(_anchor);
      return '${_monthNames[monday.month - 1]} ${monday.year}';
    } else if (_viewMode == 'day') {
      return '${_monthNames[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}';
    }
    return '${_monthNames[_anchor.month - 1]} ${_anchor.year}';
  }

  Widget _buildNavRow(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => setState(() => _shiftAnchor(-1)),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                _navLabel(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _shiftAnchor(1)),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'day', label: Text('Day')),
              ButtonSegment(value: 'week', label: Text('Week')),
              ButtonSegment(value: 'month', label: Text('Month')),
            ],
            selected: {_viewMode},
            onSelectionChanged: (sel) => setState(() => _viewMode = sel.first),
          ),
        ),
      ],
    );
  }

  void _shiftAnchor(int direction) {
    if (_viewMode == 'week') {
      _anchor = _anchor.add(Duration(days: 7 * direction));
    } else if (_viewMode == 'day') {
      _selectedDate = _selectedDate.add(Duration(days: direction));
      _anchor = _selectedDate;
    } else {
      _anchor = DateTime(_anchor.year, _anchor.month + direction, 1);
    }
  }

  List<DateTime> _weekDaysFor(DateTime anchor) {
    final monday = _mondayOf(anchor);
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  Widget _buildBody(ColorScheme scheme) {
    switch (_viewMode) {
      case 'week':
        return _buildWeekList(scheme);
      case 'month':
        return SingleChildScrollView(child: _buildMonthGrid(scheme));
      case 'day':
      default:
        return _buildDayAgenda(scheme);
    }
  }

  Widget _buildWeekList(ColorScheme scheme) {
    final days = _weekDaysFor(_anchor);
    return ListView.separated(
      itemCount: days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final day = days[i];
        final events = _eventsOn(day);
        final isToday = _isSameDay(day, _today);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isToday
                ? scheme.primary.withValues(alpha: 0.08)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
            border: isToday
                ? Border.all(color: scheme.primary, width: 1.2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _selectedDate = day;
                  _viewMode = 'day';
                }),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_weekdayShort[day.weekday - 1]}, ${_monthNames[day.month - 1].substring(0, 3)} ${day.day}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isToday ? scheme.primary : scheme.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        if (events.isNotEmpty)
                          Text(
                            '${events.length} event${events.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _openEventForm(defaultDate: day),
                          icon: Icon(
                            Icons.add,
                            size: 18,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (events.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 2),
                  child: Text(
                    'No events',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...events.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: GestureDetector(
                      onTap: () => _openEventForm(existing: e),
                      child: Row(
                        children: [
                          Icon(
                            e.category.icon,
                            size: 14,
                            color: e.category.color,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${e.start.format(context)} – ${e.title}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: scheme.onSurface,
                                decoration: e.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthGrid(ColorScheme scheme) {
    final firstOfMonth = DateTime(_anchor.year, _anchor.month, 1);
    final lastOfMonth = DateTime(_anchor.year, _anchor.month + 1, 0);
    final leadingBlanks = firstOfMonth.weekday - 1;
    final totalCells = leadingBlanks + lastOfMonth.day;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        Row(
          children: _weekdayShort
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        for (var r = 0; r < rows; r++)
          Row(
            children: List.generate(7, (c) {
              final cellIndex = r * 7 + c;
              final dayNum = cellIndex - leadingBlanks + 1;
              if (dayNum < 1 || dayNum > lastOfMonth.day) {
                return const Expanded(child: SizedBox(height: 78));
              }
              final day = DateTime(_anchor.year, _anchor.month, dayNum);
              final dayEvents = _eventsOn(day);
              final isToday = scheduleDateKey(day) == scheduleDateKey(_today);

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedDate = day;
                    _viewMode = 'day';
                  }),
                  child: Container(
                    height: 78,
                    margin: const EdgeInsets.all(2),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isToday
                          ? scheme.primary.withValues(alpha: 0.1)
                          : scheme.surfaceContainerHighest.withValues(
                              alpha: 0.3,
                            ),
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: scheme.primary, width: 1.2)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isToday ? scheme.primary : scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 3,
                          runSpacing: 3,
                          children: [
                            for (final e in dayEvents.take(3))
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: e.category.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (dayEvents.length > 3)
                              Text(
                                '+${dayEvents.length - 3}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildDayAgenda(ColorScheme scheme) {
    final weekDays = _weekDaysFor(_selectedDate);
    final dayEvents = _eventsOn(_selectedDate);
    final doneCount = dayEvents.where((e) => e.isDone).length;
    final progress = dayEvents.isEmpty ? 0.0 : doneCount / dayEvents.length;
    final isToday = _isSameDay(_selectedDate, _today);
    final tomorrow = _today.add(const Duration(days: 1));
    final tomorrowEvents = isToday
        ? _eventsOn(tomorrow)
        : const <ScheduleEvent>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 66,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: weekDays.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final day = weekDays[i];
              final selected = _isSameDay(day, _selectedDate);
              return GestureDetector(
                onTap: () => setState(() => _selectedDate = day),
                child: Container(
                  width: 56,
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.primary
                        : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _weekdayShort[day.weekday - 1],
                        style: TextStyle(
                          fontSize: 11,
                          color: selected
                              ? Colors.white70
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isToday ? 'Today' : _weekdayShort[_selectedDate.weekday - 1],
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: scheme.onSurface,
              ),
            ),
            Text(
              '$doneCount/${dayEvents.length} Completed',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: progress, minHeight: 5),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: dayEvents.isEmpty
              ? Center(
                  child: Text(
                    'Nothing scheduled for this day.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                )
              : ListView(
                  children: [
                    ...dayEvents.map((e) => _eventTile(scheme, e)),
                    if (tomorrowEvents.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tomorrow',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedDate = tomorrow),
                                  child: Text(
                                    '${_weekdayShort[tomorrow.weekday - 1]}, ${_monthNames[tomorrow.month - 1].substring(0, 3)} ${tomorrow.day} ›',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...tomorrowEvents
                                .take(2)
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          e.category.icon,
                                          size: 14,
                                          color: e.category.color,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${e.start.format(context)} – ${e.title}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _eventTile(ColorScheme scheme, ScheduleEvent e) {
    final status = _eventStatus(e);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 66,
              child: Text(
                '${e.start.format(context)}\n${e.end.format(context)}',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: GestureDetector(
                onTap: () => _toggleDone(e.id),
                child: Icon(
                  e.isDone ? Icons.check_circle : Icons.circle_outlined,
                  size: 18,
                  color: e.isDone
                      ? const Color(0xFF22C55E)
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => _openEventForm(existing: e),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: e.category.color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          e.category.icon,
                          size: 18,
                          color: e.category.color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                                decoration: e.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            if (e.subtitle.isNotEmpty)
                              Text(
                                e.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(
                            status,
                            scheme,
                          ).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _statusColor(status, scheme),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      scheduleDateKey(a) == scheduleDateKey(b);
}
