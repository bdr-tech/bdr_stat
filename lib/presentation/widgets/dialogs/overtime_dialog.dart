import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 연장전 설정 결과
class OvertimeSettings {
  final int minutes; // 연장전 시간 (분)
  final int additionalTimeouts; // 추가 타임아웃
  final bool resetTeamFouls; // 팀 파울 리셋 여부

  const OvertimeSettings({
    required this.minutes,
    required this.additionalTimeouts,
    required this.resetTeamFouls,
  });

  /// 기본 연장전 설정 (5분, 추가 타임아웃 없음, 팀 파울 유지)
  factory OvertimeSettings.defaultSettings() {
    return const OvertimeSettings(
      minutes: 5,
      additionalTimeouts: 0,
      resetTeamFouls: false,
    );
  }
}

/// 연장전 다이얼로그
class OvertimeDialog extends StatefulWidget {
  const OvertimeDialog({
    super.key,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.score,
    required this.overtimeNumber,
    this.defaultMinutes = 5,
    this.onConfirm,
  });

  final String homeTeamName;
  final String awayTeamName;
  final int score; // 동점 점수
  final int overtimeNumber; // 몇 번째 연장전인지 (1, 2, 3...)
  final int defaultMinutes;
  final void Function(OvertimeSettings settings)? onConfirm;

  @override
  State<OvertimeDialog> createState() => _OvertimeDialogState();
}

class _OvertimeDialogState extends State<OvertimeDialog> {
  late int _minutes;
  int _additionalTimeouts = 0;
  bool _resetTeamFouls = false;

  @override
  void initState() {
    super.initState();
    _minutes = widget.defaultMinutes;
  }

  void _confirm() {
    final settings = OvertimeSettings(
      minutes: _minutes,
      additionalTimeouts: _additionalTimeouts,
      resetTeamFouls: _resetTeamFouls,
    );
    widget.onConfirm?.call(settings);
    Navigator.pop(context, settings);
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
                color: AppTheme.warningColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.overtimeNumber == 1
                        ? '연장전'
                        : '${widget.overtimeNumber}차 연장전',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 동점 스코어 표시
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.homeTeamName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.homeTeamColor,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.score} : ${widget.score}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  widget.awayTeamName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.awayTeamColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // 연장전 시간 설정
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '연장전 시간',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [3, 5, 10].map((minutes) {
                final isSelected = _minutes == minutes;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => setState(() => _minutes = minutes),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 64,
                        height: 48,
                        alignment: Alignment.center,
                        child: Text(
                          '$minutes분',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // 추가 타임아웃
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '추가 타임아웃',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [0, 1, 2].map((count) {
                final isSelected = _additionalTimeouts == count;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => setState(() => _additionalTimeouts = count),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 64,
                        height: 48,
                        alignment: Alignment.center,
                        child: Text(
                          count == 0 ? '없음' : '+$count',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // 팀 파울 리셋 옵션
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '팀 파울 리셋',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _resetTeamFouls ? '팀 파울을 0으로 리셋합니다' : '팀 파울을 유지합니다',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _resetTeamFouls,
                    onChanged: (value) => setState(() => _resetTeamFouls = value),
                    activeColor: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 액션 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _confirm,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('연장전 시작'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
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

/// 연장전 다이얼로그 표시 헬퍼 함수
Future<OvertimeSettings?> showOvertimeDialog({
  required BuildContext context,
  required String homeTeamName,
  required String awayTeamName,
  required int score,
  int overtimeNumber = 1,
  int defaultMinutes = 5,
}) {
  return showDialog<OvertimeSettings?>(
    context: context,
    barrierDismissible: false,
    builder: (context) => OvertimeDialog(
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      score: score,
      overtimeNumber: overtimeNumber,
      defaultMinutes: defaultMinutes,
    ),
  );
}
