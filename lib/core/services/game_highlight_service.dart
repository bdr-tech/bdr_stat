// TODO(phase2): This service is not yet integrated.
// Planned for Phase 2 release. Do not call from production code.
// Used by: llm_summary_service.dart (also phase2). No screen integration exists.

import 'dart:convert';
import 'dart:math';

import '../../data/database/database.dart';

/// 경기 하이라이트 요약 서비스
///
/// 기능:
/// - PlayByPlay 데이터 분석
/// - 핵심 모멘트 추출 (득점 런, 클러치 타임, 개인 기록)
/// - LLM 프롬프트 생성
/// - 소셜 공유용 요약 텍스트 생성
///
// TODO(phase2): Service logic is complete but no screen calls this directly.
// TODO(phase2): Integrate with game_end screen or a dedicated highlights screen.
class GameHighlightService {
  GameHighlightService._();

  static final GameHighlightService instance = GameHighlightService._();

  // ═══════════════════════════════════════════════════════════════
  // 핵심 모멘트 추출
  // ═══════════════════════════════════════════════════════════════

  /// 경기 데이터에서 핵심 모멘트 추출
  GameHighlights extractHighlights({
    required LocalMatche match,
    required List<LocalPlayByPlay> events,
    required List<LocalPlayerStat> playerStats,
    required Map<int, String> playerNames,
  }) {
    // 득점 런 분석
    final scoringRuns = _extractScoringRuns(events, match);

    // 클러치 타임 분석 (4쿼터 마지막 2분 + 점수차 5점 이내)
    final clutchPlays = _extractClutchPlays(events, match);

    // 개인 기록 하이라이트
    final personalHighlights =
        _extractPersonalHighlights(playerStats, playerNames);

    // 리드 변경 횟수
    final leadChanges = _countLeadChanges(events);

    // 최대 점수차
    final maxLead = _findMaxLead(events, match);

    // 쿼터별 점수
    final quarterScores = _parseQuarterScores(match.quarterScoresJson);

    return GameHighlights(
      matchId: match.id,
      homeTeamName: match.homeTeamName,
      awayTeamName: match.awayTeamName,
      finalScore: GameScore(
        home: match.homeScore,
        away: match.awayScore,
      ),
      quarterScores: quarterScores,
      scoringRuns: scoringRuns,
      clutchPlays: clutchPlays,
      personalHighlights: personalHighlights,
      leadChanges: leadChanges,
      maxLead: maxLead,
      totalPlays: events.length,
    );
  }

  /// 득점 런 추출 (연속 N점 이상)
  List<ScoringRun> _extractScoringRuns(
    List<LocalPlayByPlay> events,
    LocalMatche match, {
    int minPoints = 8,
  }) {
    final runs = <ScoringRun>[];
    final shots = events
        .where((e) => e.actionType == 'shot' && e.isMade == true)
        .toList()
      ..sort((a, b) {
        final qCompare = a.quarter.compareTo(b.quarter);
        if (qCompare != 0) return qCompare;
        return b.gameClockSeconds.compareTo(a.gameClockSeconds);
      });

    if (shots.isEmpty) return runs;

    int currentTeamId = shots.first.tournamentTeamId;
    int runPoints = shots.first.pointsScored;
    int runStartQuarter = shots.first.quarter;
    int runStartClock = shots.first.gameClockSeconds;
    int runEndQuarter = shots.first.quarter;
    int runEndClock = shots.first.gameClockSeconds;

    for (int i = 1; i < shots.length; i++) {
      final shot = shots[i];

      if (shot.tournamentTeamId == currentTeamId) {
        // 같은 팀 연속 득점
        runPoints += shot.pointsScored;
        runEndQuarter = shot.quarter;
        runEndClock = shot.gameClockSeconds;
      } else {
        // 팀 변경 - 이전 런 저장
        if (runPoints >= minPoints) {
          runs.add(ScoringRun(
            teamId: currentTeamId,
            teamName: currentTeamId == match.homeTeamId
                ? match.homeTeamName
                : match.awayTeamName,
            points: runPoints,
            opponentPoints: 0,
            startQuarter: runStartQuarter,
            startClockSeconds: runStartClock,
            endQuarter: runEndQuarter,
            endClockSeconds: runEndClock,
          ));
        }

        // 새 런 시작
        currentTeamId = shot.tournamentTeamId;
        runPoints = shot.pointsScored;
        runStartQuarter = shot.quarter;
        runStartClock = shot.gameClockSeconds;
        runEndQuarter = shot.quarter;
        runEndClock = shot.gameClockSeconds;
      }
    }

    // 마지막 런 저장
    if (runPoints >= minPoints) {
      runs.add(ScoringRun(
        teamId: currentTeamId,
        teamName: currentTeamId == match.homeTeamId
            ? match.homeTeamName
            : match.awayTeamName,
        points: runPoints,
        opponentPoints: 0,
        startQuarter: runStartQuarter,
        startClockSeconds: runStartClock,
        endQuarter: runEndQuarter,
        endClockSeconds: runEndClock,
      ));
    }

    // 점수 높은 순 정렬
    runs.sort((a, b) => b.points.compareTo(a.points));

    return runs.take(5).toList();
  }

  /// 클러치 플레이 추출 (4쿼터 마지막 2분, 점수차 5점 이내)
  List<ClutchPlay> _extractClutchPlays(
    List<LocalPlayByPlay> events,
    LocalMatche match,
  ) {
    final clutchPlays = <ClutchPlay>[];

    // 4쿼터 마지막 2분 (120초)
    final clutchEvents = events.where((e) {
      if (e.quarter < 4) return false;
      if (e.quarter == 4 && e.gameClockSeconds > 120) return false;

      // 점수차 확인
      final scoreDiff = (e.homeScoreAtTime - e.awayScoreAtTime).abs();
      return scoreDiff <= 5;
    }).toList();

    for (final event in clutchEvents) {
      if (event.actionType == 'shot' && event.isMade == true) {
        final isHome = event.tournamentTeamId == match.homeTeamId;
        clutchPlays.add(ClutchPlay(
          playerId: event.tournamentTeamPlayerId,
          teamId: event.tournamentTeamId,
          teamName: isHome ? match.homeTeamName : match.awayTeamName,
          playType: ClutchPlayType.clutchScore,
          points: event.pointsScored,
          quarter: event.quarter,
          clockSeconds: event.gameClockSeconds,
          scoreBefore: GameScore(
            home: event.homeScoreAtTime - (isHome ? event.pointsScored : 0),
            away: event.awayScoreAtTime - (isHome ? 0 : event.pointsScored),
          ),
          scoreAfter: GameScore(
            home: event.homeScoreAtTime,
            away: event.awayScoreAtTime,
          ),
        ));
      } else if (event.actionType == 'steal') {
        clutchPlays.add(ClutchPlay(
          playerId: event.tournamentTeamPlayerId,
          teamId: event.tournamentTeamId,
          teamName: event.tournamentTeamId == match.homeTeamId
              ? match.homeTeamName
              : match.awayTeamName,
          playType: ClutchPlayType.clutchSteal,
          points: 0,
          quarter: event.quarter,
          clockSeconds: event.gameClockSeconds,
          scoreBefore: GameScore(
            home: event.homeScoreAtTime,
            away: event.awayScoreAtTime,
          ),
          scoreAfter: GameScore(
            home: event.homeScoreAtTime,
            away: event.awayScoreAtTime,
          ),
        ));
      } else if (event.actionType == 'block') {
        clutchPlays.add(ClutchPlay(
          playerId: event.tournamentTeamPlayerId,
          teamId: event.tournamentTeamId,
          teamName: event.tournamentTeamId == match.homeTeamId
              ? match.homeTeamName
              : match.awayTeamName,
          playType: ClutchPlayType.clutchBlock,
          points: 0,
          quarter: event.quarter,
          clockSeconds: event.gameClockSeconds,
          scoreBefore: GameScore(
            home: event.homeScoreAtTime,
            away: event.awayScoreAtTime,
          ),
          scoreAfter: GameScore(
            home: event.homeScoreAtTime,
            away: event.awayScoreAtTime,
          ),
        ));
      }
    }

    return clutchPlays;
  }

  /// 개인 기록 하이라이트 추출
  List<PersonalHighlight> _extractPersonalHighlights(
    List<LocalPlayerStat> stats,
    Map<int, String> playerNames,
  ) {
    final highlights = <PersonalHighlight>[];

    for (final stat in stats) {
      final playerName =
          playerNames[stat.tournamentTeamPlayerId] ?? '선수 ${stat.tournamentTeamPlayerId}';
      final rebounds = stat.offensiveRebounds + stat.defensiveRebounds;

      // 더블더블 체크
      int doubleDigitCount = 0;
      final categories = <String>[];

      if (stat.points >= 10) {
        doubleDigitCount++;
        categories.add('득점');
      }
      if (rebounds >= 10) {
        doubleDigitCount++;
        categories.add('리바운드');
      }
      if (stat.assists >= 10) {
        doubleDigitCount++;
        categories.add('어시스트');
      }
      if (stat.steals >= 10) {
        doubleDigitCount++;
        categories.add('스틸');
      }
      if (stat.blocks >= 10) {
        doubleDigitCount++;
        categories.add('블락');
      }

      if (doubleDigitCount >= 3) {
        highlights.add(PersonalHighlight(
          playerId: stat.tournamentTeamPlayerId,
          playerName: playerName,
          type: PersonalHighlightType.tripleDouble,
          stats: {
            'points': stat.points,
            'rebounds': rebounds,
            'assists': stat.assists,
            'steals': stat.steals,
            'blocks': stat.blocks,
          },
          categories: categories,
          description:
              '$playerName ${stat.points}득점 $rebounds리바운드 ${stat.assists}어시스트 트리플더블!',
        ));
      } else if (doubleDigitCount >= 2) {
        highlights.add(PersonalHighlight(
          playerId: stat.tournamentTeamPlayerId,
          playerName: playerName,
          type: PersonalHighlightType.doubleDouble,
          stats: {
            'points': stat.points,
            'rebounds': rebounds,
            'assists': stat.assists,
          },
          categories: categories,
          description:
              '$playerName ${stat.points}득점 $rebounds리바운드 더블더블',
        ));
      }

      // 고득점 (25점 이상)
      if (stat.points >= 25 && doubleDigitCount < 2) {
        highlights.add(PersonalHighlight(
          playerId: stat.tournamentTeamPlayerId,
          playerName: playerName,
          type: PersonalHighlightType.highScorer,
          stats: {'points': stat.points},
          categories: ['득점'],
          description: '$playerName ${stat.points}득점 대활약',
        ));
      }

      // 슈팅 효율 (10시도 이상, 70% 이상)
      if (stat.fieldGoalsAttempted >= 10) {
        final fgPct = stat.fieldGoalsMade / stat.fieldGoalsAttempted;
        if (fgPct >= 0.7) {
          highlights.add(PersonalHighlight(
            playerId: stat.tournamentTeamPlayerId,
            playerName: playerName,
            type: PersonalHighlightType.efficientScoring,
            stats: {
              'fgMade': stat.fieldGoalsMade,
              'fgAttempted': stat.fieldGoalsAttempted,
              'fgPct': fgPct,
            },
            categories: ['슈팅 효율'],
            description:
                '$playerName ${stat.fieldGoalsMade}/${stat.fieldGoalsAttempted} (${(fgPct * 100).toStringAsFixed(1)}%) 고효율 슈팅',
          ));
        }
      }
    }

    return highlights;
  }

  /// 리드 변경 횟수 계산
  int _countLeadChanges(List<LocalPlayByPlay> events) {
    int leadChanges = 0;
    int? previousLeader; // null: 동점, 1: 홈, -1: 어웨이

    final shots = events
        .where((e) => e.actionType == 'shot' && e.isMade == true)
        .toList()
      ..sort((a, b) {
        final qCompare = a.quarter.compareTo(b.quarter);
        if (qCompare != 0) return qCompare;
        return b.gameClockSeconds.compareTo(a.gameClockSeconds);
      });

    for (final shot in shots) {
      final diff = shot.homeScoreAtTime - shot.awayScoreAtTime;
      int? currentLeader;

      if (diff > 0) {
        currentLeader = 1;
      } else if (diff < 0) {
        currentLeader = -1;
      } else {
        currentLeader = null;
      }

      if (previousLeader != null &&
          currentLeader != null &&
          previousLeader != currentLeader) {
        leadChanges++;
      }

      previousLeader = currentLeader;
    }

    return leadChanges;
  }

  /// 최대 점수차 찾기
  MaxLead _findMaxLead(List<LocalPlayByPlay> events, LocalMatche match) {
    int maxHomeLead = 0;
    int maxAwayLead = 0;
    int maxHomeLeadQuarter = 1;
    int maxAwayLeadQuarter = 1;

    for (final event in events) {
      final diff = event.homeScoreAtTime - event.awayScoreAtTime;

      if (diff > maxHomeLead) {
        maxHomeLead = diff;
        maxHomeLeadQuarter = event.quarter;
      }
      if (-diff > maxAwayLead) {
        maxAwayLead = -diff;
        maxAwayLeadQuarter = event.quarter;
      }
    }

    if (maxHomeLead >= maxAwayLead) {
      return MaxLead(
        teamName: match.homeTeamName,
        points: maxHomeLead,
        quarter: maxHomeLeadQuarter,
      );
    } else {
      return MaxLead(
        teamName: match.awayTeamName,
        points: maxAwayLead,
        quarter: maxAwayLeadQuarter,
      );
    }
  }

  /// 쿼터 점수 파싱
  Map<int, QuarterScore> _parseQuarterScores(String json) {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final result = <int, QuarterScore>{};

      for (int q = 1; q <= 4; q++) {
        final qKey = 'Q$q';
        if (data.containsKey(qKey)) {
          final qData = data[qKey] as Map<String, dynamic>;
          result[q] = QuarterScore(
            quarter: q,
            homeScore: qData['home'] as int? ?? 0,
            awayScore: qData['away'] as int? ?? 0,
          );
        }
      }

      // 연장전
      int otNum = 1;
      while (data.containsKey('OT$otNum')) {
        final otData = data['OT$otNum'] as Map<String, dynamic>;
        result[4 + otNum] = QuarterScore(
          quarter: 4 + otNum,
          homeScore: otData['home'] as int? ?? 0,
          awayScore: otData['away'] as int? ?? 0,
        );
        otNum++;
      }

      return result;
    } catch (e) {
      return {};
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // LLM 프롬프트 생성
  // ═══════════════════════════════════════════════════════════════

  /// LLM용 경기 요약 프롬프트 생성
  String generateSummaryPrompt(GameHighlights highlights) {
    final buffer = StringBuffer();

    buffer.writeln('다음 농구 경기 데이터를 바탕으로 한국어로 2-3문장의 경기 요약을 작성해주세요.');
    buffer.writeln('핵심 플레이어와 중요한 순간을 포함해주세요.');
    buffer.writeln();
    buffer.writeln('--- 경기 정보 ---');
    buffer.writeln(
        '${highlights.homeTeamName} vs ${highlights.awayTeamName}');
    buffer.writeln(
        '최종 점수: ${highlights.finalScore.home} : ${highlights.finalScore.away}');
    buffer.writeln(
        '승자: ${highlights.finalScore.home > highlights.finalScore.away ? highlights.homeTeamName : highlights.awayTeamName}');
    buffer.writeln();

    // 쿼터별 점수
    if (highlights.quarterScores.isNotEmpty) {
      buffer.writeln('--- 쿼터별 점수 ---');
      for (final entry in highlights.quarterScores.entries) {
        final q = entry.key;
        final score = entry.value;
        final label = q <= 4 ? 'Q$q' : 'OT${q - 4}';
        buffer.writeln('$label: ${score.homeScore} - ${score.awayScore}');
      }
      buffer.writeln();
    }

    // 득점 런
    if (highlights.scoringRuns.isNotEmpty) {
      buffer.writeln('--- 주요 득점 런 ---');
      for (final run in highlights.scoringRuns.take(3)) {
        buffer.writeln(
            '- ${run.teamName}: ${run.points}-0 런 (Q${run.startQuarter})');
      }
      buffer.writeln();
    }

    // 클러치 플레이
    if (highlights.clutchPlays.isNotEmpty) {
      buffer.writeln('--- 클러치 플레이 (4쿼터 마지막 2분) ---');
      buffer.writeln('클러치 득점: ${highlights.clutchPlays.where((p) => p.playType == ClutchPlayType.clutchScore).length}개');
      buffer.writeln();
    }

    // 개인 기록
    if (highlights.personalHighlights.isNotEmpty) {
      buffer.writeln('--- 개인 하이라이트 ---');
      for (final h in highlights.personalHighlights) {
        buffer.writeln('- ${h.description}');
      }
      buffer.writeln();
    }

    // 경기 흐름
    buffer.writeln('--- 경기 흐름 ---');
    buffer.writeln('리드 변경: ${highlights.leadChanges}회');
    buffer.writeln(
        '최대 리드: ${highlights.maxLead.teamName} +${highlights.maxLead.points}점 (Q${highlights.maxLead.quarter})');

    return buffer.toString();
  }

  /// 짧은 한 줄 요약 생성 (LLM 없이)
  String generateQuickSummary(GameHighlights highlights) {
    final winner = highlights.finalScore.home > highlights.finalScore.away
        ? highlights.homeTeamName
        : highlights.awayTeamName;
    final loser = highlights.finalScore.home > highlights.finalScore.away
        ? highlights.awayTeamName
        : highlights.homeTeamName;
    final winScore = max(highlights.finalScore.home, highlights.finalScore.away);
    final loseScore = min(highlights.finalScore.home, highlights.finalScore.away);
    final diff = winScore - loseScore;

    final buffer = StringBuffer();
    buffer.write('$winner이(가) $loser을(를) $winScore-$loseScore으로 ');

    if (diff >= 20) {
      buffer.write('대파.');
    } else if (diff >= 10) {
      buffer.write('완승.');
    } else if (diff <= 3) {
      buffer.write('접전 끝에 승리.');
    } else {
      buffer.write('제압.');
    }

    // 개인 하이라이트 추가
    if (highlights.personalHighlights.isNotEmpty) {
      final top = highlights.personalHighlights.first;
      buffer.write(' ${top.playerName}');
      if (top.type == PersonalHighlightType.tripleDouble) {
        buffer.write(' 트리플더블.');
      } else if (top.type == PersonalHighlightType.doubleDouble) {
        buffer.write(' 더블더블.');
      } else if (top.stats.containsKey('points')) {
        buffer.write(' ${top.stats['points']}득점.');
      }
    }

    // 주요 런 추가
    if (highlights.scoringRuns.isNotEmpty) {
      final topRun = highlights.scoringRuns.first;
      if (topRun.points >= 10) {
        buffer.write(' ${topRun.teamName} ${topRun.points}-0 런.');
      }
    }

    return buffer.toString();
  }

  // ═══════════════════════════════════════════════════════════════
  // 소셜 공유 카드
  // ═══════════════════════════════════════════════════════════════

  /// 소셜 공유 카드 데이터 생성
  SocialShareCard generateShareCard(
    GameHighlights highlights, {
    String? aiSummary,
  }) {
    return SocialShareCard(
      homeTeamName: highlights.homeTeamName,
      awayTeamName: highlights.awayTeamName,
      homeScore: highlights.finalScore.home,
      awayScore: highlights.finalScore.away,
      summary: aiSummary ?? generateQuickSummary(highlights),
      topPerformer: highlights.personalHighlights.isNotEmpty
          ? highlights.personalHighlights.first
          : null,
      biggestRun: highlights.scoringRuns.isNotEmpty
          ? highlights.scoringRuns.first
          : null,
      leadChanges: highlights.leadChanges,
    );
  }

  /// 트위터/X용 텍스트 생성
  String generateTwitterText(SocialShareCard card) {
    final buffer = StringBuffer();
    buffer.writeln('🏀 경기 결과');
    buffer.writeln('${card.homeTeamName} ${card.homeScore} - ${card.awayScore} ${card.awayTeamName}');
    buffer.writeln();
    buffer.writeln(card.summary);
    buffer.writeln();
    buffer.writeln('#BDR #농구 #경기결과');
    return buffer.toString();
  }

  /// 인스타그램 스토리용 텍스트 생성
  String generateInstagramText(SocialShareCard card) {
    final buffer = StringBuffer();
    buffer.writeln('🏀 FINAL SCORE 🏀');
    buffer.writeln();
    buffer.writeln(card.homeTeamName);
    buffer.writeln(card.homeScore);
    buffer.writeln();
    buffer.writeln('VS');
    buffer.writeln();
    buffer.writeln(card.awayTeamName);
    buffer.writeln(card.awayScore);
    buffer.writeln();
    if (card.topPerformer != null) {
      buffer.writeln('⭐ MVP: ${card.topPerformer!.playerName}');
      buffer.writeln(card.topPerformer!.description);
    }
    return buffer.toString();
  }
}

// ═══════════════════════════════════════════════════════════════
// 데이터 모델
// ═══════════════════════════════════════════════════════════════

/// 경기 하이라이트 데이터
class GameHighlights {
  final int matchId;
  final String homeTeamName;
  final String awayTeamName;
  final GameScore finalScore;
  final Map<int, QuarterScore> quarterScores;
  final List<ScoringRun> scoringRuns;
  final List<ClutchPlay> clutchPlays;
  final List<PersonalHighlight> personalHighlights;
  final int leadChanges;
  final MaxLead maxLead;
  final int totalPlays;

  const GameHighlights({
    required this.matchId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.finalScore,
    required this.quarterScores,
    required this.scoringRuns,
    required this.clutchPlays,
    required this.personalHighlights,
    required this.leadChanges,
    required this.maxLead,
    required this.totalPlays,
  });

  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'homeTeam': homeTeamName,
        'awayTeam': awayTeamName,
        'finalScore': finalScore.toJson(),
        'quarterScores':
            quarterScores.map((k, v) => MapEntry(k.toString(), v.toJson())),
        'scoringRuns': scoringRuns.map((r) => r.toJson()).toList(),
        'clutchPlays': clutchPlays.map((p) => p.toJson()).toList(),
        'personalHighlights': personalHighlights.map((h) => h.toJson()).toList(),
        'leadChanges': leadChanges,
        'maxLead': maxLead.toJson(),
      };
}

/// 경기 점수
class GameScore {
  final int home;
  final int away;

  const GameScore({required this.home, required this.away});

  Map<String, dynamic> toJson() => {'home': home, 'away': away};
}

/// 쿼터 점수
class QuarterScore {
  final int quarter;
  final int homeScore;
  final int awayScore;

  const QuarterScore({
    required this.quarter,
    required this.homeScore,
    required this.awayScore,
  });

  Map<String, dynamic> toJson() => {
        'quarter': quarter,
        'home': homeScore,
        'away': awayScore,
      };
}

/// 득점 런
class ScoringRun {
  final int teamId;
  final String teamName;
  final int points;
  final int opponentPoints;
  final int startQuarter;
  final int startClockSeconds;
  final int endQuarter;
  final int endClockSeconds;

  const ScoringRun({
    required this.teamId,
    required this.teamName,
    required this.points,
    required this.opponentPoints,
    required this.startQuarter,
    required this.startClockSeconds,
    required this.endQuarter,
    required this.endClockSeconds,
  });

  String get display => '$points-$opponentPoints';

  Map<String, dynamic> toJson() => {
        'teamName': teamName,
        'points': points,
        'opponentPoints': opponentPoints,
        'startQ': startQuarter,
        'endQ': endQuarter,
      };
}

/// 클러치 플레이 타입
enum ClutchPlayType {
  clutchScore, // 클러치 득점
  clutchSteal, // 클러치 스틸
  clutchBlock, // 클러치 블락
  clutchRebound, // 클러치 리바운드
}

/// 클러치 플레이
class ClutchPlay {
  final int playerId;
  final int teamId;
  final String teamName;
  final ClutchPlayType playType;
  final int points;
  final int quarter;
  final int clockSeconds;
  final GameScore scoreBefore;
  final GameScore scoreAfter;

  const ClutchPlay({
    required this.playerId,
    required this.teamId,
    required this.teamName,
    required this.playType,
    required this.points,
    required this.quarter,
    required this.clockSeconds,
    required this.scoreBefore,
    required this.scoreAfter,
  });

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'teamName': teamName,
        'type': playType.name,
        'points': points,
        'quarter': quarter,
        'clock': clockSeconds,
      };
}

/// 개인 하이라이트 타입
enum PersonalHighlightType {
  tripleDouble, // 트리플 더블
  doubleDouble, // 더블 더블
  highScorer, // 고득점
  efficientScoring, // 고효율 슈팅
  defensiveStar, // 수비 스타
}

/// 개인 하이라이트
class PersonalHighlight {
  final int playerId;
  final String playerName;
  final PersonalHighlightType type;
  final Map<String, dynamic> stats;
  final List<String> categories;
  final String description;

  const PersonalHighlight({
    required this.playerId,
    required this.playerName,
    required this.type,
    required this.stats,
    required this.categories,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'playerName': playerName,
        'type': type.name,
        'stats': stats,
        'categories': categories,
        'description': description,
      };
}

/// 최대 리드
class MaxLead {
  final String teamName;
  final int points;
  final int quarter;

  const MaxLead({
    required this.teamName,
    required this.points,
    required this.quarter,
  });

  Map<String, dynamic> toJson() => {
        'teamName': teamName,
        'points': points,
        'quarter': quarter,
      };
}

/// 소셜 공유 카드
class SocialShareCard {
  final String homeTeamName;
  final String awayTeamName;
  final int homeScore;
  final int awayScore;
  final String summary;
  final PersonalHighlight? topPerformer;
  final ScoringRun? biggestRun;
  final int leadChanges;

  const SocialShareCard({
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeScore,
    required this.awayScore,
    required this.summary,
    this.topPerformer,
    this.biggestRun,
    required this.leadChanges,
  });

  String get winner =>
      homeScore > awayScore ? homeTeamName : awayTeamName;

  String get scoreDisplay => '$homeScore - $awayScore';

  Map<String, dynamic> toJson() => {
        'homeTeam': homeTeamName,
        'awayTeam': awayTeamName,
        'homeScore': homeScore,
        'awayScore': awayScore,
        'summary': summary,
        'topPerformer': topPerformer?.toJson(),
        'biggestRun': biggestRun?.toJson(),
        'leadChanges': leadChanges,
      };
}
