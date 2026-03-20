import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';
import '../../../di/providers.dart';
import '../../widgets/shot_chart/shot_chart_painter.dart';
import '../../widgets/shot_chart/shot_filter_widget.dart';

/// 슛차트 뷰 모드
enum ShotChartViewMode {
  scatter, // 산점도
  heatmap, // 히트맵
  zone, // 존차트
}

/// 슛차트 화면
class ShotChartScreen extends ConsumerStatefulWidget {
  const ShotChartScreen({
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
  ConsumerState<ShotChartScreen> createState() => _ShotChartScreenState();
}

class _ShotChartScreenState extends ConsumerState<ShotChartScreen> {
  ShotChartViewMode _viewMode = ShotChartViewMode.scatter;
  ShotFilterState _filter = const ShotFilterState();

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('슛차트'),
        actions: [
          // 뷰 모드 선택
          PopupMenuButton<ShotChartViewMode>(
            icon: const Icon(Icons.view_module),
            tooltip: '뷰 모드',
            onSelected: (mode) => setState(() => _viewMode = mode),
            itemBuilder: (context) => [
              _buildViewModeItem(ShotChartViewMode.scatter, '산점도', Icons.scatter_plot),
              _buildViewModeItem(ShotChartViewMode.heatmap, '히트맵', Icons.gradient),
              _buildViewModeItem(ShotChartViewMode.zone, '존차트', Icons.grid_view),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터
          ShotFilterWidget(
            filter: _filter,
            homeTeamName: widget.homeTeamName,
            awayTeamName: widget.awayTeamName,
            homeTeamId: widget.homeTeamId,
            awayTeamId: widget.awayTeamId,
            matchId: widget.matchId,
            database: database,
            onFilterChanged: (filter) => setState(() => _filter = filter),
          ),
          // 슛차트
          Expanded(
            child: _buildShotChart(database),
          ),
          // 범례
          _buildLegend(),
        ],
      ),
    );
  }

  PopupMenuItem<ShotChartViewMode> _buildViewModeItem(
    ShotChartViewMode mode,
    String label,
    IconData icon,
  ) {
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: _viewMode == mode ? AppTheme.primaryColor : AppTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: _viewMode == mode ? AppTheme.primaryColor : AppTheme.textPrimary,
            ),
          ),
          if (_viewMode == mode) ...[
            const Spacer(),
            const Icon(Icons.check, size: 16, color: AppTheme.primaryColor),
          ],
        ],
      ),
    );
  }

  Widget _buildShotChart(AppDatabase database) {
    return StreamBuilder<List<LocalPlayByPlay>>(
      stream: database.playByPlayDao.watchShotsByMatch(widget.matchId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // 필터 적용
        final shots = _applyFilter(snapshot.data!);

        if (shots.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_basketball, size: 64, color: AppTheme.textHint),
                SizedBox(height: 16),
                Text(
                  '슛 데이터가 없습니다',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        // 통계 계산
        final stats = _calculateStats(shots);

        return Column(
          children: [
            // 슛 통계 요약
            _buildStatsSummary(stats),
            // 코트 + 슛차트
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 94 / 50, // NBA 코트 비율
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.courtColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.courtLineColor, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CustomPaint(
                          painter: ShotChartPainter(
                            shots: shots,
                            viewMode: _viewMode,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<LocalPlayByPlay> _applyFilter(List<LocalPlayByPlay> shots) {
    return shots.where((shot) {
      // 팀 필터
      if (_filter.teamId != null && shot.tournamentTeamId != _filter.teamId) {
        return false;
      }

      // 선수 필터
      if (_filter.playerId != null && shot.tournamentTeamPlayerId != _filter.playerId) {
        return false;
      }

      // 쿼터 필터
      if (_filter.quarter != null && shot.quarter != _filter.quarter) {
        return false;
      }

      // 성공/실패 필터
      if (_filter.madeOnly && shot.isMade != true) {
        return false;
      }
      if (_filter.missedOnly && shot.isMade != false) {
        return false;
      }

      // 슛 타입 필터
      if (_filter.shotType != null) {
        if (_filter.shotType == '2pt' && shot.actionSubtype != '2pt') {
          return false;
        }
        if (_filter.shotType == '3pt' && shot.actionSubtype != '3pt') {
          return false;
        }
        if (_filter.shotType == 'ft' && shot.actionSubtype != 'ft') {
          return false;
        }
      }

      return true;
    }).toList();
  }

  _ShotStats _calculateStats(List<LocalPlayByPlay> shots) {
    int totalShots = 0, madeShots = 0;
    int twoPointers = 0, twoPointersMade = 0;
    int threePointers = 0, threePointersMade = 0;
    int freeThrows = 0, freeThrowsMade = 0;
    int totalPoints = 0;

    for (final shot in shots) {
      if (shot.actionSubtype == 'ft') {
        freeThrows++;
        if (shot.isMade == true) {
          freeThrowsMade++;
          totalPoints += 1;
        }
      } else if (shot.actionSubtype == '3pt') {
        threePointers++;
        totalShots++;
        if (shot.isMade == true) {
          threePointersMade++;
          madeShots++;
          totalPoints += 3;
        }
      } else {
        twoPointers++;
        totalShots++;
        if (shot.isMade == true) {
          twoPointersMade++;
          madeShots++;
          totalPoints += 2;
        }
      }
    }

    return _ShotStats(
      totalShots: totalShots,
      madeShots: madeShots,
      twoPointers: twoPointers,
      twoPointersMade: twoPointersMade,
      threePointers: threePointers,
      threePointersMade: threePointersMade,
      freeThrows: freeThrows,
      freeThrowsMade: freeThrowsMade,
      totalPoints: totalPoints,
    );
  }

  Widget _buildStatsSummary(_ShotStats stats) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(bottom: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'FG',
            '${stats.madeShots}/${stats.totalShots}',
            stats.fgPercentage,
          ),
          _buildStatItem(
            '2P',
            '${stats.twoPointersMade}/${stats.twoPointers}',
            stats.twoPointPercentage,
          ),
          _buildStatItem(
            '3P',
            '${stats.threePointersMade}/${stats.threePointers}',
            stats.threePointPercentage,
          ),
          _buildStatItem(
            'FT',
            '${stats.freeThrowsMade}/${stats.freeThrows}',
            stats.ftPercentage,
          ),
          _buildStatItem(
            'PTS',
            '${stats.totalPoints}',
            null,
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, double? percentage, {bool highlight = false}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 20 : 14,
            fontWeight: FontWeight.bold,
            color: highlight ? AppTheme.secondaryColor : AppTheme.textPrimary,
          ),
        ),
        if (percentage != null)
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 10,
              color: percentage >= 50
                  ? AppTheme.successColor
                  : percentage >= 33
                      ? AppTheme.textSecondary
                      : AppTheme.errorColor,
            ),
          ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: _viewMode == ShotChartViewMode.heatmap
          ? _buildHeatmapLegend()
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(AppTheme.shotMadeColor, '성공'),
                const SizedBox(width: 24),
                _buildLegendItem(AppTheme.shotMissedColor, '실패'),
                if (_viewMode == ShotChartViewMode.zone) ...[
                  const SizedBox(width: 24),
                  _buildLegendItem(AppTheme.primaryColor, '높은 성공률'),
                ],
              ],
            ),
    );
  }

  /// 히트맵 전용 그라데이션 범례
  Widget _buildHeatmapLegend() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 성공률 그라데이션 바
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '성공률: ',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '0%',
              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            ),
            const SizedBox(width: 4),
            Container(
              width: 150,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE53935), // 빨강
                    Color(0xFFFF9800), // 주황
                    Color(0xFFFFEB3B), // 노랑
                    Color(0xFF4CAF50), // 초록
                  ],
                  stops: [0.0, 0.33, 0.5, 1.0],
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '100%',
              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 핫존 설명
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '핫존 (가장 많은 슛 시도)',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.info_outline, size: 14, color: AppTheme.textHint),
            const SizedBox(width: 4),
            const Text(
              '색 진하기 = 슛 시도량',
              style: TextStyle(fontSize: 10, color: AppTheme.textHint),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: _viewMode == ShotChartViewMode.zone ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: _viewMode == ShotChartViewMode.zone ? BorderRadius.circular(2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// 슛 통계
class _ShotStats {
  final int totalShots;
  final int madeShots;
  final int twoPointers;
  final int twoPointersMade;
  final int threePointers;
  final int threePointersMade;
  final int freeThrows;
  final int freeThrowsMade;
  final int totalPoints;

  const _ShotStats({
    required this.totalShots,
    required this.madeShots,
    required this.twoPointers,
    required this.twoPointersMade,
    required this.threePointers,
    required this.threePointersMade,
    required this.freeThrows,
    required this.freeThrowsMade,
    required this.totalPoints,
  });

  double get fgPercentage => totalShots > 0 ? (madeShots / totalShots) * 100 : 0;
  double get twoPointPercentage => twoPointers > 0 ? (twoPointersMade / twoPointers) * 100 : 0;
  double get threePointPercentage => threePointers > 0 ? (threePointersMade / threePointers) * 100 : 0;
  double get ftPercentage => freeThrows > 0 ? (freeThrowsMade / freeThrows) * 100 : 0;
}
