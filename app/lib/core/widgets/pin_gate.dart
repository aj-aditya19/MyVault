import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/pin_service.dart';

/// Call this before navigating into a locked section. Returns true if the
/// section should be opened (either it was already unlocked this session,
/// or the person just entered the right PIN / biometric / set up a new PIN).
Future<bool> ensureSectionUnlocked(
  BuildContext context, {
  required String sectionName,
}) async {
  final pinService = context.read<PinService>();
  final hasPin = await pinService.hasPin();

  if (!hasPin) {
    if (!context.mounted) return false;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PinSetupScreen(sectionName: sectionName),
        fullscreenDialog: true,
      ),
    );
    return created == true;
  }

  if (pinService.isUnlocked) return true;

  if (!context.mounted) return false;
  final unlocked = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => PinEntryScreen(sectionName: sectionName),
      fullscreenDialog: true,
    ),
  );
  return unlocked == true;
}

class _PinDots extends StatelessWidget {
  final int length;
  final int filled;
  final Color color;

  const _PinDots({
    required this.length,
    required this.filled,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isFilled = index < filled;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
        );
      }),
    );
  }
}

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;

  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget keyButton(String label, {VoidCallback? onTap, Widget? child}) {
      return Expanded(
        child: AspectRatio(
          aspectRatio: 1.4,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Material(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onTap,
                child: Center(
                  child:
                      child ??
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget row(List<Widget> children) =>
        Row(mainAxisAlignment: MainAxisAlignment.center, children: children);

    return Column(
      children: [
        row([
          keyButton('1', onTap: () => onDigit('1')),
          keyButton('2', onTap: () => onDigit('2')),
          keyButton('3', onTap: () => onDigit('3')),
        ]),
        row([
          keyButton('4', onTap: () => onDigit('4')),
          keyButton('5', onTap: () => onDigit('5')),
          keyButton('6', onTap: () => onDigit('6')),
        ]),
        row([
          keyButton('7', onTap: () => onDigit('7')),
          keyButton('8', onTap: () => onDigit('8')),
          keyButton('9', onTap: () => onDigit('9')),
        ]),
        row([
          keyButton(
            '',
            onTap: onBiometric,
            child: Icon(
              Icons.fingerprint_rounded,
              size: 26,
              color: onBiometric != null ? scheme.primary : Colors.transparent,
            ),
          ),
          keyButton('0', onTap: () => onDigit('0')),
          keyButton(
            '',
            onTap: onBackspace,
            child: const Icon(Icons.backspace_outlined, size: 22),
          ),
        ]),
      ],
    );
  }
}

/// Shown when a gated section already has a PIN - person must enter it
/// (or use biometrics) to proceed.
class PinEntryScreen extends StatefulWidget {
  final String sectionName;
  const PinEntryScreen({super.key, required this.sectionName});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  static const int _pinLength = 4;
  String _entered = '';
  String? _error;
  bool _biometricAvailable = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final pinService = context.read<PinService>();
    final enabled = await pinService.isBiometricEnabled();
    final available = enabled && await pinService.biometricAvailable();
    if (mounted) {
      setState(() => _biometricAvailable = available);
      if (available) _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    final pinService = context.read<PinService>();
    final ok = await pinService.tryBiometricUnlock();
    if (ok && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _onDigit(String digit) {
    if (_entered.length >= _pinLength || _checking) return;
    setState(() {
      _entered += digit;
      _error = null;
    });
    if (_entered.length == _pinLength) _submit();
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _submit() async {
    setState(() => _checking = true);
    final pinService = context.read<PinService>();
    final ok = await pinService.verifyPin(_entered);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _checking = false;
        _entered = '';
        _error = 'Incorrect PIN, try again';
      });
    }
  }

  Future<void> _forgotPin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset PIN?'),
        content: const Text(
          'This removes the current PIN. You can set a new one right after, '
          'but this does not recover any data - it just resets the lock.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final pinService = context.read<PinService>();
    await pinService.removePin();
    if (!mounted) return;
    final created = await Navigator.of(context).pushReplacement<bool, void>(
      MaterialPageRoute(
        builder: (_) => PinSetupScreen(sectionName: widget.sectionName),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(created == true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 42, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.sectionName} is locked',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter your PIN to continue',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  _PinDots(
                    length: _pinLength,
                    filled: _entered.length,
                    color: _error != null ? scheme.error : scheme.primary,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 20,
                    child: Text(
                      _error ?? '',
                      style: TextStyle(color: scheme.error, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Keypad(
                    onDigit: _onDigit,
                    onBackspace: _onBackspace,
                    onBiometric: _biometricAvailable ? _tryBiometric : null,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _forgotPin,
                    child: const Text('Forgot PIN?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown the first time a person locks a section (no PIN set yet) and from
/// Settings when changing the PIN.
class PinSetupScreen extends StatefulWidget {
  final String sectionName;
  const PinSetupScreen({super.key, required this.sectionName});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  static const int _pinLength = 4;
  String _first = '';
  String _entered = '';
  bool _confirming = false;
  String? _error;

  void _onDigit(String digit) {
    if (_entered.length >= _pinLength) return;
    setState(() {
      _entered += digit;
      _error = null;
    });
    if (_entered.length == _pinLength) _handleComplete();
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _handleComplete() async {
    if (!_confirming) {
      setState(() {
        _first = _entered;
        _entered = '';
        _confirming = true;
      });
      return;
    }

    if (_entered == _first) {
      final pinService = context.read<PinService>();
      await pinService.setPin(_entered);

      final biometricAvailable = await pinService.biometricAvailable();
      bool wantsBiometric = false;
      if (biometricAvailable && mounted) {
        wantsBiometric =
            await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Use biometric unlock too?'),
                content: const Text(
                  'You can unlock locked sections with your fingerprint or '
                  'face instead of typing the PIN every time.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Not now'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Enable'),
                  ),
                ],
              ),
            ) ??
            false;
      }
      await pinService.setBiometricEnabled(wantsBiometric);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _entered = '';
        _confirming = false;
        _first = '';
        _error = "PINs didn't match - start again";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 42,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _confirming
                        ? 'Confirm your PIN'
                        : 'Set a PIN for ${widget.sectionName}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This PIN will also protect Money, Schedule, and '
                    'Projects together.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  _PinDots(
                    length: _pinLength,
                    filled: _entered.length,
                    color: _error != null ? scheme.error : scheme.primary,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 20,
                    child: Text(
                      _error ?? '',
                      style: TextStyle(color: scheme.error, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Keypad(onDigit: _onDigit, onBackspace: _onBackspace),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
