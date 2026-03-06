import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class Quoteshome extends StatefulWidget {
  const Quoteshome({super.key});

  @override
  State<Quoteshome> createState() => _QuoteshomeState();
}

class _QuoteshomeState extends State<Quoteshome> {
  final TextEditingController controller = TextEditingController();
  List<String> quotesList = [];
  late File quotesFile;

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

  Future<void> inifile() async {
    final dir = await getApplicationDocumentsDirectory();
    quotesFile = File('${dir.path}/quotes_file.txt');

    if (!await quotesFile.exists()) {
      await quotesFile.create();
      await quotesFile.writeAsString(encryptData(jsonEncode([])));
    }

    String content = await quotesFile.readAsString();

    if (content.isEmpty) return;
    try {
      final decrypted = decrypt(content);
      List decodedData = jsonDecode(decrypted);
      setState(() {
        quotesList = List<String>.from(decodedData);
      });
    } catch (e) {
      print("Data is not encrypted. Encrypting old data now....");
      try {
        List decodedData = jsonDecode(content);
        String encrypted = encryptData(jsonEncode(decodedData));
        await quotesFile.writeAsString(encrypted);

        setState(() {
          quotesList = List<String>.from(decodedData);
        });
      } catch (e2) {
        print("File is corrupted : $e2");
        quotesList = [];
      }
    }
  }

  Future<void> saveQuotes() async {
    final jsonString = jsonEncode(quotesList);
    final encryptedData = encryptData(jsonString);
    await quotesFile.writeAsString(encryptedData);
  }

  @override
  void initState() {
    super.initState();
    key = encrypt.Key.fromUtf8('my 32 length key................');
    encrypter = encrypt.Encrypter(encrypt.AES(key));
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
