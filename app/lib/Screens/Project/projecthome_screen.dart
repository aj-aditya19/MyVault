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
  bool _loading = true;

  static const String _boxName = 'project_ideas';

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

    projects = decoded
        .map<Map<String, String>>((item) => Map<String, String>.from(item))
        .toList();

    if (!mounted) return;
    setState(() => _loading = false);
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

  Future<bool> _confirmDelete(String name) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete project?'),
        content: Text('"$name" will be removed for good.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showDialog(
            context: context,
            builder: (context) => const AddProjectPopup(),
          );
          if (result != null) addProject(Map<String, String>.from(result));
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : projects.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 56,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No project ideas yet',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap + to jot down your first idea — name, tech\nstack, and a rough timeline.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.rocket_launch_rounded,
                          size: 20,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project['name'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                            if ((project['desc'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                project['desc']!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            if ((project['tech'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: project['tech']!
                                    .split(',')
                                    .map((t) => t.trim())
                                    .where((t) => t.isNotEmpty)
                                    .map(
                                      (t) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: scheme.surfaceContainerHighest
                                              .withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          t,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            if ((project['start_date'] ?? '').isNotEmpty ||
                                (project['end_date'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 12,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${project['start_date'] ?? '?'} → ${project['end_date'] ?? '?'}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: scheme.primary,
                            ),
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
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: scheme.error,
                            ),
                            onPressed: () async {
                              final ok = await _confirmDelete(
                                project['name'] ?? 'this project',
                              );
                              if (!ok) return;
                              setState(() => projects.removeAt(index));
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
    );
  }
}
