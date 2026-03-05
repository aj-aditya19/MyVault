import 'package:flutter/material.dart';

class MonthlyTask extends StatefulWidget {
  const MonthlyTask({super.key});

  @override
  State<MonthlyTask> createState() => _MonthlyTaskState();
}

class _MonthlyTaskState extends State<MonthlyTask> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 150,
        width: 200,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 208, 208, 208),
          border: Border.all(
            width: 2,
            color: Color.fromARGB(255, 208, 208, 208),
          ),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(Icons.warning_amber_rounded, size: 35),
            Text(
              "Monthly Task\nComing Soon",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
