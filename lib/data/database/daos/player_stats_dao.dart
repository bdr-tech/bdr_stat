import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'player_stats_dao.g.dart';

@DriftAccessor(tables: [LocalPlayerStats, LocalTournamentPlayers])
class PlayerStatsDao extends DatabaseAccessor<AppDatabase>
    with _$PlayerStatsDaoMixin {
  PlayerStatsDao(super.db);

  // ═══════════════════════════════════════════════════════════════
  // Player Stats CRUD
  // ═══════════════════════════════════════════════════════════════

  Future<int> insertPlayerStats(LocalPlayerStatsCompanion stats) async {
    return into(localPlayerStats).insert(stats);
  }

  Future<void> insertBatchPlayerStats(
      List<LocalPlayerStatsCompanion> statsList) async {
    await batch((batch) {
      batch.insertAll(localPlayerStats, statsList);
    });
  }

  Future<LocalPlayerStat?> getPlayerStats(int matchId, int playerId) async {
    return (select(localPlayerStats)
          ..where((s) =>
              s.localMatchId.equals(matchId) &
              s.tournamentTeamPlayerId.equals(playerId)))
        .getSingleOrNull();
  }

  Future<List<LocalPlayerStat>> getStatsByMatch(int matchId) async {
    return (select(localPlayerStats)
          ..where((s) => s.localMatchId.equals(matchId)))
        .get();
  }

  Future<List<LocalPlayerStat>> getStatsByMatchAndTeam(
      int matchId, int teamId) async {
    return (select(localPlayerStats)
          ..where((s) =>
              s.localMatchId.equals(matchId) &
              s.tournamentTeamId.equals(teamId)))
        .get();
  }

  Future<List<LocalPlayerStat>> getOnCourtPlayers(
      int matchId, int teamId) async {
    return (select(localPlayerStats)
          ..where((s) =>
              s.localMatchId.equals(matchId) &
              s.tournamentTeamId.equals(teamId) &
              s.isOnCourt.equals(true)))
        .get();
  }

  Stream<List<LocalPlayerStat>> watchStatsByMatch(int matchId) {
    return (select(localPlayerStats)
          ..where((s) => s.localMatchId.equals(matchId)))
        .watch();
  }

  Stream<List<LocalPlayerStat>> watchStatsByMatchAndTeam(
      int matchId, int teamId) {
    return (select(localPlayerStats)
          ..where((s) =>
              s.localMatchId.equals(matchId) &
              s.tournamentTeamId.equals(teamId)))
        .watch();
  }

  // ═══════════════════════════════════════════════════════════════
  // Stats Updates
  // ═══════════════════════════════════════════════════════════════

  Future<void> updatePlayerStats(int id, LocalPlayerStatsCompanion stats) async {
    await (update(localPlayerStats)..where((s) => s.id.equals(id))).write(stats);
  }

  Future<void> setOnCourt(int matchId, int playerId, bool isOnCourt) async {
    final now = DateTime.now();
    await (update(localPlayerStats)
          ..where((s) =>
              s.localMatchId.equals(matchId) &
              s.tournamentTeamPlayerId.equals(playerId)))
        .write(LocalPlayerStatsCompanion(
          isOnCourt: Value(isOnCourt),
          lastEnteredAt: isOnCourt ? Value(now) : const Value.absent(),
          updatedAt: Value(now),
        ));
  }

  Future<void> setFouledOut(int matchId, int playerId, bool fouledOut) async {
    await (update(localPlayerStats)
          ..where((s) =>
              s.localMatchId.equals(matchId) &
              s.tournamentTeamPlayerId.equals(playerId)))
        .write(LocalPlayerStatsCompanion(
          fouledOut: Value(fouledOut),
          ejected: Value(false),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> addMinutesPlayed(int matchId, int playerId, int minutes) async {
    await _atomicIncrement(matchId, playerId, {
      'minutes_played': minutes,
    });
  }

  /// Alias for getStatsByMatchAndTeam
  Future<List<LocalPlayerStat>> getStatsByTeam(int matchId, int teamId) async {
    return getStatsByMatchAndTeam(matchId, teamId);
  }

  /// Initialize player stats for a match
  Future<void> initializeStats({
    required int matchId,
    required int playerId,
    required int teamId,
    required bool isOnCourt,
  }) async {
    // 이미 존재하면 무시 (중복 방지)
    final existing = await (select(localPlayerStats)
          ..where((s) => s.localMatchId.equals(matchId) & s.tournamentTeamPlayerId.equals(playerId)))
        .get();
    if (existing.isNotEmpty) return;

    await into(localPlayerStats).insert(
      LocalPlayerStatsCompanion.insert(
        localMatchId: matchId,
        tournamentTeamPlayerId: playerId,
        tournamentTeamId: teamId,
        isStarter: Value(isOnCourt),
        isOnCourt: Value(isOnCourt),
        minutesPlayed: const Value(0),
        points: const Value(0),
        fieldGoalsMade: const Value(0),
        fieldGoalsAttempted: const Value(0),
        twoPointersMade: const Value(0),
        twoPointersAttempted: const Value(0),
        threePointersMade: const Value(0),
        threePointersAttempted: const Value(0),
        freeThrowsMade: const Value(0),
        freeThrowsAttempted: const Value(0),
        offensiveRebounds: const Value(0),
        defensiveRebounds: const Value(0),
        totalRebounds: const Value(0),
        assists: const Value(0),
        steals: const Value(0),
        blocks: const Value(0),
        turnovers: const Value(0),
        personalFouls: const Value(0),
        plusMinus: const Value(0),
        fouledOut: const Value(false),
        ejected: const Value(false),
        isManuallyEdited: const Value(false),
        updatedAt: DateTime.now(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Stat Increments (슛, 리바운드 등)
  // ═══════════════════════════════════════════════════════════════

  // ─── Atomic SQL Increment Helper ───────────────────────────
  // Read-modify-write 대신 단일 SQL UPDATE로 경쟁 조건 방지

  Future<void> _atomicIncrement(
    int matchId,
    int playerId,
    Map<String, int> increments,
  ) async {
    final setClauses = increments.entries
        .map((e) => '${e.key} = MAX(0, MIN(999, ${e.key} + ${e.value}))')
        .join(', ');
    await customStatement(
      'UPDATE local_player_stats SET $setClauses, updated_at = ? '
      'WHERE local_match_id = ? AND tournament_team_player_id = ?',
      [DateTime.now().millisecondsSinceEpoch ~/ 1000, matchId, playerId],
    );
  }

  /// 2점슛 기록 (increment: 1이면 증가, -1이면 감소 for undo)
  Future<void> recordTwoPointer(
      int matchId, int playerId, bool made, {int increment = 1}) async {
    await _atomicIncrement(matchId, playerId, {
      'two_pointers_attempted': increment,
      'two_pointers_made': made ? increment : 0,
      'field_goals_attempted': increment,
      'field_goals_made': made ? increment : 0,
      'points': made ? 2 * increment : 0,
    });
  }

  /// 3점슛 기록 (increment: 1이면 증가, -1이면 감소 for undo)
  Future<void> recordThreePointer(
      int matchId, int playerId, bool made, {int increment = 1}) async {
    await _atomicIncrement(matchId, playerId, {
      'three_pointers_attempted': increment,
      'three_pointers_made': made ? increment : 0,
      'field_goals_attempted': increment,
      'field_goals_made': made ? increment : 0,
      'points': made ? 3 * increment : 0,
    });
  }

  /// 자유투 기록 (increment: 1이면 증가, -1이면 감소 for undo)
  Future<void> recordFreeThrow(
      int matchId, int playerId, bool made, {int increment = 1}) async {
    await _atomicIncrement(matchId, playerId, {
      'free_throws_attempted': increment,
      'free_throws_made': made ? increment : 0,
      'points': made ? increment : 0,
    });
  }

  /// 리바운드 기록 (increment: 1이면 증가, -1이면 감소 for undo)
  Future<void> recordRebound(
      int matchId, int playerId, bool isOffensive, {int increment = 1}) async {
    await _atomicIncrement(matchId, playerId, {
      'offensive_rebounds': isOffensive ? increment : 0,
      'defensive_rebounds': isOffensive ? 0 : increment,
      'total_rebounds': increment,
    });
  }

  /// 어시스트 기록 (increment: 1이면 증가, -1이면 감소 for undo)
  Future<void> recordAssist(int matchId, int playerId, {int increment = 1}) async {
    await _atomicIncrement(matchId, playerId, {
      'assists': increment,
    });
  }

  /// 스틸 기록 (increment: 1이면 증가, -1이면 감소 for undo)
  Future<void> recordSteal(int matchId, int playerId, {int increment = 1}) async {
    await _atomicIncrement(matchId, playerId, {
      'steals': increment,
    });
  }

  /// 블락 기록 (increment: 1이면 증가, -1이면 감소 for undo)
  Future<void> recordBlock(int matchId, int playerId, {int increment = 1}) async {
    await _atomicIncrement(matchId, playerId, {
      'blocks': increment,
    });
  }

  /// 턴오버 기록 (increment: 1이면 증가, -1이면 감소 for undo)
  Future<void> recordTurnover(int matchId, int playerId, {int increment = 1}) async {
    await _atomicIncrement(matchId, playerId, {
      'turnovers': increment,
    });
  }

  /// 파울 기록 (increment: 1이면 증가, -1이면 감소 for undo)
  Future<void> recordFoul(int matchId, int playerId, {int increment = 1}) async {
    // 파울은 fouled_out 계산 필요 → 2단계
    await customStatement(
      'UPDATE local_player_stats SET '
      'personal_fouls = MAX(0, MIN(10, personal_fouls + ?)), '
      'fouled_out = CASE WHEN MAX(0, MIN(10, personal_fouls + ?)) >= 5 THEN 1 ELSE 0 END, '
      'updated_at = ? '
      'WHERE local_match_id = ? AND tournament_team_player_id = ?',
      [increment, increment, DateTime.now().millisecondsSinceEpoch ~/ 1000, matchId, playerId],
    );
  }

  /// 테크니컬 파울 기록
  Future<void> recordTechnicalFoul(int matchId, int playerId) async {
    await customStatement(
      'UPDATE local_player_stats SET '
      'technical_fouls = technical_fouls + 1, '
      'personal_fouls = MAX(0, MIN(10, personal_fouls + 1)), '
      'fouled_out = CASE WHEN MAX(0, MIN(10, personal_fouls + 1)) >= 5 THEN 1 ELSE 0 END, '
      'ejected = CASE WHEN technical_fouls + 1 + unsportsmanlike_fouls >= 2 THEN 1 ELSE 0 END, '
      'updated_at = ? '
      'WHERE local_match_id = ? AND tournament_team_player_id = ?',
      [DateTime.now().millisecondsSinceEpoch ~/ 1000, matchId, playerId],
    );
  }

  /// 비신사적 파울 기록
  Future<void> recordUnsportsmanlikeFoul(int matchId, int playerId) async {
    await customStatement(
      'UPDATE local_player_stats SET '
      'unsportsmanlike_fouls = unsportsmanlike_fouls + 1, '
      'personal_fouls = MAX(0, MIN(10, personal_fouls + 1)), '
      'fouled_out = CASE WHEN MAX(0, MIN(10, personal_fouls + 1)) >= 5 THEN 1 ELSE 0 END, '
      'ejected = CASE WHEN technical_fouls + unsportsmanlike_fouls + 1 >= 2 THEN 1 ELSE 0 END, '
      'updated_at = ? '
      'WHERE local_match_id = ? AND tournament_team_player_id = ?',
      [DateTime.now().millisecondsSinceEpoch ~/ 1000, matchId, playerId],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Plus/Minus (FR-003)
  // ═══════════════════════════════════════════════════════════════

  /// +/- 누적 업데이트: 득점 발생 시 호출
  /// [delta] 양수 = 득점팀, 음수 = 실점팀
  Future<void> updatePlusMinus(
    int matchId,
    int playerId,
    int delta,
  ) async {
    await customStatement(
      'UPDATE local_player_stats '
      'SET plus_minus = plus_minus + ?, updated_at = ? '
      'WHERE local_match_id = ? AND tournament_team_player_id = ?',
      [delta, DateTime.now().millisecondsSinceEpoch ~/ 1000, matchId, playerId],
    );
  }

  /// 득점 이벤트 발생 시: 코트 위 전체 선수 +/- 일괄 업데이트
  /// 득점 팀 코트 위 선수: +points / 실점 팀 코트 위 선수: -points
  Future<void> applyPlusMinusForScore({
    required int matchId,
    required int scoringTeamId,
    required int opponentTeamId,
    required int points,
  }) async {
    if (points == 0) return; // 자유투 실패 등

    // 득점 팀 코트 위 선수: +points
    final scoringOnCourt = await getOnCourtPlayers(matchId, scoringTeamId);
    for (final player in scoringOnCourt) {
      await updatePlusMinus(matchId, player.tournamentTeamPlayerId, points);
    }

    // 실점 팀 코트 위 선수: -points
    final opponentOnCourt = await getOnCourtPlayers(matchId, opponentTeamId);
    for (final player in opponentOnCourt) {
      await updatePlusMinus(matchId, player.tournamentTeamPlayerId, -points);
    }
  }

  /// Undo: 득점 취소 시 +/- 역방향 적용
  /// ADR-002: 현재 ON-COURT 기준으로 역방향 적용 (단순화)
  Future<void> revertPlusMinusForScore({
    required int matchId,
    required int scoringTeamId,
    required int opponentTeamId,
    required int points,
  }) async {
    if (points == 0) return;

    // 역방향: 득점 팀 -points, 실점 팀 +points
    final scoringOnCourt = await getOnCourtPlayers(matchId, scoringTeamId);
    for (final player in scoringOnCourt) {
      await updatePlusMinus(matchId, player.tournamentTeamPlayerId, -points);
    }

    final opponentOnCourt = await getOnCourtPlayers(matchId, opponentTeamId);
    for (final player in opponentOnCourt) {
      await updatePlusMinus(matchId, player.tournamentTeamPlayerId, points);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Direct Stats Update (Map 기반)
  // ═══════════════════════════════════════════════════════════════

  /// 선수별 스탯 조회 (alias for getPlayerStats)
  Future<LocalPlayerStat?> getStatsByPlayer(int matchId, int playerId) async {
    return getPlayerStats(matchId, playerId);
  }

  /// Map 기반 스탯 업데이트 (기록 수정용)
  Future<void> updateStats(
    int matchId,
    int playerId,
    Map<String, int> updates,
  ) async {
    final stats = await getPlayerStats(matchId, playerId);
    if (stats == null) return;

    await (update(localPlayerStats)..where((s) => s.id.equals(stats.id)))
        .write(LocalPlayerStatsCompanion(
          fieldGoalsMade: updates.containsKey('fieldGoalsMade')
              ? Value(updates['fieldGoalsMade']!.clamp(0, 999))
              : const Value.absent(),
          fieldGoalsAttempted: updates.containsKey('fieldGoalsAttempted')
              ? Value(updates['fieldGoalsAttempted']!.clamp(0, 999))
              : const Value.absent(),
          twoPointersMade: updates.containsKey('twoPointersMade')
              ? Value(updates['twoPointersMade']!.clamp(0, 999))
              : const Value.absent(),
          twoPointersAttempted: updates.containsKey('twoPointersAttempted')
              ? Value(updates['twoPointersAttempted']!.clamp(0, 999))
              : const Value.absent(),
          threePointersMade: updates.containsKey('threePointersMade')
              ? Value(updates['threePointersMade']!.clamp(0, 999))
              : const Value.absent(),
          threePointersAttempted: updates.containsKey('threePointersAttempted')
              ? Value(updates['threePointersAttempted']!.clamp(0, 999))
              : const Value.absent(),
          freeThrowsMade: updates.containsKey('freeThrowsMade')
              ? Value(updates['freeThrowsMade']!.clamp(0, 999))
              : const Value.absent(),
          freeThrowsAttempted: updates.containsKey('freeThrowsAttempted')
              ? Value(updates['freeThrowsAttempted']!.clamp(0, 999))
              : const Value.absent(),
          points: updates.containsKey('points')
              ? Value(updates['points']!.clamp(0, 999))
              : const Value.absent(),
          isManuallyEdited: const Value(true),
          updatedAt: Value(DateTime.now()),
        ));
  }

  // ═══════════════════════════════════════════════════════════════
  // Manual Edit
  // ═══════════════════════════════════════════════════════════════

  Future<void> manualUpdateStats(
    int matchId,
    int playerId,
    LocalPlayerStatsCompanion stats,
  ) async {
    await (update(localPlayerStats)
          ..where((s) =>
              s.localMatchId.equals(matchId) &
              s.tournamentTeamPlayerId.equals(playerId)))
        .write(stats.copyWith(
          isManuallyEdited: const Value(true),
          updatedAt: Value(DateTime.now()),
        ));
  }

  // ═══════════════════════════════════════════════════════════════
  // Delete
  // ═══════════════════════════════════════════════════════════════

  Future<void> deleteStatsByMatch(int matchId) async {
    await (delete(localPlayerStats)
          ..where((s) => s.localMatchId.equals(matchId)))
        .go();
  }
}

extension LocalPlayerStatsCompanionCopyWith on LocalPlayerStatsCompanion {
  LocalPlayerStatsCompanion copyWith({
    Value<int>? id,
    Value<int>? localMatchId,
    Value<int>? tournamentTeamPlayerId,
    Value<int>? tournamentTeamId,
    Value<bool>? isStarter,
    Value<bool>? isOnCourt,
    Value<int>? minutesPlayed,
    Value<DateTime?>? lastEnteredAt,
    Value<int>? points,
    Value<int>? fieldGoalsMade,
    Value<int>? fieldGoalsAttempted,
    Value<int>? twoPointersMade,
    Value<int>? twoPointersAttempted,
    Value<int>? threePointersMade,
    Value<int>? threePointersAttempted,
    Value<int>? freeThrowsMade,
    Value<int>? freeThrowsAttempted,
    Value<int>? offensiveRebounds,
    Value<int>? defensiveRebounds,
    Value<int>? totalRebounds,
    Value<int>? assists,
    Value<int>? steals,
    Value<int>? blocks,
    Value<int>? turnovers,
    Value<int>? personalFouls,
    Value<int>? plusMinus,
    Value<bool>? fouledOut,
    Value<bool>? ejected,
    Value<bool>? isManuallyEdited,
    Value<DateTime>? updatedAt,
  }) {
    return LocalPlayerStatsCompanion(
      id: id ?? this.id,
      localMatchId: localMatchId ?? this.localMatchId,
      tournamentTeamPlayerId: tournamentTeamPlayerId ?? this.tournamentTeamPlayerId,
      tournamentTeamId: tournamentTeamId ?? this.tournamentTeamId,
      isStarter: isStarter ?? this.isStarter,
      isOnCourt: isOnCourt ?? this.isOnCourt,
      minutesPlayed: minutesPlayed ?? this.minutesPlayed,
      lastEnteredAt: lastEnteredAt ?? this.lastEnteredAt,
      points: points ?? this.points,
      fieldGoalsMade: fieldGoalsMade ?? this.fieldGoalsMade,
      fieldGoalsAttempted: fieldGoalsAttempted ?? this.fieldGoalsAttempted,
      twoPointersMade: twoPointersMade ?? this.twoPointersMade,
      twoPointersAttempted: twoPointersAttempted ?? this.twoPointersAttempted,
      threePointersMade: threePointersMade ?? this.threePointersMade,
      threePointersAttempted: threePointersAttempted ?? this.threePointersAttempted,
      freeThrowsMade: freeThrowsMade ?? this.freeThrowsMade,
      freeThrowsAttempted: freeThrowsAttempted ?? this.freeThrowsAttempted,
      offensiveRebounds: offensiveRebounds ?? this.offensiveRebounds,
      defensiveRebounds: defensiveRebounds ?? this.defensiveRebounds,
      totalRebounds: totalRebounds ?? this.totalRebounds,
      assists: assists ?? this.assists,
      steals: steals ?? this.steals,
      blocks: blocks ?? this.blocks,
      turnovers: turnovers ?? this.turnovers,
      personalFouls: personalFouls ?? this.personalFouls,
      plusMinus: plusMinus ?? this.plusMinus,
      fouledOut: fouledOut ?? this.fouledOut,
      ejected: ejected ?? this.ejected,
      isManuallyEdited: isManuallyEdited ?? this.isManuallyEdited,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
