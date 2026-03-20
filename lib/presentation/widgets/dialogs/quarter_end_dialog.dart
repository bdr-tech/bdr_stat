import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 쿼터 종료 액션
enum QuarterEndAction {
  nextQuarter, // 다음 쿼터 시작
  viewBoxScore, // 박스스코어 확인
  endGame, // 경기 종료 (4쿼터 종료 시)
  overtime, // 연장전 (동점일 때)
}

/// 쿼터 종료 결과
class QuarterEndResult {
  final QuarterEndAction action;

  const QuarterEndResult({required this.action});
}

/// 쿼터 종료 다이얼로그
class QuarterEndDialog extends StatelessWidget {
  const QuarterEndDialog({
    super.key,
    required this.currentQuarter,
    required this.maxQuarters,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeScore,
    required this.awayScore,
    required this.quarterScores, // {'Q1': {'home': 20, 'away': 18}, ...}
    this.isOvertime = false,
    this.overtimeNumber = 0,
    this.onAction,
  });

  final int currentQuarter;
  final int maxQuarters;
  final String homeTeamName;
  final String awayTeamName;
  final int homeScore;
  final int awayScore;
  final Map<String, Map<String, int>> quarterScores;
  final bool isOvertime;
  final int overtimeNumber;
  final void Function(QuarterEndResult result)? onAction;

  bool get _isFinalQuarter => currentQuarter >= maxQuarters && !isOvertime;
  bool get _isTied => homeScore == awayScore;
  String get _quarterLabel {
    if (isOvertime) {
      return 'OT${overtimeNumber > 1 ? overtimeNumber : ''}';
    }
    return '$currentQuarter쿼터';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_quarterLabel 종료',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 현재 스코어
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TeamScore(
                  teamName: homeTeamName,
                  score: homeScore,
                  isWinning: homeScore > awayScore,
                  isHome: true,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text(
                    ':',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _TeamScore(
                  teamName: awayTeamName,
                  score: awayScore,
                  isWinning: awayScore > homeScore,
                  isHome: false,
                ),
              ],
            ),

            // 동점 표시
            if (_isTied) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '동점',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warningColor,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // 쿼터별 점수 표
            if (quarterScores.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // 헤더
                    Row(
                      children: [
                        const SizedBox(width: 60),
                        ...List.generate(currentQuarter, (index) {
                          final qNum = index + 1;
                          final isOT = qNum > maxQuarters;
                          return Expanded(
                            child: Text(
                              isOT ? 'OT${qNum - maxQuarters}' : 'Q$qNum',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          );
                        }),
                        const Expanded(
                          child: Text(
                            '합계',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 홈팀
                    _QuarterScoreRow(
                      teamName: homeTeamName,
                      scores: _getTeamQuarterScores(true),
                      total: homeScore,
                      currentQuarter: currentQuarter,
                      maxQuarters: maxQuarters,
                    ),
                    const SizedBox(height: 4),
                    // 원정팀
                    _QuarterScoreRow(
                      teamName: awayTeamName,
                      scores: _getTeamQuarterScores(false),
                      total: awayScore,
                      currentQuarter: currentQuarter,
                      maxQuarters: maxQuarters,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Divider(),
            const SizedBox(height: 16),

            // 액션 버튼들
            if (_isFinalQuarter && _isTied) ...[
              // 동점이면 연장전 또는 무승부 종료
              _ActionButton(
                icon: Icons.play_arrow,
                label: '연장전 시작',
                description: '5분 연장전',
                color: AppTheme.primaryColor,
                onTap: () => _selectAction(context, QuarterEndAction.overtime),
              ),
              const SizedBox(height: 8),
              _ActionButton(
                icon: Icons.sports_score,
                label: '무승부로 종료',
                description: '경기 종료',
                color: AppTheme.warningColor,
                onTap: () => _selectAction(context, QuarterEndAction.endGame),
              ),
            ] else if (_isFinalQuarter || isOvertime) ...[
              // 마지막 쿼터 (승부 결정)
              _ActionButton(
                icon: Icons.sports_score,
                label: '경기 종료',
                description: '최종 결과 확정',
                color: AppTheme.successColor,
                onTap: () => _selectAction(context, QuarterEndAction.endGame),
              ),
            ] else ...[
              // 일반 쿼터 종료
              _ActionButton(
                icon: Icons.play_arrow,
                label: '${currentQuarter + 1}쿼터 시작',
                description: '팀 파울 리셋, 10:00 시작',
                color: AppTheme.primaryColor,
                onTap: () => _selectAction(context, QuarterEndAction.nextQuarter),
              ),
            ],

            const SizedBox(height: 8),

            // 박스스코어 확인
            _ActionButton(
              icon: Icons.table_chart,
              label: '박스스코어 확인',
              description: '선수별 스탯 확인',
              color: AppTheme.secondaryColor,
              onTap: () => _selectAction(context, QuarterEndAction.viewBoxScore),
            ),
          ],
        ),
      ),
    );
  }

  List<int> _getTeamQuarterScores(bool isHome) {
    final scores = <int>[];
    for (int i = 1; i <= currentQuarter; i++) {
      final key = i > maxQuarters ? 'OT${i - maxQuarters}' : 'Q$i';
      final quarterData = quarterScores[key];
      if (quarterData != null) {
        scores.add(isHome ? (quarterData['home'] ?? 0) : (quarterData['away'] ?? 0));
      } else {
        scores.add(0);
      }
    }
    return scores;
  }

  void _selectAction(BuildContext context, QuarterEndAction action) {
    final result = QuarterEndResult(action: action);
    onAction?.call(result);
    Navigator.pop(context, result);
  }
}

/// 팀 스코어 위젯
class _TeamScore extends StatelessWidget {
  const _TeamScore({
    required this.teamName,
    required this.score,
    required this.isWinning,
    required this.isHome,
  });

  final String teamName;
  final int score;
  final bool isWinning;
  final bool isHome;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          teamName,
          style: TextStyle(
            fontSize: 14,
            color: isHome ? AppTheme.homeTeamColor : AppTheme.awayTeamColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: isWinning ? AppTheme.successColor : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// 쿼터별 점수 행
class _QuarterScoreRow extends StatelessWidget {
  const _QuarterScoreRow({
    required this.teamName,
    required this.scores,
    required this.total,
    required this.currentQuarter,
    required this.maxQuarters,
  });

  final String teamName;
  final List<int> scores;
  final int total;
  final int currentQuarter;
  final int maxQuarters;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            teamName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ...List.generate(currentQuarter, (index) {
          return Expanded(
            child: Text(
              index < scores.length ? '${scores[index]}' : '-',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          );
        }),
        Expanded(
          child: Text(
            '$total',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// 액션 버튼 위젯
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

/// 쿼터 종료 다이얼로그 표시 헬퍼 함수
Future<QuarterEndResult?> showQuarterEndDialog({
  required BuildContext context,
  required int currentQuarter,
  required int maxQuarters,
  required String homeTeamName,
  required String awayTeamName,
  required int homeScore,
  required int awayScore,
  required Map<String, Map<String, int>> quarterScores,
  bool isOvertime = false,
  int overtimeNumber = 0,
}) {
  return showDialog<QuarterEndResult?>(
    context: context,
    barrierDismissible: false,
    builder: (context) => QuarterEndDialog(
      currentQuarter: currentQuarter,
      maxQuarters: maxQuarters,
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      homeScore: homeScore,
      awayScore: awayScore,
      quarterScores: quarterScores,
      isOvertime: isOvertime,
      overtimeNumber: overtimeNumber,
    ),
  );
}
