import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// DB 용량 경고 레벨
enum StorageWarningLevel {
  normal,   // 정상 (70% 미만)
  warning,  // 경고 (70-90%)
  critical, // 위험 (90% 이상)
}

/// DB 저장소 상태 데이터
class DbStorageState {
  final int dbSizeBytes;
  final int maxSizeBytes;
  final double usagePercent;
  final StorageWarningLevel warningLevel;
  final DateTime? lastChecked;
  final bool hasShownWarning;
  final bool hasShownCritical;

  const DbStorageState({
    this.dbSizeBytes = 0,
    this.maxSizeBytes = _defaultMaxSize,
    this.usagePercent = 0.0,
    this.warningLevel = StorageWarningLevel.normal,
    this.lastChecked,
    this.hasShownWarning = false,
    this.hasShownCritical = false,
  });

  // 기본 최대 용량: 500MB (농구 기록 앱 기준 충분한 용량)
  static const int _defaultMaxSize = 500 * 1024 * 1024;

  DbStorageState copyWith({
    int? dbSizeBytes,
    int? maxSizeBytes,
    double? usagePercent,
    StorageWarningLevel? warningLevel,
    DateTime? lastChecked,
    bool? hasShownWarning,
    bool? hasShownCritical,
  }) {
    return DbStorageState(
      dbSizeBytes: dbSizeBytes ?? this.dbSizeBytes,
      maxSizeBytes: maxSizeBytes ?? this.maxSizeBytes,
      usagePercent: usagePercent ?? this.usagePercent,
      warningLevel: warningLevel ?? this.warningLevel,
      lastChecked: lastChecked ?? this.lastChecked,
      hasShownWarning: hasShownWarning ?? this.hasShownWarning,
      hasShownCritical: hasShownCritical ?? this.hasShownCritical,
    );
  }

  /// 사람이 읽기 쉬운 DB 크기
  String get formattedSize {
    if (dbSizeBytes < 1024) return '${dbSizeBytes}B';
    if (dbSizeBytes < 1024 * 1024) return '${(dbSizeBytes / 1024).toStringAsFixed(1)}KB';
    if (dbSizeBytes < 1024 * 1024 * 1024) {
      return '${(dbSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(dbSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  /// 최대 용량 표시
  String get formattedMaxSize {
    return '${(maxSizeBytes / (1024 * 1024)).toStringAsFixed(0)}MB';
  }

  bool get isWarning => warningLevel == StorageWarningLevel.warning;
  bool get isCritical => warningLevel == StorageWarningLevel.critical;
  bool get needsWarning => isWarning || isCritical;
}

/// DB 저장소 모니터
/// SQLite DB 파일 크기를 모니터링하고 70% 초과 시 경고
class DbStorageMonitor extends StateNotifier<DbStorageState> {
  DbStorageMonitor() : super(const DbStorageState()) {
    _init();
  }

  Timer? _periodicCheckTimer;

  static const double _warningThreshold = 0.70;  // 70%
  static const double _criticalThreshold = 0.90;  // 90%
  static const Duration _checkInterval = Duration(minutes: 10);
  static const String _dbFileName = 'bdr_tournament.db';

  void _init() {
    _checkStorage();
    _periodicCheckTimer = Timer.periodic(_checkInterval, (_) {
      _checkStorage();
    });
  }

  Future<void> _checkStorage() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, _dbFileName));

      if (!dbFile.existsSync()) {
        debugPrint('[DbStorageMonitor] DB file not found');
        return;
      }

      final fileStat = dbFile.statSync();
      final sizeBytes = fileStat.size;

      // WAL/SHM 파일도 포함
      final walFile = File('${dbFile.path}-wal');
      final shmFile = File('${dbFile.path}-shm');
      int totalSize = sizeBytes;
      if (walFile.existsSync()) totalSize += walFile.statSync().size;
      if (shmFile.existsSync()) totalSize += shmFile.statSync().size;

      final maxSize = state.maxSizeBytes;
      final usagePercent = totalSize / maxSize;

      StorageWarningLevel warningLevel;
      if (usagePercent >= _criticalThreshold) {
        warningLevel = StorageWarningLevel.critical;
      } else if (usagePercent >= _warningThreshold) {
        warningLevel = StorageWarningLevel.warning;
      } else {
        warningLevel = StorageWarningLevel.normal;
      }

      state = state.copyWith(
        dbSizeBytes: totalSize,
        usagePercent: usagePercent,
        warningLevel: warningLevel,
        lastChecked: DateTime.now(),
      );

      debugPrint(
        '[DbStorageMonitor] DB size: ${state.formattedSize} / ${state.formattedMaxSize} '
        '(${(usagePercent * 100).toStringAsFixed(1)}%, ${warningLevel.name})',
      );
    } catch (e) {
      debugPrint('[DbStorageMonitor] Storage check error: $e');
    }
  }

  /// 수동 확인
  Future<void> checkNow() async {
    await _checkStorage();
  }

  /// 경고 표시됨 기록
  void markWarningShown() {
    state = state.copyWith(hasShownWarning: true);
  }

  /// 위험 경고 표시됨 기록
  void markCriticalShown() {
    state = state.copyWith(hasShownCritical: true);
  }

  /// 경고 리셋 (데이터 삭제 후)
  void resetWarnings() {
    state = state.copyWith(
      hasShownWarning: false,
      hasShownCritical: false,
    );
  }

  @override
  void dispose() {
    _periodicCheckTimer?.cancel();
    super.dispose();
  }
}

/// DB 저장소 모니터 프로바이더
final dbStorageMonitorProvider =
    StateNotifierProvider<DbStorageMonitor, DbStorageState>((ref) {
  return DbStorageMonitor();
});

/// DB 용량 경고 레벨 프로바이더
final dbStorageWarningProvider = Provider<StorageWarningLevel>((ref) {
  return ref.watch(dbStorageMonitorProvider).warningLevel;
});

/// DB 용량 경고 배너 위젯
class DbStorageWarningBanner extends ConsumerStatefulWidget {
  const DbStorageWarningBanner({super.key});

  @override
  ConsumerState<DbStorageWarningBanner> createState() => _DbStorageWarningBannerState();
}

class _DbStorageWarningBannerState extends ConsumerState<DbStorageWarningBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final storageState = ref.watch(dbStorageMonitorProvider);

    if (!storageState.needsWarning || _dismissed) {
      return const SizedBox.shrink();
    }

    // 이미 표시된 경고는 다시 표시하지 않음
    if (storageState.isWarning && storageState.hasShownWarning && !storageState.isCritical) {
      return const SizedBox.shrink();
    }
    if (storageState.isCritical && storageState.hasShownCritical) {
      return const SizedBox.shrink();
    }

    final color = storageState.isCritical ? Colors.red : Colors.orange;
    final message = storageState.isCritical
        ? 'DB 용량이 거의 가득 찼습니다 (${(storageState.usagePercent * 100).toStringAsFixed(0)}%)'
        : 'DB 용량이 70%를 초과했습니다 (${(storageState.usagePercent * 100).toStringAsFixed(0)}%)';
    final subMessage = storageState.isCritical
        ? '${storageState.formattedSize} / ${storageState.formattedMaxSize} · 종료된 대회 데이터를 삭제해주세요'
        : '${storageState.formattedSize} / ${storageState.formattedMaxSize} · 데이터 관리에서 정리할 수 있습니다';

    // 경고 표시됨 기록
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (storageState.isCritical) {
        ref.read(dbStorageMonitorProvider.notifier).markCriticalShown();
      } else {
        ref.read(dbStorageMonitorProvider.notifier).markWarningShown();
      }
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(
              storageState.isCritical ? Icons.storage : Icons.disc_full,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subMessage,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _dismissed = true),
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: '닫기',
            ),
          ],
        ),
      ),
    );
  }
}
