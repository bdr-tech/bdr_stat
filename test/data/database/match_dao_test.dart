import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bdr_tournament_recorder/data/database/database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('MatchDao', () {
    test('should create match with auto-increment id', () async {
      final match = LocalMatchesCompanion.insert(
        localUuid: 'test-uuid-123',
        tournamentId: 'tournament-1',
        homeTeamId: 1,
        awayTeamId: 2,
        homeTeamName: '홈팀',
        awayTeamName: '원정팀',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await database.matchDao.insertMatch(match);
      expect(id, greaterThan(0));

      final fetched = await database.matchDao.getMatchById(id);
      expect(fetched, isNotNull);
      expect(fetched!.localUuid, equals('test-uuid-123'));
      expect(fetched.homeTeamName, equals('홈팀'));
    });

    test('should update match score', () async {
      final match = LocalMatchesCompanion.insert(
        localUuid: 'test-uuid-456',
        tournamentId: 'tournament-1',
        homeTeamId: 1,
        awayTeamId: 2,
        homeTeamName: '홈팀',
        awayTeamName: '원정팀',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await database.matchDao.insertMatch(match);
      await database.matchDao.updateMatchScore(id, 25, 22);

      final fetched = await database.matchDao.getMatchById(id);
      expect(fetched!.homeScore, equals(25));
      expect(fetched.awayScore, equals(22));
    });

    test('should update match status', () async {
      final match = LocalMatchesCompanion.insert(
        localUuid: 'test-uuid-789',
        tournamentId: 'tournament-1',
        homeTeamId: 1,
        awayTeamId: 2,
        homeTeamName: '홈팀',
        awayTeamName: '원정팀',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await database.matchDao.insertMatch(match);

      await database.matchDao.updateMatchStatus(id, 'in_progress');
      var fetched = await database.matchDao.getMatchById(id);
      expect(fetched!.status, equals('in_progress'));

      await database.matchDao.updateMatchStatus(id, 'finished');
      fetched = await database.matchDao.getMatchById(id);
      expect(fetched!.status, equals('finished'));
    });

    test('should get all matches by status', () async {
      // Create multiple matches with different statuses
      for (var i = 0; i < 3; i++) {
        final match = LocalMatchesCompanion.insert(
          localUuid: 'test-uuid-progress-$i',
          tournamentId: 'tournament-1',
          homeTeamId: 1,
          awayTeamId: 2,
          homeTeamName: '홈팀 $i',
          awayTeamName: '원정팀 $i',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final id = await database.matchDao.insertMatch(match);
        await database.matchDao.updateMatchStatus(id, 'in_progress');
      }

      for (var i = 0; i < 2; i++) {
        final match = LocalMatchesCompanion.insert(
          localUuid: 'test-uuid-finished-$i',
          tournamentId: 'tournament-1',
          homeTeamId: 1,
          awayTeamId: 2,
          homeTeamName: '홈팀 F$i',
          awayTeamName: '원정팀 F$i',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final id = await database.matchDao.insertMatch(match);
        await database.matchDao.updateMatchStatus(id, 'finished');
      }

      final inProgress = await database.matchDao.getAllMatchesByStatus('in_progress');
      expect(inProgress.length, equals(3));

      final finished = await database.matchDao.getAllMatchesByStatus('finished');
      expect(finished.length, equals(2));
    });

    test('should update quarter and game clock', () async {
      final match = LocalMatchesCompanion.insert(
        localUuid: 'test-uuid-quarter',
        tournamentId: 'tournament-1',
        homeTeamId: 1,
        awayTeamId: 2,
        homeTeamName: '홈팀',
        awayTeamName: '원정팀',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await database.matchDao.insertMatch(match);
      await database.matchDao.updateQuarter(id, 2);
      await database.matchDao.updateGameClock(id, 450);
      await database.matchDao.updateShotClock(id, 18);

      final fetched = await database.matchDao.getMatchById(id);
      expect(fetched!.currentQuarter, equals(2));
      expect(fetched.gameClockSeconds, equals(450));
      expect(fetched.shotClockSeconds, equals(18));
    });

    test('should get unsynced matches', () async {
      // Create synced match
      final syncedMatch = LocalMatchesCompanion.insert(
        localUuid: 'test-uuid-synced',
        tournamentId: 'tournament-1',
        homeTeamId: 1,
        awayTeamId: 2,
        homeTeamName: '홈팀',
        awayTeamName: '원정팀',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final syncedId = await database.matchDao.insertMatch(syncedMatch);
      await database.matchDao.updateMatchStatus(syncedId, 'finished');
      await database.matchDao.markAsSynced(syncedId, serverId: 100, serverUuid: 'server-uuid-1');

      // Create unsynced match (must be finished to show in getUnsyncedMatches)
      final unsyncedMatch = LocalMatchesCompanion.insert(
        localUuid: 'test-uuid-unsynced',
        tournamentId: 'tournament-1',
        homeTeamId: 1,
        awayTeamId: 2,
        homeTeamName: '홈팀 2',
        awayTeamName: '원정팀 2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final unsyncedId = await database.matchDao.insertMatch(unsyncedMatch);
      await database.matchDao.updateMatchStatus(unsyncedId, 'finished');

      final unsynced = await database.matchDao.getUnsyncedMatches();
      expect(unsynced.length, equals(1));
      expect(unsynced.first.localUuid, equals('test-uuid-unsynced'));
    });
  });
}
