---
agent: Maya (11-리팩토링 전문가)
created: 2026-03-09
project: BDR Tournament Recorder
---

# 코드 스멜 보고서

## 발견된 스멜 목록

| ID | 스멜 타입 | 위치 | 심각도 | 상태 |
|----|---------|------|--------|------|
| S-001 | 거대 클래스 (Large Class) | `lib/presentation/screens/recorder/match_recording_screen.dart` 3826줄 | 낮음 | MAYA-001 대기 (Kai 완료 후) |
| S-002 | 에러 처리 비일관성 (Inconsistent Error Handling) | `lib/data/api/api_client.dart` — `DioExceptionType` 케이스 누락 | 낮음 | MAYA-003에서 해소 |
| S-003 | ApiResponse void 버그 (Null Check Logic Error) | `lib/data/api/api_client.dart:477` — `isSuccess => data != null` | 중간 | MAYA-003에서 해소 |
| S-004 | 섹션 구분자 오류 (Dead Comment) | `lib/data/api/api_client.dart` — `// Error Handling` 위치 오류 | 낮음 | MAYA-003에서 해소 |
| S-005 | 스텁 연동 없는 서비스 (Speculative Generality) | `lib/core/services/` 6개 파일 — Phase 2 미연동 서비스 | 낮음 | MAYA-004에서 마커 추가 |
| S-006 | 테스트 로컬 변수 네이밍 (Naming Convention) | `test/core/services/event_queue_test.dart:15` — `_makeEvent` | 낮음 | MAYA-005에서 해소 |
| S-007 | Provider family key 혼재 | `match_recording_screen.dart` — `_MatchRecordingArgs` vs `int matchId` | 낮음 | MAYA-001 완료 후 통일 |

## 해소된 스멜: 4개 (S-002, S-003, S-004, S-006)
## 마커 추가: 1개 (S-005)
## 보류 중: 2개 (S-001, S-007 — Kai 작업 완료 후)
