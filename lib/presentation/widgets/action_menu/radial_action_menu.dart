import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;

import '../../../core/theme/app_theme.dart';

/// 방사형 에어 커맨드 액션 메뉴
/// 펜 호버 또는 탭으로 활성화되는 빠른 액션 메뉴
class RadialActionMenu extends StatefulWidget {
  const RadialActionMenu({
    super.key,
    required this.actions,
    required this.child,
    this.onActionSelected,
    this.onFoulSubtypeSelected,
    this.menuRadius = 100,
    this.buttonRadius = 26,
    this.centerWidget,
    this.animationDuration = const Duration(milliseconds: 200),
    this.enableHover = true,
    this.hoverDelay = const Duration(milliseconds: 300),
    this.playerFouls = 0,
    this.foulOutLimit = 5,
  });

  /// 표시할 액션 목록
  final List<RadialAction> actions;

  /// 메뉴를 표시할 위젯 (보통 선수 카드)
  final Widget child;

  /// 액션 선택 콜백
  final void Function(RadialAction action)? onActionSelected;

  /// 파울 서브타입 선택 콜백 (FR-012: 파울 서브메뉴)
  final void Function(RadialAction foulSubtype)? onFoulSubtypeSelected;

  /// 메뉴 반지름
  final double menuRadius;

  /// 버튼 반지름
  final double buttonRadius;

  /// 중앙 위젯 (선수 정보 등)
  final Widget? centerWidget;

  /// 애니메이션 지속 시간
  final Duration animationDuration;

  /// 호버 활성화 여부
  final bool enableHover;

  /// 호버 후 메뉴 표시까지 지연
  final Duration hoverDelay;

  /// 현재 선수 파울 수 (파울아웃 비활성화용)
  final int playerFouls;

  /// 파울아웃 한도
  final int foulOutLimit;

  @override
  State<RadialActionMenu> createState() => _RadialActionMenuState();
}

class _RadialActionMenuState extends State<RadialActionMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  OverlayEntry? _overlayEntry;
  bool _isMenuVisible = false;
  Offset _menuPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hideMenu();
    _controller.dispose();
    super.dispose();
  }

  void _showMenu(Offset position) {
    if (_isMenuVisible) return;

    _menuPosition = position;
    _isMenuVisible = true;

    _overlayEntry = OverlayEntry(
      builder: (context) => _RadialMenuOverlay(
        position: _menuPosition,
        actions: widget.actions,
        menuRadius: widget.menuRadius,
        buttonRadius: widget.buttonRadius,
        centerWidget: widget.centerWidget,
        scaleAnimation: _scaleAnimation,
        opacityAnimation: _opacityAnimation,
        onActionSelected: (action) {
          if (action.id == 'foul') {
            // 파울 탭 → 서브메뉴 열기
            _hideMenu();
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) {
                _showFoulSubmenu(_menuPosition);
              }
            });
          } else {
            _hideMenu();
            widget.onActionSelected?.call(action);
          }
        },
        onDismiss: _hideMenu,
        playerFouls: widget.playerFouls,
        foulOutLimit: widget.foulOutLimit,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _controller.forward();
  }

  void _hideMenu() {
    if (!_isMenuVisible) return;

    _controller.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isMenuVisible = false;
    });
  }

  void _handleTap(TapDownDetails details) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = details.localPosition;
    final globalPosition = renderBox.localToGlobal(localPosition);

    if (_isMenuVisible) {
      _hideMenu();
    } else {
      _showMenu(globalPosition);
    }
  }

  void _handleHover(PointerHoverEvent event) {
    if (!widget.enableHover) return;

    // 스타일러스(펜) 감지
    if (event.kind == PointerDeviceKind.stylus) {
      final renderBox = context.findRenderObject() as RenderBox;
      final globalPosition = renderBox.localToGlobal(event.localPosition);

      // 지연 후 메뉴 표시
      Future.delayed(widget.hoverDelay, () {
        if (mounted && !_isMenuVisible) {
          _showMenu(globalPosition);
        }
      });
    }
  }

  /// 파울 서브메뉴 표시 (FR-012: 파울 종류 선택)
  void _showFoulSubmenu(Offset position) {
    if (_isMenuVisible) return;

    final isFouledOut = widget.playerFouls >= widget.foulOutLimit;
    if (isFouledOut) return; // 파울아웃 선수는 서브메뉴 표시 안 함

    _menuPosition = position;
    _isMenuVisible = true;

    _overlayEntry = OverlayEntry(
      builder: (context) => _RadialMenuOverlay(
        position: _menuPosition,
        actions: RadialAction.foulSubtypeActions,
        menuRadius: 90,
        buttonRadius: widget.buttonRadius,
        centerWidget: const Center(
          child: Text(
            'FOUL',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626),
            ),
          ),
        ),
        scaleAnimation: _scaleAnimation,
        opacityAnimation: _opacityAnimation,
        onActionSelected: (action) {
          _hideMenu();
          widget.onFoulSubtypeSelected?.call(action);
        },
        onDismiss: _hideMenu,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerHover: _handleHover,
      child: GestureDetector(
        onTapDown: _handleTap,
        child: widget.child,
      ),
    );
  }
}

/// 방사형 액션 데이터
class RadialAction {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final bool isPrimary;

  const RadialAction({
    required this.id,
    required this.label,
    required this.icon,
    this.color = AppTheme.primaryColor,
    this.isPrimary = false,
  });

  // ── 슛 플로우 액션 (성공/실패 다이얼로그 → 어시스트/리바운드 연결) ──
  static const twoPoint = RadialAction(
    id: '2pt',
    label: '2점',
    icon: Icons.sports_basketball,
    color: Color(0xFFF97316),
    isPrimary: true,
  );

  static const threePoint = RadialAction(
    id: '3pt',
    label: '3점',
    icon: Icons.star,
    color: Color(0xFF8B5CF6),
    isPrimary: true,
  );

  static const freeThrow = RadialAction(
    id: 'ft',
    label: '자유투',
    icon: Icons.circle_outlined,
    color: Color(0xFF10B981),
  );

  // 프리셋 액션들 (레거시 — 성공/실패 분리)
  static const twoPointMade = RadialAction(
    id: '2pt_made',
    label: '2점 성공',
    icon: Icons.sports_basketball,
    color: AppTheme.shotMadeColor,
    isPrimary: true,
  );

  static const twoPointMissed = RadialAction(
    id: '2pt_missed',
    label: '2점 실패',
    icon: Icons.sports_basketball_outlined,
    color: AppTheme.shotMissedColor,
  );

  static const threePointMade = RadialAction(
    id: '3pt_made',
    label: '3점 성공',
    icon: Icons.star,
    color: AppTheme.shotMadeColor,
    isPrimary: true,
  );

  static const threePointMissed = RadialAction(
    id: '3pt_missed',
    label: '3점 실패',
    icon: Icons.star_outline,
    color: AppTheme.shotMissedColor,
  );

  static const freeThrowMade = RadialAction(
    id: 'ft_made',
    label: '자유투 성공',
    icon: Icons.check_circle,
    color: AppTheme.shotMadeColor,
  );

  static const freeThrowMissed = RadialAction(
    id: 'ft_missed',
    label: '자유투 실패',
    icon: Icons.cancel,
    color: AppTheme.shotMissedColor,
  );

  static const assist = RadialAction(
    id: 'assist',
    label: 'AST',
    icon: Icons.assistant_photo,
    color: Color(0xFF6366F1), // 인디고
  );

  static const rebound = RadialAction(
    id: 'rebound',
    label: 'REB',
    icon: Icons.replay,
    color: AppTheme.primaryColor,
  );

  static const offensiveRebound = RadialAction(
    id: 'offensive_rebound',
    label: 'OREB',
    icon: Icons.arrow_upward,
    color: Color(0xFFEF4444), // 빨강
  );

  static const defensiveRebound = RadialAction(
    id: 'defensive_rebound',
    label: 'DREB',
    icon: Icons.arrow_downward,
    color: Color(0xFF3B82F6), // 파랑
  );

  static const steal = RadialAction(
    id: 'steal',
    label: 'STL',
    icon: Icons.flash_on,
    color: Color(0xFF10B981), // 에메랄드
  );

  static const block = RadialAction(
    id: 'block',
    label: 'BLK',
    icon: Icons.shield,
    color: Color(0xFF0EA5E9), // 스카이블루
  );

  static const turnover = RadialAction(
    id: 'turnover',
    label: 'TO',
    icon: Icons.swap_horiz,
    color: Color(0xFFF59E0B), // 앰버
  );

  static const foul = RadialAction(
    id: 'foul',
    label: 'FOUL',
    icon: Icons.front_hand,
    color: Color(0xFFDC2626), // 레드
  );

  static const substitution = RadialAction(
    id: 'substitution',
    label: '교체',
    icon: Icons.swap_horiz,
    color: AppTheme.secondaryColor,
  );

  // ═══════════════════════════════════════════════════════════════
  // 파울 서브타입 액션들 (FR-012: 파울 서브메뉴)
  // ═══════════════════════════════════════════════════════════════

  static const foulOffensive = RadialAction(
    id: 'foul_offensive',
    label: 'OFFNS',
    icon: Icons.front_hand,
    color: Color(0xFFF97316), // 주황
  );

  static const foulPersonal = RadialAction(
    id: 'foul_personal',
    label: 'DEFNS',
    icon: Icons.front_hand,
    color: Color(0xFF3B82F6), // 파랑
  );

  static const foulTechnical = RadialAction(
    id: 'foul_technical',
    label: 'TECH',
    icon: Icons.front_hand,
    color: Color(0xFF6B7280), // 회색
  );

  static const foulUnsportsmanlike = RadialAction(
    id: 'foul_unsportsmanlike',
    label: 'UNSP',
    icon: Icons.front_hand,
    color: Color(0xFF8B5CF6), // 보라
  );

  static const foulFlagrant1 = RadialAction(
    id: 'foul_flagrant1',
    label: 'FLAG1',
    icon: Icons.front_hand,
    color: Color(0xFFDC2626), // 빨강
  );

  static const foulFlagrant2 = RadialAction(
    id: 'foul_flagrant2',
    label: 'FLAG2',
    icon: Icons.front_hand,
    color: Color(0xFF7F1D1D), // 진빨강
  );

  /// 슛 관련 액션 목록
  static const List<RadialAction> shotActions = [
    twoPointMade,
    twoPointMissed,
    threePointMade,
    threePointMissed,
    freeThrowMade,
    freeThrowMissed,
  ];

  /// 기타 스탯 액션 목록
  static const List<RadialAction> statActions = [
    foul,               // 12시 (최상단)
    offensiveRebound,   // 시계방향 2번
    defensiveRebound,   // 3번
    assist,             // 4번
    steal,              // 5번
    block,              // 6번
    turnover,           // 7번
  ];

  /// 전체 액션 목록 (기본 — 레거시 유지)
  static const List<RadialAction> defaultActions = [
    twoPointMade,
    threePointMade,
    rebound,
    assist,
    foul,
    substitution,
  ];

  /// Sprint 2 에어커맨드 액션 (FR-012)
  /// 파울(12시) → OREB → DREB → AST → STL → BLK → TO (시계방향)
  /// 선수 탭 에어커맨드 (슛 제외 — 슛은 코트 탭으로 분리)
  static const List<RadialAction> sprintTwoActions = [
    steal,              // index 0 → 12시
    block,              // index 1 → 약 3시
    turnover,           // index 2 → 약 6시
    foul,               // index 3 → 약 9시
  ];

  /// 코트 위치 탭 시 표시할 슛 메뉴
  static const List<RadialAction> shotFlowActions = [
    twoPoint,           // 2점 → 성공/실패 → 어시스트/리바운드
    threePoint,         // 3점 → 성공/실패 → 어시스트/리바운드
    freeThrow,          // 자유투
  ];

  /// 파울 서브메뉴 액션 목록 (간소화: 플래그런트 제거)
  /// 테크니컬(12시) → 오펜스 → 디펜스 → U파울
  static const List<RadialAction> foulSubtypeActions = [
    foulTechnical,       // 12시
    foulOffensive,       // 약 3시
    foulPersonal,        // 약 6시
    foulUnsportsmanlike, // 약 9시
  ];
}

/// 오버레이로 표시되는 방사형 메뉴
class _RadialMenuOverlay extends StatelessWidget {
  const _RadialMenuOverlay({
    required this.position,
    required this.actions,
    required this.menuRadius,
    required this.buttonRadius,
    required this.scaleAnimation,
    required this.opacityAnimation,
    required this.onActionSelected,
    required this.onDismiss,
    this.centerWidget,
    this.playerFouls = 0,
    this.foulOutLimit = 5,
  });

  final Offset position;
  final List<RadialAction> actions;
  final double menuRadius;
  final double buttonRadius;
  final Widget? centerWidget;
  final Animation<double> scaleAnimation;
  final Animation<double> opacityAnimation;
  final void Function(RadialAction) onActionSelected;
  final VoidCallback onDismiss;
  final int playerFouls;
  final int foulOutLimit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 배경 터치로 메뉴 닫기
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            child: Container(color: Colors.transparent),
          ),
        ),

        // 메뉴
        Positioned(
          left: position.dx - menuRadius - buttonRadius,
          top: position.dy - menuRadius - buttonRadius,
          child: AnimatedBuilder(
            animation: scaleAnimation,
            builder: (context, child) => Transform.scale(
              scale: scaleAnimation.value,
              child: Opacity(
                opacity: opacityAnimation.value,
                child: _buildMenu(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenu(BuildContext context) {
    final totalSize = (menuRadius + buttonRadius) * 2;

    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 중앙 원 (배경)
          Container(
            width: menuRadius * 1.2,
            height: menuRadius * 1.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceColor.withValues(alpha: 0.95),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: centerWidget,
          ),

          // 액션 버튼들
          ...List.generate(actions.length, (index) {
            final action = actions[index];
            final angle = _calculateAngle(index, actions.length);
            final x = menuRadius * math.cos(angle);
            final y = menuRadius * math.sin(angle);

            // 파울 버튼 비활성화 처리 (5파울 이상)
            final isFoulButton = action.id == 'foul';
            final isFouledOut = playerFouls >= foulOutLimit;
            final isDisabled = isFoulButton && isFouledOut;

            return Positioned(
              left: totalSize / 2 + x - buttonRadius,
              top: totalSize / 2 + y - buttonRadius,
              child: _RadialActionButton(
                action: action,
                radius: buttonRadius,
                onTap: isDisabled ? () {} : () => onActionSelected(action),
                isDisabled: isDisabled,
                disabledLabel: 'OUT',
              ),
            );
          }),
        ],
      ),
    );
  }

  double _calculateAngle(int index, int total) {
    // 위쪽부터 시계 방향으로 배치
    const startAngle = -math.pi / 2;
    final angleStep = (2 * math.pi) / total;
    return startAngle + (index * angleStep);
  }
}

/// 방사형 메뉴의 개별 액션 버튼
class _RadialActionButton extends StatelessWidget {
  const _RadialActionButton({
    required this.action,
    required this.radius,
    required this.onTap,
    this.isDisabled = false,
    this.disabledLabel,
  });

  final RadialAction action;
  final double radius;
  final VoidCallback onTap;
  final bool isDisabled;
  final String? disabledLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDisabled ? Colors.grey[600]! : action.color;
    final effectiveOpacity = isDisabled ? 0.4 : 1.0;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: effectiveOpacity,
        child: Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: effectiveColor,
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: effectiveColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
            border: action.isPrimary
                ? Border.all(color: Colors.white, width: 3)
                : null,
          ),
          child: Center(
            child: Text(
              isDisabled ? (disabledLabel ?? action.label) : action.label,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.42,
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
  }
}

/// 호버 가능한 선수 카드 래퍼
class HoverablePlayerCard extends StatefulWidget {
  const HoverablePlayerCard({
    super.key,
    required this.child,
    required this.actions,
    required this.onActionSelected,
    this.onFoulSubtypeSelected,
    this.playerName,
    this.jerseyNumber,
    this.playerFouls = 0,
    this.foulOutLimit = 5,
  });

  final Widget child;
  final List<RadialAction> actions;
  final void Function(RadialAction action) onActionSelected;
  final void Function(RadialAction foulSubtype)? onFoulSubtypeSelected;
  final String? playerName;
  final String? jerseyNumber;
  final int playerFouls;
  final int foulOutLimit;

  @override
  State<HoverablePlayerCard> createState() => _HoverablePlayerCardState();
}

class _HoverablePlayerCardState extends State<HoverablePlayerCard> {
  @override
  Widget build(BuildContext context) {
    return RadialActionMenu(
      actions: widget.actions,
      onActionSelected: widget.onActionSelected,
      onFoulSubtypeSelected: widget.onFoulSubtypeSelected,
      playerFouls: widget.playerFouls,
      foulOutLimit: widget.foulOutLimit,
      centerWidget: widget.playerName != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.jerseyNumber != null)
                  Text(
                    '#${widget.jerseyNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                Text(
                  widget.playerName!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : null,
      child: widget.child,
    );
  }
}
