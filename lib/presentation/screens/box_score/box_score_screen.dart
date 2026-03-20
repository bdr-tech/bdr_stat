import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';
import '../../../di/providers.dart';
import '../../../domain/models/quarter_stats_models.dart';

// ── 컬럼 정의 (Sprint 2: FG%/3P%/FT%/+/- 추가) ─────────────────────────────
class _Col {
  final String label;
  final int flex;
  const _Col(this.label, this.flex);
}

const _playerFlex = 5; // 선수 이름 열
const _cols = [
  _Col('MIN', 2),
  _Col('PTS', 2),
  _Col('FG',  3),
  _Col('FG%', 3),  // FR-002
  _Col('3P',  3),
  _Col('3P%', 3),  // FR-002
  _Col('FT',  3),
  _Col('FT%', 3),  // FR-002
  _Col('OR',  2),
  _Col('DR',  2),
  _Col('REB', 2),
  _Col('AST', 2),
  _Col('STL', 2),
  _Col('BLK', 2),
  _Col('TO',  2),
  _Col('PF',  2),
  _Col('+/-', 2), // FR-003
];

/// NBA 스타일 박스스코어 화면 (Sprint 2)
///
/// FR-001: 쿼터 탭 (전체/Q1/Q2/Q3/Q4/OT)
/// FR-002: FG%/3P%/FT% 컬럼
/// FR-003: +/- 코트마진 컬럼
class BoxScoreScreen extends ConsumerStatefulWidget {
  const BoxScoreScreen({
    super.key,
    required this.matchId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeTeamId,
    required this.awayTeamId,
    this.homeScore = 0,
    this.awayScore = 0,
    this.isLive = false,
  });

  final int matchId;
  final String homeTeamName;
  final String awayTeamName;
  final int homeTeamId;
  final int awayTeamId;
  final int homeScore;
  final int awayScore;
  final bool isLive;

  @override
  ConsumerState<BoxScoreScreen> createState() => _BoxScoreScreenState();
}

class _BoxScoreScreenState extends ConsumerState<BoxScoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _selectedQuarter; // null = ALL, 1-4 = Q1-Q4, 5+ = OT

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
    final database = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/matches');
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('박스스코어', style: TextStyle(fontSize: 16)),
            if (widget.isLive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(140),
          child: Column(
            children: [
              _buildScoreHeader(),
              // FR-001: 쿼터 필터 탭
              _buildQuarterTabs(),
              // 홈/어웨이 팀 탭
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8, height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            color: AppTheme.homeTeamColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Flexible(child: Text(widget.homeTeamName, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8, height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            color: AppTheme.awayTeamColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Flexible(child: Text(widget.awayTeamName, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ],
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.textPrimary,
                unselectedLabelColor: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TeamBoxScore(
            matchId: widget.matchId,
            teamId: widget.homeTeamId,
            teamName: widget.homeTeamName,
            isHome: true,
            database: database,
            selectedQuarter: _selectedQuarter,
            onStatEdit: _onStatEdit,
          ),
          _TeamBoxScore(
            matchId: widget.matchId,
            teamId: widget.awayTeamId,
            teamName: widget.awayTeamName,
            isHome: false,
            database: database,
            selectedQuarter: _selectedQuarter,
            onStatEdit: _onStatEdit,
          ),
        ],
      ),
    );
  }

  /// FR-001: 쿼터 필터 탭
  Widget _buildQuarterTabs() {
    final tabs = [
      _QuarterTab(label: '전체', value: null),
      _QuarterTab(label: 'Q1', value: 1),
      _QuarterTab(label: 'Q2', value: 2),
      _QuarterTab(label: 'Q3', value: 3),
      _QuarterTab(label: 'Q4', value: 4),
      _QuarterTab(label: 'OT', value: 5),
    ];

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedQuarter == tab.value;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedQuarter = tab.value),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(6),
                  border: isSelected
                      ? null
                      : Border.all(color: AppTheme.borderColor, width: 0.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScoreHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(widget.homeTeamName,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis),
                Text('${widget.homeScore}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.homeTeamColor)),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.awayTeamName,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis),
                Text('${widget.awayScore}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.awayTeamColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onStatEdit(LocalPlayerStat stat, LocalTournamentPlayer player) async {
    // 선수 프로필 페이지로 이동 (NBA.com 스타일)
    final playerId = player.userId;
    if (playerId != null && playerId > 0) {
      final url = 'https://mybdr.kr/players/$playerId';
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    }
  }
}

class _QuarterTab {
  final String label;
  final int? value;
  const _QuarterTab({required this.label, required this.value});
}

// ── 팀별 박스스코어 (쿼터 집계 지원) ─────────────────────────────────────────

class _TeamBoxScore extends StatelessWidget {
  const _TeamBoxScore({
    required this.matchId,
    required this.teamId,
    required this.teamName,
    required this.isHome,
    required this.database,
    required this.selectedQuarter,
    required this.onStatEdit,
  });

  final int matchId;
  final int teamId;
  final String teamName;
  final bool isHome;
  final AppDatabase database;
  final int? selectedQuarter; // null = ALL
  final Future<void> Function(LocalPlayerStat, LocalTournamentPlayer) onStatEdit;

  @override
  Widget build(BuildContext context) {
    // ALL 탭: LocalPlayerStats 직접 (source of truth)
    // 쿼터 탭: PlayByPlay 집계 쿼리
    if (selectedQuarter == null) {
      return _buildFromPlayerStats();
    } else {
      return _buildFromQuarterStats();
    }
  }

  /// ALL 탭: LocalPlayerStats 기반 (기존 로직 + FG%/+/- 추가)
  Widget _buildFromPlayerStats() {
    return StreamBuilder<List<LocalPlayerStat>>(
      stream: database.playerStatsDao.watchStatsByMatchAndTeam(matchId, teamId),
      builder: (context, statsSnapshot) {
        if (!statsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = statsSnapshot.data!;
        if (stats.isEmpty) {
          return const Center(
            child: Text('선수 데이터가 없습니다', style: TextStyle(color: AppTheme.textSecondary)),
          );
        }
        return FutureBuilder<List<LocalTournamentPlayer>>(
          future: database.tournamentDao.getPlayersByTeam(teamId),
          builder: (context, playersSnapshot) {
            if (!playersSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final players = playersSnapshot.data!;
            final playerMap = {for (var p in players) p.id: p};

            stats.sort((a, b) {
              if (a.isStarter != b.isStarter) return a.isStarter ? -1 : 1;
              return b.points.compareTo(a.points);
            });

            return Column(
              children: [
                _StatHeader(),
                Expanded(
                  child: ListView.builder(
                    itemCount: stats.length,
                    itemBuilder: (context, index) {
                      final stat = stats[index];
                      final player = playerMap[stat.tournamentTeamPlayerId];
                      if (player == null) return const SizedBox.shrink();
                      return _PlayerRow(
                        stat: stat,
                        player: player,
                        isOdd: index.isOdd,
                        onTap: () => onStatEdit(stat, player),
                      );
                    },
                  ),
                ),
                _TeamTotalRow(stats: stats, isHome: isHome),
              ],
            );
          },
        );
      },
    );
  }

  /// 쿼터 탭: PlayByPlay 집계 쿼리 기반
  Widget _buildFromQuarterStats() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: database.playByPlayDao.getTeamQuarterStats(
        matchId: matchId,
        teamId: teamId,
        quarter: selectedQuarter,
      ),
      builder: (context, statsSnapshot) {
        if (!statsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rawStats = statsSnapshot.data!;
        if (rawStats.isEmpty) {
          return Center(
            child: Text(
              'Q$selectedQuarter 기록이 없습니다',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        final quarterStats = rawStats
            .map((row) => PlayerQuarterStats.fromQueryRow(row, quarter: selectedQuarter))
            .toList();

        return FutureBuilder<List<LocalTournamentPlayer>>(
          future: database.tournamentDao.getPlayersByTeam(teamId),
          builder: (context, playersSnapshot) {
            if (!playersSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final players = playersSnapshot.data!;
            final playerMap = {for (var p in players) p.id: p};

            return Column(
              children: [
                _StatHeader(),
                Expanded(
                  child: ListView.builder(
                    itemCount: quarterStats.length,
                    itemBuilder: (context, index) {
                      final qs = quarterStats[index];
                      final player = playerMap[qs.playerId];
                      if (player == null) return const SizedBox.shrink();
                      return _QuarterPlayerRow(
                        stats: qs,
                        player: player,
                        isOdd: index.isOdd,
                      );
                    },
                  ),
                ),
                _QuarterTeamTotalRow(stats: quarterStats, isHome: isHome),
              ],
            );
          },
        );
      },
    );
  }
}

// ── 공통 Row 빌더 ──────────────────────────────────────────────────────────

Widget _buildStatRow({
  required Widget nameCell,
  required List<String> values,
  Color? bgColor,
  TextStyle? valueStyle,
  List<TextStyle?>? perColStyles,
}) {
  return Container(
    color: bgColor,
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    child: Row(
      children: [
        Expanded(flex: _playerFlex, child: nameCell),
        for (int i = 0; i < _cols.length; i++)
          Expanded(
            flex: _cols[i].flex,
            child: Text(
              i < values.length ? values[i] : '',
              textAlign: TextAlign.center,
              style: perColStyles != null && i < perColStyles.length && perColStyles[i] != null
                  ? perColStyles[i]!
                  : valueStyle ?? const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            ),
          ),
      ],
    ),
  );
}

// ── 헤더 행 ──────────────────────────────────────────────────────────────────

class _StatHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(bottom: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: _buildStatRow(
        nameCell: const Text('PLAYER',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
        values: _cols.map((c) => c.label).toList(),
        valueStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
      ),
    );
  }
}

// ── 선수 행 (ALL 탭) ─────────────────────────────────────────────────────────

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.stat,
    required this.player,
    required this.isOdd,
    required this.onTap,
  });

  final LocalPlayerStat stat;
  final LocalTournamentPlayer player;
  final bool isOdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // FR-002: FG%, 3P%, FT% 계산
    final fgPct = stat.fieldGoalsAttempted > 0
        ? (stat.fieldGoalsMade / stat.fieldGoalsAttempted * 100)
        : null;
    final tpPct = stat.threePointersAttempted > 0
        ? (stat.threePointersMade / stat.threePointersAttempted * 100)
        : null;
    final ftPct = stat.freeThrowsAttempted > 0
        ? (stat.freeThrowsMade / stat.freeThrowsAttempted * 100)
        : null;

    // FR-003: +/- 포맷
    final pmStr = stat.plusMinus > 0
        ? '+${stat.plusMinus}'
        : '${stat.plusMinus}';

    final values = [
      '${stat.minutesPlayed}',
      '${stat.points}',
      '${stat.fieldGoalsMade}-${stat.fieldGoalsAttempted}',
      PlayerQuarterStats.formatPercentage(fgPct),
      '${stat.threePointersMade}-${stat.threePointersAttempted}',
      PlayerQuarterStats.formatPercentage(tpPct),
      '${stat.freeThrowsMade}-${stat.freeThrowsAttempted}',
      PlayerQuarterStats.formatPercentage(ftPct),
      '${stat.offensiveRebounds}',
      '${stat.defensiveRebounds}',
      '${stat.totalRebounds}',
      '${stat.assists}',
      '${stat.steals}',
      '${stat.blocks}',
      '${stat.turnovers}',
      '${stat.personalFouls}',
      pmStr,
    ];

    // 컬럼별 스타일
    final styles = <TextStyle?>[
      const TextStyle(fontSize: 10, color: AppTheme.textSecondary), // MIN
      TextStyle(fontSize: 11, fontWeight: FontWeight.bold, // PTS
        color: stat.points >= 20 ? AppTheme.secondaryColor
            : stat.points >= 10 ? AppTheme.textPrimary
            : AppTheme.textSecondary),
      null, // FG
      _pctStyle(fgPct), // FG%
      null, // 3P
      _pctStyle(tpPct), // 3P%
      null, // FT
      _pctStyle(ftPct), // FT%
      null, null, // OR, DR
      TextStyle(fontSize: 10, fontWeight: FontWeight.bold, // REB
        color: stat.totalRebounds >= 10 ? AppTheme.primaryColor : AppTheme.textSecondary),
      TextStyle(fontSize: 10, // AST
        color: stat.assists >= 10 ? AppTheme.primaryColor : AppTheme.textSecondary),
      null, null, // STL, BLK
      TextStyle(fontSize: 10, // TO
        color: stat.turnovers >= 5 ? AppTheme.errorColor : AppTheme.textSecondary),
      TextStyle(fontSize: 10, // PF
        color: stat.personalFouls >= 5 ? AppTheme.errorColor
            : stat.personalFouls >= 4 ? AppTheme.warningColor
            : AppTheme.textSecondary),
      _pmStyle(stat.plusMinus), // +/- (FR-003)
    ];

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isOdd ? AppTheme.cardColor.withValues(alpha: 0.3) : null,
          border: const Border(bottom: BorderSide(color: AppTheme.dividerColor, width: 0.5)),
        ),
        child: _buildStatRow(
          nameCell: _buildNameCell(stat, player),
          values: values,
          perColStyles: styles,
        ),
      ),
    );
  }
}

// ── 선수 행 (쿼터 탭) ────────────────────────────────────────────────────────

class _QuarterPlayerRow extends StatelessWidget {
  const _QuarterPlayerRow({
    required this.stats,
    required this.player,
    required this.isOdd,
  });

  final PlayerQuarterStats stats;
  final LocalTournamentPlayer player;
  final bool isOdd;

  @override
  Widget build(BuildContext context) {
    final pmStr = ''; // 쿼터별 +/-는 미지원 (경기 통산만)

    final values = [
      '', // MIN (쿼터별 출전시간 미추적)
      '${stats.totalPoints}',
      '${stats.fgm}-${stats.fga}',
      PlayerQuarterStats.formatPercentage(stats.fgPercentage),
      '${stats.threePm}-${stats.threePa}',
      PlayerQuarterStats.formatPercentage(stats.threePercentage),
      '${stats.ftm}-${stats.fta}',
      PlayerQuarterStats.formatPercentage(stats.ftPercentage),
      '${stats.offensiveRebounds}',
      '${stats.defensiveRebounds}',
      '${stats.totalRebounds}',
      '${stats.assists}',
      '${stats.steals}',
      '${stats.blocks}',
      '${stats.turnovers}',
      '${stats.personalFouls}',
      pmStr,
    ];

    return Container(
      decoration: BoxDecoration(
        color: isOdd ? AppTheme.cardColor.withValues(alpha: 0.3) : null,
        border: const Border(bottom: BorderSide(color: AppTheme.dividerColor, width: 0.5)),
      ),
      child: _buildStatRow(
        nameCell: Row(
          children: [
            Text('#${player.jerseyNumber ?? '-'}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
            const SizedBox(width: 3),
            Expanded(
              child: Text(player.userNickname ?? player.userName,
                style: const TextStyle(fontSize: 10, color: AppTheme.textPrimary),
                overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        values: values,
      ),
    );
  }
}

// ── TEAM 합계 행 (ALL 탭) ────────────────────────────────────────────────────

class _TeamTotalRow extends StatelessWidget {
  const _TeamTotalRow({required this.stats, required this.isHome});

  final List<LocalPlayerStat> stats;
  final bool isHome;

  @override
  Widget build(BuildContext context) {
    int pts = 0, fgm = 0, fga = 0, tpm = 0, tpa = 0, ftm = 0, fta = 0;
    int oreb = 0, dreb = 0, reb = 0, ast = 0, stl = 0, blk = 0, to = 0, pf = 0;

    for (final s in stats) {
      pts += s.points; fgm += s.fieldGoalsMade; fga += s.fieldGoalsAttempted;
      tpm += s.threePointersMade; tpa += s.threePointersAttempted;
      ftm += s.freeThrowsMade; fta += s.freeThrowsAttempted;
      oreb += s.offensiveRebounds; dreb += s.defensiveRebounds;
      reb += s.totalRebounds; ast += s.assists; stl += s.steals;
      blk += s.blocks; to += s.turnovers; pf += s.personalFouls;
    }

    final fgPct = fga > 0 ? (fgm / fga * 100) : null;
    final tpPct = tpa > 0 ? (tpm / tpa * 100) : null;
    final ftPct = fta > 0 ? (ftm / fta * 100) : null;

    final values = [
      '', '$pts',
      '$fgm-$fga', PlayerQuarterStats.formatPercentage(fgPct),
      '$tpm-$tpa', PlayerQuarterStats.formatPercentage(tpPct),
      '$ftm-$fta', PlayerQuarterStats.formatPercentage(ftPct),
      '$oreb', '$dreb', '$reb', '$ast', '$stl', '$blk', '$to', '$pf', '',
    ];

    final boldStyle = const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary);
    final normalStyle = const TextStyle(fontSize: 10, color: AppTheme.textPrimary);

    return Container(
      decoration: BoxDecoration(
        color: (isHome ? AppTheme.homeTeamColor : AppTheme.awayTeamColor).withValues(alpha: 0.1),
        border: const Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: _buildStatRow(
        nameCell: const Text('TEAM',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        values: values,
        perColStyles: [
          normalStyle, boldStyle,
          normalStyle, boldStyle,
          normalStyle, boldStyle,
          normalStyle, boldStyle,
          normalStyle, normalStyle, boldStyle,
          normalStyle, normalStyle, normalStyle, normalStyle, normalStyle, normalStyle,
        ],
      ),
    );
  }
}

// ── TEAM 합계 행 (쿼터 탭) ───────────────────────────────────────────────────

class _QuarterTeamTotalRow extends StatelessWidget {
  const _QuarterTeamTotalRow({required this.stats, required this.isHome});

  final List<PlayerQuarterStats> stats;
  final bool isHome;

  @override
  Widget build(BuildContext context) {
    int pts = 0, fgm = 0, fga = 0, tpm = 0, tpa = 0, ftm = 0, fta = 0;
    int oreb = 0, dreb = 0, reb = 0, ast = 0, stl = 0, blk = 0, to = 0, pf = 0;

    for (final s in stats) {
      pts += s.totalPoints; fgm += s.fgm; fga += s.fga;
      tpm += s.threePm; tpa += s.threePa;
      ftm += s.ftm; fta += s.fta;
      oreb += s.offensiveRebounds; dreb += s.defensiveRebounds;
      reb += s.totalRebounds; ast += s.assists; stl += s.steals;
      blk += s.blocks; to += s.turnovers; pf += s.personalFouls;
    }

    final fgPct = fga > 0 ? (fgm / fga * 100) : null;
    final tpPct = tpa > 0 ? (tpm / tpa * 100) : null;
    final ftPct = fta > 0 ? (ftm / fta * 100) : null;

    final values = [
      '', '$pts',
      '$fgm-$fga', PlayerQuarterStats.formatPercentage(fgPct),
      '$tpm-$tpa', PlayerQuarterStats.formatPercentage(tpPct),
      '$ftm-$fta', PlayerQuarterStats.formatPercentage(ftPct),
      '$oreb', '$dreb', '$reb', '$ast', '$stl', '$blk', '$to', '$pf', '',
    ];

    final boldStyle = const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary);
    final normalStyle = const TextStyle(fontSize: 10, color: AppTheme.textPrimary);

    return Container(
      decoration: BoxDecoration(
        color: (isHome ? AppTheme.homeTeamColor : AppTheme.awayTeamColor).withValues(alpha: 0.1),
        border: const Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: _buildStatRow(
        nameCell: const Text('TEAM',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        values: values,
        perColStyles: [
          normalStyle, boldStyle,
          normalStyle, boldStyle,
          normalStyle, boldStyle,
          normalStyle, boldStyle,
          normalStyle, normalStyle, boldStyle,
          normalStyle, normalStyle, normalStyle, normalStyle, normalStyle, normalStyle,
        ],
      ),
    );
  }
}

// ── 헬퍼 ─────────────────────────────────────────────────────────────────────

/// 선수 이름 셀 (공통)
Widget _buildNameCell(LocalPlayerStat stat, LocalTournamentPlayer player) {
  return Row(
    children: [
      Text('#${player.jerseyNumber ?? '-'}',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
          color: stat.isStarter ? AppTheme.primaryColor : AppTheme.textSecondary)),
      const SizedBox(width: 3),
      Expanded(
        child: Text(player.userNickname ?? player.userName,
          style: TextStyle(fontSize: 10,
            fontWeight: stat.isStarter ? FontWeight.bold : FontWeight.normal,
            color: AppTheme.textPrimary),
          overflow: TextOverflow.ellipsis),
      ),
      if (stat.isManuallyEdited)
        const Padding(padding: EdgeInsets.only(left: 2),
          child: Icon(Icons.edit, size: 8, color: AppTheme.warningColor)),
      if (stat.fouledOut)
        Container(
          margin: const EdgeInsets.only(left: 2),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          decoration: BoxDecoration(color: AppTheme.errorColor, borderRadius: BorderRadius.circular(2)),
          child: const Text('F', style: TextStyle(fontSize: 7, color: Colors.white)),
        ),
    ],
  );
}

/// FG%/3P%/FT% 스타일 (높은 퍼센티지 하이라이트)
TextStyle? _pctStyle(double? pct) {
  if (pct == null) {
    return const TextStyle(fontSize: 10, color: AppTheme.textSecondary);
  }
  if (pct >= 50.0) {
    return const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.successColor);
  }
  return const TextStyle(fontSize: 10, color: AppTheme.textSecondary);
}

/// +/- 스타일 (양수=녹색, 음수=적색)
TextStyle _pmStyle(int pm) {
  if (pm > 0) {
    return const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.successColor);
  } else if (pm < 0) {
    return const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.errorColor);
  }
  return const TextStyle(fontSize: 10, color: AppTheme.textSecondary);
}
