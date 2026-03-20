# BDR Sprint 2 — 테스트 계획서

> **작성자**: Nora (QA 엔지니어, 11년차)
> **작성일**: 2026-03-16
> **버전**: 2.0 (Sprint 2)
> **대상**: bdr_stat Sprint 2 — FR-001 ~ FR-013

---

## 1. 개요

### 1.1 목적
BDR Tournament Recorder 앱의 핵심 기능에 대한 품질 검증을 수행하여, 사용자에게 안정적이고 신뢰할 수 있는 농구 경기 기록 시스템을 제공합니다.

### 1.2 테스트 범위

#### In-Scope
| 영역 | 테스트 항목 |
|------|------------|
| **슛 기록 플로우** | 2점슛/3점슛/자유투 기록, 성공/실패, 어시스트/리바운드 연결 |
| **액션 연동** | 스틸→턴오버, 블락→슛실패, 파울→자유투 시퀀스 |
| **팀 파울/보너스** | 쿼터별 파울 누적, 보너스 상태, 쿼터 전환 시 리셋 |
| **오프라인 동작** | 네트워크 없이 로컬 DB 저장, 동기화 대기 |
| **점수 계산** | 2P×2 + 3P×3 + FT×1 공식 검증 |
| **Undo 기능** | 연결된 액션 함께 취소, 스택 관리 |

#### Out-of-Scope
- Rails 백엔드 API 테스트 (별도 프로젝트)
- UI/UX 디자인 일관성 (수동 검토)
- 성능/부하 테스트 (Phase 2)

### 1.3 테스트 전략

```
                    ┌─────────────────────┐
                    │   E2E Integration   │  ← 10%
                    │   (Game Flow)       │
                    ├─────────────────────┤
                    │  Widget Tests       │  ← 20%
                    │  (UI Components)    │
                    ├─────────────────────┤
                    │   Unit Tests        │  ← 70%
                    │   (Business Logic)  │
                    └─────────────────────┘
```

---

## 2. 테스트 환경

### 2.1 기술 스택
| 항목 | 버전/도구 |
|------|----------|
| Flutter | 3.x |
| Dart | 3.x |
| 테스트 프레임워크 | flutter_test |
| 목킹 | mocktail |
| DB 테스트 | Drift in-memory |
| CI/CD | GitHub Actions |

### 2.2 테스트 데이터
- 인메모리 Drift 데이터베이스 사용
- 각 테스트 케이스에서 독립적인 데이터 생성
- 시드 데이터: 대회, 팀, 선수, 경기 기본 정보

---

## 3. 테스트 유형별 전략

### 3.1 단위 테스트 (Unit Tests)
**목표 커버리지**: 80% 이상

| 레이어 | 테스트 대상 | 우선순위 |
|--------|------------|----------|
| Core Utils | ScoreUtils, TeamFoulUtils, TimeUtils, CourtUtils | Critical |
| Data Layer | DAO 클래스 (PlayByPlayDao, MatchDao, PlayerStatsDao) | Critical |
| Providers | UndoStackProvider, GameStateProvider | High |
| Models | UndoableAction, PlayerWithStats | Medium |

### 3.2 위젯 테스트 (Widget Tests)
**목표 커버리지**: 60% 이상

| 컴포넌트 | 테스트 항목 |
|----------|------------|
| ShotResultDialog | 버튼 렌더링, 콜백 실행 |
| AssistSelectDialog | 선수 목록 표시, 선택 |
| ReboundSelectDialog | 공격/수비 리바운드 구분 |
| TeamFoulBonusWidget | 보너스 상태 표시 |

### 3.3 통합 테스트 (Integration Tests)
**시나리오 기반 테스트**

| 시나리오 | 설명 |
|----------|------|
| 완전한 슛 기록 플로우 | 선수 선택 → 슛 종류 → 결과 → 어시스트/리바운드 |
| 파울 시퀀스 | 파울 기록 → 자유투 시퀀스 완료 |
| 쿼터 전환 | 쿼터 종료 → 파울 리셋 → 다음 쿼터 시작 |
| 오프라인 동기화 | 오프라인 기록 → 온라인 시 동기화 |

---

## 4. 합격 기준 (Exit Criteria)

### 4.1 테스트 통과 기준
| 심각도 | 허용 결함 수 |
|--------|-------------|
| Critical | 0개 |
| Major | 0개 |
| Minor | 3개 이하 |
| Trivial | 무제한 |

### 4.2 커버리지 목표
| 유형 | 목표 |
|------|------|
| Statement Coverage | ≥ 70% |
| Branch Coverage | ≥ 60% |
| Function Coverage | ≥ 80% |

### 4.3 성능 기준
| 항목 | 기준 |
|------|------|
| 단위 테스트 실행 | < 30초 |
| 위젯 테스트 실행 | < 60초 |
| 전체 테스트 스위트 | < 3분 |

---

## 5. 테스트 일정

### Phase 1: 단위 테스트 (현재)
- [x] 기존 테스트 분석 (358개 통과 확인)
- [ ] 액션 연동 테스트 추가
- [ ] 오프라인 동작 테스트 추가
- [ ] 점수 계산 통합 테스트 추가

### Phase 2: 위젯/통합 테스트
- [ ] 슛 기록 플로우 E2E 테스트
- [ ] 파울 시퀀스 테스트
- [ ] 5파울 교체 테스트

---

## 6. 리스크 및 대응

| 리스크 | 영향 | 대응 방안 |
|--------|------|----------|
| 인메모리 DB 한계 | 실제 SQLite 동작과 차이 가능 | 통합 테스트에서 파일 DB 사용 |
| 시간 의존 테스트 | 비결정적 실패 가능 | 시간 목킹 사용 |
| UI 렌더링 테스트 | 플랫폼별 차이 | Golden 테스트 도입 검토 |

---

## 7. 테스트 도구 및 명령

### 실행 명령
```bash
# 전체 테스트
flutter test

# 특정 파일
flutter test test/unit/core/score_utils_test.dart

# 커버리지
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# 특정 그룹
flutter test --name "ActionLinkage"
```

### CI/CD 파이프라인
```yaml
name: Flutter Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
```

---

## 8. 참조 문서

- `CLAUDE.md` - 프로젝트 규칙 및 테스트 규칙
- `outputs/05-development/code-review-report.md` - 개발 리뷰 보고서
- `outputs/06-qa/test-cases.md` - 상세 테스트 케이스

---

*Nora (06-qa) - BDR AI Development Team*
