import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:app/core/services/storage_service.dart';

class Valueshome extends StatefulWidget {
  const Valueshome({super.key});

  @override
  State<Valueshome> createState() => _ValueshomeState();
}

class _ValueshomeState extends State<Valueshome> {
  final TextEditingController controller = TextEditingController();
  List<String> valuesList = [];

  static const String _boxName = 'values_file';

  Future<void> inifile() async {
    List<dynamic> decoded = await StorageService.read<List<dynamic>>(
      _boxName,
      <dynamic>[],
    );

    if (decoded.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      final legacy = await StorageService.readLegacyPath(
        '${dir.path}/MyVault/values_file.txt',
      );
      if (legacy is List && legacy.isNotEmpty) {
        decoded = legacy;
        await StorageService.write(_boxName, decoded);
      }
    }

    setState(() {
      valuesList = List<String>.from(decoded);
    });
  }

  Future<void> saveValues() async {
    await StorageService.write(_boxName, valuesList);
  }

  @override
  void initState() {
    super.initState();
    inifile();
  }

  void addValue() async {
    final text = controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        valuesList.add(text);
        controller.clear();
      });
      await saveValues();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Values"),
        backgroundColor: Colors.transparent,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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

            Expanded(
              child: ListView.builder(
                itemCount: valuesList.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "${index + 1}-> ${valuesList[index]}",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: scheme.primary),
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
