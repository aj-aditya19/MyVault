import 'package:app/Other/section_tabs.dart';
import 'package:app/Screens/Money/account.dart';
import 'package:app/Screens/Money/weekly.dart';
import 'package:flutter/material.dart';

class Moneyhome extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  Moneyhome({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<Moneyhome> createState() => _MoneyhomeState();
}

class _MoneyhomeState extends State<Moneyhome> {
  int selectedIndex = 0;

  List<Widget> get taskScreens => [
    Weekly(
      themeMode: widget.themeMode,
      onThemeModeChanged: widget.onThemeModeChanged,
    ),
    Account(
      themeMode: widget.themeMode,
      onThemeModeChanged: widget.onThemeModeChanged,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          SectionTabs(
            labels: ["Weekly", "Accounts"],
            icons: [
              Icons.insights_rounded,
              Icons.account_balance_wallet_rounded,
            ],
            selectedIndex: selectedIndex,
            onChanged: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
          ),
          SizedBox(height: 8),
          Divider(height: 1),
          SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              child: KeyedSubtree(
                key: ValueKey(selectedIndex),
                child: taskScreens[selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
