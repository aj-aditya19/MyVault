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

  final List<Map<String, String>> starterProjects = const [
    {
      "name": "Vault Budget Tracker",
      "desc":
          "A clean finance dashboard for weekly limits, quick deductions, and history.",
      "tech": "Flutter, Local Storage",
      "start_date": "2026-05-01",
      "end_date": "2026-05-18",
    },
    {
      "name": "Study Sprint Planner",
      "desc":
          "A focused planning view with weekly goals, progress notes, and reminders.",
      "tech": "Flutter, State Management",
      "start_date": "2026-05-08",
      "end_date": "2026-05-24",
    },
    {
      "name": "Portfolio Notes Board",
      "desc":
          "An idea board for logging experiments, release ideas, and design references.",
      "tech": "Flutter, Encryption",
      "start_date": "2026-05-10",
      "end_date": "2026-06-02",
    },
  ];

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

      final loadedProjects = decodedData
          .map<Map<String, String>>((item) => Map<String, String>.from(item))
          .toList();

      if (loadedProjects.isEmpty) {
        projects = List<Map<String, String>>.from(starterProjects);
        await saveProjects();
      } else {
        projects = loadedProjects;
      }

      setState(() {});
    } catch (e) {
      print("Data is not encrypted. Encrypting old data now...");

      try {
        List decodedData = jsonDecode(content);
        String encrypted = encryptData(jsonEncode(decodedData));
        await projectFile.writeAsString(encrypted);

        final loadedProjects = decodedData
            .map<Map<String, String>>((item) => Map<String, String>.from(item))
            .toList();

        if (loadedProjects.isEmpty) {
          projects = List<Map<String, String>>.from(starterProjects);
          await saveProjects();
        } else {
          projects = loadedProjects;
        }

        setState(() {});
      } catch (e2) {
        print("File is corrupted: $e2");
        projects = List<Map<String, String>>.from(starterProjects);
        await saveProjects();
        setState(() {});
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Projects Home"),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outline, width: 1),
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              color: scheme.surface.withValues(alpha: 0.68),
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
                  const Padding(padding: EdgeInsets.all(12)),
                  Text(
                    "Add New project Idea",
                    style: TextStyle(
                      fontSize: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const Icon(Icons.add),
                ],
              ),
            ),
          ),
          Expanded(
            child: projects.isEmpty
                ? Center(
                    child: Text(
                      'No projects yet. Add your first idea.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(
                              alpha: 0.28,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    project["name"]!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    project["desc"]!,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Tech: ${project["tech"]!}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "${project["start_date"]!}-${project["end_date"]!}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: scheme.primary),
                                  onPressed: () async {
                                    final updatedProject =
                                        await editProjectPopup(
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
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
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
