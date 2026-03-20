import 'dart:io' show Platform;

/// 앱 전체 상수
class AppConstants {
  AppConstants._();

  // 앱 정보
  static const String appName = 'BDR Tournament Recorder';
  static const String appVersion = '1.0.0';

  // API 환경 설정
  // 빌드 시 --dart-define=ENV=production 으로 환경 지정 가능
  // 예: flutter build ios --dart-define=ENV=production
  static const String _environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'production',
  );

  // 개발 서버 IP (태블릿에서 Mac으로 연결 시)
  // 빌드 시 --dart-define=DEV_SERVER_IP=192.168.1.100 으로 지정 가능
  static const String _devServerIp = String.fromEnvironment(
    'DEV_SERVER_IP',
    defaultValue: 'localhost',
  );

  // 개발 서버 포트
  // 빌드 시 --dart-define=DEV_SERVER_PORT=3000 으로 지정 가능
  static const String _devServerPort = String.fromEnvironment(
    'DEV_SERVER_PORT',
    defaultValue: '3000',
  );

  /// 데스크톱(macOS/Windows/Linux)인지 여부
  static bool get isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  /// 현재 API Base URL
  /// - production: https://mybdr.kr
  /// - staging: https://staging.mybdr.kr (향후 분리 대비)
  /// - local: http://localhost:{port}
  /// - development (macOS): http://localhost:{port} (자동 감지)
  /// - development (tablet): http://{DEV_SERVER_IP}:{port}
  static String get baseUrl {
    switch (_environment) {
      case 'production':
        return 'https://mybdr.kr';
      case 'staging':
        return 'https://mybdr.kr';
      case 'local':
        return 'http://localhost:$_devServerPort';
      default: // development
        // macOS 데스크톱에서 실행 시 127.0.0.1 사용
        // (localhost는 IPv6 ::1로 먼저 시도하여 연결 지연 발생 가능)
        final host = isDesktop ? '127.0.0.1' : _devServerIp;
        return 'http://$host:$_devServerPort';
    }
  }

  /// 현재 환경
  static String get environment => _environment;

  /// 개발 환경 여부
  static bool get isDevelopment => _environment == 'development' || _environment == 'local';

  /// 프로덕션 환경 여부
  static bool get isProduction => _environment == 'production';

  static const Duration apiTimeout = Duration(seconds: 30);

  // 자동 저장
  static const Duration autoSaveInterval = Duration(seconds: 30);

  // Undo 스택
  static const int maxUndoStackSize = 10;

  // 타이머 (BUG-002 수정: 하드코딩 제거)
  /// 스플래시 화면 초기 딜레이
  static const Duration splashInitialDelay = Duration(milliseconds: 1500);

  /// AuthProvider 초기화 대기 체크 간격
  static const Duration authCheckInterval = Duration(milliseconds: 100);

  /// AuthProvider 초기화 최대 대기 횟수 (100ms * 30 = 3초)
  static const int authCheckMaxAttempts = 30;

  /// 네트워크 상태 주기적 확인 간격
  static const Duration networkCheckInterval = Duration(seconds: 30);

  /// 인터넷 접근 타임아웃
  static const Duration internetAccessTimeout = Duration(seconds: 5);
}

/// 게임 규칙 기본값
class GameRulesDefaults {
  GameRulesDefaults._();

  // 시간
  static const int quarterMinutes = 10;
  static const int quarterSeconds = quarterMinutes * 60;
  static const int overtimeMinutes = 5;
  static const int overtimeSeconds = overtimeMinutes * 60;
  static const int shotClockSeconds = 24;
  static const int shotClockAfterOffensiveRebound = 14;

  // 파울
  static const int bonusThreshold = 5; // 5파울부터 보너스
  static const int foulOutLimit = 5; // 5파울 퇴장

  // 타임아웃
  static const int timeoutsPerHalf = 2;
  static const int totalTimeouts = 4;

  /// 대회 설정에서 커스텀 규칙 로드
  static Map<String, int> fromJson(Map<String, dynamic>? json) {
    if (json == null) return defaults;
    return {
      'quarter_minutes': json['quarter_minutes'] as int? ?? quarterMinutes,
      'shot_clock_seconds': json['shot_clock_seconds'] as int? ?? shotClockSeconds,
      'foul_out_limit': json['foul_out_limit'] as int? ?? foulOutLimit,
      'timeouts_per_half': json['timeouts_per_half'] as int? ?? timeoutsPerHalf,
      'total_timeouts': json['total_timeouts'] as int? ?? totalTimeouts,
    };
  }

  static const Map<String, int> defaults = {
    'quarter_minutes': quarterMinutes,
    'shot_clock_seconds': shotClockSeconds,
    'foul_out_limit': foulOutLimit,
    'timeouts_per_half': timeoutsPerHalf,
    'total_timeouts': totalTimeouts,
  };
}

/// 액션 타입
class ActionTypes {
  ActionTypes._();

  static const String shot = 'shot';
  static const String rebound = 'rebound';
  static const String assist = 'assist';
  static const String steal = 'steal';
  static const String block = 'block';
  static const String turnover = 'turnover';
  static const String foul = 'foul';
  static const String substitution = 'substitution';
  static const String timeout = 'timeout';
  static const String quarterStart = 'quarter_start';
  static const String quarterEnd = 'quarter_end';
  static const String jumpBall = 'jump_ball';
}

/// 액션 서브타입
class ActionSubtypes {
  ActionSubtypes._();

  // 슛 종류
  static const String twoPoint = '2pt';
  static const String threePoint = '3pt';
  static const String freeThrow = 'ft';

  // 리바운드 종류
  static const String offensive = 'offensive';
  static const String defensive = 'defensive';

  // 파울 종류
  static const String personal = 'personal';
  static const String shooting = 'shooting';
  static const String offensiveFoul = 'offensive';
  static const String technical = 'technical';
  static const String flagrant = 'flagrant';
  static const String flagrant2 = 'flagrant2'; // Sprint 2: 플래그런트 2
  static const String unsportsmanlike = 'unsportsmanlike';
  static const String andOne = 'and_one';
}

/// 경기 상태
class MatchStatus {
  MatchStatus._();

  // 서버 호환 상태값 (mybdr API 기준 - 이것을 사용)
  static const String scheduled = 'scheduled';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String bye = 'bye';
  static const String cancelled = 'cancelled';
  static const String pending = 'pending';

  // 레거시 앱 내부값 (향후 제거 예정)
  static const String warmup = 'warmup';
  @Deprecated('Use inProgress instead')
  static const String live = 'live';
  static const String halftime = 'halftime';
  @Deprecated('Use completed instead')
  static const String finished = 'finished';

  /// 경기 진행 중 여부
  static bool isActive(String status) =>
      status == inProgress || status == 'live';

  /// 경기 완료 여부
  static bool isDone(String status) =>
      status == completed || status == 'finished';
}

/// 포지션
class Positions {
  Positions._();

  static const String pg = 'PG';
  static const String sg = 'SG';
  static const String sf = 'SF';
  static const String pf = 'PF';
  static const String c = 'C';

  static const List<String> all = [pg, sg, sf, pf, c];

  static String getName(String position) {
    switch (position) {
      case pg:
        return '포인트가드';
      case sg:
        return '슈팅가드';
      case sf:
        return '스몰포워드';
      case pf:
        return '파워포워드';
      case c:
        return '센터';
      default:
        return position;
    }
  }
}

/// NBA 25-Zone 정의
class CourtZones {
  CourtZones._();

  // Restricted Area
  static const int restrictedArea = 1;

  // Paint (non-restricted)
  static const int paintLeft = 2;
  static const int paintCenter = 3;
  static const int paintRight = 4;

  // Mid-Range
  static const int midRangeLeftBaseline = 5;
  static const int midRangeLeftWing = 6;
  static const int midRangeLeftElbow = 7;
  static const int midRangeTopKey = 8;
  static const int midRangeRightElbow = 9;
  static const int midRangeRightWing = 10;
  static const int midRangeRightBaseline = 11;

  // 3-Point
  static const int threePointLeftCorner = 12;
  static const int threePointLeftWing = 13;
  static const int threePointLeftTop = 14;
  static const int threePointTopCenter = 15;
  static const int threePointRightTop = 16;
  static const int threePointRightWing = 17;
  static const int threePointRightCorner = 18;

  // Backcourt (beyond half court)
  static const int backcourt = 25;

  /// 3점 라인 안쪽인지 확인
  static bool isThreePointer(int zone) {
    return zone >= 12 && zone <= 18;
  }

  /// 존 이름 반환
  static String getZoneName(int zone) {
    switch (zone) {
      case restrictedArea:
        return '제한구역';
      case paintLeft:
        return '페인트 좌측';
      case paintCenter:
        return '페인트 중앙';
      case paintRight:
        return '페인트 우측';
      case midRangeLeftBaseline:
        return '미드레인지 좌측 베이스라인';
      case midRangeLeftWing:
        return '미드레인지 좌측 윙';
      case midRangeLeftElbow:
        return '미드레인지 좌측 엘보';
      case midRangeTopKey:
        return '미드레인지 탑키';
      case midRangeRightElbow:
        return '미드레인지 우측 엘보';
      case midRangeRightWing:
        return '미드레인지 우측 윙';
      case midRangeRightBaseline:
        return '미드레인지 우측 베이스라인';
      case threePointLeftCorner:
        return '3점 좌측 코너';
      case threePointLeftWing:
        return '3점 좌측 윙';
      case threePointLeftTop:
        return '3점 좌측 탑';
      case threePointTopCenter:
        return '3점 탑 중앙';
      case threePointRightTop:
        return '3점 우측 탑';
      case threePointRightWing:
        return '3점 우측 윙';
      case threePointRightCorner:
        return '3점 우측 코너';
      case backcourt:
        return '백코트';
      default:
        return 'Zone $zone';
    }
  }
}
