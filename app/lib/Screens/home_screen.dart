import 'package:app/Other/AppBar.dart';
import 'package:app/Other/Drawer.dart';
import 'package:app/Other/NavigateBar.dart';
import 'package:app/Screens/Money/moneyhome_screen.dart';
import 'package:app/Screens/Task/taskhome_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  HomeScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  List<Widget> get screens => [
    Taskhome(
      themeMode: widget.themeMode,
      onThemeModeChanged: widget.onThemeModeChanged,
    ),
    Moneyhome(
      themeMode: widget.themeMode,
      onThemeModeChanged: widget.onThemeModeChanged,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.light
        ? false
        : true;

    return Scaffold(
      extendBody: true,
      drawer: MyDrawer(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
      ),
      appBar: Appbar(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, raints) {
            final maxWidth = raints.maxWidth > 900 ? 900.0 : raints.maxWidth;

            return Center(
              child: Container(
                width: maxWidth,

                // TAKES MAX POSSIBLE HEIGHT
                height: double.infinity,

                margin: EdgeInsets.fromLTRB(14, 10, 14, 10),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: isDark ? 0.22 : 0.68),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.30 : 0.10,
                      ),
                      blurRadius: 26,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),

                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 360),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey(selectedIndex),
                    child: screens[selectedIndex],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Navigatebar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
    );
  }
}
