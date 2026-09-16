import 'package:app/Screens/Money/moneyhistory.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:app/core/services/try.dart';
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

  double get totalSpent => weeklySpending.fold<double>(
    0,
    (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0),
  );

  double get budgetProgress =>
      weeklyBudget <= 0 ? 0 : (totalSpent / weeklyBudget).clamp(0.0, 1.0);

  int get _daysLeftInWeek {
    final now = DateTime.now();
    final daysFromThursday = (now.weekday - DateTime.thursday + 7) % 7;
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysFromThursday));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final today = DateTime(now.year, now.month, now.day);
    return endOfWeek.difference(today).inDays + 1;
  }

  double get _averageDailySpend {
    final now = DateTime.now();
    final daysFromThursday = (now.weekday - DateTime.thursday + 7) % 7;
    final daysElapsed = daysFromThursday + 1;
    return daysElapsed <= 0 ? totalSpent : totalSpent / daysElapsed;
  }

  Map<String, double> get _categoryTotals {
    final totals = <String, double>{};
    for (final item in weeklySpending) {
      final category = (item['category'] as String?)?.trim();
      final key = (category == null || category.isEmpty) ? 'General' : category;
      final amount = (item['amount'] as num?)?.toDouble() ?? 0;
      totals[key] = (totals[key] ?? 0) + amount;
    }
    return totals;
  }

  static const List<String> _defaultCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Other',
  ];

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

      remainingWeekly = weeklyBudget - totalSpent;
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
    // await DailyReminderService.schedule();
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
                final amount = double.tryParse(controller.text.trim());
                if (amount == null || amount <= 0) return;

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
    String selectedCategory = _defaultCategories.first;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: _dialogFieldDecoration(scheme, "Category"),
                    items: _defaultCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedCategory = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );
                    if (amount == null ||
                        amount <= 0 ||
                        descController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Enter a description and a positive amount.',
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      weeklySpending.add({
                        "desc": descController.text.trim(),
                        "amount": amount,
                        "category": selectedCategory,
                        "spent_at": DateTime.now().toIso8601String(),
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
      },
    );
  }

  Future<void> _deleteSpend(int index) async {
    setState(() {
      final removed = weeklySpending.removeAt(index);
      remainingWeekly += ((removed['amount'] as num?)?.toDouble() ?? 0);
    });
    await saveWeeklyData();
  }

  void endWeek() async {
    weekNumber = getCurrentWeekNumber() + 1;

    weeklyBudget = 0;
    remainingWeekly = 0;
    weeklySpending.clear();

    await saveWeeklyData();
    setState(() {});
  }

  Color _remainingColor(ColorScheme scheme) {
    if (weeklyBudget <= 0) return scheme.onSurfaceVariant;
    if (remainingWeekly < 0) return scheme.error;
    final remainingRatio = remainingWeekly / weeklyBudget;
    if (remainingRatio < 0.2) return Colors.orange.shade700;
    return scheme.primary;
  }

  Widget _buildCategoryBreakdown(ColorScheme scheme) {
    final totals = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxAmount = totals.first.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By category',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          for (final entry in totals)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(color: scheme.onSurface),
                      ),
                      Text(
                        '₹${entry.value.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxAmount <= 0 ? 0 : entry.value / maxAmount,
                      minHeight: 5,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Week $weekNumber",
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      IconButton(
                        tooltip: 'Edit weekly budget',
                        onPressed: setWeeklyBudget,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                  Text(
                    "₹${remainingWeekly.toStringAsFixed(2)} remaining",
                    style: TextStyle(
                      fontSize: 26,
                      color: _remainingColor(scheme),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: budgetProgress,
                      minHeight: 8,
                      color: _remainingColor(scheme),
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Spent ₹${totalSpent.toStringAsFixed(2)}'),
                      Text('Budget ₹${weeklyBudget.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_daysLeftInWeek day${_daysLeftInWeek == 1 ? '' : 's'} left this week',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Avg ₹${_averageDailySpend.toStringAsFixed(0)}/day',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_categoryTotals.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildCategoryBreakdown(scheme),
            ],
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
                        final category = (item["category"] as String?)?.trim();

                        return Dismissible(
                          key: ValueKey(
                            '${item["spent_at"]}_${item["desc"]}_$index',
                          ),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: scheme.error.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) => _deleteSpend(index),
                          child: Container(
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item["desc"],
                                        style: TextStyle(
                                          color: scheme.onSurface,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (category != null &&
                                          category.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 3,
                                          ),
                                          child: Text(
                                            category,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                    ],
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
