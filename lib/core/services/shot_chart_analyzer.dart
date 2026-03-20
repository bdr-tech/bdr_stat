import 'dart:math';
import 'dart:ui';

import '../../data/database/database.dart';

/// 슛 차트 분석 서비스
///
/// 기능:
/// - 존별 슈팅 효율 분석
/// - 히트맵 데이터 생성
/// - 핫존/콜드존 식별
/// - 슈팅 패턴 분석
class ShotChartAnalyzer {
  ShotChartAnalyzer._();

  static final ShotChartAnalyzer instance = ShotChartAnalyzer._();

  // ═══════════════════════════════════════════════════════════════
  // 코트 존 정의 (NBA 스타일)
  // ═══════════════════════════════════════════════════════════════

  /// NBA 스타일 코트 존 (25개 존)
  static const List<CourtZone> courtZones = [
    // 제한구역 (페인트)
    CourtZone(1, 'Restricted Area', ZoneType.restrictedArea, 0.0),
    CourtZone(2, 'Paint (Left)', ZoneType.paint, 0.0),
    CourtZone(3, 'Paint (Center)', ZoneType.paint, 0.0),
    CourtZone(4, 'Paint (Right)', ZoneType.paint, 0.0),

    // 미드레인지
    CourtZone(5, 'Mid-Range (Left Baseline)', ZoneType.midRange, 10.0),
    CourtZone(6, 'Mid-Range (Left Wing)', ZoneType.midRange, 12.0),
    CourtZone(7, 'Mid-Range (Left Elbow)', ZoneType.midRange, 15.0),
    CourtZone(8, 'Mid-Range (Top of Key)', ZoneType.midRange, 16.0),
    CourtZone(9, 'Mid-Range (Right Elbow)', ZoneType.midRange, 15.0),
    CourtZone(10, 'Mid-Range (Right Wing)', ZoneType.midRange, 12.0),
    CourtZone(11, 'Mid-Range (Right Baseline)', ZoneType.midRange, 10.0),

    // 3점 라인
    CourtZone(12, '3PT (Left Corner)', ZoneType.threePoint, 22.0),
    CourtZone(13, '3PT (Left Wing)', ZoneType.threePoint, 23.75),
    CourtZone(14, '3PT (Left 45)', ZoneType.threePoint, 23.75),
    CourtZone(15, '3PT (Top of Arc)', ZoneType.threePoint, 23.75),
    CourtZone(16, '3PT (Right 45)', ZoneType.threePoint, 23.75),
    CourtZone(17, '3PT (Right Wing)', ZoneType.threePoint, 23.75),
    CourtZone(18, '3PT (Right Corner)', ZoneType.threePoint, 22.0),

    // 장거리
    CourtZone(19, 'Deep 3PT (Left)', ZoneType.deepThree, 28.0),
    CourtZone(20, 'Deep 3PT (Center)', ZoneType.deepThree, 30.0),
    CourtZone(21, 'Deep 3PT (Right)', ZoneType.deepThree, 28.0),

    // 하프코트 이상
    CourtZone(22, 'Half Court (Left)', ZoneType.halfCourt, 47.0),
    CourtZone(23, 'Half Court (Center)', ZoneType.halfCourt, 47.0),
    CourtZone(24, 'Half Court (Right)', ZoneType.halfCourt, 47.0),

    // 자유투
    CourtZone(25, 'Free Throw', ZoneType.freeThrow, 15.0),
  ];

  /// 좌표로 존 ID 결정
  int getZoneFromCoordinates(double x, double y) {
    // 코트 좌표: (0,0) = 코트 좌측 하단, (100, 100) = 코트 우측 상단
    // 바스켓 위치: (50, 5.25) 정도 (하프코트 기준)

    final distanceFromRim = _calculateDistanceFromRim(x, y);
    final angle = _calculateAngle(x, y);

    // 하프코트 이상
    if (y > 47) {
      if (x < 33) return 22;
      if (x > 67) return 24;
      return 23;
    }

    // 딥 3점 (28피트 이상)
    if (distanceFromRim >= 28) {
      if (angle < -30) return 19;
      if (angle > 30) return 21;
      return 20;
    }

    // 3점 라인 (22-23.75 피트)
    if (distanceFromRim >= 22 ||
        (y < 14 && (x < 3 || x > 97))) {
      // 코너 3점
      if (y < 14) {
        return x < 50 ? 12 : 18;
      }
      // 윙 ~ 탑
      if (angle < -60) return 13;
      if (angle < -30) return 14;
      if (angle > 60) return 17;
      if (angle > 30) return 16;
      return 15;
    }

    // 미드레인지 (6-22 피트)
    if (distanceFromRim >= 6) {
      if (y < 14) {
        return x < 50 ? 5 : 11;
      }
      if (angle < -60) return 6;
      if (angle < -20) return 7;
      if (angle > 60) return 10;
      if (angle > 20) return 9;
      return 8;
    }

    // 페인트 (4-6 피트)
    if (distanceFromRim >= 4) {
      if (x < 40) return 2;
      if (x > 60) return 4;
      return 3;
    }

    // 제한구역 (4피트 이내)
    return 1;
  }

  /// 림으로부터의 거리 계산 (피트)
  double _calculateDistanceFromRim(double x, double y) {
    // 코트 좌표를 피트로 변환 (94x50 피트 코트)
    final courtX = (x / 100) * 50; // 0-50
    final courtY = (y / 100) * 47; // 하프코트 0-47

    // 바스켓 위치 (하프코트 중앙, 베이스라인에서 5.25피트)
    const rimX = 25.0; // 중앙
    const rimY = 5.25; // 베이스라인에서 거리

    final dx = courtX - rimX;
    final dy = courtY - rimY;

    return sqrt(dx * dx + dy * dy);
  }

  /// 바스켓 기준 각도 계산 (-90 ~ 90)
  double _calculateAngle(double x, double y) {
    final courtX = (x / 100) * 50 - 25; // -25 ~ 25 (중앙이 0)
    final courtY = (y / 100) * 47 - 5.25;

    if (courtY <= 0) return 0;
    return atan2(courtX, courtY) * (180 / pi);
  }

  // ═══════════════════════════════════════════════════════════════
  // 슛 분석
  // ═══════════════════════════════════════════════════════════════

  /// PlayByPlay 이벤트에서 슛 데이터 분석
  ShotChartAnalysis analyzeShotChart({
    required List<LocalPlayByPlay> events,
    int? playerId,
    int? teamId,
  }) {
    // 슛 이벤트만 필터링
    var shots = events.where((e) => e.actionType == 'shot').toList();

    // 선수별 필터
    if (playerId != null) {
      shots = shots.where((e) => e.tournamentTeamPlayerId == playerId).toList();
    }

    // 팀별 필터
    if (teamId != null) {
      shots = shots.where((e) => e.tournamentTeamId == teamId).toList();
    }

    // 존별 통계 초기화
    final zoneStats = <int, ZoneStats>{};
    for (final zone in courtZones) {
      zoneStats[zone.id] = ZoneStats(zoneId: zone.id, zoneName: zone.name);
    }

    // 개별 슛 데이터
    final shotData = <ShotData>[];

    for (final shot in shots) {
      // 존 결정
      int zoneId;
      if (shot.courtZone != null) {
        zoneId = shot.courtZone!;
      } else if (shot.courtX != null && shot.courtY != null) {
        zoneId = getZoneFromCoordinates(shot.courtX!, shot.courtY!);
      } else {
        // 액션 서브타입으로 추정
        zoneId = _estimateZoneFromSubtype(shot.actionSubtype);
      }

      // 슛 데이터 생성
      final data = ShotData(
        playerId: shot.tournamentTeamPlayerId,
        teamId: shot.tournamentTeamId,
        x: shot.courtX ?? 50,
        y: shot.courtY ?? 50,
        zoneId: zoneId,
        isMade: shot.isMade ?? false,
        shotType: shot.actionSubtype ?? '2pt',
        points: shot.pointsScored,
        quarter: shot.quarter,
        gameClockSeconds: shot.gameClockSeconds,
        isFastbreak: shot.isFastbreak,
        isSecondChance: shot.isSecondChance,
      );

      shotData.add(data);

      // 존 통계 업데이트
      final stats = zoneStats[zoneId]!;
      stats.attempts++;
      if (shot.isMade == true) {
        stats.makes++;
        stats.points += shot.pointsScored;
      }
    }

    // 효율성 계산
    for (final stats in zoneStats.values) {
      stats.calculateEfficiency();
    }

    // 핫존/콜드존 식별
    final avgEfficiency = _calculateAverageEfficiency(zoneStats.values.toList());
    final hotZones = <int>[];
    final coldZones = <int>[];

    for (final stats in zoneStats.values) {
      if (stats.attempts >= 3) {
        // 최소 3번 시도
        if (stats.efficiency >= avgEfficiency + 0.05) {
          hotZones.add(stats.zoneId);
        } else if (stats.efficiency <= avgEfficiency - 0.05) {
          coldZones.add(stats.zoneId);
        }
      }
    }

    return ShotChartAnalysis(
      totalShots: shotData.length,
      totalMakes: shotData.where((s) => s.isMade).length,
      totalPoints: shotData.fold(0, (sum, s) => sum + (s.isMade ? s.points : 0)),
      zoneStats: Map.unmodifiable(zoneStats),
      shotData: List.unmodifiable(shotData),
      hotZones: List.unmodifiable(hotZones),
      coldZones: List.unmodifiable(coldZones),
      averageEfficiency: avgEfficiency,
    );
  }

  /// 서브타입에서 존 추정
  int _estimateZoneFromSubtype(String? subtype) {
    switch (subtype) {
      case '3pt':
        return 15; // 탑 오브 아크
      case 'ft':
        return 25; // 자유투
      case 'layup':
      case 'dunk':
        return 1; // 제한구역
      default:
        return 3; // 페인트 중앙
    }
  }

  /// 평균 효율 계산
  double _calculateAverageEfficiency(List<ZoneStats> stats) {
    final withAttempts = stats.where((s) => s.attempts > 0).toList();
    if (withAttempts.isEmpty) return 0;

    final totalAttempts = withAttempts.fold(0, (sum, s) => sum + s.attempts);
    final totalMakes = withAttempts.fold(0, (sum, s) => sum + s.makes);

    return totalAttempts > 0 ? totalMakes / totalAttempts : 0;
  }

  // ═══════════════════════════════════════════════════════════════
  // 히트맵 생성
  // ═══════════════════════════════════════════════════════════════

  /// 히트맵 데이터 생성
  HeatmapData generateHeatmap({
    required ShotChartAnalysis analysis,
    int gridSize = 20,
  }) {
    // 그리드 초기화
    final grid = List.generate(
      gridSize,
      (_) => List.filled(gridSize, HeatmapCell(attempts: 0, makes: 0)),
    );

    // 슛 데이터를 그리드에 매핑
    for (final shot in analysis.shotData) {
      final gridX = ((shot.x / 100) * gridSize).floor().clamp(0, gridSize - 1);
      final gridY = ((shot.y / 100) * gridSize).floor().clamp(0, gridSize - 1);

      final cell = grid[gridY][gridX];
      grid[gridY][gridX] = HeatmapCell(
        attempts: cell.attempts + 1,
        makes: cell.makes + (shot.isMade ? 1 : 0),
      );
    }

    // 효율성 계산
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        grid[y][x].calculateEfficiency();
      }
    }

    return HeatmapData(
      gridSize: gridSize,
      cells: grid,
      maxAttempts: grid.expand((row) => row).fold(0, (max, cell) =>
          cell.attempts > max ? cell.attempts : max),
    );
  }

  /// 선수별 슈팅 성향 분석
  ShootingTendency analyzeShootingTendency(ShotChartAnalysis analysis) {
    int rimAttempts = 0;
    int rimMakes = 0;
    int midRangeAttempts = 0;
    int midRangeMakes = 0;
    int threePointAttempts = 0;
    int threePointMakes = 0;
    int cornerThreeAttempts = 0;
    int cornerThreeMakes = 0;

    for (final stats in analysis.zoneStats.values) {
      final zone = courtZones.firstWhere((z) => z.id == stats.zoneId);

      switch (zone.type) {
        case ZoneType.restrictedArea:
          rimAttempts += stats.attempts;
          rimMakes += stats.makes;
          break;
        case ZoneType.paint:
          rimAttempts += stats.attempts;
          rimMakes += stats.makes;
          break;
        case ZoneType.midRange:
          midRangeAttempts += stats.attempts;
          midRangeMakes += stats.makes;
          break;
        case ZoneType.threePoint:
          threePointAttempts += stats.attempts;
          threePointMakes += stats.makes;
          // 코너 3점 따로 계산
          if (stats.zoneId == 12 || stats.zoneId == 18) {
            cornerThreeAttempts += stats.attempts;
            cornerThreeMakes += stats.makes;
          }
          break;
        case ZoneType.deepThree:
          threePointAttempts += stats.attempts;
          threePointMakes += stats.makes;
          break;
        case ZoneType.halfCourt:
          // 무시
          break;
        case ZoneType.freeThrow:
          // 무시
          break;
      }
    }

    final totalAttempts = analysis.totalShots;

    return ShootingTendency(
      rimAttempts: rimAttempts,
      rimMakes: rimMakes,
      rimPct: rimAttempts > 0 ? rimMakes / rimAttempts : 0,
      rimFrequency: totalAttempts > 0 ? rimAttempts / totalAttempts : 0,
      midRangeAttempts: midRangeAttempts,
      midRangeMakes: midRangeMakes,
      midRangePct: midRangeAttempts > 0 ? midRangeMakes / midRangeAttempts : 0,
      midRangeFrequency:
          totalAttempts > 0 ? midRangeAttempts / totalAttempts : 0,
      threePointAttempts: threePointAttempts,
      threePointMakes: threePointMakes,
      threePointPct:
          threePointAttempts > 0 ? threePointMakes / threePointAttempts : 0,
      threePointFrequency:
          totalAttempts > 0 ? threePointAttempts / totalAttempts : 0,
      cornerThreeAttempts: cornerThreeAttempts,
      cornerThreeMakes: cornerThreeMakes,
      cornerThreePct:
          cornerThreeAttempts > 0 ? cornerThreeMakes / cornerThreeAttempts : 0,
    );
  }

  /// 쿼터별 슈팅 분석
  Map<int, ShotChartAnalysis> analyzeByQuarter(
      List<LocalPlayByPlay> events,
      {int? playerId}) {
    final byQuarter = <int, List<LocalPlayByPlay>>{};

    var shots = events.where((e) => e.actionType == 'shot').toList();
    if (playerId != null) {
      shots = shots.where((e) => e.tournamentTeamPlayerId == playerId).toList();
    }

    for (final shot in shots) {
      byQuarter.putIfAbsent(shot.quarter, () => []).add(shot);
    }

    return byQuarter.map(
      (quarter, quarterShots) => MapEntry(
        quarter,
        analyzeShotChart(events: quarterShots, playerId: playerId),
      ),
    );
  }
}

/// 코트 존 타입
enum ZoneType {
  restrictedArea, // 제한구역
  paint, // 페인트
  midRange, // 미드레인지
  threePoint, // 3점
  deepThree, // 딥 3점
  halfCourt, // 하프코트 이상
  freeThrow, // 자유투
}

/// 코트 존 정의
class CourtZone {
  final int id;
  final String name;
  final ZoneType type;
  final double distance; // 바스켓까지 평균 거리 (피트)

  const CourtZone(this.id, this.name, this.type, this.distance);
}

/// 존별 통계
class ZoneStats {
  final int zoneId;
  final String zoneName;
  int attempts;
  int makes;
  int points;
  double efficiency;

  ZoneStats({
    required this.zoneId,
    required this.zoneName,
    this.attempts = 0,
    this.makes = 0,
    this.points = 0,
    this.efficiency = 0,
  });

  void calculateEfficiency() {
    efficiency = attempts > 0 ? makes / attempts : 0;
  }

  /// 효율성 등급 색상 (히트맵용)
  Color getHeatmapColor() {
    if (attempts < 2) return const Color(0xFFE0E0E0); // 데이터 부족

    // 효율성에 따른 색상 (파랑 = 저조, 빨강 = 좋음)
    if (efficiency >= 0.5) return const Color(0xFFFF0000); // 빨강
    if (efficiency >= 0.4) return const Color(0xFFFF6600); // 주황
    if (efficiency >= 0.3) return const Color(0xFFFFFF00); // 노랑
    if (efficiency >= 0.2) return const Color(0xFF00CCFF); // 하늘
    return const Color(0xFF0066FF); // 파랑
  }

  Map<String, dynamic> toJson() => {
        'zoneId': zoneId,
        'zoneName': zoneName,
        'attempts': attempts,
        'makes': makes,
        'points': points,
        'efficiency': (efficiency * 100).toStringAsFixed(1),
      };
}

/// 개별 슛 데이터
class ShotData {
  final int playerId;
  final int teamId;
  final double x;
  final double y;
  final int zoneId;
  final bool isMade;
  final String shotType;
  final int points;
  final int quarter;
  final int gameClockSeconds;
  final bool isFastbreak;
  final bool isSecondChance;

  const ShotData({
    required this.playerId,
    required this.teamId,
    required this.x,
    required this.y,
    required this.zoneId,
    required this.isMade,
    required this.shotType,
    required this.points,
    required this.quarter,
    required this.gameClockSeconds,
    this.isFastbreak = false,
    this.isSecondChance = false,
  });

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'x': x,
        'y': y,
        'zoneId': zoneId,
        'isMade': isMade,
        'shotType': shotType,
        'points': points,
        'quarter': quarter,
      };
}

/// 슛 차트 분석 결과
class ShotChartAnalysis {
  final int totalShots;
  final int totalMakes;
  final int totalPoints;
  final Map<int, ZoneStats> zoneStats;
  final List<ShotData> shotData;
  final List<int> hotZones;
  final List<int> coldZones;
  final double averageEfficiency;

  const ShotChartAnalysis({
    required this.totalShots,
    required this.totalMakes,
    required this.totalPoints,
    required this.zoneStats,
    required this.shotData,
    required this.hotZones,
    required this.coldZones,
    required this.averageEfficiency,
  });

  double get shootingPercentage =>
      totalShots > 0 ? totalMakes / totalShots : 0;

  Map<String, dynamic> toJson() => {
        'totalShots': totalShots,
        'totalMakes': totalMakes,
        'totalPoints': totalPoints,
        'shootingPct': (shootingPercentage * 100).toStringAsFixed(1),
        'avgEfficiency': (averageEfficiency * 100).toStringAsFixed(1),
        'hotZones': hotZones,
        'coldZones': coldZones,
        'zoneStats': zoneStats.map((k, v) => MapEntry(k.toString(), v.toJson())),
      };
}

/// 히트맵 셀
class HeatmapCell {
  int attempts;
  int makes;
  double efficiency;

  HeatmapCell({
    required this.attempts,
    required this.makes,
    this.efficiency = 0,
  });

  void calculateEfficiency() {
    efficiency = attempts > 0 ? makes / attempts : 0;
  }

  /// 히트맵 색상 (투명도로 빈도, 색상으로 효율)
  Color getColor({required int maxAttempts}) {
    if (attempts == 0) return const Color(0x00000000);

    final alpha = (attempts / maxAttempts * 200 + 55).clamp(55.0, 255.0).toInt();

    // 효율성 기반 색상
    final int r, g, b;
    if (efficiency >= 0.5) {
      r = 0;
      g = 200;
      b = 0;
    } else if (efficiency >= 0.3) {
      r = 255;
      g = 200;
      b = 0;
    } else {
      r = 255;
      g = 0;
      b = 0;
    }

    return Color.fromARGB(alpha, r, g, b);
  }
}

/// 히트맵 데이터
class HeatmapData {
  final int gridSize;
  final List<List<HeatmapCell>> cells;
  final int maxAttempts;

  const HeatmapData({
    required this.gridSize,
    required this.cells,
    required this.maxAttempts,
  });

  /// 특정 위치의 셀 조회
  HeatmapCell getCell(int x, int y) => cells[y][x];
}

/// 슈팅 성향 분석 결과
class ShootingTendency {
  final int rimAttempts;
  final int rimMakes;
  final double rimPct;
  final double rimFrequency;

  final int midRangeAttempts;
  final int midRangeMakes;
  final double midRangePct;
  final double midRangeFrequency;

  final int threePointAttempts;
  final int threePointMakes;
  final double threePointPct;
  final double threePointFrequency;

  final int cornerThreeAttempts;
  final int cornerThreeMakes;
  final double cornerThreePct;

  const ShootingTendency({
    required this.rimAttempts,
    required this.rimMakes,
    required this.rimPct,
    required this.rimFrequency,
    required this.midRangeAttempts,
    required this.midRangeMakes,
    required this.midRangePct,
    required this.midRangeFrequency,
    required this.threePointAttempts,
    required this.threePointMakes,
    required this.threePointPct,
    required this.threePointFrequency,
    required this.cornerThreeAttempts,
    required this.cornerThreeMakes,
    required this.cornerThreePct,
  });

  /// 슈팅 스타일 분류
  String get shootingStyle {
    if (threePointFrequency >= 0.5) return '3점 슈터';
    if (rimFrequency >= 0.5) return '림 어택커';
    if (midRangeFrequency >= 0.4) return '미드레인지 전문';
    return '올라운드';
  }

  Map<String, dynamic> toJson() => {
        'rim': {
          'attempts': rimAttempts,
          'makes': rimMakes,
          'pct': (rimPct * 100).toStringAsFixed(1),
          'frequency': (rimFrequency * 100).toStringAsFixed(1),
        },
        'midRange': {
          'attempts': midRangeAttempts,
          'makes': midRangeMakes,
          'pct': (midRangePct * 100).toStringAsFixed(1),
          'frequency': (midRangeFrequency * 100).toStringAsFixed(1),
        },
        'threePoint': {
          'attempts': threePointAttempts,
          'makes': threePointMakes,
          'pct': (threePointPct * 100).toStringAsFixed(1),
          'frequency': (threePointFrequency * 100).toStringAsFixed(1),
        },
        'cornerThree': {
          'attempts': cornerThreeAttempts,
          'makes': cornerThreeMakes,
          'pct': (cornerThreePct * 100).toStringAsFixed(1),
        },
        'style': shootingStyle,
      };
}
