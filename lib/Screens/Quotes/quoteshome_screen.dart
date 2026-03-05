import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Quoteshome extends StatefulWidget {
  const Quoteshome({super.key});

  @override
  State<Quoteshome> createState() => _QuoteshomeState();
}

class _QuoteshomeState extends State<Quoteshome> {
  final TextEditingController controller = TextEditingController();
  List<String> quotesList = [];

  late File quotesFile;

  Future<void> inifile() async {
    final dir = await getApplicationDocumentsDirectory();
    quotesFile = File('${dir.path}/quotes_file.txt');

    if (!await quotesFile.exists()) {
      await quotesFile.create();
      await quotesFile.writeAsString(jsonEncode([]));
    }

    String content = await quotesFile.readAsString();

    if (content.isNotEmpty) {
      List Decoded = jsonDecode(content);
      setState(() {
        quotesList = Decoded.map<String>((item) => item.toString()).toList();
      });
    }
  }

  Future<void> saveQuotes() async {
    await quotesFile.writeAsString(jsonEncode(quotesList));
  }

  @override
  void initState() {
    super.initState();
    inifile();
  }

  void addQuote() async {
    final text = controller.text;
    if (text.isNotEmpty) {
      setState(() {
        quotesList.add(text);
        controller.clear();
      });
    }
    await saveQuotes();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quotes"),
        backgroundColor: const Color.fromARGB(255, 206, 203, 203),
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
                ElevatedButton(onPressed: addQuote, child: Icon(Icons.add)),
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
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          quotesList[index],
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
