import 'package:flutter/material.dart';

Future<Map<String, String>?> editProjectPopup(
  BuildContext context,
  Map<String, String> project,
) {
  final nameController = TextEditingController(text: project["name"]);
  final descController = TextEditingController(text: project["desc"]);
  final techController = TextEditingController(text: project["tech"]);
  final startController = TextEditingController(text: project["start_date"]);
  final endController = TextEditingController(text: project["end_date"]);

  InputDecoration fieldDecoration(ColorScheme scheme, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.92),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    );
  }

  return showDialog<Map<String, String>>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;

      return AlertDialog(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Edit Project", style: TextStyle(color: scheme.onSurface)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: scheme.onSurface),
                cursorColor: scheme.primary,
                decoration: fieldDecoration(scheme, "Name"),
              ),
              TextField(
                controller: descController,
                style: TextStyle(color: scheme.onSurface),
                cursorColor: scheme.primary,
                decoration: fieldDecoration(scheme, "Description"),
              ),
              TextField(
                controller: techController,
                style: TextStyle(color: scheme.onSurface),
                cursorColor: scheme.primary,
                decoration: fieldDecoration(scheme, "Tech"),
              ),
              TextField(
                controller: startController,
                style: TextStyle(color: scheme.onSurface),
                cursorColor: scheme.primary,
                decoration: fieldDecoration(scheme, "Start Date"),
              ),
              TextField(
                controller: endController,
                style: TextStyle(color: scheme.onSurface),
                cursorColor: scheme.primary,
                decoration: fieldDecoration(scheme, "End Date"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                "name": nameController.text,
                "desc": descController.text,
                "tech": techController.text,
                "start_date": startController.text,
                "end_date": endController.text,
              });
            },
            child: const Text("Save"),
          ),
        ],
      );
    },
  );
}
