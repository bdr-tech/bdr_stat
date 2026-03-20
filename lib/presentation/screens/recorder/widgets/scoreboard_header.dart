// ─── Scoreboard Header ────────────────────────────────────────────────────────
// Full-width interactive scoreboard occupying ~30% of screen height.
// Absorbs all controls previously in LeftHandZone + MiniScoreboard.
//
// Touch interactions:
//  • Quarter label  → quarter change dialog
//  • Shot clock     → start / stop toggle
//  • [24s] [14s]    → reset shot clock
//  • Timeout dots   → record timeout for that team

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/bdr_design_system.dart';
import '../recorder_state.dart';
import 'score_board.dart';

class ScoreboardHeader extends StatelessWidget {
  const ScoreboardHeader({
    super.key,
    required this.state,
    required this.onShotClockToggle,
    required this.onReset24,
    required this.onReset14,
    required this.onQuarterChange,
    required this.onTimeout,
  });

  final RecordingState state;
  final VoidCallback onShotClockToggle;
  final VoidCallback onReset24;
  final VoidCallback onReset14;
  final void Function(int quarter) onQuarterChange;
  final void Function(String teamSide) onTimeout;

  @override
  Widget build(BuildContext context) {
    final isLive = state.matchStatus == 'in_progress';
    final sc = state.shotClockSeconds;
    final scColor = sc <= 5
        ? DS.error
        : sc <= 10
            ? DS.warning
            : DS.gold;

    final m = (state.elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (state.elapsedSeconds % 60).toString().padLeft(2, '0');
    final clockLabel = '$m:$s';

    final quarterLabel = state.currentQuarter <= 4
        ? 'Q${state.currentQuarter}'
        : 'OT${state.currentQuarter - 4}';

    return Container(
      decoration: BoxDecoration(
        color: DS.surface,
        border: const Border(
          bottom: BorderSide(color: DS.glassBorder, width: 1),
        ),
      ),
      child: Stack(
        children: [
          // Team color gradient overlays
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          DS.homeRed.withValues(alpha: 0.06),
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
                          DS.awayBlue.withValues(alpha: 0.06),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── HOME side ──────────────────────────────────────────────
                Expanded(
                  child: _TeamColumn(
                    teamName: state.homeTeamName,
                    score: state.homeScore,
                    fouls: state.homeTeamFouls,
                    timeouts: state.homeTimeouts,
                    teamColor: DS.homeRed,
                    isHome: true,
                    isLive: isLive,
                    onTimeout: () {
                      if (isLive && state.homeTimeouts > 0) {
                        HapticFeedback.mediumImpact();
                        onTimeout('home');
                      }
                    },
                  ),
                ),

                // ── Center controls ────────────────────────────────────────
                SizedBox(
                  width: 130,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Status + Quarter
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StatusChip(status: state.matchStatus),
                          if (isLive) ...[
                            const SizedBox(width: 8),
                            TapScaleButton(
                              onTap: isLive
                                  ? () {
                                      HapticFeedback.selectionClick();
                                      onQuarterChange(state.currentQuarter);
                                    }
                                  : null,
                              child: GlassBox(
                                borderRadius: DS.radiusSm,
                                fillColor: DS.gold.withValues(alpha: 0.12),
                                borderColor: DS.gold.withValues(alpha: 0.4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                child: Text(
                                  quarterLabel,
                                  style: DSText.bebasSmall(
                                      color: DS.gold, size: 13),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Game clock
                      if (isLive) ...[
                        const SizedBox(height: 4),
                        Text(
                          clockLabel,
                          style: DSText.rajdhaniClock(
                            color: state.isTimerRunning
                                ? DS.textPrimary
                                : DS.textHint,
                            size: 18,
                          ),
                        ),
                      ],

                      // Shot clock
                      if (isLive) ...[
                        const SizedBox(height: 6),
                        TapScaleButton(
                          onTap: onShotClockToggle,
                          scaleFactor: 0.93,
                          child: GlassBox(
                            borderRadius: DS.radiusMd,
                            fillColor: scColor.withValues(alpha: 0.1),
                            borderColor: scColor.withValues(
                                alpha: state.isShotClockRunning ? 0.55 : 0.25),
                            glowShadows: state.isShotClockRunning
                                ? DS.glowColor(scColor, intensity: 0.5)
                                : [],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  state.isShotClockRunning
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: scColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  sc.toString().padLeft(2, '0'),
                                  style: DSText.rajdhaniLarge(
                                      color: scColor, size: 30),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Reset buttons
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ResetButton(
                                label: '24s', onTap: onReset24),
                            const SizedBox(width: 6),
                            _ResetButton(
                                label: '14s', onTap: onReset14),
                          ],
                        ),
                      ],

                      if (!isLive) ...[
                        const SizedBox(height: 8),
                        // Quarter selector when not live
                        _QuarterSelector(
                          currentQuarter: state.currentQuarter,
                          onQuarterChange: onQuarterChange,
                          enabled: false,
                        ),
                      ],
                    ],
                  ),
                ),

                // ── AWAY side ──────────────────────────────────────────────
                Expanded(
                  child: _TeamColumn(
                    teamName: state.awayTeamName,
                    score: state.awayScore,
                    fouls: state.awayTeamFouls,
                    timeouts: state.awayTimeouts,
                    teamColor: DS.awayBlue,
                    isHome: false,
                    isLive: isLive,
                    onTimeout: () {
                      if (isLive && state.awayTimeouts > 0) {
                        HapticFeedback.mediumImpact();
                        onTimeout('away');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Team Column ──────────────────────────────────────────────────────────────

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({
    required this.teamName,
    required this.score,
    required this.fouls,
    required this.timeouts,
    required this.teamColor,
    required this.isHome,
    required this.isLive,
    required this.onTimeout,
  });

  final String teamName;
  final int score;
  final int fouls;
  final int timeouts;
  final Color teamColor;
  final bool isHome;
  final bool isLive;
  final VoidCallback onTimeout;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 팀명 + 팀파울 (상단)
        Text(
          teamName.toUpperCase(),
          style: DSText.bebasMedium(color: teamColor, size: 14),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        FoulDots(fouls: fouls, color: teamColor),

        const SizedBox(height: 4),

        // 점수 (중간, 크게)
        AnimatedScore(score: score, color: Colors.white, fontSize: 52),

        const SizedBox(height: 4),

        // 타임아웃 (하단, 전/후반 구분)
        TapScaleButton(
          onTap: isLive && timeouts > 0 ? onTimeout : null,
          child: Opacity(
            opacity: isLive ? 1.0 : 0.4,
            child: TimeoutDots(remaining: timeouts),
          ),
        ),
      ],
    );
  }
}

// ─── Reset Button ─────────────────────────────────────────────────────────────

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScaleButton(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: GlassBox(
        borderRadius: DS.radiusSm,
        fillColor: DS.glassFill,
        borderColor: DS.glassBorder,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          '↺ $label',
          style: DSText.jakartaLabel(color: DS.textSecondary, size: 10),
        ),
      ),
    );
  }
}

// ─── Quarter Selector (compact, inline) ──────────────────────────────────────

class _QuarterSelector extends StatelessWidget {
  const _QuarterSelector({
    required this.currentQuarter,
    required this.onQuarterChange,
    required this.enabled,
  });

  final int currentQuarter;
  final void Function(int) onQuarterChange;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 3,
      children: List.generate(5, (i) {
        final q = i + 1;
        final label = q <= 4 ? 'Q$q' : 'OT1';
        final isSelected = currentQuarter == q;
        return TapScaleButton(
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onQuarterChange(q);
                }
              : null,
          child: GlassBox(
            borderRadius: DS.radiusSm,
            fillColor: isSelected
                ? DS.gold.withValues(alpha: 0.15)
                : DS.glassFill,
            borderColor: isSelected
                ? DS.gold.withValues(alpha: 0.5)
                : DS.glassBorder,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              label,
              style: DSText.bebasSmall(
                color: isSelected ? DS.gold : DS.textHint,
                size: 11,
              ),
            ),
          ),
        );
      }),
    );
  }
}
