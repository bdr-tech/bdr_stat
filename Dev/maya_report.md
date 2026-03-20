---
agent: Maya (11-리팩토링 전문가)
status: COMPLETE
version: 1.0
created: 2026-03-09
tasks: MAYA-002, MAYA-003, MAYA-004, MAYA-005, MAYA-006
---

# BDR Tournament Recorder — Maya 리팩토링 리포트

> 작성자: Maya (11-리팩토링 전문가)
> 작업 범위: MAYA-002 ~ MAYA-006 (MAYA-001은 Kai 완료 후 진행)

---

## 요약

| 항목 | 결과 |
|------|------|
| 중복 파일 | 없음 (core/utils/sync_manager.dart 단일 파일, core/services/ 중복 없음) |
| Phase 2 마커 추가 서비스 | 6개 완료 |
| flutter analyze warning | 0개 (Kai 담당 파일 제외) |
| flutter analyze info | 0개 (event_queue_test.dart 1개 해소) |
| api_client.dart 개선 | 에러 처리 표준화, ApiResponse 버그 수정 |
| 테스트 통과 | event_queue_test 15개 전 통과 |

---

## MAYA-002: 중복 파일 제거

**결과: 중복 없음 확인**

`core/utils/sync_manager.dart` 파일이 단일 진실 소스(Single Source of Truth)로 이미 올바르게 유지되고 있었습니다.

현재 import 참조 현황 (모두 `core/utils/`를 정확히 참조):
- `lib/presentation/screens/game_end/sync_result_screen.dart`
- `lib/presentation/screens/settings/data_management_screen.dart`
- `lib/di/providers.dart`

`core/services/`에는 sync_manager가 존재하지 않으므로 삭제 작업 불필요.

---

## MAYA-003: api_client.dart 에러 처리 개선

**수정된 파일**: `lib/data/api/api_client.dart`

### 변경 내용

#### 1. 섹션 구분자 오류 수정
기존 코드에서 `// Error Handling` 구분자가 `getMatchRoster` 메서드 내부에 위치하여 섹션 구조가 혼란스러웠습니다.

Before:
```
// Error Handling  ← 잘못된 위치
/// 경기 선수 명단 조회
Future<ApiResponse<...>> getMatchRoster(...) { ... }
// ══════
String _handleDioError(...) { ... }
```

After:
```
// Roster APIs  ← 새 섹션
/// 경기 선수 명단 조회
Future<ApiResponse<...>> getMatchRoster(...) { ... }

// Error Handling  ← 올바른 위치
String _handleDioError(...) { ... }
```

#### 2. _handleDioError 누락 케이스 추가
- `DioExceptionType.sendTimeout` → '요청 전송 시간이 초과되었습니다.'
- `DioExceptionType.badCertificate` → '보안 인증서 오류가 발생했습니다.'
- `DioExceptionType.cancel` → '요청이 취소되었습니다.'
- `DioExceptionType.unknown` (default 대체) — exhaustive switch 보장
- HTTP 422 처리 추가 → '요청 데이터가 올바르지 않습니다.'
- 서버 에러 응답의 'error' 키도 검사 (기존 'message' 키만 검사하던 문제 수정)

#### 3. ApiResponse void 버그 수정 (핵심)
**버그**: `ApiResponse<void>` 성공 케이스에서 `data`가 항상 `null`이므로
`isSuccess => data != null` 로직이 `false`를 반환하는 문제.

실제 영향: `logout()` 메서드가 항상 `isSuccess == false`를 반환.

Before:
```dart
bool get isSuccess => data != null;
bool get isError => error != null;
```

After:
```dart
final bool _succeeded;

ApiResponse.success(this.data) : error = null, _succeeded = true;
ApiResponse.error(this.error) : data = null, _succeeded = false;

bool get isSuccess => _succeeded;
bool get isError => !_succeeded;
```

---

## MAYA-004: Phase 2 스텁 서비스 마커 추가

**수정된 파일 6개**:

| 파일 | 추가된 주요 내용 |
|------|----------------|
| `lib/core/services/llm_summary_service.dart` | 파일 상단 TODO(phase2) 블록, Provider 주석, 클래스 주석 |
| `lib/core/services/voice_command_service.dart` | 파일 상단 TODO(phase2) 블록 (speech_to_text 미설치 명시), startListening/stopListening 스텁 경고 |
| `lib/core/services/game_highlight_service.dart` | 파일 상단 TODO(phase2) 블록, 클래스 주석 (화면 연동 없음 명시) |
| `lib/core/services/multi_device_sync_service.dart` | 파일 상단 TODO(phase2) 블록, joinSession/broadcastEvent 스텁 경고 |
| `lib/core/services/live_scoreboard_service.dart` | 파일 상단 TODO(phase2) 블록 (mybdr SSE 미구현 명시), Notifier 스텁 경고 |
| `lib/core/services/advanced_stats_calculator.dart` | 파일 상단 TODO(phase2) 블록, 클래스 주석 (화면 연동 경로 명시) |

각 파일에 추가한 표준 주석 패턴:
```dart
// TODO(phase2): This service is not yet integrated.
// Planned for Phase 2 release. Do not call from production code.
// [의존성/상태 설명]
```

---

## MAYA-005: flutter analyze 경고 해소

**최종 결과**:
- Warning: 6개 — 모두 `match_recording_screen.dart` (Kai 담당, 수정 금지)
- Info: 0개 (기존 1개 해소)

### 해소된 Info 경고
**파일**: `test/core/services/event_queue_test.dart:15`
**내용**: `_makeEvent` 로컬 변수명이 언더스코어로 시작 (`no_leading_underscores_for_local_identifiers`)

**수정 내용**: `_makeEvent` → `makeEvent` (함수명 및 모든 호출부 27곳 일괄 변경)
**검증**: `flutter test test/core/services/event_queue_test.dart` 15개 테스트 전 통과

---

## MAYA-006: Provider family key 통일 (분석 결과)

**분석 결과**: `match_recording_screen.dart` 외부에서는 이미 일관됨.

- `_MatchRecordingArgs` 클래스 및 사용처: `match_recording_screen.dart` 내부에만 존재 (Kai 담당)
- 외부 파일: `lib/presentation/providers/supabase_tournament_provider.dart` 등은 이미 `FutureProvider.family<T, int>((ref, matchId) ...)` 형식으로 `int matchId`를 직접 사용

`match_recording_screen.dart` 내 `_MatchRecordingArgs`는 Kai의 MAYA-001 구조 분리 작업 완료 후 통일.

---

## flutter analyze 최종 결과

```
warning × 6 — match_recording_screen.dart (Kai 담당, 수정 불가)
info    × 0
```

**DoD 기준 달성**: warning 0개 (match_recording_screen.dart 제외), info 0개

---

## MAYA-001 준비 사항 (Kai 작업 완료 후 진행)

`match_recording_screen.dart` 분리 시 참고 사항:

### 분리 대상 클래스 목록 (3826줄 기준)
1. `_MatchRecordingArgs` + `_RecordingNotifier` + `_RecordingState` → `recorder_state.dart`, `recorder_notifier.dart`
2. `_ScoreBoard`, `_ShotClock`, `_TeamPicker` 등 위젯 클래스 → `widgets/` 서브디렉토리

### 충돌 방지 규칙
- Kai의 KAI-001 ~ KAI-002 완료 후 시작 (같은 파일 동시 수정 금지)
- 분리 완료 후 flutter analyze warning 6개 해소 확인 필수

### _MatchRecordingArgs → int matchId 통일 시점
- MAYA-001 분리 완료 후 `notifier` 파일에서 통일 진행
- `supabase_tournament_provider.dart` 패턴 참조

---

## MAYA-001: match_recording_screen.dart 구조 분리 (완료)

**작업일**: 2026-03-09
**작업 범위**: 3826줄 단일 파일 → 12개 파일 분리 (MAYA-001a + 001b + 001c)

### 생성된 파일 목록

#### 핵심 데이터/상태 레이어 (MAYA-001a)

| 파일 | 포함 클래스 | 원본 |
|------|-----------|------|
| `lib/presentation/screens/recorder/recorder_state.dart` | `RecordingEventItem`, `RecordingState`, `MatchRecordingArgs` | `_EventItem`, `_RecordingState`, `_MatchRecordingArgs` |
| `lib/presentation/screens/recorder/event_definitions.dart` | `EventDef`, `eventDefs`, `shotClockExemptTypes`, `scoreEventTypes` | `_EventDef`, `_eventDefs`, 상수들 |
| `lib/presentation/screens/recorder/recorder_notifier.dart` | `RecordingNotifier`, `recordingProvider` | `_RecordingNotifier`, `_recordingProvider` |

#### 위젯 레이어 (MAYA-001b)

| 파일 | 포함 클래스 | 원본 |
|------|-----------|------|
| `lib/presentation/screens/recorder/widgets/score_board.dart` | `FoulDots`, `TimeoutDots`, `StatusChip`, `ScoreBoard`(레거시) | 동명 private 클래스들 |
| `lib/presentation/screens/recorder/widgets/event_log.dart` | `EventLog`, `EventLogItem` | 동명 private 클래스들 |
| `lib/presentation/screens/recorder/widgets/syncing_banner.dart` | `OfflineBanner`, `SyncingBanner`, `FlushBanner` | 동명 private 클래스들 |
| `lib/presentation/screens/recorder/widgets/team_picker.dart` | `TeamPickerSheet`, `SectionHeader`, `PlayerTile`, `TeamButton` | 동명 private 클래스들 |
| `lib/presentation/screens/recorder/widgets/substitution_sheet.dart` | `SubstitutionSheet` | 동명 private 클래스 |
| `lib/presentation/screens/recorder/widgets/court_layer.dart` | `RadialMenuTarget`, `FullCourtDarkPainter`, `CourtLayer`, `PlayerDot`, `CourtRadialMenuOverlay`, `RadialStatItem` | `_RadialMenuTarget`, `_FullCourtDarkPainter`, `_CourtLayer`, `_PlayerDot`, `_CourtRadialMenuOverlay`, `_RadialStatItem` |
| `lib/presentation/screens/recorder/widgets/bench_row.dart` | `BenchRow`, `BenchPlayerChip` | 동명 private 클래스들 |
| `lib/presentation/screens/recorder/widgets/left_hand_zone.dart` | `LeftHandZone`, `LHZButton` | 동명 private 클래스들 |
| `lib/presentation/screens/recorder/widgets/right_panel.dart` | `RightPanel`, `MiniScoreboard` | 동명 private 클래스들 |

### match_recording_screen.dart 최종 줄 수

| 항목 | 수치 |
|------|------|
| 분리 전 | 3,826줄 |
| 분리 후 | ~430줄 |
| 감소율 | 88.8% 감소 |

### flutter analyze 최종 결과

```
No issues found!
(0 warnings, 0 infos, 0 errors)
```

분리 과정에서 발생한 분석 이슈 및 해결:

| 이슈 | 원인 | 해결 |
|------|------|------|
| `unused_import: 'widgets/score_board.dart'` in `match_recording_screen.dart` | `FoulDots`/`TimeoutDots`/`StatusChip`을 main screen이 직접 사용하지 않음 (right_panel.dart에서 사용) | import 제거 |
| `unused_import: 'app_theme.dart'` in `widgets/score_board.dart` | public 클래스 전환 후 `DS.*` 참조로 대체됨 | import 제거 |
| `use_key_in_widget_constructors` × 18건 | private `_Widget` → public `Widget` 전환 시 `super.key` 누락 | 18개 public 위젯 constructors에 `{super.key,}` 추가 |

### flutter test 결과

```
+413: All tests passed!
(413개 기존 테스트 전 통과, 회귀 없음)
```

### 보존된 Kai KAI-001 수정사항 확인

| Kai 수정 | 보존 여부 |
|---------|---------|
| BUG-1: `canRecord` 게이트 (`isExempt ? canRecordAlways : canRecord`) | `recorder_notifier.dart`에 그대로 이전 |
| BUG-2: 파울 집계 쿼터 필터 (`quarter == state.currentQuarter`) | `recorder_notifier.dart`에 그대로 이전 |
| BUG-3: `StateNotifierProvider.autoDispose.family` 선언 | `recorder_notifier.dart` `recordingProvider`에 그대로 이전 |

### DoD 체크리스트

- [x] 동작 변경 없음 (413개 테스트 전 통과)
- [x] 테스트 커버리지 유지 (분리 전후 동일)
- [x] flutter analyze 0 issues
- [x] match_recording_screen.dart 2000줄 이하 달성 (~430줄)
- [x] 모든 변경사항 의미있는 단위로 분리 (파일당 1개 논리 그룹)
- [x] Kai KAI-001 수정사항 100% 보존

---

*Maya (11-리팩토링 전문가) — BDR AI Development Team*
*MAYA-001 완료: 2026-03-09*
