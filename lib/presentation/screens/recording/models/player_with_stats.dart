import '../../../../data/database/database.dart';

/// 선수 + 통계 결합 모델
class PlayerWithStats {
  final LocalTournamentPlayer player;
  final LocalPlayerStat stats;

  PlayerWithStats({required this.player, required this.stats});

  /// 선수 이름 (편의 getter)
  String get name => player.userName;

  /// 등번호 (편의 getter)
  int? get jerseyNumber => player.jerseyNumber;

  /// 출전 중 여부 (편의 getter)
  bool get isOnCourt => stats.isOnCourt;

  /// 득점 계산 (2점 + 3점 + 자유투)
  int get points =>
      (stats.twoPointersMade * 2) +
      (stats.threePointersMade * 3) +
      stats.freeThrowsMade;

  /// 총 리바운드
  int get rebounds => stats.offensiveRebounds + stats.defensiveRebounds;

  /// 슛 시도
  int get shotAttempts => stats.twoPointersAttempted + stats.threePointersAttempted;

  /// 슛 성공
  int get shotMade => stats.twoPointersMade + stats.threePointersMade;

  /// 슛 성공률 (백분율)
  double get shotPercentage {
    if (shotAttempts == 0) return 0.0;
    return (shotMade / shotAttempts) * 100;
  }

  /// 3점 성공률 (백분율)
  double get threePointPercentage {
    if (stats.threePointersAttempted == 0) return 0.0;
    return (stats.threePointersMade / stats.threePointersAttempted) * 100;
  }

  /// 자유투 성공률 (백분율)
  double get freeThrowPercentage {
    if (stats.freeThrowsAttempted == 0) return 0.0;
    return (stats.freeThrowsMade / stats.freeThrowsAttempted) * 100;
  }

  /// 스탯 요약 문자열
  String get statSummary {
    return '$points점 ${rebounds}R ${stats.assists}A';
  }

  /// 간단 스탯 문자열 (점수만)
  String get pointsDisplay => '$points';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerWithStats &&
          runtimeType == other.runtimeType &&
          player.id == other.player.id;

  @override
  int get hashCode => player.id.hashCode;
}
