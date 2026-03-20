import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';

/// 선수 교체 패널
class SubstitutionPanel extends ConsumerStatefulWidget {
  const SubstitutionPanel({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.playersOnCourt,
    required this.playersOnBench,
    required this.onSubstitution,
    this.maxOnCourt = 5,
  });

  final int teamId;
  final String teamName;
  final List<LocalTournamentPlayer> playersOnCourt;
  final List<LocalTournamentPlayer> playersOnBench;
  final void Function(LocalTournamentPlayer subOut, LocalTournamentPlayer subIn)
      onSubstitution;
  final int maxOnCourt;

  @override
  ConsumerState<SubstitutionPanel> createState() => _SubstitutionPanelState();
}

class _SubstitutionPanelState extends ConsumerState<SubstitutionPanel> {
  LocalTournamentPlayer? _selectedToSubOut;
  LocalTournamentPlayer? _selectedToSubIn;

  void _handleSubOutSelect(LocalTournamentPlayer player) {
    setState(() {
      if (_selectedToSubOut?.id == player.id) {
        _selectedToSubOut = null;
      } else {
        _selectedToSubOut = player;
      }
    });
    _tryComplete();
  }

  void _handleSubInSelect(LocalTournamentPlayer player) {
    setState(() {
      if (_selectedToSubIn?.id == player.id) {
        _selectedToSubIn = null;
      } else {
        _selectedToSubIn = player;
      }
    });
    _tryComplete();
  }

  void _tryComplete() {
    if (_selectedToSubOut != null && _selectedToSubIn != null) {
      widget.onSubstitution(_selectedToSubOut!, _selectedToSubIn!);
      setState(() {
        _selectedToSubOut = null;
        _selectedToSubIn = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Row(
            children: [
              const Icon(Icons.swap_horiz, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                '${widget.teamName} 선수 교체',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 안내 텍스트
          if (_selectedToSubOut == null && _selectedToSubIn == null)
            const Text(
              '코트에서 나갈 선수를 선택하세요',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          else if (_selectedToSubOut != null && _selectedToSubIn == null)
            Text(
              '${_selectedToSubOut!.userName} 대신 들어갈 선수를 선택하세요',
              style: const TextStyle(color: AppTheme.primaryColor),
            ),

          const SizedBox(height: 12),

          // 코트 선수 (교체 OUT)
          const Text(
            '코트',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.playersOnCourt.map((player) {
              final isSelected = _selectedToSubOut?.id == player.id;
              final isFouledOut = player.isActive == false;

              return _PlayerChip(
                player: player,
                isSelected: isSelected,
                isDisabled: false,
                isFouledOut: isFouledOut,
                onTap: () => _handleSubOutSelect(player),
                chipColor: isFouledOut
                    ? AppTheme.errorColor
                    : (isSelected ? AppTheme.primaryColor : null),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // 벤치 선수 (교체 IN)
          const Text(
            '벤치',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.playersOnBench.isEmpty)
            const Text(
              '벤치에 선수가 없습니다',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.playersOnBench.map((player) {
                final isSelected = _selectedToSubIn?.id == player.id;
                final canSelect = _selectedToSubOut != null;

                return _PlayerChip(
                  player: player,
                  isSelected: isSelected,
                  isDisabled: !canSelect,
                  onTap: canSelect ? () => _handleSubInSelect(player) : null,
                  chipColor: isSelected ? AppTheme.successColor : null,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

/// 선수 칩 위젯
class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    required this.player,
    required this.isSelected,
    required this.isDisabled,
    this.isFouledOut = false,
    this.onTap,
    this.chipColor,
  });

  final LocalTournamentPlayer player;
  final bool isSelected;
  final bool isDisabled;
  final bool isFouledOut;
  final VoidCallback? onTap;
  final Color? chipColor;

  @override
  Widget build(BuildContext context) {
    final color = chipColor ??
        (isDisabled ? AppTheme.textSecondary : AppTheme.surfaceColor);

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 등번호
            if (player.jerseyNumber != null)
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.3) : color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${player.jerseyNumber}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
            if (player.jerseyNumber != null) const SizedBox(width: 8),

            // 이름
            Text(
              player.userName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isDisabled
                        ? AppTheme.textSecondary
                        : AppTheme.textPrimary),
              ),
            ),

            // 파울 아웃 표시
            if (isFouledOut) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.error,
                size: 16,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 빠른 교체 다이얼로그
class QuickSubstitutionDialog extends StatefulWidget {
  const QuickSubstitutionDialog({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.playerOut,
    required this.availablePlayers,
    required this.onSubstitution,
  });

  final int teamId;
  final String teamName;
  final LocalTournamentPlayer playerOut;
  final List<LocalTournamentPlayer> availablePlayers;
  final void Function(LocalTournamentPlayer subIn) onSubstitution;

  @override
  State<QuickSubstitutionDialog> createState() =>
      _QuickSubstitutionDialogState();
}

class _QuickSubstitutionDialogState extends State<QuickSubstitutionDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                const Icon(Icons.swap_horiz, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.playerOut.userName} 교체',
                    style: const TextStyle(
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
            const SizedBox(height: 8),
            Text(
              '들어갈 선수를 선택하세요',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            // 선수 목록
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Column(
                  children: widget.availablePlayers.map((player) {
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          player.jerseyNumber?.toString() ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      title: Text(player.userName),
                      subtitle: Text(
                        player.position ?? '포지션 미정',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        widget.onSubstitution(player);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 5파울 강제 교체 다이얼로그
class FouledOutDialog extends StatelessWidget {
  const FouledOutDialog({
    super.key,
    required this.player,
    required this.availablePlayers,
    required this.onSubstitution,
  });

  final LocalTournamentPlayer player;
  final List<LocalTournamentPlayer> availablePlayers;
  final void Function(LocalTournamentPlayer subIn) onSubstitution;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.error, color: AppTheme.errorColor),
          const SizedBox(width: 8),
          Text(
            '${player.userName} 파울 아웃!',
            style: const TextStyle(color: AppTheme.errorColor),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('교체 선수를 선택해주세요.'),
          const SizedBox(height: 16),
          if (availablePlayers.isEmpty)
            const Text(
              '벤치에 선수가 없습니다.',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          else
            ...availablePlayers.map((p) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    '#${p.jerseyNumber ?? "-"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(p.userName),
                onTap: () {
                  onSubstitution(p);
                  Navigator.pop(context);
                },
              );
            }),
        ],
      ),
      actions: [
        if (availablePlayers.isNotEmpty)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('나중에'),
          ),
      ],
    );
  }
}

/// 교체 기록 표시 위젯
class SubstitutionHistoryItem extends StatelessWidget {
  const SubstitutionHistoryItem({
    super.key,
    required this.subOutName,
    required this.subInName,
    required this.quarter,
    required this.gameClockSeconds,
    this.onUndo,
  });

  final String subOutName;
  final String subInName;
  final int quarter;
  final int gameClockSeconds;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final minutes = gameClockSeconds ~/ 60;
    final seconds = gameClockSeconds % 60;
    final timeStr = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 시간
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Q$quarter $timeStr',
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 교체 내용
          Expanded(
            child: Row(
              children: [
                Text(
                  subOutName,
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  subInName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ),

          // Undo 버튼
          if (onUndo != null)
            IconButton(
              onPressed: onUndo,
              icon: const Icon(Icons.undo, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
        ],
      ),
    );
  }
}
