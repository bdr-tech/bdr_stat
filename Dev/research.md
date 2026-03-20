# BDR Tournament Recorder — Research 문서

> 작성일: 2026-03-06
> 범위: 현재 코드베이스 전체 분석 (v1.1 QA 통과 이후)
> Flutter + Riverpod + Drift + GoRouter + Dio

---

## 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [기술 스택](#2-기술-스택)
3. [아키텍처 구조](#3-아키텍처-구조)
4. [구현 완료 기능](#4-구현-완료-기능)
5. [현재 미구현 / 갭 분석](#5-현재-미구현--갭-분석)
6. [API 연동 현황](#6-api-연동-현황)
7. [알려진 기술 부채](#7-알려진-기술-부채)

---

## 1. 프로젝트 개요

### 1.1 목적
농구 대회 기록원(Recorder)이 태블릿으로 실시간 경기 기록을 하는 앱.
오프라인 우선 아키텍처 — 경기 중 네트워크 단절 시에도 로컬 큐에 저장 후 동기화.

### 1.2 원칙 (CLAUDE.md)
- **오프라인 우선**: 모든 기록은 로컬 DB에 먼저 저장
- **입력 속도 최우선**: 단순 슛 기록 2초 이내 목표
- **데이터 무결성**: UUID 기반 멱등성, 절대 중복 기록 없음
- **MyBDR 100% 호환**: mybdr Next.js API와 완전 호환

### 1.3 버전 이력
- v1.0: 기본 기록 기능 릴리스 (402개 테스트 통과)
- v1.1: UX 개선 (햅틱, 스와이프, 다크모드, 등번호 검색) — QA PASS (382개)
- v1.2 (현재): 기록원 전용 플로우 (recorder 역할 기반 로그인 후 배정 경기 기록)

---

## 2. 기술 스택

### 의존성 (pubspec.yaml 기준)

| 패키지 | 버전 | 용도 |
|--------|------|------|
| flutter_riverpod | ^2.5.1 | 상태 관리 |
| drift | ^2.20.0 | 로컬 SQLite ORM |
| dio | ^5.6.0 | HTTP 클라이언트 |
| go_router | ^14.2.7 | 라우팅 |
| flutter_secure_storage | ^9.2.2 | JWT 토큰 저장 |
| mobile_scanner | ^5.2.1 | QR 스캔 |
| shared_preferences | - | EventQueue 영속화 |
| freezed_annotation | ^2.4.4 | 불변 모델 |

---

## 3. 아키텍처 구조

### 3.1 디렉토리 레이아웃

```
lib/
├── core/
│   ├── services/
│   │   ├── event_queue.dart         ← 오프라인 이벤트 큐 (SharedPrefs)
│   │   ├── sync_manager.dart        ← 온라인 복귀 시 배치 동기화
│   │   ├── haptic_service.dart      ← 햅틱 피드백 래퍼
│   │   ├── auto_save_manager.dart   ← 자동저장
│   │   ├── live_scoreboard_service.dart
│   │   ├── advanced_stats_calculator.dart
│   │   ├── llm_summary_service.dart ← AI 경기 요약 (미완성)
│   │   └── ...
│   ├── theme/app_theme.dart
│   └── utils/
│       ├── sync_manager.dart
│       └── score_utils.dart
├── data/
│   ├── database/
│   │   ├── database.dart            ← Drift DB 정의
│   │   ├── tables.dart              ← 테이블 스키마
│   │   └── daos/                   ← DAO 레이어
│   └── api/
│       └── api_client.dart         ← Dio HTTP 클라이언트
├── domain/
│   ├── models/auth_models.dart
│   └── usecases/                   ← 파울/블록/스틸 UseCase
├── di/
│   ├── providers.dart              ← Riverpod Provider 등록
│   └── usecase_providers.dart
└── presentation/
    ├── router/app_router.dart      ← GoRouter 정의
    ├── providers/
    │   ├── undo_stack_provider.dart
    │   └── network_status_provider.dart
    └── screens/
        ├── auth/login_screen.dart
        ├── tournament/             ← 대회 연결/확인/목록
        ├── match/                  ← 경기 목록/스타터 선택
        ├── recording/              ← 기존 기록 화면 (full 3-panel)
        ├── recorder/               ← 기록원 전용 화면 (v1.2 신규)
        ├── box_score/
        ├── shot_chart/
        ├── game_end/               ← 최종검토/MVP/동기화결과
        ├── analysis/
        └── settings/
```

### 3.2 두 가지 기록 플로우

| 구분 | 경로 | 대상 | 특징 |
|------|------|------|------|
| **기존 플로우** | `/matches → /starter/:id → /recording/:id` | 대회 관리자 | Drift DB + 3-panel 레이아웃, 풀 기능 |
| **기록원 플로우** | `/recorder/matches → /recorder/matches/:id/record` | 배정된 기록원 | mybdr API 직접, 경량 UI, 온라인 우선 |

### 3.3 오프라인 이벤트 큐 (EventQueue)

```dart
// core/services/event_queue.dart
class PendingEvent {
  String clientEventId;  // UUID (멱등성 키)
  int matchId;
  Map<String, dynamic> data;
  DateTime createdAt;
}
```

동작 흐름:
1. 이벤트 발생 → `enqueue()` → SharedPreferences 영속화
2. 온라인 복귀 → `dequeueAll()` → `batchFlushEvents` API
3. 오프라인 Undo → `removeByClientEventId()` (v1.2에서 추가)

---

## 4. 구현 완료 기능

### 4.1 기존 기록 플로우 (recording/)

- **스타터 선택** (`starter_select_screen.dart`): 홈/어웨이 5명 선발
- **경기 기록** (`game_recording_screen.dart`): 3-panel (홈팀 | 코트 | 어웨이팀)
  - 선수 탭 → `player_action_menu.dart` (에어커맨드 스타일)
  - 슛 차트 코트 입력 (`court_with_players.dart`)
  - 라이브 게임 로그 (`live_game_log.dart`)
- **Play-by-Play 수정** (`play_by_play_edit_screen.dart`)
- **박스스코어** (`box_score_screen.dart`)
- **슛차트** (`shot_chart_screen.dart`)
- **경기 종료 플로우**: 최종검토 → MVP 선정 → 동기화 결과

### 4.2 대회/경기 관리

- 대회 연결 (토큰 / QR 방식)
- 대회 확인 및 로컬 데이터 다운로드
- 경기 목록 (`match_list_screen.dart`)

### 4.3 기록원 전용 (recorder/ — v1.2)

- **RecorderMatchesScreen**: 배정된 경기 목록 (API 조회)
  - 상태 뱃지 (예정/진행중/완료/취소)
  - Pull-to-refresh
  - 진행중 경기 강조 (초록 border)
- **MatchRecordingScreen**: 실시간 기록
  - 쿼터 선택 (Q1~Q4, OT1~OT2)
  - 게임 클록 (MM:SS, 시작/정지)
  - 팀 구분 BottomSheet (2-step: 팀 → 선수)
  - 낙관적 점수 업데이트
  - 오프라인 Undo (pending) / API Undo (confirmed)
  - 이벤트 로그 (teamSide 뱃지, 쿼터 표시)

### 4.4 v1.1 UX 기능

- 햅틱 피드백 (모든 주요 액션)
- 스와이프 제스처 (뒤로가기)
- 다크모드
- 등번호 빠른 검색

### 4.5 서비스 레이어 (코드 존재, 연동 미완)

| 서비스 | 상태 |
|--------|------|
| `live_scoreboard_service.dart` | 코드 있음, 화면 연동 미완 |
| `advanced_stats_calculator.dart` | 코드 있음, UI 미완 |
| `llm_summary_service.dart` | 스텁 수준 |
| `game_highlight_service.dart` | 스텁 수준 |
| `multi_device_sync_service.dart` | 코드 있음, 미검증 |
| `voice_command_service.dart` | 스텁 수준 |

---

## 5. 현재 미구현 / 갭 분석

### 5.1 기록원 플로우 (recorder/)

| 항목 | 상태 | 근거 |
|------|------|------|
| 선수 목록 API 로드 | ❌ 미구현 | `MatchRecordingScreen`에서 homePlayers/awayPlayers 하드코딩 없이 빈 상태 |
| 샷 클락 (24/14초) | ❌ 미구현 | 요구사항엔 있으나 현재 없음 |
| 팀 파울 카운터 | ❌ 미구현 | 이벤트 기록만 있고 집계 UI 없음 |
| 선수 교체 이벤트 | ❌ 미구현 | 교체(SUB) 이벤트 타입 없음 |
| 타임아웃 기록 | ❌ 미구현 | 이벤트 타입 없음 |
| 배치 플러시 연동 | ⚠️ 부분 | `dequeueAll()` 있으나 자동 재시도 없음 |
| 경기 시작/종료 API | ❌ 미구현 | status 변경 API 호출 없음 |

### 5.2 기존 플로우 vs 기록원 플로우 통합

- 두 플로우가 완전히 분리됨 (각자 별도 Provider, 별도 UI)
- 기존 플로우: Drift DB 기반, 풍부한 기능
- 기록원 플로우: API 기반, 경량
- **미결 질문**: 기록원 플로우에서도 Drift DB를 캐시로 사용할지?

### 5.3 원본 요구사항 대비 미구현

원본 `bdr_tournament_recorder_prompt.md` 기준:

| 기능 | 상태 |
|------|------|
| 3-Panel 레이아웃 (기존 플로우) | ✅ 구현 |
| 에어커맨드 (펜 호버 메뉴) | ✅ 구현 (player_action_menu) |
| 25-zone 슛차트 | ✅ 구현 |
| 쿼터타이머 (공식 경기시간) | ❌ 미구현 (기록원 플로우) |
| 샷 클락 (24/14초) | ❌ 미구현 |
| 다중 기기 동기화 | ⚠️ 서비스 있으나 미검증 |
| 실시간 스코어보드 공유 URL | ❌ 미구현 |
| AI 경기 하이라이트 요약 | ❌ 스텁 수준 |

---

## 6. API 연동 현황

### 6.1 mybdr API 엔드포인트 (api_client.dart 기준 추정)

| 엔드포인트 | 메서드 | 용도 | 상태 |
|-----------|--------|------|------|
| `/api/v1/tournaments/verify` | GET | 대회 코드 검증 | ✅ |
| `/api/v1/matches` | GET | 경기 목록 | ✅ |
| `/api/v1/matches/:id/events` | POST | 이벤트 기록 | ✅ |
| `/api/v1/matches/:id/events/batch` | POST | 배치 동기화 | ✅ |
| `/api/v1/matches/:id/events/:eid/undo` | PATCH | 이벤트 Undo | ✅ |
| `/api/v1/recorder/matches` | GET | 기록원 배정 경기 | ✅ |
| `/api/v1/matches/:id/players` | GET | 경기 선수 목록 | ❓ 구현 여부 미확인 |
| `/api/v1/matches/:id/status` | PATCH | 경기 상태 변경 | ❓ |

### 6.2 인증

- JWT 토큰 → `flutter_secure_storage`에 저장
- `recorder` 역할 필수: mybdr API `requireRecorder` 미들웨어
- 토큰 만료 자동 갱신: 현재 구현 여부 불명확

---

## 7. 알려진 기술 부채

| 항목 | 심각도 | 설명 |
|------|--------|------|
| 선수 목록 로드 미구현 | 높음 | 기록원 플로우에서 선수 귀속 불가 |
| Provider family key 통일성 | 낮음 | `_MatchRecordingArgs` vs `int matchId` 혼재 |
| 에러 핸들링 표준화 | 중간 | 화면마다 에러 처리 방식 다름 |
| 오프라인 큐 자동 재시도 | 중간 | 수동 플러시만 있음 |
| JWT 갱신 로직 | 높음 | 토큰 만료 시 UX 미정 |
| 기존/기록원 플로우 통합 | 낮음 | 코드 중복 있음 |
