import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 크래시 심각도 레벨
enum CrashSeverity {
  info,
  warning,
  error,
  fatal,
}

/// 크래시 보고서
class CrashReport {
  final String id;
  final String message;
  final String? stackTrace;
  final CrashSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic> tags;
  final Map<String, dynamic> extra;
  final bool isSynced;

  CrashReport({
    required this.id,
    required this.message,
    this.stackTrace,
    this.severity = CrashSeverity.error,
    DateTime? timestamp,
    Map<String, dynamic>? tags,
    Map<String, dynamic>? extra,
    this.isSynced = false,
  })  : timestamp = timestamp ?? DateTime.now(),
        tags = tags ?? {},
        extra = extra ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
        'stackTrace': stackTrace,
        'severity': severity.name,
        'timestamp': timestamp.toIso8601String(),
        'tags': tags,
        'extra': extra,
        'isSynced': isSynced,
      };

  factory CrashReport.fromJson(Map<String, dynamic> json) => CrashReport(
        id: json['id'] as String,
        message: json['message'] as String,
        stackTrace: json['stackTrace'] as String?,
        severity: CrashSeverity.values.firstWhere(
          (e) => e.name == json['severity'],
          orElse: () => CrashSeverity.error,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
        tags: Map<String, dynamic>.from(json['tags'] as Map? ?? {}),
        extra: Map<String, dynamic>.from(json['extra'] as Map? ?? {}),
        isSynced: json['isSynced'] as bool? ?? false,
      );

  CrashReport copyWith({
    String? id,
    String? message,
    String? stackTrace,
    CrashSeverity? severity,
    DateTime? timestamp,
    Map<String, dynamic>? tags,
    Map<String, dynamic>? extra,
    bool? isSynced,
  }) {
    return CrashReport(
      id: id ?? this.id,
      message: message ?? this.message,
      stackTrace: stackTrace ?? this.stackTrace,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      tags: tags ?? this.tags,
      extra: extra ?? this.extra,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

/// 크래시 리포팅 서비스 (추상 클래스)
abstract class CrashReporter {
  /// 초기화
  Future<void> initialize();

  /// 크래시 보고
  Future<void> reportCrash(
    dynamic exception,
    StackTrace? stackTrace, {
    CrashSeverity severity = CrashSeverity.error,
    Map<String, dynamic>? tags,
    Map<String, dynamic>? extra,
  });

  /// 메시지 기록
  Future<void> logMessage(
    String message, {
    CrashSeverity severity = CrashSeverity.info,
    Map<String, dynamic>? tags,
    Map<String, dynamic>? extra,
  });

  /// 사용자 정보 설정
  void setUser({String? id, String? email, String? name});

  /// 태그 설정
  void setTag(String key, dynamic value);

  /// 추가 데이터 설정
  void setExtra(String key, dynamic value);

  /// 미동기화 보고서 수
  Future<int> getUnsyncedReportCount();

  /// 미동기화 보고서 동기화 시도
  Future<void> syncReports();
}

/// 로컬 크래시 리포터 (오프라인 지원)
///
/// - 모든 크래시를 로컬에 저장
/// - Sentry/Firebase 연동 전 사용 가능
/// - 나중에 동기화 가능
class LocalCrashReporter implements CrashReporter {
  static final LocalCrashReporter instance = LocalCrashReporter._();

  LocalCrashReporter._();

  static const int _maxReports = 100;
  static const String _reportsFileName = 'crash_reports.json';

  final Queue<CrashReport> _recentReports = Queue();
  final Map<String, dynamic> _globalTags = {};
  final Map<String, dynamic> _globalExtra = {};
  Map<String, String>? _user;

  bool _isInitialized = false;
  String? _reportsFilePath;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      _reportsFilePath = '${directory.path}/$_reportsFileName';

      // 기존 보고서 로드
      await _loadReports();

      _isInitialized = true;

      developer.log('CrashReporter initialized', name: 'CrashReporter');
    } catch (e) {
      developer.log('Failed to initialize CrashReporter: $e',
          name: 'CrashReporter');
    }
  }

  Future<void> _loadReports() async {
    if (_reportsFilePath == null) return;

    try {
      final file = File(_reportsFilePath!);
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;

        for (final json in jsonList) {
          _recentReports.add(CrashReport.fromJson(json as Map<String, dynamic>));
        }
      }
    } catch (e) {
      developer.log('Failed to load crash reports: $e', name: 'CrashReporter');
    }
  }

  Future<void> _saveReports() async {
    if (_reportsFilePath == null) return;

    try {
      final file = File(_reportsFilePath!);
      final jsonList = _recentReports.map((r) => r.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      developer.log('Failed to save crash reports: $e', name: 'CrashReporter');
    }
  }

  @override
  Future<void> reportCrash(
    dynamic exception,
    StackTrace? stackTrace, {
    CrashSeverity severity = CrashSeverity.error,
    Map<String, dynamic>? tags,
    Map<String, dynamic>? extra,
  }) async {
    final report = CrashReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: exception.toString(),
      stackTrace: stackTrace?.toString(),
      severity: severity,
      tags: {..._globalTags, ...?tags},
      extra: {
        ..._globalExtra,
        ...?extra,
        if (_user != null) 'user': _user,
      },
    );

    _addReport(report);

    // 콘솔 출력 (디버그 모드)
    if (kDebugMode) {
      developer.log(
        '🚨 CRASH: ${report.message}',
        name: 'CrashReporter',
        error: exception,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> logMessage(
    String message, {
    CrashSeverity severity = CrashSeverity.info,
    Map<String, dynamic>? tags,
    Map<String, dynamic>? extra,
  }) async {
    final report = CrashReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      severity: severity,
      tags: {..._globalTags, ...?tags},
      extra: {
        ..._globalExtra,
        ...?extra,
        if (_user != null) 'user': _user,
      },
    );

    _addReport(report);

    // 콘솔 출력 (디버그 모드)
    if (kDebugMode) {
      final icon = switch (severity) {
        CrashSeverity.info => 'ℹ️',
        CrashSeverity.warning => '⚠️',
        CrashSeverity.error => '❌',
        CrashSeverity.fatal => '💀',
      };
      developer.log('$icon $message', name: 'CrashReporter');
    }
  }

  void _addReport(CrashReport report) {
    _recentReports.add(report);

    // 최대 개수 유지
    while (_recentReports.length > _maxReports) {
      _recentReports.removeFirst();
    }

    // 비동기로 저장
    _saveReports();
  }

  @override
  void setUser({String? id, String? email, String? name}) {
    if (id == null && email == null && name == null) {
      _user = null;
    } else {
      _user = {
        if (id != null) 'id': id,
        if (email != null) 'email': email,
        if (name != null) 'name': name,
      };
    }
  }

  @override
  void setTag(String key, dynamic value) {
    _globalTags[key] = value;
  }

  @override
  void setExtra(String key, dynamic value) {
    _globalExtra[key] = value;
  }

  @override
  Future<int> getUnsyncedReportCount() async {
    return _recentReports.where((r) => !r.isSynced).length;
  }

  @override
  Future<void> syncReports() async {
    // TODO: Sentry/Firebase 연동 시 구현
    // 현재는 로컬 저장만 수행
    developer.log(
      'Sync not implemented - reports stored locally',
      name: 'CrashReporter',
    );
  }

  /// 최근 보고서 가져오기
  List<CrashReport> getRecentReports({int? limit}) {
    final reports = _recentReports.toList().reversed.toList();
    if (limit != null && reports.length > limit) {
      return reports.sublist(0, limit);
    }
    return reports;
  }

  /// 보고서 클리어
  Future<void> clearReports() async {
    _recentReports.clear();
    await _saveReports();
  }

  /// 요약 정보
  Map<String, dynamic> getSummary() {
    final reports = _recentReports.toList();
    final bySeverity = <String, int>{};

    for (final report in reports) {
      final key = report.severity.name;
      bySeverity[key] = (bySeverity[key] ?? 0) + 1;
    }

    return {
      'totalReports': reports.length,
      'unsyncedReports': reports.where((r) => !r.isSynced).length,
      'bySeverity': bySeverity,
      'lastReportTime': reports.isNotEmpty
          ? reports.last.timestamp.toIso8601String()
          : null,
    };
  }
}

/// Flutter 에러 핸들러 설정
///
/// main() 에서 호출하여 전역 에러 핸들링 설정
void setupCrashReporting() {
  // Flutter 프레임워크 에러 핸들링
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);

    LocalCrashReporter.instance.reportCrash(
      details.exception,
      details.stack,
      severity: CrashSeverity.error,
      tags: {'source': 'flutter_error'},
      extra: {
        'library': details.library,
        'context': details.context?.toString(),
      },
    );
  };

  // Platform 에러 핸들링 (비동기 에러 등)
  PlatformDispatcher.instance.onError = (error, stack) {
    LocalCrashReporter.instance.reportCrash(
      error,
      stack,
      severity: CrashSeverity.fatal,
      tags: {'source': 'platform_error'},
    );
    return true;
  };
}

/// Zone 기반 에러 핸들링으로 앱 실행
///
/// main() 에서 사용:
/// ```dart
/// void main() async {
///   runAppWithCrashReporting(() async {
///     WidgetsFlutterBinding.ensureInitialized();
///     await LocalCrashReporter.instance.initialize();
///     runApp(const MyApp());
///   });
/// }
/// ```
Future<void> runAppWithCrashReporting(Future<void> Function() appRunner) async {
  await runZonedGuarded(
    appRunner,
    (error, stackTrace) {
      LocalCrashReporter.instance.reportCrash(
        error,
        stackTrace,
        severity: CrashSeverity.fatal,
        tags: {'source': 'zone_error'},
      );
    },
  );
}
