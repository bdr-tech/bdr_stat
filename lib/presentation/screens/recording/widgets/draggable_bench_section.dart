import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../models/player_with_stats.dart';

/// 드래그앤드롭 교체가 가능한 벤치 섹션
class DraggableBenchSection extends StatelessWidget {
  const DraggableBenchSection({
    super.key,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeBenchPlayers,
    required this.awayBenchPlayers,
    required this.homeOnCourtPlayers,
    required this.awayOnCourtPlayers,
    required this.onSubstitution,
    this.homeTeamColor = const Color(0xFFF97316),
    this.awayTeamColor = const Color(0xFF10B981),
  });

  final String homeTeamName;
  final String awayTeamName;
  final List<PlayerWithStats> homeBenchPlayers;
  final List<PlayerWithStats> awayBenchPlayers;
  final List<PlayerWithStats> homeOnCourtPlayers;
  final List<PlayerWithStats> awayOnCourtPlayers;
  final void Function(PlayerWithStats subOut, PlayerWithStats subIn, bool isHome) onSubstitution;
  final Color homeTeamColor;
  final Color awayTeamColor;

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
            child: _DraggableBenchTeamPanel(
              teamName: homeTeamName,
              benchPlayers: homeBenchPlayers,
              onCourtPlayers: homeOnCourtPlayers,
              teamColor: homeTeamColor,
              isHome: true,
              onSubstitution: (subOut, subIn) => onSubstitution(subOut, subIn, true),
            ),
          ),

          // 구분선
          Container(
            width: 1,
            color: AppTheme.borderColor,
          ),

          // 원정팀 벤치
          Expanded(
            child: _DraggableBenchTeamPanel(
              teamName: awayTeamName,
              benchPlayers: awayBenchPlayers,
              onCourtPlayers: awayOnCourtPlayers,
              teamColor: awayTeamColor,
              isHome: false,
              onSubstitution: (subOut, subIn) => onSubstitution(subOut, subIn, false),
            ),
          ),
        ],
      ),
    );
  }
}

/// 개별 팀 벤치 패널 (드래그앤드롭 지원)
class _DraggableBenchTeamPanel extends StatefulWidget {
  const _DraggableBenchTeamPanel({
    required this.teamName,
    required this.benchPlayers,
    required this.onCourtPlayers,
    required this.teamColor,
    required this.isHome,
    required this.onSubstitution,
  });

  final String teamName;
  final List<PlayerWithStats> benchPlayers;
  final List<PlayerWithStats> onCourtPlayers;
  final Color teamColor;
  final bool isHome;
  final void Function(PlayerWithStats subOut, PlayerWithStats subIn) onSubstitution;

  @override
  State<_DraggableBenchTeamPanel> createState() => _DraggableBenchTeamPanelState();
}

class _DraggableBenchTeamPanelState extends State<_DraggableBenchTeamPanel> {
  // 향후 드래그 교체 기능용 (현재 미사용)
  // PlayerWithStats? _selectedOnCourtPlayer;
  // bool _isSubstituting = false;

  void _startSubstitution(PlayerWithStats benchPlayer) {
    // 코트에 5명 미만이면 바로 투입 (교체 불필요)
    if (widget.onCourtPlayers.length < 5) {
      widget.onSubstitution(benchPlayer, benchPlayer); // 특수 케이스: subOut == subIn → 직접 투입
      return;
    }
    // 5명 이상이면 교체할 선수 선택
    _showSubstitutionDialog(benchPlayer);
  }

  Future<void> _showSubstitutionDialog(PlayerWithStats benchPlayer) async {
    final subOut = await showDialog<PlayerWithStats>(
      context: context,
      builder: (context) => _SubstitutionDialog(
        benchPlayer: benchPlayer,
        onCourtPlayers: widget.onCourtPlayers,
        teamColor: widget.teamColor,
        teamName: widget.teamName,
      ),
    );

    if (subOut != null) {
      widget.onSubstitution(subOut, benchPlayer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: widget.teamColor.withValues(alpha: 0.4), width: 2),
        ),
      ),
      child: Row(
        children: [
          // BENCH 라벨
          Container(
            width: 36,
            child: Center(
              child: Text(
                'B',
                style: TextStyle(
                  color: widget.teamColor.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // 선수 리스트 (5인 이상 시 "+N" 버튼으로 전체보기)
          Expanded(
            child: GestureDetector(
              onTap: widget.benchPlayers.length > 4 ? () => _showAllBenchPlayers() : null,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                itemCount: widget.benchPlayers.length > 4
                    ? 5  // 4명 + "+N" 버튼
                    : widget.benchPlayers.length,
                itemBuilder: (context, index) {
                  // "+N" 더보기 버튼
                  if (widget.benchPlayers.length > 4 && index == 4) {
                    final remaining = widget.benchPlayers.length - 4;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: GestureDetector(
                        onTap: () => _showAllBenchPlayers(),
                        child: Container(
                          width: 32,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.teamColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: widget.teamColor.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Text('+$remaining', style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold, color: widget.teamColor,
                            )),
                          ),
                        ),
                      ),
                    );
                  }
                  final player = widget.benchPlayers[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _DraggableBenchPlayerIcon(
                      player: player,
                      teamColor: widget.teamColor,
                      isHome: widget.isHome,
                      onTap: () => _startSubstitution(player),
                      onDragStart: () => _startSubstitution(player),
                    ),
                );
              },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 벤치 전체 선수 팝업
  void _showAllBenchPlayers() {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 12)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${widget.teamName} BENCH', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: widget.teamColor,
                )),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.benchPlayers.map((p) {
                    final isFouledOut = p.stats.personalFouls >= 5;
                    return GestureDetector(
                      onTap: isFouledOut ? null : () {
                        Navigator.pop(ctx);
                        _startSubstitution(p);
                      },
                      child: Opacity(
                        opacity: isFouledOut ? 0.4 : 1.0,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isFouledOut
                                ? AppTheme.errorColor.withValues(alpha: 0.15)
                                : widget.teamColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isFouledOut ? AppTheme.errorColor : widget.teamColor.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${p.player.jerseyNumber ?? '-'}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isFouledOut ? AppTheme.errorColor : widget.teamColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 벤치 선수 아이콘 (탭 → 교체 다이얼로그)
class _DraggableBenchPlayerIcon extends StatelessWidget {
  const _DraggableBenchPlayerIcon({
    required this.player,
    required this.teamColor,
    required this.isHome,
    required this.onTap,
    required this.onDragStart,
  });

  final PlayerWithStats player;
  final Color teamColor;
  final bool isHome;
  final VoidCallback onTap;
  final VoidCallback onDragStart;

  @override
  Widget build(BuildContext context) {
    final bool isFouledOut = player.stats.personalFouls >= 5;

    return GestureDetector(
      onTap: isFouledOut ? null : onTap,
      child: _PlayerIconContent(
        player: player,
        teamColor: teamColor,
        isFouledOut: isFouledOut,
        isDragging: false,
      ),
    );
  }
}

/// 선수 칩 콘텐츠 (스타팅과 동일한 60x60 둥근 정사각형)
class _PlayerIconContent extends StatelessWidget {
  const _PlayerIconContent({
    required this.player,
    required this.teamColor,
    required this.isFouledOut,
    required this.isDragging,
  });

  final PlayerWithStats player;
  final Color teamColor;
  final bool isFouledOut;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final fouls = player.stats.personalFouls;
    final isWarning = fouls == 4;

    return Opacity(
      opacity: isFouledOut ? 0.4 : 1.0,
      child: Container(
        width: 40,
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        decoration: BoxDecoration(
          color: isFouledOut
              ? AppTheme.errorColor.withValues(alpha: 0.15)
              : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFouledOut
                ? AppTheme.errorColor
                : (isWarning ? AppTheme.foulWarningColor : teamColor),
            width: isFouledOut || isWarning ? 2 : 1.5,
          ),
        ),
        child: Center(
          child: Text(
            '${player.player.jerseyNumber ?? '-'}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isFouledOut ? AppTheme.errorColor : teamColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// 교체 선수 선택 다이얼로그
class _SubstitutionDialog extends StatelessWidget {
  const _SubstitutionDialog({
    required this.benchPlayer,
    required this.onCourtPlayers,
    required this.teamColor,
    required this.teamName,
  });

  final PlayerWithStats benchPlayer;
  final List<PlayerWithStats> onCourtPlayers;
  final Color teamColor;
  final String teamName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: teamColor,
                ),
                child: Center(
                  child: Text(
                    '${benchPlayer.player.jerseyNumber ?? '-'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.swap_horiz, size: 28),
              const SizedBox(width: 12),
              const Text('?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '교체할 선수를 선택하세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: onCourtPlayers.map((player) {
            return InkWell(
              onTap: () => Navigator.of(context).pop(player),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: teamColor.withValues(alpha: 0.2),
                  border: Border.all(color: teamColor, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${player.player.jerseyNumber ?? '-'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: teamColor,
                      ),
                    ),
                    Text(
                      '${player.points}P',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
      ],
    );
  }
}
