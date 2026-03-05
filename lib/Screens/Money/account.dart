import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

// ... Keep all your imports and class declarations the same ...

class _AccountState extends State<Account> {
  double totalBalance = 1000;

  // Only store sector and percent
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<File> getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/account_data.txt");
  }

  Future<void> saveData() async {
    final file = await getFile();

    // Only save sector and percent
    Map<String, dynamic> data = {
      "balance": totalBalance,
      "transactions": transactions, // no 'amount'
    };
    await file.writeAsString(jsonEncode(data));
  }

  Future<void> loadData() async {
    try {
      final file = await getFile();

      if (await file.exists()) {
        String content = await file.readAsString();

        if (content.isNotEmpty) {
          Map<String, dynamic> data = jsonDecode(content);

          setState(() {
            totalBalance = (data["balance"] ?? 0).toDouble();
            transactions = List<Map<String, dynamic>>.from(
              data["transactions"] ?? [],
            );
          });
        }
      }
    } catch (e) {
      print("Error loading data: $e");
      final file = await getFile();
      await file.writeAsString("");
    }
  }

  void showSectorDialog({int? index}) {
    TextEditingController nameController = TextEditingController();
    TextEditingController percentController = TextEditingController();

    if (index != null) {
      nameController.text = transactions[index]["sector"];
      percentController.text = transactions[index]["percent"].toString();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(index == null ? "Add Sector" : "Edit Sector"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Sector Name"),
            ),
            TextField(
              controller: percentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Percent"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              String name = nameController.text;
              double percent = double.tryParse(percentController.text) ?? 0;

              setState(() {
                if (index == null) {
                  transactions.add({"sector": name, "percent": percent});
                } else {
                  transactions[index] = {"sector": name, "percent": percent};
                }
              });

              saveData();
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  void removeSector(int index) {
    setState(() {
      transactions.removeAt(index);
    });
    saveData();
  }

  void changeBalance() {
    TextEditingController controller = TextEditingController(
      text: totalBalance.toString(),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Set Balance"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                totalBalance = double.tryParse(controller.text) ?? 0;
              });
              saveData();
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(20),
      child: Column(
        children: [
          GestureDetector(
            onTap: changeBalance,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.lightBlueAccent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "Account",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.account_balance, color: Colors.white),
                    ],
                  ),
                  Column(
                    children: [
                      Text("Balance", style: TextStyle(color: Colors.white)),
                      Text(
                        "\ ₹ ${totalBalance.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 10),
          Divider(),

          Expanded(
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.amberAccent,
              ),
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final item = transactions[index];

                  // Calculate amount in INR
                  double usdAmount =
                      totalBalance * (item["percent"] ?? 0) / 100;
                  double conversionRate = 1;
                  double inrAmount = usdAmount * conversionRate;

                  return Container(
                    margin: EdgeInsets.only(bottom: 15),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item["sector"].toString().toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () =>
                                      showSectorDialog(index: index),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => removeSector(index),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Text("Percent: ${item["percent"]}%"),
                        Text(
                          "Amount: ₹${inrAmount.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: inrAmount < 0 ? Colors.red : Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          SizedBox(height: 10),

          ElevatedButton(
            onPressed: () => showSectorDialog(),
            child: Text("Add Sector"),
          ),
        ],
      ),
    );
  }
}
