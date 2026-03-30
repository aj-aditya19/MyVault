import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class Moneyhistory extends StatefulWidget {
  const Moneyhistory({super.key});

  @override
  State<Moneyhistory> createState() => _MoneyhistoryState();
}

class _MoneyhistoryState extends State<Moneyhistory> {
  List<Map<String, dynamic>> weeks = [];

  late File taskFile;
  late encrypt.Key key;
  late encrypt.Encrypter encrypter;

  @override
  void initState() {
    super.initState();
    key = encrypt.Key.fromUtf8('my 32 length key................');
    encrypter = encrypt.Encrypter(encrypt.AES(key));
    loadHistory();
  }

  String decrypt(String base64Data) {
    final combined = base64Decode(base64Data);
    final iv = encrypt.IV(combined.sublist(0, 16));
    final encryptedBytes = combined.sublist(16);
    final encrypted = encrypt.Encrypted(encryptedBytes);
    return encrypter.decrypt(encrypted, iv: iv);
  }

  Future<void> loadHistory() async {
    final dir = await getApplicationDocumentsDirectory();
    taskFile = File('${dir.path}/weekly_money.txt');

    if (!await taskFile.exists()) return;

    try {
      String content = await taskFile.readAsString();

      if (content.isEmpty) return;

      final decrypted = decrypt(content);
      final decoded = jsonDecode(decrypted);

      if (decoded is List) {
        setState(() {
          weeks = List<Map<String, dynamic>>.from(decoded.reversed);
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  double getTotalSpent(List spending) {
    return spending.fold(0, (sum, item) => sum + (item["amount"] ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Money History"),
        backgroundColor: const Color.fromARGB(255, 206, 203, 203),
      ),
      body: weeks.isEmpty
          ? const Center(child: Text("No Data Found"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: weeks.length,
              itemBuilder: (context, index) {
                final week = weeks[index];
                final spending = week["spending"] ?? [];
                final budget = (week["weekly_budget"] ?? 0).toDouble();
                final spent = getTotalSpent(spending);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 4,
                        color: Colors.black12,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Week ${week["week_number"]}    ₹${spent.toStringAsFixed(0)} / ₹${budget.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),
                      const Divider(),
                      ...spending.map<Widget>((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item["desc"] ?? ""),
                              Text(
                                "₹${item["amount"]}",
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
