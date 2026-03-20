import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// 성능 메트릭 타입
enum MetricType {
  dbRead,
  dbWrite,
  uiRender,
  networkRequest,
  stateUpdate,
  other,
}

/// 단일 성능 측정 결과
class PerformanceMetric {
  final String name;
  final MetricType type;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PerformanceMetric({
    required this.name,
    required this.type,
    required this.duration,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isSlowOperation {
    switch (type) {
      case MetricType.dbRead:
        return duration.inMilliseconds > 100;
      case MetricType.dbWrite:
        return duration.inMilliseconds > 200;
      case MetricType.uiRender:
        return duration.inMilliseconds > 16; // 60fps = 16ms
      case MetricType.networkRequest:
        return duration.inMilliseconds > 3000;
      case MetricType.stateUpdate:
        return duration.inMilliseconds > 50;
      case MetricType.other:
        return duration.inMilliseconds > 500;
    }
  }

  @override
  String toString() =>
      'PerformanceMetric($name, ${type.name}, ${duration.inMilliseconds}ms)';
}

/// 프레임 레이트 정보
class FrameRateInfo {
  final double fps;
  final int droppedFrames;
  final int totalFrames;
  final DateTime timestamp;

  FrameRateInfo({
    required this.fps,
    required this.droppedFrames,
    required this.totalFrames,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isJanky => fps < 55 || droppedFrames > 0;
}

/// 성능 모니터링 서비스
///
/// 앱의 성능 지표를 추적하고 분석합니다.
/// - DB 작업 시간
/// - UI 프레임 레이트
/// - 느린 작업 감지
class PerformanceMonitor {
  static final PerformanceMonitor instance = PerformanceMonitor._();

  PerformanceMonitor._();

  // 설정
  bool _isEnabled = kDebugMode;
  bool logSlowOperations = true;
  final int _maxMetricHistory = 100;

  // 메트릭 저장소
  final Queue<PerformanceMetric> _recentMetrics = Queue();
  final Map<MetricType, List<Duration>> _metricsByType = {};
  final List<FrameRateInfo> _frameRateHistory = [];

  // 프레임 레이트 추적
  int _frameCount = 0;
  int _droppedFrames = 0;
  DateTime? _lastFrameRateUpdate;
  SchedulerBinding? _schedulerBinding;

  // 통계
  int _totalOperations = 0;
  int _slowOperations = 0;

  /// 모니터링 활성화
  bool get isEnabled => _isEnabled;
  set isEnabled(bool value) {
    _isEnabled = value;
    if (value) {
      _startFrameTracking();
    } else {
      _stopFrameTracking();
    }
  }

  /// 프레임 레이트 추적 시작
  void _startFrameTracking() {
    _schedulerBinding = SchedulerBinding.instance;
    _lastFrameRateUpdate = DateTime.now();
    _frameCount = 0;
    _droppedFrames = 0;

    _schedulerBinding?.addTimingsCallback(_onFrameCallback);
  }

  /// 프레임 레이트 추적 중지
  void _stopFrameTracking() {
    _schedulerBinding?.removeTimingsCallback(_onFrameCallback);
  }

  /// 프레임 콜백
  void _onFrameCallback(List<FrameTiming> timings) {
    for (final timing in timings) {
      _frameCount++;

      // 16ms (60fps) 초과 시 드롭 프레임으로 간주
      final buildTime = timing.buildDuration.inMilliseconds;
      final rasterTime = timing.rasterDuration.inMilliseconds;
      if (buildTime + rasterTime > 16) {
        _droppedFrames++;
      }
    }

    // 1초마다 FPS 계산
    final now = DateTime.now();
    if (_lastFrameRateUpdate != null &&
        now.difference(_lastFrameRateUpdate!).inSeconds >= 1) {
      _recordFrameRate();
      _lastFrameRateUpdate = now;
      _frameCount = 0;
      _droppedFrames = 0;
    }
  }

  /// FPS 기록
  void _recordFrameRate() {
    if (_frameCount == 0) return;

    final fps = _frameCount.toDouble();
    final info = FrameRateInfo(
      fps: fps,
      droppedFrames: _droppedFrames,
      totalFrames: _frameCount,
    );

    _frameRateHistory.add(info);

    // 최근 60개만 유지 (1분)
    while (_frameRateHistory.length > 60) {
      _frameRateHistory.removeAt(0);
    }

    if (info.isJanky && logSlowOperations) {
      developer.log(
        '⚠️ Low FPS detected: ${fps.toStringAsFixed(1)} FPS, $_droppedFrames dropped',
        name: 'PerformanceMonitor',
      );
    }
  }

  /// 작업 시간 측정 (동기)
  T measure<T>(
    String name,
    MetricType type,
    T Function() operation, {
    Map<String, dynamic>? metadata,
  }) {
    if (!_isEnabled) return operation();

    final stopwatch = Stopwatch()..start();
    try {
      return operation();
    } finally {
      stopwatch.stop();
      _recordMetric(name, type, stopwatch.elapsed, metadata);
    }
  }

  /// 작업 시간 측정 (비동기)
  Future<T> measureAsync<T>(
    String name,
    MetricType type,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isEnabled) return operation();

    final stopwatch = Stopwatch()..start();
    try {
      return await operation();
    } finally {
      stopwatch.stop();
      _recordMetric(name, type, stopwatch.elapsed, metadata);
    }
  }

  /// 메트릭 기록
  void _recordMetric(
    String name,
    MetricType type,
    Duration duration,
    Map<String, dynamic>? metadata,
  ) {
    final metric = PerformanceMetric(
      name: name,
      type: type,
      duration: duration,
      metadata: metadata,
    );

    _recentMetrics.add(metric);
    while (_recentMetrics.length > _maxMetricHistory) {
      _recentMetrics.removeFirst();
    }

    _metricsByType.putIfAbsent(type, () => []);
    _metricsByType[type]!.add(duration);

    _totalOperations++;

    if (metric.isSlowOperation) {
      _slowOperations++;
      if (logSlowOperations) {
        developer.log(
          '⚠️ Slow operation: $name (${duration.inMilliseconds}ms)',
          name: 'PerformanceMonitor',
        );
      }
    }
  }

  /// 수동 메트릭 기록
  void recordMetric(
    String name,
    MetricType type,
    Duration duration, {
    Map<String, dynamic>? metadata,
  }) {
    if (!_isEnabled) return;
    _recordMetric(name, type, duration, metadata);
  }

  /// 최근 메트릭 가져오기
  List<PerformanceMetric> getRecentMetrics({int? limit, MetricType? type}) {
    var metrics = _recentMetrics.toList();

    if (type != null) {
      metrics = metrics.where((m) => m.type == type).toList();
    }

    if (limit != null && metrics.length > limit) {
      metrics = metrics.sublist(metrics.length - limit);
    }

    return metrics;
  }

  /// 타입별 평균 시간
  Duration? getAverageDuration(MetricType type) {
    final durations = _metricsByType[type];
    if (durations == null || durations.isEmpty) return null;

    final total = durations.fold<int>(0, (sum, d) => sum + d.inMicroseconds);
    return Duration(microseconds: total ~/ durations.length);
  }

  /// 느린 작업 비율
  double get slowOperationRatio {
    if (_totalOperations == 0) return 0;
    return _slowOperations / _totalOperations;
  }

  /// 현재 FPS
  double? get currentFps {
    if (_frameRateHistory.isEmpty) return null;
    return _frameRateHistory.last.fps;
  }

  /// 평균 FPS
  double? get averageFps {
    if (_frameRateHistory.isEmpty) return null;
    final total = _frameRateHistory.fold<double>(0, (sum, f) => sum + f.fps);
    return total / _frameRateHistory.length;
  }

  /// 성능 요약 보고서 생성
  Map<String, dynamic> generateReport() {
    return {
      'isEnabled': _isEnabled,
      'totalOperations': _totalOperations,
      'slowOperations': _slowOperations,
      'slowOperationRatio': slowOperationRatio,
      'currentFps': currentFps,
      'averageFps': averageFps,
      'metricsByType': _metricsByType.map((type, durations) {
        if (durations.isEmpty) {
          return MapEntry(type.name, {'count': 0});
        }
        final avgMs = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds) ~/
            durations.length;
        final maxMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);
        return MapEntry(type.name, {
          'count': durations.length,
          'avgMs': avgMs,
          'maxMs': maxMs,
        });
      }),
      'recentSlowOperations': _recentMetrics
          .where((m) => m.isSlowOperation)
          .take(10)
          .map((m) => {
                'name': m.name,
                'type': m.type.name,
                'durationMs': m.duration.inMilliseconds,
                'timestamp': m.timestamp.toIso8601String(),
              })
          .toList(),
    };
  }

  /// 통계 초기화
  void reset() {
    _recentMetrics.clear();
    _metricsByType.clear();
    _frameRateHistory.clear();
    _totalOperations = 0;
    _slowOperations = 0;
    _frameCount = 0;
    _droppedFrames = 0;
  }

  /// 디버그 출력
  void printReport() {
    if (!kDebugMode) return;

    final report = generateReport();
    developer.log('╔════════════════════════════════════════════════════════╗');
    developer.log('║            Performance Monitor Report                  ║');
    developer.log('╠════════════════════════════════════════════════════════╣');
    developer.log('║ Total Operations: ${report['totalOperations'].toString().padLeft(6)}                         ║');
    developer.log('║ Slow Operations:  ${report['slowOperations'].toString().padLeft(6)} (${(report['slowOperationRatio'] * 100).toStringAsFixed(1)}%)              ║');
    if (report['currentFps'] != null) {
      developer.log('║ Current FPS:      ${(report['currentFps'] as double).toStringAsFixed(1).padLeft(6)}                         ║');
      developer.log('║ Average FPS:      ${(report['averageFps'] as double).toStringAsFixed(1).padLeft(6)}                         ║');
    }
    developer.log('╚════════════════════════════════════════════════════════╝');
  }
}

/// 성능 측정 확장 메서드
extension PerformanceMonitorExtension on PerformanceMonitor {
  /// DB 읽기 작업 측정
  Future<T> measureDbRead<T>(String name, Future<T> Function() operation) {
    return measureAsync(name, MetricType.dbRead, operation);
  }

  /// DB 쓰기 작업 측정
  Future<T> measureDbWrite<T>(String name, Future<T> Function() operation) {
    return measureAsync(name, MetricType.dbWrite, operation);
  }

  /// UI 렌더링 측정
  T measureUiRender<T>(String name, T Function() operation) {
    return measure(name, MetricType.uiRender, operation);
  }

  /// 네트워크 요청 측정
  Future<T> measureNetworkRequest<T>(String name, Future<T> Function() operation) {
    return measureAsync(name, MetricType.networkRequest, operation);
  }

  /// 상태 업데이트 측정
  T measureStateUpdate<T>(String name, T Function() operation) {
    return measure(name, MetricType.stateUpdate, operation);
  }
}
