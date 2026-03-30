import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';

class StatisticshomeScreen extends StatefulWidget {
  const StatisticshomeScreen({super.key});

  @override
  State<StatisticshomeScreen> createState() => _StatisticshomeScreenState();
}

class _StatisticshomeScreenState extends State<StatisticshomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistics Page"),
        backgroundColor: const Color.fromARGB(255, 206, 203, 203),
      ),
      body: Center(child: Text("Statistics Home Page")),
    );
  }
}
