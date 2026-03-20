/// 쿼터별 선수 통계 (FR-001)
///
/// PlayByPlay 집계 쿼리 결과를 담는 도메인 모델.
/// 스키마 변경 없이 집계 쿼리로 생성.
class PlayerQuarterStats {
  final int playerId;
  final int? quarter; // null = ALL (전체 경기)
  final int totalPoints;
  final int fgm;
  final int fga;
  final int twoPm;
  final int twoPa;
  final int threePm;
  final int threePa;
  final int ftm;
  final int fta;
  final int offensiveRebounds;
  final int defensiveRebounds;
  final int assists;
  final int steals;
  final int blocks;
  final int turnovers;
  final int personalFouls;

  const PlayerQuarterStats({
    required this.playerId,
    this.quarter,
    this.totalPoints = 0,
    this.fgm = 0,
    this.fga = 0,
    this.twoPm = 0,
    this.twoPa = 0,
    this.threePm = 0,
    this.threePa = 0,
    this.ftm = 0,
    this.fta = 0,
    this.offensiveRebounds = 0,
    this.defensiveRebounds = 0,
    this.assists = 0,
    this.steals = 0,
    this.blocks = 0,
    this.turnovers = 0,
    this.personalFouls = 0,
  });

  // ── 계산 필드 ──

  int get totalRebounds => offensiveRebounds + defensiveRebounds;

  /// FG% (FR-002). FGA=0이면 null ("-" 표시용)
  double? get fgPercentage =>
      fga == 0 ? null : (fgm / fga * 100);

  /// 3P% (FR-002). 3PA=0이면 null
  double? get threePercentage =>
      threePa == 0 ? null : (threePm / threePa * 100);

  /// FT% (FR-002). FTA=0이면 null
  double? get ftPercentage =>
      fta == 0 ? null : (ftm / fta * 100);

  /// 퍼센티지 포맷 문자열 (소수점 1자리)
  /// null이면 "-" 반환
  static String formatPercentage(double? pct) {
    if (pct == null) return '-';
    return pct.toStringAsFixed(1);
  }

  /// Drift customSelect 결과 row에서 생성
  factory PlayerQuarterStats.fromQueryRow(
    Map<String, dynamic> row, {
    int? playerId,
    int? quarter,
  }) {
    return PlayerQuarterStats(
      playerId: playerId ?? (row['tournament_team_player_id'] as int? ?? 0),
      quarter: quarter,
      totalPoints: (row['total_points'] as int?) ?? 0,
      fgm: (row['fgm'] as int?) ?? 0,
      fga: (row['fga'] as int?) ?? 0,
      twoPm: (row['two_pm'] as int?) ?? 0,
      twoPa: (row['two_pa'] as int?) ?? 0,
      threePm: (row['three_pm'] as int?) ?? 0,
      threePa: (row['three_pa'] as int?) ?? 0,
      ftm: (row['ftm'] as int?) ?? 0,
      fta: (row['fta'] as int?) ?? 0,
      offensiveRebounds: (row['orb'] as int?) ?? 0,
      defensiveRebounds: (row['drb'] as int?) ?? 0,
      assists: (row['ast'] as int?) ?? 0,
      steals: (row['stl'] as int?) ?? 0,
      blocks: (row['blk'] as int?) ?? 0,
      turnovers: (row['tov'] as int?) ?? 0,
      personalFouls: (row['pf'] as int?) ?? 0,
    );
  }

  /// 빈 스탯 (선수가 해당 쿼터에 기록이 없을 때)
  factory PlayerQuarterStats.empty({
    required int playerId,
    int? quarter,
  }) {
    return PlayerQuarterStats(
      playerId: playerId,
      quarter: quarter,
    );
  }
}

/// 쿼터별 팀 점수 요약
class QuarterScoreSummary {
  final int q1;
  final int q2;
  final int q3;
  final int q4;
  final List<int> overtime;

  const QuarterScoreSummary({
    this.q1 = 0,
    this.q2 = 0,
    this.q3 = 0,
    this.q4 = 0,
    this.overtime = const [],
  });

  int get total => q1 + q2 + q3 + q4 + overtime.fold(0, (a, b) => a + b);

  /// 특정 쿼터 점수 조회
  int pointsForQuarter(int quarter) {
    switch (quarter) {
      case 1: return q1;
      case 2: return q2;
      case 3: return q3;
      case 4: return q4;
      default:
        final otIndex = quarter - 5;
        if (otIndex >= 0 && otIndex < overtime.length) {
          return overtime[otIndex];
        }
        return 0;
    }
  }

  /// Drift customSelect 결과 rows에서 생성
  factory QuarterScoreSummary.fromQueryRows(List<Map<String, dynamic>> rows) {
    var q1 = 0, q2 = 0, q3 = 0, q4 = 0;
    final overtime = <int>[];

    for (final row in rows) {
      final quarter = row['quarter'] as int? ?? 0;
      final points = row['quarter_points'] as int? ?? 0;
      switch (quarter) {
        case 1: q1 = points;
        case 2: q2 = points;
        case 3: q3 = points;
        case 4: q4 = points;
        default:
          final otIndex = quarter - 5;
          while (overtime.length <= otIndex) {
            overtime.add(0);
          }
          overtime[otIndex] = points;
      }
    }
    return QuarterScoreSummary(
      q1: q1,
      q2: q2,
      q3: q3,
      q4: q4,
      overtime: overtime,
    );
  }
}
