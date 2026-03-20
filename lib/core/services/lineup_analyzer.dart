// TODO: 이 서비스는 현재 미사용. v2.0에서 활성화 예정.
// 빌드에 포함되나 tree-shaking으로 사용되지 않으면 제거됨.

import '../../data/database/database.dart';

/// 5-man 라인업 분석 서비스
///
/// 기능:
/// - 라인업별 +/- 추적
/// - 베스트/워스트 라인업 분석
/// - 라인업 시간 추적
/// - 라인업 효율성 계산
class LineupAnalyzer {
  LineupAnalyzer._();

  static final LineupAnalyzer instance = LineupAnalyzer._();

  // ═══════════════════════════════════════════════════════════════
  // 라인업 데이터 구조
  // ═══════════════════════════════════════════════════════════════

  /// 현재 코트에 있는 선수들로부터 라인업 생성
  Lineup createLineup(List<int> playerIds) {
    assert(playerIds.length == 5, 'Lineup must have exactly 5 players');

    // ID 정렬로 일관된 키 생성
    final sortedIds = List<int>.from(playerIds)..sort();
    return Lineup(playerIds: sortedIds);
  }

  /// 라인업 키 생성 (선수 ID 조합)
  String generateLineupKey(List<int> playerIds) {
    final sortedIds = List<int>.from(playerIds)..sort();
    return sortedIds.join('-');
  }

  /// 2-man 조합 키 생성
  List<String> generate2ManCombinations(List<int> playerIds) {
    final combinations = <String>[];
    for (int i = 0; i < playerIds.length; i++) {
      for (int j = i + 1; j < playerIds.length; j++) {
        final pair = [playerIds[i], playerIds[j]]..sort();
        combinations.add('${pair[0]}-${pair[1]}');
      }
    }
    return combinations;
  }

  /// 3-man 조합 키 생성
  List<String> generate3ManCombinations(List<int> playerIds) {
    final combinations = <String>[];
    for (int i = 0; i < playerIds.length; i++) {
      for (int j = i + 1; j < playerIds.length; j++) {
        for (int k = j + 1; k < playerIds.length; k++) {
          final trio = [playerIds[i], playerIds[j], playerIds[k]]..sort();
          combinations.add('${trio[0]}-${trio[1]}-${trio[2]}');
        }
      }
    }
    return combinations;
  }

  // ═══════════════════════════════════════════════════════════════
  // 라인업 트래킹
  // ═══════════════════════════════════════════════════════════════

  /// PlayByPlay 이벤트들로부터 라인업 통계 계산
  LineupAnalysisResult analyzeLineups({
    required List<LocalPlayByPlay> events,
    required int teamId,
    required Map<int, List<int>> quarterStartingLineups,
  }) {
    final lineupStats = <String, LineupStats>{};
    final twoManStats = <String, CombinationStats>{};
    final threeManStats = <String, CombinationStats>{};

    // 쿼터별 현재 라인업 추적
    List<int> currentLineup = [];
    int lastClockSeconds = 0;
    int currentQuarter = 1;

    // 이벤트를 시간순으로 정렬
    final sortedEvents = List<LocalPlayByPlay>.from(events)
      ..sort((a, b) {
        final quarterCompare = a.quarter.compareTo(b.quarter);
        if (quarterCompare != 0) return quarterCompare;
        // 시간은 역순 (남은 시간이므로 큰 숫자가 먼저)
        return b.gameClockSeconds.compareTo(a.gameClockSeconds);
      });

    for (final event in sortedEvents) {
      // 쿼터 변경 감지
      if (event.quarter != currentQuarter) {
        // 이전 쿼터 마감 처리
        if (currentLineup.length == 5) {
          _updateLineupTime(
            lineupStats,
            twoManStats,
            threeManStats,
            currentLineup,
            lastClockSeconds,
          );
        }

        // 새 쿼터 시작
        currentQuarter = event.quarter;
        currentLineup = quarterStartingLineups[currentQuarter] ?? [];
        lastClockSeconds = event.gameClockSeconds;

        if (currentLineup.length == 5) {
          _ensureLineupEntry(
            lineupStats,
            twoManStats,
            threeManStats,
            currentLineup,
          );
        }
        continue;
      }

      // 교체 이벤트 처리
      if (event.actionType == 'substitution' &&
          event.tournamentTeamId == teamId) {
        // 교체 전 시간 업데이트
        if (currentLineup.length == 5 && lastClockSeconds > 0) {
          final timeElapsed = lastClockSeconds - event.gameClockSeconds;
          if (timeElapsed > 0) {
            _addLineupTime(
              lineupStats,
              twoManStats,
              threeManStats,
              currentLineup,
              timeElapsed,
            );
          }
        }

        // 라인업 변경
        final subOut = event.subOutPlayerId;
        final subIn = event.subInPlayerId;

        if (subOut != null && currentLineup.contains(subOut)) {
          currentLineup.remove(subOut);
        }
        if (subIn != null && !currentLineup.contains(subIn)) {
          currentLineup.add(subIn);
        }

        lastClockSeconds = event.gameClockSeconds;

        if (currentLineup.length == 5) {
          _ensureLineupEntry(
            lineupStats,
            twoManStats,
            threeManStats,
            currentLineup,
          );
        }
        continue;
      }

      // 득점 이벤트 처리
      if (event.actionType == 'shot' &&
          event.actionSubtype != null &&
          event.isMade == true &&
          currentLineup.length == 5) {
        final lineupKey = generateLineupKey(currentLineup);
        final stats = lineupStats[lineupKey];
        if (stats != null) {
          final points = event.pointsScored;

          if (event.tournamentTeamId == teamId) {
            // 우리 팀 득점
            stats.pointsScored += points;
            stats.plusMinus += points;
          } else {
            // 상대 팀 득점
            stats.pointsAllowed += points;
            stats.plusMinus -= points;
          }
        }

        // 조합별 업데이트
        _updateCombinationPoints(
          twoManStats,
          threeManStats,
          currentLineup,
          event.pointsScored,
          event.tournamentTeamId == teamId,
        );
      }
    }

    // 마지막 라인업 시간 마감
    if (currentLineup.length == 5 && lastClockSeconds > 0) {
      _addLineupTime(
        lineupStats,
        twoManStats,
        threeManStats,
        currentLineup,
        lastClockSeconds,
      );
    }

    // 결과 계산
    return LineupAnalysisResult(
      lineupStats: Map.unmodifiable(lineupStats),
      twoManStats: Map.unmodifiable(twoManStats),
      threeManStats: Map.unmodifiable(threeManStats),
      bestLineups: _getBestLineups(lineupStats.values.toList()),
      worstLineups: _getWorstLineups(lineupStats.values.toList()),
      mostUsedLineups: _getMostUsedLineups(lineupStats.values.toList()),
    );
  }

  void _ensureLineupEntry(
    Map<String, LineupStats> lineupStats,
    Map<String, CombinationStats> twoManStats,
    Map<String, CombinationStats> threeManStats,
    List<int> lineup,
  ) {
    final lineupKey = generateLineupKey(lineup);
    lineupStats.putIfAbsent(
      lineupKey,
      () => LineupStats(playerIds: List.from(lineup)),
    );

    // 2-man 조합
    for (final key in generate2ManCombinations(lineup)) {
      twoManStats.putIfAbsent(
        key,
        () => CombinationStats(
          playerIds: key.split('-').map(int.parse).toList(),
        ),
      );
    }

    // 3-man 조합
    for (final key in generate3ManCombinations(lineup)) {
      threeManStats.putIfAbsent(
        key,
        () => CombinationStats(
          playerIds: key.split('-').map(int.parse).toList(),
        ),
      );
    }
  }

  void _addLineupTime(
    Map<String, LineupStats> lineupStats,
    Map<String, CombinationStats> twoManStats,
    Map<String, CombinationStats> threeManStats,
    List<int> lineup,
    int seconds,
  ) {
    final lineupKey = generateLineupKey(lineup);
    final stats = lineupStats[lineupKey];
    if (stats != null) {
      stats.secondsPlayed += seconds;
    }

    // 2-man 조합 시간 업데이트
    for (final key in generate2ManCombinations(lineup)) {
      final combStats = twoManStats[key];
      if (combStats != null) {
        combStats.secondsPlayed += seconds;
      }
    }

    // 3-man 조합 시간 업데이트
    for (final key in generate3ManCombinations(lineup)) {
      final combStats = threeManStats[key];
      if (combStats != null) {
        combStats.secondsPlayed += seconds;
      }
    }
  }

  void _updateLineupTime(
    Map<String, LineupStats> lineupStats,
    Map<String, CombinationStats> twoManStats,
    Map<String, CombinationStats> threeManStats,
    List<int> lineup,
    int remainingSeconds,
  ) {
    // 쿼터 끝 (0초까지)
    _addLineupTime(
      lineupStats,
      twoManStats,
      threeManStats,
      lineup,
      remainingSeconds,
    );
  }

  void _updateCombinationPoints(
    Map<String, CombinationStats> twoManStats,
    Map<String, CombinationStats> threeManStats,
    List<int> lineup,
    int points,
    bool isOurScore,
  ) {
    // 2-man 조합 업데이트
    for (final key in generate2ManCombinations(lineup)) {
      final stats = twoManStats[key];
      if (stats != null) {
        if (isOurScore) {
          stats.pointsScored += points;
          stats.plusMinus += points;
        } else {
          stats.pointsAllowed += points;
          stats.plusMinus -= points;
        }
      }
    }

    // 3-man 조합 업데이트
    for (final key in generate3ManCombinations(lineup)) {
      final stats = threeManStats[key];
      if (stats != null) {
        if (isOurScore) {
          stats.pointsScored += points;
          stats.plusMinus += points;
        } else {
          stats.pointsAllowed += points;
          stats.plusMinus -= points;
        }
      }
    }
  }

  List<LineupStats> _getBestLineups(List<LineupStats> lineups) {
    // 최소 2분 이상 플레이한 라인업만
    final filtered = lineups.where((l) => l.secondsPlayed >= 120).toList();
    filtered.sort((a, b) => b.plusMinus.compareTo(a.plusMinus));
    return filtered.take(5).toList();
  }

  List<LineupStats> _getWorstLineups(List<LineupStats> lineups) {
    // 최소 2분 이상 플레이한 라인업만
    final filtered = lineups.where((l) => l.secondsPlayed >= 120).toList();
    filtered.sort((a, b) => a.plusMinus.compareTo(b.plusMinus));
    return filtered.take(5).toList();
  }

  List<LineupStats> _getMostUsedLineups(List<LineupStats> lineups) {
    final sorted = List<LineupStats>.from(lineups)
      ..sort((a, b) => b.secondsPlayed.compareTo(a.secondsPlayed));
    return sorted.take(5).toList();
  }
}

/// 5-man 라인업
class Lineup {
  final List<int> playerIds;

  Lineup({required List<int> playerIds})
      : assert(playerIds.length == 5),
        playerIds = List.unmodifiable(playerIds..sort());

  String get key => playerIds.join('-');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lineup &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;
}

/// 라인업 통계
class LineupStats {
  final List<int> playerIds;
  int secondsPlayed;
  int pointsScored;
  int pointsAllowed;
  int plusMinus;

  LineupStats({
    required this.playerIds,
    this.secondsPlayed = 0,
    this.pointsScored = 0,
    this.pointsAllowed = 0,
    this.plusMinus = 0,
  });

  String get key => playerIds.join('-');

  /// 플레이 시간 (분)
  double get minutesPlayed => secondsPlayed / 60;

  /// 100 포제션당 득점 (추정)
  double get offensiveRating {
    if (secondsPlayed == 0) return 0;
    // 대략 1분당 2포제션 가정
    final possessions = (secondsPlayed / 60) * 2;
    if (possessions == 0) return 0;
    return (pointsScored / possessions) * 100;
  }

  /// 100 포제션당 실점 (추정)
  double get defensiveRating {
    if (secondsPlayed == 0) return 0;
    final possessions = (secondsPlayed / 60) * 2;
    if (possessions == 0) return 0;
    return (pointsAllowed / possessions) * 100;
  }

  /// 넷 레이팅 (공격 - 수비)
  double get netRating => offensiveRating - defensiveRating;

  /// 분당 +/-
  double get plusMinusPerMinute {
    if (secondsPlayed == 0) return 0;
    return plusMinus / minutesPlayed;
  }

  Map<String, dynamic> toJson() => {
        'playerIds': playerIds,
        'secondsPlayed': secondsPlayed,
        'minutesPlayed': minutesPlayed.toStringAsFixed(1),
        'pointsScored': pointsScored,
        'pointsAllowed': pointsAllowed,
        'plusMinus': plusMinus,
        'offRtg': offensiveRating.toStringAsFixed(1),
        'defRtg': defensiveRating.toStringAsFixed(1),
        'netRtg': netRating.toStringAsFixed(1),
      };
}

/// 2-man, 3-man 조합 통계
class CombinationStats {
  final List<int> playerIds;
  int secondsPlayed;
  int pointsScored;
  int pointsAllowed;
  int plusMinus;

  CombinationStats({
    required this.playerIds,
    this.secondsPlayed = 0,
    this.pointsScored = 0,
    this.pointsAllowed = 0,
    this.plusMinus = 0,
  });

  String get key => playerIds.join('-');

  double get minutesPlayed => secondsPlayed / 60;

  double get plusMinusPerMinute {
    if (secondsPlayed == 0) return 0;
    return plusMinus / minutesPlayed;
  }

  Map<String, dynamic> toJson() => {
        'playerIds': playerIds,
        'secondsPlayed': secondsPlayed,
        'minutesPlayed': minutesPlayed.toStringAsFixed(1),
        'plusMinus': plusMinus,
      };
}

/// 라인업 분석 결과
class LineupAnalysisResult {
  final Map<String, LineupStats> lineupStats;
  final Map<String, CombinationStats> twoManStats;
  final Map<String, CombinationStats> threeManStats;
  final List<LineupStats> bestLineups;
  final List<LineupStats> worstLineups;
  final List<LineupStats> mostUsedLineups;

  const LineupAnalysisResult({
    required this.lineupStats,
    required this.twoManStats,
    required this.threeManStats,
    required this.bestLineups,
    required this.worstLineups,
    required this.mostUsedLineups,
  });

  /// 특정 라인업 통계 조회
  LineupStats? getLineupStats(List<int> playerIds) {
    final key = (List<int>.from(playerIds)..sort()).join('-');
    return lineupStats[key];
  }

  /// 특정 2-man 조합 통계 조회
  CombinationStats? get2ManStats(int player1, int player2) {
    final pair = [player1, player2]..sort();
    return twoManStats['${pair[0]}-${pair[1]}'];
  }

  /// 특정 3-man 조합 통계 조회
  CombinationStats? get3ManStats(int player1, int player2, int player3) {
    final trio = [player1, player2, player3]..sort();
    return threeManStats['${trio[0]}-${trio[1]}-${trio[2]}'];
  }

  /// 베스트 2-man 조합 (최소 2분 이상)
  List<CombinationStats> getBest2ManCombinations({int limit = 5}) {
    final filtered = twoManStats.values
        .where((s) => s.secondsPlayed >= 120)
        .toList()
      ..sort((a, b) => b.plusMinus.compareTo(a.plusMinus));
    return filtered.take(limit).toList();
  }

  /// 베스트 3-man 조합 (최소 2분 이상)
  List<CombinationStats> getBest3ManCombinations({int limit = 5}) {
    final filtered = threeManStats.values
        .where((s) => s.secondsPlayed >= 120)
        .toList()
      ..sort((a, b) => b.plusMinus.compareTo(a.plusMinus));
    return filtered.take(limit).toList();
  }

  Map<String, dynamic> toJson() => {
        'totalLineups': lineupStats.length,
        'bestLineups': bestLineups.map((l) => l.toJson()).toList(),
        'worstLineups': worstLineups.map((l) => l.toJson()).toList(),
        'mostUsedLineups': mostUsedLineups.map((l) => l.toJson()).toList(),
        'best2ManCombos':
            getBest2ManCombinations().map((c) => c.toJson()).toList(),
        'best3ManCombos':
            getBest3ManCombinations().map((c) => c.toJson()).toList(),
      };
}
