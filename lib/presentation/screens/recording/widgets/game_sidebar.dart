import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../widgets/timer/game_timer_widget.dart';

/// 게임 사이드바 - 타이머 및 라이브 로그
class GameSidebar extends ConsumerWidget {
  const GameSidebar({
    super.key,
    required this.onSendTap,
    required this.onBoxScoreTap,
    required this.onSettingsTap,
  });

  final VoidCallback onSendTap;
  final VoidCallback onBoxScoreTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // 게임 시계와 샷 클락
        const _TimerSection(),
        const SizedBox(height: 16),

        // 라이브 로그
        const Expanded(child: _LiveLogSection()),
      ],
    );
  }
}

/// 타이머 섹션 (게임 시계 + 샷 클락)
class _TimerSection extends ConsumerWidget {
  const _TimerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(gameTimerProvider);
    final timerNotifier = ref.read(gameTimerProvider.notifier);

    return Column(
      children: [
        // 게임 시계 (Sprint 2: 1/10초 정밀도, FR-007)
        GestureDetector(
          onTap: timerNotifier.toggle,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF1E293B),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  timerState.formattedGameClock,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: timerState.isGameClockShowingDecimal ? 38 : 48,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981), // 에메랄드 그린
                    letterSpacing: timerState.isGameClockShowingDecimal ? 2 : 4,
                    shadows: const [
                      Shadow(
                        color: Color(0xFF10B981),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'GAME CLOCK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
        // FR-005: 게임클락 +/- 조정 버튼 (정지 상태에서만)
        if (!timerState.isRunning) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ShotClockButton(
                  label: timerState.isGameClockShowingDecimal ? '-0.1s' : '-1s',
                  onTap: () {
                    if (timerState.isGameClockShowingDecimal) {
                      timerNotifier.adjustGameClockTenths(-1);
                    } else {
                      timerNotifier.adjustGameClock(-1);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShotClockButton(
                  label: timerState.isGameClockShowingDecimal ? '+0.1s' : '+1s',
                  onTap: () {
                    if (timerState.isGameClockShowingDecimal) {
                      timerNotifier.adjustGameClockTenths(1);
                    } else {
                      timerNotifier.adjustGameClock(1);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),

        // 샷 클락 (Sprint 2: 1/10초 정밀도 + FR-004 정지 표시)
        GestureDetector(
          onTap: timerNotifier.toggle,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF1E293B),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  timerState.formattedShotClock,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: timerState.isShotClockShowingDecimal ? 40 : 48,
                    fontWeight: FontWeight.bold,
                    color: timerState.isShotClockShowingDecimal
                        ? Colors.red
                        : const Color(0xFFEF4444),
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        color: timerState.isShotClockShowingDecimal
                            ? Colors.red
                            : const Color(0xFFEF4444),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SHOT CLOCK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                        letterSpacing: 2,
                      ),
                    ),
                    if (timerState.isShotClockPaused) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'PAUSED',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        // FR-004: 샷클락 정지 시 시작 버튼 + 리셋 버튼
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ShotClockButton(
                label: '24s',
                onTap: () => timerNotifier.resetShotClock(seconds: 24),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ShotClockButton(
                label: '14s',
                onTap: () => timerNotifier.resetShotClock(seconds: 14),
              ),
            ),
            if (timerState.isShotClockPaused) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _ShotClockButton(
                  label: 'START',
                  onTap: timerNotifier.startShotClock,
                  isStart: true,
                ),
              ),
            ],
          ],
        ),
        // FR-005: +/- 조정 버튼 (정지 상태에서만)
        if (!timerState.isRunning) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ShotClockButton(
                  label: '-1s',
                  onTap: () => timerNotifier.adjustShotClock(-10),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShotClockButton(
                  label: '+1s',
                  onTap: () => timerNotifier.adjustShotClock(10),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// 라이브 로그 섹션
class _LiveLogSection extends StatelessWidget {
  const _LiveLogSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'LIVE LOG',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                Icon(
                  Icons.history,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),

          // 로그 리스트
          Expanded(
            child: _buildLogList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    // 임시 로그 데이터 - 실제로는 Provider에서 가져와야 함
    return ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        _LogItem(
          teamColor: Color(0xFFF97316), // 오렌지
          teamName: 'A Team',
          playerNumber: '15',
          action: '3pt Made',
        ),
        SizedBox(height: 8),
        _LogItem(
          teamColor: Color(0xFF10B981), // 그린
          teamName: 'B Team',
          playerNumber: '7',
          action: 'Rebound',
        ),
        SizedBox(height: 8),
        _LogItem(
          teamColor: Color(0xFFF97316),
          teamName: 'A Team',
          playerNumber: '2',
          action: 'Foul',
          isOld: true,
        ),
        SizedBox(height: 24),
        _RecordingIndicator(),
      ],
    );
  }
}

/// 개별 로그 아이템
class _LogItem extends StatelessWidget {
  const _LogItem({
    required this.teamColor,
    required this.teamName,
    required this.playerNumber,
    required this.action,
    this.isOld = false,
  });

  final Color teamColor;
  final String teamName;
  final String playerNumber;
  final String action;
  final bool isOld;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isOld ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: teamColor,
              width: 4,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$teamName #$playerNumber',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            Text(
              action,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 샷클락 버튼 (리셋/시작/조정)
class _ShotClockButton extends StatelessWidget {
  const _ShotClockButton({
    required this.label,
    required this.onTap,
    this.isStart = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isStart;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isStart
          ? const Color(0xFF10B981).withValues(alpha: 0.15)
          : const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isStart
                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                  : const Color(0xFF334155),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isStart ? const Color(0xFF10B981) : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

/// 녹화 중 인디케이터
class _RecordingIndicator extends StatelessWidget {
  const _RecordingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.sports_basketball,
          size: 32,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 8),
        Text(
          'RECORDING...',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.grey[500],
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
