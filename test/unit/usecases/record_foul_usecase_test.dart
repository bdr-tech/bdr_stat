import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bdr_tournament_recorder/data/database/database.dart';
import 'package:bdr_tournament_recorder/domain/usecases/usecases.dart';

void main() {
  late AppDatabase database;
  late RecordFoulUseCase useCase;
  late int testMatchId;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    useCase = RecordFoulUseCase(database);

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
    final foulPlayerStats = LocalPlayerStatsCompanion.insert(
      localMatchId: testMatchId,
      tournamentTeamPlayerId: 101, // Foul player
      tournamentTeamId: 1,
      updatedAt: DateTime.now(),
    );
    await database.playerStatsDao.insertPlayerStats(foulPlayerStats);

    final fouledPlayerStats = LocalPlayerStatsCompanion.insert(
      localMatchId: testMatchId,
      tournamentTeamPlayerId: 201, // Fouled player (opponent)
      tournamentTeamId: 2,
      updatedAt: DateTime.now(),
    );
    await database.playerStatsDao.insertPlayerStats(fouledPlayerStats);
  });

  tearDown(() async {
    await database.close();
  });

  group('RecordFoulUseCase - Personal Foul', () {
    test('일반 파울 기록 시 파울 스탯이 증가해야 함', () async {
      final result = await useCase.executePersonalFoul(
        matchId: testMatchId,
        foulPlayerId: 101,
        foulPlayerTeamId: 1,
        quarter: 1,
        gameClockSeconds: 540,
        homeScore: 10,
        awayScore: 8,
      );

      expect(result.success, isTrue);
      expect(result.primaryActionId, isNotEmpty);

      // 파울 선수 스탯 확인
      final foulPlayerStats = await database.playerStatsDao.getPlayerStats(
        testMatchId,
        101,
      );
      expect(foulPlayerStats!.personalFouls, equals(1));
      expect(foulPlayerStats.fouledOut, isFalse);
    });

    test('5파울 시 fouledOut이 true가 되어야 함', () async {
      // 5번 파울 기록
      for (var i = 0; i < 5; i++) {
        await useCase.executePersonalFoul(
          matchId: testMatchId,
          foulPlayerId: 101,
          foulPlayerTeamId: 1,
          quarter: 1,
          gameClockSeconds: 540 - (i * 60),
          homeScore: 10,
          awayScore: 8,
        );
      }

      final foulPlayerStats = await database.playerStatsDao.getPlayerStats(
        testMatchId,
        101,
      );
      expect(foulPlayerStats!.personalFouls, equals(5));
      expect(foulPlayerStats.fouledOut, isTrue);
    });

    test('5파울 시 결과 metadata에 isFouledOut이 true로 반환되어야 함', () async {
      // 4번 파울 먼저 기록
      for (var i = 0; i < 4; i++) {
        await useCase.executePersonalFoul(
          matchId: testMatchId,
          foulPlayerId: 101,
          foulPlayerTeamId: 1,
          quarter: 1,
          gameClockSeconds: 540 - (i * 60),
          homeScore: 10,
          awayScore: 8,
        );
      }

      // 5번째 파울
      final result = await useCase.executePersonalFoul(
        matchId: testMatchId,
        foulPlayerId: 101,
        foulPlayerTeamId: 1,
        quarter: 1,
        gameClockSeconds: 300,
        homeScore: 10,
        awayScore: 8,
      );

      expect(result.metadata!['isFouledOut'], isTrue);
    });

    test('일반 파울 취소 시 파울 스탯이 롤백되어야 함', () async {
      final result = await useCase.executePersonalFoul(
        matchId: testMatchId,
        foulPlayerId: 101,
        foulPlayerTeamId: 1,
        quarter: 1,
        gameClockSeconds: 540,
        homeScore: 10,
        awayScore: 8,
      );

      // Undo 실행
      final undoSuccess = await useCase.undoPersonalFoul(
        matchId: testMatchId,
        foulPlayerId: 101,
        foulLocalId: result.primaryActionId,
      );

      expect(undoSuccess, isTrue);

      final foulPlayerStats = await database.playerStatsDao.getPlayerStats(
        testMatchId,
        101,
      );
      expect(foulPlayerStats!.personalFouls, equals(0));

      // Play-by-Play 삭제 확인
      final plays = await database.playByPlayDao.getPlaysByMatch(testMatchId);
      expect(plays.length, equals(0));
    });
  });

  group('RecordFoulUseCase - Offensive Foul', () {
    test('오펜시브 파울 기록 시 본인 턴오버가 자동으로 기록되어야 함', () async {
      // CLAUDE.md: "오펜시브 파울 → 본인 턴오버" 자동 연동 테스트

      final result = await useCase.executeOffensiveFoul(
        matchId: testMatchId,
        foulPlayerId: 101,
        foulPlayerTeamId: 1,
        quarter: 1,
        gameClockSeconds: 540,
        homeScore: 10,
        awayScore: 8,
      );

      expect(result.success, isTrue);
      expect(result.primaryActionId, isNotEmpty);
      expect(result.linkedActionId, isNotEmpty);

      // 파울 선수 스탯 확인
      final foulPlayerStats = await database.playerStatsDao.getPlayerStats(
        testMatchId,
        101,
      );
      expect(foulPlayerStats!.personalFouls, equals(1));
      expect(foulPlayerStats.turnovers, equals(1)); // 자동 연동!
    });

    test('오펜시브 파울 기록 시 Play-by-Play 기록이 양쪽 모두 생성되어야 함', () async {
      final result = await useCase.executeOffensiveFoul(
        matchId: testMatchId,
        foulPlayerId: 101,
        foulPlayerTeamId: 1,
        quarter: 1,
        gameClockSeconds: 540,
        homeScore: 10,
        awayScore: 8,
      );

      expect(result.success, isTrue);

      // Play-by-Play 기록 확인
      final plays = await database.playByPlayDao.getPlaysByMatch(testMatchId);
      expect(plays.length, equals(2));

      // 파울 기록 확인
      final foulPlay = plays.firstWhere((p) => p.actionType == 'foul');
      expect(foulPlay.tournamentTeamPlayerId, equals(101));
      expect(foulPlay.actionSubtype, equals('offensive'));
      expect(foulPlay.linkedActionId, isNotNull);

      // 턴오버 기록 확인
      final turnoverPlay = plays.firstWhere((p) => p.actionType == 'turnover');
      expect(turnoverPlay.tournamentTeamPlayerId, equals(101)); // 본인!
      expect(turnoverPlay.actionSubtype, equals('offensive_foul'));
      expect(turnoverPlay.linkedActionId, isNotNull);

      // 두 기록이 서로 연결되어 있는지 확인
      expect(foulPlay.linkedActionId, equals(turnoverPlay.localId));
      expect(turnoverPlay.linkedActionId, equals(foulPlay.localId));
    });

    test('오펜시브 파울 취소 시 파울과 턴오버 모두 롤백되어야 함', () async {
      final result = await useCase.executeOffensiveFoul(
        matchId: testMatchId,
        foulPlayerId: 101,
        foulPlayerTeamId: 1,
        quarter: 1,
        gameClockSeconds: 540,
        homeScore: 10,
        awayScore: 8,
      );

      // Undo 실행
      final undoSuccess = await useCase.undoOffensiveFoul(
        matchId: testMatchId,
        foulPlayerId: 101,
        foulLocalId: result.primaryActionId,
        turnoverLocalId: result.linkedActionId!,
      );

      expect(undoSuccess, isTrue);

      final foulPlayerStats = await database.playerStatsDao.getPlayerStats(
        testMatchId,
        101,
      );
      expect(foulPlayerStats!.personalFouls, equals(0));
      expect(foulPlayerStats.turnovers, equals(0));

      // Play-by-Play 삭제 확인
      final plays = await database.playByPlayDao.getPlaysByMatch(testMatchId);
      expect(plays.length, equals(0));
    });
  });

  group('RecordFoulUseCase - Shooting Foul', () {
    test('슈팅 파울 기록 시 자유투 시퀀스 정보가 반환되어야 함', () async {
      // CLAUDE.md: "슈팅 파울 → 자유투 시퀀스" 테스트

      final result = await useCase.executeShootingFoul(
        matchId: testMatchId,
        foulPlayerId: 101,
        foulPlayerTeamId: 1,
        fouledPlayerId: 201,
        fouledPlayerTeamId: 2,
        quarter: 1,
        gameClockSeconds: 540,
        homeScore: 10,
        awayScore: 8,
        freeThrowCount: 2,
      );

      expect(result.success, isTrue);
      expect(result.metadata, isNotNull);

      // 자유투 시퀀스 정보 확인
      final ftSequence = result.metadata!['freeThrowSequence'] as Map<String, dynamic>;
      expect(ftSequence['totalShots'], equals(2));
      expect(ftSequence['shooterPlayerId'], equals(201));
      expect(ftSequence['foulPlayerId'], equals(101));
    });

    test('3점슛 중 슈팅 파울 시 자유투 3개가 반환되어야 함', () async {
      final result = await useCase.executeShootingFoul(
        matchId: testMatchId,
        foulPlayerId: 101,
        foulPlayerTeamId: 1,
        fouledPlayerId: 201,
        fouledPlayerTeamId: 2,
        quarter: 1,
        gameClockSeconds: 540,
        homeScore: 10,
        awayScore: 8,
        freeThrowCount: 2,
        wasShootingThreePointer: true,
      );

      expect(result.success, isTrue);

      final ftSequence = result.metadata!['freeThrowSequence'] as Map<String, dynamic>;
      expect(ftSequence['totalShots'], equals(3)); // 3점슛 → 3개
    });

    test('슈팅 파울 기록 시 파울 스탯이 증가하고 Play-by-Play가 생성되어야 함', () async {
      final result = await useCase.executeShootingFoul(
        matchId: testMatchId,
        foulPlayerId: 101,
        foulPlayerTeamId: 1,
        fouledPlayerId: 201,
        fouledPlayerTeamId: 2,
        quarter: 1,
        gameClockSeconds: 540,
        homeScore: 10,
        awayScore: 8,
        freeThrowCount: 2,
      );

      expect(result.success, isTrue);

      // 파울 선수 스탯 확인
      final foulPlayerStats = await database.playerStatsDao.getPlayerStats(
        testMatchId,
        101,
      );
      expect(foulPlayerStats!.personalFouls, equals(1));

      // Play-by-Play 기록 확인
      final plays = await database.playByPlayDao.getPlaysByMatch(testMatchId);
      expect(plays.length, equals(1));

      final foulPlay = plays.first;
      expect(foulPlay.actionType, equals('foul'));
      expect(foulPlay.actionSubtype, equals('shooting'));
      expect(foulPlay.fouledPlayerId, equals(201));
    });

    test('슈팅 파울 취소 시 파울 스탯이 롤백되어야 함', () async {
      final result = await useCase.executeShootingFoul(
        matchId: testMatchId,
        foulPlayerId: 101,
        foulPlayerTeamId: 1,
        fouledPlayerId: 201,
        fouledPlayerTeamId: 2,
        quarter: 1,
        gameClockSeconds: 540,
        homeScore: 10,
        awayScore: 8,
        freeThrowCount: 2,
      );

      // Undo 실행
      final undoSuccess = await useCase.undoShootingFoul(
        matchId: testMatchId,
        foulPlayerId: 101,
        foulLocalId: result.primaryActionId,
      );

      expect(undoSuccess, isTrue);

      final foulPlayerStats = await database.playerStatsDao.getPlayerStats(
        testMatchId,
        101,
      );
      expect(foulPlayerStats!.personalFouls, equals(0));

      // Play-by-Play 삭제 확인
      final plays = await database.playByPlayDao.getPlaysByMatch(testMatchId);
      expect(plays.length, equals(0));
    });
  });

  group('FreeThrowSequence', () {
    test('FreeThrowSequence toMap()이 올바른 형태를 반환해야 함', () {
      final sequence = FreeThrowSequence(
        totalShots: 2,
        shooterPlayerId: 201,
        foulPlayerId: 101,
      );

      final map = sequence.toMap();
      expect(map['totalShots'], equals(2));
      expect(map['shooterPlayerId'], equals(201));
      expect(map['foulPlayerId'], equals(101));
    });

    test('FreeThrowSequence fromMap()이 올바르게 파싱해야 함', () {
      final map = {
        'totalShots': 3,
        'shooterPlayerId': 201,
        'foulPlayerId': 101,
      };

      final sequence = FreeThrowSequence.fromMap(map);
      expect(sequence.totalShots, equals(3));
      expect(sequence.shooterPlayerId, equals(201));
      expect(sequence.foulPlayerId, equals(101));
    });
  });
}
