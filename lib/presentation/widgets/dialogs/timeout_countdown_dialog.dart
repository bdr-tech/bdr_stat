import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

/// 타임아웃 60초 카운트다운 오버레이
///
/// showDialog 대신 Overlay를 사용하여 코트 영역 터치를 차단하지 않는다.
/// 사이드 패널 영역(홈=좌측, 어웨이=우측)에 Positioned로 배치.
///
/// 사용법:
/// ```dart
/// final entry = TimeoutCountdownOverlay.show(
///   context: context,
///   isHome: true,
///   teamColor: homeTeamColor,
/// );
/// // 수동 닫기: entry.remove();
/// ```
class TimeoutCountdownOverlay extends StatefulWidget {
  const TimeoutCountdownOverlay({
    super.key,
    required this.isHome,
    required this.teamColor,
    required this.onDismiss,
  });

  final bool isHome;
  final Color teamColor;
  final VoidCallback onDismiss;

  /// Overlay에 카운트다운을 표시하고 OverlayEntry를 반환
  static OverlayEntry show({
    required BuildContext context,
    required bool isHome,
    required Color teamColor,
  }) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => TimeoutCountdownOverlay(
        isHome: isHome,
        teamColor: teamColor,
        onDismiss: () => entry.remove(),
      ),
    );
    Overlay.of(context).insert(entry);
    return entry;
  }

  @override
  State<TimeoutCountdownOverlay> createState() =>
      _TimeoutCountdownOverlayState();
}

class _TimeoutCountdownOverlayState extends State<TimeoutCountdownOverlay>
    with SingleTickerProviderStateMixin {
  /// 60초 = 600 tenths (0.1초 단위)
  int _remainingTenths = 600;
  Timer? _timer;
  late AnimationController _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeAnim = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )..forward();

    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() {
        _remainingTenths--;
        if (_remainingTenths <= 0) {
          _remainingTenths = 0;
          _timer?.cancel();
          HapticFeedback.heavyImpact();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeAnim.dispose();
    super.dispose();
  }

  void _dismiss() {
    _timer?.cancel();
    _fadeAnim.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  String get _formattedTime {
    final seconds = _remainingTenths ~/ 10;
    final tenths = _remainingTenths % 10;
    return '$seconds.$tenths';
  }

  double get _progress => _remainingTenths / 600.0;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final isExpired = _remainingTenths <= 0;
    final isWarning = _remainingTenths <= 100; // 10초 이하

    // 홈팀 = 좌측, 어웨이팀 = 우측에 배치
    final double left = widget.isHome ? 16 : screen.width - 16 - 120;
    final double top = screen.height * 0.3;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Stack(
        children: [
          // 배경은 투명 - 코트 영역 터치 가능하도록 IgnorePointer 사용하지 않음
          // 오버레이 외부 탭 시 닫기 처리 없음 (닫기 버튼으로만 닫음)
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 120,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isExpired
                        ? AppTheme.errorColor
                        : (isWarning
                            ? AppTheme.warningColor
                            : widget.teamColor),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isExpired
                              ? AppTheme.errorColor
                              : widget.teamColor)
                          .withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 타이틀
                    Text(
                      'TIME OUT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: widget.teamColor,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 원형 카운트다운
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 배경 원
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 6,
                              color: AppTheme.borderColor,
                            ),
                          ),
                          // 진행 원
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: _progress,
                              strokeWidth: 6,
                              color: isExpired
                                  ? AppTheme.errorColor
                                  : (isWarning
                                      ? AppTheme.warningColor
                                      : widget.teamColor),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          // 시간 텍스트
                          Text(
                            _formattedTime,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isExpired
                                  ? AppTheme.errorColor
                                  : (isWarning
                                      ? AppTheme.warningColor
                                      : AppTheme.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 만료 시 텍스트
                    if (isExpired)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'EXPIRED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.errorColor,
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                    // 닫기 버튼
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? AppTheme.errorColor.withValues(alpha: 0.2)
                              : AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isExpired
                                ? AppTheme.errorColor
                                : AppTheme.borderColor,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            isExpired ? 'CLOSE' : 'DISMISS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isExpired
                                  ? AppTheme.errorColor
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
