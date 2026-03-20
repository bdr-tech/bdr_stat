import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bdr_tournament_recorder/data/database/database.dart';

/// Integration test for complete game recording flow
/// Tests the entire flow: match creation → player stats → play-by-play → scoring
void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('Game Recording Integration', () {
    test('complete game flow: create match, record actions, verify scores', () async {
      // 1. Create match
      final match = LocalMatchesCompanion.insert(
        localUuid: 'game-flow-test-uuid',
        tournamentId: 'tournament-1',
        homeTeamId: 1,
        awayTeamId: 2,
        homeTeamName: '홈팀',
        awayTeamName: '원정팀',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final matchId = await database.matchDao.insertMatch(match);
      await database.matchDao.updateMatchStatus(matchId, 'in_progress');

      // 2. Create player stats for both teams (5 players each)
      final homePlayers = <int>[];
      final awayPlayers = <int>[];

      for (var i = 0; i < 5; i++) {
        // Home team players
        final homeStats = LocalPlayerStatsCompanion.insert(
          localMatchId: matchId,
          tournamentTeamPlayerId: 100 + i,
          tournamentTeamId: 1,
          isStarter: const Value(true),
          isOnCourt: const Value(true),
          updatedAt: DateTime.now(),
        );
        await database.playerStatsDao.insertPlayerStats(homeStats);
        homePlayers.add(100 + i);

        // Away team players
        final awayStats = LocalPlayerStatsCompanion.insert(
          localMatchId: matchId,
          tournamentTeamPlayerId: 200 + i,
          tournamentTeamId: 2,
          isStarter: const Value(true),
          isOnCourt: const Value(true),
          updatedAt: DateTime.now(),
        );
        await database.playerStatsDao.insertPlayerStats(awayStats);
        awayPlayers.add(200 + i);
      }

      // 3. Simulate Q1 actions
      var homeScore = 0;
      var awayScore = 0;
      var gameClockSeconds = 600;

      // Home player 0 makes a 2-pointer
      await database.playerStatsDao.recordTwoPointer(matchId, homePlayers[0], true);
      homeScore += 2;
      gameClockSeconds -= 30;

      await database.playByPlayDao.insertPlay(LocalPlayByPlaysCompanion.insert(
        localId: 'pbp-1',
        localMatchId: matchId,
        tournamentTeamPlayerId: homePlayers[0],
        tournamentTeamId: 1,
        quarter: 1,
        gameClockSeconds: gameClockSeconds,
        actionType: 'shot',
        homeScoreAtTime: homeScore,
        awayScoreAtTime: awayScore,
        createdAt: DateTime.now(),
        actionSubtype: const Value('2pt'),
        isMade: const Value(true),
        pointsScored: const Value(2),
        courtX: const Value(45.0),
        courtY: const Value(50.0),
      ));

      // Away player 0 makes a 3-pointer
      await database.playerStatsDao.recordThreePointer(matchId, awayPlayers[0], true);
      awayScore += 3;
      gameClockSeconds -= 25;

      await database.playByPlayDao.insertPlay(LocalPlayByPlaysCompanion.insert(
        localId: 'pbp-2',
        localMatchId: matchId,
        tournamentTeamPlayerId: awayPlayers[0],
        tournamentTeamId: 2,
        quarter: 1,
        gameClockSeconds: gameClockSeconds,
        actionType: 'shot',
        homeScoreAtTime: homeScore,
        awayScoreAtTime: awayScore,
        createdAt: DateTime.now(),
        actionSubtype: const Value('3pt'),
        isMade: const Value(true),
        pointsScored: const Value(3),
        courtX: const Value(25.0),
        courtY: const Value(10.0),
      ));

      // Home player 1 makes a free throw (2 of 3)
      await database.playerStatsDao.recordFreeThrow(matchId, homePlayers[1], true);
      await database.playerStatsDao.recordFreeThrow(matchId, homePlayers[1], true);
      await database.playerStatsDao.recordFreeThrow(matchId, homePlayers[1], false);
      homeScore += 2;
      gameClockSeconds -= 20;

      // Home player 2 gets a steal (auto: away player turnover)
      await database.playerStatsDao.recordSteal(matchId, homePlayers[2]);
      await database.playerStatsDao.recordTurnover(matchId, awayPlayers[1]);

      await database.playByPlayDao.insertPlay(LocalPlayByPlaysCompanion.insert(
        localId: 'pbp-3',
        localMatchId: matchId,
        tournamentTeamPlayerId: homePlayers[2],
        tournamentTeamId: 1,
        quarter: 1,
        gameClockSeconds: gameClockSeconds,
        actionType: 'steal',
        homeScoreAtTime: homeScore,
        awayScoreAtTime: awayScore,
        createdAt: DateTime.now(),
      ));

      // Home player 3 gets a rebound
      await database.playerStatsDao.recordRebound(matchId, homePlayers[3], false);

      // Away player 2 commits a foul
      await database.playerStatsDao.recordFoul(matchId, awayPlayers[2]);

      // Update match score
      await database.matchDao.updateMatchScore(matchId, homeScore, awayScore);
      await database.matchDao.updateGameClock(matchId, gameClockSeconds);

      // 4. Verify data integrity
      // Verify match score
      final fetchedMatch = await database.matchDao.getMatchById(matchId);
      expect(fetchedMatch!.homeScore, equals(4)); // 2 + 2 FT
      expect(fetchedMatch.awayScore, equals(3)); // 3pt

      // Verify player stats
      final homePlayer0Stats = await database.playerStatsDao.getPlayerStats(matchId, homePlayers[0]);
      expect(homePlayer0Stats!.points, equals(2));
      expect(homePlayer0Stats.twoPointersMade, equals(1));
      expect(homePlayer0Stats.twoPointersAttempted, equals(1));

      final awayPlayer0Stats = await database.playerStatsDao.getPlayerStats(matchId, awayPlayers[0]);
      expect(awayPlayer0Stats!.points, equals(3));
      expect(awayPlayer0Stats.threePointersMade, equals(1));

      final homePlayer1Stats = await database.playerStatsDao.getPlayerStats(matchId, homePlayers[1]);
      expect(homePlayer1Stats!.points, equals(2));
      expect(homePlayer1Stats.freeThrowsMade, equals(2));
      expect(homePlayer1Stats.freeThrowsAttempted, equals(3));

      final homePlayer2Stats = await database.playerStatsDao.getPlayerStats(matchId, homePlayers[2]);
      expect(homePlayer2Stats!.steals, equals(1));

      final awayPlayer1Stats = await database.playerStatsDao.getPlayerStats(matchId, awayPlayers[1]);
      expect(awayPlayer1Stats!.turnovers, equals(1));

      final homePlayer3Stats = await database.playerStatsDao.getPlayerStats(matchId, homePlayers[3]);
      expect(homePlayer3Stats!.defensiveRebounds, equals(1));
      expect(homePlayer3Stats.totalRebounds, equals(1));

      final awayPlayer2Stats = await database.playerStatsDao.getPlayerStats(matchId, awayPlayers[2]);
      expect(awayPlayer2Stats!.personalFouls, equals(1));

      // Verify play-by-play count
      final plays = await database.playByPlayDao.getPlaysByMatch(matchId);
      expect(plays.length, equals(3)); // 2 shots + 1 steal

      // Verify shot chart
      final shotChart = await database.playByPlayDao.getShots(matchId);
      expect(shotChart.length, equals(2));

      // 5. Verify team totals
      final homeTeamStats = await database.playerStatsDao.getStatsByMatchAndTeam(matchId, 1);
      final homeTeamPoints = homeTeamStats.fold<int>(0, (sum, s) => sum + s.points);
      expect(homeTeamPoints, equals(homeScore));

      final awayTeamStats = await database.playerStatsDao.getStatsByMatchAndTeam(matchId, 2);
      final awayTeamPoints = awayTeamStats.fold<int>(0, (sum, s) => sum + s.points);
      expect(awayTeamPoints, equals(awayScore));
    });

    test('substitution flow: sub in/out players', () async {
      // Create match
      final match = LocalMatchesCompanion.insert(
        localUuid: 'sub-test-uuid',
        tournamentId: 'tournament-1',
        homeTeamId: 1,
        awayTeamId: 2,
        homeTeamName: '홈팀',
        awayTeamName: '원정팀',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final matchId = await database.matchDao.insertMatch(match);

      // Create starter player
      final starterStats = LocalPlayerStatsCompanion.insert(
        localMatchId: matchId,
        tournamentTeamPlayerId: 100,
        tournamentTeamId: 1,
        isStarter: const Value(true),
        isOnCourt: const Value(true),
        updatedAt: DateTime.now(),
      );
      await database.playerStatsDao.insertPlayerStats(starterStats);

      // Create bench player
      final benchStats = LocalPlayerStatsCompanion.insert(
        localMatchId: matchId,
        tournamentTeamPlayerId: 105,
        tournamentTeamId: 1,
        isStarter: const Value(false),
        isOnCourt: const Value(false),
        updatedAt: DateTime.now(),
      );
      await database.playerStatsDao.insertPlayerStats(benchStats);

      // Substitute: bench player in, starter out
      await database.playerStatsDao.setOnCourt(matchId, 100, false);
      await database.playerStatsDao.setOnCourt(matchId, 105, true);

      // Record substitution play
      await database.playByPlayDao.insertPlay(LocalPlayByPlaysCompanion.insert(
        localId: 'sub-pbp-1',
        localMatchId: matchId,
        tournamentTeamPlayerId: 105,
        tournamentTeamId: 1,
        quarter: 1,
        gameClockSeconds: 300,
        actionType: 'substitution',
        homeScoreAtTime: 10,
        awayScoreAtTime: 8,
        createdAt: DateTime.now(),
        subInPlayerId: const Value(105),
        subOutPlayerId: const Value(100),
      ));

      // Verify on-court status
      final starterFetched = await database.playerStatsDao.getPlayerStats(matchId, 100);
      expect(starterFetched!.isOnCourt, isFalse);

      final benchFetched = await database.playerStatsDao.getPlayerStats(matchId, 105);
      expect(benchFetched!.isOnCourt, isTrue);

      // Verify substitution record
      final plays = await database.playByPlayDao.getPlaysByMatch(matchId);
      expect(plays.length, equals(1));
      expect(plays.first.actionType, equals('substitution'));
      expect(plays.first.subInPlayerId, equals(105));
      expect(plays.first.subOutPlayerId, equals(100));
    });

    test('foul out scenario: 5 fouls triggers fouled out flag', () async {
      final match = LocalMatchesCompanion.insert(
        localUuid: 'foul-out-test-uuid',
        tournamentId: 'tournament-1',
        homeTeamId: 1,
        awayTeamId: 2,
        homeTeamName: '홈팀',
        awayTeamName: '원정팀',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final matchId = await database.matchDao.insertMatch(match);

      final stats = LocalPlayerStatsCompanion.insert(
        localMatchId: matchId,
        tournamentTeamPlayerId: 100,
        tournamentTeamId: 1,
        updatedAt: DateTime.now(),
      );
      await database.playerStatsDao.insertPlayerStats(stats);

      // Add 4 fouls - should not be fouled out yet
      for (var i = 0; i < 4; i++) {
        await database.playerStatsDao.recordFoul(matchId, 100);
      }

      var fetched = await database.playerStatsDao.getPlayerStats(matchId, 100);
      expect(fetched!.personalFouls, equals(4));
      expect(fetched.fouledOut, isFalse);

      // 5th foul - should trigger foul out
      await database.playerStatsDao.recordFoul(matchId, 100);

      fetched = await database.playerStatsDao.getPlayerStats(matchId, 100);
      expect(fetched!.personalFouls, equals(5));
      expect(fetched.fouledOut, isTrue);
    });

    test('undo last play: delete and verify', () async {
      final match = LocalMatchesCompanion.insert(
        localUuid: 'undo-test-uuid',
        tournamentId: 'tournament-1',
        homeTeamId: 1,
        awayTeamId: 2,
        homeTeamName: '홈팀',
        awayTeamName: '원정팀',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final matchId = await database.matchDao.insertMatch(match);

      // Create player stats
      final stats = LocalPlayerStatsCompanion.insert(
        localMatchId: matchId,
        tournamentTeamPlayerId: 100,
        tournamentTeamId: 1,
        updatedAt: DateTime.now(),
      );
      await database.playerStatsDao.insertPlayerStats(stats);

      // Record a shot
      await database.playerStatsDao.recordTwoPointer(matchId, 100, true);
      await database.playByPlayDao.insertPlay(LocalPlayByPlaysCompanion.insert(
        localId: 'undo-shot-1',
        localMatchId: matchId,
        tournamentTeamPlayerId: 100,
        tournamentTeamId: 1,
        quarter: 1,
        gameClockSeconds: 580,
        actionType: 'shot',
        homeScoreAtTime: 2,
        awayScoreAtTime: 0,
        createdAt: DateTime.now(),
        actionSubtype: const Value('2pt'),
        isMade: const Value(true),
        pointsScored: const Value(2),
      ));

      // Verify initial state
      var playerStats = await database.playerStatsDao.getPlayerStats(matchId, 100);
      expect(playerStats!.points, equals(2));

      var plays = await database.playByPlayDao.getPlaysByMatch(matchId);
      expect(plays.length, equals(1));

      // Get last play for undo
      final lastPlay = await database.playByPlayDao.getLastPlay(matchId);
      expect(lastPlay, isNotNull);
      expect(lastPlay!.localId, equals('undo-shot-1'));

      // Undo: delete play and revert stats
      await database.playByPlayDao.deletePlayByLocalId(lastPlay.localId);
      // In real app, stats would also be reverted
      // For this test, we just verify the play was deleted

      plays = await database.playByPlayDao.getPlaysByMatch(matchId);
      expect(plays.length, equals(0));
    });

    test('quarter transition: verify quarter scores are tracked', () async {
      final match = LocalMatchesCompanion.insert(
        localUuid: 'quarter-test-uuid',
        tournamentId: 'tournament-1',
        homeTeamId: 1,
        awayTeamId: 2,
        homeTeamName: '홈팀',
        awayTeamName: '원정팀',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final matchId = await database.matchDao.insertMatch(match);

      // Q1 ends with 20-18
      await database.matchDao.updateMatchScore(matchId, 20, 18);
      await database.matchDao.updateQuarterScores(matchId, '{"home":{"q1":20},"away":{"q1":18}}');
      await database.matchDao.updateQuarter(matchId, 2);

      var fetchedMatch = await database.matchDao.getMatchById(matchId);
      expect(fetchedMatch!.currentQuarter, equals(2));
      expect(fetchedMatch.quarterScoresJson.contains('"q1":20'), isTrue);

      // Q2 ends with 42-40 (22-22 in Q2)
      await database.matchDao.updateMatchScore(matchId, 42, 40);
      await database.matchDao.updateQuarterScores(
          matchId, '{"home":{"q1":20,"q2":22},"away":{"q1":18,"q2":22}}');
      await database.matchDao.updateQuarter(matchId, 3);

      fetchedMatch = await database.matchDao.getMatchById(matchId);
      expect(fetchedMatch!.currentQuarter, equals(3));
      expect(fetchedMatch.homeScore, equals(42));
      expect(fetchedMatch.awayScore, equals(40));
    });
  });
}
