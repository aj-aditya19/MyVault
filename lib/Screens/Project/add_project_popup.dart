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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Add New Project"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Project Name"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: techController,
              decoration: const InputDecoration(labelText: "Tech Stack"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: startDateController,
              decoration: const InputDecoration(labelText: "Start Date"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: endDateController,
              decoration: const InputDecoration(labelText: "End Date"),
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
