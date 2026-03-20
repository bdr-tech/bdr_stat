import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database/database.dart';
import '../data/api/api_client.dart';
import '../domain/models/game_rules_model.dart';
import '../core/utils/sync_manager.dart';
import '../core/services/device_manager.dart';
import '../core/services/event_queue.dart';
import '../core/services/data_refresh_service.dart';
import '../core/services/haptic_service.dart';
import '../core/services/performance_monitor.dart';
import '../core/services/crash_reporter.dart';

/// 데이터베이스 프로바이더
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// API 클라이언트 프로바이더
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Secure Storage 프로바이더
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    // macOS Keychain 설정
    mOptions: MacOsOptions(
      accountName: 'bdr_tournament_recorder',
      groupId: 'com.bdr.tournamentRecorder',
    ),
  );
});

/// 저장된 API 토큰 프로바이더
final savedApiTokenProvider = FutureProvider<String?>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  return storage.read(key: 'api_token');
});

/// 현재 대회 ID 프로바이더
final currentTournamentIdProvider = StateProvider<String?>((ref) => null);

/// 현재 경기 ID 프로바이더
final currentMatchIdProvider = StateProvider<int?>((ref) => null);

// ═══════════════════════════════════════════════════════════════
// DAO Providers
// ═══════════════════════════════════════════════════════════════

final tournamentDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return db.tournamentDao;
});

final matchDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return db.matchDao;
});

final playerStatsDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return db.playerStatsDao;
});

final playByPlayDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return db.playByPlayDao;
});

final editLogDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return db.editLogDao;
});

// ═══════════════════════════════════════════════════════════════
// Game Rules Provider (Sprint 2: FR-006, FR-010)
// ═══════════════════════════════════════════════════════════════

/// 현재 대회의 GameRulesModel 프로바이더
/// 대회 game_rules JSON에서 파싱. 미설정 시 FIBA 기본값으로 폴백.
final gameRulesProvider = FutureProvider<GameRulesModel>((ref) async {
  final tournamentId = ref.watch(currentTournamentIdProvider);
  if (tournamentId == null) return const GameRulesModel();

  final db = ref.watch(databaseProvider);
  final tournament = await db.tournamentDao.getTournamentById(tournamentId);
  if (tournament == null) return const GameRulesModel();

  return GameRulesModel.fromJsonString(tournament.gameRulesJson);
});

/// 팀별 선수 목록 프로바이더
final teamPlayersProvider =
    FutureProvider.family<List<LocalTournamentPlayer>, int>((ref, teamId) async {
  final db = ref.watch(databaseProvider);
  return db.tournamentDao.getPlayersByTeam(teamId);
});

// ═══════════════════════════════════════════════════════════════
// Sync Manager Provider
// ═══════════════════════════════════════════════════════════════

/// EventQueue 프로바이더
final eventQueueProvider = Provider<EventQueue>((ref) {
  final queue = EventQueue();
  // load는 비동기이므로 사용처에서 호출
  return queue;
});

final syncManagerProvider = Provider<SyncManager>((ref) {
  final database = ref.watch(databaseProvider);
  final apiClient = ref.watch(apiClientProvider);
  final deviceManager = ref.watch(deviceManagerProvider);
  final eventQueue = ref.watch(eventQueueProvider);
  return SyncManager(
    database: database,
    apiClient: apiClient,
    deviceManager: deviceManager,
    eventQueue: eventQueue,
  );
});

/// 미동기화 경기 수 프로바이더
final unsyncedMatchCountProvider = FutureProvider<int>((ref) async {
  final syncManager = ref.watch(syncManagerProvider);
  return syncManager.getUnsyncedMatchCount();
});

/// 데이터 새로고침 서비스 프로바이더
final dataRefreshServiceProvider = Provider<DataRefreshService>((ref) {
  final database = ref.watch(databaseProvider);
  final apiClient = ref.watch(apiClientProvider);
  return DataRefreshService(database: database, apiClient: apiClient);
});

// ═══════════════════════════════════════════════════════════════
// Device Manager Provider
// ═══════════════════════════════════════════════════════════════

/// 기기 관리 프로바이더 (싱글톤)
final deviceManagerProvider = Provider<DeviceManager>((ref) {
  return DeviceManager();
});

/// 현재 기기 정보 프로바이더
final currentDeviceProvider = FutureProvider<DeviceInfo>((ref) async {
  final deviceManager = ref.watch(deviceManagerProvider);
  return deviceManager.initialize();
});

/// 기기 ID 프로바이더
final deviceIdProvider = FutureProvider<String>((ref) async {
  final deviceManager = ref.watch(deviceManagerProvider);
  return deviceManager.getDeviceId();
});

// ═══════════════════════════════════════════════════════════════
// Haptic Service Provider
// ═══════════════════════════════════════════════════════════════

/// 햅틱 피드백 서비스 프로바이더
final hapticServiceProvider = Provider<HapticService>((ref) {
  return HapticService.instance;
});

/// 햅틱 피드백 활성화 상태 프로바이더
final hapticEnabledProvider = StateProvider<bool>((ref) => true);

// ═══════════════════════════════════════════════════════════════
// Performance Monitor Provider
// ═══════════════════════════════════════════════════════════════

/// 성능 모니터링 서비스 프로바이더
final performanceMonitorProvider = Provider<PerformanceMonitor>((ref) {
  return PerformanceMonitor.instance;
});

// ═══════════════════════════════════════════════════════════════
// Crash Reporter Provider
// ═══════════════════════════════════════════════════════════════

/// 크래시 리포팅 서비스 프로바이더
final crashReporterProvider = Provider<LocalCrashReporter>((ref) {
  return LocalCrashReporter.instance;
});

// ═══════════════════════════════════════════════════════════════
// Theme Providers
// ═══════════════════════════════════════════════════════════════

/// 테마 모드 프로바이더 (시스템 연동)
/// ThemeMode.system: 시스템 설정 따름, ThemeMode.light/dark: 강제 설정
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// ═══════════════════════════════════════════════════════════════
// Hand Preference Provider (왼손/오른손 레이아웃)
// ═══════════════════════════════════════════════════════════════

/// 왼손잡이 모드 프로바이더 (SharedPreferences 지속)
/// true = 왼손잡이 (사이드바가 왼쪽), false = 오른손잡이 (사이드바가 오른쪽, 기본값)
final isLeftHandedProvider = StateNotifierProvider<HandPreferenceNotifier, bool>((ref) {
  return HandPreferenceNotifier();
});

class HandPreferenceNotifier extends StateNotifier<bool> {
  static const _key = 'is_left_handed';

  HandPreferenceNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
