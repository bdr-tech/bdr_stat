import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 타임아웃 종류
enum TimeoutType {
  home, // 홈팀 타임아웃
  away, // 원정팀 타임아웃
  official, // 공식 타임아웃 (TV, 부상 등)
}

/// 타임아웃 결과
class TimeoutResult {
  final TimeoutType type;
  final String? reason; // 공식 타임아웃인 경우 사유

  const TimeoutResult({
    required this.type,
    this.reason,
  });

  bool get isTeamTimeout =>
      type == TimeoutType.home || type == TimeoutType.away;
  bool get isHomeTeam => type == TimeoutType.home;
  bool get isAwayTeam => type == TimeoutType.away;
  bool get isOfficial => type == TimeoutType.official;
}

/// 타임아웃 다이얼로그
class TimeoutDialog extends StatefulWidget {
  const TimeoutDialog({
    super.key,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeTimeoutsRemaining,
    required this.awayTimeoutsRemaining,
    this.onSelect,
  });

  final String homeTeamName;
  final String awayTeamName;
  final int homeTimeoutsRemaining;
  final int awayTimeoutsRemaining;
  final void Function(TimeoutResult result)? onSelect;

  @override
  State<TimeoutDialog> createState() => _TimeoutDialogState();
}

class _TimeoutDialogState extends State<TimeoutDialog> {
  TimeoutType? _selectedType;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _selectType(TimeoutType type) {
    // 타임아웃 남은 횟수 체크
    if (type == TimeoutType.home && widget.homeTimeoutsRemaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('홈팀 타임아웃이 남아있지 않습니다')),
      );
      return;
    }
    if (type == TimeoutType.away && widget.awayTimeoutsRemaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('원정팀 타임아웃이 남아있지 않습니다')),
      );
      return;
    }

    setState(() {
      _selectedType = type;
    });

    // 공식 타임아웃이 아니면 바로 확인
    if (type != TimeoutType.official) {
      _confirm();
    }
  }

  void _confirm() {
    if (_selectedType == null) return;

    final result = TimeoutResult(
      type: _selectedType!,
      reason:
          _selectedType == TimeoutType.official && _reasonController.text.isNotEmpty
              ? _reasonController.text
              : null,
    );

    widget.onSelect?.call(result);
    Navigator.pop(context, result);
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
            Row(
              children: [
                const Icon(Icons.timer_off, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '타임아웃',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 타임아웃 종류 선택 (공식 타임아웃 사유 입력 화면이 아닐 때)
            if (_selectedType != TimeoutType.official) ...[
              // 홈팀 타임아웃
              _TimeoutButton(
                teamName: widget.homeTeamName,
                remaining: widget.homeTimeoutsRemaining,
                color: AppTheme.homeTeamColor,
                isHome: true,
                isDisabled: widget.homeTimeoutsRemaining <= 0,
                onTap: () => _selectType(TimeoutType.home),
              ),

              const SizedBox(height: 12),

              // 원정팀 타임아웃
              _TimeoutButton(
                teamName: widget.awayTeamName,
                remaining: widget.awayTimeoutsRemaining,
                color: AppTheme.awayTeamColor,
                isHome: false,
                isDisabled: widget.awayTimeoutsRemaining <= 0,
                onTap: () => _selectType(TimeoutType.away),
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // 공식 타임아웃
              _OfficialTimeoutButton(
                onTap: () => _selectType(TimeoutType.official),
              ),
            ],

            // 공식 타임아웃 사유 입력
            if (_selectedType == TimeoutType.official) ...[
              const Text(
                '공식 타임아웃',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  hintText: '사유 입력 (선택사항)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _QuickReasonChip(
                    label: 'TV 타임아웃',
                    onTap: () => _reasonController.text = 'TV 타임아웃',
                  ),
                  _QuickReasonChip(
                    label: '부상',
                    onTap: () => _reasonController.text = '부상',
                  ),
                  _QuickReasonChip(
                    label: '장비 점검',
                    onTap: () => _reasonController.text = '장비 점검',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedType = null;
                        });
                      },
                      child: const Text('뒤로'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: const Text('확인'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 팀 타임아웃 버튼
class _TimeoutButton extends StatelessWidget {
  const _TimeoutButton({
    required this.teamName,
    required this.remaining,
    required this.color,
    required this.isHome,
    required this.isDisabled,
    required this.onTap,
  });

  final String teamName;
  final int remaining;
  final Color color;
  final bool isHome;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDisabled
          ? AppTheme.backgroundColor
          : color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDisabled ? AppTheme.textHint : color,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  isHome ? 'H' : 'A',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teamName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDisabled
                            ? AppTheme.textHint
                            : AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '남은 타임아웃: $remaining',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDisabled
                            ? AppTheme.textHint
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDisabled)
                const Text(
                  '없음',
                  style: TextStyle(
                    color: AppTheme.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: color,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 공식 타임아웃 버튼
class _OfficialTimeoutButton extends StatelessWidget {
  const _OfficialTimeoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.backgroundColor,
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
                  color: AppTheme.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.gavel,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '공식 타임아웃',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'TV, 부상, 장비 점검 등',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// 빠른 사유 선택 칩
class _QuickReasonChip extends StatelessWidget {
  const _QuickReasonChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppTheme.backgroundColor,
    );
  }
}

/// 타임아웃 다이얼로그 표시 헬퍼 함수
Future<TimeoutResult?> showTimeoutDialog({
  required BuildContext context,
  required String homeTeamName,
  required String awayTeamName,
  required int homeTimeoutsRemaining,
  required int awayTimeoutsRemaining,
}) {
  return showDialog<TimeoutResult?>(
    context: context,
    builder: (context) => TimeoutDialog(
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      homeTimeoutsRemaining: homeTimeoutsRemaining,
      awayTimeoutsRemaining: awayTimeoutsRemaining,
    ),
  );
}
