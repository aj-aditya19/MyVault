import 'package:app/Screens/Task/weeklyhistory.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
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

  String get currentWeekKey {
    DateTime now = DateTime.now();
    int year = now.year;

    DateTime firstJan = DateTime(year, 1, 1);

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
      await weeklyFile.writeAsString(encryptData(jsonEncode({})));
    }

    String content = await weeklyFile.readAsString();

    if (content.isEmpty) return;
    try {
      final decrypted = decrypt(content);
      Map<String, dynamic> decoded = jsonDecode(decrypted);
      decoded = jsonDecode(decrypted);
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
    } catch (e) {
      print("Data is not encrypted. Encrypting old data now....");
      try {
        Map<String, dynamic> decoded = jsonDecode(content);
        String encrypted = encryptData(jsonEncode(decoded));
        await weeklyFile.writeAsString(encrypted);

        setState(() {
          allWeeklyTasks = decoded.map<String, List<Map<String, dynamic>>>(
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
        allWeeklyTasks = {};
      }
    }
  }

  Future<void> saveTasks() async {
    await weeklyFile.writeAsString(jsonEncode(allWeeklyTasks));
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
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Weeklyhistory()),
              );
            },
            child: Text("History"),
          ),
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
