import 'package:app/Screens/Task/dailyhistory.dart';
import 'package:app/Screens/Task/daily_checkin_screen.dart';
import 'package:app/Screens/Task/constant_goals_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class DailyTask extends StatefulWidget {
  const DailyTask({super.key});

  @override
  State<DailyTask> createState() => _DailyTaskState();
}

class _DailyTaskState extends State<DailyTask> {
  final TextEditingController controller = TextEditingController();

  Map<String, List<Map<String, dynamic>>> allTasks = {};
  late File taskFile;

  late final encrypt.Key key;
  late final encrypt.Encrypter encrypter;

  String encryptData(String data) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = encrypter.encrypt(data, iv: iv);
    final combined = iv.bytes + encrypted.bytes;
    return base64Encode(combined);
  }

  String decrypt(String base64Data) {
    final combined = base64Decode(base64Data);
    final iv = encrypt.IV(combined.sublist(0, 16));
    final encryptedBytes = combined.sublist(16);
    final encrypted = encrypt.Encrypted(encryptedBytes);
    return encrypter.decrypt(encrypted, iv: iv);
  }

  String get today {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  List<Map<String, dynamic>> get todayTasks {
    return allTasks[today] ?? [];
  }

  Future<void> initFile() async {
    final dir = await getApplicationDocumentsDirectory();
    taskFile = File('${dir.path}/tasks_file.txt');

    if (!await taskFile.exists()) {
      await taskFile.create();
      await taskFile.writeAsString(encryptData(jsonEncode([])));
    }

    String content = await taskFile.readAsString();

    if (content.isEmpty) return;
    try {
      final decrypted = decrypt(content);
      Map<String, dynamic> decoded = jsonDecode(decrypted);
      decoded = jsonDecode(decrypted);
      setState(() {
        allTasks = decoded.map<String, List<Map<String, dynamic>>>(
          (key, value) => MapEntry(
            key,
            (value as List)
                .map<Map<String, dynamic>>(
                  (item) => {"title": item["title"], "isDone": item["isDone"]},
                )
                .toList(),
          ),
        );
      });
    } catch (e) {
      print("Data is not encrypted. Encrypting old data now....");
      try {
        Map<String, dynamic> decoded = jsonDecode(content);
        String encrypted = encryptData(jsonEncode(decoded));
        await taskFile.writeAsString(encrypted);

        setState(() {
          allTasks = decoded.map<String, List<Map<String, dynamic>>>(
            (key, value) => MapEntry(
              key,
              (value as List)
                  .map<Map<String, dynamic>>(
                    (item) => {
                      "title": item["title"],
                      "isDone": item["isDone"],
                    },
                  )
                  .toList(),
            ),
          );
        });
      } catch (e2) {
        print("File is corrupted : $e2");
        allTasks = {};
      }
    }
  }

  Future<void> saveTasks() async {
    await taskFile.writeAsString(jsonEncode(allTasks));
  }

  @override
  void initState() {
    super.initState();
    key = encrypt.Key.fromUtf8('my 32 length key................');
    encrypter = encrypt.Encrypter(encrypt.AES(key));
    initFile();
  }

  void addTask() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      allTasks.putIfAbsent(today, () => []);
      allTasks[today]!.add({"title": text, "isDone": false});
      controller.clear();
    });

    await saveTasks();
  }

  void toggleTask(int index) async {
    setState(() {
      allTasks[today]![index]["isDone"] = !allTasks[today]![index]["isDone"];
    });

    await saveTasks();
  }

  void deleteTask(int index) async {
    setState(() {
      allTasks[today]!.removeAt(index);
    });

    await saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final dayNumber = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: "Day: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: "$dayNumber",
                      style: const TextStyle(fontWeight: FontWeight.w400),
                    ),
                    TextSpan(
                      text: "/365",
                      style: const TextStyle(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 18),
              ),

              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: "Date: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: today,
                      style: const TextStyle(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),

          Divider(height: 20, thickness: 2),
          SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Dailyhistory(),
                    ),
                  );
                },
                icon: const Icon(Icons.history_rounded),
                label: const Text("History"),
              ),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DailyCheckinScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.monitor_heart_outlined),
                label: const Text("Daily Check-in"),
              ),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConstantGoalsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.flag_circle_outlined),
                label: const Text("Constant Goals"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.30),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Enter today's task",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: addTask,
                  icon: Icon(Icons.add_circle, color: scheme.primary),
                ),
              ],
            ),
          ),

          SizedBox(height: 10),
          Divider(height: 20, thickness: 2),
          SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: todayTasks.length,
              itemBuilder: (context, index) {
                final task = todayTasks[index];

                return TaskTile(
                  title: task["title"],
                  isDone: task["isDone"],
                  onTap: () => toggleTask(index),
                  onDelete: () => deleteTask(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TaskTile extends StatelessWidget {
  final String title;
  final bool isDone;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.title,
    required this.isDone,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDone
              ? Colors.green.withValues(alpha: 0.18)
              : scheme.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.26),
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              color: Colors.black12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isDone ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isDone ? Colors.green : scheme.onSurface,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
