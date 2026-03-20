# +/- 코트마진 계산 알고리즘 설계

> Marcus (설계 에이전트) | BDR Sprint 2 | 2026-03-16
> 요구사항 연계: FR-003 (+/- 코트마진)

---

## 1. 현황 분석

### 1.1 기존 구현 상태

**LocalPlayerStats 테이블 (tables.dart)**
```dart
IntColumn get plusMinus => integer().withDefault(const Constant(0))();
IntColumn get isOnCourt => boolean().withDefault(const Constant(false))();
DateTimeColumn get lastEnteredAt => dateTime().nullable()();
```

- `plusMinus` 컬럼: 존재하나 현재 업데이트 로직 없음
- `isOnCourt`: 교체 이벤트 시 플래그 관리 필요
- `lastEnteredAt`: 코트 진입 시각 (출전 시간 계산용)

**LocalPlayByPlays 테이블 (tables.dart)**
```dart
IntColumn get subInPlayerId => integer().nullable()();
IntColumn get subOutPlayerId => integer().nullable()();
IntColumn get homeScoreAtTime => integer()();
IntColumn get awayScoreAtTime => integer()();
IntColumn get pointsScored => integer().withDefault(const Constant(0))();
IntColumn get tournamentTeamId => integer()();
```

- 교체 이벤트: `actionType = 'substitution'`
- 득점 이벤트: `actionType = 'shot'`, `pointsScored > 0`
- 점수 스냅샷: `homeScoreAtTime`, `awayScoreAtTime` 이미 저장됨

**PlayerStatsDao (player_stats_dao.dart)**
```dart
Future<List<LocalPlayerStat>> getOnCourtPlayers(int matchId, int teamId) async {
  // isOnCourt = true인 선수 조회 — 존재함
}
Future<void> setOnCourt(int matchId, int playerId, bool isOnCourt) async {
  // isOnCourt 플래그 업데이트 — 존재함
}
```

**갭**: `plusMinus` 업데이트 로직이 없다. 득점 이벤트 발생 시 코트 위 5인에게 +/- 누적하는 코드가 PlayerStatsDao에 없다.

### 1.2 mybdr 서버 (Prisma schema)

```
MatchPlayerStat.plusMinus  Int?  @default(0)  @map("plus_minus")
```

동기화 시 `plusMinus` 값을 서버로 전송한다. 서버는 별도 계산 없이 클라이언트 값을 신뢰한다.

---

## 2. +/- 계산 알고리즘

### 2.1 핵심 개념

+/-는 "해당 선수가 코트에 있는 동안 팀이 득점한 점수 - 상대팀이 득점한 점수"다.

```
+/- = (자팀 득점, 코트 위 시간) - (상대팀 득점, 코트 위 시간)
```

### 2.2 이벤트 처리 흐름

```
[득점 이벤트 발생]
        │
        ├─ pointsScored > 0
        │   points = play.pointsScored
        │   scoringTeamId = play.tournamentTeamId
        │
        ├─ ON-COURT 홈팀 선수 5명 조회 (getOnCourtPlayers)
        ├─ ON-COURT 어웨이팀 선수 5명 조회
        │
        ├─ 득점 팀이 홈팀이면:
        │   홈팀 선수 5명: plusMinus += points
        │   어웨이팀 선수 5명: plusMinus -= points
        │
        └─ 득점 팀이 어웨이팀이면:
            어웨이팀 선수 5명: plusMinus += points
            홈팀 선수 5명: plusMinus -= points

[교체 이벤트 발생]
        │
        ├─ actionType = 'substitution'
        ├─ subOutPlayerId → setOnCourt(false)
        └─ subInPlayerId → setOnCourt(true)
        [plusMinus에 대한 별도 처리 없음 — 누적값 그대로 유지]
```

### 2.3 자유투 처리

자유투는 `actionType = 'shot'`, `actionSubtype = 'ft'`, `pointsScored = 1` (성공 시) 또는 `pointsScored = 0` (실패 시).

```
자유투 성공: pointsScored = 1 → +/- 업데이트 (일반 득점과 동일)
자유투 실패: pointsScored = 0 → +/- 업데이트 없음
```

### 2.4 Undo 처리

```
[Undo: 득점 이벤트 취소]
  → 원래 events의 points를 역방향으로 적용
  → 홈팀 선수에게: plusMinus -= points (득점 팀이 홈팀인 경우)
  → 어웨이팀 선수에게: plusMinus += points

단, Undo 시점의 ON-COURT 상태는 원래 이벤트 시점과 다를 수 있음
→ 해결책: Undo는 현재 ON-COURT 기준이 아닌, 원본 이벤트의 play record에서
  homeScoreAtTime/awayScoreAtTime 스냅샷을 활용하지 않고,
  현재 ON-COURT 선수에게 역방향 적용 (단순화)
→ 이 트레이드오프는 ADR-002에 기록
```

---

## 3. DAO 쿼리 설계

### 3.1 PlayerStatsDao 신규 메서드

```dart
/// +/- 누적 업데이트: 득점 발생 시 호출
/// increment: 양수=득점팀, 음수=실점팀
Future<void> updatePlusMinus(
  int matchId,
  int playerId,
  int delta, // +points or -points
) async {
  await customStatement(
    'UPDATE local_player_stats '
    'SET plus_minus = plus_minus + ?, updated_at = ? '
    'WHERE local_match_id = ? AND tournament_team_player_id = ?',
    [delta, DateTime.now().millisecondsSinceEpoch ~/ 1000, matchId, playerId],
  );
}

/// 득점 이벤트 발생 시: 코트 위 전체 선수 +/- 일괄 업데이트
Future<void> applyPlusMinusForScore({
  required int matchId,
  required int scoringTeamId,
  required int opponentTeamId,
  required int points,
}) async {
  // 득점 팀 코트 위 선수: +points
  final scoringOnCourt = await getOnCourtPlayers(matchId, scoringTeamId);
  for (final player in scoringOnCourt) {
    await updatePlusMinus(matchId, player.tournamentTeamPlayerId, points);
  }

  // 실점 팀 코트 위 선수: -points
  final opponentOnCourt = await getOnCourtPlayers(matchId, opponentTeamId);
  for (final player in opponentOnCourt) {
    await updatePlusMinus(matchId, player.tournamentTeamPlayerId, -points);
  }
}
```

### 3.2 트랜잭션 단위

```dart
// 득점 기록 전체 트랜잭션:
await database.transaction(() async {
  // 1. PlayByPlay 저장
  final playId = await playByPlayDao.insertPlay(playCompanion);

  // 2. 선수 스탯 업데이트 (points, FGM 등)
  await playerStatsDao.recordTwoPointer(matchId, playerId, isMade: true);

  // 3. 팀 점수 업데이트 (LocalMatches)
  await matchDao.incrementScore(matchId, teamSide, points);

  // 4. +/- 업데이트 (FR-003)
  await playerStatsDao.applyPlusMinusForScore(
    matchId: matchId,
    scoringTeamId: scoringTeamId,
    opponentTeamId: opponentTeamId,
    points: points,
  );
});
```

### 3.3 교체 이벤트 트랜잭션

```dart
// 교체 기록 트랜잭션:
await database.transaction(() async {
  // 1. PlayByPlay 저장 (actionType: 'substitution')
  await playByPlayDao.insertPlay(subPlayCompanion);

  // 2. 교체 나가는 선수: isOnCourt = false
  await playerStatsDao.setOnCourt(matchId, subOutPlayerId, false);

  // 3. 교체 들어오는 선수: isOnCourt = true
  await playerStatsDao.setOnCourt(matchId, subInPlayerId, true);

  // 4. +/- 변경 없음 (누적값 유지)
  //    교체 자체는 +/- 이벤트가 아님
});
```

---

## 4. 데이터 흐름 다이어그램

```
경기 시작
    │
    ▼
스타터 5인 isOnCourt = true 설정
    │
    ▼
[득점 이벤트] ─────────────────────────────────────────────────────┐
    │                                                              │
    ├─ PlayByPlay INSERT:                                          │
    │    homeScoreAtTime = 현재 홈 점수                              │
    │    awayScoreAtTime = 현재 어웨이 점수 + points                  │
    │    pointsScored = 2 or 3 or 1                               │
    │                                                              │
    ├─ MatchPlayerStats UPDATE (득점자):                            │
    │    points += 2, twoPointersMade += 1, etc.                  │
    │                                                              │
    └─ ON-COURT 전체 (10인) +/- 업데이트: ◄──────────────────────────┘
         득점팀 5인: plus_minus += points
         실점팀 5인: plus_minus -= points

[교체 이벤트]
    │
    ├─ PlayByPlay INSERT (subInPlayerId, subOutPlayerId)
    ├─ subOut: isOnCourt = false
    └─ subIn:  isOnCourt = true
               [plusMinus 변경 없음]

경기 종료
    │
    └─ LocalPlayerStats.plusMinus → 서버 동기화
       (MatchPlayerStat.plus_minus)
```

---

## 5. 엣지 케이스 처리

### 5.1 교체 누락 (기록 실수)

**시나리오**: 기록원이 교체를 놓쳐서 실제로는 코트에 없는 선수가 `isOnCourt = true` 상태.

**처리**:
- +/- 계산은 DB의 `isOnCourt` 상태를 기준으로 함
- 교체 이벤트 소급 입력 시: 현재 구현에서는 해당 시점 이후의 +/- 재계산 없음
- 실용적 결정: 소급 재계산은 복잡도가 과도하다. 교체 누락은 기록 수정(play_by_play_edit)으로 처리하되, +/-는 best-effort 값으로 설명한다.
- **향후 개선**: `isManuallyEdited = true` 플래그로 수동 수정 추적

### 5.2 쿼터 시작 (새 쿼터)

```dart
// 쿼터 전환 시 +/- 리셋 여부: 리셋하지 않음
// +/-는 경기 전체 누적값 (쿼터별 +/- 분리는 미구현, 추후 검토)
// 이유: FIBA 공식 박스스코어에서 +/-는 경기 통산 기준
```

### 5.3 연장전

```dart
// OT 진입: 선수 교체 없으면 기존 isOnCourt 상태 유지
// OT 득점도 동일한 applyPlusMinusForScore 로직 적용
// 특별 처리 없음
```

### 5.4 초기 스타터 데이터 없음

```dart
// getOnCourtPlayers 결과가 비어 있으면:
// → +/- 업데이트 건너뜀 (for loop 실행 안 됨)
// → PlayByPlay와 선수 스탯은 정상 기록
// → 로그 경고: '[plusMinus] No on-court players found for team $teamId'
```

### 5.5 5인 미만 코트 상황 (파울아웃/부상)

```dart
// isOnCourt = true인 선수가 4인이면 4인에게만 +/- 적용
// 규칙상 비정상이나 DB 상태 기준으로 처리
```

---

## 6. ADR-002: +/- 계산 시점 — 이벤트 발생 즉시 vs 경기 종료 후 집계

```
ADR-002: +/- 계산 방식
상태: 승인
작성일: 2026-03-16
요구사항: FR-003
```

### 컨텍스트

+/- 계산을 구현하는 방법은 크게 두 가지다.

### 결정: 이벤트 발생 즉시 누적

득점 이벤트 INSERT 트랜잭션 내에서 즉시 `LocalPlayerStats.plusMinus`를 업데이트한다.

### 대안 검토

**대안 A: 이벤트 발생 즉시 누적 (채택)**
- 장점: 박스스코어 화면에서 별도 집계 쿼리 없이 즉시 표시 가능. 기존 `_atomicIncrement` 패턴과 일관성.
- 단점: Undo 시 재계산 복잡도. 교체 누락 시 오차 누적.

**대안 B: PlayByPlay에서 경기 종료 시 집계**
- 장점: Undo나 수정이 자동 반영됨. 항상 정확한 값.
- 단점: 박스스코어 실시간 표시를 위해 매번 집계 쿼리 실행. 경기 중 집계 쿼리 비용이 높다.

**대안 C: PlayByPlay에서 실시간 집계 쿼리**
```sql
-- 특정 선수의 +/-: 코트 진입/퇴장 시각 기반 집계
-- 구현 복잡도: 교체 이벤트 시각과 득점 이벤트 시각 비교 필요
-- 현재 LocalPlayByPlays에 교체 시각 저장되나, 쿼터+gameClockSeconds 기준
-- gameClockSeconds 역방향(카운트다운) 해석 필요 → 오류 가능성
```
- 채택하지 않은 이유: 교체 시각 vs 득점 시각 비교 로직이 복잡하고, 게임 클락 카운트다운 해석 오류 시 잘못된 +/-가 표시된다.

### 결과

이벤트 즉시 누적 방식을 채택한다. Undo는 현재 ON-COURT 기준으로 역방향 적용한다. 소급 수정 시 +/-는 best-effort 값이며, 수동 수정 플래그(`isManuallyEdited`)로 표시한다.

### 트레이드오프

포기하는 것: Undo/소급 수정 후 +/- 완벽한 정확성.
얻는 것: 구현 단순성, 실시간 표시 성능, 기존 `_atomicIncrement` 패턴과의 일관성.
