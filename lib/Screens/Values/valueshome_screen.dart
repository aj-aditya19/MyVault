import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class Valueshome extends StatefulWidget {
  const Valueshome({super.key});

  @override
  State<Valueshome> createState() => _ValueshomeState();
}

class _ValueshomeState extends State<Valueshome> {
  final TextEditingController controller = TextEditingController();
  List<String> valuesList = [];
  late File valuesFile;

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
    valuesFile = File('${dir.path}/values_file.txt');

    if (!await valuesFile.exists()) {
      await valuesFile.create();
      await valuesFile.writeAsString(encryptData(jsonEncode([])));
    }

    String content = await valuesFile.readAsString();

    if (content.isEmpty) return;
    try {
      final decrypted = decrypt(content);
      List decodedData = jsonDecode(decrypted);
      setState(() {
        valuesList = List<String>.from(decodedData);
      });
    } catch (e) {
      print("Data is not encrypted. Encrypting old data now....");
      try {
        List decodedData = jsonDecode(content);
        String encrypted = encryptData(jsonEncode(decodedData));
        await valuesFile.writeAsString(encrypted);

        setState(() {
          valuesList = List<String>.from(decodedData);
        });
      } catch (e2) {
        print("File is corrupted : $e2");
        valuesList = [];
      }
    }
  }

  Future<void> saveValues() async {
    final jsonString = jsonEncode(valuesList);
    final encryptedData = encryptData(jsonString);
    await valuesFile.writeAsString(encryptedData);
  }

  @override
  void initState() {
    super.initState();
    key = encrypt.Key.fromUtf8('my 32 length key................');
    encrypter = encrypt.Encrypter(encrypt.AES(key));
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
