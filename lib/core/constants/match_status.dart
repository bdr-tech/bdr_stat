/// 서버 동기화용 매치 상태 (mybdr API 기준)
enum MatchStatusServer {
  scheduled('scheduled'),
  inProgress('in_progress'),
  live('live'),
  completed('completed');

  const MatchStatusServer(this.value);
  final String value;

  static MatchStatusServer fromString(String s) {
    return MatchStatusServer.values.firstWhere(
      (e) => e.value == s,
      orElse: () => MatchStatusServer.scheduled,
    );
  }
}

/// 로컬 기록용 매치 상태 (UI 표시용)
enum MatchStatusLocal {
  scheduled('scheduled'),
  warmup('warmup'),
  live('live'),
  halftime('halftime'),
  finished('finished');

  const MatchStatusLocal(this.value);
  final String value;

  /// 로컬 상태 -> 서버 전송용 변환
  MatchStatusServer toServerStatus() {
    switch (this) {
      case MatchStatusLocal.scheduled:
        return MatchStatusServer.scheduled;
      case MatchStatusLocal.warmup:
      case MatchStatusLocal.live:
      case MatchStatusLocal.halftime:
        return MatchStatusServer.live;
      case MatchStatusLocal.finished:
        return MatchStatusServer.completed;
    }
  }

  /// 서버 상태 -> 로컬 표시용 변환
  static MatchStatusLocal fromServerStatus(MatchStatusServer server) {
    switch (server) {
      case MatchStatusServer.scheduled:
        return MatchStatusLocal.scheduled;
      case MatchStatusServer.inProgress:
      case MatchStatusServer.live:
        return MatchStatusLocal.live;
      case MatchStatusServer.completed:
        return MatchStatusLocal.finished;
    }
  }

  static MatchStatusLocal fromString(String s) {
    return MatchStatusLocal.values.firstWhere(
      (e) => e.value == s,
      orElse: () => MatchStatusLocal.scheduled,
    );
  }

  String get displayLabel {
    switch (this) {
      case MatchStatusLocal.scheduled:
        return '예정';
      case MatchStatusLocal.warmup:
        return '워밍업';
      case MatchStatusLocal.live:
        return 'LIVE';
      case MatchStatusLocal.halftime:
        return '하프타임';
      case MatchStatusLocal.finished:
        return '종료';
    }
  }
}
