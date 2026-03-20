import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../data/api/api_client.dart';
import '../../data/database/database.dart';

/// 서버→로컬 데이터 새로고침 결과
class DataRefreshResult {
  final bool success;
  final String? errorMessage;
  final int newMatchesAdded;
  final int matchesUpdated;
  final int teamsUpdated;
  final int playersUpdated;
  final int matchesSkipped;

  const DataRefreshResult({
    required this.success,
    this.errorMessage,
    this.newMatchesAdded = 0,
    this.matchesUpdated = 0,
    this.teamsUpdated = 0,
    this.playersUpdated = 0,
    this.matchesSkipped = 0,
  });

  String get summary {
    if (!success) return errorMessage ?? '새로고침 실패';
    final parts = <String>[];
    if (newMatchesAdded > 0) parts.add('새 경기 $newMatchesAdded건 추가');
    if (matchesUpdated > 0) parts.add('경기 $matchesUpdated건 업데이트');
    if (teamsUpdated > 0) parts.add('팀 $teamsUpdated개 갱신');
    if (playersUpdated > 0) parts.add('선수 $playersUpdated명 갱신');
    if (matchesSkipped > 0) parts.add('진행 중 $matchesSkipped건 건너뜀');
    if (parts.isEmpty) return '데이터가 최신 상태입니다';
    return '데이터 갱신 완료 (${parts.join(', ')})';
  }
}

/// 서버→로컬 데이터 새로고침 서비스
///
/// mybdr.kr 서버에서 최신 대회 데이터를 다운로드하여
/// 로컬 DB에 병합합니다. 기록 중인 경기(live)와
/// 미업로드 경기(finished & !isSynced)의 데이터는 보호합니다.
class DataRefreshService {
  DataRefreshService({
    required this.database,
    required this.apiClient,
  });

  final AppDatabase database;
  final ApiClient apiClient;

  /// 대회 전체 데이터 새로고침 (서버→로컬 병합)
  Future<DataRefreshResult> refreshTournamentData(String tournamentId) async {
    try {
      // 1. 서버에서 전체 데이터 다운로드
      final result = await apiClient.getTournamentFullData(tournamentId);

      if (!result.isSuccess || result.data == null) {
        final error = result.error ?? '데이터 다운로드 실패';
        // 404: 서버에서 대회 삭제됨
        if (error.contains('찾을 수 없습니다')) {
          return DataRefreshResult(
            success: false,
            errorMessage: '서버에서 대회가 삭제되었습니다.',
          );
        }
        return DataRefreshResult(success: false, errorMessage: error);
      }

      final fullData = result.data!;

      // 2. 트랜잭션으로 병합 실행
      return await _mergeData(tournamentId, fullData);
    } catch (e) {
      debugPrint('[DataRefreshService] refreshTournamentData error: $e');
      return DataRefreshResult(
        success: false,
        errorMessage: _parseErrorMessage(e),
      );
    }
  }

  /// 서버 데이터를 로컬 DB에 병합
  Future<DataRefreshResult> _mergeData(
    String tournamentId,
    TournamentFullData fullData,
  ) async {
    int newMatchesAdded = 0;
    int matchesUpdated = 0;
    int matchesSkipped = 0;
    int teamsUpdated = 0;
    int playersUpdated = 0;

    await database.transaction(() async {
      final now = DateTime.now();

      // ── 대회 정보 upsert (기존 apiToken 유지) ──
      final existingTournament =
          await database.tournamentDao.getTournamentById(tournamentId);
      final apiToken = existingTournament?.apiToken ?? '';

      await database.tournamentDao.insertTournament(
        LocalTournamentsCompanion.insert(
          id: fullData.tournament.id,
          name: fullData.tournament.name,
          status: fullData.tournament.status,
          startDate: Value(fullData.tournament.startDate),
          endDate: Value(fullData.tournament.endDate),
          venueName: Value(fullData.tournament.venueName),
          venueAddress: Value(fullData.tournament.venueAddress),
          gameRulesJson: jsonEncode(fullData.tournament.gameRules ?? {}),
          apiToken: apiToken,
          syncedAt: now,
        ),
      );

      // ── 팀 upsert (insertOnConflictUpdate) ──
      final teamCompanions = fullData.teams.map((team) {
        return LocalTournamentTeamsCompanion.insert(
          id: Value(team.id),
          tournamentId: team.tournamentId,
          teamId: team.teamId,
          teamName: team.teamName,
          teamLogoUrl: Value(team.teamLogoUrl),
          primaryColor: Value(team.primaryColor),
          secondaryColor: Value(team.secondaryColor),
          groupName: Value(team.groupName),
          seedNumber: Value(team.seedNumber),
          syncedAt: now,
        );
      }).toList();
      await database.tournamentDao.insertTeams(teamCompanions);
      teamsUpdated = teamCompanions.length;

      // ── 선수 upsert ──
      // 서버에 있는 선수 ID 목록 수집
      final serverPlayerIds = <int>{};

      final playerCompanions = fullData.players.map((player) {
        serverPlayerIds.add(player.id);
        return LocalTournamentPlayersCompanion.insert(
          id: Value(player.id),
          tournamentTeamId: player.tournamentTeamId,
          userId: Value(player.userId),
          userName: player.userName,
          userNickname: Value(player.userNickname),
          profileImageUrl: Value(player.profileImageUrl),
          jerseyNumber: Value(player.jerseyNumber),
          position: Value(player.position),
          role: player.role,
          isStarter: Value(player.isStarter),
          isActive: Value(player.isActive),
          bdrDnaCode: Value(player.bdrDnaCode),
          syncedAt: now,
        );
      }).toList();
      await database.tournamentDao.insertPlayers(playerCompanions);
      playersUpdated = playerCompanions.length;

      // 서버 응답에 없는 선수는 isActive = false 처리 (삭제하지 않음)
      for (final team in fullData.teams) {
        final localPlayers =
            await database.tournamentDao.getPlayersByTeam(team.id);
        for (final player in localPlayers) {
          if (!serverPlayerIds.contains(player.id)) {
            await database.tournamentDao.updatePlayerStarter(player.id, false);
            // isActive를 false로 변경
            await (database.update(database.localTournamentPlayers)
                  ..where((p) => p.id.equals(player.id)))
                .write(const LocalTournamentPlayersCompanion(
              isActive: Value(false),
            ));
          }
        }
      }

      // ── 경기 병합 (핵심 로직) ──
      // serverId → localMatchId 매핑 (스탯/PBP 병합용)
      final serverIdToLocalMatchId = <int, int>{};

      for (final serverMatch in fullData.matches) {
        final mergeResult = await _mergeMatch(
          tournamentId: tournamentId,
          serverMatch: serverMatch,
          teams: fullData.teams,
          now: now,
        );
        switch (mergeResult) {
          case _MatchMergeResult.inserted:
            newMatchesAdded++;
            break;
          case _MatchMergeResult.updated:
            matchesUpdated++;
            break;
          case _MatchMergeResult.skipped:
            matchesSkipped++;
            break;
        }

        // 매핑 구축: serverId → localMatchId
        final localMatch = await database.matchDao
            .getMatchByLocalUuid('local_${serverMatch.uuid}');
        if (localMatch != null) {
          serverIdToLocalMatchId[serverMatch.id] = localMatch.id;
        }
      }

      // ── 완료+동기화된 경기의 스탯/PBP 병합 ──
      await _mergePlayerStats(
        fullData.playerStats,
        serverIdToLocalMatchId,
        now,
      );
      await _mergePlayByPlays(
        fullData.playByPlays,
        serverIdToLocalMatchId,
        now,
      );
    });

    return DataRefreshResult(
      success: true,
      newMatchesAdded: newMatchesAdded,
      matchesUpdated: matchesUpdated,
      teamsUpdated: teamsUpdated,
      playersUpdated: playersUpdated,
      matchesSkipped: matchesSkipped,
    );
  }

  /// 개별 경기 병합 로직
  ///
  /// 서버 경기 → 로컬 DB에서 serverUuid로 검색
  ///   ├─ 매칭 없음 → 새 경기로 INSERT
  ///   └─ 매칭 있음 → 로컬 상태 확인
  ///         ├─ 로컬 status = 'live' → 건너뜀 (기록 중 보호)
  ///         ├─ 로컬 status = 'finished' & isSynced = false → 건너뜀 (업로드 우선)
  ///         └─ 그 외 → 서버 데이터로 업데이트
  Future<_MatchMergeResult> _mergeMatch({
    required String tournamentId,
    required MatchData serverMatch,
    required List<TeamData> teams,
    required DateTime now,
  }) async {
    // serverUuid로 로컬 매칭 검색
    final localMatch =
        await database.matchDao.getMatchByLocalUuid('local_${serverMatch.uuid}');

    // serverUuid가 일치하는 경기가 없으면 serverId로도 확인
    final existingByServerId = localMatch ??
        await _findMatchByServerId(tournamentId, serverMatch.id);

    if (existingByServerId == null) {
      // 새 경기 INSERT
      final homeTeam = teams.firstWhere(
        (t) => t.id == serverMatch.homeTeamId,
        orElse: () => teams.first,
      );
      final awayTeam = teams.firstWhere(
        (t) => t.id == serverMatch.awayTeamId,
        orElse: () => teams.first,
      );

      await database.matchDao.saveMatch(LocalMatchesCompanion.insert(
        serverId: Value(serverMatch.id),
        serverUuid: Value(serverMatch.uuid),
        localUuid: 'local_${serverMatch.uuid}',
        tournamentId: serverMatch.tournamentId,
        homeTeamId: serverMatch.homeTeamId,
        awayTeamId: serverMatch.awayTeamId,
        homeTeamName: homeTeam.teamName,
        awayTeamName: awayTeam.teamName,
        roundName: Value(serverMatch.roundName),
        roundNumber: Value(serverMatch.roundNumber),
        groupName: Value(serverMatch.groupName),
        scheduledAt: Value(serverMatch.scheduledAt),
        status: Value(serverMatch.status),
        homeScore: Value(serverMatch.homeScore ?? 0),
        awayScore: Value(serverMatch.awayScore ?? 0),
        createdAt: now,
        updatedAt: now,
      ));
      return _MatchMergeResult.inserted;
    }

    // 로컬 경기가 존재하는 경우 — 상태별 처리
    final localStatus = existingByServerId.status;

    // live 경기: 기록 중 보호 → 건너뜀
    if (localStatus == 'live' || localStatus == 'in_progress') {
      return _MatchMergeResult.skipped;
    }

    // finished & 미업로드: 로컬 기록 보호 → 건너뜀
    if ((localStatus == 'finished' || localStatus == 'completed') &&
        !existingByServerId.isSynced) {
      return _MatchMergeResult.skipped;
    }

    // scheduled 또는 finished+synced: 서버 데이터로 업데이트
    final homeTeam = teams.firstWhere(
      (t) => t.id == serverMatch.homeTeamId,
      orElse: () => teams.first,
    );
    final awayTeam = teams.firstWhere(
      (t) => t.id == serverMatch.awayTeamId,
      orElse: () => teams.first,
    );

    await database.matchDao.updateMatch(
      existingByServerId.id,
      LocalMatchesCompanion(
        serverId: Value(serverMatch.id),
        serverUuid: Value(serverMatch.uuid),
        homeTeamId: Value(serverMatch.homeTeamId),
        awayTeamId: Value(serverMatch.awayTeamId),
        homeTeamName: Value(homeTeam.teamName),
        awayTeamName: Value(awayTeam.teamName),
        roundName: Value(serverMatch.roundName),
        roundNumber: Value(serverMatch.roundNumber),
        groupName: Value(serverMatch.groupName),
        scheduledAt: Value(serverMatch.scheduledAt),
        status: Value(serverMatch.status),
        homeScore: Value(serverMatch.homeScore ?? 0),
        awayScore: Value(serverMatch.awayScore ?? 0),
        updatedAt: Value(now),
      ),
    );
    return _MatchMergeResult.updated;
  }

  /// serverId로 로컬 경기 찾기
  Future<LocalMatche?> _findMatchByServerId(
      String tournamentId, int serverId) async {
    final matches =
        await database.matchDao.getMatchesByTournament(tournamentId);
    for (final match in matches) {
      if (match.serverId == serverId) {
        return match;
      }
    }
    return null;
  }

  /// 서버 선수 스탯을 로컬 DB에 병합
  /// 이미 업로드된(isSynced) 경기의 스탯만 병합, 로컬 미업로드 데이터는 보호
  Future<void> _mergePlayerStats(
    List<ServerPlayerStatData> serverStats,
    Map<int, int> serverIdToLocalMatchId,
    DateTime now,
  ) async {
    for (final stat in serverStats) {
      final localMatchId = serverIdToLocalMatchId[stat.tournamentMatchId];
      if (localMatchId == null) continue;

      // 로컬 경기 상태 확인 - 미업로드 경기의 스탯은 건너뜀
      final localMatch = await database.matchDao.getMatchById(localMatchId);
      if (localMatch == null) continue;
      if ((localMatch.status == 'finished' || localMatch.status == 'completed') &&
          !localMatch.isSynced) {
        continue; // 로컬 기록 보호
      }

      // 해당 경기+선수의 기존 스탯 확인
      final existingStats = await database.playerStatsDao
          .getStatsByMatch(localMatchId);
      final existing = existingStats.where(
        (s) => s.tournamentTeamPlayerId == stat.tournamentTeamPlayerId,
      );

      if (existing.isEmpty) {
        // 새 스탯 INSERT
        await database.into(database.localPlayerStats).insert(
          LocalPlayerStatsCompanion.insert(
            localMatchId: localMatchId,
            tournamentTeamPlayerId: stat.tournamentTeamPlayerId,
            tournamentTeamId: 0, // 서버 데이터에서는 team 정보가 player를 통해 간접 참조
            isStarter: Value(stat.isStarter),
            minutesPlayed: Value(stat.minutesPlayed),
            points: Value(stat.points),
            fieldGoalsMade: Value(stat.fieldGoalsMade),
            fieldGoalsAttempted: Value(stat.fieldGoalsAttempted),
            twoPointersMade: Value(stat.twoPointersMade),
            twoPointersAttempted: Value(stat.twoPointersAttempted),
            threePointersMade: Value(stat.threePointersMade),
            threePointersAttempted: Value(stat.threePointersAttempted),
            freeThrowsMade: Value(stat.freeThrowsMade),
            freeThrowsAttempted: Value(stat.freeThrowsAttempted),
            offensiveRebounds: Value(stat.offensiveRebounds),
            defensiveRebounds: Value(stat.defensiveRebounds),
            totalRebounds: Value(stat.totalRebounds),
            assists: Value(stat.assists),
            steals: Value(stat.steals),
            blocks: Value(stat.blocks),
            turnovers: Value(stat.turnovers),
            personalFouls: Value(stat.personalFouls),
            plusMinus: Value(stat.plusMinus),
            fouledOut: Value(stat.fouledOut),
            ejected: Value(stat.ejected),
            updatedAt: now,
          ),
        );
      }
      // 기존 스탯이 있으면 서버 데이터로 덮어쓰지 않음 (로컬 우선)
    }
  }

  /// 서버 PBP를 로컬 DB에 병합
  /// localId로 중복 방지, 이미 업로드된 경기의 PBP만 병합
  Future<void> _mergePlayByPlays(
    List<ServerPlayByPlayData> serverPbps,
    Map<int, int> serverIdToLocalMatchId,
    DateTime now,
  ) async {
    for (final pbp in serverPbps) {
      final localMatchId = serverIdToLocalMatchId[pbp.tournamentMatchId];
      if (localMatchId == null) continue;

      // 로컬 경기 상태 확인
      final localMatch = await database.matchDao.getMatchById(localMatchId);
      if (localMatch == null) continue;
      if ((localMatch.status == 'finished' || localMatch.status == 'completed') &&
          !localMatch.isSynced) {
        continue; // 로컬 기록 보호
      }

      // localId로 중복 확인
      final existingPbps = await database.playByPlayDao
          .getPlaysByMatch(localMatchId);
      final isDuplicate = existingPbps.any((p) => p.localId == pbp.localId);
      if (isDuplicate) continue;

      await database.into(database.localPlayByPlays).insert(
        LocalPlayByPlaysCompanion.insert(
          localId: pbp.localId,
          localMatchId: localMatchId,
          tournamentTeamPlayerId: pbp.tournamentTeamPlayerId ?? 0,
          tournamentTeamId: pbp.tournamentTeamId ?? 0,
          quarter: pbp.quarter,
          gameClockSeconds: pbp.gameClockSeconds ?? 0,
          shotClockSeconds: Value(pbp.shotClockSeconds),
          actionType: pbp.actionType,
          actionSubtype: Value(pbp.actionSubtype),
          isMade: Value(pbp.isMade),
          pointsScored: Value(pbp.pointsScored),
          courtX: Value(pbp.courtX),
          courtY: Value(pbp.courtY),
          courtZone: Value(pbp.courtZone),
          homeScoreAtTime: pbp.homeScoreAtTime ?? 0,
          awayScoreAtTime: pbp.awayScoreAtTime ?? 0,
          assistPlayerId: Value(pbp.assistPlayerId),
          reboundPlayerId: Value(pbp.reboundPlayerId),
          blockPlayerId: Value(pbp.blockPlayerId),
          stealPlayerId: Value(pbp.stealPlayerId),
          fouledPlayerId: Value(pbp.fouledPlayerId),
          isFastbreak: Value(pbp.isFastbreak),
          isSecondChance: Value(pbp.isSecondChance),
          isFromTurnover: Value(pbp.isFromTurnover),
          description: Value(pbp.description),
          isSynced: Value(true), // 서버에서 받은 데이터이므로 synced
          createdAt: now,
        ),
      );
    }
  }

  String _parseErrorMessage(dynamic error) {
    final message = error.toString();
    if (message.contains('SocketException') ||
        message.contains('connection')) {
      return '네트워크 연결 후 다시 시도해주세요.';
    }
    if (message.contains('401') || message.contains('Unauthorized')) {
      return '인증이 만료되었습니다. 다시 연결해주세요.';
    }
    if (message.contains('404')) {
      return '서버에서 대회가 삭제되었습니다.';
    }
    if (message.contains('timeout')) {
      return '연결 시간이 초과되었습니다.';
    }
    return '데이터 갱신 중 오류가 발생했습니다.';
  }
}

enum _MatchMergeResult { inserted, updated, skipped }
