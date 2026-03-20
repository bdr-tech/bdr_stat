import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/database.dart';
import 'linked_action_result.dart';

/// 스틸 기록 UseCase
///
/// CLAUDE.md 요구사항 구현:
/// "스틸 기록 시 → 상대 턴오버 자동"
///
/// 스틸과 상대 턴오버를 트랜잭션으로 묶어서 원자성을 보장합니다.
class RecordStealUseCase {
  final AppDatabase _database;
  final Uuid _uuid;

  RecordStealUseCase(this._database) : _uuid = const Uuid();

  /// 스틸 기록 실행
  ///
  /// [matchId] 경기 ID
  /// [stealPlayerId] 스틸한 선수 ID
  /// [stealPlayerTeamId] 스틸한 선수의 팀 ID
  /// [turnoverPlayerId] 턴오버 당한 선수 ID
  /// [turnoverPlayerTeamId] 턴오버 당한 선수의 팀 ID
  /// [quarter] 현재 쿼터
  /// [gameClockSeconds] 현재 경기 시계 (초)
  /// [homeScore] 현재 홈 점수
  /// [awayScore] 현재 원정 점수
  Future<LinkedActionResult> execute({
    required int matchId,
    required int stealPlayerId,
    required int stealPlayerTeamId,
    required int turnoverPlayerId,
    required int turnoverPlayerTeamId,
    required int quarter,
    required int gameClockSeconds,
    required int homeScore,
    required int awayScore,
  }) async {
    final stealLocalId = _uuid.v4();
    final turnoverLocalId = _uuid.v4();
    final now = DateTime.now();

    try {
      await _database.transaction(() async {
        // 1. 스틸 선수 스탯 업데이트
        await _database.playerStatsDao.recordSteal(matchId, stealPlayerId);

        // 2. 턴오버 선수 스탯 업데이트 (자동 연동!)
        await _database.playerStatsDao.recordTurnover(matchId, turnoverPlayerId);

        // 3. 스틸 Play-by-Play 기록
        await _database.playByPlayDao.insertPlay(
          LocalPlayByPlaysCompanion.insert(
            localId: stealLocalId,
            localMatchId: matchId,
            tournamentTeamPlayerId: stealPlayerId,
            tournamentTeamId: stealPlayerTeamId,
            quarter: quarter,
            gameClockSeconds: gameClockSeconds,
            actionType: 'steal',
            homeScoreAtTime: homeScore,
            awayScoreAtTime: awayScore,
            createdAt: now,
            linkedActionId: Value(turnoverLocalId), // 턴오버와 연결
          ),
        );

        // 4. 턴오버 Play-by-Play 기록 (자동 연동!)
        await _database.playByPlayDao.insertPlay(
          LocalPlayByPlaysCompanion.insert(
            localId: turnoverLocalId,
            localMatchId: matchId,
            tournamentTeamPlayerId: turnoverPlayerId,
            tournamentTeamId: turnoverPlayerTeamId,
            quarter: quarter,
            gameClockSeconds: gameClockSeconds,
            actionType: 'turnover',
            homeScoreAtTime: homeScore,
            awayScoreAtTime: awayScore,
            createdAt: now,
            linkedActionId: Value(stealLocalId), // 스틸과 연결
            actionSubtype: const Value('stolen'), // 스틸로 인한 턴오버
          ),
        );
      });

      return LinkedActionResult.success(
        primaryActionId: stealLocalId,
        linkedActionId: turnoverLocalId,
        metadata: {
          'stealPlayerId': stealPlayerId,
          'turnoverPlayerId': turnoverPlayerId,
        },
      );
    } catch (e) {
      return LinkedActionResult.failure(
        errorMessage: '스틸 기록 실패: ${e.toString()}',
      );
    }
  }

  /// 스틸 기록 취소 (Undo)
  ///
  /// 트랜잭션으로 스틸과 연결된 턴오버를 함께 취소합니다.
  Future<bool> undo({
    required int matchId,
    required int stealPlayerId,
    required int turnoverPlayerId,
    required String stealLocalId,
    required String turnoverLocalId,
  }) async {
    try {
      await _database.transaction(() async {
        // 1. 스틸 선수 스탯 롤백 (increment: -1)
        await _database.playerStatsDao.recordSteal(
          matchId,
          stealPlayerId,
          increment: -1,
        );

        // 2. 턴오버 선수 스탯 롤백 (increment: -1)
        await _database.playerStatsDao.recordTurnover(
          matchId,
          turnoverPlayerId,
          increment: -1,
        );

        // 3. Play-by-Play 기록 삭제
        await _database.playByPlayDao.deletePlayByLocalId(stealLocalId);
        await _database.playByPlayDao.deletePlayByLocalId(turnoverLocalId);
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}
