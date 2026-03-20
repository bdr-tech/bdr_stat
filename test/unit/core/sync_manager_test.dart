import 'package:flutter_test/flutter_test.dart';
import 'package:bdr_tournament_recorder/core/utils/sync_manager.dart';

void main() {
  group('SyncResultData', () {
    test('should create with success=true and data', () {
      final now = DateTime.now();
      final result = SyncResultData(
        success: true,
        serverMatchId: 123,
        playerCount: 10,
        playByPlayCount: 50,
        careerStatsUpdated: true,
        syncedAt: now,
      );

      expect(result.success, true);
      expect(result.serverMatchId, 123);
      expect(result.playerCount, 10);
      expect(result.playByPlayCount, 50);
      expect(result.careerStatsUpdated, true);
      expect(result.syncedAt, now);
      expect(result.errorMessage, isNull);
    });

    test('should create with success=false and error', () {
      const result = SyncResultData(
        success: false,
        errorMessage: 'Network error occurred',
      );

      expect(result.success, false);
      expect(result.errorMessage, 'Network error occurred');
      expect(result.serverMatchId, isNull);
      expect(result.playerCount, isNull);
      expect(result.playByPlayCount, isNull);
      expect(result.careerStatsUpdated, isNull);
      expect(result.syncedAt, isNull);
    });

    test('should create with minimal data', () {
      const result = SyncResultData(success: true);

      expect(result.success, true);
      expect(result.errorMessage, isNull);
      expect(result.serverMatchId, isNull);
      expect(result.playerCount, isNull);
      expect(result.playByPlayCount, isNull);
      expect(result.careerStatsUpdated, isNull);
      expect(result.syncedAt, isNull);
    });

    test('should allow all fields to be set', () {
      final syncedAt = DateTime(2024, 1, 15, 10, 30);
      final result = SyncResultData(
        success: true,
        errorMessage: null,
        serverMatchId: 456,
        playerCount: 12,
        playByPlayCount: 100,
        careerStatsUpdated: false,
        syncedAt: syncedAt,
      );

      expect(result.success, true);
      expect(result.errorMessage, isNull);
      expect(result.serverMatchId, 456);
      expect(result.playerCount, 12);
      expect(result.playByPlayCount, 100);
      expect(result.careerStatsUpdated, false);
      expect(result.syncedAt, syncedAt);
    });

    test('should handle zero counts', () {
      const result = SyncResultData(
        success: true,
        playerCount: 0,
        playByPlayCount: 0,
      );

      expect(result.success, true);
      expect(result.playerCount, 0);
      expect(result.playByPlayCount, 0);
    });

    test('should preserve all values with large numbers', () {
      final result = SyncResultData(
        success: true,
        serverMatchId: 999999,
        playerCount: 100,
        playByPlayCount: 10000,
      );

      expect(result.serverMatchId, 999999);
      expect(result.playerCount, 100);
      expect(result.playByPlayCount, 10000);
    });

    group('conflict fields', () {
      test('should create with conflict data', () {
        const result = SyncResultData(
          success: false,
          hasConflict: true,
          conflictResolution: 'Server data is newer',
        );

        expect(result.success, false);
        expect(result.hasConflict, true);
        expect(result.conflictResolution, 'Server data is newer');
      });

      test('should indicate no conflict when hasConflict is false', () {
        const result = SyncResultData(
          success: true,
          hasConflict: false,
        );

        expect(result.hasConflict, false);
        expect(result.conflictResolution, isNull);
      });
    });

    group('copyWith', () {
      test('should copy with all fields', () {
        final original = SyncResultData(
          success: true,
          serverMatchId: 123,
          playerCount: 10,
          syncedAt: DateTime(2024, 1, 1),
        );

        final copied = original.copyWith(
          success: false,
          errorMessage: 'Error',
          hasConflict: true,
        );

        expect(copied.success, false);
        expect(copied.errorMessage, 'Error');
        expect(copied.hasConflict, true);
        expect(copied.serverMatchId, 123); // preserved
        expect(copied.playerCount, 10); // preserved
      });

      test('should preserve original values when not specified', () {
        final original = SyncResultData(
          success: true,
          serverMatchId: 456,
          playerCount: 12,
        );

        final copied = original.copyWith();

        expect(copied.success, true);
        expect(copied.serverMatchId, 456);
        expect(copied.playerCount, 12);
      });
    });
  });

  group('ExponentialBackoff', () {
    test('should calculate base delay for first retry', () {
      final delay = ExponentialBackoff.calculateWithoutJitter(0);
      expect(delay.inSeconds, 2); // base * 2^0 = 2
    });

    test('should calculate exponential delay for subsequent retries', () {
      final delay1 = ExponentialBackoff.calculateWithoutJitter(1);
      final delay2 = ExponentialBackoff.calculateWithoutJitter(2);
      final delay3 = ExponentialBackoff.calculateWithoutJitter(3);
      final delay4 = ExponentialBackoff.calculateWithoutJitter(4);

      expect(delay1.inSeconds, 4); // 2 * 2^1 = 4
      expect(delay2.inSeconds, 8); // 2 * 2^2 = 8
      expect(delay3.inSeconds, 16); // 2 * 2^3 = 16
      expect(delay4.inSeconds, 32); // 2 * 2^4 = 32
    });

    test('should cap at maximum delay', () {
      final delay10 = ExponentialBackoff.calculateWithoutJitter(10);
      expect(delay10.inSeconds, 300); // capped at 5 minutes
    });

    test('should include jitter in calculate()', () {
      // Run multiple times to verify jitter is applied
      final delays = <int>[];
      for (var i = 0; i < 10; i++) {
        delays.add(ExponentialBackoff.calculate(2).inSeconds);
      }

      // All delays should be around 8 seconds (±30% = 5.6 to 10.4)
      for (final delay in delays) {
        expect(delay, greaterThanOrEqualTo(1));
        expect(delay, lessThanOrEqualTo(15));
      }
    });

    test('should always return positive duration', () {
      for (var i = 0; i < 20; i++) {
        final delay = ExponentialBackoff.calculate(0);
        expect(delay.inSeconds, greaterThanOrEqualTo(1));
      }
    });
  });

  group('SyncQueueItem', () {
    test('should create with required fields', () {
      final now = DateTime.now();
      final item = SyncQueueItem(
        matchId: 1,
        localUuid: 'uuid-123',
        addedAt: now,
      );

      expect(item.matchId, 1);
      expect(item.localUuid, 'uuid-123');
      expect(item.retryCount, 0);
      expect(item.addedAt, now);
      expect(item.lastAttemptAt, isNull);
      expect(item.priority, SyncPriority.normal);
      expect(item.lastError, isNull);
    });

    test('should create with all fields', () {
      final addedAt = DateTime(2024, 1, 1);
      final lastAttemptAt = DateTime(2024, 1, 2);
      final item = SyncQueueItem(
        matchId: 2,
        localUuid: 'uuid-456',
        retryCount: 3,
        addedAt: addedAt,
        lastAttemptAt: lastAttemptAt,
        priority: SyncPriority.high,
        lastError: 'Network error',
      );

      expect(item.matchId, 2);
      expect(item.localUuid, 'uuid-456');
      expect(item.retryCount, 3);
      expect(item.addedAt, addedAt);
      expect(item.lastAttemptAt, lastAttemptAt);
      expect(item.priority, SyncPriority.high);
      expect(item.lastError, 'Network error');
    });

    group('copyWith', () {
      test('should copy with updated fields', () {
        final original = SyncQueueItem(
          matchId: 1,
          localUuid: 'uuid-123',
          addedAt: DateTime(2024, 1, 1),
        );

        final copied = original.copyWith(
          retryCount: 2,
          priority: SyncPriority.low,
          lastError: 'Timeout',
        );

        expect(copied.matchId, 1); // preserved
        expect(copied.localUuid, 'uuid-123'); // preserved
        expect(copied.retryCount, 2);
        expect(copied.priority, SyncPriority.low);
        expect(copied.lastError, 'Timeout');
      });
    });

    group('getBackoffDuration', () {
      test('should return exponential backoff based on retryCount', () {
        final item0 = SyncQueueItem(
          matchId: 1,
          localUuid: 'uuid',
          addedAt: DateTime.now(),
          retryCount: 0,
        );
        final item3 = SyncQueueItem(
          matchId: 1,
          localUuid: 'uuid',
          addedAt: DateTime.now(),
          retryCount: 3,
        );

        // With jitter, we can only check approximate ranges
        final duration0 = item0.getBackoffDuration();
        final duration3 = item3.getBackoffDuration();

        expect(duration0.inSeconds, greaterThanOrEqualTo(1));
        expect(duration3.inSeconds, greaterThan(duration0.inSeconds * 2));
      });
    });

    group('canRetryNow', () {
      test('should return true when lastAttemptAt is null', () {
        final item = SyncQueueItem(
          matchId: 1,
          localUuid: 'uuid',
          addedAt: DateTime.now(),
        );

        expect(item.canRetryNow(), true);
      });

      test('should return true when enough time has passed', () {
        final item = SyncQueueItem(
          matchId: 1,
          localUuid: 'uuid',
          addedAt: DateTime.now(),
          retryCount: 0,
          lastAttemptAt: DateTime.now().subtract(const Duration(seconds: 10)),
        );

        expect(item.canRetryNow(), true);
      });

      test('should return false when not enough time has passed', () {
        final item = SyncQueueItem(
          matchId: 1,
          localUuid: 'uuid',
          addedAt: DateTime.now(),
          retryCount: 3,
          lastAttemptAt: DateTime.now(), // just attempted
        );

        expect(item.canRetryNow(), false);
      });
    });
  });

  group('SyncPriority', () {
    test('should have correct order', () {
      expect(SyncPriority.high.index, lessThan(SyncPriority.normal.index));
      expect(SyncPriority.normal.index, lessThan(SyncPriority.low.index));
    });

    test('should have three priorities', () {
      expect(SyncPriority.values.length, 3);
    });
  });

  group('ConflictResult', () {
    test('should create noConflict constant', () {
      const result = ConflictResult.noConflict;

      expect(result.hasConflict, false);
      expect(result.conflictType, isNull);
      expect(result.resolution, isNull);
      expect(result.serverData, isNull);
      expect(result.localData, isNull);
    });

    test('should create with conflict data', () {
      const result = ConflictResult(
        hasConflict: true,
        conflictType: 'server_newer',
        resolution: 'Server data is newer. Consider merging.',
        serverData: {'updated_at': '2024-01-15T10:00:00Z'},
        localData: {'updated_at': '2024-01-14T10:00:00Z'},
      );

      expect(result.hasConflict, true);
      expect(result.conflictType, 'server_newer');
      expect(result.resolution, 'Server data is newer. Consider merging.');
      expect(result.serverData, isNotNull);
      expect(result.localData, isNotNull);
    });

    test('should handle duplicate_score conflict type', () {
      const result = ConflictResult(
        hasConflict: true,
        conflictType: 'duplicate_score',
        resolution: 'Possible duplicate. Manual review recommended.',
      );

      expect(result.conflictType, 'duplicate_score');
    });
  });

  group('SyncQueueStatus', () {
    test('should create with required fields', () {
      const status = SyncQueueStatus(
        totalItems: 5,
        pendingItems: 3,
        retryingItems: 2,
        isProcessing: true,
      );

      expect(status.totalItems, 5);
      expect(status.pendingItems, 3);
      expect(status.retryingItems, 2);
      expect(status.isProcessing, true);
      expect(status.lastProcessedAt, isNull);
      expect(status.currentConcurrentSyncs, 0);
    });

    test('should create with all fields', () {
      final lastProcessed = DateTime(2024, 1, 15);
      final status = SyncQueueStatus(
        totalItems: 10,
        pendingItems: 5,
        retryingItems: 5,
        isProcessing: false,
        lastProcessedAt: lastProcessed,
        currentConcurrentSyncs: 2,
      );

      expect(status.totalItems, 10);
      expect(status.lastProcessedAt, lastProcessed);
      expect(status.currentConcurrentSyncs, 2);
    });

    group('computed properties', () {
      test('isEmpty should return true when totalItems is 0', () {
        const emptyStatus = SyncQueueStatus(
          totalItems: 0,
          pendingItems: 0,
          retryingItems: 0,
          isProcessing: false,
        );

        const nonEmptyStatus = SyncQueueStatus(
          totalItems: 1,
          pendingItems: 1,
          retryingItems: 0,
          isProcessing: false,
        );

        expect(emptyStatus.isEmpty, true);
        expect(nonEmptyStatus.isEmpty, false);
      });

      test('hasErrors should return true when retryingItems > 0', () {
        const noErrors = SyncQueueStatus(
          totalItems: 5,
          pendingItems: 5,
          retryingItems: 0,
          isProcessing: false,
        );

        const withErrors = SyncQueueStatus(
          totalItems: 5,
          pendingItems: 3,
          retryingItems: 2,
          isProcessing: false,
        );

        expect(noErrors.hasErrors, false);
        expect(withErrors.hasErrors, true);
      });

      test('isActivelyProcessing should check currentConcurrentSyncs', () {
        const notActive = SyncQueueStatus(
          totalItems: 5,
          pendingItems: 5,
          retryingItems: 0,
          isProcessing: true,
          currentConcurrentSyncs: 0,
        );

        const active = SyncQueueStatus(
          totalItems: 5,
          pendingItems: 4,
          retryingItems: 0,
          isProcessing: true,
          currentConcurrentSyncs: 1,
        );

        expect(notActive.isActivelyProcessing, false);
        expect(active.isActivelyProcessing, true);
      });
    });

    test('toString should include all relevant info', () {
      const status = SyncQueueStatus(
        totalItems: 5,
        pendingItems: 3,
        retryingItems: 2,
        isProcessing: true,
        currentConcurrentSyncs: 1,
      );

      final str = status.toString();
      expect(str, contains('total: 5'));
      expect(str, contains('pending: 3'));
      expect(str, contains('retrying: 2'));
      expect(str, contains('processing: true'));
      expect(str, contains('concurrent: 1'));
    });
  });

  group('SyncInfo', () {
    test('should create with required fields', () {
      const info = SyncInfo(
        unsyncedCount: 3,
        queueStatus: SyncQueueStatus(
          totalItems: 2,
          pendingItems: 2,
          retryingItems: 0,
          isProcessing: false,
        ),
      );

      expect(info.unsyncedCount, 3);
      expect(info.queueStatus.totalItems, 2);
    });

    group('needsSync', () {
      test('should return true when unsyncedCount > 0', () {
        const info = SyncInfo(
          unsyncedCount: 5,
          queueStatus: SyncQueueStatus(
            totalItems: 0,
            pendingItems: 0,
            retryingItems: 0,
            isProcessing: false,
          ),
        );

        expect(info.needsSync, true);
      });

      test('should return true when queue is not empty', () {
        const info = SyncInfo(
          unsyncedCount: 0,
          queueStatus: SyncQueueStatus(
            totalItems: 3,
            pendingItems: 3,
            retryingItems: 0,
            isProcessing: false,
          ),
        );

        expect(info.needsSync, true);
      });

      test('should return false when nothing to sync', () {
        const info = SyncInfo(
          unsyncedCount: 0,
          queueStatus: SyncQueueStatus(
            totalItems: 0,
            pendingItems: 0,
            retryingItems: 0,
            isProcessing: false,
          ),
        );

        expect(info.needsSync, false);
      });
    });
  });
}
