// TODO(phase2): This service is not yet integrated.
// Planned for Phase 2 release. Do not call from production code.
// Requires: speech_to_text package (not in pubspec.yaml), microphone permission setup.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 음성 명령 서비스 프로바이더
// TODO(phase2): Provider not registered in main DI. Wire up only after Phase 2 design approval.
final voiceCommandServiceProvider = Provider<VoiceCommandService>((ref) {
  return VoiceCommandService();
});

/// 음성 인식 상태 프로바이더
final voiceRecognitionStateProvider =
    StateNotifierProvider<VoiceRecognitionStateNotifier, VoiceRecognitionState>(
        (ref) {
  return VoiceRecognitionStateNotifier(ref);
});

/// 음성 명령 서비스
///
/// 기능:
/// - 음성 인식 (speech_to_text)
/// - 명령어 파싱 및 실행
/// - 한국어 지원
/// - 농구 용어 인식 최적화
///
// TODO(phase2): VoiceCommandService.startListening / stopListening are stubs.
// TODO(phase2): Integrate speech_to_text package and implement _checkAvailability.
class VoiceCommandService {
  // 명령어 패턴 정의
  static const Map<String, VoiceCommandType> _commandPatterns = {
    // 슛 관련
    '슛': VoiceCommandType.shot,
    '샷': VoiceCommandType.shot,
    '2점': VoiceCommandType.twoPoint,
    '투 포인트': VoiceCommandType.twoPoint,
    '3점': VoiceCommandType.threePoint,
    '쓰리': VoiceCommandType.threePoint,
    '쓰리 포인트': VoiceCommandType.threePoint,
    '자유투': VoiceCommandType.freeThrow,
    '프리스로': VoiceCommandType.freeThrow,

    // 결과
    '성공': VoiceCommandType.made,
    '들어갔어': VoiceCommandType.made,
    '들어감': VoiceCommandType.made,
    '실패': VoiceCommandType.missed,
    '미스': VoiceCommandType.missed,
    '놓쳤어': VoiceCommandType.missed,

    // 스탯 관련
    '어시스트': VoiceCommandType.assist,
    '리바운드': VoiceCommandType.rebound,
    '오펜스 리바운드': VoiceCommandType.offensiveRebound,
    '공격 리바운드': VoiceCommandType.offensiveRebound,
    '디펜스 리바운드': VoiceCommandType.defensiveRebound,
    '수비 리바운드': VoiceCommandType.defensiveRebound,
    '스틸': VoiceCommandType.steal,
    '블락': VoiceCommandType.block,
    '블록': VoiceCommandType.block,
    '턴오버': VoiceCommandType.turnover,
    '파울': VoiceCommandType.foul,

    // 타이머 관련
    '타이머 시작': VoiceCommandType.timerStart,
    '타이머 스탑': VoiceCommandType.timerStop,
    '타이머 멈춰': VoiceCommandType.timerStop,
    '쿼터 종료': VoiceCommandType.quarterEnd,

    // 교체
    '교체': VoiceCommandType.substitution,
    '선수 교체': VoiceCommandType.substitution,

    // 실행 취소
    '취소': VoiceCommandType.undo,
    '되돌리기': VoiceCommandType.undo,
  };

  // 선수 번호 인식 패턴
  static final RegExp _numberPattern = RegExp(r'(\d{1,2})번');
  // 향후 선수 이름 인식용 (현재 미사용)
  // static final RegExp _playerNamePattern = RegExp(r'([\uAC00-\uD7AF]+)\s*(선수)?');

  /// 음성 텍스트에서 명령어 파싱
  VoiceCommandResult parseCommand(String text) {
    final normalizedText = text.trim().toLowerCase();
    final commands = <VoiceCommandType>[];
    int? playerNumber;
    String? playerName;

    // 선수 번호 추출
    final numberMatch = _numberPattern.firstMatch(text);
    if (numberMatch != null) {
      playerNumber = int.tryParse(numberMatch.group(1) ?? '');
    }

    // 명령어 매칭
    for (final entry in _commandPatterns.entries) {
      if (normalizedText.contains(entry.key.toLowerCase())) {
        commands.add(entry.value);
      }
    }

    // 명령어 우선순위 정렬 및 정리
    final primaryCommand = _determinePrimaryCommand(commands);

    return VoiceCommandResult(
      rawText: text,
      command: primaryCommand,
      allCommands: commands,
      playerNumber: playerNumber,
      playerName: playerName,
      confidence: _calculateConfidence(commands, primaryCommand),
    );
  }

  /// 주 명령어 결정 (우선순위 기반)
  VoiceCommandType? _determinePrimaryCommand(List<VoiceCommandType> commands) {
    if (commands.isEmpty) return null;

    // 우선순위: 액션 > 결과 > 기타
    const priority = [
      // 액션 (높은 우선순위)
      VoiceCommandType.shot,
      VoiceCommandType.twoPoint,
      VoiceCommandType.threePoint,
      VoiceCommandType.freeThrow,
      VoiceCommandType.rebound,
      VoiceCommandType.offensiveRebound,
      VoiceCommandType.defensiveRebound,
      VoiceCommandType.assist,
      VoiceCommandType.steal,
      VoiceCommandType.block,
      VoiceCommandType.turnover,
      VoiceCommandType.foul,
      VoiceCommandType.substitution,
      // 타이머 관련
      VoiceCommandType.timerStart,
      VoiceCommandType.timerStop,
      VoiceCommandType.quarterEnd,
      // 결과 (낮은 우선순위 - 보조 정보)
      VoiceCommandType.made,
      VoiceCommandType.missed,
      VoiceCommandType.undo,
    ];

    for (final cmd in priority) {
      if (commands.contains(cmd)) {
        return cmd;
      }
    }

    return commands.first;
  }

  /// 신뢰도 계산
  double _calculateConfidence(
    List<VoiceCommandType> commands,
    VoiceCommandType? primaryCommand,
  ) {
    if (primaryCommand == null) return 0.0;
    if (commands.length == 1) return 1.0;

    // 여러 명령어가 감지되면 신뢰도 감소
    return 1.0 - (commands.length - 1) * 0.15;
  }

  /// 명령어 실행 가능 여부
  bool canExecute(VoiceCommandResult result, {double minConfidence = 0.7}) {
    return result.command != null && result.confidence >= minConfidence;
  }

  /// 명령어를 사람이 읽을 수 있는 텍스트로 변환
  String commandToDisplayText(VoiceCommandType command) {
    switch (command) {
      case VoiceCommandType.shot:
        return '슛';
      case VoiceCommandType.twoPoint:
        return '2점 슛';
      case VoiceCommandType.threePoint:
        return '3점 슛';
      case VoiceCommandType.freeThrow:
        return '자유투';
      case VoiceCommandType.made:
        return '성공';
      case VoiceCommandType.missed:
        return '실패';
      case VoiceCommandType.assist:
        return '어시스트';
      case VoiceCommandType.rebound:
        return '리바운드';
      case VoiceCommandType.offensiveRebound:
        return '공격 리바운드';
      case VoiceCommandType.defensiveRebound:
        return '수비 리바운드';
      case VoiceCommandType.steal:
        return '스틸';
      case VoiceCommandType.block:
        return '블락';
      case VoiceCommandType.turnover:
        return '턴오버';
      case VoiceCommandType.foul:
        return '파울';
      case VoiceCommandType.timerStart:
        return '타이머 시작';
      case VoiceCommandType.timerStop:
        return '타이머 정지';
      case VoiceCommandType.quarterEnd:
        return '쿼터 종료';
      case VoiceCommandType.substitution:
        return '선수 교체';
      case VoiceCommandType.undo:
        return '취소';
    }
  }
}

/// 음성 명령 타입
enum VoiceCommandType {
  // 슛 관련
  shot,
  twoPoint,
  threePoint,
  freeThrow,

  // 슛 결과
  made,
  missed,

  // 스탯
  assist,
  rebound,
  offensiveRebound,
  defensiveRebound,
  steal,
  block,
  turnover,
  foul,

  // 타이머
  timerStart,
  timerStop,
  quarterEnd,

  // 기타
  substitution,
  undo,
}

/// 음성 명령 파싱 결과
class VoiceCommandResult {
  final String rawText;
  final VoiceCommandType? command;
  final List<VoiceCommandType> allCommands;
  final int? playerNumber;
  final String? playerName;
  final double confidence;

  const VoiceCommandResult({
    required this.rawText,
    this.command,
    required this.allCommands,
    this.playerNumber,
    this.playerName,
    required this.confidence,
  });

  bool get hasCommand => command != null;
  bool get hasPlayer => playerNumber != null || playerName != null;

  /// 슛 결과 포함 여부
  bool get includesMade => allCommands.contains(VoiceCommandType.made);
  bool get includesMissed => allCommands.contains(VoiceCommandType.missed);

  /// 슛 타입 명령인지
  bool get isShotCommand =>
      command == VoiceCommandType.shot ||
      command == VoiceCommandType.twoPoint ||
      command == VoiceCommandType.threePoint ||
      command == VoiceCommandType.freeThrow;

  @override
  String toString() {
    return 'VoiceCommandResult('
        'text: "$rawText", '
        'command: $command, '
        'player: $playerNumber, '
        'confidence: ${(confidence * 100).toStringAsFixed(0)}%'
        ')';
  }
}

/// 음성 인식 상태
enum VoiceListeningStatus {
  idle, // 대기 중
  listening, // 듣는 중
  processing, // 처리 중
  error, // 오류
  notAvailable, // 사용 불가
}

/// 음성 인식 상태 모델
class VoiceRecognitionState {
  final VoiceListeningStatus status;
  final String? currentText;
  final VoiceCommandResult? lastResult;
  final String? errorMessage;
  final bool isAvailable;

  const VoiceRecognitionState({
    this.status = VoiceListeningStatus.idle,
    this.currentText,
    this.lastResult,
    this.errorMessage,
    this.isAvailable = false,
  });

  VoiceRecognitionState copyWith({
    VoiceListeningStatus? status,
    String? currentText,
    VoiceCommandResult? lastResult,
    String? errorMessage,
    bool? isAvailable,
  }) {
    return VoiceRecognitionState(
      status: status ?? this.status,
      currentText: currentText ?? this.currentText,
      lastResult: lastResult ?? this.lastResult,
      errorMessage: errorMessage ?? this.errorMessage,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  bool get isListening => status == VoiceListeningStatus.listening;
  bool get isProcessing => status == VoiceListeningStatus.processing;
  bool get hasError => status == VoiceListeningStatus.error;
}

/// 음성 인식 상태 관리자
class VoiceRecognitionStateNotifier extends StateNotifier<VoiceRecognitionState> {
  VoiceRecognitionStateNotifier(this._ref)
      : super(const VoiceRecognitionState()) {
    _checkAvailability();
  }

  final Ref _ref;
  StreamSubscription? _recognitionSubscription;

  /// 음성 인식 사용 가능 여부 확인
  Future<void> _checkAvailability() async {
    // TODO: speech_to_text 패키지 통합 시 실제 확인 로직 구현
    // 현재는 플레이스홀더
    await Future.delayed(const Duration(milliseconds: 100));

    state = state.copyWith(
      isAvailable: true, // speech_to_text 통합 후 실제 값으로 변경
      status: VoiceListeningStatus.idle,
    );
  }

  /// 음성 인식 시작
  Future<void> startListening() async {
    if (!state.isAvailable) {
      state = state.copyWith(
        status: VoiceListeningStatus.notAvailable,
        errorMessage: '음성 인식을 사용할 수 없습니다',
      );
      return;
    }

    state = state.copyWith(
      status: VoiceListeningStatus.listening,
      currentText: null,
      errorMessage: null,
    );

    // TODO: speech_to_text 통합 시 실제 음성 인식 시작
    debugPrint('[VoiceCommand] 음성 인식 시작');
  }

  /// 음성 인식 중지
  Future<void> stopListening() async {
    state = state.copyWith(status: VoiceListeningStatus.idle);
    await _recognitionSubscription?.cancel();
    debugPrint('[VoiceCommand] 음성 인식 중지');
  }

  /// 인식된 텍스트 처리
  void onRecognitionResult(String text, {bool isFinal = false}) {
    final service = _ref.read(voiceCommandServiceProvider);

    state = state.copyWith(
      currentText: text,
      status: isFinal
          ? VoiceListeningStatus.processing
          : VoiceListeningStatus.listening,
    );

    if (isFinal) {
      final result = service.parseCommand(text);
      state = state.copyWith(
        lastResult: result,
        status: VoiceListeningStatus.idle,
      );
      debugPrint('[VoiceCommand] 파싱 결과: $result');
    }
  }

  /// 에러 처리
  void handleError(String error) {
    state = state.copyWith(
      status: VoiceListeningStatus.error,
      errorMessage: error,
    );
    debugPrint('[VoiceCommand] 오류: $error');
  }

  /// 상태 초기화
  void reset() {
    state = const VoiceRecognitionState(isAvailable: true);
  }

  @override
  void dispose() {
    _recognitionSubscription?.cancel();
    super.dispose();
  }
}

/// 음성 명령 실행 콜백 타입
typedef VoiceCommandCallback = void Function(VoiceCommandResult result);

/// 음성 명령 핸들러 믹스인
///
/// 화면에서 음성 명령을 처리할 때 사용
mixin VoiceCommandHandler {
  /// 음성 명령 처리
  void handleVoiceCommand(VoiceCommandResult result) {
    if (!result.hasCommand) return;

    switch (result.command!) {
      case VoiceCommandType.shot:
      case VoiceCommandType.twoPoint:
      case VoiceCommandType.threePoint:
      case VoiceCommandType.freeThrow:
        onShotCommand(result);
        break;

      case VoiceCommandType.assist:
        onAssistCommand(result);
        break;

      case VoiceCommandType.rebound:
      case VoiceCommandType.offensiveRebound:
      case VoiceCommandType.defensiveRebound:
        onReboundCommand(result);
        break;

      case VoiceCommandType.steal:
        onStealCommand(result);
        break;

      case VoiceCommandType.block:
        onBlockCommand(result);
        break;

      case VoiceCommandType.turnover:
        onTurnoverCommand(result);
        break;

      case VoiceCommandType.foul:
        onFoulCommand(result);
        break;

      case VoiceCommandType.timerStart:
        onTimerStartCommand();
        break;

      case VoiceCommandType.timerStop:
        onTimerStopCommand();
        break;

      case VoiceCommandType.quarterEnd:
        onQuarterEndCommand();
        break;

      case VoiceCommandType.substitution:
        onSubstitutionCommand(result);
        break;

      case VoiceCommandType.undo:
        onUndoCommand();
        break;

      case VoiceCommandType.made:
      case VoiceCommandType.missed:
        // 단독 결과 명령은 무시 (슛과 함께 처리)
        break;
    }
  }

  // 오버라이드해서 구현할 메서드들
  void onShotCommand(VoiceCommandResult result) {}
  void onAssistCommand(VoiceCommandResult result) {}
  void onReboundCommand(VoiceCommandResult result) {}
  void onStealCommand(VoiceCommandResult result) {}
  void onBlockCommand(VoiceCommandResult result) {}
  void onTurnoverCommand(VoiceCommandResult result) {}
  void onFoulCommand(VoiceCommandResult result) {}
  void onTimerStartCommand() {}
  void onTimerStopCommand() {}
  void onQuarterEndCommand() {}
  void onSubstitutionCommand(VoiceCommandResult result) {}
  void onUndoCommand() {}
}
