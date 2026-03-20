// TODO(phase2): This service is not yet integrated.
// Planned for Phase 2 release. Do not call from production code.
// Calculation logic is complete, but no screen or provider calls calculateFromPlayerStat().

import 'dart:math';

import '../../data/database/database.dart';

/// 고급 통계 계산 서비스
///
/// 제공하는 지표:
/// - PER (Player Efficiency Rating): 선수 효율성 종합 지표
/// - TS% (True Shooting Percentage): 실질 슈팅 효율
/// - EFG% (Effective Field Goal %): 유효 야투율
/// - USG% (Usage Rate): 공격 점유율
/// - AST% (Assist Percentage): 어시스트율
/// - REB% (Rebound Percentage): 리바운드율
/// - PIE (Player Impact Estimate): 선수 임팩트 추정치
/// - Game Score: 단일 경기 퍼포먼스 점수
// TODO(phase2): Connect to box_score_screen or a dedicated advanced stats screen.
class AdvancedStatsCalculator {
  AdvancedStatsCalculator._();

  static final AdvancedStatsCalculator instance = AdvancedStatsCalculator._();

  // ═══════════════════════════════════════════════════════════════
  // 기본 효율성 지표
  // ═══════════════════════════════════════════════════════════════

  /// True Shooting Percentage (TS%)
  /// 실질 슈팅 효율 - 2점슛, 3점슛, 자유투를 모두 고려한 슈팅 효율
  ///
  /// 공식: Points / (2 * (FGA + 0.44 * FTA))
  double calculateTrueShootingPct({
    required int points,
    required int fieldGoalAttempts,
    required int freeThrowAttempts,
  }) {
    final denominator = 2 * (fieldGoalAttempts + 0.44 * freeThrowAttempts);
    if (denominator == 0) return 0.0;
    return points / denominator;
  }

  /// Effective Field Goal Percentage (EFG%)
  /// 유효 야투율 - 3점슛의 추가 가치를 반영
  ///
  /// 공식: (FGM + 0.5 * 3PM) / FGA
  double calculateEffectiveFieldGoalPct({
    required int fieldGoalsMade,
    required int threePointersMade,
    required int fieldGoalAttempts,
  }) {
    if (fieldGoalAttempts == 0) return 0.0;
    return (fieldGoalsMade + 0.5 * threePointersMade) / fieldGoalAttempts;
  }

  /// 야투율 (FG%)
  double calculateFieldGoalPct({
    required int fieldGoalsMade,
    required int fieldGoalAttempts,
  }) {
    if (fieldGoalAttempts == 0) return 0.0;
    return fieldGoalsMade / fieldGoalAttempts;
  }

  /// 3점슛 성공률 (3P%)
  double calculateThreePointPct({
    required int threePointersMade,
    required int threePointAttempts,
  }) {
    if (threePointAttempts == 0) return 0.0;
    return threePointersMade / threePointAttempts;
  }

  /// 자유투 성공률 (FT%)
  double calculateFreeThrowPct({
    required int freeThrowsMade,
    required int freeThrowAttempts,
  }) {
    if (freeThrowAttempts == 0) return 0.0;
    return freeThrowsMade / freeThrowAttempts;
  }

  // ═══════════════════════════════════════════════════════════════
  // 고급 효율성 지표
  // ═══════════════════════════════════════════════════════════════

  /// Player Efficiency Rating (PER) - 간소화 버전
  /// 한 경기 기준 선수 효율성 종합 지표
  ///
  /// 참고: NBA 공식 PER는 리그 평균 등 많은 팩터가 필요하므로
  /// 여기서는 단일 경기 기준 간소화된 버전 사용
  double calculateSimplePER({
    required int points,
    required int rebounds,
    required int assists,
    required int steals,
    required int blocks,
    required int turnovers,
    required int personalFouls,
    required int fieldGoalsMade,
    required int fieldGoalAttempts,
    required int freeThrowsMade,
    required int freeThrowAttempts,
    required int minutesPlayed,
  }) {
    if (minutesPlayed == 0) return 0.0;

    // 긍정적 기여
    final positive = points +
        rebounds * 1.2 +
        assists * 1.5 +
        steals * 2.0 +
        blocks * 2.0;

    // 부정적 기여
    final fieldGoalMisses = fieldGoalAttempts - fieldGoalsMade;
    final freeThrowMisses = freeThrowAttempts - freeThrowsMade;
    final negative =
        turnovers * 1.5 + fieldGoalMisses * 0.8 + freeThrowMisses * 0.5;

    // 시간당 효율성 (36분 기준 정규화)
    final efficiency = (positive - negative) * (36 / minutesPlayed);

    return efficiency;
  }

  /// Usage Rate (USG%)
  /// 팀 공격 점유율 - 선수가 코트에 있을 때 팀 공격의 몇 %를 사용했는지
  ///
  /// 공식: 100 * ((FGA + 0.44 * FTA + TOV) * (팀총시간 / 5)) / (분 * (팀FGA + 0.44 * 팀FTA + 팀TOV))
  double calculateUsageRate({
    required int fieldGoalAttempts,
    required int freeThrowAttempts,
    required int turnovers,
    required int minutesPlayed,
    required int teamFieldGoalAttempts,
    required int teamFreeThrowAttempts,
    required int teamTurnovers,
    required int teamMinutes,
  }) {
    if (minutesPlayed == 0 || teamMinutes == 0) return 0.0;

    final playerPossessions =
        fieldGoalAttempts + 0.44 * freeThrowAttempts + turnovers;
    final teamPossessions =
        teamFieldGoalAttempts + 0.44 * teamFreeThrowAttempts + teamTurnovers;

    if (teamPossessions == 0) return 0.0;

    return 100 *
        (playerPossessions * (teamMinutes / 5)) /
        (minutesPlayed * teamPossessions);
  }

  /// Assist Percentage (AST%)
  /// 어시스트율 - 선수가 코트에 있을 때 팀 필드골 중 어시스트한 비율
  ///
  /// 공식: 100 * AST / (((MIN / (팀MIN / 5)) * 팀FGM) - FGM)
  double calculateAssistPercentage({
    required int assists,
    required int minutesPlayed,
    required int fieldGoalsMade,
    required int teamFieldGoalsMade,
    required int teamMinutes,
  }) {
    if (minutesPlayed == 0 || teamMinutes == 0) return 0.0;

    final possibleAssists =
        ((minutesPlayed / (teamMinutes / 5)) * teamFieldGoalsMade) -
            fieldGoalsMade;

    if (possibleAssists <= 0) return 0.0;

    return min(100.0, 100 * assists / possibleAssists);
  }

  /// Rebound Percentage (REB%)
  /// 총 리바운드율 - 선수가 코트에 있을 때 가능한 리바운드 중 잡은 비율
  double calculateReboundPercentage({
    required int rebounds,
    required int minutesPlayed,
    required int teamRebounds,
    required int opponentRebounds,
    required int teamMinutes,
  }) {
    if (minutesPlayed == 0 || teamMinutes == 0) return 0.0;

    final totalRebounds = teamRebounds + opponentRebounds;
    if (totalRebounds == 0) return 0.0;

    final playerMinutesRatio = minutesPlayed / (teamMinutes / 5);

    return 100 * rebounds / (playerMinutesRatio * totalRebounds);
  }

  /// Offensive Rebound Percentage (OREB%)
  double calculateOffensiveReboundPct({
    required int offensiveRebounds,
    required int minutesPlayed,
    required int teamOffensiveRebounds,
    required int opponentDefensiveRebounds,
    required int teamMinutes,
  }) {
    if (minutesPlayed == 0 || teamMinutes == 0) return 0.0;

    final totalOReb = teamOffensiveRebounds + opponentDefensiveRebounds;
    if (totalOReb == 0) return 0.0;

    final playerMinutesRatio = minutesPlayed / (teamMinutes / 5);

    return 100 * offensiveRebounds / (playerMinutesRatio * totalOReb);
  }

  /// Defensive Rebound Percentage (DREB%)
  double calculateDefensiveReboundPct({
    required int defensiveRebounds,
    required int minutesPlayed,
    required int teamDefensiveRebounds,
    required int opponentOffensiveRebounds,
    required int teamMinutes,
  }) {
    if (minutesPlayed == 0 || teamMinutes == 0) return 0.0;

    final totalDReb = teamDefensiveRebounds + opponentOffensiveRebounds;
    if (totalDReb == 0) return 0.0;

    final playerMinutesRatio = minutesPlayed / (teamMinutes / 5);

    return 100 * defensiveRebounds / (playerMinutesRatio * totalDReb);
  }

  // ═══════════════════════════════════════════════════════════════
  // 종합 지표
  // ═══════════════════════════════════════════════════════════════

  /// Game Score
  /// 단일 경기 퍼포먼스 점수 (John Hollinger's formula)
  ///
  /// 공식: PTS + 0.4*FGM - 0.7*FGA - 0.4*(FTA-FTM) + 0.7*OREB + 0.3*DREB
  ///       + STL + 0.7*AST + 0.7*BLK - 0.4*PF - TOV
  double calculateGameScore({
    required int points,
    required int fieldGoalsMade,
    required int fieldGoalAttempts,
    required int freeThrowsMade,
    required int freeThrowAttempts,
    required int offensiveRebounds,
    required int defensiveRebounds,
    required int steals,
    required int assists,
    required int blocks,
    required int personalFouls,
    required int turnovers,
  }) {
    return points +
        0.4 * fieldGoalsMade -
        0.7 * fieldGoalAttempts -
        0.4 * (freeThrowAttempts - freeThrowsMade) +
        0.7 * offensiveRebounds +
        0.3 * defensiveRebounds +
        steals +
        0.7 * assists +
        0.7 * blocks -
        0.4 * personalFouls -
        turnovers;
  }

  /// Player Impact Estimate (PIE)
  /// NBA에서 사용하는 선수 임팩트 추정치
  ///
  /// 공식: (PTS + FGM + FTM - FGA - FTA + DREB + (.5 * OREB) + AST + STL
  ///       + (.5 * BLK) - PF - TOV) / GmPTS + GmFGM + GmFTM - GmFGA - GmFTA
  ///       + GmDREB + (.5 * GmOREB) + GmAST + GmSTL + (.5 * GmBLK) - GmPF - GmTOV
  double calculatePIE({
    // 선수 스탯
    required int points,
    required int fieldGoalsMade,
    required int fieldGoalAttempts,
    required int freeThrowsMade,
    required int freeThrowAttempts,
    required int offensiveRebounds,
    required int defensiveRebounds,
    required int assists,
    required int steals,
    required int blocks,
    required int personalFouls,
    required int turnovers,
    // 경기 전체 스탯 (양팀 합계)
    required int gamePoints,
    required int gameFieldGoalsMade,
    required int gameFieldGoalAttempts,
    required int gameFreeThrowsMade,
    required int gameFreeThrowAttempts,
    required int gameOffensiveRebounds,
    required int gameDefensiveRebounds,
    required int gameAssists,
    required int gameSteals,
    required int gameBlocks,
    required int gameFouls,
    required int gameTurnovers,
  }) {
    final playerContribution = points +
        fieldGoalsMade +
        freeThrowsMade -
        fieldGoalAttempts -
        freeThrowAttempts +
        defensiveRebounds +
        (0.5 * offensiveRebounds) +
        assists +
        steals +
        (0.5 * blocks) -
        personalFouls -
        turnovers;

    final gameTotal = gamePoints +
        gameFieldGoalsMade +
        gameFreeThrowsMade -
        gameFieldGoalAttempts -
        gameFreeThrowAttempts +
        gameDefensiveRebounds +
        (0.5 * gameOffensiveRebounds) +
        gameAssists +
        gameSteals +
        (0.5 * gameBlocks) -
        gameFouls -
        gameTurnovers;

    if (gameTotal == 0) return 0.0;

    return playerContribution / gameTotal;
  }

  // ═══════════════════════════════════════════════════════════════
  // 팀 통계
  // ═══════════════════════════════════════════════════════════════

  /// 팀 공격 효율 (Offensive Rating)
  /// 100 포제션당 득점
  double calculateOffensiveRating({
    required int points,
    required int possessions,
  }) {
    if (possessions == 0) return 0.0;
    return (points / possessions) * 100;
  }

  /// 팀 수비 효율 (Defensive Rating)
  /// 100 포제션당 실점
  double calculateDefensiveRating({
    required int opponentPoints,
    required int possessions,
  }) {
    if (possessions == 0) return 0.0;
    return (opponentPoints / possessions) * 100;
  }

  /// 포제션 추정
  /// 공식: FGA - OREB + TOV + 0.44 * FTA
  double estimatePossessions({
    required int fieldGoalAttempts,
    required int offensiveRebounds,
    required int turnovers,
    required int freeThrowAttempts,
  }) {
    return fieldGoalAttempts -
        offensiveRebounds +
        turnovers +
        0.44 * freeThrowAttempts;
  }

  /// 페이스 (Pace)
  /// 48분당 포제션 수
  double calculatePace({
    required double possessions,
    required int minutesPlayed,
  }) {
    if (minutesPlayed == 0) return 0.0;
    return possessions * 48 / minutesPlayed;
  }

  // ═══════════════════════════════════════════════════════════════
  // LocalPlayerStat에서 모든 통계 계산
  // ═══════════════════════════════════════════════════════════════

  /// 선수 통계에서 종합 고급 지표 계산
  AdvancedPlayerStats calculateFromPlayerStat(
    LocalPlayerStat stat, {
    TeamStats? teamStats,
    GameStats? gameStats,
  }) {
    // 기본 슈팅 효율
    final fgPct = calculateFieldGoalPct(
      fieldGoalsMade: stat.fieldGoalsMade,
      fieldGoalAttempts: stat.fieldGoalsAttempted,
    );

    final threePct = calculateThreePointPct(
      threePointersMade: stat.threePointersMade,
      threePointAttempts: stat.threePointersAttempted,
    );

    final ftPct = calculateFreeThrowPct(
      freeThrowsMade: stat.freeThrowsMade,
      freeThrowAttempts: stat.freeThrowsAttempted,
    );

    // 고급 슈팅 효율
    final tsPct = calculateTrueShootingPct(
      points: stat.points,
      fieldGoalAttempts: stat.fieldGoalsAttempted,
      freeThrowAttempts: stat.freeThrowsAttempted,
    );

    final efgPct = calculateEffectiveFieldGoalPct(
      fieldGoalsMade: stat.fieldGoalsMade,
      threePointersMade: stat.threePointersMade,
      fieldGoalAttempts: stat.fieldGoalsAttempted,
    );

    // Game Score
    final gameScore = calculateGameScore(
      points: stat.points,
      fieldGoalsMade: stat.fieldGoalsMade,
      fieldGoalAttempts: stat.fieldGoalsAttempted,
      freeThrowsMade: stat.freeThrowsMade,
      freeThrowAttempts: stat.freeThrowsAttempted,
      offensiveRebounds: stat.offensiveRebounds,
      defensiveRebounds: stat.defensiveRebounds,
      steals: stat.steals,
      assists: stat.assists,
      blocks: stat.blocks,
      personalFouls: stat.personalFouls,
      turnovers: stat.turnovers,
    );

    // Simple PER
    final simplePER = calculateSimplePER(
      points: stat.points,
      rebounds: stat.offensiveRebounds + stat.defensiveRebounds,
      assists: stat.assists,
      steals: stat.steals,
      blocks: stat.blocks,
      turnovers: stat.turnovers,
      personalFouls: stat.personalFouls,
      fieldGoalsMade: stat.fieldGoalsMade,
      fieldGoalAttempts: stat.fieldGoalsAttempted,
      freeThrowsMade: stat.freeThrowsMade,
      freeThrowAttempts: stat.freeThrowsAttempted,
      minutesPlayed: stat.minutesPlayed,
    );

    // 팀 데이터가 있으면 추가 지표 계산
    double? usageRate;
    double? assistPct;
    double? reboundPct;

    if (teamStats != null) {
      usageRate = calculateUsageRate(
        fieldGoalAttempts: stat.fieldGoalsAttempted,
        freeThrowAttempts: stat.freeThrowsAttempted,
        turnovers: stat.turnovers,
        minutesPlayed: stat.minutesPlayed,
        teamFieldGoalAttempts: teamStats.fgAttempts,
        teamFreeThrowAttempts: teamStats.ftAttempts,
        teamTurnovers: teamStats.turnovers,
        teamMinutes: teamStats.totalMinutes,
      );

      assistPct = calculateAssistPercentage(
        assists: stat.assists,
        minutesPlayed: stat.minutesPlayed,
        fieldGoalsMade: stat.fieldGoalsMade,
        teamFieldGoalsMade: teamStats.fgMade,
        teamMinutes: teamStats.totalMinutes,
      );

      reboundPct = calculateReboundPercentage(
        rebounds: stat.offensiveRebounds + stat.defensiveRebounds,
        minutesPlayed: stat.minutesPlayed,
        teamRebounds: teamStats.totalRebounds,
        opponentRebounds: teamStats.opponentRebounds,
        teamMinutes: teamStats.totalMinutes,
      );
    }

    // PIE (경기 전체 데이터 필요)
    double? pie;
    if (gameStats != null) {
      pie = calculatePIE(
        points: stat.points,
        fieldGoalsMade: stat.fieldGoalsMade,
        fieldGoalAttempts: stat.fieldGoalsAttempted,
        freeThrowsMade: stat.freeThrowsMade,
        freeThrowAttempts: stat.freeThrowsAttempted,
        offensiveRebounds: stat.offensiveRebounds,
        defensiveRebounds: stat.defensiveRebounds,
        assists: stat.assists,
        steals: stat.steals,
        blocks: stat.blocks,
        personalFouls: stat.personalFouls,
        turnovers: stat.turnovers,
        gamePoints: gameStats.totalPoints,
        gameFieldGoalsMade: gameStats.fgMade,
        gameFieldGoalAttempts: gameStats.fgAttempts,
        gameFreeThrowsMade: gameStats.ftMade,
        gameFreeThrowAttempts: gameStats.ftAttempts,
        gameOffensiveRebounds: gameStats.offRebounds,
        gameDefensiveRebounds: gameStats.defRebounds,
        gameAssists: gameStats.assists,
        gameSteals: gameStats.steals,
        gameBlocks: gameStats.blocks,
        gameFouls: gameStats.fouls,
        gameTurnovers: gameStats.turnovers,
      );
    }

    return AdvancedPlayerStats(
      playerId: stat.tournamentTeamPlayerId,
      matchId: stat.localMatchId,
      fieldGoalPct: fgPct,
      threePointPct: threePct,
      freeThrowPct: ftPct,
      trueShootingPct: tsPct,
      effectiveFieldGoalPct: efgPct,
      gameScore: gameScore,
      simplePER: simplePER,
      usageRate: usageRate,
      assistPct: assistPct,
      reboundPct: reboundPct,
      pie: pie,
    );
  }
}

/// 선수 고급 통계 결과
class AdvancedPlayerStats {
  final int playerId;
  final int matchId;

  // 기본 슈팅 효율
  final double fieldGoalPct;
  final double threePointPct;
  final double freeThrowPct;

  // 고급 슈팅 효율
  final double trueShootingPct;
  final double effectiveFieldGoalPct;

  // 종합 지표
  final double gameScore;
  final double simplePER;
  final double? usageRate;
  final double? assistPct;
  final double? reboundPct;
  final double? pie;

  const AdvancedPlayerStats({
    required this.playerId,
    required this.matchId,
    required this.fieldGoalPct,
    required this.threePointPct,
    required this.freeThrowPct,
    required this.trueShootingPct,
    required this.effectiveFieldGoalPct,
    required this.gameScore,
    required this.simplePER,
    this.usageRate,
    this.assistPct,
    this.reboundPct,
    this.pie,
  });

  /// 효율성 등급 (A, B, C, D, F)
  String get efficiencyGrade {
    if (trueShootingPct >= 0.6) return 'A';
    if (trueShootingPct >= 0.55) return 'B';
    if (trueShootingPct >= 0.5) return 'C';
    if (trueShootingPct >= 0.45) return 'D';
    return 'F';
  }

  /// Game Score 기반 퍼포먼스 등급
  String get performanceGrade {
    if (gameScore >= 20) return '★★★★★'; // 엘리트
    if (gameScore >= 15) return '★★★★☆'; // 훌륭함
    if (gameScore >= 10) return '★★★☆☆'; // 좋음
    if (gameScore >= 5) return '★★☆☆☆'; // 평균
    return '★☆☆☆☆'; // 개선 필요
  }

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'matchId': matchId,
        'fgPct': fieldGoalPct,
        '3pPct': threePointPct,
        'ftPct': freeThrowPct,
        'tsPct': trueShootingPct,
        'efgPct': effectiveFieldGoalPct,
        'gameScore': gameScore,
        'simplePER': simplePER,
        'usageRate': usageRate,
        'assistPct': assistPct,
        'reboundPct': reboundPct,
        'pie': pie,
        'efficiencyGrade': efficiencyGrade,
        'performanceGrade': performanceGrade,
      };
}

/// 팀 통계 데이터 (USG%, AST%, REB% 계산용)
class TeamStats {
  final int fgMade;
  final int fgAttempts;
  final int ftAttempts;
  final int turnovers;
  final int totalRebounds;
  final int opponentRebounds;
  final int totalMinutes;

  const TeamStats({
    required this.fgMade,
    required this.fgAttempts,
    required this.ftAttempts,
    required this.turnovers,
    required this.totalRebounds,
    required this.opponentRebounds,
    required this.totalMinutes,
  });
}

/// 경기 전체 통계 데이터 (PIE 계산용)
class GameStats {
  final int totalPoints;
  final int fgMade;
  final int fgAttempts;
  final int ftMade;
  final int ftAttempts;
  final int offRebounds;
  final int defRebounds;
  final int assists;
  final int steals;
  final int blocks;
  final int fouls;
  final int turnovers;

  const GameStats({
    required this.totalPoints,
    required this.fgMade,
    required this.fgAttempts,
    required this.ftMade,
    required this.ftAttempts,
    required this.offRebounds,
    required this.defRebounds,
    required this.assists,
    required this.steals,
    required this.blocks,
    required this.fouls,
    required this.turnovers,
  });
}
