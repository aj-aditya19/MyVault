import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  List<Map<String, dynamic>> savings = [];
  late encrypt.Key key;
  late encrypt.Encrypter encrypter;

  @override
  void initState() {
    super.initState();
    key = encrypt.Key.fromUtf8('my 32 length key................');
    encrypter = encrypt.Encrypter(encrypt.AES(key));
    loadSavings();
  }

  String decryptData(String base64Data) {
    final combined = base64Decode(base64Data);
    final iv = encrypt.IV(combined.sublist(0, 16));
    final encryptedBytes = combined.sublist(16);
    final encrypted = encrypt.Encrypted(encryptedBytes);
    return encrypter.decrypt(encrypted, iv: iv);
  }

  Future<void> loadSavings() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/account_data.txt");

      if (!await file.exists()) return;

      String content = await file.readAsString();
      if (content.isEmpty) return;

      // 🔑 Decrypt before JSON decode
      String decrypted = decryptData(content);

      Map<String, dynamic> data = jsonDecode(decrypted);

      setState(() {
        savings = List<Map<String, dynamic>>.from(
          data["transactions"].where((item) => item["sector"] == "Savings"),
        );
      });
    } catch (e) {
      print("Error loading savings: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalSavings = savings.fold(
      0,
      (sum, item) => sum + (item["money_available"] ?? 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Savings Screen"),
        backgroundColor: const Color.fromARGB(255, 206, 203, 203),
      ),
      body: Center(
        child: Text(
          "Total Savings: ₹${totalSavings.toStringAsFixed(2)}",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
