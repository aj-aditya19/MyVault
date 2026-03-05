import 'package:flutter/material.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text(
              "Aditya",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("aditya@email.com"),
          ),
          Divider(),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Privacy"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text("Notifications"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text("Appearance"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),

          Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text("Dark Mode"),
            value: false,
            onChanged: (value) {},
          ),
          Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("About App"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
