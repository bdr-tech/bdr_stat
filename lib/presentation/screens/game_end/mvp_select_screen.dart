import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';
import '../../../di/providers.dart';

/// MVP 선정 후보 데이터
class MvpCandidate {
  final int playerId;
  final int teamId;
  final String playerName;
  final int? jerseyNumber;
  final int points;
  final int rebounds;
  final int assists;
  final int steals;
  final int blocks;
  final double efficiency;

  const MvpCandidate({
    required this.playerId,
    required this.teamId,
    required this.playerName,
    this.jerseyNumber,
    required this.points,
    required this.rebounds,
    required this.assists,
    required this.steals,
    required this.blocks,
    required this.efficiency,
  });
}

/// MVP 선택 화면
class MvpSelectScreen extends ConsumerStatefulWidget {
  const MvpSelectScreen({
    super.key,
    required this.matchId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeScore,
    required this.awayScore,
  });

  final int matchId;
  final int homeTeamId;
  final int awayTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final int homeScore;
  final int awayScore;

  @override
  ConsumerState<MvpSelectScreen> createState() => _MvpSelectScreenState();
}

class _MvpSelectScreenState extends ConsumerState<MvpSelectScreen> {
  bool _isLoading = true;
  List<MvpCandidate> _homeCandidates = [];
  List<MvpCandidate> _awayCandidates = [];
  int? _selectedMvpId;
  final Map<int, LocalTournamentPlayer> _playerMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final database = ref.read(databaseProvider);

    // 선수 정보 로드
    final homePlayers =
        await database.tournamentDao.getPlayersByTeam(widget.homeTeamId);
    final awayPlayers =
        await database.tournamentDao.getPlayersByTeam(widget.awayTeamId);

    for (final p in [...homePlayers, ...awayPlayers]) {
      _playerMap[p.id] = p;
    }

    // 스탯 로드
    final homeStats = await database.playerStatsDao
        .getStatsByMatchAndTeam(widget.matchId, widget.homeTeamId);
    final awayStats = await database.playerStatsDao
        .getStatsByMatchAndTeam(widget.matchId, widget.awayTeamId);

    // MVP 후보 생성
    _homeCandidates = _createCandidates(homeStats);
    _awayCandidates = _createCandidates(awayStats);

    // 효율성 기준 정렬
    _homeCandidates.sort((a, b) => b.efficiency.compareTo(a.efficiency));
    _awayCandidates.sort((a, b) => b.efficiency.compareTo(a.efficiency));

    // 기존 MVP 확인
    final match = await database.matchDao.getMatchById(widget.matchId);
    _selectedMvpId = match?.mvpPlayerId;

    setState(() => _isLoading = false);
  }

  List<MvpCandidate> _createCandidates(List<LocalPlayerStat> stats) {
    return stats.map((s) {
      final player = _playerMap[s.tournamentTeamPlayerId];
      // 효율성: PTS + REB + AST + STL + BLK - TO - Missed FG - Missed FT
      final efficiency = s.points +
          s.totalRebounds +
          s.assists +
          s.steals +
          s.blocks -
          s.turnovers -
          (s.fieldGoalsAttempted - s.fieldGoalsMade) -
          (s.freeThrowsAttempted - s.freeThrowsMade).toDouble();

      return MvpCandidate(
        playerId: s.tournamentTeamPlayerId,
        teamId: s.tournamentTeamId,
        playerName: player?.userName ?? '선수 #${s.tournamentTeamPlayerId}',
        jerseyNumber: player?.jerseyNumber,
        points: s.points,
        rebounds: s.totalRebounds,
        assists: s.assists,
        steals: s.steals,
        blocks: s.blocks,
        efficiency: efficiency,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('MVP 선정'),
        actions: [
          TextButton(
            onPressed: _selectedMvpId != null ? _confirmAndContinue : null,
            child: Text(
              _selectedMvpId != null ? '완료' : '건너뛰기',
              style: TextStyle(
                color:
                    _selectedMvpId != null ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 안내 메시지
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.surfaceColor,
                  child: const Text(
                    '이번 경기의 MVP를 선택해주세요.\n선택하지 않고 건너뛸 수 있습니다.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // 선수 목록
                Expanded(
                  child: Row(
                    children: [
                      // 홈팀
                      Expanded(
                        child: _buildTeamSection(
                          widget.homeTeamName,
                          _homeCandidates,
                          AppTheme.primaryColor,
                        ),
                      ),
                      Container(
                        width: 1,
                        color: AppTheme.dividerColor,
                      ),
                      // 원정팀
                      Expanded(
                        child: _buildTeamSection(
                          widget.awayTeamName,
                          _awayCandidates,
                          AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // 하단 버튼
                _buildBottomButton(),
              ],
            ),
    );
  }

  Widget _buildTeamSection(
    String teamName,
    List<MvpCandidate> candidates,
    Color teamColor,
  ) {
    return Column(
      children: [
        // 팀 헤더
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: teamColor.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(color: teamColor, width: 2),
            ),
          ),
          child: Text(
            teamName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: teamColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // 선수 목록
        Expanded(
          child: ListView.builder(
            itemCount: candidates.length,
            itemBuilder: (context, index) {
              final candidate = candidates[index];
              return _buildCandidateCard(candidate, teamColor, index == 0);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCandidateCard(
    MvpCandidate candidate,
    Color teamColor,
    bool isTopPerformer,
  ) {
    final isSelected = _selectedMvpId == candidate.playerId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMvpId = isSelected ? null : candidate.playerId;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? teamColor.withValues(alpha: 0.2) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? teamColor : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 선택 표시
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? teamColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? teamColor : AppTheme.textHint,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            // 선수 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (candidate.jerseyNumber != null)
                        Text(
                          '#${candidate.jerseyNumber} ',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          candidate.playerName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isTopPerformer)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'TOP',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 스탯
                  Row(
                    children: [
                      _buildStatChip('PTS', candidate.points),
                      const SizedBox(width: 4),
                      _buildStatChip('REB', candidate.rebounds),
                      const SizedBox(width: 4),
                      _buildStatChip('AST', candidate.assists),
                      if (candidate.steals > 0) ...[
                        const SizedBox(width: 4),
                        _buildStatChip('STL', candidate.steals),
                      ],
                      if (candidate.blocks > 0) ...[
                        const SizedBox(width: 4),
                        _buildStatChip('BLK', candidate.blocks),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // 효율성
            Column(
              children: [
                const Text(
                  'EFF',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  candidate.efficiency.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: candidate.efficiency >= 20
                        ? AppTheme.successColor
                        : candidate.efficiency >= 10
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$value$label',
        style: const TextStyle(
          fontSize: 10,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        children: [
          // 선택 상태 표시
          Expanded(
            child: _selectedMvpId != null
                ? Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: AppTheme.secondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getSelectedPlayerName(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'MVP를 선택해주세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          // 완료 버튼
          ElevatedButton.icon(
            onPressed: _confirmAndContinue,
            icon: const Icon(Icons.check),
            label: Text(_selectedMvpId != null ? '경기 종료' : '건너뛰기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedMvpId != null
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _getSelectedPlayerName() {
    if (_selectedMvpId == null) return '';

    // 홈팀에서 찾기
    for (final c in _homeCandidates) {
      if (c.playerId == _selectedMvpId) {
        return '${c.playerName} (${widget.homeTeamName})';
      }
    }
    // 원정팀에서 찾기
    for (final c in _awayCandidates) {
      if (c.playerId == _selectedMvpId) {
        return '${c.playerName} (${widget.awayTeamName})';
      }
    }
    return '';
  }

  Future<void> _confirmAndContinue() async {
    final database = ref.read(databaseProvider);

    // MVP 저장
    if (_selectedMvpId != null) {
      await database.matchDao.setMvp(widget.matchId, _selectedMvpId!);
    }

    // 경기 상태를 finished로 변경
    await database.matchDao.updateStatus(widget.matchId, 'finished');

    if (!mounted) return;

    // 동기화 결과 화면으로 이동
    context.pushReplacement(
      '/sync-result/${widget.matchId}',
      extra: {
        'homeTeamId': widget.homeTeamId,
        'awayTeamId': widget.awayTeamId,
        'homeTeamName': widget.homeTeamName,
        'awayTeamName': widget.awayTeamName,
        'homeScore': widget.homeScore,
        'awayScore': widget.awayScore,
        'mvpPlayerId': _selectedMvpId,
      },
    );
  }
}
