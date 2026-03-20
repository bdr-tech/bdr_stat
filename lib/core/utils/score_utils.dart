import 'dart:convert';

/// 점수 관련 유틸리티
class ScoreUtils {
  ScoreUtils._();

  /// 득점 계산 (2P×2 + 3P×3 + FT×1)
  static int calculatePoints({
    required int twoPointersMade,
    required int threePointersMade,
    required int freeThrowsMade,
  }) {
    return (twoPointersMade * 2) + (threePointersMade * 3) + freeThrowsMade;
  }

  /// 슛 성공률 계산
  static double calculatePercentage(int made, int attempted) {
    if (attempted == 0) return 0.0;
    return (made / attempted) * 100;
  }

  /// 슛 성공률 포맷팅
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// FG 문자열 포맷팅 (예: "10-18")
  static String formatMadeAttempted(int made, int attempted) {
    return '$made-$attempted';
  }

  /// FG 문자열 + 퍼센트 포맷팅 (예: "10-18 (55.6%)")
  static String formatMadeAttemptedWithPercentage(int made, int attempted) {
    final percentage = calculatePercentage(made, attempted);
    return '$made-$attempted (${formatPercentage(percentage)})';
  }

  /// 쿼터별 점수 JSON 파싱
  static Map<String, Map<String, int>> parseQuarterScores(String json) {
    if (json.isEmpty || json == '{}') {
      return {'home': {}, 'away': {}};
    }
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return {
        'home': (decoded['home'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as int)) ??
            {},
        'away': (decoded['away'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as int)) ??
            {},
      };
    } catch (e) {
      return {'home': {}, 'away': {}};
    }
  }

  /// 쿼터별 점수 JSON 생성
  static String encodeQuarterScores(Map<String, Map<String, int>> scores) {
    return jsonEncode(scores);
  }

  /// 쿼터별 점수 업데이트
  static String updateQuarterScore(
    String json,
    int quarter,
    bool isHome,
    int score,
  ) {
    final scores = parseQuarterScores(json);
    final quarterKey = 'q$quarter';
    final teamKey = isHome ? 'home' : 'away';

    scores[teamKey]![quarterKey] = score;
    return encodeQuarterScores(scores);
  }

  /// 쿼터별 점수에서 총점 계산
  static int calculateTotalFromQuarters(
    Map<String, Map<String, int>> scores,
    bool isHome,
  ) {
    final teamScores = isHome ? scores['home']! : scores['away']!;
    return teamScores.values.fold(0, (sum, score) => sum + score);
  }
}

/// 팀 파울 관련 유틸리티
class TeamFoulUtils {
  TeamFoulUtils._();

  /// 팀 파울 JSON 파싱
  static Map<String, Map<String, int>> parseTeamFouls(String json) {
    if (json.isEmpty || json == '{}') {
      return {'home': {}, 'away': {}};
    }
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return {
        'home': (decoded['home'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as int)) ??
            {},
        'away': (decoded['away'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as int)) ??
            {},
      };
    } catch (e) {
      return {'home': {}, 'away': {}};
    }
  }

  /// 팀 파울 JSON 생성
  static String encodeTeamFouls(Map<String, Map<String, int>> fouls) {
    return jsonEncode(fouls);
  }

  /// 쿼터별 팀 파울 가져오기
  static int getQuarterFouls(String json, int quarter, bool isHome) {
    final fouls = parseTeamFouls(json);
    final quarterKey = 'q$quarter';
    final teamKey = isHome ? 'home' : 'away';
    return fouls[teamKey]?[quarterKey] ?? 0;
  }

  /// 팀 파울 추가
  static String addTeamFoul(String json, int quarter, bool isHome) {
    final fouls = parseTeamFouls(json);
    final quarterKey = 'q$quarter';
    final teamKey = isHome ? 'home' : 'away';

    fouls[teamKey]![quarterKey] = (fouls[teamKey]![quarterKey] ?? 0) + 1;
    return encodeTeamFouls(fouls);
  }

  /// 보너스 상태 확인
  static bool isInBonus(String json, int quarter, bool isHome, {int threshold = 5}) {
    return getQuarterFouls(json, quarter, isHome) >= threshold;
  }
}
