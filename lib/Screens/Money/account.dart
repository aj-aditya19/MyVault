import 'package:app/Screens/Money/savings_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  double totalBalance = 1000;

  List<Map<String, dynamic>> transactions = [];
  late encrypt.Key key;
  late encrypt.Encrypter encrypter;

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

  @override
  void initState() {
    super.initState();
    key = encrypt.Key.fromUtf8('my 32 length key................');
    encrypter = encrypt.Encrypter(encrypt.AES(key));
    loadData();
  }

  Future<File> getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/account_data.txt");
  }

  Future<void> saveData() async {
    final file = await getFile();

    Map<String, dynamic> data = {
      "balance": totalBalance,
      "transactions": transactions,
    };

    String encrypted = encryptData(jsonEncode(data));
    await file.writeAsString(encrypted);
  }

  Future<void> loadData() async {
    try {
      final file = await getFile();

      if (await file.exists()) {
        String content = await file.readAsString();

        if (content.isEmpty) return;

        String decrypted;
        try {
          decrypted = decryptData(content);
        } catch (_) {
          decrypted = content;
        }

        Map<String, dynamic> data = jsonDecode(decrypted);

        setState(() {
          totalBalance = (data["balance"] ?? 0).toDouble();
          transactions = List<Map<String, dynamic>>.from(
            data["transactions"] ?? [],
          );
        });
      }
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  void deductMoney(int index, double amount) {
    setState(() {
      transactions[index]["money_available"] -= amount;
      totalBalance -= amount;
    });

    saveData();
  }

  void showGlobalDeductionDialog() {
    if (transactions.isEmpty) return;

    String selectedSector = transactions[0]["sector"];
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Deduct Money"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedSector,
              items: transactions
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item["sector"],
                      child: Text(item["sector"]),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                selectedSector = value!;
              },
              decoration: InputDecoration(labelText: "Select Sector"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Amount"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              double amount = double.tryParse(amountController.text) ?? 0;

              int index = transactions.indexWhere(
                (item) => item["sector"] == selectedSector,
              );

              if (index != -1 &&
                  transactions[index]["money_available"] >= amount) {
                setState(() {
                  transactions[index]["money_available"] -= amount;
                  totalBalance -= amount;
                });

                saveData();
              }

              Navigator.pop(context);
            },
            child: Text("Confirm"),
          ),
        ],
      ),
    );
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

              double money = totalBalance * percent / 100;

              setState(() {
                if (index == null) {
                  transactions.add({
                    "sector": name,
                    "percent": percent,
                    "money_available": money,
                  });
                } else {
                  transactions[index] = {
                    "sector": name,
                    "percent": percent,
                    "money_available": money,
                  };
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

  void addmoneytobudget({int? index}) {
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

              double money = totalBalance * percent / 100;

              setState(() {
                if (index == null) {
                  transactions.add({
                    "sector": name,
                    "percent": percent,
                    "money_available": money,
                  });
                } else {
                  transactions[index] = {
                    "sector": name,
                    "percent": percent,
                    "money_available": money,
                  };
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

  void distributeMoney(int new_money, bool isAddMoney) {
    if (isAddMoney) {
      totalBalance += new_money;
      for (var item in transactions) {
        double percent = (item["percent"] ?? 0).toDouble();
        item["money_available"] += new_money * percent / 100;
      }
    } else {
      totalBalance -= new_money;
      for (var item in transactions) {
        double percent = (item["percent"] ?? 0).toDouble();
        item["money_available"] -= new_money * percent / 100;
      }
    }
  }

  void editTotalBalance() {
    TextEditingController new_amount = TextEditingController();
    bool isAddMode = true;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Set Balance"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Current Money: $totalBalance"),
                  TextField(
                    controller: new_amount,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "${totalBalance / 10}",
                    ),
                  ),

                  SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Deduct"),

                      Switch(
                        value: isAddMode,
                        onChanged: (value) {
                          setStateDialog(() {
                            isAddMode = value;
                          });
                        },
                      ),

                      Text("Add"),
                    ],
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    int amount = int.tryParse(new_amount.text) ?? 0;

                    setState(() {
                      distributeMoney(amount, isAddMode);
                    });

                    saveData();
                    Navigator.pop(context);
                  },
                  child: Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: showGlobalDeductionDialog,
        backgroundColor: const Color.fromARGB(255, 225, 95, 86),
        child: Icon(Icons.remove, size: 20),
      ),
      body: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.lightBlueAccent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
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
                    ],
                  ),
                  Column(
                    children: [
                      Text("Balance", style: TextStyle(color: Colors.white)),
                      Row(
                        children: [
                          Text(
                            "\ ₹ ${totalBalance.toStringAsFixed(2)}",
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                          IconButton(
                            onPressed: () => editTotalBalance(),
                            icon: Icon(
                              Icons.arrow_right_outlined,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: showSectorDialog,
                  child: Container(
                    alignment: Alignment.center,
                    width: 120,
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 2,
                        color: const Color.fromARGB(255, 124, 122, 122),
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Add Sector"),
                        SizedBox(width: 2),
                        Icon(Icons.add_circle_sharp),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavingsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    alignment: Alignment.center,
                    width: 100,
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 2,
                        color: const Color.fromARGB(255, 124, 122, 122),
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text("Savings"), Icon(Icons.arrow_right)],
                    ),
                  ),
                ),
              ],
            ),
            Divider(),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(5),
                itemCount: transactions
                    .where((item) => item["sector"] != "Savings")
                    .length,
                itemBuilder: (context, index) {
                  final item = transactions[index];
                  double amount = (item["money_available"] ?? 0).toDouble();
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
                            Row(
                              children: [
                                Text(
                                  item["sector"].toString().toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Text("${item["percent"]}%"),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  "₹${amount.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: amount < 0
                                        ? Colors.red
                                        : Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, size: 20),
                                      onPressed: () =>
                                          showSectorDialog(index: index),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, size: 20),

                                      onPressed: () => removeSector(index),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
