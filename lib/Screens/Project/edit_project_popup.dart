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

  return showDialog<Map<String, String>>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Edit Project"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: techController,
                decoration: const InputDecoration(labelText: "Tech"),
              ),
              TextField(
                controller: startController,
                decoration: const InputDecoration(labelText: "Start Date"),
              ),
              TextField(
                controller: endController,
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
