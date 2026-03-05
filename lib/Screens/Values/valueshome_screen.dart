import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Valueshome extends StatefulWidget {
  const Valueshome({super.key});

  @override
  State<Valueshome> createState() => _ValueshomeState();
}

class _ValueshomeState extends State<Valueshome> {
  final TextEditingController controller = TextEditingController();
  List<String> valuesList = [];
  late File valuesFile;

  Future<void> inifile() async {
    final dir = await getApplicationDocumentsDirectory();
    valuesFile = File('${dir.path}/values_file.txt');

    if (!await valuesFile.exists()) {
      await valuesFile.create();
      await valuesFile.writeAsString(jsonEncode([]));
    }

    String content = await valuesFile.readAsString();

    if (content.isNotEmpty) {
      List Decoded = jsonDecode(content);
      setState(() {
        valuesList = Decoded.map<String>((item) => item.toString()).toList();
      });
    }
  }

  Future<void> saveValues() async {
    await valuesFile.writeAsString(jsonEncode(valuesList));
  }

  @override
  void initState() {
    super.initState();
    inifile();
  }

  void addValue() async {
    final text = controller.text;
    if (text.isNotEmpty) {
      setState(() {
        valuesList.add(text);
        controller.clear();
      });
    }
    await saveValues();
  }

  void editValue(int index) {
    controller.text = valuesList[index];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Value"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  valuesList[index] = controller.text;
                  controller.clear();
                });

                await saveValues();
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Values"),
        backgroundColor: const Color.fromARGB(255, 206, 203, 203),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Input Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Enter a Value",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: addValue, child: const Text("+")),
              ],
            ),

            const SizedBox(height: 20),

            // 🔹 Values List
            Expanded(
              child: ListView.builder(
                itemCount: valuesList.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${index + 1}-> ${valuesList[index]}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                editValue(index);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                setState(() {
                                  valuesList.removeAt(index);
                                });

                                await saveValues();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
