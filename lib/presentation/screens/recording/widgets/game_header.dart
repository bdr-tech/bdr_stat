import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../widgets/timer/game_timer_widget.dart';

/// 게임 헤더 — 9:3 분할 레이아웃
/// 좌(flex 9): 홈점수 | 쿼터+공유 | 원정점수
/// 우(flex 3): 전송하기 / 박스스코어 / 설정 액션 버튼
class GameHeader extends ConsumerWidget {
  const GameHeader({
    super.key,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeScore,
    required this.awayScore,
    this.homeTeamColor = const Color(0xFFF97316),
    this.awayTeamColor = const Color(0xFF10B981),
    this.isOvertime = false,
    this.overtimeNumber = 0,
    this.onSharePressed,
    this.onHomeScoreLongPress,
    this.onAwayScoreLongPress,
    this.onSendTap,
    this.onBoxScoreTap,
    this.onSettingsTap,
    this.logoAssetPath,
  });

  final String homeTeamName;
  final String awayTeamName;
  final int homeScore;
  final int awayScore;
  final Color homeTeamColor;
  final Color awayTeamColor;
  final bool isOvertime;
  final int overtimeNumber;
  final VoidCallback? onSharePressed;
  final VoidCallback? onHomeScoreLongPress;
  final VoidCallback? onAwayScoreLongPress;
  final VoidCallback? onSendTap;
  final VoidCallback? onBoxScoreTap;
  final VoidCallback? onSettingsTap;
  final String? logoAssetPath; // 왼쪽 로고 이미지 경로

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(gameTimerProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── 왼쪽 패널 (flex 9): 로고 + 점수 + 쿼터 ──
          Expanded(
            flex: 9,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 로고 자리
                  if (logoAssetPath != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Image.asset(logoAssetPath!, width: 36, height: 36),
                    )
                  else
                    const SizedBox(width: 36), // 로고 없으면 빈 자리
                  _TeamScore(
                    teamName: homeTeamName,
                    score: homeScore,
                    scoreColor: homeTeamColor,
                    alignment: CrossAxisAlignment.start,
                    onLongPress: onHomeScoreLongPress,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 선공 화살표 (탭으로 전환)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              final notifier = ref.read(gameTimerProvider.notifier);
                              notifier.togglePossession();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (timerState.possession == Possession.home
                                    ? homeTeamColor : awayTeamColor).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (timerState.possession == Possession.home
                                      ? homeTeamColor : awayTeamColor).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    timerState.possession == Possession.home
                                        ? Icons.arrow_back_ios_rounded
                                        : Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: timerState.possession == Possession.home
                                        ? homeTeamColor : awayTeamColor,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '공격',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: timerState.possession == Possession.home
                                          ? homeTeamColor : awayTeamColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          _QuarterIndicator(
                            currentQuarter: timerState.quarter,
                            maxQuarters: timerState.maxQuarters,
                            isOvertime: isOvertime,
                            overtimeNumber: overtimeNumber,
                          ),
                        ],
                      ),
                      if (onSharePressed != null) ...[
                        const SizedBox(width: 16),
                        _ShareButton(onPressed: onSharePressed!),
                      ],
                    ],
                  ),
                  _TeamScore(
                    teamName: awayTeamName,
                    score: awayScore,
                    scoreColor: awayTeamColor,
                    alignment: CrossAxisAlignment.end,
                    onLongPress: onAwayScoreLongPress,
                  ),
                ],
              ),
            ),
          ),

          // ── 구분선 ──
          Container(
            width: 1,
            height: 72,
            color: AppTheme.borderColor,
          ),

          // ── 오른쪽 패널 (flex 3): 액션 버튼 ──
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (onSendTap != null)
                    _HeaderActionButton(
                      icon: Icons.send_rounded,
                      label: '전송하기',
                      onTap: onSendTap!,
                      color: const Color(0xFF10B981),
                    ),
                  if (onBoxScoreTap != null)
                    _HeaderActionButton(
                      icon: Icons.leaderboard_rounded,
                      label: '박스스코어',
                      onTap: onBoxScoreTap!,
                      color: Colors.white,
                    ),
                  if (onSettingsTap != null)
                    _HeaderActionButton(
                      icon: Icons.settings_rounded,
                      label: '설정',
                      onTap: onSettingsTap!,
                      color: Colors.white60,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 팀 점수 ──────────────────────────────────────────────────────────────────

class _TeamScore extends StatelessWidget {
  const _TeamScore({
    required this.teamName,
    required this.score,
    required this.scoreColor,
    required this.alignment,
    this.onLongPress,
  });

  final String teamName;
  final int score;
  final Color scoreColor;
  final CrossAxisAlignment alignment;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            teamName.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[300],
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: scoreColor,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 쿼터 인디케이터 ───────────────────────────────────────────────────────────

class _QuarterIndicator extends StatelessWidget {
  const _QuarterIndicator({
    required this.currentQuarter,
    required this.maxQuarters,
    required this.isOvertime,
    required this.overtimeNumber,
  });

  final int currentQuarter;
  final int maxQuarters;
  final bool isOvertime;
  final int overtimeNumber;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isOvertime
              ? 'OVERTIME${overtimeNumber > 1 ? ' $overtimeNumber' : ''}'
              : 'QUARTER $currentQuarter',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey[300],
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            maxQuarters,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < currentQuarter
                      ? const Color(0xFF10B981)
                      : Colors.grey[500],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 공유 버튼 ─────────────────────────────────────────────────────────────────

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_2, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              Text(
                '공유',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[300],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 헤더 액션 버튼 (우측 패널) ─────────────────────────────────────────────────

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
