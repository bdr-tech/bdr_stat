// ─── Right Panel ──────────────────────────────────────────────────────────────
// Slim event log panel on the right side of the court.
// Scoreboard has been moved to ScoreboardHeader (top 30%).

import 'package:flutter/material.dart';

import '../../../../core/theme/bdr_design_system.dart';
import '../recorder_state.dart';
import 'event_log.dart';
// score_board re-exports for external usage
export 'score_board.dart' show FoulDots, TimeoutDots, StatusChip;

class RightPanel extends StatelessWidget {
  const RightPanel({
    super.key,
    required this.state,
    required this.onUndo,
  });

  final RecordingState state;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Undo header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: const BoxDecoration(
          color: DS.surface,
          border: Border(bottom: BorderSide(color: DS.glassBorder, width: 1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt_rounded, size: 12, color: DS.gold),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'LOG',
                style: DSText.jakartaLabel(color: DS.gold, size: 10),
              ),
            ),
            TapScaleButton(
              onTap: state.events.isNotEmpty ? onUndo : null,
              child: Icon(
                Icons.undo_rounded,
                size: 18,
                color: state.events.isNotEmpty
                    ? DS.textSecondary
                    : DS.textHint,
              ),
            ),
          ],
        ),
      ),

      // Event log
      Expanded(
        child: EventLog(
          events: state.events,
          homeTeamName: state.homeTeamName,
          awayTeamName: state.awayTeamName,
        ),
      ),
    ]);
  }
}
