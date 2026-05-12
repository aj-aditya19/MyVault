import 'package:flutter/material.dart';

class AddProjectPopup extends StatefulWidget {
  const AddProjectPopup({super.key});

  @override
  State<AddProjectPopup> createState() => _AddProjectPopupState();
}

class _AddProjectPopupState extends State<AddProjectPopup> {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final techController = TextEditingController();
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();

  InputDecoration _fieldDecoration(ColorScheme scheme, String label) {
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: scheme.surface,
      surfaceTintColor: scheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text("Add New Project", style: TextStyle(color: scheme.onSurface)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: scheme.onSurface),
              cursorColor: scheme.primary,
              decoration: _fieldDecoration(scheme, "Project Name"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              style: TextStyle(color: scheme.onSurface),
              cursorColor: scheme.primary,
              decoration: _fieldDecoration(scheme, "Description"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: techController,
              style: TextStyle(color: scheme.onSurface),
              cursorColor: scheme.primary,
              decoration: _fieldDecoration(scheme, "Tech Stack"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: startDateController,
              style: TextStyle(color: scheme.onSurface),
              cursorColor: scheme.primary,
              decoration: _fieldDecoration(scheme, "Start Date"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: endDateController,
              style: TextStyle(color: scheme.onSurface),
              cursorColor: scheme.primary,
              decoration: _fieldDecoration(scheme, "End Date"),
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
              "start_date": startDateController.text,
              "end_date": endDateController.text,
            });
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
