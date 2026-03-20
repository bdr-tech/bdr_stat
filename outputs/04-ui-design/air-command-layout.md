# 에어커맨드 원형 메뉴 레이아웃 설계

> Aria (UI/UX 디자이너) | BDR Sprint 2 | 2026-03-16
> 요구사항 연계: FR-012 (에어커맨드 UX 변경, WBS 2.1)
> 참조: plan.md FR-012, radial_action_menu.dart (기존 구현), CLAUDE.md

---

## 1. 설계 배경 및 현황 분석

### 1.1 현재 구현 (radial_action_menu.dart) 분석

현재 `RadialActionMenu`는 아래 구조로 동작한다:

- **트리거**: 탭(GestureDetector.onTapDown) 또는 스타일러스 호버 300ms 딜레이
- **배치 알고리즘**: `_calculateAngle()` — 12시 방향(-π/2)에서 시작, 균등 분할
- **현재 defaultActions**: `[twoPointMade, threePointMade, rebound, assist, foul, substitution]` — 6개 버튼
- **문제점**:
  - 파울 단일 항목만 있음 → 서브메뉴 없음
  - OR/DR 구분 없이 rebound 단일 항목
  - 순서가 FR-012 명세(파울 12시 → 시계방향 OR/DR/AST/BLK/STL/TO)와 불일치
  - `menuRadius: 65, buttonRadius: 18` (BenchPlayerIcon) → 터치 타겟 36px — Apple HIG 44px 미달

### 1.2 FR-012 요구 배치

```
          [FOUL]        ← 12시 (0°)
    [TO]          [OR]  ← 11시(330°) / 1시(30°)
  [STL]            [DR] ← 9시(270°) / ...
    [BLK]        [AST]  ← 7시(210°) / 5시(150°)
```

시계방향 순서: FOUL(12시) → OR(1시 = 약 2시) → DR → AST → BLK → STL → TO(11시 = 약 10시)

> 파울은 12시에 고정, 나머지 6개를 1시 방향부터 시계방향으로 배치한다.
> 총 7개 버튼이므로 360/7 = 약 51.4° 간격.

---

## 2. 원형 메뉴 기하학 명세

### 2.1 버튼 배치 각도 (단위: 도)

| 버튼 | 위치 | 각도 | 설명 |
|------|------|------|------|
| FOUL | 12시 | -90° | 고정 (최상단) |
| OR   | 약 1~2시 | -38° | 공격리바운드 |
| DR   | 약 3~4시 | 13°  | 수비리바운드 |
| AST  | 약 5시   | 64°  | 어시스트 |
| BLK  | 약 7시   | 167° | 블락 |
| STL  | 약 9시   | 218° | 스틸 |
| TO   | 약 10~11시 | 269° | 턴오버 |

> 각도 계산: startAngle = -π/2 (12시), 7개 균등 배치이므로 첫 버튼은 -π/2에 위치.
> 구현 시 `_calculateAngle`의 기존 균등 분할 로직 재사용 가능.

### 2.2 크기 명세

| 항목 | 현재 (BenchSection) | Sprint 2 목표 | 근거 |
|------|---------------------|----------------|------|
| menuRadius | 65 | **100** | 7버튼 간격 확보 |
| buttonRadius | 18 | **26** | 터치 타겟 52px (Apple HIG 44px 초과) |
| 터치 타겟 | 36px | **52px** | HIG 준수 |
| 애니메이션 | 200ms | **200ms** | 유지 (FR-012 요건: 200ms 이내) |
| centerWidget 크기 | menuRadius*1.2 = 78px | **120px** | 선수 이름 + 현재 스탯 표시 |

### 2.3 ASCII 와이어프레임 — 원형 메뉴 전체 구조

```
              [ FOUL ]
             (빨강/레드)
          ↑ 최상단 고정

    [TO]              [OR]
  (앰버/노랑)        (빨강/오렌지)

                ┌─────────────────┐
                │   #23 김민준    │  ← centerWidget
                │  5P 3R 1A      │  ← 현재 스탯
                └─────────────────┘

    [STL]             [DR]
  (에메랄드)         (파랑)

          [BLK]    [AST]
        (스카이블루) (인디고)
```

### 2.4 실제 픽셀 레이아웃 (menuRadius=100, buttonRadius=26)

```
총 캔버스 크기: (100+26)*2 = 252px × 252px

12시 방향 FOUL 버튼 중심: (126, 26)
1~2시 OR 버튼 중심: (126 + 100*cos(-38°), 126 + 100*sin(-38°))
                  ≈ (126+79, 126-62) = (205, 64)
3~4시 DR 버튼:     ≈ (126+92, 126+23) = (218, 149)
5시 AST 버튼:      ≈ (126+45, 126+91) = (171, 217)
7시 BLK 버튼:      ≈ (126-45, 126+91) = (81, 217)
9시 STL 버튼:      ≈ (126-92, 126+23) = (34, 149)
10~11시 TO 버튼:   ≈ (126-79, 126-62) = (47, 64)
```

---

## 3. 파울 서브메뉴 설계

### 3.1 서브메뉴 트리거

FOUL 버튼 탭 → 원형 메뉴 닫힘 → **즉시 파울 서브메뉴 표시** (새 오버레이)

### 3.2 서브메뉴 레이아웃 (6개 버튼)

FOUL 선택 후 표시되는 2차 원형 메뉴. 중앙에 "파울 종류" 표시.

```
               [테크니컬]
              (회색/중립)

  [U파울]              [오펜스]
  (보라)               (주황)

        ┌─────────────────┐
        │     FOUL        │
        │    종류 선택     │
        └─────────────────┘

  [플래그런트2]        [디펜스]
  (진빨강/크리티컬)    (파랑)

             [플래그런트1]
             (빨강)
```

### 3.3 파울 서브타입 컬러 코드 (Kai에게 전달)

| 서브타입 | 레이블 | 색상 | actionSubtype |
|---------|--------|------|---------------|
| 오펜스 파울 | OFFNS | `Color(0xFFF97316)` 주황 | `'offensive'` |
| 디펜스 파울 | DEFNS | `Color(0xFF3B82F6)` 파랑 | `'personal'` |
| 테크니컬 | TECH | `Color(0xFF6B7280)` 회색 | `'technical'` |
| U파울 | UNSP | `Color(0xFF8B5CF6)` 보라 | `'unsportsmanlike'` |
| 플래그런트 1 | FLAG1 | `Color(0xFFDC2626)` 빨강 | `'flagrant'` + `isFlagrant: true` |
| 플래그런트 2 | FLAG2 | `Color(0xFF7F1D1D)` 진빨강 | `'flagrant2'` (신규) |

### 3.4 서브메뉴 크기

- menuRadius: 90 (본메뉴보다 살짝 작게)
- buttonRadius: 26 (동일)
- 중앙 위젯: "FOUL 종류" 텍스트

---

## 4. 상태별 디자인 명세

### 4.1 정상 상태 (Normal)

- 선수 카드 탭 → 200ms 애니메이션으로 메뉴 등장
- 중앙 위젯: 등번호(크게) + 이름(작게) + 현재 스탯 한 줄(PTS/REB/AST)
- 배경: `AppTheme.surfaceColor.withValues(alpha: 0.95)` 반투명
- 배경 탭 → 메뉴 닫힘

### 4.2 로딩 상태

해당 없음 (로컬 동작, 즉시 반응).

### 4.3 빈 상태 (Empty)

해당 없음. 메뉴는 항상 7개 버튼 표시.

### 4.4 에러 상태

- FOUL → 서브메뉴 중 "뒤로가기" 버튼 없는 경우: 배경 탭으로 닫기 가능
- 파울 5개 초과 선수: 메뉴는 열리되 FOUL 버튼에 비활성 오버레이 + "파울아웃" 텍스트 표시

```
FOUL 버튼 (파울아웃):
┌────────────────────┐
│  [front_hand] icon │  ← 투명도 0.4
│    FOUL OUT        │  ← 텍스트 변경
└────────────────────┘
```

### 4.5 비활성화 상태

- 게임 클락 미실행(isPaused) 중에는 메뉴 열림은 허용
- 5파울 선수: FOUL 버튼만 비활성 처리 (나머지 스탯은 기록 가능)

---

## 5. 인터랙션 플로우

```
선수 탭/호버
    │
    ▼ (200ms 이내)
원형 메뉴 표시
    │
    ├─── OR/DR/AST/BLK/STL/TO 탭
    │         │
    │         └── 즉시 기록 + 메뉴 닫힘 + Undo 스낵바(2초)
    │
    └─── FOUL 탭
              │
              └── 파울 서브메뉴 표시 (1차 메뉴 닫힘)
                      │
                      ├── 서브타입 탭 → 즉시 기록 + 닫힘
                      └── 배경 탭 → 취소 (메뉴 닫힘)
```

---

## 6. Flutter 구현 가이드 (Kai에게)

### 6.1 수정 필요 파일

`lib/presentation/widgets/action_menu/radial_action_menu.dart`

### 6.2 신규 Actions 목록 (RadialAction 상수 추가)

```dart
// 기존 offensiveRebound, defensiveRebound, steal, block, turnover, foul 활용
// foul 버튼에 서브메뉴 트리거 기능 추가 필요

static const List<RadialAction> sprintTwoActions = [
  foul,               // index 0 → 12시 (첫 번째)
  offensiveRebound,   // index 1 → 1~2시
  defensiveRebound,   // index 2 → 3~4시
  assist,             // index 3 → 5시
  block,              // index 4 → 7시
  steal,              // index 5 → 9시
  turnover,           // index 6 → 10~11시
];
```

### 6.3 파울 서브메뉴 구현 전략

`RadialAction`에 `hasSubmenu: bool` 필드 추가 또는 `onActionSelected` 콜백에서 분기 처리.

권장: `RadialActionMenu`에 `onFoulSelected` 별도 콜백 추가:
```dart
final void Function()? onFoulTapped;  // 파울 탭 시 서브메뉴 열기
```

서브메뉴는 동일한 `_RadialMenuOverlay` 재사용. 포지션은 원래 선수 카드 위치 기반.

### 6.4 크기 변경 (BenchSection, CourtWithPlayers)

```dart
// BenchSection 내 _BenchPlayerIcon
RadialActionMenu(
  actions: RadialAction.sprintTwoActions,
  menuRadius: 100,      // 65 → 100
  buttonRadius: 26,     // 18 → 26
  ...
)

// CourtWithPlayers 내 선수 아이콘
RadialActionMenu(
  actions: RadialAction.sprintTwoActions,
  menuRadius: 110,      // 코트 위 선수는 약간 더 크게
  buttonRadius: 26,
  ...
)
```

### 6.5 flagrant2 ActionSubtype 추가

```dart
// lib/core/constants/event_definitions.dart (또는 해당 파일)
static const String flagrant2 = 'flagrant2';
```

---

## 7. 접근성 체크리스트

- [x] 터치 타겟 52px — Apple HIG 44px 초과 (RISK-003 대응)
- [x] 각 버튼 색상 대비: 흰 아이콘/텍스트 위 채도 높은 배경 → 4.5:1 이상 확보
- [x] 배경 탭으로 취소 가능 — 실수 방지
- [x] FOUL 서브메뉴 뒤로가기: 배경 탭으로 닫기
- [x] 5파울 선수 FOUL 버튼 시각적 비활성화 명시

---

## 8. 자체 검증 (DoD)

- [x] FR-012 순서 준수: 파울(12시) → OR → DR → AST → BLK → STL → TO 시계방향
- [x] 파울 서브메뉴 6개 타입 모두 정의 (flagrant2 포함)
- [x] 터치 타겟 44px 이상 (52px)
- [x] 애니메이션 200ms 이내 명세
- [x] 모든 상태(정상/로딩 해당없음/빈 해당없음/에러/비활성화) 정의
- [x] Kai가 이 문서만으로 구현 가능한 수준의 각도/크기/색상 명세 완료
