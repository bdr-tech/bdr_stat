import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BDR Premium Design System  (A + C: Premium Sports × Glassmorphism)
//
// 색상 철학:
//   배경    : #05050F  — 극심한 다크, 미세한 인디고 틴트
//   HOME    : #E63946  — BDR 로고 레드
//   AWAY    : #2B6CB0  — BDR 로고 블루
//   GOLD    : #F59E0B  — 프리미엄 액센트 (득점, 하이라이트)
//   Glass   : rgba(255,255,255,0.06) + blur 20
// ─────────────────────────────────────────────────────────────────────────────

class DS {
  DS._();

  // ── 배경 ──────────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFF05050F);
  static const Color surface = Color(0xFF0D0D1A);
  static const Color elevated = Color(0xFF12121F);

  // ── 팀 컬러 ────────────────────────────────────────────────────────────────
  static const Color homeRed = Color(0xFFE63946);
  static const Color awayBlue = Color(0xFF2B6CB0);

  // ── 액센트 ────────────────────────────────────────────────────────────────
  static const Color gold = Color(0xFFF59E0B);
  static const Color goldDim = Color(0xFFB45309);
  static const Color emerald = Color(0xFF10B981);
  static const Color rose = Color(0xFFF43F5E);
  static const Color violet = Color(0xFF8B5CF6);

  // ── 기능 색상 ─────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF22C55E);

  // ── 텍스트 ────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF);  // 60% white
  static const Color textHint = Color(0x4DFFFFFF);       // 30% white

  // ── 글래스 ────────────────────────────────────────────────────────────────
  static const Color glassFill = Color(0x0FFFFFFF);      // 6% white
  static const Color glassFillMid = Color(0x1AFFFFFF);   // 10% white
  static const Color glassBorder = Color(0x1FFFFFFF);    // 12% white
  static const Color glassBorderBright = Color(0x33FFFFFF); // 20% white

  // ── 블러 ──────────────────────────────────────────────────────────────────
  static const double blurRadius = 20.0;
  static const double blurRadiusSm = 12.0;

  // ── 라운딩 ────────────────────────────────────────────────────────────────
  static const double radiusXs = 6.0;
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 28.0;

  // ── Glow BoxShadow 헬퍼 ───────────────────────────────────────────────────
  static List<BoxShadow> glowRed({double intensity = 0.5}) => [
    BoxShadow(
      color: homeRed.withValues(alpha: intensity * 0.6),
      blurRadius: 24,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: homeRed.withValues(alpha: intensity * 0.3),
      blurRadius: 48,
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> glowBlue({double intensity = 0.5}) => [
    BoxShadow(
      color: awayBlue.withValues(alpha: intensity * 0.6),
      blurRadius: 24,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: awayBlue.withValues(alpha: intensity * 0.3),
      blurRadius: 48,
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> glowGold({double intensity = 0.6}) => [
    BoxShadow(
      color: gold.withValues(alpha: intensity * 0.7),
      blurRadius: 20,
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> glowColor(Color color, {double intensity = 0.5}) => [
    BoxShadow(
      color: color.withValues(alpha: intensity * 0.6),
      blurRadius: 20,
      spreadRadius: -2,
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Typography — Bebas Neue × Plus Jakarta Sans × Rajdhani
// ─────────────────────────────────────────────────────────────────────────────

class DSText {
  DSText._();

  // Bebas Neue — 스포츠 헤드라인, 팀명, 큰 점수
  static TextStyle bebasHuge({Color color = DS.textPrimary, double size = 80}) =>
      GoogleFonts.bebasNeue(fontSize: size, color: color, letterSpacing: 2);

  static TextStyle bebasLarge({Color color = DS.textPrimary, double size = 48}) =>
      GoogleFonts.bebasNeue(fontSize: size, color: color, letterSpacing: 1.5);

  static TextStyle bebasMedium({Color color = DS.textPrimary, double size = 28}) =>
      GoogleFonts.bebasNeue(fontSize: size, color: color, letterSpacing: 1);

  static TextStyle bebasSmall({Color color = DS.textPrimary, double size = 18}) =>
      GoogleFonts.bebasNeue(fontSize: size, color: color, letterSpacing: 0.5);

  // Rajdhani — 디지털 클락, 샷클락
  static TextStyle rajdhaniClock({Color color = DS.textPrimary, double size = 22}) =>
      GoogleFonts.rajdhani(
        fontSize: size, color: color,
        fontWeight: FontWeight.w700, letterSpacing: 2,
      );

  static TextStyle rajdhaniLarge({Color color = DS.textPrimary, double size = 40}) =>
      GoogleFonts.rajdhani(
        fontSize: size, color: color,
        fontWeight: FontWeight.w700, letterSpacing: 3,
      );

  // Plus Jakarta Sans — 본문, 라벨
  static TextStyle jakartaLabel({Color color = DS.textSecondary, double size = 11}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size, color: color,
        fontWeight: FontWeight.w600, letterSpacing: 1.2,
      );

  static TextStyle jakartaBody({Color color = DS.textPrimary, double size = 14}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, color: color);

  static TextStyle jakartaBold({Color color = DS.textPrimary, double size = 14}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size, color: color, fontWeight: FontWeight.w700,
      );

  static TextStyle jakartaButton({Color color = DS.textPrimary, double size = 13}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size, color: color,
        fontWeight: FontWeight.w600, letterSpacing: 0.3,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass Container — BackdropFilter + gradient border
// ─────────────────────────────────────────────────────────────────────────────

class GlassBox extends StatelessWidget {
  const GlassBox({
    super.key,
    required this.child,
    this.borderRadius = DS.radiusMd,
    this.blur = DS.blurRadius,
    this.fillColor = DS.glassFill,
    this.borderColor = DS.glassBorder,
    this.borderWidth = 1.0,
    this.padding = EdgeInsets.zero,
    this.glowShadows = const [],
    this.gradient,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final List<BoxShadow> glowShadows;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: gradient == null ? fillColor : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: glowShadows,
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tap Scale Button — scale + bounce 애니메이션
// ─────────────────────────────────────────────────────────────────────────────

class TapScaleButton extends StatefulWidget {
  const TapScaleButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.93,
    this.duration = const Duration(milliseconds: 100),
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;

  @override
  State<TapScaleButton> createState() => _TapScaleButtonState();
}

class _TapScaleButtonState extends State<TapScaleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();
  void _onTapUp(TapUpDetails _) => _ctrl.reverse();
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing Live Dot
// ─────────────────────────────────────────────────────────────────────────────

class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key, this.color = DS.homeRed, this.size = 8.0});
  final Color color;
  final double size;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: _pulse.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _pulse.value * 0.6),
              blurRadius: widget.size * 1.5,
              spreadRadius: widget.size * 0.3,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Score Number — AnimatedSwitcher + scale flash
// ─────────────────────────────────────────────────────────────────────────────

class AnimatedScore extends StatelessWidget {
  const AnimatedScore({
    super.key,
    required this.score,
    required this.color,
    this.fontSize = 72.0,
  });

  final int score;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: Tween<double>(begin: 1.35, end: 1.0).animate(
          CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        ),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Text(
        '$score',
        key: ValueKey(score),
        style: DSText.bebasHuge(color: color, size: fontSize),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide-in list item animation
// ─────────────────────────────────────────────────────────────────────────────

class SlideInItem extends StatefulWidget {
  const SlideInItem({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<SlideInItem> createState() => _SlideInItemState();
}

class _SlideInItemState extends State<SlideInItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(opacity: _fade, child: widget.child),
    );
  }
}
