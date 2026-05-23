import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ScheduleHomepage extends StatefulWidget {
  const ScheduleHomepage({super.key});

  @override
  State<ScheduleHomepage> createState() => _ScheduleHomepageState();
}

class _ScheduleHomepageState extends State<ScheduleHomepage> {
  static const List<String> _weekDays = [
    'Thurs',
    'Fri',
    'Sat',
    'Sun',
    'Mon',
    'Tues',
    'Wed',
  ];

  static const int _startMinute = 4 * 60;
  static const int _endMinute = 22 * 60;
  static const int _slotMinutes = 20;
  static const double _pixelsPerMinute = 2;
  static const double _dayLabelWidth = 100;
  static const double _laneHeight = 72;

  final Map<String, List<_ScheduleEntry>> _tasksByDay = {
    for (final day in _weekDays) day: [],
  };

  late final encrypt.Key _key;
  late final encrypt.Encrypter _encrypter;
  late File _scheduleFile;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _startController = TextEditingController(
    text: '04:00',
  );
  final TextEditingController _durationController = TextEditingController(
    text: '60',
  );

  String _selectedDay = _weekDays.first;
  String? _editingTaskId;
  bool _isDone = false;

  int get _gridMinuteSpan => _endMinute - _startMinute;
  double get _gridWidth => _gridMinuteSpan * _pixelsPerMinute;
  int get _slotCount => _gridMinuteSpan ~/ _slotMinutes;

  @override
  void initState() {
    super.initState();
    _key = encrypt.Key.fromUtf8('my 32 length key................');
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
    _selectedDay = _dayNameForDate(DateTime.now());
    _initFile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  String _encryptData(String data) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(data, iv: iv);
    final combined = iv.bytes + encrypted.bytes;
    return base64Encode(combined);
  }

  String _decryptData(String base64Data) {
    final combined = base64Decode(base64Data);
    final iv = encrypt.IV(combined.sublist(0, 16));
    final encryptedBytes = combined.sublist(16);
    final encrypted = encrypt.Encrypted(encryptedBytes);
    return _encrypter.decrypt(encrypted, iv: iv);
  }

  Future<void> _initFile() async {
    final dir = await getApplicationDocumentsDirectory();
    _scheduleFile = File('${dir.path}/weekly_schedule.txt');

    if (!await _scheduleFile.exists()) {
      await _scheduleFile.create();
      await _scheduleFile.writeAsString(_encryptData(jsonEncode({})));
    }

    await _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      final content = await _scheduleFile.readAsString();
      if (content.isEmpty) return;

      Map<String, dynamic> decoded;

      try {
        decoded = jsonDecode(_decryptData(content)) as Map<String, dynamic>;
      } catch (_) {
        decoded = jsonDecode(content) as Map<String, dynamic>;
        await _scheduleFile.writeAsString(_encryptData(jsonEncode(decoded)));
      }

      for (final day in _weekDays) {
        final rawItems = decoded[day];
        if (rawItems is List) {
          _tasksByDay[day] = rawItems
              .map(
                (item) => _ScheduleEntry.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _saveSchedule() async {
    final payload = <String, dynamic>{
      for (final day in _weekDays)
        day: _tasksByDay[day]!.map((entry) => entry.toJson()).toList(),
    };

    await _scheduleFile.writeAsString(_encryptData(jsonEncode(payload)));
  }

  String _dayNameForDate(DateTime date) {
    switch (date.weekday) {
      case DateTime.thursday:
        return 'Thurs';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tues';
      default:
        return 'Wed';
    }
  }

  int _weekdayForName(String name) {
    switch (name) {
      case 'Thurs':
        return DateTime.thursday;
      case 'Fri':
        return DateTime.friday;
      case 'Sat':
        return DateTime.saturday;
      case 'Sun':
        return DateTime.sunday;
      case 'Mon':
        return DateTime.monday;
      case 'Tues':
        return DateTime.tuesday;
      default:
        return DateTime.wednesday;
    }
  }

  DateTime _dateForDayName(String name) {
    final today = DateTime.now();
    final targetWeekday = _weekdayForName(name);
    var delta = targetWeekday - today.weekday;
    if (delta < 0) delta += 7;
    final date = DateTime(
      today.year,
      today.month,
      today.day,
    ).add(Duration(days: delta));
    return date;
  }

  String _formatDayShortDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m';
  }

  int _parseTimeToMinute(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) {
      return _startMinute;
    }

    final hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final minute = int.tryParse(match.group(2) ?? '') ?? 0;
    return (hour * 60) + minute;
  }

  String _formatMinute(int minuteOfDay) {
    final hour = (minuteOfDay ~/ 60) % 24;
    final minute = minuteOfDay % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final minuteText = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteText $period';
  }

  String _formatTimeForInput(int minuteOfDay) {
    final hour = (minuteOfDay ~/ 60) % 24;
    final minute = minuteOfDay % 60;
    final hourText = hour.toString().padLeft(2, '0');
    final minuteText = minute.toString().padLeft(2, '0');
    return '$hourText:$minuteText';
  }

  String _formatCompactTime(int minuteOfDay) {
    final hour = (minuteOfDay ~/ 60) % 24;
    final minute = minuteOfDay % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    if (minute == 0) {
      return '$hour12 $period';
    }
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatHourLabel(int minuteOfDay) {
    final hour = (minuteOfDay ~/ 60) % 24;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12 $period';
  }

  int _snapToSlot(int minuteOfDay) {
    final raw = ((minuteOfDay - _startMinute) / _slotMinutes).round();
    final snapped = _startMinute + (raw * _slotMinutes);
    return snapped.clamp(_startMinute, _endMinute - _slotMinutes).toInt();
  }

  int _clampDuration(int durationMinutes) {
    final snapped = ((durationMinutes / _slotMinutes).round() * _slotMinutes)
        .clamp(_slotMinutes, _gridMinuteSpan);
    return snapped.toInt();
  }

  List<_ScheduleEntry> _tasksForDay(String day) {
    final tasks = List<_ScheduleEntry>.from(_tasksByDay[day] ?? []);
    tasks.sort((a, b) => a.startMinute.compareTo(b.startMinute));
    return tasks;
  }

  int _laneCount(List<_ScheduleEntry> tasks) {
    final laneEnds = <int>[];
    final sorted = List<_ScheduleEntry>.from(tasks)
      ..sort((a, b) => a.startMinute.compareTo(b.startMinute));

    for (final task in sorted) {
      var laneIndex = 0;
      while (laneIndex < laneEnds.length &&
          task.startMinute < laneEnds[laneIndex]) {
        laneIndex++;
      }

      if (laneIndex == laneEnds.length) {
        laneEnds.add(task.endMinute);
      } else {
        laneEnds[laneIndex] = task.endMinute;
      }
    }

    return laneEnds.isEmpty ? 1 : laneEnds.length;
  }

  Future<void> _toggleTaskDone(String day, String id) async {
    final tasks = _tasksByDay[day] ?? [];
    final index = tasks.indexWhere((entry) => entry.id == id);
    if (index == -1) {
      return;
    }

    setState(() {
      tasks[index] = tasks[index].copyWith(isDone: !tasks[index].isDone);
    });
    await _saveSchedule();
  }

  Future<void> _deleteTask(String day, String id) async {
    final tasks = _tasksByDay[day] ?? [];
    tasks.removeWhere((entry) => entry.id == id);
    setState(() {});
    await _saveSchedule();
  }

  Future<void> _saveTask({String? day}) async {
    final targetDay = day ?? _selectedDay;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }

    final startMinute = _snapToSlot(_parseTimeToMinute(_startController.text));
    final durationMinutes = _clampDuration(
      int.tryParse(_durationController.text.trim()) ?? _slotMinutes,
    );

    final entry = _ScheduleEntry(
      id: _editingTaskId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      startMinute: startMinute,
      durationMinutes: durationMinutes,
      isDone: _isDone,
    );

    setState(() {
      final tasks = _tasksByDay[targetDay] ?? [];
      if (_editingTaskId == null) {
        tasks.add(entry);
      } else {
        final index = tasks.indexWhere((item) => item.id == _editingTaskId);
        if (index == -1) {
          tasks.add(entry);
        } else {
          tasks[index] = entry;
        }
      }

      _tasksByDay[targetDay] = tasks;
      _selectedDay = targetDay;
      _editingTaskId = null;
      _isDone = false;
    });

    await _saveSchedule();
  }

  void _openTaskDialog({String? day, _ScheduleEntry? existing}) {
    final targetDay = day ?? _selectedDay;
    var dialogDay = targetDay;

    if (existing == null) {
      _editingTaskId = null;
      _titleController.text = '';
      _startController.text = '04:00';
      _durationController.text = '60';
      _isDone = false;
    } else {
      _editingTaskId = existing.id;
      _titleController.text = existing.title;
      _startController.text = _formatTimeForInput(existing.startMinute);
      _durationController.text = existing.durationMinutes.toString();
      _isDone = existing.isDone;
      dialogDay = existing != null ? day ?? _selectedDay : dialogDay;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: scheme.surface,
              surfaceTintColor: scheme.surfaceTint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                existing == null ? 'Add Schedule Box' : 'Edit Schedule Box',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: dialogDay,
                      items: _weekDays
                          .map(
                            (dayName) => DropdownMenuItem(
                              value: dayName,
                              child: Text(dayName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          dialogDay = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Day'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Task'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _startController,
                            decoration: const InputDecoration(
                              labelText: 'Start (HH:MM)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Minutes',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isDone,
                      onChanged: (value) {
                        setDialogState(() {
                          _isDone = value ?? false;
                        });
                      },
                      title: const Text('Completed'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              actions: [
                if (existing != null)
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      await _deleteTask(dialogDay, existing.id);
                    },
                    child: const Text('Delete'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await _saveTask(day: dialogDay);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    final headerSlots = <Widget>[
      Container(
        width: _dayLabelWidth,
        height: 54,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
          border: Border(
            right: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.3),
            ),
            bottom: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: const Text(
          'Day / Time',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      SizedBox(
        width: _gridWidth,
        height: 54,
        child: Row(
          children: List.generate(_slotCount, (index) {
            final minute = _startMinute + (index * _slotMinutes);
            final isHourMark = minute % 60 == 0;

            return Container(
              width: _slotMinutes * _pixelsPerMinute,
              height: 54,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
                border: Border(
                  left: BorderSide(
                    color: isHourMark
                        ? scheme.outlineVariant.withValues(alpha: 0.45)
                        : Colors.transparent,
                    width: isHourMark ? 1.0 : 0.0,
                  ),
                  right: BorderSide(color: Colors.transparent),
                  bottom: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: isHourMark
                  ? Text(
                      _formatHourLabel(minute),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  : const SizedBox.shrink(),
            );
          }),
        ),
      ),
    ];

    // add small gap between day label and grid so hour label isn't flush
    return Row(
      children: [headerSlots[0], const SizedBox(width: 8), headerSlots[1]],
    );
  }

  Widget _buildDayRow(String day, ColorScheme scheme) {
    final tasks = _tasksForDay(day);
    final laneCount = _laneCount(tasks);
    final rowHeight = (laneCount * _laneHeight) + 12;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _dayLabelWidth,
          height: rowHeight,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
            border: Border(
              right: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
              bottom: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                day,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatDayShortDate(_dateForDayName(day)),
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: _gridWidth,
          height: rowHeight,
          child: Stack(
            children: [
              Row(
                children: List.generate(_slotCount, (index) {
                  final minute = _startMinute + (index * _slotMinutes);
                  final isHourMark = minute % 60 == 0;

                  return Container(
                    width: _slotMinutes * _pixelsPerMinute,
                    height: rowHeight,
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.22),
                      border: Border(
                        left: BorderSide(
                          color: isHourMark
                              ? scheme.outlineVariant.withValues(alpha: 0.40)
                              : Colors.transparent,
                          width: isHourMark ? 1.0 : 0.0,
                        ),
                        right: BorderSide(color: Colors.transparent),
                        bottom: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              ...tasks.asMap().entries.map((entry) {
                final task = entry.value;
                final laneIndex = _laneIndexForTask(tasks, task);
                final left =
                    (task.startMinute - _startMinute) * _pixelsPerMinute;
                final width = task.durationMinutes * _pixelsPerMinute;
                final top = 6 + (laneIndex * _laneHeight);

                return Positioned(
                  left: left,
                  top: top,
                  width: width,
                  height: _laneHeight - 10,
                  child: GestureDetector(
                    onTap: () => _openTaskDialog(day: day, existing: task),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: task.isDone
                            ? Colors.green.withValues(alpha: 0.22)
                            : scheme.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: task.isDone
                              ? Colors.green.withValues(alpha: 0.55)
                              : scheme.primary.withValues(alpha: 0.35),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 6,
                            offset: Offset(0, 2),
                            color: Colors.black12,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  task.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: task.isDone
                                        ? Colors.green.shade900
                                        : scheme.onSurface,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _toggleTaskDone(day, task.id),
                                child: Icon(
                                  task.isDone
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 16,
                                  color: task.isDone
                                      ? Colors.green
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            '${_formatMinute(task.startMinute)} - ${_formatMinute(task.endMinute)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  int _laneIndexForTask(List<_ScheduleEntry> tasks, _ScheduleEntry target) {
    final laneEnds = <int>[];
    final sorted = List<_ScheduleEntry>.from(tasks)
      ..sort((a, b) => a.startMinute.compareTo(b.startMinute));

    for (final task in sorted) {
      var laneIndex = 0;
      while (laneIndex < laneEnds.length &&
          task.startMinute < laneEnds[laneIndex]) {
        laneIndex++;
      }

      if (laneIndex == laneEnds.length) {
        laneEnds.add(task.endMinute);
      } else {
        laneEnds[laneIndex] = task.endMinute;
      }

      if (task.id == target.id) {
        return laneIndex;
      }
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Schedule'),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskDialog(day: _selectedDay),
        icon: const Icon(Icons.add),
        label: const Text('Add Box'),
      ),
      body: Column(
        children: [
          // header notes removed to keep UI simple
          const SizedBox.shrink(),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  children: [
                    _buildHeader(scheme),
                    ..._weekDays.map((day) => _buildDayRow(day, scheme)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleEntry {
  final String id;
  final String title;
  final int startMinute;
  final int durationMinutes;
  final bool isDone;

  const _ScheduleEntry({
    required this.id,
    required this.title,
    required this.startMinute,
    required this.durationMinutes,
    required this.isDone,
  });

  int get endMinute => startMinute + durationMinutes;

  _ScheduleEntry copyWith({
    String? id,
    String? title,
    int? startMinute,
    int? durationMinutes,
    bool? isDone,
  }) {
    return _ScheduleEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      startMinute: startMinute ?? this.startMinute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'startMinute': startMinute,
    'durationMinutes': durationMinutes,
    'isDone': isDone,
  };

  factory _ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return _ScheduleEntry(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? '',
      startMinute: (json['startMinute'] ?? 4 * 60) is int
          ? json['startMinute'] as int
          : int.tryParse(json['startMinute'].toString()) ?? 4 * 60,
      durationMinutes: (json['durationMinutes'] ?? 60) is int
          ? json['durationMinutes'] as int
          : int.tryParse(json['durationMinutes'].toString()) ?? 60,
      isDone: json['isDone'] == true,
    );
  }
}
