import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';
import '../../screens/recording/models/player_with_stats.dart';

/// 스마트 어시스트 추천 로직
class AssistRecommender {
  /// 추천 점수 계산 (높을수록 어시스트 가능성 높음)
  static double calculateScore(PlayerWithStats player, LocalTournamentPlayer scorer) {
    double score = 0.0;

    // 1. 코트 위에 있는 선수 우선 (+50)
    if (player.isOnCourt) {
      score += 50.0;
    }

    // 2. 이번 경기 어시스트 수에 따른 점수 (어시스트당 +10, 최대 +30)
    score += (player.stats.assists.clamp(0, 3)) * 10.0;

    // 3. 포지션 기반 점수 (가드: +15, 포워드: +5)
    final position = player.player.position?.toUpperCase() ?? '';
    if (position.contains('PG') || position.contains('포인트가드')) {
      score += 15.0;
    } else if (position.contains('SG') || position.contains('슈팅가드')) {
      score += 12.0;
    } else if (position.contains('SF') || position.contains('포워드')) {
      score += 5.0;
    }

    // 4. 플레이타임 기반 (출전 시간이 긴 선수가 더 영향력 있음)
    final minutes = player.stats.minutesPlayed;
    score += (minutes.clamp(0, 10)) * 1.0;

    return score;
  }

  /// 추천 선수 목록 정렬 (점수 높은 순)
  static List<PlayerWithStats> sortByRecommendation(
    List<PlayerWithStats> players,
    LocalTournamentPlayer scorer,
  ) {
    // 득점자 제외
    final filtered = players.where((p) => p.player.id != scorer.id).toList();

    // 추천 점수로 정렬
    filtered.sort((a, b) {
      final scoreA = calculateScore(a, scorer);
      final scoreB = calculateScore(b, scorer);
      return scoreB.compareTo(scoreA);
    });

    return filtered;
  }

  /// 추천 여부 판단 (상위 3명)
  static bool isRecommended(PlayerWithStats player, LocalTournamentPlayer scorer, List<PlayerWithStats> allPlayers) {
    final sorted = sortByRecommendation(allPlayers, scorer);
    if (sorted.length <= 3) return sorted.contains(player);

    final topThree = sorted.take(3).toList();
    return topThree.any((p) => p.player.id == player.player.id);
  }
}

/// 스마트 어시스트 선택 다이얼로그
class AssistSelectDialog extends StatelessWidget {
  const AssistSelectDialog({
    super.key,
    required this.scorer,
    required this.teammates,
    this.teammatesWithStats,
    this.onSelect,
  });

  final LocalTournamentPlayer scorer;
  final List<LocalTournamentPlayer> teammates;
  final List<PlayerWithStats>? teammatesWithStats; // 스마트 추천용
  final void Function(LocalTournamentPlayer? assister)? onSelect;

  @override
  Widget build(BuildContext context) {
    // 스마트 추천 사용 여부
    final useSmartRecommendation = teammatesWithStats != null;

    // 슈터 제외한 팀원 목록
    List<dynamic> sortedTeammates;

    if (useSmartRecommendation) {
      sortedTeammates =
          AssistRecommender.sortByRecommendation(teammatesWithStats!, scorer);
    } else {
      sortedTeammates =
          teammates.where((p) => p.id != scorer.id).toList();
    }

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Row(
              children: [
                const Icon(Icons.compare_arrows, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '어시스트',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${scorer.userName}의 슛을 도운 선수',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // "어시스트 없음" 옵션
            _PlayerTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.close,
                  color: Theme.of(context).hintColor,
                ),
              ),
              title: '어시스트 없음',
              subtitle: '개인 기술로 득점',
              isRecommended: false,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect?.call(null);
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 8),
            const Divider(),

            // 스마트 추천 안내
            if (useSmartRecommendation) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: AppTheme.warningColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '추천순으로 정렬됨',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),

            // 팀원 목록
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Column(
                  children: sortedTeammates.map((item) {
                    final LocalTournamentPlayer player;
                    final bool isRecommended;
                    final String? statInfo;
                    final bool isOnCourt;

                    if (item is PlayerWithStats) {
                      player = item.player;
                      isRecommended = AssistRecommender.isRecommended(
                        item,
                        scorer,
                        teammatesWithStats!,
                      );
                      statInfo = '${item.stats.assists}A';
                      isOnCourt = item.isOnCourt;
                    } else {
                      player = item as LocalTournamentPlayer;
                      isRecommended = false;
                      statInfo = null;
                      isOnCourt = true;
                    }

                    return _PlayerTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isOnCourt
                              ? AppTheme.primaryColor.withValues(alpha: 0.15)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: isRecommended
                              ? Border.all(
                                  color: AppTheme.warningColor,
                                  width: 2,
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '#${player.jerseyNumber ?? '-'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isOnCourt
                                ? AppTheme.primaryColor
                                : Theme.of(context).hintColor,
                          ),
                        ),
                      ),
                      title: player.userName,
                      subtitle: _buildSubtitle(player, statInfo, isOnCourt),
                      isRecommended: isRecommended,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelect?.call(player);
                        Navigator.pop(context, player);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle(LocalTournamentPlayer player, String? statInfo, bool isOnCourt) {
    final parts = <String>[];

    if (player.position != null && player.position!.isNotEmpty) {
      parts.add(player.position!);
    }

    if (statInfo != null) {
      parts.add(statInfo);
    }

    if (!isOnCourt) {
      parts.add('벤치');
    }

    return parts.isEmpty ? '포지션 미정' : parts.join(' · ');
  }
}

/// 선수 타일 위젯 (추천 배지 포함)
class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isRecommended = false,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 10,
                                  color: AppTheme.warningColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '추천',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.warningColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Theme.of(context).hintColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// 어시스트 선택 다이얼로그 표시 헬퍼 함수
Future<LocalTournamentPlayer?> showAssistSelectDialog({
  required BuildContext context,
  required LocalTournamentPlayer scorer,
  required List<LocalTournamentPlayer> teammates,
}) {
  return showDialog<LocalTournamentPlayer?>(
    context: context,
    builder: (context) => AssistSelectDialog(
      scorer: scorer,
      teammates: teammates,
    ),
  );
}

/// 스마트 어시스트 선택 다이얼로그 표시 헬퍼 함수 (추천 기능 포함)
Future<LocalTournamentPlayer?> showSmartAssistSelectDialog({
  required BuildContext context,
  required LocalTournamentPlayer scorer,
  required List<PlayerWithStats> teammates,
}) {
  return showDialog<LocalTournamentPlayer?>(
    context: context,
    builder: (context) => AssistSelectDialog(
      scorer: scorer,
      teammates: teammates.map((p) => p.player).toList(),
      teammatesWithStats: teammates,
    ),
  );
}
