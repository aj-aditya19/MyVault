import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class Weeklyhistory extends StatefulWidget {
  const Weeklyhistory({super.key});

  @override
  State<Weeklyhistory> createState() => _WeeklyhistoryState();
}

class _WeeklyhistoryState extends State<Weeklyhistory> {
  Map<String, List<Map<String, dynamic>>> weeklyTasks = {};
  late File taskFile;
  late encrypt.Key key;
  late encrypt.Encrypter encrypter;

  @override
  void initState() {
    super.initState();
    key = encrypt.Key.fromUtf8('my 32 length key................');
    encrypter = encrypt.Encrypter(encrypt.AES(key));
    loadHistory();
  }

  String decrypt(String base64Data) {
    final combined = base64Decode(base64Data);
    final iv = encrypt.IV(combined.sublist(0, 16));
    final encryptedBytes = combined.sublist(16);
    final encrypted = encrypt.Encrypted(encryptedBytes);
    return encrypter.decrypt(encrypted, iv: iv);
  }

  Future<void> loadHistory() async {
    final dir = await getApplicationDocumentsDirectory();
    taskFile = File('${dir.path}/weekly_tasks.txt');

    if (!await taskFile.exists()) return;

    try {
      String content = await taskFile.readAsString();
      final decrypted = decrypt(content);
      final decoded = jsonDecode(decrypted);

      setState(() {
        weeklyTasks = (decoded as Map<String, dynamic>).map(
          (key, value) => MapEntry(
            key,
            (value as List)
                .map<Map<String, dynamic>>(
                  (e) => {"title": e["title"], "isDone": e["isDone"]},
                )
                .toList(),
          ),
        );
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  bool isWeekPassed(List<Map<String, dynamic>> tasks) {
    return tasks.every((task) => task["isDone"] == true);
  }

  String formatWeeklyDate(String input) {
    try {
      final regex = RegExp(r'Week-(\d+) \((\d+)\)');
      final match = regex.firstMatch(input);

      if (match == null) return input;

      final weekNumber = int.parse(match.group(1)!);
      final year = int.parse(match.group(2)!);

      final jan4 = DateTime(year, 1, 4);
      final startOfWeek1 = jan4.subtract(Duration(days: jan4.weekday - 1));

      final startDate = startOfWeek1.add(Duration(days: (weekNumber - 1) * 7));

      final endDate = startDate.add(const Duration(days: 6));

      const months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];

      String start = "${startDate.day} ${months[startDate.month - 1]}";
      String end = "${endDate.day} ${months[endDate.month - 1]}";

      return "Week $weekNumber, $start - $end";
    } catch (e) {
      return input;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = weeklyTasks.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    int total_weeks = weeklyTasks.length;
    int total_weeks_pass = weeklyTasks.values
        .where((tasks) => isWeekPassed(tasks))
        .length;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weekly Tasks History"),
        backgroundColor: const Color.fromARGB(255, 206, 203, 203),
      ),
      body: weeklyTasks.isEmpty
          ? const Center(child: Text("No history available"))
          : Column(
              children: [
                // stats
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Total Weeks: $total_weeks"),
                      SizedBox(width: 10),
                      Text("Total Weeks Pass: $total_weeks_pass"),
                      SizedBox(width: 10),
                      Text(
                        "Pass Rate: ${total_weeks > 0 ? ((total_weeks_pass / total_weeks) * 100).toStringAsFixed(2) : "0.00"}%",
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: weeklyTasks.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final week = entry.key;
                      final tasks = entry.value;
                      final pass = isWeekPassed(tasks);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatWeeklyDate(week),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  pass ? "PASS" : "FAIL",
                                  style: TextStyle(
                                    color: pass ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            ...tasks.map((task) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(task["title"])),
                                    Text(
                                      task["isDone"] ? "true" : "false",
                                      style: TextStyle(
                                        color: task["isDone"]
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
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
