import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bdr_tournament_recorder/core/services/event_queue.dart';

void main() {
  group('EventQueue', () {
    late EventQueue queue;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      queue = EventQueue();
      await queue.load();
    });

    PendingEvent makeEvent({
      String? clientEventId,
      int matchId = 1,
      String eventType = '2pt',
    }) {
      return PendingEvent(
        clientEventId: clientEventId ?? 'evt-${DateTime.now().microsecondsSinceEpoch}',
        matchId: matchId,
        data: {
          'event_type': eventType,
          'client_event_id': clientEventId ?? 'evt-test',
          'team_id': 100,
          'quarter': 1,
          'game_time': '05:30',
        },
        createdAt: DateTime.now(),
      );
    }

    group('enqueue', () {
      test('should add event to queue and persist', () async {
        expect(queue.isEmpty, isTrue);
        expect(queue.length, 0);

        await queue.enqueue(makeEvent(clientEventId: 'e1'));
        expect(queue.length, 1);
        expect(queue.isEmpty, isFalse);
      });

      test('should add multiple events in order', () async {
        await queue.enqueue(makeEvent(clientEventId: 'e1'));
        await queue.enqueue(makeEvent(clientEventId: 'e2'));
        await queue.enqueue(makeEvent(clientEventId: 'e3'));
        expect(queue.length, 3);
      });

      test('should persist across load cycles', () async {
        await queue.enqueue(makeEvent(clientEventId: 'persist-1'));
        await queue.enqueue(makeEvent(clientEventId: 'persist-2'));

        // Create new queue and load from SharedPreferences
        final queue2 = EventQueue();
        await queue2.load();
        expect(queue2.length, 2);
      });
    });

    group('dequeueAll', () {
      test('should return all events and clear queue', () async {
        await queue.enqueue(makeEvent(clientEventId: 'e1'));
        await queue.enqueue(makeEvent(clientEventId: 'e2'));

        final events = await queue.dequeueAll();
        expect(events.length, 2);
        expect(events[0].clientEventId, 'e1');
        expect(events[1].clientEventId, 'e2');
        expect(queue.isEmpty, isTrue);
        expect(queue.length, 0);
      });

      test('should return empty list when queue is empty', () async {
        final events = await queue.dequeueAll();
        expect(events, isEmpty);
      });

      test('should persist empty state after dequeue', () async {
        await queue.enqueue(makeEvent(clientEventId: 'e1'));
        await queue.dequeueAll();

        final queue2 = EventQueue();
        await queue2.load();
        expect(queue2.isEmpty, isTrue);
      });
    });

    group('dequeueByMatch', () {
      test('should only dequeue events for specific match', () async {
        await queue.enqueue(makeEvent(clientEventId: 'e1', matchId: 1));
        await queue.enqueue(makeEvent(clientEventId: 'e2', matchId: 2));
        await queue.enqueue(makeEvent(clientEventId: 'e3', matchId: 1));

        final match1Events = await queue.dequeueByMatch(1);
        expect(match1Events.length, 2);
        expect(queue.length, 1); // match 2 event remains
      });

      test('should return empty list when no events for match', () async {
        await queue.enqueue(makeEvent(clientEventId: 'e1', matchId: 1));

        final result = await queue.dequeueByMatch(999);
        expect(result, isEmpty);
        expect(queue.length, 1);
      });
    });

    group('removeByClientEventId', () {
      test('should remove specific event by clientEventId', () async {
        await queue.enqueue(makeEvent(clientEventId: 'keep'));
        await queue.enqueue(makeEvent(clientEventId: 'remove'));
        await queue.enqueue(makeEvent(clientEventId: 'keep2'));

        final removed = await queue.removeByClientEventId('remove');
        expect(removed, isTrue);
        expect(queue.length, 2);
      });

      test('should return false when event not found', () async {
        await queue.enqueue(makeEvent(clientEventId: 'e1'));

        final removed = await queue.removeByClientEventId('nonexistent');
        expect(removed, isFalse);
        expect(queue.length, 1);
      });
    });

    group('countForMatch', () {
      test('should count events per match', () async {
        await queue.enqueue(makeEvent(clientEventId: 'e1', matchId: 1));
        await queue.enqueue(makeEvent(clientEventId: 'e2', matchId: 2));
        await queue.enqueue(makeEvent(clientEventId: 'e3', matchId: 1));

        expect(queue.countForMatch(1), 2);
        expect(queue.countForMatch(2), 1);
        expect(queue.countForMatch(3), 0);
      });
    });

    group('offline queue preservation', () {
      test('should preserve events through app restart simulation', () async {
        // Simulate offline: enqueue events
        await queue.enqueue(makeEvent(clientEventId: 'offline-1', matchId: 5));
        await queue.enqueue(makeEvent(clientEventId: 'offline-2', matchId: 5));
        await queue.enqueue(makeEvent(clientEventId: 'offline-3', matchId: 5));

        expect(queue.length, 3);

        // Simulate app restart: new queue instance, load from storage
        final restoredQueue = EventQueue();
        await restoredQueue.load();

        expect(restoredQueue.length, 3);
        expect(restoredQueue.countForMatch(5), 3);

        // Verify data integrity after restoration
        final events = await restoredQueue.dequeueAll();
        expect(events[0].clientEventId, 'offline-1');
        expect(events[1].clientEventId, 'offline-2');
        expect(events[2].clientEventId, 'offline-3');
        expect(events[0].matchId, 5);
      });
    });

    group('online flush simulation', () {
      test('should dequeue by match for batch flush', () async {
        // Queue events from 2 different matches
        await queue.enqueue(makeEvent(clientEventId: 'a1', matchId: 10));
        await queue.enqueue(makeEvent(clientEventId: 'b1', matchId: 20));
        await queue.enqueue(makeEvent(clientEventId: 'a2', matchId: 10));

        // Flush match 10 events (simulating online recovery)
        final match10Events = await queue.dequeueByMatch(10);
        expect(match10Events.length, 2);
        expect(match10Events[0].clientEventId, 'a1');
        expect(match10Events[1].clientEventId, 'a2');

        // Match 20 events should remain
        expect(queue.length, 1);
        expect(queue.countForMatch(20), 1);
      });

      test('should re-enqueue failed events', () async {
        await queue.enqueue(makeEvent(clientEventId: 'f1', matchId: 10));
        await queue.enqueue(makeEvent(clientEventId: 'f2', matchId: 10));

        // Dequeue for flush attempt
        final events = await queue.dequeueByMatch(10);
        expect(queue.length, 0);

        // Simulate flush failure: re-enqueue
        for (final e in events) {
          await queue.enqueue(e);
        }
        expect(queue.length, 2);
        expect(queue.countForMatch(10), 2);
      });
    });

    group('PendingEvent serialization', () {
      test('should serialize and deserialize correctly', () {
        final event = PendingEvent(
          clientEventId: 'test-uuid',
          matchId: 42,
          data: {'event_type': '3pt', 'value': 3, 'team_id': 100},
          createdAt: DateTime(2026, 3, 9, 15, 30),
        );

        final json = event.toJson();
        final restored = PendingEvent.fromJson(json);

        expect(restored.clientEventId, 'test-uuid');
        expect(restored.matchId, 42);
        expect(restored.data['event_type'], '3pt');
        expect(restored.data['value'], 3);
        expect(restored.createdAt.year, 2026);
        expect(restored.createdAt.month, 3);
      });
    });
  });
}
