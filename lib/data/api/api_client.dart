import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/match_status.dart';
import '../../domain/models/auth_models.dart';

/// 서버에서 int 또는 String으로 올 수 있는 값을 안전하게 int 변환
int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is double) return value.toInt();
  return 0;
}

/// BDR API 클라이언트
class ApiClient {
  ApiClient({String? baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? AppConstants.baseUrl,
          connectTimeout: AppConstants.apiTimeout,
          receiveTimeout: AppConstants.apiTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    if (kDebugMode) {
      final resolvedUrl = baseUrl ?? AppConstants.baseUrl;
      debugPrint('══════════════════════════════════════');
      debugPrint('BDR API Client initialized');
      debugPrint('  ENV: ${AppConstants.environment}');
      debugPrint('  Base URL: $resolvedUrl');
      debugPrint('  Desktop: ${AppConstants.isDesktop}');
      debugPrint('══════════════════════════════════════');
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        // 401 토큰 만료 시 자동 갱신 시도 (사용자 JWT 토큰이 있을 때만)
        // _isRefreshing 플래그로 무한 루프 방지
        if (error.response?.statusCode == 401 && _userToken != null && !_isRefreshing) {
          _isRefreshing = true;
          debugPrint('User JWT expired - attempting refresh');
          try {
            final refreshResponse = await Dio(BaseOptions(
              baseUrl: _dio.options.baseUrl,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $_userToken',
              },
            )).post('/api/v1/auth/refresh');

            final refreshData = refreshResponse.data as Map<String, dynamic>;
            if (refreshData.containsKey('token')) {
              final newToken = refreshData['token'] as String;
              setUserToken(newToken);
              _onTokenRefreshed?.call(newToken);
              _isRefreshing = false;

              // 원래 요청 재시도
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newToken';
              final retryResponse = await _dio.fetch(opts);
              return handler.resolve(retryResponse);
            }
            _isRefreshing = false;
          } catch (e) {
            _isRefreshing = false;
            debugPrint('Token refresh failed: $e');
            setUserToken(null);
            _onTokenExpired?.call();
          }
        }
        handler.next(error);
      },
    ));
  }

  final Dio _dio;
  String? _userToken;   // JWT 사용자 인증 토큰
  String? _apiToken;    // 대회 API 토큰 (별도 관리)
  bool _isRefreshing = false; // 토큰 리프레시 무한 루프 방지
  void Function(String newToken)? _onTokenRefreshed;
  void Function()? _onTokenExpired;

  /// 토큰 만료 콜백 설정 (로그아웃 처리용)
  void setOnTokenExpired(void Function()? callback) {
    _onTokenExpired = callback;
  }

  /// 토큰 갱신 콜백 설정 (AuthProvider에서 사용)
  void setOnTokenRefreshed(void Function(String newToken)? callback) {
    _onTokenRefreshed = callback;
  }

  /// 대회 토큰 설정 (대회 연결용 - 헤더에는 설정하지 않음)
  void setApiToken(String? token) {
    _apiToken = token;
  }

  String? get apiToken => _apiToken;

  /// JWT 사용자 토큰 설정 (로그인 시)
  void setUserToken(String? token) {
    _userToken = token;
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  /// 현재 활성 토큰 (사용자 토큰 우선)
  String? get activeToken => _userToken ?? _apiToken;

  // ═══════════════════════════════════════════════════════════════
  // Auth APIs
  // ═══════════════════════════════════════════════════════════════

  /// 로그인
  Future<ApiResponse<LoginResponse>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/login',
        data: {'email': email, 'password': password},
      );

      // API returns token/user directly (no success/data wrapper)
      final data = response.data as Map<String, dynamic>;
      if (data.containsKey('token')) {
        final loginResponse = LoginResponse.fromJson(data);
        setUserToken(loginResponse.token);
        return ApiResponse.success(loginResponse);
      } else {
        return ApiResponse.error(
            data['error'] as String? ?? '로그인에 실패했습니다.');
      }
    } on DioException catch (e) {
      // 로그인 실패 시 서버 응답의 에러 메시지 우선 사용
      if (e.type == DioExceptionType.badResponse && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map && responseData['error'] != null) {
          return ApiResponse.error(responseData['error'] as String);
        }
      }
      return ApiResponse.error(_handleDioError(e));
    }
  }

  /// 로그아웃
  Future<ApiResponse<void>> logout() async {
    try {
      await _dio.post('/api/v1/auth/logout');
      setUserToken(null);
      return ApiResponse.success(null);
    } on DioException catch (e) {
      // 로그아웃은 실패해도 로컬 토큰 제거
      setUserToken(null);
      return ApiResponse.error(_handleDioError(e));
    }
  }

  /// 현재 사용자 정보 조회
  Future<ApiResponse<UserInfo>> getCurrentUser() async {
    try {
      final response = await _dio.get('/api/v1/auth/me');
      final data = response.data as Map<String, dynamic>;
      if (data.containsKey('error')) {
        return ApiResponse.error(data['error'] as String);
      }
      return ApiResponse.success(UserInfo.fromJson(data));
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    }
  }

  /// 내 대회 목록 조회 (최대 2회 재시도)
  Future<ApiResponse<List<MyTournamentInfo>>> getMyTournaments() async {
    const maxRetries = 2;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _dio.get('/api/v1/auth/my-tournaments');
        // 서버 응답: 배열 [...] 또는 { success: true, data: [...] }
        final List<dynamic> rawList;
        if (response.data is List) {
          rawList = response.data as List;
        } else if (response.data is Map && response.data['data'] is List) {
          rawList = response.data['data'] as List;
        } else if (response.data is Map && response.data['success'] == true) {
          rawList = (response.data['data'] ?? []) as List;
        } else {
          return ApiResponse.error(
              response.data?['error'] as String? ?? '대회 목록을 가져올 수 없습니다.');
        }
        final tournaments = rawList
            .map((t) => MyTournamentInfo.fromJson(t as Map<String, dynamic>))
            .toList();
        return ApiResponse.success(tournaments);
      } on DioException catch (e) {
        debugPrint('getMyTournaments attempt $attempt/$maxRetries failed: ${e.type}');
        if (attempt < maxRetries &&
            (e.type == DioExceptionType.connectionTimeout ||
             e.type == DioExceptionType.receiveTimeout ||
             e.type == DioExceptionType.connectionError)) {
          await Future.delayed(Duration(seconds: attempt));
          continue;
        }
        return ApiResponse.error(_handleDioError(e));
      }
    }
    return ApiResponse.error('대회 목록을 불러올 수 없습니다.');
  }

  /// 토큰 갱신
  Future<ApiResponse<LoginResponse>> refreshToken() async {
    try {
      final response = await _dio.post('/api/v1/auth/refresh');
      final data = response.data as Map<String, dynamic>;
      if (data.containsKey('token')) {
        final newToken = data['token'] as String;
        final expiresAtStr = data['expires_at'] as String?;
        final expiresAt = expiresAtStr != null
            ? DateTime.parse(expiresAtStr)
            : DateTime.now().add(const Duration(days: 7));

        setUserToken(newToken);

        final userResponse = await getCurrentUser();
        if (userResponse.isSuccess) {
          return ApiResponse.success(LoginResponse(
            token: newToken,
            user: userResponse.data!,
            expiresAt: expiresAt,
          ));
        }
        return ApiResponse.error('사용자 정보를 가져올 수 없습니다.');
      } else {
        return ApiResponse.error(
            data['error'] as String? ?? '토큰 갱신에 실패했습니다.');
      }
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Tournament APIs
  // ═══════════════════════════════════════════════════════════════

  /// 토큰으로 대회 검증 (최대 3회 재시도)
  Future<ApiResponse<TournamentData>> verifyTournament(String token) async {
    const maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // 대회 토큰은 query param으로 전달 + Authorization 헤더에도 설정
        final response = await _dio.get(
          '/api/v1/tournaments/connect',
          queryParameters: {'token': token},
        );
        final data = response.data['data'] ?? response.data;
        return ApiResponse.success(TournamentData.fromJson(data));
      } on DioException catch (e) {
        debugPrint('verifyTournament attempt $attempt/$maxRetries failed: ${e.type}');
        // 연결 관련 에러만 재시도 (401 같은 로직 에러는 즉시 반환)
        if (attempt < maxRetries &&
            (e.type == DioExceptionType.connectionTimeout ||
             e.type == DioExceptionType.receiveTimeout ||
             e.type == DioExceptionType.connectionError)) {
          await Future.delayed(Duration(seconds: attempt)); // 1s, 2s 대기
          continue;
        }
        return ApiResponse.error(_handleDioError(e));
      }
    }
    return ApiResponse.error('연결에 실패했습니다. 네트워크를 확인해주세요.');
  }

  /// 대회 전체 데이터 다운로드
  Future<ApiResponse<TournamentFullData>> getTournamentFullData(
      String tournamentId) async {
    try {
      // JWT 사용자 토큰 우선 (withAuth 미들웨어 호환), 없으면 대회 API 토큰
      final tokenForHeader = _userToken ?? _apiToken;
      final response = await _dio.get(
        '/api/v1/tournaments/$tournamentId/full-data',
        options: tokenForHeader != null
            ? Options(headers: {'Authorization': 'Bearer $tokenForHeader'})
            : null,
      );
      final data = response.data['data'] ?? response.data;
      return ApiResponse.success(TournamentFullData.fromJson(data));
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Match APIs
  // ═══════════════════════════════════════════════════════════════

  /// 경기 데이터 단일 동기화 (v2: /matches/sync 엔드포인트)
  Future<ApiResponse<SyncResult>> syncMatchData(
      String tournamentId, Map<String, dynamic> matchData) async {
    try {
      // JWT 사용자 토큰 우선 (withAuth 미들웨어 호환)
      final tokenForHeader = _userToken ?? _apiToken;
      debugPrint('[syncMatch] POST /api/v1/tournaments/$tournamentId/matches/sync');
      debugPrint('[syncMatch] match: ${matchData['match']}');
      debugPrint('[syncMatch] token: ${tokenForHeader != null ? "present" : "MISSING"}');
      debugPrint('[syncMatch] stats: ${(matchData['player_stats'] as List?)?.length ?? 0}, pbp: ${(matchData['play_by_plays'] as List?)?.length ?? 0}');
      // 첫 번째 stat과 pbp 출력
      final statsList = matchData['player_stats'] as List?;
      if (statsList != null && statsList.isNotEmpty) {
        debugPrint('[syncMatch] first_stat: ${statsList.first}');
      }
      final pbpList = matchData['play_by_plays'] as List?;
      if (pbpList != null && pbpList.isNotEmpty) {
        debugPrint('[syncMatch] first_pbp: ${pbpList.first}');
      }
      final response = await _dio.post(
        '/api/v1/tournaments/$tournamentId/matches/sync',
        data: matchData,
        options: tokenForHeader != null
            ? Options(headers: {'Authorization': 'Bearer $tokenForHeader'})
            : null,
      );
      debugPrint('[syncMatch] status: ${response.statusCode}');
      debugPrint('[syncMatch] body: ${response.data}');
      final resData = response.data as Map<String, dynamic>;
      // 서버 응답 형식 호환: {success: true, data: {...}} 또는 직접 {...}
      if (resData.containsKey('success') && resData['success'] == true) {
        final data = resData['data'] as Map<String, dynamic>;
        return ApiResponse.success(SyncResult.fromJson(data));
      } else if (resData.containsKey('server_match_id')) {
        // apiSuccess()가 래퍼 없이 직접 데이터를 반환하는 경우
        return ApiResponse.success(SyncResult.fromJson(resData));
      } else {
        final err = resData['error'] as String? ?? '동기화에 실패했습니다.';
        debugPrint('[syncMatch] ERROR: $err');
        return ApiResponse.error(err);
      }
    } on DioException catch (e) {
      debugPrint('[syncMatch] DioException: ${e.type} ${e.response?.statusCode} ${e.response?.data}');
      return ApiResponse.error(_handleDioError(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Recorder APIs
  // ═══════════════════════════════════════════════════════════════

  /// 기록자에게 배정된 경기 목록 조회
  Future<ApiResponse<List<dynamic>>> getRecorderMatches() async {
    try {
      final response = await _dio.get('/api/v1/recorder/matches');
      if (response.data['success'] == true) {
        final matches = (response.data['data']?['matches'] as List?) ?? [];
        return ApiResponse.success(matches);
      } else {
        return ApiResponse.error(
            response.data['error'] as String? ?? '경기 목록을 가져올 수 없습니다.');
      }
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    }
  }

  /// 경기 상태 업데이트
  Future<ApiResponse<Map<String, dynamic>>> updateMatchStatus(
      int matchId, String status) async {
    try {
      final response = await _dio.patch(
        '/api/v1/matches/$matchId/status',
        data: {'status': status},
      );
      if (response.data['success'] == true) {
        final data = (response.data['data'] as Map<String, dynamic>?) ?? {};
        return ApiResponse.success(data);
      } else {
        return ApiResponse.error(
            response.data['error'] as String? ?? '경기 상태를 업데이트할 수 없습니다.');
      }
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    }
  }

  /// 단일 이벤트 기록
  Future<ApiResponse<Map<String, dynamic>>> postEvent(
      int matchId, Map<String, dynamic> event) async {
    try {
      debugPrint('[postEvent] POST /api/v1/matches/$matchId/events');
      debugPrint('[postEvent] data: $event');
      final response =
          await _dio.post('/api/v1/matches/$matchId/events', data: event);
      debugPrint('[postEvent] status: ${response.statusCode}');
      debugPrint('[postEvent] body: ${response.data}');
      if (response.data['success'] == true) {
        final data = (response.data['data'] as Map<String, dynamic>?) ?? {};
        return ApiResponse.success(data);
      } else {
        final err = response.data['error'] as String? ?? '이벤트를 기록할 수 없습니다.';
        debugPrint('[postEvent] ERROR: $err');
        return ApiResponse.error(err);
      }
    } on DioException catch (e) {
      debugPrint('[postEvent] DioException: ${e.type} ${e.response?.statusCode} ${e.response?.data}');
      return ApiResponse.error(_handleDioError(e));
    }
  }

  /// 이벤트 취소 (undo)
  Future<ApiResponse<Map<String, dynamic>>> undoEvent(
      int matchId, int eventId) async {
    try {
      final response = await _dio.patch(
        '/api/v1/matches/$matchId/events/$eventId/undo',
        data: {},
      );
      if (response.data['success'] == true) {
        final data = (response.data['data'] as Map<String, dynamic>?) ?? {};
        return ApiResponse.success(data);
      } else {
        return ApiResponse.error(
            response.data['error'] as String? ?? '이벤트를 취소할 수 없습니다.');
      }
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    }
  }

  /// 경기 이벤트 목록 조회 (취소되지 않은 것만)
  Future<ApiResponse<List<dynamic>>> getEvents(int matchId) async {
    try {
      final response = await _dio.get('/api/v1/matches/$matchId/events');
      if (response.data['success'] == true) {
        final events = (response.data['data']?['events'] as List?) ?? [];
        return ApiResponse.success(events);
      } else {
        return ApiResponse.error(
            response.data['error'] as String? ?? '이벤트 목록을 가져올 수 없습니다.');
      }
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    }
  }

  /// 오프라인 이벤트 일괄 전송 (batch flush)
  Future<ApiResponse<Map<String, dynamic>>> batchFlushEvents(
      int matchId, List<Map<String, dynamic>> events) async {
    try {
      debugPrint('[batchFlush] POST /api/v1/matches/$matchId/events/batch (${events.length} events)');
      final response = await _dio.post(
        '/api/v1/matches/$matchId/events/batch',
        data: {'events': events},
      );
      debugPrint('[batchFlush] status: ${response.statusCode}');
      debugPrint('[batchFlush] body: ${response.data}');
      if (response.data['success'] == true) {
        final data = (response.data['data'] as Map<String, dynamic>?) ?? {};
        return ApiResponse.success(data);
      } else {
        final err = response.data['error'] as String? ?? '이벤트 일괄 전송에 실패했습니다.';
        debugPrint('[batchFlush] ERROR: $err');
        return ApiResponse.error(err);
      }
    } on DioException catch (e) {
      debugPrint('[batchFlush] DioException: ${e.type} ${e.response?.statusCode} ${e.response?.data}');
      return ApiResponse.error(_handleDioError(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Roster APIs
  // ═══════════════════════════════════════════════════════════════

  /// 경기 선수 명단 조회 (홈/어웨이)
  Future<ApiResponse<Map<String, dynamic>>> getMatchRoster(int matchId) async {
    try {
      final response = await _dio.get('/api/v1/matches/$matchId/roster');
      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        return ApiResponse.success(data);
      } else {
        return ApiResponse.error(
            response.data['error'] as String? ?? '선수 명단을 가져올 수 없습니다.');
      }
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Error Handling
  // ═══════════════════════════════════════════════════════════════

  /// DioException을 사람이 읽을 수 있는 한국어 에러 메시지로 변환
  ///
  /// 재시도 가능 에러 유형:
  ///   - connectionTimeout, receiveTimeout, sendTimeout, connectionError
  /// 재시도 불가 에러 유형:
  ///   - badResponse (401, 403, 404, 5xx)
  ///   - badCertificate, cancel
  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '연결 시간이 초과되었습니다.';
      case DioExceptionType.receiveTimeout:
        return '응답 시간이 초과되었습니다.';
      case DioExceptionType.sendTimeout:
        return '요청 전송 시간이 초과되었습니다.';
      case DioExceptionType.badCertificate:
        return '보안 인증서 오류가 발생했습니다.';
      case DioExceptionType.cancel:
        return '요청이 취소되었습니다.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return '인증이 만료되었습니다. 다시 연결해주세요.';
        } else if (statusCode == 403) {
          return '접근 권한이 없습니다.';
        } else if (statusCode == 404) {
          return '요청한 정보를 찾을 수 없습니다.';
        } else if (statusCode == 422) {
          return '요청 데이터가 올바르지 않습니다.';
        } else if (statusCode != null && statusCode >= 500) {
          return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
        }
        // 서버가 에러 응답에 메시지를 포함한 경우 우선 사용
        final serverMsg = error.response?.data;
        if (serverMsg is Map) {
          final msg = serverMsg['message'] as String? ?? serverMsg['error'] as String?;
          if (msg != null && msg.isNotEmpty) return msg;
        }
        return '요청 처리 중 오류가 발생했습니다.';
      case DioExceptionType.connectionError:
        return '네트워크 연결을 확인해주세요.';
      case DioExceptionType.unknown:
        return '알 수 없는 오류가 발생했습니다.';
    }
  }
}

/// API 응답 래퍼
///
/// 사용 예:
///   final result = await apiClient.login(email, password);
///   if (result.isSuccess) { ... result.data ... }
///   else { showError(result.error!); }
///
/// 주의: ApiResponse[void] 의 경우 data는 항상 null 이지만
///       isSuccess 는 에러 유무로 판단합니다.
class ApiResponse<T> {
  ApiResponse.success(this.data)
      : error = null,
        _succeeded = true;
  ApiResponse.error(this.error)
      : data = null,
        _succeeded = false;

  final T? data;
  final String? error;
  final bool _succeeded;

  /// 성공 여부 — void 응답에서도 올바르게 동작합니다.
  bool get isSuccess => _succeeded;
  bool get isError => !_succeeded;
}

/// 대회 정보 (검증 응답)
class TournamentData {
  TournamentData({
    required this.id,
    required this.name,
    required this.status,
    this.startDate,
    this.endDate,
    this.venueName,
    this.venueAddress,
    this.gameRules,
    this.teamCount,
    this.primaryColor,
    this.secondaryColor,
  });

  factory TournamentData.fromJson(Map<String, dynamic> json) {
    return TournamentData(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String,
      status: json['status'] as String,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString())
          : null,
      endDate:
          json['end_date'] != null ? DateTime.tryParse(json['end_date'].toString()) : null,
      venueName: json['venue_name'] as String?,
      venueAddress: json['venue_address'] as String?,
      gameRules: json['game_rules'] as Map<String, dynamic>?,
      teamCount: json['team_count'] as int?,
      primaryColor: json['primary_color'] as String?,
      secondaryColor: json['secondary_color'] as String?,
    );
  }

  final String id;
  final String name;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? venueName;
  final String? venueAddress;
  final Map<String, dynamic>? gameRules;
  final int? teamCount;
  final String? primaryColor;
  final String? secondaryColor;
}

/// 대회 전체 데이터 (다운로드용)
class TournamentFullData {
  TournamentFullData({
    required this.tournament,
    required this.teams,
    required this.players,
    required this.matches,
    this.playerStats = const [],
    this.playByPlays = const [],
  });

  factory TournamentFullData.fromJson(Map<String, dynamic> json) {
    return TournamentFullData(
      tournament: json['tournament'] != null
          ? TournamentData.fromJson(json['tournament'] as Map<String, dynamic>)
          : TournamentData(id: '', name: '', status: 'unknown'),
      teams: (json['teams'] as List)
          .map((t) => TeamData.fromJson(t as Map<String, dynamic>))
          .toList(),
      players: (json['players'] as List)
          .map((p) => PlayerData.fromJson(p as Map<String, dynamic>))
          .toList(),
      matches: (json['matches'] as List?)
              ?.map((m) => MatchData.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      playerStats: (json['player_stats'] as List?)
              ?.map((s) => ServerPlayerStatData.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      playByPlays: (json['play_by_plays'] as List?)
              ?.map((p) => ServerPlayByPlayData.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  final TournamentData tournament;
  final List<TeamData> teams;
  final List<PlayerData> players;
  final List<MatchData> matches;
  final List<ServerPlayerStatData> playerStats;
  final List<ServerPlayByPlayData> playByPlays;
}

/// 팀 데이터
class TeamData {
  TeamData({
    required this.id,
    required this.tournamentId,
    required this.teamId,
    required this.teamName,
    this.teamLogoUrl,
    this.primaryColor,
    this.secondaryColor,
    this.groupName,
    this.seedNumber,
    this.wins = 0,
    this.losses = 0,
  });

  factory TeamData.fromJson(Map<String, dynamic> json) {
    return TeamData(
      id: _toInt(json['id']),
      tournamentId: json['tournament_id']?.toString() ?? '',
      teamId: _toInt(json['team_id']),
      teamName: json['team_name'] as String? ?? 'Unknown Team',
      teamLogoUrl: json['team_logo_url'] as String?,
      primaryColor: json['primary_color'] as String?,
      secondaryColor: json['secondary_color'] as String?,
      groupName: json['group_name'] as String?,
      seedNumber: json['seed_number'] as int?,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
    );
  }

  final int id;
  final String tournamentId;
  final int teamId;
  final String teamName;
  final String? teamLogoUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final String? groupName;
  final int? seedNumber;
  final int wins;
  final int losses;
}

/// 선수 데이터
class PlayerData {
  PlayerData({
    required this.id,
    required this.tournamentTeamId,
    this.userId,
    required this.userName,
    this.userNickname,
    this.profileImageUrl,
    this.jerseyNumber,
    this.position,
    this.role = 'player',
    this.isStarter = false,
    this.isActive = true,
    this.bdrDnaCode,
  });

  factory PlayerData.fromJson(Map<String, dynamic> json) {
    return PlayerData(
      id: _toInt(json['id']),
      tournamentTeamId: _toInt(json['tournament_team_id']),
      userId: json['user_id'] != null ? _toInt(json['user_id']) : null,
      userName: json['user_name'] as String? ?? 'Unknown',
      userNickname: json['user_nickname'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      jerseyNumber: json['jersey_number'] as int?,
      position: json['position'] as String?,
      role: json['role'] as String? ?? 'player',
      isStarter: json['is_starter'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      bdrDnaCode: json['bdr_dna_code'] as String?,
    );
  }

  final int id;
  final int tournamentTeamId;
  final int? userId;
  final String userName;
  final String? userNickname;
  final String? profileImageUrl;
  final int? jerseyNumber;
  final String? position;
  final String role;
  final bool isStarter;
  final bool isActive;
  final String? bdrDnaCode;
}

/// 경기 데이터
class MatchData {
  MatchData({
    required this.id,
    required this.uuid,
    required this.tournamentId,
    required this.homeTeamId,
    required this.awayTeamId,
    this.roundName,
    this.roundNumber,
    this.groupName,
    this.scheduledAt,
    this.status = 'scheduled',
    this.homeScore,
    this.awayScore,
    this.quarterScores,
  });

  factory MatchData.fromJson(Map<String, dynamic> json) {
    return MatchData(
      id: _toInt(json['id']),
      uuid: json['uuid'] as String? ?? '',
      tournamentId: json['tournament_id']?.toString() ?? '',
      homeTeamId: _toInt(json['home_team_id']),
      awayTeamId: _toInt(json['away_team_id']),
      roundName: json['round_name'] as String?,
      roundNumber: json['round_number'] as int?,
      groupName: json['group_name'] as String?,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'].toString())
          : null,
      status: MatchStatusLocal.fromServerStatus(
        MatchStatusServer.fromString(json['status'] as String? ?? 'scheduled'),
      ).value,
      homeScore: json['home_score'] as int?,
      awayScore: json['away_score'] as int?,
      quarterScores: json['quarter_scores'] as Map<String, dynamic>?,
    );
  }

  final int id;
  final String uuid;
  final String tournamentId;
  final int homeTeamId;
  final int awayTeamId;
  final String? roundName;
  final int? roundNumber;
  final String? groupName;
  final DateTime? scheduledAt;
  final String status;
  final int? homeScore;
  final int? awayScore;
  final Map<String, dynamic>? quarterScores;
}

/// 서버에서 다운로드한 선수 스탯 데이터
class ServerPlayerStatData {
  ServerPlayerStatData({
    required this.id,
    required this.tournamentMatchId,
    required this.tournamentTeamPlayerId,
    this.isStarter = false,
    this.minutesPlayed = 0,
    this.points = 0,
    this.fieldGoalsMade = 0,
    this.fieldGoalsAttempted = 0,
    this.twoPointersMade = 0,
    this.twoPointersAttempted = 0,
    this.threePointersMade = 0,
    this.threePointersAttempted = 0,
    this.freeThrowsMade = 0,
    this.freeThrowsAttempted = 0,
    this.offensiveRebounds = 0,
    this.defensiveRebounds = 0,
    this.totalRebounds = 0,
    this.assists = 0,
    this.steals = 0,
    this.blocks = 0,
    this.turnovers = 0,
    this.personalFouls = 0,
    this.plusMinus = 0,
    this.fouledOut = false,
    this.ejected = false,
  });

  factory ServerPlayerStatData.fromJson(Map<String, dynamic> json) {
    return ServerPlayerStatData(
      id: json['id'] as int,
      tournamentMatchId: json['tournament_match_id'] as int,
      tournamentTeamPlayerId: json['tournament_team_player_id'] as int,
      isStarter: json['is_starter'] as bool? ?? false,
      minutesPlayed: json['minutes_played'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
      fieldGoalsMade: json['field_goals_made'] as int? ?? 0,
      fieldGoalsAttempted: json['field_goals_attempted'] as int? ?? 0,
      twoPointersMade: json['two_pointers_made'] as int? ?? 0,
      twoPointersAttempted: json['two_pointers_attempted'] as int? ?? 0,
      threePointersMade: json['three_pointers_made'] as int? ?? 0,
      threePointersAttempted: json['three_pointers_attempted'] as int? ?? 0,
      freeThrowsMade: json['free_throws_made'] as int? ?? 0,
      freeThrowsAttempted: json['free_throws_attempted'] as int? ?? 0,
      offensiveRebounds: json['offensive_rebounds'] as int? ?? 0,
      defensiveRebounds: json['defensive_rebounds'] as int? ?? 0,
      totalRebounds: json['total_rebounds'] as int? ?? 0,
      assists: json['assists'] as int? ?? 0,
      steals: json['steals'] as int? ?? 0,
      blocks: json['blocks'] as int? ?? 0,
      turnovers: json['turnovers'] as int? ?? 0,
      personalFouls: json['personal_fouls'] as int? ?? 0,
      plusMinus: json['plus_minus'] as int? ?? 0,
      fouledOut: json['fouled_out'] as bool? ?? false,
      ejected: json['ejected'] as bool? ?? false,
    );
  }

  final int id, tournamentMatchId, tournamentTeamPlayerId;
  final bool isStarter;
  final int minutesPlayed, points;
  final int fieldGoalsMade, fieldGoalsAttempted;
  final int twoPointersMade, twoPointersAttempted;
  final int threePointersMade, threePointersAttempted;
  final int freeThrowsMade, freeThrowsAttempted;
  final int offensiveRebounds, defensiveRebounds, totalRebounds;
  final int assists, steals, blocks, turnovers, personalFouls, plusMinus;
  final bool fouledOut, ejected;
}

/// 서버에서 다운로드한 PBP 데이터
class ServerPlayByPlayData {
  ServerPlayByPlayData({
    required this.id,
    required this.localId,
    required this.tournamentMatchId,
    this.tournamentTeamPlayerId,
    this.tournamentTeamId,
    this.quarter = 1,
    this.gameClockSeconds,
    this.shotClockSeconds,
    this.actionType = '',
    this.actionSubtype,
    this.isMade,
    this.pointsScored = 0,
    this.courtX,
    this.courtY,
    this.courtZone,
    this.homeScoreAtTime,
    this.awayScoreAtTime,
    this.assistPlayerId,
    this.reboundPlayerId,
    this.blockPlayerId,
    this.stealPlayerId,
    this.fouledPlayerId,
    this.isFastbreak = false,
    this.isSecondChance = false,
    this.isFromTurnover = false,
    this.description,
  });

  factory ServerPlayByPlayData.fromJson(Map<String, dynamic> json) {
    return ServerPlayByPlayData(
      id: json['id'] as int,
      localId: json['local_id'] as String? ?? 'server_${json['id']}',
      tournamentMatchId: json['tournament_match_id'] as int,
      tournamentTeamPlayerId: json['tournament_team_player_id'] as int?,
      tournamentTeamId: json['tournament_team_id'] as int?,
      quarter: json['quarter'] as int? ?? 1,
      gameClockSeconds: json['game_clock_seconds'] as int?,
      shotClockSeconds: json['shot_clock_seconds'] as int?,
      actionType: json['action_type'] as String? ?? '',
      actionSubtype: json['action_subtype'] as String?,
      isMade: json['is_made'] as bool?,
      pointsScored: json['points_scored'] as int? ?? 0,
      courtX: (json['court_x'] as num?)?.toDouble(),
      courtY: (json['court_y'] as num?)?.toDouble(),
      courtZone: json['court_zone'] as int?,
      homeScoreAtTime: json['home_score_at_time'] as int?,
      awayScoreAtTime: json['away_score_at_time'] as int?,
      assistPlayerId: json['assist_player_id'] as int?,
      reboundPlayerId: json['rebound_player_id'] as int?,
      blockPlayerId: json['block_player_id'] as int?,
      stealPlayerId: json['steal_player_id'] as int?,
      fouledPlayerId: json['fouled_player_id'] as int?,
      isFastbreak: json['is_fastbreak'] as bool? ?? false,
      isSecondChance: json['is_second_chance'] as bool? ?? false,
      isFromTurnover: json['is_from_turnover'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }

  final int id;
  final String localId;
  final int tournamentMatchId;
  final int? tournamentTeamPlayerId, tournamentTeamId;
  final int quarter;
  final int? gameClockSeconds, shotClockSeconds;
  final String actionType;
  final String? actionSubtype;
  final bool? isMade;
  final int pointsScored;
  final double? courtX, courtY;
  final int? courtZone;
  final int? homeScoreAtTime, awayScoreAtTime;
  final int? assistPlayerId, reboundPlayerId, blockPlayerId, stealPlayerId, fouledPlayerId;
  final bool isFastbreak, isSecondChance, isFromTurnover;
  final String? description;
}

/// 동기화 결과
class SyncResult {
  SyncResult({
    required this.success,
    this.matchId,
    this.serverMatchId,
    this.message,
    this.careerStatsUpdated,
    this.hasConflict,
    this.conflictMessage,
    this.serverData,
  });

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      success: true, // API returned success if we reach here
      matchId: json['match_id'] as int?,
      serverMatchId: json['server_match_id'] as int?,
      message: json['message'] as String?,
      careerStatsUpdated: json['career_stats_updated'] as bool?,
      hasConflict: json['has_conflict'] as bool?,
      conflictMessage: json['conflict_message'] as String?,
      serverData: json['server_data'] as Map<String, dynamic>?,
    );
  }

  final bool success;
  final int? matchId;
  final int? serverMatchId;
  final String? message;
  final bool? careerStatsUpdated;
  final bool? hasConflict;
  final String? conflictMessage;
  final Map<String, dynamic>? serverData;
}
