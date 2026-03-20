import 'package:flutter_test/flutter_test.dart';
import 'package:bdr_tournament_recorder/core/utils/score_utils.dart';

void main() {
  group('ScoreUtils', () {
    group('calculatePoints', () {
      test('should calculate points correctly with all shot types', () {
        expect(
          ScoreUtils.calculatePoints(
            twoPointersMade: 5,
            threePointersMade: 3,
            freeThrowsMade: 4,
          ),
          23, // 5*2 + 3*3 + 4*1 = 10 + 9 + 4 = 23
        );
      });

      test('should return 0 for all zeros', () {
        expect(
          ScoreUtils.calculatePoints(
            twoPointersMade: 0,
            threePointersMade: 0,
            freeThrowsMade: 0,
          ),
          0,
        );
      });

      test('should calculate correctly with only 2-pointers', () {
        expect(
          ScoreUtils.calculatePoints(
            twoPointersMade: 10,
            threePointersMade: 0,
            freeThrowsMade: 0,
          ),
          20,
        );
      });

      test('should calculate correctly with only 3-pointers', () {
        expect(
          ScoreUtils.calculatePoints(
            twoPointersMade: 0,
            threePointersMade: 10,
            freeThrowsMade: 0,
          ),
          30,
        );
      });

      test('should calculate correctly with only free throws', () {
        expect(
          ScoreUtils.calculatePoints(
            twoPointersMade: 0,
            threePointersMade: 0,
            freeThrowsMade: 10,
          ),
          10,
        );
      });
    });

    group('calculatePercentage', () {
      test('should calculate percentage correctly', () {
        expect(ScoreUtils.calculatePercentage(5, 10), 50.0);
        expect(ScoreUtils.calculatePercentage(1, 4), 25.0);
        expect(ScoreUtils.calculatePercentage(3, 3), 100.0);
      });

      test('should return 0 when no attempts', () {
        expect(ScoreUtils.calculatePercentage(0, 0), 0.0);
      });

      test('should handle perfect shooting', () {
        expect(ScoreUtils.calculatePercentage(10, 10), 100.0);
      });

      test('should handle zero made shots', () {
        expect(ScoreUtils.calculatePercentage(0, 10), 0.0);
      });
    });

    group('formatPercentage', () {
      test('should format percentage with one decimal', () {
        expect(ScoreUtils.formatPercentage(50.0), '50.0%');
        expect(ScoreUtils.formatPercentage(33.333), '33.3%');
        expect(ScoreUtils.formatPercentage(100.0), '100.0%');
      });
    });

    group('formatMadeAttempted', () {
      test('should format made-attempted correctly', () {
        expect(ScoreUtils.formatMadeAttempted(10, 18), '10-18');
        expect(ScoreUtils.formatMadeAttempted(0, 0), '0-0');
        expect(ScoreUtils.formatMadeAttempted(5, 5), '5-5');
      });
    });

    group('formatMadeAttemptedWithPercentage', () {
      test('should format with percentage correctly', () {
        expect(
          ScoreUtils.formatMadeAttemptedWithPercentage(5, 10),
          '5-10 (50.0%)',
        );
      });

      test('should handle zero attempts', () {
        expect(
          ScoreUtils.formatMadeAttemptedWithPercentage(0, 0),
          '0-0 (0.0%)',
        );
      });
    });

    group('parseQuarterScores', () {
      test('should parse valid JSON', () {
        final json = '{"home":{"q1":20,"q2":25},"away":{"q1":22,"q2":18}}';
        final result = ScoreUtils.parseQuarterScores(json);

        expect(result['home']!['q1'], 20);
        expect(result['home']!['q2'], 25);
        expect(result['away']!['q1'], 22);
        expect(result['away']!['q2'], 18);
      });

      test('should return empty maps for empty string', () {
        final result = ScoreUtils.parseQuarterScores('');
        expect(result['home'], isEmpty);
        expect(result['away'], isEmpty);
      });

      test('should return empty maps for empty JSON object', () {
        final result = ScoreUtils.parseQuarterScores('{}');
        expect(result['home'], isEmpty);
        expect(result['away'], isEmpty);
      });

      test('should handle invalid JSON', () {
        final result = ScoreUtils.parseQuarterScores('invalid json');
        expect(result['home'], isEmpty);
        expect(result['away'], isEmpty);
      });

      test('should handle partial data', () {
        final json = '{"home":{"q1":20}}';
        final result = ScoreUtils.parseQuarterScores(json);

        expect(result['home']!['q1'], 20);
        expect(result['away'], isEmpty);
      });
    });

    group('encodeQuarterScores', () {
      test('should encode scores to JSON', () {
        final scores = {
          'home': {'q1': 20, 'q2': 25},
          'away': {'q1': 22, 'q2': 18},
        };
        final json = ScoreUtils.encodeQuarterScores(scores);
        final parsed = ScoreUtils.parseQuarterScores(json);

        expect(parsed['home']!['q1'], 20);
        expect(parsed['away']!['q2'], 18);
      });
    });

    group('updateQuarterScore', () {
      test('should update existing quarter score', () {
        final json = '{"home":{"q1":20},"away":{"q1":22}}';
        final updated = ScoreUtils.updateQuarterScore(json, 1, true, 25);
        final parsed = ScoreUtils.parseQuarterScores(updated);

        expect(parsed['home']!['q1'], 25);
        expect(parsed['away']!['q1'], 22);
      });

      test('should add new quarter score', () {
        final json = '{"home":{"q1":20},"away":{"q1":22}}';
        final updated = ScoreUtils.updateQuarterScore(json, 2, true, 30);
        final parsed = ScoreUtils.parseQuarterScores(updated);

        expect(parsed['home']!['q1'], 20);
        expect(parsed['home']!['q2'], 30);
      });

      test('should update away team score', () {
        final json = '{"home":{},"away":{}}';
        final updated = ScoreUtils.updateQuarterScore(json, 1, false, 15);
        final parsed = ScoreUtils.parseQuarterScores(updated);

        expect(parsed['away']!['q1'], 15);
      });
    });

    group('calculateTotalFromQuarters', () {
      test('should calculate total for home team', () {
        final scores = {
          'home': {'q1': 20, 'q2': 25, 'q3': 18, 'q4': 22},
          'away': {'q1': 22, 'q2': 18, 'q3': 20, 'q4': 25},
        };
        expect(ScoreUtils.calculateTotalFromQuarters(scores, true), 85);
      });

      test('should calculate total for away team', () {
        final scores = {
          'home': {'q1': 20, 'q2': 25, 'q3': 18, 'q4': 22},
          'away': {'q1': 22, 'q2': 18, 'q3': 20, 'q4': 25},
        };
        expect(ScoreUtils.calculateTotalFromQuarters(scores, false), 85);
      });

      test('should return 0 for empty quarters', () {
        final scores = {'home': <String, int>{}, 'away': <String, int>{}};
        expect(ScoreUtils.calculateTotalFromQuarters(scores, true), 0);
      });
    });
  });

  group('TeamFoulUtils', () {
    group('parseTeamFouls', () {
      test('should parse valid JSON', () {
        final json = '{"home":{"q1":3,"q2":4},"away":{"q1":2,"q2":5}}';
        final result = TeamFoulUtils.parseTeamFouls(json);

        expect(result['home']!['q1'], 3);
        expect(result['away']!['q2'], 5);
      });

      test('should return empty maps for empty string', () {
        final result = TeamFoulUtils.parseTeamFouls('');
        expect(result['home'], isEmpty);
        expect(result['away'], isEmpty);
      });

      test('should handle invalid JSON', () {
        final result = TeamFoulUtils.parseTeamFouls('not json');
        expect(result['home'], isEmpty);
        expect(result['away'], isEmpty);
      });
    });

    group('getQuarterFouls', () {
      test('should return correct foul count', () {
        final json = '{"home":{"q1":3},"away":{"q1":2}}';
        expect(TeamFoulUtils.getQuarterFouls(json, 1, true), 3);
        expect(TeamFoulUtils.getQuarterFouls(json, 1, false), 2);
      });

      test('should return 0 for missing quarter', () {
        final json = '{"home":{"q1":3},"away":{"q1":2}}';
        expect(TeamFoulUtils.getQuarterFouls(json, 2, true), 0);
      });

      test('should return 0 for empty JSON', () {
        expect(TeamFoulUtils.getQuarterFouls('', 1, true), 0);
      });
    });

    group('addTeamFoul', () {
      test('should add foul to existing quarter', () {
        final json = '{"home":{"q1":3},"away":{"q1":2}}';
        final updated = TeamFoulUtils.addTeamFoul(json, 1, true);
        expect(TeamFoulUtils.getQuarterFouls(updated, 1, true), 4);
      });

      test('should add foul to new quarter', () {
        final json = '{"home":{},"away":{}}';
        final updated = TeamFoulUtils.addTeamFoul(json, 1, false);
        expect(TeamFoulUtils.getQuarterFouls(updated, 1, false), 1);
      });

      test('should add multiple fouls', () {
        var json = '{"home":{},"away":{}}';
        json = TeamFoulUtils.addTeamFoul(json, 1, true);
        json = TeamFoulUtils.addTeamFoul(json, 1, true);
        json = TeamFoulUtils.addTeamFoul(json, 1, true);
        expect(TeamFoulUtils.getQuarterFouls(json, 1, true), 3);
      });
    });

    group('isInBonus', () {
      test('should return true when at threshold', () {
        final json = '{"home":{"q1":5},"away":{"q1":4}}';
        expect(TeamFoulUtils.isInBonus(json, 1, true), true);
        expect(TeamFoulUtils.isInBonus(json, 1, false), false);
      });

      test('should return true when above threshold', () {
        final json = '{"home":{"q1":7},"away":{}}';
        expect(TeamFoulUtils.isInBonus(json, 1, true), true);
      });

      test('should return false when below threshold', () {
        final json = '{"home":{"q1":3},"away":{}}';
        expect(TeamFoulUtils.isInBonus(json, 1, true), false);
      });

      test('should support custom threshold', () {
        final json = '{"home":{"q1":3},"away":{}}';
        expect(TeamFoulUtils.isInBonus(json, 1, true, threshold: 3), true);
        expect(TeamFoulUtils.isInBonus(json, 1, true, threshold: 4), false);
      });
    });
  });
}
