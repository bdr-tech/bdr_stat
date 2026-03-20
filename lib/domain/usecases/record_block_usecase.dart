import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/database.dart';
import 'linked_action_result.dart';

/// 블락 기록 UseCase
///
/// CLAUDE.md 요구사항 구현:
/// "블락 → 상대 슛 실패"
///
/// 블락과 상대 슛 실패를 트랜잭션으로 묶어서 원자성을 보장합니다.
class RecordBlockUseCase {
  final AppDatabase _database;
  final Uuid _uuid;

  RecordBlockUseCase(this._database) : _uuid = const Uuid();

  /// 블락 기록 실행
  ///
  /// [matchId] 경기 ID
  /// [blockPlayerId] 블락한 선수 ID
  /// [blockPlayerTeamId] 블락한 선수의 팀 ID
  /// [shooterPlayerId] 슛을 시도한 선수 ID
  /// [shooterPlayerTeamId] 슛을 시도한 선수의 팀 ID
  /// [quarter] 현재 쿼터
  /// [gameClockSeconds] 현재 경기 시계 (초)
  /// [homeScore] 현재 홈 점수
  /// [awayScore] 현재 원정 점수
  /// [isThreePointer] 3점슛 여부
  /// [courtX] 슛 위치 X 좌표 (옵션)
  /// [courtY] 슛 위치 Y 좌표 (옵션)
  /// [courtZone] 슛 존 (옵션)
  Future<LinkedActionResult> execute({
    required int matchId,
    required int blockPlayerId,
    required int blockPlayerTeamId,
    required int shooterPlayerId,
    required int shooterPlayerTeamId,
    required int quarter,
    required int gameClockSeconds,
    required int homeScore,
    required int awayScore,
    required bool isThreePointer,
    double? courtX,
    double? courtY,
    int? courtZone,
  }) async {
    final blockLocalId = _uuid.v4();
    final shotMissLocalId = _uuid.v4();
    final now = DateTime.now();

    try {
      await _database.transaction(() async {
        // 1. 블락 선수 스탯 업데이트
        await _database.playerStatsDao.recordBlock(matchId, blockPlayerId);

        // 2. 슈터 슛 실패 스탯 업데이트 (자동 연동!)
        if (isThreePointer) {
          await _database.playerStatsDao.recordThreePointer(
            matchId,
            shooterPlayerId,
            false, // made = false
          );
        } else {
          await _database.playerStatsDao.recordTwoPointer(
            matchId,
            shooterPlayerId,
            false, // made = false
          );
        }

        // 3. 블락 Play-by-Play 기록
        await _database.playByPlayDao.insertPlay(
          LocalPlayByPlaysCompanion.insert(
            localId: blockLocalId,
            localMatchId: matchId,
            tournamentTeamPlayerId: blockPlayerId,
            tournamentTeamId: blockPlayerTeamId,
            quarter: quarter,
            gameClockSeconds: gameClockSeconds,
            actionType: 'block',
            homeScoreAtTime: homeScore,
            awayScoreAtTime: awayScore,
            createdAt: now,
            linkedActionId: Value(shotMissLocalId), // 슛 실패와 연결
          ),
        );

        // 4. 슛 실패 Play-by-Play 기록 (자동 연동!)
        await _database.playByPlayDao.insertPlay(
          LocalPlayByPlaysCompanion.insert(
            localId: shotMissLocalId,
            localMatchId: matchId,
            tournamentTeamPlayerId: shooterPlayerId,
            tournamentTeamId: shooterPlayerTeamId,
            quarter: quarter,
            gameClockSeconds: gameClockSeconds,
            actionType: 'shot',
            homeScoreAtTime: homeScore,
            awayScoreAtTime: awayScore,
            createdAt: now,
            linkedActionId: Value(blockLocalId), // 블락과 연결
            actionSubtype: Value(isThreePointer ? '3pt' : '2pt'),
            isMade: const Value(false), // 실패
            pointsScored: const Value(0),
            courtX: courtX != null ? Value(courtX) : const Value.absent(),
            courtY: courtY != null ? Value(courtY) : const Value.absent(),
            courtZone: courtZone != null ? Value(courtZone) : const Value.absent(),
          ),
        );
      });

      return LinkedActionResult.success(
        primaryActionId: blockLocalId,
        linkedActionId: shotMissLocalId,
        metadata: {
          'blockPlayerId': blockPlayerId,
          'shooterPlayerId': shooterPlayerId,
          'isThreePointer': isThreePointer,
        },
      );
    } catch (e) {
      return LinkedActionResult.failure(
        errorMessage: '블락 기록 실패: ${e.toString()}',
      );
    }
  }

  /// 블락 기록 취소 (Undo)
  ///
  /// 트랜잭션으로 블락과 연결된 슛 실패를 함께 취소합니다.
  Future<bool> undo({
    required int matchId,
    required int blockPlayerId,
    required int shooterPlayerId,
    required String blockLocalId,
    required String shotMissLocalId,
    required bool isThreePointer,
  }) async {
    try {
      await _database.transaction(() async {
        // 1. 블락 선수 스탯 롤백 (increment: -1)
        await _database.playerStatsDao.recordBlock(
          matchId,
          blockPlayerId,
          increment: -1,
        );

        // 2. 슈터 슛 실패 스탯 롤백 (increment: -1)
        if (isThreePointer) {
          await _database.playerStatsDao.recordThreePointer(
            matchId,
            shooterPlayerId,
            false, // made
            increment: -1,
          );
        } else {
          await _database.playerStatsDao.recordTwoPointer(
            matchId,
            shooterPlayerId,
            false, // made
            increment: -1,
          );
        }

        // 3. Play-by-Play 기록 삭제
        await _database.playByPlayDao.deletePlayByLocalId(blockLocalId);
        await _database.playByPlayDao.deletePlayByLocalId(shotMissLocalId);
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}
