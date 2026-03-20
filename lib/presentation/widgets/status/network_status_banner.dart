import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/network_status_provider.dart';

/// 네트워크 상태 배너
/// 화면 상단에 표시되는 네트워크/동기화 상태 알림
class NetworkStatusBanner extends ConsumerStatefulWidget {
  const NetworkStatusBanner({
    super.key,
    this.showSyncStatus = true,
  });

  final bool showSyncStatus;

  @override
  ConsumerState<NetworkStatusBanner> createState() => _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends ConsumerState<NetworkStatusBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isVisible = false;
  NetworkStatus? _lastStatus;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateVisibility(NetworkState state) {
    final shouldShow = state.isOffline ||
        state.syncStatus == SyncStatus.failed ||
        (state.syncStatus == SyncStatus.syncing && widget.showSyncStatus);

    if (shouldShow && !_isVisible) {
      _isVisible = true;
      _animationController.forward();
    } else if (!shouldShow && _isVisible) {
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() => _isVisible = false);
        }
      });
    }

    // 상태 변경 시 연결 복구 알림
    if (_lastStatus == NetworkStatus.disconnected &&
        state.networkStatus == NetworkStatus.connected) {
      _showConnectionRestoredSnackbar();
    }
    _lastStatus = state.networkStatus;
  }

  void _showConnectionRestoredSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi, color: Colors.white),
            SizedBox(width: 8),
            Text('네트워크 연결이 복구되었습니다'),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(networkStatusProvider);

    // 상태 변화 감지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateVisibility(state);
    });

    if (!_isVisible && !state.isOffline && state.syncStatus != SyncStatus.failed) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 50),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: _buildBanner(state),
    );
  }

  Widget _buildBanner(NetworkState state) {
    // 오프라인 상태
    if (state.isOffline) {
      return _BannerContent(
        icon: Icons.wifi_off,
        message: '오프라인 모드',
        subMessage: state.hasPendingSync
            ? '동기화 대기 중: ${state.pendingSyncCount}건'
            : '인터넷 연결을 확인해주세요',
        color: AppTheme.warningColor,
        onRetry: () => ref.read(networkStatusProvider.notifier).checkConnection(),
      );
    }

    // 동기화 실패
    if (state.syncStatus == SyncStatus.failed) {
      return _BannerContent(
        icon: Icons.sync_problem,
        message: '동기화 실패',
        subMessage: state.lastError ?? '서버 연결에 실패했습니다',
        color: AppTheme.errorColor,
        onRetry: () => ref.read(networkStatusProvider.notifier).checkConnection(),
      );
    }

    // 동기화 중
    if (state.syncStatus == SyncStatus.syncing) {
      return _BannerContent(
        icon: Icons.sync,
        message: '동기화 중...',
        subMessage: '잠시만 기다려주세요',
        color: AppTheme.primaryColor,
        showProgress: true,
      );
    }

    return const SizedBox.shrink();
  }
}

/// 배너 내용 위젯
class _BannerContent extends StatelessWidget {
  const _BannerContent({
    required this.icon,
    required this.message,
    required this.subMessage,
    required this.color,
    this.onRetry,
    this.showProgress = false,
  });

  final IconData icon;
  final String message;
  final String subMessage;
  final Color color;
  final VoidCallback? onRetry;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // 아이콘 (동기화 중일 때 회전)
            if (showProgress)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),

            // 메시지
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subMessage,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // 재시도 버튼
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('재시도'),
              ),
          ],
        ),
      ),
    );
  }
}

/// 컴팩트한 네트워크 상태 인디케이터 (앱바용)
class NetworkStatusIndicator extends ConsumerWidget {
  const NetworkStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(networkStatusProvider);

    if (state.isOnline && state.syncStatus != SyncStatus.syncing) {
      return const SizedBox.shrink();
    }

    IconData icon;
    Color color;
    String tooltip;

    if (state.isOffline) {
      icon = Icons.wifi_off;
      color = AppTheme.warningColor;
      tooltip = '오프라인';
    } else if (state.syncStatus == SyncStatus.syncing) {
      icon = Icons.sync;
      color = AppTheme.primaryColor;
      tooltip = '동기화 중';
    } else if (state.syncStatus == SyncStatus.failed) {
      icon = Icons.sync_problem;
      color = AppTheme.errorColor;
      tooltip = '동기화 실패';
    } else {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: state.syncStatus == SyncStatus.syncing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            : Icon(icon, color: color, size: 20),
      ),
    );
  }
}

/// 미동기화 배지 (아이콘에 붙이는 작은 뱃지)
class UnsyncedBadge extends ConsumerWidget {
  const UnsyncedBadge({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingSyncCountProvider);

    if (count == 0) {
      return child;
    }

    return Badge(
      label: Text(
        count > 9 ? '9+' : count.toString(),
        style: const TextStyle(fontSize: 10),
      ),
      backgroundColor: AppTheme.warningColor,
      child: child,
    );
  }
}
