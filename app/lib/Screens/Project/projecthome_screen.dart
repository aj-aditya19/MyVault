import 'package:app/Screens/Project/edit_project_popup.dart';
import 'package:flutter/material.dart';
import 'add_project_popup.dart';
import 'package:path_provider/path_provider.dart';
import 'package:app/core/services/storage_service.dart';

class Projecthome extends StatefulWidget {
  const Projecthome({super.key});

  @override
  State<Projecthome> createState() => _ProjecthomeState();
}

class _ProjecthomeState extends State<Projecthome> {
  List<Map<String, String>> projects = [];

  static const String _boxName = 'project_ideas';

  final List<Map<String, String>> starterProjects = const [
    // {
    //   "name": "Portfolio Notes Board",
    //   "desc":
    //       "An idea board for logging experiments, release ideas, and design references.",
    //   "tech": "Flutter, Encryption",
    //   "start_date": "2026-05-10",
    //   "end_date": "2026-06-02",
    // },
  ];

  @override
  void initState() {
    super.initState();
    initFile();
  }

  Future<void> initFile() async {
    List<Map<String, dynamic>> decoded = await StorageService.readList(
      _boxName,
    );

    if (decoded.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      final legacy = await StorageService.readLegacyPath(
        '${dir.path}/MyVault/project_ideas.txt',
      );
      if (legacy is List && legacy.isNotEmpty) {
        decoded = legacy
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }

    final loadedProjects = decoded
        .map<Map<String, String>>((item) => Map<String, String>.from(item))
        .toList();

    if (loadedProjects.isEmpty) {
      projects = List<Map<String, String>>.from(starterProjects);
    } else {
      projects = loadedProjects;
    }

    await saveProjects();
    setState(() {});
  }

  Future<void> saveProjects() async {
    await StorageService.write(_boxName, projects);
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
