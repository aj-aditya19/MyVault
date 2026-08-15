import 'package:app/Screens/Money/moneyhistory.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:app/core/services/storage_service.dart';

class Weekly extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  const Weekly({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<Weekly> createState() => _WeeklyState();
}

class _WeeklyState extends State<Weekly> {
  double weeklyBudget = 0;
  double remainingWeekly = 0;

  List<Map<String, dynamic>> sectors = [];
  List<Map<String, dynamic>> weeklySpending = [];

  int weekNumber = 0;

  static const String _boxName = 'weekly_money';

  @override
  void initState() {
    super.initState();
    loadWeeklyData();
  }

  int getCurrentWeekNumber() {
    DateTime now = DateTime.now();
    DateTime firstDayOfYear = DateTime(now.year, 1, 1);
    return ((now.difference(firstDayOfYear).inDays) ~/ 7) + 1;
  }

  InputDecoration _dialogFieldDecoration(ColorScheme scheme, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.92),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadAllWeeks() async {
    List<Map<String, dynamic>> weeks = await StorageService.readList(_boxName);

    if (weeks.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      final legacy = await StorageService.readLegacyPath(
        '${dir.path}/weekly_money.txt',
      );
      if (legacy is List && legacy.isNotEmpty) {
        weeks = legacy
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        await StorageService.write(_boxName, weeks);
      }
    }

    return weeks;
  }

  Future<void> loadWeeklyData() async {
    weekNumber = getCurrentWeekNumber();

    final weeks = await _loadAllWeeks();

    final currentWeek = weeks.firstWhere(
      (w) => w["week_number"] == weekNumber,
      orElse: () => {},
    );

    if (currentWeek.isNotEmpty) {
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
  }

  Future<void> saveWeeklyData() async {
    final weeks = await StorageService.readList(_boxName);

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

    await StorageService.write(_boxName, weeks);
  }

  void setWeeklyBudget() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          backgroundColor: scheme.surface,
          surfaceTintColor: scheme.surfaceTint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Enter Weekly Budget",
            style: TextStyle(color: scheme.onSurface),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: scheme.onSurface),
            cursorColor: scheme.primary,
            decoration: _dialogFieldDecoration(scheme, "Budget Amount"),
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
                Navigator.pop(dialogContext);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void showDeductPopup() {
    TextEditingController descController = TextEditingController();
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          backgroundColor: scheme.surface,
          surfaceTintColor: scheme.surfaceTint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Deduct Money",
            style: TextStyle(color: scheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descController,
                style: TextStyle(color: scheme.onSurface),
                cursorColor: scheme.primary,
                decoration: _dialogFieldDecoration(scheme, "Description"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: scheme.onSurface),
                cursorColor: scheme.primary,
                decoration: _dialogFieldDecoration(scheme, "Amount"),
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
                Navigator.pop(dialogContext);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
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
              child: weeklySpending.isEmpty
                  ? Center(
                      child: Text(
                        "No spending recorded yet.",
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      itemCount: weeklySpending.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = weeklySpending[index];

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item["desc"],
                                  style: TextStyle(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "- ₹${item["amount"]}",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            ElevatedButton(onPressed: endWeek, child: const Text("End Week")),
          ],
        ),
      ),
    );
  }
}
