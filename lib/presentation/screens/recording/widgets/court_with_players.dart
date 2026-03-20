import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../widgets/court/basketball_court.dart';
import '../../../widgets/action_menu/radial_action_menu.dart';
import '../models/player_with_stats.dart';

/// 코트 + 하단 선수 배치 위젯
///
/// 레이아웃:
///   ┌─────────── 코트 ───────────┐
///   │          (슛 차트)          │
///   └────────────────────────────┘
///   [홈1][홈2][홈3][홈4][홈5] | [원정1][원정2][원정3][원정4][원정5]
///
/// 인터랙션:
///   - 선수 탭 → 스탯 에어커맨드 (AST, REB, STL, BLK, TO, FOUL)
///   - 선수 롱프레스+드래그 → 코트에 드롭 → 슈팅 에어커맨드
class CourtWithPlayers extends StatefulWidget {
  const CourtWithPlayers({
    super.key,
    required this.homePlayers,
    required this.awayPlayers,
    required this.onPlayerTap,
    required this.onRadialAction,
    required this.shotMarkers,
    this.homeTeamColor = const Color(0xFFF97316),
    this.awayTeamColor = const Color(0xFF10B981),
    this.onQuickShot,
    this.onDragShot,
    this.homeTeamName,
    this.awayTeamName,
    this.onShotPosition,
  });

  final List<PlayerWithStats> homePlayers;
  final List<PlayerWithStats> awayPlayers;
  final void Function(PlayerWithStats, bool) onPlayerTap;
  final void Function(RadialAction action, PlayerWithStats player, bool isHome)
      onRadialAction;
  final List<ShotMarker> shotMarkers;
  final Color homeTeamColor;
  final Color awayTeamColor;
  final void Function(
          PlayerWithStats player, bool isHome, bool isThreePointer)?
      onQuickShot;
  final void Function(
          PlayerWithStats player, bool isHome, double x, double y, int zone)?
      onDragShot;
  /// 슛 메뉴에서 탭 시 글로벌 위치 + 코트 비율 좌표 전달
  final void Function(Offset globalPosition, double courtRx, double courtRy, int zone)? onShotPosition;
  final String? homeTeamName;
  final String? awayTeamName;

  @override
  State<CourtWithPlayers> createState() => _CourtWithPlayersState();
}

class _CourtWithPlayersState extends State<CourtWithPlayers>
    with SingleTickerProviderStateMixin {
  _ShotMenuInfo? _shotMenu;
  PlayerWithStats? _selectedPlayer;
  bool _selectedIsHome = false;

  late AnimationController _menuAnim;
  late Animation<double> _menuScale;
  late Animation<double> _menuOpacity;

  @override
  void initState() {
    super.initState();
    _menuAnim = AnimationController(
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 60),
      vsync: this,
    );
    _menuScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _menuAnim, curve: Curves.easeOutCubic),
    );
    _menuOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _menuAnim, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hideStatMenu();
    _menuAnim.dispose();
    super.dispose();
  }

  void _dismissShotMenu() {
    _menuAnim.reverse().then((_) {
      if (mounted) setState(() {
        _shotMenu = null;
        _selectedPlayer = null;
      });
    });
  }

  /// 글로벌 좌표에서 코트 로컬 좌표로 변환 후 슛 메뉴 열기
  void _openShotMenuAtGlobalPos(Offset globalPos) {
    // _buildCourt의 LayoutBuilder 컨텍스트 필요 → 코트 RenderBox 찾기
    final courtBox = _courtKey.currentContext?.findRenderObject() as RenderBox?;
    if (courtBox == null || _selectedPlayer == null) return;
    final local = courtBox.globalToLocal(globalPos);
    final cw = courtBox.size.width;
    final ch = courtBox.size.height;
    final rx = (local.dx / cw).clamp(0.0, 1.0);
    final ry = (local.dy / ch).clamp(0.0, 1.0);
    setState(() {
      _shotMenu = _ShotMenuInfo(
        position: local,
        player: _selectedPlayer!,
        isHome: _selectedIsHome,
        isThreePointer: !_isInsideThreePointLine(rx, ry),
        rx: rx,
        ry: ry,
        zone: _calculateZone(rx, ry),
      );
      _selectedPlayer = null;
    });
    _menuAnim.forward(from: 0);
    HapticFeedback.heavyImpact();
  }

  final GlobalKey _courtKey = GlobalKey();

  // ─── 스탯 에어커맨드 (Overlay 기반) ───────────────────────

  OverlayEntry? _statOverlay;

  void _showStatMenu(PlayerWithStats player, bool isHome, Offset globalPos) {
    _hideStatMenu(); // 기존 메뉴 닫기
    // 선수 선택 (코트 탭 시 슛 메뉴용)
    setState(() {
      _selectedPlayer = player;
      _selectedIsHome = isHome;
    });

    final teamColor = isHome ? widget.homeTeamColor : widget.awayTeamColor;
    final actions = RadialAction.sprintTwoActions;
    const menuRadius = 80.0;
    const buttonRadius = 32.0;

    // 화면 크기로 위치 클램프
    final screen = MediaQuery.of(context).size;
    const totalR = menuRadius + buttonRadius + 4;
    final cx = globalPos.dx.clamp(totalR, screen.width - totalR);
    final cy = globalPos.dy.clamp(totalR, screen.height - totalR);

    _statOverlay = OverlayEntry(
      builder: (ctx) => _StatAirCommandOverlay(
        cx: cx,
        cy: cy,
        menuRadius: menuRadius,
        buttonRadius: buttonRadius,
        actions: actions,
        teamColor: teamColor,
        player: player,
        onAction: (action) {
          if (action.id == 'foul') {
            _hideStatMenu();
            setState(() => _selectedPlayer = null);
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) {
                _showFoulSubmenu(player, isHome, globalPos);
              }
            });
          } else {
            _hideStatMenu();
            setState(() => _selectedPlayer = null);
            widget.onRadialAction(action, player, isHome);
          }
        },
        onDismiss: () {
          _hideStatMenu();
        },
        onDismissWithPosition: (globalPos) {
          _hideStatMenu();
          // 에어커맨드 배경 탭 → 코트 위치에 슛 메뉴 바로 열기
          if (_selectedPlayer != null) {
            _openShotMenuAtGlobalPos(globalPos);
          }
        },
      ),
    );

    Overlay.of(context).insert(_statOverlay!);
  }

  /// 파울 서브메뉴 (파울 종류 선택)
  void _showFoulSubmenu(PlayerWithStats player, bool isHome, Offset globalPos) {
    _hideStatMenu();

    final teamColor = isHome ? widget.homeTeamColor : widget.awayTeamColor;
    final actions = RadialAction.foulSubtypeActions;
    const menuRadius = 90.0;
    const buttonRadius = 32.0;

    final screen = MediaQuery.of(context).size;
    const totalR = menuRadius + buttonRadius + 4;
    final cx = globalPos.dx.clamp(totalR, screen.width - totalR);
    final cy = globalPos.dy.clamp(totalR, screen.height - totalR);

    _statOverlay = OverlayEntry(
      builder: (ctx) => _StatAirCommandOverlay(
        cx: cx,
        cy: cy,
        menuRadius: menuRadius,
        buttonRadius: buttonRadius,
        actions: actions,
        teamColor: teamColor,
        player: player,
        onAction: (action) {
          _hideStatMenu();
          widget.onRadialAction(action, player, isHome);
        },
        onDismiss: _hideStatMenu,
      ),
    );

    Overlay.of(context).insert(_statOverlay!);
  }

  void _hideStatMenu() {
    _statOverlay?.remove();
    _statOverlay = null;
  }

  // ─── 3점 라인 판별 ─────────────────────────────────────────

  bool _isInsideThreePointLine(double rx, double ry) {
    final bool isLeftHalf = rx < 0.5;
    final basketRx = isLeftHalf ? 5.25 / 94.0 : 1.0 - 5.25 / 94.0;
    const basketRy = 0.5;
    final cornerBound = 3.0 / 50.0;
    if (ry < cornerBound || ry > 1.0 - cornerBound) return true;
    final dx = (rx - basketRx) * 94.0;
    final dy = (ry - basketRy) * 50.0;
    final dist = math.sqrt(dx * dx + dy * dy);
    return dist < 23.75;
  }

  int _calculateZone(double x, double y) {
    final xZone = x < 0.33 ? 0 : (x < 0.67 ? 1 : 2);
    final yZone = y < 0.33 ? 0 : (y < 0.67 ? 1 : 2);
    return yZone * 3 + xZone + 1;
  }

  // ─── 메인 레이아웃 ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final homeSorted = [...widget.homePlayers]
      ..sort(
          (a, b) => (a.jerseyNumber ?? 999).compareTo(b.jerseyNumber ?? 999));
    final awaySorted = [...widget.awayPlayers]
      ..sort(
          (a, b) => (a.jerseyNumber ?? 999).compareTo(b.jerseyNumber ?? 999));

    return Column(
      children: [
        // 코트 (상단)
        Expanded(child: _buildCourt()),
        // 스타팅 선수 바 (팀명 없이 번호만)
        SizedBox(
          height: 72,
          child: Row(
            children: [
              Expanded(
                child: _buildPlayerBar(
                  players: homeSorted,
                  isHome: true,
                  teamColor: widget.homeTeamColor,
                  teamName: widget.homeTeamName ?? 'HOME',
                ),
              ),
              Container(width: 1, color: AppTheme.borderColor),
              Expanded(
                child: _buildPlayerBar(
                  players: awaySorted,
                  isHome: false,
                  teamColor: widget.awayTeamColor,
                  teamName: widget.awayTeamName ?? 'AWAY',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 선수 가로 바 ──────────────────────────────────────────

  Widget _buildPlayerBar({
    required List<PlayerWithStats> players,
    required bool isHome,
    required Color teamColor,
    required String teamName,
  }) {
    final totalFouls =
        players.fold<int>(0, (s, p) => s + p.stats.personalFouls);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: teamColor.withValues(alpha: 0.4), width: 2),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: players.length,
        itemBuilder: (context, index) {
          return _buildPlayerChip(players[index], isHome, teamColor);
        },
      ),
    );
  }

  // ─── 개별 선수 칩 ─────────────────────────────────────────
  // onTap → 스탯 에어커맨드 (Overlay)
  // LongPress+Drag → 코트로 드래그 → 슈팅 에어커맨드

  Widget _buildPlayerChip(
      PlayerWithStats player, bool isHome, Color teamColor) {
    final fouls = player.stats.personalFouls;
    final isFouledOut = fouls >= 5;
    final isWarning = fouls == 4;
    final isSelected = _selectedPlayer?.player.id == player.player.id;

    // 파울 색상: 1-3 노란, 4 주황, 5 빨강
    final foulColor = fouls >= 5
        ? AppTheme.errorColor
        : fouls >= 4
            ? Colors.orange
            : fouls >= 1
                ? Colors.amber
                : null;

    // 고정 크기 칩 — 파울 표시는 내부 오버레이
    final chip = Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 메인 칩
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? teamColor
                    : isFouledOut
                        ? AppTheme.errorColor.withValues(alpha: 0.15)
                        : AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : isFouledOut
                          ? AppTheme.errorColor
                          : (isWarning ? AppTheme.foulWarningColor : teamColor),
                  width: isSelected ? 2.5 : (isFouledOut || isWarning ? 2 : 1.5),
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: teamColor.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 2)]
                    : [BoxShadow(color: teamColor.withValues(alpha: 0.2), blurRadius: 4, spreadRadius: -1)],
              ),
              child: Center(
                child: Text(
                  '${player.jerseyNumber ?? '-'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: isSelected ? Colors.white : isFouledOut ? AppTheme.errorColor : teamColor,
                  ),
                ),
              ),
            ),
          ),

          // 좌상단: T/U 뱃지 (칩 내부)
          if (player.stats.technicalFouls > 0 || player.stats.unsportsmanlikeFouls > 0)
            Positioned(
              left: 2,
              top: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (player.stats.technicalFouls > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('T${player.stats.technicalFouls}',
                          style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  if (player.stats.unsportsmanlikeFouls > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.purple[700],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('U${player.stats.unsportsmanlikeFouls}',
                          style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                ],
              ),
            ),

          // 하단 내부: 파울 도트 (칩 안쪽 하단)
          if (fouls > 0)
            Positioned(
              bottom: 3,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(fouls.clamp(0, 5), (i) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 0.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: foulColor,
                    border: Border.all(
                      color: isSelected ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                )),
              ),
            ),
        ],
      ),
    );

    // 탭 → 에어커맨드 (스탯) + 선수 선택 (코트 탭 대기)
    return GestureDetector(
      onTap: () {
        widget.onPlayerTap(player, isHome);
      },
      onTapUp: (details) {
        HapticFeedback.heavyImpact();
        _showStatMenu(player, isHome, details.globalPosition);
      },
      child: chip,
    );
  }

  // ─── 코트 영역 (DragTarget) ────────────────────────────────

  Widget _buildCourt() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cw = constraints.maxWidth;
        final ch = constraints.maxHeight;

        return Stack(
          key: _courtKey,
          clipBehavior: Clip.none,
          children: [
            // 코트 배경
            Positioned.fill(
              child: GestureDetector(
                onTapUp: (details) {
                  if (_shotMenu != null) {
                    _dismissShotMenu();
                    return;
                  }
                  // 선수 선택 후 코트 탭 → 슛 메뉴
                  if (_selectedPlayer != null) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box == null) return;
                    final local = box.globalToLocal(details.globalPosition);
                    final rx = (local.dx / cw).clamp(0.0, 1.0);
                    final ry = (local.dy / ch).clamp(0.0, 1.0);
                    final isThree = !_isInsideThreePointLine(rx, ry);
                    setState(() {
                      _shotMenu = _ShotMenuInfo(
                        position: local,
                        player: _selectedPlayer!,
                        isHome: _selectedIsHome,
                        isThreePointer: isThree,
                        rx: rx,
                        ry: ry,
                        zone: _calculateZone(rx, ry),
                      );
                      _selectedPlayer = null;
                    });
                    _menuAnim.forward(from: 0);
                    HapticFeedback.heavyImpact();
                    return;
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/basketball_court_bg.png',
                            fit: BoxFit.fill,
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                              painter: _NbaFullCourtPainter()),
                        ),
                        for (final m in widget.shotMarkers)
                          Positioned(
                            left: m.x * cw - 8,
                            top: m.y * ch - 8,
                            child: IgnorePointer(
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: m.isMade
                                      ? AppTheme.shotMadeColor
                                          .withValues(alpha: 0.8)
                                      : AppTheme.shotMissedColor
                                          .withValues(alpha: 0.8),
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                                child: m.isThreePointer
                                    ? const Center(
                                        child: Text('3',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight:
                                                    FontWeight.bold)))
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 슈팅 에어커맨드 (코트 탭 후)
            if (_shotMenu != null) _buildShotAirCommand(cw, ch),
          ]);
      },
    );
  }

  // ─── 드롭 핸들러 ───────────────────────────────────────────

  void _handleDrop(
      _PlayerDragData data, Offset dropPos, double cw, double ch) {
    final rx = (dropPos.dx / cw).clamp(0.0, 1.0);
    final ry = (dropPos.dy / ch).clamp(0.0, 1.0);
    final zone = _calculateZone(rx, ry);
    final isThree = !_isInsideThreePointLine(rx, ry);

    widget.onPlayerTap(data.player, data.isHome);

    setState(() {
      _shotMenu = _ShotMenuInfo(
        position: dropPos,
        player: data.player,
        isHome: data.isHome,
        isThreePointer: isThree,
        rx: rx,
        ry: ry,
        zone: zone,
      );
    });
    _menuAnim.forward(from: 0);
  }

  // ─── 슈팅 에어커맨드 (드롭 후, 원형 3버튼) ─────────────────

  Widget _buildShotAirCommand(double cw, double ch) {
    final m = _shotMenu!;
    final isThree = m.isThreePointer;
    final ptLabel = isThree ? '3점' : '2점';

    const menuR = 80.0;
    const btnR = 40.0;
    const totalR = menuR + btnR + 4;

    final cx = m.position.dx.clamp(totalR, cw - totalR);
    final cy = m.position.dy.clamp(totalR, ch - totalR);

    final ptColor = isThree ? const Color(0xFF8B5CF6) : const Color(0xFFF97316);

    return Stack(
      children: [
        // 배경 탭 → 닫기
        Positioned.fill(
          child: GestureDetector(
            onTap: _dismissShotMenu,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.black.withValues(alpha: 0.08)),
          ),
        ),
        // 반원형 에어커맨드: [점수 | FT]
        AnimatedBuilder(
          animation: _menuScale,
          builder: (context, _) => Positioned(
            left: cx - 80,
            top: cy - 44,
            child: Transform.scale(
              scale: _menuScale.value,
              child: Opacity(
                opacity: _menuOpacity.value,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 왼쪽: 점수 (2점 or 3점)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        final courtBox = _courtKey.currentContext?.findRenderObject() as RenderBox?;
                        if (courtBox != null) {
                          widget.onShotPosition?.call(
                            courtBox.localToGlobal(m.position),
                            m.rx * 100, m.ry * 100, m.zone,
                          );
                        }
                        _dismissShotMenu();
                        final action = isThree
                            ? RadialAction.threePoint
                            : RadialAction.twoPoint;
                        widget.onRadialAction(action, m.player, m.isHome);
                      },
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(38),
                          ),
                          color: ptColor,
                          boxShadow: [
                            BoxShadow(
                              color: ptColor.withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sports_basketball,
                                  color: Colors.white, size: 22),
                              Text(
                                ptLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // 오른쪽: 자유투
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        final courtBox = _courtKey.currentContext?.findRenderObject() as RenderBox?;
                        if (courtBox != null) {
                          widget.onShotPosition?.call(
                            courtBox.localToGlobal(m.position),
                            m.rx * 100, m.ry * 100, m.zone,
                          );
                        }
                        _dismissShotMenu();
                        widget.onRadialAction(
                            RadialAction.freeThrow, m.player, m.isHome);
                      },
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(38),
                          ),
                          color: const Color(0xFF10B981),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle_outlined,
                                  color: Colors.white, size: 22),
                              Text(
                                'FT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 스탯 에어커맨드 오버레이 (Overlay 기반) ────────────────────

class _StatAirCommandOverlay extends StatefulWidget {
  const _StatAirCommandOverlay({
    required this.cx,
    required this.cy,
    required this.menuRadius,
    required this.buttonRadius,
    required this.actions,
    required this.teamColor,
    required this.player,
    required this.onAction,
    required this.onDismiss,
    this.onDismissWithPosition,
  });

  final double cx, cy;
  final double menuRadius, buttonRadius;
  final List<RadialAction> actions;
  final Color teamColor;
  final PlayerWithStats player;
  final void Function(RadialAction) onAction;
  final VoidCallback onDismiss;
  /// 배경 탭 시 글로벌 위치 전달 (코트 탭 → 슛 메뉴)
  final void Function(Offset globalPosition)? onDismissWithPosition;

  @override
  State<_StatAirCommandOverlay> createState() =>
      _StatAirCommandOverlayState();
}

class _StatAirCommandOverlayState extends State<_StatAirCommandOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutBack),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _dismiss() {
    _anim.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalR = widget.menuRadius + widget.buttonRadius + 4;

    return Stack(
      children: [
        // 배경 탭 → 닫기 (위치 전달)
        Positioned.fill(
          child: GestureDetector(
            onTapUp: (details) {
              if (widget.onDismissWithPosition != null) {
                _anim.reverse().then((_) {
                  widget.onDismissWithPosition!(details.globalPosition);
                });
              } else {
                _dismiss();
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.black.withValues(alpha: 0.15)),
          ),
        ),
        // 메뉴
        AnimatedBuilder(
          animation: _scale,
          builder: (context, _) => Positioned(
            left: widget.cx - totalR,
            top: widget.cy - totalR,
            child: Transform.scale(
              scale: _scale.value,
              child: Opacity(
                opacity: _opacity.value,
                child: SizedBox(
                  width: totalR * 2,
                  height: totalR * 2,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 중앙 투명 (선수 칩 반전 효과로 대체)
                      // 방사형 액션 버튼
                      ...List.generate(widget.actions.length, (i) {
                        final action = widget.actions[i];
                        final angle = -math.pi / 2 +
                            (2 * math.pi / widget.actions.length) * i;
                        final bx = totalR +
                            widget.menuRadius * math.cos(angle) -
                            widget.buttonRadius;
                        final by = totalR +
                            widget.menuRadius * math.sin(angle) -
                            widget.buttonRadius;

                        return Positioned(
                          left: bx,
                          top: by,
                          child: GestureDetector(
                            onTap: () {
                              _dismiss();
                              widget.onAction(action);
                            },
                            child: Container(
                              width: widget.buttonRadius * 2,
                              height: widget.buttonRadius * 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: action.color,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        action.color.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  action.label,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: widget.buttonRadius * 0.42,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 내부 모델 ────────────────────────────────────────────────

class _PlayerDragData {
  final PlayerWithStats player;
  final bool isHome;
  const _PlayerDragData({required this.player, required this.isHome});
}

class _ShotMenuInfo {
  final Offset position;
  final PlayerWithStats player;
  final bool isHome;
  final bool isThreePointer;
  final double rx, ry;
  final int zone;
  const _ShotMenuInfo({
    required this.position,
    required this.player,
    required this.isHome,
    required this.isThreePointer,
    required this.rx,
    required this.ry,
    required this.zone,
  });
}

// ─── NBA 규격 풀코트 라인 페인터 ─────────────────────────────
class _NbaFullCourtPainter extends CustomPainter {
  static const _courtL = 94.0;
  static const _courtW = 50.0;
  static const _basketFromBaseline = 5.25;
  static const _keyLength = 19.0;
  static const _keyWidth = 16.0;
  static const _ftCircleR = 6.0;
  static const _threeArcR = 23.75;
  static const _cornerThreeFromSideline = 3.0;
  static const _restrictedR = 4.0;
  static const _centerCircleR = 6.0;
  static const _backboardFromBaseline = 4.0;
  static const _rimR = 0.75;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const pad = 2.0;
    final sx = (w - 2 * pad) / _courtL;
    final sy = (h - 2 * pad) / _courtW;

    Offset ft2px(double fx, double fy) =>
        Offset(pad + fx * sx, pad + fy * sy);

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final thick = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rimPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRect(
        Rect.fromLTWH(pad, pad, w - 2 * pad, h - 2 * pad), thick);

    final mid = ft2px(_courtL / 2, 0);
    final midBot = ft2px(_courtL / 2, _courtW);
    canvas.drawLine(mid, midBot, thick);

    final center = ft2px(_courtL / 2, _courtW / 2);
    final ccRx = _centerCircleR * sx;
    final ccRy = _centerCircleR * sy;
    canvas.drawOval(
        Rect.fromCenter(
            center: center, width: ccRx * 2, height: ccRy * 2),
        line);

    _drawHalf(canvas, sx, sy, pad, w, h, line, dash, rimPaint,
        isLeft: true);
    _drawHalf(canvas, sx, sy, pad, w, h, line, dash, rimPaint,
        isLeft: false);
  }

  void _drawHalf(Canvas canvas, double sx, double sy, double pad, double w,
      double h, Paint line, Paint dash, Paint rimPaint,
      {required bool isLeft}) {
    final bx =
        isLeft ? _basketFromBaseline : _courtL - _basketFromBaseline;
    final by = _courtW / 2;
    final basketPx = Offset(pad + bx * sx, pad + by * sy);
    final blX = isLeft ? pad : w - pad;

    final keyLenPx = _keyLength * sx;
    final keyLeft = isLeft ? pad : w - pad - keyLenPx;
    final keyTop = pad + (_courtW / 2 - _keyWidth / 2) * sy;
    canvas.drawRect(
        Rect.fromLTWH(keyLeft, keyTop, keyLenPx, _keyWidth * sy), line);

    final ftCenterX =
        isLeft ? pad + _keyLength * sx : w - pad - _keyLength * sx;
    final ftCenter = Offset(ftCenterX, pad + by * sy);
    final ftRx = _ftCircleR * sx;
    final ftRy = _ftCircleR * sy;
    final ftRect = Rect.fromCenter(
        center: ftCenter, width: ftRx * 2, height: ftRy * 2);

    if (isLeft) {
      canvas.drawArc(ftRect, -math.pi / 2, math.pi, false, line);
      canvas.drawArc(ftRect, math.pi / 2, math.pi, false, dash);
    } else {
      canvas.drawArc(ftRect, math.pi / 2, -math.pi, false, line);
      canvas.drawArc(ftRect, -math.pi / 2, -math.pi, false, dash);
    }

    final cornerTopY = pad + _cornerThreeFromSideline * sy;
    final cornerBotY = h - pad - _cornerThreeFromSideline * sy;
    final arcRx = _threeArcR * sx;
    final arcRy = _threeArcR * sy;

    final dyTopFt = _cornerThreeFromSideline - _courtW / 2;
    final sinParam = dyTopFt / _threeArcR;

    if (sinParam.abs() < 1.0) {
      final tTop = math.asin(sinParam);
      final tBot = -tTop;
      final crossDxFt = _threeArcR * math.cos(tTop);
      final crossXft = isLeft ? bx + crossDxFt : bx - crossDxFt;
      final crossTopPx = Offset(pad + crossXft * sx, cornerTopY);
      final crossBotPx = Offset(pad + crossXft * sx, cornerBotY);

      canvas.drawLine(Offset(blX, cornerTopY), crossTopPx, line);
      canvas.drawLine(Offset(blX, cornerBotY), crossBotPx, line);

      final arcRect = Rect.fromCenter(
          center: basketPx, width: arcRx * 2, height: arcRy * 2);

      if (isLeft) {
        final startAngle = tTop;
        final sweepAngle = tBot - tTop;
        canvas.drawArc(arcRect, startAngle, sweepAngle, false, line);
      } else {
        final startAngle = math.pi - tTop;
        final sweepAngle = -(tBot - tTop);
        canvas.drawArc(arcRect, startAngle, sweepAngle, false, line);
      }
    }

    final raRx = _restrictedR * sx;
    final raRy = _restrictedR * sy;
    final raRect = Rect.fromCenter(
        center: basketPx, width: raRx * 2, height: raRy * 2);
    if (isLeft) {
      canvas.drawArc(raRect, -math.pi / 2, math.pi, false, dash);
    } else {
      canvas.drawArc(raRect, math.pi / 2, -math.pi, false, dash);
    }

    final bbXft = isLeft
        ? _backboardFromBaseline
        : _courtL - _backboardFromBaseline;
    final bbPx = pad + bbXft * sx;
    final bbHalf = 3.0 * sy;
    canvas.drawLine(Offset(bbPx, basketPx.dy - bbHalf),
        Offset(bbPx, basketPx.dy + bbHalf), line);

    final rRx = (_rimR * sx).clamp(3.0, 8.0);
    final rRy = (_rimR * sy).clamp(3.0, 8.0);
    canvas.drawOval(
        Rect.fromCenter(
            center: basketPx, width: rRx * 2, height: rRy * 2),
        rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── 레거시 export ───────────────────────────────────────────

class PlayerCourtIcon extends StatelessWidget {
  const PlayerCourtIcon({
    super.key,
    required this.player,
    required this.isHome,
    required this.onTap,
    required this.onRadialAction,
    this.teamColor,
    this.size = 40,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  final PlayerWithStats player;
  final bool isHome;
  final VoidCallback onTap;
  final void Function(RadialAction action) onRadialAction;
  final Color? teamColor;
  final double size;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  @override
  Widget build(BuildContext context) {
    final color = teamColor ??
        (isHome ? AppTheme.homeTeamColor : AppTheme.awayTeamColor);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.5), width: 2),
        ),
        child: Center(
          child: Text(
            '${player.player.jerseyNumber ?? '-'}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: size * 0.35,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class SimpleCourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(
        Rect.fromLTWH(10, 10, size.width - 20, size.height - 20), paint);
    canvas.drawLine(Offset(size.width / 2, 10),
        Offset(size.width / 2, size.height - 10), paint);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), 50, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
