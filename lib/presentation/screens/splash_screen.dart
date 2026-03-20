import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../core/theme/bdr_design_system.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/app_recovery_service.dart';
import '../widgets/dialogs/recovery_dialog.dart';
import '../providers/auth_provider.dart';
import '../../domain/models/auth_models.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _textCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _pulse;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    // Logo entrance: scale + fade
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Continuous pulse glow
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Text entrance: fade + slide up
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    // Stagger animations
    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _textCtrl.forward();
    });

    _checkInitialRoute();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _pulseCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkInitialRoute() async {
    await Future.delayed(AppConstants.splashInitialDelay);
    if (!mounted) return;

    await _checkForRecoverableMatch();
    if (!mounted) return;

    final authState = ref.read(authProvider);

    if (authState.status == AuthStatus.loading ||
        authState.status == AuthStatus.initial) {
      for (var i = 0; i < AppConstants.authCheckMaxAttempts; i++) {
        await Future.delayed(AppConstants.authCheckInterval);
        if (!mounted) return;
        final currentState = ref.read(authProvider);
        if (currentState.status != AuthStatus.loading &&
            currentState.status != AuthStatus.initial) {
          break;
        }
      }
    }

    if (!mounted) return;

    final finalAuthState = ref.read(authProvider);

    if (finalAuthState.isAuthenticated) {
      _startBackgroundSync();
      context.go('/tournaments');
      return;
    }

    final tokenAsync = ref.read(savedApiTokenProvider);
    final token = tokenAsync.valueOrNull;

    if (token != null) {
      _startBackgroundSync();
      context.go('/matches');
    } else {
      context.go('/login');
    }
  }

  void _startBackgroundSync() {
    try {
      final syncManager = ref.read(syncManagerProvider);
      syncManager.startBackgroundSync();
    } catch (e) {
      debugPrint('Background sync start error: $e');
    }
  }

  Future<void> _checkForRecoverableMatch() async {
    try {
      final recoveryService = ref.read(appRecoveryServiceProvider);
      final recoverableMatch =
          await recoveryService.checkForRecoverableMatch();

      if (recoverableMatch != null && mounted) {
        final action = await RecoveryDialog.show(context, recoverableMatch);
        if (action == RecoveryAction.continueMatch && mounted) {
          return;
        }
      }
    } catch (e) {
      debugPrint('Recovery check error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DS.bg,
      body: Stack(
        children: [
          // Ambient glow background
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Positioned.fill(
              child: CustomPaint(
                painter: _AmbientGlowPainter(
                  intensity: _pulse.value,
                ),
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo
                AnimatedBuilder(
                  animation: _logoCtrl,
                  builder: (_, child) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: child,
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(DS.radiusXl),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            DS.homeRed,
                            DS.homeRed.withValues(alpha: 0.8),
                            DS.awayBlue,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                DS.homeRed.withValues(alpha: _pulse.value * 0.4),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: DS.awayBlue
                                .withValues(alpha: _pulse.value * 0.3),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'B',
                          style: DSText.bebasHuge(
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Animated text
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        Text(
                          'BDR TOURNAMENT',
                          style: DSText.bebasLarge(
                            color: DS.textPrimary,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: DS.gold.withValues(alpha: 0.5),
                            ),
                            borderRadius: BorderRadius.circular(DS.radiusXs),
                          ),
                          child: Text(
                            'RECORDER',
                            style: DSText.jakartaLabel(
                              color: DS.gold,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Loading indicator
                FadeTransition(
                  opacity: _textOpacity,
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DS.textHint,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ambient glow painter for splash background
class _AmbientGlowPainter extends CustomPainter {
  _AmbientGlowPainter({required this.intensity});
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    // Red glow - top left
    final redPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.6, -0.4),
        radius: 1.2,
        colors: [
          DS.homeRed.withValues(alpha: intensity * 0.08),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, redPaint);

    // Blue glow - bottom right
    final bluePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.6, 0.5),
        radius: 1.2,
        colors: [
          DS.awayBlue.withValues(alpha: intensity * 0.06),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bluePaint);
  }

  @override
  bool shouldRepaint(_AmbientGlowPainter old) => old.intensity != intensity;
}
