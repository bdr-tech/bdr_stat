import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../di/providers.dart';
import '../../../data/database/database.dart';

/// 스타터 선택 화면
class StarterSelectScreen extends ConsumerStatefulWidget {
  const StarterSelectScreen({super.key, required this.matchId});

  final int matchId;

  @override
  ConsumerState<StarterSelectScreen> createState() =>
      _StarterSelectScreenState();
}

class _StarterSelectScreenState extends ConsumerState<StarterSelectScreen> {
  LocalMatche? _match;
  LocalTournamentTeam? _homeTeam;
  LocalTournamentTeam? _awayTeam;
  List<LocalTournamentPlayer> _homePlayers = [];
  List<LocalTournamentPlayer> _awayPlayers = [];

  final Set<int> _homeStarters = {};
  final Set<int> _awayStarters = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(databaseProvider);

    // 경기 정보 로드
    final match = await db.matchDao.getMatchById(widget.matchId);
    if (match == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('경기 정보를 찾을 수 없습니다.')),
        );
        context.pop();
      }
      return;
    }

    // 팀 정보 로드
    final homeTeam = await db.tournamentDao.getTeamById(match.homeTeamId);
    final awayTeam = await db.tournamentDao.getTeamById(match.awayTeamId);

    // 선수 목록 로드
    final homePlayers =
        await db.tournamentDao.getPlayersByTeamId(match.homeTeamId);
    final awayPlayers =
        await db.tournamentDao.getPlayersByTeamId(match.awayTeamId);

    // 기본 스타터 설정 (isStarter가 true인 선수)
    final homeStarterIds = homePlayers
        .where((p) => p.isStarter)
        .take(5)
        .map((p) => p.id)
        .toSet();
    final awayStarterIds = awayPlayers
        .where((p) => p.isStarter)
        .take(5)
        .map((p) => p.id)
        .toSet();

    setState(() {
      _match = match;
      _homeTeam = homeTeam;
      _awayTeam = awayTeam;
      _homePlayers = homePlayers;
      _awayPlayers = awayPlayers;
      _homeStarters.addAll(homeStarterIds);
      _awayStarters.addAll(awayStarterIds);
      _isLoading = false;
    });
  }

  void _toggleStarter(int playerId, bool isHome) {
    setState(() {
      final starters = isHome ? _homeStarters : _awayStarters;
      if (starters.contains(playerId)) {
        starters.remove(playerId);
      } else if (starters.length < 5) {
        starters.add(playerId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('스타터는 5명까지만 선택할 수 있습니다.')),
        );
      }
    });
  }

  bool _canStart() {
    return _homeStarters.length == 5 && _awayStarters.length == 5;
  }

  Future<void> _startGame() async {
    if (!_canStart()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('양 팀 모두 5명의 스타터를 선택해야 합니다.')),
      );
      return;
    }

    final db = ref.read(databaseProvider);

    // 경기 상태 업데이트
    await db.matchDao.updateMatchStatus(widget.matchId, 'in_progress');
    await db.matchDao.updateMatchClock(widget.matchId, 1, 720); // 1쿼터 12분
    // 점수 리셋
    await db.matchDao.updateMatchScore(widget.matchId, 0, 0);

    // 기존 스탯 삭제 후 재생성 (다시 시작 대응)
    await db.playerStatsDao.deleteStatsByMatch(widget.matchId);

    // 선수 통계 초기화
    for (final playerId in _homeStarters) {
      await db.playerStatsDao.initializeStats(
        matchId: widget.matchId,
        playerId: playerId,
        teamId: _match!.homeTeamId,
        isOnCourt: true,
      );
    }
    for (final playerId in _awayStarters) {
      await db.playerStatsDao.initializeStats(
        matchId: widget.matchId,
        playerId: playerId,
        teamId: _match!.awayTeamId,
        isOnCourt: true,
      );
    }

    // 벤치 선수 통계 초기화
    for (final player in _homePlayers) {
      if (!_homeStarters.contains(player.id)) {
        await db.playerStatsDao.initializeStats(
          matchId: widget.matchId,
          playerId: player.id,
          teamId: _match!.homeTeamId,
          isOnCourt: false,
        );
      }
    }
    for (final player in _awayPlayers) {
      if (!_awayStarters.contains(player.id)) {
        await db.playerStatsDao.initializeStats(
          matchId: widget.matchId,
          playerId: player.id,
          teamId: _match!.awayTeamId,
          isOnCourt: false,
        );
      }
    }

    // 현재 경기 ID 설정
    ref.read(currentMatchIdProvider.notifier).state = widget.matchId;

    if (mounted) {
      context.go('/recording/${widget.matchId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('스타터 선택'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '${_homeStarters.length}/5 vs ${_awayStarters.length}/5',
                style: TextStyle(
                  color: _canStart()
                      ? AppTheme.successColor
                      : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // 홈팀
          Expanded(
            child: _TeamStarterPanel(
              team: _homeTeam,
              players: _homePlayers,
              selectedIds: _homeStarters,
              isHome: true,
              teamColor: const Color(0xFFF97316), // 오렌지
              onToggle: (id) => _toggleStarter(id, true),
            ),
          ),

          // 구분선
          Container(
            width: 2,
            color: AppTheme.dividerColor,
          ),

          // 원정팀
          Expanded(
            child: _TeamStarterPanel(
              team: _awayTeam,
              players: _awayPlayers,
              selectedIds: _awayStarters,
              isHome: false,
              teamColor: const Color(0xFF10B981), // 에메랄드
              onToggle: (id) => _toggleStarter(id, false),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _canStart() ? _startGame : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canStart()
                    ? AppTheme.successColor
                    : AppTheme.surfaceColor,
              ),
              child: Text(
                _canStart() ? '경기 시작' : '양 팀 5명씩 선택하세요',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 팀 스타터 선택 패널
class _TeamStarterPanel extends StatelessWidget {
  const _TeamStarterPanel({
    required this.team,
    required this.players,
    required this.selectedIds,
    required this.isHome,
    required this.teamColor,
    required this.onToggle,
  });

  final LocalTournamentTeam? team;
  final List<LocalTournamentPlayer> players;
  final Set<int> selectedIds;
  final bool isHome;
  final Color teamColor;
  final void Function(int) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 팀 헤더
        Container(
          padding: const EdgeInsets.all(16),
          color: teamColor.withValues(alpha: 0.15),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: team?.teamLogoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          team!.teamLogoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.sports_basketball,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.sports_basketball,
                        color: AppTheme.primaryColor,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team?.teamName ?? (isHome ? '홈팀' : '원정팀'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: teamColor,
                          ),
                    ),
                    Text(
                      isHome ? 'HOME' : 'AWAY',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selectedIds.length == 5
                      ? teamColor.withValues(alpha: 0.2)
                      : AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedIds.length == 5
                        ? teamColor
                        : AppTheme.dividerColor,
                  ),
                ),
                child: Text(
                  '${selectedIds.length}/5',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selectedIds.length == 5
                        ? teamColor
                        : AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 선수 목록
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final isSelected = selectedIds.contains(player.id);

              return _PlayerCard(
                player: player,
                isSelected: isSelected,
                teamColor: teamColor,
                onTap: () => onToggle(player.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 선수 카드
class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.player,
    required this.isSelected,
    required this.teamColor,
    required this.onTap,
  });

  final LocalTournamentPlayer player;
  final bool isSelected;
  final Color teamColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: isSelected
          ? teamColor.withValues(alpha: 0.15)
          : AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? teamColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 체크박스
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? teamColor
                      : AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? teamColor
                        : AppTheme.dividerColor,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),

              // 등번호
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? teamColor : AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '#${player.jerseyNumber ?? '-'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 선수 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    if (player.position != null)
                      Text(
                        _getPositionText(player.position!),
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

              // 스타터 뱃지
              if (player.isStarter)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '기본 스타터',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.warningColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPositionText(String position) {
    switch (position.toUpperCase()) {
      case 'PG':
        return '포인트가드';
      case 'SG':
        return '슈팅가드';
      case 'SF':
        return '스몰포워드';
      case 'PF':
        return '파워포워드';
      case 'C':
        return '센터';
      default:
        return position;
    }
  }
}
