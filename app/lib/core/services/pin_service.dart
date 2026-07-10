import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class PinService extends ChangeNotifier {
  static const _pinKey = 'myvault_pin_v1';
  static const _biometricKey = 'myvault_biometric_enabled_v1';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isUnlocked = false;
  bool get isUnlocked => _isUnlocked;

  Future<bool> hasPin() async {
    final value = await _secureStorage.read(key: _pinKey);
    return value != null && value.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    await _secureStorage.write(key: _pinKey, value: pin);
    _isUnlocked = true;
    notifyListeners();
  }

  Future<void> removePin() async {
    await _secureStorage.delete(key: _pinKey);
    _isUnlocked = false;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _secureStorage.read(key: _pinKey);
    final ok = stored != null && stored == pin;
    if (ok) {
      _isUnlocked = true;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricKey);
    return value == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _biometricKey,
      value: enabled ? 'true' : 'false',
    );
  }

  Future<bool> biometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      return canCheck || supported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> tryBiometricUnlock() async {
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Unlock this section of MyVault',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (ok) {
        _isUnlocked = true;
        notifyListeners();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  void lockNow() {
    _isUnlocked = false;
    notifyListeners();
  }
}
