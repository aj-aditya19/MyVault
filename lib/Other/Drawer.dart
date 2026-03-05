import 'package:flutter/material.dart';
import 'package:app/Screens/Project/projecthome_screen.dart';
import 'package:app/Screens/Quotes/quoteshome_screen.dart';
import 'package:app/Screens/Values/valueshome_screen.dart';
import 'package:app/Other/setting_screen.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text("Other Sectors"),
          ),
          ListTile(
            title: Text("Projects"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Projecthome()),
              );
            },
            leading: Icon(Icons.arrow_forward_ios_rounded),
          ),
          ListTile(
            title: Text("Quotes"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Quoteshome()),
              );
            },
            leading: Icon(Icons.arrow_forward_ios_rounded),
          ),
          ListTile(
            title: Text("Values"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Valueshome()),
              );
            },
            leading: Icon(Icons.arrow_forward_ios_rounded),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text("Settings"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("Liceness"),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
