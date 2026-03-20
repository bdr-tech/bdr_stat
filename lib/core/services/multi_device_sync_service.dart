// TODO(phase2): This service is not yet integrated.
// Planned for Phase 2 release. Do not call from production code.
// joinSession() is a stub — returns null always. WebSocket layer not implemented.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/database.dart';

/// 멀티 디바이스 동기화 서비스 프로바이더
// TODO(phase2): Provider not registered in main DI. Wire up only after Phase 2 design approval.
final multiDeviceSyncServiceProvider = Provider<MultiDeviceSyncService>((ref) {
  return MultiDeviceSyncService();
});

/// 동기화 상태 프로바이더
final syncStateProvider =
    StateNotifierProvider<SyncStateNotifier, MultiDeviceSyncState>((ref) {
  return SyncStateNotifier(ref);
});

/// 연결된 디바이스 목록 프로바이더
final connectedDevicesProvider = StateProvider<List<ConnectedDevice>>((ref) {
  return [];
});

/// 멀티 디바이스 동기화 서비스
///
/// 기능:
/// - 실시간 경기 데이터 동기화
/// - 디바이스 간 P2P 연결 (WebSocket)
/// - 충돌 해결 (타임스탬프 기반)
/// - 오프라인 지원 및 재연결
///
// TODO(phase2): joinSession() always returns null — stub only.
// TODO(phase2): broadcastEvent() does not transmit over network — stub only.
class MultiDeviceSyncService {
  final _uuidGenerator = const Uuid();

  // 로컬 디바이스 정보
  String? _deviceId;
  String? _deviceName;

  // 동기화 이벤트 스트림
  final _syncEventController = StreamController<SyncEvent>.broadcast();
  Stream<SyncEvent> get syncEvents => _syncEventController.stream;

  // 연결 상태
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// 디바이스 ID 초기화
  Future<String> initializeDevice({String? customName}) async {
    _deviceId ??= _uuidGenerator.v4();
    _deviceName = customName ?? 'Device-${_deviceId!.substring(0, 8)}';
    return _deviceId!;
  }

  /// 동기화 세션 생성 (호스트)
  Future<SyncSession> createSession({
    required int matchId,
    required String matchName,
  }) async {
    final sessionId = _uuidGenerator.v4().substring(0, 8).toUpperCase();

    final session = SyncSession(
      sessionId: sessionId,
      matchId: matchId,
      matchName: matchName,
      hostDeviceId: _deviceId!,
      hostDeviceName: _deviceName!,
      createdAt: DateTime.now(),
      isHost: true,
    );

    debugPrint('[Sync] 세션 생성: $sessionId');

    return session;
  }

  /// 동기화 세션 참여 (게스트)
  Future<SyncSession?> joinSession({
    required String sessionId,
    required String deviceName,
  }) async {
    // TODO: 실제 구현에서는 서버/P2P 연결
    debugPrint('[Sync] 세션 참여 시도: $sessionId');

    // 플레이스홀더 - 실제로는 서버에서 세션 정보 조회
    return null;
  }

  /// 세션 종료
  Future<void> endSession(String sessionId) async {
    debugPrint('[Sync] 세션 종료: $sessionId');
    _isConnected = false;
  }

  /// 데이터 브로드캐스트 (모든 연결된 디바이스에 전송)
  Future<void> broadcastEvent(SyncEvent event) async {
    if (!_isConnected) return;

    _syncEventController.add(event);
    debugPrint('[Sync] 이벤트 브로드캐스트: ${event.type}');

    // TODO: 실제 구현에서는 WebSocket으로 전송
  }

  /// PlayByPlay 이벤트 동기화
  Future<void> syncPlayByPlay(LocalPlayByPlay play) async {
    final event = SyncEvent(
      id: _uuidGenerator.v4(),
      type: SyncEventType.playByPlay,
      timestamp: DateTime.now(),
      deviceId: _deviceId!,
      data: _playByPlayToJson(play),
    );

    await broadcastEvent(event);
  }

  /// 점수 변경 동기화
  Future<void> syncScoreChange({
    required int homeScore,
    required int awayScore,
    required int quarter,
    required int clockSeconds,
  }) async {
    final event = SyncEvent(
      id: _uuidGenerator.v4(),
      type: SyncEventType.scoreChange,
      timestamp: DateTime.now(),
      deviceId: _deviceId!,
      data: {
        'homeScore': homeScore,
        'awayScore': awayScore,
        'quarter': quarter,
        'clockSeconds': clockSeconds,
      },
    );

    await broadcastEvent(event);
  }

  /// 타이머 상태 동기화
  Future<void> syncTimerState({
    required int quarter,
    required int clockSeconds,
    required bool isRunning,
  }) async {
    final event = SyncEvent(
      id: _uuidGenerator.v4(),
      type: SyncEventType.timerUpdate,
      timestamp: DateTime.now(),
      deviceId: _deviceId!,
      data: {
        'quarter': quarter,
        'clockSeconds': clockSeconds,
        'isRunning': isRunning,
      },
    );

    await broadcastEvent(event);
  }

  /// 선수 교체 동기화
  Future<void> syncSubstitution({
    required int teamId,
    required int playerInId,
    required int playerOutId,
  }) async {
    final event = SyncEvent(
      id: _uuidGenerator.v4(),
      type: SyncEventType.substitution,
      timestamp: DateTime.now(),
      deviceId: _deviceId!,
      data: {
        'teamId': teamId,
        'playerInId': playerInId,
        'playerOutId': playerOutId,
      },
    );

    await broadcastEvent(event);
  }

  /// PlayByPlay를 JSON으로 변환
  Map<String, dynamic> _playByPlayToJson(LocalPlayByPlay play) {
    return {
      'id': play.id,
      'localId': play.localId,
      'matchId': play.localMatchId,
      'quarter': play.quarter,
      'clockSeconds': play.gameClockSeconds,
      'teamId': play.tournamentTeamId,
      'playerId': play.tournamentTeamPlayerId,
      'actionType': play.actionType,
      'actionSubtype': play.actionSubtype,
      'isMade': play.isMade,
      'points': play.pointsScored,
      'homeScore': play.homeScoreAtTime,
      'awayScore': play.awayScoreAtTime,
    };
  }

  /// 충돌 해결 (타임스탬프 기반 - 나중 것이 우선)
  SyncEvent resolveConflict(SyncEvent local, SyncEvent remote) {
    if (remote.timestamp.isAfter(local.timestamp)) {
      return remote;
    }
    return local;
  }

  void dispose() {
    _syncEventController.close();
  }
}

/// 동기화 세션 정보
class SyncSession {
  final String sessionId;
  final int matchId;
  final String matchName;
  final String hostDeviceId;
  final String hostDeviceName;
  final DateTime createdAt;
  final bool isHost;

  const SyncSession({
    required this.sessionId,
    required this.matchId,
    required this.matchName,
    required this.hostDeviceId,
    required this.hostDeviceName,
    required this.createdAt,
    required this.isHost,
  });

  /// QR 코드용 데이터
  String toQrData() {
    return jsonEncode({
      'type': 'bdr_sync',
      'sessionId': sessionId,
      'matchId': matchId,
      'matchName': matchName,
      'hostName': hostDeviceName,
    });
  }

  /// QR 코드 데이터에서 생성
  static SyncSession? fromQrData(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      if (json['type'] != 'bdr_sync') return null;

      return SyncSession(
        sessionId: json['sessionId'] as String,
        matchId: json['matchId'] as int,
        matchName: json['matchName'] as String,
        hostDeviceId: '',
        hostDeviceName: json['hostName'] as String,
        createdAt: DateTime.now(),
        isHost: false,
      );
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'matchId': matchId,
        'matchName': matchName,
        'hostDeviceId': hostDeviceId,
        'hostDeviceName': hostDeviceName,
        'createdAt': createdAt.toIso8601String(),
        'isHost': isHost,
      };
}

/// 동기화 이벤트 타입
enum SyncEventType {
  playByPlay, // PlayByPlay 기록
  scoreChange, // 점수 변경
  timerUpdate, // 타이머 업데이트
  substitution, // 선수 교체
  quarterEnd, // 쿼터 종료
  gameEnd, // 경기 종료
  deviceJoined, // 디바이스 참여
  deviceLeft, // 디바이스 이탈
  fullSync, // 전체 동기화 (새 디바이스 참여 시)
}

/// 동기화 이벤트
class SyncEvent {
  final String id;
  final SyncEventType type;
  final DateTime timestamp;
  final String deviceId;
  final Map<String, dynamic> data;
  final bool isProcessed;

  const SyncEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.deviceId,
    required this.data,
    this.isProcessed = false,
  });

  SyncEvent copyWith({
    String? id,
    SyncEventType? type,
    DateTime? timestamp,
    String? deviceId,
    Map<String, dynamic>? data,
    bool? isProcessed,
  }) {
    return SyncEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      deviceId: deviceId ?? this.deviceId,
      data: data ?? this.data,
      isProcessed: isProcessed ?? this.isProcessed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'deviceId': deviceId,
        'data': data,
      };

  factory SyncEvent.fromJson(Map<String, dynamic> json) {
    return SyncEvent(
      id: json['id'] as String,
      type: SyncEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SyncEventType.playByPlay,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      deviceId: json['deviceId'] as String,
      data: json['data'] as Map<String, dynamic>,
    );
  }
}

/// 연결된 디바이스 정보
class ConnectedDevice {
  final String deviceId;
  final String deviceName;
  final DeviceRole role;
  final DateTime connectedAt;
  final bool isActive;

  const ConnectedDevice({
    required this.deviceId,
    required this.deviceName,
    required this.role,
    required this.connectedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'role': role.name,
        'connectedAt': connectedAt.toIso8601String(),
        'isActive': isActive,
      };
}

/// 디바이스 역할
enum DeviceRole {
  host, // 호스트 (메인 기록자)
  recorder, // 보조 기록자
  viewer, // 뷰어 (읽기 전용)
}

/// 동기화 상태
enum SyncStatus {
  disconnected, // 연결 안됨
  connecting, // 연결 중
  connected, // 연결됨
  syncing, // 동기화 중
  error, // 오류
}

/// 멀티 디바이스 동기화 상태 모델
class MultiDeviceSyncState {
  final SyncStatus status;
  final SyncSession? currentSession;
  final List<ConnectedDevice> devices;
  final int pendingEvents;
  final String? errorMessage;
  final DateTime? lastSyncTime;

  const MultiDeviceSyncState({
    this.status = SyncStatus.disconnected,
    this.currentSession,
    this.devices = const [],
    this.pendingEvents = 0,
    this.errorMessage,
    this.lastSyncTime,
  });

  MultiDeviceSyncState copyWith({
    SyncStatus? status,
    SyncSession? currentSession,
    List<ConnectedDevice>? devices,
    int? pendingEvents,
    String? errorMessage,
    DateTime? lastSyncTime,
  }) {
    return MultiDeviceSyncState(
      status: status ?? this.status,
      currentSession: currentSession ?? this.currentSession,
      devices: devices ?? this.devices,
      pendingEvents: pendingEvents ?? this.pendingEvents,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  bool get isConnected => status == SyncStatus.connected;
  bool get isSyncing => status == SyncStatus.syncing;
  bool get hasError => status == SyncStatus.error;
  bool get isHost => currentSession?.isHost ?? false;
  int get deviceCount => devices.length;
}

/// 동기화 상태 관리자
class SyncStateNotifier extends StateNotifier<MultiDeviceSyncState> {
  SyncStateNotifier(this._ref) : super(const MultiDeviceSyncState());

  final Ref _ref;
  StreamSubscription? _eventSubscription;

  /// 동기화 세션 생성 (호스트)
  Future<SyncSession?> createSession({
    required int matchId,
    required String matchName,
  }) async {
    state = state.copyWith(status: SyncStatus.connecting);

    try {
      final service = _ref.read(multiDeviceSyncServiceProvider);
      await service.initializeDevice();

      final session = await service.createSession(
        matchId: matchId,
        matchName: matchName,
      );

      state = state.copyWith(
        status: SyncStatus.connected,
        currentSession: session,
        devices: [
          ConnectedDevice(
            deviceId: session.hostDeviceId,
            deviceName: session.hostDeviceName,
            role: DeviceRole.host,
            connectedAt: DateTime.now(),
          ),
        ],
      );

      _startListening();
      return session;
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// 세션 참여 (게스트)
  Future<bool> joinSession(String sessionId) async {
    state = state.copyWith(status: SyncStatus.connecting);

    try {
      final service = _ref.read(multiDeviceSyncServiceProvider);
      await service.initializeDevice();

      final session = await service.joinSession(
        sessionId: sessionId,
        deviceName: 'Guest',
      );

      if (session == null) {
        state = state.copyWith(
          status: SyncStatus.error,
          errorMessage: '세션을 찾을 수 없습니다',
        );
        return false;
      }

      state = state.copyWith(
        status: SyncStatus.connected,
        currentSession: session,
      );

      _startListening();
      return true;
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// 세션 종료
  Future<void> endSession() async {
    final session = state.currentSession;
    if (session == null) return;

    final service = _ref.read(multiDeviceSyncServiceProvider);
    await service.endSession(session.sessionId);

    await _eventSubscription?.cancel();

    state = const MultiDeviceSyncState();
  }

  /// 이벤트 리스닝 시작
  void _startListening() {
    final service = _ref.read(multiDeviceSyncServiceProvider);

    _eventSubscription = service.syncEvents.listen(
      _handleSyncEvent,
      onError: (error) {
        state = state.copyWith(
          status: SyncStatus.error,
          errorMessage: error.toString(),
        );
      },
    );
  }

  /// 동기화 이벤트 처리
  void _handleSyncEvent(SyncEvent event) {
    debugPrint('[Sync] 이벤트 수신: ${event.type}');

    state = state.copyWith(lastSyncTime: DateTime.now());

    switch (event.type) {
      case SyncEventType.deviceJoined:
        _handleDeviceJoined(event);
        break;
      case SyncEventType.deviceLeft:
        _handleDeviceLeft(event);
        break;
      case SyncEventType.playByPlay:
      case SyncEventType.scoreChange:
      case SyncEventType.timerUpdate:
      case SyncEventType.substitution:
        // 실제 구현에서는 이벤트를 적절한 프로바이더로 전달
        break;
      default:
        break;
    }
  }

  void _handleDeviceJoined(SyncEvent event) {
    final newDevice = ConnectedDevice(
      deviceId: event.data['deviceId'] as String,
      deviceName: event.data['deviceName'] as String,
      role: DeviceRole.recorder,
      connectedAt: DateTime.now(),
    );

    state = state.copyWith(
      devices: [...state.devices, newDevice],
    );
  }

  void _handleDeviceLeft(SyncEvent event) {
    state = state.copyWith(
      devices: state.devices
          .where((d) => d.deviceId != event.data['deviceId'])
          .toList(),
    );
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}
