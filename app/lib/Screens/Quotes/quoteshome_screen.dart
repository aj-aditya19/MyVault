import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:app/core/services/storage_service.dart';

class Quoteshome extends StatefulWidget {
  const Quoteshome({super.key});

  @override
  State<Quoteshome> createState() => _QuoteshomeState();
}

class _QuoteshomeState extends State<Quoteshome> {
  final TextEditingController controller = TextEditingController();
  List<String> quotesList = [];

  static const String _boxName = 'quotes_file';

  Future<void> inifile() async {
    List<dynamic> decoded = await StorageService.read<List<dynamic>>(
      _boxName,
      <dynamic>[],
    );

    if (decoded.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      final legacy = await StorageService.readLegacyPath(
        '${dir.path}/MyVault/quotes_file.txt',
      );
      if (legacy is List && legacy.isNotEmpty) {
        decoded = legacy;
        await StorageService.write(_boxName, decoded);
      }
    }

    setState(() {
      quotesList = List<String>.from(decoded);
    });
  }

  Future<void> saveQuotes() async {
    await StorageService.write(_boxName, quotesList);
  }

  @override
  void initState() {
    super.initState();
    inifile();
  }

  void addQuote() async {
    final text = controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        quotesList.add(text);
        controller.clear();
      });
      await saveQuotes();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void editQuote(int index) {
    controller.text = quotesList[index];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Quote"),
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
                  quotesList[index] = controller.text;
                  controller.clear();
                });
                await saveQuotes();
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
        title: const Text("Quotes"),
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
                      hintText: "Enter a Quote",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: addQuote,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: quotesList.length,
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
                            quotesList[index],
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
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
                                editQuote(index);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                setState(() {
                                  quotesList.removeAt(index);
                                });
                                await saveQuotes();
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
