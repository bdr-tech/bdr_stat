import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/database.dart';
import 'linked_action_result.dart';

/// 파울 기록 UseCase
///
/// CLAUDE.md 요구사항 구현:
/// - "오펜시브 파울 → 본인 턴오버"
/// - "슈팅 파울 → 자유투 시퀀스"
/// - "5파울 → 강제 교체 모달" (fouledOut 플래그로 처리)
///
/// 파울 타입에 따라 연결된 액션을 트랜잭션으로 묶어서 원자성을 보장합니다.
class RecordFoulUseCase {
  final AppDatabase _database;
  final Uuid _uuid;

  RecordFoulUseCase(this._database) : _uuid = const Uuid();

  /// 일반 파울 기록 실행
  ///
  /// [matchId] 경기 ID
  /// [foulPlayerId] 파울한 선수 ID
  /// [foulPlayerTeamId] 파울한 선수의 팀 ID
  /// [quarter] 현재 쿼터
  /// [gameClockSeconds] 현재 경기 시계 (초)
  /// [homeScore] 현재 홈 점수
  /// [awayScore] 현재 원정 점수
  Future<LinkedActionResult> executePersonalFoul({
    required int matchId,
    required int foulPlayerId,
    required int foulPlayerTeamId,
    required int quarter,
    required int gameClockSeconds,
    required int homeScore,
    required int awayScore,
  }) async {
    final foulLocalId = _uuid.v4();
    final now = DateTime.now();

    try {
      bool isFouledOut = false;

      await _database.transaction(() async {
        // 1. 파울 선수 스탯 업데이트
        await _database.playerStatsDao.recordFoul(matchId, foulPlayerId);

        // 2. 5파울 확인
        final stats = await _database.playerStatsDao.getPlayerStats(
          matchId,
          foulPlayerId,
        );
        isFouledOut = stats?.fouledOut ?? false;

        // 3. 파울 Play-by-Play 기록
        await _database.playByPlayDao.insertPlay(
          LocalPlayByPlaysCompanion.insert(
            localId: foulLocalId,
            localMatchId: matchId,
            tournamentTeamPlayerId: foulPlayerId,
            tournamentTeamId: foulPlayerTeamId,
            quarter: quarter,
            gameClockSeconds: gameClockSeconds,
            actionType: 'foul',
            homeScoreAtTime: homeScore,
            awayScoreAtTime: awayScore,
            createdAt: now,
            actionSubtype: const Value('personal'),
          ),
        );
      });

      return LinkedActionResult.success(
        primaryActionId: foulLocalId,
        metadata: {
          'foulPlayerId': foulPlayerId,
          'foulType': 'personal',
          'isFouledOut': isFouledOut, // 5파울 여부 (UI에서 교체 모달 표시용)
        },
      );
    } catch (e) {
      return LinkedActionResult.failure(
        errorMessage: '파울 기록 실패: ${e.toString()}',
      );
    }
  }

  /// 오펜시브 파울 기록 실행 (자동 턴오버 포함)
  ///
  /// CLAUDE.md: "오펜시브 파울 → 본인 턴오버"
  Future<LinkedActionResult> executeOffensiveFoul({
    required int matchId,
    required int foulPlayerId,
    required int foulPlayerTeamId,
    required int quarter,
    required int gameClockSeconds,
    required int homeScore,
    required int awayScore,
  }) async {
    final foulLocalId = _uuid.v4();
    final turnoverLocalId = _uuid.v4();
    final now = DateTime.now();

    try {
      bool isFouledOut = false;

      await _database.transaction(() async {
        // 1. 파울 선수 스탯 업데이트
        await _database.playerStatsDao.recordFoul(matchId, foulPlayerId);

        // 2. 턴오버 스탯 업데이트 (자동 연동!)
        await _database.playerStatsDao.recordTurnover(matchId, foulPlayerId);

        // 3. 5파울 확인
        final stats = await _database.playerStatsDao.getPlayerStats(
          matchId,
          foulPlayerId,
        );
        isFouledOut = stats?.fouledOut ?? false;

        // 4. 파울 Play-by-Play 기록
        await _database.playByPlayDao.insertPlay(
          LocalPlayByPlaysCompanion.insert(
            localId: foulLocalId,
            localMatchId: matchId,
            tournamentTeamPlayerId: foulPlayerId,
            tournamentTeamId: foulPlayerTeamId,
            quarter: quarter,
            gameClockSeconds: gameClockSeconds,
            actionType: 'foul',
            homeScoreAtTime: homeScore,
            awayScoreAtTime: awayScore,
            createdAt: now,
            actionSubtype: const Value('offensive'),
            linkedActionId: Value(turnoverLocalId), // 턴오버와 연결
          ),
        );

        // 5. 턴오버 Play-by-Play 기록 (자동 연동!)
        await _database.playByPlayDao.insertPlay(
          LocalPlayByPlaysCompanion.insert(
            localId: turnoverLocalId,
            localMatchId: matchId,
            tournamentTeamPlayerId: foulPlayerId,
            tournamentTeamId: foulPlayerTeamId,
            quarter: quarter,
            gameClockSeconds: gameClockSeconds,
            actionType: 'turnover',
            homeScoreAtTime: homeScore,
            awayScoreAtTime: awayScore,
            createdAt: now,
            actionSubtype: const Value('offensive_foul'), // 오펜시브 파울로 인한 턴오버
            linkedActionId: Value(foulLocalId), // 파울과 연결
          ),
        );
      });

      return LinkedActionResult.success(
        primaryActionId: foulLocalId,
        linkedActionId: turnoverLocalId,
        metadata: {
          'foulPlayerId': foulPlayerId,
          'foulType': 'offensive',
          'isFouledOut': isFouledOut,
        },
      );
    } catch (e) {
      return LinkedActionResult.failure(
        errorMessage: '오펜시브 파울 기록 실패: ${e.toString()}',
      );
    }
  }

  /// 슈팅 파울 기록 실행 (자유투 시퀀스 정보 반환)
  ///
  /// CLAUDE.md: "슈팅 파울 → 자유투 시퀀스"
  ///
  /// 자유투는 별도로 기록해야 합니다 (UI에서 순차적으로 입력)
  /// 이 메서드는 파울 기록과 함께 자유투 시퀀스 정보를 반환합니다.
  Future<LinkedActionResult> executeShootingFoul({
    required int matchId,
    required int foulPlayerId,
    required int foulPlayerTeamId,
    required int fouledPlayerId,
    required int fouledPlayerTeamId,
    required int quarter,
    required int gameClockSeconds,
    required int homeScore,
    required int awayScore,
    required int freeThrowCount, // 자유투 개수 (2 또는 3)
    bool wasShootingThreePointer = false, // 3점슛 시도 중 파울
  }) async {
    final foulLocalId = _uuid.v4();
    final now = DateTime.now();

    // 자유투 개수 결정: 3점슛 중 파울이면 3개, 아니면 2개
    final ftCount = wasShootingThreePointer ? 3 : freeThrowCount;

    try {
      bool isFouledOut = false;

      await _database.transaction(() async {
        // 1. 파울 선수 스탯 업데이트
        await _database.playerStatsDao.recordFoul(matchId, foulPlayerId);

        // 2. 5파울 확인
        final stats = await _database.playerStatsDao.getPlayerStats(
          matchId,
          foulPlayerId,
        );
        isFouledOut = stats?.fouledOut ?? false;

        // 3. 파울 Play-by-Play 기록
        await _database.playByPlayDao.insertPlay(
          LocalPlayByPlaysCompanion.insert(
            localId: foulLocalId,
            localMatchId: matchId,
            tournamentTeamPlayerId: foulPlayerId,
            tournamentTeamId: foulPlayerTeamId,
            quarter: quarter,
            gameClockSeconds: gameClockSeconds,
            actionType: 'foul',
            homeScoreAtTime: homeScore,
            awayScoreAtTime: awayScore,
            createdAt: now,
            actionSubtype: const Value('shooting'),
            fouledPlayerId: Value(fouledPlayerId), // 파울 당한 선수
          ),
        );
      });

      // 자유투 시퀀스 정보 반환 (UI에서 자유투 입력 모달 표시용)
      final ftSequence = FreeThrowSequence(
        totalShots: ftCount,
        shooterPlayerId: fouledPlayerId,
        foulPlayerId: foulPlayerId,
      );

      return LinkedActionResult.success(
        primaryActionId: foulLocalId,
        metadata: {
          'foulPlayerId': foulPlayerId,
          'fouledPlayerId': fouledPlayerId,
          'foulType': 'shooting',
          'isFouledOut': isFouledOut,
          'freeThrowSequence': ftSequence.toMap(),
        },
      );
    } catch (e) {
      return LinkedActionResult.failure(
        errorMessage: '슈팅 파울 기록 실패: ${e.toString()}',
      );
    }
  }

  /// 파울 기록 취소 (Undo)
  Future<bool> undoPersonalFoul({
    required int matchId,
    required int foulPlayerId,
    required String foulLocalId,
  }) async {
    try {
      await _database.transaction(() async {
        // 1. 파울 스탯 롤백
        await _database.playerStatsDao.recordFoul(
          matchId,
          foulPlayerId,
          increment: -1,
        );

        // 2. Play-by-Play 기록 삭제
        await _database.playByPlayDao.deletePlayByLocalId(foulLocalId);
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 오펜시브 파울 취소 (Undo) - 턴오버도 함께 취소
  Future<bool> undoOffensiveFoul({
    required int matchId,
    required int foulPlayerId,
    required String foulLocalId,
    required String turnoverLocalId,
  }) async {
    try {
      await _database.transaction(() async {
        // 1. 파울 스탯 롤백
        await _database.playerStatsDao.recordFoul(
          matchId,
          foulPlayerId,
          increment: -1,
        );

        // 2. 턴오버 스탯 롤백
        await _database.playerStatsDao.recordTurnover(
          matchId,
          foulPlayerId,
          increment: -1,
        );

        // 3. Play-by-Play 기록 삭제
        await _database.playByPlayDao.deletePlayByLocalId(foulLocalId);
        await _database.playByPlayDao.deletePlayByLocalId(turnoverLocalId);
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 슈팅 파울 취소 (Undo)
  /// 주의: 자유투도 별도로 취소해야 합니다
  Future<bool> undoShootingFoul({
    required int matchId,
    required int foulPlayerId,
    required String foulLocalId,
  }) async {
    return undoPersonalFoul(
      matchId: matchId,
      foulPlayerId: foulPlayerId,
      foulLocalId: foulLocalId,
    );
  }
}
