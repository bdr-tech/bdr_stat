// UseCase Layer - 액션 연동 자동화
//
// CLAUDE.md 요구사항에 따른 UseCase 구현:
// - 스틸 → 상대 턴오버
// - 블락 → 상대 슛 실패
// - 오펜시브 파울 → 본인 턴오버
// - 슈팅 파울 → 자유투 시퀀스
// - 5파울 → fouledOut 플래그 (강제 교체 모달용)

export 'linked_action_result.dart';
export 'record_steal_usecase.dart';
export 'record_block_usecase.dart';
export 'record_foul_usecase.dart';
