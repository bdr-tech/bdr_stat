# 쿼터별 통계 집계 쿼리 설계

> Marcus (설계 에이전트) | BDR Sprint 2 | 2026-03-16
> 요구사항 연계: FR-001 (쿼터별 통계), 옵션 B (PlayByPlays 집계, 스키마 변경 없음)

---

## 1. 현황 분석

### 1.1 사장 승인 사항 (FR-001 옵션 B)

PlayByPlay 기반 집계 쿼리. `LocalPlayByPlays` 테이블의 `quarter` 필드를 활용해 Q1/Q2/Q3/Q4/ALL 탭용 통계를 동적으로 집계한다. **스키마 변경 없음.**

### 1.2 기존 PlayByPlay 구조 확인

```dart
// tables.dart
class LocalPlayByPlays extends Table {
  IntColumn get quarter => integer()();           // 1=Q1, 2=Q2, 3=Q3, 4=Q4, 5=OT1...
  IntColumn get gameClockSeconds => integer()();
  TextColumn get actionType => text()();           // shot, rebound, assist, steal, block, turnover, foul, substitution, timeout
  TextColumn get actionSubtype => text().nullable()(); // 2pt, 3pt, ft, offensive, defensive, personal...
  BoolColumn get isMade => boolean().nullable()();
  IntColumn get pointsScored => integer().withDefault(const Constant(0))();
  IntColumn get tournamentTeamPlayerId => integer()();
  IntColumn get tournamentTeamId => integer()();
  IntColumn get localMatchId => integer()();
  IntColumn get assistPlayerId => integer().nullable()();
  IntColumn get reboundPlayerId => integer().nullable()();
  // ...
}
```

**인덱스 (이미 존재)**:
```dart
@TableIndex(name: 'idx_pbp_quarter', columns: {#localMatchId, #quarter})
@TableIndex(name: 'idx_pbp_timeline', columns: {#localMatchId, #quarter, #gameClockSeconds})
@TableIndex(name: 'idx_pbp_action', columns: {#localMatchId, #actionType})
```

FR-001 집계에 필요한 인덱스가 이미 준비되어 있다. 추가 인덱스 불필요.

### 1.3 기존 PlayByPlayDao 현황

```dart
Future<List<LocalPlayByPlay>> getPlaysByMatchAndQuarter(int matchId, int quarter) async {
  // 존재: quarter별 전체 플레이 조회 (로우 레벨)
}
```

집계(aggregation) 레이어가 없다. 현재는 전체 row를 Dart로 가져와서 집계해야 하는 구조.

---

## 2. 집계 쿼리 설계

### 2.1 설계 원칙

**원칙**: Drift 쿼리 빌더를 최대한 활용. 불가능한 집계만 `customSelect` 사용.

Drift는 `GROUP BY`와 `SUM()` 집계를 제한적으로 지원한다. 쿼터별 선수 스탯 집계는 `customSelect`가 불가피하다.

### 2.2 선수별 쿼터 통계 집계 쿼리

#### SQL (Drift customSelect용)

```sql
-- 특정 경기, 특정 선수, 특정 쿼터의 스탯 집계
-- quarter = 0이면 전체 (ALL 탭)

SELECT
  tournament_team_player_id,
  quarter,

  -- 득점
  SUM(CASE WHEN action_type = 'shot' AND is_made = 1 AND action_subtype = '2pt' THEN 2 ELSE 0 END) AS points_2pt,
  SUM(CASE WHEN action_type = 'shot' AND is_made = 1 AND action_subtype = '3pt' THEN 3 ELSE 0 END) AS points_3pt,
  SUM(CASE WHEN action_type = 'shot' AND is_made = 1 AND action_subtype = 'ft'  THEN 1 ELSE 0 END) AS points_ft,
  SUM(points_scored) AS total_points,

  -- 슛 (필드골)
  SUM(CASE WHEN action_type = 'shot' AND action_subtype != 'ft' THEN 1 ELSE 0 END)          AS fga,
  SUM(CASE WHEN action_type = 'shot' AND action_subtype != 'ft' AND is_made = 1 THEN 1 ELSE 0 END) AS fgm,
  SUM(CASE WHEN action_type = 'shot' AND action_subtype = '2pt' THEN 1 ELSE 0 END)          AS two_pa,
  SUM(CASE WHEN action_type = 'shot' AND action_subtype = '2pt' AND is_made = 1 THEN 1 ELSE 0 END) AS two_pm,
  SUM(CASE WHEN action_type = 'shot' AND action_subtype = '3pt' THEN 1 ELSE 0 END)          AS three_pa,
  SUM(CASE WHEN action_type = 'shot' AND action_subtype = '3pt' AND is_made = 1 THEN 1 ELSE 0 END) AS three_pm,

  -- 자유투
  SUM(CASE WHEN action_type = 'shot' AND action_subtype = 'ft' THEN 1 ELSE 0 END)           AS fta,
  SUM(CASE WHEN action_type = 'shot' AND action_subtype = 'ft'  AND is_made = 1 THEN 1 ELSE 0 END) AS ftm,

  -- 리바운드 (action_type = 'rebound', 리바운드 선수는 reboundPlayerId → 별도 처리)
  -- 주의: rebound 이벤트의 주체는 tournament_team_player_id
  SUM(CASE WHEN action_type = 'rebound' AND action_subtype = 'offensive' THEN 1 ELSE 0 END) AS orb,
  SUM(CASE WHEN action_type = 'rebound' AND action_subtype = 'defensive' THEN 1 ELSE 0 END) AS drb,

  -- 기타
  SUM(CASE WHEN action_type = 'assist'   THEN 1 ELSE 0 END) AS ast,
  SUM(CASE WHEN action_type = 'steal'    THEN 1 ELSE 0 END) AS stl,
  SUM(CASE WHEN action_type = 'block'    THEN 1 ELSE 0 END) AS blk,
  SUM(CASE WHEN action_type = 'turnover' THEN 1 ELSE 0 END) AS tov,
  SUM(CASE WHEN action_type = 'foul'     THEN 1 ELSE 0 END) AS pf

FROM local_play_by_plays
WHERE local_match_id = ?
  AND tournament_team_player_id = ?
  -- quarter 조건: ALL이면 생략 (Dart에서 조건부로 추가)
  [AND quarter = ?]
GROUP BY tournament_team_player_id, quarter
```

#### Dart DAO 메서드 설계

```dart
// PlayByPlayDao에 추가

/// 선수별 쿼터 통계 집계 (FR-001)
/// quarter: null이면 전체(ALL) 집계
Future<PlayerQuarterStats?> getPlayerQuarterStats({
  required int matchId,
  required int playerId,
  int? quarter, // null = ALL
}) async {
  final quarterCondition = quarter != null ? 'AND quarter = ?' : '';
  final args = quarter != null
      ? [matchId, playerId, quarter]
      : [matchId, playerId];

  final result = await customSelect(
    '''
    SELECT
      tournament_team_player_id,
      SUM(points_scored) AS total_points,
      SUM(CASE WHEN action_type = 'shot' AND action_subtype != 'ft' THEN 1 ELSE 0 END) AS fga,
      SUM(CASE WHEN action_type = 'shot' AND action_subtype != 'ft' AND is_made = 1 THEN 1 ELSE 0 END) AS fgm,
      SUM(CASE WHEN action_type = 'shot' AND action_subtype = '2pt' THEN 1 ELSE 0 END) AS two_pa,
      SUM(CASE WHEN action_type = 'shot' AND action_subtype = '2pt' AND is_made = 1 THEN 1 ELSE 0 END) AS two_pm,
      SUM(CASE WHEN action_type = 'shot' AND action_subtype = '3pt' THEN 1 ELSE 0 END) AS three_pa,
      SUM(CASE WHEN action_type = 'shot' AND action_subtype = '3pt' AND is_made = 1 THEN 1 ELSE 0 END) AS three_pm,
      SUM(CASE WHEN action_type = 'shot' AND action_subtype = 'ft' THEN 1 ELSE 0 END)  AS fta,
      SUM(CASE WHEN action_type = 'shot' AND action_subtype = 'ft' AND is_made = 1 THEN 1 ELSE 0 END) AS ftm,
      SUM(CASE WHEN action_type = 'rebound' AND action_subtype = 'offensive' THEN 1 ELSE 0 END) AS orb,
      SUM(CASE WHEN action_type = 'rebound' AND action_subtype = 'defensive' THEN 1 ELSE 0 END) AS drb,
      SUM(CASE WHEN action_type = 'assist'   THEN 1 ELSE 0 END) AS ast,
      SUM(CASE WHEN action_type = 'steal'    THEN 1 ELSE 0 END) AS stl,
      SUM(CASE WHEN action_type = 'block'    THEN 1 ELSE 0 END) AS blk,
      SUM(CASE WHEN action_type = 'turnover' THEN 1 ELSE 0 END) AS tov,
      SUM(CASE WHEN action_type = 'foul'     THEN 1 ELSE 0 END) AS pf
    FROM local_play_by_plays
    WHERE local_match_id = ?
      AND tournament_team_player_id = ?
      $quarterCondition
    ''',
    variables: args.map((a) => Variable(a)).toList(),
    readsFrom: {localPlayByPlays},
  ).getSingleOrNull();

  if (result == null) return null;
  return PlayerQuarterStats.fromRow(result, playerId: playerId, quarter: quarter);
}

/// 팀 전체 쿼터 통계 집계 (박스스코어 전체 뷰용)
Future<List<PlayerQuarterStats>> getTeamQuarterStats({
  required int matchId,
  required int teamId,
  int? quarter,
}) async {
  final quarterCondition = quarter != null ? 'AND quarter = ?' : '';
  final args = quarter != null
      ? [matchId, teamId, quarter]
      : [matchId, teamId];

  final results = await customSelect(
    '''
    SELECT
      tournament_team_player_id,
      SUM(points_scored) AS total_points,
      SUM(CASE WHEN action_type = 'shot' AND action_subtype != 'ft' THEN 1 ELSE 0 END) AS fga,
      SUM(CASE WHEN action_type = 'shot' AND action_subtype != 'ft' AND is_made = 1 THEN 1 ELSE 0 END) AS fgm,
      SUM(CASE WHEN action_type = 'shot' AND action_subtype = '2pt' THEN 1 ELSE 0 END) AS two_pa,
      SUM(CASE WHEN action_type = 'shot' AND action_subtype = '2pt' AND is_made = 1 THEN 1 ELSE 0 END) AS two_pm,
      SUM(CASE WHEN action_type = 'shot' AND action_subtype = '3pt' THEN 1 ELSE 0 END) AS three_pa,
      SUM(CASE WHEN action_type = 'shot' AND action_subtype = '3pt' AND is_made = 1 THEN 1 ELSE 0 END) AS three_pm,
      SUM(CASE WHEN action_type = 'shot' AND action_subtype = 'ft' THEN 1 ELSE 0 END) AS fta,
      SUM(CASE WHEN action_type = 'shot' AND action_subtype = 'ft' AND is_made = 1 THEN 1 ELSE 0 END) AS ftm,
      SUM(CASE WHEN action_type = 'rebound' AND action_subtype = 'offensive' THEN 1 ELSE 0 END) AS orb,
      SUM(CASE WHEN action_type = 'rebound' AND action_subtype = 'defensive' THEN 1 ELSE 0 END) AS drb,
      SUM(CASE WHEN action_type = 'assist'   THEN 1 ELSE 0 END) AS ast,
      SUM(CASE WHEN action_type = 'steal'    THEN 1 ELSE 0 END) AS stl,
      SUM(CASE WHEN action_type = 'block'    THEN 1 ELSE 0 END) AS blk,
      SUM(CASE WHEN action_type = 'turnover' THEN 1 ELSE 0 END) AS tov,
      SUM(CASE WHEN action_type = 'foul'     THEN 1 ELSE 0 END) AS pf
    FROM local_play_by_plays
    WHERE local_match_id = ?
      AND tournament_team_id = ?
      $quarterCondition
    GROUP BY tournament_team_player_id
    ORDER BY total_points DESC
    ''',
    variables: args.map((a) => Variable(a)).toList(),
    readsFrom: {localPlayByPlays},
  ).get();

  return results.map((row) => PlayerQuarterStats.fromRow(row)).toList();
}

/// 쿼터별 팀 점수 집계 (점수 요약 행용)
Future<QuarterScoreSummary> getQuarterScoreSummary({
  required int matchId,
  required int teamId,
}) async {
  final result = await customSelect(
    '''
    SELECT
      quarter,
      SUM(points_scored) AS quarter_points
    FROM local_play_by_plays
    WHERE local_match_id = ?
      AND tournament_team_id = ?
      AND action_type = 'shot'
      AND is_made = 1
    GROUP BY quarter
    ORDER BY quarter
    ''',
    variables: [Variable(matchId), Variable(teamId)],
    readsFrom: {localPlayByPlays},
  ).get();

  return QuarterScoreSummary.fromRows(result);
}
```

---

## 3. 박스스코어 UI 데이터 모델

### 3.1 PlayerQuarterStats (도메인 모델)

```dart
// lib/domain/models/quarter_stats_models.dart

@freezed
class PlayerQuarterStats with _$PlayerQuarterStats {
  const factory PlayerQuarterStats({
    required int playerId,
    int? quarter, // null = ALL
    @Default(0) int totalPoints,
    @Default(0) int fgm,
    @Default(0) int fga,
    @Default(0) int twoPm,
    @Default(0) int twoPa,
    @Default(0) int threePm,
    @Default(0) int threePa,
    @Default(0) int ftm,
    @Default(0) int fta,
    @Default(0) int offensiveRebounds,
    @Default(0) int defensiveRebounds,
    @Default(0) int assists,
    @Default(0) int steals,
    @Default(0) int blocks,
    @Default(0) int turnovers,
    @Default(0) int personalFouls,
  }) = _PlayerQuarterStats;

  const PlayerQuarterStats._();

  // 계산 필드
  int get totalRebounds => offensiveRebounds + defensiveRebounds;

  double get fgPercentage =>
      fga == 0 ? 0.0 : (fgm / fga * 100);

  double get threePercentage =>
      threePa == 0 ? 0.0 : (threePm / threePa * 100);

  double get ftPercentage =>
      fta == 0 ? 0.0 : (ftm / fta * 100);

  static PlayerQuarterStats fromRow(QueryRow row, {int? playerId, int? quarter}) {
    return PlayerQuarterStats(
      playerId: playerId ?? row.read<int>('tournament_team_player_id'),
      quarter: quarter,
      totalPoints: row.read<int>('total_points'),
      fgm: row.read<int>('fgm'),
      fga: row.read<int>('fga'),
      twoPm: row.read<int>('two_pm'),
      twoPa: row.read<int>('two_pa'),
      threePm: row.read<int>('three_pm'),
      threePa: row.read<int>('three_pa'),
      ftm: row.read<int>('ftm'),
      fta: row.read<int>('fta'),
      offensiveRebounds: row.read<int>('orb'),
      defensiveRebounds: row.read<int>('drb'),
      assists: row.read<int>('ast'),
      steals: row.read<int>('stl'),
      blocks: row.read<int>('blk'),
      turnovers: row.read<int>('tov'),
      personalFouls: row.read<int>('pf'),
    );
  }
}

@freezed
class QuarterScoreSummary with _$QuarterScoreSummary {
  const factory QuarterScoreSummary({
    @Default(0) int q1,
    @Default(0) int q2,
    @Default(0) int q3,
    @Default(0) int q4,
    @Default([]) List<int> overtime,
  }) = _QuarterScoreSummary;

  const QuarterScoreSummary._();

  int get total => q1 + q2 + q3 + q4 + overtime.fold(0, (a, b) => a + b);

  static QuarterScoreSummary fromRows(List<QueryRow> rows) {
    var q1 = 0, q2 = 0, q3 = 0, q4 = 0;
    final overtime = <int>[];
    for (final row in rows) {
      final quarter = row.read<int>('quarter');
      final points = row.read<int>('quarter_points');
      switch (quarter) {
        case 1: q1 = points; break;
        case 2: q2 = points; break;
        case 3: q3 = points; break;
        case 4: q4 = points; break;
        default:
          // OT: quarter 5부터
          final otIndex = quarter - 5;
          while (overtime.length <= otIndex) overtime.add(0);
          overtime[otIndex] = points;
      }
    }
    return QuarterScoreSummary(q1: q1, q2: q2, q3: q3, q4: q4, overtime: overtime);
  }
}

/// 박스스코어 전체 뷰 데이터
@freezed
class BoxScoreData with _$BoxScoreData {
  const factory BoxScoreData({
    required int matchId,
    int? selectedQuarter, // null = ALL
    required List<BoxScorePlayerRow> homePlayers,
    required List<BoxScorePlayerRow> awayPlayers,
    required QuarterScoreSummary homeScore,
    required QuarterScoreSummary awayScore,
  }) = _BoxScoreData;
}

@freezed
class BoxScorePlayerRow with _$BoxScorePlayerRow {
  const factory BoxScorePlayerRow({
    required int playerId,
    required String playerName,
    required int jerseyNumber,
    required bool isStarter,
    required PlayerQuarterStats stats,
    // +/-는 LocalPlayerStats.plusMinus에서 (경기 통산 값)
    @Default(0) int plusMinus,
  }) = _BoxScorePlayerRow;
}
```

### 3.2 박스스코어 탭별 Provider 설계

```dart
// lib/presentation/providers/box_score_provider.dart

// 탭 선택 상태
final selectedQuarterTabProvider = StateProvider.family<int?, int>(
  (ref, matchId) => null, // null = ALL
);

// 박스스코어 데이터 (탭 변경 시 재집계)
final boxScoreDataProvider = FutureProvider.family<BoxScoreData, ({int matchId, int homeTeamId, int awayTeamId})>(
  (ref, args) async {
    final quarter = ref.watch(selectedQuarterTabProvider(args.matchId));
    final pbpDao = ref.read(playByPlayDaoProvider);
    final statsDao = ref.read(playerStatsDaoProvider);

    // 병렬 조회
    final results = await Future.wait([
      pbpDao.getTeamQuarterStats(matchId: args.matchId, teamId: args.homeTeamId, quarter: quarter),
      pbpDao.getTeamQuarterStats(matchId: args.matchId, teamId: args.awayTeamId, quarter: quarter),
      pbpDao.getQuarterScoreSummary(matchId: args.matchId, teamId: args.homeTeamId),
      pbpDao.getQuarterScoreSummary(matchId: args.matchId, teamId: args.awayTeamId),
      statsDao.getStatsByMatchAndTeam(args.matchId, args.homeTeamId),
      statsDao.getStatsByMatchAndTeam(args.matchId, args.awayTeamId),
    ]);

    // 결과 조합 (생략, Ethan 구현)
    return BoxScoreData(...);
  },
);
```

---

## 4. mybdr API 응답 구조 (quarterStats)

### 4.1 박스스코어 API 엔드포인트

FR-001에서 mybdr API에 쿼터별 통계를 조회하는 별도 API가 필요한지 확인한다.

**현재 상태**: 동기화는 단방향 (Flutter → mybdr). 박스스코어 화면은 로컬 DB에서 직접 집계.

**결론**: Sprint 2 범위에서 별도 API는 불필요. 박스스코어는 로컬 집계로 처리. 단, 경기 종료 시 서버에 동기화된 `MatchPlayerStat`는 쿼터별 분리 없이 경기 통산 값만 저장한다.

### 4.2 향후 API 확장 (참고용, Sprint 2 범위 외)

```
GET /api/v1/matches/:id/quarter-stats?quarter=1

Response 200:
{
  "quarter": 1,
  "home_team": {
    "team_id": 123,
    "players": [
      {
        "player_id": 456,
        "jersey_number": 10,
        "name": "김철수",
        "pts": 8,
        "fgm": 3,
        "fga": 6,
        "three_pm": 1,
        "three_pa": 2,
        "ftm": 1,
        "fta": 2,
        "reb": 3,
        "ast": 2,
        "stl": 1,
        "blk": 0,
        "tov": 1,
        "pf": 2,
        "plus_minus": 5
      }
    ],
    "totals": {
      "pts": 25,
      "fgm": 10,
      "fga": 22,
      ...
    }
  },
  "away_team": { ... }
}
```

---

## 5. 성능 고려사항

### 5.1 쿼리 실행 계획

```
-- 현재 인덱스: (local_match_id, quarter)
-- 쿼터별 집계 쿼리: idx_pbp_quarter 활용 → O(log n) 스캔

-- 경기당 예상 PlayByPlay 수:
--   10분 쿼터 × 4 = 40분 경기
--   평균 1분당 5개 이벤트 → 약 200개/경기
--   최대 400개 가정 (파울, 자유투 포함)

-- SQLite에서 400행 GROUP BY + SUM: < 5ms (충분히 빠름)
```

### 5.2 캐싱 전략

```dart
// 경기 진행 중: 박스스코어 탭 진입 시마다 재집계
// → 400행 이하, 5ms 이내 → 캐싱 불필요

// 경기 종료 후: LocalPlayerStats.plusMinus가 최종 값이므로
// ALL 탭은 LocalPlayerStats에서 직접 읽기 (집계 불필요)
// 쿼터별 탭만 PlayByPlay 집계 사용
```

### 5.3 ALL 탭 최적화

```dart
// ALL 탭 = 경기 통산
// 옵션 1: PlayByPlay 전체 집계 (일관성 보장, 느릴 수 있음)
// 옵션 2: LocalPlayerStats 직접 읽기 (빠름, 단 plusMinus만)

// 결정: ALL 탭은 LocalPlayerStats 직접 읽기 (기본 스탯)
//       + PlayByPlay 집계가 필요한 필드만 보완
// 단순화 이유: LocalPlayerStats는 이미 각 이벤트에서 원자적으로 업데이트됨
//              경기 통산 값은 LocalPlayerStats가 진실의 소스(source of truth)
```

---

## 6. ADR-003: 쿼터별 통계 집계 방식 — 스키마 변경 vs PlayByPlay 집계

```
ADR-003: FR-001 쿼터별 통계 구현 방식
상태: 승인 (사장 결정)
작성일: 2026-03-16
요구사항: FR-001
사장 결정: 옵션 B (PlayByPlay 집계, 스키마 변경 없음)
```

### 컨텍스트

박스스코어 Q1/Q2/Q3/Q4/ALL 탭을 위해 쿼터별 통계가 필요하다.

### 결정: PlayByPlay 집계 쿼리 (옵션 B)

기존 `LocalPlayByPlays.quarter` 필드를 활용해 `customSelect` 집계 쿼리로 쿼터별 통계를 동적으로 집계한다.

### 대안 검토

**대안 A: 쿼터별 스탯 테이블 추가**
```dart
class LocalPlayerQuarterStats extends Table {
  // quarter, player_id, points, fgm, ... 별도 테이블
}
```
- 장점: 박스스코어 조회 성능 최적화. 집계 쿼리 불필요.
- 단점: Drift 마이그레이션 필요 (schemaVersion 증가). 기존 기록 데이터 마이그레이션 필요. 스탯 업데이트 시 두 테이블 동시 유지 필요 → 정합성 부담.

**대안 B: PlayByPlay 집계 쿼리 (채택)**
- 장점: 스키마 변경 없음. PlayByPlay가 단일 진실의 소스. 쿼리 수정만으로 로직 변경 가능.
- 단점: 매 조회마다 집계 쿼리 실행. 단, 경기당 400행 이하이므로 SQLite에서 < 5ms로 허용 가능.

**대안 C: PlayByPlay + 메모리 캐싱**
- 집계 결과를 Riverpod Provider로 캐싱. 탭 전환 시 재계산 없음.
- 단점: 실시간 경기 중 이벤트 발생 시 캐시 무효화 로직 필요.
- 채택 여부: Provider 캐싱은 Riverpod의 `FutureProvider`가 자동으로 처리하므로 추가 구현 불필요. 단, 실시간 업데이트를 위해 `StreamProvider`를 검토할 수 있다 (향후 개선).

### 결과

`PlayByPlayDao.getTeamQuarterStats()` / `getPlayerQuarterStats()` / `getQuarterScoreSummary()` 3개 메서드를 추가한다. Drift 스키마 버전은 변경하지 않는다.

### 트레이드오프

포기하는 것: 조회 성능 (쿼터 탭 전환 시 5ms 집계 쿼리 실행).
얻는 것: 마이그레이션 없는 구현, PlayByPlay 단일 진실의 소스 유지, Sprint 2 일정 단축.
