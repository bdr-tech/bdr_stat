# CLAUDE.md - BDR Tournament Recorder

> 이 파일은 Claude Code가 프로젝트 작업 시 참고하는 규칙입니다.

---

## 🚦 모든 작업의 시작점 — 4단계 방어체계

**개발 작업 수신 시 반드시 아래 순서 준수:**

1. **리서치** (`Dev/research.md`) — 현재 코드베이스 현황 파악 → 무지한 변경 방지
2. **계획** (`Dev/plan.md`) — 판단 주석 작성 및 사장 승인 → 잘못된 변경 방지
3. **주석 주입** — plan.md의 `<!-- [승인] -->` / `<!-- [수정: ...] -->` 확인
4. **구현** — 승인된 항목만 방해 없이 실행

### 리서치 / 계획 파일 위치
1. Research.md: `/Users/grizrider/CC/BDR/bdr_stat/Dev/research.md`
2. plan.md: `/Users/grizrider/CC/BDR/bdr_stat/Dev/plan.md`

---

## 🤖 AI 개발팀

이 프로젝트는 Claude Code Sub Agent 기반 AI 개발팀이 운영합니다.
**사장(사람)**이 방향을 제시하고, 각 전문 에이전트가 실행합니다.

### 팀 구성

| 순번 | 이름 | 역할 | 에이전트 파일 |
|------|------|------|--------------|
| 1 | **Dylan** | 기획 PM (15년차) | `~/.claude/agents/01-planner.md` |
| 2 | **Sophia** | 분석가 (12년차) | `~/.claude/agents/02-analyst.md` |
| 3 | **Marcus** | 아키텍트 (18년차) | `~/.claude/agents/03-architect.md` |
| 4 | **Aria** | UI/UX 디자이너 (10년차) | `~/.claude/agents/04-designer.md` |
| 5 | **Ethan** | 풀스택 테크리드 (14년차) | `~/.claude/agents/05-developer.md` |
| 6 | **Nora** | QA 엔지니어 (11년차) | `~/.claude/agents/06-qa.md` |
| 7 | **Felix** | DevOps/문서화 (배포) | `~/.claude/agents/07-deployer.md` |
| 8 | **Victor** | IT 컨설턴트 (20년차) | `~/.claude/agents/08-consultant.md` |

### 워크플로우
```
[사장: 아이디어/방향 제시]
        │
        ▼
┌─── Victor(08-상담) ◄──────────────────┐
│   (아이디어 구체화, 기술 자문)           │
│       │                                │
│       ▼                                │
│   Dylan(01-기획) ─────────────┐        │
│   (프로젝트 헌장, 범위, 계획)   │        │
│       │                      │        │
│       ▼                      │        │
│   Sophia(02-분석)             │        │
│   (AS-IS/TO-BE, 요구사항)     │        │
│       │                      │        │
│       ▼                      │        │
│   Marcus(03-설계) ◄── Aria(04-디자인)  │
│   (아키텍처, DB, API)  (UI/UX) │        │
│       │         │            │        │
│       ▼         ▼            │        │
│   Ethan(05-개발) ◄───────────┘        │
│   (코딩, 단위테스트)                    │
│       │                                │
│       ▼                                │
│   Nora(06-QA) ── (결함) ──► Ethan      │
│   (통합/시스템/성능 테스트)              │
│       │                                │
│       ▼                                │
│   Felix(07-배포/문서화)                 │
│   (CI/CD, 산출물 생성)                  │
│       │                                │
│       ▼                                │
│   [릴리스 완료] ──► 피드백 ─────────────┘
└────────────────────────────────────────┘
```

### 에이전트 운영 규칙
1. **산출물 체인**: 각 에이전트는 이전 단계의 산출물을 반드시 참조
2. **요구사항 추적**: 모든 작업은 요구사항 ID(FR-번호)로 추적
3. **크로스 리뷰**: 각 단계 완료 시 다음 에이전트가 리뷰
4. **사장 의사결정**: 주요 분기점에서 사장(사람) 확인
5. **프로젝트 규칙 준수**: 아래의 모든 프로젝트 규칙은 **모든 에이전트가 반드시 따라야 하는 절대 규칙**

### 산출물 디렉토리
```
outputs/
├── 01-planning/          # Dylan의 기획 산출물
├── 02-analysis/          # Sophia의 분석 산출물
├── 03-design/            # Marcus의 설계 산출물
├── 04-ui-design/         # Aria의 디자인 산출물
├── 05-development/       # Ethan의 개발 산출물
├── 06-qa/                # Nora의 QA 산출물
└── 07-deploy-docs/       # Felix의 배포/문서 산출물
```

---

## 🎯 프로젝트 핵심 원칙

> ⚠️ **모든 에이전트 필독**: 아래 원칙은 이 프로젝트의 절대 규칙입니다.
> Marcus(설계), Ethan(개발), Nora(QA)는 특히 이 섹션을 반드시 숙지해야 합니다.

### 1. 오프라인 우선 (Offline-First)
```
절대 규칙:
- 모든 기능은 네트워크 없이 동작해야 함
- 데이터는 항상 로컬 DB(Drift)에 먼저 저장
- API 호출 실패해도 앱이 멈추면 안 됨
- 네트워크 상태 체크 후 분기하는 코드 금지 (저장은 항상 로컬 먼저)
```

### 2. 입력 속도 최우선
```
목표:
- 슛 기록: 3초 이내
- 모든 액션: "원-투" 2동작으로 완료
- 에어 커맨드(펜 호버)로 메뉴 자동 표시 → 바로 탭

금지:
- 불필요한 확인 다이얼로그 (경기 종료 등 중요 액션 제외)
- 3단계 이상의 nested modal
- 로딩 중 입력 차단
```

### 3. 데이터 무결성
```
필수:
- 모든 DB 작업은 트랜잭션으로 감싸기
- PlayByPlay 저장 실패 시 롤백
- local_id(UUID)로 중복 방지
```

---

## 🏗 기술 스택

> Sophia(분석), Marcus(설계), Aria(디자인) 에이전트는 이 기술 스택 내에서 설계해야 합니다.
> Ethan(개발)은 이 스택으로 구현합니다.

| 레이어 | 기술 |
|--------|------|
| **모바일 앱** | Flutter + Dart |
| **상태 관리** | Riverpod |
| **로컬 DB** | Drift (SQLite) |
| **백엔드** | Ruby on Rails (기존 bdr_platform) |
| **DB** | PostgreSQL |
| **라우팅** | GoRouter |
| **동기화** | 로컬 → 서버 단방향 + 양방향 (토너먼트/팀 데이터) |

---

## 📁 프로젝트 구조 규칙

### 디렉토리 구조
```
lib/
├── core/          # 상수, 테마, 유틸리티
├── data/          # DB, Repository, API
├── domain/        # 모델, UseCase, 비즈니스 규칙
├── presentation/  # Provider, Screen, Widget
└── di/            # Dependency Injection (Riverpod)
```

### 파일 네이밍
```
screens:    *_screen.dart       (예: game_recording_screen.dart)
widgets:    *_widget.dart 또는 그냥 *.dart
providers:  *_provider.dart
models:     *.dart              (예: player.dart)
daos:       *_dao.dart
usecases:   *_usecase.dart
```

---

## 🛠 코드 컨벤션

> Ethan(개발)의 기본 코딩 표준입니다. Nora(QA)는 이 컨벤션 준수 여부를 검증합니다.

### Dart/Flutter
```dart
// ✅ 좋은 예
class PlayerCard extends ConsumerWidget {
  const PlayerCard({super.key, required this.player});
  
  final Player player;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ...
  }
}

// ❌ 나쁜 예 - StatelessWidget 대신 ConsumerWidget 사용
class PlayerCard extends StatelessWidget { ... }
```

### 상태 관리 (Riverpod)
```dart
// ✅ 화면/위젯 상태: StateNotifierProvider 또는 NotifierProvider
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>(...);

// ✅ 단순 읽기: Provider
final currentPlayerProvider = Provider<Player?>(...);

// ✅ 비동기 데이터: FutureProvider / StreamProvider
final tournamentProvider = FutureProvider<Tournament>(...);

// ❌ 금지: setState(), 전역 변수
```

### Drift (SQLite)
```dart
// ✅ 모든 DB 작업은 DAO를 통해
class PlayByPlayDao extends DatabaseAccessor<AppDatabase> {
  Future<void> insertPlay(PlayByPlayCompanion play) async {
    await into(playByPlays).insert(play);
  }
}

// ❌ 금지: 직접 SQL 문자열 작성 (Drift 쿼리 빌더 사용)
```

---

## 🎮 기능별 구현 규칙

> Aria(디자인)는 이 인터랙션 패턴을 반영하여 화면을 설계해야 합니다.
> Ethan(개발)은 이 플로우대로 구현합니다.
> Nora(QA)는 이 플로우를 기준으로 테스트 케이스를 설계합니다.

### 에어 커맨드 (핵심!)
```dart
// 펜 호버 감지
Listener(
  onPointerHover: (event) {
    if (event.kind == PointerDeviceKind.stylus) {
      _showQuickMenu(event.position);
    }
  },
  onPointerExit: (_) => _scheduleMenuClose(delay: 300.ms),
  child: PlayerCard(...),
)

// 비-펜 대응: 탭으로도 메뉴 열림
GestureDetector(
  onTap: () => _showQuickMenu(cardPosition),
  child: ...,
)
```

### 슛 기록 플로우
```
1. 선수 호버/탭 → 방사형 메뉴
2. 슛 종류 탭 → 코트 터치 대기
3. 코트 터치 → 성공/실패 선택
4. 성공 시 → 어시스트 선택 (선택사항)
5. 실패 시 → 리바운드 선택 (선택사항)

* 각 단계에서 [없음/건너뛰기] 항상 제공
```

### 액션 연동 자동화
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

### 팀 파울 / 보너스
```dart
// 쿼터별 관리
class TeamFoulManager {
  static const BONUS_THRESHOLD = 5;
  
  void addFoul(int quarter, int teamId) { ... }
  bool isInBonus(int quarter, int teamId) { ... }
  void resetForQuarter(int quarter) { ... }  // 새 쿼터 시작 시 호출
}
```

---

## 🚫 절대 금지 사항

> ⚠️ **모든 에이전트 필독**: 설계, 개발, QA 모두 이 금지사항을 위반하면 안 됩니다.

### 코드 금지
```dart
// ❌ 네트워크 체크 후 분기해서 저장 결정
if (await hasNetwork()) {
  await api.save(data);
} else {
  await localDb.save(data);
}

// ✅ 항상 로컬 먼저, 나중에 동기화
await localDb.save(data);
if (await hasNetwork()) {
  await syncToServer();
}
```

```dart
// ❌ 하드코딩된 타이머 값
Timer(Duration(seconds: 10), callback);

// ✅ game_rules에서 가져오기
final quarterMinutes = tournament.gameRules.quarterMinutes;
```

```dart
// ❌ 직접 Navigator 사용 (일관성)
Navigator.push(context, MaterialPageRoute(...));

// ✅ GoRouter 또는 일관된 라우팅 방식
context.push('/game-recording');
```

### 아키텍처 금지
```
❌ Widget에서 직접 DB 접근
❌ Provider 밖에서 비즈니스 로직
❌ API 응답을 Widget에서 직접 처리
❌ 전역 상태 (Riverpod Provider 외)
```

---

## ✅ 테스트 규칙

> Nora(QA)의 기본 테스트 프레임워크입니다. Ethan(개발)도 단위 테스트 작성 시 따릅니다.

### 필수 테스트
```dart
// 1. 오프라인 동작 테스트
test('should save play without network', () async {
  // 네트워크 없이 저장 가능해야 함
});

// 2. 액션 연동 테스트
test('steal should auto-record turnover', () async {
  await recordSteal(player1, player2);
  expect(player2.turnovers, 1);
});

// 3. 점수 계산 테스트
test('points should equal 2P*2 + 3P*3 + FT*1', () async {
  // ...
});
```

### 테스트 실행
```bash
# 유닛 테스트
flutter test

# 특정 파일
flutter test test/domain/usecases/record_shot_test.dart

# 커버리지
flutter test --coverage
```

---

## 📝 커밋 규칙

### 커밋 메시지 형식
```
<type>(<scope>): <description>

예시:
feat(recording): add air command for player cards
fix(sync): handle 401 token expiration
refactor(database): migrate to Drift 2.x
test(usecase): add steal-turnover linkage test
```

### Type
- `feat`: 새 기능
- `fix`: 버그 수정
- `refactor`: 리팩토링
- `test`: 테스트
- `docs`: 문서
- `style`: 포맷팅
- `chore`: 빌드, 설정

---

## 🔗 관련 문서

- **메인 프롬프트**: `bdr_tournament_recorder_prompt.md`
- **기존 Rails 스키마**: `schema.rb` (bdr_platform)
- **API 명세**: 프롬프트 내 "동기화 로직" 섹션
- **AI 개발팀 가이드**: `QUICKSTART.md`
- **에이전트 프롬프트**: `agents/*.md`

---

## 💡 개발 팁

### 1. Drift 마이그레이션
```dart
// 스키마 변경 시
@DriftDatabase(tables: [...])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 2;  // 버전 증가
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(playByPlays, playByPlays.courtZone);
      }
    },
  );
}
```

### 2. 디버깅
```dart
// 로컬 DB 내용 확인
final db = ref.read(databaseProvider);
final plays = await db.select(db.playByPlays).get();
debugPrint('Plays: ${plays.length}');
```

### 3. 성능
```dart
// 대량 INSERT는 batch로
await database.batch((batch) {
  for (final play in plays) {
    batch.insert(playByPlays, play);
  }
});
```

---

## 🎯 현재 Phase 체크

개발 시작 전 현재 Phase 확인:
- [ ] Phase 0: Rails 백엔드 준비 완료?
- [ ] Phase 1: Flutter 프로젝트 설정
- [ ] Phase 2: 온보딩 + 경기 선택
- [ ] Phase 3: 메인 기록 화면
- [ ] ...

**현재 Phase**: _____ (여기에 기록)

---

## 📞 질문 시 포함할 정보

Claude에게 질문할 때 다음 정보 포함:
1. 현재 작업 중인 파일/기능
2. 에러 메시지 (있다면)
3. 기대 동작 vs 실제 동작
4. 관련 코드 스니펫