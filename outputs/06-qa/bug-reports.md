# BDR Sprint 2 — 결함 보고서

> **작성자**: Nora (QA 엔지니어, 11년차)
> **작성일**: 2026-03-16
> **버전**: Sprint 2 (FR-001~FR-013)
> **범례**: Critical(배포 불가) / Major(심각 오동작) / Minor(기능 저하) / Trivial(미관/개선)

---

## BUG-001: Undo 시점 ON-COURT 불일치로 plusMinus 역산 오류 가능성

- **심각도**: Minor
- **우선순위**: P3
- **관련 요구사항**: FR-003 (plusMinus ON-COURT 연동)
- **관련 테스트케이스**: TC-012
- **환경**: Flutter / Drift DB / GameStateProvider
- **상태**: Open

**재현 단계**:
1. 선수 A, B, C가 코트에 있는 상태에서 홈팀 득점 기록 (A+1, B+1, C+1 적용)
2. 선수 교체: A OUT → D IN (A는 벤치, D가 코트)
3. 이전 득점 Undo 시도

**기대 결과**: Undo 시 득점 당시 코트 선수(A, B, C)의 plusMinus가 -1씩 역산되어야 함

**실제 결과**: `revertPlusMinusForScore()`는 현재 코트 선수(B, C, D) 기준으로 역산. 선수 A는 역산에서 누락되고, D는 부당하게 -1 적용됨.

**코드 위치**: `player_stats_dao.dart` — `revertPlusMinusForScore()`

**근본 원인**: PlayByPlay에 득점 시점 ON-COURT 스냅샷이 없음. 역산이 현재 코트 기준으로만 동작.

**수정 방향**:
```dart
// 현재: 현재 ON-COURT 기준 역산
// 개선안 1 (단기): PlayByPlay에 득점 시 on_court_snapshot 필드 추가
//   → revertPlusMinusForScore()에서 snapshot 사용
// 개선안 2 (현실적 타협): +/- Undo는 득점 직후에만 허용
//   → 교체 후 이전 득점 Undo는 +/- 변경 없이 점수만 취소
```

**릴리스 차단 여부**: 아니오 — 교체가 없는 일반적 Undo 시나리오는 정확. 선수 교체 후 Undo는 드문 시나리오이며 Minor 수준.

---

## BUG-002: watchUnsyncedCount / watchSyncInfo 무한 루프 잠재 위험

- **심각도**: Minor
- **우선순위**: P3
- **관련 요구사항**: FR-002 (오프라인 동기화)
- **관련 테스트케이스**: TC-038
- **환경**: sync_manager.dart / Flutter
- **상태**: Open

**재현 단계**:
1. `watchUnsyncedCount()` 또는 `watchSyncInfo()` Stream을 구독
2. Provider 또는 위젯이 dispose 없이 구독을 유지한 채 화면 이탈
3. 메모리 누수 모니터링

**기대 결과**: 위젯 dispose 시 Stream 자동 취소

**실제 결과**: `while(true)` 루프 기반 Stream이므로, 구독자가 없어도 루프가 종료되지 않음. Dart의 비동기 generator는 수동 취소 메커니즘 없이는 GC 되지 않을 수 있음.

**코드 위치**: `sync_manager.dart` 라인 1016–1034

```dart
// 현재 구현 (문제)
Stream<int> watchUnsyncedCount() async* {
  while (true) {          // 취소 불가능한 무한 루프
    yield await getUnsyncedMatchCount();
    await Future.delayed(const Duration(seconds: 30));
  }
}
```

**수정 방향**:
```dart
// 권고: StreamController 기반으로 전환
StreamController<int>? _unsyncedCountController;

Stream<int> watchUnsyncedCount() {
  _unsyncedCountController ??= StreamController<int>.broadcast(
    onCancel: () {
      _unsyncedCountController?.close();
      _unsyncedCountController = null;
    },
  );
  return _unsyncedCountController!.stream;
}

// 또는 Drift DB Watch 스트림 직접 활용 (권장)
Stream<int> watchUnsyncedCount() {
  return (select(matches)
    ..where((m) => m.isSynced.equals(false)))
    .watch()
    .map((list) => list.length);
}
```

**릴리스 차단 여부**: 아니오 — 현재 앱 사용 패턴에서 MatchListScreen이 앱 생명주기와 함께 유지되므로 실질적 문제 발생 빈도 낮음. Minor로 분류.

---

## BUG-003: MatchListScreen 날짜 포맷에 연도 없음

- **심각도**: Trivial
- **우선순위**: P4
- **관련 요구사항**: N/A
- **관련 테스트케이스**: N/A
- **환경**: match_list_screen.dart / UI
- **상태**: Open

**재현 단계**:
1. 경기 목록 화면에서 '예정' 탭 확인
2. 일정 표시 영역 확인

**기대 결과**: "2026.03.16 14:30" 형태로 연도 포함 표시

**실제 결과**: "3/16 14:30" 형태로 연도 미포함 표시

**코드 위치**: `match_list_screen.dart` 라인 708–711

```dart
String _formatScheduledTime(DateTime? time) {
  if (time == null) return '시간 미정';
  return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  // 연도 없음, 월/일 패딩 없음
}
```

**수정 방향**:
```dart
String _formatScheduledTime(DateTime? time) {
  if (time == null) return '시간 미정';
  final m = time.month.toString().padLeft(2, '0');
  final d = time.day.toString().padLeft(2, '0');
  final h = time.hour.toString().padLeft(2, '0');
  final min = time.minute.toString().padLeft(2, '0');
  return '${time.year}.$m.$d $h:$min';
}
```

**릴리스 차단 여부**: 아니오 — UX 개선 사항.

---

## BUG-004: adjustGameClock 타이머 실행 중 호출 차단 미구현

- **심각도**: Minor
- **우선순위**: P3
- **관련 요구사항**: FR-005 (+/- 조정 버튼)
- **관련 테스트케이스**: TC-022
- **환경**: game_timer_widget.dart
- **상태**: Open

**재현 단계**:
1. 게임 타이머를 시작 상태로 설정 (`isRunning = true`)
2. `adjustGameClock(-1)` 또는 `adjustGameClock(1)` 직접 호출 시도 (예: 위젯 외부 코드)

**기대 결과**: 타이머 실행 중에는 게임클락 수동 조정 불가 (adjustShotClock과 동일 정책)

**실제 결과**: `adjustShotClock()`은 `if (state.isRunning) return;` 차단이 있으나, `adjustGameClock()`은 차단 없음

**코드 위치**: `game_timer_widget.dart`

```dart
// adjustShotClock — 차단 있음
void adjustShotClock(int deltaTenths) {
  if (state.isRunning) return; // 차단
  ...
}

// adjustGameClock — 차단 없음 (버그)
void adjustGameClock(int deltaSeconds) {
  final deltaTenths = deltaSeconds * 10;
  final maxTenths = state.quarterMinutes * 600;
  final newTenths = (state.gameClockTenths + deltaTenths).clamp(0, maxTenths);
  state = state.copyWith(gameClockTenths: newTenths);  // 차단 없음
  onStateChanged?.call(state);
}
```

**실제 UI 영향**: UI에서는 `if (!state.isRunning)` 조건으로 +/- 버튼 자체가 숨겨져 있으므로, 현재 UI를 통한 재현은 불가. 단, 외부 호출 경로(통합 테스트, 다른 위젯)에서 취약점 존재.

**수정 방향**:
```dart
void adjustGameClock(int deltaSeconds) {
  if (state.isRunning) return; // 추가 필요
  final deltaTenths = deltaSeconds * 10;
  ...
}
```

**릴리스 차단 여부**: 아니오 — UI 레이어에서 이미 차단되어 있음. Minor 수준.

---

## BUG-005: RadialActionMenu isFouledOut 계산 — fouledOut DB 플래그 미사용 가능성

- **심각도**: Trivial
- **우선순위**: P4
- **관련 요구사항**: FR-012 (5파울 비활성화)
- **관련 테스트케이스**: TC-042
- **환경**: radial_action_menu.dart
- **상태**: Open

**발견 경위**: 코드 리뷰 중 `isFouledOut` 계산 방식 확인.

**현재 동작**: `isFouledOut = playerFouls >= foulOutLimit` — 파울 횟수 기반 실시간 계산.

**잠재적 불일치**: DB의 `player_stats.fouled_out` 필드는 SQL CASE WHEN으로 `recordFoul()` 시점에 설정되지만, UI의 `isFouledOut`은 `playerFouls` 카운터 기준으로 독립 계산. 두 값이 불일치할 경우(예: 비정상 데이터 상태) UI와 DB 상태가 다를 수 있음.

**실제 영향**: 일반적인 정상 플로우에서는 두 값이 항상 동기화되므로 영향 없음. 비정상 데이터 복구 시나리오에서만 문제 가능.

**수정 방향**: DB `fouled_out` 플래그를 UI의 단일 진실 공급원으로 사용하거나, 두 값 불일치 시 경고 로그 추가.

**릴리스 차단 여부**: 아니오.

---

## 버그 상태 요약

| BUG-번호 | 심각도 | 상태 | 릴리스 차단 |
|---------|--------|------|-----------|
| BUG-001 | Minor | Open | 아니오 |
| BUG-002 | Minor | Open | 아니오 |
| BUG-003 | Trivial | Open | 아니오 |
| BUG-004 | Minor | Open | 아니오 |
| BUG-005 | Trivial | Open | 아니오 |

**Critical 버그**: 0건
**Major 버그**: 0건
**Minor 버그**: 3건 (BUG-001, BUG-002, BUG-004)
**Trivial 버그**: 2건 (BUG-003, BUG-005)

---

*Nora (06-qa) — BDR AI Development Team*
*Sprint 2 Bug Reports — 2026-03-16*
