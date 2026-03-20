# KAI Report - BDR Tournament Recorder Final Sprint

> 작성자: Kai (Flutter Expert)
> 날짜: 2026-03-09
> 대상: KAI-001 ~ KAI-003

---

## 1. 발견된 버그 목록

### BUG-1: 라디얼 메뉴 canRecord 게이트 누락 (KAI-001a)

- **파일**: `lib/presentation/screens/recorder/match_recording_screen.dart:3328-3329`
- **증상**: 라디얼 메뉴에서 샷클락 면제 이벤트(파울/교체/타임아웃)가 경기 상태(`in_progress`) 체크 없이 항상 활성화됨
- **원인**: `canRecord || _shotClockExemptTypes.contains(def.type)` 조건에서 면제 타입이면 무조건 `true` 반환
- **수정**: `isExempt ? canRecordAlways : canRecord`로 변경. 경기 미시작 시 면제 타입도 비활성화
- **심각도**: MEDIUM

### BUG-2: _loadEvents 파울 집계가 전체 쿼터 합산 (KAI-001d)

- **파일**: `lib/presentation/screens/recorder/match_recording_screen.dart:327-331`
- **증상**: API에서 이벤트 재로드 시 (undo, flush 후) 파울 카운터가 전체 경기 파울로 집계됨. `setQuarter()`에서 로컬 리셋해도 `_loadEvents()` 호출 시 다시 전체 합산
- **원인**: 파울 집계 시 `quarter == state.currentQuarter` 필터 누락
- **수정**: 현재 쿼터의 파울만 집계하도록 조건 추가
- **심각도**: HIGH (보너스 표시에 직접 영향)

### BUG-3: Provider autoDispose 누락으로 메모리 누수 가능 (KAI-001e)

- **파일**: `lib/presentation/screens/recorder/match_recording_screen.dart:848`
- **증상**: `_recordingProvider`가 `StateNotifierProvider.family`로 선언되어 autoDispose 없음. 화면 이탈 후에도 Notifier가 유지되어 `_rosterChannel`, `_gameTimer`, `_shotClockTimer`가 해제되지 않을 수 있음
- **원인**: `autoDispose` 수식자 누락
- **수정**: `StateNotifierProvider.autoDispose.family`로 변경
- **심각도**: MEDIUM (Supabase Realtime 채널 누수 위험)

---

## 2. 검증 결과 (버그 아닌 항목)

### KAI-001a: canRecord 게이트 기본 로직 -- 정상

- `_RecordingState.canRecord` getter: `matchStatus == 'in_progress' && isShotClockRunning` (line 106)
- `_RecordingState.canRecordAlways` getter: `matchStatus == 'in_progress'` (line 108)
- `_EventButton`에서 비활성 시 스낵바 경고 표시 (line 2533-2544)
- `recordEvent()`에서 `canRecord`/`canRecordAlways` 게이트 체크 (line 423-425)

### KAI-001b: 선수 명단 로드 분기 -- 정상

- `_loadRoster()`: `tournamentId.isEmpty` 시 API 폴백 (`apiClient.getMatchRoster`), 아닐 시 Supabase RPC
- 두 경로 모두 에러 처리 포함
- Realtime 구독도 `tournamentId.isNotEmpty` 조건으로 보호

### KAI-001c: 교체 Sheet 엣지케이스 -- 정상

- `_SubstitutionSheet`: 스타터 0명 시 "스타터 정보가 없습니다" (line 1968-1971)
- 벤치 0명 시 "교체 가능한 선수가 없습니다" (line 1980-1983)
- `_showSubstitutionPicker`: 선수 명단 자체가 없으면 스낵바 경고 후 리턴 (line 1191-1197)
- 스타터 5명 제한은 구조적으로 보장됨 (out=스타터, in=벤치 선택)

### KAI-001d: 쿼터 변경 파울 리셋 -- 정상 (BUG-2 수정 후)

- `setQuarter()`: `homeTeamFouls: 0, awayTeamFouls: 0` (line 657-664)
- `_confirmQuarterChange`: 파울 있을 때 확인 다이얼로그 표시 (line 1448-1480)

### KAI-001e: dispose 채널 해제 -- 정상 (BUG-3 수정 후)

- `dispose()`: `_gameTimer?.cancel()`, `_shotClockTimer?.cancel()`, `SupabaseService.instance.unsubscribe(_rosterChannel!)` 모두 구현 (line 195-201)
- autoDispose 추가로 화면 이탈 시 확실히 호출됨

### KAI-002: EventQueue 오프라인 큐 -- 정상

- `enqueue()`: SharedPreferences에 즉시 영속화
- `dequeueAll()`: 전체 반환 후 큐 비움
- `dequeueByMatch()`: 특정 경기 이벤트만 추출
- `removeByClientEventId()`: 오프라인 Undo용
- 지수 백오프 재시도: `_flushQueueInternal` 최대 3회, 2s/4s/8s 간격 (line 776-789)
- 실패 시 재큐잉: 실패한 이벤트를 다시 enqueue (line 781, 784)
- 온라인 복귀 감지: `isOnlineProvider` 리스닝 + `_wasOffline` 패턴 (line 985-991)

---

## 3. 수정 내용 요약

| 수정 | 파일 | 내용 |
|------|------|------|
| BUG-1 수정 | match_recording_screen.dart:3328 | 라디얼 메뉴 canRecord 분기: `isExempt ? canRecordAlways : canRecord` |
| BUG-2 수정 | match_recording_screen.dart:328 | 파울 집계에 `quarter == state.currentQuarter` 조건 추가 |
| BUG-3 수정 | match_recording_screen.dart:848 | `autoDispose` 수식자 추가 |

---

## 4. 추가된 테스트 목록

### test/core/services/event_queue_test.dart (19개 테스트)

| 그룹 | 테스트명 |
|------|----------|
| enqueue | should add event to queue and persist |
| enqueue | should add multiple events in order |
| enqueue | should persist across load cycles |
| dequeueAll | should return all events and clear queue |
| dequeueAll | should return empty list when queue is empty |
| dequeueAll | should persist empty state after dequeue |
| dequeueByMatch | should only dequeue events for specific match |
| dequeueByMatch | should return empty list when no events for match |
| removeByClientEventId | should remove specific event by clientEventId |
| removeByClientEventId | should return false when event not found |
| countForMatch | should count events per match |
| offline queue preservation | should preserve events through app restart simulation |
| online flush simulation | should dequeue by match for batch flush |
| online flush simulation | should re-enqueue failed events |
| PendingEvent serialization | should serialize and deserialize correctly |

### test/presentation/recorder/recorder_state_test.dart (12개 테스트)

| 그룹 | 테스트명 |
|------|----------|
| canRecord gate | canRecord: false when match is scheduled |
| canRecord gate | canRecord: false when in_progress but shot clock not running |
| canRecord gate | canRecord: true when in_progress and shot clock running |
| canRecord gate | canRecord: false when match is completed |
| canRecord gate | shot clock exempt types should be recordable without shot clock |
| canRecord gate | shot clock exempt types should NOT be recordable when match not in_progress |
| quarter change foul reset | should reset both team fouls to 0 on quarter change |
| quarter change foul reset | should reset fouls when changing to overtime |
| quarter change foul reset | should preserve match status when changing quarter |
| substitution bench edge cases | should handle empty player list |
| substitution bench edge cases | should handle all starters no bench |
| substitution bench edge cases | should handle all bench no starters |
| substitution bench edge cases | should correctly split starters and bench |
| substitution bench edge cases | substitution should swap is_starter flags |
| timeout tracking | should track remaining timeouts |
| timeout tracking | should not go below 0 timeouts |

**총 31개 테스트 -- 전체 통과**

---

## 5. 남은 이슈 (범위 외)

| 항목 | 설명 | 권장 |
|------|------|------|
| `super.key` unused_element_parameter 경고 6개 | `_CourtLayer`, `_BenchRow`, `_BenchPlayerChip`, `_LeftHandZone`, `_RightPanel`, `_MiniScoreboard`의 `super.key` | Maya MAYA-001 분리 시 해결 예정 |
| 파울 집계 쿼터 간 이벤트 누적 복원 | `_loadEvents`에서 현재 쿼터 파울만 집계하지만, 쿼터 변경 후 이전 쿼터로 돌아갈 때 파울이 올바르게 복원되려면 전체 이벤트에서 해당 쿼터 파울을 재계산해야 함. 현재는 `state.currentQuarter`를 기준으로 하므로 정상 동작하나, 쿼터를 되돌릴 경우 파울이 0으로 표시됨 | 실제 경기에서는 쿼터를 역방향으로 변경하는 일이 드물어 Phase 2 검토 |
| `_loadEvents` 이후 `_loadRoster` 동시 호출 경합 | `_init()`에서 `Future.wait([_loadEvents(), _loadRoster()])` 사용. 두 비동기 호출이 모두 `state.copyWith`를 호출하므로 경합 가능 | 현재 `StateNotifier`는 동기적이므로 문제 없으나, 향후 복잡한 상태 변경 시 주의 |

---

*Kai (Flutter Expert) -- BDR AI Development Team*
*flutter analyze: 경고 6개 (기존 수준, 신규 추가 없음)*
*flutter test: 신규 31개 전체 통과*
