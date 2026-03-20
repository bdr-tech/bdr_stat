# game_rules JSON 스키마 명세

> Marcus (설계 에이전트) | BDR Sprint 2 | 2026-03-16
> 요구사항 연계: FR-006 (샷클락 소수점 표시), FR-010 (타임아웃 설정)

---

## 1. 현황 분석

### 1.1 서버 (mybdr Prisma schema)

```
Tournament.game_rules  Json?  @default("{}")
```

- PostgreSQL JSONB 컬럼, 스키마리스(schema-less)
- 현재 저장된 키: 없음 또는 개발 초기 임의 키

### 1.2 Flutter 앱 (bdr_stat)

```dart
// tables.dart
class LocalTournaments extends Table {
  TextColumn get gameRulesJson => text()(); // JSONB → JSON String
}

// app_constants.dart
class GameRulesDefaults {
  static const int quarterMinutes = 10;
  static const int overtimeMinutes = 5;
  static const int shotClockSeconds = 24;
  static const int shotClockAfterOffensiveRebound = 14;
  static const int bonusThreshold = 5;
  static const int foulOutLimit = 5;
  static const int timeoutsPerHalf = 2;
  static const int totalTimeouts = 4;

  static Map<String, int> fromJson(Map<String, dynamic>? json) {
    // 현재: 7개 키만 처리, shot_clock_decimal_* 없음
  }
}
```

### 1.3 갭 식별

| 항목 | 현재 상태 | Sprint 2 필요 |
|------|-----------|---------------|
| shot_clock_decimal_threshold | 없음 | FR-006: 기본값 5 |
| shot_clock_decimal_precision | 없음 | FR-006: 기본값 1 (1/10초) |
| timeout_full_seconds | 없음 | FR-010: 타임아웃 지속시간 |
| timeout_20s_seconds | 없음 | FR-010: 20초 타임아웃 |
| bonus_timeout_last2min | 없음 | FR-010: 마지막 2분 보너스 TO |
| timeouts_first_half | 없음 | FR-010: 전반 타임아웃 수 |
| timeouts_second_half | 없음 | FR-010: 후반 타임아웃 수 |
| timeouts_overtime | 없음 | FR-010: 연장 타임아웃 수 |

---

## 2. game_rules 전체 JSON 스키마

### 2.1 최상위 구조

```json
{
  "timing": { ... },
  "shot_clock": { ... },
  "fouls": { ... },
  "timeouts": { ... },
  "scoring": { ... }
}
```

섹션을 5개로 분리한다. 섹션이 없으면 해당 섹션의 모든 값을 FIBA 기본값으로 처리한다.

### 2.2 완전한 스키마 (FIBA 2025 기준 기본값 포함)

```json
{
  "timing": {
    "quarter_minutes": 10,
    "overtime_minutes": 5,
    "halftime_seconds": 600,
    "quarter_break_seconds": 120,
    "before_overtime_seconds": 120
  },
  "shot_clock": {
    "full_seconds": 24,
    "after_offensive_rebound_seconds": 14,
    "decimal_threshold_seconds": 5,
    "decimal_precision": 1
  },
  "fouls": {
    "foul_out_limit": 5,
    "team_bonus_threshold": 5,
    "team_double_bonus_threshold": 10,
    "technical_foul_ejection_limit": 2
  },
  "timeouts": {
    "full_duration_seconds": 60,
    "twenty_second_duration_seconds": 20,
    "timeouts_first_half": 2,
    "timeouts_second_half": 3,
    "timeouts_overtime": 1,
    "bonus_timeout_last2min_enabled": false,
    "bonus_timeout_last2min_count": 1
  },
  "scoring": {
    "three_point_line_enabled": true,
    "goaltending_violation_enabled": true
  }
}
```

### 2.3 필드 명세 테이블

#### timing

| 필드 | 타입 | FIBA 기본값 | 설명 |
|------|------|------------|------|
| quarter_minutes | int | 10 | 쿼터 시간 (분) |
| overtime_minutes | int | 5 | 연장전 시간 (분) |
| halftime_seconds | int | 600 | 하프타임 휴식 (초) |
| quarter_break_seconds | int | 120 | 쿼터 간 휴식 (초) |
| before_overtime_seconds | int | 120 | 연장전 전 휴식 (초) |

#### shot_clock (FR-006 핵심)

| 필드 | 타입 | FIBA 기본값 | 설명 |
|------|------|------------|------|
| full_seconds | int | 24 | 샷클락 기본 시간 |
| after_offensive_rebound_seconds | int | 14 | 공격 리바운드 후 샷클락 |
| **decimal_threshold_seconds** | int | **5** | 이 시간 미만부터 소수점 표시 (FR-006 옵션 A) |
| **decimal_precision** | int | **1** | 소수점 자릿수: 1=1/10초, 2=1/100초 (FR-006 옵션 C) |

> FR-006 결정: 옵션 A+C. `decimal_threshold_seconds=5` 기본값, 대회 설정으로 변경 가능. `decimal_precision=1` (1/10초 표시).

#### fouls

| 필드 | 타입 | FIBA 기본값 | 설명 |
|------|------|------------|------|
| foul_out_limit | int | 5 | 파울아웃 한도 (FIBA: 5, NBA: 6) |
| team_bonus_threshold | int | 5 | 팀 파울 보너스 진입 (5파울부터) |
| team_double_bonus_threshold | int | 10 | 더블 보너스 (미사용 시 999) |
| technical_foul_ejection_limit | int | 2 | 기술적 파울 퇴장 한도 |

#### timeouts (FR-010 핵심)

| 필드 | 타입 | FIBA 기본값 | 설명 |
|------|------|------------|------|
| full_duration_seconds | int | 60 | 일반 타임아웃 지속시간 (초) |
| twenty_second_duration_seconds | int | 20 | 20초 타임아웃 지속시간 |
| **timeouts_first_half** | int | **2** | 전반 타임아웃 허용 횟수 (FR-010) |
| **timeouts_second_half** | int | **3** | 후반 타임아웃 허용 횟수 (FR-010) |
| **timeouts_overtime** | int | **1** | 연장전 타임아웃 허용 횟수 (FR-010) |
| **bonus_timeout_last2min_enabled** | bool | **false** | 마지막 2분 보너스 TO 활성화 (FR-010) |
| **bonus_timeout_last2min_count** | int | **1** | 보너스 TO 횟수 (enabled=true 시) |

#### scoring

| 필드 | 타입 | FIBA 기본값 | 설명 |
|------|------|------------|------|
| three_point_line_enabled | bool | true | 3점 라인 여부 |
| goaltending_violation_enabled | bool | true | 골텐딩 바이올레이션 |

---

## 3. Flutter 앱 파싱 로직 설계

### 3.1 GameRulesModel (신규 도메인 모델)

```dart
// lib/domain/models/game_rules_model.dart
@freezed
class GameRulesModel with _$GameRulesModel {
  const factory GameRulesModel({
    // timing
    @Default(10) int quarterMinutes,
    @Default(5) int overtimeMinutes,
    @Default(600) int halftimeSeconds,
    @Default(120) int quarterBreakSeconds,
    @Default(120) int beforeOvertimeSeconds,

    // shot_clock (FR-006)
    @Default(24) int shotClockFullSeconds,
    @Default(14) int shotClockAfterOffensiveReboundSeconds,
    @Default(5) int shotClockDecimalThresholdSeconds,
    @Default(1) int shotClockDecimalPrecision,

    // fouls
    @Default(5) int foulOutLimit,
    @Default(5) int teamBonusThreshold,
    @Default(10) int teamDoubleBonusThreshold,
    @Default(2) int technicalFoulEjectionLimit,

    // timeouts (FR-010)
    @Default(60) int timeoutFullDurationSeconds,
    @Default(20) int timeoutTwentySecondDurationSeconds,
    @Default(2) int timeoutsFirstHalf,
    @Default(3) int timeoutsSecondHalf,
    @Default(1) int timeoutsOvertime,
    @Default(false) bool bonusTimeoutLast2minEnabled,
    @Default(1) int bonusTimeoutLast2minCount,

    // scoring
    @Default(true) bool threePointLineEnabled,
    @Default(true) bool goaltendingViolationEnabled,
  }) = _GameRulesModel;

  factory GameRulesModel.fromJson(Map<String, dynamic> json) {
    final timing = json['timing'] as Map<String, dynamic>? ?? {};
    final shotClock = json['shot_clock'] as Map<String, dynamic>? ?? {};
    final fouls = json['fouls'] as Map<String, dynamic>? ?? {};
    final timeouts = json['timeouts'] as Map<String, dynamic>? ?? {};
    final scoring = json['scoring'] as Map<String, dynamic>? ?? {};

    return GameRulesModel(
      // timing
      quarterMinutes: timing['quarter_minutes'] as int? ?? 10,
      overtimeMinutes: timing['overtime_minutes'] as int? ?? 5,
      halftimeSeconds: timing['halftime_seconds'] as int? ?? 600,
      quarterBreakSeconds: timing['quarter_break_seconds'] as int? ?? 120,
      beforeOvertimeSeconds: timing['before_overtime_seconds'] as int? ?? 120,

      // shot_clock (FR-006)
      shotClockFullSeconds: shotClock['full_seconds'] as int? ?? 24,
      shotClockAfterOffensiveReboundSeconds:
          shotClock['after_offensive_rebound_seconds'] as int? ?? 14,
      shotClockDecimalThresholdSeconds:
          shotClock['decimal_threshold_seconds'] as int? ?? 5,
      shotClockDecimalPrecision:
          shotClock['decimal_precision'] as int? ?? 1,

      // fouls
      foulOutLimit: fouls['foul_out_limit'] as int? ?? 5,
      teamBonusThreshold: fouls['team_bonus_threshold'] as int? ?? 5,
      teamDoubleBonusThreshold: fouls['team_double_bonus_threshold'] as int? ?? 10,
      technicalFoulEjectionLimit: fouls['technical_foul_ejection_limit'] as int? ?? 2,

      // timeouts (FR-010)
      timeoutFullDurationSeconds: timeouts['full_duration_seconds'] as int? ?? 60,
      timeoutTwentySecondDurationSeconds:
          timeouts['twenty_second_duration_seconds'] as int? ?? 20,
      timeoutsFirstHalf: timeouts['timeouts_first_half'] as int? ?? 2,
      timeoutsSecondHalf: timeouts['timeouts_second_half'] as int? ?? 3,
      timeoutsOvertime: timeouts['timeouts_overtime'] as int? ?? 1,
      bonusTimeoutLast2minEnabled:
          timeouts['bonus_timeout_last2min_enabled'] as bool? ?? false,
      bonusTimeoutLast2minCount:
          timeouts['bonus_timeout_last2min_count'] as int? ?? 1,

      // scoring
      threePointLineEnabled: scoring['three_point_line_enabled'] as bool? ?? true,
      goaltendingViolationEnabled:
          scoring['goaltending_violation_enabled'] as bool? ?? true,
    );
  }

  const GameRulesModel._();

  /// 대회 미연결 시 기본값 (FIBA 2025)
  static const GameRulesModel defaults = GameRulesModel();

  /// 샷클락 소수점 표시 여부 (FR-006)
  bool shouldShowDecimal(int remainingSeconds) {
    return remainingSeconds < shotClockDecimalThresholdSeconds;
  }

  /// 타임아웃 잔여 횟수 계산 (FR-010)
  int timeoutsAllowedForHalf(int half) {
    // half: 1=전반(Q1+Q2), 2=후반(Q3+Q4), 3+=연장
    switch (half) {
      case 1:
        return timeoutsFirstHalf;
      case 2:
        return timeoutsSecondHalf;
      default:
        return timeoutsOvertime;
    }
  }
}
```

### 3.2 기존 GameRulesDefaults 호환 유지 전략

```dart
// app_constants.dart의 GameRulesDefaults는 그대로 유지 (하위 호환)
// 신규 코드는 GameRulesModel을 사용
// Provider에서 변환:
final gameRulesProvider = Provider<GameRulesModel>((ref) {
  final tournament = ref.watch(currentTournamentProvider);
  if (tournament == null) return const GameRulesModel();
  try {
    final json = jsonDecode(tournament.gameRulesJson) as Map<String, dynamic>;
    return GameRulesModel.fromJson(json);
  } catch (_) {
    return const GameRulesModel(); // fallback
  }
});
```

---

## 4. mybdr API: game_rules 저장/조회

### 4.1 현재 상태

`Tournament.game_rules` JSONB 컬럼에 자유 형식으로 저장.
대회 생성/수정 API에서 이 필드를 그대로 pass-through.

### 4.2 Sprint 2에서 추가 필요한 API

**API-GR-01: 대회 game_rules 조회**
```
GET /api/v1/tournaments/:id/game-rules
Authorization: Bearer {tournament_api_token}

Response 200:
{
  "game_rules": {
    "timing": { "quarter_minutes": 10, ... },
    "shot_clock": { "full_seconds": 24, "decimal_threshold_seconds": 5, ... },
    "fouls": { "foul_out_limit": 5, ... },
    "timeouts": { "timeouts_first_half": 2, ... },
    "scoring": { "three_point_line_enabled": true }
  }
}
```

> Flutter 앱은 대회 연결 시 tournament verify API 응답에 `game_rules` 포함. 별도 API 불필요.
> `GET /api/v1/tournaments/:id/verify` 응답에 이미 tournament 객체 포함 → game_rules 추가만 필요.

---

## 5. ADR-001: game_rules를 섹션별 JSON으로 구조화

```
ADR-001: game_rules JSON 스키마 구조화
상태: 승인
작성일: 2026-03-16
요구사항: FR-006, FR-010
```

### 컨텍스트

`Tournament.game_rules` JSONB 컬럼에 키를 추가해야 한다. FR-006(샷클락 소수점)과 FR-010(타임아웃)을 위한 신규 키가 필요하다. 기존 코드베이스의 `GameRulesDefaults`는 단일 평탄 구조(`quarter_minutes`, `shot_clock_seconds` 등)를 사용하고 있다.

### 결정: 섹션별 중첩 JSON 구조 도입

기존 평탄 구조를 유지하는 대신, `timing` / `shot_clock` / `fouls` / `timeouts` / `scoring` 5개 섹션으로 구조화한다.

### 대안 검토

**대안 A: 기존 평탄 구조 확장**
```json
{
  "quarter_minutes": 10,
  "shot_clock_decimal_threshold": 5,
  "timeouts_first_half": 2
}
```
- 장점: 기존 코드 최소 변경
- 단점: 키가 30개 이상이 되면 관련 설정을 파악하기 어렵다. `shot_clock_seconds`와 `shot_clock_decimal_threshold`의 관계가 네이밍만으로 명확하지 않다.

**대안 B: 섹션별 중첩 구조 (채택)**
- 장점: 관련 설정이 그룹화되어 있어 읽기 용이. 새 섹션 추가 시 기존 섹션에 영향 없음. Ethan이 "shot_clock 관련 설정을 모두 찾아라"라는 요청에 즉시 응답 가능.
- 단점: 기존 `GameRulesDefaults.fromJson`을 교체해야 한다 (하위 호환 처리 필요).

### 결과

- 기존 `GameRulesDefaults`는 deprecated 처리하지 않고 유지. 신규 코드는 `GameRulesModel`을 사용.
- 서버에 game_rules가 비어 있거나 구 형식이면 클라이언트 기본값으로 fallback.

### 트레이드오프

포기하는 것: `GameRulesDefaults.fromJson`과 `GameRulesModel.fromJson` 두 가지 파싱 경로가 공존하는 기간 동안 혼란 가능.
얻는 것: 섹션 추가(예: `shot_clock.plus_time_enabled` 등)가 다른 섹션에 영향을 주지 않는 안전한 확장성.
