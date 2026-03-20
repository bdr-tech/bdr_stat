import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'tournament_dao.g.dart';

@DriftAccessor(tables: [
  LocalTournaments,
  LocalTournamentTeams,
  LocalTournamentPlayers,
  RecentTournaments,
])
class TournamentDao extends DatabaseAccessor<AppDatabase>
    with _$TournamentDaoMixin {
  TournamentDao(super.db);

  // ═══════════════════════════════════════════════════════════════
  // Tournament CRUD
  // ═══════════════════════════════════════════════════════════════

  Future<void> insertTournament(LocalTournamentsCompanion tournament) async {
    await into(localTournaments).insertOnConflictUpdate(tournament);
  }

  Future<LocalTournament?> getTournamentById(String id) async {
    return (select(localTournaments)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<LocalTournament?> getTournamentByToken(String token) async {
    return (select(localTournaments)..where((t) => t.apiToken.equals(token)))
        .getSingleOrNull();
  }

  Future<List<LocalTournament>> getAllTournaments() async {
    return select(localTournaments).get();
  }

  Future<void> deleteTournament(String id) async {
    await (delete(localTournaments)..where((t) => t.id.equals(id))).go();
  }

  // ═══════════════════════════════════════════════════════════════
  // Tournament Teams CRUD
  // ═══════════════════════════════════════════════════════════════

  Future<void> insertTeam(LocalTournamentTeamsCompanion team) async {
    await into(localTournamentTeams).insertOnConflictUpdate(team);
  }

  Future<void> insertTeams(List<LocalTournamentTeamsCompanion> teams) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localTournamentTeams, teams);
    });
  }

  Future<List<LocalTournamentTeam>> getTeamsByTournament(
      String tournamentId) async {
    return (select(localTournamentTeams)
          ..where((t) => t.tournamentId.equals(tournamentId)))
        .get();
  }

  Future<LocalTournamentTeam?> getTeamById(int id) async {
    return (select(localTournamentTeams)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // ═══════════════════════════════════════════════════════════════
  // Tournament Players CRUD
  // ═══════════════════════════════════════════════════════════════

  Future<void> insertPlayer(LocalTournamentPlayersCompanion player) async {
    await into(localTournamentPlayers).insertOnConflictUpdate(player);
  }

  Future<void> insertPlayers(
      List<LocalTournamentPlayersCompanion> players) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localTournamentPlayers, players);
    });
  }

  Future<List<LocalTournamentPlayer>> getPlayersByTeam(int teamId) async {
    return (select(localTournamentPlayers)
          ..where((p) => p.tournamentTeamId.equals(teamId))
          ..orderBy([(p) => OrderingTerm.asc(p.jerseyNumber)]))
        .get();
  }

  /// Alias for getPlayersByTeam
  Future<List<LocalTournamentPlayer>> getPlayersByTeamId(int teamId) async {
    return getPlayersByTeam(teamId);
  }

  Future<LocalTournamentPlayer?> getPlayerById(int id) async {
    return (select(localTournamentPlayers)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  /// 여러 선수를 ID 목록으로 한번에 조회 (성능 최적화)
  Future<List<LocalTournamentPlayer>> getPlayersByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    return (select(localTournamentPlayers)..where((p) => p.id.isIn(ids))).get();
  }

  Future<List<LocalTournamentPlayer>> getStartersByTeam(int teamId) async {
    return (select(localTournamentPlayers)
          ..where((p) =>
              p.tournamentTeamId.equals(teamId) & p.isStarter.equals(true)))
        .get();
  }

  Future<void> updatePlayerStarter(int playerId, bool isStarter) async {
    await (update(localTournamentPlayers)
          ..where((p) => p.id.equals(playerId)))
        .write(LocalTournamentPlayersCompanion(
          isStarter: Value(isStarter),
        ));
  }

  // ═══════════════════════════════════════════════════════════════
  // Recent Tournaments
  // ═══════════════════════════════════════════════════════════════

  Future<void> addRecentTournament({
    required String tournamentId,
    required String tournamentName,
    required String apiToken,
  }) async {
    await into(recentTournaments).insertOnConflictUpdate(
      RecentTournamentsCompanion(
        tournamentId: Value(tournamentId),
        tournamentName: Value(tournamentName),
        apiToken: Value(apiToken),
        connectedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Save recent tournament using companion
  Future<void> saveRecentTournament(RecentTournamentsCompanion recent) async {
    await into(recentTournaments).insertOnConflictUpdate(recent);
  }

  /// Alias methods for backward compatibility
  Future<void> saveTournament(LocalTournamentsCompanion tournament) async {
    await insertTournament(tournament);
  }

  Future<void> saveTeam(LocalTournamentTeamsCompanion team) async {
    await insertTeam(team);
  }

  Future<void> savePlayer(LocalTournamentPlayersCompanion player) async {
    await insertPlayer(player);
  }

  Future<List<RecentTournament>> getRecentTournaments({int limit = 5}) async {
    return (select(recentTournaments)
          ..orderBy([(t) => OrderingTerm.desc(t.connectedAt)])
          ..limit(limit))
        .get();
  }

  Future<void> deleteRecentTournament(String tournamentId) async {
    await (delete(recentTournaments)
          ..where((t) => t.tournamentId.equals(tournamentId)))
        .go();
  }

  // ═══════════════════════════════════════════════════════════════
  // Bulk Operations (대회 데이터 일괄 저장)
  // ═══════════════════════════════════════════════════════════════

  Future<void> saveTournamentData({
    required LocalTournamentsCompanion tournament,
    required List<LocalTournamentTeamsCompanion> teams,
    required List<LocalTournamentPlayersCompanion> players,
  }) async {
    await transaction(() async {
      await insertTournament(tournament);
      await insertTeams(teams);
      await insertPlayers(players);
    });
  }

  /// 대회 캐시 데이터 삭제 (팀/선수만 — 경기/스탯/PBP는 별도)
  Future<void> clearTournamentData(String tournamentId) async {
    await transaction(() async {
      // 선수 삭제 (팀 ID로)
      final teams = await getTeamsByTournament(tournamentId);
      for (final team in teams) {
        await (delete(localTournamentPlayers)
              ..where((p) => p.tournamentTeamId.equals(team.id)))
            .go();
      }
      // 팀 삭제
      await (delete(localTournamentTeams)
            ..where((t) => t.tournamentId.equals(tournamentId)))
          .go();
      // 대회 삭제
      await deleteTournament(tournamentId);
    });
  }

  /// 대회 전체 데이터 삭제 (경기/스탯/PBP/수정로그 포함)
  Future<void> clearAllTournamentData(String tournamentId) async {
    await transaction(() async {
      // 1. 경기 관련 데이터 삭제 (경기 ID 목록 먼저 조회)
      final matches = await db.matchDao.getMatchesByTournament(tournamentId);
      for (final match in matches) {
        // 수정 로그 삭제
        await (db.delete(db.localEditLogs)
              ..where((e) => e.localMatchId.equals(match.id)))
            .go();
        // PBP 삭제
        await (db.delete(db.localPlayByPlays)
              ..where((p) => p.localMatchId.equals(match.id)))
            .go();
        // 선수 스탯 삭제
        await (db.delete(db.localPlayerStats)
              ..where((s) => s.localMatchId.equals(match.id)))
            .go();
      }
      // 경기 삭제
      await (db.delete(db.localMatches)
            ..where((m) => m.tournamentId.equals(tournamentId)))
          .go();

      // 2. 선수 삭제
      final teams = await getTeamsByTournament(tournamentId);
      for (final team in teams) {
        await (delete(localTournamentPlayers)
              ..where((p) => p.tournamentTeamId.equals(team.id)))
            .go();
      }

      // 3. 팀 삭제
      await (delete(localTournamentTeams)
            ..where((t) => t.tournamentId.equals(tournamentId)))
          .go();

      // 4. 대회 삭제
      await deleteTournament(tournamentId);
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // Cache Stats (캐시 현황 조회)
  // ═══════════════════════════════════════════════════════════════

  /// 대회별 캐시 현황 조회
  Future<TournamentCacheStats> getCacheStats(String tournamentId) async {
    final tournament = await getTournamentById(tournamentId);
    if (tournament == null) {
      return TournamentCacheStats.empty(tournamentId);
    }

    final teams = await getTeamsByTournament(tournamentId);

    int playerCount = 0;
    for (final team in teams) {
      final players = await getPlayersByTeam(team.id);
      playerCount += players.length;
    }

    final matches = await db.matchDao.getMatchesByTournament(tournamentId);
    final unsyncedMatches = matches.where(
      (m) => !m.isSynced && m.status == 'finished',
    ).toList();
    final finishedMatches = matches.where(
      (m) => m.status == 'finished',
    ).toList();

    // 가장 오래된/최신 syncedAt
    DateTime? teamsSyncedAt;
    if (teams.isNotEmpty) {
      teamsSyncedAt = teams.first.syncedAt;
      for (final team in teams) {
        if (team.syncedAt.isBefore(teamsSyncedAt!)) {
          teamsSyncedAt = team.syncedAt;
        }
      }
    }

    return TournamentCacheStats(
      tournamentId: tournamentId,
      tournamentName: tournament.name,
      tournamentStatus: tournament.status,
      teamCount: teams.length,
      playerCount: playerCount,
      matchCount: matches.length,
      finishedMatchCount: finishedMatches.length,
      unsyncedMatchCount: unsyncedMatches.length,
      tournamentSyncedAt: tournament.syncedAt,
      teamsSyncedAt: teamsSyncedAt,
    );
  }

  /// 모든 연결된 대회의 캐시 현황 조회
  Future<List<TournamentCacheStats>> getAllCacheStats() async {
    final tournaments = await getAllTournaments();
    final stats = <TournamentCacheStats>[];
    for (final tournament in tournaments) {
      stats.add(await getCacheStats(tournament.id));
    }
    return stats;
  }
}

/// 대회 캐시 현황 데이터
class TournamentCacheStats {
  final String tournamentId;
  final String tournamentName;
  final String tournamentStatus;
  final int teamCount;
  final int playerCount;
  final int matchCount;
  final int finishedMatchCount;
  final int unsyncedMatchCount;
  final DateTime? tournamentSyncedAt;
  final DateTime? teamsSyncedAt;

  const TournamentCacheStats({
    required this.tournamentId,
    required this.tournamentName,
    required this.tournamentStatus,
    required this.teamCount,
    required this.playerCount,
    required this.matchCount,
    required this.finishedMatchCount,
    required this.unsyncedMatchCount,
    this.tournamentSyncedAt,
    this.teamsSyncedAt,
  });

  factory TournamentCacheStats.empty(String tournamentId) {
    return TournamentCacheStats(
      tournamentId: tournamentId,
      tournamentName: '',
      tournamentStatus: '',
      teamCount: 0,
      playerCount: 0,
      matchCount: 0,
      finishedMatchCount: 0,
      unsyncedMatchCount: 0,
    );
  }

  bool get hasUnsyncedMatches => unsyncedMatchCount > 0;

  /// 마지막 동기화 시각 (가장 오래된 것 기준)
  DateTime? get lastSyncedAt {
    if (tournamentSyncedAt == null) return null;
    if (teamsSyncedAt == null) return tournamentSyncedAt;
    return tournamentSyncedAt!.isBefore(teamsSyncedAt!)
        ? tournamentSyncedAt
        : teamsSyncedAt;
  }

  /// 동기화가 오래된지 확인 (24시간 기준)
  bool get isSyncStale {
    if (lastSyncedAt == null) return true;
    return DateTime.now().difference(lastSyncedAt!).inHours >= 24;
  }
}
