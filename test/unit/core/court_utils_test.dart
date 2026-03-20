import 'package:flutter_test/flutter_test.dart';
import 'package:bdr_tournament_recorder/core/utils/court_utils.dart';
import 'package:bdr_tournament_recorder/core/constants/app_constants.dart';

void main() {
  group('CourtUtils', () {
    group('getDistanceFromBasket', () {
      test('should return 0 for basket position', () {
        // Basket is at approximately x=5.6 (5.25 feet from baseline in % terms)
        const basketX = (5.25 / 94.0) * 100;
        const basketY = 50.0;
        final distance = CourtUtils.getDistanceFromBasket(basketX, basketY);
        expect(distance, closeTo(0, 0.5));
      });

      test('should return correct distance for free throw line', () {
        // Free throw line is 15 feet from basket
        // basketX = (5.25 / 94.0) * 100; (reference point)
        const ftLineX = ((5.25 + 15) / 94.0) * 100;
        const y = 50.0; // Center court
        final distance = CourtUtils.getDistanceFromBasket(ftLineX, y);
        expect(distance, closeTo(15.0, 1.0));
      });
    });

    group('getZoneFromCoordinates', () {
      test('should return restricted area for close shots', () {
        // Very close to basket (within 4 feet)
        final zone = CourtUtils.getZoneFromCoordinates(3, 50);
        expect(zone, CourtZones.restrictedArea);
      });

      test('should return 3-point zone for far corner shots', () {
        // Left corner 3-point shot
        final leftCorner = CourtUtils.getZoneFromCoordinates(8, 5);
        expect(leftCorner, CourtZones.threePointLeftCorner);

        // Right corner 3-point shot
        final rightCorner = CourtUtils.getZoneFromCoordinates(8, 95);
        expect(rightCorner, CourtZones.threePointRightCorner);
      });

      test('should return mid-range for moderate distance shots', () {
        // Mid-range shot near baseline left
        final zone = CourtUtils.getZoneFromCoordinates(10, 20);
        expect(
          zone == CourtZones.midRangeLeftBaseline ||
              zone == CourtZones.midRangeLeftWing,
          true,
        );
      });
    });

    group('getShotType', () {
      test('should return 2pt for shots inside the arc', () {
        // Close shot
        expect(CourtUtils.getShotType(5, 50), ActionSubtypes.twoPoint);

        // Mid-range shot
        expect(CourtUtils.getShotType(15, 50), ActionSubtypes.twoPoint);
      });

      test('should return 3pt for corner three', () {
        // Left corner three
        expect(CourtUtils.getShotType(5, 5), ActionSubtypes.threePoint);

        // Right corner three
        expect(CourtUtils.getShotType(5, 95), ActionSubtypes.threePoint);
      });

      test('should return 3pt for top of arc shots', () {
        // Top center three
        expect(CourtUtils.getShotType(35, 50), ActionSubtypes.threePoint);
      });
    });

    group('mirrorCoordinates', () {
      test('should mirror coordinates correctly', () {
        final (newX, newY) = CourtUtils.mirrorCoordinates(25, 30);
        expect(newX, 75);
        expect(newY, 70);
      });

      test('should handle corner cases', () {
        final (x1, y1) = CourtUtils.mirrorCoordinates(0, 0);
        expect(x1, 100);
        expect(y1, 100);

        final (x2, y2) = CourtUtils.mirrorCoordinates(100, 100);
        expect(x2, 0);
        expect(y2, 0);
      });

      test('should handle center of court', () {
        final (x, y) = CourtUtils.mirrorCoordinates(50, 50);
        expect(x, 50);
        expect(y, 50);
      });
    });

    group('constants', () {
      test('should have correct court dimensions', () {
        expect(CourtUtils.courtLength, 94.0);
        expect(CourtUtils.courtWidth, 50.0);
      });

      test('should have correct 3-point distances', () {
        expect(CourtUtils.threePointDistance, 23.75);
        expect(CourtUtils.cornerThreeDistance, 22.0);
      });

      test('should have correct restricted area radius', () {
        expect(CourtUtils.restrictedAreaRadius, 4.0);
      });

      test('should have correct free throw line distance', () {
        expect(CourtUtils.freeThrowLineDistance, 15.0);
      });
    });
  });

  group('CourtZones', () {
    group('isThreePointer', () {
      test('should return true for 3-point zones', () {
        expect(CourtZones.isThreePointer(CourtZones.threePointLeftCorner), true);
        expect(CourtZones.isThreePointer(CourtZones.threePointLeftWing), true);
        expect(CourtZones.isThreePointer(CourtZones.threePointLeftTop), true);
        expect(CourtZones.isThreePointer(CourtZones.threePointTopCenter), true);
        expect(CourtZones.isThreePointer(CourtZones.threePointRightTop), true);
        expect(CourtZones.isThreePointer(CourtZones.threePointRightWing), true);
        expect(CourtZones.isThreePointer(CourtZones.threePointRightCorner), true);
      });

      test('should return false for non-3-point zones', () {
        expect(CourtZones.isThreePointer(CourtZones.restrictedArea), false);
        expect(CourtZones.isThreePointer(CourtZones.paintLeft), false);
        expect(CourtZones.isThreePointer(CourtZones.paintCenter), false);
        expect(CourtZones.isThreePointer(CourtZones.midRangeLeftBaseline), false);
        expect(CourtZones.isThreePointer(CourtZones.midRangeTopKey), false);
        expect(CourtZones.isThreePointer(CourtZones.backcourt), false);
      });
    });

    group('getZoneName', () {
      test('should return correct names for paint zones', () {
        expect(CourtZones.getZoneName(CourtZones.restrictedArea), '제한구역');
        expect(CourtZones.getZoneName(CourtZones.paintLeft), '페인트 좌측');
        expect(CourtZones.getZoneName(CourtZones.paintCenter), '페인트 중앙');
        expect(CourtZones.getZoneName(CourtZones.paintRight), '페인트 우측');
      });

      test('should return correct names for mid-range zones', () {
        expect(
          CourtZones.getZoneName(CourtZones.midRangeLeftBaseline),
          '미드레인지 좌측 베이스라인',
        );
        expect(CourtZones.getZoneName(CourtZones.midRangeTopKey), '미드레인지 탑키');
      });

      test('should return correct names for 3-point zones', () {
        expect(CourtZones.getZoneName(CourtZones.threePointLeftCorner), '3점 좌측 코너');
        expect(CourtZones.getZoneName(CourtZones.threePointTopCenter), '3점 탑 중앙');
        expect(CourtZones.getZoneName(CourtZones.threePointRightCorner), '3점 우측 코너');
      });

      test('should return correct name for backcourt', () {
        expect(CourtZones.getZoneName(CourtZones.backcourt), '백코트');
      });

      test('should return default name for unknown zone', () {
        expect(CourtZones.getZoneName(99), 'Zone 99');
      });
    });

    group('zone constants', () {
      test('should have correct zone values', () {
        expect(CourtZones.restrictedArea, 1);
        expect(CourtZones.paintLeft, 2);
        expect(CourtZones.paintCenter, 3);
        expect(CourtZones.paintRight, 4);
      });

      test('should have 3-point zones in range 12-18', () {
        expect(CourtZones.threePointLeftCorner, 12);
        expect(CourtZones.threePointRightCorner, 18);
      });

      test('should have backcourt at 25', () {
        expect(CourtZones.backcourt, 25);
      });
    });
  });
}
