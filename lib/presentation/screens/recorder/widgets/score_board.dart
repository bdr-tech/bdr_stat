// ─── Score Board Widgets ──────────────────────────────────────────────────────
// _ScoreBoard (legacy/unused), _FoulDots, _TimeoutDots, _StatusChip

// ignore_for_file: unused_element

import 'package:flutter/material.dart';

import '../../../../core/theme/bdr_design_system.dart';

// ─── Foul Dots (§1.5 파울 표시) ───────────────────────────────────────────────

class FoulDots extends StatelessWidget {
  const FoulDots({super.key, required this.fouls, this.color = DS.textSecondary});
  final int fouls;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isBonus = fouls >= 5;
    final activeColor = isBonus ? DS.error : color.withValues(alpha: 0.7);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '파울 $fouls',
          style: DSText.jakartaLabel(color: activeColor, size: 10),
        ),
        if (isBonus) ...[
          const SizedBox(width: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: DS.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text('BONUS', style: DSText.jakartaLabel(color: DS.error, size: 8)),
          ),
        ],
      ],
    );
  }
}

// ─── Timeout Dots (§2.2 타임아웃 잔여 표시) ───────────────────────────────────

class TimeoutDots extends StatelessWidget {
  const TimeoutDots({super.key, required this.remaining});
  final int remaining;

  @override
  Widget build(BuildContext context) {
    // 전반 2개 | 후반 3개 구분 표시 (FIBA 규칙)
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 전반 타임아웃 (2개)
        ...List.generate(2, (i) => _dot(i < remaining)),
        // 구분선
        Container(
          width: 1,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          color: DS.textHint.withValues(alpha: 0.3),
        ),
        // 후반 타임아웃 (3개)
        ...List.generate(3, (i) => _dot((i + 2) < remaining)),
      ],
    );
  }

  Widget _dot(bool filled) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? DS.gold : DS.textHint.withValues(alpha: 0.2),
        boxShadow: filled
            ? [BoxShadow(color: DS.gold.withValues(alpha: 0.4), blurRadius: 4)]
            : null,
      ),
    );
  }
}

// ─── Status Chip ──────────────────────────────────────────────────────────────

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'in_progress' => ('LIVE', DS.success),
      'completed' => ('종료', DS.textHint),
      'cancelled' => ('취소', DS.error),
      _ => ('예정', DS.awayBlue),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == 'in_progress') ...[
          PulsingDot(color: color, size: 7),
          const SizedBox(width: 5),
        ],
        Text(label, style: DSText.jakartaLabel(color: color, size: 11)),
      ],
    );
  }
}

// ─── Score Board (legacy — unused, kept for reference) ────────────────────────

class ScoreBoard extends StatelessWidget {
  const ScoreBoard({
    super.key,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeScore,
    required this.awayScore,
    required this.status,
    required this.currentQuarter,
    required this.elapsedSeconds,
    required this.isTimerRunning,
    required this.homeTeamFouls,
    required this.awayTeamFouls,
    required this.shotClockSeconds,
    required this.isShotClockRunning,
    required this.homeTimeouts,
    required this.awayTimeouts,
    required this.onShotClockTap,
    required this.onReset24,
    required this.onReset14,
  });

  final String homeTeamName;
  final String awayTeamName;
  final int homeScore;
  final int awayScore;
  final String status;
  final int currentQuarter;
  final int elapsedSeconds;
  final bool isTimerRunning;
  final int homeTeamFouls;
  final int awayTeamFouls;
  final int shotClockSeconds;
  final bool isShotClockRunning;
  final int homeTimeouts;
  final int awayTimeouts;
  final VoidCallback onShotClockTap;
  final VoidCallback onReset24;
  final VoidCallback onReset14;

  @override
  Widget build(BuildContext context) {
    final quarterLabel = currentQuarter <= 4 ? 'Q$currentQuarter' : 'OT${currentQuarter - 4}';
    final m = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (elapsedSeconds % 60).toString().padLeft(2, '0');
    final clockLabel = '$m:$s';
    final isLive = status == 'in_progress';

    final shotClockColor = shotClockSeconds <= 5
        ? DS.error
        : shotClockSeconds <= 10
            ? DS.warning
            : DS.gold;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      child: GlassBox(
        borderRadius: DS.radiusXl,
        blur: DS.blurRadius,
        borderColor: DS.glassBorder,
        glowShadows: [
          BoxShadow(
            color: DS.homeRed.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(-20, 0),
          ),
          BoxShadow(
            color: DS.awayBlue.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(20, 0),
          ),
        ],
        child: Stack(
          children: [
            // 좌측 HOME 글로우 그라디언트
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DS.radiusXl),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              DS.homeRed.withValues(alpha: 0.07),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              DS.awayBlue.withValues(alpha: 0.07),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 메인 콘텐츠
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                children: [
                  // ── 메인 스코어 행 ───────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 홈팀 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              homeTeamName.toUpperCase(),
                              style: DSText.bebasMedium(color: DS.homeRed, size: 20),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text('HOME', style: DSText.jakartaLabel(color: DS.homeRed.withValues(alpha: 0.6))),
                            const SizedBox(height: 6),
                            FoulDots(fouls: homeTeamFouls, color: DS.homeRed),
                            const SizedBox(height: 4),
                            TimeoutDots(remaining: homeTimeouts),
                          ],
                        ),
                      ),

                      // 중앙: 점수 + 상태
                      Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              AnimatedScore(score: homeScore, color: Colors.white, fontSize: 68),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  ':',
                                  style: DSText.bebasLarge(color: DS.textHint, size: 40),
                                ),
                              ),
                              AnimatedScore(score: awayScore, color: Colors.white, fontSize: 68),
                            ],
                          ),

                          // 상태 + 쿼터 + 클락
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusChip(status: status),
                              if (isLive) ...[
                                const SizedBox(width: 8),
                                Text(
                                  quarterLabel,
                                  style: DSText.bebasSmall(color: DS.gold, size: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  clockLabel,
                                  style: DSText.rajdhaniClock(
                                    color: isTimerRunning ? DS.textPrimary : DS.textHint,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // §2.1 샷클락
                          if (isLive) ...[
                            const SizedBox(height: 8),
                            TapScaleButton(
                              onTap: onShotClockTap,
                              scaleFactor: 0.95,
                              child: GlassBox(
                                borderRadius: DS.radiusSm,
                                blur: DS.blurRadiusSm,
                                borderColor: isShotClockRunning
                                    ? shotClockColor.withValues(alpha: 0.5)
                                    : DS.glassBorder,
                                glowShadows: isShotClockRunning
                                    ? DS.glowColor(shotClockColor, intensity: 0.4)
                                    : [],
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isShotClockRunning ? Icons.timer_rounded : Icons.timer_off_rounded,
                                      size: 14,
                                      color: isShotClockRunning ? shotClockColor : DS.textHint,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      shotClockSeconds.toString().padLeft(2, '0'),
                                      style: DSText.rajdhaniLarge(
                                        color: isShotClockRunning ? shotClockColor : DS.textHint,
                                        size: 32,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: onReset24,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: const Size(44, 32),
                                  ),
                                  child: Text('24초', style: DSText.jakartaLabel(color: DS.gold)),
                                ),
                                Text('·', style: DSText.jakartaLabel(color: DS.textHint)),
                                TextButton(
                                  onPressed: onReset14,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: const Size(44, 32),
                                  ),
                                  child: Text('14초', style: DSText.jakartaLabel(color: DS.gold)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),

                      // 어웨이팀 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              awayTeamName.toUpperCase(),
                              style: DSText.bebasMedium(color: DS.awayBlue, size: 20),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text('AWAY', style: DSText.jakartaLabel(color: DS.awayBlue.withValues(alpha: 0.6))),
                            const SizedBox(height: 6),
                            FoulDots(fouls: awayTeamFouls, color: DS.awayBlue),
                            const SizedBox(height: 4),
                            TimeoutDots(remaining: awayTimeouts),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
