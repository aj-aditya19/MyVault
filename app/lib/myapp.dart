import 'package:flutter/material.dart';
import 'package:app/Screens/Auth/auth_screen.dart';
import 'package:app/Screens/home_screen.dart';
import 'package:app/core/services/storage_service.dart';
import 'package:app/core/services/sync_manager.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isBootstrapping = true;
  bool _showAuthGate = false;

  @override
  void initState() {
    super.initState();
    _bootstrapAppEntry();
  }

  Future<void> _bootstrapAppEntry() async {
    final session = await StorageService.readMap('app_session');
    final hasSeenEntryGate = session['entryChoiceMade'] == true;
    final shouldShowAuth = !SyncManager.isSignedIn && !hasSeenEntryGate;

    if (!mounted) return;
    setState(() {
      _showAuthGate = shouldShowAuth;
      _isBootstrapping = false;
    });
  }

  Future<void> _saveEntryChoice({required bool usedWithoutAccount}) async {
    final session = await StorageService.readMap('app_session');
    session['entryChoiceMade'] = true;
    session['usedWithoutAccount'] = usedWithoutAccount;
    session['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    await StorageService.write('app_session', session);
  }

  Future<void> _completeLoginFlow() async {
    await _saveEntryChoice(usedWithoutAccount: false);
    if (!mounted) return;
    setState(() {
      _showAuthGate = false;
    });
  }

  Future<void> _continueWithoutAccount() async {
    await _saveEntryChoice(usedWithoutAccount: true);
    if (!mounted) return;
    setState(() {
      _showAuthGate = false;
    });
  }

  void _openLoginFromHome() {
    setState(() {
      _showAuthGate = true;
    });
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isBootstrapping) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: _themeMode,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: _showAuthGate
          ? AuthScreen(
              themeMode: _themeMode,
              onThemeModeChanged: _setThemeMode,
              allowSkip: true,
              onAuthSuccess: _completeLoginFlow,
              onSkip: _continueWithoutAccount,
            )
          : HomeScreen(
              themeMode: _themeMode,
              onThemeModeChanged: _setThemeMode,
              isSignedIn: SyncManager.isSignedIn,
              onLoginRequested: _openLoginFromHome,
            ),
    );
  }
}
