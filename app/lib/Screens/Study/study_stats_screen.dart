import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:app/core/models/study_session_model.dart';
import 'package:app/core/services/storage_service.dart';
import 'package:app/core/utils/responsive.dart';
import 'package:app/core/widgets/common_widgets.dart';

class StudyStatsScreen extends StatefulWidget {
  const StudyStatsScreen({super.key});

  @override
  State<StudyStatsScreen> createState() => _StudyStatsScreenState();
}

class _StudyStatsScreenState extends State<StudyStatsScreen> {
  bool _loading = true;
  List<StudySession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await StorageService.readList('study_sessions');
    setState(() {
      _sessions = raw.map(StudySession.fromJson).toList();
      _loading = false;
    });
  }

  double _hoursOn(DateTime day) {
    final minutes = _sessions
        .where(
          (s) =>
              s.date.year == day.year &&
              s.date.month == day.month &&
              s.date.day == day.day,
        )
        .fold<int>(0, (sum, s) => sum + s.durationMinutes);
    return minutes / 60.0;
  }

  double _minutesOn(DateTime day) => _hoursOn(day) * 60;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String formatHours(double hours) {
      final h = hours.floor();
      final m = ((hours - h) * 60).round();
      if (m == 0) {
        return "$h hr";
      }
      return "$h hr $m min";
    }

    final todayHours = _hoursOn(today);
    final weekHours = List.generate(
      7,
      (i) => _hoursOn(today.subtract(Duration(days: i))),
    ).fold<double>(0, (a, b) => a + b);
    final monthHours =
        _sessions
            .where((s) => s.date.year == now.year && s.date.month == now.month)
            .fold<int>(0, (sum, s) => sum + s.durationMinutes) /
        60.0;

    // last 7 days, oldest -> newest, for the line chart
    final last7Days = List.generate(
      7,
      (i) => today.subtract(Duration(days: 6 - i)),
    );
    final spots = List.generate(
      last7Days.length,
      (i) => FlSpot(i.toDouble(), _hoursOn(last7Days[i])),
    );
    final maxY = spots.fold<double>(1, (m, s) => s.y > m ? s.y : m) + 0.5;
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // subject-wise breakdown, all time
    final subjectTotals = <String, int>{};
    for (final s in _sessions) {
      subjectTotals[s.subject] =
          (subjectTotals[s.subject] ?? 0) + s.durationMinutes;
    }
    final sortedSubjects = subjectTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxSubjectMinutes = sortedSubjects.isEmpty
        ? 1
        : sortedSubjects.first.value;

    // heatmap: last 70 days
    final heatmapDays = List.generate(
      70,
      (i) => today.subtract(Duration(days: 69 - i)),
    );

    if (_sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Log a few study sessions to see your stats and trends here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return ResponsiveContent(
      child: ListView(
        padding: const EdgeInsets.all(4),
        children: [
          GridView.count(
            crossAxisCount: Responsive.gridColumns(context),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.25,
            children: [
              StatCard(
                icon: Icons.today_rounded,
                value: '${todayHours.toStringAsFixed(1)}h',
                label: 'Today',
                color: Colors.blue,
              ),
              StatCard(
                icon: Icons.calendar_view_week_rounded,
                value: '${weekHours.toStringAsFixed(1)}h',
                label: 'Last 7 days',
                color: Colors.purple,
              ),
              StatCard(
                icon: Icons.calendar_month_rounded,
                value: '${monthHours.toStringAsFixed(1)}h',
                label: 'This month',
                color: Colors.teal,
              ),
              StatCard(
                icon: Icons.menu_book_rounded,
                value: '${sortedSubjects.length}',
                label: 'Subjects tracked',
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionHeading(
            title: 'Weekly Trend',
            subtitle: 'Hours studied per day, last 7 days',
          ),
          const SizedBox(height: 10),
          Container(
            height: 200,
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,

                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          formatHours(spot.y),
                          TextStyle(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),

                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: scheme.outlineVariant.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= dayLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            " ${dayLabels[last7Days[idx].weekday - 1]}",
                            style: TextStyle(
                              fontSize: 10,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: scheme.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: scheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeading(
            title: 'Productivity Heatmap',
            subtitle: 'Last 70 days',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: heatmapDays.map((day) {
                final minutes = _minutesOn(day);
                final color = minutes <= 0
                    ? scheme.surfaceContainerHighest
                    : minutes < 30
                    ? scheme.primary.withValues(alpha: 0.25)
                    : minutes < 60
                    ? scheme.primary.withValues(alpha: 0.45)
                    : minutes < 120
                    ? scheme.primary.withValues(alpha: 0.7)
                    : scheme.primary;
                return Tooltip(
                  message: '${day.day}/${day.month}: ${minutes.toInt()} min',
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SectionHeading(title: 'Subject-wise breakdown'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: sortedSubjects.map((entry) {
                final fraction = entry.value / maxSubjectMinutes;
                final hours = entry.value / 60.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${formatHours(hours)}',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: fraction.clamp(0.02, 1.0),
                          minHeight: 8,
                          backgroundColor: scheme.surfaceContainerHighest,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
