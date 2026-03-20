import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 실행 취소 가능한 액션 타입
enum UndoableActionType {
  shot, // 슛
  freeThrow, // 자유투
  assist, // 어시스트
  rebound, // 리바운드
  steal, // 스틸
  block, // 블락
  turnover, // 턴오버
  foul, // 파울
  timeout, // 타임아웃
  substitution, // 교체
}

/// 실행 취소 가능한 액션
class UndoableAction {
  final String id; // 고유 ID
  final UndoableActionType type;
  final int playerId;
  final String playerName;
  final int matchId;
  final DateTime timestamp;
  final Map<String, dynamic> data; // 액션별 추가 데이터
  final List<String>? linkedActionIds; // 연관된 액션 ID들 (슛+어시스트 등)

  UndoableAction({
    required this.id,
    required this.type,
    required this.playerId,
    required this.playerName,
    required this.matchId,
    required this.timestamp,
    this.data = const {},
    this.linkedActionIds,
  });

  /// 액션 타입 라벨
  String get typeLabel {
    switch (type) {
      case UndoableActionType.shot:
        final isMade = data['isMade'] as bool? ?? false;
        final isThree = data['isThreePointer'] as bool? ?? false;
        return '${isThree ? "3점" : "2점"} ${isMade ? "성공" : "실패"}';
      case UndoableActionType.freeThrow:
        final isMade = data['isMade'] as bool? ?? false;
        return '자유투 ${isMade ? "성공" : "실패"}';
      case UndoableActionType.assist:
        return '어시스트';
      case UndoableActionType.rebound:
        final isOffensive = data['isOffensive'] as bool? ?? false;
        return '${isOffensive ? "공격" : "수비"} 리바운드';
      case UndoableActionType.steal:
        return '스틸';
      case UndoableActionType.block:
        return '블락';
      case UndoableActionType.turnover:
        return '턴오버';
      case UndoableActionType.foul:
        return '파울';
      case UndoableActionType.timeout:
        return '타임아웃';
      case UndoableActionType.substitution:
        return '선수 교체';
    }
  }

  /// 표시용 설명
  String get description {
    return '#$playerName - $typeLabel';
  }

  /// 포인트 변화량 (슛/자유투 성공 시)
  int get pointsChange {
    if (type == UndoableActionType.shot) {
      final isMade = data['isMade'] as bool? ?? false;
      if (!isMade) return 0;
      final isThree = data['isThreePointer'] as bool? ?? false;
      return isThree ? 3 : 2;
    }
    if (type == UndoableActionType.freeThrow) {
      final isMade = data['isMade'] as bool? ?? false;
      return isMade ? 1 : 0;
    }
    return 0;
  }
}

/// Undo 스택 상태
class UndoStackState {
  final List<UndoableAction> actions;
  final int maxSize;

  const UndoStackState({
    this.actions = const [],
    this.maxSize = 500,
  });

  /// 마지막 액션
  UndoableAction? get lastAction => actions.isNotEmpty ? actions.last : null;

  /// 스택이 비어있는지
  bool get isEmpty => actions.isEmpty;

  /// 스택이 꽉 찼는지
  bool get isFull => actions.length >= maxSize;

  /// 액션 개수
  int get length => actions.length;

  /// 새 액션 추가
  UndoStackState push(UndoableAction action) {
    final newActions = List<UndoableAction>.from(actions);

    // 최대 크기 초과 시 가장 오래된 것 제거
    if (newActions.length >= maxSize) {
      newActions.removeAt(0);
    }

    newActions.add(action);
    return UndoStackState(actions: newActions, maxSize: maxSize);
  }

  /// 마지막 액션 제거
  UndoStackState pop() {
    if (actions.isEmpty) return this;

    final newActions = List<UndoableAction>.from(actions);
    newActions.removeLast();
    return UndoStackState(actions: newActions, maxSize: maxSize);
  }

  /// ID로 액션 찾기
  UndoableAction? findById(String id) {
    try {
      return actions.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 연관된 액션들 찾기
  List<UndoableAction> findLinkedActions(String actionId) {
    final action = findById(actionId);
    if (action == null || action.linkedActionIds == null) {
      return [];
    }

    return actions
        .where((a) => action.linkedActionIds!.contains(a.id))
        .toList();
  }

  /// ID로 액션 제거 (연관된 액션도 함께)
  UndoStackState removeById(String id, {bool includeLinked = true}) {
    final action = findById(id);
    if (action == null) return this;

    final idsToRemove = <String>{id};

    // 연관된 액션도 제거
    if (includeLinked && action.linkedActionIds != null) {
      idsToRemove.addAll(action.linkedActionIds!);
    }

    // 이 액션을 링크로 가진 다른 액션들도 제거
    if (includeLinked) {
      for (final a in actions) {
        if (a.linkedActionIds?.contains(id) ?? false) {
          idsToRemove.add(a.id);
        }
      }
    }

    final newActions = actions
        .where((a) => !idsToRemove.contains(a.id))
        .toList();

    return UndoStackState(actions: newActions, maxSize: maxSize);
  }

  /// 스택 초기화
  UndoStackState clear() {
    return UndoStackState(actions: const [], maxSize: maxSize);
  }
}

/// Undo 스택 Provider
class UndoStackNotifier extends StateNotifier<UndoStackState> {
  UndoStackNotifier() : super(const UndoStackState());

  /// 액션 추가
  void push(UndoableAction action) {
    state = state.push(action);
  }

  /// 슛 기록 추가
  void recordShot({
    required int playerId,
    required String playerName,
    required int matchId,
    required bool isMade,
    required bool isThreePointer,
    bool? isHome,
    String? linkedAssistActionId,
  }) {
    final action = UndoableAction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: UndoableActionType.shot,
      playerId: playerId,
      playerName: playerName,
      matchId: matchId,
      timestamp: DateTime.now(),
      data: {
        'isMade': isMade,
        'isThreePointer': isThreePointer,
        if (isHome != null) 'isHome': isHome,
      },
      linkedActionIds:
          linkedAssistActionId != null ? [linkedAssistActionId] : null,
    );
    push(action);
  }

  /// 자유투 기록 추가
  void recordFreeThrow({
    required int playerId,
    required String playerName,
    required int matchId,
    required bool isMade,
    required int shotNumber, // 몇 번째 자유투인지
    required int totalShots, // 총 자유투 개수
    bool? isHome,
  }) {
    final action = UndoableAction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: UndoableActionType.freeThrow,
      playerId: playerId,
      playerName: playerName,
      matchId: matchId,
      timestamp: DateTime.now(),
      data: {
        'isMade': isMade,
        'shotNumber': shotNumber,
        'totalShots': totalShots,
        if (isHome != null) 'isHome': isHome,
      },
    );
    push(action);
  }

  /// 어시스트 기록 추가
  String recordAssist({
    required int playerId,
    required String playerName,
    required int matchId,
    bool? isHome,
  }) {
    final actionId = DateTime.now().microsecondsSinceEpoch.toString();
    final action = UndoableAction(
      id: actionId,
      type: UndoableActionType.assist,
      playerId: playerId,
      playerName: playerName,
      matchId: matchId,
      timestamp: DateTime.now(),
      data: {
        if (isHome != null) 'isHome': isHome,
      },
    );
    push(action);
    return actionId;
  }

  /// 리바운드 기록 추가
  void recordRebound({
    required int playerId,
    required String playerName,
    required int matchId,
    required bool isOffensive,
    bool? isHome,
  }) {
    final action = UndoableAction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: UndoableActionType.rebound,
      playerId: playerId,
      playerName: playerName,
      matchId: matchId,
      timestamp: DateTime.now(),
      data: {
        'isOffensive': isOffensive,
        if (isHome != null) 'isHome': isHome,
      },
    );
    push(action);
  }

  /// 스틸 기록 추가
  void recordSteal({
    required int playerId,
    required String playerName,
    required int matchId,
    bool? isHome,
    String? linkedTurnoverActionId,
  }) {
    final action = UndoableAction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: UndoableActionType.steal,
      playerId: playerId,
      playerName: playerName,
      matchId: matchId,
      timestamp: DateTime.now(),
      data: {
        if (isHome != null) 'isHome': isHome,
      },
      linkedActionIds:
          linkedTurnoverActionId != null ? [linkedTurnoverActionId] : null,
    );
    push(action);
  }

  /// 블락 기록 추가
  void recordBlock({
    required int playerId,
    required String playerName,
    required int matchId,
    bool? isHome,
  }) {
    final action = UndoableAction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: UndoableActionType.block,
      playerId: playerId,
      playerName: playerName,
      matchId: matchId,
      timestamp: DateTime.now(),
      data: {
        if (isHome != null) 'isHome': isHome,
      },
    );
    push(action);
  }

  /// 턴오버 기록 추가
  String recordTurnover({
    required int playerId,
    required String playerName,
    required int matchId,
    bool? isHome,
  }) {
    final actionId = DateTime.now().microsecondsSinceEpoch.toString();
    final action = UndoableAction(
      id: actionId,
      type: UndoableActionType.turnover,
      playerId: playerId,
      playerName: playerName,
      matchId: matchId,
      timestamp: DateTime.now(),
      data: {
        if (isHome != null) 'isHome': isHome,
      },
    );
    push(action);
    return actionId;
  }

  /// 파울 기록 추가
  void recordFoul({
    required int playerId,
    required String playerName,
    required int matchId,
    bool? isHome,
    String? foulType,
    List<String>? linkedFreeThrowActionIds,
  }) {
    final action = UndoableAction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: UndoableActionType.foul,
      playerId: playerId,
      playerName: playerName,
      matchId: matchId,
      timestamp: DateTime.now(),
      data: {
        'foulType': foulType,
        if (isHome != null) 'isHome': isHome,
      },
      linkedActionIds: linkedFreeThrowActionIds,
    );
    push(action);
  }

  /// 타임아웃 기록 추가
  void recordTimeout({
    required int matchId,
    required String teamName,
    required bool isHome,
    bool isOfficial = false,
  }) {
    final action = UndoableAction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: UndoableActionType.timeout,
      playerId: 0,
      playerName: teamName,
      matchId: matchId,
      timestamp: DateTime.now(),
      data: {
        'isHome': isHome,
        'isOfficial': isOfficial,
      },
    );
    push(action);
  }

  /// 선수 교체 기록 추가
  void recordSubstitution({
    required int matchId,
    required int subOutPlayerId,
    required String subOutPlayerName,
    required int subInPlayerId,
    required String subInPlayerName,
    required bool isHome,
  }) {
    final action = UndoableAction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: UndoableActionType.substitution,
      playerId: subOutPlayerId,
      playerName: '$subOutPlayerName → $subInPlayerName',
      matchId: matchId,
      timestamp: DateTime.now(),
      data: {
        'subOutPlayerId': subOutPlayerId,
        'subOutPlayerName': subOutPlayerName,
        'subInPlayerId': subInPlayerId,
        'subInPlayerName': subInPlayerName,
        'isHome': isHome,
      },
    );
    push(action);
  }

  /// 마지막 액션 취소
  UndoableAction? undoLast() {
    final action = state.lastAction;
    if (action != null) {
      state = state.pop();
    }
    return action;
  }

  /// ID로 액션 취소 (연관된 액션도 함께)
  List<UndoableAction> undoById(String id, {bool includeLinked = true}) {
    final actionsToUndo = <UndoableAction>[];

    final action = state.findById(id);
    if (action != null) {
      actionsToUndo.add(action);

      if (includeLinked) {
        actionsToUndo.addAll(state.findLinkedActions(id));
      }
    }

    state = state.removeById(id, includeLinked: includeLinked);
    return actionsToUndo;
  }

  /// 스택 초기화
  void clear() {
    state = state.clear();
  }
}

/// Undo 스택 Provider 정의
final undoStackProvider =
    StateNotifierProvider<UndoStackNotifier, UndoStackState>((ref) {
  return UndoStackNotifier();
});
