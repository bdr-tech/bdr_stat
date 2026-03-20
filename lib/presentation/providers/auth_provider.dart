import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/api/api_client.dart';
import '../../di/providers.dart';
import '../../domain/models/auth_models.dart';
import 'supabase_tournament_provider.dart';

/// 인증 상태 키 (Secure Storage / SharedPreferences)
const String _authTokenKey = 'user_auth_token';
const String _authUserKey = 'user_auth_user';
const String _authExpiresKey = 'user_auth_expires';

/// macOS debug 모드에서 Keychain 문제 우회를 위한 헬퍼
/// Debug 모드에서는 SharedPreferences 사용, Release에서는 SecureStorage 사용
class _AuthStorage {
  _AuthStorage(this._secureStorage);

  final FlutterSecureStorage _secureStorage;
  SharedPreferences? _prefs;
  bool _useSharedPrefs = false;

  Future<void> _initIfNeeded() async {
    // macOS debug 모드에서만 SharedPreferences 폴백 허용
    // Release 빌드에서는 절대 SharedPreferences를 사용하지 않음
    if (kDebugMode && Platform.isMacOS) {
      _useSharedPrefs = true;
      _prefs ??= await SharedPreferences.getInstance();
      return;
    }
    // Release 모드에서 _useSharedPrefs가 true가 되면 안 됨
    if (!kDebugMode && _useSharedPrefs) {
      debugPrint('⚠️ SECURITY WARNING: SharedPreferences fallback active in release mode! Switching back to SecureStorage.');
      _useSharedPrefs = false;
    }
  }

  Future<String?> read(String key) async {
    await _initIfNeeded();
    if (_useSharedPrefs) {
      return _prefs?.getString(key);
    }
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      debugPrint('⚠️ SecureStorage read failed: $e');
      if (kDebugMode) {
        // Debug에서만 SharedPreferences 폴백 허용
        _useSharedPrefs = true;
        _prefs ??= await SharedPreferences.getInstance();
        return _prefs?.getString(key);
      }
      // Release에서는 null 반환 (재로그인 유도)
      return null;
    }
  }

  Future<void> write(String key, String value) async {
    await _initIfNeeded();
    if (_useSharedPrefs) {
      await _prefs?.setString(key, value);
      return;
    }
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      debugPrint('⚠️ SecureStorage write failed: $e');
      if (kDebugMode) {
        // Debug에서만 SharedPreferences 폴백 허용
        _useSharedPrefs = true;
        _prefs ??= await SharedPreferences.getInstance();
        await _prefs?.setString(key, value);
      }
      // Release에서는 쓰기 실패 — 다음 앱 실행 시 재로그인 필요
    }
  }

  Future<void> delete(String key) async {
    await _initIfNeeded();
    if (_useSharedPrefs) {
      await _prefs?.remove(key);
      return;
    }
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      debugPrint('⚠️ SecureStorage delete failed: $e');
      if (kDebugMode) {
        // Debug에서만 SharedPreferences 폴백 허용
        _prefs ??= await SharedPreferences.getInstance();
        await _prefs?.remove(key);
      }
      // Release에서는 삭제 실패 무시 — 토큰 만료 시 자연 정리됨
    }
  }
}

/// 인증 상태 관리 Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required this.apiClient,
    required FlutterSecureStorage secureStorage,
    required this.ref,
  }) : _storage = _AuthStorage(secureStorage),
       super(AuthState()) {
    // 초기화 시 저장된 인증 정보 로드
    _loadSavedAuth();
  }

  final ApiClient apiClient;
  final _AuthStorage _storage;
  final Ref ref;

  /// 저장된 인증 정보 로드
  Future<void> _loadSavedAuth() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final token = await _storage.read(_authTokenKey);
      final userJson = await _storage.read(_authUserKey);
      final expiresStr = await _storage.read(_authExpiresKey);

      debugPrint('🔐 Checking saved auth: token=${token != null}, user=${userJson != null}');

      if (token != null && userJson != null) {
        final expiresAt = expiresStr != null ? DateTime.tryParse(expiresStr) : null;

        // 토큰 만료 확인
        if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
          debugPrint('🔐 Token expired, attempting refresh...');
          // 토큰 만료됨 - 갱신 시도
          apiClient.setUserToken(token);
          final refreshResult = await apiClient.refreshToken();

          if (refreshResult.isSuccess) {
            await _saveAuth(refreshResult.data!);
            state = AuthState(
              status: AuthStatus.authenticated,
              user: refreshResult.data!.user,
              token: refreshResult.data!.token,
              expiresAt: refreshResult.data!.expiresAt,
            );
            return;
          } else {
            // 갱신 실패 - 로그아웃
            debugPrint('🔐 Token refresh failed, clearing auth');
            await _clearAuth();
            state = AuthState(status: AuthStatus.unauthenticated);
            return;
          }
        }

        // 유효한 토큰 - 서버에서 확인
        apiClient.setUserToken(token);

        // 토큰 유효성 확인을 위해 사용자 정보 조회 시도
        final userResult = await apiClient.getCurrentUser();
        if (userResult.isSuccess) {
          debugPrint('🔐 Token valid, user authenticated');
          state = AuthState(
            status: AuthStatus.authenticated,
            user: userResult.data!,
            token: token,
            expiresAt: expiresAt,
          );
          // Fire-and-forget: 앱 재시작 시 대회 데이터 pre-fetch
          ref.read(tournamentPrefetchProvider.notifier).prefetchAll();
        } else {
          // 토큰이 유효하지 않음 - 저장된 인증 정보 삭제
          debugPrint('🔐 Token invalid (server rejected), clearing auth');
          await _clearAuth();
          apiClient.setUserToken(null);
          state = AuthState(status: AuthStatus.unauthenticated);
        }
      } else {
        debugPrint('🔐 No saved auth found');
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      debugPrint('🔐 Load saved auth error: $e');
      // 오류 발생 시 저장된 인증 정보 삭제
      await _clearAuth();
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// 로그인
  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await apiClient.login(email, password);

    if (result.isSuccess) {
      // 토큰을 API 클라이언트에 설정
      apiClient.setUserToken(result.data!.token);
      await _saveAuth(result.data!);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.data!.user,
        token: result.data!.token,
        expiresAt: result.data!.expiresAt,
      );

      // Fire-and-forget: 로그인 직후 대회 데이터 Supabase pre-fetch
      ref.read(tournamentPrefetchProvider.notifier).prefetchAll();

      return true;
    } else {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: result.error,
      );
      return false;
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);

    await apiClient.logout();
    await _clearAuth();

    state = AuthState(status: AuthStatus.unauthenticated);
  }

  /// 인증 정보 저장
  Future<void> _saveAuth(LoginResponse loginResponse) async {
    await _storage.write(_authTokenKey, loginResponse.token);
    await _storage.write(_authUserKey, jsonEncode(loginResponse.user.toJson()));
    await _storage.write(_authExpiresKey, loginResponse.expiresAt.toIso8601String());
  }

  /// 인증 정보 삭제
  Future<void> _clearAuth() async {
    await _storage.delete(_authTokenKey);
    await _storage.delete(_authUserKey);
    await _storage.delete(_authExpiresKey);
  }

  /// 사용자 정보 새로고침
  Future<void> refreshUser() async {
    if (!state.isAuthenticated) return;

    final result = await apiClient.getCurrentUser();
    if (result.isSuccess) {
      state = state.copyWith(user: result.data);
      // 사용자 정보 저장 업데이트
      await _storage.write(_authUserKey, jsonEncode(result.data!.toJson()));
    }
  }

  /// 토큰 갱신
  Future<bool> refreshToken() async {
    if (!state.isAuthenticated) return false;

    final result = await apiClient.refreshToken();
    if (result.isSuccess) {
      await _saveAuth(result.data!);
      state = state.copyWith(
        token: result.data!.token,
        expiresAt: result.data!.expiresAt,
        user: result.data!.user,
      );
      return true;
    }
    return false;
  }

  /// [DEV] 개발 모드 - 인증 없이 테스트용 상태 설정
  void setDevMode() {
    debugPrint('🔧 DEV MODE: Setting mock authenticated state');
    state = AuthState(
      status: AuthStatus.authenticated,
      user: UserInfo(
        id: 0,
        email: 'dev@bdr.kr',
        name: '개발자',
      ),
      token: 'dev-token-mock',
      expiresAt: DateTime.now().add(const Duration(days: 365)),
      isDevMode: true,
    );
  }
}

/// 인증 상태 프로바이더
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthNotifier(apiClient: apiClient, secureStorage: secureStorage, ref: ref);
});

/// 인증 여부 프로바이더
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// 현재 사용자 프로바이더
final currentUserProvider = Provider<UserInfo?>((ref) {
  return ref.watch(authProvider).user;
});

/// 내 대회 목록 프로바이더
final myTournamentsProvider = FutureProvider<List<MyTournamentInfo>>((ref) async {
  final authState = ref.watch(authProvider);

  if (!authState.isAuthenticated) {
    return [];
  }

  // DEV 모드: 데모 대회 데이터 반환
  if (authState.isDevMode) {
    debugPrint('🔧 DEV MODE: Returning demo tournaments');
    return _demoTournaments;
  }

  final apiClient = ref.watch(apiClientProvider);
  final result = await apiClient.getMyTournaments();

  if (result.isSuccess) {
    return result.data!;
  } else {
    throw Exception(result.error);
  }
});

/// DEV 모드용 데모 대회 목록
final List<MyTournamentInfo> _demoTournaments = [
  MyTournamentInfo(
    id: 'demo-tournament-001',
    name: '2025 BDR 챔피언십',
    status: 'in_progress',
    format: 'single_elimination',
    startDate: DateTime.now(),
    endDate: DateTime.now().add(const Duration(days: 7)),
    venueName: '서울 체육관',
    teamCount: 8,
    matchCount: 12,
    role: 'admin',
    canEdit: true,
    apiToken: 'demo-token-001',
  ),
  MyTournamentInfo(
    id: 'demo-tournament-002',
    name: '봄맞이 3on3 대회',
    status: 'registration_open',
    format: 'round_robin',
    startDate: DateTime.now().add(const Duration(days: 14)),
    venueName: '부산 실내 체육관',
    teamCount: 16,
    matchCount: 24,
    seriesName: '2025 BDR 시즌',
    role: 'organizer',
    canEdit: true,
    apiToken: 'demo-token-002',
  ),
];

/// 기록 가능한 대회 목록 프로바이더
final recordableTournamentsProvider = Provider<List<MyTournamentInfo>>((ref) {
  final tournamentsAsync = ref.watch(myTournamentsProvider);

  return tournamentsAsync.when(
    data: (tournaments) => tournaments.where((t) => t.canRecord && t.canEdit).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
