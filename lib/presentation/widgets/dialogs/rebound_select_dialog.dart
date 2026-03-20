import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';

/// 리바운드 선택 결과
class ReboundResult {
  final LocalTournamentPlayer? rebounder;
  final bool isOffensive;

  const ReboundResult({
    this.rebounder,
    required this.isOffensive,
  });

  bool get hasRebounder => rebounder != null;
}

/// 리바운드 선택 다이얼로그
class ReboundSelectDialog extends StatefulWidget {
  const ReboundSelectDialog({
    super.key,
    required this.shootingTeamPlayers,
    required this.defendingTeamPlayers,
    required this.shootingTeamName,
    required this.defendingTeamName,
    this.onSelect,
  });

  final List<LocalTournamentPlayer> shootingTeamPlayers;
  final List<LocalTournamentPlayer> defendingTeamPlayers;
  final String shootingTeamName;
  final String defendingTeamName;
  final void Function(ReboundResult? result)? onSelect;

  @override
  State<ReboundSelectDialog> createState() => _ReboundSelectDialogState();
}

class _ReboundSelectDialogState extends State<ReboundSelectDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Row(
              children: [
                const Icon(Icons.replay, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '리바운드',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // "리바운드 없음" 옵션
            _NoReboundTile(
              onTap: () {
                widget.onSelect?.call(null);
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 16),

            // 탭 바 (공격/수비 리바운드)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondary,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sports_basketball, size: 18),
                        const SizedBox(width: 4),
                        Text('공격 (${widget.shootingTeamName})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shield, size: 18),
                        const SizedBox(width: 4),
                        Text('수비 (${widget.defendingTeamName})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 선수 목록
            SizedBox(
              height: 250,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 공격 리바운드 (슈팅 팀)
                  _PlayerList(
                    players: widget.shootingTeamPlayers,
                    reboundType: '공격 리바운드',
                    onSelect: (player) {
                      widget.onSelect?.call(ReboundResult(
                        rebounder: player,
                        isOffensive: true,
                      ));
                      Navigator.pop(context, ReboundResult(
                        rebounder: player,
                        isOffensive: true,
                      ));
                    },
                  ),
                  // 수비 리바운드 (상대 팀)
                  _PlayerList(
                    players: widget.defendingTeamPlayers,
                    reboundType: '수비 리바운드',
                    onSelect: (player) {
                      widget.onSelect?.call(ReboundResult(
                        rebounder: player,
                        isOffensive: false,
                      ));
                      Navigator.pop(context, ReboundResult(
                        rebounder: player,
                        isOffensive: false,
                      ));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 리바운드 없음 타일
class _NoReboundTile extends StatelessWidget {
  const _NoReboundTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.close,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '리바운드 없음',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '아웃 오브 바운드, 에어볼 등',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// 선수 목록 위젯
class _PlayerList extends StatelessWidget {
  const _PlayerList({
    required this.players,
    required this.reboundType,
    required this.onSelect,
  });

  final List<LocalTournamentPlayer> players;
  final String reboundType;
  final void Function(LocalTournamentPlayer) onSelect;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return const Center(
        child: Text(
          '선수가 없습니다',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.separated(
      itemCount: players.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final player = players[index];
        return Material(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => onSelect(player),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${player.jerseyNumber ?? '-'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.userName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          player.position ?? '포지션 미정',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 리바운드 선택 다이얼로그 표시 헬퍼 함수
Future<ReboundResult?> showReboundSelectDialog({
  required BuildContext context,
  required List<LocalTournamentPlayer> shootingTeamPlayers,
  required List<LocalTournamentPlayer> defendingTeamPlayers,
  required String shootingTeamName,
  required String defendingTeamName,
}) {
  return showDialog<ReboundResult?>(
    context: context,
    builder: (context) => ReboundSelectDialog(
      shootingTeamPlayers: shootingTeamPlayers,
      defendingTeamPlayers: defendingTeamPlayers,
      shootingTeamName: shootingTeamName,
      defendingTeamName: defendingTeamName,
    ),
  );
}
