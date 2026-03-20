import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bdr_tournament_recorder/data/database/database.dart';
import 'package:bdr_tournament_recorder/domain/usecases/usecases.dart';

void main() {
  late AppDatabase database;
  late RecordBlockUseCase useCase;
  late int testMatchId;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    useCase = RecordBlockUseCase(database);

    // Create test match
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

    // Create player stats for test players
    final blockPlayerStats = LocalPlayerStatsCompanion.insert(
      localMatchId: testMatchId,
      tournamentTeamPlayerId: 101, // Block player
      tournamentTeamId: 1,
      updatedAt: DateTime.now(),
    );
    await database.playerStatsDao.insertPlayerStats(blockPlayerStats);

    final shooterPlayerStats = LocalPlayerStatsCompanion.insert(
      localMatchId: testMatchId,
      tournamentTeamPlayerId: 201, // Shooter (opponent)
      tournamentTeamId: 2,
      updatedAt: DateTime.now(),
    );
    await database.playerStatsDao.insertPlayerStats(shooterPlayerStats);
  });

  tearDown(() async {
    await database.close();
  });

  group('RecordBlockUseCase', () {
    test('블락 기록 시 상대 2점슛 실패가 자동으로 기록되어야 함', () async {
      // CLAUDE.md: "블락 → 상대 슛 실패" 자동 연동 테스트

      final result = await useCase.execute(
        matchId: testMatchId,
        blockPlayerId: 101,
        blockPlayerTeamId: 1,
        shooterPlayerId: 201,
        shooterPlayerTeamId: 2,
        quarter: 1,
        gameClockSeconds: 540,
        homeScore: 10,
        awayScore: 8,
        isThreePointer: false, // 2점슛
      );

      // 결과 확인
      expect(result.success, isTrue);
      expect(result.primaryActionId, isNotEmpty);
      expect(result.linkedActionId, isNotEmpty);

      // 블락 선수 스탯 확인
      final blockPlayerStats = await database.playerStatsDao.getPlayerStats(
        testMatchId,
        101,
      );
      expect(blockPlayerStats!.blocks, equals(1));

      // 슈터 슛 실패 스탯 확인 (자동 연동!)
      final shooterStats = await database.playerStatsDao.getPlayerStats(
        testMatchId,
        201,
      );
      expect(shooterStats!.twoPointersAttempted, equals(1));
      expect(shooterStats.twoPointersMade, equals(0));
      expect(shooterStats.fieldGoalsAttempted, equals(1));
      expect(shooterStats.fieldGoalsMade, equals(0));
    });

    test('블락 기록 시 상대 3점슛 실패가 자동으로 기록되어야 함', () async {
      final result = await useCase.execute(
        matchId: testMatchId,
        blockPlayerId: 101,
        blockPlayerTeamId: 1,
        shooterPlayerId: 201,
        shooterPlayerTeamId: 2,
        quarter: 1,
        gameClockSeconds: 540,
        homeScore: 10,
        awayScore: 8,
        isThreePointer: true, // 3점슛
      );

      expect(result.success, isTrue);

      // 슈터 3점슛 실패 스탯 확인
      final shooterStats = await database.playerStatsDao.getPlayerStats(
        testMatchId,
        201,
      );
      expect(shooterStats!.threePointersAttempted, equals(1));
      expect(shooterStats.threePointersMade, equals(0));
      expect(shooterStats.fieldGoalsAttempted, equals(1));
      expect(shooterStats.fieldGoalsMade, equals(0));
    });

    test('블락 기록 시 Play-by-Play 기록이 양쪽 모두 생성되어야 함', () async {
      final result = await useCase.execute(
        matchId: testMatchId,
        blockPlayerId: 101,
        blockPlayerTeamId: 1,
        shooterPlayerId: 201,
        shooterPlayerTeamId: 2,
        quarter: 1,
        gameClockSeconds: 540,
        homeScore: 10,
        awayScore: 8,
        isThreePointer: false,
        courtX: 50.0,
        courtY: 30.0,
        courtZone: 5,
      );

      expect(result.success, isTrue);

      // Play-by-Play 기록 확인
      final plays = await database.playByPlayDao.getPlaysByMatch(testMatchId);
      expect(plays.length, equals(2));

      // 블락 기록 확인
      final blockPlay = plays.firstWhere((p) => p.actionType == 'block');
      expect(blockPlay.tournamentTeamPlayerId, equals(101));
      expect(blockPlay.linkedActionId, isNotNull);

      // 슛 실패 기록 확인
      final shotPlay = plays.firstWhere((p) => p.actionType == 'shot');
      expect(shotPlay.tournamentTeamPlayerId, equals(201));
      expect(shotPlay.isMade, isFalse);
      expect(shotPlay.pointsScored, equals(0));
      expect(shotPlay.courtX, equals(50.0));
      expect(shotPlay.courtY, equals(30.0));
      expect(shotPlay.linkedActionId, isNotNull);

      // 두 기록이 서로 연결되어 있는지 확인
      expect(blockPlay.linkedActionId, equals(shotPlay.localId));
      expect(shotPlay.linkedActionId, equals(blockPlay.localId));
    });

    test('블락 기록 취소 시 양쪽 스탯과 Play-by-Play가 롤백되어야 함', () async {
      // 먼저 블락 기록
      final result = await useCase.execute(
        matchId: testMatchId,
        blockPlayerId: 101,
        blockPlayerTeamId: 1,
        shooterPlayerId: 201,
        shooterPlayerTeamId: 2,
        quarter: 1,
        gameClockSeconds: 540,
        homeScore: 10,
        awayScore: 8,
        isThreePointer: false,
      );

      expect(result.success, isTrue);

      // Undo 실행
      final undoSuccess = await useCase.undo(
        matchId: testMatchId,
        blockPlayerId: 101,
        shooterPlayerId: 201,
        blockLocalId: result.primaryActionId,
        shotMissLocalId: result.linkedActionId!,
        isThreePointer: false,
      );

      expect(undoSuccess, isTrue);

      // 블락 선수 스탯 확인 (롤백)
      final blockPlayerStats = await database.playerStatsDao.getPlayerStats(
        testMatchId,
        101,
      );
      expect(blockPlayerStats!.blocks, equals(0));

      // 슈터 스탯 확인 (롤백)
      final shooterStats = await database.playerStatsDao.getPlayerStats(
        testMatchId,
        201,
      );
      expect(shooterStats!.twoPointersAttempted, equals(0));
      expect(shooterStats.fieldGoalsAttempted, equals(0));

      // Play-by-Play 삭제 확인
      final plays = await database.playByPlayDao.getPlaysByMatch(testMatchId);
      expect(plays.length, equals(0));
    });

    test('3점슛 블락 취소 시 3점슛 스탯이 롤백되어야 함', () async {
      // 3점슛 블락 기록
      final result = await useCase.execute(
        matchId: testMatchId,
        blockPlayerId: 101,
        blockPlayerTeamId: 1,
        shooterPlayerId: 201,
        shooterPlayerTeamId: 2,
        quarter: 1,
        gameClockSeconds: 540,
        homeScore: 10,
        awayScore: 8,
        isThreePointer: true,
      );

      // Undo 실행
      await useCase.undo(
        matchId: testMatchId,
        blockPlayerId: 101,
        shooterPlayerId: 201,
        blockLocalId: result.primaryActionId,
        shotMissLocalId: result.linkedActionId!,
        isThreePointer: true,
      );

      // 슈터 3점슛 스탯 확인 (롤백)
      final shooterStats = await database.playerStatsDao.getPlayerStats(
        testMatchId,
        201,
      );
      expect(shooterStats!.threePointersAttempted, equals(0));
    });

    test('결과 metadata에 올바른 정보가 포함되어야 함', () async {
      final result = await useCase.execute(
        matchId: testMatchId,
        blockPlayerId: 101,
        blockPlayerTeamId: 1,
        shooterPlayerId: 201,
        shooterPlayerTeamId: 2,
        quarter: 1,
        gameClockSeconds: 540,
        homeScore: 10,
        awayScore: 8,
        isThreePointer: true,
      );

      expect(result.metadata, isNotNull);
      expect(result.metadata!['blockPlayerId'], equals(101));
      expect(result.metadata!['shooterPlayerId'], equals(201));
      expect(result.metadata!['isThreePointer'], isTrue);
    });
  });
}
