import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/score_utils.dart';
import '../../../../data/database/database.dart';
import '../../../widgets/action_menu/radial_action_menu.dart';
import '../models/player_with_stats.dart';

/// 팀 선수 패널 (리스트 형태 - 경기 중 선수 상단, 벤치 하단)
class TeamPlayersPanel extends StatelessWidget {
  const TeamPlayersPanel({
    super.key,
    required this.team,
    required this.players,
    required this.isHome,
    required this.onPlayerTap,
    required this.onRadialAction,
  });

  final LocalTournamentTeam? team;
  final List<PlayerWithStats> players;
  final bool isHome;
  final void Function(PlayerWithStats, bool) onPlayerTap;
  final void Function(RadialAction action, PlayerWithStats player, bool isHome) onRadialAction;

  @override
  Widget build(BuildContext context) {
    // 코트 위 선수와 벤치 선수 분리
    final onCourt = players.where((p) => p.stats.isOnCourt).toList();
    final bench = players.where((p) => !p.stats.isOnCourt).toList();

    return Container(
      color: AppTheme.surfaceColor,
      child: Column(
        children: [
          // 팀 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isHome
                  ? AppTheme.homeTeamColor
                  : AppTheme.awayTeamColor,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    team?.teamName ?? (isHome ? '홈' : '원정'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PF: ${onCourt.fold<int>(0, (sum, p) => sum + p.stats.personalFouls)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ON COURT 섹션 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: isHome
                ? AppTheme.homeTeamColor.withValues(alpha: 0.1)
                : AppTheme.awayTeamColor.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(
                  Icons.sports_basketball,
                  size: 12,
                  color: isHome ? AppTheme.homeTeamColor : AppTheme.awayTeamColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'ON COURT (${onCourt.length})',
                  style: TextStyle(
                    fontSize: 10,
                    color: isHome ? AppTheme.homeTeamColor : AppTheme.awayTeamColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 코트 위 선수 리스트 (세로 스크롤)
          Expanded(
            flex: 3,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: onCourt.length,
              itemBuilder: (context, index) {
                final p = onCourt[index];
                return PlayerListItem(
                  player: p,
                  isHome: isHome,
                  isOnCourt: true,
                  onTap: () => onPlayerTap(p, isHome),
                  onRadialAction: (action) => onRadialAction(action, p, isHome),
                );
              },
            ),
          ),

          // 벤치 구분선
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: AppTheme.backgroundColor,
            child: Row(
              children: [
                Icon(
                  Icons.event_seat,
                  size: 12,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'BENCH (${bench.length})',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppTheme.dividerColor,
                  ),
                ),
              ],
            ),
          ),

          // 벤치 선수 리스트 (세로 스크롤)
          Expanded(
            flex: 2,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: bench.length,
              itemBuilder: (context, index) {
                final p = bench[index];
                return PlayerListItem(
                  player: p,
                  isHome: isHome,
                  isOnCourt: false,
                  onTap: () => onPlayerTap(p, isHome),
                  onRadialAction: (action) => onRadialAction(action, p, isHome),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 선수 리스트 아이템 (간결한 리스트 형태)
class PlayerListItem extends StatelessWidget {
  const PlayerListItem({
    super.key,
    required this.player,
    required this.isHome,
    required this.isOnCourt,
    required this.onTap,
    required this.onRadialAction,
  });

  final PlayerWithStats player;
  final bool isHome;
  final bool isOnCourt;
  final VoidCallback onTap;
  final void Function(RadialAction action) onRadialAction;

  static const int _maxFouls = 5;
  bool get _isFouledOut => player.stats.personalFouls >= _maxFouls;
  bool get _isWarning => player.stats.personalFouls == _maxFouls - 1;

  @override
  Widget build(BuildContext context) {
    final stats = player.stats;
    final points = ScoreUtils.calculatePoints(
      twoPointersMade: stats.twoPointersMade,
      threePointersMade: stats.threePointersMade,
      freeThrowsMade: stats.freeThrowsMade,
    );

    return RadialActionMenu(
      actions: RadialAction.defaultActions,
      onActionSelected: onRadialAction,
      menuRadius: 65,
      buttonRadius: 18,
      centerWidget: Text(
        '#${player.player.jerseyNumber ?? '-'}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: isHome ? AppTheme.homeTeamColor : AppTheme.awayTeamColor,
        ),
      ),
      child: InkWell(
        onTap: _isFouledOut ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: _isFouledOut
                ? AppTheme.errorColor.withValues(alpha: 0.1)
                : (isOnCourt ? AppTheme.cardColor : AppTheme.backgroundColor),
            borderRadius: BorderRadius.circular(8),
            border: _isFouledOut
                ? Border.all(color: AppTheme.errorColor, width: 1)
                : (_isWarning
                    ? Border.all(color: AppTheme.foulWarningColor, width: 1)
                    : null),
          ),
          child: Row(
            children: [
              // 등번호 (원형 배경)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isFouledOut
                      ? AppTheme.errorColor.withValues(alpha: 0.3)
                      : (isHome
                          ? AppTheme.homeTeamColor.withValues(alpha: 0.15)
                          : AppTheme.awayTeamColor.withValues(alpha: 0.15)),
                ),
                child: Center(
                  child: Text(
                    '#${player.player.jerseyNumber ?? '-'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: _isFouledOut
                          ? AppTheme.errorColor
                          : (isHome ? AppTheme.homeTeamColor : AppTheme.awayTeamColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 이름
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      player.player.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: _isFouledOut
                            ? AppTheme.textSecondary
                            : AppTheme.textPrimary,
                        decoration: _isFouledOut
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isOnCourt)
                      Text(
                        '$points PTS  ${stats.totalRebounds}R  ${stats.assists}A',
                        style: TextStyle(
                          fontSize: 9,
                          color: _isFouledOut
                              ? AppTheme.textHint
                              : AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),

              // 파울 표시
              if (stats.personalFouls > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: _isFouledOut
                        ? AppTheme.errorColor
                        : (_isWarning
                            ? AppTheme.foulWarningColor
                            : AppTheme.textSecondary.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PF${stats.personalFouls}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _isFouledOut || _isWarning
                          ? Colors.white
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
