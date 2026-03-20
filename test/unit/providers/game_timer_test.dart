import 'package:flutter_test/flutter_test.dart';
import 'package:bdr_tournament_recorder/presentation/widgets/timer/game_timer_widget.dart';

void main() {
  group('GameTimerState', () {
    test('should have correct default values', () {
      const state = GameTimerState();

      expect(state.quarter, 1);
      expect(state.gameClockSeconds, 600);
      expect(state.shotClockSeconds, 24);
      expect(state.isRunning, false);
      expect(state.isPaused, false);
      expect(state.maxQuarters, 4);
      expect(state.quarterMinutes, 10);
    });

    test('should create with custom values', () {
      const state = GameTimerState(
        quarter: 3,
        gameClockSeconds: 300,
        shotClockSeconds: 14,
        isRunning: true,
        isPaused: false,
        maxQuarters: 4,
        quarterMinutes: 12,
      );

      expect(state.quarter, 3);
      expect(state.gameClockSeconds, 300);
      expect(state.shotClockSeconds, 14);
      expect(state.isRunning, true);
      expect(state.isPaused, false);
      expect(state.maxQuarters, 4);
      expect(state.quarterMinutes, 12);
    });

    group('copyWith', () {
      test('should copy with all fields changed', () {
        const original = GameTimerState();
        final copied = original.copyWith(
          quarter: 2,
          gameClockSeconds: 300,
          shotClockSeconds: 14,
          isRunning: true,
          isPaused: true,
          maxQuarters: 5,
          quarterMinutes: 12,
        );

        expect(copied.quarter, 2);
        expect(copied.gameClockSeconds, 300);
        expect(copied.shotClockSeconds, 14);
        expect(copied.isRunning, true);
        expect(copied.isPaused, true);
        expect(copied.maxQuarters, 5);
        expect(copied.quarterMinutes, 12);
      });

      test('should preserve unchanged fields', () {
        const original = GameTimerState(
          quarter: 3,
          gameClockSeconds: 450,
          shotClockSeconds: 18,
        );
        final copied = original.copyWith(isRunning: true);

        expect(copied.quarter, 3);
        expect(copied.gameClockSeconds, 450);
        expect(copied.shotClockSeconds, 18);
        expect(copied.isRunning, true);
      });
    });

    group('computed properties', () {
      test('isOvertime should be true when quarter > maxQuarters', () {
        const regularState = GameTimerState(quarter: 4, maxQuarters: 4);
        const overtimeState = GameTimerState(quarter: 5, maxQuarters: 4);

        expect(regularState.isOvertime, false);
        expect(overtimeState.isOvertime, true);
      });

      test('isHalftime should be true at Q2 end', () {
        const halftimeState = GameTimerState(quarter: 2, gameClockSeconds: 0);
        const notHalftimeState = GameTimerState(quarter: 2, gameClockSeconds: 300);
        const wrongQuarterState = GameTimerState(quarter: 1, gameClockSeconds: 0);

        expect(halftimeState.isHalftime, true);
        expect(notHalftimeState.isHalftime, false);
        expect(wrongQuarterState.isHalftime, false);
      });

      test('isGameEnd should be true when overtime ends', () {
        const gameEndState = GameTimerState(quarter: 5, gameClockSeconds: 0, maxQuarters: 4);
        const notGameEndState = GameTimerState(quarter: 5, gameClockSeconds: 60, maxQuarters: 4);
        const regularQuarterState = GameTimerState(quarter: 4, gameClockSeconds: 0, maxQuarters: 4);

        expect(gameEndState.isGameEnd, true);
        expect(notGameEndState.isGameEnd, false);
        expect(regularQuarterState.isGameEnd, false);
      });

      test('shotClockViolation should be true when shotClock is 0', () {
        const violationState = GameTimerState(shotClockSeconds: 0);
        const noViolationState = GameTimerState(shotClockSeconds: 5);

        expect(violationState.shotClockViolation, true);
        expect(noViolationState.shotClockViolation, false);
      });
    });

    group('formattedGameClock', () {
      test('should format with leading zeros', () {
        const state1 = GameTimerState(gameClockSeconds: 605); // 10:05
        const state2 = GameTimerState(gameClockSeconds: 65); // 01:05
        const state3 = GameTimerState(gameClockSeconds: 5); // 00:05
        const state4 = GameTimerState(gameClockSeconds: 0); // 00:00

        expect(state1.formattedGameClock, '10:05');
        expect(state2.formattedGameClock, '01:05');
        expect(state3.formattedGameClock, '00:05');
        expect(state4.formattedGameClock, '00:00');
      });

      test('should handle full 10 minutes', () {
        const state = GameTimerState(gameClockSeconds: 600);
        expect(state.formattedGameClock, '10:00');
      });

      test('should handle 12 minute quarters', () {
        const state = GameTimerState(gameClockSeconds: 720);
        expect(state.formattedGameClock, '12:00');
      });
    });

    group('formattedShotClock', () {
      test('should format with leading zeros', () {
        const state1 = GameTimerState(shotClockSeconds: 24);
        const state2 = GameTimerState(shotClockSeconds: 9);
        const state3 = GameTimerState(shotClockSeconds: 0);

        expect(state1.formattedShotClock, '24');
        expect(state2.formattedShotClock, '09');
        expect(state3.formattedShotClock, '00');
      });
    });

    group('quarterLabel', () {
      test('should return Q1-Q4 for regular quarters', () {
        const q1 = GameTimerState(quarter: 1);
        const q2 = GameTimerState(quarter: 2);
        const q3 = GameTimerState(quarter: 3);
        const q4 = GameTimerState(quarter: 4);

        expect(q1.quarterLabel, 'Q1');
        expect(q2.quarterLabel, 'Q2');
        expect(q3.quarterLabel, 'Q3');
        expect(q4.quarterLabel, 'Q4');
      });

      test('should return OT for first overtime', () {
        const ot1 = GameTimerState(quarter: 5, maxQuarters: 4);
        expect(ot1.quarterLabel, 'OT');
      });

      test('should return OT2, OT3 for additional overtimes', () {
        const ot2 = GameTimerState(quarter: 6, maxQuarters: 4);
        const ot3 = GameTimerState(quarter: 7, maxQuarters: 4);

        expect(ot2.quarterLabel, 'OT2');
        expect(ot3.quarterLabel, 'OT3');
      });
    });
  });

  group('GameTimerNotifier', () {
    late GameTimerNotifier notifier;
    late List<GameTimerState> stateChanges;
    late List<int> quarterEnds;
    late int shotClockViolationCount;

    setUp(() {
      stateChanges = [];
      quarterEnds = [];
      shotClockViolationCount = 0;

      notifier = GameTimerNotifier(
        onStateChanged: (state) => stateChanges.add(state),
        onQuarterEnd: (quarter) => quarterEnds.add(quarter),
        onShotClockViolation: () => shotClockViolationCount++,
      );
    });

    tearDown(() {
      notifier.dispose();
    });

    test('should have default initial state', () {
      expect(notifier.state.quarter, 1);
      expect(notifier.state.gameClockSeconds, 600);
      expect(notifier.state.shotClockSeconds, 24);
      expect(notifier.state.isRunning, false);
    });

    group('initialize', () {
      test('should set quarter minutes and max quarters', () {
        notifier.initialize(quarterMinutes: 12, maxQuarters: 5);

        expect(notifier.state.quarterMinutes, 12);
        expect(notifier.state.maxQuarters, 5);
        expect(notifier.state.gameClockSeconds, 720); // 12 * 60
      });

      test('should use default values when not specified', () {
        notifier.initialize();

        expect(notifier.state.quarterMinutes, 10);
        expect(notifier.state.maxQuarters, 4);
        expect(notifier.state.gameClockSeconds, 600);
      });
    });

    group('start/pause/toggle', () {
      test('start should set isRunning to true', () {
        notifier.start();

        expect(notifier.state.isRunning, true);
        expect(notifier.state.isPaused, false);
        expect(stateChanges.length, 1);
      });

      test('start should not restart if already running', () {
        notifier.start();
        final firstCallCount = stateChanges.length;
        notifier.start();

        expect(stateChanges.length, firstCallCount);
      });

      test('pause should set isRunning to false and isPaused to true', () {
        notifier.start();
        notifier.pause();

        expect(notifier.state.isRunning, false);
        expect(notifier.state.isPaused, true);
      });

      test('toggle should start when paused', () {
        notifier.toggle();

        expect(notifier.state.isRunning, true);
      });

      test('toggle should pause when running', () {
        notifier.start();
        notifier.toggle();

        expect(notifier.state.isRunning, false);
        expect(notifier.state.isPaused, true);
      });
    });

    group('resetShotClock', () {
      test('should reset to 24 seconds by default', () {
        notifier.resetShotClock();

        expect(notifier.state.shotClockSeconds, 24);
      });

      test('should reset to specified seconds', () {
        notifier.resetShotClock(seconds: 14);

        expect(notifier.state.shotClockSeconds, 14);
      });

      test('resetShotClock14 should reset to 14 seconds', () {
        notifier.resetShotClock14();

        expect(notifier.state.shotClockSeconds, 14);
      });
    });

    group('nextQuarter', () {
      test('should increment quarter', () {
        notifier.nextQuarter();

        expect(notifier.state.quarter, 2);
      });

      test('should reset game clock to quarter minutes', () {
        notifier.initialize(quarterMinutes: 10);
        notifier.nextQuarter();

        expect(notifier.state.gameClockSeconds, 600);
      });

      test('should reset shot clock to 24', () {
        notifier.nextQuarter();

        expect(notifier.state.shotClockSeconds, 24);
      });

      test('should stop running', () {
        notifier.start();
        notifier.nextQuarter();

        expect(notifier.state.isRunning, false);
        expect(notifier.state.isPaused, false);
      });

      test('should set 5 minutes for overtime', () {
        notifier.initialize(quarterMinutes: 10, maxQuarters: 4);
        // Go to Q5 (OT)
        for (var i = 0; i < 4; i++) {
          notifier.nextQuarter();
        }

        expect(notifier.state.quarter, 5);
        expect(notifier.state.gameClockSeconds, 300); // 5 minutes
      });
    });

    group('startOvertime', () {
      test('should start first overtime', () {
        notifier.initialize(maxQuarters: 4);
        notifier.startOvertime();

        expect(notifier.state.quarter, 5);
        expect(notifier.state.gameClockSeconds, 300); // 5 minutes default
      });

      test('should allow custom overtime minutes', () {
        notifier.initialize(maxQuarters: 4);
        notifier.startOvertime(minutes: 3);

        expect(notifier.state.gameClockSeconds, 180); // 3 minutes
      });

      test('should start next overtime when already in OT', () {
        notifier.initialize(maxQuarters: 4);
        notifier.startOvertime(); // OT1
        notifier.startOvertime(); // OT2

        expect(notifier.state.quarter, 6);
      });
    });

    group('adjustGameClock', () {
      test('should add seconds', () {
        notifier.initialize(quarterMinutes: 10);
        notifier.setGameClock(300);
        notifier.adjustGameClock(60);

        expect(notifier.state.gameClockSeconds, 360);
      });

      test('should subtract seconds', () {
        notifier.setGameClock(300);
        notifier.adjustGameClock(-60);

        expect(notifier.state.gameClockSeconds, 240);
      });

      test('should clamp to 0', () {
        notifier.setGameClock(30);
        notifier.adjustGameClock(-60);

        expect(notifier.state.gameClockSeconds, 0);
      });

      test('should clamp to max', () {
        notifier.initialize(quarterMinutes: 10);
        notifier.setGameClock(590);
        notifier.adjustGameClock(60);

        expect(notifier.state.gameClockSeconds, 600);
      });
    });

    group('setGameClock', () {
      test('should set exact seconds', () {
        notifier.setGameClock(450);

        expect(notifier.state.gameClockSeconds, 450);
        expect(stateChanges.isNotEmpty, true);
      });
    });

    group('setQuarter', () {
      test('should set exact quarter', () {
        notifier.setQuarter(3);

        expect(notifier.state.quarter, 3);
        expect(stateChanges.isNotEmpty, true);
      });
    });
  });
}
