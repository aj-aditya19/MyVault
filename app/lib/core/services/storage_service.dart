import 'dart:convert';
import 'dart:io';

import 'package:app/core/services/sync_manager.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';

class StorageService {
  StorageService._();

  static final encrypt.Key _key = encrypt.Key.fromUtf8(
    'my 32 length key................',
  );
  static final encrypt.Encrypter _encrypter = encrypt.Encrypter(
    encrypt.AES(_key),
  );

  static String encryptData(String data) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(data, iv: iv);
    final combined = iv.bytes + encrypted.bytes;
    return base64Encode(combined);
  }

  static String decryptData(String base64Data) {
    final combined = base64Decode(base64Data);
    final iv = encrypt.IV(combined.sublist(0, 16));
    final encryptedBytes = combined.sublist(16);
    final encrypted = encrypt.Encrypted(encryptedBytes);
    return _encrypter.decrypt(encrypted, iv: iv);
  }

  static Future<File> _fileFor(String boxName) async {
    final dir = await getApplicationDocumentsDirectory();
    final myVaultDir = Directory('${dir.path}/MyVault');
    await myVaultDir.create(recursive: true);
    return File('${myVaultDir.path}/$boxName.box.txt');
  }

  static dynamic normalizeStoredValue(
    dynamic decoded, {
    required dynamic fallback,
  }) {
    if (decoded == null) return fallback;

    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      if (map.containsKey('value')) {
        return map['value'] ?? fallback;
      }
      if (map.containsKey('updatedAt') || map.containsKey('updatedBy')) {
        return map['value'] ?? fallback;
      }
      return map;
    }

    if (decoded is List) return decoded;
    return fallback;
  }

  static Future<T> read<T>(String boxName, T fallback) async {
    try {
      final file = await _fileFor(boxName);

      Map<String, dynamic> localEnvelope = {
        'value': fallback,
        'updatedAt': 0,
        'updatedBy': 'local-device',
      };

      // -----------------------------
      // 1. Read local data
      // -----------------------------
      if (await file.exists()) {
        final content = await file.readAsString();

        if (content.isNotEmpty) {
          try {
            final decrypted = decryptData(content);
            final decoded = jsonDecode(decrypted);

            if (decoded is Map && decoded.containsKey('value')) {
              // IMPORTANT:
              // Preserve updatedAt and updatedBy.
              localEnvelope = Map<String, dynamic>.from(decoded);
            } else {
              localEnvelope = {
                'value': normalizeStoredValue(decoded, fallback: fallback),
                'updatedAt': 0,
                'updatedBy': 'local-device',
              };
            }
          } catch (_) {
            try {
              final decoded = jsonDecode(content);

              if (decoded is Map && decoded.containsKey('value')) {
                localEnvelope = Map<String, dynamic>.from(decoded);
              } else {
                localEnvelope = {
                  'value': normalizeStoredValue(decoded, fallback: fallback),
                  'updatedAt': 0,
                  'updatedBy': 'local-device',
                };
              }

              await write(boxName, localEnvelope['value'] ?? fallback);
            } catch (_) {
              localEnvelope = {
                'value': fallback,
                'updatedAt': 0,
                'updatedBy': 'local-device',
              };
            }
          }
        }
      }

      // -----------------------------
      // 2. Compare with Firebase
      // -----------------------------
      if (SyncManager.isSignedIn) {
        final remoteSnapshot = await SyncManager.pullRemoteSnapshot(boxName);

        if (remoteSnapshot != null) {
          final merged = SyncManager.resolveMerge(
            localEnvelope,
            remoteSnapshot,
          );

          if (merged is Map) {
            final mergedMap = Map<String, dynamic>.from(merged);

            final mergedValue = mergedMap['value'] ?? fallback;

            await _writeLocalOnly(
              boxName,
              mergedValue,
              updatedAt: _updatedAtOf(mergedMap),
              updatedBy: mergedMap['updatedBy']?.toString(),
            );

            return mergedValue as T;
          }
        }
      }

      // -----------------------------
      // 3. Return local data
      // -----------------------------
      return (localEnvelope['value'] ?? fallback) as T;
    } catch (_) {
      return fallback;
    }
  }

  static Future<void> saveRemoteBox(
    String boxName,
    Map<String, dynamic> envelope,
  ) async {
    try {
      final value = envelope['value'];

      final updatedAt = envelope['updatedAt'];
      final updatedBy = envelope['updatedBy'];

      final file = await _fileFor(boxName);

      final localEnvelope = {
        'value': value,
        'updatedAt': updatedAt ?? 0,
        'updatedBy': updatedBy ?? 'remote-device',
      };

      await file.writeAsString(encryptData(jsonEncode(localEnvelope)));
    } catch (_) {
      // Ignore individual box failures.
    }
  }

  static int _updatedAtOf(Map<String, dynamic> envelope) {
    final value = envelope['updatedAt'];

    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;

    return 0;
  }

  static Future<void> _writeLocalOnly(
    String boxName,
    dynamic value, {
    required int updatedAt,
    String? updatedBy,
  }) async {
    final file = await _fileFor(boxName);

    final envelope = {
      'value': value,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy ?? 'remote-device',
    };

    await file.writeAsString(encryptData(jsonEncode(envelope)));
  }

  static Future<void> write(String boxName, dynamic value) async {
    final file = await _fileFor(boxName);
    if (!await file.exists()) {
      await file.create(recursive: true);
    }

    final envelope = SyncManager.createSyncEnvelope(
      value,
      userId: SyncManager.currentUserId,
    );

    await file.writeAsString(encryptData(jsonEncode(envelope)));
    await SyncManager.syncLocalBox(boxName, value);
  }

  static Future<void> syncAllLocalBoxesToCloud() async {
    if (!SyncManager.isSignedIn) return;

    final dir = await getApplicationDocumentsDirectory();
    final myVaultDir = Directory('${dir.path}/MyVault');
    if (!await myVaultDir.exists()) return;

    final files = myVaultDir.listSync().whereType<File>().where(
      (file) => file.path.endsWith('.box.txt'),
    );

    for (final file in files) {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final boxName = fileName.substring(
        0,
        fileName.length - '.box.txt'.length,
      );

      try {
        final content = await file.readAsString();
        if (content.isEmpty) continue;

        dynamic decoded;
        try {
          decoded = jsonDecode(decryptData(content));
        } catch (_) {
          decoded = jsonDecode(content);
        }

        final normalized = normalizeStoredValue(decoded, fallback: decoded);
        await SyncManager.syncLocalBox(boxName, normalized);
      } catch (_) {
        // Continue syncing other boxes even if one file is unreadable.
      }
    }
  }

  static Future<void> syncAllBoxes() async {
    if (!SyncManager.isSignedIn) return;

    try {
      final remoteBoxes = await SyncManager.getAllRemoteBoxes();

      for (final entry in remoteBoxes.entries) {
        await _mergeRemoteBox(entry.key, entry.value);
      }

      await syncAllLocalBoxesToCloud();
    } catch (e) {
      print('Full sync failed: $e');
    }
  }

  static Future<void> _mergeRemoteBox(
    String boxName,
    Map<String, dynamic> remoteEnvelope,
  ) async {
    try {
      final file = await _fileFor(boxName);

      Map<String, dynamic>? localEnvelope;

      if (await file.exists()) {
        final content = await file.readAsString();

        if (content.isNotEmpty) {
          try {
            final decrypted = decryptData(content);
            final decoded = jsonDecode(decrypted);

            if (decoded is Map) {
              localEnvelope = Map<String, dynamic>.from(decoded);
            }
          } catch (_) {}
        }
      }

      // No local copy → download Firebase version.
      if (localEnvelope == null) {
        await file.writeAsString(encryptData(jsonEncode(remoteEnvelope)));
        return;
      }

      final merged = SyncManager.resolveMerge(localEnvelope, remoteEnvelope);

      if (merged is Map) {
        final mergedMap = Map<String, dynamic>.from(merged);

        await file.writeAsString(encryptData(jsonEncode(mergedMap)));
      }
    } catch (_) {
      // Ignore individual box errors.
    }
  }

  static Future<List<Map<String, dynamic>>> readList(String boxName) async {
    final raw = await read<dynamic>(boxName, <dynamic>[]);
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<Map<String, dynamic>> readMap(String boxName) async {
    final raw = await read<dynamic>(boxName, <String, dynamic>{});
    if (raw is! Map) return {};
    return Map<String, dynamic>.from(raw);
  }

  static Future<dynamic> readLegacyFile(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      if (content.isEmpty) return null;
      try {
        return jsonDecode(decryptData(content));
      } catch (_) {
        return jsonDecode(content);
      }
    } catch (_) {
      return null;
    }
  }
}
