import 'package:drift/drift.dart' hide isNotNull;
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

  group('PlayByPlayDao', () {
    test('should insert play-by-play record', () async {
      final play = LocalPlayByPlaysCompanion.insert(
        localId: 'play-uuid-1',
        localMatchId: testMatchId,
        tournamentTeamPlayerId: 101,
        tournamentTeamId: 1,
        quarter: 1,
        gameClockSeconds: 540,
        actionType: 'shot',
        homeScoreAtTime: 0,
        awayScoreAtTime: 0,
        createdAt: DateTime.now(),
        actionSubtype: const Value('2pt'),
        isMade: const Value(true),
        pointsScored: const Value(2),
        courtX: const Value(50.0),
        courtY: const Value(30.0),
        courtZone: const Value(5),
        shotDistance: const Value(15.0),
      );

      final id = await database.playByPlayDao.insertPlay(play);
      expect(id, greaterThan(0));

      final plays = await database.playByPlayDao.getPlaysByMatch(testMatchId);
      expect(plays.length, equals(1));
      expect(plays.first.actionType, equals('shot'));
      expect(plays.first.pointsScored, equals(2));
      expect(plays.first.courtX, equals(50.0));
    });

    test('should get plays by quarter', () async {
      // Insert plays for Q1
      for (var i = 0; i < 5; i++) {
        final play = LocalPlayByPlaysCompanion.insert(
          localId: 'play-q1-$i',
          localMatchId: testMatchId,
          tournamentTeamPlayerId: 101,
          tournamentTeamId: 1,
          quarter: 1,
          gameClockSeconds: 600 - (i * 60),
          actionType: 'shot',
          homeScoreAtTime: i * 2,
          awayScoreAtTime: 0,
          createdAt: DateTime.now(),
        );
        await database.playByPlayDao.insertPlay(play);
      }

      // Insert plays for Q2
      for (var i = 0; i < 3; i++) {
        final play = LocalPlayByPlaysCompanion.insert(
          localId: 'play-q2-$i',
          localMatchId: testMatchId,
          tournamentTeamPlayerId: 101,
          tournamentTeamId: 1,
          quarter: 2,
          gameClockSeconds: 600 - (i * 60),
          actionType: 'shot',
          homeScoreAtTime: 10 + (i * 2),
          awayScoreAtTime: 0,
          createdAt: DateTime.now(),
        );
        await database.playByPlayDao.insertPlay(play);
      }

      final q1Plays = await database.playByPlayDao.getPlaysByMatchAndQuarter(testMatchId, 1);
      expect(q1Plays.length, equals(5));

      final q2Plays = await database.playByPlayDao.getPlaysByMatchAndQuarter(testMatchId, 2);
      expect(q2Plays.length, equals(3));
    });

    test('should get plays by player', () async {
      // Insert plays for player 101
      for (var i = 0; i < 4; i++) {
        final play = LocalPlayByPlaysCompanion.insert(
          localId: 'play-p101-$i',
          localMatchId: testMatchId,
          tournamentTeamPlayerId: 101,
          tournamentTeamId: 1,
          quarter: 1,
          gameClockSeconds: 600 - (i * 60),
          actionType: 'shot',
          homeScoreAtTime: i * 2,
          awayScoreAtTime: 0,
          createdAt: DateTime.now(),
        );
        await database.playByPlayDao.insertPlay(play);
      }

      // Insert plays for player 102
      for (var i = 0; i < 2; i++) {
        final play = LocalPlayByPlaysCompanion.insert(
          localId: 'play-p102-$i',
          localMatchId: testMatchId,
          tournamentTeamPlayerId: 102,
          tournamentTeamId: 1,
          quarter: 1,
          gameClockSeconds: 500 - (i * 60),
          actionType: 'shot',
          homeScoreAtTime: 8 + (i * 2),
          awayScoreAtTime: 0,
          createdAt: DateTime.now(),
        );
        await database.playByPlayDao.insertPlay(play);
      }

      final player101Plays = await database.playByPlayDao.getPlaysByPlayer(testMatchId, 101);
      expect(player101Plays.length, equals(4));

      final player102Plays = await database.playByPlayDao.getPlaysByPlayer(testMatchId, 102);
      expect(player102Plays.length, equals(2));
    });

    test('should get shot data (shots only)', () async {
      // Insert shots
      for (var i = 0; i < 3; i++) {
        final play = LocalPlayByPlaysCompanion.insert(
          localId: 'shot-$i',
          localMatchId: testMatchId,
          tournamentTeamPlayerId: 101,
          tournamentTeamId: 1,
          quarter: 1,
          gameClockSeconds: 600 - (i * 60),
          actionType: 'shot',
          homeScoreAtTime: i * 2,
          awayScoreAtTime: 0,
          createdAt: DateTime.now(),
          courtX: Value(50.0 + i * 10),
          courtY: Value(30.0 + i * 5),
          isMade: const Value(true),
        );
        await database.playByPlayDao.insertPlay(play);
      }

      // Insert non-shot plays
      final rebound = LocalPlayByPlaysCompanion.insert(
        localId: 'rebound-1',
        localMatchId: testMatchId,
        tournamentTeamPlayerId: 101,
        tournamentTeamId: 1,
        quarter: 1,
        gameClockSeconds: 300,
        actionType: 'rebound',
        homeScoreAtTime: 6,
        awayScoreAtTime: 0,
        createdAt: DateTime.now(),
      );
      await database.playByPlayDao.insertPlay(rebound);

      final shots = await database.playByPlayDao.getShots(testMatchId);
      expect(shots.length, equals(3));
      expect(shots.every((p) => p.actionType == 'shot'), isTrue);
    });

    test('should get unsynced plays', () async {
      // Insert synced play
      final syncedPlay = LocalPlayByPlaysCompanion.insert(
        localId: 'synced-play',
        localMatchId: testMatchId,
        tournamentTeamPlayerId: 101,
        tournamentTeamId: 1,
        quarter: 1,
        gameClockSeconds: 600,
        actionType: 'shot',
        homeScoreAtTime: 0,
        awayScoreAtTime: 0,
        createdAt: DateTime.now(),
        isSynced: const Value(true),
      );
      await database.playByPlayDao.insertPlay(syncedPlay);

      // Insert unsynced plays
      for (var i = 0; i < 3; i++) {
        final unsyncedPlay = LocalPlayByPlaysCompanion.insert(
          localId: 'unsynced-play-$i',
          localMatchId: testMatchId,
          tournamentTeamPlayerId: 101,
          tournamentTeamId: 1,
          quarter: 1,
          gameClockSeconds: 500 - (i * 60),
          actionType: 'shot',
          homeScoreAtTime: 2 + (i * 2),
          awayScoreAtTime: 0,
          createdAt: DateTime.now(),
          isSynced: const Value(false),
        );
        await database.playByPlayDao.insertPlay(unsyncedPlay);
      }

      final unsyncedPlays = await database.playByPlayDao.getUnsyncedPlays(testMatchId);
      expect(unsyncedPlays.length, equals(3));
    });

    test('should count plays by match', () async {
      for (var i = 0; i < 10; i++) {
        final play = LocalPlayByPlaysCompanion.insert(
          localId: 'play-count-$i',
          localMatchId: testMatchId,
          tournamentTeamPlayerId: 101,
          tournamentTeamId: 1,
          quarter: 1,
          gameClockSeconds: 600 - (i * 30),
          actionType: 'shot',
          homeScoreAtTime: i * 2,
          awayScoreAtTime: 0,
          createdAt: DateTime.now(),
        );
        await database.playByPlayDao.insertPlay(play);
      }

      final plays = await database.playByPlayDao.getPlaysByMatch(testMatchId);
      expect(plays.length, equals(10));
    });

    test('should delete play by local id', () async {
      final play = LocalPlayByPlaysCompanion.insert(
        localId: 'play-to-delete',
        localMatchId: testMatchId,
        tournamentTeamPlayerId: 101,
        tournamentTeamId: 1,
        quarter: 1,
        gameClockSeconds: 600,
        actionType: 'shot',
        homeScoreAtTime: 0,
        awayScoreAtTime: 0,
        createdAt: DateTime.now(),
      );
      await database.playByPlayDao.insertPlay(play);

      var plays = await database.playByPlayDao.getPlaysByMatch(testMatchId);
      expect(plays.length, equals(1));

      await database.playByPlayDao.deletePlayByLocalId('play-to-delete');

      plays = await database.playByPlayDao.getPlaysByMatch(testMatchId);
      expect(plays.length, equals(0));
    });

    test('should get last play for undo', () async {
      for (var i = 0; i < 5; i++) {
        final play = LocalPlayByPlaysCompanion.insert(
          localId: 'play-last-$i',
          localMatchId: testMatchId,
          tournamentTeamPlayerId: 101,
          tournamentTeamId: 1,
          quarter: 1,
          gameClockSeconds: 600 - (i * 60),
          actionType: 'shot',
          homeScoreAtTime: i * 2,
          awayScoreAtTime: 0,
          createdAt: DateTime.now().add(Duration(seconds: i)),
        );
        await database.playByPlayDao.insertPlay(play);
      }

      final lastPlay = await database.playByPlayDao.getLastPlay(testMatchId);
      expect(lastPlay, isNotNull);
      expect(lastPlay!.localId, equals('play-last-4'));
    });

    test('should get recent plays', () async {
      for (var i = 0; i < 10; i++) {
        final play = LocalPlayByPlaysCompanion.insert(
          localId: 'recent-play-$i',
          localMatchId: testMatchId,
          tournamentTeamPlayerId: 101,
          tournamentTeamId: 1,
          quarter: 1,
          gameClockSeconds: 600 - (i * 30),
          actionType: 'shot',
          homeScoreAtTime: i * 2,
          awayScoreAtTime: 0,
          createdAt: DateTime.now().add(Duration(seconds: i)),
        );
        await database.playByPlayDao.insertPlay(play);
      }

      final recentPlays = await database.playByPlayDao.getRecentPlays(testMatchId, limit: 5);
      expect(recentPlays.length, equals(5));
    });
  });
}
