import 'package:flutter/material.dart';
import 'package:app/Screens/Project/projecthome_screen.dart';
import 'package:app/Screens/Quotes/quoteshome_screen.dart';
import 'package:app/Screens/Values/valueshome_screen.dart';
import 'package:app/Screens/Task/constant_goals_screen.dart';
import 'package:app/Other/license_screen.dart';
import 'package:app/Other/setting_screen.dart';
import 'package:app/core/widgets/pin_gate.dart';

class MyDrawer extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const MyDrawer({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  Future<void> _openProjects() async {
    final unlocked = await ensureSectionUnlocked(context, sectionName: 'Projects');
    if (!unlocked || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Projecthome()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.95),
                  scheme.tertiary.withValues(alpha: 0.95),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Other Sectors",
                  style: TextStyle(
                    color: widget.themeMode == ThemeMode.dark
                        ? Colors.black
                        : Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Plan and track every area",
                  style: TextStyle(
                    color: widget.themeMode == ThemeMode.dark
                        ? const Color.fromARGB(255, 25, 25, 25)
                        : const Color.fromARGB(255, 211, 209, 209),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text("Projects"),
            onTap: _openProjects,
            leading: const Icon(Icons.folder_copy_outlined),
            trailing: Icon(Icons.lock_outline, size: 16, color: scheme.onSurfaceVariant),
          ),
          ListTile(
            title: const Text("Quotes"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Quoteshome()),
              );
            },
            leading: const Icon(Icons.format_quote_rounded),
          ),
          ListTile(
            title: const Text("Values"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Valueshome()),
              );
            },
            leading: const Icon(Icons.workspace_premium_outlined),
          ),
          ListTile(
            title: const Text("Constant Goals"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConstantGoalsScreen(),
                ),
              );
            },
            leading: const Icon(Icons.flag_circle_outlined),
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            secondary: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
            ),
            title: const Text("Dark Mode"),
            value: widget.themeMode == ThemeMode.dark,
            onChanged: (value) {
              widget.onThemeModeChanged(
                value ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingScreen(
                    themeMode: widget.themeMode,
                    onThemeModeChanged: widget.onThemeModeChanged,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("Licenses"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LicenseScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
