# Bug Report - BDR Tournament Recorder

> **작성자**: Nora (06-qa)
> **작성일**: 2026-02-12
> **버전**: 1.0
> **최종 업데이트**: 2026-02-12

---

## 결함 요약

| 총 결함 | Critical | Major | Minor | Trivial | 해결됨 |
|---------|----------|-------|-------|---------|--------|
| 2 | 0 | 1 | 0 | 1 | **2** |

---

## BUG-001: 액션 연동 자동화 미구현

### 기본 정보

| 항목 | 값 |
|------|-----|
| **ID** | BUG-001 |
| **심각도** | Major |
| **우선순위** | High |
| **상태** | ✅ **Closed (Fixed)** |
| **컴포넌트** | Domain Layer / UseCase |
| **관련 요구사항** | FR-002 (액션 연동 자동화) |
| **수정자** | Ethan (05-developer) |
| **수정일** | 2026-02-12 |

### 설명

CLAUDE.md에 명시된 액션 연동 자동화 기능이 구현되어 있지 않습니다.

#### CLAUDE.md 요구사항 (필수 연동 목록)

```dart
// 스틸 기록 시 → 상대 턴오버 자동
Future<void> recordSteal(int stealPlayerId, int turnoverPlayerId) async {
  await database.transaction(() async {
    await _recordStat(stealPlayerId, StatType.steal, 1);
    await _recordStat(turnoverPlayerId, StatType.turnover, 1);  // 자동!
    await _recordPlayByPlay(...);
  });
}

// 필수 연동 목록:
// - 스틸 → 상대 턴오버
// - 블락 → 상대 슛 실패
// - 오펜시브 파울 → 본인 턴오버
// - 슈팅 파울 → 자유투 시퀀스
// - 5파울 → 강제 교체 모달
```

### 수정 내용 (Ethan)

UseCase 레이어 구현으로 액션 연동 자동화 완료:

| UseCase | 기능 |
|---------|------|
| `RecordStealUseCase` | 스틸 → 상대 턴오버 자동 연동 |
| `RecordBlockUseCase` | 블락 → 상대 슛 실패 자동 연동 |
| `RecordFoulUseCase` | 오펜시브 파울 → 턴오버, 슈팅 파울 → FT 시퀀스 |

#### 추가된 파일
- `lib/domain/usecases/linked_action_result.dart`
- `lib/domain/usecases/record_steal_usecase.dart`
- `lib/domain/usecases/record_block_usecase.dart`
- `lib/domain/usecases/record_foul_usecase.dart`
- `lib/domain/usecases/usecases.dart`
- `lib/di/usecase_providers.dart`

#### 스키마 변경
- `LocalPlayByPlays` 테이블에 `linkedActionId` 컬럼 추가
- 스키마 버전 3 → 4

### QA 검증 결과

| 테스트 항목 | 결과 |
|-------------|------|
| 신규 UseCase 테스트 24개 | ✅ Pass |
| 전체 프로젝트 테스트 402개 | ✅ Pass |
| 스틸→턴오버 연동 | ✅ 확인 |
| 블락→슛실패 연동 | ✅ 확인 |
| 오펜시브파울→턴오버 연동 | ✅ 확인 |
| 슈팅파울→FT시퀀스 반환 | ✅ 확인 |
| 5파울→fouledOut 플래그 | ✅ 확인 |

**검증 완료일**: 2026-02-12

---

## BUG-002: 하드코딩된 타이머 값

### 기본 정보

| 항목 | 값 |
|------|-----|
| **ID** | BUG-002 |
| **심각도** | Trivial |
| **우선순위** | Low |
| **상태** | ✅ **Closed (Fixed)** |
| **컴포넌트** | Core / Presentation |
| **관련 요구사항** | - |
| **수정자** | Ethan (05-developer) |
| **수정일** | 2026-02-12 |

### 설명

타이머 관련 값들이 하드코딩되어 있습니다.

### 발견 위치

1. `lib/presentation/screens/splash_screen.dart`
   - 스플래시 화면 딜레이 (1500ms)
   - AuthProvider 대기 간격 (100ms)
   - AuthProvider 대기 횟수 (30회)

2. `lib/presentation/providers/network_status_provider.dart`
   - 네트워크 체크 간격 (30초)
   - 인터넷 접근 타임아웃 (5초)

### 수정 내용 (Ethan)

`AppConstants`에 타이머 상수 추가 및 해당 파일에서 상수 참조:

```dart
// lib/core/constants/app_constants.dart
static const Duration splashInitialDelay = Duration(milliseconds: 1500);
static const Duration authCheckInterval = Duration(milliseconds: 100);
static const int authCheckMaxAttempts = 30;
static const Duration networkCheckInterval = Duration(seconds: 30);
static const Duration internetAccessTimeout = Duration(seconds: 5);
```

### QA 검증 결과

| 검증 항목 | 결과 |
|----------|------|
| splash_screen.dart 하드코딩 제거 | ✅ 확인 |
| network_status_provider.dart 하드코딩 제거 | ✅ 확인 |
| AppConstants 상수 추가 (5개) | ✅ 확인 |
| 전체 테스트 402개 | ✅ Pass |

#### 상세 검증

**splash_screen.dart**:
```
Line 29: await Future.delayed(AppConstants.splashInitialDelay);
Line 45: for (var i = 0; i < AppConstants.authCheckMaxAttempts; i++) {
Line 46: await Future.delayed(AppConstants.authCheckInterval);
```

**network_status_provider.dart**:
```
Line 84: AppConstants.networkCheckInterval,
Line 135: .timeout(AppConstants.internetAccessTimeout);
```

**검증 완료일**: 2026-02-12

---

## 참고: 이전 개발 단계에서 수정된 항목

> 아래 항목들은 Ethan(05-developer)의 리팩토링에서 수정 완료되었습니다.

### 수정 완료 - Navigator.pop → context.pop 변환

| 파일 | 변경 사항 | 상태 |
|------|----------|------|
| `tournament_list_screen.dart` | 2건 변환 | ✅ 완료 |
| `match_list_screen.dart` | 4건 변환 | ✅ 완료 |
| `shot_result_dialog.dart` | 3건 변환 | ✅ 완료 |

### 수정 완료 - StatelessWidget → ConsumerWidget 변환

| 파일 | 클래스 | 상태 |
|------|--------|------|
| `match_list_screen.dart` | `_TeamInfo` | ✅ 완료 |
| `shot_result_dialog.dart` | `ShotResultDialog` | ✅ 완료 |
| `shot_result_dialog.dart` | `_ResultButton` | ✅ 완료 |

---

## 결함 추적 히스토리

| 날짜 | 결함 ID | 변경 사항 | 담당자 |
|------|---------|----------|--------|
| 2026-02-12 | BUG-001 | 신규 등록 | Nora (06-qa) |
| 2026-02-12 | BUG-001 | 수정 완료 | Ethan (05-developer) |
| 2026-02-12 | BUG-001 | 검증 완료 → Closed | Nora (06-qa) |
| 2026-02-12 | BUG-002 | 신규 등록 | Nora (06-qa) |
| 2026-02-12 | BUG-002 | 수정 완료 | Ethan (05-developer) |
| 2026-02-12 | BUG-002 | 검증 완료 → Closed | Nora (06-qa) |

---

## QA 최종 결론

| 항목 | 상태 |
|------|------|
| 모든 버그 수정됨 | ✅ |
| 전체 테스트 통과 | ✅ (402/402) |
| 회귀 버그 | 없음 |
| 릴리스 준비 | **Ready** |

---

*Nora (06-qa) - BDR AI Development Team*
