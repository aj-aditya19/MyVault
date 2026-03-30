import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class Dailyhistory extends StatefulWidget {
  const Dailyhistory({super.key});

  @override
  State<Dailyhistory> createState() => _DailyhistoryState();
}

class _DailyhistoryState extends State<Dailyhistory> {
  Map<String, List<Map<String, dynamic>>> dailyTasks = {};

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
    taskFile = File('${dir.path}/tasks_file.txt');

    if (!await taskFile.exists()) return;

    try {
      String content = await taskFile.readAsString();
      final decrypted = decrypt(content);
      final decoded = jsonDecode(decrypted);

      setState(() {
        dailyTasks = (decoded as Map<String, dynamic>).map(
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

  bool isPass(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) return false;
    return tasks.every((task) => task["isDone"] == true);
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

      const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

      return "${date.day} ${months[date.month - 1]} ${date.year} ${days[date.weekday - 1]}";
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = dailyTasks.entries.toList();
    int total_days = entries.length;
    int total_days_pass = entries.where((entry) {
      return isPass(entry.value);
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Tasks History"),
        backgroundColor: const Color.fromARGB(255, 206, 203, 203),
      ),
      body: entries.isEmpty
          ? const Center(child: Text("No history available"))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("Total Days: $total_days"),
                      SizedBox(width: 10),
                      Text("Total Days Pass: $total_days_pass"),
                      SizedBox(width: 10),
                      Text(
                        "Pass Rate: ${total_days > 0 ? ((total_days_pass / total_days) * 100).toStringAsFixed(2) : "0.00"}%",
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
                                  formatDate(date),
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
