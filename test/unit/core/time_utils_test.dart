import 'package:flutter_test/flutter_test.dart';
import 'package:bdr_tournament_recorder/core/utils/time_utils.dart';

void main() {
  group('TimeUtils', () {
    group('formatGameClock', () {
      test('should format zero seconds', () {
        expect(TimeUtils.formatGameClock(0), '00:00');
      });

      test('should format seconds only', () {
        expect(TimeUtils.formatGameClock(45), '00:45');
        expect(TimeUtils.formatGameClock(5), '00:05');
        expect(TimeUtils.formatGameClock(59), '00:59');
      });

      test('should format minutes and seconds', () {
        expect(TimeUtils.formatGameClock(60), '01:00');
        expect(TimeUtils.formatGameClock(90), '01:30');
        expect(TimeUtils.formatGameClock(125), '02:05');
      });

      test('should format full quarter time (10 minutes)', () {
        expect(TimeUtils.formatGameClock(600), '10:00');
      });

      test('should format full quarter time (12 minutes)', () {
        expect(TimeUtils.formatGameClock(720), '12:00');
      });

      test('should pad single digit minutes', () {
        expect(TimeUtils.formatGameClock(300), '05:00');
        expect(TimeUtils.formatGameClock(540), '09:00');
      });
    });

    group('formatClock', () {
      test('should be alias for formatGameClock', () {
        expect(TimeUtils.formatClock(0), TimeUtils.formatGameClock(0));
        expect(TimeUtils.formatClock(125), TimeUtils.formatGameClock(125));
        expect(TimeUtils.formatClock(600), TimeUtils.formatGameClock(600));
      });
    });

    group('formatShotClock', () {
      test('should format seconds under 60 as plain number', () {
        expect(TimeUtils.formatShotClock(24), '24');
        expect(TimeUtils.formatShotClock(14), '14');
        expect(TimeUtils.formatShotClock(5), '5');
        expect(TimeUtils.formatShotClock(0), '0');
      });

      test('should format seconds at or above 60 with colon', () {
        expect(TimeUtils.formatShotClock(60), '1:00');
        expect(TimeUtils.formatShotClock(75), '1:15');
        expect(TimeUtils.formatShotClock(120), '2:00');
      });
    });

    group('formatMinutesPlayed', () {
      test('should format minutes under 60 with 분', () {
        expect(TimeUtils.formatMinutesPlayed(0), '0분');
        expect(TimeUtils.formatMinutesPlayed(30), '30분');
        expect(TimeUtils.formatMinutesPlayed(59), '59분');
      });

      test('should format hours and minutes', () {
        expect(TimeUtils.formatMinutesPlayed(60), '1시간 0분');
        expect(TimeUtils.formatMinutesPlayed(90), '1시간 30분');
        expect(TimeUtils.formatMinutesPlayed(150), '2시간 30분');
      });
    });

    group('parseGameClock', () {
      test('should parse valid MM:SS format', () {
        expect(TimeUtils.parseGameClock('00:00'), 0);
        expect(TimeUtils.parseGameClock('00:45'), 45);
        expect(TimeUtils.parseGameClock('01:30'), 90);
        expect(TimeUtils.parseGameClock('10:00'), 600);
        expect(TimeUtils.parseGameClock('12:00'), 720);
      });

      test('should return 0 for invalid format', () {
        expect(TimeUtils.parseGameClock('invalid'), 0);
        expect(TimeUtils.parseGameClock(''), 0);
        expect(TimeUtils.parseGameClock('1:2:3'), 0);
      });

      test('should handle non-numeric parts', () {
        expect(TimeUtils.parseGameClock('ab:cd'), 0);
      });
    });

    group('getQuarterName', () {
      test('should return correct quarter names for regulation', () {
        expect(TimeUtils.getQuarterName(1), '1Q');
        expect(TimeUtils.getQuarterName(2), '2Q');
        expect(TimeUtils.getQuarterName(3), '3Q');
        expect(TimeUtils.getQuarterName(4), '4Q');
      });

      test('should return correct overtime names', () {
        expect(TimeUtils.getQuarterName(5), 'OT1');
        expect(TimeUtils.getQuarterName(6), 'OT2');
        expect(TimeUtils.getQuarterName(7), 'OT3');
      });
    });

    group('getQuarterFullName', () {
      test('should return full quarter names for regulation', () {
        expect(TimeUtils.getQuarterFullName(1), '1쿼터');
        expect(TimeUtils.getQuarterFullName(2), '2쿼터');
        expect(TimeUtils.getQuarterFullName(3), '3쿼터');
        expect(TimeUtils.getQuarterFullName(4), '4쿼터');
      });

      test('should return full overtime names', () {
        expect(TimeUtils.getQuarterFullName(5), '연장 1');
        expect(TimeUtils.getQuarterFullName(6), '연장 2');
        expect(TimeUtils.getQuarterFullName(7), '연장 3');
      });
    });
  });
}
