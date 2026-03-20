// ─── Bench Row Widgets ────────────────────────────────────────────────────────
// Bench player chips with dual interaction:
//  • Single tap  → opens Air Command radial menu (stat recording)
//  • Long press + drag → substitution (drag onto court starter)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/bdr_design_system.dart';
import '../recorder_state.dart';

class BenchRow extends StatelessWidget {
  const BenchRow({
    super.key,
    required this.state,
    this.onPlayerTap,
  });

  final RecordingState state;

  /// Called when a bench player chip is tapped.
  /// Provides player data, team side, and screen position for radial menu.
  final void Function(
    Map<String, dynamic> player,
    String teamSide,
    Offset screenCenter,
  )? onPlayerTap;

  @override
  Widget build(BuildContext context) {
    final homeBench =
        state.homePlayers.where((p) => p['is_starter'] != true).toList();
    final awayBench =
        state.awayPlayers.where((p) => p['is_starter'] != true).toList();

    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: DS.surface,
        border: Border(top: BorderSide(color: DS.glassBorder, width: 1)),
      ),
      child: Row(children: [
        // HOME bench
        Expanded(
          child: _buildBenchSide('home', homeBench, DS.homeRed),
        ),
        Container(width: 1, color: DS.glassBorder),
        // AWAY bench
        Expanded(
          child: _buildBenchSide('away', awayBench, DS.awayBlue),
        ),
      ]),
    );
  }

  Widget _buildBenchSide(
    String teamSide,
    List<Map<String, dynamic>> bench,
    Color color,
  ) {
    if (bench.isEmpty) {
      return Center(
        child: Text(
          'BENCH',
          style: DSText.jakartaLabel(color: DS.textHint, size: 9),
        ),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      itemCount: bench.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (ctx, i) => BenchPlayerChip(
        player: bench[i],
        teamSide: teamSide,
        color: color,
        onPlayerTap: onPlayerTap,
      ),
    );
  }
}

// ─── Bench Player Chip ────────────────────────────────────────────────────────

class BenchPlayerChip extends StatelessWidget {
  const BenchPlayerChip({
    super.key,
    required this.player,
    required this.teamSide,
    required this.color,
    this.onPlayerTap,
  });

  final Map<String, dynamic> player;
  final String teamSide;
  final Color color;
  final void Function(
    Map<String, dynamic> player,
    String teamSide,
    Offset screenCenter,
  )? onPlayerTap;

  @override
  Widget build(BuildContext context) {
    final num = '${player['jersey_number'] ?? '?'}';
    final name = (player['name'] as String? ?? '').split(' ').last;

    return GestureDetector(
      onTapDown: onPlayerTap != null
          ? (details) {
              HapticFeedback.lightImpact();
              onPlayerTap!(player, teamSide, details.globalPosition);
            }
          : null,
      child: _buildChip(color, num, name),
    );
  }

  Widget _buildChip(Color color, String num, String name,
      {double opacity = 1.0}) {
    return Opacity(
      opacity: opacity,
      child: GlassBox(
        borderRadius: DS.radiusSm,
        fillColor: color.withValues(alpha: 0.15),
        borderColor: color.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('#$num',
                style: DSText.bebasSmall(color: color, size: 13)),
            const SizedBox(width: 3),
            Text(
              name,
              style: DSText.jakartaLabel(color: DS.textSecondary, size: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
