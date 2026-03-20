# BDR Known Bug Patterns — QA 누적 지식

> **목적**: 이 코드베이스에서 반복적으로 발생하거나 발생 가능성이 높은 버그 패턴을 기록한다.
> 향후 QA 시 이 목록을 우선 확인 리스트로 활용할 것.
>
> **업데이트 규칙**: 버그 발견 시 패턴을 추출하여 이 파일에 추가. 재발 방지 TC도 함께 등록.

---

## PATTERN-001: async* Stream 무한 루프 취소 불가

**발견 스프린트**: Sprint 2
**관련 버그**: BUG-002

**패턴 설명**:
`async*` 제너레이터와 `while (true)` + `Future.delayed()` 조합으로 구현된 Stream은 구독자가 없어도 루프가 자동 종료되지 않는다. Flutter Provider/Riverpod에서 이런 Stream을 `StreamProvider`로 노출할 때 dispose 처리가 불완전할 경우 메모리 누수 가능.

**위험 신호**:
```dart
// 위험한 패턴
Stream<T> watchSomething() async* {
  while (true) {
    yield await someAsyncOperation();
    await Future.delayed(const Duration(seconds: N));
  }
}
```

**안전한 패턴**:
```dart
// 권고: Drift DB Watch 스트림 직접 활용
Stream<int> watchCount() {
  return (select(table)..where(...)).watch().map((list) => list.length);
}
```

**이 파일에서 확인할 곳**: `sync_manager.dart` — `watchUnsyncedCount()`, `watchSyncInfo()`

**재발 방지 TC**: 새로운 `Stream` 메서드 추가 시 취소 가능 여부 반드시 검증.

---

## PATTERN-002: 시점 기반 역산 — 상태 스냅샷 누락

**발견 스프린트**: Sprint 2
**관련 버그**: BUG-001

**패턴 설명**:
"행동 X를 Undo할 때 X가 적용된 시점의 상태로 역산해야 한다"는 요구가 있을 때, 현재 상태 기반으로 역산하면 중간에 다른 상태 변경(선수 교체 등)이 있을 경우 부정확해진다.

**위험 신호**:
- Undo 기능이 "현재 ON-COURT 선수" 또는 "현재 상태" 기준으로 역산하는 코드
- PlayByPlay 레코드에 당시 상태(코트 선수 목록, 점수 등) 스냅샷이 없는 경우

**안전한 패턴**:
```dart
// PlayByPlay 저장 시 현재 상태 스냅샷 포함
final onCourtSnapshot = await getOnCourtPlayers(matchId, teamId);
await insertPlay(LocalPlayByPlaysCompanion(
  // ... 기존 필드 ...
  onCourtPlayerIds: Value(jsonEncode(onCourtSnapshot.map((p) => p.id).toList())),
));

// Undo 시 스냅샷 사용
final play = await getPlayById(playId);
final onCourt = jsonDecode(play.onCourtPlayerIds ?? '[]');
for (final playerId in onCourt) {
  await updatePlusMinus(playerId, -delta);
}
```

**이 파일에서 확인할 곳**: `player_stats_dao.dart` — `revertPlusMinusForScore()`

**재발 방지 TC**: Undo 테스트 시 반드시 "중간 상태 변경 후 Undo" 시나리오 포함.

---

## PATTERN-003: 동일 로직의 비대칭 방어 코드

**발견 스프린트**: Sprint 2
**관련 버그**: BUG-004

**패턴 설명**:
동일한 정책("실행 중 조정 불가")을 적용해야 하는 여러 메서드가 있을 때, 일부 메서드에만 방어 코드가 추가되고 나머지는 누락되는 패턴. UI 레이어에서 차단하더라도 도메인 레이어의 메서드는 독립적으로 방어되어야 한다.

**위험 신호**:
```dart
void adjustA(int delta) {
  if (state.isRunning) return; // 차단 있음
  ...
}

void adjustB(int delta) {
  // 차단 없음 — 같은 정책인데 누락
  ...
}
```

**확인 방법**: 동일 컨텍스트의 메서드군에서 `isRunning` 등 상태 체크가 일관되게 적용되었는지 확인.

**재발 방지 TC**: Notifier 메서드 추가 시 "타이머 실행 중 호출" 경계 TC 반드시 추가.

---

## PATTERN-004: 경계값 `<` vs `<=` — 소수점 임계값 처리

**발견 스프린트**: Sprint 2
**검증 완료**

**패턴 설명**:
"N초 미만에서 소수점 표시"를 구현할 때 `<` (엄격한 부등호)를 사용해야 한다. `<=` 사용 시 정확히 N초인 순간에도 소수점이 표시되어 요구사항 불일치 발생.

**올바른 구현**:
```dart
if (shotClockTenths < thresholdTenths) { // '<' 엄격한 부등호
  // 소수점 표시 ("4.9")
} else {
  // 정수 표시 ("05")
}
```

**경계값 확인**:
- threshold = 5초 = 50 tenths
- `shotClockTenths = 50`: `50 < 50` = false → 정수 "05" (정확)
- `shotClockTenths = 49`: `49 < 50` = true → 소수점 "4.9" (정확)

**이 파일에서 확인할 곳**: `game_timer_widget.dart` — `formattedShotClock`, `formattedGameClock`

**재발 방지 TC**: 타이머 관련 포맷 변경 시 threshold 경계값(정확히 N초) TC 필수.

---

## PATTERN-005: SQLite Boolean — `is_made = 1` 명시 필요

**발견 스프린트**: Sprint 2
**검증 완료**

**패턴 설명**:
Drift ORM이 Boolean을 SQLite에서 INTEGER(0/1)로 저장한다. custom SQL 쿼리에서 Boolean 필드를 비교할 때 `is_made = 1` (또는 `= true`)로 명시해야 한다. Drift 쿼리 빌더는 자동 처리하지만 `customSelect()` 사용 시 주의.

**위험 신호**:
```sql
-- 잠재적 문제 (Dart true/false 비교는 SQLite에서 지원 안 됨)
WHERE is_made = true

-- 올바른 방법
WHERE is_made = 1
```

**이 파일에서 확인할 곳**: `play_by_play_dao.dart` — `getTeamQuarterStats()` SQL 쿼리 — 현재 `is_made = 1` 사용 확인됨 (정상).

**재발 방지 TC**: customSelect SQL 추가 시 Boolean 필드 조건 리뷰 필수.

---

## PATTERN-006: DeadLetter 큐 상한 — 메모리 보호

**발견 스프린트**: Sprint 2
**검증 완료 (설계 우수)**

**패턴 설명**:
재시도 실패 큐(dead-letter)를 구현할 때 상한(max size)이 없으면 SharedPreferences 또는 메모리가 무한 팽창한다. BDR 구현은 `deadLetters.length > 20` 조건으로 FIFO 방식 20개 상한 적용 — 우수.

**올바른 패턴** (확인됨):
```dart
if (deadLetters.length > 20) {
  deadLetters.removeRange(0, deadLetters.length - 20); // 오래된 것 제거
}
```

**향후 확인 사항**: dead-letter 큐 조회 UI가 추가될 경우, 상한을 설정에서 변경 가능하도록 `_maxDeadLetters` 상수화 권고.

---

*Nora (06-qa) — BDR AI Development Team*
*초기 작성: Sprint 2 — 2026-03-16*
*다음 업데이트: Sprint 3 QA 완료 후*
