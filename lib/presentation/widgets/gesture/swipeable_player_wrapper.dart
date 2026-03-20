import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

/// 스와이프 제스처로 빠른 슛 기록이 가능한 선수 래퍼 위젯
///
/// - 왼쪽 스와이프: 2점 슛
/// - 오른쪽 스와이프: 3점 슛
class SwipeablePlayerWrapper extends StatefulWidget {
  const SwipeablePlayerWrapper({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.swipeThreshold = 50.0,
    this.enabled = true,
    this.showIndicators = true,
    this.leftLabel = '2PT',
    this.rightLabel = '3PT',
    this.leftColor,
    this.rightColor,
  });

  /// 감싸질 자식 위젯
  final Widget child;

  /// 왼쪽 스와이프 콜백 (2점)
  final VoidCallback? onSwipeLeft;

  /// 오른쪽 스와이프 콜백 (3점)
  final VoidCallback? onSwipeRight;

  /// 스와이프 인식 임계값 (픽셀)
  final double swipeThreshold;

  /// 스와이프 제스처 활성화 여부
  final bool enabled;

  /// 스와이프 방향 인디케이터 표시 여부
  final bool showIndicators;

  /// 왼쪽 스와이프 라벨
  final String leftLabel;

  /// 오른쪽 스와이프 라벨
  final String rightLabel;

  /// 왼쪽 스와이프 색상
  final Color? leftColor;

  /// 오른쪽 스와이프 색상
  final Color? rightColor;

  @override
  State<SwipeablePlayerWrapper> createState() => _SwipeablePlayerWrapperState();
}

class _SwipeablePlayerWrapperState extends State<SwipeablePlayerWrapper>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  bool _isDragging = false;

  late AnimationController _resetController;
  late Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _resetAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOut),
    );
    _resetAnimation.addListener(() {
      setState(() {
        _dragOffset = _resetAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (!widget.enabled) return;
    setState(() {
      _isDragging = true;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;
    setState(() {
      _dragOffset += details.delta.dx;
      // 최대 드래그 거리 제한
      _dragOffset = _dragOffset.clamp(-100.0, 100.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!widget.enabled) return;

    // 스와이프 방향 및 거리 확인
    if (_dragOffset.abs() >= widget.swipeThreshold) {
      if (_dragOffset < 0 && widget.onSwipeLeft != null) {
        // 왼쪽 스와이프 → 2점
        HapticFeedback.mediumImpact();
        widget.onSwipeLeft!();
      } else if (_dragOffset > 0 && widget.onSwipeRight != null) {
        // 오른쪽 스와이프 → 3점
        HapticFeedback.heavyImpact();
        widget.onSwipeRight!();
      }
    }

    // 원위치로 복귀 애니메이션
    _resetAnimation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOut,
    ));
    _resetController.forward(from: 0);

    setState(() {
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final leftColor = widget.leftColor ?? AppTheme.primaryColor;
    final rightColor = widget.rightColor ?? AppTheme.secondaryColor;

    // 스와이프 진행도 (0.0 ~ 1.0)
    final progress = (_dragOffset.abs() / widget.swipeThreshold).clamp(0.0, 1.0);
    final isLeftSwipe = _dragOffset < 0;

    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 스와이프 인디케이터 (배경)
          if (widget.showIndicators && _isDragging && progress > 0.3)
            Positioned.fill(
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 100),
                  opacity: progress,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isLeftSwipe ? leftColor : rightColor).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isLeftSwipe ? widget.leftLabel : widget.rightLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 메인 콘텐츠 (드래그에 따라 이동)
          Transform.translate(
            offset: Offset(_dragOffset * 0.3, 0), // 살짝만 이동
            child: AnimatedScale(
              scale: _isDragging ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: widget.child,
            ),
          ),

          // 스와이프 방향 화살표 (드래그 중)
          if (widget.showIndicators && _isDragging && progress > 0.1)
            Positioned(
              left: isLeftSwipe ? -20 : null,
              right: isLeftSwipe ? null : -20,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 100),
                  opacity: progress * 0.8,
                  child: Icon(
                    isLeftSwipe ? Icons.chevron_left : Icons.chevron_right,
                    color: isLeftSwipe ? leftColor : rightColor,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 스와이프 액션 타입
enum SwipeAction {
  twoPoint,
  threePoint,
}
