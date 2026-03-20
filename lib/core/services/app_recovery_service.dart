import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database/database.dart';
import '../../di/providers.dart';

/// 복구 가능한 경기 정보
class RecoverableMatch {
  final int matchId;
  final String homeTeamName;
  final String awayTeamName;
  final int homeScore;
  final int awayScore;
  final int currentQuarter;
  final DateTime? lastUpdated;
  final String status;

  const RecoverableMatch({
    required this.matchId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeScore,
    required this.awayScore,
    required this.currentQuarter,
    this.lastUpdated,
    required this.status,
  });

  String get scoreDisplay => '$homeScore : $awayScore';
  String get quarterDisplay => currentQuarter <= 4 ? 'Q$currentQuarter' : 'OT${currentQuarter - 4}';
}

/// 앱 복구 서비스
/// 앱 재시작 시 진행 중인 경기를 감지하고 복구를 도와줌
class AppRecoveryService {
  AppRecoveryService({
    required this.database,
  });

  final AppDatabase database;

  static const String _lastActiveMatchKey = 'last_active_match_id';
  static const String _lastActiveTimeKey = 'last_active_time';
  static const String _appCrashedKey = 'app_crashed';

  /// 앱 시작 시 복구 필요 여부 확인
  Future<RecoverableMatch?> checkForRecoverableMatch() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. 저장된 마지막 활성 경기 확인
      final lastMatchId = prefs.getInt(_lastActiveMatchKey);
      final lastActiveTime = prefs.getString(_lastActiveTimeKey);
      // 비정상 종료 여부는 진행 중인 경기가 있으면 복구 다이얼로그 표시로 대체
      // final crashed = prefs.getBool(_appCrashedKey) ?? false;

      // 2. 진행 중인 경기 확인 (DB에서 직접)
      final inProgressMatches = await database.matchDao.getAllMatchesByStatus('in_progress');

      if (inProgressMatches.isEmpty) {
        await _clearRecoveryState();
        return null;
      }

      // 3. 가장 최근 진행 중인 경기 찾기
      LocalMatche? targetMatch;

      // 마지막 활성 경기가 있고 여전히 진행 중이면 우선
      if (lastMatchId != null) {
        targetMatch = inProgressMatches
            .where((m) => m.id == lastMatchId)
            .firstOrNull;
      }

      // 없으면 가장 최근 진행 중인 경기
      targetMatch ??= inProgressMatches.first;

      // 4. 팀 정보 로드
      final homeTeam = await database.tournamentDao.getTeamById(targetMatch.homeTeamId);
      final awayTeam = await database.tournamentDao.getTeamById(targetMatch.awayTeamId);

      return RecoverableMatch(
        matchId: targetMatch.id,
        homeTeamName: homeTeam?.teamName ?? '홈팀',
        awayTeamName: awayTeam?.teamName ?? '원정팀',
        homeScore: targetMatch.homeScore,
        awayScore: targetMatch.awayScore,
        currentQuarter: targetMatch.currentQuarter,
        lastUpdated: lastActiveTime != null ? DateTime.tryParse(lastActiveTime) : null,
        status: targetMatch.status,
      );
    } catch (e) {
      debugPrint('Recovery check error: $e');
      return null;
    }
  }

  /// 현재 활성 경기 기록 (앱 사용 중 주기적으로 호출)
  Future<void> recordActiveMatch(int matchId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastActiveMatchKey, matchId);
      await prefs.setString(_lastActiveTimeKey, DateTime.now().toIso8601String());
      await prefs.setBool(_appCrashedKey, true); // 정상 종료 시 false로 변경
    } catch (e) {
      debugPrint('Record active match error: $e');
    }
  }

  /// 앱 정상 종료 기록
  Future<void> recordNormalExit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_appCrashedKey, false);
    } catch (e) {
      debugPrint('Record normal exit error: $e');
    }
  }

  /// 복구 상태 초기화
  Future<void> _clearRecoveryState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastActiveMatchKey);
      await prefs.remove(_lastActiveTimeKey);
      await prefs.remove(_appCrashedKey);
    } catch (e) {
      debugPrint('Clear recovery state error: $e');
    }
  }

  /// 경기 복구 선택 시 호출
  Future<void> onRecoveryAccepted(int matchId) async {
    await recordActiveMatch(matchId);
  }

  /// 경기 새로 시작 선택 시 호출
  Future<void> onRecoveryDeclined(int matchId) async {
    try {
      // 진행 중인 경기를 취소 상태로 변경
      await database.matchDao.updateMatchStatus(matchId, 'cancelled');
      await _clearRecoveryState();
    } catch (e) {
      debugPrint('Decline recovery error: $e');
    }
  }

  /// 완료되지 않은 모든 경기 목록 조회
  Future<List<RecoverableMatch>> getAllInProgressMatches() async {
    try {
      final matches = await database.matchDao.getAllMatchesByStatus('in_progress');
      final result = <RecoverableMatch>[];

      for (final match in matches) {
        final homeTeam = await database.tournamentDao.getTeamById(match.homeTeamId);
        final awayTeam = await database.tournamentDao.getTeamById(match.awayTeamId);

        result.add(RecoverableMatch(
          matchId: match.id,
          homeTeamName: homeTeam?.teamName ?? '홈팀',
          awayTeamName: awayTeam?.teamName ?? '원정팀',
          homeScore: match.homeScore,
          awayScore: match.awayScore,
          currentQuarter: match.currentQuarter,
          lastUpdated: match.updatedAt,
          status: match.status,
        ));
      }

      return result;
    } catch (e) {
      debugPrint('Get all in-progress matches error: $e');
      return [];
    }
  }

  /// 데이터 무결성 검증
  Future<List<String>> validateMatchData(int matchId) async {
    final issues = <String>[];

    try {
      final match = await database.matchDao.getMatchById(matchId);
      if (match == null) {
        issues.add('경기 정보를 찾을 수 없습니다.');
        return issues;
      }

      // 선수 스탯 확인
      final homeStats = await database.playerStatsDao
          .getStatsByMatchAndTeam(matchId, match.homeTeamId);
      final awayStats = await database.playerStatsDao
          .getStatsByMatchAndTeam(matchId, match.awayTeamId);

      if (homeStats.isEmpty) {
        issues.add('홈팀 선수 스탯이 없습니다.');
      }
      if (awayStats.isEmpty) {
        issues.add('원정팀 선수 스탯이 없습니다.');
      }

      // 점수 합계 검증
      final homePointsSum = homeStats.fold<int>(0, (sum, s) => sum + s.points);
      final awayPointsSum = awayStats.fold<int>(0, (sum, s) => sum + s.points);

      if (homePointsSum != match.homeScore) {
        issues.add('홈팀 점수 불일치: 기록 ${match.homeScore}, 합계 $homePointsSum');
      }
      if (awayPointsSum != match.awayScore) {
        issues.add('원정팀 점수 불일치: 기록 ${match.awayScore}, 합계 $awayPointsSum');
      }

      // 플레이바이플레이 확인
      final plays = await database.playByPlayDao.getPlaysByMatch(matchId);
      if (plays.isEmpty && (match.homeScore > 0 || match.awayScore > 0)) {
        issues.add('플레이 기록이 없습니다 (점수는 있음).');
      }
    } catch (e) {
      issues.add('데이터 검증 중 오류: $e');
    }

    return issues;
  }
}

/// 앱 복구 서비스 프로바이더
final appRecoveryServiceProvider = Provider<AppRecoveryService>((ref) {
  final database = ref.watch(databaseProvider);
  return AppRecoveryService(database: database);
});

/// 복구 가능한 경기 프로바이더
final recoverableMatchProvider = FutureProvider<RecoverableMatch?>((ref) async {
  final service = ref.watch(appRecoveryServiceProvider);
  return service.checkForRecoverableMatch();
});
