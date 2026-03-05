import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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

  @override
  void initState() {
    super.initState();
    loadAccountData();
  }

  Future<File> getAccountFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/account_data.txt");
  }

  Future<void> loadAccountData() async {
    final file = await getAccountFile();

    if (await file.exists()) {
      String content = await file.readAsString();
      Map<String, dynamic> data = jsonDecode(content);

      setState(() {
        sectors = List<Map<String, dynamic>>.from(data["transactions"]);
      });
    }
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

                for (var sector in sectors) {
                  double percent = sector["percent"];
                  double allocated = (percent * weeklyBudget) / 100;

                  sector["weeklyAllocated"] = allocated;
                  sector["weeklyRemaining"] = allocated;
                }

                weeklySpending.clear();
              });

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void showDeductPopup() {
    String selectedSector = sectors.isNotEmpty ? sectors[0]["sector"] : "";

    TextEditingController descController = TextEditingController();
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Deduct Money"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: selectedSector,
                items: sectors
                    .map<DropdownMenuItem<String>>(
                      (sector) => DropdownMenuItem<String>(
                        value: sector["sector"] as String,
                        child: Text(sector["sector"]),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) {
                  selectedSector = value!;
                },
              ),
              TextField(
                controller: descController,
                maxLength: 20,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              double amount = double.tryParse(amountController.text) ?? 0;

              setState(() {
                remainingWeekly -= amount;

                var sector = sectors.firstWhere(
                  (s) => s["sector"] == selectedSector,
                );

                sector["weeklyRemaining"] -= amount;

                weeklySpending.add({
                  "sector": selectedSector,
                  "desc": descController.text,
                  "amount": amount,
                });
              });

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> endWeek() async {
    if (remainingWeekly > 0) {
      final file = await getAccountFile();
      String content = await file.readAsString();
      Map<String, dynamic> data = jsonDecode(content);

      data["balance"] += remainingWeekly;

      await file.writeAsString(jsonEncode(data));
    }

    setState(() {
      weeklyBudget = 0;
      remainingWeekly = 0;
      weeklySpending.clear();
    });
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
                  color: Colors.green,
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
                children: [
                  ...sectors.map((sector) {
                    double remain = sector["weeklyRemaining"] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sector["sector"].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Remaining: ₹${remain.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: remain < 0 ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 20),
                  const Text(
                    "Spending History",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  ...weeklySpending.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item["sector"]),
                              Text(
                                item["desc"],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "- ₹${item["amount"]}",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            ElevatedButton(onPressed: endWeek, child: const Text("End Week")),
          ],
        ),
      ),
    );
  }
}
