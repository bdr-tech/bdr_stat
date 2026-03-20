import 'package:drift/drift.dart';

// ═══════════════════════════════════════════════════════════════
// 캐싱용 테이블 (서버에서 다운로드)
// ═══════════════════════════════════════════════════════════════

/// 대회 정보 (캐싱)
class LocalTournaments extends Table {
  TextColumn get id => text()(); // UUID (서버와 동일!)
  TextColumn get name => text()();
  TextColumn get apiToken => text()(); // 인증용
  TextColumn get status => text()(); // draft, registration, ongoing, completed
  TextColumn get gameRulesJson => text()(); // JSONB → JSON String
  TextColumn get venueName => text().nullable()();
  TextColumn get venueAddress => text().nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 대회 등록 팀 (캐싱)
class LocalTournamentTeams extends Table {
  IntColumn get id => integer()(); // 서버 ID (bigint)
  TextColumn get tournamentId => text()(); // UUID → LocalTournaments.id
  IntColumn get teamId => integer()(); // 서버 teams.id
  TextColumn get teamName => text()(); // 조인 데이터 캐싱
  TextColumn get teamLogoUrl => text().nullable()();
  TextColumn get primaryColor => text().nullable()();
  TextColumn get secondaryColor => text().nullable()();
  TextColumn get groupName => text().nullable()();
  IntColumn get seedNumber => integer().nullable()();
  IntColumn get wins => integer().withDefault(const Constant(0))();
  IntColumn get losses => integer().withDefault(const Constant(0))();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 대회 등록 선수 (캐싱)
class LocalTournamentPlayers extends Table {
  IntColumn get id => integer()(); // 서버 tournament_team_players.id
  IntColumn get tournamentTeamId => integer()(); // → LocalTournamentTeams.id
  IntColumn get userId => integer().nullable()(); // 서버 users.id (게스트 선수는 null)
  TextColumn get userName => text()(); // 캐싱
  TextColumn get userNickname => text().nullable()();
  TextColumn get profileImageUrl => text().nullable()();
  IntColumn get jerseyNumber => integer().nullable()();
  TextColumn get position => text().nullable()(); // PG, SG, SF, PF, C
  TextColumn get role => text()(); // player, captain, coach
  BoolColumn get isStarter => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  // BDR DNA 코드 (유저 연결용)
  TextColumn get bdrDnaCode => text().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════
// 기록용 테이블 (로컬 생성 → 서버 동기화)
// ═══════════════════════════════════════════════════════════════

/// 경기 정보 (로컬 생성 + 동기화)
@TableIndex(name: 'idx_match_tournament', columns: {#tournamentId})
@TableIndex(name: 'idx_match_status', columns: {#status})
@TableIndex(name: 'idx_match_sync', columns: {#isSynced})
class LocalMatches extends Table {
  IntColumn get id => integer().autoIncrement()(); // 로컬 자동 증가
  IntColumn get serverId => integer().nullable()(); // 서버 tournament_matches.id (동기화 후)
  TextColumn get serverUuid => text().nullable()(); // 서버 uuid
  TextColumn get localUuid => text()(); // 로컬 UUID (동기화 중복 방지)
  TextColumn get tournamentId => text()(); // UUID → LocalTournaments.id
  IntColumn get homeTeamId => integer()(); // → LocalTournamentTeams.id
  IntColumn get awayTeamId => integer()();
  TextColumn get homeTeamName => text()();
  TextColumn get awayTeamName => text()();
  IntColumn get homeScore => integer().withDefault(const Constant(0))();
  IntColumn get awayScore => integer().withDefault(const Constant(0))();

  // 쿼터별 점수 (서버 quarter_scores와 동일 구조)
  // {"home":{"q1":25,"q2":22,...},"away":{...}}
  TextColumn get quarterScoresJson => text().withDefault(const Constant('{}'))();

  // 경기 진행 상태
  IntColumn get currentQuarter => integer().withDefault(const Constant(1))();
  IntColumn get gameClockSeconds => integer().withDefault(const Constant(600))(); // 10분 = 600초
  IntColumn get shotClockSeconds => integer().withDefault(const Constant(24))();
  TextColumn get status => text().withDefault(const Constant('scheduled'))(); // scheduled, warmup, live, halftime, finished

  // 팀 파울 (쿼터별)
  TextColumn get teamFoulsJson => text().withDefault(const Constant('{}'))(); // {"home":{"q1":3,"q2":2,...},"away":{...}}

  // 타임아웃
  IntColumn get homeTimeoutsRemaining => integer().withDefault(const Constant(4))();
  IntColumn get awayTimeoutsRemaining => integer().withDefault(const Constant(4))();

  // 라운드 정보
  TextColumn get roundName => text().nullable()();
  IntColumn get roundNumber => integer().nullable()();
  TextColumn get groupName => text().nullable()();

  // MVP
  IntColumn get mvpPlayerId => integer().nullable()();

  // 시간 기록
  DateTimeColumn get scheduledAt => dateTime().nullable()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();

  // 동기화 상태
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get syncError => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// 경기별 선수 스탯 (→ 서버 match_player_stats 와 1:1 매핑)
@TableIndex(name: 'idx_player_stats_match', columns: {#localMatchId})
@TableIndex(name: 'idx_player_stats_player', columns: {#tournamentTeamPlayerId})
@TableIndex(
  name: 'idx_player_stats_match_team',
  columns: {#localMatchId, #tournamentTeamId},
)
class LocalPlayerStats extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get localMatchId => integer()(); // → LocalMatches.id
  IntColumn get tournamentTeamPlayerId => integer()(); // 서버 ID
  IntColumn get tournamentTeamId => integer()();

  BoolColumn get isStarter => boolean().withDefault(const Constant(false))();
  BoolColumn get isOnCourt => boolean().withDefault(const Constant(false))(); // 현재 코트에 있는지 (로컬 전용)
  IntColumn get minutesPlayed => integer().withDefault(const Constant(0))();

  // 출전 시간 추적용
  DateTimeColumn get lastEnteredAt => dateTime().nullable()(); // 마지막 코트 진입 시간

  // 득점 (서버 match_player_stats 스키마와 동일!)
  IntColumn get points => integer().withDefault(const Constant(0))();
  IntColumn get fieldGoalsMade => integer().withDefault(const Constant(0))();
  IntColumn get fieldGoalsAttempted => integer().withDefault(const Constant(0))();
  IntColumn get twoPointersMade => integer().withDefault(const Constant(0))();
  IntColumn get twoPointersAttempted => integer().withDefault(const Constant(0))();
  IntColumn get threePointersMade => integer().withDefault(const Constant(0))();
  IntColumn get threePointersAttempted => integer().withDefault(const Constant(0))();
  IntColumn get freeThrowsMade => integer().withDefault(const Constant(0))();
  IntColumn get freeThrowsAttempted => integer().withDefault(const Constant(0))();

  // 리바운드
  IntColumn get offensiveRebounds => integer().withDefault(const Constant(0))();
  IntColumn get defensiveRebounds => integer().withDefault(const Constant(0))();
  IntColumn get totalRebounds => integer().withDefault(const Constant(0))();

  // 기타
  IntColumn get assists => integer().withDefault(const Constant(0))();
  IntColumn get steals => integer().withDefault(const Constant(0))();
  IntColumn get blocks => integer().withDefault(const Constant(0))();
  IntColumn get turnovers => integer().withDefault(const Constant(0))();
  IntColumn get personalFouls => integer().withDefault(const Constant(0))();
  IntColumn get technicalFouls => integer().withDefault(const Constant(0))();
  IntColumn get unsportsmanlikeFouls => integer().withDefault(const Constant(0))();
  IntColumn get plusMinus => integer().withDefault(const Constant(0))();

  // 상태
  BoolColumn get fouledOut => boolean().withDefault(const Constant(false))();
  BoolColumn get ejected => boolean().withDefault(const Constant(false))();

  // 수동 수정 플래그
  BoolColumn get isManuallyEdited => boolean().withDefault(const Constant(false))();

  DateTimeColumn get updatedAt => dateTime()();
}

/// Play-by-Play (슛차트 핵심! → 서버 play_by_plays 신규 테이블)
@TableIndex(name: 'idx_pbp_match', columns: {#localMatchId})
@TableIndex(name: 'idx_pbp_quarter', columns: {#localMatchId, #quarter})
@TableIndex(
  name: 'idx_pbp_timeline',
  columns: {#localMatchId, #quarter, #gameClockSeconds},
)
@TableIndex(name: 'idx_pbp_player', columns: {#tournamentTeamPlayerId})
@TableIndex(name: 'idx_pbp_action', columns: {#localMatchId, #actionType})
@TableIndex(name: 'idx_pbp_sync', columns: {#isSynced})
class LocalPlayByPlays extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get localId => text()(); // UUID for sync deduplication
  IntColumn get localMatchId => integer()(); // → LocalMatches.id
  IntColumn get tournamentTeamPlayerId => integer()();
  IntColumn get tournamentTeamId => integer()();

  // 시간
  IntColumn get quarter => integer()();
  IntColumn get gameClockSeconds => integer()();
  IntColumn get shotClockSeconds => integer().nullable()();

  // 액션
  // shot, rebound, assist, steal, block, turnover, foul, substitution, timeout, quarter_start, quarter_end
  TextColumn get actionType => text()();
  // 2pt, 3pt, ft, offensive, defensive, personal, technical, flagrant...
  TextColumn get actionSubtype => text().nullable()();
  BoolColumn get isMade => boolean().nullable()();
  IntColumn get pointsScored => integer().withDefault(const Constant(0))();

  // 슛차트 위치 (핵심!)
  RealColumn get courtX => real().nullable()(); // 0-100
  RealColumn get courtY => real().nullable()(); // 0-100
  IntColumn get courtZone => integer().nullable()(); // 1-25 (NBA zone)
  RealColumn get shotDistance => real().nullable()(); // 림까지 거리 (feet)

  // 관련 선수
  IntColumn get assistPlayerId => integer().nullable()();
  IntColumn get reboundPlayerId => integer().nullable()(); // 리바운드 선수
  IntColumn get blockPlayerId => integer().nullable()();
  IntColumn get stealPlayerId => integer().nullable()();
  IntColumn get fouledPlayerId => integer().nullable()(); // 파울 당한 선수

  // 교체
  IntColumn get subInPlayerId => integer().nullable()();
  IntColumn get subOutPlayerId => integer().nullable()();

  // 파울 상세
  BoolColumn get isFlagrant => boolean().withDefault(const Constant(false))();
  BoolColumn get isTechnical => boolean().withDefault(const Constant(false))();

  // 태깅
  BoolColumn get isFastbreak => boolean().withDefault(const Constant(false))();
  BoolColumn get isSecondChance => boolean().withDefault(const Constant(false))();
  BoolColumn get isFromTurnover => boolean().withDefault(const Constant(false))();

  // 경기 상황 스냅샷
  IntColumn get homeScoreAtTime => integer()();
  IntColumn get awayScoreAtTime => integer()();

  // 설명 (자동 생성)
  TextColumn get description => text().nullable()();

  // 연결된 액션 (액션 연동 자동화용)
  // 예: 스틸→턴오버, 블락→슛실패 연결
  TextColumn get linkedActionId => text().nullable()();

  // 동기화
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
}

/// 최근 연결 대회 (캐시)
class RecentTournaments extends Table {
  TextColumn get tournamentId => text()();
  TextColumn get tournamentName => text()();
  TextColumn get apiToken => text()();
  DateTimeColumn get connectedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {tournamentId};
}

/// 수정 이력 (감사 로그)
///
/// Play-by-Play 기록의 수정/삭제 이력을 저장합니다.
@TableIndex(name: 'idx_edit_log_match', columns: {#localMatchId})
@TableIndex(name: 'idx_edit_log_time', columns: {#editedAt})
class LocalEditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get localMatchId => integer()(); // → LocalMatches.id

  // 수정 대상
  TextColumn get targetType => text()(); // play_by_play, player_stats
  IntColumn get targetId => integer()(); // 대상 레코드 ID
  TextColumn get targetLocalId => text().nullable()(); // play의 localId

  // 수정 내용
  TextColumn get editType => text()(); // create, update, delete
  TextColumn get fieldName => text().nullable()(); // 변경된 필드명
  TextColumn get oldValue => text().nullable()(); // 이전 값 (JSON)
  TextColumn get newValue => text().nullable()(); // 새 값 (JSON)

  // 메타데이터
  TextColumn get description => text().nullable()(); // 변경 설명
  IntColumn get editorPlayerId => integer().nullable()(); // 수정한 사람 (기록자)

  DateTimeColumn get editedAt => dateTime()();
}
