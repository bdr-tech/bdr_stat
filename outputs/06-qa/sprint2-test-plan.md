# BDR Sprint 2 — 테스트 계획서 + 테스트 케이스

> **작성자**: Nora (QA 엔지니어, 11년차)
> **작성일**: 2026-03-16
> **버전**: 1.0
> **대상**: bdr_stat Sprint 2 (FR-001 ~ FR-013)

---

## 1. 테스트 범위

### In-Scope
| 마일스톤 | 기능 | FR |
|---|---|---|
| M1 클락 정밀화 | 샷클락 5초 미만 1/10초, 게임클락 1분 이내 1/10초, 리셋 후 정지, +/- 조정 | FR-004~007 |
| M2 에어커맨드 UX | 원형 메뉴 7버튼, 파울 서브메뉴 6종, 5파울 비활성화 | FR-012 |
| M3 박스스코어 | 쿼터별 집계, FG%/3P%/FT%, +/- 코트마진 | FR-001~003 |
| M4 작전타임 | 타임아웃 버튼·차감·비활성화, 팀파울 표시, game_rules 연동 | FR-008~010 |
| M5 UI 정리 | 로그 영역 50% 축소(최대 4줄), 스낵바 2초 자동 소멸 | FR-011, FR-013 |
| 동기화 | bdr_stat → mybdr quarterStats, plusMinus, game_rules | M3·M4 연동 |
| 회귀 | 득점/리바운드/어시스트 기존 기록 정상 동작 | 전체 |

### Out-of-Scope
- mybdr 웹 프론트엔드 직접 테스트 (별도 QA 범위)
- 작전타임 60초 카운트다운 UI (Phase 2 후보)
- 성능 부하 테스트 (k6 별도)

---

## 2. 합격 기준 (Exit Criteria) [자율설정]

| 기준 | 목표 | 미충족 시 |
|---|---|---|
| Critical 버그 | 0건 | No-Go |
| Major 버그 | 0건 | No-Go |
| TC 통과율 | 48개 중 46개 이상 (95.8%) | No-Go |
| 회귀 TC | 기존 기능 100% 통과 | No-Go |
| Minor/Trivial | 기록 후 차기 스프린트 허용 | Go 가능 |

---

## 3. 테스트 케이스 (TC-001 ~ TC-048)

---

### [M1 클락 정밀화] FR-004: 샷클락 리셋 후 정지

**TC-013: 샷클락 24초 리셋 후 정지 확인**
- 관련 요구사항: FR-004
- 유형: 정상
- 사전조건: 게임 진행 중 (isRunning = true), 샷클락 15초
- 테스트 단계:
  1. [24초] 리셋 버튼 탭
- 입력값: resetShotClock(seconds: 24, pauseShotClock: true)
- 기대결과: shotClockTenths = 240, isShotClockPaused = true, gameClockTenths 계속 감소
- 우선순위: Critical

**TC-014: 게임클락 독립 실행 확인 (리셋 후)**
- 관련 요구사항: FR-004
- 유형: 정상
- 사전조건: TC-013 실행 후 상태 (샷클락 24초 정지, 게임클락 running)
- 테스트 단계:
  1. 1초 대기
  2. gameClockTenths 값 확인
  3. shotClockTenths 값 확인
- 입력값: 1초 경과
- 기대결과: gameClockTenths = (이전값 - 10), shotClockTenths = 240 (변화 없음)
- 우선순위: Critical

**TC-015: 샷클락 수동 시작 버튼**
- 관련 요구사항: FR-004
- 유형: 정상
- 사전조건: isShotClockPaused = true, isRunning = true
- 테스트 단계:
  1. "샷클락 시작" 버튼 탭 (startShotClock())
  2. 0.5초 대기
- 입력값: startShotClock()
- 기대결과: isShotClockPaused = false, shotClockTenths 감소 시작
- 우선순위: High

---

### [M1] FR-005: +/- 조정 버튼

**TC-016: 샷클락 +1초 조정 (정지 상태)**
- 관련 요구사항: FR-005
- 유형: 정상
- 사전조건: isRunning = false, shotClockTenths = 180 (18초)
- 테스트 단계:
  1. 샷클락 [+] 버튼 탭 (adjustShotClock(10))
- 기대결과: shotClockTenths = 190 (19초)
- 우선순위: High

**TC-017: 게임클락 -1초 조정 (정지 상태)**
- 관련 요구사항: FR-005
- 유형: 정상
- 사전조건: isRunning = false, gameClockTenths = 3000 (5분)
- 테스트 단계:
  1. 게임클락 [-] 버튼 탭 (adjustGameClock(-1))
- 기대결과: gameClockTenths = 2990 (4분 59초)
- 우선순위: High

**TC-018: 실행 중 +/- 조정 차단 (gate)**
- 관련 요구사항: FR-005
- 유형: 네거티브
- 사전조건: isRunning = true, shotClockTenths = 180
- 테스트 단계:
  1. 샷클락 [+] 버튼 탭 시도
- 기대결과: adjustShotClock()이 호출되어도 상태 변화 없음 (isRunning 체크로 무시)
- 우선순위: High
- **코드 검증**: game_timer_widget.dart:334 `if (state.isRunning) return;` - 확인됨

---

### [M1] FR-006: 샷클락 1/10초 표시

**TC-019: 5초 이상 정수 표시**
- 관련 요구사항: FR-006
- 유형: 정상
- 사전조건: shotClockTenths = 180 (18초), threshold = 5초
- 기대결과: formattedShotClock = "18" (패딩 포함)
- 우선순위: High

**TC-020: 5초 미만 소수점 표시**
- 관련 요구사항: FR-006
- 유형: 정상
- 사전조건: shotClockTenths = 47 (4.7초)
- 기대결과: formattedShotClock = "4.7"
- 우선순위: Critical

**TC-021: threshold 경계값 (5.0초 = 50 tenths)**
- 관련 요구사항: FR-006
- 유형: 경계값
- 사전조건: shotClockTenths = 50 (정확히 5.0초)
- 기대결과: formattedShotClock = "05" (정수, threshold 이상이므로)
- 우선순위: Critical
- **버그 가능성**: shotClockTenths < thresholdTenths (50 < 50 = false) → "05" 반환 맞음

---

### [M1] FR-007: 게임클락 1/10초 표시

**TC-022: 1분 이상 MM:SS 포맷**
- 관련 요구사항: FR-007
- 유형: 정상
- 사전조건: gameClockTenths = 3000 (5분)
- 기대결과: formattedGameClock = "05:00"
- 우선순위: High

**TC-023: 1분 미만 소수점 포맷**
- 관련 요구사항: FR-007
- 유형: 정상
- 사전조건: gameClockTenths = 453 (45.3초)
- 기대결과: formattedGameClock = "0:45.3"
- 우선순위: Critical

**TC-024: 1분 경계값 (600 tenths)**
- 관련 요구사항: FR-007
- 유형: 경계값
- 사전조건: gameClockTenths = 600 (정확히 60초)
- 기대결과: formattedGameClock = "01:00" (MM:SS 포맷, 600 < 600 = false)
- 우선순위: Critical
- **코드 검증**: game_timer_widget.dart:97 `if (gameClockTenths < 600)` — 600은 정수 포맷 → "01:00" 맞음

---

### [M2 에어커맨드] FR-012

**TC-038: 선수 탭 → 에어커맨드 메뉴 표시**
- 관련 요구사항: FR-012
- 유형: 정상
- 사전조건: 게임 레코딩 화면, 코트에 선수 표시
- 테스트 단계:
  1. 선수 아이콘 탭 (GestureDetector.onTapDown)
- 기대결과: 200ms 이내 원형 메뉴 Overlay 표시, 7개 버튼 보임
- 우선순위: High

**TC-039: 에어커맨드 버튼 배치 (12시부터 시계방향)**
- 관련 요구사항: FR-012
- 유형: 정상
- 사전조건: 에어커맨드 메뉴 표시 상태
- 기대결과:
  - index 0 (FOUL) = 상단 12시 방향 (angle = -π/2)
  - index 1 (OREB) = 약 1~2시
  - index 6 (TO) = 약 10~11시
- 우선순위: High
- **코드 검증**: radial_action_menu.dart:577 `startAngle = -math.pi/2` — 맞음

**TC-040: 파울 버튼 탭 → 서브메뉴 전환**
- 관련 요구사항: FR-012
- 유형: 정상
- 사전조건: 에어커맨드 메뉴 표시
- 테스트 단계:
  1. [FOUL] 버튼 탭
- 기대결과: 기존 메뉴 숨겨지고 6개 파울 서브메뉴 표시 (50ms 딜레이 후)
- 우선순위: High

**TC-041: 파울 서브메뉴 6종 확인**
- 관련 요구사항: FR-012
- 유형: 정상
- 기대결과: TECH(12시), OFFNS, DEFNS, FLAG1, FLAG2, UNSP 표시
- 우선순위: High
- **코드 검증**: radial_action_menu.dart:450 foulSubtypeActions 리스트 — 6개 확인됨

**TC-042: 5파울 선수 FOUL 버튼 비활성화**
- 관련 요구사항: FR-012
- 유형: 예외
- 사전조건: 선수 personalFouls = 5
- 기대결과:
  - FOUL 버튼 비활성화 (isDisabled = true, opacity 0.4)
  - 버튼 탭해도 서브메뉴 표시 안 됨
  - 다른 버튼(OR, DR 등)은 정상 작동
- 우선순위: Critical
- **코드 검증**: radial_action_menu.dart:554-556 isFouledOut 체크 — 확인됨

**TC-043: 5파울 선수 서브메뉴 자체 표시 차단**
- 관련 요구사항: FR-012
- 유형: 예외
- 사전조건: playerFouls >= foulOutLimit (5)
- 기대결과: _showFoulSubmenu() 내부 `if (isFouledOut) return` 실행 → 서브메뉴 표시 안 됨
- 우선순위: Critical
- **코드 검증**: radial_action_menu.dart:182-183 — 확인됨

**TC-044: 배경 탭 → 메뉴 닫기**
- 관련 요구사항: FR-012
- 유형: 정상
- 사전조건: 에어커맨드 메뉴 표시
- 테스트 단계: 메뉴 외부 배경 탭
- 기대결과: Overlay 제거, isMenuVisible = false
- 우선순위: Medium

**TC-045: 터치 타겟 크기 (44px)**
- 관련 요구사항: FR-012
- 유형: 정상
- 기대결과: buttonRadius = 26 → 버튼 직경 52px (≥44px, Apple HIG 기준 충족)
- 우선순위: Medium
- **코드 검증**: radial_action_menu.dart:26 `buttonRadius = 26` — 직경 52px 확인됨

---

### [M3 박스스코어] FR-001: 쿼터별 기록

**TC-001: Q1 탭 선택 시 Q1 기록만 표시**
- 관련 요구사항: FR-001
- 유형: 정상
- 사전조건: 매치 ID 존재, Q1에 선수 A 2점슛 5개 성공 PlayByPlay 저장
- 테스트 단계:
  1. 박스스코어 화면 진입
  2. "Q1" 탭 탭
- 기대결과:
  - 선수 A의 PTS = 10, FGM = 5, FGA = 5
  - getTeamQuarterStats(quarter: 1) 호출됨
- 우선순위: Critical

**TC-002: 전체 탭 합산 일치**
- 관련 요구사항: FR-001
- 유형: 정상
- 사전조건: Q1 10점, Q2 8점, Q3 6점, Q4 4점 기록
- 테스트 단계:
  1. "전체" 탭 선택
- 기대결과: LocalPlayerStats 기반 합산 — 선수 A PTS = 28
- 우선순위: Critical

**TC-003: 빈 쿼터 탭 (Q3 기록 없음)**
- 관련 요구사항: FR-001
- 유형: 경계값
- 사전조건: Q3 PlayByPlay 없음
- 기대결과: "Q3 기록이 없습니다" 메시지 표시
- 우선순위: Medium

**TC-004: OT 탭 표시**
- 관련 요구사항: FR-001
- 유형: 정상
- 사전조건: 연장전 quarter=5 PlayByPlay 존재
- 기대결과: "OT" 탭에서 해당 기록 표시
- 우선순위: Medium

**TC-005: 쿼터 탭 전환 속도 < 100ms**
- 관련 요구사항: FR-001 비기능
- 유형: 성능
- 기대결과: 탭 전환 후 화면 갱신 100ms 이내 (FutureBuilder 로딩 포함)
- 우선순위: Medium

---

### [M3] FR-002: 슈팅 성공률

**TC-006: FG% 계산 정확도**
- 관련 요구사항: FR-002
- 유형: 정상
- 사전조건: FGM=5, FGA=10
- 기대결과: FG% 표시 = "50.0" (소수점 1자리, FIBA 기준)
- 우선순위: High

**TC-007: FGA=0 시 "-" 표시 (0 나누기 방지)**
- 관련 요구사항: FR-002
- 유형: 경계값
- 사전조건: FGM=0, FGA=0
- 기대결과: FG% 열 = "-"
- 우선순위: Critical
- **코드 검증**: PlayerQuarterStats.fgPercentage → fga == 0이면 null, formatPercentage(null) = "-" — 확인됨

**TC-008: FT% 소수점 반올림**
- 관련 요구사항: FR-002
- 유형: 정상
- 사전조건: FTM=2, FTA=3 (66.666...%)
- 기대결과: FT% = "66.7" (소수점 1자리 반올림)
- 우선순위: Medium
- **코드 검증**: toStringAsFixed(1) 적용됨 — 확인

---

### [M3] FR-003: +/- 코트마진

**TC-009: 득점 시 ON-COURT 선수 +/- 누적**
- 관련 요구사항: FR-003
- 유형: 정상
- 사전조건: 홈팀 선수 A, B, C, D, E가 isOnCourt=true, 어웨이팀 5명 코트
- 테스트 단계:
  1. 홈팀 2점슛 성공 (points=2)
  2. applyPlusMinusForScore(scoringTeamId=home, points=2) 호출
- 기대결과:
  - 홈팀 A~E: plusMinus += 2
  - 어웨이팀 5명: plusMinus -= 2
- 우선순위: Critical

**TC-010: 박스스코어 +/- 표시 포맷**
- 관련 요구사항: FR-003
- 유형: 정상
- 사전조건: 선수 plusMinus = 5
- 기대결과: "+5" (양수 앞에 + 붙임)
- 우선순위: High
- **코드 검증**: box_score_screen.dart:569 `'+${stat.plusMinus}'` — 확인됨

**TC-011: +/- 0 표시**
- 관련 요구사항: FR-003
- 유형: 경계값
- 사전조건: plusMinus = 0
- 기대결과: "0" 표시 (회색 스타일)
- 우선순위: Medium

**TC-012: Undo 시 +/- 역방향 적용**
- 관련 요구사항: FR-003
- 유형: 네거티브
- 사전조건: 득점 기록 후 (선수들 plusMinus += 2)
- 테스트 단계:
  1. 해당 기록 Undo
  2. revertPlusMinusForScore() 호출
- 기대결과: 현재 ON-COURT 선수들 plusMinus가 역방향 적용 (단순화 처리)
- 우선순위: High

---

### [M4] FR-008: 작전타임 버튼

**TC-025: T/O 버튼 탭 → 카운트 차감**
- 관련 요구사항: FR-008
- 유형: 정상
- 사전조건: homeTimeoutsRemaining = 2
- 테스트 단계:
  1. 홈팀 [T/O] 버튼 탭
  2. onTimeoutCalled(true) 콜백 실행
- 기대결과: homeTimeoutsUsed += 1 → homeTimeoutsRemaining = 1, PlayByPlay 기록 생성
- 우선순위: High

**TC-026: 잔여 T/O 표시 업데이트**
- 관련 요구사항: FR-008
- 유형: 정상
- 사전조건: 타임아웃 1회 사용 후
- 기대결과: T/O 인디케이터 바 1개 → 비어있음 표시
- 우선순위: Medium

**TC-027: 잔여 T/O=0 버튼 비활성화**
- 관련 요구사항: FR-008
- 유형: 경계값
- 사전조건: timeoutsRemaining = 0
- 기대결과:
  - 버튼 탭 불가 (GestureDetector.onTap = null)
  - 버튼 텍스트 "T/O 없음" 표시
  - 버튼 색상 회색
- 우선순위: Critical
- **코드 검증**: bench_section.dart:356 `final isActive = timeoutsRemaining > 0 && onTimeoutCalled != null` — 확인됨

**TC-028: T/O PlayByPlay 기록 생성 확인**
- 관련 요구사항: FR-008
- 유형: 정상
- 기대결과: action_type = 'timeout' PlayByPlay 행 생성됨 (DB 확인)
- 우선순위: High

---

### [M4] FR-009: 팀파울 표시

**TC-029: 팀파울 5 이상 시 BONUS 뱃지**
- 관련 요구사항: FR-009
- 유형: 경계값
- 사전조건: teamFouls = 5, foulBonusThreshold = 5
- 기대결과: "BONUS" 뱃지 표시, 컨테이너 amber 테두리
- 우선순위: High
- **코드 검증**: bench_section.dart:146 `bool get _isInBonus => teamFouls >= foulBonusThreshold` — 확인됨

**TC-030: 팀파울 4/5 표시 포맷**
- 관련 요구사항: FR-009
- 유형: 정상
- 사전조건: teamFouls = 3, foulBonusThreshold = 5
- 기대결과: "3/5" 표시 (채워진 점 3개, 빈 점 2개)
- 우선순위: Medium

---

### [M4] FR-010: 대회 타임아웃 설정

**TC-031: game_rules JSON → 타임아웃 설정 파싱**
- 관련 요구사항: FR-010
- 유형: 정상
- 사전조건: tournament.gameRulesJson = `{"timeouts":{"timeouts_first_half":2,"timeouts_second_half":3,"timeouts_overtime":1}}`
- 기대결과: GameRulesModel.timeoutsFirstHalf = 2, timeoutsSecondHalf = 3
- 우선순위: High

**TC-032: game_rules 미설정 → FIBA 기본값 폴백**
- 관련 요구사항: FR-010
- 유형: 경계값
- 사전조건: tournament.gameRulesJson = "" 또는 "{}"
- 기대결과: GameRulesModel.defaults 적용 — timeoutsFirstHalf = 2, timeoutsSecondHalf = 3
- 우선순위: Critical
- **코드 검증**: game_rules_model.dart:125-133 fromJsonString fallback — 확인됨

**TC-033: 전반/후반 타임아웃 분리 관리**
- 관련 요구사항: FR-010
- 유형: 정상
- 사전조건: Q1, Q2(전반) 타임아웃 2회 소진
- 테스트 단계:
  1. Q3(후반) 시작
- 기대결과: 후반 타임아웃 3회로 리셋
- 우선순위: Critical

**TC-034: timeoutsAllowedForHalf 계산 (연장)**
- 관련 요구사항: FR-010
- 유형: 정상
- 사전조건: quarter = 5 (연장)
- 기대결과: timeoutsAllowedForHalf(3) = 1 (FIBA 연장 1회)
- 우선순위: Medium
- **코드 검증**: game_rules_model.dart:149-158 halfFromQuarter(5) = 3, default = 1 — 확인됨

**TC-035: 잘못된 game_rules JSON 파싱 오류 처리**
- 관련 요구사항: FR-010
- 유형: 네거티브
- 사전조건: gameRulesJson = "invalid_json"
- 기대결과: catch 블록에서 GameRulesModel() 반환 (앱 충돌 없음)
- 우선순위: Critical
- **코드 검증**: game_rules_model.dart:131 `catch (_) { return const GameRulesModel(); }` — 확인됨

---

### [M5] FR-011: 로그 영역 축소

**TC-036: 최대 4개 로그 항목 표시**
- 관련 요구사항: FR-011
- 유형: 정상
- 사전조건: undoStack에 10개 액션 존재
- 기대결과: LiveGameLogPanel 로그 영역에 최근 4개만 표시
- 우선순위: High
- **코드 검증**: live_game_log.dart:447 `math.min(actions.length, 4)` — 확인됨

**TC-037: 로그 영역 고정 높이 224px**
- 관련 요구사항: FR-011
- 유형: 경계값
- 기대결과: _buildLogSection SizedBox height = 224px
- 우선순위: Medium
- **코드 검증**: live_game_log.dart:58-62 `SizedBox(height: 224, ...)` — 확인됨

---

### [M5] FR-013: 안내문 자동 소멸

**TC-046: 스낵바 2초 후 자동 소멸**
- 관련 요구사항: FR-013
- 유형: 정상
- 사전조건: 기록 완료 후
- 테스트 단계:
  1. UndoSnackbar.show() 호출
  2. 2초 대기
- 기대결과: 스낵바 자동 소멸
- 우선순위: High
- **코드 검증**: undo_snackbar.dart:15 `Duration duration = const Duration(seconds: 2)` — 확인됨

**TC-047: clearSnackBars() 사전 호출**
- 관련 요구사항: FR-013
- 유형: 정상
- 사전조건: 이전 스낵바가 아직 표시 중
- 테스트 단계:
  1. 새 기록 완료 → UndoSnackbar.show() 호출
- 기대결과: 이전 스낵바 즉시 제거 후 새 스낵바 표시
- 우선순위: High
- **코드 검증**: undo_snackbar.dart:17 `ScaffoldMessenger.of(context).clearSnackBars()` — 확인됨

**TC-048: 스낵바 표시 중 "실행 취소" 가능**
- 관련 요구사항: FR-013
- 유형: 회귀
- 사전조건: 스낵바 표시 중 (2초 이내)
- 테스트 단계:
  1. "실행 취소" 액션 탭
  2. onUndo() 콜백 실행
- 기대결과: 해당 기록 취소, 스낵바 소멸
- 우선순위: High

---

### [동기화] WBS 6.6

**TC-049: game_rules 동기화 포함 여부**
- 유형: 정상
- 사전조건: 대회 game_rules 설정 후 경기 시작
- 기대결과: sync API payload에 match.quarterScoresJson 포함 (현재 구현 확인 필요)
- 우선순위: Medium

**TC-050: plusMinus 동기화 payload 포함**
- 유형: 정상
- 기대결과: _buildSyncData()에서 player_stats[i].plus_minus 포함
- 우선순위: High
- **코드 검증**: sync_manager.dart:890 `'plus_minus': s.plusMinus` — 확인됨

---

### [회귀] WBS 6.7

**TC-R01: 2점슛 기록 정상 동작**
- 유형: 회귀
- 기대결과: FGM+1, FGA+1, points+2, PlayByPlay 생성
- 우선순위: Critical

**TC-R02: 3점슛 기록 정상 동작**
- 유형: 회귀
- 기대결과: 3PM+1, 3PA+1, FGM+1, FGA+1, points+3
- 우선순위: Critical

**TC-R03: 어시스트 자동 연동**
- 유형: 회귀
- 기대결과: 슛 성공 후 어시스트 선택 → AST+1, 별도 PlayByPlay
- 우선순위: High

**TC-R04: 스틸 → 상대 턴오버 자동**
- 유형: 회귀
- 기대결과: STL+1 동시에 상대 TO+1
- 우선순위: High

**TC-R05: 5파울 → fouledOut = true**
- 유형: 회귀
- 기대결과: personalFouls=5 → fouledOut=true, 선수 카드 비활성화
- 우선순위: Critical
