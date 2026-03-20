---
agent: Maya (11-리팩토링 전문가)
created: 2026-03-09
---

# 리팩토링 이력

## 2026-03-09

### MAYA-002: 중복 파일 확인
- **기법**: 중복 제거 (Remove Duplicate)
- **결과**: core/utils/sync_manager.dart 단일 파일로 이미 정리됨, 추가 작업 불필요

### MAYA-003: api_client.dart 에러 처리 표준화
- **기법**: Reorganize Code (섹션 재정리) + Add Guard Clause (누락 케이스 추가) + Fix Logic Bug
- **파일**: `lib/data/api/api_client.dart`
- **변경 내용**:
  1. 섹션 구분자 위치 수정 (Roster APIs / Error Handling 명확 분리)
  2. `_handleDioError` — sendTimeout, badCertificate, cancel, unknown 케이스 추가
  3. HTTP 422 처리 추가
  4. 서버 에러 응답에서 'error' 키도 검사하도록 개선
  5. `ApiResponse.isSuccess` 로직 버그 수정 (`data != null` → `_succeeded` 플래그 기반)
- **테스트 영향**: 기존 동작 보존 (isSuccess 버그 수정으로 logout() 메서드가 올바른 결과 반환)

### MAYA-004: Phase 2 스텁 서비스 마커 추가
- **기법**: Add Explanatory Comment (설명 주석 추가)
- **파일**: 6개
  - `lib/core/services/llm_summary_service.dart`
  - `lib/core/services/voice_command_service.dart`
  - `lib/core/services/game_highlight_service.dart`
  - `lib/core/services/multi_device_sync_service.dart`
  - `lib/core/services/live_scoreboard_service.dart`
  - `lib/core/services/advanced_stats_calculator.dart`
- **변경 내용**: 각 파일 상단에 `// TODO(phase2):` 블록 추가, 스텁 메서드에 개별 주석 추가

### MAYA-005: flutter analyze info 경고 해소
- **기법**: Rename (변수명 변경)
- **파일**: `test/core/services/event_queue_test.dart`
- **변경 내용**: `_makeEvent` → `makeEvent` (함수명 + 27개 호출부)
- **검증**: flutter test 15개 전 통과
