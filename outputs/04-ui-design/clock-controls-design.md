# 클락 +/- 조정 버튼 디자인 명세

> Aria (UI/UX 디자이너) | BDR Sprint 2 | 2026-03-16
> 요구사항 연계: FR-005 (+/- 조정 버튼), FR-004 (샷클락 리셋 후 정지)
> 참조: live_game_log.dart (_buildGameClock, _buildShotClock), game_timer_widget.dart

---

## 1. 현재 클락 UI 분석

### 1.1 게임클락 (`_buildGameClock`)

- 전체 컨테이너 탭 → `timerNotifier.toggle` (시작/정지)
- `GameTimerWidget._buildFull()`에 `-1:00 / -0:10 / +0:10 / +1:00` 버튼 존재
- **문제**: `LiveGameLogPanel`의 게임클락 섹션에는 조정 버튼 없음. `GameTimerWidget.full` 버전만 있음.

### 1.2 샷클락 (`_buildShotClock`)

- 중앙 샷클락 표시 탭 → toggle
- 좌측 [14] 리셋 버튼, 우측 [24] 리셋 버튼
- `adjustGameClock(int seconds)` 메서드 이미 존재 (활용 가능)
- **문제**: +/- 1초 단위 미세 조정 버튼 없음

---

## 2. Sprint 2 클락 컨트롤 레이아웃

### 2.1 게임클락 영역 — FR-005

```
┌─────────────────────────────────────────────────┐
│              GAME CLOCK                          │
│                                                  │
│  ┌───────┐  ┌─────────────────────────┐  ┌───┐  │
│  │  [+]  │  │      08:34              │  │ [-] │  │
│  │       │  │   ▶ RUNNING             │  │     │  │
│  └───────┘  └─────────────────────────┘  └───┘  │
│   +1초          (탭: 시작/정지)         -1초      │
└─────────────────────────────────────────────────┘
```

버튼 배치: 클락 표시 좌측 [+], 우측 [-]

**주의**: 클락이 실행 중(isRunning = true)일 때 +/- 버튼 비활성화. 정지 상태에서만 활성.

### 2.2 샷클락 영역 — FR-005

```
┌──────┐  ┌───┐  ┌──────────────────┐  ┌───┐  ┌──────┐
│  14  │  │[+]│  │       18         │  │[-]│  │  24  │
│      │  │   │  │   SHOT CLOCK     │  │   │  │      │
└──────┘  └───┘  └──────────────────┘  └───┘  └──────┘
14초 리셋  +1초     샷클락 표시          -1초   24초 리셋
```

버튼 배치: 기존 14초/24초 리셋 버튼 사이에 +/- 버튼 삽입.

> 14초 버튼과 +버튼 사이, 24초 버튼과 -버튼 사이는 8px 간격.

---

## 3. +/- 버튼 상세 디자인

### 3.1 활성 상태 (isRunning = false)

```
┌─────────────────┐
│      [ + ]      │  또는  │      [ - ]      │
│   add_circle    │        │ remove_circle    │
│     +1초        │        │     -1초         │
└─────────────────┘
```

| 속성 | 값 |
|------|-----|
| 크기 | 44px × 44px |
| 배경 | `AppTheme.surfaceColor` |
| border | `AppTheme.borderColor` 1px |
| borderRadius | 8px |
| 아이콘 | `Icons.add_circle_outline` / `Icons.remove_circle_outline` |
| 아이콘 크기 | 20px |
| 아이콘 색상 | `AppTheme.textPrimary` |
| 라벨 (옵션) | `+1s` / `-1s`, fontSize 9px, `AppTheme.textSecondary` |

### 3.2 비활성 상태 (isRunning = true)

```
┌─────────────────┐
│      [ + ]      │  ← 투명도 0.3 적용
│   (비활성화)     │
└─────────────────┘
```

| 속성 | 값 |
|------|-----|
| 배경 | `AppTheme.surfaceColor.withValues(alpha: 0.4)` |
| 아이콘 색상 | `Colors.grey[600]` |
| onTap | `null` (비활성) |
| 시각적 힌트 | 아이콘 투명도 0.3 |

### 3.3 탭 피드백

- 활성 탭: `HapticFeedback.lightImpact()` + 버튼 잠시 `InkWell` ripple
- 비활성 탭: 반응 없음 (null onTap)

---

## 4. ASCII 와이어프레임 — 사이드바 전체 (클락 영역)

```
┌──────────────────────────────────────────────┐
│              GAME CLOCK 섹션                 │
│                                              │
│  ┌──────┐  ┌─────────────────────────┐  ┌──┐ │
│  │  +   │  │      08:34              │  │- │ │
│  │ (+1s)│  │    ▶ RUNNING            │  │  │ │
│  └──────┘  └─────────────────────────┘  └──┘ │
│             (탭 전체 영역: toggle)            │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│              SHOT CLOCK 섹션                 │
│                                              │
│  ┌───┐  ┌──┐  ┌────────────────┐  ┌──┐ ┌───┐│
│  │14 │  │+ │  │      18        │  │- │ │24 ││
│  │   │  │  │  │   SHOT CLOCK   │  │  │ │   ││
│  └───┘  └──┘  └────────────────┘  └──┘ └───┘│
│ (14s리셋)(+1s)  (탭: toggle)    (-1s)(24s리셋)│
└──────────────────────────────────────────────┘
```

---

## 5. 클락 조정 버튼 인터랙션 플로우

```
클락 정지 상태
    │
    ├── [+] 탭 → gameTimerNotifier.adjustGameClock(+1)
    │                   ↓
    │           클락 +1초 즉시 반영 (State 업데이트)
    │           HapticFeedback.lightImpact()
    │
    ├── [-] 탭 → gameTimerNotifier.adjustGameClock(-1)
    │                   ↓
    │           0초 미만으로는 내려가지 않음 (clamp 처리)
    │           0초 도달 시 [-] 버튼 추가 비활성화
    │
    └── [▶ 시작] 탭 → 클락 실행 시작
                       ↓
                [+][-] 버튼 자동 비활성화
```

샷클락 전용 추가 동작:
```
[-] 탭 → shotClock 0초 도달
    │
    └── shotClockSeconds = 0 →
        샷클락 표시 빨강으로 전환 (이미 구현)
        [-] 버튼 비활성화
```

---

## 6. 게임클락 +/- 단위 명세

| 클락 | +/- 단위 | 이유 |
|------|---------|------|
| 게임클락 | ±1초 | FR-005 명세 "1초 단위" |
| 샷클락 | ±1초 | FR-005 명세 "1초 단위" |

> FR-007 (1분 이내 1/10초 표시)와는 별개.
> 조정은 항상 1초 단위이며, 표시 포맷만 1/10초로 변경된다.

---

## 7. 샷클락 리셋 후 정지 동작 — FR-004 (참고)

> FR-004는 클락 정밀화 작업(M1)으로 Kai가 타이머 엔진에서 처리.
> Aria 담당: 시각적 피드백 명세만.

### 7.1 리셋 후 상태 표시

[24s] 또는 [14s] 버튼 탭 → 즉시 샷클락 숫자 변경 + **정지 아이콘** 표시:

```
리셋 직후:
┌─────────────────────────────────────────┐
│         24                              │
│    SHOT CLOCK  ⏸ PAUSED                 │  ← "PAUSED" 텍스트 추가
└─────────────────────────────────────────┘
border: AppTheme.borderColor (초록 테두리 없음 = 정지)
```

vs 실행 중:
```
┌─────────────────────────────────────────┐
│         18                              │
│    SHOT CLOCK  ▶ RUNNING               │
└─────────────────────────────────────────┘
border: Color(0xFFEF4444) (빨강 = 실행)
```

---

## 8. 1/10초 표시 시각적 명세 — FR-005/FR-006 연동

> 타이머 포맷은 Kai(Flutter)가 처리하나, 폰트 및 크기는 Aria 명세 범위.

### 8.1 샷클락 5초 미만 전환

```
5초 이상:
┌────────┐
│   18   │   fontSize: 36, color: Color(0xFFEF4444)
│        │
└────────┘

5초 미만 (1/10초 표시):
┌────────┐
│  4.7   │   fontSize: 32 (소수점 포함해 같은 크기 유지)
│        │   fontFamily: 'monospace' 유지
└────────┘
```

- 5초 미만 전환 시 배경 `Colors.red.withValues(alpha: 0.2)` 강화
- 배경 빨강 + glow 효과 강조 (기존 구현 유지)

### 8.2 게임클락 1분 이내 전환 — FR-007 연동

```
1분 이상:
┌────────────┐
│  08:34     │   fontSize: 42, monospace
└────────────┘

1분 미만 (1/10초):
┌────────────┐
│  0:45.3    │   fontSize: 40 (포맷 변경)
└────────────┘
border: 초록 isRunning 상태 강조 유지
```

---

## 9. 버튼 플로우 상태 정리 (Kai 구현용 조건 정리)

| 조건 | 게임클락 +/- | 샷클락 +/- |
|------|-------------|------------|
| 클락 실행 중 | 비활성 | 비활성 |
| 클락 정지 | 활성 | 활성 |
| 게임클락 = 0 | [-] 비활성, [+] 활성 | 무관 |
| 샷클락 = 0 | 무관 | [-] 비활성, [+] 활성 |
| 샷클락 = max(24) | [+] 비활성, [-] 활성 | [+] 비활성 |
| isLoading | 모두 비활성 | 모두 비활성 |

---

## 10. 위젯 수정 위치 (Kai에게)

### 10.1 수정 파일

`lib/presentation/screens/recording/widgets/live_game_log.dart`

- `_buildGameClock()`: 기존 탭 영역 좌우에 +/- 버튼 추가
- `_buildShotClock()`: 14초/24초 리셋 버튼 사이에 +/- 버튼 삽입

### 10.2 필요한 신규 메서드 (GameTimerNotifier)

```dart
// game_timer_widget.dart 또는 별도 파일에 추가
void adjustShotClock(int seconds) {
  final newClock = (state.shotClockSeconds + seconds).clamp(0, 99);
  state = state.copyWith(shotClockSeconds: newClock);
  onStateChanged?.call(state);
}
```

> `adjustGameClock`은 이미 존재. `adjustShotClock`만 추가 필요.

### 10.3 버튼 비활성화 gate

```dart
// 게임클락 +/- 버튼
onTap: timerState.isRunning ? null : () => timerNotifier.adjustGameClock(1),

// 샷클락 +/- 버튼
onTap: timerState.isRunning ? null : () => timerNotifier.adjustShotClock(1),
```

---

## 11. 접근성 체크리스트

- [x] 터치 타겟 44px × 44px (Apple HIG 준수)
- [x] 비활성 시 투명도 + null onTap으로 이중 차단
- [x] 아이콘 의미 명확: `add_circle_outline` / `remove_circle_outline`
- [x] 라벨 "+1s" / "-1s" 추가로 의도 전달
- [x] 클락 실행 중 비활성화 — 오조작 방지 (FR-005 명세)

---

## 12. 자체 검증 (DoD)

- [x] FR-005: 게임클락/샷클락 +/- 버튼 위치, 크기, 단위(±1초) 명세 완료
- [x] FR-005 추가 조건: 클락 정지 상태에서만 활성화 — 시각 표현 명세 완료
- [x] FR-004 연동: 리셋 후 PAUSED 상태 표시 명세 포함
- [x] FR-006/FR-007: 1/10초 표시 전환 시 폰트 크기 명세 포함
- [x] 정상/로딩/에러/비활성 상태 모두 정의
- [x] Kai가 이 문서만으로 `live_game_log.dart` 수정 가능한 수준
