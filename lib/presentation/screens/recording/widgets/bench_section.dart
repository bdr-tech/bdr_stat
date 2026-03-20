import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../widgets/action_menu/radial_action_menu.dart';
import '../models/player_with_stats.dart';

/// 벤치 섹션 - 양팀 벤치 선수 + 팀파울 + 타임아웃 (Sprint 2: FR-008, FR-009)
class BenchSection extends StatelessWidget {
  const BenchSection({
    super.key,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeBenchPlayers,
    required this.awayBenchPlayers,
    required this.onPlayerTap,
    required this.onRadialAction,
    this.onFoulSubtypeSelected,
    this.onTimeoutCalled,
    this.homeTeamColor = const Color(0xFFF97316),
    this.awayTeamColor = const Color(0xFF6366F1),
    this.homeTeamFouls = 0,
    this.awayTeamFouls = 0,
    this.homeTimeoutsRemaining = 2,
    this.awayTimeoutsRemaining = 2,
    this.homeTimeoutsMax = 2,
    this.awayTimeoutsMax = 2,
    this.foulBonusThreshold = 5,
  });

  final String homeTeamName;
  final String awayTeamName;
  final List<PlayerWithStats> homeBenchPlayers;
  final List<PlayerWithStats> awayBenchPlayers;
  final void Function(PlayerWithStats, bool isHome) onPlayerTap;
  final void Function(RadialAction action, PlayerWithStats player, bool isHome) onRadialAction;
  final void Function(RadialAction foulSubtype, PlayerWithStats player, bool isHome)? onFoulSubtypeSelected;
  final void Function(bool isHome)? onTimeoutCalled;
  final Color homeTeamColor;
  final Color awayTeamColor;
  final int homeTeamFouls;
  final int awayTeamFouls;
  final int homeTimeoutsRemaining;
  final int awayTimeoutsRemaining;
  final int homeTimeoutsMax;
  final int awayTimeoutsMax;
  final int foulBonusThreshold;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 홈팀 벤치
          Expanded(
            child: _BenchTeamPanel(
              teamName: homeTeamName,
              players: homeBenchPlayers,
              teamColor: homeTeamColor,
              isHome: true,
              teamFouls: homeTeamFouls,
              timeoutsRemaining: homeTimeoutsRemaining,
              timeoutsMax: homeTimeoutsMax,
              foulBonusThreshold: foulBonusThreshold,
              onPlayerTap: (player) => onPlayerTap(player, true),
              onRadialAction: (action, player) => onRadialAction(action, player, true),
              onFoulSubtypeSelected: onFoulSubtypeSelected != null
                  ? (foulSubtype, player) => onFoulSubtypeSelected!(foulSubtype, player, true)
                  : null,
              onTimeoutCalled: onTimeoutCalled != null
                  ? () => onTimeoutCalled!(true)
                  : null,
            ),
          ),

          // 구분선
          Container(
            width: 1,
            color: AppTheme.borderColor,
          ),

          // 원정팀 벤치
          Expanded(
            child: _BenchTeamPanel(
              teamName: awayTeamName,
              players: awayBenchPlayers,
              teamColor: awayTeamColor,
              isHome: false,
              teamFouls: awayTeamFouls,
              timeoutsRemaining: awayTimeoutsRemaining,
              timeoutsMax: awayTimeoutsMax,
              foulBonusThreshold: foulBonusThreshold,
              onPlayerTap: (player) => onPlayerTap(player, false),
              onRadialAction: (action, player) => onRadialAction(action, player, false),
              onFoulSubtypeSelected: onFoulSubtypeSelected != null
                  ? (foulSubtype, player) => onFoulSubtypeSelected!(foulSubtype, player, false)
                  : null,
              onTimeoutCalled: onTimeoutCalled != null
                  ? () => onTimeoutCalled!(false)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// 개별 팀 벤치 패널 (Sprint 2: 파울 + 타임아웃 + 선수)
class _BenchTeamPanel extends StatelessWidget {
  const _BenchTeamPanel({
    required this.teamName,
    required this.players,
    required this.teamColor,
    required this.isHome,
    required this.onPlayerTap,
    required this.onRadialAction,
    this.onFoulSubtypeSelected,
    this.onTimeoutCalled,
    this.teamFouls = 0,
    this.timeoutsRemaining = 2,
    this.timeoutsMax = 2,
    this.foulBonusThreshold = 5,
  });

  final String teamName;
  final List<PlayerWithStats> players;
  final Color teamColor;
  final bool isHome;
  final void Function(PlayerWithStats) onPlayerTap;
  final void Function(RadialAction action, PlayerWithStats player) onRadialAction;
  final void Function(RadialAction foulSubtype, PlayerWithStats player)? onFoulSubtypeSelected;
  final VoidCallback? onTimeoutCalled;
  final int teamFouls;
  final int timeoutsRemaining;
  final int timeoutsMax;
  final int foulBonusThreshold;

  bool get _isInBonus => teamFouls >= foulBonusThreshold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Layer 1: 벤치 선수 아이콘들 (스타팅과 동일한 버튼 모양)
          SizedBox(
            height: 52,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: players.map((player) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _BenchPlayerIcon(
                      player: player,
                      teamColor: teamColor,
                      isHome: isHome,
                      onTap: () => onPlayerTap(player),
                      onRadialAction: (action) => onRadialAction(action, player),
                      onFoulSubtypeSelected: onFoulSubtypeSelected != null
                          ? (foulSubtype) => onFoulSubtypeSelected!(foulSubtype, player)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Layer 2: 타임아웃 버튼 + 팀파울 (한 줄)
          Row(
            children: [
              Expanded(child: _buildTimeoutButton()),
              const SizedBox(width: 6),
              _buildCompactFoulIndicator(),
            ],
          ),
        ],
      ),
    );
  }

  /// 간결한 팀파울 인디케이터: "PF: 3/5" 형태
  Widget _buildCompactFoulIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: _isInBonus
            ? AppTheme.warningColor.withValues(alpha: 0.1)
            : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: _isInBonus
            ? Border.all(color: AppTheme.warningColor, width: 1.5)
            : Border.all(color: AppTheme.borderColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PF: $teamFouls/$foulBonusThreshold',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _isInBonus ? AppTheme.warningColor : AppTheme.textSecondary,
            ),
          ),
          if (_isInBonus) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.warningColor,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'B',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 타임아웃 호출 버튼 (FR-008)
  Widget _buildTimeoutButton() {
    final isActive = timeoutsRemaining > 0 && onTimeoutCalled != null;

    return GestureDetector(
      onTap: isActive ? onTimeoutCalled : null,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: isActive
              ? teamColor.withValues(alpha: 0.15)
              : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? teamColor.withValues(alpha: 0.3)
                : Colors.grey[700]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_off,
              size: 14,
              color: isActive ? teamColor : Colors.grey[500],
            ),
            const SizedBox(width: 4),
            Text(
              isActive ? 'T/O' : 'T/O 없음',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? teamColor : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 벤치 선수 아이콘 (Sprint 2: sprintTwoActions 사용)
class _BenchPlayerIcon extends StatelessWidget {
  const _BenchPlayerIcon({
    required this.player,
    required this.teamColor,
    required this.isHome,
    required this.onTap,
    required this.onRadialAction,
    this.onFoulSubtypeSelected,
  });

  final PlayerWithStats player;
  final Color teamColor;
  final bool isHome;
  final VoidCallback onTap;
  final void Function(RadialAction action) onRadialAction;
  final void Function(RadialAction foulSubtype)? onFoulSubtypeSelected;

  static const double _iconSize = 44.0;

  @override
  Widget build(BuildContext context) {
    final bool isFouledOut = player.stats.personalFouls >= 5;

    return RadialActionMenu(
      actions: RadialAction.sprintTwoActions,
      onActionSelected: onRadialAction,
      onFoulSubtypeSelected: onFoulSubtypeSelected,
      menuRadius: 100,
      buttonRadius: 26,
      playerFouls: player.stats.personalFouls,
      foulOutLimit: 5,
      centerWidget: Center(
        child: Text(
          '${player.player.jerseyNumber ?? '-'}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: teamColor,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: isFouledOut ? null : onTap,
        child: Opacity(
          opacity: isFouledOut ? 0.4 : 1.0,
          child: Container(
            width: _iconSize,
            height: _iconSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFouledOut ? Colors.grey[700] : teamColor,
              border: Border.all(
                color: isFouledOut
                    ? Colors.grey[600]!
                    : _lighten(teamColor, 0.2),
                width: 2,
              ),
              boxShadow: isFouledOut
                  ? null
                  : [
                      BoxShadow(
                        color: teamColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ],
            ),
            child: Center(
              child: Text(
                '${player.player.jerseyNumber ?? '-'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}
