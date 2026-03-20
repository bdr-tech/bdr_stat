import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/undo_stack_provider.dart';

/// Undo 스낵바 위젯 (액션 기록 후 표시)
class UndoSnackbar {
  UndoSnackbar._();

  /// Undo 스낵바 표시 (FR-013: 2초 자동 소멸 강제)
  static void show({
    required BuildContext context,
    required UndoableAction action,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _UndoSnackbarContent(action: action),
        action: SnackBarAction(
          label: '실행 취소',
          textColor: AppTheme.primaryColor,
          onPressed: onUndo,
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// 스코어 변경이 포함된 Undo 스낵바 표시 (FR-013: 2초 자동 소멸 강제)
  static void showWithScore({
    required BuildContext context,
    required UndoableAction action,
    required int homeScore,
    required int awayScore,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _UndoSnackbarContentWithScore(
          action: action,
          homeScore: homeScore,
          awayScore: awayScore,
        ),
        action: SnackBarAction(
          label: '실행 취소',
          textColor: AppTheme.primaryColor,
          onPressed: onUndo,
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// 에러 스낵바 표시 (FR-013: clearSnackBars 사용)
  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ],
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// 성공 스낵바 표시 (FR-013: clearSnackBars 사용)
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppTheme.successColor, size: 20),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ],
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

/// 스낵바 내용 위젯
class _UndoSnackbarContent extends StatelessWidget {
  const _UndoSnackbarContent({required this.action});

  final UndoableAction action;

  IconData get _icon {
    switch (action.type) {
      case UndoableActionType.shot:
        return Icons.sports_basketball;
      case UndoableActionType.freeThrow:
        return Icons.sports_handball;
      case UndoableActionType.assist:
        return Icons.compare_arrows;
      case UndoableActionType.rebound:
        return Icons.replay;
      case UndoableActionType.steal:
        return Icons.flash_on;
      case UndoableActionType.block:
        return Icons.block;
      case UndoableActionType.turnover:
        return Icons.error_outline;
      case UndoableActionType.foul:
        return Icons.front_hand;
      case UndoableActionType.timeout:
        return Icons.timer_off;
      case UndoableActionType.substitution:
        return Icons.swap_horiz;
    }
  }

  Color get _iconColor {
    switch (action.type) {
      case UndoableActionType.shot:
        final isMade = action.data['isMade'] as bool? ?? false;
        return isMade ? AppTheme.shotMadeColor : AppTheme.shotMissedColor;
      case UndoableActionType.freeThrow:
        final isMade = action.data['isMade'] as bool? ?? false;
        return isMade ? AppTheme.shotMadeColor : AppTheme.shotMissedColor;
      case UndoableActionType.assist:
        return AppTheme.primaryColor;
      case UndoableActionType.rebound:
        return AppTheme.primaryColor;
      case UndoableActionType.steal:
        return AppTheme.successColor;
      case UndoableActionType.block:
        return AppTheme.successColor;
      case UndoableActionType.turnover:
        return AppTheme.warningColor;
      case UndoableActionType.foul:
        return AppTheme.errorColor;
      case UndoableActionType.timeout:
        return AppTheme.warningColor;
      case UndoableActionType.substitution:
        return AppTheme.secondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _iconColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(_icon, color: _iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                action.playerName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                action.typeLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 스코어 포함 스낵바 내용 위젯
class _UndoSnackbarContentWithScore extends StatelessWidget {
  const _UndoSnackbarContentWithScore({
    required this.action,
    required this.homeScore,
    required this.awayScore,
  });

  final UndoableAction action;
  final int homeScore;
  final int awayScore;

  @override
  Widget build(BuildContext context) {
    final pointsChange = action.pointsChange;
    final showScore = pointsChange > 0;

    return Row(
      children: [
        // 액션 아이콘
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.check,
            color: AppTheme.successColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        // 액션 설명
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                action.description,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (showScore)
                Text(
                  '+$pointsChange점',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.successColor,
                  ),
                ),
            ],
          ),
        ),
        // 현재 스코어
        if (showScore)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$homeScore : $awayScore',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Undo 확인 다이얼로그 위젯
class UndoConfirmDialog extends StatelessWidget {
  const UndoConfirmDialog({
    super.key,
    required this.action,
    required this.linkedActions,
  });

  final UndoableAction action;
  final List<UndoableAction> linkedActions;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.undo, color: AppTheme.warningColor),
          SizedBox(width: 8),
          Text('실행 취소'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '다음 기록을 취소하시겠습니까?',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          _ActionTile(action: action, isMain: true),
          if (linkedActions.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '연관된 기록도 함께 취소됩니다:',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...linkedActions.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _ActionTile(action: a, isMain: false),
                )),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.warningColor,
          ),
          child: const Text('실행 취소'),
        ),
      ],
    );
  }
}

/// 액션 타일 위젯
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.action,
    required this.isMain,
  });

  final UndoableAction action;
  final bool isMain;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMain
            ? AppTheme.warningColor.withValues(alpha: 0.1)
            : AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: isMain
            ? Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          Text(
            action.playerName,
            style: TextStyle(
              fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              action.typeLabel,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

/// Undo 확인 다이얼로그 표시 헬퍼 함수
Future<bool?> showUndoConfirmDialog({
  required BuildContext context,
  required UndoableAction action,
  List<UndoableAction> linkedActions = const [],
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => UndoConfirmDialog(
      action: action,
      linkedActions: linkedActions,
    ),
  );
}
