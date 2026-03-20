// ─── Team Picker Sheet ────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/bdr_design_system.dart';

class TeamPickerSheet extends StatefulWidget {
  const TeamPickerSheet({
    super.key,
    required this.eventLabel,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homePlayers,
    required this.awayPlayers,
    required this.onPick,
    this.onToggleStarter,
  });

  final String eventLabel;
  final String homeTeamName;
  final String awayTeamName;
  final List<Map<String, dynamic>> homePlayers;
  final List<Map<String, dynamic>> awayPlayers;
  final void Function(String teamSide, int? playerId, String? playerName) onPick;
  final void Function(String teamSide, int playerId)? onToggleStarter;

  @override
  State<TeamPickerSheet> createState() => _TeamPickerSheetState();
}

class _TeamPickerSheetState extends State<TeamPickerSheet> {
  String? _selectedTeam;
  final _sheetController = DraggableScrollableController();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _selectTeam(String teamSide) {
    setState(() => _selectedTeam = teamSide);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sheetController.isAttached) {
        _sheetController.animateTo(
          0.75,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _goBack() {
    setState(() => _selectedTeam = null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sheetController.isAttached) {
        _sheetController.animateTo(
          0.38,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.38,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scroll) => Column(
        children: [
          // 핸들 + 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.textHint,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (_selectedTeam != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 18),
                        onPressed: _goBack,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    if (_selectedTeam != null) const SizedBox(width: 8),
                    Text(
                      _selectedTeam == null
                          ? '${widget.eventLabel} — 팀 선택'
                          : '${widget.eventLabel} — ${_selectedTeam == 'home' ? widget.homeTeamName : widget.awayTeamName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _selectedTeam == null
                ? _buildTeamSelector()
                : _buildPlayerSelector(scroll),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TeamButton(
              label: widget.homeTeamName,
              sublabel: 'HOME · ${widget.homePlayers.where((p) => p['is_starter'] == true).length}명 선발',
              color: AppTheme.primaryColor,
              onTap: () {
                HapticFeedback.lightImpact();
                if (widget.homePlayers.isEmpty) {
                  widget.onPick('home', null, null);
                } else {
                  _selectTeam('home');
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TeamButton(
              label: widget.awayTeamName,
              sublabel: 'AWAY · ${widget.awayPlayers.where((p) => p['is_starter'] == true).length}명 선발',
              color: AppTheme.secondaryColor,
              onTap: () {
                HapticFeedback.lightImpact();
                if (widget.awayPlayers.isEmpty) {
                  widget.onPick('away', null, null);
                } else {
                  _selectTeam('away');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSelector(ScrollController scroll) {
    final teamSide = _selectedTeam!;
    final players = teamSide == 'home' ? widget.homePlayers : widget.awayPlayers;
    final starters = players.where((p) => p['is_starter'] == true).toList();
    final bench = players.where((p) => p['is_starter'] != true).toList();

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // 선수 미지정
        ListTile(
          leading: const Icon(Icons.person_outline, color: AppTheme.textSecondary),
          title: const Text('선수 미지정', style: TextStyle(color: AppTheme.textSecondary)),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onPick(teamSide, null, null);
          },
        ),
        const Divider(height: 1),

        // 선발 섹션
        SectionHeader(
          label: '선발',
          count: starters.length,
          color: AppTheme.successColor,
        ),
        ...starters.map((p) => PlayerTile(
          player: p,
          teamSide: teamSide,
          isStarter: true,
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onPick(teamSide, p['id'] as int?, p['name'] as String?);
          },
          onToggle: widget.onToggleStarter == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  widget.onToggleStarter!(teamSide, p['id'] as int);
                  setState(() {}); // 시각 즉시 반영
                },
        )),

        if (starters.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('선발 없음', style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
          ),

        const Divider(height: 1),

        // 후보 섹션
        SectionHeader(
          label: '후보',
          count: bench.length,
          color: AppTheme.textSecondary,
        ),
        ...bench.map((p) => PlayerTile(
          player: p,
          teamSide: teamSide,
          isStarter: false,
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onPick(teamSide, p['id'] as int?, p['name'] as String?);
          },
          onToggle: widget.onToggleStarter == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  widget.onToggleStarter!(teamSide, p['id'] as int);
                  setState(() {});
                },
        )),

        if (bench.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('후보 없음', style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
          ),
      ],
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            width: 4, height: 14,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          Text(
            '$label ($count명)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Player Tile ──────────────────────────────────────────────────────────────

class PlayerTile extends StatelessWidget {
  const PlayerTile({
    super.key,
    required this.player,
    required this.teamSide,
    required this.isStarter,
    required this.onTap,
    this.onToggle,
  });

  final Map<String, dynamic> player;
  final String teamSide;
  final bool isStarter;
  final VoidCallback onTap;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final name = player['name'] as String? ?? '선수';
    final number = player['jersey_number'] as int?;
    final accentColor = teamSide == 'home' ? AppTheme.primaryColor : AppTheme.secondaryColor;

    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: accentColor.withValues(alpha: 0.12),
        child: Text(
          number != null ? '#$number' : '?',
          style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: player['position'] != null
          ? Text(player['position'] as String, style: const TextStyle(fontSize: 12))
          : null,
      trailing: onToggle != null
          ? Tooltip(
              message: isStarter ? '후보로 변경' : '선발로 변경',
              child: IconButton(
                icon: Icon(
                  isStarter ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 18,
                  color: isStarter ? AppTheme.textSecondary : AppTheme.successColor,
                ),
                onPressed: onToggle,
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}

// ─── Team Button ──────────────────────────────────────────────────────────────

class TeamButton extends StatelessWidget {
  const TeamButton({
    super.key,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScaleButton(
      onTap: onTap,
      child: GlassBox(
        borderRadius: DS.radiusMd,
        blur: DS.blurRadius,
        fillColor: color.withValues(alpha: 0.10),
        borderColor: color.withValues(alpha: 0.35),
        glowShadows: DS.glowColor(color, intensity: 0.3),
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: DSText.bebasMedium(color: color, size: 22),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              sublabel,
              style: DSText.jakartaLabel(color: color.withValues(alpha: 0.6), size: 10),
            ),
          ],
        ),
      ),
    );
  }
}
