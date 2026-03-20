import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/score_utils.dart';
import '../../../../di/providers.dart';
import '../../../providers/undo_stack_provider.dart';
import '../../../widgets/substitution/substitution_panel.dart';
import '../models/player_with_stats.dart';

/// 선수 액션 메뉴
class PlayerActionMenu extends ConsumerWidget {
  const PlayerActionMenu({
    super.key,
    required this.player,
    required this.isHome,
    required this.matchId,
    required this.benchPlayers,
    required this.teamName,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homePlayers,
    required this.awayPlayers,
    required this.onActionComplete,
  });

  final PlayerWithStats player;
  final bool isHome;
  final int matchId;
  final List<PlayerWithStats> benchPlayers;
  final String teamName;
  final String homeTeamName;
  final String awayTeamName;
  final List<PlayerWithStats> homePlayers;
  final List<PlayerWithStats> awayPlayers;
  final VoidCallback onActionComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 선수 정보
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '#${player.player.jerseyNumber ?? '-'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.player.userName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${ScoreUtils.calculatePoints(twoPointersMade: player.stats.twoPointersMade, threePointersMade: player.stats.threePointersMade, freeThrowsMade: player.stats.freeThrowsMade)} PTS  ${player.stats.totalRebounds} REB  ${player.stats.assists} AST',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 액션 버튼들
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionButton(
                  icon: Icons.sports_basketball,
                  label: '2점 성공',
                  color: AppTheme.madeColor,
                  onTap: () => _recordShot(ref, true, false),
                ),
                ActionButton(
                  icon: Icons.sports_basketball_outlined,
                  label: '2점 실패',
                  color: AppTheme.missedColor,
                  onTap: () => _recordShot(ref, false, false),
                ),
                ActionButton(
                  icon: Icons.star,
                  label: '3점 성공',
                  color: AppTheme.madeColor,
                  onTap: () => _recordShot(ref, true, true),
                ),
                ActionButton(
                  icon: Icons.star_outline,
                  label: '3점 실패',
                  color: AppTheme.missedColor,
                  onTap: () => _recordShot(ref, false, true),
                ),
                ActionButton(
                  icon: Icons.sports_handball,
                  label: '자유투 성공',
                  color: AppTheme.madeColor,
                  onTap: () => _recordFreeThrow(ref, true),
                ),
                ActionButton(
                  icon: Icons.sports_handball_outlined,
                  label: '자유투 실패',
                  color: AppTheme.missedColor,
                  onTap: () => _recordFreeThrow(ref, false),
                ),
                ActionButton(
                  icon: Icons.flash_on,
                  label: '스틸',
                  color: AppTheme.successColor,
                  onTap: () => _recordSteal(ref),
                ),
                ActionButton(
                  icon: Icons.block,
                  label: '블락',
                  color: AppTheme.successColor,
                  onTap: () => _recordBlock(ref),
                ),
                ActionButton(
                  icon: Icons.error_outline,
                  label: '턴오버',
                  color: AppTheme.warningColor,
                  onTap: () => _recordTurnover(ref),
                ),
                ActionButton(
                  icon: Icons.front_hand,
                  label: '파울',
                  color: AppTheme.errorColor,
                  onTap: () => _recordFoul(ref),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 교체 버튼
            if (player.stats.isOnCourt)
              OutlinedButton.icon(
                onPressed: benchPlayers.isEmpty
                    ? null
                    : () => _showSubstitutionDialog(context, ref),
                icon: const Icon(Icons.swap_horiz),
                label: Text(
                  benchPlayers.isEmpty ? '벤치 선수 없음' : '선수 교체',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordShot(WidgetRef ref, bool made, bool isThree) async {
    final db = ref.read(databaseProvider);
    if (isThree) {
      await db.playerStatsDao.recordThreePointer(
        matchId,
        player.player.id,
        made,
      );
    } else {
      await db.playerStatsDao.recordTwoPointer(
        matchId,
        player.player.id,
        made,
      );
    }
    // 점수 업데이트
    if (made) {
      final points = isThree ? 3 : 2;
      final match = await db.matchDao.getMatchById(matchId);
      if (match != null) {
        if (isHome) {
          await db.matchDao.updateMatchScore(
            matchId,
            match.homeScore + points,
            match.awayScore,
          );
        } else {
          await db.matchDao.updateMatchScore(
            matchId,
            match.homeScore,
            match.awayScore + points,
          );
        }
      }
    }
    // Undo 스택에 기록
    ref.read(undoStackProvider.notifier).recordShot(
      playerId: player.player.id,
      playerName: player.player.userName,
      matchId: matchId,
      isMade: made,
      isThreePointer: isThree,
      isHome: isHome,
    );
    onActionComplete();
  }

  Future<void> _recordFreeThrow(WidgetRef ref, bool made) async {
    final db = ref.read(databaseProvider);
    await db.playerStatsDao.recordFreeThrow(matchId, player.player.id, made);
    // 점수 업데이트
    if (made) {
      final match = await db.matchDao.getMatchById(matchId);
      if (match != null) {
        if (isHome) {
          await db.matchDao.updateMatchScore(
            matchId,
            match.homeScore + 1,
            match.awayScore,
          );
        } else {
          await db.matchDao.updateMatchScore(
            matchId,
            match.homeScore,
            match.awayScore + 1,
          );
        }
      }
    }
    // Undo 스택에 기록
    ref.read(undoStackProvider.notifier).recordFreeThrow(
      playerId: player.player.id,
      playerName: player.player.userName,
      matchId: matchId,
      isMade: made,
      shotNumber: 1,
      totalShots: 1,
      isHome: isHome,
    );
    onActionComplete();
  }

  /// 교체 다이얼로그 표시
  Future<void> _showSubstitutionDialog(BuildContext context, WidgetRef ref) async {
    final availablePlayers = benchPlayers.map((p) => p.player).toList();

    await showDialog(
      context: context,
      builder: (dialogContext) => QuickSubstitutionDialog(
        teamId: player.player.tournamentTeamId,
        teamName: teamName,
        playerOut: player.player,
        availablePlayers: availablePlayers,
        onSubstitution: (subIn) async {
          final db = ref.read(databaseProvider);

          // 교체 OUT 선수 벤치로
          await db.playerStatsDao.setOnCourt(matchId, player.player.id, false);

          // 교체 IN 선수 코트로
          await db.playerStatsDao.setOnCourt(matchId, subIn.id, true);

          // Undo 스택에 기록
          ref.read(undoStackProvider.notifier).recordSubstitution(
            matchId: matchId,
            subOutPlayerId: player.player.id,
            subOutPlayerName: player.player.userName,
            subInPlayerId: subIn.id,
            subInPlayerName: subIn.userName,
            isHome: isHome,
          );

          onActionComplete();
        },
      ),
    );
  }

  Future<void> _recordSteal(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    await db.playerStatsDao.recordSteal(matchId, player.player.id);
    // Undo 스택에 기록
    ref.read(undoStackProvider.notifier).recordSteal(
      playerId: player.player.id,
      playerName: player.player.userName,
      matchId: matchId,
      isHome: isHome,
    );
    onActionComplete();
  }

  Future<void> _recordBlock(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    await db.playerStatsDao.recordBlock(matchId, player.player.id);
    // Undo 스택에 기록
    ref.read(undoStackProvider.notifier).recordBlock(
      playerId: player.player.id,
      playerName: player.player.userName,
      matchId: matchId,
      isHome: isHome,
    );
    onActionComplete();
  }

  Future<void> _recordTurnover(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    await db.playerStatsDao.recordTurnover(matchId, player.player.id);
    // Undo 스택에 기록
    ref.read(undoStackProvider.notifier).recordTurnover(
      playerId: player.player.id,
      playerName: player.player.userName,
      matchId: matchId,
      isHome: isHome,
    );
    onActionComplete();
  }

  Future<void> _recordFoul(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    await db.playerStatsDao.recordFoul(matchId, player.player.id);
    // Undo 스택에 기록
    ref.read(undoStackProvider.notifier).recordFoul(
      playerId: player.player.id,
      playerName: player.player.userName,
      matchId: matchId,
      isHome: isHome,
    );
    onActionComplete();
  }
}

/// 액션 버튼 위젯
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
