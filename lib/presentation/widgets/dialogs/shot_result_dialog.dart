import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';

/// 슛 결과 선택 다이얼로그
class ShotResultDialog extends ConsumerWidget {
  const ShotResultDialog({
    super.key,
    required this.player,
    required this.shotType,
    this.zoneName,
    this.onResult,
  });

  final LocalTournamentPlayer player;
  final ShotType shotType;
  final String? zoneName;
  final void Function(bool isMade)? onResult;

  String get _shotTypeLabel {
    switch (shotType) {
      case ShotType.twoPoint:
        return '2점슛';
      case ShotType.threePoint:
        return '3점슛';
      case ShotType.freeThrow:
        return '자유투';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#${player.jerseyNumber ?? '-'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _shotTypeLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 존 정보
            if (zoneName != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  zoneName!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // 결과 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 성공 버튼
                Expanded(
                  child: _ResultButton(
                    icon: Icons.check_circle,
                    label: '성공',
                    color: AppTheme.shotMadeColor,
                    onTap: () {
                      onResult?.call(true);
                      context.pop(true);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // 실패 버튼
                Expanded(
                  child: _ResultButton(
                    icon: Icons.cancel,
                    label: '실패',
                    color: AppTheme.shotMissedColor,
                    onTap: () {
                      onResult?.call(false);
                      context.pop(false);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 취소 버튼
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('취소'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 결과 버튼 위젯
class _ResultButton extends ConsumerWidget {
  const _ResultButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 슛 타입 enum
enum ShotType {
  twoPoint,
  threePoint,
  freeThrow,
}

/// 슛 결과 다이얼로그 표시 헬퍼 함수
Future<bool?> showShotResultDialog({
  required BuildContext context,
  required LocalTournamentPlayer player,
  required ShotType shotType,
  String? zoneName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ShotResultDialog(
      player: player,
      shotType: shotType,
      zoneName: zoneName,
    ),
  );
}
