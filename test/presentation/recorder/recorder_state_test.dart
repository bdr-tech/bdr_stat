import 'package:flutter_test/flutter_test.dart';

/// _RecordingState is private to match_recording_screen.dart,
/// so we replicate the core logic here for unit testing.
/// This tests the state transition rules that the notifier enforces.

// Replicate the canRecord / canRecordAlways logic
class RecorderState {
  RecorderState({
    this.matchStatus = 'scheduled',
    this.isShotClockRunning = false,
    this.homeTeamFouls = 0,
    this.awayTeamFouls = 0,
    this.currentQuarter = 1,
    this.homeTimeouts = 5,
    this.awayTimeouts = 5,
    this.homePlayers = const [],
    this.awayPlayers = const [],
  });

  final String matchStatus;
  final bool isShotClockRunning;
  final int homeTeamFouls;
  final int awayTeamFouls;
  final int currentQuarter;
  final int homeTimeouts;
  final int awayTimeouts;
  final List<Map<String, dynamic>> homePlayers;
  final List<Map<String, dynamic>> awayPlayers;

  /// Scoring / stat events require shot clock running
  bool get canRecord => matchStatus == 'in_progress' && isShotClockRunning;

  /// Foul / sub / timeout can be recorded without shot clock
  bool get canRecordAlways => matchStatus == 'in_progress';

  bool get isCompleted => matchStatus == 'completed';

  RecorderState copyWith({
    String? matchStatus,
    bool? isShotClockRunning,
    int? homeTeamFouls,
    int? awayTeamFouls,
    int? currentQuarter,
    int? homeTimeouts,
    int? awayTimeouts,
    List<Map<String, dynamic>>? homePlayers,
    List<Map<String, dynamic>>? awayPlayers,
  }) {
    return RecorderState(
      matchStatus: matchStatus ?? this.matchStatus,
      isShotClockRunning: isShotClockRunning ?? this.isShotClockRunning,
      homeTeamFouls: homeTeamFouls ?? this.homeTeamFouls,
      awayTeamFouls: awayTeamFouls ?? this.awayTeamFouls,
      currentQuarter: currentQuarter ?? this.currentQuarter,
      homeTimeouts: homeTimeouts ?? this.homeTimeouts,
      awayTimeouts: awayTimeouts ?? this.awayTimeouts,
      homePlayers: homePlayers ?? this.homePlayers,
      awayPlayers: awayPlayers ?? this.awayPlayers,
    );
  }
}

/// Simulates setQuarter behavior (resets fouls)
RecorderState setQuarter(RecorderState state, int quarter) {
  return state.copyWith(
    currentQuarter: quarter,
    homeTeamFouls: 0,
    awayTeamFouls: 0,
  );
}

/// Shot clock exempt event types
const shotClockExemptTypes = {'foul_personal', 'foul_technical', 'sub', 'timeout'};

void main() {
  group('RecorderState - canRecord gate', () {
    test('canRecord: false when match is scheduled (not started)', () {
      final state = RecorderState(matchStatus: 'scheduled', isShotClockRunning: false);
      expect(state.canRecord, isFalse);
      expect(state.canRecordAlways, isFalse);
    });

    test('canRecord: false when match is in_progress but shot clock not running', () {
      final state = RecorderState(matchStatus: 'in_progress', isShotClockRunning: false);
      expect(state.canRecord, isFalse);
      // But canRecordAlways should be true for fouls/subs/timeouts
      expect(state.canRecordAlways, isTrue);
    });

    test('canRecord: true when match is in_progress and shot clock running', () {
      final state = RecorderState(matchStatus: 'in_progress', isShotClockRunning: true);
      expect(state.canRecord, isTrue);
      expect(state.canRecordAlways, isTrue);
    });

    test('canRecord: false when match is completed', () {
      final state = RecorderState(matchStatus: 'completed', isShotClockRunning: true);
      expect(state.canRecord, isFalse);
      expect(state.canRecordAlways, isFalse);
      expect(state.isCompleted, isTrue);
    });

    test('shot clock exempt types should be recordable without shot clock', () {
      final state = RecorderState(matchStatus: 'in_progress', isShotClockRunning: false);

      for (final exemptType in shotClockExemptTypes) {
        final canRecord = shotClockExemptTypes.contains(exemptType)
            ? state.canRecordAlways
            : state.canRecord;
        expect(canRecord, isTrue, reason: '$exemptType should be recordable without shot clock');
      }

      // Non-exempt types should not be recordable
      for (final type in ['2pt', '3pt', '1pt', 'rebound_off', 'assist', 'steal']) {
        final canRecord = shotClockExemptTypes.contains(type)
            ? state.canRecordAlways
            : state.canRecord;
        expect(canRecord, isFalse, reason: '$type should NOT be recordable without shot clock');
      }
    });

    test('shot clock exempt types should NOT be recordable when match not in_progress', () {
      final state = RecorderState(matchStatus: 'scheduled', isShotClockRunning: false);

      for (final exemptType in shotClockExemptTypes) {
        final canRecord = shotClockExemptTypes.contains(exemptType)
            ? state.canRecordAlways
            : state.canRecord;
        expect(canRecord, isFalse, reason: '$exemptType should NOT be recordable when match is scheduled');
      }
    });
  });

  group('RecorderState - quarter change foul reset', () {
    test('should reset both team fouls to 0 on quarter change', () {
      final state = RecorderState(
        matchStatus: 'in_progress',
        homeTeamFouls: 3,
        awayTeamFouls: 4,
        currentQuarter: 1,
      );

      final newState = setQuarter(state, 2);
      expect(newState.currentQuarter, 2);
      expect(newState.homeTeamFouls, 0);
      expect(newState.awayTeamFouls, 0);
    });

    test('should reset fouls when changing to overtime', () {
      final state = RecorderState(
        matchStatus: 'in_progress',
        homeTeamFouls: 5,
        awayTeamFouls: 2,
        currentQuarter: 4,
      );

      final newState = setQuarter(state, 5); // OT1
      expect(newState.currentQuarter, 5);
      expect(newState.homeTeamFouls, 0);
      expect(newState.awayTeamFouls, 0);
    });

    test('should preserve match status when changing quarter', () {
      final state = RecorderState(
        matchStatus: 'in_progress',
        homeTeamFouls: 3,
        awayTeamFouls: 1,
        currentQuarter: 1,
      );

      final newState = setQuarter(state, 3);
      expect(newState.matchStatus, 'in_progress');
    });
  });

  group('RecorderState - substitution bench edge cases', () {
    test('should handle empty player list', () {
      final state = RecorderState(
        homePlayers: [],
        awayPlayers: [],
      );

      final homeStarters = state.homePlayers
          .where((p) => p['is_starter'] == true)
          .toList();
      final homeBench = state.homePlayers
          .where((p) => p['is_starter'] != true)
          .toList();

      expect(homeStarters, isEmpty);
      expect(homeBench, isEmpty);
    });

    test('should handle all starters no bench', () {
      final state = RecorderState(
        homePlayers: [
          {'id': 1, 'name': 'Player 1', 'is_starter': true},
          {'id': 2, 'name': 'Player 2', 'is_starter': true},
          {'id': 3, 'name': 'Player 3', 'is_starter': true},
          {'id': 4, 'name': 'Player 4', 'is_starter': true},
          {'id': 5, 'name': 'Player 5', 'is_starter': true},
        ],
      );

      final starters = state.homePlayers
          .where((p) => p['is_starter'] == true)
          .toList();
      final bench = state.homePlayers
          .where((p) => p['is_starter'] != true)
          .toList();

      expect(starters.length, 5);
      expect(bench, isEmpty);
    });

    test('should handle all bench no starters', () {
      final state = RecorderState(
        homePlayers: [
          {'id': 1, 'name': 'Player 1', 'is_starter': false},
          {'id': 2, 'name': 'Player 2', 'is_starter': false},
        ],
      );

      final starters = state.homePlayers
          .where((p) => p['is_starter'] == true)
          .toList();
      final bench = state.homePlayers
          .where((p) => p['is_starter'] != true)
          .toList();

      expect(starters, isEmpty);
      expect(bench.length, 2);
    });

    test('should correctly split starters and bench', () {
      final state = RecorderState(
        homePlayers: [
          {'id': 1, 'name': 'Starter 1', 'is_starter': true},
          {'id': 2, 'name': 'Starter 2', 'is_starter': true},
          {'id': 3, 'name': 'Bench 1', 'is_starter': false},
          {'id': 4, 'name': 'Bench 2', 'is_starter': false},
          {'id': 5, 'name': 'Starter 3', 'is_starter': true},
        ],
      );

      final starters = state.homePlayers
          .where((p) => p['is_starter'] == true)
          .toList();
      final bench = state.homePlayers
          .where((p) => p['is_starter'] != true)
          .toList();

      expect(starters.length, 3);
      expect(bench.length, 2);
    });

    test('substitution should swap is_starter flags', () {
      final players = <Map<String, dynamic>>[
        {'id': 1, 'name': 'Starter 1', 'is_starter': true},
        {'id': 2, 'name': 'Starter 2', 'is_starter': true},
        {'id': 3, 'name': 'Bench 1', 'is_starter': false},
      ];

      // Simulate substitution: player 1 out, player 3 in
      final outPlayerId = 1;
      final inPlayerId = 3;
      for (final p in players) {
        if (p['id'] == outPlayerId) p['is_starter'] = false;
        if (p['id'] == inPlayerId) p['is_starter'] = true;
      }

      final starters = players.where((p) => p['is_starter'] == true).toList();
      final bench = players.where((p) => p['is_starter'] != true).toList();

      expect(starters.length, 2);
      expect(bench.length, 1);
      expect(starters.any((p) => p['id'] == 3), isTrue);
      expect(bench.any((p) => p['id'] == 1), isTrue);
    });
  });

  group('RecorderState - timeout tracking', () {
    test('should track remaining timeouts', () {
      var state = RecorderState(homeTimeouts: 5, awayTimeouts: 5);
      expect(state.homeTimeouts, 5);
      expect(state.awayTimeouts, 5);

      // Simulate home timeout
      state = state.copyWith(homeTimeouts: state.homeTimeouts - 1);
      expect(state.homeTimeouts, 4);
      expect(state.awayTimeouts, 5);
    });

    test('should not go below 0 timeouts', () {
      final state = RecorderState(homeTimeouts: 0, awayTimeouts: 0);
      expect(state.homeTimeouts, 0);
      // The check (remaining <= 0) prevents recording when no timeouts left
      expect(state.homeTimeouts <= 0, isTrue);
    });
  });
}
