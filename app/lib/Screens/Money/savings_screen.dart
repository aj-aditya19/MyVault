import 'package:flutter/material.dart';
import 'package:app/core/services/storage_service.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  List<Map<String, dynamic>> savings = [];

  @override
  void initState() {
    super.initState();
    loadSavings();
  }

  Future<void> loadSavings() async {
    try {
      final data = await StorageService.readMap('account_data');
      final transactions = List<Map<String, dynamic>>.from(
        data["transactions"] ?? [],
      );

      setState(() {
        savings = transactions
            .where((item) => item["sector"] == "Savings")
            .toList();
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
