import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Reads motivational messages from assets/data/motivation_messages.json
/// and hands one back at random.
///
/// Right now the JSON only has one message in it, so this will always
/// return that one — but the function itself already picks randomly, so
/// the moment more lines are added to the JSON file, every caller
/// automatically starts getting variety with zero code changes.
class MotivationService {
  MotivationService._();

  static const String _assetPath = 'assets/data/motivation_messages.json';

  // Used only if the asset is missing or fails to parse (e.g. it hasn't
  // been added to pubspec.yaml's `assets:` list yet), so the app never
  // crashes or shows an empty notification.
  static const List<String> _fallback = [
    'Small steps count. Set one task and one budget for today, then make it happen.',
  ];

  static List<String>? _cache;
  static final Random _random = Random();

  static Future<List<String>> _loadMessages() async {
    if (_cache != null) return _cache!;

    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw);
      final list = (decoded is Map ? decoded['messages'] : decoded) as List?;
      final messages = (list ?? [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      _cache = messages.isEmpty ? _fallback : messages;
    } catch (e) {
      debugPrint('MotivationService: failed to load $_assetPath: $e');
      _cache = _fallback;
    }

    return _cache!;
  }

  /// Returns one random motivational message.
  static Future<String> getRandomMessage() async {
    final messages = await _loadMessages();
    return messages[_random.nextInt(messages.length)];
  }

  /// Call this if messages are edited/added during the same app session
  /// (normally not needed — the JSON is only read at startup).
  static void clearCache() => _cache = null;
}
