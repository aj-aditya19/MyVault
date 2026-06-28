import 'package:app/core/models/task_model.dart';
import 'package:app/core/services/storage_service.dart';
import 'package:flutter/material.dart';

class Dailyhistory extends StatefulWidget {
  const Dailyhistory({super.key});

  @override
  State<Dailyhistory> createState() => _DailyhistoryState();
}

class _DailyhistoryState extends State<Dailyhistory> {
  Map<String, List<TaskItem>> dailyTasks = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final raw = await StorageService.readMap('tasks');
    final parsed = <String, List<TaskItem>>{};

    raw.forEach((dayKey, value) {
      if (value is! List) return;
      parsed[dayKey] = value
          .whereType<Map>()
          .map((e) {
            final map = Map<String, dynamic>.from(e);
            return map.containsKey('id')
                ? TaskItem.fromJson(map)
                : TaskItem.fromLegacy(map, dayKey, dayKey + map['title'].toString());
          })
          .toList();
    });

    setState(() {
      dailyTasks = parsed;
      _loading = false;
    });
  }

  bool isPass(List<TaskItem> tasks) {
    if (tasks.isEmpty) return false;
    return tasks.every((task) => task.isDone);
  }

  String formatDate(String rawDate) {
    try {
      final parts = rawDate.split("-");
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      const months = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
      ];
      const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

      return "${date.day} ${months[date.month - 1]} ${date.year} ${days[date.weekday - 1]}";
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final entries = dailyTasks.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    int totalDays = entries.length;
    int totalDaysPass = entries.where((entry) => isPass(entry.value)).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Tasks History"),
        backgroundColor: Colors.transparent,
      ),
      body: entries.isEmpty
          ? const Center(child: Text("No history available"))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.28)),
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      Text("Total Days: $totalDays"),
                      Text("Passed: $totalDaysPass"),
                      Text(
                        "Pass Rate: ${totalDays > 0 ? ((totalDaysPass / totalDays) * 100).toStringAsFixed(2) : "0.00"}%",
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final date = entry.key;
                      final tasks = entry.value;
                      final pass = isPass(tasks);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.26)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatDate(date),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  pass ? "PASS" : "FAIL",
                                  style: TextStyle(
                                    color: pass ? Colors.green : scheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            ...tasks.map((task) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: task.priority.color,
                                      ),
                                    ),
                                    Expanded(child: Text(task.title)),
                                    Text(
                                      task.isDone ? "Done" : "Pending",
                                      style: TextStyle(
                                        color: task.isDone ? Colors.green : scheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
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
