// ─── Court Layer Widgets ──────────────────────────────────────────────────────
// Court background painter, player dots, radial menu overlay.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/bdr_design_system.dart';
import '../event_definitions.dart';
import '../recorder_state.dart';

// ─── Radial Menu Target (data class) ─────────────────────────────────────────

/// 라디얼 메뉴 대상 (탭된 선수 정보)
class RadialMenuTarget {
  const RadialMenuTarget({
    required this.player,
    required this.teamSide,
    required this.screenCenter,
  });
  final Map<String, dynamic> player;
  final String teamSide;
  final Offset screenCenter;
}

// ─── Full Court Dark Painter ──────────────────────────────────────────────────

class FullCourtDarkPainter extends CustomPainter {
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    double cx(double ft) => ft / 94.0 * w;
    double cy(double ft) => ft / 50.0 * h;

    // 바닥 그라디언트
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [Color(0xFF1C1008), Color(0xFF241508), Color(0xFF1C1008)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 페인트 영역 fill (4% white)
    final paintFill = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTRB(cx(0), cy(17), cx(19), cy(33)), paintFill);
    canvas.drawRect(Rect.fromLTRB(cx(75), cy(17), cx(94), cy(33)), paintFill);

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final dashed = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // 경계선
    canvas.drawRect(Rect.fromLTRB(cx(0), cy(0), cx(94), cy(50)), line);
    // 하프코트 라인
    canvas.drawLine(Offset(cx(47), cy(0)), Offset(cx(47), cy(50)), line);

    // 페인트 직사각형
    canvas.drawRect(Rect.fromLTRB(cx(0), cy(17), cx(19), cy(33)), line);
    canvas.drawRect(Rect.fromLTRB(cx(75), cy(17), cx(94), cy(33)), line);

    // 자유투 서클 (HOME)
    final ftDiam = cy(12);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx(19), cy(25)), width: ftDiam, height: ftDiam),
      -math.pi / 2, math.pi, false, line,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx(19), cy(25)), width: ftDiam, height: ftDiam),
      math.pi / 2, math.pi, false, dashed,
    );

    // 자유투 서클 (AWAY)
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx(75), cy(25)), width: ftDiam, height: ftDiam),
      math.pi / 2, math.pi, false, line,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx(75), cy(25)), width: ftDiam, height: ftDiam),
      -math.pi / 2, math.pi, false, dashed,
    );

    // 3점 라인 (HOME)
    final homePath = Path()
      ..moveTo(cx(0), cy(3))
      ..lineTo(cx(14), cy(3))
      ..arcToPoint(Offset(cx(14), cy(47)),
          radius: Radius.circular(cx(23.75)), clockwise: true)
      ..lineTo(cx(0), cy(47));
    canvas.drawPath(homePath, line);

    // 3점 라인 (AWAY)
    final awayPath = Path()
      ..moveTo(cx(94), cy(3))
      ..lineTo(cx(80), cy(3))
      ..arcToPoint(Offset(cx(80), cy(47)),
          radius: Radius.circular(cx(23.75)), clockwise: false)
      ..lineTo(cx(94), cy(47));
    canvas.drawPath(awayPath, line);

    // 센터 서클
    canvas.drawCircle(Offset(cx(47), cy(25)), cy(6), line);

    // 바스켓 (림 + 백보드)
    final rim = Paint()
      ..color = const Color(0xFFFF6B35).withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final board = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // HOME basket
    canvas.drawCircle(Offset(cx(5.25), cy(25)), cy(0.75), rim);
    canvas.drawLine(Offset(cx(4.0), cy(22)), Offset(cx(4.0), cy(28)), board);

    // AWAY basket
    canvas.drawCircle(Offset(cx(88.75), cy(25)), cy(0.75), rim);
    canvas.drawLine(Offset(cx(90.0), cy(22)), Offset(cx(90.0), cy(28)), board);
  }
}

// ─── Court Layer ─────────────────────────────────────────────────────────────

class CourtLayer extends StatelessWidget {
  const CourtLayer({
    super.key,
    required this.state,
    required this.playerPositions,
    required this.onPlayerTap,
    this.onCourtTap,
  });

  final RecordingState state;
  final Map<int, Offset> playerPositions;
  final void Function(
    Map<String, dynamic> player,
    String teamSide,
    Offset screenCenter,
  ) onPlayerTap;
  /// 코트 빈 곳 탭 → 슛 선택 메뉴 (가장 가까운 선수 기준)
  final void Function(Offset globalPosition)? onCourtTap;

  static const _homeDefaults = [
    Offset(0.35, 0.50), Offset(0.25, 0.25), Offset(0.15, 0.15),
    Offset(0.20, 0.38), Offset(0.08, 0.50),
  ];
  static const _awayDefaults = [
    Offset(0.65, 0.50), Offset(0.75, 0.25), Offset(0.85, 0.15),
    Offset(0.80, 0.38), Offset(0.92, 0.50),
  ];

  @override
  Widget build(BuildContext context) {
    final homeStarters =
        state.homePlayers.where((p) => p['is_starter'] == true).toList();
    final awayStarters =
        state.awayPlayers.where((p) => p['is_starter'] == true).toList();

    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      return Stack(children: [
        // Court background (빈 곳 탭 → 슛 메뉴)
        GestureDetector(
          onTapUp: onCourtTap != null
              ? (details) => onCourtTap!(details.globalPosition)
              : null,
          child: CustomPaint(size: Size(w, h), painter: FullCourtDarkPainter()),
        ),

        // HOME player dots
        ...List.generate(homeStarters.length, (i) {
          final player = homeStarters[i];
          final id = player['id'] as int;
          final pos = playerPositions[id] ??
              (i < _homeDefaults.length ? _homeDefaults[i] : const Offset(0.2, 0.5));
          return _buildPlayerSlot(w, h, player, 'home', pos, DS.homeRed);
        }),

        // AWAY player dots
        ...List.generate(awayStarters.length, (i) {
          final player = awayStarters[i];
          final id = player['id'] as int;
          final pos = playerPositions[id] ??
              (i < _awayDefaults.length ? _awayDefaults[i] : const Offset(0.8, 0.5));
          return _buildPlayerSlot(w, h, player, 'away', pos, DS.awayBlue);
        }),

        // 경기 상태 오버레이
        if (state.matchStatus == 'scheduled')
          Center(
            child: GlassBox(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                '경기 시작 후 기록 가능',
                style: DSText.jakartaBody(color: DS.textSecondary, size: 13),
              ),
            ),
          ),
        if (state.isCompleted)
          Center(
            child: GlassBox(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              fillColor: DS.success.withValues(alpha: 0.08),
              borderColor: DS.success.withValues(alpha: 0.3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: DS.success, size: 18),
                  const SizedBox(width: 8),
                  Text('경기 종료', style: DSText.jakartaBold(color: DS.success)),
                ],
              ),
            ),
          ),
      ]);
    });
  }

  Widget _buildPlayerSlot(
    double w,
    double h,
    Map<String, dynamic> player,
    String teamSide,
    Offset pos,
    Color teamColor,
  ) {
    const dotRadius = 22.0;
    final playerId = player['id'] as int;

    return Positioned(
      left: pos.dx * w - dotRadius,
      top: pos.dy * h - dotRadius,
      child: Builder(builder: (bCtx) {
        return PlayerDot(
          player: player,
          teamColor: teamColor,
          isDropTarget: false,
          foulCount: state.playerFoulCounts[playerId] ?? 0,
          onTap: () {
            final renderBox = bCtx.findRenderObject() as RenderBox?;
            if (renderBox == null) return;
            final globalCenter = renderBox.localToGlobal(
              const Offset(dotRadius, dotRadius),
            );
            onPlayerTap(player, teamSide, globalCenter);
          },
        );
      }),
    );
  }
}

// ─── Player Dot ───────────────────────────────────────────────────────────────

class PlayerDot extends StatelessWidget {
  const PlayerDot({
    super.key,
    required this.player,
    required this.teamColor,
    this.isDropTarget = false,
    required this.onTap,
    this.foulCount = 0,
  });

  final Map<String, dynamic> player;
  final Color teamColor;
  final bool isDropTarget;
  final VoidCallback onTap;
  final int foulCount;

  @override
  Widget build(BuildContext context) {
    final jerseyNum = '${player['jersey_number'] ?? '?'}';
    final name = (player['name'] as String? ?? '').split(' ').last;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 52,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: teamColor.withValues(alpha: isDropTarget ? 0.5 : 0.25),
                    border: Border.all(
                      color: isDropTarget ? DS.gold : teamColor,
                      width: isDropTarget ? 2.5 : 1.5,
                    ),
                    boxShadow: isDropTarget
                        ? DS.glowGold(intensity: 0.6)
                        : [
                            BoxShadow(
                              color: teamColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                            )
                          ],
                  ),
                  child: Center(
                    child: Text(
                      jerseyNum,
                      style: DSText.bebasSmall(color: DS.textPrimary, size: 18),
                    ),
                  ),
                ),
                // 개인파울 수 뱃지
                if (foulCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: foulCount >= 5 ? DS.error : DS.warning,
                        border: Border.all(color: DS.bg, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '${foulCount}',
                          style: DSText.jakartaLabel(
                            color: Colors.white,
                            size: 9,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              name,
              style: DSText.jakartaLabel(color: DS.textSecondary, size: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Court Radial Menu Overlay ────────────────────────────────────────────────

class CourtRadialMenuOverlay extends StatefulWidget {
  const CourtRadialMenuOverlay({
    super.key,
    required this.target,
    required this.state,
    this.shotOnly = false,
    required this.onDismiss,
    required this.onSelect,
  });

  final RadialMenuTarget target;
  final RecordingState state;
  final bool shotOnly;
  final VoidCallback onDismiss;
  final void Function(EventDef def) onSelect;

  @override
  State<CourtRadialMenuOverlay> createState() =>
      _CourtRadialMenuOverlayState();
}

class _CourtRadialMenuOverlayState extends State<CourtRadialMenuOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  // 라디얼 메뉴에 표시할 이벤트 타입
  static const _shotTypes = ['2pt', '3pt', '1pt'];
  // 탭: 슛 + 스탯 전부 (어시스트/리바운드는 슛 후속 오버레이로 이동)
  static const _allTypes = [
    '2pt', '3pt', '1pt',
    'steal', 'block',
    'turnover', 'foul_personal',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final activeTypes = widget.shotOnly ? _shotTypes : _allTypes;
    final menuDefs = eventDefs
        .where((d) => activeTypes.contains(d.type))
        .toList();

    // Edge clamp
    const r = 140.0;
    final cx = widget.target.screenCenter.dx.clamp(r, screenSize.width - r);
    final cy = widget.target.screenCenter.dy.clamp(r, screenSize.height - r);
    final center = Offset(cx, cy);

    final playerName =
        widget.target.player['name'] as String? ?? '선수';
    final jerseyNum =
        '${widget.target.player['jersey_number'] ?? ''}';

    return Stack(children: [
      // 반투명 배경 (탭으로 닫기)
      Positioned.fill(
        child: GestureDetector(
          onTap: widget.onDismiss,
          child: Container(color: Colors.black.withValues(alpha: 0.25)),
        ),
      ),

      // 라디얼 메뉴
      Positioned(
        left: center.dx - r,
        top: center.dy - r,
        child: ScaleTransition(
          scale: _scale,
          child: SizedBox(
            width: r * 2,
            height: r * 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 중앙 선수 정보
                GlassBox(
                  borderRadius: 999,
                  padding: const EdgeInsets.all(8),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '#$jerseyNum',
                          style: DSText.bebasSmall(
                              color: widget.target.teamSide == 'home'
                                  ? DS.homeRed
                                  : DS.awayBlue,
                              size: 16),
                        ),
                        Text(
                          playerName.split(' ').last,
                          style: DSText.jakartaLabel(
                              color: DS.textSecondary, size: 9),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // 방사형 아이템들
                ...List.generate(menuDefs.length, (i) {
                  final def = menuDefs[i];
                  final angle =
                      -math.pi / 2 + (i * 2 * math.pi / menuDefs.length);
                  const itemR = 110.0;
                  final dx = itemR * math.cos(angle);
                  final dy = itemR * math.sin(angle);
                  const itemSize = 52.0;

                  final isExempt = shotClockExemptTypes.contains(def.type);
                  final canRecord = isExempt
                      ? widget.state.canRecordAlways
                      : widget.state.canRecord;
                  final teamColor =
                      widget.target.teamSide == 'home' ? DS.homeRed : DS.awayBlue;

                  return Positioned(
                    left: r + dx - itemSize / 2,
                    top: r + dy - itemSize / 2,
                    child: RadialStatItem(
                      def: def,
                      teamColor: teamColor,
                      enabled: canRecord,
                      onTap: () => widget.onSelect(def),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    ]);
  }
}

// ─── Radial Stat Item ─────────────────────────────────────────────────────────

class RadialStatItem extends StatelessWidget {
  const RadialStatItem({
    super.key,
    required this.def,
    required this.teamColor,
    required this.enabled,
    required this.onTap,
  });

  final EventDef def;
  final Color teamColor;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScaleButton(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.3,
        child: GlassBox(
          borderRadius: 999,
          fillColor: def.color.withValues(alpha: 0.15),
          borderColor: def.color.withValues(alpha: 0.5),
          glowShadows: enabled ? DS.glowColor(def.color, intensity: 0.4) : [],
          child: SizedBox(
            width: 52,
            height: 52,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(def.icon, color: Colors.white, size: 18),
                const SizedBox(height: 2),
                Text(
                  def.label,
                  style: DSText.jakartaLabel(color: Colors.white, size: 8),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
