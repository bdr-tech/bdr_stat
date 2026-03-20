import 'package:flutter_test/flutter_test.dart';
import 'package:bdr_tournament_recorder/presentation/providers/network_status_provider.dart';

void main() {
  group('NetworkStatus enum', () {
    test('should have correct values', () {
      expect(NetworkStatus.values.length, 3);
      expect(NetworkStatus.connected.index, 0);
      expect(NetworkStatus.disconnected.index, 1);
      expect(NetworkStatus.checking.index, 2);
    });
  });

  group('SyncStatus enum', () {
    test('should have correct values', () {
      expect(SyncStatus.values.length, 5);
      expect(SyncStatus.idle.index, 0);
      expect(SyncStatus.syncing.index, 1);
      expect(SyncStatus.success.index, 2);
      expect(SyncStatus.failed.index, 3);
      expect(SyncStatus.pending.index, 4);
    });
  });

  group('NetworkState', () {
    test('should create with default values', () {
      const state = NetworkState();
      expect(state.networkStatus, NetworkStatus.checking);
      expect(state.syncStatus, SyncStatus.idle);
      expect(state.pendingSyncCount, 0);
      expect(state.lastError, isNull);
      expect(state.lastChecked, isNull);
    });

    test('should create with custom values', () {
      final now = DateTime.now();
      final state = NetworkState(
        networkStatus: NetworkStatus.connected,
        syncStatus: SyncStatus.syncing,
        pendingSyncCount: 5,
        lastError: 'Test error',
        lastChecked: now,
      );
      expect(state.networkStatus, NetworkStatus.connected);
      expect(state.syncStatus, SyncStatus.syncing);
      expect(state.pendingSyncCount, 5);
      expect(state.lastError, 'Test error');
      expect(state.lastChecked, now);
    });

    group('copyWith', () {
      test('should copy with new networkStatus', () {
        const state = NetworkState(networkStatus: NetworkStatus.disconnected);
        final newState = state.copyWith(networkStatus: NetworkStatus.connected);
        expect(newState.networkStatus, NetworkStatus.connected);
        expect(newState.syncStatus, state.syncStatus);
      });

      test('should copy with new syncStatus', () {
        const state = NetworkState();
        final newState = state.copyWith(syncStatus: SyncStatus.success);
        expect(newState.syncStatus, SyncStatus.success);
        expect(newState.networkStatus, state.networkStatus);
      });

      test('should copy with new pendingSyncCount', () {
        const state = NetworkState();
        final newState = state.copyWith(pendingSyncCount: 10);
        expect(newState.pendingSyncCount, 10);
      });

      test('should copy with new lastError', () {
        const state = NetworkState(lastError: 'old error');
        final newState = state.copyWith(lastError: 'new error');
        expect(newState.lastError, 'new error');
      });

      test('should clear lastError when passed null explicitly', () {
        const state = NetworkState(lastError: 'old error');
        // copyWith clears lastError when null is passed
        final newState = state.copyWith(lastError: null);
        expect(newState.lastError, isNull);
      });

      test('should copy with new lastChecked', () {
        final now = DateTime.now();
        const state = NetworkState();
        final newState = state.copyWith(lastChecked: now);
        expect(newState.lastChecked, now);
      });
    });

    group('isOnline', () {
      test('should return true when connected', () {
        const state = NetworkState(networkStatus: NetworkStatus.connected);
        expect(state.isOnline, true);
      });

      test('should return false when disconnected', () {
        const state = NetworkState(networkStatus: NetworkStatus.disconnected);
        expect(state.isOnline, false);
      });

      test('should return false when checking', () {
        const state = NetworkState(networkStatus: NetworkStatus.checking);
        expect(state.isOnline, false);
      });
    });

    group('isOffline', () {
      test('should return true when disconnected', () {
        const state = NetworkState(networkStatus: NetworkStatus.disconnected);
        expect(state.isOffline, true);
      });

      test('should return false when connected', () {
        const state = NetworkState(networkStatus: NetworkStatus.connected);
        expect(state.isOffline, false);
      });

      test('should return false when checking', () {
        const state = NetworkState(networkStatus: NetworkStatus.checking);
        expect(state.isOffline, false);
      });
    });

    group('hasPendingSync', () {
      test('should return true when pendingSyncCount > 0', () {
        const state = NetworkState(pendingSyncCount: 1);
        expect(state.hasPendingSync, true);
      });

      test('should return false when pendingSyncCount == 0', () {
        const state = NetworkState(pendingSyncCount: 0);
        expect(state.hasPendingSync, false);
      });
    });
  });
}
