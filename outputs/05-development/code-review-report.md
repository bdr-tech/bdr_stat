# Code Review Report - BDR Tournament Recorder

> **작성자**: Ethan (05-developer)
> **작성일**: 2026-02-12
> **검토 기준**: CLAUDE.md 코드 컨벤션 및 절대 금지 사항

---

## 1. 요약

| 분류 | 위반 건수 | 심각도 |
|------|----------|--------|
| Navigator 직접 사용 | 8건 | 중간 |
| StatelessWidget 사용 (ConsumerWidget 대체 필요) | 3건 | 중간 |
| 하드코딩된 타이머 값 | 2건 | 낮음 |
| 트랜잭션 미사용 (잠재적) | 1건 | 낮음 |
| **총계** | **14건** | - |

✅ **긍정적 발견사항**:
- 오프라인 우선 아키텍처 잘 구현됨 (로컬 DB 먼저 저장, 동기화는 별도)
- Riverpod StateNotifier 패턴 일관되게 사용
- GoRouter 사용 (단, 일부 다이얼로그에서 Navigator.pop 사용)
- Drift DAO 패턴 적절히 구현됨

---

## 2. 상세 위반 사항

### 2.1 Navigator 직접 사용 (GoRouter로 대체 필요)

**CLAUDE.md 규칙 위반**:
```dart
// ❌ 직접 Navigator 사용 (일관성)
Navigator.push(context, MaterialPageRoute(...));

// ✅ GoRouter 또는 일관된 라우팅 방식
context.push('/game-recording');
```

| 파일 | 라인 | 현재 코드 | 수정 방향 |
|------|------|----------|----------|
| `tournament_list_screen.dart` | 509 | `Navigator.pop(context)` | `context.pop()` |
| `tournament_list_screen.dart` | 514 | `Navigator.pop(context)` | `context.pop()` |
| `match_list_screen.dart` | 173 | `Navigator.pop(context)` | `context.pop()` |
| `match_list_screen.dart` | 180 | `Navigator.pop(context)` | `context.pop()` |
| `match_list_screen.dart` | 197 | `Navigator.pop(context)` | `context.pop()` |
| `match_list_screen.dart` | 203 | `Navigator.pop(context)` | `context.pop()` |
| `shot_result_dialog.dart` | 119 | `Navigator.pop(context, true)` | `context.pop(true)` |
| `shot_result_dialog.dart` | 132 | `Navigator.pop(context, false)` | `context.pop(false)` |
| `shot_result_dialog.dart` | 143 | `Navigator.pop(context)` | `context.pop()` |

### 2.2 StatelessWidget 사용 (ConsumerWidget 대체 권장)

**CLAUDE.md 규칙 위반**:
```dart
// ✅ 좋은 예
class PlayerCard extends ConsumerWidget {
  const PlayerCard({super.key, required this.player});
  ...
}

// ❌ 나쁜 예 - StatelessWidget 대신 ConsumerWidget 사용
class PlayerCard extends StatelessWidget { ... }
```

| 파일 | 라인 | 클래스명 | 상태 |
|------|------|---------|------|
| `match_list_screen.dart` | 500 | `_TeamInfo` | StatelessWidget → ConsumerWidget |
| `shot_result_dialog.dart` | 7 | `ShotResultDialog` | StatelessWidget → ConsumerWidget |
| `shot_result_dialog.dart` | 154 | `_ResultButton` | StatelessWidget → ConsumerWidget |

**참고**: 현재 Provider를 사용하지 않는 순수 UI 위젯이라면 StatelessWidget 사용도 허용될 수 있으나, 일관성과 향후 확장성을 위해 ConsumerWidget 사용 권장

### 2.3 하드코딩된 타이머/딜레이 값

**CLAUDE.md 규칙 위반**:
```dart
// ❌ 하드코딩된 타이머 값
Timer(Duration(seconds: 10), callback);

// ✅ game_rules에서 가져오기
final quarterMinutes = tournament.gameRules.quarterMinutes;
```

| 파일 | 라인 | 현재 값 | 권장 조치 |
|------|------|---------|----------|
| `splash_screen.dart` | ~55 | `1500.ms`, `100.ms` | 상수 또는 설정으로 분리 |
| `network_status_provider.dart` | 81 | `Duration(seconds: 30)` | 설정 가능한 상수로 분리 |

### 2.4 트랜잭션 미사용 (잠재적 문제)

**CLAUDE.md 규칙**:
```dart
// 필수:
// - 모든 DB 작업은 트랜잭션으로 감싸기
// - PlayByPlay 저장 실패 시 롤백
```

| 파일 | 메서드 | 문제점 |
|------|--------|--------|
| `player_stats_dao.dart` | 개별 recordXxx 메서드 | 연관 스탯 업데이트가 트랜잭션으로 묶이지 않음 |

**세부사항**:
- `recordTwoPointer`, `recordThreePointer`, `recordFreeThrow` 등이 개별 호출됨
- 슛 기록 시 PlayByPlay와 PlayerStats가 함께 업데이트되어야 하나, UseCase 레벨에서 트랜잭션 처리 필요
- 현재 `PlayByPlayDao.insertPlays`는 batch 사용 중 (양호)

---

## 3. 긍정적 발견사항 (준수 항목)

### 3.1 오프라인 우선 아키텍처 ✅

`sync_manager.dart` 분석 결과:
- 로컬 DB 먼저 저장 후 동기화 수행
- 네트워크 체크 후 분기하는 저장 로직 없음
- 지수 백오프(Exponential Backoff) 재시도 구현
- 충돌 감지 및 해결 로직 포함

```dart
// 올바른 패턴 (sync_manager.dart)
// 1. 로컬에 먼저 저장 (recordStat 등)
// 2. 동기화 시 서버로 전송
// 3. 실패 시 재시도 큐에 추가
```

### 3.2 Riverpod 상태 관리 ✅

- `StateNotifierProvider` 적절히 사용
- `FutureProvider`, `StreamProvider` 비동기 데이터 처리
- `Provider`로 단순 읽기 값 제공
- 전역 변수 사용 없음

### 3.3 Drift DAO 패턴 ✅

- 모든 DB 작업이 DAO를 통해 수행
- Drift 쿼리 빌더 사용 (직접 SQL 문자열 없음)
- batch 연산 적절히 활용

### 3.4 GoRouter 라우팅 ✅

- 메인 네비게이션은 `context.go()`, `context.push()` 사용
- 일부 다이얼로그만 `Navigator.pop()` 사용 (수정 필요)

---

## 4. 리팩토링 계획

### Phase 1: Navigator.pop → context.pop 변환 (우선순위: 높음)

```dart
// 변경 전
Navigator.pop(context);
Navigator.pop(context, true);

// 변경 후
import 'package:go_router/go_router.dart';
context.pop();
context.pop(true);
```

**대상 파일**:
1. `lib/presentation/screens/tournament/tournament_list_screen.dart`
2. `lib/presentation/screens/match/match_list_screen.dart`
3. `lib/presentation/widgets/dialogs/shot_result_dialog.dart`

### Phase 2: StatelessWidget → ConsumerWidget 변환 (우선순위: 중간)

**대상 파일**:
1. `lib/presentation/screens/match/match_list_screen.dart` - `_TeamInfo`
2. `lib/presentation/widgets/dialogs/shot_result_dialog.dart` - `ShotResultDialog`, `_ResultButton`

### Phase 3: 상수 추출 (우선순위: 낮음)

**신규 파일 생성**: `lib/core/constants/timing_constants.dart`

```dart
class TimingConstants {
  static const Duration splashDelay = Duration(milliseconds: 1500);
  static const Duration splashFadeIn = Duration(milliseconds: 100);
  static const Duration networkCheckInterval = Duration(seconds: 30);
}
```

### Phase 4: 트랜잭션 래퍼 추가 (우선순위: 낮음)

UseCase 레벨에서 복합 DB 작업을 트랜잭션으로 묶는 패턴 적용

---

## 5. 테스트 계획

### 단위 테스트 대상

1. **Navigator → GoRouter 변환 후**
   - 다이얼로그 닫기 동작 확인
   - 결과 값 전달 확인

2. **StatelessWidget → ConsumerWidget 변환 후**
   - 렌더링 정상 동작
   - (필요 시) Provider 연결 테스트

3. **상수 분리 후**
   - 타이밍 값 올바르게 적용되는지 확인

---

## 6. 결론

BDR Tournament Recorder 코드베이스는 전반적으로 CLAUDE.md의 핵심 원칙(오프라인 우선, 로컬 먼저 저장)을 잘 준수하고 있습니다.

발견된 14건의 위반 사항 중 대부분은 일관성 관련 이슈이며, 심각한 아키텍처 위반은 없습니다. Navigator.pop 사용 건은 GoRouter로 통일하는 것이 좋으며, StatelessWidget 사용 건은 프로젝트 컨벤션에 따라 ConsumerWidget으로 변경을 권장합니다.

**권장 조치 우선순위**:
1. 🔴 Navigator.pop → context.pop 변환 (일관성)
2. 🟡 StatelessWidget → ConsumerWidget 변환 (컨벤션)
3. 🟢 하드코딩 상수 분리 (유지보수성)

---

*Ethan (05-developer) - BDR AI Development Team*
