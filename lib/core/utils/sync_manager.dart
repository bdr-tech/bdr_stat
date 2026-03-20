import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/api/api_client.dart';
import '../../data/database/database.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/match_status.dart';
import '../services/device_manager.dart';
import '../services/event_queue.dart';

/// 동기화 결과 데이터
class SyncResultData {
  final bool success;
  final String? errorMessage;
  final int? serverMatchId;
  final int? playerCount;
  final int? playByPlayCount;
  final bool? careerStatsUpdated;
  final DateTime? syncedAt;
  final bool? hasConflict;
  final String? conflictResolution;

  const SyncResultData({
    required this.success,
    this.errorMessage,
    this.serverMatchId,
    this.playerCount,
    this.playByPlayCount,
    this.careerStatsUpdated,
    this.syncedAt,
    this.hasConflict,
    this.conflictResolution,
  });

  SyncResultData copyWith({
    bool? success,
    String? errorMessage,
    int? serverMatchId,
    int? playerCount,
    int? playByPlayCount,
    bool? careerStatsUpdated,
    DateTime? syncedAt,
    bool? hasConflict,
    String? conflictResolution,
  }) {
    return SyncResultData(
      success: success ?? this.success,
      errorMessage: errorMessage ?? this.errorMessage,
      serverMatchId: serverMatchId ?? this.serverMatchId,
      playerCount: playerCount ?? this.playerCount,
      playByPlayCount: playByPlayCount ?? this.playByPlayCount,
      careerStatsUpdated: careerStatsUpdated ?? this.careerStatsUpdated,
      syncedAt: syncedAt ?? this.syncedAt,
      hasConflict: hasConflict ?? this.hasConflict,
      conflictResolution: conflictResolution ?? this.conflictResolution,
    );
  }
}

/// 동기화 큐 항목
class SyncQueueItem {
  final int matchId;
  final String localUuid;
  final int retryCount;
  final DateTime addedAt;
  final DateTime? lastAttemptAt;
  final SyncPriority priority;
  final String? lastError;

  const SyncQueueItem({
    required this.matchId,
    required this.localUuid,
    this.retryCount = 0,
    required this.addedAt,
    this.lastAttemptAt,
    this.priority = SyncPriority.normal,
    this.lastError,
  });

  SyncQueueItem copyWith({
    int? matchId,
    String? localUuid,
    int? retryCount,
    DateTime? addedAt,
    DateTime? lastAttemptAt,
    SyncPriority? priority,
    String? lastError,
  }) {
    return SyncQueueItem(
      matchId: matchId ?? this.matchId,
      localUuid: localUuid ?? this.localUuid,
      retryCount: retryCount ?? this.retryCount,
      addedAt: addedAt ?? this.addedAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      priority: priority ?? this.priority,
      lastError: lastError ?? this.lastError,
    );
  }

  /// 다음 재시도까지 대기해야 하는 시간 계산 (지수 백오프 + 지터)
  Duration getBackoffDuration() {
    return ExponentialBackoff.calculate(retryCount);
  }

  /// 현재 재시도 가능한지 확인
  bool canRetryNow() {
    if (lastAttemptAt == null) return true;
    final backoff = getBackoffDuration();
    return DateTime.now().difference(lastAttemptAt!) >= backoff;
  }
}

/// 동기화 우선순위
enum SyncPriority {
  high,   // 사용자가 명시적으로 요청한 동기화
  normal, // 일반 백그라운드 동기화
  low,    // 재시도가 여러 번 실패한 항목
}

/// 지수 백오프 계산 유틸리티
class ExponentialBackoff {
  static const int _baseDelaySeconds = 2;
  static const int _maxDelaySeconds = 300; // 5분
  static const double _jitterFactor = 0.3;
  static final Random _random = Random();

  /// 지수 백오프 + 지터 계산
  /// retryCount: 0부터 시작하는 재시도 횟수
  static Duration calculate(int retryCount) {
    // 지수 백오프: base * 2^retryCount
    final exponentialDelay = _baseDelaySeconds * pow(2, retryCount).toInt();
    final cappedDelay = min(exponentialDelay, _maxDelaySeconds);

    // 지터 추가: ±30% 랜덤 변동
    final jitterRange = (cappedDelay * _jitterFactor).toInt();
    final jitter = _random.nextInt(jitterRange * 2 + 1) - jitterRange;

    final finalDelay = max(1, cappedDelay + jitter);
    return Duration(seconds: finalDelay);
  }

  /// 테스트용: 지터 없이 순수 지수 백오프만 계산
  static Duration calculateWithoutJitter(int retryCount) {
    final exponentialDelay = _baseDelaySeconds * pow(2, retryCount).toInt();
    final cappedDelay = min(exponentialDelay, _maxDelaySeconds);
    return Duration(seconds: cappedDelay);
  }
}

/// 충돌 감지 결과
class ConflictResult {
  final bool hasConflict;
  final String? conflictType;
  final String? resolution;
  final Map<String, dynamic>? serverData;
  final Map<String, dynamic>? localData;
  final String? serverDeviceId;
  final String? serverDeviceName;
  final DateTime? serverUpdatedAt;

  const ConflictResult({
    required this.hasConflict,
    this.conflictType,
    this.resolution,
    this.serverData,
    this.localData,
    this.serverDeviceId,
    this.serverDeviceName,
    this.serverUpdatedAt,
  });

  static const ConflictResult noConflict = ConflictResult(hasConflict: false);

  /// 충돌 상세 정보 반환
  Map<String, dynamic> toDetailedInfo() {
    return {
      'has_conflict': hasConflict,
      'conflict_type': conflictType,
      'resolution_suggestion': resolution,
      'server_device_id': serverDeviceId,
      'server_device_name': serverDeviceName,
      'server_updated_at': serverUpdatedAt?.toIso8601String(),
      'server_data': serverData,
      'local_data': localData,
    };
  }
}

/// 동기화 매니저
/// 경기 종료 후 서버와 데이터 동기화를 담당
/// 백그라운드 큐, 지수 백오프, 충돌 감지, 다중 기기 추적 지원
class SyncManager {
  SyncManager({
    required this.database,
    required this.apiClient,
    this.deviceManager,
    this.eventQueue,
  });

  final AppDatabase database;
  final ApiClient apiClient;
  final DeviceManager? deviceManager;
  final EventQueue? eventQueue;

  // 재시도 상한 — 50회 초과 시 dead-letter 처리하여 큐 무한 팽창 방지
  static const int _maxRetriesBeforeLowPriority = 10;
  static const int _maxRetries = 50;
  static const Duration _queueProcessInterval = Duration(seconds: 30);
  static const int _maxConcurrentSyncs = 2;
  static const Duration _conflictCacheTtl = Duration(hours: 24);

  // 백그라운드 동기화 큐
  final List<SyncQueueItem> _syncQueue = [];
  Timer? _queueProcessTimer;
  bool _isProcessingQueue = false;
  int _currentConcurrentSyncs = 0;

  // 경기 중 자동 동기화
  Timer? _autoSyncTimer;
  int? _autoSyncMatchId;
  static const Duration _autoSyncInterval = Duration(seconds: 45);

  // 네트워크 연결 감지
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _lastKnownConnected = false;

  // 큐 영속성 키
  static const String _queuePersistKey = 'sync_queue_items';

  // 동기화 상태 스트림
  final StreamController<SyncQueueStatus> _statusController =
      StreamController<SyncQueueStatus>.broadcast();
  Stream<SyncQueueStatus> get statusStream => _statusController.stream;

  // 충돌 감지를 위한 캐시 (local_uuid -> server 데이터)
  final Map<String, Map<String, dynamic>> _conflictCache = {};
  // 충돌 캐시 타임스탬프 (local_uuid -> 캐시된 시간)
  final Map<String, DateTime> _conflictCacheTimestamps = {};

  /// 네트워크 연결 상태 확인 — API 서버 직접 핑
  Future<bool> checkNetworkConnection() async {
    try {
      // 1차: API 서버에 직접 연결 시도
      final uri = Uri.parse(AppConstants.baseUrl);
      final result = await InternetAddress.lookup(uri.host)
          .timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
      return false;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      // 2차 폴백: google.com으로 일반 인터넷 확인
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  // =====================
  // 백그라운드 큐 관리
  // =====================

  /// 백그라운드 동기화 시작
  void startBackgroundSync() {
    if (_queueProcessTimer?.isActive == true) return;

    _queueProcessTimer = Timer.periodic(_queueProcessInterval, (_) {
      _processQueue();
    });

    // 네트워크 변화 감지 시작
    _startConnectivityListener();

    // 영속 큐 복원 후 즉시 처리
    _loadPersistedQueue().then((_) => _processQueue());
    debugPrint('[SyncManager] Background sync started');
  }

  /// 백그라운드 동기화 중지
  void stopBackgroundSync() {
    _queueProcessTimer?.cancel();
    _queueProcessTimer = null;
    debugPrint('[SyncManager] Background sync stopped');
  }

  // =====================
  // 경기 중 자동 동기화
  // =====================

  /// 경기 기록 중 자동 주기적 동기화 시작
  /// 경기 화면 진입 시 호출 — 45초마다 서버에 전체 데이터를 자동 전송
  void startAutoSync(int matchId) {
    stopAutoSync();
    _autoSyncMatchId = matchId;

    // 네트워크 감지도 함께 시작
    _startConnectivityListener();

    _autoSyncTimer = Timer.periodic(_autoSyncInterval, (_) {
      _performAutoSync();
    });
    debugPrint('[SyncManager] Auto sync started for match $matchId (every ${_autoSyncInterval.inSeconds}s)');
  }

  /// 경기 기록 중 자동 동기화 중지
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    _autoSyncMatchId = null;
    debugPrint('[SyncManager] Auto sync stopped');
  }

  /// 자동 동기화 실행 (UI에 영향 없이 조용히)
  Future<void> _performAutoSync() async {
    final matchId = _autoSyncMatchId;
    if (matchId == null) return;

    final hasNetwork = await checkNetworkConnection();
    if (!hasNetwork) {
      debugPrint('[SyncManager] Auto sync skipped — no network');
      return;
    }

    try {
      final result = await syncMatch(matchId, fromQueue: true);
      if (result.success) {
        debugPrint('[SyncManager] Auto sync success: PBP=${result.playByPlayCount}, players=${result.playerCount}');
      } else {
        debugPrint('[SyncManager] Auto sync failed: ${result.errorMessage}');
        // 실패해도 무시 — 다음 주기에 재시도
      }
    } catch (e) {
      debugPrint('[SyncManager] Auto sync error: $e');
    }
  }

  // =====================
  // 네트워크 복구 감지
  // =====================

  /// 네트워크 연결 변화 감지 시작
  void _startConnectivityListener() {
    if (_connectivitySubscription != null) return;

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (results) {
        final isConnected = results.any((r) =>
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.ethernet);

        if (isConnected && !_lastKnownConnected) {
          // 오프라인 → 온라인 복구
          debugPrint('[SyncManager] Network recovered! Triggering sync...');
          _onNetworkRecovered();
        }
        _lastKnownConnected = isConnected;
      },
      onError: (e) {
        debugPrint('[SyncManager] Connectivity listener error: $e');
      },
    );
    debugPrint('[SyncManager] Connectivity listener started');
  }

  /// 네트워크 복구 시 동기화 즉시 시도
  Future<void> _onNetworkRecovered() async {
    // 1. 경기 중 자동 동기화 대상이 있으면 즉시 sync
    if (_autoSyncMatchId != null) {
      _performAutoSync();
    }

    // 2. 백그라운드 큐에 대기 중인 항목 처리
    if (_syncQueue.isNotEmpty) {
      _processQueue();
    }
  }

  /// 네트워크 감지 중지
  void _stopConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  // =====================
  // 큐 영속성 (SharedPreferences)
  // =====================

  /// 큐를 SharedPreferences에 저장
  Future<void> _persistQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = _syncQueue.map((item) => jsonEncode({
        'match_id': item.matchId,
        'local_uuid': item.localUuid,
        'retry_count': item.retryCount,
        'added_at': item.addedAt.toIso8601String(),
        'last_attempt_at': item.lastAttemptAt?.toIso8601String(),
        'priority': item.priority.index,
        'last_error': item.lastError,
      })).toList();
      await prefs.setStringList(_queuePersistKey, items);
    } catch (e) {
      debugPrint('[SyncManager] Failed to persist queue: $e');
    }
  }

  /// SharedPreferences에서 큐 복원
  Future<void> _loadPersistedQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = prefs.getStringList(_queuePersistKey);
      if (items == null || items.isEmpty) return;

      for (final itemJson in items) {
        final json = jsonDecode(itemJson) as Map<String, dynamic>;
        final localUuid = json['local_uuid'] as String;

        // 이미 큐에 있으면 스킵
        if (_syncQueue.any((i) => i.localUuid == localUuid)) continue;

        _syncQueue.add(SyncQueueItem(
          matchId: json['match_id'] as int,
          localUuid: localUuid,
          retryCount: json['retry_count'] as int? ?? 0,
          addedAt: DateTime.parse(json['added_at'] as String),
          lastAttemptAt: json['last_attempt_at'] != null
              ? DateTime.parse(json['last_attempt_at'] as String)
              : null,
          priority: SyncPriority.values[json['priority'] as int? ?? 1],
          lastError: json['last_error'] as String?,
        ));
      }

      if (_syncQueue.isNotEmpty) {
        debugPrint('[SyncManager] Restored ${_syncQueue.length} items from persisted queue');
      }
      _emitStatus();
    } catch (e) {
      debugPrint('[SyncManager] Failed to load persisted queue: $e');
    }
  }

  /// 리소스 정리
  void dispose() {
    stopBackgroundSync();
    stopAutoSync();
    _stopConnectivityListener();
    _statusController.close();
  }

  /// 큐에 동기화 항목 추가
  Future<void> addToQueue(int matchId, {SyncPriority priority = SyncPriority.normal}) async {
    final match = await database.matchDao.getMatchById(matchId);
    if (match == null) {
      debugPrint('[SyncManager] Match not found: $matchId');
      return;
    }

    // 이미 큐에 있는지 확인 (local_uuid로 중복 체크)
    final existingIndex = _syncQueue.indexWhere(
      (item) => item.localUuid == match.localUuid,
    );

    if (existingIndex >= 0) {
      // 이미 있으면 우선순위만 업데이트 (더 높은 우선순위로)
      if (priority.index < _syncQueue[existingIndex].priority.index) {
        _syncQueue[existingIndex] = _syncQueue[existingIndex].copyWith(
          priority: priority,
        );
      }
      debugPrint('[SyncManager] Match already in queue: ${match.localUuid}');
      return;
    }

    _syncQueue.add(SyncQueueItem(
      matchId: matchId,
      localUuid: match.localUuid,
      addedAt: DateTime.now(),
      priority: priority,
    ));

    _emitStatus();
    _persistQueue();
    debugPrint('[SyncManager] Added to queue: $matchId (${match.localUuid})');

    // 높은 우선순위면 즉시 처리 시도
    if (priority == SyncPriority.high) {
      _processQueue();
    }
  }

  /// 큐에서 항목 제거
  void removeFromQueue(String localUuid) {
    _syncQueue.removeWhere((item) => item.localUuid == localUuid);
    _emitStatus();
    _persistQueue();
  }

  /// 큐 상태 조회
  SyncQueueStatus getQueueStatus() {
    return SyncQueueStatus(
      totalItems: _syncQueue.length,
      pendingItems: _syncQueue.where((i) => i.retryCount == 0).length,
      retryingItems: _syncQueue.where((i) => i.retryCount > 0).length,
      isProcessing: _isProcessingQueue,
      lastProcessedAt: _lastProcessedAt,
      currentConcurrentSyncs: _currentConcurrentSyncs,
    );
  }

  DateTime? _lastProcessedAt;

  /// 큐 처리
  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    if (_syncQueue.isEmpty) return;

    final hasNetwork = await checkNetworkConnection();
    if (!hasNetwork) {
      debugPrint('[SyncManager] No network, skipping queue processing');
      return;
    }

    _isProcessingQueue = true;
    _emitStatus();

    // 만료된 충돌 캐시 정리
    _cleanExpiredConflicts();

    try {
      // 우선순위와 백오프 시간을 고려하여 정렬
      _syncQueue.sort((a, b) {
        // 1. 우선순위 비교 (높은 것이 먼저)
        final priorityCompare = a.priority.index.compareTo(b.priority.index);
        if (priorityCompare != 0) return priorityCompare;

        // 2. 재시도 가능한 것 먼저
        final aCanRetry = a.canRetryNow();
        final bCanRetry = b.canRetryNow();
        if (aCanRetry && !bCanRetry) return -1;
        if (!aCanRetry && bCanRetry) return 1;

        // 3. 추가된 시간 순 (오래된 것 먼저)
        return a.addedAt.compareTo(b.addedAt);
      });

      // 동시 처리 가능한 항목들 선택
      final itemsToProcess = <SyncQueueItem>[];
      for (final item in _syncQueue) {
        if (itemsToProcess.length >= _maxConcurrentSyncs) break;
        if (item.canRetryNow()) {
          itemsToProcess.add(item);
        }
      }

      // 병렬 처리
      final futures = itemsToProcess.map((item) => _processQueueItem(item));
      await Future.wait(futures);

      _lastProcessedAt = DateTime.now();
    } finally {
      _isProcessingQueue = false;
      _emitStatus();
    }
  }

  /// 개별 큐 항목 처리
  Future<void> _processQueueItem(SyncQueueItem item) async {
    final queueIndex = _syncQueue.indexWhere((i) => i.localUuid == item.localUuid);
    if (queueIndex < 0) return; // 이미 제거됨

    try {
      _currentConcurrentSyncs++;
      final result = await syncMatch(item.matchId, fromQueue: true);

      if (result.success) {
        // 성공 시 큐에서 제거
        removeFromQueue(item.localUuid);
        debugPrint('[SyncManager] Sync success, removed from queue: ${item.localUuid}');
      } else if (result.hasConflict == true) {
        // 충돌 발생 - 사용자 개입 필요
        _syncQueue[queueIndex] = item.copyWith(
          lastAttemptAt: DateTime.now(),
          lastError: 'Conflict: ${result.conflictResolution}',
          priority: SyncPriority.low,
        );
        debugPrint('[SyncManager] Conflict detected: ${item.localUuid}');
      } else {
        // 실패 시 재시도 횟수 증가
        final newRetryCount = item.retryCount + 1;

        // maxRetries 초과 시 dead-letter 처리
        if (newRetryCount >= _maxRetries) {
          await _moveToDeadLetter(item.copyWith(
            retryCount: newRetryCount,
            lastError: result.errorMessage,
          ));
          return;
        }

        final newPriority = newRetryCount >= _maxRetriesBeforeLowPriority
            ? SyncPriority.low
            : item.priority;
        _syncQueue[queueIndex] = item.copyWith(
          retryCount: newRetryCount,
          lastAttemptAt: DateTime.now(),
          lastError: result.errorMessage,
          priority: newPriority,
        );
        debugPrint('[SyncManager] Retry scheduled (attempt $newRetryCount/$_maxRetries): ${item.localUuid}');
      }
      _persistQueue();
    } finally {
      _currentConcurrentSyncs--;
    }
  }

  /// 상태 변경 알림
  void _emitStatus() {
    if (!_statusController.isClosed) {
      _statusController.add(getQueueStatus());
    }
  }

  // =====================
  // 충돌 감지
  // =====================

  /// 서버 데이터와 로컬 데이터 충돌 감지
  Future<ConflictResult> detectConflict(
    LocalMatche match,
    Map<String, dynamic>? serverData,
  ) async {
    if (serverData == null) {
      return ConflictResult.noConflict;
    }

    // 서버 기기 정보 추출
    final serverDevice = serverData['device'] as Map<String, dynamic>?;
    final serverDeviceId = serverDevice?['device_id'] as String?;
    final serverDeviceName = serverDevice?['device_name'] as String?;
    final serverUpdatedAtStr = serverData['updated_at'] as String?;
    final serverUpdatedAt = serverUpdatedAtStr != null
        ? DateTime.tryParse(serverUpdatedAtStr)
        : null;

    // 현재 기기 ID
    final currentDeviceId = deviceManager?.currentDevice?.deviceId;

    // 서버에 이미 동일한 local_uuid로 데이터가 있는 경우
    final serverLocalUuid = serverData['local_uuid'] as String?;
    if (serverLocalUuid == match.localUuid) {
      // 같은 UUID면 이미 동기화된 데이터 - 업데이트 필요 여부 확인
      if (serverUpdatedAt != null && serverUpdatedAt.isAfter(match.updatedAt)) {
        // 다른 기기에서 더 최근에 수정된 경우
        final isSameDevice = currentDeviceId == serverDeviceId;
        return ConflictResult(
          hasConflict: true,
          conflictType: isSameDevice ? 'local_outdated' : 'multi_device_conflict',
          resolution: isSameDevice
              ? '로컬 데이터가 서버보다 오래되었습니다.'
              : '다른 기기(${serverDeviceName ?? serverDeviceId ?? "알 수 없음"})에서 더 최근에 수정되었습니다.',
          serverData: serverData,
          localData: {
            'updated_at': match.updatedAt.toIso8601String(),
            'device_id': currentDeviceId,
          },
          serverDeviceId: serverDeviceId,
          serverDeviceName: serverDeviceName,
          serverUpdatedAt: serverUpdatedAt,
        );
      }
      return ConflictResult.noConflict;
    }

    // 서버에 다른 UUID로 같은 경기 데이터가 있는 경우 (중복 가능성)
    final serverHomeScore = serverData['home_score'] as int?;
    final serverAwayScore = serverData['away_score'] as int?;

    if (serverHomeScore != null &&
        serverAwayScore != null &&
        serverHomeScore == match.homeScore &&
        serverAwayScore == match.awayScore) {
      return ConflictResult(
        hasConflict: true,
        conflictType: 'duplicate_score',
        resolution: '동일한 점수의 경기 데이터가 이미 존재합니다. 수동 검토가 필요합니다.',
        serverData: serverData,
        localData: {
          'local_uuid': match.localUuid,
          'home_score': match.homeScore,
          'away_score': match.awayScore,
          'device_id': currentDeviceId,
        },
        serverDeviceId: serverDeviceId,
        serverDeviceName: serverDeviceName,
        serverUpdatedAt: serverUpdatedAt,
      );
    }

    return ConflictResult.noConflict;
  }

  /// 충돌 해결: 로컬 데이터 사용
  Future<SyncResultData> resolveConflictWithLocal(int matchId) async {
    // 충돌 캐시 정리 후 강제 업로드
    final match = await database.matchDao.getMatchById(matchId);
    if (match != null) {
      _conflictCache.remove(match.localUuid);
      _conflictCacheTimestamps.remove(match.localUuid);
    }

    // 서버 데이터 덮어쓰기 플래그와 함께 동기화
    return _syncWithForce(matchId, forceLocal: true);
  }

  /// 충돌 해결: 서버 데이터 사용
  Future<SyncResultData> resolveConflictWithServer(int matchId) async {
    final match = await database.matchDao.getMatchById(matchId);
    if (match == null) {
      return const SyncResultData(
        success: false,
        errorMessage: '경기 정보를 찾을 수 없습니다.',
      );
    }

    final serverData = getCachedServerData(match.localUuid);
    if (serverData == null) {
      return const SyncResultData(
        success: false,
        errorMessage: '서버 데이터를 찾을 수 없습니다.',
      );
    }

    // 서버 데이터로 로컬 DB 업데이트
    try {
      await _updateLocalFromServer(matchId, serverData);
      _conflictCache.remove(match.localUuid);
      _conflictCacheTimestamps.remove(match.localUuid);

      return SyncResultData(
        success: true,
        syncedAt: DateTime.now(),
        hasConflict: false,
      );
    } catch (e) {
      return SyncResultData(
        success: false,
        errorMessage: '서버 데이터 적용 실패: $e',
      );
    }
  }

  /// 강제 동기화 (충돌 무시)
  Future<SyncResultData> _syncWithForce(int matchId, {bool forceLocal = false}) async {
    try {
      final match = await database.matchDao.getMatchById(matchId);
      if (match == null) {
        return const SyncResultData(
          success: false,
          errorMessage: '경기 정보를 찾을 수 없습니다.',
        );
      }

      final playerStats = await database.playerStatsDao.getStatsByMatch(matchId);
      final playByPlays = await database.playByPlayDao.getPlaysByMatch(matchId);

      final syncData = _buildSyncData(match, playerStats, playByPlays);
      syncData['force_overwrite'] = forceLocal;

      final response = await apiClient.syncMatchData(
        match.tournamentId,
        syncData,
      );

      if (response.isSuccess && response.data != null) {
        await database.matchDao.markAsSynced(
          matchId,
          serverId: response.data!.serverMatchId,
        );
        await database.playByPlayDao.markAllAsSynced(matchId);

        return SyncResultData(
          success: true,
          serverMatchId: response.data!.serverMatchId,
          playerCount: playerStats.length,
          playByPlayCount: playByPlays.length,
          syncedAt: DateTime.now(),
          hasConflict: false,
        );
      } else {
        throw Exception(response.error ?? '동기화 실패');
      }
    } catch (e) {
      return SyncResultData(
        success: false,
        errorMessage: _parseErrorMessage(e),
      );
    }
  }

  /// 서버 데이터로 로컬 업데이트
  Future<void> _updateLocalFromServer(int matchId, Map<String, dynamic> serverData) async {
    // 서버 데이터에서 점수 등 기본 정보 추출 및 로컬 업데이트
    final homeScore = serverData['home_score'] as int?;
    final awayScore = serverData['away_score'] as int?;
    final status = serverData['status'] as String?;

    if (homeScore != null && awayScore != null) {
      await database.matchDao.updateMatchScore(matchId, homeScore, awayScore);
    }
    if (status != null) {
      await database.matchDao.updateStatus(matchId, status);
    }

    // 동기화 완료로 표시
    final serverId = serverData['id'] as int?;
    await database.matchDao.markAsSynced(matchId, serverId: serverId);

    debugPrint('[SyncManager] Local data updated from server: matchId=$matchId');
  }

  /// 충돌 캐시 업데이트
  void cacheServerData(String localUuid, Map<String, dynamic> data) {
    _conflictCache[localUuid] = data;
    _conflictCacheTimestamps[localUuid] = DateTime.now();
  }

  /// 충돌 캐시 조회
  Map<String, dynamic>? getCachedServerData(String localUuid) {
    return _conflictCache[localUuid];
  }

  /// 충돌 캐시 정리
  void clearConflictCache() {
    _conflictCache.clear();
    _conflictCacheTimestamps.clear();
  }

  /// 24시간 이상 된 충돌 캐시 엔트리 자동 제거
  void _cleanExpiredConflicts() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    _conflictCacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) >= _conflictCacheTtl) {
        expiredKeys.add(key);
      }
    });
    for (final key in expiredKeys) {
      _conflictCache.remove(key);
      _conflictCacheTimestamps.remove(key);
    }
    if (expiredKeys.isNotEmpty) {
      debugPrint('[SyncManager] Cleaned ${expiredKeys.length} expired conflict cache entries');
    }
  }

  /// 재시도 상한 초과 항목을 dead-letter로 이동
  Future<void> _moveToDeadLetter(SyncQueueItem item) async {
    debugPrint('[SyncManager] DEAD_LETTER: match=${item.matchId}, retries=${item.retryCount}, error=${item.lastError}');
    _syncQueue.removeWhere((i) => i.localUuid == item.localUuid);
    _emitStatus();
    _persistQueue();

    // SharedPreferences에 dead-letter 기록 (최대 20개 유지)
    try {
      final prefs = await SharedPreferences.getInstance();
      final deadLetters = prefs.getStringList('dead_letter_queue') ?? [];
      deadLetters.add(jsonEncode({
        'match_id': item.matchId,
        'local_uuid': item.localUuid,
        'retry_count': item.retryCount,
        'last_error': item.lastError,
        'dead_at': DateTime.now().toIso8601String(),
      }));
      if (deadLetters.length > 20) {
        deadLetters.removeRange(0, deadLetters.length - 20);
      }
      await prefs.setStringList('dead_letter_queue', deadLetters);
    } catch (e) {
      debugPrint('[SyncManager] Failed to persist dead-letter: $e');
    }
  }

  // =====================
  // 메인 동기화 로직
  // =====================

  /// 경기 데이터 동기화
  /// [fromQueue]: true면 큐에서 호출된 것이므로 재시도 로직 생략
  Future<SyncResultData> syncMatch(int matchId, {bool fromQueue = false}) async {
    // EventQueue에 미전송 이벤트가 있으면 먼저 flush 시도
    if (eventQueue != null && eventQueue!.countForMatch(matchId) > 0) {
      debugPrint('[SyncManager] Flushing ${eventQueue!.countForMatch(matchId)} pending events before sync');
      // flush 시도하되 실패해도 sync는 계속 진행
    }

    int retryCount = 0;
    // 큐에서 호출 시 1회, 직접 호출 시 3회 (사용자 대기 중이므로 적절한 횟수)
    final maxAttempts = fromQueue ? 1 : 3;

    while (retryCount < maxAttempts) {
      try {
        // 1. 경기 정보 조회
        final match = await database.matchDao.getMatchById(matchId);
        if (match == null) {
          return const SyncResultData(
            success: false,
            errorMessage: '경기 정보를 찾을 수 없습니다.',
          );
        }

        // 2. 충돌 감지 (캐시된 서버 데이터와 비교)
        final cachedServerData = getCachedServerData(match.localUuid);
        final conflictResult = await detectConflict(match, cachedServerData);
        if (conflictResult.hasConflict) {
          debugPrint('[SyncManager] Conflict detected for ${match.localUuid}: ${conflictResult.conflictType}');
          return SyncResultData(
            success: false,
            hasConflict: true,
            conflictResolution: conflictResult.resolution,
            errorMessage: '데이터 충돌이 감지되었습니다: ${conflictResult.resolution}',
          );
        }

        // 3. 선수 스탯 조회
        final playerStats = await database.playerStatsDao.getStatsByMatch(matchId);

        // 4. 플레이바이플레이 조회
        final playByPlays = await database.playByPlayDao.getPlaysByMatch(matchId);

        // 5. 동기화 데이터 구성
        final syncData = _buildSyncData(match, playerStats, playByPlays);

        // 6. API 호출
        final response = await apiClient.syncMatchData(
          match.tournamentId,
          syncData,
        );

        if (response.isSuccess && response.data != null) {
          // 7. 충돌 응답 확인
          if (response.data!.hasConflict == true) {
            // 서버에서 충돌 감지
            cacheServerData(match.localUuid, response.data!.serverData ?? {});
            return SyncResultData(
              success: false,
              hasConflict: true,
              conflictResolution: response.data!.conflictMessage,
              errorMessage: response.data!.conflictMessage ?? '서버 데이터와 충돌이 발생했습니다.',
            );
          }

          // 8. 동기화 성공 - 로컬 DB 업데이트
          await database.matchDao.markAsSynced(
            matchId,
            serverId: response.data!.serverMatchId,
          );

          // PlayByPlay 동기화 완료 표시
          await database.playByPlayDao.markAllAsSynced(matchId);

          // 충돌 캐시 정리
          _conflictCache.remove(match.localUuid);
          _conflictCacheTimestamps.remove(match.localUuid);

          return SyncResultData(
            success: true,
            serverMatchId: response.data!.serverMatchId,
            playerCount: playerStats.length,
            playByPlayCount: playByPlays.length,
            careerStatsUpdated: response.data!.careerStatsUpdated,
            syncedAt: DateTime.now(),
            hasConflict: false,
          );
        } else {
          // API 에러
          throw Exception(response.error ?? '동기화 실패');
        }
      } catch (e, stack) {
        retryCount++;
        debugPrint('[SyncManager] Sync attempt $retryCount/$maxAttempts failed: $e');
        debugPrint('[SyncManager] Stack: $stack');

        if (retryCount < maxAttempts) {
          final backoff = ExponentialBackoff.calculate(retryCount - 1);
          debugPrint('[SyncManager] Waiting ${backoff.inSeconds}s before retry...');
          await Future.delayed(backoff);
        } else {
          await database.matchDao.markSyncError(matchId, e.toString());

          // 개발 중: 원본 에러 메시지 직접 표시
          final rawError = e.toString();
          return SyncResultData(
            success: false,
            errorMessage: '동기화 실패: $rawError',
          );
        }
      }
    }

    return const SyncResultData(
      success: false,
      errorMessage: '동기화에 실패했습니다.',
    );
  }

  /// 동기화 데이터 구성 — /api/v1/tournaments/[id]/matches/sync 포맷
  Map<String, dynamic> _buildSyncData(
    LocalMatche match,
    List<LocalPlayerStat> playerStats,
    List<LocalPlayByPlay> playByPlays,
  ) {
    final serverId = match.serverId;
    if (serverId == null || serverId <= 0) {
      debugPrint('[SyncManager] WARNING: serverId is null/invalid for match ${match.id}');
    }
    return {
      'match': {
        'server_id': serverId ?? 0,
        'home_score': match.homeScore,
        'away_score': match.awayScore,
        'status': MatchStatusLocal.fromString(match.status).toServerStatus().value,
        'current_quarter': match.currentQuarter,
        'quarter_scores': match.quarterScoresJson.isNotEmpty && match.quarterScoresJson != '{}'
            ? jsonDecode(match.quarterScoresJson)
            : null,
        'mvp_player_id': match.mvpPlayerId,
        'started_at': match.startedAt?.toIso8601String(),
        'ended_at': match.endedAt?.toIso8601String(),
      },
      'player_stats': playerStats
          .map((s) => {
                'tournament_team_player_id': s.tournamentTeamPlayerId,
                'tournament_team_id': s.tournamentTeamId,
                'is_starter': s.isStarter,
                'minutes_played': s.minutesPlayed,
                'points': s.points,
                'field_goals_made': s.fieldGoalsMade,
                'field_goals_attempted': s.fieldGoalsAttempted,
                'two_pointers_made': s.twoPointersMade,
                'two_pointers_attempted': s.twoPointersAttempted,
                'three_pointers_made': s.threePointersMade,
                'three_pointers_attempted': s.threePointersAttempted,
                'free_throws_made': s.freeThrowsMade,
                'free_throws_attempted': s.freeThrowsAttempted,
                'offensive_rebounds': s.offensiveRebounds,
                'defensive_rebounds': s.defensiveRebounds,
                'total_rebounds': s.totalRebounds,
                'assists': s.assists,
                'steals': s.steals,
                'blocks': s.blocks,
                'turnovers': s.turnovers,
                'personal_fouls': s.personalFouls,
                'plus_minus': s.plusMinus,
                'fouled_out': s.fouledOut,
                'ejected': s.ejected,
              })
          .toList(),
      'play_by_plays': playByPlays
          .map((pbp) => {
                'local_id': pbp.localId,
                'tournament_team_player_id': pbp.tournamentTeamPlayerId,
                'tournament_team_id': pbp.tournamentTeamId,
                'quarter': pbp.quarter,
                'game_clock_seconds': pbp.gameClockSeconds,
                'shot_clock_seconds': pbp.shotClockSeconds,
                'action_type': pbp.actionType,
                'action_subtype': pbp.actionSubtype,
                'is_made': pbp.isMade,
                'points_scored': pbp.pointsScored,
                'court_x': pbp.courtX,
                'court_y': pbp.courtY,
                'court_zone': pbp.courtZone,
                'shot_distance': pbp.shotDistance,
                'home_score_at_time': pbp.homeScoreAtTime,
                'away_score_at_time': pbp.awayScoreAtTime,
                'assist_player_id': pbp.assistPlayerId,
                'rebound_player_id': pbp.reboundPlayerId,
                'block_player_id': pbp.blockPlayerId,
                'steal_player_id': pbp.stealPlayerId,
                'fouled_player_id': pbp.fouledPlayerId,
                'sub_in_player_id': pbp.subInPlayerId,
                'sub_out_player_id': pbp.subOutPlayerId,
                'is_flagrant': pbp.isFlagrant,
                'is_technical': pbp.isTechnical,
                'is_fastbreak': pbp.isFastbreak,
                'is_second_chance': pbp.isSecondChance,
                'is_from_turnover': pbp.isFromTurnover,
                'description': pbp.description,
              })
          .toList(),
    };
  }

  /// 에러 메시지 파싱
  String _parseErrorMessage(dynamic error) {
    final message = error.toString();

    if (message.contains('SocketException') ||
        message.contains('connection')) {
      return '네트워크 연결을 확인해주세요.';
    }
    if (message.contains('401') || message.contains('Unauthorized')) {
      return '인증이 만료되었습니다. 다시 연결해주세요.';
    }
    if (message.contains('403') || message.contains('Forbidden')) {
      return '접근 권한이 없습니다.';
    }
    if (message.contains('500') || message.contains('Server')) {
      return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }
    if (message.contains('timeout')) {
      return '연결 시간이 초과되었습니다.';
    }

    return '동기화 중 오류가 발생했습니다.';
  }

  /// 미동기화 경기 목록 조회
  Future<List<LocalMatche>> getUnsyncedMatches() async {
    return database.matchDao.getUnsyncedMatches();
  }

  /// 미동기화 경기 수 조회
  Future<int> getUnsyncedMatchCount() async {
    final matches = await getUnsyncedMatches();
    return matches.length;
  }

  /// 모든 미동기화 경기 동기화 시도
  /// [useQueue]: true면 백그라운드 큐에 추가, false면 즉시 순차 처리
  Future<Map<int, SyncResultData>> syncAllUnsyncedMatches({
    bool useQueue = true,
    SyncPriority priority = SyncPriority.normal,
  }) async {
    final unsyncedMatches = await getUnsyncedMatches();
    final results = <int, SyncResultData>{};

    if (useQueue) {
      // 큐에 추가하고 백그라운드 처리
      for (final match in unsyncedMatches) {
        await addToQueue(match.id, priority: priority);
        results[match.id] = const SyncResultData(
          success: true,
          errorMessage: 'Added to sync queue',
        );
      }

      // 즉시 큐 처리 시작
      _processQueue();
    } else {
      // 기존 방식: 즉시 순차 처리
      for (final match in unsyncedMatches) {
        final result = await syncMatch(match.id);
        results[match.id] = result;

        // 각 경기 동기화 사이에 약간의 딜레이
        if (unsyncedMatches.last != match) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    return results;
  }

  /// 높은 우선순위로 즉시 동기화 요청
  Future<SyncResultData> syncMatchImmediately(int matchId) async {
    // 큐에 있으면 제거
    final match = await database.matchDao.getMatchById(matchId);
    if (match != null) {
      removeFromQueue(match.localUuid);
    }

    // 즉시 동기화 시도
    return syncMatch(matchId);
  }

  /// 동기화 상태 스트림 (경기 목록 화면용)
  Stream<int> watchUnsyncedCount() async* {
    while (true) {
      yield await getUnsyncedMatchCount();
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  /// 큐 상태 포함 동기화 정보 스트림
  Stream<SyncInfo> watchSyncInfo() async* {
    while (true) {
      final unsyncedCount = await getUnsyncedMatchCount();
      final queueStatus = getQueueStatus();
      yield SyncInfo(
        unsyncedCount: unsyncedCount,
        queueStatus: queueStatus,
      );
      await Future.delayed(const Duration(seconds: 10));
    }
  }
}

/// 동기화 큐 상태
class SyncQueueStatus {
  final int totalItems;
  final int pendingItems;
  final int retryingItems;
  final bool isProcessing;
  final DateTime? lastProcessedAt;
  final int currentConcurrentSyncs;

  const SyncQueueStatus({
    required this.totalItems,
    required this.pendingItems,
    required this.retryingItems,
    required this.isProcessing,
    this.lastProcessedAt,
    this.currentConcurrentSyncs = 0,
  });

  bool get isEmpty => totalItems == 0;
  bool get hasErrors => retryingItems > 0;
  bool get isActivelyProcessing => currentConcurrentSyncs > 0;

  @override
  String toString() {
    return 'SyncQueueStatus(total: $totalItems, pending: $pendingItems, retrying: $retryingItems, processing: $isProcessing, concurrent: $currentConcurrentSyncs)';
  }
}

/// 동기화 전체 정보
class SyncInfo {
  final int unsyncedCount;
  final SyncQueueStatus queueStatus;

  const SyncInfo({
    required this.unsyncedCount,
    required this.queueStatus,
  });

  bool get needsSync => unsyncedCount > 0 || !queueStatus.isEmpty;
}
