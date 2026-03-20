import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/constants/app_constants.dart';

/// 네트워크 상태
enum NetworkStatus {
  connected,    // 연결됨
  disconnected, // 연결 안됨
  checking,     // 확인 중
}

/// 동기화 상태
enum SyncStatus {
  idle,       // 대기
  syncing,    // 동기화 중
  success,    // 성공
  failed,     // 실패
  pending,    // 대기 중 (오프라인)
}

/// 네트워크 및 동기화 상태 데이터
class NetworkState {
  final NetworkStatus networkStatus;
  final SyncStatus syncStatus;
  final int pendingSyncCount;
  final String? lastError;
  final DateTime? lastChecked;

  const NetworkState({
    this.networkStatus = NetworkStatus.checking,
    this.syncStatus = SyncStatus.idle,
    this.pendingSyncCount = 0,
    this.lastError,
    this.lastChecked,
  });

  NetworkState copyWith({
    NetworkStatus? networkStatus,
    SyncStatus? syncStatus,
    int? pendingSyncCount,
    String? lastError,
    DateTime? lastChecked,
  }) {
    return NetworkState(
      networkStatus: networkStatus ?? this.networkStatus,
      syncStatus: syncStatus ?? this.syncStatus,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      lastError: lastError,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  bool get isOnline => networkStatus == NetworkStatus.connected;
  bool get isOffline => networkStatus == NetworkStatus.disconnected;
  bool get hasPendingSync => pendingSyncCount > 0;
}

/// 네트워크 상태 관리 Notifier
class NetworkStatusNotifier extends StateNotifier<NetworkState> {
  NetworkStatusNotifier() : super(const NetworkState()) {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _periodicCheckTimer;

  void _init() {
    // 초기 상태 확인
    _checkConnectivity();

    // 연결 상태 변경 리스너
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results);
    });

    // 주기적 확인
    _periodicCheckTimer = Timer.periodic(
      AppConstants.networkCheckInterval,
      (_) => _checkConnectivity(),
    );
  }

  Future<void> _checkConnectivity() async {
    state = state.copyWith(
      networkStatus: NetworkStatus.checking,
      lastChecked: DateTime.now(),
    );

    try {
      final results = await _connectivity.checkConnectivity();
      await _handleConnectivityChange(results);
    } catch (e) {
      debugPrint('Connectivity check error: $e');
      state = state.copyWith(networkStatus: NetworkStatus.disconnected);
    }
  }

  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    // 연결 타입이 하나라도 있으면 연결됨으로 판단
    final hasConnection = results.any((r) => r != ConnectivityResult.none);

    if (hasConnection) {
      // 실제 인터넷 연결 확인
      final hasInternet = await _checkInternetAccess();

      final wasOffline = state.isOffline;
      state = state.copyWith(
        networkStatus: hasInternet ? NetworkStatus.connected : NetworkStatus.disconnected,
        lastChecked: DateTime.now(),
      );

      // 오프라인에서 온라인으로 복구 시 동기화 트리거 가능
      if (wasOffline && hasInternet && state.hasPendingSync) {
        // 동기화 필요 알림 (실제 동기화는 외부에서 처리)
        debugPrint('Network recovered. Pending sync count: ${state.pendingSyncCount}');
      }
    } else {
      state = state.copyWith(
        networkStatus: NetworkStatus.disconnected,
        lastChecked: DateTime.now(),
      );
    }
  }

  /// 실제 인터넷 접속 가능 여부 확인
  /// DNS lookup으로 빠르게 판단 (TCP/HTTP 연결보다 안정적)
  Future<bool> _checkInternetAccess() async {
    // 1차: API 서버 DNS lookup (가장 가볍고 안정적)
    try {
      final uri = Uri.parse(AppConstants.baseUrl);
      final result = await InternetAddress.lookup(uri.host)
          .timeout(AppConstants.internetAccessTimeout);
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (e) {
      debugPrint('Network check: DNS lookup failed for API server - $e');
    }

    // 2차: google.com DNS lookup (API 서버 DNS 실패 시 폴백)
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(AppConstants.internetAccessTimeout);
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {
      // DNS 실패
    }

    return false;
  }

  /// 수동 연결 확인
  Future<void> checkConnection() async {
    await _checkConnectivity();
  }

  /// 동기화 상태 업데이트
  void updateSyncStatus(SyncStatus status, {String? error}) {
    state = state.copyWith(
      syncStatus: status,
      lastError: error,
    );
  }

  /// 대기 중인 동기화 수 업데이트
  void updatePendingSyncCount(int count) {
    state = state.copyWith(pendingSyncCount: count);
  }

  /// 동기화 실패 기록
  void recordSyncFailure(String error) {
    state = state.copyWith(
      syncStatus: SyncStatus.failed,
      lastError: error,
    );
  }

  /// 동기화 성공 기록
  void recordSyncSuccess() {
    state = state.copyWith(
      syncStatus: SyncStatus.success,
      lastError: null,
      pendingSyncCount: 0,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _periodicCheckTimer?.cancel();
    super.dispose();
  }
}

/// 네트워크 상태 프로바이더
final networkStatusProvider =
    StateNotifierProvider<NetworkStatusNotifier, NetworkState>((ref) {
  return NetworkStatusNotifier();
});

/// 온라인 여부 프로바이더 (간단한 bool 값)
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(networkStatusProvider).isOnline;
});

/// 대기 중인 동기화 수 프로바이더
final pendingSyncCountProvider = Provider<int>((ref) {
  return ref.watch(networkStatusProvider).pendingSyncCount;
});
