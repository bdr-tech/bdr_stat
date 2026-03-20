import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';

/// 스탯 수정 다이얼로그
class EditStatDialog extends StatefulWidget {
  const EditStatDialog({
    super.key,
    required this.playerName,
    required this.jerseyNumber,
    required this.currentStats,
  });

  final String playerName;
  final int jerseyNumber;
  final LocalPlayerStat currentStats;

  @override
  State<EditStatDialog> createState() => _EditStatDialogState();
}

class _EditStatDialogState extends State<EditStatDialog> {
  late Map<String, int> _stats;

  @override
  void initState() {
    super.initState();
    _stats = {
      'min': widget.currentStats.minutesPlayed,
      'points': widget.currentStats.points,
      'fgm': widget.currentStats.fieldGoalsMade,
      'fga': widget.currentStats.fieldGoalsAttempted,
      'twopm': widget.currentStats.twoPointersMade,
      'twopa': widget.currentStats.twoPointersAttempted,
      'threepm': widget.currentStats.threePointersMade,
      'threepa': widget.currentStats.threePointersAttempted,
      'ftm': widget.currentStats.freeThrowsMade,
      'fta': widget.currentStats.freeThrowsAttempted,
      'oreb': widget.currentStats.offensiveRebounds,
      'dreb': widget.currentStats.defensiveRebounds,
      'reb': widget.currentStats.totalRebounds,
      'ast': widget.currentStats.assists,
      'stl': widget.currentStats.steals,
      'blk': widget.currentStats.blocks,
      'to': widget.currentStats.turnovers,
      'pf': widget.currentStats.personalFouls,
      'pm': widget.currentStats.plusMinus,
    };
  }

  void _updateStat(String key, int delta) {
    setState(() {
      final newValue = (_stats[key] ?? 0) + delta;
      _stats[key] = newValue.clamp(key == 'pm' ? -99 : 0, 999);

      // 연관 스탯 자동 업데이트
      if (key == 'twopm' || key == 'threepm') {
        _recalculateFG();
        _recalculatePoints();
      } else if (key == 'twopa' || key == 'threepa') {
        _recalculateFG();
      } else if (key == 'ftm') {
        _recalculatePoints();
      } else if (key == 'oreb' || key == 'dreb') {
        _recalculateReb();
      }
    });
  }

  void _recalculateFG() {
    _stats['fgm'] = (_stats['twopm'] ?? 0) + (_stats['threepm'] ?? 0);
    _stats['fga'] = (_stats['twopa'] ?? 0) + (_stats['threepa'] ?? 0);
  }

  void _recalculatePoints() {
    _stats['points'] = ((_stats['twopm'] ?? 0) * 2) +
        ((_stats['threepm'] ?? 0) * 3) +
        (_stats['ftm'] ?? 0);
  }

  void _recalculateReb() {
    _stats['reb'] = (_stats['oreb'] ?? 0) + (_stats['dreb'] ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            _buildHeader(),
            // 스탯 편집 영역
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 시간
                    _buildStatSection('시간', [
                      _StatItem('MIN', 'min'),
                    ]),
                    const Divider(color: AppTheme.dividerColor),
                    // 득점
                    _buildStatSection('득점', [
                      _StatItem('PTS', 'points', readOnly: true),
                      _StatItem('2PM', 'twopm'),
                      _StatItem('2PA', 'twopa'),
                      _StatItem('3PM', 'threepm'),
                      _StatItem('3PA', 'threepa'),
                      _StatItem('FTM', 'ftm'),
                      _StatItem('FTA', 'fta'),
                    ]),
                    const Divider(color: AppTheme.dividerColor),
                    // 리바운드
                    _buildStatSection('리바운드', [
                      _StatItem('REB', 'reb', readOnly: true),
                      _StatItem('OREB', 'oreb'),
                      _StatItem('DREB', 'dreb'),
                    ]),
                    const Divider(color: AppTheme.dividerColor),
                    // 기타
                    _buildStatSection('기타', [
                      _StatItem('AST', 'ast'),
                      _StatItem('STL', 'stl'),
                      _StatItem('BLK', 'blk'),
                      _StatItem('TO', 'to'),
                      _StatItem('PF', 'pf'),
                      _StatItem('+/-', 'pm', allowNegative: true),
                    ]),
                  ],
                ),
              ),
            ),
            // 버튼
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          // 등번호
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${widget.jerseyNumber}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 이름
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.playerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Text(
                  '스탯 수정',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // 수동 수정 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 12, color: AppTheme.warningColor),
                SizedBox(width: 4),
                Text(
                  '수동',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatSection(String title, List<_StatItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) => _buildStatEditor(item)).toList(),
        ),
      ],
    );
  }

  Widget _buildStatEditor(_StatItem item) {
    final value = _stats[item.key] ?? 0;
    final isReadOnly = item.readOnly;

    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isReadOnly
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isReadOnly ? AppTheme.primaryColor : AppTheme.dividerColor,
        ),
      ),
      child: Column(
        children: [
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 감소 버튼
              if (!isReadOnly)
                _StatButton(
                  icon: Icons.remove,
                  onTap: () => _updateStat(item.key, -1),
                  enabled: item.allowNegative || value > 0,
                )
              else
                const SizedBox(width: 24),
              // 값
              Text(
                item.allowNegative && value > 0 ? '+$value' : '$value',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isReadOnly ? AppTheme.primaryColor : AppTheme.textPrimary,
                ),
              ),
              // 증가 버튼
              if (!isReadOnly)
                _StatButton(
                  icon: Icons.add,
                  onTap: () => _updateStat(item.key, 1),
                  enabled: true,
                )
              else
                const SizedBox(width: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        children: [
          // 취소
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
          ),
          const SizedBox(width: 12),
          // 저장
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _stats),
              child: const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 스탯 아이템 정의
class _StatItem {
  final String label;
  final String key;
  final bool readOnly;
  final bool allowNegative;

  const _StatItem(
    this.label,
    this.key, {
    this.readOnly = false,
    this.allowNegative = false,
  });
}

/// 스탯 증감 버튼
class _StatButton extends StatelessWidget {
  const _StatButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: enabled ? AppTheme.primaryColor : AppTheme.dividerColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? Colors.white : AppTheme.textHint,
        ),
      ),
    );
  }
}
