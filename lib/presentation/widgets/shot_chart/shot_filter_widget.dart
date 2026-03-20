import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';

/// 슛 필터 상태
class ShotFilterState {
  final int? teamId;
  final int? playerId;
  final int? quarter;
  final String? shotType; // '2pt', '3pt', 'ft'
  final bool madeOnly;
  final bool missedOnly;

  const ShotFilterState({
    this.teamId,
    this.playerId,
    this.quarter,
    this.shotType,
    this.madeOnly = false,
    this.missedOnly = false,
  });

  ShotFilterState copyWith({
    int? teamId,
    int? playerId,
    int? quarter,
    String? shotType,
    bool? madeOnly,
    bool? missedOnly,
    bool clearTeam = false,
    bool clearPlayer = false,
    bool clearQuarter = false,
    bool clearShotType = false,
  }) {
    return ShotFilterState(
      teamId: clearTeam ? null : (teamId ?? this.teamId),
      playerId: clearPlayer ? null : (playerId ?? this.playerId),
      quarter: clearQuarter ? null : (quarter ?? this.quarter),
      shotType: clearShotType ? null : (shotType ?? this.shotType),
      madeOnly: madeOnly ?? this.madeOnly,
      missedOnly: missedOnly ?? this.missedOnly,
    );
  }

  bool get hasFilter =>
      teamId != null ||
      playerId != null ||
      quarter != null ||
      shotType != null ||
      madeOnly ||
      missedOnly;
}

/// 슛 필터 위젯
class ShotFilterWidget extends StatelessWidget {
  const ShotFilterWidget({
    super.key,
    required this.filter,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.matchId,
    required this.database,
    required this.onFilterChanged,
  });

  final ShotFilterState filter;
  final String homeTeamName;
  final String awayTeamName;
  final int homeTeamId;
  final int awayTeamId;
  final int matchId;
  final AppDatabase database;
  final ValueChanged<ShotFilterState> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(bottom: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 필터 칩들
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 팀 필터
                _buildTeamFilterChip(),
                const SizedBox(width: 8),
                // 선수 필터
                _buildPlayerFilterChip(),
                const SizedBox(width: 8),
                // 쿼터 필터
                _buildQuarterFilterChip(),
                const SizedBox(width: 8),
                // 슛 타입 필터
                _buildShotTypeFilterChip(),
                const SizedBox(width: 8),
                // 성공/실패 필터
                _buildResultFilterChip(),
                // 필터 초기화
                if (filter.hasFilter) ...[
                  const SizedBox(width: 8),
                  _buildClearFilterButton(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamFilterChip() {
    final isSelected = filter.teamId != null;
    final selectedTeamName = filter.teamId == homeTeamId
        ? homeTeamName
        : filter.teamId == awayTeamId
            ? awayTeamName
            : '팀';

    return PopupMenuButton<int?>(
      initialValue: filter.teamId,
      onSelected: (teamId) {
        if (teamId == null) {
          onFilterChanged(filter.copyWith(clearTeam: true, clearPlayer: true));
        } else {
          onFilterChanged(filter.copyWith(teamId: teamId, clearPlayer: true));
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: null,
          child: Text('전체'),
        ),
        PopupMenuItem(
          value: homeTeamId,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.homeTeamColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(homeTeamName),
            ],
          ),
        ),
        PopupMenuItem(
          value: awayTeamId,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.awayTeamColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(awayTeamName),
            ],
          ),
        ),
      ],
      child: _FilterChip(
        label: isSelected ? selectedTeamName : '팀',
        icon: Icons.groups,
        isSelected: isSelected,
      ),
    );
  }

  Widget _buildPlayerFilterChip() {
    if (filter.teamId == null) {
      return _FilterChip(
        label: '선수',
        icon: Icons.person,
        isSelected: false,
        enabled: false,
      );
    }

    return FutureBuilder<List<LocalTournamentPlayer>>(
      future: database.tournamentDao.getPlayersByTeam(filter.teamId!),
      builder: (context, snapshot) {
        final players = snapshot.data ?? [];
        final selectedPlayer = filter.playerId != null
            ? players.where((p) => p.id == filter.playerId).firstOrNull
            : null;

        return PopupMenuButton<int?>(
          initialValue: filter.playerId,
          onSelected: (playerId) {
            if (playerId == null) {
              onFilterChanged(filter.copyWith(clearPlayer: true));
            } else {
              onFilterChanged(filter.copyWith(playerId: playerId));
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: null,
              child: Text('전체'),
            ),
            ...players.map((player) => PopupMenuItem(
                  value: player.id,
                  child: Text(
                    '#${player.jerseyNumber ?? '-'} ${player.userNickname ?? player.userName}',
                  ),
                )),
          ],
          child: _FilterChip(
            label: selectedPlayer != null
                ? '#${selectedPlayer.jerseyNumber ?? '-'} ${selectedPlayer.userNickname ?? selectedPlayer.userName}'
                : '선수',
            icon: Icons.person,
            isSelected: filter.playerId != null,
          ),
        );
      },
    );
  }

  Widget _buildQuarterFilterChip() {
    final quarterLabels = {
      1: '1Q',
      2: '2Q',
      3: '3Q',
      4: '4Q',
      5: 'OT1',
      6: 'OT2',
    };

    return PopupMenuButton<int?>(
      initialValue: filter.quarter,
      onSelected: (quarter) {
        if (quarter == null) {
          onFilterChanged(filter.copyWith(clearQuarter: true));
        } else {
          onFilterChanged(filter.copyWith(quarter: quarter));
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: null,
          child: Text('전체'),
        ),
        ...quarterLabels.entries.map((e) => PopupMenuItem(
              value: e.key,
              child: Text(e.value),
            )),
      ],
      child: _FilterChip(
        label: filter.quarter != null
            ? quarterLabels[filter.quarter] ?? 'Q${filter.quarter}'
            : '쿼터',
        icon: Icons.timer,
        isSelected: filter.quarter != null,
      ),
    );
  }

  Widget _buildShotTypeFilterChip() {
    final shotTypeLabels = {
      '2pt': '2점슛',
      '3pt': '3점슛',
      'ft': '자유투',
    };

    return PopupMenuButton<String?>(
      initialValue: filter.shotType,
      onSelected: (shotType) {
        if (shotType == null) {
          onFilterChanged(filter.copyWith(clearShotType: true));
        } else {
          onFilterChanged(filter.copyWith(shotType: shotType));
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: null,
          child: Text('전체'),
        ),
        ...shotTypeLabels.entries.map((e) => PopupMenuItem(
              value: e.key,
              child: Text(e.value),
            )),
      ],
      child: _FilterChip(
        label: filter.shotType != null
            ? shotTypeLabels[filter.shotType] ?? filter.shotType!
            : '슛 타입',
        icon: Icons.sports_basketball,
        isSelected: filter.shotType != null,
      ),
    );
  }

  Widget _buildResultFilterChip() {
    String label = '결과';
    if (filter.madeOnly) label = '성공';
    if (filter.missedOnly) label = '실패';

    return PopupMenuButton<String>(
      onSelected: (result) {
        switch (result) {
          case 'all':
            onFilterChanged(filter.copyWith(madeOnly: false, missedOnly: false));
            break;
          case 'made':
            onFilterChanged(filter.copyWith(madeOnly: true, missedOnly: false));
            break;
          case 'missed':
            onFilterChanged(filter.copyWith(madeOnly: false, missedOnly: true));
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'all',
          child: Text('전체'),
        ),
        PopupMenuItem(
          value: 'made',
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppTheme.shotMadeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text('성공'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'missed',
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.shotMissedColor, width: 2),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text('실패'),
            ],
          ),
        ),
      ],
      child: _FilterChip(
        label: label,
        icon: filter.madeOnly
            ? Icons.check_circle
            : filter.missedOnly
                ? Icons.cancel
                : Icons.filter_list,
        isSelected: filter.madeOnly || filter.missedOnly,
        color: filter.madeOnly
            ? AppTheme.shotMadeColor
            : filter.missedOnly
                ? AppTheme.shotMissedColor
                : null,
      ),
    );
  }

  Widget _buildClearFilterButton() {
    return InkWell(
      onTap: () => onFilterChanged(const ShotFilterState()),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.clear, size: 14, color: AppTheme.errorColor),
            SizedBox(width: 4),
            Text(
              '초기화',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.errorColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 필터 칩 위젯
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.enabled = true,
    this.color,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final bool enabled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? (isSelected ? AppTheme.primaryColor : AppTheme.textSecondary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? effectiveColor.withValues(alpha: 0.1)
            : AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? (isSelected ? effectiveColor : AppTheme.dividerColor)
              : AppTheme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: enabled ? effectiveColor : AppTheme.textHint,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: enabled
                  ? (isSelected ? effectiveColor : AppTheme.textSecondary)
                  : AppTheme.textHint,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.arrow_drop_down,
            size: 16,
            color: enabled ? AppTheme.textSecondary : AppTheme.textHint,
          ),
        ],
      ),
    );
  }
}
