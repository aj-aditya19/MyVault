import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;

class StatisticshomeScreen extends StatefulWidget {
  const StatisticshomeScreen({super.key});

  @override
  State<StatisticshomeScreen> createState() => _StatisticshomeScreenState();
}

class _StatisticshomeScreenState extends State<StatisticshomeScreen> {
  late File _checkinFile;
  late encrypt.Key _key;
  late encrypt.Encrypter _encrypter;

  bool _loading = true;

  Map<String, dynamic> _allData = {};
  List<_StudyPoint> _points = [];

  late DateTime _currentWeekStart;

  @override
  void initState() {
    super.initState();

    _key = encrypt.Key.fromUtf8('my 32 length key................');

    _encrypter = encrypt.Encrypter(encrypt.AES(_key));

    _currentWeekStart = getStartOfWeek(DateTime.now());

    _initFile();
  }

  DateTime getStartOfWeek(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);

    int daysFromThursday = (cleanDate.weekday - DateTime.thursday + 7) % 7;

    return cleanDate.subtract(Duration(days: daysFromThursday));
  }

  DateTime getEndOfWeek(DateTime date) {
    return getStartOfWeek(date).add(const Duration(days: 6));
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

    _checkinFile = File('${dir.path}/daily_checkin.txt');

    if (!await _checkinFile.exists()) {
      await _checkinFile.create();

      await _checkinFile.writeAsString(_encryptData(jsonEncode({})));
    }

    await _loadStudyHours();
  }

  Future<void> _loadStudyHours() async {
    try {
      final content = await _checkinFile.readAsString();

      if (content.isEmpty) {
        setState(() {
          _points = getWeekPoints(_currentWeekStart, {});

          _loading = false;
        });

        return;
      }

      final decrypted = _decryptData(content);

      final decoded = jsonDecode(decrypted) as Map<String, dynamic>;

      print(decoded);
      _allData = decoded;

      setState(() {
        _points = getWeekPoints(_currentWeekStart, _allData);

        _loading = false;
      });
    } catch (e) {
      setState(() {
        _points = getWeekPoints(_currentWeekStart, {});

        _loading = false;
      });
    }
  }

  List<_StudyPoint> getWeekPoints(
    DateTime weekStart,
    Map<String, dynamic> allData,
  ) {
    List<_StudyPoint> weekPoints = [];

    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));

      final key = '${day.year}-${day.month}-${day.day}';

      double hours = 0;

      if (allData.containsKey(key)) {
        final data = allData[key];

        if (data is Map<String, dynamic>) {
          hours = (data['study_hours'] is num)
              ? (data['study_hours'] as num).toDouble()
              : double.tryParse(data['study_hours']?.toString() ?? '') ?? 0;
        }
      }

      weekPoints.add(
        _StudyPoint(rawDate: key, label: '${day.day}', hours: hours),
      );
    }

    return weekPoints;
  }

  String formatWeekRange() {
    final end = _currentWeekStart.add(const Duration(days: 6));

    return '${_currentWeekStart.day}/${_currentWeekStart.month}'
        ' - '
        '${end.day}/${end.month}';
  }

  void previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));

      _points = getWeekPoints(_currentWeekStart, _allData);
    });
  }

  void nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));

      _points = getWeekPoints(_currentWeekStart, _allData);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final maxHours = _points.isEmpty
        ? 0.0
        : _points.map((e) => e.hours).reduce(math.max);

    final chartMaxY = math.max(6.0, (maxHours + 1).ceilToDouble());
    final totalHours = _points.fold(0.0, (sum, item) => sum + item.hours);

    final bestDay = _points.isEmpty
        ? null
        : _points.reduce((a, b) => a.hours >= b.hours ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: previousWeek,
                      icon: const Icon(Icons.arrow_back_ios),
                    ),
                    Text(
                      formatWeekRange(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: nextWeek,
                      icon: const Icon(Icons.arrow_forward_ios),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: scheme.surface.withValues(alpha: 0.75),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Study Hours',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Thursday to Wednesday',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        height: 280,
                        child: _StudyLineChart(
                          points: _points,
                          maxY: chartMaxY,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Hours',
                        value: totalHours.toStringAsFixed(1),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _StatCard(
                        title: 'Best Day',
                        value: bestDay == null
                            ? 'No data'
                            : '${bestDay.label} (${bestDay.hours.toStringAsFixed(1)}h)',
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _StudyPoint {
  final String rawDate;
  final String label;
  final double hours;

  const _StudyPoint({
    required this.rawDate,
    required this.label,
    required this.hours,
  });
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surface.withValues(alpha: 0.74),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyLineChart extends StatelessWidget {
  final List<_StudyPoint> points;
  final double maxY;

  const _StudyLineChart({required this.points, required this.maxY});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return CustomPaint(
      painter: _StudyLineChartPainter(
        points: points,
        maxY: maxY,
        lineColor: scheme.primary,
        gridColor: scheme.outlineVariant.withValues(alpha: 0.3),
        fillColor: scheme.primary.withValues(alpha: 0.15),
        labelColor: scheme.onSurfaceVariant,
        axisColor: scheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _StudyLineChartPainter extends CustomPainter {
  final List<_StudyPoint> points;
  final double maxY;
  final Color lineColor;
  final Color gridColor;
  final Color fillColor;
  final Color labelColor;
  final Color axisColor;

  _StudyLineChartPainter({
    required this.points,
    required this.maxY,
    required this.lineColor,
    required this.gridColor,
    required this.fillColor,
    required this.labelColor,
    required this.axisColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 40.0;
    const rightPadding = 16.0;
    const topPadding = 20.0;
    const bottomPadding = 40.0;

    final chartWidth = size.width - leftPadding - rightPadding;

    final chartHeight = size.height - topPadding - bottomPadding;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= 4; i++) {
      final y = topPadding + chartHeight - (chartHeight / 4) * i;

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }

    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + chartHeight),
      axisPaint,
    );

    canvas.drawLine(
      Offset(leftPadding, topPadding + chartHeight),
      Offset(size.width - rightPadding, topPadding + chartHeight),
      axisPaint,
    );

    final stepX = chartWidth / (points.length - 1);

    final dots = <Offset>[];

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      final x = leftPadding + stepX * i;

      final normalized = (point.hours / maxY).clamp(0.0, 1.0);

      final y = topPadding + chartHeight - (chartHeight * normalized);

      dots.add(Offset(x, y));
    }

    final fillPath = Path()
      ..moveTo(dots.first.dx, topPadding + chartHeight)
      ..lineTo(dots.first.dx, dots.first.dy);

    for (final dot in dots.skip(1)) {
      fillPath.lineTo(dot.dx, dot.dy);
    }

    fillPath
      ..lineTo(dots.last.dx, topPadding + chartHeight)
      ..close();

    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(dots.first.dx, dots.first.dy);

    for (final dot in dots.skip(1)) {
      linePath.lineTo(dot.dx, dot.dy);
    }

    canvas.drawPath(linePath, linePaint);

    for (int i = 0; i < dots.length; i++) {
      final dot = dots[i];

      canvas.drawCircle(dot, 5, Paint()..color = Colors.white);

      canvas.drawCircle(dot, 3.5, Paint()..color = lineColor);

      textPainter.text = TextSpan(
        text: points[i].label,
        style: TextStyle(
          color: labelColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(dot.dx - textPainter.width / 2, topPadding + chartHeight + 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StudyLineChartPainter oldDelegate) {
    return true;
  }
}
