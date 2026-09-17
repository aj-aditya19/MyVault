import 'package:app/Other/AppBar.dart';
import 'package:app/Other/Drawer.dart';
import 'package:app/Other/NavigateBar.dart';
import 'package:app/Screens/Dashboard/dashboard_screen.dart';
import 'package:app/Screens/Money/moneyhome_screen.dart';
import 'package:app/Screens/Schedule/schedule_screen.dart';
import 'package:app/Screens/Study/study_home_screen.dart';
import 'package:app/Screens/Task/taskhome_screen.dart';
import 'package:app/core/utils/responsive.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final bool isSignedIn;
  final VoidCallback onLoginRequested;

  HomeScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.isSignedIn,
    required this.onLoginRequested,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  int _dashboardTick = 0;

  void _goToTab(int index) {
    setState(() {
      if (index == 0 && selectedIndex != 0) {
        _dashboardTick++;
      }
      selectedIndex = index;
    });
  }

  List<Widget> get screens => [
    DashboardScreen(key: ValueKey('dash-$_dashboardTick'), onOpenTab: _goToTab),
    Taskhome(
      themeMode: widget.themeMode,
      onThemeModeChanged: widget.onThemeModeChanged,
    ),
    StudyHomeScreen(),
    Moneyhome(
      themeMode: widget.themeMode,
      onThemeModeChanged: widget.onThemeModeChanged,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final useSideNav = Responsive.useSideNav(context);
    final maxWidth = Responsive.maxContentWidth(context);

    final mainpart = LayoutBuilder(
      builder: (context, constraints) {
        final cappedWidth = maxWidth.isFinite
            ? (constraints.maxWidth > maxWidth
                  ? maxWidth
                  : constraints.maxWidth)
            : constraints.maxWidth;

        return Center(
          child: SizedBox(
            width: cappedWidth,
            height: double.infinity,
            child: screens[selectedIndex],
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
        isSignedIn: widget.isSignedIn,
        onLoginRequested: widget.onLoginRequested,
      ),
      body: SafeArea(
        top: false,
        child: useSideNav
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Navigatebar(currentIndex: selectedIndex, onTap: _goToTab),
                  const VerticalDivider(width: 1),
                  Expanded(child: mainpart),
                ],
              )
            : mainpart,
      ),
      bottomNavigationBar: useSideNav
          ? null
          : Navigatebar(currentIndex: selectedIndex, onTap: _goToTab),
    );
  }
}
