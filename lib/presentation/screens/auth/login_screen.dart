import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/bdr_design_system.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  // TODO: 테스트용 임시 값 — 출시 전 반드시 제거
  final _emailController = TextEditingController(text: 'bdr.wonyoung@gmail.com');
  final _passwordController = TextEditingController(text: '1234');
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    // 프로덕션 빌드: 사용자가 직접 입력

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));

    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    final success = await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      HapticFeedback.mediumImpact();
      context.go('/tournaments');
    } else {
      HapticFeedback.heavyImpact();
      final errorMessage =
          ref.read(authProvider).errorMessage ?? '로그인에 실패했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage,
              style: DSText.jakartaBody(color: Colors.white, size: 13)),
          backgroundColor: DS.error.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: DSText.jakartaLabel(color: DS.textSecondary, size: 13),
      hintStyle: DSText.jakartaBody(color: DS.textHint, size: 14),
      prefixIcon: Icon(icon, color: DS.textSecondary, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: DS.glassFillMid,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DS.radiusSm),
        borderSide: BorderSide(color: DS.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DS.radiusSm),
        borderSide: BorderSide(color: DS.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DS.radiusSm),
        borderSide: const BorderSide(color: DS.gold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DS.radiusSm),
        borderSide: const BorderSide(color: DS.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DS.radiusSm),
        borderSide: const BorderSide(color: DS.error, width: 1.5),
      ),
      errorStyle: DSText.jakartaLabel(color: DS.error, size: 11),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: DS.bg,
      body: Stack(
        children: [
          // Ambient background
          Positioned.fill(
            child: CustomPaint(
              painter: _LoginBackgroundPainter(),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width > 600 ? size.width * 0.25 : 32,
                  vertical: 24,
                ),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(DS.radiusLg),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [DS.homeRed, DS.awayBlue],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: DS.homeRed.withValues(alpha: 0.3),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'B',
                                style: DSText.bebasHuge(
                                  color: Colors.white,
                                  size: 44,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Title
                          Text(
                            'BDR TOURNAMENT',
                            style: DSText.bebasMedium(
                              color: DS.textPrimary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '대회 운영자 로그인',
                            style: DSText.jakartaBody(
                              color: DS.textSecondary,
                              size: 13,
                            ),
                          ),

                          const SizedBox(height: 36),

                          // Login form glass card
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(DS.radiusMd),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                  sigmaX: DS.blurRadiusSm,
                                  sigmaY: DS.blurRadiusSm),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: DS.glassFill,
                                  borderRadius:
                                      BorderRadius.circular(DS.radiusMd),
                                  border: Border.all(
                                    color: DS.glassBorder,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Email
                                    TextFormField(
                                      controller: _emailController,
                                      focusNode: _emailFocus,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      textInputAction:
                                          TextInputAction.next,
                                      autofillHints: null,
                                      style: DSText.jakartaBody(
                                        color: DS.textPrimary,
                                        size: 14,
                                      ),
                                      cursorColor: DS.gold,
                                      decoration: _inputDecoration(
                                        label: '이메일',
                                        hint: 'example@bdr.kr',
                                        icon: Icons.email_outlined,
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return '이메일을 입력해주세요.';
                                        }
                                        if (!value.contains('@')) {
                                          return '올바른 이메일 형식을 입력해주세요.';
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) =>
                                          _passwordFocus.requestFocus(),
                                    ),

                                    const SizedBox(height: 16),

                                    // Password
                                    TextFormField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocus,
                                      obscureText: _obscurePassword,
                                      textInputAction:
                                          TextInputAction.done,
                                      autofillHints: null,
                                      style: DSText.jakartaBody(
                                        color: DS.textPrimary,
                                        size: 14,
                                      ),
                                      cursorColor: DS.gold,
                                      decoration: _inputDecoration(
                                        label: '비밀번호',
                                        hint: '',
                                        icon: Icons.lock_outlined,
                                        suffix: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons
                                                    .visibility_off_outlined,
                                            color: DS.textHint,
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscurePassword =
                                                  !_obscurePassword),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.isEmpty) {
                                          return '비밀번호를 입력해주세요.';
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) =>
                                          _handleLogin(),
                                    ),

                                    const SizedBox(height: 24),

                                    // Login button
                                    TapScaleButton(
                                      onTap: _isLoading ||
                                              authState.isLoading
                                          ? null
                                          : _handleLogin,
                                      child: Container(
                                        height: 52,
                                        decoration: BoxDecoration(
                                          gradient: (_isLoading ||
                                                  authState.isLoading)
                                              ? null
                                              : const LinearGradient(
                                                  colors: [
                                                    DS.homeRed,
                                                    Color(0xFFCC2D3A),
                                                  ],
                                                ),
                                          color: (_isLoading ||
                                                  authState.isLoading)
                                              ? DS.glassFillMid
                                              : null,
                                          borderRadius:
                                              BorderRadius.circular(
                                                  DS.radiusSm),
                                          boxShadow: (_isLoading ||
                                                  authState.isLoading)
                                              ? null
                                              : [
                                                  BoxShadow(
                                                    color: DS.homeRed
                                                        .withValues(
                                                            alpha: 0.4),
                                                    blurRadius: 20,
                                                    offset:
                                                        const Offset(0, 4),
                                                  ),
                                                ],
                                        ),
                                        child: Center(
                                          child: (_isLoading ||
                                                  authState.isLoading)
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: DS.textSecondary,
                                                    strokeCap:
                                                        StrokeCap.round,
                                                  ),
                                                )
                                              : Text(
                                                  '로그인',
                                                  style:
                                                      DSText.jakartaButton(
                                                    color: Colors.white,
                                                    size: 15,
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

                          const SizedBox(height: 20),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: DS.glassBorder,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                child: Text(
                                  '또는',
                                  style: DSText.jakartaLabel(
                                    color: DS.textHint,
                                    size: 11,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: DS.glassBorder,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Token connect
                          TapScaleButton(
                            onTap: () => context.go('/connect'),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: DS.glassFill,
                                borderRadius:
                                    BorderRadius.circular(DS.radiusSm),
                                border: Border.all(color: DS.glassBorder),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.qr_code_rounded,
                                      color: DS.textSecondary, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    '토큰으로 연결',
                                    style: DSText.jakartaButton(
                                      color: DS.textSecondary,
                                      size: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Dev mode bypass
                          if (kDebugMode) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                ref
                                    .read(authProvider.notifier)
                                    .setDevMode();
                                context.go('/tournaments');
                              },
                              child: Text(
                                '[DEV] 로그인 없이 진입',
                                style: DSText.jakartaLabel(
                                  color: DS.gold.withValues(alpha: 0.7),
                                  size: 11,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),

                          // Help text
                          Text(
                            '대회를 주최하거나 관리자로 등록된\nBDR 계정으로 로그인하세요.',
                            style: DSText.jakartaBody(
                              color: DS.textHint,
                              size: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Subtle red glow top-left
    final redPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.8, -0.6),
        radius: 1.5,
        colors: [
          DS.homeRed.withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, redPaint);

    // Subtle blue glow bottom-right
    final bluePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.8, 0.7),
        radius: 1.5,
        colors: [
          DS.awayBlue.withValues(alpha: 0.04),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
