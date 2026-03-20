# BUG-001 수정 완료 보고서

## 버그 개요

| 항목 | 내용 |
|------|------|
| **버그 ID** | BUG-001 |
| **제목** | 액션 연동 자동화 미구현 |
| **심각도** | Major |
| **상태** | ✅ 수정 완료 |
| **수정자** | Ethan (05-developer) |
| **수정일** | 2026-02-12 |

## 문제 분석

### 원인
- CLAUDE.md에 명시된 액션 연동 자동화 요구사항이 구현되지 않음
- 기존 DAO에서 개별 스탯 기록만 수행하고, 연결된 액션 자동 기록 미구현

### 미구현 요구사항 (CLAUDE.md)
```
// 필수 연동 목록:
// - 스틸 → 상대 턴오버
// - 블락 → 상대 슛 실패
// - 오펜시브 파울 → 본인 턴오버
// - 슈팅 파울 → 자유투 시퀀스
// - 5파울 → 강제 교체 모달
```

## 수정 내용

### 1. UseCase Layer 신규 추가

아키텍처 패턴에 따라 비즈니스 로직을 UseCase로 분리하여 구현:

```
lib/domain/usecases/
├── linked_action_result.dart    # 결과 모델, FoulType, FreeThrowSequence
├── record_steal_usecase.dart    # 스틸 + 턴오버 자동 연동
├── record_block_usecase.dart    # 블락 + 슛 실패 자동 연동
├── record_foul_usecase.dart     # 파울 종류별 자동 연동
└── usecases.dart                # Export 파일
```

### 2. 데이터베이스 스키마 수정

`LocalPlayByPlays` 테이블에 액션 연결을 위한 컬럼 추가:

```dart
// lib/data/database/tables.dart
TextColumn get linkedActionId => text().nullable()();
```

- 스키마 버전: 3 → 4
- 마이그레이션: `ALTER TABLE local_play_by_plays ADD COLUMN linked_action_id TEXT`

### 3. Riverpod Provider 추가

```dart
// lib/di/usecase_providers.dart
final recordStealUseCaseProvider = Provider<RecordStealUseCase>(...);
final recordBlockUseCaseProvider = Provider<RecordBlockUseCase>(...);
final recordFoulUseCaseProvider = Provider<RecordFoulUseCase>(...);
```

## UseCase 구현 상세

### RecordStealUseCase
- **기능**: 스틸 기록 시 상대 턴오버 자동 기록
- **트랜잭션**: 원자성 보장
- **Play-by-Play**: 스틸과 턴오버 양방향 linkedActionId 연결
- **Undo**: 스틸/턴오버 동시 롤백

### RecordBlockUseCase
- **기능**: 블락 기록 시 상대 슛 실패 자동 기록
- **슛 타입**: 2점/3점 구분하여 해당 스탯에 반영
- **코트 위치**: courtX, courtY, courtZone 지원
- **Undo**: 블락/슛실패 동시 롤백

### RecordFoulUseCase
- **일반 파울**: 파울 카운트 증가, 5파울 시 fouledOut 플래그
- **오펜시브 파울**: 파울 + 본인 턴오버 자동 연동
- **슈팅 파울**: 파울 + FreeThrowSequence 정보 반환
- **5파울 감지**: metadata에 isFouledOut 포함 (UI에서 교체 모달 표시용)

## 테스트 결과

### 신규 테스트 추가
- `test/unit/usecases/record_steal_usecase_test.dart` (5개)
- `test/unit/usecases/record_block_usecase_test.dart` (6개)
- `test/unit/usecases/record_foul_usecase_test.dart` (13개)

### 테스트 커버리지
| 항목 | 결과 |
|------|------|
| 신규 UseCase 테스트 | 24개 통과 |
| 전체 프로젝트 테스트 | 402개 통과 |
| 실패 테스트 | 0개 |

## 파일 변경 목록

### 신규 파일 (6개)
1. `lib/domain/usecases/linked_action_result.dart`
2. `lib/domain/usecases/record_steal_usecase.dart`
3. `lib/domain/usecases/record_block_usecase.dart`
4. `lib/domain/usecases/record_foul_usecase.dart`
5. `lib/domain/usecases/usecases.dart`
6. `lib/di/usecase_providers.dart`

### 수정 파일 (2개)
1. `lib/data/database/tables.dart` - linkedActionId 컬럼 추가
2. `lib/data/database/database.dart` - 스키마 버전 4, 마이그레이션 추가

### 테스트 파일 (3개)
1. `test/unit/usecases/record_steal_usecase_test.dart`
2. `test/unit/usecases/record_block_usecase_test.dart`
3. `test/unit/usecases/record_foul_usecase_test.dart`

## 사용 가이드 (UI 연동)

### 스틸 기록 예시
```dart
final useCase = ref.read(recordStealUseCaseProvider);
final result = await useCase.execute(
  matchId: matchId,
  stealPlayerId: stealPlayer.id,
  stealPlayerTeamId: stealPlayer.teamId,
  turnoverPlayerId: turnoverPlayer.id,
  turnoverPlayerTeamId: turnoverPlayer.teamId,
  quarter: currentQuarter,
  gameClockSeconds: gameClock,
  homeScore: homeScore,
  awayScore: awayScore,
);

if (result.success) {
  // 스틸 + 턴오버 모두 기록 완료
}
```

### 슈팅 파울 예시 (자유투 시퀀스)
```dart
final useCase = ref.read(recordFoulUseCaseProvider);
final result = await useCase.executeShootingFoul(
  matchId: matchId,
  foulPlayerId: foulPlayer.id,
  foulPlayerTeamId: foulPlayer.teamId,
  fouledPlayerId: shooter.id,
  fouledPlayerTeamId: shooter.teamId,
  quarter: currentQuarter,
  gameClockSeconds: gameClock,
  homeScore: homeScore,
  awayScore: awayScore,
  freeThrowCount: 2,
  wasShootingThreePointer: false,
);

if (result.success) {
  final ftSequence = FreeThrowSequence.fromMap(
    result.metadata!['freeThrowSequence'],
  );
  // 자유투 입력 모달 표시
  showFreeThrowModal(ftSequence);

  // 5파울 확인
  if (result.metadata!['isFouledOut'] == true) {
    showSubstitutionModal(foulPlayer);
  }
}
```

## 후속 작업

1. **UI 연동**: 기록 화면에서 UseCase 호출로 전환 필요
2. **BUG-002**: 하드코딩된 타이머 값 수정 (Trivial)

---

**검토자**: Nora (06-qa)
**승인**: Pending
