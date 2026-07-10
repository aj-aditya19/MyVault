import 'dart:convert';
import 'dart:io';
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
    return File('${dir.path}/$boxName.box.txt');
  }

  static Future<T> read<T>(String boxName, T fallback) async {
    try {
      final file = await _fileFor(boxName);
      if (!await file.exists()) return fallback;

      final content = await file.readAsString();
      if (content.isEmpty) return fallback;

      try {
        final decrypted = decryptData(content);
        return jsonDecode(decrypted) as T;
      } catch (_) {
        final decoded = jsonDecode(content) as T;
        await write(boxName, decoded);
        return decoded;
      }
    } catch (_) {
      return fallback;
    }
  }

  static Future<void> write(String boxName, dynamic value) async {
    final file = await _fileFor(boxName);
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    await file.writeAsString(encryptData(jsonEncode(value)));
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
