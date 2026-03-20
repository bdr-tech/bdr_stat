import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';
import '../../../di/providers.dart';

/// 데이터 검증 결과
class ValidationResult {
  final String title;
  final String description;
  final bool passed;
  final String? warning;

  const ValidationResult({
    required this.title,
    required this.description,
    required this.passed,
    this.warning,
  });
}

/// 최종 검토 화면
class FinalReviewScreen extends ConsumerStatefulWidget {
  const FinalReviewScreen({
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
  ConsumerState<FinalReviewScreen> createState() => _FinalReviewScreenState();
}

class _FinalReviewScreenState extends ConsumerState<FinalReviewScreen> {
  List<ValidationResult> _validations = [];
  bool _isLoading = true;
  LocalMatche? _match;
  List<LocalPlayerStat> _homeStats = [];
  List<LocalPlayerStat> _awayStats = [];
  Map<int, Map<String, int>> _quarterScores = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final database = ref.read(databaseProvider);

    // 경기 정보 로드
    _match = await database.matchDao.getMatchById(widget.matchId);

    // 선수 스탯 로드
    _homeStats = await database.playerStatsDao
        .getStatsByMatchAndTeam(widget.matchId, widget.homeTeamId);
    _awayStats = await database.playerStatsDao
        .getStatsByMatchAndTeam(widget.matchId, widget.awayTeamId);

    // 쿼터 점수 파싱
    if (_match != null && _match!.quarterScoresJson.isNotEmpty && _match!.quarterScoresJson != '{}') {
      try {
        final json = jsonDecode(_match!.quarterScoresJson);
        _quarterScores = (json as Map<String, dynamic>).map(
          (key, value) => MapEntry(
            int.parse(key),
            Map<String, int>.from(value as Map),
          ),
        );
      } catch (_) {}
    }

    // 검증 수행
    _validations = _validateData();

    setState(() => _isLoading = false);
  }

  List<ValidationResult> _validateData() {
    final validations = <ValidationResult>[];

    // 1. 득점 합계 검증
    final homePointsFromStats =
        _homeStats.fold<int>(0, (sum, s) => sum + s.points);
    final awayPointsFromStats =
        _awayStats.fold<int>(0, (sum, s) => sum + s.points);

    validations.add(ValidationResult(
      title: '홈팀 득점 합계',
      description:
          '박스스코어: $homePointsFromStats점 / 스코어보드: ${widget.homeScore}점',
      passed: homePointsFromStats == widget.homeScore,
      warning: homePointsFromStats != widget.homeScore
          ? '스코어보드와 박스스코어 합계가 다릅니다.'
          : null,
    ));

    validations.add(ValidationResult(
      title: '원정팀 득점 합계',
      description:
          '박스스코어: $awayPointsFromStats점 / 스코어보드: ${widget.awayScore}점',
      passed: awayPointsFromStats == widget.awayScore,
      warning: awayPointsFromStats != widget.awayScore
          ? '스코어보드와 박스스코어 합계가 다릅니다.'
          : null,
    ));

    // 2. 슛 기록 검증 (득점 = 2P*2 + 3P*3 + FT*1)
    for (final stats in [..._homeStats, ..._awayStats]) {
      final calculatedPoints = stats.twoPointersMade * 2 +
          stats.threePointersMade * 3 +
          stats.freeThrowsMade;
      if (calculatedPoints != stats.points && stats.points > 0) {
        validations.add(ValidationResult(
          title: '선수 #${stats.tournamentTeamPlayerId} 득점 검증',
          description: '계산: $calculatedPoints점 / 기록: ${stats.points}점',
          passed: false,
          warning: '득점 계산이 맞지 않습니다 (2P*2 + 3P*3 + FT*1).',
        ));
      }
    }

    // 3. 리바운드 검증 (OREB + DREB = TRB)
    for (final stats in [..._homeStats, ..._awayStats]) {
      final calculatedReb = stats.offensiveRebounds + stats.defensiveRebounds;
      if (calculatedReb != stats.totalRebounds && stats.totalRebounds > 0) {
        validations.add(ValidationResult(
          title: '선수 #${stats.tournamentTeamPlayerId} 리바운드 검증',
          description:
              'OREB(${stats.offensiveRebounds}) + DREB(${stats.defensiveRebounds}) = ${stats.totalRebounds}',
          passed: false,
          warning: '리바운드 합계가 맞지 않습니다.',
        ));
      }
    }

    // 4. FGA >= FGM 검증
    for (final stats in [..._homeStats, ..._awayStats]) {
      if (stats.fieldGoalsAttempted < stats.fieldGoalsMade) {
        validations.add(ValidationResult(
          title: '선수 #${stats.tournamentTeamPlayerId} 필드골 검증',
          description:
              'FGA(${stats.fieldGoalsAttempted}) < FGM(${stats.fieldGoalsMade})',
          passed: false,
          warning: 'FGA가 FGM보다 작을 수 없습니다.',
        ));
      }
    }

    // 5. 쿼터 점수 합계 검증
    if (_quarterScores.isNotEmpty) {
      int homeQuarterTotal = 0;
      int awayQuarterTotal = 0;
      for (final qs in _quarterScores.values) {
        homeQuarterTotal += qs['home'] ?? 0;
        awayQuarterTotal += qs['away'] ?? 0;
      }

      validations.add(ValidationResult(
        title: '홈팀 쿼터 점수 합계',
        description: '쿼터합: $homeQuarterTotal점 / 최종: ${widget.homeScore}점',
        passed: homeQuarterTotal == widget.homeScore,
        warning: homeQuarterTotal != widget.homeScore
            ? '쿼터별 점수 합계가 최종 점수와 다릅니다.'
            : null,
      ));

      validations.add(ValidationResult(
        title: '원정팀 쿼터 점수 합계',
        description: '쿼터합: $awayQuarterTotal점 / 최종: ${widget.awayScore}점',
        passed: awayQuarterTotal == widget.awayScore,
        warning: awayQuarterTotal != widget.awayScore
            ? '쿼터별 점수 합계가 최종 점수와 다릅니다.'
            : null,
      ));
    }

    // 검증 결과가 없으면 "모두 통과" 추가
    if (validations.isEmpty) {
      validations.add(const ValidationResult(
        title: '데이터 검증 완료',
        description: '모든 검증 항목이 통과되었습니다.',
        passed: true,
      ));
    }

    return validations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('최종 검토'),
        actions: [
          TextButton(
            onPressed: _goToMvpSelect,
            child: const Text('다음'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 최종 스코어
                  _buildFinalScore(),
                  const SizedBox(height: 16),

                  // 쿼터별 점수
                  _buildQuarterScores(),
                  const SizedBox(height: 16),

                  // 검증 결과
                  _buildValidationResults(),
                  const SizedBox(height: 16),

                  // 버튼들
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildFinalScore() {
    final winner = widget.homeScore > widget.awayScore
        ? 'home'
        : (widget.awayScore > widget.homeScore ? 'away' : 'tie');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          const Text(
            '최종 스코어',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 홈팀
              Expanded(
                child: Column(
                  children: [
                    Text(
                      widget.homeTeamName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: winner == 'home'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: winner == 'home'
                            ? AppTheme.primaryColor
                            : AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.homeScore}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: winner == 'home'
                            ? AppTheme.primaryColor
                            : AppTheme.textPrimary,
                      ),
                    ),
                    if (winner == 'home')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'WIN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // VS
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: winner == 'away'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: winner == 'away'
                            ? AppTheme.secondaryColor
                            : AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.awayScore}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: winner == 'away'
                            ? AppTheme.secondaryColor
                            : AppTheme.textPrimary,
                      ),
                    ),
                    if (winner == 'away')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'WIN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuarterScores() {
    if (_quarterScores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '쿼터별 점수',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: AppTheme.dividerColor, width: 0.5),
            children: [
              // 헤더
              TableRow(
                decoration: const BoxDecoration(color: AppTheme.backgroundColor),
                children: [
                  const TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        '팀',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  ..._quarterScores.keys.map((q) => TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            q <= 4 ? 'Q$q' : 'OT${q - 4}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )),
                  const TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        '합계',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              // 홈팀
              TableRow(
                children: [
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        widget.homeTeamName,
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  ..._quarterScores.values.map((qs) => TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '${qs['home'] ?? 0}',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )),
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '${widget.homeScore}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              // 원정팀
              TableRow(
                children: [
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        widget.awayTeamName,
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  ..._quarterScores.values.map((qs) => TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '${qs['away'] ?? 0}',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )),
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '${widget.awayScore}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValidationResults() {
    final hasErrors = _validations.any((v) => !v.passed);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasErrors ? AppTheme.warningColor : AppTheme.successColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasErrors ? Icons.warning_amber : Icons.check_circle,
                color: hasErrors ? AppTheme.warningColor : AppTheme.successColor,
              ),
              const SizedBox(width: 8),
              Text(
                hasErrors ? '데이터 검증 경고' : '데이터 검증 완료',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: hasErrors ? AppTheme.warningColor : AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._validations.map((v) => _buildValidationItem(v)),
        ],
      ),
    );
  }

  Widget _buildValidationItem(ValidationResult validation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            validation.passed ? Icons.check : Icons.warning,
            size: 16,
            color:
                validation.passed ? AppTheme.successColor : AppTheme.warningColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  validation.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  validation.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (validation.warning != null)
                  Text(
                    validation.warning!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.warningColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _goToBoxScore,
                icon: const Icon(Icons.table_chart),
                label: const Text('박스스코어 수정'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.dividerColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _goToShotChart,
                icon: const Icon(Icons.scatter_plot),
                label: const Text('슛차트 확인'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.dividerColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _goToMvpSelect,
            icon: const Icon(Icons.flag),
            label: const Text('MVP 선정으로 이동'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _goToBoxScore() {
    context.push(
      '/box-score/${widget.matchId}',
      extra: {
        'homeTeamName': widget.homeTeamName,
        'awayTeamName': widget.awayTeamName,
        'homeTeamId': widget.homeTeamId,
        'awayTeamId': widget.awayTeamId,
        'homeScore': widget.homeScore,
        'awayScore': widget.awayScore,
        'isLive': false,
      },
    );
  }

  void _goToShotChart() {
    context.push(
      '/shot-chart/${widget.matchId}',
      extra: {
        'homeTeamId': widget.homeTeamId,
        'awayTeamId': widget.awayTeamId,
        'homeTeamName': widget.homeTeamName,
        'awayTeamName': widget.awayTeamName,
      },
    );
  }

  void _goToMvpSelect() {
    context.push(
      '/mvp-select/${widget.matchId}',
      extra: {
        'homeTeamId': widget.homeTeamId,
        'awayTeamId': widget.awayTeamId,
        'homeTeamName': widget.homeTeamName,
        'awayTeamName': widget.awayTeamName,
        'homeScore': widget.homeScore,
        'awayScore': widget.awayScore,
      },
    );
  }
}
