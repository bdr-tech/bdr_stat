import 'dart:convert';

/// 대회 게임 규칙 모델 (FR-006, FR-010)
///
/// game_rules JSON 스키마 기반. 섹션별 중첩 구조.
/// 모든 필드는 FIBA 2025 기본값이 설정되어 있어 null-safe.
class GameRulesModel {
  // timing
  final int quarterMinutes;
  final int overtimeMinutes;
  final int halftimeSeconds;
  final int quarterBreakSeconds;
  final int beforeOvertimeSeconds;

  // shot_clock (FR-006)
  final int shotClockFullSeconds;
  final int shotClockAfterOffensiveReboundSeconds;
  final int shotClockDecimalThresholdSeconds;
  final int shotClockDecimalPrecision;

  // fouls
  final int foulOutLimit;
  final int teamBonusThreshold;
  final int teamDoubleBonusThreshold;
  final int technicalFoulEjectionLimit;

  // timeouts (FR-010)
  final int timeoutFullDurationSeconds;
  final int timeoutTwentySecondDurationSeconds;
  final int timeoutsFirstHalf;
  final int timeoutsSecondHalf;
  final int timeoutsOvertime;
  final bool bonusTimeoutLast2minEnabled;
  final int bonusTimeoutLast2minCount;

  // scoring
  final bool threePointLineEnabled;
  final bool goaltendingViolationEnabled;

  const GameRulesModel({
    // timing
    this.quarterMinutes = 10,
    this.overtimeMinutes = 5,
    this.halftimeSeconds = 600,
    this.quarterBreakSeconds = 120,
    this.beforeOvertimeSeconds = 120,
    // shot_clock
    this.shotClockFullSeconds = 24,
    this.shotClockAfterOffensiveReboundSeconds = 14,
    this.shotClockDecimalThresholdSeconds = 5,
    this.shotClockDecimalPrecision = 1,
    // fouls
    this.foulOutLimit = 5,
    this.teamBonusThreshold = 5,
    this.teamDoubleBonusThreshold = 10,
    this.technicalFoulEjectionLimit = 2,
    // timeouts
    this.timeoutFullDurationSeconds = 60,
    this.timeoutTwentySecondDurationSeconds = 20,
    this.timeoutsFirstHalf = 2,
    this.timeoutsSecondHalf = 3,
    this.timeoutsOvertime = 1,
    this.bonusTimeoutLast2minEnabled = false,
    this.bonusTimeoutLast2minCount = 1,
    // scoring
    this.threePointLineEnabled = true,
    this.goaltendingViolationEnabled = true,
  });

  /// FIBA 2025 기본값
  static const GameRulesModel defaults = GameRulesModel();

  /// JSON에서 파싱 (섹션별 중첩 구조)
  factory GameRulesModel.fromJson(Map<String, dynamic> json) {
    final timing = json['timing'] as Map<String, dynamic>? ?? {};
    final shotClock = json['shot_clock'] as Map<String, dynamic>? ?? {};
    final fouls = json['fouls'] as Map<String, dynamic>? ?? {};
    final timeouts = json['timeouts'] as Map<String, dynamic>? ?? {};
    final scoring = json['scoring'] as Map<String, dynamic>? ?? {};

    return GameRulesModel(
      // timing
      quarterMinutes: timing['quarter_minutes'] as int? ?? 10,
      overtimeMinutes: timing['overtime_minutes'] as int? ?? 5,
      halftimeSeconds: timing['halftime_seconds'] as int? ?? 600,
      quarterBreakSeconds: timing['quarter_break_seconds'] as int? ?? 120,
      beforeOvertimeSeconds: timing['before_overtime_seconds'] as int? ?? 120,
      // shot_clock (FR-006)
      shotClockFullSeconds: shotClock['full_seconds'] as int? ?? 24,
      shotClockAfterOffensiveReboundSeconds:
          shotClock['after_offensive_rebound_seconds'] as int? ?? 14,
      shotClockDecimalThresholdSeconds:
          shotClock['decimal_threshold_seconds'] as int? ?? 5,
      shotClockDecimalPrecision:
          shotClock['decimal_precision'] as int? ?? 1,
      // fouls
      foulOutLimit: fouls['foul_out_limit'] as int? ?? 5,
      teamBonusThreshold: fouls['team_bonus_threshold'] as int? ?? 5,
      teamDoubleBonusThreshold:
          fouls['team_double_bonus_threshold'] as int? ?? 10,
      technicalFoulEjectionLimit:
          fouls['technical_foul_ejection_limit'] as int? ?? 2,
      // timeouts (FR-010)
      timeoutFullDurationSeconds:
          timeouts['full_duration_seconds'] as int? ?? 60,
      timeoutTwentySecondDurationSeconds:
          timeouts['twenty_second_duration_seconds'] as int? ?? 20,
      timeoutsFirstHalf: timeouts['timeouts_first_half'] as int? ?? 2,
      timeoutsSecondHalf: timeouts['timeouts_second_half'] as int? ?? 3,
      timeoutsOvertime: timeouts['timeouts_overtime'] as int? ?? 1,
      bonusTimeoutLast2minEnabled:
          timeouts['bonus_timeout_last2min_enabled'] as bool? ?? false,
      bonusTimeoutLast2minCount:
          timeouts['bonus_timeout_last2min_count'] as int? ?? 1,
      // scoring
      threePointLineEnabled:
          scoring['three_point_line_enabled'] as bool? ?? true,
      goaltendingViolationEnabled:
          scoring['goaltending_violation_enabled'] as bool? ?? true,
    );
  }

  /// JSON 문자열에서 파싱 (LocalTournaments.gameRulesJson 용)
  factory GameRulesModel.fromJsonString(String jsonString) {
    if (jsonString.isEmpty || jsonString == '{}') {
      return const GameRulesModel();
    }
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return GameRulesModel.fromJson(json);
    } catch (_) {
      return const GameRulesModel();
    }
  }

  /// 샷클락 소수점 표시 여부 (FR-006)
  /// [remainingTenths] 남은 시간 (1/10초 단위)
  bool shouldShowShotClockDecimal(int remainingTenths) {
    return remainingTenths < shotClockDecimalThresholdSeconds * 10;
  }

  /// 게임클락 소수점 표시 여부 (FR-007)
  /// 1분(600 tenths) 이내에서 1/10초 표시
  bool shouldShowGameClockDecimal(int remainingTenths) {
    return remainingTenths < 600; // 60초 * 10 = 600 tenths
  }

  /// 해당 half의 타임아웃 허용 횟수 (FR-010)
  int timeoutsAllowedForHalf(int half) {
    switch (half) {
      case 1:
        return timeoutsFirstHalf;
      case 2:
        return timeoutsSecondHalf;
      default:
        return timeoutsOvertime;
    }
  }

  /// 쿼터에서 half 번호 계산
  /// Q1,Q2 → 1 (전반), Q3,Q4 → 2 (후반), Q5+ → 3+ (연장)
  static int halfFromQuarter(int quarter) {
    if (quarter <= 2) return 1;
    if (quarter <= 4) return 2;
    return 3; // 연장
  }
}
