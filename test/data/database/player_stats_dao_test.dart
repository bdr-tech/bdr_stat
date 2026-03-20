import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bdr_tournament_recorder/data/database/database.dart';

void main() {
  late AppDatabase database;
  late int testMatchId;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    // Create a test match first
    final match = LocalMatchesCompanion.insert(
      localUuid: 'test-match-uuid',
      tournamentId: 'tournament-1',
      homeTeamId: 1,
      awayTeamId: 2,
      homeTeamName: '홈팀',
      awayTeamName: '원정팀',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    testMatchId = await database.matchDao.insertMatch(match);
  });

  tearDown(() async {
    await database.close();
  });

  group('PlayerStatsDao', () {
    test('should create player stats', () async {
      final stats = LocalPlayerStatsCompanion.insert(
        localMatchId: testMatchId,
        tournamentTeamPlayerId: 101,
        tournamentTeamId: 1,
        updatedAt: DateTime.now(),
      );

      final id = await database.playerStatsDao.insertPlayerStats(stats);
      expect(id, greaterThan(0));

      final fetched = await database.playerStatsDao.getPlayerStats(testMatchId, 101);
      expect(fetched, isNotNull);
      expect(fetched!.points, equals(0));
    });

    test('should update player points correctly', () async {
      final stats = LocalPlayerStatsCompanion.insert(
        localMatchId: testMatchId,
        tournamentTeamPlayerId: 102,
        tournamentTeamId: 1,
        updatedAt: DateTime.now(),
      );
      await database.playerStatsDao.insertPlayerStats(stats);

      // Add 2-pointer
      await database.playerStatsDao.recordTwoPointer(testMatchId, 102, true);
      var fetched = await database.playerStatsDao.getPlayerStats(testMatchId, 102);
      expect(fetched!.points, equals(2));
      expect(fetched.twoPointersMade, equals(1));
      expect(fetched.twoPointersAttempted, equals(1));
      expect(fetched.fieldGoalsMade, equals(1));
      expect(fetched.fieldGoalsAttempted, equals(1));

      // Add missed 2-pointer
      await database.playerStatsDao.recordTwoPointer(testMatchId, 102, false);
      fetched = await database.playerStatsDao.getPlayerStats(testMatchId, 102);
      expect(fetched!.points, equals(2));
      expect(fetched.twoPointersMade, equals(1));
      expect(fetched.twoPointersAttempted, equals(2));

      // Add 3-pointer
      await database.playerStatsDao.recordThreePointer(testMatchId, 102, true);
      fetched = await database.playerStatsDao.getPlayerStats(testMatchId, 102);
      expect(fetched!.points, equals(5));
      expect(fetched.threePointersMade, equals(1));
      expect(fetched.threePointersAttempted, equals(1));

      // Add free throw
      await database.playerStatsDao.recordFreeThrow(testMatchId, 102, true);
      fetched = await database.playerStatsDao.getPlayerStats(testMatchId, 102);
      expect(fetched!.points, equals(6));
      expect(fetched.freeThrowsMade, equals(1));
      expect(fetched.freeThrowsAttempted, equals(1));
    });

    test('should update rebounds correctly', () async {
      final stats = LocalPlayerStatsCompanion.insert(
        localMatchId: testMatchId,
        tournamentTeamPlayerId: 103,
        tournamentTeamId: 1,
        updatedAt: DateTime.now(),
      );
      await database.playerStatsDao.insertPlayerStats(stats);

      await database.playerStatsDao.recordRebound(testMatchId, 103, true);
      var fetched = await database.playerStatsDao.getPlayerStats(testMatchId, 103);
      expect(fetched!.offensiveRebounds, equals(1));
      expect(fetched.totalRebounds, equals(1));

      await database.playerStatsDao.recordRebound(testMatchId, 103, false);
      fetched = await database.playerStatsDao.getPlayerStats(testMatchId, 103);
      expect(fetched!.defensiveRebounds, equals(1));
      expect(fetched.totalRebounds, equals(2));
    });

    test('should update assists, steals, blocks, turnovers', () async {
      final stats = LocalPlayerStatsCompanion.insert(
        localMatchId: testMatchId,
        tournamentTeamPlayerId: 104,
        tournamentTeamId: 1,
        updatedAt: DateTime.now(),
      );
      await database.playerStatsDao.insertPlayerStats(stats);

      await database.playerStatsDao.recordAssist(testMatchId, 104);
      await database.playerStatsDao.recordSteal(testMatchId, 104);
      await database.playerStatsDao.recordBlock(testMatchId, 104);
      await database.playerStatsDao.recordTurnover(testMatchId, 104);

      final fetched = await database.playerStatsDao.getPlayerStats(testMatchId, 104);
      expect(fetched!.assists, equals(1));
      expect(fetched.steals, equals(1));
      expect(fetched.blocks, equals(1));
      expect(fetched.turnovers, equals(1));
    });

    test('should track fouls and foul out', () async {
      final stats = LocalPlayerStatsCompanion.insert(
        localMatchId: testMatchId,
        tournamentTeamPlayerId: 105,
        tournamentTeamId: 1,
        updatedAt: DateTime.now(),
      );
      await database.playerStatsDao.insertPlayerStats(stats);

      // Add 5 fouls
      for (var i = 0; i < 5; i++) {
        await database.playerStatsDao.recordFoul(testMatchId, 105);
      }

      final fetched = await database.playerStatsDao.getPlayerStats(testMatchId, 105);
      expect(fetched!.personalFouls, equals(5));
      expect(fetched.fouledOut, isTrue);
    });

    test('should get stats by match and team', () async {
      // Create stats for home team
      for (var i = 0; i < 5; i++) {
        final stats = LocalPlayerStatsCompanion.insert(
          localMatchId: testMatchId,
          tournamentTeamPlayerId: 200 + i,
          tournamentTeamId: 1, // Home team
          updatedAt: DateTime.now(),
        );
        await database.playerStatsDao.insertPlayerStats(stats);
      }

      // Create stats for away team
      for (var i = 0; i < 5; i++) {
        final stats = LocalPlayerStatsCompanion.insert(
          localMatchId: testMatchId,
          tournamentTeamPlayerId: 300 + i,
          tournamentTeamId: 2, // Away team
          updatedAt: DateTime.now(),
        );
        await database.playerStatsDao.insertPlayerStats(stats);
      }

      final homeStats = await database.playerStatsDao.getStatsByMatchAndTeam(testMatchId, 1);
      expect(homeStats.length, equals(5));

      final awayStats = await database.playerStatsDao.getStatsByMatchAndTeam(testMatchId, 2);
      expect(awayStats.length, equals(5));
    });

    test('should update on-court status', () async {
      final stats = LocalPlayerStatsCompanion.insert(
        localMatchId: testMatchId,
        tournamentTeamPlayerId: 106,
        tournamentTeamId: 1,
        updatedAt: DateTime.now(),
      );
      await database.playerStatsDao.insertPlayerStats(stats);

      await database.playerStatsDao.setOnCourt(testMatchId, 106, true);
      var fetched = await database.playerStatsDao.getPlayerStats(testMatchId, 106);
      expect(fetched!.isOnCourt, isTrue);

      await database.playerStatsDao.setOnCourt(testMatchId, 106, false);
      fetched = await database.playerStatsDao.getPlayerStats(testMatchId, 106);
      expect(fetched!.isOnCourt, isFalse);
    });

    test('should support undo with negative increment', () async {
      final stats = LocalPlayerStatsCompanion.insert(
        localMatchId: testMatchId,
        tournamentTeamPlayerId: 107,
        tournamentTeamId: 1,
        updatedAt: DateTime.now(),
      );
      await database.playerStatsDao.insertPlayerStats(stats);

      // Record a 2-pointer
      await database.playerStatsDao.recordTwoPointer(testMatchId, 107, true);
      var fetched = await database.playerStatsDao.getPlayerStats(testMatchId, 107);
      expect(fetched!.points, equals(2));
      expect(fetched.twoPointersMade, equals(1));

      // Undo the 2-pointer (using negative increment)
      await database.playerStatsDao.recordTwoPointer(testMatchId, 107, true, increment: -1);
      fetched = await database.playerStatsDao.getPlayerStats(testMatchId, 107);
      expect(fetched!.points, equals(0));
      expect(fetched.twoPointersMade, equals(0));
      expect(fetched.twoPointersAttempted, equals(0));
    });
  });
}
