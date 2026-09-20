import 'package:app/core/services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app/firebase_options.dart';

class SyncManager {
  SyncManager._();

  static final Connectivity _connectivity = Connectivity();

  static bool _initialized = false;
  static bool _firebaseReady = false;

  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      _firebaseReady = true;
    } catch (e) {
      print('SYNC: Firebase initialization failed: $e');
      _firebaseReady = false;
    }

    _initialized = true;

    _connectivity.onConnectivityChanged.listen((results) async {
      final hasConnection = results.any(
        (result) => result != ConnectivityResult.none,
      );

      if (_firebaseReady && hasConnection && _auth.currentUser != null) {
        await syncPendingChanges();
      }
    });
  }

  static Stream<User?> authStateChanges() {
    if (!_firebaseReady) {
      return Stream<User?>.value(null);
    }
    return _auth.authStateChanges();
  }

  static Future<bool> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    if (!_firebaseReady) {
      return false;
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      print('Firebase Login Error [${e.code}]: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected Login Error: $e');
      return false;
    }
  }

  static Future<bool> createUserWithEmailAndPassword(
    String email,
    String password, {
    String? name,
    String? phoneNumber,
  }) async {
    if (!_firebaseReady) {
      print('Firebase is not initialized.');
      return false;
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      final normalizedName = name?.trim();
      final normalizedPhone = phoneNumber?.trim();

      if (user != null) {
        if (normalizedName != null && normalizedName.isNotEmpty) {
          await user.updateDisplayName(normalizedName);
        }

        await _firestore.collection('users').doc(user.uid).set({
          'name': (normalizedName != null && normalizedName.isNotEmpty)
              ? normalizedName
              : user.displayName,
          'email': user.email,
          'phoneNumber': (normalizedPhone != null && normalizedPhone.isNotEmpty)
              ? normalizedPhone
              : null,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return true;
    } on FirebaseAuthException catch (e) {
      print('Firebase Signup Error [${e.code}]: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected Signup Error: $e');
      return false;
    }
  }

  /// Sends the user a secure password-reset link through Firebase's own
  /// mail system. This is deliberately NOT a custom OTP-over-SMTP flow —
  /// that would require embedding real email credentials inside the app,
  /// which anyone could pull back out of the compiled APK. Firebase handles
  /// the actual sending on its own servers, so no secret ever needs to live
  /// on the client.
  static Future<bool> sendPasswordResetEmail(String email) async {
    if (!_firebaseReady) return false;

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      print('Password reset error [${e.code}]: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected password reset error: $e');
      return false;
    }
  }

  static Future<void> signOut() async {
    if (!_firebaseReady) return;
    await _auth.signOut();
  }

  static Future<Map<String, Map<String, dynamic>>> getAllRemoteBoxes() async {
    if (!_initialized || currentUserId == null) {
      return {};
    }

    try {
      final snapshot = await _firestore
          .collection('userData')
          .doc(currentUserId)
          .collection('boxes')
          .get();

      final result = <String, Map<String, dynamic>>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (data.isNotEmpty) {
          result[doc.id] = Map<String, dynamic>.from(data);
        }
      }

      return result;
    } catch (_) {
      return {};
    }
  }

  static String? get currentUserId {
    if (!_firebaseReady) return null;
    return _auth.currentUser?.uid;
  }

  static bool get isSignedIn {
    if (!_firebaseReady) return false;
    return _auth.currentUser != null;
  }

  static Future<void> syncPendingChanges() async {
    if (!_initialized || currentUserId == null) return;

    try {
      await StorageService.syncAllBoxes();
    } catch (e) {
      print('Pending sync failed: $e');
    }
  }

  /// Pulls the latest remote data and pushes any local changes. Wire this
  /// into every moment we get a fresh chance to sync — live connectivity
  /// changes (see the listener above) and app resume (see myapp.dart) —
  /// because the connectivity stream alone can miss a reconnect on some
  /// devices, which is what let offline edits sit unsynced before.
  static Future<void> forceSyncNow() async {
    if (!_firebaseReady || currentUserId == null) return;
    await syncPendingChanges();
  }

  static Map<String, dynamic> createSyncEnvelope(
    dynamic value, {
    String? userId,
    int? updatedAt,
    String? updatedBy,
  }) {
    return {
      'value': value,
      'updatedAt': updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      'updatedBy': updatedBy ?? userId ?? currentUserId ?? 'local-device',
    };
  }

  /// Pushes [value] up to this user's cloud copy of [boxName]. Pass through
  /// the box's real [updatedAt]/[updatedBy] when re-pushing an existing
  /// envelope (e.g. during a full resync) — otherwise every sync stamps a
  /// fresh "now", which makes an untouched box look freshly edited and
  /// breaks last-write-wins comparisons against other devices.
  static Future<void> syncLocalBox(
    String boxName,
    dynamic value, {
    int? updatedAt,
    String? updatedBy,
  }) async {
    if (!_initialized || currentUserId == null) return;

    final payload = createSyncEnvelope(
      value,
      userId: currentUserId,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );

    await syncEnvelope(boxName, payload);
  }

  static Future<void> pullAllRemoteBoxesToLocal() async {
    if (!_initialized || currentUserId == null) return;

    try {
      final snapshot = await _firestore
          .collection('userData')
          .doc(currentUserId)
          .collection('boxes')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data.isEmpty) continue;

        await StorageService.saveRemoteBox(
          doc.id,
          Map<String, dynamic>.from(data),
        );
      }
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> pullRemoteSnapshot(
    String boxName,
  ) async {
    if (!_initialized || currentUserId == null) return null;

    try {
      final doc = await _firestore
          .collection('userData')
          .doc(currentUserId)
          .collection('boxes')
          .doc(boxName)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return Map<String, dynamic>.from(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  static Future<dynamic> pullAndMergeBox(
    String boxName,
    dynamic localValue,
  ) async {
    final remoteValue = await pullRemoteSnapshot(boxName);
    if (remoteValue == null) return localValue;

    final merged = resolveMerge(localValue, remoteValue);
    if (merged == null) return localValue;
    return merged;
  }

  static dynamic resolveMerge(dynamic localValue, dynamic remoteValue) {
    if (localValue == null) return remoteValue;
    if (remoteValue == null) return localValue;

    if (localValue is Map && remoteValue is Map) {
      final localMap = Map<String, dynamic>.from(localValue);
      final remoteMap = Map<String, dynamic>.from(remoteValue);

      final localUpdatedAt = _readUpdatedAt(localMap) ?? 0;
      final remoteUpdatedAt = _readUpdatedAt(remoteMap) ?? 0;

      if (remoteUpdatedAt > localUpdatedAt) {
        return remoteMap;
      }

      if (localUpdatedAt > remoteUpdatedAt) {
        return localMap;
      }

      return remoteMap;
    }

    return remoteValue;
  }

  /// Pushes one envelope to Firestore. Bounded with a timeout so that a
  /// write made while offline doesn't hang forever — Firestore normally
  /// keeps such a Future pending until it reconnects, which is fine when
  /// this is fired in the background (see StorageService.write) but we
  /// still want it to fail fast and get retried by the next resync rather
  /// than leaking an unresolved Future indefinitely.
  static Future<void> syncEnvelope(
    String boxName,
    Map<String, dynamic> envelope,
  ) async {
    if (!_initialized || currentUserId == null) return;

    try {
      await _firestore
          .collection('userData')
          .doc(currentUserId)
          .collection('boxes')
          .doc(boxName)
          .set(envelope, SetOptions(merge: true))
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      // Offline, or timed out waiting for a connection — that's fine, the
      // local copy already has this change and the next resync (live
      // connectivity change or app resume) will push it again.
      print('Sync envelope failed for $boxName: $e');
    }
  }

  static int? _readUpdatedAt(dynamic value) {
    if (value is! Map) return null;

    final map = Map<String, dynamic>.from(value);
    final updatedAt = map['updatedAt'];
    if (updatedAt is int) return updatedAt;
    if (updatedAt is num) return updatedAt.toInt();
    if (updatedAt is String) {
      final parsed = int.tryParse(updatedAt);
      if (parsed != null) return parsed;
    }
    return null;
  }
}
