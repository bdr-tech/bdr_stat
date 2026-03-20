import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../screens/recording/models/player_with_stats.dart';

/// 실시간 스탯 리더 표시 위젯
///
/// 경기 중 득점, 리바운드, 어시스트 등 주요 스탯 리더를 실시간으로 표시합니다.
class LiveLeaderWidget extends StatelessWidget {
  const LiveLeaderWidget({
    super.key,
    required this.homePlayers,
    required this.awayPlayers,
    required this.homeTeamName,
    required this.awayTeamName,
    this.compact = false,
  });

  final List<PlayerWithStats> homePlayers;
  final List<PlayerWithStats> awayPlayers;
  final String homeTeamName;
  final String awayTeamName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final allPlayers = [...homePlayers, ...awayPlayers];

    if (allPlayers.isEmpty) {
      return const SizedBox.shrink();
    }

    // 각 스탯별 리더 계산
    final pointsLeader = _getLeader(allPlayers, (p) => p.stats.points);
    final reboundsLeader = _getLeader(allPlayers, (p) => p.stats.totalRebounds);
    final assistsLeader = _getLeader(allPlayers, (p) => p.stats.assists);

    if (compact) {
      return _buildCompactView(pointsLeader, reboundsLeader, assistsLeader);
    }

    return _buildFullView(pointsLeader, reboundsLeader, assistsLeader);
  }

  /// 컴팩트 뷰 (한 줄)
  Widget _buildCompactView(
    _LeaderInfo? points,
    _LeaderInfo? rebounds,
    _LeaderInfo? assists,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border.all(color: AppTheme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (points != null) ...[
            _buildCompactLeaderItem('PTS', points),
            const SizedBox(width: 12),
          ],
          if (rebounds != null) ...[
            _buildCompactLeaderItem('REB', rebounds),
            const SizedBox(width: 12),
          ],
          if (assists != null) _buildCompactLeaderItem('AST', assists),
        ],
      ),
    );
  }

  Widget _buildCompactLeaderItem(String label, _LeaderInfo leader) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        _buildPlayerBadge(leader, compact: true),
        const SizedBox(width: 2),
        Text(
          '${leader.value}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  /// 전체 뷰 (3열)
  Widget _buildFullView(
    _LeaderInfo? points,
    _LeaderInfo? rebounds,
    _LeaderInfo? assists,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 타이틀
          Row(
            children: [
              const Icon(
                Icons.leaderboard,
                size: 16,
                color: AppTheme.secondaryColor,
              ),
              const SizedBox(width: 6),
              const Text(
                '실시간 리더',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 리더 목록
          Row(
            children: [
              Expanded(
                child: _buildLeaderCard(
                  '득점',
                  Icons.sports_basketball,
                  points,
                  AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLeaderCard(
                  '리바운드',
                  Icons.replay,
                  rebounds,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLeaderCard(
                  '어시스트',
                  Icons.sports_handball,
                  assists,
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderCard(
    String label,
    IconData icon,
    _LeaderInfo? leader,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 라벨
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: accentColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 리더 정보
          if (leader != null) ...[
            _buildPlayerBadge(leader),
            const SizedBox(height: 4),
            Text(
              '${leader.value}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ] else ...[
            const Text(
              '-',
              style: TextStyle(
                fontSize: 20,
                color: AppTheme.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerBadge(_LeaderInfo leader, {bool compact = false}) {
    final isHome = homePlayers.any((p) => p.player.id == leader.playerId);
    final teamColor = isHome ? AppTheme.homeTeamColor : AppTheme.awayTeamColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 8,
        vertical: compact ? 1 : 3,
      ),
      decoration: BoxDecoration(
        color: teamColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
        border: Border.all(
          color: teamColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leader.jerseyNumber != null) ...[
            Text(
              '#${leader.jerseyNumber}',
              style: TextStyle(
                fontSize: compact ? 9 : 10,
                fontWeight: FontWeight.bold,
                color: teamColor,
              ),
            ),
            SizedBox(width: compact ? 2 : 4),
          ],
          Text(
            leader.playerName,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 특정 스탯의 리더 찾기
  _LeaderInfo? _getLeader(
    List<PlayerWithStats> players,
    int Function(PlayerWithStats) statGetter,
  ) {
    if (players.isEmpty) return null;

    PlayerWithStats? leader;
    int maxValue = 0;

    for (final player in players) {
      final value = statGetter(player);
      if (value > maxValue) {
        maxValue = value;
        leader = player;
      }
    }

    if (leader == null || maxValue == 0) return null;

    return _LeaderInfo(
      playerId: leader.player.id,
      playerName: leader.player.userNickname ?? leader.player.userName,
      jerseyNumber: leader.player.jerseyNumber,
      value: maxValue,
    );
  }
}

/// 리더 정보
class _LeaderInfo {
  final int playerId;
  final String playerName;
  final int? jerseyNumber;
  final int value;

  const _LeaderInfo({
    required this.playerId,
    required this.playerName,
    this.jerseyNumber,
    required this.value,
  });
}

/// 확장 가능한 리더 패널 (스코어보드 옆)
class ExpandableLiveLeaderPanel extends StatefulWidget {
  const ExpandableLiveLeaderPanel({
    super.key,
    required this.homePlayers,
    required this.awayPlayers,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  final List<PlayerWithStats> homePlayers;
  final List<PlayerWithStats> awayPlayers;
  final String homeTeamName;
  final String awayTeamName;

  @override
  State<ExpandableLiveLeaderPanel> createState() =>
      _ExpandableLiveLeaderPanelState();
}

class _ExpandableLiveLeaderPanelState extends State<ExpandableLiveLeaderPanel>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpand,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isExpanded
                ? AppTheme.primaryColor.withValues(alpha: 0.4)
                : AppTheme.dividerColor,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더 (항상 표시)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.leaderboard,
                    size: 14,
                    color: AppTheme.secondaryColor,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '리더',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // 확장 콘텐츠
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: LiveLeaderWidget(
                  homePlayers: widget.homePlayers,
                  awayPlayers: widget.awayPlayers,
                  homeTeamName: widget.homeTeamName,
                  awayTeamName: widget.awayTeamName,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 슬라이드아웃 리더 드로어
class LiveLeaderDrawer extends StatelessWidget {
  const LiveLeaderDrawer({
    super.key,
    required this.homePlayers,
    required this.awayPlayers,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  final List<PlayerWithStats> homePlayers;
  final List<PlayerWithStats> awayPlayers;
  final String homeTeamName;
  final String awayTeamName;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.primaryColor,
              child: Row(
                children: [
                  const Icon(
                    Icons.leaderboard,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '실시간 리더',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // 리더 목록
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    LiveLeaderWidget(
                      homePlayers: homePlayers,
                      awayPlayers: awayPlayers,
                      homeTeamName: homeTeamName,
                      awayTeamName: awayTeamName,
                    ),
                    const SizedBox(height: 24),
                    // 추가 상세 리더보드
                    _buildDetailedLeaderboard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedLeaderboard() {
    final allPlayers = [...homePlayers, ...awayPlayers];

    // 여러 스탯별 상위 3명씩 표시
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLeaderSection('스틸', allPlayers, (p) => p.stats.steals),
        const SizedBox(height: 16),
        _buildLeaderSection('블락', allPlayers, (p) => p.stats.blocks),
        const SizedBox(height: 16),
        _buildLeaderSection('3점 성공', allPlayers, (p) => p.stats.threePointersMade),
      ],
    );
  }

  Widget _buildLeaderSection(
    String label,
    List<PlayerWithStats> players,
    int Function(PlayerWithStats) statGetter,
  ) {
    // 상위 3명 정렬
    final sorted = [...players]
      ..sort((a, b) => statGetter(b).compareTo(statGetter(a)));
    final top3 = sorted.take(3).where((p) => statGetter(p) > 0).toList();

    if (top3.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ...top3.asMap().entries.map((entry) {
          final index = entry.key;
          final player = entry.value;
          final isHome = homePlayers.any((p) => p.player.id == player.player.id);

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Row(
              children: [
                // 순위
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index == 0
                        ? AppTheme.secondaryColor
                        : AppTheme.textHint.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: index == 0 ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 선수 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.player.userNickname ?? player.player.userName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        isHome ? homeTeamName : awayTeamName,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // 스탯 값
                Text(
                  '${statGetter(player)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
