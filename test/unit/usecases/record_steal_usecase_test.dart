import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bdr_tournament_recorder/data/database/database.dart';
import 'package:bdr_tournament_recorder/domain/usecases/usecases.dart';

void main() {
  late AppDatabase database;
  late RecordStealUseCase useCase;
  late int testMatchId;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    useCase = RecordStealUseCase(database);

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
    final stealPlayerStats = LocalPlayerStatsCompanion.insert(
      localMatchId: testMatchId,
      tournamentTeamPlayerId: 101, // Steal player
      tournamentTeamId: 1,
      updatedAt: DateTime.now(),
    );
    await database.playerStatsDao.insertPlayerStats(stealPlayerStats);

    final turnoverPlayerStats = LocalPlayerStatsCompanion.insert(
      localMatchId: testMatchId,
      tournamentTeamPlayerId: 201, // Turnover player (opponent)
      tournamentTeamId: 2,
      updatedAt: DateTime.now(),
    );
    await database.playerStatsDao.insertPlayerStats(turnoverPlayerStats);
  });

  tearDown(() async {
    await database.close();
  });

  group('RecordStealUseCase', () {
    test('스틸 기록 시 상대 턴오버가 자동으로 기록되어야 함', () async {
      // CLAUDE.md: "스틸 → 상대 턴오버" 자동 연동 테스트

      final result = await useCase.execute(
        matchId: testMatchId,
        stealPlayerId: 101,
        stealPlayerTeamId: 1,
        turnoverPlayerId: 201,
        turnoverPlayerTeamId: 2,
        quarter: 1,
        gameClockSeconds: 540,
        homeScore: 10,
        awayScore: 8,
      );

      // 결과 확인
      expect(result.success, isTrue);
      expect(result.primaryActionId, isNotEmpty);
      expect(result.linkedActionId, isNotEmpty);

      // 스틸 선수 스탯 확인
      final stealPlayerStats = await database.playerStatsDao.getPlayerStats(
        testMatchId,
        101,
      );
      expect(stealPlayerStats!.steals, equals(1));

      // 턴오버 선수 스탯 확인 (자동 연동!)
      final turnoverPlayerStats = await database.playerStatsDao.getPlayerStats(
        testMatchId,
        201,
      );
      expect(turnoverPlayerStats!.turnovers, equals(1));
    });

    test('스틸 기록 시 Play-by-Play 기록이 양쪽 모두 생성되어야 함', () async {
      final result = await useCase.execute(
        matchId: testMatchId,
        stealPlayerId: 101,
        stealPlayerTeamId: 1,
        turnoverPlayerId: 201,
        turnoverPlayerTeamId: 2,
        quarter: 1,
        gameClockSeconds: 540,
        homeScore: 10,
        awayScore: 8,
      );

      expect(result.success, isTrue);

      // Play-by-Play 기록 확인
      final plays = await database.playByPlayDao.getPlaysByMatch(testMatchId);
      expect(plays.length, equals(2));

      // 스틸 기록 확인
      final stealPlay = plays.firstWhere((p) => p.actionType == 'steal');
      expect(stealPlay.tournamentTeamPlayerId, equals(101));
      expect(stealPlay.linkedActionId, isNotNull);

      // 턴오버 기록 확인
      final turnoverPlay = plays.firstWhere((p) => p.actionType == 'turnover');
      expect(turnoverPlay.tournamentTeamPlayerId, equals(201));
      expect(turnoverPlay.actionSubtype, equals('stolen'));
      expect(turnoverPlay.linkedActionId, isNotNull);

      // 두 기록이 서로 연결되어 있는지 확인
      expect(stealPlay.linkedActionId, equals(turnoverPlay.localId));
      expect(turnoverPlay.linkedActionId, equals(stealPlay.localId));
    });

    test('스틸 기록 취소 시 양쪽 스탯과 Play-by-Play가 롤백되어야 함', () async {
      // 먼저 스틸 기록
      final result = await useCase.execute(
        matchId: testMatchId,
        stealPlayerId: 101,
        stealPlayerTeamId: 1,
        turnoverPlayerId: 201,
        turnoverPlayerTeamId: 2,
        quarter: 1,
        gameClockSeconds: 540,
        homeScore: 10,
        awayScore: 8,
      );

      expect(result.success, isTrue);

      // Undo 실행
      final undoSuccess = await useCase.undo(
        matchId: testMatchId,
        stealPlayerId: 101,
        turnoverPlayerId: 201,
        stealLocalId: result.primaryActionId,
        turnoverLocalId: result.linkedActionId!,
      );

      expect(undoSuccess, isTrue);

      // 스틸 선수 스탯 확인 (롤백)
      final stealPlayerStats = await database.playerStatsDao.getPlayerStats(
        testMatchId,
        101,
      );
      expect(stealPlayerStats!.steals, equals(0));

      // 턴오버 선수 스탯 확인 (롤백)
      final turnoverPlayerStats = await database.playerStatsDao.getPlayerStats(
        testMatchId,
        201,
      );
      expect(turnoverPlayerStats!.turnovers, equals(0));

      // Play-by-Play 삭제 확인
      final plays = await database.playByPlayDao.getPlaysByMatch(testMatchId);
      expect(plays.length, equals(0));
    });

    test('여러 번 스틸 기록 시 누적되어야 함', () async {
      // 첫 번째 스틸
      await useCase.execute(
        matchId: testMatchId,
        stealPlayerId: 101,
        stealPlayerTeamId: 1,
        turnoverPlayerId: 201,
        turnoverPlayerTeamId: 2,
        quarter: 1,
        gameClockSeconds: 540,
        homeScore: 10,
        awayScore: 8,
      );

      // 두 번째 스틸
      await useCase.execute(
        matchId: testMatchId,
        stealPlayerId: 101,
        stealPlayerTeamId: 1,
        turnoverPlayerId: 201,
        turnoverPlayerTeamId: 2,
        quarter: 1,
        gameClockSeconds: 480,
        homeScore: 12,
        awayScore: 8,
      );

      // 스틸 선수 스탯 확인
      final stealPlayerStats = await database.playerStatsDao.getPlayerStats(
        testMatchId,
        101,
      );
      expect(stealPlayerStats!.steals, equals(2));

      // 턴오버 선수 스탯 확인
      final turnoverPlayerStats = await database.playerStatsDao.getPlayerStats(
        testMatchId,
        201,
      );
      expect(turnoverPlayerStats!.turnovers, equals(2));
    });

    test('결과 metadata에 올바른 정보가 포함되어야 함', () async {
      final result = await useCase.execute(
        matchId: testMatchId,
        stealPlayerId: 101,
        stealPlayerTeamId: 1,
        turnoverPlayerId: 201,
        turnoverPlayerTeamId: 2,
        quarter: 1,
        gameClockSeconds: 540,
        homeScore: 10,
        awayScore: 8,
      );

      expect(result.metadata, isNotNull);
      expect(result.metadata!['stealPlayerId'], equals(101));
      expect(result.metadata!['turnoverPlayerId'], equals(201));
    });
  });
}
