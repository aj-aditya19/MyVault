import 'package:flutter/material.dart';
import 'package:app/core/services/storage_service.dart';

class ExpenseCaptureService {
  ExpenseCaptureService._();

  static const String _boxName = 'weekly_money';

  static int _currentWeekNumber(DateTime date) =>
      ((date.difference(DateTime(date.year, 1, 1)).inDays) ~/ 7) + 1;

  static Future<bool> promptExpenseConfirmation({
    required BuildContext context,
    required double amount,
    String merchant = 'this payment',
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          backgroundColor: scheme.surface,
          surfaceTintColor: scheme.surfaceTint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Log this expense?'),
          content: Text(
            'Did you spend ₹${amount.toStringAsFixed(2)} on $merchant?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return false;
    if (!context.mounted) return false;

    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          backgroundColor: scheme.surface,
          surfaceTintColor: scheme.surfaceTint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('What was it for?'),
          content: TextField(
            controller: reasonController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. groceries, cab, recharge',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, ''),
              child: const Text('Skip'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, reasonController.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    await _logSpend(
      amount: amount,
      description: (reason == null || reason.isEmpty) ? merchant : reason,
    );
    return true;
  }

  static Future<void> _logSpend({
    required double amount,
    required String description,
  }) async {
    final now = DateTime.now();
    final weekNumber = _currentWeekNumber(now);

    final weeks = await StorageService.readList(_boxName);
    var index = weeks.indexWhere((w) => w['week_number'] == weekNumber);

    Map<String, dynamic> week = index == -1
        ? {
            'week_number': weekNumber,
            'weekly_budget': 0,
            'sectors': [],
            'spending': [],
          }
        : Map<String, dynamic>.from(weeks[index]);

    final spending = List<Map<String, dynamic>>.from(week['spending'] ?? []);
    spending.add({
      'desc': description,
      'amount': amount,
      'spent_at': now.toIso8601String(),
      'source': 'quick_capture',
    });
    week['spending'] = spending;

    if (index == -1) {
      weeks.add(week);
    } else {
      weeks[index] = week;
    }

    await StorageService.write(_boxName, weeks);
  }
}
