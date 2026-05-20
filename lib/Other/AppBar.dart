import 'package:app/Screens/Schedule.dart/Schedule_homepage.dart';
import 'package:app/Screens/Statistics/statisticshome_screen.dart';
import 'package:flutter/material.dart';

class Appbar extends StatelessWidget implements PreferredSizeWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const Appbar({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  ThemeMode _nextThemeMode() {
    if (themeMode == ThemeMode.system) {
      return ThemeMode.light;
    }
    if (themeMode == ThemeMode.light) {
      return ThemeMode.dark;
    }
    return ThemeMode.system;
  }

  IconData _themeIcon() {
    if (themeMode == ThemeMode.light) {
      return Icons.light_mode_rounded;
    }
    if (themeMode == ThemeMode.dark) {
      return Icons.dark_mode_rounded;
    }
    return Icons.brightness_auto_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppBar(
      title: Text(
        'MyVault',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: scheme.onSurface,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Switch Theme',
          onPressed: () => onThemeModeChanged(_nextThemeMode()),
          icon: Icon(_themeIcon()),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StatisticshomeScreen(),
              ),
            );
          },
          icon: const Icon(Icons.bar_chart_rounded),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ScheduleHomepage()),
            );
          },
          icon: const Icon(Icons.calendar_month_rounded),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
