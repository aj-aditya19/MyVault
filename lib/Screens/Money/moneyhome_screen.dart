import 'package:app/Other/section_tabs.dart';
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

  late final List<Widget> taskScreens = const [Weekly(), Account()];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          SectionTabs(
            labels: const ["Weekly", "Accounts"],
            icons: const [
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
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
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
