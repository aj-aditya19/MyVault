import 'package:flutter/material.dart';

class Navigatebar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const Navigatebar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<Navigatebar> createState() => _NavigatebarState();
}

class _NavigatebarState extends State<Navigatebar> {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: widget.onTap,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.task_alt_rounded),
          label: "Tasks",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: "Money"),
      ],
    );
  }
}
