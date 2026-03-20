import 'dart:math' as math;
import '../constants/app_constants.dart';

/// 농구 코트 좌표 및 존 관련 유틸리티
class CourtUtils {
  CourtUtils._();

  // NBA 코트 실제 치수 (feet)
  static const double courtLength = 94.0;
  static const double courtWidth = 50.0;
  static const double threePointDistance = 23.75; // 3점 라인 거리 (코너 제외)
  static const double cornerThreeDistance = 22.0; // 코너 3점 거리
  static const double restrictedAreaRadius = 4.0;
  static const double freeThrowLineDistance = 15.0;

  // 코트 좌표는 0-100 퍼센트로 정규화
  // X: 0 = 왼쪽 베이스라인, 100 = 오른쪽 베이스라인
  // Y: 0 = 하단, 100 = 상단

  /// 좌표를 실제 거리(feet)로 변환
  static double getDistanceFromBasket(double x, double y) {
    // 바스켓 위치: (5.25, 50) - 베이스라인에서 5.25 feet, 코트 중앙
    const basketX = (5.25 / courtLength) * 100;
    const basketY = 50.0;

    final dx = (x - basketX) / 100 * courtLength;
    final dy = (y - basketY) / 100 * courtWidth;

    return math.sqrt(dx * dx + dy * dy);
  }

  /// 좌표를 NBA 25-zone으로 변환
  static int getZoneFromCoordinates(double x, double y) {
    final distance = getDistanceFromBasket(x, y);

    // 제한구역 (4 feet 이내)
    if (distance <= restrictedAreaRadius) {
      return CourtZones.restrictedArea;
    }

    // 3점 라인 체크
    final isThreePointer = _isThreePointer(x, y, distance);

    if (isThreePointer) {
      return _getThreePointZone(x, y);
    }

    // 페인트존 (제한구역 ~ 자유투 라인)
    if (_isInPaint(x, y)) {
      return _getPaintZone(x, y);
    }

    // 미드레인지
    return _getMidRangeZone(x, y);
  }

  /// 3점 라인 밖인지 확인
  static bool _isThreePointer(double x, double y, double distance) {
    // 코너 영역 체크 (y가 코트 끝 쪽)
    if (y < 10 || y > 90) {
      return distance >= cornerThreeDistance;
    }
    return distance >= threePointDistance;
  }

  /// 페인트존 내부인지 확인
  static bool _isInPaint(double x, double y) {
    // 페인트존: 베이스라인에서 자유투 라인까지, 코트 중앙 ±6 feet
    const paintWidth = 12.0; // 페인트 너비 (12 feet)
    const paintWidthPercent = (paintWidth / courtWidth) * 100;

    final paintLeft = 50 - paintWidthPercent / 2;
    final paintRight = 50 + paintWidthPercent / 2;

    const paintEndX = (freeThrowLineDistance / courtLength) * 100;

    return x <= paintEndX && y >= paintLeft && y <= paintRight;
  }

  /// 페인트존 세부 영역
  static int _getPaintZone(double x, double y) {
    if (y < 40) return CourtZones.paintLeft;
    if (y > 60) return CourtZones.paintRight;
    return CourtZones.paintCenter;
  }

  /// 미드레인지 세부 영역
  static int _getMidRangeZone(double x, double y) {
    // 베이스라인 근처
    if (x < 15) {
      if (y < 30) return CourtZones.midRangeLeftBaseline;
      if (y > 70) return CourtZones.midRangeRightBaseline;
    }

    // 윙
    if (y < 25) return CourtZones.midRangeLeftWing;
    if (y > 75) return CourtZones.midRangeRightWing;

    // 엘보
    if (y < 40) return CourtZones.midRangeLeftElbow;
    if (y > 60) return CourtZones.midRangeRightElbow;

    // 탑키
    return CourtZones.midRangeTopKey;
  }

  /// 3점 세부 영역
  static int _getThreePointZone(double x, double y) {
    // 코너
    if (x < 15) {
      if (y < 15) return CourtZones.threePointLeftCorner;
      if (y > 85) return CourtZones.threePointRightCorner;
    }

    // 윙
    if (y < 20) return CourtZones.threePointLeftWing;
    if (y > 80) return CourtZones.threePointRightWing;

    // 탑
    if (y < 40) return CourtZones.threePointLeftTop;
    if (y > 60) return CourtZones.threePointRightTop;
    return CourtZones.threePointTopCenter;
  }

  /// 슛 종류 결정 (2점 vs 3점)
  static String getShotType(double x, double y) {
    final distance = getDistanceFromBasket(x, y);
    final isThree = _isThreePointer(x, y, distance);
    return isThree ? ActionSubtypes.threePoint : ActionSubtypes.twoPoint;
  }

  /// 반대편 코트로 좌표 변환 (코트 반전)
  static (double, double) mirrorCoordinates(double x, double y) {
    return (100 - x, 100 - y);
  }
}
