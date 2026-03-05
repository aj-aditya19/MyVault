// import 'package:flutter/material.dart';

// class WeeklyTask extends StatefulWidget {
//   const WeeklyTask({super.key});

//   @override
//   State<WeeklyTask> createState() => _WeeklyTaskState();
// }

// class _WeeklyTaskState extends State<WeeklyTask> {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Container(
//         height: 150,
//         width: 200,
//         padding: EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: const Color.fromARGB(255, 208, 208, 208),
//           border: Border.all(
//             width: 2,
//             color: Color.fromARGB(255, 208, 208, 208),
//           ),
//           borderRadius: BorderRadius.all(Radius.circular(20)),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             Icon(Icons.warning_amber_rounded, size: 35),
//             Text(
//               "Weekhly Task\nComing Soon",
//               style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class WeeklyTask extends StatefulWidget {
  const WeeklyTask({super.key});

  @override
  State<WeeklyTask> createState() => _WeeklyTaskState();
}

class _WeeklyTaskState extends State<WeeklyTask> {
  final TextEditingController controller = TextEditingController();

  Map<String, List<Map<String, dynamic>>> allWeeklyTasks = {};
  late File weeklyFile;

  // 🔥 Get Thursday-based week number
  String get currentWeekKey {
    DateTime now = DateTime.now();
    int year = now.year;

    DateTime firstJan = DateTime(year, 1, 1);

    // Find first Thursday
    int difference = (DateTime.thursday - firstJan.weekday) % 7;
    DateTime firstThursday = firstJan.add(Duration(days: difference));

    int weekNumber;

    if (now.isBefore(firstThursday)) {
      weekNumber = 1;
    } else {
      int daysDiff = now.difference(firstThursday).inDays;
      weekNumber = (daysDiff ~/ 7) + 1;
    }

    return "Week-$weekNumber ($year)";
  }

  List<Map<String, dynamic>> get currentWeekTasks {
    return allWeeklyTasks[currentWeekKey] ?? [];
  }

  Future<void> initFile() async {
    final dir = await getApplicationDocumentsDirectory();
    weeklyFile = File('${dir.path}/weekly_tasks.txt');

    if (!await weeklyFile.exists()) {
      await weeklyFile.create();
      await weeklyFile.writeAsString(jsonEncode({}));
    }

    String content = await weeklyFile.readAsString();

    if (content.isNotEmpty) {
      Map decoded = jsonDecode(content);

      setState(() {
        allWeeklyTasks = decoded.map<String, List<Map<String, dynamic>>>(
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
    await weeklyFile.writeAsString(jsonEncode(allWeeklyTasks));
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
      allWeeklyTasks.putIfAbsent(currentWeekKey, () => []);
      allWeeklyTasks[currentWeekKey]!.add({"title": text, "isDone": false});
      controller.clear();
    });

    await saveTasks();
  }

  void toggleTask(int index) async {
    setState(() {
      allWeeklyTasks[currentWeekKey]![index]["isDone"] =
          !allWeeklyTasks[currentWeekKey]![index]["isDone"];
    });

    await saveTasks();
  }

  void deleteTask(int index) async {
    setState(() {
      allWeeklyTasks[currentWeekKey]!.removeAt(index);
    });

    await saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            currentWeekKey,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

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
                      hintText: "Enter weekly task",
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

          Expanded(
            child: ListView.builder(
              itemCount: currentWeekTasks.length,
              itemBuilder: (context, index) {
                final task = currentWeekTasks[index];

                return ListTile(
                  leading: Icon(
                    task["isDone"]
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: task["isDone"] ? Colors.green : Colors.grey,
                  ),
                  title: Text(
                    task["title"],
                    style: TextStyle(
                      decoration: task["isDone"]
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  onTap: () => toggleTask(index),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteTask(index),
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
