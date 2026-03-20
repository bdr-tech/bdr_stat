import 'package:flutter_test/flutter_test.dart';
import 'package:bdr_tournament_recorder/presentation/providers/undo_stack_provider.dart';

void main() {
  group('UndoableAction', () {
    test('should create action with correct properties', () {
      final action = UndoableAction(
        id: 'test-1',
        type: UndoableActionType.shot,
        playerId: 1,
        playerName: 'Player 1',
        matchId: 100,
        timestamp: DateTime(2024, 1, 1),
        data: {'isMade': true, 'isThreePointer': false},
      );

      expect(action.id, 'test-1');
      expect(action.type, UndoableActionType.shot);
      expect(action.playerId, 1);
      expect(action.playerName, 'Player 1');
      expect(action.matchId, 100);
    });

    test('typeLabel should return correct label for shot', () {
      final madeTwo = UndoableAction(
        id: '1',
        type: UndoableActionType.shot,
        playerId: 1,
        playerName: 'P1',
        matchId: 1,
        timestamp: DateTime.now(),
        data: {'isMade': true, 'isThreePointer': false},
      );
      expect(madeTwo.typeLabel, '2점 성공');

      final missedThree = UndoableAction(
        id: '2',
        type: UndoableActionType.shot,
        playerId: 1,
        playerName: 'P1',
        matchId: 1,
        timestamp: DateTime.now(),
        data: {'isMade': false, 'isThreePointer': true},
      );
      expect(missedThree.typeLabel, '3점 실패');
    });

    test('typeLabel should return correct label for free throw', () {
      final madeFt = UndoableAction(
        id: '1',
        type: UndoableActionType.freeThrow,
        playerId: 1,
        playerName: 'P1',
        matchId: 1,
        timestamp: DateTime.now(),
        data: {'isMade': true},
      );
      expect(madeFt.typeLabel, '자유투 성공');
    });

    test('typeLabel should return correct label for rebound', () {
      final offensiveReb = UndoableAction(
        id: '1',
        type: UndoableActionType.rebound,
        playerId: 1,
        playerName: 'P1',
        matchId: 1,
        timestamp: DateTime.now(),
        data: {'isOffensive': true},
      );
      expect(offensiveReb.typeLabel, '공격 리바운드');

      final defensiveReb = UndoableAction(
        id: '2',
        type: UndoableActionType.rebound,
        playerId: 1,
        playerName: 'P1',
        matchId: 1,
        timestamp: DateTime.now(),
        data: {'isOffensive': false},
      );
      expect(defensiveReb.typeLabel, '수비 리바운드');
    });

    test('typeLabel should return correct labels for other actions', () {
      final types = {
        UndoableActionType.assist: '어시스트',
        UndoableActionType.steal: '스틸',
        UndoableActionType.block: '블락',
        UndoableActionType.turnover: '턴오버',
        UndoableActionType.foul: '파울',
        UndoableActionType.timeout: '타임아웃',
        UndoableActionType.substitution: '선수 교체',
      };

      for (final entry in types.entries) {
        final action = UndoableAction(
          id: '1',
          type: entry.key,
          playerId: 1,
          playerName: 'P1',
          matchId: 1,
          timestamp: DateTime.now(),
        );
        expect(action.typeLabel, entry.value,
            reason: 'Type ${entry.key} should have label ${entry.value}');
      }
    });

    test('pointsChange should return correct values', () {
      // 2 points made
      final twoMade = UndoableAction(
        id: '1',
        type: UndoableActionType.shot,
        playerId: 1,
        playerName: 'P1',
        matchId: 1,
        timestamp: DateTime.now(),
        data: {'isMade': true, 'isThreePointer': false},
      );
      expect(twoMade.pointsChange, 2);

      // 3 points made
      final threeMade = UndoableAction(
        id: '2',
        type: UndoableActionType.shot,
        playerId: 1,
        playerName: 'P1',
        matchId: 1,
        timestamp: DateTime.now(),
        data: {'isMade': true, 'isThreePointer': true},
      );
      expect(threeMade.pointsChange, 3);

      // Missed shot
      final missed = UndoableAction(
        id: '3',
        type: UndoableActionType.shot,
        playerId: 1,
        playerName: 'P1',
        matchId: 1,
        timestamp: DateTime.now(),
        data: {'isMade': false, 'isThreePointer': false},
      );
      expect(missed.pointsChange, 0);

      // Free throw made
      final ftMade = UndoableAction(
        id: '4',
        type: UndoableActionType.freeThrow,
        playerId: 1,
        playerName: 'P1',
        matchId: 1,
        timestamp: DateTime.now(),
        data: {'isMade': true},
      );
      expect(ftMade.pointsChange, 1);

      // Other action types return 0
      final assist = UndoableAction(
        id: '5',
        type: UndoableActionType.assist,
        playerId: 1,
        playerName: 'P1',
        matchId: 1,
        timestamp: DateTime.now(),
      );
      expect(assist.pointsChange, 0);
    });
  });

  group('UndoStackState', () {
    test('should start empty', () {
      const state = UndoStackState();
      expect(state.isEmpty, true);
      expect(state.length, 0);
      expect(state.lastAction, null);
    });

    test('should push actions correctly', () {
      const state = UndoStackState();
      final action = _createAction('1');

      final newState = state.push(action);
      expect(newState.length, 1);
      expect(newState.lastAction?.id, '1');
      expect(newState.isEmpty, false);
    });

    test('should pop actions correctly', () {
      const state = UndoStackState();
      final action1 = _createAction('1');
      final action2 = _createAction('2');

      final afterPush = state.push(action1).push(action2);
      expect(afterPush.length, 2);

      final afterPop = afterPush.pop();
      expect(afterPop.length, 1);
      expect(afterPop.lastAction?.id, '1');
    });

    test('should respect maxSize', () {
      const state = UndoStackState(maxSize: 3);

      var current = state;
      for (var i = 1; i <= 5; i++) {
        current = current.push(_createAction('$i'));
      }

      expect(current.length, 3);
      // Should keep the 3 most recent: 3, 4, 5
      expect(current.actions[0].id, '3');
      expect(current.actions[2].id, '5');
    });

    test('findById should return correct action', () {
      const state = UndoStackState();
      final action1 = _createAction('1');
      final action2 = _createAction('2');

      final withActions = state.push(action1).push(action2);

      expect(withActions.findById('1')?.id, '1');
      expect(withActions.findById('2')?.id, '2');
      expect(withActions.findById('3'), null);
    });

    test('findLinkedActions should return linked actions', () {
      const state = UndoStackState();

      final assistAction = _createAction('assist-1');
      final shotAction = UndoableAction(
        id: 'shot-1',
        type: UndoableActionType.shot,
        playerId: 1,
        playerName: 'P1',
        matchId: 1,
        timestamp: DateTime.now(),
        data: {'isMade': true, 'isThreePointer': false},
        linkedActionIds: ['assist-1'],
      );

      final withActions = state.push(assistAction).push(shotAction);
      final linked = withActions.findLinkedActions('shot-1');

      expect(linked.length, 1);
      expect(linked[0].id, 'assist-1');
    });

    test('removeById should remove action and linked actions', () {
      const state = UndoStackState();

      final turnoverAction = _createAction('to-1', type: UndoableActionType.turnover);
      final stealAction = UndoableAction(
        id: 'steal-1',
        type: UndoableActionType.steal,
        playerId: 2,
        playerName: 'P2',
        matchId: 1,
        timestamp: DateTime.now(),
        linkedActionIds: ['to-1'],
      );

      final withActions = state.push(turnoverAction).push(stealAction);
      expect(withActions.length, 2);

      // Remove steal (should also remove linked turnover)
      final afterRemove = withActions.removeById('steal-1');
      expect(afterRemove.length, 0);
    });

    test('clear should reset stack', () {
      const state = UndoStackState();
      final withActions = state.push(_createAction('1')).push(_createAction('2'));

      final cleared = withActions.clear();
      expect(cleared.isEmpty, true);
      expect(cleared.maxSize, state.maxSize);
    });
  });

  group('UndoStackNotifier', () {
    late UndoStackNotifier notifier;

    setUp(() {
      notifier = UndoStackNotifier();
    });

    test('should record shot correctly', () {
      notifier.recordShot(
        playerId: 1,
        playerName: 'Player 1',
        matchId: 100,
        isMade: true,
        isThreePointer: true,
      );

      expect(notifier.state.length, 1);
      final action = notifier.state.lastAction!;
      expect(action.type, UndoableActionType.shot);
      expect(action.data['isMade'], true);
      expect(action.data['isThreePointer'], true);
    });

    test('should record free throw correctly', () {
      notifier.recordFreeThrow(
        playerId: 1,
        playerName: 'Player 1',
        matchId: 100,
        isMade: true,
        shotNumber: 1,
        totalShots: 2,
      );

      expect(notifier.state.length, 1);
      final action = notifier.state.lastAction!;
      expect(action.type, UndoableActionType.freeThrow);
      expect(action.data['isMade'], true);
      expect(action.data['shotNumber'], 1);
      expect(action.data['totalShots'], 2);
    });

    test('should record assist and return action id', () {
      final actionId = notifier.recordAssist(
        playerId: 1,
        playerName: 'Player 1',
        matchId: 100,
      );

      expect(actionId.isNotEmpty, true);
      expect(notifier.state.length, 1);
      expect(notifier.state.lastAction!.type, UndoableActionType.assist);
    });

    test('should record rebound correctly', () {
      notifier.recordRebound(
        playerId: 1,
        playerName: 'Player 1',
        matchId: 100,
        isOffensive: true,
      );

      expect(notifier.state.length, 1);
      final action = notifier.state.lastAction!;
      expect(action.type, UndoableActionType.rebound);
      expect(action.data['isOffensive'], true);
    });

    test('should record steal with linked turnover', () async {
      // First record turnover
      final toId = notifier.recordTurnover(
        playerId: 2,
        playerName: 'Player 2',
        matchId: 100,
      );

      // Then record steal linked to turnover
      await Future.delayed(const Duration(milliseconds: 10)); // Ensure different timestamp
      notifier.recordSteal(
        playerId: 1,
        playerName: 'Player 1',
        matchId: 100,
        linkedTurnoverActionId: toId,
      );

      expect(notifier.state.length, 2);
      final stealAction = notifier.state.lastAction!;
      expect(stealAction.linkedActionIds, contains(toId));
    });

    test('should record block correctly', () {
      notifier.recordBlock(
        playerId: 1,
        playerName: 'Player 1',
        matchId: 100,
      );

      expect(notifier.state.length, 1);
      expect(notifier.state.lastAction!.type, UndoableActionType.block);
    });

    test('should record foul correctly', () {
      notifier.recordFoul(
        playerId: 1,
        playerName: 'Player 1',
        matchId: 100,
        foulType: 'personal',
      );

      expect(notifier.state.length, 1);
      final action = notifier.state.lastAction!;
      expect(action.type, UndoableActionType.foul);
      expect(action.data['foulType'], 'personal');
    });

    test('should record timeout correctly', () {
      notifier.recordTimeout(
        matchId: 100,
        teamName: 'Team A',
        isHome: true,
        isOfficial: false,
      );

      expect(notifier.state.length, 1);
      final action = notifier.state.lastAction!;
      expect(action.type, UndoableActionType.timeout);
      expect(action.data['isHome'], true);
      expect(action.data['isOfficial'], false);
    });

    test('should record substitution correctly', () {
      notifier.recordSubstitution(
        matchId: 100,
        subOutPlayerId: 1,
        subOutPlayerName: 'Player Out',
        subInPlayerId: 2,
        subInPlayerName: 'Player In',
        isHome: true,
      );

      expect(notifier.state.length, 1);
      final action = notifier.state.lastAction!;
      expect(action.type, UndoableActionType.substitution);
      expect(action.data['subOutPlayerId'], 1);
      expect(action.data['subInPlayerId'], 2);
    });

    test('undoLast should return and remove last action', () {
      notifier.recordShot(
        playerId: 1,
        playerName: 'P1',
        matchId: 100,
        isMade: true,
        isThreePointer: false,
      );
      notifier.recordAssist(
        playerId: 2,
        playerName: 'P2',
        matchId: 100,
      );

      expect(notifier.state.length, 2);

      final undone = notifier.undoLast();
      expect(undone?.type, UndoableActionType.assist);
      expect(notifier.state.length, 1);
    });

    test('undoById should remove action and linked actions', () async {
      // Record turnover
      final toId = notifier.recordTurnover(
        playerId: 1,
        playerName: 'P1',
        matchId: 100,
      );

      await Future.delayed(const Duration(milliseconds: 10));

      // Record steal linked to turnover
      notifier.recordSteal(
        playerId: 2,
        playerName: 'P2',
        matchId: 100,
        linkedTurnoverActionId: toId,
      );

      expect(notifier.state.length, 2);
      final stealId = notifier.state.lastAction!.id;

      // Undo steal (should also undo linked turnover)
      final undone = notifier.undoById(stealId);
      expect(undone.length, 2);
      expect(notifier.state.isEmpty, true);
    });

    test('clear should empty the stack', () {
      notifier.recordShot(
        playerId: 1,
        playerName: 'P1',
        matchId: 100,
        isMade: true,
        isThreePointer: false,
      );
      notifier.recordAssist(playerId: 2, playerName: 'P2', matchId: 100);

      expect(notifier.state.length, 2);

      notifier.clear();
      expect(notifier.state.isEmpty, true);
    });
  });
}

/// Helper to create a test action
UndoableAction _createAction(
  String id, {
  UndoableActionType type = UndoableActionType.assist,
}) {
  return UndoableAction(
    id: id,
    type: type,
    playerId: 1,
    playerName: 'Test Player',
    matchId: 1,
    timestamp: DateTime.now(),
  );
}
