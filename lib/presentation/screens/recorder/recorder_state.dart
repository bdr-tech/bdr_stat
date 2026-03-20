// ─── Recording State ──────────────────────────────────────────────────────────
// State classes for MatchRecordingScreen.
// Separated from match_recording_screen.dart for maintainability.

// ─── Event Item ───────────────────────────────────────────────────────────────

class RecordingEventItem {
  RecordingEventItem({
    required this.id,
    required this.clientEventId,
    required this.eventType,
    required this.createdAt,
    required this.teamSide,
    this.quarter,
    this.gameTime,
    this.playerId,
    this.playerName,
    this.value,
    this.isPending = false,
  });

  final int id;
  final String clientEventId;
  final String eventType;
  final DateTime createdAt;
  final String teamSide; // 'home' | 'away' | ''
  final int? quarter;
  final String? gameTime;
  final int? playerId;
  final String? playerName;
  final int? value; // 득점 값 (2, 3, 1) — Undo 시 정확한 차감용
  final bool isPending;
}

// ─── Recording State ──────────────────────────────────────────────────────────

class RecordingState {
  RecordingState({
    this.matchStatus = 'scheduled',
    this.homeScore = 0,
    this.awayScore = 0,
    this.events = const [],
    this.pendingCount = 0,
    this.isLoading = false,
    this.isSyncing = false,
    this.errorMessage,
    this.homeTeamName = 'HOME',
    this.awayTeamName = 'AWAY',
    this.homeTeamId = 0,
    this.awayTeamId = 0,
    this.currentQuarter = 1,
    this.elapsedSeconds = 0,
    this.isTimerRunning = false,
    this.homePlayers = const [],
    this.awayPlayers = const [],
    // §1.5 팀 파울
    this.homeTeamFouls = 0,
    this.awayTeamFouls = 0,
    // §2.1 샷 클락
    this.shotClockSeconds = 24,
    this.isShotClockRunning = false,
    // §2.2 타임아웃
    this.homeTimeouts = 5,
    this.awayTimeouts = 5,
    // 오프라인 미반영 상태 변경
    this.pendingStatusChange,
    // 선수별 개인파울 수
    this.playerFoulCounts = const {},
    // 선수별 T+U 파울 합계 (2 = 퇴장)
    this.playerTechUnsportFouls = const {},
    // 퇴장 알림 대상 선수 ID (처리 후 null로 리셋)
    this.ejectedPlayerId,
  });

  final String matchStatus;
  final int homeScore;
  final int awayScore;
  final List<RecordingEventItem> events;
  final int pendingCount;
  final bool isLoading;
  final bool isSyncing;
  final String? errorMessage;
  final String homeTeamName;
  final String awayTeamName;
  final int homeTeamId;
  final int awayTeamId;
  final int currentQuarter;
  final int elapsedSeconds;
  final bool isTimerRunning;
  final List<Map<String, dynamic>> homePlayers;
  final List<Map<String, dynamic>> awayPlayers;
  final int homeTeamFouls;
  final int awayTeamFouls;
  final int shotClockSeconds;
  final bool isShotClockRunning;
  final int homeTimeouts;
  final int awayTimeouts;
  final String? pendingStatusChange;
  final Map<int, int> playerFoulCounts;
  final Map<int, int> playerTechUnsportFouls;
  final int? ejectedPlayerId;

  /// §2.1 게이트: 샷클락이 실행 중일 때만 기록 가능 (득점/스탯)
  bool get canRecord => matchStatus == 'in_progress' && isShotClockRunning;
  /// 샷클락 없이도 기록 가능 (파울/교체/타임아웃)
  bool get canRecordAlways => matchStatus == 'in_progress';
  bool get isCompleted => matchStatus == 'completed';

  RecordingState copyWith({
    String? matchStatus,
    int? homeScore,
    int? awayScore,
    List<RecordingEventItem>? events,
    int? pendingCount,
    bool? isLoading,
    bool? isSyncing,
    String? errorMessage,
    String? homeTeamName,
    String? awayTeamName,
    int? homeTeamId,
    int? awayTeamId,
    int? currentQuarter,
    int? elapsedSeconds,
    bool? isTimerRunning,
    List<Map<String, dynamic>>? homePlayers,
    List<Map<String, dynamic>>? awayPlayers,
    int? homeTeamFouls,
    int? awayTeamFouls,
    int? shotClockSeconds,
    bool? isShotClockRunning,
    int? homeTimeouts,
    int? awayTimeouts,
    String? pendingStatusChange,
    Map<int, int>? playerFoulCounts,
    Map<int, int>? playerTechUnsportFouls,
    int? ejectedPlayerId,
    bool clearEjected = false,
    bool clearPendingStatus = false,
    bool clearError = false,
  }) {
    return RecordingState(
      matchStatus: matchStatus ?? this.matchStatus,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      events: events ?? this.events,
      pendingCount: pendingCount ?? this.pendingCount,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      homeTeamName: homeTeamName ?? this.homeTeamName,
      awayTeamName: awayTeamName ?? this.awayTeamName,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      currentQuarter: currentQuarter ?? this.currentQuarter,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      homePlayers: homePlayers ?? this.homePlayers,
      awayPlayers: awayPlayers ?? this.awayPlayers,
      homeTeamFouls: homeTeamFouls ?? this.homeTeamFouls,
      awayTeamFouls: awayTeamFouls ?? this.awayTeamFouls,
      shotClockSeconds: shotClockSeconds ?? this.shotClockSeconds,
      isShotClockRunning: isShotClockRunning ?? this.isShotClockRunning,
      homeTimeouts: homeTimeouts ?? this.homeTimeouts,
      awayTimeouts: awayTimeouts ?? this.awayTimeouts,
      pendingStatusChange: clearPendingStatus ? null : pendingStatusChange ?? this.pendingStatusChange,
      playerFoulCounts: playerFoulCounts ?? this.playerFoulCounts,
      playerTechUnsportFouls: playerTechUnsportFouls ?? this.playerTechUnsportFouls,
      ejectedPlayerId: clearEjected ? null : ejectedPlayerId ?? this.ejectedPlayerId,
    );
  }
}

// ─── Match Recording Args ─────────────────────────────────────────────────────

class MatchRecordingArgs {
  const MatchRecordingArgs({
    required this.matchId,
    required this.tournamentId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
  });
  final int matchId;
  final String tournamentId;
  final int homeTeamId;
  final int awayTeamId;
  final String homeTeamName;
  final String awayTeamName;

  @override
  bool operator ==(Object other) =>
      other is MatchRecordingArgs && other.matchId == matchId;

  @override
  int get hashCode => matchId.hashCode;
}
