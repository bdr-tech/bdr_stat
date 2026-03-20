import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/theme/app_theme.dart';

/// 경기 시작 전 체크리스트 다이얼로그
///
/// 모든 항목이 충족되어야 경기 시작 버튼이 활성화됩니다.
class GameStartChecklistDialog extends StatefulWidget {
  const GameStartChecklistDialog({
    super.key,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeStarterCount,
    required this.awayStarterCount,
    required this.quarterMinutes,
    required this.totalQuarters,
    this.requiredStarters = 5,
  });

  final String homeTeamName;
  final String awayTeamName;
  final int homeStarterCount;
  final int awayStarterCount;
  final int quarterMinutes;
  final int totalQuarters;
  final int requiredStarters;

  @override
  State<GameStartChecklistDialog> createState() => _GameStartChecklistDialogState();
}

class _GameStartChecklistDialogState extends State<GameStartChecklistDialog> {
  bool? _jumpBallWinner; // true = home, false = away, null = not selected
  bool _hasNetwork = false;
  bool _isCheckingNetwork = true;

  @override
  void initState() {
    super.initState();
    _checkNetworkStatus();
  }

  Future<void> _checkNetworkStatus() async {
    setState(() => _isCheckingNetwork = true);

    try {
      final result = await Connectivity().checkConnectivity();
      setState(() {
        _hasNetwork = result.isNotEmpty &&
            result.first != ConnectivityResult.none;
        _isCheckingNetwork = false;
      });
    } catch (e) {
      setState(() {
        _hasNetwork = false;
        _isCheckingNetwork = false;
      });
    }
  }

  bool get _homeStartersReady => widget.homeStarterCount >= widget.requiredStarters;
  bool get _awayStartersReady => widget.awayStarterCount >= widget.requiredStarters;
  bool get _timerConfigured => widget.quarterMinutes > 0 && widget.totalQuarters > 0;
  bool get _jumpBallSelected => _jumpBallWinner != null;

  bool get _canStartGame =>
      _homeStartersReady &&
      _awayStartersReady &&
      _timerConfigured &&
      _jumpBallSelected;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                const Icon(Icons.checklist_rounded, size: 28),
                const SizedBox(width: 12),
                Text(
                  '경기 시작 체크리스트',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '모든 항목을 확인하고 경기를 시작하세요',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 32),

            // 체크리스트 항목들
            _buildChecklistItem(
              context,
              icon: Icons.people,
              title: '${widget.homeTeamName} 선발 선수',
              subtitle: '${widget.homeStarterCount}/${widget.requiredStarters}명 선택됨',
              isChecked: _homeStartersReady,
              isError: widget.homeStarterCount > widget.requiredStarters,
            ),
            const SizedBox(height: 12),

            _buildChecklistItem(
              context,
              icon: Icons.people_outline,
              title: '${widget.awayTeamName} 선발 선수',
              subtitle: '${widget.awayStarterCount}/${widget.requiredStarters}명 선택됨',
              isChecked: _awayStartersReady,
              isError: widget.awayStarterCount > widget.requiredStarters,
            ),
            const SizedBox(height: 12),

            _buildChecklistItem(
              context,
              icon: Icons.timer,
              title: '타이머 설정',
              subtitle: '${widget.quarterMinutes}분 x ${widget.totalQuarters}쿼터',
              isChecked: _timerConfigured,
            ),
            const SizedBox(height: 12),

            _buildChecklistItem(
              context,
              icon: Icons.wifi,
              title: '네트워크 상태',
              subtitle: _isCheckingNetwork
                  ? '확인 중...'
                  : (_hasNetwork ? '연결됨 (동기화 가능)' : '오프라인 (로컬 저장)'),
              isChecked: true, // 네트워크는 필수가 아님
              isWarning: !_hasNetwork && !_isCheckingNetwork,
              trailing: _isCheckingNetwork
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: _checkNetworkStatus,
                      tooltip: '다시 확인',
                    ),
            ),
            const SizedBox(height: 20),

            // 점프볼 승자 선택
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _jumpBallSelected
                      ? AppTheme.successColor
                      : Theme.of(context).dividerColor,
                  width: _jumpBallSelected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.sports_basketball,
                        size: 20,
                        color: _jumpBallSelected
                            ? AppTheme.successColor
                            : Theme.of(context).hintColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '점프볼 승자',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (_jumpBallSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.successColor,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTeamButton(
                          context,
                          teamName: widget.homeTeamName,
                          isSelected: _jumpBallWinner == true,
                          color: AppTheme.homeTeamColor,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _jumpBallWinner = true);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTeamButton(
                          context,
                          teamName: widget.awayTeamName,
                          isSelected: _jumpBallWinner == false,
                          color: AppTheme.awayTeamColor,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _jumpBallWinner = false);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 버튼들
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
                    onPressed: _canStartGame
                        ? () {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(context, _jumpBallWinner);
                          }
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('경기 시작'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Theme.of(context).disabledColor,
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

  Widget _buildChecklistItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isChecked,
    bool isError = false,
    bool isWarning = false,
    Widget? trailing,
  }) {
    final Color statusColor;
    final IconData statusIcon;

    if (isError) {
      statusColor = AppTheme.errorColor;
      statusIcon = Icons.error;
    } else if (isWarning) {
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.warning;
    } else if (isChecked) {
      statusColor = AppTheme.successColor;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Theme.of(context).hintColor;
      statusIcon = Icons.radio_button_unchecked;
    }

    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).hintColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isError ? AppTheme.errorColor : null,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
        if (trailing == null)
          Icon(statusIcon, color: statusColor, size: 24),
      ],
    );
  }

  Widget _buildTeamButton(
    BuildContext context, {
    required String teamName,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Theme.of(context).dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              teamName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 경기 시작 체크리스트 다이얼로그를 표시하고 결과를 반환합니다.
///
/// 반환값:
/// - true: 홈팀이 점프볼 승리
/// - false: 원정팀이 점프볼 승리
/// - null: 취소됨
Future<bool?> showGameStartChecklistDialog({
  required BuildContext context,
  required String homeTeamName,
  required String awayTeamName,
  required int homeStarterCount,
  required int awayStarterCount,
  required int quarterMinutes,
  required int totalQuarters,
  int requiredStarters = 5,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => GameStartChecklistDialog(
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      homeStarterCount: homeStarterCount,
      awayStarterCount: awayStarterCount,
      quarterMinutes: quarterMinutes,
      totalQuarters: totalQuarters,
      requiredStarters: requiredStarters,
    ),
  );
}
