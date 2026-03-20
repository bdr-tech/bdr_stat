import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';

/// 자유투 시퀀스 결과
class FreeThrowSequenceResult {
  final int made;
  final int attempted;
  final List<bool> results; // 각 자유투 결과 (true: 성공, false: 실패)
  final bool lastMissed; // 마지막이 실패인지 (리바운드 연결용)

  const FreeThrowSequenceResult({
    required this.made,
    required this.attempted,
    required this.results,
    required this.lastMissed,
  });
}

/// 자유투 시퀀스 다이얼로그
class FreeThrowSequenceDialog extends StatefulWidget {
  const FreeThrowSequenceDialog({
    super.key,
    required this.player,
    this.initialCount,
    this.onComplete,
  });

  final LocalTournamentPlayer player;
  final int? initialCount; // 자유투 개수가 미리 정해진 경우
  final void Function(FreeThrowSequenceResult result)? onComplete;

  @override
  State<FreeThrowSequenceDialog> createState() => _FreeThrowSequenceDialogState();
}

class _FreeThrowSequenceDialogState extends State<FreeThrowSequenceDialog> {
  int? _totalCount;
  final List<bool> _results = [];

  int get _currentShot => _results.length + 1;
  bool get _isSelectingCount => _totalCount == null;
  bool get _isComplete => _totalCount != null && _results.length >= _totalCount!;

  @override
  void initState() {
    super.initState();
    if (widget.initialCount != null) {
      _totalCount = widget.initialCount;
    }
  }

  void _selectCount(int count) {
    setState(() {
      _totalCount = count;
      _results.clear();
    });
  }

  void _recordResult(bool isMade) {
    setState(() {
      _results.add(isMade);
    });

    if (_isComplete) {
      _finishSequence();
    }
  }

  void _finishSequence() {
    final made = _results.where((r) => r).length;
    final result = FreeThrowSequenceResult(
      made: made,
      attempted: _totalCount!,
      results: List.from(_results),
      lastMissed: _results.isNotEmpty && !_results.last,
    );

    widget.onComplete?.call(result);
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
                    '#${widget.player.jerseyNumber ?? '-'}',
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
                      widget.player.userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '자유투',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 내용
            if (_isSelectingCount)
              _buildCountSelector()
            else
              _buildShotInput(),

            const SizedBox(height: 16),

            // 취소 버튼
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
          ],
        ),
      ),
    );
  }

  /// 자유투 개수 선택 UI
  Widget _buildCountSelector() {
    return Column(
      children: [
        const Text(
          '자유투 개수를 선택하세요',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CountButton(count: 1, onTap: () => _selectCount(1)),
            _CountButton(count: 2, onTap: () => _selectCount(2)),
            _CountButton(count: 3, onTap: () => _selectCount(3)),
          ],
        ),
      ],
    );
  }

  /// 자유투 입력 UI
  Widget _buildShotInput() {
    return Column(
      children: [
        // 진행 상태 표시
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$_currentShot / $_totalCount',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 결과 표시
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_totalCount!, (index) {
            if (index < _results.length) {
              // 이미 기록된 결과
              final isMade = _results[index];
              return Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isMade ? AppTheme.shotMadeColor : AppTheme.shotMissedColor,
                ),
                child: Icon(
                  isMade ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              );
            } else if (index == _results.length) {
              // 현재 입력할 자유투
              return Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor, width: 3),
                ),
                child: const Center(
                  child: Text(
                    '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              );
            } else {
              // 아직 입력하지 않은 자유투
              return Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderColor, width: 1),
                ),
              );
            }
          }),
        ),

        const SizedBox(height: 24),

        // 성공/실패 버튼
        if (!_isComplete)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _ResultButton(
                  icon: Icons.check_circle,
                  label: '성공',
                  color: AppTheme.shotMadeColor,
                  onTap: () => _recordResult(true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ResultButton(
                  icon: Icons.cancel,
                  label: '실패',
                  color: AppTheme.shotMissedColor,
                  onTap: () => _recordResult(false),
                ),
              ),
            ],
          ),

        // 완료 표시
        if (_isComplete) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_results.where((r) => r).length}/${_totalCount!} 성공',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.successColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 개수 선택 버튼
class _CountButton extends StatelessWidget {
  const _CountButton({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// 결과 버튼 위젯
class _ResultButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
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

/// 자유투 시퀀스 다이얼로그 표시 헬퍼 함수
Future<FreeThrowSequenceResult?> showFreeThrowSequenceDialog({
  required BuildContext context,
  required LocalTournamentPlayer player,
  int? initialCount,
}) {
  return showDialog<FreeThrowSequenceResult?>(
    context: context,
    barrierDismissible: false,
    builder: (context) => FreeThrowSequenceDialog(
      player: player,
      initialCount: initialCount,
    ),
  );
}
