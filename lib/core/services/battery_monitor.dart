import 'dart:async';

import 'package:battery_plus/battery_plus.dart' as battery_plus;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 배터리 상태
enum BatteryWarningLevel {
  normal,   // 정상 (20% 초과)
  low,      // 부족 (10-20%)
  critical, // 위험 (10% 이하)
}

/// 배터리 상태 데이터
class AppBatteryState {
  final int level;
  final BatteryWarningLevel warningLevel;
  final bool isCharging;
  final DateTime? lastChecked;
  final bool hasShownLowWarning;
  final bool hasShownCriticalWarning;

  const AppBatteryState({
    this.level = 100,
    this.warningLevel = BatteryWarningLevel.normal,
    this.isCharging = false,
    this.lastChecked,
    this.hasShownLowWarning = false,
    this.hasShownCriticalWarning = false,
  });

  AppBatteryState copyWith({
    int? level,
    BatteryWarningLevel? warningLevel,
    bool? isCharging,
    DateTime? lastChecked,
    bool? hasShownLowWarning,
    bool? hasShownCriticalWarning,
  }) {
    return AppBatteryState(
      level: level ?? this.level,
      warningLevel: warningLevel ?? this.warningLevel,
      isCharging: isCharging ?? this.isCharging,
      lastChecked: lastChecked ?? this.lastChecked,
      hasShownLowWarning: hasShownLowWarning ?? this.hasShownLowWarning,
      hasShownCriticalWarning: hasShownCriticalWarning ?? this.hasShownCriticalWarning,
    );
  }

  bool get isLow => warningLevel == BatteryWarningLevel.low;
  bool get isCritical => warningLevel == BatteryWarningLevel.critical;
  bool get needsWarning => (isLow || isCritical) && !isCharging;
}

/// 배터리 모니터
/// 배터리 상태를 모니터링하고 경고를 제공
class BatteryMonitor extends StateNotifier<AppBatteryState> {
  BatteryMonitor() : super(const AppBatteryState()) {
    _init();
  }

  final battery_plus.Battery _battery = battery_plus.Battery();
  StreamSubscription<battery_plus.BatteryState>? _batteryStateSubscription;
  Timer? _periodicCheckTimer;

  static const int _lowThreshold = 20;
  static const int _criticalThreshold = 10;
  static const Duration _checkInterval = Duration(minutes: 5);

  void _init() {
    // 초기 상태 확인
    _checkBattery();

    // 배터리 상태 변경 리스너
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((batteryState) {
      final isCharging = batteryState == battery_plus.BatteryState.charging ||
          batteryState == battery_plus.BatteryState.full;
      state = state.copyWith(isCharging: isCharging);
      // 충전 중이면 경고 리셋
      if (isCharging) {
        state = state.copyWith(
          hasShownLowWarning: false,
          hasShownCriticalWarning: false,
        );
      }
    });

    // 주기적 확인
    _periodicCheckTimer = Timer.periodic(_checkInterval, (_) {
      _checkBattery();
    });
  }

  Future<void> _checkBattery() async {
    try {
      final level = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;
      final isCharging = batteryState == battery_plus.BatteryState.charging ||
          batteryState == battery_plus.BatteryState.full;

      BatteryWarningLevel warningLevel;
      if (level <= _criticalThreshold) {
        warningLevel = BatteryWarningLevel.critical;
      } else if (level <= _lowThreshold) {
        warningLevel = BatteryWarningLevel.low;
      } else {
        warningLevel = BatteryWarningLevel.normal;
      }

      state = state.copyWith(
        level: level,
        warningLevel: warningLevel,
        isCharging: isCharging,
        lastChecked: DateTime.now(),
      );

      debugPrint('Battery: $level% (${warningLevel.name}, charging: $isCharging)');
    } catch (e) {
      debugPrint('Battery check error: $e');
    }
  }

  /// 수동 배터리 확인
  Future<void> checkNow() async {
    await _checkBattery();
  }

  /// 저전력 경고 표시됨 기록
  void markLowWarningShown() {
    state = state.copyWith(hasShownLowWarning: true);
  }

  /// 위험 경고 표시됨 기록
  void markCriticalWarningShown() {
    state = state.copyWith(hasShownCriticalWarning: true);
  }

  /// 경고 리셋 (충전 시작 또는 수동)
  void resetWarnings() {
    state = state.copyWith(
      hasShownLowWarning: false,
      hasShownCriticalWarning: false,
    );
  }

  @override
  void dispose() {
    _batteryStateSubscription?.cancel();
    _periodicCheckTimer?.cancel();
    super.dispose();
  }
}

/// 배터리 모니터 프로바이더
final batteryMonitorProvider =
    StateNotifierProvider<BatteryMonitor, AppBatteryState>((ref) {
  return BatteryMonitor();
});

/// 배터리 레벨 프로바이더
final batteryLevelProvider = Provider<int>((ref) {
  return ref.watch(batteryMonitorProvider).level;
});

/// 배터리 경고 레벨 프로바이더
final batteryWarningLevelProvider = Provider<BatteryWarningLevel>((ref) {
  return ref.watch(batteryMonitorProvider).warningLevel;
});

/// 배터리 경고 배너 위젯
class BatteryWarningBanner extends ConsumerStatefulWidget {
  const BatteryWarningBanner({super.key});

  @override
  ConsumerState<BatteryWarningBanner> createState() => _BatteryWarningBannerState();
}

class _BatteryWarningBannerState extends ConsumerState<BatteryWarningBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(batteryMonitorProvider);

    // 경고 필요 없거나 해제됨
    if (!state.needsWarning || _dismissed) {
      return const SizedBox.shrink();
    }

    // 이미 표시된 경고는 다시 표시하지 않음
    if (state.isLow && state.hasShownLowWarning && !state.isCritical) {
      return const SizedBox.shrink();
    }
    if (state.isCritical && state.hasShownCriticalWarning) {
      return const SizedBox.shrink();
    }

    final color = state.isCritical ? Colors.red : Colors.orange;
    final message = state.isCritical
        ? '배터리가 매우 부족합니다 (${state.level}%)'
        : '배터리가 부족합니다 (${state.level}%)';
    final subMessage = state.isCritical
        ? '충전기를 연결하고 화면 밝기를 낮춰주세요'
        : '충전기 연결을 권장합니다';

    // 경고 표시됨 기록
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.isCritical) {
        ref.read(batteryMonitorProvider.notifier).markCriticalWarningShown();
      } else {
        ref.read(batteryMonitorProvider.notifier).markLowWarningShown();
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
              state.isCritical ? Icons.battery_alert : Icons.battery_2_bar,
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

/// 배터리 상태 아이콘 위젯 (앱바용)
class BatteryStatusIcon extends ConsumerWidget {
  const BatteryStatusIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(batteryMonitorProvider);

    // 정상이면 표시 안함
    if (state.warningLevel == BatteryWarningLevel.normal) {
      return const SizedBox.shrink();
    }

    final color = state.isCritical ? Colors.red : Colors.orange;
    final icon = state.isCritical
        ? Icons.battery_alert
        : (state.isCharging ? Icons.battery_charging_full : Icons.battery_2_bar);

    return Tooltip(
      message: '배터리 ${state.level}%',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 2),
            Text(
              '${state.level}%',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
