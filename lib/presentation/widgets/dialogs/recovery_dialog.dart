import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/app_recovery_service.dart';
import '../../../core/theme/app_theme.dart';

/// 복구 결과
enum RecoveryAction {
  continueMatch,  // 이어서 기록
  startFresh,     // 새로 시작
  cancel,         // 취소
}

/// 경기 복구 다이얼로그
/// 앱 재시작 시 진행 중인 경기가 있으면 표시
class RecoveryDialog extends ConsumerWidget {
  const RecoveryDialog({
    super.key,
    required this.match,
  });

  final RecoverableMatch match;

  static Future<RecoveryAction?> show(
    BuildContext context,
    RecoverableMatch match,
  ) {
    return showDialog<RecoveryAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RecoveryDialog(match: match),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restore,
              color: AppTheme.warningColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text('진행 중인 경기 발견'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 경기 정보 카드
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              children: [
                // 팀 이름과 점수
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        match.homeTeamName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        match.scoreDisplay,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        match.awayTeamName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 쿼터 정보
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        match.quarterDisplay,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (match.lastUpdated != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatLastUpdated(match.lastUpdated!),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 안내 메시지
          const Text(
            '이어서 기록하시겠습니까?\n새로 시작하면 기존 기록이 취소됩니다.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        // 새로 시작
        TextButton(
          onPressed: () => _handleStartFresh(context, ref),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.errorColor,
          ),
          child: const Text('새로 시작'),
        ),
        // 이어서 기록
        ElevatedButton.icon(
          onPressed: () => _handleContinue(context, ref),
          icon: const Icon(Icons.play_arrow),
          label: const Text('이어서 기록'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return '방금 전';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else {
      return DateFormat('MM/dd HH:mm').format(dateTime);
    }
  }

  Future<void> _handleContinue(BuildContext context, WidgetRef ref) async {
    final service = ref.read(appRecoveryServiceProvider);
    await service.onRecoveryAccepted(match.matchId);

    if (context.mounted) {
      Navigator.of(context).pop(RecoveryAction.continueMatch);

      // 경기 기록 화면으로 이동
      context.go('/recording/${match.matchId}');
    }
  }

  Future<void> _handleStartFresh(BuildContext context, WidgetRef ref) async {
    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기존 경기 취소'),
        content: const Text(
          '기존 경기 기록이 취소됩니다.\n정말 새로 시작하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('돌아가기'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final service = ref.read(appRecoveryServiceProvider);
      await service.onRecoveryDeclined(match.matchId);

      if (context.mounted) {
        Navigator.of(context).pop(RecoveryAction.startFresh);
      }
    }
  }
}

/// 진행 중인 경기 목록 다이얼로그
class InProgressMatchesDialog extends ConsumerWidget {
  const InProgressMatchesDialog({
    super.key,
    required this.matches,
  });

  final List<RecoverableMatch> matches;

  static Future<RecoverableMatch?> show(
    BuildContext context,
    List<RecoverableMatch> matches,
  ) {
    return showDialog<RecoverableMatch>(
      context: context,
      builder: (context) => InProgressMatchesDialog(matches: matches),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      title: const Row(
        children: [
          Icon(Icons.sports_basketball, color: AppTheme.primaryColor),
          SizedBox(width: 8),
          Text('진행 중인 경기'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: matches.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final match = matches[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${match.homeTeamName} vs ${match.awayTeamName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${match.scoreDisplay} • ${match.quarterDisplay}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, match),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
