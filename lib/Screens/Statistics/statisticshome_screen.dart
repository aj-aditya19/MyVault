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

  List<_StudyPoint> _points = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _key = encrypt.Key.fromUtf8('my 32 length key................');
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
    _initFile();
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

  String _encryptData(String data) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(data, iv: iv);
    final combined = iv.bytes + encrypted.bytes;
    return base64Encode(combined);
  }

  Future<void> _loadStudyHours() async {
    final demoPoints = [
      _StudyPoint(rawDate: '2026-05-06', label: 'Mon', hours: 2.0),
      _StudyPoint(rawDate: '2026-05-07', label: 'Tue', hours: 3.5),
      _StudyPoint(rawDate: '2026-05-08', label: 'Wed', hours: 4.0),
      _StudyPoint(rawDate: '2026-05-09', label: 'Thu', hours: 2.75),
      _StudyPoint(rawDate: '2026-05-10', label: 'Fri', hours: 5.25),
      _StudyPoint(rawDate: '2026-05-11', label: 'Sat', hours: 3.0),
      _StudyPoint(rawDate: '2026-05-12', label: 'Sun', hours: 4.5),
    ];

    try {
      final content = await _checkinFile.readAsString();
      if (content.isEmpty) {
        setState(() {
          _points = demoPoints;
          _loading = false;
        });
        return;
      }

      final decrypted = _decryptData(content);
      final decoded = jsonDecode(decrypted);

      if (decoded is Map<String, dynamic>) {
        final points = decoded.entries
            .map((entry) {
              final data = entry.value;
              if (data is! Map<String, dynamic>) return null;

              final studyHours = (data['study_hours'] is num)
                  ? (data['study_hours'] as num).toDouble()
                  : double.tryParse(data['study_hours']?.toString() ?? '') ?? 0;

              return _StudyPoint(
                rawDate: entry.key,
                label: _formatLabel(entry.key),
                hours: studyHours,
              );
            })
            .whereType<_StudyPoint>()
            .toList();

        points.sort((a, b) => a.rawDate.compareTo(b.rawDate));

        setState(() {
          _points = points.isEmpty ? demoPoints : points;
          _loading = false;
        });
      } else {
        setState(() {
          _points = demoPoints;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _points = demoPoints;
        _loading = false;
      });
    }
  }

  String _formatLabel(String rawDate) {
    final parts = rawDate.split('-');
    if (parts.length != 3) return rawDate;
    final month = int.tryParse(parts[1]) ?? 0;
    final day = int.tryParse(parts[2]) ?? 0;

    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (month < 1 || month > 12) return rawDate;
    return '${monthNames[month - 1]} $day';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final maxHours = _points.isEmpty
        ? 0.0
        : _points.map((point) => point.hours).reduce(math.max);
    final chartMaxY = math.max(6.0, (maxHours + 1).ceilToDouble());

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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: scheme.surface.withValues(alpha: 0.74),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Study Hours Trend',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Day by day study time from your daily check-ins',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 18),
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
                        title: 'Days tracked',
                        value: _points.length.toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Best day',
                        value: _points.isEmpty
                            ? '-'
                            : _points
                                  .reduce((a, b) => a.hours >= b.hours ? a : b)
                                  .label,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatCard(
                  title: 'Quick Summary',
                  value: _points.isEmpty
                      ? 'No history yet'
                      : '${_points.map((e) => e.hours).reduce((a, b) => a + b).toStringAsFixed(1)} total study hours',
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 16,
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

    if (points.isEmpty) {
      return Center(
        child: Text(
          'No study data yet',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _StudyLineChartPainter(
            points: points,
            maxY: maxY,
            lineColor: scheme.primary,
            gridColor: scheme.outlineVariant.withValues(alpha: 0.30),
            fillColor: scheme.primary.withValues(alpha: 0.15),
            labelColor: scheme.onSurfaceVariant,
            axisColor: scheme.onSurfaceVariant.withValues(alpha: 0.55),
          ),
          child: const SizedBox.expand(),
        );
      },
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
    const leftPadding = 42.0;
    const rightPadding = 16.0;
    const topPadding = 18.0;
    const bottomPadding = 44.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    if (chartWidth <= 0 || chartHeight <= 0) return;

    final paint = Paint()..style = PaintingStyle.stroke;
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= 4; i++) {
      final y = topPadding + chartHeight - (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      final label = (maxY / 4 * i).toStringAsFixed(i == 0 ? 0 : 1);
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: labelColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, y - textPainter.height / 2));
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

    final stepX = points.length == 1 ? 0.0 : chartWidth / (points.length - 1);
    final dots = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final x = leftPadding + stepX * i;
      final normalized = (point.hours / maxY).clamp(0.0, 1.0);
      final y = topPadding + chartHeight - (chartHeight * normalized);
      dots.add(Offset(x, y));
    }

    final areaPath = Path()
      ..moveTo(dots.first.dx, topPadding + chartHeight)
      ..lineTo(dots.first.dx, dots.first.dy);
    for (final dot in dots.skip(1)) {
      areaPath.lineTo(dot.dx, dot.dy);
    }
    areaPath
      ..lineTo(dots.last.dx, topPadding + chartHeight)
      ..close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    final path = Path()..moveTo(dots.first.dx, dots.first.dy);
    for (final dot in dots.skip(1)) {
      path.lineTo(dot.dx, dot.dy);
    }

    paint
      ..color = lineColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);

    for (final dot in dots) {
      canvas.drawCircle(dot, 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(dot, 4.0, Paint()..color = lineColor);
    }

    final labelCount = points.length <= 4 ? points.length : 4;
    final labelStep = points.length == 1
        ? 1
        : (points.length - 1) / math.max(1, labelCount - 1);
    for (int i = 0; i < labelCount; i++) {
      final pointIndex = (i * labelStep).round().clamp(0, points.length - 1);
      final point = points[pointIndex];
      final dot = dots[pointIndex];

      textPainter.text = TextSpan(
        text: point.label,
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
    return oldDelegate.points != points || oldDelegate.maxY != maxY;
  }
}
