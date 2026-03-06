import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class Weekly extends StatefulWidget {
  const Weekly({super.key});

  @override
  State<Weekly> createState() => _WeeklyState();
}

class _WeeklyState extends State<Weekly> {
  double weeklyBudget = 0;
  double remainingWeekly = 0;

  List<Map<String, dynamic>> sectors = [];
  List<Map<String, dynamic>> weeklySpending = [];

  late File weeklyFile;
  late File accountFile;

  late encrypt.Key key;
  late encrypt.Encrypter encrypter;

  DateTime? startDate;
  DateTime? endDate;
  int weekNumber = 0;

  @override
  void initState() {
    super.initState();
    key = encrypt.Key.fromUtf8('my 32 length key................');
    encrypter = encrypt.Encrypter(encrypt.AES(key));
    initFiles();
  }

  String encryptData(String data) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = encrypter.encrypt(data, iv: iv);
    final combined = iv.bytes + encrypted.bytes;
    return base64Encode(combined);
  }

  String decryptData(String base64Data) {
    final combined = base64Decode(base64Data);
    final iv = encrypt.IV(combined.sublist(0, 16));
    final encryptedBytes = combined.sublist(16);
    final encrypted = encrypt.Encrypted(encryptedBytes);
    return encrypter.decrypt(encrypted, iv: iv);
  }

  Map<String, dynamic> getCurrentWeekInfo() {
    DateTime now = DateTime.now();
    int diff = now.weekday - 4;
    if (diff < 0) diff += 7;

    DateTime startOfWeek = now.subtract(Duration(days: diff));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    DateTime firstDayOfYear = DateTime(now.year, 1, 1);
    int weekNum = ((startOfWeek.difference(firstDayOfYear).inDays) ~/ 7) + 1;

    return {
      "week_number": weekNum,
      "start_date": startOfWeek,
      "end_date": endOfWeek,
    };
  }

  Future<void> addToSavingsSector(double amount) async {
    if (!await accountFile.exists()) return;

    String content = await accountFile.readAsString();
    if (content.isEmpty) return;

    final decrypted = decryptData(content);
    Map<String, dynamic> data = jsonDecode(decrypted);

    List transactions = data["transactions"];

    int index = transactions.indexWhere((item) => item["sector"] == "Savings");

    if (index == -1) {
      // sector exist nahi karta
      transactions.add({
        "sector": "Savings",
        "percent": 0,
        "money_available": amount,
      });
    } else {
      // sector exist karta hai
      transactions[index]["money_available"] =
          (transactions[index]["money_available"] ?? 0) + amount;
    }

    data["transactions"] = transactions;

    String encrypted = encryptData(jsonEncode(data));
    await accountFile.writeAsString(encrypted);
  }

  Future<void> initFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    weeklyFile = File("${dir.path}/weekly_money.txt");
    accountFile = File("${dir.path}/account_data.txt");

    if (!await weeklyFile.exists()) {
      await weeklyFile.create();
    }

    await loadWeeklyData();
  }

  Future<void> loadWeeklyData() async {
    final current = getCurrentWeekInfo();

    if (await weeklyFile.exists()) {
      String content = await weeklyFile.readAsString();

      if (content.isNotEmpty) {
        try {
          final decrypted = decryptData(content);
          Map<String, dynamic> data = jsonDecode(decrypted);

          startDate = DateTime.parse(data["start_date"]);
          endDate = DateTime.parse(data["end_date"]);
          weekNumber = data["week_number"];

          weeklyBudget = (data["weekly_budget"] ?? 0).toDouble();
          remainingWeekly = (data["remaining"] ?? 0).toDouble();

          sectors = List<Map<String, dynamic>>.from(data["sectors"] ?? []);
          weeklySpending = List<Map<String, dynamic>>.from(
            data["spending"] ?? [],
          );

          DateTime now = DateTime.now();
          if (now.isAfter(endDate!) && now.weekday == DateTime.thursday) {
            await handleWeekChange(current);
          }

          setState(() {});
          return;
        } catch (_) {}
      }
    }

    await handleWeekChange(current);
  }

  Future<void> handleWeekChange(Map<String, dynamic> current) async {
    if (remainingWeekly > 0) {
      await addToSavingsSector(remainingWeekly);
    }

    weeklyBudget = 0;
    remainingWeekly = 0;
    weeklySpending.clear();

    startDate = current["start_date"];
    endDate = current["end_date"];
    weekNumber = current["week_number"];

    await saveWeeklyData();
    setState(() {});
  }

  Future<void> saveWeeklyData() async {
    final data = {
      "week_number": weekNumber,
      "start_date": startDate?.toIso8601String(),
      "end_date": endDate?.toIso8601String(),
      "weekly_budget": weeklyBudget,
      "remaining": remainingWeekly,
      "sectors": sectors,
      "spending": weeklySpending,
    };

    String encrypted = encryptData(jsonEncode(data));
    await weeklyFile.writeAsString(encrypted);
  }

  Future<void> addToAccount(double amount) async {
    if (!await accountFile.exists()) return;

    String content = await accountFile.readAsString();

    if (content.isEmpty) return;

    final decrypted = decryptData(content);
    Map<String, dynamic> data = jsonDecode(decrypted);

    data["balance"] += amount;

    String encrypted = encryptData(jsonEncode(data));
    await accountFile.writeAsString(encrypted);
  }

  void setWeeklyBudget() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter Weekly Budget"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () {
              double amount = double.tryParse(controller.text) ?? 0;

              setState(() {
                weeklyBudget = amount;
                remainingWeekly = amount;
              });

              saveWeeklyData();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void showDeductPopup() {
    TextEditingController descController = TextEditingController();
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Deduct Money"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              double amount = double.tryParse(amountController.text) ?? 0;

              setState(() {
                remainingWeekly -= amount;

                weeklySpending.add({
                  "desc": descController.text,
                  "amount": amount,
                });
              });

              saveWeeklyData();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: showDeductPopup,
        child: const Icon(Icons.remove),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: setWeeklyBudget,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: remainingWeekly < 0 ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Weekly Budget",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₹ ${remainingWeekly.toStringAsFixed(2)} / ${weeklyBudget.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: weeklySpending.map((item) {
                  return ListTile(
                    title: Text(item["desc"]),
                    trailing: Text(
                      "- ₹${item["amount"]}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }).toList(),
              ),
            ),
            ElevatedButton(
              onPressed: () => handleWeekChange(getCurrentWeekInfo()),
              child: const Text("End Week"),
            ),
          ],
        ),
      ),
    );
  }
}
