// TODO(phase2): This service is not yet integrated.
// Planned for Phase 2 release. Do not call from production code.
// No screen or widget subscribes to liveScoreboardProvider or scoreboardEventStreamProvider.
// mybdr SSE endpoint not yet implemented on server side.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../presentation/widgets/timer/game_timer_widget.dart';
import 'game_share_service.dart';

/// 실시간 스코어보드 이벤트 타입
enum ScoreboardEventType {
  scoreUpdate,     // 점수 변경
  quarterChange,   // 쿼터 변경
  clockSync,       // 시계 동기화
  timeout,         // 타임아웃
  possession,      // 공격권 변경
  foul,            // 파울
  substitution,    // 선수 교체
  gameStatus,      // 경기 상태 변경
}

/// 스코어보드 이벤트
class ScoreboardEvent {
  final ScoreboardEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  ScoreboardEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'ts': timestamp.millisecondsSinceEpoch,
        'data': data,
      };

  factory ScoreboardEvent.fromJson(Map<String, dynamic> json) {
    return ScoreboardEvent(
      type: ScoreboardEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ScoreboardEventType.scoreUpdate,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
      data: json['data'] as Map<String, dynamic>,
    );
  }

  String toBase64() => base64Encode(utf8.encode(jsonEncode(toJson())));

  static ScoreboardEvent fromBase64(String encoded) {
    final json = jsonDecode(utf8.decode(base64Decode(encoded)));
    return ScoreboardEvent.fromJson(json as Map<String, dynamic>);
  }
}

/// 실시간 스코어보드 상태
class LiveScoreboardState {
  // 경기 정보
  final int matchId;
  final String localUuid;
  final String status;

  // 팀 정보
  final String homeTeamName;
  final String awayTeamName;
  final int homeScore;
  final int awayScore;

  // 게임 클럭
  final int quarter;
  final int gameClockSeconds;
  final int shotClockSeconds;
  final bool isClockRunning;

  // 공격권
  final String possession; // 'home' | 'away' | 'jumpBall'

  // 파울 상태
  final int homeTeamFouls;
  final int awayTeamFouls;
  final bool homeInBonus;
  final bool awayInBonus;

  // 타임아웃 정보
  final int homeTimeoutsRemaining;
  final int awayTimeoutsRemaining;

  // 쿼터별 점수
  final Map<int, int> homeQuarterScores;
  final Map<int, int> awayQuarterScores;

  // 최종 업데이트 시간
  final DateTime lastUpdated;

  // 버전 (동기화용)
  final int version;

  const LiveScoreboardState({
    required this.matchId,
    required this.localUuid,
    required this.status,
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeScore = 0,
    this.awayScore = 0,
    this.quarter = 1,
    this.gameClockSeconds = 600,
    this.shotClockSeconds = 24,
    this.isClockRunning = false,
    this.possession = 'home',
    this.homeTeamFouls = 0,
    this.awayTeamFouls = 0,
    this.homeInBonus = false,
    this.awayInBonus = false,
    this.homeTimeoutsRemaining = 5,
    this.awayTimeoutsRemaining = 5,
    this.homeQuarterScores = const {},
    this.awayQuarterScores = const {},
    required this.lastUpdated,
    this.version = 0,
  });

  LiveScoreboardState copyWith({
    int? matchId,
    String? localUuid,
    String? status,
    String? homeTeamName,
    String? awayTeamName,
    int? homeScore,
    int? awayScore,
    int? quarter,
    int? gameClockSeconds,
    int? shotClockSeconds,
    bool? isClockRunning,
    String? possession,
    int? homeTeamFouls,
    int? awayTeamFouls,
    bool? homeInBonus,
    bool? awayInBonus,
    int? homeTimeoutsRemaining,
    int? awayTimeoutsRemaining,
    Map<int, int>? homeQuarterScores,
    Map<int, int>? awayQuarterScores,
    DateTime? lastUpdated,
    int? version,
  }) {
    return LiveScoreboardState(
      matchId: matchId ?? this.matchId,
      localUuid: localUuid ?? this.localUuid,
      status: status ?? this.status,
      homeTeamName: homeTeamName ?? this.homeTeamName,
      awayTeamName: awayTeamName ?? this.awayTeamName,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      quarter: quarter ?? this.quarter,
      gameClockSeconds: gameClockSeconds ?? this.gameClockSeconds,
      shotClockSeconds: shotClockSeconds ?? this.shotClockSeconds,
      isClockRunning: isClockRunning ?? this.isClockRunning,
      possession: possession ?? this.possession,
      homeTeamFouls: homeTeamFouls ?? this.homeTeamFouls,
      awayTeamFouls: awayTeamFouls ?? this.awayTeamFouls,
      homeInBonus: homeInBonus ?? this.homeInBonus,
      awayInBonus: awayInBonus ?? this.awayInBonus,
      homeTimeoutsRemaining:
          homeTimeoutsRemaining ?? this.homeTimeoutsRemaining,
      awayTimeoutsRemaining:
          awayTimeoutsRemaining ?? this.awayTimeoutsRemaining,
      homeQuarterScores: homeQuarterScores ?? this.homeQuarterScores,
      awayQuarterScores: awayQuarterScores ?? this.awayQuarterScores,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      version: version ?? this.version,
    );
  }

  /// 시계 표시 형식
  String get formattedGameClock {
    final minutes = gameClockSeconds ~/ 60;
    final seconds = gameClockSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedShotClock => shotClockSeconds.toString().padLeft(2, '0');

  /// 쿼터 표시
  String get quarterLabel {
    if (quarter <= 4) {
      return 'Q$quarter';
    } else {
      final otNumber = quarter - 4;
      return otNumber == 1 ? 'OT' : 'OT$otNumber';
    }
  }

  /// 점수 표시
  String get scoreDisplay => '$homeScore : $awayScore';

  /// 상태 텍스트
  String get statusText {
    switch (status) {
      case 'scheduled':
        return '예정';
      case 'warmup':
        return '워밍업';
      case 'live':
        return isClockRunning ? 'LIVE' : '일시정지';
      case 'halftime':
        return '하프타임';
      case 'finished':
        return '종료';
      default:
        return status;
    }
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'localUuid': localUuid,
        'status': status,
        'homeTeam': homeTeamName,
        'awayTeam': awayTeamName,
        'homeScore': homeScore,
        'awayScore': awayScore,
        'quarter': quarter,
        'gameClock': gameClockSeconds,
        'shotClock': shotClockSeconds,
        'clockRunning': isClockRunning,
        'possession': possession,
        'homeFouls': homeTeamFouls,
        'awayFouls': awayTeamFouls,
        'homeBonus': homeInBonus,
        'awayBonus': awayInBonus,
        'homeTimeouts': homeTimeoutsRemaining,
        'awayTimeouts': awayTimeoutsRemaining,
        'homeQtrScores': homeQuarterScores.map(
          (k, v) => MapEntry(k.toString(), v),
        ),
        'awayQtrScores': awayQuarterScores.map(
          (k, v) => MapEntry(k.toString(), v),
        ),
        'lastUpdated': lastUpdated.millisecondsSinceEpoch,
        'version': version,
      };

  /// JSON 역직렬화
  factory LiveScoreboardState.fromJson(Map<String, dynamic> json) {
    return LiveScoreboardState(
      matchId: json['matchId'] as int,
      localUuid: json['localUuid'] as String,
      status: json['status'] as String,
      homeTeamName: json['homeTeam'] as String,
      awayTeamName: json['awayTeam'] as String,
      homeScore: json['homeScore'] as int,
      awayScore: json['awayScore'] as int,
      quarter: json['quarter'] as int,
      gameClockSeconds: json['gameClock'] as int,
      shotClockSeconds: json['shotClock'] as int,
      isClockRunning: json['clockRunning'] as bool,
      possession: json['possession'] as String,
      homeTeamFouls: json['homeFouls'] as int,
      awayTeamFouls: json['awayFouls'] as int,
      homeInBonus: json['homeBonus'] as bool,
      awayInBonus: json['awayBonus'] as bool,
      homeTimeoutsRemaining: json['homeTimeouts'] as int,
      awayTimeoutsRemaining: json['awayTimeouts'] as int,
      homeQuarterScores: (json['homeQtrScores'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(int.parse(k), v as int),
      ),
      awayQuarterScores: (json['awayQtrScores'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(int.parse(k), v as int),
      ),
      lastUpdated:
          DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'] as int),
      version: json['version'] as int,
    );
  }

  /// Base64 인코딩
  String toBase64() => base64Encode(utf8.encode(jsonEncode(toJson())));

  /// Base64 역직렬화
  static LiveScoreboardState fromBase64(String encoded) {
    final json = jsonDecode(utf8.decode(base64Decode(encoded)));
    return LiveScoreboardState.fromJson(json as Map<String, dynamic>);
  }

  /// GameShareData로 변환
  GameShareData toShareData() {
    return GameShareData(
      matchId: matchId,
      localUuid: localUuid,
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      homeScore: homeScore,
      awayScore: awayScore,
      currentQuarter: quarter,
      gameClockSeconds: gameClockSeconds,
      status: status,
    );
  }
}

/// 실시간 스코어보드 Notifier
// TODO(phase2): Notifier is complete but no screen wires up syncWithTimer() or syncWithMatch().
class LiveScoreboardNotifier extends StateNotifier<LiveScoreboardState?> {
  LiveScoreboardNotifier() : super(null);

  final _eventController = StreamController<ScoreboardEvent>.broadcast();

  Stream<ScoreboardEvent> get eventStream => _eventController.stream;

  Timer? _clockSyncTimer;

  /// 경기 초기화
  void initializeMatch({
    required int matchId,
    required String localUuid,
    required String homeTeamName,
    required String awayTeamName,
    String status = 'scheduled',
    int quarterMinutes = 10,
  }) {
    state = LiveScoreboardState(
      matchId: matchId,
      localUuid: localUuid,
      status: status,
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      gameClockSeconds: quarterMinutes * 60,
      lastUpdated: DateTime.now(),
    );

    _emitEvent(ScoreboardEventType.gameStatus, {
      'status': status,
    });
  }

  /// 점수 업데이트
  void updateScore({
    int? homeScore,
    int? awayScore,
    int? pointsScored,
    String? scoringTeam,
  }) {
    if (state == null) return;

    final newHomeScore = homeScore ?? state!.homeScore;
    final newAwayScore = awayScore ?? state!.awayScore;

    state = state!.copyWith(
      homeScore: newHomeScore,
      awayScore: newAwayScore,
      lastUpdated: DateTime.now(),
      version: state!.version + 1,
    );

    _emitEvent(ScoreboardEventType.scoreUpdate, {
      'home': newHomeScore,
      'away': newAwayScore,
      'points': pointsScored,
      'team': scoringTeam,
    });
  }

  /// 쿼터 변경
  void changeQuarter(int quarter, {int? quarterMinutes}) {
    if (state == null) return;

    final clockSeconds = (quarterMinutes ?? 10) * 60;

    state = state!.copyWith(
      quarter: quarter,
      gameClockSeconds: clockSeconds,
      shotClockSeconds: 24,
      homeTeamFouls: 0,
      awayTeamFouls: 0,
      homeInBonus: false,
      awayInBonus: false,
      lastUpdated: DateTime.now(),
      version: state!.version + 1,
    );

    _emitEvent(ScoreboardEventType.quarterChange, {
      'quarter': quarter,
      'gameClock': clockSeconds,
    });
  }

  /// 시계 동기화
  void syncClock({
    required int gameClockSeconds,
    int? shotClockSeconds,
    bool? isRunning,
  }) {
    if (state == null) return;

    state = state!.copyWith(
      gameClockSeconds: gameClockSeconds,
      shotClockSeconds: shotClockSeconds ?? state!.shotClockSeconds,
      isClockRunning: isRunning ?? state!.isClockRunning,
      lastUpdated: DateTime.now(),
      version: state!.version + 1,
    );

    _emitEvent(ScoreboardEventType.clockSync, {
      'gameClock': gameClockSeconds,
      'shotClock': shotClockSeconds ?? state!.shotClockSeconds,
      'running': isRunning ?? state!.isClockRunning,
    });
  }

  /// 공격권 변경
  void changePossession(String possession) {
    if (state == null) return;

    state = state!.copyWith(
      possession: possession,
      shotClockSeconds: 24,
      lastUpdated: DateTime.now(),
      version: state!.version + 1,
    );

    _emitEvent(ScoreboardEventType.possession, {
      'possession': possession,
    });
  }

  /// 파울 기록
  void recordFoul({
    required bool isHome,
    String? foulType,
  }) {
    if (state == null) return;

    final newHomeFouls =
        isHome ? state!.homeTeamFouls + 1 : state!.homeTeamFouls;
    final newAwayFouls =
        isHome ? state!.awayTeamFouls : state!.awayTeamFouls + 1;
    final homeBonus = newHomeFouls >= 5;
    final awayBonus = newAwayFouls >= 5;

    state = state!.copyWith(
      homeTeamFouls: newHomeFouls,
      awayTeamFouls: newAwayFouls,
      homeInBonus: homeBonus,
      awayInBonus: awayBonus,
      lastUpdated: DateTime.now(),
      version: state!.version + 1,
    );

    _emitEvent(ScoreboardEventType.foul, {
      'team': isHome ? 'home' : 'away',
      'fouls': isHome ? newHomeFouls : newAwayFouls,
      'inBonus': isHome ? homeBonus : awayBonus,
      'foulType': foulType,
    });
  }

  /// 타임아웃 사용
  void useTimeout({required bool isHome}) {
    if (state == null) return;

    final remaining = isHome
        ? state!.homeTimeoutsRemaining - 1
        : state!.awayTimeoutsRemaining - 1;

    if (remaining < 0) return;

    state = state!.copyWith(
      homeTimeoutsRemaining:
          isHome ? remaining : state!.homeTimeoutsRemaining,
      awayTimeoutsRemaining:
          isHome ? state!.awayTimeoutsRemaining : remaining,
      isClockRunning: false,
      lastUpdated: DateTime.now(),
      version: state!.version + 1,
    );

    _emitEvent(ScoreboardEventType.timeout, {
      'team': isHome ? 'home' : 'away',
      'remaining': remaining,
    });
  }

  /// 경기 상태 변경
  void setGameStatus(String status) {
    if (state == null) return;

    state = state!.copyWith(
      status: status,
      lastUpdated: DateTime.now(),
      version: state!.version + 1,
    );

    _emitEvent(ScoreboardEventType.gameStatus, {
      'status': status,
    });
  }

  /// 쿼터 점수 업데이트
  void updateQuarterScore(int quarter, {int? homeScore, int? awayScore}) {
    if (state == null) return;

    final newHomeQtr = Map<int, int>.from(state!.homeQuarterScores);
    final newAwayQtr = Map<int, int>.from(state!.awayQuarterScores);

    if (homeScore != null) newHomeQtr[quarter] = homeScore;
    if (awayScore != null) newAwayQtr[quarter] = awayScore;

    state = state!.copyWith(
      homeQuarterScores: newHomeQtr,
      awayQuarterScores: newAwayQtr,
      lastUpdated: DateTime.now(),
      version: state!.version + 1,
    );
  }

  /// 타이머 상태와 동기화
  void syncWithTimer(GameTimerState timerState) {
    if (state == null) return;

    final possessionStr = switch (timerState.possession) {
      Possession.home => 'home',
      Possession.away => 'away',
      Possession.jumpBall => 'jumpBall',
    };

    state = state!.copyWith(
      quarter: timerState.quarter,
      gameClockSeconds: timerState.gameClockSeconds,
      shotClockSeconds: timerState.shotClockSeconds,
      isClockRunning: timerState.isRunning,
      possession: possessionStr,
      lastUpdated: DateTime.now(),
      version: state!.version + 1,
    );
  }

  /// 경기 데이터와 동기화
  void syncWithMatch(LocalMatche match) {
    if (state == null) return;

    state = state!.copyWith(
      status: match.status,
      homeScore: match.homeScore,
      awayScore: match.awayScore,
      lastUpdated: DateTime.now(),
      version: state!.version + 1,
    );
  }

  /// 주기적 클럭 동기화 시작 (1초마다)
  void startClockSync() {
    _clockSyncTimer?.cancel();
    _clockSyncTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state != null && state!.isClockRunning) {
        _emitEvent(ScoreboardEventType.clockSync, {
          'gameClock': state!.gameClockSeconds,
          'shotClock': state!.shotClockSeconds,
          'running': true,
        });
      }
    });
  }

  /// 클럭 동기화 중지
  void stopClockSync() {
    _clockSyncTimer?.cancel();
    _clockSyncTimer = null;
  }

  /// 이벤트 발행
  void _emitEvent(ScoreboardEventType type, Map<String, dynamic> data) {
    _eventController.add(ScoreboardEvent(type: type, data: data));
  }

  @override
  void dispose() {
    _clockSyncTimer?.cancel();
    _eventController.close();
    super.dispose();
  }
}

/// Provider
final liveScoreboardProvider =
    StateNotifierProvider<LiveScoreboardNotifier, LiveScoreboardState?>(
  (ref) => LiveScoreboardNotifier(),
);

/// 스코어보드 이벤트 스트림 Provider
final scoreboardEventStreamProvider = StreamProvider<ScoreboardEvent>((ref) {
  final notifier = ref.watch(liveScoreboardProvider.notifier);
  return notifier.eventStream;
});
