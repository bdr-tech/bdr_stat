import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'play_by_play_dao.g.dart';

@DriftAccessor(tables: [LocalPlayByPlays])
class PlayByPlayDao extends DatabaseAccessor<AppDatabase>
    with _$PlayByPlayDaoMixin {
  PlayByPlayDao(super.db);

  // ═══════════════════════════════════════════════════════════════
  // Play By Play CRUD
  // ═══════════════════════════════════════════════════════════════

  Future<int> insertPlay(LocalPlayByPlaysCompanion play) async {
    return into(localPlayByPlays).insert(play);
  }

  Future<void> insertPlays(List<LocalPlayByPlaysCompanion> plays) async {
    await batch((batch) {
      batch.insertAll(localPlayByPlays, plays);
    });
  }

  Future<LocalPlayByPlay?> getPlayById(int id) async {
    return (select(localPlayByPlays)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  Future<LocalPlayByPlay?> getPlayByLocalId(String localId) async {
    return (select(localPlayByPlays)..where((p) => p.localId.equals(localId)))
        .getSingleOrNull();
  }

  Future<List<LocalPlayByPlay>> getPlaysByMatch(int matchId) async {
    return (select(localPlayByPlays)
          ..where((p) => p.localMatchId.equals(matchId))
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .get();
  }

  Future<List<LocalPlayByPlay>> getPlaysByMatchAndQuarter(
      int matchId, int quarter) async {
    return (select(localPlayByPlays)
          ..where((p) =>
              p.localMatchId.equals(matchId) & p.quarter.equals(quarter))
          ..orderBy([(p) => OrderingTerm.desc(p.gameClockSeconds)]))
        .get();
  }

  Future<List<LocalPlayByPlay>> getPlaysByPlayer(
      int matchId, int playerId) async {
    return (select(localPlayByPlays)
          ..where((p) =>
              p.localMatchId.equals(matchId) &
              p.tournamentTeamPlayerId.equals(playerId))
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .get();
  }

  Stream<List<LocalPlayByPlay>> watchPlaysByMatch(int matchId) {
    return (select(localPlayByPlays)
          ..where((p) => p.localMatchId.equals(matchId))
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .watch();
  }

  // ═══════════════════════════════════════════════════════════════
  // Shot Chart Queries (슛차트용)
  // ═══════════════════════════════════════════════════════════════

  Stream<List<LocalPlayByPlay>> watchShotsByMatch(int matchId) {
    return (select(localPlayByPlays)
          ..where((p) =>
              p.localMatchId.equals(matchId) & p.actionType.equals('shot'))
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .watch();
  }

  Future<List<LocalPlayByPlay>> getShots(int matchId) async {
    return (select(localPlayByPlays)
          ..where((p) =>
              p.localMatchId.equals(matchId) & p.actionType.equals('shot'))
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .get();
  }

  Future<List<LocalPlayByPlay>> getShotsByTeam(int matchId, int teamId) async {
    return (select(localPlayByPlays)
          ..where((p) =>
              p.localMatchId.equals(matchId) &
              p.actionType.equals('shot') &
              p.tournamentTeamId.equals(teamId))
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .get();
  }

  Future<List<LocalPlayByPlay>> getShotsByPlayer(
      int matchId, int playerId) async {
    return (select(localPlayByPlays)
          ..where((p) =>
              p.localMatchId.equals(matchId) &
              p.actionType.equals('shot') &
              p.tournamentTeamPlayerId.equals(playerId))
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .get();
  }

  Future<List<LocalPlayByPlay>> getShotsByZone(int matchId, int zone) async {
    return (select(localPlayByPlays)
          ..where((p) =>
              p.localMatchId.equals(matchId) &
              p.actionType.equals('shot') &
              p.courtZone.equals(zone)))
        .get();
  }

  // ═══════════════════════════════════════════════════════════════
  // Recent Plays (Undo용)
  // ═══════════════════════════════════════════════════════════════

  Future<List<LocalPlayByPlay>> getRecentPlays(int matchId,
      {int limit = 10}) async {
    return (select(localPlayByPlays)
          ..where((p) => p.localMatchId.equals(matchId))
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<LocalPlayByPlay?> getLastPlay(int matchId) async {
    final plays = await getRecentPlays(matchId, limit: 1);
    return plays.isNotEmpty ? plays.first : null;
  }

  // ═══════════════════════════════════════════════════════════════
  // Sync
  // ═══════════════════════════════════════════════════════════════

  Future<List<LocalPlayByPlay>> getUnsyncedPlays(int matchId) async {
    return (select(localPlayByPlays)
          ..where((p) =>
              p.localMatchId.equals(matchId) & p.isSynced.equals(false)))
        .get();
  }

  Future<void> markAsSynced(int id) async {
    await (update(localPlayByPlays)..where((p) => p.id.equals(id))).write(
      const LocalPlayByPlaysCompanion(
        isSynced: Value(true),
      ),
    );
  }

  Future<void> markAllAsSynced(int matchId) async {
    await (update(localPlayByPlays)
          ..where((p) => p.localMatchId.equals(matchId)))
        .write(
      const LocalPlayByPlaysCompanion(
        isSynced: Value(true),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Update (기록 수정용)
  // ═══════════════════════════════════════════════════════════════

  /// 플레이 기록 업데이트
  Future<void> updatePlay(int id, LocalPlayByPlaysCompanion play) async {
    await (update(localPlayByPlays)..where((p) => p.id.equals(id))).write(play);
  }

  /// 득점자 변경
  Future<void> updateScorer(int playId, int newPlayerId) async {
    await (update(localPlayByPlays)..where((p) => p.id.equals(playId))).write(
      LocalPlayByPlaysCompanion(
        tournamentTeamPlayerId: Value(newPlayerId),
        isSynced: const Value(false), // 동기화 필요 표시
      ),
    );
  }

  /// 슛 타입 변경 (2점 ↔ 3점)
  Future<void> updateShotType(int playId, String newSubtype, int newPoints) async {
    await (update(localPlayByPlays)..where((p) => p.id.equals(playId))).write(
      LocalPlayByPlaysCompanion(
        actionSubtype: Value(newSubtype),
        pointsScored: Value(newPoints),
        isSynced: const Value(false),
      ),
    );
  }

  /// 성공/실패 변경
  Future<void> updateShotResult(int playId, bool isMade, int points) async {
    await (update(localPlayByPlays)..where((p) => p.id.equals(playId))).write(
      LocalPlayByPlaysCompanion(
        isMade: Value(isMade),
        pointsScored: Value(points),
        isSynced: const Value(false),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Delete (Undo 구현용)
  // ═══════════════════════════════════════════════════════════════

  Future<void> deletePlay(int id) async {
    await (delete(localPlayByPlays)..where((p) => p.id.equals(id))).go();
  }

  Future<void> deletePlayByLocalId(String localId) async {
    await (delete(localPlayByPlays)..where((p) => p.localId.equals(localId)))
        .go();
  }

  Future<void> deletePlaysByMatch(int matchId) async {
    await (delete(localPlayByPlays)..where((p) => p.localMatchId.equals(matchId)))
        .go();
  }

  // 연관된 플레이 함께 삭제 (예: 슛 성공 취소 시 어시스트도 삭제)
  Future<void> deleteRelatedPlays(int matchId, int playerId, DateTime time,
      {Duration tolerance = const Duration(seconds: 2)}) async {
    final minTime = time.subtract(tolerance);
    final maxTime = time.add(tolerance);

    await (delete(localPlayByPlays)
          ..where((p) =>
              p.localMatchId.equals(matchId) &
              p.createdAt.isBetweenValues(minTime, maxTime) &
              (p.tournamentTeamPlayerId.equals(playerId) |
                  p.assistPlayerId.equals(playerId))))
        .go();
  }

  // ═══════════════════════════════════════════════════════════════
  // Quarter Stats Queries (FR-001)
  // ═══════════════════════════════════════════════════════════════

  /// 팀 전체 쿼터별 선수 통계 집계 (박스스코어 뷰용)
  /// [quarter] null이면 전체(ALL) 집계
  Future<List<Map<String, dynamic>>> getTeamQuarterStats({
    required int matchId,
    required int teamId,
    int? quarter,
  }) async {
    final quarterCondition = quarter != null ? 'AND quarter = ?' : '';
    final args = quarter != null
        ? [matchId, teamId, quarter]
        : [matchId, teamId];

    final results = await customSelect(
      '''
      SELECT
        tournament_team_player_id,
        COALESCE(SUM(points_scored), 0) AS total_points,
        COALESCE(SUM(CASE WHEN action_type = 'shot' AND action_subtype != 'ft' THEN 1 ELSE 0 END), 0) AS fga,
        COALESCE(SUM(CASE WHEN action_type = 'shot' AND action_subtype != 'ft' AND is_made = 1 THEN 1 ELSE 0 END), 0) AS fgm,
        COALESCE(SUM(CASE WHEN action_type = 'shot' AND action_subtype = '2pt' THEN 1 ELSE 0 END), 0) AS two_pa,
        COALESCE(SUM(CASE WHEN action_type = 'shot' AND action_subtype = '2pt' AND is_made = 1 THEN 1 ELSE 0 END), 0) AS two_pm,
        COALESCE(SUM(CASE WHEN action_type = 'shot' AND action_subtype = '3pt' THEN 1 ELSE 0 END), 0) AS three_pa,
        COALESCE(SUM(CASE WHEN action_type = 'shot' AND action_subtype = '3pt' AND is_made = 1 THEN 1 ELSE 0 END), 0) AS three_pm,
        COALESCE(SUM(CASE WHEN action_type = 'shot' AND action_subtype = 'ft' THEN 1 ELSE 0 END), 0) AS fta,
        COALESCE(SUM(CASE WHEN action_type = 'shot' AND action_subtype = 'ft' AND is_made = 1 THEN 1 ELSE 0 END), 0) AS ftm,
        COALESCE(SUM(CASE WHEN action_type = 'rebound' AND action_subtype = 'offensive' THEN 1 ELSE 0 END), 0) AS orb,
        COALESCE(SUM(CASE WHEN action_type = 'rebound' AND action_subtype = 'defensive' THEN 1 ELSE 0 END), 0) AS drb,
        COALESCE(SUM(CASE WHEN action_type = 'assist' THEN 1 ELSE 0 END), 0) AS ast,
        COALESCE(SUM(CASE WHEN action_type = 'steal' THEN 1 ELSE 0 END), 0) AS stl,
        COALESCE(SUM(CASE WHEN action_type = 'block' THEN 1 ELSE 0 END), 0) AS blk,
        COALESCE(SUM(CASE WHEN action_type = 'turnover' THEN 1 ELSE 0 END), 0) AS tov,
        COALESCE(SUM(CASE WHEN action_type = 'foul' THEN 1 ELSE 0 END), 0) AS pf
      FROM local_play_by_plays
      WHERE local_match_id = ?
        AND tournament_team_id = ?
        $quarterCondition
      GROUP BY tournament_team_player_id
      ORDER BY total_points DESC
      ''',
      variables: args.map((a) => Variable(a)).toList(),
      readsFrom: {localPlayByPlays},
    ).get();

    return results.map((row) => row.data).toList();
  }

  /// 쿼터별 팀 점수 집계 (점수 요약 행용)
  Future<List<Map<String, dynamic>>> getQuarterScoreSummary({
    required int matchId,
    required int teamId,
  }) async {
    final results = await customSelect(
      '''
      SELECT
        quarter,
        COALESCE(SUM(points_scored), 0) AS quarter_points
      FROM local_play_by_plays
      WHERE local_match_id = ?
        AND tournament_team_id = ?
        AND action_type = 'shot'
        AND is_made = 1
      GROUP BY quarter
      ORDER BY quarter
      ''',
      variables: [Variable(matchId), Variable(teamId)],
      readsFrom: {localPlayByPlays},
    ).get();

    return results.map((row) => row.data).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // Statistics Queries
  // ═══════════════════════════════════════════════════════════════

  Future<Map<String, int>> getActionCounts(int matchId) async {
    final plays = await getPlaysByMatch(matchId);
    final counts = <String, int>{};
    for (final play in plays) {
      counts[play.actionType] = (counts[play.actionType] ?? 0) + 1;
    }
    return counts;
  }

  Future<int> getTeamScoreFromPlays(int matchId, int teamId) async {
    final plays = await (select(localPlayByPlays)
          ..where((p) =>
              p.localMatchId.equals(matchId) &
              p.tournamentTeamId.equals(teamId) &
              p.pointsScored.isBiggerThanValue(0)))
        .get();
    return plays.fold<int>(0, (sum, play) => sum + play.pointsScored);
  }
}
