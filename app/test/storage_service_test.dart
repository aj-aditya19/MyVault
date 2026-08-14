import 'package:app/core/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StorageService payload normalization', () {
    test('accepts raw list payloads without an envelope', () {
      final value = StorageService.normalizeStoredValue([
        {'id': '1', 'subject': 'Math'},
      ], fallback: <dynamic>[]);

      expect(value, isA<List>());
      expect(value.length, 1);
      expect((value as List).first['subject'], 'Math');
    });

    test('accepts raw map payloads without an envelope', () {
      final value = StorageService.normalizeStoredValue({
        '2026-01-01': [
          {'id': '1'},
        ],
      }, fallback: <String, dynamic>{});

      expect(value, isA<Map>());
      expect((value as Map)['2026-01-01'], isA<List>());
    });

    test('unwraps envelope payloads that include value metadata', () {
      final value = StorageService.normalizeStoredValue({
        'value': ['hello'],
        'updatedAt': 123,
        'updatedBy': 'user-1',
      }, fallback: <dynamic>[]);

      expect(value, ['hello']);
    });
  });
}
