---
agent: Dylan (01-기획)
status: COMPLETE
version: 1.0
created: 2026-03-09
updated: 2026-03-09
self-review: PASS
next-trigger: Kai (flutter-expert) + Maya (refactoring-specialist) 병렬 시작
blocking-issues: 없음
human-gate: 없음 — 범위는 plan.md 기준으로 확정된 항목만 포함
---

# BDR Tournament Recorder — Final Sprint 계획서

> 작성자: Dylan (01-기획 PM)
> 근거: Dev/research.md, Dev/plan.md, outputs/ 전체, 코드베이스 직접 분석
> 목표: 앱 완성도 100% 달성 후 릴리스 준비 완료

---

## 목차

1. [현재 완성도 평가](#1-현재-완성도-평가)
2. [미완성/버그 있는 기능 목록](#2-미완성버그-있는-기능-목록)
3. [Kai 담당 작업](#3-kai-담당-작업-flutter-전문-영역)
4. [Maya 담당 작업](#4-maya-담당-작업-리팩토링-영역)
5. [병렬/순차 실행 계획](#5-병렬순차-실행-계획)
6. [마무리 기준 (Definition of Done)](#6-마무리-기준-definition-of-done)
7. [리스크 레지스터](#7-리스크-레지스터)

---

## 1. 현재 완성도 평가

### 1.1 버전 이력 요약

| 버전 | 상태 | 테스트 |
|------|------|--------|
| v1.0 | 기본 기록 기능 릴리스 | 375개 통과 |
| v1.1 | UX 개선 (햅틱/스와이프/다크모드/등번호검색) | 382개 통과, QA PASS |
| v1.2 (현재) | 기록원 전용 플로우 — plan.md 항목 모두 구현 완료 상태 | 미검증 |

### 1.2 기능별 완성도

| 기능 영역 | 완성도 | 근거 |
|-----------|--------|------|
| 기존 기록 플로우 (3-Panel) | 95% | plan.md 구현 완료 확인, UseCase 연동 완료, QA PASS |
| 대회 연결/다운로드 | 90% | 코드 존재 확인, Supabase + API 이중화 |
| 기록원 플로우 (recorder/) | 70% | plan.md Phase A+B+C 앱측 완료라 기재되어 있으나 미검증 |
| 오프라인 큐/동기화 | 85% | EventQueue 완성, 자동 재시도 구현 완료 |
| 박스스코어/슛차트 | 90% | 화면 존재, 연동 검증 필요 |
| 실시간 스코어보드 공유 (앱측) | 80% | URL 공유 UI 구현, mybdr측 SSE 미구현 |
| AI 경기 요약 | 5% | llm_summary_service.dart 스텁 수준, 보류 결정 |
| 테스트 커버리지 | 75% | 유닛/DB 테스트 충분, 기록원 플로우 E2E 없음 |

### 1.3 전체 완성도: 약 78%

미완성 22%의 구성:
- 기록원 플로우 미검증 버그 가능성 (약 10%)
- 서비스 레이어 연동 미완 (약 7%)
- 테스트 커버리지 부족 (약 5%)

---

## 2. 미완성/버그 있는 기능 목록

### 2.1 HIGH — 기록원 플로우 검증 필요 항목

plan.md 기준 구현 완료라고 기재되어 있으나, 실제 기기 동작 검증이 없는 항목:

| 항목 | 위치 | 우려 사항 |
|------|------|-----------|
| 선수 명단 로드 | match_recording_screen.dart:226 | Supabase/API 이중화 분기 동작 미검증 |
| 샷클락 게이트 (canRecord) | _RecordingState.canRecord | 샷클락 미시작 시 모든 버튼 비활성 — UX 혼란 가능 |
| 오프라인 큐 자동 재시도 (지수 백오프) | notifier 내부 | 백오프 로직 실제 동작 미검증 |
| 선수 교체 3단계 Sheet | _SubstitutionSheet | 복잡한 상태 전환, 엣지케이스 미검증 |
| 쿼터 변경 시 파울 카운터 리셋 | _resetQuarterStats | 쿼터 변경 트리거 시점 불명확 |
| Supabase Realtime 로스터 구독 | _rosterChannel | 연결 해제/재연결 처리 미검증 |

### 2.2 MEDIUM — 서비스 레이어 연동 미완

| 서비스 | 파일 | 상태 | 비고 |
|--------|------|------|------|
| live_scoreboard_service.dart | core/services/ | 코드 있음, 화면 연동 없음 | Phase 2 후보 |
| advanced_stats_calculator.dart | core/services/ | 코드 있음, UI 없음 | Phase 2 후보 |
| multi_device_sync_service.dart | core/services/ | 코드 있음, 검증 없음 | Phase 2 후보 |
| llm_summary_service.dart | core/services/ | 스텁 수준 | 보류 결정됨 |
| voice_command_service.dart | core/services/ | 스텁 수준 | Phase 2 후보 |
| game_highlight_service.dart | core/services/ | 스텁 수준 | Phase 2 후보 |

### 2.3 LOW — 알려진 코드 품질 이슈

| 항목 | 심각도 | 설명 |
|------|--------|------|
| match_recording_screen.dart 3826줄 | 낮음 | 단일 파일 과대, 분리 필요 |
| Provider family key 혼재 | 낮음 | _MatchRecordingArgs vs int 혼재 |
| 에러 핸들링 비표준화 | 낮음 | 화면마다 처리 방식 다름 |
| core/utils/sync_manager.dart 중복 | 낮음 | core/services/와 동일 파일 2개 존재 |
| flutter analyze 경고 12개 | 낮음 | v1.1 QA에서 확인, 정보 수준 |

---

## 3. Kai 담당 작업 (Flutter 전문 영역)

### 우선순위: HIGH

#### KAI-001: 기록원 플로우 통합 검증 및 버그 수정

**목표**: match_recording_screen.dart 실제 동작 검증, 발견된 버그 수정

**입력 조건**:
- lib/presentation/screens/recorder/match_recording_screen.dart (3826줄)
- plan.md §1~§2 구현 완료 명세

**세부 작업**:

| 태스크 | 완료 기준 | 예상 소요 |
|--------|-----------|-----------|
| KAI-001a: canRecord 게이트 UX 검증 | 샷클락 정지 시 경고 배너 + 버튼 비활성 정상 동작 | 0.5일 |
| KAI-001b: 선수 명단 로드 Supabase/API 분기 검증 | tournamentId 유무에 따른 두 경로 모두 동작 | 0.5일 |
| KAI-001c: 선수 교체 Sheet 엣지케이스 처리 | 스타터 0명 / 벤치 0명 시 빈 상태 처리 | 0.5일 |
| KAI-001d: 쿼터 변경 파울 리셋 검증 | Q1→Q2 전환 시 팀 파울 0으로 초기화 확인 | 0.5일 |
| KAI-001e: Supabase Realtime 연결 해제 처리 | dispose 시 채널 해제, 재진입 시 재구독 | 0.5일 |

**담당**: Kai
**병렬 가능**: Maya와 독립 병렬 실행 가능

---

#### KAI-002: 오프라인 큐 자동 재시도 검증

**목표**: 지수 백오프 로직 실제 동작 확인, 실패 시 재큐잉 정확성 보장

**입력 조건**:
- lib/core/services/event_queue.dart
- match_recording_screen.dart 내 flushQueue() 로직

**세부 작업**:

| 태스크 | 완료 기준 | 예상 소요 |
|--------|-----------|-----------|
| KAI-002a: 오프라인 → 온라인 복귀 시 자동 플러시 동작 확인 | _wasOffline 패턴 정상 동작 | 0.5일 |
| KAI-002b: 부분 실패 시 재큐잉 정확성 | 실패한 이벤트만 다시 큐에 적재 | 0.5일 |
| KAI-002c: 동기화 배너 (_SyncingBanner) 표시/숨김 | 진행 중 스피너, 완료 시 자동 숨김 | 0.5일 |

**담당**: Kai
**병렬 가능**: KAI-001과 순차 (같은 화면 파일)

---

#### KAI-003: 기록원 플로우 E2E 시나리오 테스트 작성

**목표**: 기록원 플로우 핵심 경로 자동화 테스트

**입력 조건**: 기존 test/ 디렉토리 구조, flutter_test 패턴

**세부 작업**:

| 태스크 | 완료 기준 | 예상 소요 |
|--------|-----------|-----------|
| KAI-003a: 경기 시작 → 이벤트 기록 → 종료 플로우 통합 테스트 | 핵심 경로 1회 통과 | 1일 |
| KAI-003b: 오프라인 이벤트 큐 단위 테스트 | enqueue/dequeue/removeById 3개 테스트 | 0.5일 |
| KAI-003c: 샷클락 상태 기반 기록 허용/차단 단위 테스트 | canRecord 게이트 4개 시나리오 | 0.5일 |

**담당**: Kai
**병렬 가능**: KAI-001 완료 후 시작

---

### 우선순위: MEDIUM

#### KAI-004: 기존 기록 플로우 (recording/) 안정성 검증

**목표**: v1.2에서 변경된 코드가 기존 플로우에 영향 없는지 회귀 검증

**세부 작업**:

| 태스크 | 완료 기준 | 예상 소요 |
|--------|-----------|-----------|
| KAI-004a: 기존 스타터 선택 → 기록 → 종료 플로우 정상 동작 | 수동 검증 완료 | 0.5일 |
| KAI-004b: UseCase 연동 (스틸→턴오버, 블락→슛실패) 실제 동작 | 연동 자동화 정상 작동 | 0.5일 |

**담당**: Kai
**병렬 가능**: KAI-001~003과 병렬 가능

---

#### KAI-005: 앱 안정성 모니터링 도구 검증

**목표**: CrashReporter, PerformanceMonitor, BatteryMonitor 실제 동작 확인

**세부 작업**:

| 태스크 | 완료 기준 | 예상 소요 |
|--------|-----------|-----------|
| KAI-005a: crash_reporter.dart 초기화 및 로그 수집 확인 | 앱 크래시 시 로컬 로그 저장 | 0.5일 |
| KAI-005b: performance_monitor.dart 활성화 상태 확인 | 성능 지표 수집 여부 확인 | 0.5일 |

**담당**: Kai
**병렬 가능**: 독립 실행 가능

---

## 4. Maya 담당 작업 (리팩토링 영역)

### 우선순위: HIGH

#### MAYA-001: match_recording_screen.dart 분리

**목표**: 3826줄 단일 파일을 책임 기반으로 분리

**입력 조건**:
- lib/presentation/screens/recorder/match_recording_screen.dart 전체
- 기존 recording/ 위젯 분리 패턴 참조

**세부 작업**:

| 태스크 | 완료 기준 | 예상 소요 |
|--------|-----------|-----------|
| MAYA-001a: State + Notifier 클래스를 별도 파일로 분리 | recorder_state.dart, recorder_notifier.dart 생성 | 0.5일 |
| MAYA-001b: 위젯 클래스 분리 (_ScoreBoard, _ShotClock, _TeamPicker 등) | widgets/ 서브디렉토리로 이동 | 1일 |
| MAYA-001c: 분리 후 전체 테스트 통과 확인 | flutter test 전체 통과, analyze 경고 증가 없음 | 0.5일 |

**담당**: Maya
**병렬 가능**: Kai와 독립 병렬 실행 가능
**주의**: Kai의 KAI-001 작업과 충돌 방지 필요. Maya는 구조 분리만, 로직 변경은 Kai 담당.

---

#### MAYA-002: 중복 파일 제거

**목표**: core/utils/sync_manager.dart 와 core/services/ 중복 정리

**세부 작업**:

| 태스크 | 완료 기준 | 예상 소요 |
|--------|-----------|-----------|
| MAYA-002a: core/utils/sync_manager.dart 참조 추적 | 모든 import 위치 파악 | 0.5일 |
| MAYA-002b: core/services/로 통일, 중복 파일 삭제 | 단일 진실 소스(single source of truth) 유지 | 0.5일 |
| MAYA-002c: flutter analyze 경고 12개 해소 | 0개 또는 정보 수준만 남기기 | 0.5일 |

**담당**: Maya
**병렬 가능**: MAYA-001과 병렬 가능

---

### 우선순위: MEDIUM

#### MAYA-003: 에러 핸들링 표준화

**목표**: 화면마다 다른 에러 처리 방식을 공통 패턴으로 통일

**입력 조건**:
- 현재 에러 처리 패턴 분석 (DioException, String? errorMessage 혼재)
- AppConstants 패턴 참조

**세부 작업**:

| 태스크 | 완료 기준 | 예상 소요 |
|--------|-----------|-----------|
| MAYA-003a: 공통 AppError 모델 정의 | AppError(type, message, recoverable) | 0.5일 |
| MAYA-003b: api_client.dart 에러 반환 표준화 | ApiResponse<T, AppError>로 타입화 | 1일 |
| MAYA-003c: 화면별 에러 표시 공통 위젯 적용 | ErrorBanner 위젯 일관 사용 | 0.5일 |

**담당**: Maya
**병렬 가능**: MAYA-001 완료 후 시작 권장 (구조 분리 후 적용이 효율적)

---

#### MAYA-004: 서비스 레이어 스텁 정리

**목표**: 미완성 서비스 파일에 TODO 태그 및 Phase 2 마커 명시

**세부 작업**:

| 태스크 | 완료 기준 | 예상 소요 |
|--------|-----------|-----------|
| MAYA-004a: 스텁 서비스 파일에 // TODO(phase2): 주석 일괄 추가 | llm_summary, voice_command, game_highlight, multi_device_sync | 0.5일 |
| MAYA-004b: live_scoreboard_service, advanced_stats_calculator 사용처 정리 | 연동 없는 import 제거 | 0.5일 |

**담당**: Maya
**병렬 가능**: 독립 실행 가능

---

### 우선순위: LOW

#### MAYA-005: Provider family key 통일

**목표**: _MatchRecordingArgs vs int matchId 혼재 해소

**세부 작업**:

| 태스크 | 완료 기준 | 예상 소요 |
|--------|-----------|-----------|
| MAYA-005a: Provider family 파라미터 타입 일관성 확보 | int matchId 기준으로 통일 | 0.5일 |

**담당**: Maya
**병렬 가능**: 독립 실행 가능, 우선순위 낮으므로 위 작업 완료 후 진행

---

## 5. 병렬/순차 실행 계획

### 5.1 전체 실행 타임라인

```
Day 1-2 (병렬 시작)
├── [Kai]  KAI-001: 기록원 플로우 통합 검증 (2일)
└── [Maya] MAYA-001: match_recording_screen 분리 (2일)
           MAYA-002: 중복 파일 제거 (1일, Day 1 완료 목표)

Day 2-3
├── [Kai]  KAI-002: 오프라인 큐 재시도 검증 (1일, KAI-001 이후)
│          KAI-004: 기존 플로우 회귀 검증 (1일, 병렬)
│          KAI-005: 앱 안정성 도구 검증 (1일, 병렬)
└── [Maya] MAYA-003: 에러 핸들링 표준화 (2일, MAYA-001 이후)
           MAYA-004: 스텁 서비스 정리 (1일, 병렬)

Day 3-4
└── [Kai]  KAI-003: E2E 시나리오 테스트 작성 (2일, KAI-001 이후)

Day 4-5 (순차 — 통합 검증)
└── [Kai + Maya] 통합 테스트 실행, 회귀 확인
                 flutter test 전체 통과 확인
                 flutter analyze 경고 0 목표

Day 5 (Dylan 게이트 리뷰)
└── Definition of Done 체크리스트 점검
    Nora QA 트리거 (v1.2 공식 QA)
```

### 5.2 의존성 맵

```
KAI-001 → KAI-002 (같은 화면 파일, 순차)
KAI-001 → KAI-003 (검증 완료 후 테스트 작성)
MAYA-001 → MAYA-003 (구조 분리 후 에러 표준화)

[독립 병렬 가능]
KAI-001 || MAYA-001
KAI-004 || MAYA-002
KAI-005 || MAYA-004
MAYA-005 (언제든 독립 실행)
```

### 5.3 충돌 방지 규칙

| 규칙 | 내용 |
|------|------|
| 파일 락 | match_recording_screen.dart: Kai 우선, Maya는 구조 분리 시작 전 Kai 완료 대기 |
| 커밋 단위 | 기능 단위로 커밋 (feat/fix/refactor 구분), 같은 날 merge 전 확인 |
| 테스트 게이트 | 각 PR에서 flutter test 전체 통과 필수 |

---

## 6. 마무리 기준 (Definition of Done)

### 6.1 기능 DoD (Kai 담당)

- [ ] 기록원 플로우 핵심 경로 (경기 시작 → 이벤트 기록 → 종료) 정상 동작
- [ ] 샷클락 게이트: 미시작 시 득점/스탯 버튼 비활성, 경고 배너 표시
- [ ] 선수 명단 로드: Supabase 경로 및 API 폴백 모두 동작
- [ ] 선수 교체: 3단계 Sheet 스타터/벤치 경계 케이스 처리
- [ ] 쿼터 변경 시 팀 파울 카운터 0 초기화
- [ ] 오프라인 → 온라인 복귀 시 자동 배치 플러시 동작
- [ ] 기존 기록 플로우 (recording/) 회귀 없음
- [ ] flutter test 전체 통과 (현재 382개 이상)
- [ ] 기록원 플로우 E2E 테스트 최소 1개 통과

### 6.2 코드 품질 DoD (Maya 담당)

- [ ] match_recording_screen.dart 2000줄 이하로 분리 (또는 State/Notifier/Widget 3개 파일로 분리)
- [ ] core/utils/sync_manager.dart 중복 제거 완료
- [ ] flutter analyze 경고: 정보(info) 수준만 허용, warning 0개
- [ ] 스텁 서비스 파일에 // TODO(phase2): 주석 명시
- [ ] 에러 핸들링 공통 패턴 적용 (최소 recorder/ 화면)

### 6.3 릴리스 DoD (Dylan 게이트)

- [ ] Kai DoD 전항목 PASS
- [ ] Maya DoD 전항목 PASS
- [ ] flutter test: 400개 이상 통과 (기존 382 + 신규 E2E 최소 18개)
- [ ] flutter build apk --release 빌드 오류 없음
- [ ] 알려진 Critical/Major 버그 0개
- [ ] plan.md 보류 항목 (AI 요약, §4) Phase 2로 명시적 이관
- [ ] Nora QA v1.2 공식 사인오프

---

## 7. 리스크 레지스터

| ID | 리스크 | 발생확률 | 영향도 | 대응 전략 |
|----|--------|----------|--------|-----------|
| R-001 | match_recording_screen 분리 중 동작 오류 | 중 | 높음 | 분리 전 Kai가 기능 검증 완료, Maya는 이후 구조만 이동 |
| R-002 | Supabase Realtime 구독 메모리 누수 | 중 | 중 | dispose() 내 unsubscribe 명시적 확인, 검증 테스트 추가 |
| R-003 | 오프라인 큐 재시도 중 중복 이벤트 전송 | 낮음 | 높음 | clientEventId UUID 기반 멱등성 보장 (이미 설계됨), 서버 측 검증 |
| R-004 | 샷클락 게이트로 인한 입력 속도 저하 | 중 | 중 | 경고 UX 개선, 샷클락 시작 버튼 눈에 잘 보이게 배치 |
| R-005 | mybdr API 미구현 항목 (live 스코어보드 SSE) 의존성 | 낮음 | 낮음 | 앱측 URL 공유만 완료, SSE는 별도 mybdr 작업으로 분리 완료 |
| R-006 | 총 작업 기간 5일 초과 | 낮음 | 중 | DoD 항목 우선순위 재조정, LOW 항목 Phase 2 이관 허용 |

---

## 부록: Phase 2 이관 목록

> 이번 Final Sprint 범위 밖. 릴리스 후 다음 스프린트에서 검토.

| 항목 | 근거 |
|------|------|
| AI 경기 요약 (llm_summary_service) | plan.md §4 보류 결정, 앱/서버 연동 필요 |
| 실시간 스코어보드 SSE (mybdr측) | mybdr 별도 작업, 앱측 URL 공유만 완료 |
| 다중 기기 동기화 (multi_device_sync_service) | 검증 미완, 안정성 불확실 |
| 고급 스탯 UI (advanced_stats_calculator) | 코드 있음, UI 연동 없음 |
| 음성 커맨드 (voice_command_service) | 스텁 수준, 요구사항 미확정 |
| 라이브 리더보드 (live_scoreboard_service) | 코드 있음, 화면 연동 없음 |

---

*Dylan (01-기획 PM) — BDR AI Development Team*
*Gate 2 보고: 범위 확정 완료, 사장 확인 불필요 (plan.md 기준 기확정 항목만 포함)*
*다음 단계: Kai + Maya 병렬 실행 시작*
