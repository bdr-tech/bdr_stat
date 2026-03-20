import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'match_dao.g.dart';

@DriftAccessor(tables: [LocalMatches, LocalTournamentTeams])
class MatchDao extends DatabaseAccessor<AppDatabase> with _$MatchDaoMixin {
  MatchDao(super.db);

  // ═══════════════════════════════════════════════════════════════
  // Match CRUD
  // ═══════════════════════════════════════════════════════════════

  Future<int> insertMatch(LocalMatchesCompanion match) async {
    return into(localMatches).insert(match);
  }

  Future<LocalMatche?> getMatchById(int id) async {
    return (select(localMatches)..where((m) => m.id.equals(id)))
        .getSingleOrNull();
  }

  Future<LocalMatche?> getMatchByLocalUuid(String localUuid) async {
    final results = await (select(localMatches)..where((m) => m.localUuid.equals(localUuid))
      ..limit(1)).get();
    return results.isEmpty ? null : results.first;
  }

  Future<List<LocalMatche>> getMatchesByTournament(String tournamentId) async {
    return (select(localMatches)
          ..where((m) => m.tournamentId.equals(tournamentId))
          ..orderBy([
            (m) => OrderingTerm.desc(m.scheduledAt),
            (m) => OrderingTerm.desc(m.createdAt),
          ]))
        .get();
  }

  Future<List<LocalMatche>> getLiveMatches() async {
    return (select(localMatches)..where((m) => m.status.equals('live'))).get();
  }

  Future<List<LocalMatche>> getUnsyncedMatches() async {
    return (select(localMatches)
          ..where((m) =>
              m.isSynced.equals(false) & m.status.equals('finished')))
        .get();
  }

  Future<List<LocalMatche>> getMatchesByStatus(
      String tournamentId, String status) async {
    return (select(localMatches)
          ..where((m) =>
              m.tournamentId.equals(tournamentId) & m.status.equals(status))
          ..orderBy([
            (m) => OrderingTerm.asc(m.scheduledAt),
            (m) => OrderingTerm.desc(m.createdAt),
          ]))
        .get();
  }

  Future<int> saveMatch(LocalMatchesCompanion match) async {
    // localUuid 기준 중복 체크 — 이미 있으면 serverId 등 업데이트
    final uuid = match.localUuid.value;
    final existing = await getMatchByLocalUuid(uuid);
    if (existing != null) {
      await (update(localMatches)..where((m) => m.localUuid.equals(uuid))).write(
        LocalMatchesCompanion(
          serverId: match.serverId,
          serverUuid: match.serverUuid,
          status: match.status,
          updatedAt: Value(DateTime.now()),
        ),
      );
      return existing.id;
    }
    return into(localMatches).insert(match);
  }

  Future<void> updateMatchScore(int matchId, int homeScore, int awayScore) async {
    await updateScore(matchId, homeScore, awayScore);
  }

  Future<void> updateMatchStatus(int matchId, String status) async {
    await updateStatus(matchId, status);
  }

  Future<void> updateMatchClock(int matchId, int quarter, int clockSeconds) async {
    await (update(localMatches)..where((m) => m.id.equals(matchId))).write(
      LocalMatchesCompanion(
        currentQuarter: Value(quarter),
        gameClockSeconds: Value(clockSeconds),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<LocalMatche?> watchMatch(int matchId) {
    return (select(localMatches)..where((m) => m.id.equals(matchId)))
        .watchSingleOrNull();
  }

  // ═══════════════════════════════════════════════════════════════
  // Match Updates
  // ═══════════════════════════════════════════════════════════════

  Future<void> updateMatch(int id, LocalMatchesCompanion match) async {
    await (update(localMatches)..where((m) => m.id.equals(id))).write(match);
  }

  Future<void> updateScore(int matchId, int homeScore, int awayScore) async {
    await (update(localMatches)..where((m) => m.id.equals(matchId))).write(
      LocalMatchesCompanion(
        homeScore: Value(homeScore),
        awayScore: Value(awayScore),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateGameClock(int matchId, int gameClockSeconds) async {
    await (update(localMatches)..where((m) => m.id.equals(matchId))).write(
      LocalMatchesCompanion(
        gameClockSeconds: Value(gameClockSeconds),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateShotClock(int matchId, int shotClockSeconds) async {
    await (update(localMatches)..where((m) => m.id.equals(matchId))).write(
      LocalMatchesCompanion(
        shotClockSeconds: Value(shotClockSeconds),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateQuarter(int matchId, int quarter) async {
    await (update(localMatches)..where((m) => m.id.equals(matchId))).write(
      LocalMatchesCompanion(
        currentQuarter: Value(quarter),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateStatus(int matchId, String status) async {
    final now = DateTime.now();
    final companion = LocalMatchesCompanion(
      status: Value(status),
      updatedAt: Value(now),
    );

    // 상태에 따른 시간 기록
    if (status == 'live') {
      await (update(localMatches)..where((m) => m.id.equals(matchId))).write(
        companion.copyWith(startedAt: Value(now)),
      );
    } else if (status == 'finished') {
      await (update(localMatches)..where((m) => m.id.equals(matchId))).write(
        companion.copyWith(endedAt: Value(now)),
      );
    } else {
      await (update(localMatches)..where((m) => m.id.equals(matchId)))
          .write(companion);
    }
  }

  Future<void> updateQuarterScores(int matchId, String quarterScoresJson) async {
    await (update(localMatches)..where((m) => m.id.equals(matchId))).write(
      LocalMatchesCompanion(
        quarterScoresJson: Value(quarterScoresJson),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateTeamFouls(int matchId, String teamFoulsJson) async {
    await (update(localMatches)..where((m) => m.id.equals(matchId))).write(
      LocalMatchesCompanion(
        teamFoulsJson: Value(teamFoulsJson),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateTimeouts(
    int matchId, {
    int? homeTimeouts,
    int? awayTimeouts,
  }) async {
    await (update(localMatches)..where((m) => m.id.equals(matchId))).write(
      LocalMatchesCompanion(
        homeTimeoutsRemaining: homeTimeouts != null ? Value(homeTimeouts) : const Value.absent(),
        awayTimeoutsRemaining: awayTimeouts != null ? Value(awayTimeouts) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setMvp(int matchId, int mvpPlayerId) async {
    await (update(localMatches)..where((m) => m.id.equals(matchId))).write(
      LocalMatchesCompanion(
        mvpPlayerId: Value(mvpPlayerId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markAsSynced(int matchId, {int? serverId, String? serverUuid}) async {
    await (update(localMatches)..where((m) => m.id.equals(matchId))).write(
      LocalMatchesCompanion(
        isSynced: const Value(true),
        syncedAt: Value(DateTime.now()),
        serverId: serverId != null ? Value(serverId) : const Value.absent(),
        serverUuid: serverUuid != null ? Value(serverUuid) : const Value.absent(),
        syncError: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markSyncError(int matchId, String error) async {
    await (update(localMatches)..where((m) => m.id.equals(matchId))).write(
      LocalMatchesCompanion(
        syncError: Value(error),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// updatedAt 시간만 갱신 (자동 저장용)
  Future<void> touchUpdatedAt(int matchId) async {
    await (update(localMatches)..where((m) => m.id.equals(matchId))).write(
      LocalMatchesCompanion(
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 상태별 경기 조회 (전체 대회)
  Future<List<LocalMatche>> getAllMatchesByStatus(String status) async {
    return (select(localMatches)
          ..where((m) => m.status.equals(status))
          ..orderBy([
            (m) => OrderingTerm.desc(m.updatedAt),
          ]))
        .get();
  }

  // ═══════════════════════════════════════════════════════════════
  // Match Delete
  // ═══════════════════════════════════════════════════════════════

  Future<void> deleteMatch(int id) async {
    await (delete(localMatches)..where((m) => m.id.equals(id))).go();
  }
}

extension LocalMatchesCompanionCopyWith on LocalMatchesCompanion {
  LocalMatchesCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<String?>? serverUuid,
    Value<String>? localUuid,
    Value<String>? tournamentId,
    Value<int>? homeTeamId,
    Value<int>? awayTeamId,
    Value<String>? homeTeamName,
    Value<String>? awayTeamName,
    Value<int>? homeScore,
    Value<int>? awayScore,
    Value<String>? quarterScoresJson,
    Value<int>? currentQuarter,
    Value<int>? gameClockSeconds,
    Value<int>? shotClockSeconds,
    Value<String>? status,
    Value<String>? teamFoulsJson,
    Value<int>? homeTimeoutsRemaining,
    Value<int>? awayTimeoutsRemaining,
    Value<String?>? roundName,
    Value<int?>? roundNumber,
    Value<String?>? groupName,
    Value<int?>? mvpPlayerId,
    Value<DateTime?>? scheduledAt,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? endedAt,
    Value<bool>? isSynced,
    Value<DateTime?>? syncedAt,
    Value<String?>? syncError,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return LocalMatchesCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      serverUuid: serverUuid ?? this.serverUuid,
      localUuid: localUuid ?? this.localUuid,
      tournamentId: tournamentId ?? this.tournamentId,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      homeTeamName: homeTeamName ?? this.homeTeamName,
      awayTeamName: awayTeamName ?? this.awayTeamName,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      quarterScoresJson: quarterScoresJson ?? this.quarterScoresJson,
      currentQuarter: currentQuarter ?? this.currentQuarter,
      gameClockSeconds: gameClockSeconds ?? this.gameClockSeconds,
      shotClockSeconds: shotClockSeconds ?? this.shotClockSeconds,
      status: status ?? this.status,
      teamFoulsJson: teamFoulsJson ?? this.teamFoulsJson,
      homeTimeoutsRemaining: homeTimeoutsRemaining ?? this.homeTimeoutsRemaining,
      awayTimeoutsRemaining: awayTimeoutsRemaining ?? this.awayTimeoutsRemaining,
      roundName: roundName ?? this.roundName,
      roundNumber: roundNumber ?? this.roundNumber,
      groupName: groupName ?? this.groupName,
      mvpPlayerId: mvpPlayerId ?? this.mvpPlayerId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      isSynced: isSynced ?? this.isSynced,
      syncedAt: syncedAt ?? this.syncedAt,
      syncError: syncError ?? this.syncError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
