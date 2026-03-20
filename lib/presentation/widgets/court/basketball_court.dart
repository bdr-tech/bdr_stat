import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../core/theme/app_theme.dart';

/// NBA 하프코트 25-zone 슛 차트
class BasketballCourt extends StatelessWidget {
  const BasketballCourt({
    super.key,
    this.onCourtTap,
    this.shots = const [],
    this.highlightZone,
    this.showZones = false,
    this.isLeftSide = true,
  });

  /// 코트 터치 시 콜백 (x, y: 0-100 범위, zone: 1-25)
  final void Function(double x, double y, int zone)? onCourtTap;

  /// 표시할 슛 목록
  final List<ShotMarker> shots;

  /// 하이라이트할 존 번호
  final int? highlightZone;

  /// 존 경계선 표시 여부
  final bool showZones;

  /// 왼쪽 골대 기준 (true) 또는 오른쪽 골대 기준 (false)
  final bool isLeftSide;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: CourtDimensions.halfCourtAspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapDown: (details) => _handleTap(details, constraints),
            child: CustomPaint(
              painter: _CourtPainter(
                shots: shots,
                highlightZone: highlightZone,
                showZones: showZones,
                isLeftSide: isLeftSide,
              ),
              size: Size(constraints.maxWidth, constraints.maxHeight),
            ),
          );
        },
      ),
    );
  }

  void _handleTap(TapDownDetails details, BoxConstraints constraints) {
    if (onCourtTap == null) return;

    final x = (details.localPosition.dx / constraints.maxWidth) * 100;
    final y = (details.localPosition.dy / constraints.maxHeight) * 100;
    final zone = CourtZones.getZone(x, y, isLeftSide);

    onCourtTap!(x, y, zone);
  }
}

/// 슛 마커 데이터
class ShotMarker {
  final double x;
  final double y;
  final bool isMade;
  final bool isThreePointer;

  const ShotMarker({
    required this.x,
    required this.y,
    required this.isMade,
    this.isThreePointer = false,
  });
}

/// 코트 치수 상수 (NBA 규격 기준, 비율로 변환)
class CourtDimensions {
  CourtDimensions._();

  // NBA 하프코트: 47ft x 50ft
  static const double halfCourtAspectRatio = 47 / 50;

  // 3점선 거리: 23.75ft (코너: 22ft)
  static const double threePointRadius = 50.5; // 비율 (%)
  static const double cornerThreeDistance = 46.8; // 비율 (%)
  static const double cornerThreeHeight = 14.0; // 비율 (%)

  // 페인트 영역: 16ft x 19ft
  static const double paintWidth = 34.0; // 비율 (%)
  static const double paintHeight = 40.4; // 비율 (%)

  // 자유투 라인
  static const double freeThrowLineDistance = 40.4; // 비율 (%)

  // 림 위치
  static const double rimX = 5.3; // 비율 (%)
  static const double rimY = 50.0; // 중앙

  // 백보드
  static const double backboardX = 2.1; // 비율 (%)
}

/// 25개 존 정의 (NBA 표준)
class CourtZones {
  CourtZones._();

  /// 좌표로 존 번호 계산 (1-25)
  /// 왼쪽 림 기준 좌표계
  static int getZone(double x, double y, bool isLeftSide) {
    // 오른쪽 림이면 x 좌표 반전
    final adjustedX = isLeftSide ? x : (100 - x);
    final adjustedY = y;

    // 림까지 거리 계산
    final distanceToRim = _distanceToRim(adjustedX, adjustedY);

    // 각도 계산 (림 기준)
    final angle = _angleFromRim(adjustedX, adjustedY);

    // 존 결정
    return _determineZone(distanceToRim, angle, adjustedX, adjustedY);
  }

  static double _distanceToRim(double x, double y) {
    const rimX = CourtDimensions.rimX;
    const rimY = CourtDimensions.rimY;
    return math.sqrt(math.pow(x - rimX, 2) + math.pow(y - rimY, 2));
  }

  static double _angleFromRim(double x, double y) {
    const rimX = CourtDimensions.rimX;
    const rimY = CourtDimensions.rimY;
    return math.atan2(y - rimY, x - rimX) * 180 / math.pi;
  }

  static int _determineZone(double distance, double angle, double x, double y) {
    // Zone 1: 림 근처 (Restricted Area)
    if (distance < 8) return 1;

    // Zone 2-5: 페인트 영역
    if (x < CourtDimensions.paintHeight) {
      if (y < 30) return 2; // 페인트 좌측 하단
      if (y < 50) return 3; // 페인트 좌측 상단
      if (y < 70) return 4; // 페인트 우측 상단
      return 5; // 페인트 우측 하단
    }

    // 3점선 안쪽 미드레인지
    final isInsideThreePoint = _isInsideThreePointLine(x, y);

    if (isInsideThreePoint) {
      // Zone 6-10: 미드레인지 (3점선 안쪽)
      if (angle < -60) return 6; // 좌측 베이스라인
      if (angle < -20) return 7; // 좌측 엘보우
      if (angle < 20) return 8; // 탑 키
      if (angle < 60) return 9; // 우측 엘보우
      return 10; // 우측 베이스라인
    }

    // 3점선 바깥
    // Zone 11-15: 코너 3점 및 윙 3점
    if (y < CourtDimensions.cornerThreeHeight) return 11; // 좌측 코너
    if (y > (100 - CourtDimensions.cornerThreeHeight)) return 15; // 우측 코너

    if (angle < -45) return 12; // 좌측 윙
    if (angle < 0) return 13; // 좌측 탑
    if (angle < 45) return 14; // 우측 탑
    return 12; // 우측 윙 (fallback)

    // Zone 16-25: 딥 3점 (거리 기반 세분화)
    // 실제 구현에서는 더 세밀한 존 분류 필요
  }

  static bool _isInsideThreePointLine(double x, double y) {
    // 코너 3점 영역 체크
    if (y < CourtDimensions.cornerThreeHeight ||
        y > (100 - CourtDimensions.cornerThreeHeight)) {
      return x < CourtDimensions.cornerThreeDistance;
    }

    // 호 영역 체크
    final distanceToRim = _distanceToRim(x, y);
    return distanceToRim < CourtDimensions.threePointRadius;
  }

  /// 존별 이름
  static String getZoneName(int zone) {
    switch (zone) {
      case 1:
        return '림 근처';
      case 2:
        return '페인트 좌하';
      case 3:
        return '페인트 좌상';
      case 4:
        return '페인트 우상';
      case 5:
        return '페인트 우하';
      case 6:
        return '좌측 베이스라인';
      case 7:
        return '좌측 엘보우';
      case 8:
        return '탑 키';
      case 9:
        return '우측 엘보우';
      case 10:
        return '우측 베이스라인';
      case 11:
        return '좌측 코너 3점';
      case 12:
        return '좌측 윙 3점';
      case 13:
        return '좌측 탑 3점';
      case 14:
        return '우측 탑 3점';
      case 15:
        return '우측 코너 3점';
      default:
        return '존 $zone';
    }
  }

  /// 존이 3점 영역인지 확인
  static bool isThreePointZone(int zone) {
    return zone >= 11 && zone <= 25;
  }
}

/// 코트 페인터
class _CourtPainter extends CustomPainter {
  final List<ShotMarker> shots;
  final int? highlightZone;
  final bool showZones;
  final bool isLeftSide;

  _CourtPainter({
    required this.shots,
    this.highlightZone,
    this.showZones = false,
    this.isLeftSide = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final courtPaint = Paint()
      ..color = AppTheme.courtColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppTheme.courtLineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final threePointPaint = Paint()
      ..color = AppTheme.threePointLineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 코트 배경
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), courtPaint);

    // 코트 경계선
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      linePaint,
    );

    // 림 위치 계산
    final rimX = isLeftSide
        ? size.width * CourtDimensions.rimX / 100
        : size.width * (1 - CourtDimensions.rimX / 100);
    final rimY = size.height * CourtDimensions.rimY / 100;

    // 페인트 영역
    _drawPaintArea(canvas, size, linePaint, rimX);

    // 자유투 원
    _drawFreeThrowCircle(canvas, size, linePaint, rimX);

    // 3점선
    _drawThreePointLine(canvas, size, threePointPaint, rimX);

    // 림
    _drawRim(canvas, rimX, rimY, linePaint);

    // 백보드
    _drawBackboard(canvas, size, rimX, rimY, linePaint);

    // 존 경계선 (디버그용)
    if (showZones) {
      _drawZoneBoundaries(canvas, size);
    }

    // 슛 마커
    _drawShots(canvas, size);
  }

  void _drawPaintArea(Canvas canvas, Size size, Paint paint, double rimX) {
    final paintWidth = size.height * CourtDimensions.paintWidth / 100;
    final paintHeight = size.width * CourtDimensions.paintHeight / 100;

    final left = isLeftSide ? 0.0 : size.width - paintHeight;
    final top = (size.height - paintWidth) / 2;

    canvas.drawRect(
      Rect.fromLTWH(left, top, paintHeight, paintWidth),
      paint,
    );
  }

  void _drawFreeThrowCircle(
      Canvas canvas, Size size, Paint paint, double rimX) {
    final centerX = isLeftSide
        ? size.width * CourtDimensions.freeThrowLineDistance / 100
        : size.width * (1 - CourtDimensions.freeThrowLineDistance / 100);
    final centerY = size.height / 2;
    final radius = size.height * 12 / 100; // 6ft radius

    canvas.drawCircle(Offset(centerX, centerY), radius, paint);
  }

  void _drawThreePointLine(
      Canvas canvas, Size size, Paint paint, double rimX) {
    final path = Path();

    // 코너 3점선 높이
    final cornerHeight = size.height * CourtDimensions.cornerThreeHeight / 100;
    final cornerDistance =
        size.width * CourtDimensions.cornerThreeDistance / 100;

    // 3점 호 반지름
    final arcRadius = size.width * CourtDimensions.threePointRadius / 100;

    if (isLeftSide) {
      // 왼쪽 코너 직선
      path.moveTo(0, cornerHeight);
      path.lineTo(cornerDistance, cornerHeight);

      // 호
      final rimY = size.height / 2;
      final startAngle = math.asin((rimY - cornerHeight) / arcRadius);
      final sweepAngle = math.pi - 2 * startAngle;

      path.arcTo(
        Rect.fromCircle(center: Offset(rimX, rimY), radius: arcRadius),
        -math.pi / 2 - startAngle,
        -sweepAngle,
        false,
      );

      // 오른쪽 코너 직선
      path.lineTo(0, size.height - cornerHeight);
    } else {
      // 오른쪽 림 기준
      path.moveTo(size.width, cornerHeight);
      path.lineTo(size.width - cornerDistance, cornerHeight);

      final rimY = size.height / 2;
      final startAngle = math.asin((rimY - cornerHeight) / arcRadius);
      final sweepAngle = math.pi - 2 * startAngle;

      path.arcTo(
        Rect.fromCircle(center: Offset(rimX, rimY), radius: arcRadius),
        -math.pi / 2 + startAngle,
        sweepAngle,
        false,
      );

      path.lineTo(size.width, size.height - cornerHeight);
    }

    canvas.drawPath(path, paint);
  }

  void _drawRim(Canvas canvas, double rimX, double rimY, Paint paint) {
    final rimPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset(rimX, rimY), 8, rimPaint);
  }

  void _drawBackboard(
      Canvas canvas, Size size, double rimX, double rimY, Paint paint) {
    final backboardPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final backboardX = isLeftSide
        ? size.width * CourtDimensions.backboardX / 100
        : size.width * (1 - CourtDimensions.backboardX / 100);

    canvas.drawLine(
      Offset(backboardX, rimY - 30),
      Offset(backboardX, rimY + 30),
      backboardPaint,
    );
  }

  void _drawZoneBoundaries(Canvas canvas, Size size) {
    // TODO: 존 경계선 그리기 (디버그용)
    // final zonePaint = Paint()
    //   ..color = Colors.white.withValues(alpha: 0.3)
    //   ..style = PaintingStyle.stroke
    //   ..strokeWidth = 1;
  }

  void _drawShots(Canvas canvas, Size size) {
    for (final shot in shots) {
      final x = shot.x * size.width / 100;
      final y = shot.y * size.height / 100;

      final markerPaint = Paint()
        ..color = shot.isMade ? AppTheme.shotMadeColor : AppTheme.shotMissedColor
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      // 마커 그리기
      if (shot.isMade) {
        // 성공: 채워진 원
        canvas.drawCircle(Offset(x, y), 8, markerPaint);
        canvas.drawCircle(Offset(x, y), 8, borderPaint);
      } else {
        // 실패: X 표시
        final xPaint = Paint()
          ..color = AppTheme.shotMissedColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

        canvas.drawLine(
          Offset(x - 6, y - 6),
          Offset(x + 6, y + 6),
          xPaint,
        );
        canvas.drawLine(
          Offset(x + 6, y - 6),
          Offset(x - 6, y + 6),
          xPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CourtPainter oldDelegate) {
    return shots != oldDelegate.shots ||
        highlightZone != oldDelegate.highlightZone ||
        showZones != oldDelegate.showZones;
  }
}
