import 'package:app/Screens/Project/edit_project_popup.dart';
import 'package:flutter/material.dart';
import 'add_project_popup.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Projecthome extends StatefulWidget {
  const Projecthome({super.key});

  @override
  State<Projecthome> createState() => _ProjecthomeState();
}

class _ProjecthomeState extends State<Projecthome> {
  List<Map<String, String>> projects = [];
  late File projectFile;

  Future<void> initFile() async {
    final dir = await getApplicationDocumentsDirectory();
    projectFile = File('${dir.path}/project_ideas.txt');

    if (!await projectFile.exists()) {
      await projectFile.create();
      await projectFile.writeAsString(jsonEncode([]));
    }

    String content = await projectFile.readAsString();

    if (content.isNotEmpty) {
      List decoded = jsonDecode(content);
      setState(() {
        projects = decoded
            .map<Map<String, String>>((item) => Map<String, String>.from(item))
            .toList();
      });
    }
  }

  Future<void> saveProjects() async {
    await projectFile.writeAsString(jsonEncode(projects));
  }

  @override
  void initState() {
    super.initState();
    initFile();
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
