import 'package:app/Screens/Money/moneyhistory.dart';
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

  late encrypt.Key key;
  late encrypt.Encrypter encrypter;

  int weekNumber = 0;

  @override
  void initState() {
    super.initState();
    key = encrypt.Key.fromUtf8('my 32 length key................');
    encrypter = encrypt.Encrypter(encrypt.AES(key));
    initFile();
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

  int getCurrentWeekNumber() {
    DateTime now = DateTime.now();
    DateTime firstDayOfYear = DateTime(now.year, 1, 1);
    return ((now.difference(firstDayOfYear).inDays) ~/ 7) + 1;
  }

  Future<void> initFile() async {
    final dir = await getApplicationDocumentsDirectory();
    weeklyFile = File("${dir.path}/weekly_money.txt");

    if (!await weeklyFile.exists()) {
      await weeklyFile.create();
      await weeklyFile.writeAsString(encryptData(jsonEncode([])));
    }

    await loadWeeklyData();
  }

  Future<void> loadWeeklyData() async {
    weekNumber = getCurrentWeekNumber();

    String content = await weeklyFile.readAsString();

    if (content.isEmpty) return;

    try {
      final decrypted = decryptData(content);
      final List data = jsonDecode(decrypted);

      final currentWeek = data.firstWhere(
        (w) => w["week_number"] == weekNumber,
        orElse: () => null,
      );

      if (currentWeek != null) {
        weeklyBudget = (currentWeek["weekly_budget"] ?? 0).toDouble();

        sectors = List<Map<String, dynamic>>.from(currentWeek["sectors"] ?? []);

        weeklySpending = List<Map<String, dynamic>>.from(
          currentWeek["spending"] ?? [],
        );

        double spent = weeklySpending.fold(
          0,
          (sum, item) => sum + (item["amount"] ?? 0),
        );

        remainingWeekly = weeklyBudget - spent;
      }

      setState(() {});
    } catch (e) {
      print("Load Error: $e");
    }
  }

  Future<void> saveWeeklyData() async {
    List weeks = [];

    String content = await weeklyFile.readAsString();

    if (content.isNotEmpty) {
      try {
        final decrypted = decryptData(content);
        final decoded = jsonDecode(decrypted);

        if (decoded is List) {
          weeks = decoded;
        }
      } catch (e) {
        print("Decode Error: $e");
      }
    }

    final newWeek = {
      "week_number": weekNumber,
      "weekly_budget": weeklyBudget,
      "sectors": sectors,
      "spending": weeklySpending,
    };

    int index = weeks.indexWhere((w) => w["week_number"] == weekNumber);

    if (index != -1) {
      weeks[index] = newWeek;
    } else {
      weeks.add(newWeek);
    }

    String encrypted = encryptData(jsonEncode(weeks));
    await weeklyFile.writeAsString(encrypted);
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
                weeklySpending.add({
                  "desc": descController.text,
                  "amount": amount,
                });

                remainingWeekly -= amount;
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

  void endWeek() async {
    weekNumber = getCurrentWeekNumber() + 1;

    weeklyBudget = 0;
    remainingWeekly = 0;
    weeklySpending.clear();

    await saveWeeklyData();
    setState(() {});
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
            SizedBox(height: 10),
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Week $weekNumber",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Moneyhistory(),
                        ),
                      );
                    },
                    child: Text("History"),
                  ),
                ],
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
            ElevatedButton(onPressed: endWeek, child: const Text("End Week")),
          ],
        ),
      ),
    );
  }
}
