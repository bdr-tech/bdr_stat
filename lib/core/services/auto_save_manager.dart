import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../di/providers.dart';
import 'app_recovery_service.dart';

/// 자동 저장 상태
enum AutoSaveStatus {
  idle,     // 대기
  saving,   // 저장 중
  saved,    // 저장 완료
  error,    // 오류
}

/// 자동 저장 상태 데이터
class AutoSaveState {
  final AutoSaveStatus status;
  final DateTime? lastSaved;
  final String? errorMessage;
  final int saveCount;

  const AutoSaveState({
    this.status = AutoSaveStatus.idle,
    this.lastSaved,
    this.errorMessage,
    this.saveCount = 0,
  });

  AutoSaveState copyWith({
    AutoSaveStatus? status,
    DateTime? lastSaved,
    String? errorMessage,
    int? saveCount,
  }) {
    return AutoSaveState(
      status: status ?? this.status,
      lastSaved: lastSaved ?? this.lastSaved,
      errorMessage: errorMessage,
      saveCount: saveCount ?? this.saveCount,
    );
  }
}

/// 자동 저장 매니저
/// 경기 기록 중 주기적으로 데이터를 저장하고 복구 상태를 기록
class AutoSaveManager extends StateNotifier<AutoSaveState> {
  AutoSaveManager({
    required this.database,
    required this.recoveryService,
    this.saveInterval = const Duration(seconds: 30),
  }) : super(const AutoSaveState());

  final AppDatabase database;
  final AppRecoveryService recoveryService;
  final Duration saveInterval;

  Timer? _autoSaveTimer;
  int? _currentMatchId;
  bool _isActive = false;

  /// 자동 저장 시작
  void startAutoSave(int matchId) {
    _currentMatchId = matchId;
    _isActive = true;

    // 즉시 한번 저장
    _performAutoSave();

    // 주기적 저장 타이머 시작
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(saveInterval, (_) {
      if (_isActive) {
        _performAutoSave();
      }
    });

    debugPrint('AutoSave started for match $matchId');
  }

  /// 자동 저장 중지
  void stopAutoSave() {
    _isActive = false;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    _currentMatchId = null;

    state = state.copyWith(status: AutoSaveStatus.idle);
    debugPrint('AutoSave stopped');
  }

  /// 수동 저장 트리거
  Future<void> saveNow() async {
    if (_currentMatchId != null) {
      await _performAutoSave();
    }
  }

  /// 자동 저장 수행
  Future<void> _performAutoSave() async {
    if (_currentMatchId == null || !_isActive) return;

    state = state.copyWith(status: AutoSaveStatus.saving);

    try {
      // 1. 복구 상태 업데이트
      await recoveryService.recordActiveMatch(_currentMatchId!);

      // 2. 데이터 무결성 검증 (간단한 검증만)
      final match = await database.matchDao.getMatchById(_currentMatchId!);
      if (match == null) {
        throw Exception('경기 정보를 찾을 수 없습니다.');
      }

      // 3. 경기 업데이트 시간 갱신
      await database.matchDao.touchUpdatedAt(_currentMatchId!);

      // 4. 성공 상태 업데이트
      state = state.copyWith(
        status: AutoSaveStatus.saved,
        lastSaved: DateTime.now(),
        saveCount: state.saveCount + 1,
        errorMessage: null,
      );

      debugPrint('AutoSave completed (count: ${state.saveCount})');
    } catch (e) {
      debugPrint('AutoSave error: $e');
      state = state.copyWith(
        status: AutoSaveStatus.error,
        errorMessage: e.toString(),
      );
    }

    // 3초 후 idle 상태로 복귀
    Future.delayed(const Duration(seconds: 3), () {
      if (state.status == AutoSaveStatus.saved) {
        state = state.copyWith(status: AutoSaveStatus.idle);
      }
    });
  }

  /// 앱 백그라운드 진입 시 호출
  Future<void> onAppBackground() async {
    if (_currentMatchId != null) {
      await _performAutoSave();
    }
  }

  /// 앱 포그라운드 복귀 시 호출
  void onAppForeground() {
    // 타이머가 중지되었다면 재시작
    if (_isActive && _autoSaveTimer == null && _currentMatchId != null) {
      startAutoSave(_currentMatchId!);
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}

/// 자동 저장 매니저 프로바이더
final autoSaveManagerProvider =
    StateNotifierProvider<AutoSaveManager, AutoSaveState>((ref) {
  final database = ref.watch(databaseProvider);
  final recoveryService = ref.watch(appRecoveryServiceProvider);
  return AutoSaveManager(
    database: database,
    recoveryService: recoveryService,
  );
});

/// 자동 저장 상태 인디케이터 위젯용 프로바이더
final autoSaveStatusProvider = Provider<AutoSaveStatus>((ref) {
  return ref.watch(autoSaveManagerProvider).status;
});

/// 마지막 저장 시간 프로바이더
final lastSavedTimeProvider = Provider<DateTime?>((ref) {
  return ref.watch(autoSaveManagerProvider).lastSaved;
});
