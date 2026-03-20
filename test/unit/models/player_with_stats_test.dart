import 'package:flutter_test/flutter_test.dart';
import 'package:bdr_tournament_recorder/data/database/database.dart';
import 'package:bdr_tournament_recorder/presentation/screens/recording/models/player_with_stats.dart';

void main() {
  // Helper to create test player
  LocalTournamentPlayer createPlayer({
    int id = 1,
    int tournamentTeamId = 1,
    String userName = 'Test Player',
    int? jerseyNumber = 23,
    String? position = 'PG',
    String role = 'player',
    bool isStarter = true,
    bool isActive = true,
  }) {
    return LocalTournamentPlayer(
      id: id,
      tournamentTeamId: tournamentTeamId,
      userName: userName,
      userNickname: null,
      profileImageUrl: null,
      jerseyNumber: jerseyNumber,
      position: position,
      role: role,
      isStarter: isStarter,
      isActive: isActive,
      syncedAt: DateTime.now(),
    );
  }

  // Helper to create test stats
  LocalPlayerStat createStats({
    int id = 1,
    int localMatchId = 1,
    int tournamentTeamPlayerId = 1,
    int tournamentTeamId = 1,
    bool isStarter = true,
    bool isOnCourt = true,
    int minutesPlayed = 0,
    int points = 0,
    int fieldGoalsMade = 0,
    int fieldGoalsAttempted = 0,
    int twoPointersMade = 0,
    int twoPointersAttempted = 0,
    int threePointersMade = 0,
    int threePointersAttempted = 0,
    int freeThrowsMade = 0,
    int freeThrowsAttempted = 0,
    int offensiveRebounds = 0,
    int defensiveRebounds = 0,
    int totalRebounds = 0,
    int assists = 0,
    int steals = 0,
    int blocks = 0,
    int turnovers = 0,
    int personalFouls = 0,
    int plusMinus = 0,
    bool fouledOut = false,
    bool ejected = false,
    bool isManuallyEdited = false,
  }) {
    return LocalPlayerStat(
      id: id,
      localMatchId: localMatchId,
      tournamentTeamPlayerId: tournamentTeamPlayerId,
      tournamentTeamId: tournamentTeamId,
      isStarter: isStarter,
      isOnCourt: isOnCourt,
      minutesPlayed: minutesPlayed,
      points: points,
      fieldGoalsMade: fieldGoalsMade,
      fieldGoalsAttempted: fieldGoalsAttempted,
      twoPointersMade: twoPointersMade,
      twoPointersAttempted: twoPointersAttempted,
      threePointersMade: threePointersMade,
      threePointersAttempted: threePointersAttempted,
      freeThrowsMade: freeThrowsMade,
      freeThrowsAttempted: freeThrowsAttempted,
      offensiveRebounds: offensiveRebounds,
      defensiveRebounds: defensiveRebounds,
      totalRebounds: totalRebounds,
      assists: assists,
      steals: steals,
      blocks: blocks,
      turnovers: turnovers,
      personalFouls: personalFouls,
      plusMinus: plusMinus,
      fouledOut: fouledOut,
      ejected: ejected,
      isManuallyEdited: isManuallyEdited,
      updatedAt: DateTime.now(),
    );
  }

  group('PlayerWithStats', () {
    test('should create with player and stats', () {
      final player = createPlayer(userName: 'John Doe');
      final stats = createStats();
      final playerWithStats = PlayerWithStats(player: player, stats: stats);

      expect(playerWithStats.player, player);
      expect(playerWithStats.stats, stats);
    });

    group('convenience getters', () {
      test('name should return player userName', () {
        final player = createPlayer(userName: 'Michael Jordan');
        final stats = createStats();
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.name, 'Michael Jordan');
      });

      test('jerseyNumber should return player jerseyNumber', () {
        final player = createPlayer(jerseyNumber: 23);
        final stats = createStats();
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.jerseyNumber, 23);
      });

      test('jerseyNumber should return null when not set', () {
        final player = createPlayer(jerseyNumber: null);
        final stats = createStats();
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.jerseyNumber, isNull);
      });

      test('isOnCourt should return stats isOnCourt', () {
        final player = createPlayer();
        final onCourtStats = createStats(isOnCourt: true);
        final offCourtStats = createStats(isOnCourt: false);

        final onCourt = PlayerWithStats(player: player, stats: onCourtStats);
        final offCourt = PlayerWithStats(player: player, stats: offCourtStats);

        expect(onCourt.isOnCourt, true);
        expect(offCourt.isOnCourt, false);
      });
    });

    group('points calculation', () {
      test('should calculate points correctly with all shot types', () {
        final player = createPlayer();
        final stats = createStats(
          twoPointersMade: 5, // 10 points
          threePointersMade: 3, // 9 points
          freeThrowsMade: 4, // 4 points
        );
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.points, 23); // 10 + 9 + 4
      });

      test('should return 0 when no shots made', () {
        final player = createPlayer();
        final stats = createStats(
          twoPointersMade: 0,
          threePointersMade: 0,
          freeThrowsMade: 0,
        );
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.points, 0);
      });

      test('should calculate correctly with only 2-pointers', () {
        final player = createPlayer();
        final stats = createStats(twoPointersMade: 7);
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.points, 14);
      });

      test('should calculate correctly with only 3-pointers', () {
        final player = createPlayer();
        final stats = createStats(threePointersMade: 5);
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.points, 15);
      });

      test('should calculate correctly with only free throws', () {
        final player = createPlayer();
        final stats = createStats(freeThrowsMade: 8);
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.points, 8);
      });
    });

    group('rebounds calculation', () {
      test('should calculate total rebounds', () {
        final player = createPlayer();
        final stats = createStats(
          offensiveRebounds: 3,
          defensiveRebounds: 7,
        );
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.rebounds, 10);
      });

      test('should return 0 when no rebounds', () {
        final player = createPlayer();
        final stats = createStats(
          offensiveRebounds: 0,
          defensiveRebounds: 0,
        );
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.rebounds, 0);
      });
    });

    group('shot attempts and made', () {
      test('should calculate total shot attempts', () {
        final player = createPlayer();
        final stats = createStats(
          twoPointersAttempted: 10,
          threePointersAttempted: 5,
        );
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.shotAttempts, 15);
      });

      test('should calculate total shots made', () {
        final player = createPlayer();
        final stats = createStats(
          twoPointersMade: 6,
          threePointersMade: 3,
        );
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.shotMade, 9);
      });
    });

    group('shotPercentage', () {
      test('should calculate shot percentage correctly', () {
        final player = createPlayer();
        final stats = createStats(
          twoPointersMade: 4,
          twoPointersAttempted: 8,
          threePointersMade: 2,
          threePointersAttempted: 4,
        );
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        // 6 made / 12 attempts = 50%
        expect(playerWithStats.shotPercentage, 50.0);
      });

      test('should return 0.0 when no shots attempted', () {
        final player = createPlayer();
        final stats = createStats(
          twoPointersMade: 0,
          twoPointersAttempted: 0,
          threePointersMade: 0,
          threePointersAttempted: 0,
        );
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.shotPercentage, 0.0);
      });

      test('should handle 100% shooting', () {
        final player = createPlayer();
        final stats = createStats(
          twoPointersMade: 5,
          twoPointersAttempted: 5,
        );
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.shotPercentage, 100.0);
      });
    });

    group('threePointPercentage', () {
      test('should calculate 3pt percentage correctly', () {
        final player = createPlayer();
        final stats = createStats(
          threePointersMade: 3,
          threePointersAttempted: 10,
        );
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.threePointPercentage, 30.0);
      });

      test('should return 0.0 when no 3pt attempted', () {
        final player = createPlayer();
        final stats = createStats(
          threePointersMade: 0,
          threePointersAttempted: 0,
        );
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.threePointPercentage, 0.0);
      });
    });

    group('freeThrowPercentage', () {
      test('should calculate FT percentage correctly', () {
        final player = createPlayer();
        final stats = createStats(
          freeThrowsMade: 8,
          freeThrowsAttempted: 10,
        );
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.freeThrowPercentage, 80.0);
      });

      test('should return 0.0 when no FT attempted', () {
        final player = createPlayer();
        final stats = createStats(
          freeThrowsMade: 0,
          freeThrowsAttempted: 0,
        );
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.freeThrowPercentage, 0.0);
      });
    });

    group('statSummary', () {
      test('should format stat summary correctly', () {
        final player = createPlayer();
        final stats = createStats(
          twoPointersMade: 5, // 10pts
          threePointersMade: 2, // 6pts
          freeThrowsMade: 2, // 2pts = 18 total
          offensiveRebounds: 2,
          defensiveRebounds: 5, // 7 total
          assists: 4,
        );
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.statSummary, '18점 7R 4A');
      });

      test('should handle zero stats', () {
        final player = createPlayer();
        final stats = createStats();
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.statSummary, '0점 0R 0A');
      });
    });

    group('pointsDisplay', () {
      test('should return points as string', () {
        final player = createPlayer();
        final stats = createStats(twoPointersMade: 10);
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.pointsDisplay, '20');
      });

      test('should return 0 for zero points', () {
        final player = createPlayer();
        final stats = createStats();
        final playerWithStats = PlayerWithStats(player: player, stats: stats);

        expect(playerWithStats.pointsDisplay, '0');
      });
    });

    group('equality', () {
      test('should be equal when same player id', () {
        final player = createPlayer(id: 1);
        final stats1 = createStats(points: 10);
        final stats2 = createStats(points: 20);

        final p1 = PlayerWithStats(player: player, stats: stats1);
        final p2 = PlayerWithStats(player: player, stats: stats2);

        expect(p1 == p2, true);
        expect(p1.hashCode, p2.hashCode);
      });

      test('should not be equal when different player id', () {
        final player1 = createPlayer(id: 1);
        final player2 = createPlayer(id: 2);
        final stats = createStats();

        final p1 = PlayerWithStats(player: player1, stats: stats);
        final p2 = PlayerWithStats(player: player2, stats: stats);

        expect(p1 == p2, false);
      });

      test('should not be equal to different instances', () {
        final player = createPlayer();
        final stats = createStats();
        final playerWithStats1 = PlayerWithStats(player: player, stats: stats);
        final playerWithStats2 = PlayerWithStats(
          player: createPlayer(id: 999),
          stats: stats,
        );

        // Different player ID means different instance
        expect(playerWithStats1 == playerWithStats2, false);
      });
    });
  });
}
