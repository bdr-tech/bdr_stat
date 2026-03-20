import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 기기 정보
class DeviceInfo {
  final String deviceId;
  final String deviceName;
  final String platform;
  final String? model;
  final DateTime registeredAt;
  final DateTime lastActiveAt;

  const DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    this.model,
    required this.registeredAt,
    required this.lastActiveAt,
  });

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'device_name': deviceName,
    'platform': platform,
    'model': model,
    'registered_at': registeredAt.toIso8601String(),
    'last_active_at': lastActiveAt.toIso8601String(),
  };

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
    deviceId: json['device_id'] as String,
    deviceName: json['device_name'] as String,
    platform: json['platform'] as String,
    model: json['model'] as String?,
    registeredAt: DateTime.parse(json['registered_at'] as String),
    lastActiveAt: DateTime.parse(json['last_active_at'] as String),
  );

  DeviceInfo copyWith({
    String? deviceId,
    String? deviceName,
    String? platform,
    String? model,
    DateTime? registeredAt,
    DateTime? lastActiveAt,
  }) {
    return DeviceInfo(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      model: model ?? this.model,
      registeredAt: registeredAt ?? this.registeredAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  String toString() => 'DeviceInfo($deviceName, $platform, $model)';
}

/// 기기 관리 서비스
/// 다중 기기 동기화 시 기기 식별 및 충돌 추적에 사용
class DeviceManager {
  static const String _deviceIdKey = 'bdr_device_id';
  static const String _deviceNameKey = 'bdr_device_name';

  DeviceInfo? _currentDevice;
  DeviceInfo? get currentDevice => _currentDevice;

  /// 기기 초기화 (앱 시작 시 호출)
  Future<DeviceInfo> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // 저장된 기기 ID 확인
    String? deviceId = prefs.getString(_deviceIdKey);
    String? deviceName = prefs.getString(_deviceNameKey);

    // 없으면 새로 생성
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
      debugPrint('[DeviceManager] Generated new device ID: $deviceId');
    }

    // 기기 정보 수집
    final deviceInfo = await _collectDeviceInfo();
    final platform = _getPlatformName();

    // 기기 이름 설정
    if (deviceName == null) {
      deviceName = deviceInfo['name'] as String? ?? '${platform}_device';
      await prefs.setString(_deviceNameKey, deviceName);
    }

    _currentDevice = DeviceInfo(
      deviceId: deviceId,
      deviceName: deviceName,
      platform: platform,
      model: deviceInfo['model'] as String?,
      registeredAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );

    debugPrint('[DeviceManager] Initialized: $_currentDevice');
    return _currentDevice!;
  }

  /// 기기 이름 변경
  Future<void> updateDeviceName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceNameKey, newName);

    if (_currentDevice != null) {
      _currentDevice = _currentDevice!.copyWith(deviceName: newName);
    }
  }

  /// 현재 기기 ID 반환
  Future<String> getDeviceId() async {
    if (_currentDevice != null) {
      return _currentDevice!.deviceId;
    }

    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      await initialize();
      return _currentDevice!.deviceId;
    }

    return deviceId;
  }

  /// 플랫폼 이름 반환
  String _getPlatformName() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// 기기 정보 수집 (기본 정보만)
  Future<Map<String, dynamic>> _collectDeviceInfo() async {
    // 플랫폼 기반 기본 기기 이름 생성
    String name;
    String? model;

    if (Platform.isAndroid) {
      name = 'Android Tablet';
      model = 'Android';
    } else if (Platform.isIOS) {
      name = 'iPad';
      model = 'iOS';
    } else if (Platform.isMacOS) {
      name = 'Mac';
      model = 'macOS';
    } else if (Platform.isWindows) {
      name = 'Windows PC';
      model = 'Windows';
    } else {
      name = 'Device';
      model = null;
    }

    return {
      'name': name,
      'model': model,
    };
  }

  /// 동기화 메타데이터 생성
  Map<String, dynamic> getSyncMetadata() {
    if (_currentDevice == null) {
      return {
        'device_id': 'unknown',
        'synced_at': DateTime.now().toIso8601String(),
      };
    }

    return {
      'device_id': _currentDevice!.deviceId,
      'device_name': _currentDevice!.deviceName,
      'platform': _currentDevice!.platform,
      'synced_at': DateTime.now().toIso8601String(),
    };
  }
}
