import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

/// 공격권 상태
enum Possession {
  home,
  away,
  jumpBall, // 점프볼/헬드볼 상황
}

/// 게임 타이머 상태 (Sprint 2: 1/10초 정밀도)
///
/// 모든 시간은 tenths (1/10초) 단위로 관리.
/// [gameClockTenths] 게임클락 (1/10초 단위, 600초 = 6000 tenths)
/// [shotClockTenths] 샷클락 (1/10초 단위, 24초 = 240 tenths)
/// [isShotClockPaused] 샷클락만 정지 (FR-004: 리셋 후 정지)
class GameTimerState {
  final int quarter;
  final int gameClockTenths;  // 1/10초 단위 (기존 gameClockSeconds * 10)
  final int shotClockTenths;  // 1/10초 단위 (기존 shotClockSeconds * 10)
  final bool isRunning;
  final bool isPaused;
  final bool isShotClockPaused; // FR-004: 샷클락만 정지
  final int maxQuarters;
  final int quarterMinutes;
  final Possession possession;
  // FR-006: 샷클락 소수점 설정 (game_rules 연동)
  final int shotClockDecimalThreshold; // 이 초 미만에서 소수점 표시 (기본 5)
  final int shotClockDecimalPrecision; // 소수점 자릿수 (기본 1 = 1/10초)

  const GameTimerState({
    this.quarter = 1,
    this.gameClockTenths = 6000, // 10분 = 600초 = 6000 tenths
    this.shotClockTenths = 240,  // 24초 = 240 tenths
    this.isRunning = false,
    this.isPaused = false,
    this.isShotClockPaused = false,
    this.maxQuarters = 4,
    this.quarterMinutes = 10,
    this.possession = Possession.home,
    this.shotClockDecimalThreshold = 10,
    this.shotClockDecimalPrecision = 1,
  });

  GameTimerState copyWith({
    int? quarter,
    int? gameClockTenths,
    int? shotClockTenths,
    bool? isRunning,
    bool? isPaused,
    bool? isShotClockPaused,
    int? maxQuarters,
    int? quarterMinutes,
    Possession? possession,
    int? shotClockDecimalThreshold,
    int? shotClockDecimalPrecision,
  }) {
    return GameTimerState(
      quarter: quarter ?? this.quarter,
      gameClockTenths: gameClockTenths ?? this.gameClockTenths,
      shotClockTenths: shotClockTenths ?? this.shotClockTenths,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      isShotClockPaused: isShotClockPaused ?? this.isShotClockPaused,
      maxQuarters: maxQuarters ?? this.maxQuarters,
      quarterMinutes: quarterMinutes ?? this.quarterMinutes,
      possession: possession ?? this.possession,
      shotClockDecimalThreshold: shotClockDecimalThreshold ?? this.shotClockDecimalThreshold,
      shotClockDecimalPrecision: shotClockDecimalPrecision ?? this.shotClockDecimalPrecision,
    );
  }

  // ── 호환성: 초 단위 getter (DB 저장, 기존 코드 호환) ──

  /// 게임클락 (초 단위, 정수) — DB 저장 및 PlayByPlay 기록용
  int get gameClockSeconds => gameClockTenths ~/ 10;

  /// 샷클락 (초 단위, 정수) — DB 저장용
  int get shotClockSeconds => shotClockTenths ~/ 10;

  // ── 상태 확인 ──

  bool get isOvertime => quarter > maxQuarters;
  bool get isHalftime => quarter == 2 && gameClockTenths == 0;
  bool get isGameEnd => quarter > maxQuarters && gameClockTenths == 0;
  bool get shotClockViolation => shotClockTenths == 0;

  // ── 포맷팅 (FR-006, FR-007) ──

  /// 게임클락 표시 포맷 (FR-007)
  /// 1분 이내: "0:45.3" (1/10초)
  /// 1분 이상: "08:22" (MM:SS)
  String get formattedGameClock {
    if (gameClockTenths < 600) {
      // 1분(60초 = 600 tenths) 이내: "0:SS.T" 포맷
      final totalSeconds = gameClockTenths ~/ 10;
      final tenths = gameClockTenths % 10;
      return '0:${totalSeconds.toString().padLeft(2, '0')}.$tenths';
    } else {
      // 1분 이상: "MM:SS" 포맷
      final totalSeconds = gameClockTenths ~/ 10;
      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// 샷클락 표시 포맷 (FR-006)
  /// threshold 미만: "4.7" (1/10초)
  /// threshold 이상: "18" (정수)
  String get formattedShotClock {
    final thresholdTenths = shotClockDecimalThreshold * 10;
    if (shotClockTenths < thresholdTenths) {
      // 소수점 표시
      final seconds = shotClockTenths ~/ 10;
      final tenths = shotClockTenths % 10;
      return '$seconds.$tenths';
    } else {
      // 정수 표시
      final seconds = shotClockTenths ~/ 10;
      return seconds.toString().padLeft(2, '0');
    }
  }

  String get quarterLabel {
    if (quarter <= maxQuarters) {
      return 'Q$quarter';
    } else {
      final otNumber = quarter - maxQuarters;
      return otNumber == 1 ? 'OT' : 'OT$otNumber';
    }
  }

  /// 게임클락이 1분 이내에서 소수점을 표시하는지 여부
  bool get isGameClockShowingDecimal => gameClockTenths < 600;

  /// 샷클락이 소수점을 표시하는지 여부
  bool get isShotClockShowingDecimal =>
      shotClockTenths < (shotClockDecimalThreshold * 10);
}

/// 게임 타이머 Notifier (Sprint 2: 100ms 정밀도 엔진)
///
/// RISK-001 대응: 1분 이상 구간에서는 1s 틱, 1분 이내에서 100ms 틱.
/// 샷클락은 threshold 미만에서 100ms 틱.
class GameTimerNotifier extends StateNotifier<GameTimerState> {
  Timer? _timer;
  final void Function(GameTimerState)? onStateChanged;
  final void Function(int quarter)? onQuarterEnd;
  final void Function()? onShotClockViolation;

  GameTimerNotifier({
    this.onStateChanged,
    this.onQuarterEnd,
    this.onShotClockViolation,
  }) : super(const GameTimerState());

  /// 초기화
  void initialize({
    int quarterMinutes = 10,
    int maxQuarters = 4,
    int shotClockDecimalThreshold = 10,
    int shotClockDecimalPrecision = 1,
  }) {
    state = GameTimerState(
      quarterMinutes: quarterMinutes,
      maxQuarters: maxQuarters,
      gameClockTenths: quarterMinutes * 600, // 분 * 60초 * 10
      shotClockDecimalThreshold: shotClockDecimalThreshold,
      shotClockDecimalPrecision: shotClockDecimalPrecision,
    );
  }

  /// DB에서 저장된 상태 복원 (초 단위 → tenths 변환)
  void restore({required int quarter, required int gameClockSeconds}) {
    state = state.copyWith(
      quarter: quarter,
      gameClockTenths: gameClockSeconds * 10,
    );
  }

  /// 타이머 시작
  void start() {
    if (state.isRunning) return;

    state = state.copyWith(isRunning: true, isPaused: false);
    _startTimer();
    onStateChanged?.call(state);
  }

  /// 샷클락만 시작 (FR-004: 리셋 후 수동 시작)
  void startShotClock() {
    if (!state.isShotClockPaused) return;
    state = state.copyWith(isShotClockPaused: false);
    // 게임클락이 이미 running이면 타이머 재설정 불필요
    if (!state.isRunning) return;
    _restartTimerIfNeeded();
    onStateChanged?.call(state);
  }

  /// 샷클락만 일시 정지 (게임클락과 독립)
  void pauseShotClock() {
    if (state.isShotClockPaused) return;
    state = state.copyWith(isShotClockPaused: true);
    onStateChanged?.call(state);
  }

  /// 타이머 일시 정지
  void pause() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isRunning: false, isPaused: true);
    onStateChanged?.call(state);
  }

  /// 타이머 토글
  void toggle() {
    if (state.isRunning) {
      pause();
    } else {
      start();
    }
  }

  /// 현재 상태에 적합한 틱 간격으로 타이머 시작
  /// RISK-001: CPU 최적화 — 정밀 표시 구간만 100ms 틱
  void _startTimer() {
    _timer?.cancel();
    final interval = _calculateTickInterval();
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  /// 틱 간격 결정
  /// 게임클락 1분 이내 OR 샷클락 threshold 이내 → 100ms
  /// 그 외 → 1000ms (CPU 절약)
  Duration _calculateTickInterval() {
    final needsPrecision = _needsHighPrecision();
    return needsPrecision
        ? const Duration(milliseconds: 100)
        : const Duration(seconds: 1);
  }

  bool _needsHighPrecision() {
    // 게임클락 1분 이내
    if (state.gameClockTenths < 600) return true;
    // 샷클락 threshold 이내 (정지 상태가 아닐 때)
    if (!state.isShotClockPaused &&
        state.shotClockTenths < state.shotClockDecimalThreshold * 10) {
      return true;
    }
    return false;
  }

  /// 정밀도 변경 시 타이머 재시작 (1s ↔ 100ms 전환)
  void _restartTimerIfNeeded() {
    if (!state.isRunning || _timer == null) return;
    final currentNeedsPrecision = _needsHighPrecision();
    // 현재 타이머의 주기 확인은 불가하므로, 경계 근처에서 항상 재시작
    _startTimer();
  }

  /// 매 틱 실행
  void _tick() {
    final bool highPrecision = _needsHighPrecision();
    final int decrement = highPrecision ? 1 : 10; // 100ms → 1 tenth, 1s → 10 tenths

    int newGameClock = state.gameClockTenths - decrement;
    int newShotClock = state.isShotClockPaused
        ? state.shotClockTenths
        : state.shotClockTenths - decrement;

    // 게임 클럭이 0 이하면 쿼터 종료
    if (newGameClock <= 0) {
      newGameClock = 0;
      state = state.copyWith(gameClockTenths: 0, shotClockTenths: 0);
      pause();
      onQuarterEnd?.call(state.quarter);
      return;
    }

    // 샷 클럭이 0 이하면 샷클락 바이올레이션
    if (newShotClock <= 0 && !state.isShotClockPaused) {
      newShotClock = 0;
      state = state.copyWith(
        gameClockTenths: newGameClock,
        shotClockTenths: 0,
      );
      pause();
      onShotClockViolation?.call();
      return;
    }

    // 정밀도 경계 확인 (1s → 100ms 전환 필요한 시점)
    final wasHighPrecision = highPrecision;
    final willNeedHighPrecision =
        newGameClock < 600 ||
        (!state.isShotClockPaused &&
            newShotClock < state.shotClockDecimalThreshold * 10);

    state = state.copyWith(
      gameClockTenths: newGameClock,
      shotClockTenths: newShotClock,
    );
    onStateChanged?.call(state);

    // 정밀도 변경 시 타이머 재시작
    if (wasHighPrecision != willNeedHighPrecision) {
      _startTimer();
    }
  }

  /// 샷 클럭 리셋 (FR-004: 리셋 후 정지)
  /// [seconds] 리셋할 초 (24 또는 14)
  /// [pauseShotClock] true면 샷클락만 정지 (게임클락은 계속)
  void resetShotClock({int seconds = 24, bool pauseShotClock = true}) {
    state = state.copyWith(
      shotClockTenths: seconds * 10,
      isShotClockPaused: pauseShotClock,
    );
    onStateChanged?.call(state);
  }

  /// 샷 클럭 14초로 리셋 (오펜시브 리바운드)
  void resetShotClock14() {
    resetShotClock(seconds: 14);
  }

  /// 샷 클럭 직접 설정 (0-99초 범위, tenths 단위)
  void setShotClock(int seconds) {
    state = state.copyWith(shotClockTenths: (seconds * 10).clamp(0, 990));
    onStateChanged?.call(state);
  }

  // ── +/- 조정 (FR-005) ──

  /// 샷클락 +/- 1초 조정 (정지 상태에서만, WBS 1.5)
  void adjustShotClock(int deltaTenths) {
    if (state.isRunning) return; // 정지 상태에서만 조정 가능
    final newTenths = (state.shotClockTenths + deltaTenths).clamp(0, 990);
    state = state.copyWith(shotClockTenths: newTenths);
    onStateChanged?.call(state);
  }

  /// 게임클락 조정 (FR-005, WBS 1.6)
  /// 1분 이내에서는 0.1초(1 tenth) 단위, 1분 이상에서는 1초(10 tenths) 단위
  void adjustGameClock(int deltaSeconds) {
    final deltaTenths = deltaSeconds * 10;
    final maxTenths = state.quarterMinutes * 600;
    final newTenths = (state.gameClockTenths + deltaTenths).clamp(0, maxTenths);
    state = state.copyWith(gameClockTenths: newTenths);
    onStateChanged?.call(state);
  }

  /// 게임클락 1/10초 단위 조정 (FR-007: 1분 이내에서 0.1초 조정)
  void adjustGameClockTenths(int deltaTenths) {
    if (state.isRunning) return; // 정지 상태에서만 조정 가능
    final maxTenths = state.quarterMinutes * 600;
    final newTenths = (state.gameClockTenths + deltaTenths).clamp(0, maxTenths);
    state = state.copyWith(gameClockTenths: newTenths);
    onStateChanged?.call(state);
  }

  /// 다음 쿼터
  void nextQuarter() {
    final newQuarter = state.quarter + 1;
    state = state.copyWith(
      quarter: newQuarter,
      gameClockTenths: newQuarter > state.maxQuarters
          ? 5 * 600 // OT는 5분 = 3000 tenths
          : state.quarterMinutes * 600,
      shotClockTenths: 240, // 24초
      isRunning: false,
      isPaused: false,
      isShotClockPaused: false,
    );
    onStateChanged?.call(state);
  }

  /// 연장전 시작
  void startOvertime({int minutes = 5}) {
    final currentOtNumber = state.quarter > state.maxQuarters
        ? state.quarter - state.maxQuarters
        : 0;
    final targetQuarter = currentOtNumber > 0
        ? state.quarter + 1
        : state.maxQuarters + 1;

    state = state.copyWith(
      quarter: targetQuarter,
      gameClockTenths: minutes * 600,
      shotClockTenths: 240,
      isRunning: false,
      isPaused: false,
      isShotClockPaused: false,
    );
    onStateChanged?.call(state);
  }

  /// 시간 직접 설정 (초 단위 → tenths 변환)
  void setGameClock(int seconds) {
    state = state.copyWith(gameClockTenths: seconds * 10);
    onStateChanged?.call(state);
  }

  /// 쿼터 직접 설정
  void setQuarter(int quarter) {
    state = state.copyWith(quarter: quarter);
    onStateChanged?.call(state);
  }

  /// 공격권 전환 (토글)
  void togglePossession() {
    final newPossession = state.possession == Possession.home
        ? Possession.away
        : Possession.home;
    state = state.copyWith(possession: newPossession);
    onStateChanged?.call(state);
  }

  /// 공격권 설정
  void setPossession(Possession possession) {
    state = state.copyWith(possession: possession);
    onStateChanged?.call(state);
  }

  /// 점프볼 상황 설정
  void setJumpBall() {
    state = state.copyWith(possession: Possession.jumpBall);
    onStateChanged?.call(state);
  }

  /// 점프볼 해결
  void resolveJumpBall(Possession winner) {
    state = state.copyWith(possession: winner);
    onStateChanged?.call(state);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// 게임 타이머 Provider
final gameTimerProvider =
    StateNotifierProvider<GameTimerNotifier, GameTimerState>((ref) {
  return GameTimerNotifier();
});

/// 게임 타이머 위젯
class GameTimerWidget extends ConsumerWidget {
  const GameTimerWidget({
    super.key,
    this.onQuarterEnd,
    this.onShotClockViolation,
    this.compact = false,
  });

  final void Function(int quarter)? onQuarterEnd;
  final void Function()? onShotClockViolation;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(gameTimerProvider);
    final timerNotifier = ref.read(gameTimerProvider.notifier);

    if (compact) {
      return _buildCompact(context, timerState, timerNotifier);
    }

    return _buildFull(context, timerState, timerNotifier);
  }

  Widget _buildCompact(
    BuildContext context,
    GameTimerState state,
    GameTimerNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 쿼터
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              state.quarterLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 게임 클럭
          GestureDetector(
            onTap: notifier.toggle,
            child: Text(
              state.formattedGameClock,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: state.isRunning
                    ? AppTheme.primaryColor
                    : AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 샷 클럭
          Container(
            width: 60,
            height: 50,
            decoration: BoxDecoration(
              color: state.isShotClockShowingDecimal
                  ? AppTheme.errorColor
                  : AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            alignment: Alignment.center,
            child: Text(
              state.formattedShotClock,
              style: TextStyle(
                fontSize: state.isShotClockShowingDecimal ? 20 : 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: state.isShotClockShowingDecimal
                    ? Colors.white
                    : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFull(
    BuildContext context,
    GameTimerState state,
    GameTimerNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 쿼터 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: state.quarter > 1
                    ? () => notifier.setQuarter(state.quarter - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: state.isOvertime
                      ? AppTheme.warningColor
                      : AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.quarterLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => notifier.setQuarter(state.quarter + 1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 게임 클럭 + +/- 조정 버튼 (FR-005, WBS 1.6)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // +/- 버튼 (왼쪽: -)
              if (!state.isRunning) ...[
                _ClockAdjustButton(
                  icon: Icons.remove,
                  onPressed: () {
                    if (state.isGameClockShowingDecimal) {
                      notifier.adjustGameClockTenths(-1); // 0.1초
                    } else {
                      notifier.adjustGameClock(-1); // 1초
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
              // 게임 클럭 디스플레이
              GestureDetector(
                onTap: notifier.toggle,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: state.isRunning
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: state.isRunning
                          ? AppTheme.primaryColor
                          : AppTheme.borderColor,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    state.formattedGameClock,
                    style: TextStyle(
                      fontSize: state.isGameClockShowingDecimal ? 44 : 56,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: state.isRunning
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              // +/- 버튼 (오른쪽: +)
              if (!state.isRunning) ...[
                const SizedBox(width: 8),
                _ClockAdjustButton(
                  icon: Icons.add,
                  onPressed: () {
                    if (state.isGameClockShowingDecimal) {
                      notifier.adjustGameClockTenths(1); // 0.1초
                    } else {
                      notifier.adjustGameClock(1); // 1초
                    }
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // 시간 조정 버튼 (큰 단위)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimeAdjustButton(
                label: '-1:00',
                onPressed: () => notifier.adjustGameClock(-60),
              ),
              _TimeAdjustButton(
                label: '-0:10',
                onPressed: () => notifier.adjustGameClock(-10),
              ),
              _TimeAdjustButton(
                label: '+0:10',
                onPressed: () => notifier.adjustGameClock(10),
              ),
              _TimeAdjustButton(
                label: '+1:00',
                onPressed: () => notifier.adjustGameClock(60),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 샷 클럭 + +/- 조정 버튼 (FR-005, WBS 1.5)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '샷클락',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              // - 버튼
              if (!state.isRunning)
                _ClockAdjustButton(
                  icon: Icons.remove,
                  onPressed: () => notifier.adjustShotClock(-10), // -1초
                  small: true,
                ),
              if (!state.isRunning) const SizedBox(width: 8),
              Container(
                width: 90,
                height: 80,
                decoration: BoxDecoration(
                  color: state.isShotClockShowingDecimal
                      ? AppTheme.errorColor
                      : AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.isShotClockShowingDecimal
                        ? AppTheme.errorColor
                        : AppTheme.borderColor,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.formattedShotClock,
                      style: TextStyle(
                        fontSize: state.isShotClockShowingDecimal ? 28 : 36,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: state.isShotClockShowingDecimal
                            ? Colors.white
                            : AppTheme.textPrimary,
                      ),
                    ),
                    // FR-004: 샷클락 정지 상태 표시
                    if (state.isShotClockPaused)
                      const Text(
                        'PAUSED',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                  ],
                ),
              ),
              // + 버튼
              if (!state.isRunning) const SizedBox(width: 8),
              if (!state.isRunning)
                _ClockAdjustButton(
                  icon: Icons.add,
                  onPressed: () => notifier.adjustShotClock(10), // +1초
                  small: true,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 샷 클럭 리셋 버튼 + 시작 버튼 (FR-004)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => notifier.resetShotClock(seconds: 24),
                child: const Text('24초'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: notifier.resetShotClock14,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                ),
                child: const Text('14초'),
              ),
              // FR-004: 샷클락 정지 상태에서 시작 버튼
              if (state.isShotClockPaused) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: notifier.startShotClock,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('샷클락 시작'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // 컨트롤 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 시작/정지 버튼
              SizedBox(
                width: 120,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: notifier.toggle,
                  icon: Icon(
                      state.isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(state.isRunning ? '정지' : '시작'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.isRunning
                        ? AppTheme.warningColor
                        : AppTheme.successColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // 다음 쿼터 버튼
              OutlinedButton.icon(
                onPressed: notifier.nextQuarter,
                icon: const Icon(Icons.skip_next),
                label: const Text('다음 쿼터'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 시간 조정 버튼 (큰 단위)
class _TimeAdjustButton extends StatelessWidget {
  const _TimeAdjustButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

/// +/- 조정 버튼 (FR-005: 클럭 위아래 버튼)
class _ClockAdjustButton extends StatelessWidget {
  const _ClockAdjustButton({
    required this.icon,
    required this.onPressed,
    this.small = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 36.0 : 44.0;
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Icon(
              icon,
              size: small ? 18 : 22,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 간단한 타이머 디스플레이 (점수판 위)
class MiniTimerDisplay extends ConsumerWidget {
  const MiniTimerDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(gameTimerProvider);
    final timerNotifier = ref.read(gameTimerProvider.notifier);

    return GestureDetector(
      onTap: timerNotifier.toggle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 쿼터
          Text(
            timerState.quarterLabel,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 8),

          // 게임 클럭
          Text(
            timerState.formattedGameClock,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: timerState.isRunning
                  ? AppTheme.primaryColor
                  : AppTheme.textPrimary,
            ),
          ),

          // 실행 표시
          if (timerState.isRunning) ...[
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.successColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
