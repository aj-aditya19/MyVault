import 'package:flutter/material.dart';

import 'package:app/Other/section_tabs.dart';
import 'package:app/Screens/Study/study_log_screen.dart';
import 'package:app/Screens/Study/study_stats_screen.dart';

class StudyHomeScreen extends StatefulWidget {
  const StudyHomeScreen({super.key});

  @override
  State<StudyHomeScreen> createState() => _StudyHomeScreenState();
}

class _StudyHomeScreenState extends State<StudyHomeScreen> {
  int selectedIndex = 0;

  // Bump to force the Stats tab to reload after a session is logged.
  int _statsTick = 0;

  void _onSessionSaved() {
    setState(() => _statsTick++);
  }

  List<Widget> get _screens => [
    StudyLogScreen(onSaved: _onSessionSaved),
    StudyStatsScreen(key: ValueKey('study-stats-$_statsTick')),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          SectionTabs(
            labels: const ['Log', 'Stats'],
            icons: const [Icons.edit_note_rounded, Icons.insights_rounded],
            selectedIndex: selectedIndex,
            onChanged: (index) {
              if (index == 1) _onSessionSaved();
              setState(() => selectedIndex = index);
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
                child: _screens[selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
