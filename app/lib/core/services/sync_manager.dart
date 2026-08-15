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

    print('SYNC: initialize() started');

    try {
      print('SYNC: Firebase.apps = ${Firebase.apps.length}');

      if (Firebase.apps.isEmpty) {
        print('SYNC: Calling Firebase.initializeApp()');

        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        print('SYNC: Firebase.initializeApp() completed');
      }

      _firebaseReady = true;
      print('SYNC: Firebase READY = $_firebaseReady');
    } catch (e, stackTrace) {
      print('SYNC: Firebase initialization FAILED');
      print('SYNC ERROR: $e');
      print(stackTrace);

      _firebaseReady = false;
    }

    _initialized = true;
    print('SYNC: initialize() completed, ready=$_firebaseReady');

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

      print('Login successful.');
      return true;
    } on FirebaseAuthException catch (e) {
      print('Firebase Login Error');
      print('Code: ${e.code}');
      print('Message: ${e.message}');
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

      print('Account created successfully.');
      return true;
    } on FirebaseAuthException catch (e) {
      print('Firebase Signup Error');
      print('Code: ${e.code}');
      print('Message: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected Signup Error: $e');
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

  static Map<String, dynamic> createSyncEnvelope(
    dynamic value, {
    String? userId,
    int? updatedAt,
  }) {
    return {
      'value': value,
      'updatedAt': updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      'updatedBy': userId ?? currentUserId ?? 'local-device',
    };
  }

  static Future<void> syncLocalBox(String boxName, dynamic value) async {
    if (!_initialized || currentUserId == null) return;

    final payload = createSyncEnvelope(value, userId: currentUserId);

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
          .set(envelope, SetOptions(merge: true));
    } catch (e) {
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

  static bool _isEqual(dynamic a, dynamic b) {
    if (a is Map && b is Map) {
      final left = Map<String, dynamic>.from(a);
      final right = Map<String, dynamic>.from(b);
      return left.length == right.length &&
          left.keys.every(
            (key) => right.containsKey(key) && _isEqual(left[key], right[key]),
          );
    }
    if (a is List && b is List) {
      return a.length == b.length &&
          List.generate(
            a.length,
            (index) => _isEqual(a[index], b[index]),
          ).every((item) => item);
    }
    return a == b;
  }
}
