import 'package:app/Screens/Money/account.dart';
import 'package:app/Screens/Money/weekly.dart';
import 'package:flutter/material.dart';

class Moneyhome extends StatefulWidget {
  const Moneyhome({super.key});

  @override
  State<Moneyhome> createState() => _MoneyhomeState();
}

class _MoneyhomeState extends State<Moneyhome> {
  int selectedIndex = 0;
  List<Widget> taskScreens = [Weekly(), Account()];
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = 0;
                });
              },
              child: Container(
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selectedIndex == 0
                          ? Colors.blue
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: const Text("Weekly"),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = 1;
                });
              },
              child: Container(
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selectedIndex == 1
                          ? Colors.blue
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Icon(Icons.lock_clock_outlined), Text("Accounts")],
                ),
              ),
            ),
          ],
        ),
        Divider(),
        Expanded(child: taskScreens[selectedIndex]),
      ],
    );
  }
}
