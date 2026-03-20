import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';
import '../../../di/providers.dart';

/// 경기 분석 리포트 화면
class GameAnalysisScreen extends ConsumerStatefulWidget {
  const GameAnalysisScreen({
    super.key,
    required this.matchId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  final int matchId;
  final int homeTeamId;
  final int awayTeamId;
  final String homeTeamName;
  final String awayTeamName;

  @override
  ConsumerState<GameAnalysisScreen> createState() => _GameAnalysisScreenState();
}

class _GameAnalysisScreenState extends ConsumerState<GameAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  _GameAnalysis? _analysis;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalysis();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalysis() async {
    final db = ref.read(databaseProvider);

    // 경기 정보
    final match = await db.matchDao.getMatchById(widget.matchId);

    // 선수 통계
    final homeStats = await db.playerStatsDao.getStatsByTeam(
      widget.matchId,
      widget.homeTeamId,
    );
    final awayStats = await db.playerStatsDao.getStatsByTeam(
      widget.matchId,
      widget.awayTeamId,
    );

    // Play-by-Play
    final plays = await db.playByPlayDao.getPlaysByMatch(widget.matchId);

    // 분석 계산
    final analysis = _calculateAnalysis(
      match: match,
      homeStats: homeStats,
      awayStats: awayStats,
      plays: plays,
    );

    if (mounted) {
      setState(() {
        _analysis = analysis;
        _isLoading = false;
      });
    }
  }

  _GameAnalysis _calculateAnalysis({
    required LocalMatche? match,
    required List<LocalPlayerStat> homeStats,
    required List<LocalPlayerStat> awayStats,
    required List<LocalPlayByPlay> plays,
  }) {
    // 팀 통계 집계
    final homeTeamStats = _aggregateTeamStats(homeStats);
    final awayTeamStats = _aggregateTeamStats(awayStats);

    // 플레이 분석
    int biggestHomeLead = 0;
    int biggestAwayLead = 0;
    int leadChanges = 0;
    int ties = 0;
    int lastLeader = 0; // 0: tie, 1: home, -1: away

    // 쿼터별 점수 흐름
    final quarterFlow = <int, List<_ScorePoint>>{};
    for (int q = 1; q <= 4; q++) {
      quarterFlow[q] = [];
    }

    // 득점 기록 분석
    int homeRunning = 0;
    int awayRunning = 0;

    for (final play in plays) {
      if (play.actionType == 'shot' && play.isMade == true) {
        if (play.tournamentTeamId == widget.homeTeamId) {
          homeRunning += play.pointsScored;
        } else {
          awayRunning += play.pointsScored;
        }

        final diff = homeRunning - awayRunning;

        // 리드 체크
        if (diff > biggestHomeLead) biggestHomeLead = diff;
        if (-diff > biggestAwayLead) biggestAwayLead = -diff;

        // 리드 변경 및 동점 체크
        final currentLeader = diff > 0 ? 1 : (diff < 0 ? -1 : 0);
        if (currentLeader == 0) {
          ties++;
        } else if (currentLeader != lastLeader && lastLeader != 0) {
          leadChanges++;
        }
        lastLeader = currentLeader;

        // 쿼터별 흐름 기록
        if (play.quarter >= 1 && play.quarter <= 4) {
          quarterFlow[play.quarter]?.add(_ScorePoint(
            homeScore: homeRunning,
            awayScore: awayRunning,
            time: play.gameClockSeconds,
          ));
        }
      }
    }

    // 페인트 득점 / 패스트브레이크 / 세컨찬스 계산
    int homePaintPoints = 0, awayPaintPoints = 0;
    int homeFastBreak = 0, awayFastBreak = 0;
    int homeSecondChance = 0, awaySecondChance = 0;
    int homeFromTurnover = 0, awayFromTurnover = 0;

    for (final play in plays) {
      if (play.actionType == 'shot' && play.isMade == true) {
        final isHome = play.tournamentTeamId == widget.homeTeamId;
        final points = play.pointsScored;

        // 페인트 득점 (제한구역 또는 페인트 존)
        if (play.courtZone != null && (play.courtZone == 1 || play.courtZone == 2)) {
          if (isHome) {
            homePaintPoints += points;
          } else {
            awayPaintPoints += points;
          }
        }

        // 패스트브레이크
        if (play.isFastbreak) {
          if (isHome) {
            homeFastBreak += points;
          } else {
            awayFastBreak += points;
          }
        }

        // 세컨찬스
        if (play.isSecondChance) {
          if (isHome) {
            homeSecondChance += points;
          } else {
            awaySecondChance += points;
          }
        }

        // 턴오버 유발 득점
        if (play.isFromTurnover) {
          if (isHome) {
            homeFromTurnover += points;
          } else {
            awayFromTurnover += points;
          }
        }
      }
    }

    // 선수 효율성 계산
    final homePlayerEfficiency = _calculatePlayerEfficiency(homeStats);
    final awayPlayerEfficiency = _calculatePlayerEfficiency(awayStats);

    return _GameAnalysis(
      match: match,
      homeTeamStats: homeTeamStats,
      awayTeamStats: awayTeamStats,
      biggestHomeLead: biggestHomeLead,
      biggestAwayLead: biggestAwayLead,
      leadChanges: leadChanges,
      ties: ties,
      quarterFlow: quarterFlow,
      homePaintPoints: homePaintPoints,
      awayPaintPoints: awayPaintPoints,
      homeFastBreak: homeFastBreak,
      awayFastBreak: awayFastBreak,
      homeSecondChance: homeSecondChance,
      awaySecondChance: awaySecondChance,
      homeFromTurnover: homeFromTurnover,
      awayFromTurnover: awayFromTurnover,
      homePlayerEfficiency: homePlayerEfficiency,
      awayPlayerEfficiency: awayPlayerEfficiency,
    );
  }

  _TeamStats _aggregateTeamStats(List<LocalPlayerStat> stats) {
    int points = 0, fgm = 0, fga = 0;
    int tpm = 0, tpa = 0, ftm = 0, fta = 0;
    int oreb = 0, dreb = 0, reb = 0;
    int ast = 0, stl = 0, blk = 0, to = 0, pf = 0;

    for (final s in stats) {
      points += s.points;
      fgm += s.fieldGoalsMade;
      fga += s.fieldGoalsAttempted;
      tpm += s.threePointersMade;
      tpa += s.threePointersAttempted;
      ftm += s.freeThrowsMade;
      fta += s.freeThrowsAttempted;
      oreb += s.offensiveRebounds;
      dreb += s.defensiveRebounds;
      reb += s.totalRebounds;
      ast += s.assists;
      stl += s.steals;
      blk += s.blocks;
      to += s.turnovers;
      pf += s.personalFouls;
    }

    return _TeamStats(
      points: points,
      fgm: fgm,
      fga: fga,
      tpm: tpm,
      tpa: tpa,
      ftm: ftm,
      fta: fta,
      oreb: oreb,
      dreb: dreb,
      reb: reb,
      ast: ast,
      stl: stl,
      blk: blk,
      to: to,
      pf: pf,
    );
  }

  List<_PlayerEfficiency> _calculatePlayerEfficiency(List<LocalPlayerStat> stats) {
    return stats.map((s) {
      // 효율성 = (PTS + REB + AST + STL + BLK) - (FGA - FGM) - (FTA - FTM) - TO
      final eff = (s.points + s.totalRebounds + s.assists + s.steals + s.blocks) -
          (s.fieldGoalsAttempted - s.fieldGoalsMade) -
          (s.freeThrowsAttempted - s.freeThrowsMade) -
          s.turnovers;

      return _PlayerEfficiency(
        playerId: s.tournamentTeamPlayerId,
        points: s.points,
        rebounds: s.totalRebounds,
        assists: s.assists,
        steals: s.steals,
        blocks: s.blocks,
        turnovers: s.turnovers,
        efficiency: eff,
        plusMinus: s.plusMinus,
      );
    }).toList()
      ..sort((a, b) => b.efficiency.compareTo(a.efficiency));
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
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('경기 분석'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '요약'),
            Tab(text: '팀 비교'),
            Tab(text: '효율성'),
            Tab(text: '흐름'),
          ],
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildTeamComparisonTab(),
          _buildEfficiencyTab(),
          _buildFlowTab(),
        ],
      ),
    );
  }

  /// 요약 탭
  Widget _buildSummaryTab() {
    final analysis = _analysis!;
    final match = analysis.match;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 최종 스코어
          _buildScoreCard(match),
          const SizedBox(height: 16),

          // 주요 지표
          _buildKeyMetricsCard(analysis),
          const SizedBox(height: 16),

          // 게임 하이라이트
          _buildHighlightsCard(analysis),
        ],
      ),
    );
  }

  Widget _buildScoreCard(LocalMatche? match) {
    return Card(
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'FINAL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 홈팀
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        widget.homeTeamName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${match?.homeScore ?? 0}',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: (match?.homeScore ?? 0) > (match?.awayScore ?? 0)
                              ? AppTheme.successColor
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                // VS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text(
                    '-',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                // 원정팀
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        widget.awayTeamName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${match?.awayScore ?? 0}',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: (match?.awayScore ?? 0) > (match?.homeScore ?? 0)
                              ? AppTheme.successColor
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsCard(_GameAnalysis analysis) {
    return Card(
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '주요 지표',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    '리드 변경',
                    '${analysis.leadChanges}회',
                    Icons.swap_horiz,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    '동점',
                    '${analysis.ties}회',
                    Icons.balance,
                    AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    '${widget.homeTeamName} 최대 리드',
                    '+${analysis.biggestHomeLead}',
                    Icons.arrow_upward,
                    AppTheme.homeTeamColor,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    '${widget.awayTeamName} 최대 리드',
                    '+${analysis.biggestAwayLead}',
                    Icons.arrow_upward,
                    AppTheme.awayTeamColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsCard(_GameAnalysis analysis) {
    return Card(
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '득점 분석',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildComparisonRow(
              '페인트 득점',
              analysis.homePaintPoints,
              analysis.awayPaintPoints,
            ),
            _buildComparisonRow(
              '패스트브레이크',
              analysis.homeFastBreak,
              analysis.awayFastBreak,
            ),
            _buildComparisonRow(
              '세컨찬스',
              analysis.homeSecondChance,
              analysis.awaySecondChance,
            ),
            _buildComparisonRow(
              '턴오버 유발',
              analysis.homeFromTurnover,
              analysis.awayFromTurnover,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String label, int homeValue, int awayValue) {
    final total = homeValue + awayValue;
    final homeRatio = total > 0 ? homeValue / total : 0.5;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$homeValue',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: homeValue > awayValue
                      ? AppTheme.homeTeamColor
                      : AppTheme.textSecondary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '$awayValue',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: awayValue > homeValue
                      ? AppTheme.awayTeamColor
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 비교 바
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: AppTheme.dividerColor,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: (homeRatio * 100).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.homeTeamColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Expanded(
                  flex: ((1 - homeRatio) * 100).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.awayTeamColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 팀 비교 탭
  Widget _buildTeamComparisonTab() {
    final analysis = _analysis!;
    final home = analysis.homeTeamStats;
    final away = analysis.awayTeamStats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.homeTeamName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.homeTeamColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 100), // 중앙 라벨 공간
                Expanded(
                  child: Text(
                    widget.awayTeamName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.awayTeamColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // 슈팅 통계
          _buildStatCompareRow('FG%', home.fgPercentage, away.fgPercentage, isPercentage: true),
          _buildStatCompareRow('3P%', home.tpPercentage, away.tpPercentage, isPercentage: true),
          _buildStatCompareRow('FT%', home.ftPercentage, away.ftPercentage, isPercentage: true),
          const Divider(),
          // 기본 통계
          _buildStatCompareRow('리바운드', home.reb.toDouble(), away.reb.toDouble()),
          _buildStatCompareRow('공격 리바운드', home.oreb.toDouble(), away.oreb.toDouble()),
          _buildStatCompareRow('수비 리바운드', home.dreb.toDouble(), away.dreb.toDouble()),
          const Divider(),
          _buildStatCompareRow('어시스트', home.ast.toDouble(), away.ast.toDouble()),
          _buildStatCompareRow('스틸', home.stl.toDouble(), away.stl.toDouble()),
          _buildStatCompareRow('블락', home.blk.toDouble(), away.blk.toDouble()),
          const Divider(),
          _buildStatCompareRow('턴오버', home.to.toDouble(), away.to.toDouble(), lowerIsBetter: true),
          _buildStatCompareRow('파울', home.pf.toDouble(), away.pf.toDouble(), lowerIsBetter: true),
        ],
      ),
    );
  }

  Widget _buildStatCompareRow(
    String label,
    double homeValue,
    double awayValue, {
    bool isPercentage = false,
    bool lowerIsBetter = false,
  }) {
    final homeWins = lowerIsBetter ? homeValue < awayValue : homeValue > awayValue;
    final awayWins = lowerIsBetter ? awayValue < homeValue : awayValue > homeValue;

    String formatValue(double v) {
      if (isPercentage) {
        return '${v.toStringAsFixed(1)}%';
      }
      return v.toInt().toString();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // 홈 값
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (homeWins)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppTheme.successColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 10, color: Colors.white),
                  ),
                Text(
                  formatValue(homeValue),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: homeWins ? FontWeight.bold : FontWeight.normal,
                    color: homeWins ? AppTheme.homeTeamColor : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // 라벨
          Container(
            width: 100,
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // 원정 값
          Expanded(
            child: Row(
              children: [
                Text(
                  formatValue(awayValue),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: awayWins ? FontWeight.bold : FontWeight.normal,
                    color: awayWins ? AppTheme.awayTeamColor : AppTheme.textPrimary,
                  ),
                ),
                if (awayWins)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppTheme.successColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 10, color: Colors.white),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 효율성 탭
  Widget _buildEfficiencyTab() {
    final analysis = _analysis!;
    final db = ref.watch(databaseProvider);

    return FutureBuilder<List<LocalTournamentPlayer>>(
      future: Future.wait([
        db.tournamentDao.getPlayersByTeam(widget.homeTeamId),
        db.tournamentDao.getPlayersByTeam(widget.awayTeamId),
      ]).then((lists) => [...lists[0], ...lists[1]]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final playerMap = {for (var p in snapshot.data!) p.id: p};
        final allEfficiency = [
          ...analysis.homePlayerEfficiency.map((e) => _EfficiencyWithTeam(e, true)),
          ...analysis.awayPlayerEfficiency.map((e) => _EfficiencyWithTeam(e, false)),
        ]..sort((a, b) => b.eff.efficiency.compareTo(a.eff.efficiency));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allEfficiency.length,
          itemBuilder: (context, index) {
            final item = allEfficiency[index];
            final player = playerMap[item.eff.playerId];
            if (player == null) return const SizedBox.shrink();

            return _buildEfficiencyCard(player, item.eff, item.isHome, index + 1);
          },
        );
      },
    );
  }

  Widget _buildEfficiencyCard(
    LocalTournamentPlayer player,
    _PlayerEfficiency eff,
    bool isHome,
    int rank,
  ) {
    final teamColor = isHome ? AppTheme.homeTeamColor : AppTheme.awayTeamColor;

    return Card(
      color: AppTheme.surfaceColor,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 순위
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank <= 3 ? AppTheme.secondaryColor : AppTheme.textHint.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 선수 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: teamColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        player.userNickname ?? player.userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (player.jerseyNumber != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '#${player.jerseyNumber}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 스탯 요약
                  Text(
                    '${eff.points}pts  ${eff.rebounds}reb  ${eff.assists}ast',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // 효율성
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'EFF ${eff.efficiency}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: eff.efficiency >= 15
                        ? AppTheme.successColor
                        : eff.efficiency >= 0
                            ? AppTheme.textPrimary
                            : AppTheme.errorColor,
                  ),
                ),
                Text(
                  '+/- ${eff.plusMinus >= 0 ? '+' : ''}${eff.plusMinus}',
                  style: TextStyle(
                    fontSize: 11,
                    color: eff.plusMinus > 0
                        ? AppTheme.successColor
                        : eff.plusMinus < 0
                            ? AppTheme.errorColor
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

  /// 흐름 탭
  Widget _buildFlowTab() {
    final analysis = _analysis!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '득점 흐름',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // 간단한 점수 흐름 차트
          for (int q = 1; q <= 4; q++) ...[
            _buildQuarterFlowCard(q, analysis.quarterFlow[q] ?? []),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildQuarterFlowCard(int quarter, List<_ScorePoint> points) {
    if (points.isEmpty) {
      return Card(
        color: AppTheme.surfaceColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$quarter쿼터',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  '득점 기록 없음',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 쿼터 시작/끝 점수
    final startPoint = points.first;
    final endPoint = points.last;
    final homeQuarterPoints = endPoint.homeScore - (quarter > 1 ? startPoint.homeScore : 0);
    final awayQuarterPoints = endPoint.awayScore - (quarter > 1 ? startPoint.awayScore : 0);

    return Card(
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$quarter쿼터',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.homeTeamColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+$homeQuarterPoints',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.homeTeamColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.awayTeamColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+$awayQuarterPoints',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.awayTeamColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 간단한 점수 차이 흐름
            SizedBox(
              height: 60,
              child: CustomPaint(
                painter: _ScoreFlowPainter(
                  points: points,
                  homeColor: AppTheme.homeTeamColor,
                  awayColor: AppTheme.awayTeamColor,
                ),
                size: const Size(double.infinity, 60),
              ),
            ),
            const SizedBox(height: 8),
            // 최종 스코어
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${endPoint.homeScore} - ${endPoint.awayScore}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '점수차: ${(endPoint.homeScore - endPoint.awayScore).abs()}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 점수 흐름 페인터
class _ScoreFlowPainter extends CustomPainter {
  final List<_ScorePoint> points;
  final Color homeColor;
  final Color awayColor;

  _ScoreFlowPainter({
    required this.points,
    required this.homeColor,
    required this.awayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // 점수 차이 범위 계산
    int minDiff = 0, maxDiff = 0;
    for (final p in points) {
      final diff = p.homeScore - p.awayScore;
      minDiff = math.min(minDiff, diff);
      maxDiff = math.max(maxDiff, diff);
    }
    final range = math.max((maxDiff - minDiff).abs(), 1);

    // 중앙선 그리기
    final centerY = size.height / 2;
    final centerPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      centerPaint,
    );

    // 점수 차이 영역 그리기
    final path = Path();
    path.moveTo(0, centerY);

    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final diff = points[i].homeScore - points[i].awayScore;
      final normalizedDiff = range > 0 ? diff / range : 0;
      final y = centerY - (normalizedDiff * (size.height / 2 - 5));
      path.lineTo(x, y);
    }

    // 끝점에서 시작점으로 돌아가기 (채우기용)
    path.lineTo(size.width, centerY);
    path.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          homeColor.withValues(alpha: 0.3),
          awayColor.withValues(alpha: 0.3),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, fillPaint);

    // 라인 그리기
    final linePath = Path();
    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final diff = points[i].homeScore - points[i].awayScore;
      final normalizedDiff = range > 0 ? diff / range : 0;
      final y = centerY - (normalizedDiff * (size.height / 2 - 5));

      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _ScoreFlowPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

/// 분석 데이터 클래스들
class _GameAnalysis {
  final LocalMatche? match;
  final _TeamStats homeTeamStats;
  final _TeamStats awayTeamStats;
  final int biggestHomeLead;
  final int biggestAwayLead;
  final int leadChanges;
  final int ties;
  final Map<int, List<_ScorePoint>> quarterFlow;
  final int homePaintPoints;
  final int awayPaintPoints;
  final int homeFastBreak;
  final int awayFastBreak;
  final int homeSecondChance;
  final int awaySecondChance;
  final int homeFromTurnover;
  final int awayFromTurnover;
  final List<_PlayerEfficiency> homePlayerEfficiency;
  final List<_PlayerEfficiency> awayPlayerEfficiency;

  const _GameAnalysis({
    required this.match,
    required this.homeTeamStats,
    required this.awayTeamStats,
    required this.biggestHomeLead,
    required this.biggestAwayLead,
    required this.leadChanges,
    required this.ties,
    required this.quarterFlow,
    required this.homePaintPoints,
    required this.awayPaintPoints,
    required this.homeFastBreak,
    required this.awayFastBreak,
    required this.homeSecondChance,
    required this.awaySecondChance,
    required this.homeFromTurnover,
    required this.awayFromTurnover,
    required this.homePlayerEfficiency,
    required this.awayPlayerEfficiency,
  });
}

class _TeamStats {
  final int points, fgm, fga, tpm, tpa, ftm, fta;
  final int oreb, dreb, reb, ast, stl, blk, to, pf;

  const _TeamStats({
    required this.points,
    required this.fgm,
    required this.fga,
    required this.tpm,
    required this.tpa,
    required this.ftm,
    required this.fta,
    required this.oreb,
    required this.dreb,
    required this.reb,
    required this.ast,
    required this.stl,
    required this.blk,
    required this.to,
    required this.pf,
  });

  double get fgPercentage => fga > 0 ? (fgm / fga) * 100 : 0;
  double get tpPercentage => tpa > 0 ? (tpm / tpa) * 100 : 0;
  double get ftPercentage => fta > 0 ? (ftm / fta) * 100 : 0;
}

class _ScorePoint {
  final int homeScore;
  final int awayScore;
  final int time;

  const _ScorePoint({
    required this.homeScore,
    required this.awayScore,
    required this.time,
  });
}

class _PlayerEfficiency {
  final int playerId;
  final int points;
  final int rebounds;
  final int assists;
  final int steals;
  final int blocks;
  final int turnovers;
  final int efficiency;
  final int plusMinus;

  const _PlayerEfficiency({
    required this.playerId,
    required this.points,
    required this.rebounds,
    required this.assists,
    required this.steals,
    required this.blocks,
    required this.turnovers,
    required this.efficiency,
    required this.plusMinus,
  });
}

class _EfficiencyWithTeam {
  final _PlayerEfficiency eff;
  final bool isHome;

  const _EfficiencyWithTeam(this.eff, this.isHome);
}
