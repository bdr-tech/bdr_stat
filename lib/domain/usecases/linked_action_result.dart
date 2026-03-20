/// 연결된 액션 기록 결과
///
/// CLAUDE.md 액션 연동 자동화 요구사항 지원:
/// - 스틸 → 상대 턴오버
/// - 블락 → 상대 슛 실패
/// - 오펜시브 파울 → 본인 턴오버
/// - 슈팅 파울 → 자유투 시퀀스
class LinkedActionResult {
  /// 주요 액션의 localId (예: 스틸)
  final String primaryActionId;

  /// 연결된 액션의 localId (예: 턴오버)
  final String? linkedActionId;

  /// 성공 여부
  final bool success;

  /// 에러 메시지 (실패 시)
  final String? errorMessage;

  /// 추가 데이터 (예: 자유투 시퀀스 정보)
  final Map<String, dynamic>? metadata;

  const LinkedActionResult({
    required this.primaryActionId,
    this.linkedActionId,
    this.success = true,
    this.errorMessage,
    this.metadata,
  });

  /// 성공 결과 생성
  factory LinkedActionResult.success({
    required String primaryActionId,
    String? linkedActionId,
    Map<String, dynamic>? metadata,
  }) {
    return LinkedActionResult(
      primaryActionId: primaryActionId,
      linkedActionId: linkedActionId,
      success: true,
      metadata: metadata,
    );
  }

  /// 실패 결과 생성
  factory LinkedActionResult.failure({
    required String errorMessage,
  }) {
    return LinkedActionResult(
      primaryActionId: '',
      success: false,
      errorMessage: errorMessage,
    );
  }

  /// 연결된 액션 ID들 (Undo 시 사용)
  List<String> get allActionIds {
    final ids = [primaryActionId];
    if (linkedActionId != null) {
      ids.add(linkedActionId!);
    }
    return ids;
  }
}

/// 파울 타입
enum FoulType {
  /// 일반 파울 (퍼스널 파울)
  personal,

  /// 슈팅 파울 (자유투 발생)
  shooting,

  /// 오펜시브 파울 (공격 파울 - 턴오버 발생)
  offensive,

  /// 테크니컬 파울
  technical,

  /// 플래그런트 파울
  flagrant,
}

/// 자유투 시퀀스 정보
class FreeThrowSequence {
  /// 자유투 개수
  final int totalShots;

  /// 슈터 선수 ID
  final int shooterPlayerId;

  /// 파울 선수 ID
  final int foulPlayerId;

  const FreeThrowSequence({
    required this.totalShots,
    required this.shooterPlayerId,
    required this.foulPlayerId,
  });

  factory FreeThrowSequence.fromMap(Map<String, dynamic> map) {
    return FreeThrowSequence(
      totalShots: map['totalShots'] as int,
      shooterPlayerId: map['shooterPlayerId'] as int,
      foulPlayerId: map['foulPlayerId'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalShots': totalShots,
      'shooterPlayerId': shooterPlayerId,
      'foulPlayerId': foulPlayerId,
    };
  }
}
