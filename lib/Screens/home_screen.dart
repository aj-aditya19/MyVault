import 'package:app/Other/AppBar.dart';
import 'package:app/Other/Drawer.dart';
import 'package:app/Other/NavigateBar.dart';
import 'package:app/Screens/Money/moneyhome_screen.dart';
import 'package:app/Screens/Task/taskhome_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  List<Widget> screens = [Taskhome(), Moneyhome()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
      appBar: Appbar(),
      body: screens[selectedIndex],
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
