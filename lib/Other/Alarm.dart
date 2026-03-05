import 'package:flutter/material.dart';

void showAlarmDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color.fromARGB(255, 131, 167, 191),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Set Alarm"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "This is the box for knowing that how to popup screen work.",
              ),
            ],
          ),
        ),
      );
    },
  );
}
