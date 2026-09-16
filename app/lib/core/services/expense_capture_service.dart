import 'package:flutter/material.dart';
import 'package:app/core/services/storage_service.dart';

/// A quick "did you spend this?" confirmation flow, logging straight into
/// the same 'weekly_money' box the Budget screen reads and writes.
///
/// Today this is triggered manually (e.g. a button, a share-sheet target,
/// or you calling it right after some other event in your own code). It's
/// built so that once real payment-notification capture exists (see the
/// note at the bottom of this file), that code can call the exact same
/// `promptExpenseConfirmation` function with the amount/merchant it parsed
/// — no other change needed.
class ExpenseCaptureService {
  ExpenseCaptureService._();

  static const String _boxName = 'weekly_money';

  static int _currentWeekNumber(DateTime date) =>
      ((date.difference(DateTime(date.year, 1, 1)).inDays) ~/ 7) + 1;

  /// Shows "Did you spend ₹[amount] on [merchant]?" with Yes / No, and if
  /// Yes, asks for a one-line reason, then logs it as a spend against the
  /// current week's budget. Returns true if it was logged.
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
    // await DailyReminderService.schedule();
  }
}

// ---------------------------------------------------------------------------
// Roadmap note — wiring this up to Google Pay / PhonePe automatically
// ---------------------------------------------------------------------------
// MyVault is local-first and doesn't talk to any bank or UPI API, and Google
// Pay has no public API for "tell me when the user spends money" — so true
// automatic detection has to happen on-device, by reading the payment app's
// own notifications. On Android that means:
//
//   1. Add a notification-listener plugin (e.g. `notification_listener_service`
//      or a small custom platform channel) to pubspec.yaml.
//   2. Declare the `BIND_NOTIFICATION_LISTENER_SERVICE` permission in
//      AndroidManifest.xml and send the user to the system settings screen
//      to grant "Notification access" to MyVault (this is a manual step the
//      user does once, Android doesn't allow granting it silently).
//   3. In the listener callback, filter for packages like
//      `com.google.android.apps.nbu.paisa.user` (Google Pay) or
//      `com.phonepe.app`, and parse the amount out of the notification text
//      (payment apps show it in a fairly consistent "₹123 paid to X" format,
//      but the exact wording changes across app versions/updates so this
//      needs light regex + testing against your own device).
//   4. Call `ExpenseCaptureService.promptExpenseConfirmation(...)` with the
//      parsed amount/merchant — everything after that already works.
//
// This is iOS-impossible (Apple doesn't allow reading other apps'
// notifications) and needs native Android permission work this text-only
// change set can't include, so it's left as a documented next step rather
// than a half-working plugin dependency guessed at here.
