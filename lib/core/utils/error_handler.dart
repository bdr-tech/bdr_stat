import 'package:flutter/material.dart';

/// 앱 전체 에러 표시 패턴 통일
/// 사용법: ErrorDisplay.showSnackBar(context, '에러 메시지');
class ErrorDisplay {
  ErrorDisplay._();

  /// 하단 SnackBar로 에러 표시 (기본 패턴)
  static void showSnackBar(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(label: '재시도', onPressed: onRetry)
            : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 네트워크 에러 전용 (재시도 포함)
  static void showNetworkError(BuildContext context, {VoidCallback? onRetry}) {
    showSnackBar(
      context,
      '네트워크 연결을 확인해주세요.',
      onRetry: onRetry,
      duration: const Duration(seconds: 5),
    );
  }
}
