import 'package:app/Other/section_tabs.dart';
import 'package:app/Screens/Task/daily.dart';
import 'package:app/Screens/Task/weekly.dart';
import 'package:flutter/material.dart';

class Taskhome extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  const Taskhome({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<Taskhome> createState() => _TaskhomeState();
}

class _TaskhomeState extends State<Taskhome> {
  int selectedIndex = 0;

  late final List<Widget> taskScreens = const [DailyTask(), WeeklyTask()];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          SectionTabs(
            labels: const ["Daily", "Weekly"],
            icons: const [
              Icons.today_rounded,
              Icons.calendar_view_week_rounded,
              Icons.table_view_rounded,
            ],
            selectedIndex: selectedIndex,
            onChanged: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
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
