// ─── Event Log Widgets ────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/theme/bdr_design_system.dart';
import '../event_definitions.dart';
import '../recorder_state.dart';

class EventLog extends StatelessWidget {
  const EventLog({
    super.key,
    required this.events,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  final List<RecordingEventItem> events;
  final String homeTeamName;
  final String awayTeamName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 13, color: DS.gold),
              const SizedBox(width: 5),
              Text('PLAY LOG', style: DSText.jakartaLabel(color: DS.gold, size: 10)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            itemCount: events.length,
            itemBuilder: (context, index) => SlideInItem(
              delay: index == 0 ? Duration.zero : Duration(milliseconds: index * 20),
              child: EventLogItem(
                event: events[index],
                homeTeamName: homeTeamName,
                awayTeamName: awayTeamName,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class EventLogItem extends StatelessWidget {
  const EventLogItem({
    super.key,
    required this.event,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  final RecordingEventItem event;
  final String homeTeamName;
  final String awayTeamName;

  @override
  Widget build(BuildContext context) {
    final def = eventDefs.firstWhere(
      (d) => d.type == event.eventType,
      orElse: () => EventDef(event.eventType, event.eventType, Icons.circle, DS.textHint),
    );

    final teamLabel = switch (event.teamSide) {
      'home' => homeTeamName,
      'away' => awayTeamName,
      _ => '',
    };

    final teamColor = event.teamSide == 'home' ? DS.homeRed : DS.awayBlue;

    final quarterLabel = event.quarter != null
        ? (event.quarter! <= 4 ? 'Q${event.quarter}' : 'OT${event.quarter! - 4}')
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: GlassBox(
        borderRadius: DS.radiusSm,
        blur: DS.blurRadiusSm,
        fillColor: DS.glassFill,
        borderColor: teamLabel.isNotEmpty
            ? teamColor.withValues(alpha: 0.2)
            : DS.glassBorder,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            // 팀 컬러 인디케이터
            if (teamLabel.isNotEmpty)
              Container(
                width: 2.5,
                height: 20,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: teamColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            Icon(def.icon, color: def.color, size: 14),
            const SizedBox(width: 7),
            Expanded(
              child: Row(
                children: [
                  Text(
                    def.label,
                    style: DSText.jakartaButton(
                      color: event.isPending ? DS.warning : DS.textPrimary,
                      size: 11,
                    ),
                  ),
                  if (event.playerName != null) ...[
                    const SizedBox(width: 5),
                    Text(
                      event.playerName!,
                      style: DSText.jakartaBody(color: DS.textSecondary, size: 11),
                    ),
                  ],
                  if (teamLabel.isNotEmpty) ...[
                    const SizedBox(width: 5),
                    Text(
                      teamLabel,
                      style: DSText.jakartaLabel(color: teamColor, size: 10),
                    ),
                  ],
                ],
              ),
            ),
            if (event.isPending)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.cloud_off_rounded, size: 11, color: DS.warning),
              ),
            if (quarterLabel != null)
              Text(quarterLabel, style: DSText.jakartaLabel(color: DS.textHint, size: 9)),
            const SizedBox(width: 4),
            Text(
              event.gameTime ?? _formatTime(event.createdAt),
              style: DSText.jakartaLabel(color: DS.textHint, size: 9),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
  }
}
