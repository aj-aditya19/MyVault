import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DailyTask extends StatefulWidget {
  const DailyTask({super.key});

  @override
  State<DailyTask> createState() => _DailyTaskState();
}

class _DailyTaskState extends State<DailyTask> {
  final TextEditingController controller = TextEditingController();

  Map<String, List<Map<String, dynamic>>> allTasks = {};
  late File taskFile;

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
      await taskFile.writeAsString(jsonEncode({}));
    }

    String content = await taskFile.readAsString();

    if (content.isNotEmpty) {
      Map decoded = jsonDecode(content);

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
    }
  }

  Future<void> saveTasks() async {
    await taskFile.writeAsString(jsonEncode(allTasks));
  }

  @override
  void initState() {
    super.initState();
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 🔥 DATE HEADER
          Text(
            "Date: $today",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          // 🔹 Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
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
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),

          // 🔹 Today's Tasks
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDone ? Colors.green.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
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
                  color: isDone ? Colors.green : Colors.black,
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
