import 'package:flutter/material.dart';
import 'package:app/core/services/storage_service.dart';

class Moneyhistory extends StatefulWidget {
  const Moneyhistory({super.key});

  @override
  State<Moneyhistory> createState() => _MoneyhistoryState();
}

class _MoneyhistoryState extends State<Moneyhistory> {
  List<Map<String, dynamic>> weeks = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final data = await StorageService.readList('weekly_money');
      setState(() {
        weeks = data.reversed.toList();
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  double getTotalSpent(List spending) {
    return spending.fold(0, (sum, item) => sum + (item["amount"] ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Money History"),
        backgroundColor: Colors.transparent,
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
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.72,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.28),
                    ),
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
                                style: TextStyle(color: scheme.error),
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
