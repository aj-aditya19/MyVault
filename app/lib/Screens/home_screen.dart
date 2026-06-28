import 'package:app/Other/AppBar.dart';
import 'package:app/Other/Drawer.dart';
import 'package:app/Other/NavigateBar.dart';
import 'package:app/Screens/Dashboard/dashboard_screen.dart';
import 'package:app/Screens/Money/moneyhome_screen.dart';
import 'package:app/Screens/Study/study_home_screen.dart';
import 'package:app/Screens/Task/taskhome_screen.dart';
import 'package:app/core/utils/responsive.dart';
import 'package:app/core/widgets/pin_gate.dart';
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
  int _dashboardTick = 0;

  static const List<NavItemData> _navItems = [
    NavItemData(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    NavItemData(icon: Icons.task_alt_rounded, label: 'Tasks'),
    NavItemData(icon: Icons.school_rounded, label: 'Study'),
    NavItemData(
      icon: Icons.account_balance_wallet_rounded,
      label: 'Money',
      locked: true,
    ),
  ];

  void _goToTab(int index) {
    setState(() {
      if (index == 0 && selectedIndex != 0) {
        _dashboardTick++;
      }
      selectedIndex = index;
    });
  }

  Future<void> _handleNavTap(int index) async {
    final item = _navItems[index];
    if (item.locked) {
      final unlocked = await ensureSectionUnlocked(
        context,
        sectionName: item.label,
      );
      if (!unlocked) return;
    }
    if (mounted) _goToTab(index);
  }

  List<Widget> get screens => [
    DashboardScreen(key: ValueKey('dash-$_dashboardTick'), onOpenTab: _goToTab),
    Taskhome(
      themeMode: widget.themeMode,
      onThemeModeChanged: widget.onThemeModeChanged,
    ),
    const StudyHomeScreen(),
    Moneyhome(
      themeMode: widget.themeMode,
      onThemeModeChanged: widget.onThemeModeChanged,
    ),
  ];

  Widget _buildGlassContainer(BuildContext context, Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      padding: const EdgeInsets.all(10),
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
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 360),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(key: ValueKey(selectedIndex), child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final useSideNav = Responsive.useSideNav(context);
    final maxWidth = Responsive.maxContentWidth(context);

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final cappedWidth = maxWidth.isFinite
            ? (constraints.maxWidth > maxWidth ? maxWidth : constraints.maxWidth)
            : constraints.maxWidth;

        return Center(
          child: SizedBox(
            width: cappedWidth,
            height: double.infinity,
            child: _buildGlassContainer(context, screens[selectedIndex]),
          ),
        );
      },
    );

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
        child: useSideNav
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Navigatebar(
                    currentIndex: selectedIndex,
                    items: _navItems,
                    onTap: _handleNavTap,
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: content),
                ],
              )
            : content,
      ),
      bottomNavigationBar: useSideNav
          ? null
          : Navigatebar(
              currentIndex: selectedIndex,
              items: _navItems,
              onTap: _handleNavTap,
            ),
    );
  }
}
