import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:app/core/services/storage_service.dart';

DateTime? _parseDateKey(String? key) {
  if (key == null) return null;
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

String _formatDateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class GoalEntry {
  GoalEntry({
    required this.id,
    required this.name,
    required this.createdAt,
    Map<String, bool>? completion,
  }) : completion = completion ?? {};

  final String id;
  String name;
  final DateTime createdAt;
  final Map<String, bool> completion;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': _formatDateKey(createdAt),
    'completion': completion,
  };

  factory GoalEntry.fromJson(
    Map<String, dynamic> json, {
    DateTime? fallbackCreatedAt,
  }) {
    final rawCompletion = (json['completion'] as Map?) ?? {};
    final completion = rawCompletion.map<String, bool>(
      (k, v) => MapEntry(k.toString(), v == true),
    );

    DateTime? createdAt = _parseDateKey(json['createdAt']?.toString());

    if (createdAt == null && completion.isNotEmpty) {
      final earliestKey = (completion.keys.toList()..sort()).first;
      createdAt = _parseDateKey(earliestKey);
    }

    createdAt ??= fallbackCreatedAt ?? DateTime.now();
    createdAt = DateTime(createdAt.year, createdAt.month, createdAt.day);

    return GoalEntry(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? '',
      createdAt: createdAt,
      completion: completion,
    );
  }
}

class ConstantGoalsScreen extends StatefulWidget {
  const ConstantGoalsScreen({super.key});

  @override
  State<ConstantGoalsScreen> createState() => _ConstantGoalsScreenState();
}

class _ConstantGoalsScreenState extends State<ConstantGoalsScreen> {
  static const double _headerRowHeight = 34;
  static const double _cellHeight = 44;

  final TextEditingController _controller = TextEditingController();
  final List<GoalEntry> _goals = [];

  static const String _boxName = 'constant_goals';

  DateTime _monthCursor = _startOfMonth(DateTime.now());
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  double _cellWidthFor(double screenWidth) {
    if (screenWidth < 380) return 30;
    if (screenWidth < 600) return 34;
    if (screenWidth < 900) return 38;
    return 42;
  }

  double _nameColWidthFor(double screenWidth) {
    if (screenWidth < 380) return 96;
    if (screenWidth < 600) return 120;
    if (screenWidth < 900) return 150;
    return 180;
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
  static DateTime _endOfMonth(DateTime d) => DateTime(d.year, d.month + 1, 0);

  static String _dateKey(DateTime d) => _formatDateKey(d);

  static const List<String> _dayLetters = [
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
    'Su',
  ];

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

  static String _dayLetter(DateTime d) => _dayLetters[d.weekday - 1];

  DateTime get _todayStart => _startOfDay(DateTime.now());

  bool get _isCurrentMonth =>
      _monthCursor.year == _todayStart.year &&
      _monthCursor.month == _todayStart.month;

  String get _monthLabel =>
      '${_monthNames[_monthCursor.month - 1]} ${_monthCursor.year}';

  void _goToPreviousMonth() {
    setState(
      () =>
          _monthCursor = DateTime(_monthCursor.year, _monthCursor.month - 1, 1),
    );
  }

  void _goToNextMonth() {
    if (_isCurrentMonth) return;
    setState(
      () =>
          _monthCursor = DateTime(_monthCursor.year, _monthCursor.month + 1, 1),
    );
  }

  List<DateTime> get _allDays {
    final start = _startOfMonth(_monthCursor);
    final end = _endOfMonth(_monthCursor);
    final days = <DateTime>[];
    var d = start;
    while (!d.isAfter(end)) {
      days.add(d);
      d = d.add(const Duration(days: 1));
    }
    return days;
  }

  List<List<DateTime>> get _weeks {
    final days = _allDays;
    final weeks = <List<DateTime>>[];
    for (var i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, math.min(i + 7, days.length)));
    }
    return weeks;
  }

  bool _isTrackable(GoalEntry g, DateTime day) {
    final dayStart = _startOfDay(day);
    return !dayStart.isBefore(g.createdAt) && !dayStart.isAfter(_todayStart);
  }

  double? _completionForDay(DateTime day) {
    final trackable = _goals.where((g) => _isTrackable(g, day)).toList();
    if (trackable.isEmpty) return null;
    final key = _dateKey(day);
    final done = trackable.where((g) => g.completion[key] == true).length;
    return done / trackable.length;
  }

  double _goalCompletionRate(GoalEntry g) {
    final trackedDays = _todayStart.difference(g.createdAt).inDays + 1;
    if (trackedDays <= 0) return 0;
    final done = g.completion.entries.where((e) => e.value == true).length;
    return (done / trackedDays).clamp(0, 1);
  }

  double _weekAverage(int weekIndex) {
    final weeks = _weeks;
    if (weekIndex < 0 || weekIndex >= weeks.length) return 0;
    final values = weeks[weekIndex]
        .where((d) => !d.isAfter(_todayStart))
        .map(_completionForDay)
        .whereType<double>()
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  int get _currentWeekIndexInMonth =>
      ((_todayStart.day - 1) ~/ 7).clamp(0, math.max(0, _weeks.length - 1));

  double get _todayCompletionRate => _completionForDay(_todayStart) ?? 0;

  bool get _hasYesterday =>
      _completionForDay(_todayStart.subtract(const Duration(days: 1))) != null;

  double get _yesterdayCompletionRate =>
      _completionForDay(_todayStart.subtract(const Duration(days: 1))) ?? 0;

  double get _todayVsYesterdayDelta =>
      _todayCompletionRate - _yesterdayCompletionRate;

  double? _rollingAverage({required int offsetDays}) {
    final values = List.generate(
      7,
      (i) => _completionForDay(
        _todayStart.subtract(Duration(days: offsetDays + i)),
      ),
    ).whereType<double>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  bool get _hasPreviousWeek => _rollingAverage(offsetDays: 7) != null;

  double get _currentWeekAvg => _rollingAverage(offsetDays: 0) ?? 0;

  double get _previousWeekAvg => _rollingAverage(offsetDays: 7) ?? 0;

  double get _weekVsPreviousDelta => _currentWeekAvg - _previousWeekAvg;

  Future<void> _loadData() async {
    Map<String, dynamic> decoded = await StorageService.readMap(_boxName);

    if (decoded.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      final legacy = await StorageService.readLegacyPath(
        '${dir.path}/MyVault/constant_goals.txt',
      );
      if (legacy is Map && legacy.isNotEmpty) {
        decoded = Map<String, dynamic>.from(legacy);
      }
    }

    if (decoded.isNotEmpty) {
      final rawGoals = (decoded['goals'] as List?) ?? [];
      final legacyFallbackStart = _parseDateKey(
        decoded['startDate']?.toString(),
      );

      setState(() {
        _goals
          ..clear()
          ..addAll(
            rawGoals.map(
              (e) => GoalEntry.fromJson(
                Map<String, dynamic>.from(e as Map),
                fallbackCreatedAt: legacyFallbackStart,
              ),
            ),
          );
        _loaded = true;
      });
      await _saveData();
    } else {
      setState(() => _loaded = true);
    }
  }

  Future<void> _saveData() async {
    final payload = {'goals': _goals.map((g) => g.toJson()).toList()};
    await StorageService.write(_boxName, payload);
  }

  Future<void> _addGoal() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _goals.add(
        GoalEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: text,
          createdAt: _todayStart,
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
    final goal = _goals[goalIndex];
    if (!_isTrackable(goal, day)) return;
    final key = _dateKey(day);
    setState(() {
      final current = goal.completion[key] ?? false;
      goal.completion[key] = !current;
    });
    await _saveData();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final cellWidth = _cellWidthFor(screenWidth);
    final nameColWidth = _nameColWidthFor(screenWidth);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Constant Goals'),
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAddGoalInput(scheme),
              const SizedBox(height: 10),
              _buildInfoBanner(scheme),
              const SizedBox(height: 18),
              Expanded(
                child: _goals.isEmpty
                    ? _buildEmptyState(scheme)
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTacticsAndChartRow(scheme, screenWidth),
                            const SizedBox(height: 16),
                            _sectionCard(
                              scheme: scheme,
                              icon: Icons.checklist_rounded,
                              title: 'Goals',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildMonthHeader(scheme),
                                  const SizedBox(height: 8),
                                  _buildWeeklyGrid(
                                    scheme,
                                    cellWidth,
                                    nameColWidth,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner(ColorScheme scheme) {
    return Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 14,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'These goals appear in your Daily Check-in.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flag_circle_outlined,
            size: 48,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No constant goals yet',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Add one above to start tracking it daily',
            style: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required ColorScheme scheme,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildAddGoalInput(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(
              Icons.flag_outlined,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: scheme.onSurface),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Add a daily constant goal',
                hintStyle: TextStyle(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _addGoal(),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _addGoal,
              icon: Icon(Icons.add_rounded, color: scheme.onPrimary),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticsAndChartRow(ColorScheme scheme, double screenWidth) {
    final tactics = _buildTacticsCard(scheme);
    final chart = _buildWeekChartCard(scheme);

    if (screenWidth < 500) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [tactics, const SizedBox(height: 12), chart],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: tactics),
        const SizedBox(width: 12),
        Expanded(flex: 6, child: chart),
      ],
    );
  }

  Widget _buildTacticsCard(ColorScheme scheme) {
    final todayPct = (_todayCompletionRate * 100).round();
    final dayDeltaPct = _hasYesterday
        ? (_todayVsYesterdayDelta * 100).round()
        : null;
    final weekDeltaPct = _hasPreviousWeek
        ? (_weekVsPreviousDelta * 100).round()
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Tactics',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$todayPct%',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            ),
          ),
          Text(
            'completed today',
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          _deltaRow(scheme, label: 'vs yesterday', deltaPct: dayDeltaPct),
          const SizedBox(height: 8),
          _deltaRow(scheme, label: 'vs last week', deltaPct: weekDeltaPct),
        ],
      ),
    );
  }

  Widget _deltaRow(
    ColorScheme scheme, {
    required String label,
    required int? deltaPct,
  }) {
    final isNA = deltaPct == null;
    final isUp = !isNA && deltaPct > 0;
    final isDown = !isNA && deltaPct < 0;

    final color = isNA
        ? scheme.onSurfaceVariant
        : (isUp
              ? Colors.green.shade600
              : (isDown ? Colors.redAccent.shade200 : scheme.onSurfaceVariant));

    final icon = isNA
        ? Icons.remove_rounded
        : (isUp
              ? Icons.arrow_upward_rounded
              : (isDown ? Icons.arrow_downward_rounded : Icons.remove_rounded));

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          isNA ? '—' : '${deltaPct.abs()}%',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekChartCard(ColorScheme scheme) {
    const chartHeight = 130.0;
    final barAreaHeight = chartHeight - 46;
    final totalWeeksInMonth = _weeks.length;
    final weeksToShow = _isCurrentMonth
        ? (_currentWeekIndexInMonth + 1).clamp(1, totalWeeksInMonth)
        : totalWeeksInMonth;
    final highlightWeekIndex = _isCurrentMonth ? _currentWeekIndexInMonth : -1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Weekly Progress',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: chartHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(weeksToShow, (i) {
                final avg = _weekAverage(i);
                final isCurrent = i == highlightWeekIndex;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${(avg * 100).round()}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          width: 30,
                          height: barAreaHeight,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        Container(
                          width: 30,
                          height: math.max(
                            avg > 0 ? 6 : 0,
                            barAreaHeight * avg,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? scheme.primary
                                : scheme.primary.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'W${i + 1}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isCurrent
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: isCurrent
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _goToPreviousMonth,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.chevron_left_rounded,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          _monthLabel,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _isCurrentMonth ? null : _goToNextMonth,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.chevron_right_rounded,
              color: _isCurrentMonth
                  ? scheme.onSurfaceVariant.withValues(alpha: 0.3)
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyGrid(
    ColorScheme scheme,
    double cellWidth,
    double nameColWidth,
  ) {
    final weeks = _weeks;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: nameColWidth,
          child: Column(
            children: [
              SizedBox(height: _headerRowHeight * 2),
              for (var i = 0; i < _goals.length; i++)
                Container(
                  height: _cellHeight,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  color: i.isEven
                      ? Colors.transparent
                      : scheme.surfaceContainerHigh.withValues(alpha: 0.4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _goals[i].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                            Text(
                              '${(_goalCompletionRate(_goals[i]) * 100).round()}% · since ${_goals[i].createdAt.day}/${_goals[i].createdAt.month}',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _editGoal(i),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _removeGoal(i),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: scheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: weeks.asMap().entries.map((entry) {
                    final weekDays = entry.value;
                    return Container(
                      width: cellWidth * weekDays.length,
                      height: _headerRowHeight,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Week ${entry.key + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                Row(
                  children: _allDays.map((day) {
                    final isToday = _dateKey(day) == _dateKey(_todayStart);
                    return Container(
                      width: cellWidth,
                      height: _headerRowHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isToday
                            ? scheme.primary.withValues(alpha: 0.14)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: isToday
                            ? Border.all(
                                color: scheme.primary.withValues(alpha: 0.6),
                              )
                            : null,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _dayLetter(day),
                              style: TextStyle(
                                fontSize: 9,
                                color: isToday
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                                fontWeight: isToday
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: isToday
                                    ? FontWeight.w800
                                    : FontWeight.normal,
                                color: isToday
                                    ? scheme.primary
                                    : scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                for (var g = 0; g < _goals.length; g++)
                  Row(
                    children: _allDays.map((day) {
                      final goal = _goals[g];
                      final key = _dateKey(day);
                      final done = goal.completion[key] == true;
                      final dayStart = _startOfDay(day);
                      final isFuture = dayStart.isAfter(_todayStart);
                      final isBeforeCreated = dayStart.isBefore(goal.createdAt);
                      final isDisabled = isFuture || isBeforeCreated;
                      final isToday = _dateKey(day) == _dateKey(_todayStart);

                      return Container(
                        width: cellWidth,
                        height: _cellHeight,
                        color: g.isEven
                            ? Colors.transparent
                            : scheme.surfaceContainerHigh.withValues(
                                alpha: 0.4,
                              ),
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: isDisabled
                              ? null
                              : () => _toggleCompletion(g, day),
                          child: Container(
                            width: cellWidth - 10,
                            height: cellWidth - 10,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              color: done
                                  ? scheme.primary
                                  : (isBeforeCreated
                                        ? scheme.surfaceContainerHighest
                                              .withValues(alpha: 0.22)
                                        : (isFuture
                                              ? scheme.surfaceContainerHighest
                                                    .withValues(alpha: 0.5)
                                              : scheme
                                                    .surfaceContainerHighest)),
                              border: Border.all(
                                color: isToday
                                    ? scheme.primary.withValues(alpha: 0.7)
                                    : scheme.outlineVariant.withValues(
                                        alpha: isBeforeCreated ? 0.15 : 0.4,
                                      ),
                                width: isToday ? 1.4 : 1,
                              ),
                            ),
                            child: done
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 15,
                                    color: scheme.onPrimary,
                                  )
                                : (isBeforeCreated
                                      ? Icon(
                                          Icons.remove_rounded,
                                          size: 12,
                                          color: scheme.onSurfaceVariant
                                              .withValues(alpha: 0.35),
                                        )
                                      : null),
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
}
