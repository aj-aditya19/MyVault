import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/sync_manager.dart';

void main() {
  group('SyncManager merge logic', () {
    test('prefers the newer value when local and remote timestamps differ', () {
      final local = {
        'items': ['local'],
        'updatedAt': 1000,
      };

      final remote = {
        'items': ['remote'],
        'updatedAt': 2000,
      };

      final merged = SyncManager.resolveMerge(local, remote);

      expect(merged['items'], ['remote']);
      expect(merged['updatedAt'], 2000);
    });

    test('keeps local data when it is newer than the cloud snapshot', () {
      final local = {
        'items': ['latest-local'],
        'updatedAt': 5000,
      };

      final remote = {
        'items': ['older-cloud'],
        'updatedAt': 2000,
      };

      final merged = SyncManager.resolveMerge(local, remote);

      expect(merged['items'], ['latest-local']);
      expect(merged['updatedAt'], 5000);
    });
  });
}
