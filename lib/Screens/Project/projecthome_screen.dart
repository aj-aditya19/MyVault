import 'package:app/Screens/Project/edit_project_popup.dart';
import 'package:flutter/material.dart';
import 'add_project_popup.dart';
import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';

class Projecthome extends StatefulWidget {
  const Projecthome({super.key});

  @override
  State<Projecthome> createState() => _ProjecthomeState();
}

class _ProjecthomeState extends State<Projecthome> {
  List<Map<String, String>> projects = [];
  late File projectFile;

  late final encrypt.Key key;
  late final encrypt.Encrypter encrypter;

  String encryptData(String data) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = encrypter.encrypt(data, iv: iv);
    final combined = iv.bytes + encrypted.bytes;
    return base64Encode(combined);
  }

  String decryptData(String base64Data) {
    final combined = base64Decode(base64Data);
    final iv = encrypt.IV(combined.sublist(0, 16));
    final encryptedBytes = combined.sublist(16);
    final encrypted = encrypt.Encrypted(encryptedBytes);
    return encrypter.decrypt(encrypted, iv: iv);
  }

  @override
  void initState() {
    super.initState();
    key = encrypt.Key.fromUtf8('my 32 length key................');
    encrypter = encrypt.Encrypter(encrypt.AES(key));
    initFile();
  }

  Future<void> initFile() async {
    final dir = await getApplicationDocumentsDirectory();
    projectFile = File('${dir.path}/project_ideas.txt');

    if (!await projectFile.exists()) {
      await projectFile.create();
      await projectFile.writeAsString(encryptData(jsonEncode([])));
    }

    String content = await projectFile.readAsString();

    if (content.isEmpty) return;

    try {
      final decrypted = decryptData(content);
      List decodedData = jsonDecode(decrypted);

      setState(() {
        projects = decodedData
            .map<Map<String, String>>((item) => Map<String, String>.from(item))
            .toList();
      });
    } catch (e) {
      print("Data is not encrypted. Encrypting old data now...");

      try {
        List decodedData = jsonDecode(content);
        String encrypted = encryptData(jsonEncode(decodedData));
        await projectFile.writeAsString(encrypted);

        setState(() {
          projects = decodedData
              .map<Map<String, String>>(
                (item) => Map<String, String>.from(item),
              )
              .toList();
        });
      } catch (e2) {
        print("File is corrupted: $e2");
        projects = [];
      }
    }
  }

  Future<void> saveProjects() async {
    final jsonString = jsonEncode(projects);
    final encryptedData = encryptData(jsonString);
    await projectFile.writeAsString(encryptedData);
  }

  void addProject(Map<String, String> newProject) async {
    setState(() {
      projects.add(newProject);
    });
    await saveProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Projects Home"),
        backgroundColor: const Color.fromARGB(255, 206, 203, 203),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 16),
            width: 300,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color.fromARGB(255, 99, 99, 99),
                width: 1,
              ),
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: GestureDetector(
              onTap: () async {
                final result = await showDialog(
                  context: context,
                  builder: (context) => const AddProjectPopup(),
                );
                if (result != null) {
                  addProject(result);
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Padding(padding: EdgeInsets.all(12)),
                  Text(
                    "Add New project Idea",
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 99, 99, 99),
                    ),
                  ),
                  Icon(Icons.add),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 250,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project["name"]!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(project["desc"]!),
                            const SizedBox(height: 6),
                            Text(
                              "Tech: ${project["tech"]!}",
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${project["start_date"]!}-${project["end_date"]!}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              final updatedProject = await editProjectPopup(
                                context,
                                projects[index],
                              );

                              if (updatedProject != null) {
                                setState(() {
                                  projects[index] = updatedProject;
                                });
                                await saveProjects();
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              setState(() {
                                projects.removeAt(index);
                              });
                              await saveProjects();
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
    );
  }
}
