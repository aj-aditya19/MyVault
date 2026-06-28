import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/Other/license_screen.dart';
import 'package:app/core/services/notification_service.dart';
import 'package:app/core/services/pin_service.dart';
import 'package:app/core/widgets/pin_gate.dart';

class SettingScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const SettingScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool notificationsEnabled = true;
  bool compactCards = false;

  bool _hasPin = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadSecurityState();
  }

  Future<void> _loadSecurityState() async {
    final pinService = context.read<PinService>();
    final hasPin = await pinService.hasPin();
    final bioEnabled = await pinService.isBiometricEnabled();
    final bioAvailable = await pinService.biometricAvailable();
    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
      _biometricEnabled = bioEnabled;
      _biometricAvailable = bioAvailable;
    });
  }

  Future<void> _changePin() async {
    final pinService = context.read<PinService>();
    if (_hasPin) {
      final verified = await ensureSectionUnlocked(context, sectionName: 'Settings');
      if (!verified) return;
      // Force a fresh PIN setup even though already unlocked this session.
      await pinService.removePin();
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PinSetupScreen(sectionName: 'Money, Schedule & Projects'),
        fullscreenDialog: true,
      ),
    );
    _loadSecurityState();
  }

  Future<void> _removePin() async {
    final verified = await ensureSectionUnlocked(context, sectionName: 'Settings');
    if (!verified) return;
    final pinService = context.read<PinService>();
    await pinService.removePin();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN removed. Locked sections are now open.')),
    );
    _loadSecurityState();
  }

  Future<void> _lockNow() async {
    context.read<PinService>().lockNow();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Money, Schedule, and Projects are locked again.')),
    );
  }

  Future<void> _toggleBiometric(bool value) async {
    final pinService = context.read<PinService>();
    await pinService.setBiometricEnabled(value);
    setState(() => _biometricEnabled = value);
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => notificationsEnabled = value);
    if (value) {
      await NotificationService.instance.init();
      await NotificationService.instance.scheduleDailySummary(
        body: 'Check your tasks and schedule for today in MyVault.',
      );
    } else {
      await NotificationService.instance.cancel(NotificationService.dailySummaryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Preferences",
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.68),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.dark_mode),
                  title: const Text("Dark Mode"),
                  subtitle: const Text("Use dark color palette"),
                  value: widget.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    widget.onThemeModeChanged(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.notifications),
                  title: const Text("Daily summary notification"),
                  subtitle: const Text("A reminder every day at 8:00 AM"),
                  value: notificationsEnabled,
                  onChanged: _toggleNotifications,
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.view_compact_alt_outlined),
                  title: const Text("Compact Cards"),
                  subtitle: const Text("Show denser list items"),
                  value: compactCards,
                  onChanged: (value) {
                    setState(() {
                      compactCards = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            "Security & App",
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: scheme.surface.withValues(alpha: 0.72),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.pin_outlined),
                  title: Text(_hasPin ? "Change PIN" : "Set up a PIN"),
                  subtitle: const Text("Protects Money, Schedule & Projects"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _changePin,
                ),
                if (_hasPin) ...[
                  const Divider(height: 1),
                  if (_biometricAvailable)
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.fingerprint_rounded),
                      title: const Text("Biometric unlock"),
                      subtitle: const Text("Use fingerprint or face instead of the PIN"),
                      value: _biometricEnabled,
                      onChanged: _toggleBiometric,
                    ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_clock_outlined),
                    title: const Text("Lock now"),
                    subtitle: const Text("Re-lock Money, Schedule & Projects"),
                    onTap: _lockNow,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.lock_open_outlined, color: scheme.error),
                    title: Text("Remove PIN", style: TextStyle(color: scheme.error)),
                    onTap: _removePin,
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text("About App"),
                  subtitle: const Text("MyVault 1.0.0"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'MyVault',
                      applicationVersion: '1.0.0',
                      applicationLegalese:
                          'Personal organizer and tracker app.',
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text("Licenses"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LicenseScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
