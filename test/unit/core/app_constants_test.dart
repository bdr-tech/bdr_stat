import 'package:flutter_test/flutter_test.dart';
import 'package:bdr_tournament_recorder/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('should have correct app info', () {
      expect(AppConstants.appName, 'BDR Tournament Recorder');
      expect(AppConstants.appVersion, '1.0.0');
    });

    test('should have correct timeout values', () {
      expect(AppConstants.apiTimeout, const Duration(seconds: 30));
      expect(AppConstants.autoSaveInterval, const Duration(seconds: 30));
    });

    test('should have correct undo stack size', () {
      expect(AppConstants.maxUndoStackSize, 10);
    });
  });

  group('GameRulesDefaults', () {
    group('time constants', () {
      test('should have correct quarter time', () {
        expect(GameRulesDefaults.quarterMinutes, 10);
        expect(GameRulesDefaults.quarterSeconds, 600);
      });

      test('should have correct overtime time', () {
        expect(GameRulesDefaults.overtimeMinutes, 5);
        expect(GameRulesDefaults.overtimeSeconds, 300);
      });

      test('should have correct shot clock', () {
        expect(GameRulesDefaults.shotClockSeconds, 24);
        expect(GameRulesDefaults.shotClockAfterOffensiveRebound, 14);
      });
    });

    group('foul constants', () {
      test('should have correct bonus threshold', () {
        expect(GameRulesDefaults.bonusThreshold, 5);
      });

      test('should have correct foul out limit', () {
        expect(GameRulesDefaults.foulOutLimit, 5);
      });
    });

    group('timeout constants', () {
      test('should have correct timeout values', () {
        expect(GameRulesDefaults.timeoutsPerHalf, 2);
        expect(GameRulesDefaults.totalTimeouts, 4);
      });
    });
  });

  group('ActionTypes', () {
    test('should have correct action type strings', () {
      expect(ActionTypes.shot, 'shot');
      expect(ActionTypes.rebound, 'rebound');
      expect(ActionTypes.assist, 'assist');
      expect(ActionTypes.steal, 'steal');
      expect(ActionTypes.block, 'block');
      expect(ActionTypes.turnover, 'turnover');
      expect(ActionTypes.foul, 'foul');
      expect(ActionTypes.substitution, 'substitution');
      expect(ActionTypes.timeout, 'timeout');
      expect(ActionTypes.quarterStart, 'quarter_start');
      expect(ActionTypes.quarterEnd, 'quarter_end');
      expect(ActionTypes.jumpBall, 'jump_ball');
    });
  });

  group('ActionSubtypes', () {
    group('shot subtypes', () {
      test('should have correct shot type strings', () {
        expect(ActionSubtypes.twoPoint, '2pt');
        expect(ActionSubtypes.threePoint, '3pt');
        expect(ActionSubtypes.freeThrow, 'ft');
      });
    });

    group('rebound subtypes', () {
      test('should have correct rebound type strings', () {
        expect(ActionSubtypes.offensive, 'offensive');
        expect(ActionSubtypes.defensive, 'defensive');
      });
    });

    group('foul subtypes', () {
      test('should have correct foul type strings', () {
        expect(ActionSubtypes.personal, 'personal');
        expect(ActionSubtypes.shooting, 'shooting');
        expect(ActionSubtypes.offensiveFoul, 'offensive');
        expect(ActionSubtypes.technical, 'technical');
        expect(ActionSubtypes.flagrant, 'flagrant');
        expect(ActionSubtypes.unsportsmanlike, 'unsportsmanlike');
        expect(ActionSubtypes.andOne, 'and_one');
      });
    });
  });

  group('MatchStatus', () {
    test('should have correct match status strings', () {
      expect(MatchStatus.scheduled, 'scheduled');
      expect(MatchStatus.inProgress, 'in_progress');
      expect(MatchStatus.completed, 'completed');
      expect(MatchStatus.bye, 'bye');
      expect(MatchStatus.pending, 'pending');
      expect(MatchStatus.cancelled, 'cancelled');
      // 레거시 호환
      expect(MatchStatus.warmup, 'warmup');
      expect(MatchStatus.halftime, 'halftime');
    });

    test('isActive and isDone helpers', () {
      expect(MatchStatus.isActive('in_progress'), true);
      // ignore: deprecated_member_use_from_same_package
      expect(MatchStatus.isActive('live'), true);
      expect(MatchStatus.isActive('scheduled'), false);
      expect(MatchStatus.isDone('completed'), true);
      // ignore: deprecated_member_use_from_same_package
      expect(MatchStatus.isDone('finished'), true);
      expect(MatchStatus.isDone('in_progress'), false);
    });
  });

  group('Positions', () {
    test('should have correct position abbreviations', () {
      expect(Positions.pg, 'PG');
      expect(Positions.sg, 'SG');
      expect(Positions.sf, 'SF');
      expect(Positions.pf, 'PF');
      expect(Positions.c, 'C');
    });

    test('should have all positions in list', () {
      expect(Positions.all, ['PG', 'SG', 'SF', 'PF', 'C']);
      expect(Positions.all.length, 5);
    });

    group('getName', () {
      test('should return correct Korean names', () {
        expect(Positions.getName('PG'), '포인트가드');
        expect(Positions.getName('SG'), '슈팅가드');
        expect(Positions.getName('SF'), '스몰포워드');
        expect(Positions.getName('PF'), '파워포워드');
        expect(Positions.getName('C'), '센터');
      });

      test('should return input for unknown position', () {
        expect(Positions.getName('Unknown'), 'Unknown');
        expect(Positions.getName(''), '');
      });
    });
  });
}
