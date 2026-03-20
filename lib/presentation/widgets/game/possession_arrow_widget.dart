import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../timer/game_timer_widget.dart';

/// 공격권 화살표 위젯
///
/// 현재 공격권을 가진 팀을 화살표로 표시합니다.
/// - 홈팀 공격: ← (왼쪽 방향)
/// - 원정팀 공격: → (오른쪽 방향)
/// - 탭하면 수동 전환 가능
class PossessionArrowWidget extends ConsumerWidget {
  const PossessionArrowWidget({
    super.key,
    this.homeTeamName = '홈',
    this.awayTeamName = '원정',
    this.size = PossessionArrowSize.medium,
    this.showLabels = true,
    this.onPossessionChanged,
  });

  final String homeTeamName;
  final String awayTeamName;
  final PossessionArrowSize size;
  final bool showLabels;
  final void Function(Possession)? onPossessionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(gameTimerProvider);
    final timerNotifier = ref.read(gameTimerProvider.notifier);

    return GestureDetector(
      onTap: () {
        timerNotifier.togglePossession();
        onPossessionChanged?.call(
          timerState.possession == Possession.home
              ? Possession.away
              : Possession.home,
        );
      },
      onLongPress: () {
        _showPossessionMenu(context, timerNotifier);
      },
      child: Tooltip(
        message: '탭: 공격권 전환, 길게 누르기: 점프볼',
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: size.horizontalPadding,
            vertical: size.verticalPadding,
          ),
          decoration: BoxDecoration(
            color: _getBackgroundColor(timerState.possession),
            borderRadius: BorderRadius.circular(size.borderRadius),
            border: Border.all(
              color: _getBorderColor(timerState.possession),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 홈팀 방향 표시
              if (showLabels) ...[
                Text(
                  homeTeamName.length > 4
                      ? homeTeamName.substring(0, 4)
                      : homeTeamName,
                  style: TextStyle(
                    fontSize: size.labelFontSize,
                    fontWeight: FontWeight.w500,
                    color: timerState.possession == Possession.home
                        ? AppTheme.homeTeamColor
                        : AppTheme.textSecondary,
                  ),
                ),
                SizedBox(width: size.spacing),
              ],

              // 화살표
              _buildArrow(timerState.possession),

              // 원정팀 방향 표시
              if (showLabels) ...[
                SizedBox(width: size.spacing),
                Text(
                  awayTeamName.length > 4
                      ? awayTeamName.substring(0, 4)
                      : awayTeamName,
                  style: TextStyle(
                    fontSize: size.labelFontSize,
                    fontWeight: FontWeight.w500,
                    color: timerState.possession == Possession.away
                        ? AppTheme.awayTeamColor
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArrow(Possession possession) {
    switch (possession) {
      case Possession.home:
        return Icon(
          Icons.arrow_back,
          size: size.arrowSize,
          color: AppTheme.homeTeamColor,
        );
      case Possession.away:
        return Icon(
          Icons.arrow_forward,
          size: size.arrowSize,
          color: AppTheme.awayTeamColor,
        );
      case Possession.jumpBall:
        return Icon(
          Icons.swap_horiz,
          size: size.arrowSize,
          color: AppTheme.warningColor,
        );
    }
  }

  Color _getBackgroundColor(Possession possession) {
    switch (possession) {
      case Possession.home:
        return AppTheme.homeTeamColor.withValues(alpha: 0.15);
      case Possession.away:
        return AppTheme.awayTeamColor.withValues(alpha: 0.15);
      case Possession.jumpBall:
        return AppTheme.warningColor.withValues(alpha: 0.15);
    }
  }

  Color _getBorderColor(Possession possession) {
    switch (possession) {
      case Possession.home:
        return AppTheme.homeTeamColor.withValues(alpha: 0.5);
      case Possession.away:
        return AppTheme.awayTeamColor.withValues(alpha: 0.5);
      case Possession.jumpBall:
        return AppTheme.warningColor.withValues(alpha: 0.5);
    }
  }

  void _showPossessionMenu(BuildContext context, GameTimerNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '공격권 설정',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.arrow_back, color: AppTheme.homeTeamColor),
              title: Text('$homeTeamName 공격'),
              onTap: () {
                notifier.setPossession(Possession.home);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.arrow_forward, color: AppTheme.awayTeamColor),
              title: Text('$awayTeamName 공격'),
              onTap: () {
                notifier.setPossession(Possession.away);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.swap_horiz, color: AppTheme.warningColor),
              title: const Text('점프볼 / 헬드볼'),
              subtitle: const Text('번갈아 공격권 전환'),
              onTap: () {
                notifier.setJumpBall();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// 공격권 화살표 크기
enum PossessionArrowSize {
  small(
    arrowSize: 20,
    labelFontSize: 10,
    horizontalPadding: 8,
    verticalPadding: 4,
    spacing: 4,
    borderRadius: 6,
  ),
  medium(
    arrowSize: 28,
    labelFontSize: 12,
    horizontalPadding: 12,
    verticalPadding: 6,
    spacing: 8,
    borderRadius: 8,
  ),
  large(
    arrowSize: 36,
    labelFontSize: 14,
    horizontalPadding: 16,
    verticalPadding: 8,
    spacing: 12,
    borderRadius: 10,
  );

  const PossessionArrowSize({
    required this.arrowSize,
    required this.labelFontSize,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.spacing,
    required this.borderRadius,
  });

  final double arrowSize;
  final double labelFontSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double spacing;
  final double borderRadius;
}

/// 간단한 공격권 인디케이터 (점수판용)
class PossessionIndicator extends ConsumerWidget {
  const PossessionIndicator({
    super.key,
    required this.isHome,
  });

  final bool isHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final possession = ref.watch(
      gameTimerProvider.select((state) => state.possession),
    );

    final isActive = (isHome && possession == Possession.home) ||
        (!isHome && possession == Possession.away);

    if (!isActive) return const SizedBox.shrink();

    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: isHome ? AppTheme.homeTeamColor : AppTheme.awayTeamColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isHome ? AppTheme.homeTeamColor : AppTheme.awayTeamColor)
                .withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
