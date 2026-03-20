// ─── Left Hand Zone ───────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/bdr_design_system.dart';
import '../recorder_state.dart';

class LeftHandZone extends StatelessWidget {
  const LeftHandZone({
    super.key,
    required this.state,
    required this.onStartStop,
    required this.onReset24,
    required this.onReset14,
    required this.onQuarterChange,
    required this.onTimeout,
  });

  final RecordingState state;
  final VoidCallback onStartStop;
  final VoidCallback onReset24;
  final VoidCallback onReset14;
  final void Function(int q) onQuarterChange;
  final void Function(String teamSide) onTimeout;

  @override
  Widget build(BuildContext context) {
    final isPlaying = state.matchStatus == 'in_progress';
    final sc = state.shotClockSeconds;
    final scColor = sc <= 5
        ? DS.error
        : sc <= 10
            ? DS.gold
            : DS.success;

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: DS.surface,
        border: const Border(top: BorderSide(color: DS.glassBorder, width: 1)),
      ),
      child: Row(children: [
        // 샷클락 리셋 버튼
        const SizedBox(width: 8),
        LHZButton(
          label: '14s ↺',
          color: DS.awayBlue,
          onTap: isPlaying ? onReset14 : null,
        ),
        const SizedBox(width: 6),
        LHZButton(
          label: '24s ↺',
          color: DS.success,
          onTap: isPlaying ? onReset24 : null,
        ),
        const SizedBox(width: 6),

        // 샷클락 메가 버튼 (▶/⏸ + 초)
        TapScaleButton(
          onTap: isPlaying ? onStartStop : null,
          child: GlassBox(
            borderRadius: DS.radiusSm,
            fillColor: scColor.withValues(alpha: 0.1),
            borderColor: scColor.withValues(alpha: 0.4),
            glowShadows: isPlaying ? DS.glowColor(scColor, intensity: 0.4) : [],
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  state.isShotClockRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: scColor,
                  size: 22,
                ),
                Text(
                  '$sc',
                  style: DSText.rajdhaniClock(color: scColor, size: 16),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),

        // 쿼터 선택
        Expanded(
          child: SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (ctx, i) {
                final q = i + 1;
                final label = q <= 4 ? 'Q$q' : 'OT${q - 4}';
                final isSelected = state.currentQuarter == q;
                return TapScaleButton(
                  onTap: isPlaying
                      ? () {
                          HapticFeedback.selectionClick();
                          onQuarterChange(q);
                        }
                      : null,
                  child: GlassBox(
                    borderRadius: DS.radiusMd,
                    fillColor: isSelected
                        ? DS.gold.withValues(alpha: 0.15)
                        : DS.glassFill,
                    borderColor: isSelected
                        ? DS.gold.withValues(alpha: 0.5)
                        : DS.glassBorder,
                    glowShadows:
                        isSelected ? DS.glowGold(intensity: 0.4) : [],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    child: Text(
                      label,
                      style: DSText.bebasSmall(
                        color: isSelected ? DS.gold : DS.textSecondary,
                        size: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // 타임아웃 버튼
        const SizedBox(width: 6),
        LHZButton(
          label: 'H\nTO(${state.homeTimeouts})',
          color: DS.homeRed,
          onTap: isPlaying && state.homeTimeouts > 0
              ? () => onTimeout('home')
              : null,
        ),
        const SizedBox(width: 6),
        LHZButton(
          label: 'A\nTO(${state.awayTimeouts})',
          color: DS.awayBlue,
          onTap: isPlaying && state.awayTimeouts > 0
              ? () => onTimeout('away')
              : null,
        ),
        const SizedBox(width: 8),
      ]),
    );
  }
}

class LHZButton extends StatelessWidget {
  const LHZButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return TapScaleButton(
      onTap: onTap,
      child: GlassBox(
        borderRadius: DS.radiusSm,
        fillColor: active ? color.withValues(alpha: 0.1) : DS.glassFill,
        borderColor: active ? color.withValues(alpha: 0.4) : DS.glassBorder,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          label,
          style: DSText.jakartaButton(
            color: active ? color : DS.textHint,
            size: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
