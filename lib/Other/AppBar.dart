import 'package:flutter/material.dart';

class Appbar extends StatelessWidget implements PreferredSizeWidget {
  const Appbar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('MyVault'),
      // actions: [
      //   IconButton(onPressed: () {}, icon: const Icon(Icons.notifications)),
      //   IconButton(onPressed: () {}, icon: const Icon(Icons.alarm)),
      // ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
