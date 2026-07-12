// import 'dart:convert';
// import 'dart:io';

// import 'package:encrypt/encrypt.dart' as encrypt;
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';

// class ConstantGoalsScreen extends StatefulWidget {
//   const ConstantGoalsScreen({super.key});

//   @override
//   State<ConstantGoalsScreen> createState() => _ConstantGoalsScreenState();
// }

// class _ConstantGoalsScreenState extends State<ConstantGoalsScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final List<String> _goals = [];

//   late File _goalsFile;
//   late encrypt.Key _key;
//   late encrypt.Encrypter _encrypter;

//   @override
//   void initState() {
//     super.initState();
//     _key = encrypt.Key.fromUtf8('my 32 length key................');
//     _encrypter = encrypt.Encrypter(encrypt.AES(_key));
//     _initFile();
//   }

//   String _encryptData(String data) {
//     final iv = encrypt.IV.fromSecureRandom(16);
//     final encrypted = _encrypter.encrypt(data, iv: iv);
//     final combined = iv.bytes + encrypted.bytes;
//     return base64Encode(combined);
//   }

//   String _decryptData(String base64Data) {
//     final combined = base64Decode(base64Data);
//     final iv = encrypt.IV(combined.sublist(0, 16));
//     final encryptedBytes = combined.sublist(16);
//     final encrypted = encrypt.Encrypted(encryptedBytes);
//     return _encrypter.decrypt(encrypted, iv: iv);
//   }

//   Future<void> _initFile() async {
//     final dir = await getApplicationDocumentsDirectory();
//     _goalsFile = File('${dir.path}/constant_goals.txt');

//     if (!await _goalsFile.exists()) {
//       await _goalsFile.create();
//       await _goalsFile.writeAsString(_encryptData(jsonEncode(<String>[])));
//     }

//     await _loadGoals();
//   }

//   Future<void> _loadGoals() async {
//     try {
//       final content = await _goalsFile.readAsString();
//       if (content.isEmpty) return;

//       final decrypted = _decryptData(content);
//       final decoded = jsonDecode(decrypted);
//       if (decoded is List) {
//         setState(() {
//           _goals
//             ..clear()
//             ..addAll(decoded.map((e) => e.toString()));
//         });
//       }
//     } catch (_) {
//       try {
//         final fallback = await _goalsFile.readAsString();
//         final decoded = jsonDecode(fallback);
//         if (decoded is List) {
//           setState(() {
//             _goals
//               ..clear()
//               ..addAll(decoded.map((e) => e.toString()));
//           });
//           await _saveGoals();
//         }
//       } catch (_) {}
//     }
//   }

//   Future<void> _saveGoals() async {
//     await _goalsFile.writeAsString(_encryptData(jsonEncode(_goals)));
//   }

//   Future<void> _addGoal() async {
//     final text = _controller.text.trim();
//     if (text.isEmpty) return;

//     setState(() {
//       _goals.add(text);
//       _controller.clear();
//     });
//     await _saveGoals();
//   }

//   Future<void> _removeGoal(int index) async {
//     setState(() {
//       _goals.removeAt(index);
//     });
//     await _saveGoals();
//   }

//   Future<void> _editGoal(int index) async {
//     final editController = TextEditingController(text: _goals[index]);
//     await showDialog<void>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Edit Goal'),
//         content: TextField(
//           controller: editController,
//           decoration: const InputDecoration(hintText: 'Goal text'),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           FilledButton(
//             onPressed: () {
//               final text = editController.text.trim();
//               if (text.isNotEmpty) {
//                 setState(() {
//                   _goals[index] = text;
//                 });
//               }
//               Navigator.pop(context);
//             },
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//     await _saveGoals();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;

//     return Scaffold(
//       appBar: AppBar(title: const Text('Constant Goals')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               decoration: BoxDecoration(
//                 color: scheme.surfaceContainerHighest.withValues(alpha: 0.64),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: scheme.outlineVariant.withValues(alpha: 0.30),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _controller,
//                       decoration: const InputDecoration(
//                         border: InputBorder.none,
//                         hintText: 'Add a daily constant goal',
//                       ),
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: _addGoal,
//                     icon: const Icon(Icons.add_circle_rounded),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 12),
//             Align(
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 'These goals appear in your Daily Check-in.',
//                 style: TextStyle(color: scheme.onSurfaceVariant),
//               ),
//             ),
//             const SizedBox(height: 12),
//             Expanded(
//               child: _goals.isEmpty
//                   ? Center(
//                       child: Text(
//                         'No constant goals yet',
//                         style: TextStyle(color: scheme.onSurfaceVariant),
//                       ),
//                     )
//                   : ListView.builder(
//                       itemCount: _goals.length,
//                       itemBuilder: (context, index) {
//                         final goal = _goals[index];
//                         return Container(
//                           margin: const EdgeInsets.only(bottom: 10),
//                           decoration: BoxDecoration(
//                             color: scheme.surface.withValues(alpha: 0.70),
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(
//                               color: scheme.outlineVariant.withValues(
//                                 alpha: 0.24,
//                               ),
//                             ),
//                           ),
//                           child: ListTile(
//                             leading: const Icon(Icons.flag_outlined),
//                             title: Text(goal),
//                             trailing: Wrap(
//                               spacing: 0,
//                               children: [
//                                 IconButton(
//                                   onPressed: () => _editGoal(index),
//                                   icon: const Icon(Icons.edit_outlined),
//                                 ),
//                                 IconButton(
//                                   onPressed: () => _removeGoal(index),
//                                   icon: Icon(
//                                     Icons.delete_outline,
//                                     color: scheme.error,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// A single "constant goal" (daily habit) with a per-day completion map.
/// Key format for completion map: 'yyyy-MM-dd'.
class GoalEntry {
  GoalEntry({
    required this.id,
    required this.name,
    Map<String, bool>? completion,
  }) : completion = completion ?? {};

  final String id;
  String name;
  final Map<String, bool> completion;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'completion': completion,
  };

  factory GoalEntry.fromJson(Map<String, dynamic> json) {
    final rawCompletion = (json['completion'] as Map?) ?? {};
    return GoalEntry(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? '',
      completion: rawCompletion.map(
        (k, v) => MapEntry(k.toString(), v == true),
      ),
    );
  }
}

/// One day's wellness log: mood on a 1-5 scale + hours of sleep.
class WellnessDay {
  WellnessDay({this.mood, this.sleepHours});

  int? mood; // 1..5
  double? sleepHours;

  Map<String, dynamic> toJson() => {'mood': mood, 'sleep': sleepHours};

  factory WellnessDay.fromJson(Map<String, dynamic> json) => WellnessDay(
    mood: json['mood'] is int
        ? json['mood'] as int
        : (json['mood'] as num?)?.toInt(),
    sleepHours: (json['sleep'] as num?)?.toDouble(),
  );
}

class ConstantGoalsScreen extends StatefulWidget {
  const ConstantGoalsScreen({super.key});

  @override
  State<ConstantGoalsScreen> createState() => _ConstantGoalsScreenState();
}

class _ConstantGoalsScreenState extends State<ConstantGoalsScreen> {
  static const double _cellWidth = 34;
  static const double _cellHeight = 40;
  static const double _nameColWidth = 130;
  static const double _headerRowHeight = 26;
  static const double _chartHeight = 110;
  static const double _wellnessHeight = 120;
  static const double _maxSleepHours = 10;

  final TextEditingController _controller = TextEditingController();
  final List<GoalEntry> _goals = [];
  final Map<String, WellnessDay> _wellness = {};

  late File _goalsFile;
  late encrypt.Key _key;
  late encrypt.Encrypter _encrypter;

  DateTime _startDate = _startOfDay(DateTime.now());
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _key = encrypt.Key.fromUtf8('my 32 length key................');
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
    _initFile();
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const List<String> _dayLetters = [
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
    'Su',
  ];

  static String _dayLetter(DateTime d) => _dayLetters[d.weekday - 1];

  DateTime get _todayStart => _startOfDay(DateTime.now());

  /// Always shows at least 3 weeks (21 days) from the tracker's start date,
  /// and grows automatically once the user has been tracking longer than that.
  int get _totalWeeks {
    final daysSinceStart = _todayStart.difference(_startDate).inDays + 1;
    final weeksElapsed = (daysSinceStart / 7).ceil();
    return math.max(3, weeksElapsed);
  }

  List<DateTime> get _allDays =>
      List.generate(_totalWeeks * 7, (i) => _startDate.add(Duration(days: i)));

  List<List<DateTime>> get _weeks {
    final days = _allDays;
    final weeks = <List<DateTime>>[];
    for (var i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, math.min(i + 7, days.length)));
    }
    return weeks;
  }

  double _completionForDay(DateTime day) {
    if (_goals.isEmpty) return 0;
    final key = _dateKey(day);
    final done = _goals.where((g) => g.completion[key] == true).length;
    return done / _goals.length;
  }

  // ---------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------

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
    _goalsFile = File('${dir.path}/constant_goals.txt');

    if (!await _goalsFile.exists()) {
      await _goalsFile.create();
      await _goalsFile.writeAsString(
        _encryptData(
          jsonEncode({
            'startDate': _dateKey(_startDate),
            'goals': <dynamic>[],
            'wellness': <String, dynamic>{},
          }),
        ),
      );
    }

    await _loadData();
  }

  Future<void> _loadData() async {
    Map<String, dynamic>? decoded;
    try {
      final content = await _goalsFile.readAsString();
      if (content.isNotEmpty) {
        final decrypted = _decryptData(content);
        decoded = jsonDecode(decrypted) as Map<String, dynamic>;
      }
    } catch (_) {
      try {
        final fallback = await _goalsFile.readAsString();
        decoded = jsonDecode(fallback) as Map<String, dynamic>;
      } catch (_) {
        decoded = null;
      }
    }

    if (decoded != null) {
      final rawGoals = (decoded['goals'] as List?) ?? [];
      final rawWellness = (decoded['wellness'] as Map?) ?? {};
      final startDateStr = decoded['startDate']?.toString();

      setState(() {
        _goals
          ..clear()
          ..addAll(
            rawGoals.map((e) => GoalEntry.fromJson(e as Map<String, dynamic>)),
          );
        _wellness
          ..clear()
          ..addAll(
            rawWellness.map(
              (k, v) => MapEntry(
                k.toString(),
                WellnessDay.fromJson(v as Map<String, dynamic>),
              ),
            ),
          );
        if (startDateStr != null) {
          final parts = startDateStr.split('-');
          if (parts.length == 3) {
            _startDate = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          }
        }
        _loaded = true;
      });
      await _saveData();
    } else {
      setState(() => _loaded = true);
    }
  }

  Future<void> _saveData() async {
    final payload = {
      'startDate': _dateKey(_startDate),
      'goals': _goals.map((g) => g.toJson()).toList(),
      'wellness': _wellness.map((k, v) => MapEntry(k, v.toJson())),
    };
    await _goalsFile.writeAsString(_encryptData(jsonEncode(payload)));
  }

  // ---------------------------------------------------------------------
  // Goal actions
  // ---------------------------------------------------------------------

  Future<void> _addGoal() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _goals.add(
        GoalEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: text,
        ),
      );
      _controller.clear();
    });
    await _saveData();
  }

  Future<void> _removeGoal(int index) async {
    setState(() => _goals.removeAt(index));
    await _saveData();
  }

  Future<void> _editGoal(int index) async {
    final editController = TextEditingController(text: _goals[index].name);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Goal'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(hintText: 'Goal text'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = editController.text.trim();
              if (text.isNotEmpty) {
                setState(() => _goals[index].name = text);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    await _saveData();
  }

  Future<void> _toggleCompletion(int goalIndex, DateTime day) async {
    if (day.isAfter(_todayStart)) return; // can't complete future days
    final key = _dateKey(day);
    setState(() {
      final current = _goals[goalIndex].completion[key] ?? false;
      _goals[goalIndex].completion[key] = !current;
    });
    await _saveData();
  }

  // ---------------------------------------------------------------------
  // Wellness actions
  // ---------------------------------------------------------------------

  Future<void> _openWellnessDialog(DateTime day) async {
    if (day.isAfter(_todayStart)) return;
    final key = _dateKey(day);
    final existing = _wellness[key];
    int mood = existing?.mood ?? 3;
    final sleepController = TextEditingController(
      text: existing?.sleepHours?.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Wellness · ${day.day}/${day.month}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mood'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (i) {
                  final value = i + 1;
                  final emojis = ['😞', '🙁', '😐', '🙂', '😄'];
                  final selected = mood == value;
                  return GestureDetector(
                    onTap: () => setDialogState(() => mood = value),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: selected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.25)
                          : Colors.transparent,
                      child: Text(
                        emojis[i],
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sleepController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Hours of sleep',
                  suffixText: 'hrs',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final sleep = double.tryParse(sleepController.text.trim());
                setState(() {
                  _wellness[key] = WellnessDay(mood: mood, sleepHours: sleep);
                });
                _saveData();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Constant Goals'),
        actions: [
          IconButton(
            tooltip: "Log today's wellness",
            onPressed: () => _openWellnessDialog(_todayStart),
            icon: const Icon(Icons.mood_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddGoalInput(scheme),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'These goals appear in your Daily Check-in.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _goals.isEmpty
                  ? Center(
                      child: Text(
                        'No constant goals yet',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(context, 'Daily Progress'),
                          const SizedBox(height: 8),
                          _buildDailyProgressChart(scheme),
                          const SizedBox(height: 24),
                          _sectionTitle(context, 'Goals'),
                          const SizedBox(height: 8),
                          _buildWeeklyGrid(scheme),
                          const SizedBox(height: 24),
                          _sectionTitle(context, 'Overall wellness'),
                          const SizedBox(height: 8),
                          _buildWellnessSection(scheme),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
  );

  Widget _buildAddGoalInput(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Add a daily constant goal',
              ),
              onSubmitted: (_) => _addGoal(),
            ),
          ),
          IconButton(
            onPressed: _addGoal,
            icon: const Icon(Icons.add_circle_rounded),
          ),
        ],
      ),
    );
  }

  // --- Daily progress bar chart -----------------------------------------

  Widget _buildDailyProgressChart(ColorScheme scheme) {
    final days = _allDays;
    return SizedBox(
      height: _chartHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: days.map((day) {
            final pct = _completionForDay(day);
            final isToday = _dateKey(day) == _dateKey(_todayStart);
            final isFuture = day.isAfter(_todayStart);
            return Container(
              width: _cellWidth,
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (pct > 0)
                    Text(
                      '${(pct * 100).round()}',
                      style: TextStyle(
                        fontSize: 9,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: isFuture
                        ? 2
                        : math.max(2, (_chartHeight - 40) * pct),
                    decoration: BoxDecoration(
                      color: isFuture
                          ? scheme.outlineVariant.withValues(alpha: 0.3)
                          : (isToday
                                ? scheme.primary
                                : scheme.primary.withValues(alpha: 0.75)),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dayLetter(day),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- Weekly checkbox grid ---------------------------------------------

  Widget _buildWeeklyGrid(ColorScheme scheme) {
    final weeks = _weeks;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fixed left column: goal names
        SizedBox(
          width: _nameColWidth,
          child: Column(
            children: [
              SizedBox(height: _headerRowHeight * 2), // corner space
              for (var i = 0; i < _goals.length; i++)
                Container(
                  height: _cellHeight,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _goals[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      InkWell(
                        onTap: () => _editGoal(i),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _removeGoal(i),
                        child: Icon(Icons.close, size: 14, color: scheme.error),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Scrollable right side: week headers + day headers + checkbox grid
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Week label row
                Row(
                  children: weeks.asMap().entries.map((entry) {
                    final weekDays = entry.value;
                    return Container(
                      width: _cellWidth * weekDays.length,
                      height: _headerRowHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.25),
                        ),
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      child: Text(
                        'Week ${entry.key + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Day letter + date number row
                Row(
                  children: _allDays.map((day) {
                    final isToday = _dateKey(day) == _dateKey(_todayStart);
                    return Container(
                      width: _cellWidth,
                      height: _headerRowHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.2),
                        ),
                        color: isToday
                            ? scheme.primary.withValues(alpha: 0.12)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _dayLetter(day),
                            style: const TextStyle(fontSize: 9),
                          ),
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                // Checkbox rows, one per goal
                for (var g = 0; g < _goals.length; g++)
                  Row(
                    children: _allDays.map((day) {
                      final key = _dateKey(day);
                      final done = _goals[g].completion[key] == true;
                      final isFuture = day.isAfter(_todayStart);
                      return GestureDetector(
                        onTap: () => _toggleCompletion(g, day),
                        child: Container(
                          width: _cellWidth,
                          height: _cellHeight,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Icon(
                            done
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 18,
                            color: isFuture
                                ? scheme.outlineVariant.withValues(alpha: 0.4)
                                : (done
                                      ? scheme.primary
                                      : scheme.onSurfaceVariant.withValues(
                                          alpha: 0.5,
                                        )),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Overall wellness (mood + sleep) chart -----------------------------

  Widget _buildWellnessSection(ColorScheme scheme) {
    final days = _allDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _wellnessHeight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final key = _dateKey(day);
                final entry = _wellness[key];
                final isFuture = day.isAfter(_todayStart);
                final sleepHeight = entry?.sleepHours != null
                    ? math.min(1.0, entry!.sleepHours! / _maxSleepHours) *
                          (_wellnessHeight - 30)
                    : 0.0;
                final moodOffset = entry?.mood != null
                    ? (entry!.mood! / 5) * (_wellnessHeight - 30)
                    : 0.0;

                return GestureDetector(
                  onTap: () => _openWellnessDialog(day),
                  child: Container(
                    width: _cellWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Sleep hours bar
                        Container(
                          height: math.max(2, sleepHeight),
                          decoration: BoxDecoration(
                            color: isFuture
                                ? scheme.outlineVariant.withValues(alpha: 0.25)
                                : scheme.secondary.withValues(alpha: 0.55),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                        ),
                        // Mood dot
                        if (entry?.mood != null)
                          Padding(
                            padding: EdgeInsets.only(bottom: moodOffset),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: scheme.surface,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.circle, size: 8, color: Colors.green),
            const SizedBox(width: 4),
            const Text('Mood', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 16),
            Container(
              width: 14,
              height: 3,
              color: scheme.secondary.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 4),
            const Text('Hours of Sleep', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
