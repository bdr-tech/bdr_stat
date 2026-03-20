import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/voice_command_service.dart';

/// 음성 명령 버튼 위젯
///
/// 길게 누르면 음성 인식 시작, 놓으면 중지
/// 또는 탭하여 토글 모드로 사용
class VoiceCommandButton extends ConsumerStatefulWidget {
  const VoiceCommandButton({
    super.key,
    required this.onCommand,
    this.size = 56,
    this.useToggleMode = false,
  });

  /// 음성 명령 인식 시 콜백
  final VoiceCommandCallback onCommand;

  /// 버튼 크기
  final double size;

  /// 토글 모드 사용 여부 (true: 탭으로 시작/중지, false: 길게 누르기)
  final bool useToggleMode;

  @override
  ConsumerState<VoiceCommandButton> createState() => _VoiceCommandButtonState();
}

class _VoiceCommandButtonState extends ConsumerState<VoiceCommandButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceRecognitionStateProvider);

    // 듣는 중이면 펄스 애니메이션
    if (voiceState.isListening && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!voiceState.isListening && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }

    // 마지막 결과가 있으면 콜백 호출
    ref.listen<VoiceRecognitionState>(voiceRecognitionStateProvider,
        (prev, next) {
      if (next.lastResult != null &&
          next.lastResult != prev?.lastResult &&
          next.lastResult!.hasCommand) {
        widget.onCommand(next.lastResult!);
      }
    });

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: voiceState.isListening ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.useToggleMode ? _onToggle : null,
        onLongPressStart: widget.useToggleMode ? null : _onLongPressStart,
        onLongPressEnd: widget.useToggleMode ? null : _onLongPressEnd,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: voiceState.isListening
                  ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                  : voiceState.hasError
                      ? [const Color(0xFF6B7280), const Color(0xFF4B5563)]
                      : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
            ),
            boxShadow: [
              BoxShadow(
                color: voiceState.isListening
                    ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                    : const Color(0xFF6366F1).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 듣는 중 표시 링
              if (voiceState.isListening)
                Positioned.fill(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),

              // 마이크 아이콘
              Icon(
                voiceState.isListening
                    ? Icons.mic
                    : voiceState.hasError
                        ? Icons.mic_off
                        : Icons.mic_none,
                color: Colors.white,
                size: widget.size * 0.5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onToggle() {
    HapticFeedback.mediumImpact();
    final notifier = ref.read(voiceRecognitionStateProvider.notifier);
    final state = ref.read(voiceRecognitionStateProvider);

    if (state.isListening) {
      notifier.stopListening();
    } else {
      notifier.startListening();
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    HapticFeedback.heavyImpact();
    ref.read(voiceRecognitionStateProvider.notifier).startListening();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    HapticFeedback.lightImpact();
    ref.read(voiceRecognitionStateProvider.notifier).stopListening();
  }
}

/// 음성 인식 결과 표시 오버레이
class VoiceRecognitionOverlay extends ConsumerWidget {
  const VoiceRecognitionOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceRecognitionStateProvider);

    if (!state.isListening && !state.isProcessing) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: state.isListening
                ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                : const Color(0xFF6366F1).withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상태 표시
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  state.isListening ? Icons.hearing : Icons.psychology,
                  color: state.isListening
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF6366F1),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  state.isListening ? '듣는 중...' : '처리 중...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),

            // 현재 인식 텍스트
            if (state.currentText != null && state.currentText!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '"${state.currentText}"',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // 마지막 인식 결과
            if (state.lastResult != null && state.lastResult!.hasCommand) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '✓ ${VoiceCommandService().commandToDisplayText(state.lastResult!.command!)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 음성 명령 안내 힌트
class VoiceCommandHint extends StatelessWidget {
  const VoiceCommandHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: Color(0xFFF59E0B),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '음성 명령 예시',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[300],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHintRow('슛 관련', '"3점 성공", "자유투 실패"'),
          _buildHintRow('스탯 기록', '"어시스트", "리바운드", "스틸"'),
          _buildHintRow('타이머', '"타이머 시작", "타이머 멈춰"'),
          _buildHintRow('기타', '"교체", "취소"'),
        ],
      ),
    );
  }

  Widget _buildHintRow(String category, String examples) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              category,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            child: Text(
              examples,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
