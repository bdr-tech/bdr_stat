// ─── Shot Follow-Up Overlay ───────────────────────────────────────────────────
// 슛 후속 동작 오버레이: 성공/실패 → 어시스트/리바운드 선택.
// 모든 버튼 56-64px, 이전 버튼 위치 근처, 모든 탭에 햅틱.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/bdr_design_system.dart';
import '../recorder_state.dart';

// ─── Follow-Up Step ──────────────────────────────────────────────────────────

enum FollowUpStep {
  madeOrMissed, // 성공/실패 선택
  assist,       // 어시스트 선수 선택 (성공 후)
  rebound,      // 리바운드 선수/팀 선택 (실패/블락 후)
}

// ─── Follow-Up State ─────────────────────────────────────────────────────────

class FollowUpState {
  const FollowUpState({
    required this.position,
    required this.teamSide,
    required this.playerId,
    required this.playerName,
    required this.shotType,
    required this.step,
    this.fromBlock = false,
  });

  final Offset position;
  final String teamSide; // 슛한 팀 ('home' | 'away')
  final int playerId;    // 슈터 ID
  final String playerName;
  final String shotType; // '2pt', '3pt', '1pt'
  final FollowUpStep step;
  final bool fromBlock;  // BLK에서 왔는지

  FollowUpState copyWith({
    Offset? position,
    FollowUpStep? step,
    bool? fromBlock,
  }) {
    return FollowUpState(
      position: position ?? this.position,
      teamSide: teamSide,
      playerId: playerId,
      playerName: playerName,
      shotType: shotType,
      step: step ?? this.step,
      fromBlock: fromBlock ?? this.fromBlock,
    );
  }
}

// ─── Callbacks ───────────────────────────────────────────────────────────────

typedef OnShotResult = void Function(bool made);
typedef OnAssistSelect = void Function(int? assistPlayerId, String? assistPlayerName);
typedef OnReboundSelect = void Function(String reboundType, String teamSide, int? playerId, String? playerName);

// ─── Shot Follow-Up Overlay ──────────────────────────────────────────────────

class ShotFollowUpOverlay extends StatefulWidget {
  const ShotFollowUpOverlay({
    super.key,
    required this.followUp,
    required this.recordingState,
    required this.onShotResult,
    required this.onAssistSelect,
    required this.onReboundSelect,
    required this.onDismiss,
  });

  final FollowUpState followUp;
  final RecordingState recordingState;
  final OnShotResult onShotResult;
  final OnAssistSelect onAssistSelect;
  final OnReboundSelect onReboundSelect;
  final VoidCallback onDismiss;

  @override
  State<ShotFollowUpOverlay> createState() => _ShotFollowUpOverlayState();
}

class _ShotFollowUpOverlayState extends State<ShotFollowUpOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Stack(children: [
      // 반투명 배경 (탭으로 닫기 = 어시스트 없음 / 리바운드 없음)
      Positioned.fill(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (widget.followUp.step == FollowUpStep.assist) {
              widget.onAssistSelect(null, null); // 어시스트 없음
            } else if (widget.followUp.step == FollowUpStep.rebound) {
              widget.onDismiss(); // 리바운드 없음
            } else {
              widget.onDismiss();
            }
          },
          child: Container(color: Colors.black.withValues(alpha: 0.3)),
        ),
      ),

      // 오버레이 콘텐츠
      _buildContent(screenSize),
    ]);
  }

  Widget _buildContent(Size screenSize) {
    switch (widget.followUp.step) {
      case FollowUpStep.madeOrMissed:
        return _buildMadeOrMissed(screenSize);
      case FollowUpStep.assist:
        return _buildAssistSelect(screenSize);
      case FollowUpStep.rebound:
        return _buildReboundSelect(screenSize);
    }
  }

  // ─── 1. 성공/실패 선택 ─────────────────────────────────────────────────────

  Widget _buildMadeOrMissed(Size screenSize) {
    final pos = _clampPosition(widget.followUp.position, screenSize, 160);
    final shotLabel = _shotLabel(widget.followUp.shotType);

    return Positioned(
      left: pos.dx - 80,
      top: pos.dy - 36,
      child: ScaleTransition(
        scale: _scale,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FollowUpButton(
              label: '$shotLabel\n성공',
              icon: Icons.check_circle_rounded,
              color: DS.success,
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onShotResult(true);
              },
            ),
            const SizedBox(width: 12),
            _FollowUpButton(
              label: '$shotLabel\n실패',
              icon: Icons.cancel_rounded,
              color: DS.error,
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onShotResult(false);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── 2. 어시스트 선수 선택 ─────────────────────────────────────────────────

  Widget _buildAssistSelect(Size screenSize) {
    final pos = _clampPosition(widget.followUp.position, screenSize, 200);
    final shooterTeam = widget.followUp.teamSide;

    // 같은 팀의 나머지 선수 (슈터 제외)
    final teammates = shooterTeam == 'home'
        ? widget.recordingState.homePlayers
        : widget.recordingState.awayPlayers;
    final others = teammates
        .where((p) => (p['id'] as int) != widget.followUp.playerId)
        .toList();

    return Positioned(
      left: (pos.dx - 120).clamp(8, screenSize.width - 248),
      top: (pos.dy - 40).clamp(8, screenSize.height - 200),
      child: ScaleTransition(
        scale: _scale,
        child: GlassBox(
          borderRadius: DS.radiusMd,
          fillColor: DS.surface.withValues(alpha: 0.95),
          borderColor: DS.glassBorder,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '어시스트',
                style: DSText.jakartaBold(color: DS.textSecondary, size: 11),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: others.map((p) {
                  final id = p['id'] as int;
                  final num = '${p['jersey_number'] ?? '?'}';
                  final name = (p['name'] as String? ?? '').split(' ').last;
                  return _PlayerNumberButton(
                    number: num,
                    name: name,
                    color: shooterTeam == 'home' ? DS.homeRed : DS.awayBlue,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onAssistSelect(id, p['name'] as String?);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              Text(
                '배경 탭 = 어시스트 없음',
                style: DSText.jakartaLabel(color: DS.textHint, size: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 3. 리바운드 선수/팀 선택 ──────────────────────────────────────────────

  Widget _buildReboundSelect(Size screenSize) {
    final pos = _clampPosition(widget.followUp.position, screenSize, 200);
    final shooterTeam = widget.followUp.teamSide;
    final defenseTeam = shooterTeam == 'home' ? 'away' : 'home';

    final offensePlayers = shooterTeam == 'home'
        ? widget.recordingState.homePlayers
        : widget.recordingState.awayPlayers;
    final defensePlayers = defenseTeam == 'home'
        ? widget.recordingState.homePlayers
        : widget.recordingState.awayPlayers;

    final offenseTeamName = shooterTeam == 'home'
        ? widget.recordingState.homeTeamName
        : widget.recordingState.awayTeamName;
    final defenseTeamName = defenseTeam == 'home'
        ? widget.recordingState.homeTeamName
        : widget.recordingState.awayTeamName;

    return Positioned(
      left: (pos.dx - 140).clamp(8, screenSize.width - 288),
      top: (pos.dy - 60).clamp(8, screenSize.height - 320),
      child: ScaleTransition(
        scale: _scale,
        child: GlassBox(
          borderRadius: DS.radiusMd,
          fillColor: DS.surface.withValues(alpha: 0.95),
          borderColor: DS.glassBorder,
          padding: const EdgeInsets.all(10),
          child: SizedBox(
            width: 270,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    '리바운드',
                    style: DSText.jakartaBold(color: DS.textSecondary, size: 11),
                  ),
                ),
                const SizedBox(height: 8),

                // 수비 리바운드 (상대팀 = 수비팀 선수)
                Text(
                  '$defenseTeamName (수비 REB)',
                  style: DSText.jakartaLabel(color: DS.textHint, size: 9),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: defensePlayers.map((p) {
                    final id = p['id'] as int;
                    final num = '${p['jersey_number'] ?? '?'}';
                    final name = (p['name'] as String? ?? '').split(' ').last;
                    return _PlayerNumberButton(
                      number: num,
                      name: name,
                      color: defenseTeam == 'home' ? DS.homeRed : DS.awayBlue,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.onReboundSelect('rebound_def', defenseTeam, id, p['name'] as String?);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 8),
                Container(height: 1, color: DS.glassBorder),
                const SizedBox(height: 8),

                // 공격 리바운드 (슛팀 선수)
                Text(
                  '$offenseTeamName (공격 REB)',
                  style: DSText.jakartaLabel(color: DS.textHint, size: 9),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: offensePlayers.map((p) {
                    final id = p['id'] as int;
                    final num = '${p['jersey_number'] ?? '?'}';
                    final name = (p['name'] as String? ?? '').split(' ').last;
                    return _PlayerNumberButton(
                      number: num,
                      name: name,
                      color: shooterTeam == 'home' ? DS.homeRed : DS.awayBlue,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.onReboundSelect('rebound_off', shooterTeam, id, p['name'] as String?);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 8),
                Container(height: 1, color: DS.glassBorder),
                const SizedBox(height: 6),

                // 팀 리바운드 (터치아웃 → 공격권 가진 팀명 클릭)
                Text(
                  '팀 리바운드 (터치아웃)',
                  style: DSText.jakartaLabel(color: DS.textHint, size: 9),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _TeamReboundButton(
                        label: defenseTeamName,
                        color: defenseTeam == 'home' ? DS.homeRed : DS.awayBlue,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onReboundSelect('rebound_team', defenseTeam, null, null);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TeamReboundButton(
                        label: offenseTeamName,
                        color: shooterTeam == 'home' ? DS.homeRed : DS.awayBlue,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onReboundSelect('rebound_team', defenseTeam, null, null);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Offset _clampPosition(Offset pos, Size screen, double margin) {
    return Offset(
      pos.dx.clamp(margin, screen.width - margin),
      pos.dy.clamp(margin, screen.height - margin),
    );
  }

  String _shotLabel(String shotType) {
    switch (shotType) {
      case '2pt': return '2점';
      case '3pt': return '3점';
      case '1pt': return '자유투';
      default: return shotType;
    }
  }
}

// ─── Follow-Up Button (성공/실패) ────────────────────────────────────────────

class _FollowUpButton extends StatelessWidget {
  const _FollowUpButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScaleButton(
      onTap: onTap,
      child: GlassBox(
        borderRadius: DS.radiusMd,
        fillColor: color.withValues(alpha: 0.15),
        borderColor: color.withValues(alpha: 0.5),
        glowShadows: DS.glowColor(color, intensity: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: DSText.jakartaBold(color: color, size: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Player Number Button (56px) ─────────────────────────────────────────────

class _PlayerNumberButton extends StatelessWidget {
  const _PlayerNumberButton({
    required this.number,
    required this.name,
    required this.color,
    required this.onTap,
  });

  final String number;
  final String name;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScaleButton(
      onTap: onTap,
      child: GlassBox(
        borderRadius: DS.radiusSm,
        fillColor: color.withValues(alpha: 0.12),
        borderColor: color.withValues(alpha: 0.4),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$number',
                style: DSText.bebasSmall(color: color, size: 16),
              ),
              Text(
                name,
                style: DSText.jakartaLabel(color: DS.textSecondary, size: 8),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Team Rebound Button ─────────────────────────────────────────────────────

class _TeamReboundButton extends StatelessWidget {
  const _TeamReboundButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScaleButton(
      onTap: onTap,
      child: GlassBox(
        borderRadius: DS.radiusSm,
        fillColor: color.withValues(alpha: 0.1),
        borderColor: color.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Center(
          child: Text(
            label,
            style: DSText.jakartaBold(color: color, size: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
