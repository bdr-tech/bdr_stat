import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../widgets/action_menu/radial_action_menu.dart';
import '../../../widgets/court/basketball_court.dart' show ShotMarker;
import '../models/player_with_stats.dart';

/// 강화된 코트 위젯 - 선수 아이콘과 드래그앤드롭 교체 지원
class EnhancedCourtWithPlayers extends StatefulWidget {
  const EnhancedCourtWithPlayers({
    super.key,
    required this.homePlayers,
    required this.awayPlayers,
    required this.onPlayerTap,
    required this.onRadialAction,
    required this.onCourtTap,
    required this.shotMarkers,
    required this.onSubstitution,
    this.homeTeamColor = const Color(0xFFF97316),
    this.awayTeamColor = const Color(0xFF10B981),
  });

  final List<PlayerWithStats> homePlayers;
  final List<PlayerWithStats> awayPlayers;
  final void Function(PlayerWithStats, bool) onPlayerTap;
  final void Function(RadialAction action, PlayerWithStats player, bool isHome) onRadialAction;
  final void Function(double x, double y, int zone) onCourtTap;
  final List<ShotMarker> shotMarkers;
  final void Function(PlayerWithStats subOut, PlayerWithStats subIn, bool isHome) onSubstitution;
  final Color homeTeamColor;
  final Color awayTeamColor;

  static const double _playerIconSize = 72.0;

  // 홈팀 선수 위치 (코트 왼쪽) - 비율로 지정 (0.0 ~ 1.0)
  static const List<Offset> _homePositions = [
    Offset(0.12, 0.50), // 포인트 가드 (중앙)
    Offset(0.22, 0.25), // 슈팅 가드 (위)
    Offset(0.22, 0.75), // 스몰 포워드 (아래)
    Offset(0.08, 0.30), // 파워 포워드 (위쪽 측면)
    Offset(0.08, 0.70), // 센터 (아래쪽 측면)
  ];

  // 원정팀 선수 위치 (코트 오른쪽)
  static const List<Offset> _awayPositions = [
    Offset(0.88, 0.50), // 포인트 가드 (중앙)
    Offset(0.78, 0.25), // 슈팅 가드 (위)
    Offset(0.78, 0.75), // 스몰 포워드 (아래)
    Offset(0.92, 0.30), // 파워 포워드 (위쪽 측면)
    Offset(0.92, 0.70), // 센터 (아래쪽 측면)
  ];

  @override
  State<EnhancedCourtWithPlayers> createState() => _EnhancedCourtWithPlayersState();
}

class _EnhancedCourtWithPlayersState extends State<EnhancedCourtWithPlayers> {
  // 향후 드래그 교체 기능용 (현재 미사용)
  // PlayerWithStats? _draggedPlayer;
  // bool? _draggedPlayerIsHome;
  // Offset? _dragPosition;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // 코트 배경
                Positioned.fill(
                  child: CustomPaint(
                    painter: _EnhancedCourtPainter(),
                  ),
                ),

                // 코트 터치 영역 (슛 기록용)
                Positioned.fill(
                  child: GestureDetector(
                    onTapUp: (details) {
                      final x = details.localPosition.dx / width;
                      final y = details.localPosition.dy / height;
                      final zone = _calculateZone(x, y);
                      widget.onCourtTap(x, y, zone);
                    },
                    behavior: HitTestBehavior.translucent,
                  ),
                ),

                // 슛 마커들
                for (final marker in widget.shotMarkers)
                  Positioned(
                    left: marker.x * width - 10,
                    top: marker.y * height - 10,
                    child: _ShotMarkerWidget(marker: marker),
                  ),

                // 홈팀 선수 아이콘 (드래그 타겟)
                for (var i = 0; i < widget.homePlayers.length && i < EnhancedCourtWithPlayers._homePositions.length; i++)
                  Positioned(
                    left: (EnhancedCourtWithPlayers._homePositions[i].dx * width - EnhancedCourtWithPlayers._playerIconSize / 2).clamp(0, width - EnhancedCourtWithPlayers._playerIconSize),
                    top: (EnhancedCourtWithPlayers._homePositions[i].dy * height - EnhancedCourtWithPlayers._playerIconSize / 2).clamp(0, height - EnhancedCourtWithPlayers._playerIconSize),
                    child: _DraggableCourtPlayerIcon(
                      player: widget.homePlayers[i],
                      isHome: true,
                      teamColor: widget.homeTeamColor,
                      size: EnhancedCourtWithPlayers._playerIconSize,
                      onTap: () => widget.onPlayerTap(widget.homePlayers[i], true),
                      onRadialAction: (action) => widget.onRadialAction(action, widget.homePlayers[i], true),
                      onAcceptSubstitution: (benchPlayer) {
                        widget.onSubstitution(widget.homePlayers[i], benchPlayer, true);
                      },
                    ),
                  ),

                // 원정팀 선수 아이콘 (드래그 타겟)
                for (var i = 0; i < widget.awayPlayers.length && i < EnhancedCourtWithPlayers._awayPositions.length; i++)
                  Positioned(
                    left: (EnhancedCourtWithPlayers._awayPositions[i].dx * width - EnhancedCourtWithPlayers._playerIconSize / 2).clamp(0, width - EnhancedCourtWithPlayers._playerIconSize),
                    top: (EnhancedCourtWithPlayers._awayPositions[i].dy * height - EnhancedCourtWithPlayers._playerIconSize / 2).clamp(0, height - EnhancedCourtWithPlayers._playerIconSize),
                    child: _DraggableCourtPlayerIcon(
                      player: widget.awayPlayers[i],
                      isHome: false,
                      teamColor: widget.awayTeamColor,
                      size: EnhancedCourtWithPlayers._playerIconSize,
                      onTap: () => widget.onPlayerTap(widget.awayPlayers[i], false),
                      onRadialAction: (action) => widget.onRadialAction(action, widget.awayPlayers[i], false),
                      onAcceptSubstitution: (benchPlayer) {
                        widget.onSubstitution(widget.awayPlayers[i], benchPlayer, false);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _calculateZone(double x, double y) {
    // 9구역 시스템 (3x3)
    final xZone = x < 0.33 ? 0 : (x < 0.67 ? 1 : 2);
    final yZone = y < 0.33 ? 0 : (y < 0.67 ? 1 : 2);
    return yZone * 3 + xZone + 1;
  }
}

/// 드래그 타겟 기능이 있는 코트 선수 아이콘
class _DraggableCourtPlayerIcon extends StatefulWidget {
  const _DraggableCourtPlayerIcon({
    required this.player,
    required this.isHome,
    required this.teamColor,
    required this.size,
    required this.onTap,
    required this.onRadialAction,
    required this.onAcceptSubstitution,
  });

  final PlayerWithStats player;
  final bool isHome;
  final Color teamColor;
  final double size;
  final VoidCallback onTap;
  final void Function(RadialAction action) onRadialAction;
  final void Function(PlayerWithStats benchPlayer) onAcceptSubstitution;

  @override
  State<_DraggableCourtPlayerIcon> createState() => _DraggableCourtPlayerIconState();
}

class _DraggableCourtPlayerIconState extends State<_DraggableCourtPlayerIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<PlayerWithStats>(
      onWillAcceptWithDetails: (details) {
        // 벤치 선수만 받을 수 있음
        return !details.data.isOnCourt;
      },
      onAcceptWithDetails: (details) {
        widget.onAcceptSubstitution(details.data);
      },
      onMove: (_) {
        if (!_isHovered) {
          setState(() => _isHovered = true);
        }
      },
      onLeave: (_) {
        if (_isHovered) {
          setState(() => _isHovered = false);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isAccepting = candidateData.isNotEmpty;

        return RadialActionMenu(
          actions: RadialAction.defaultActions,
          onActionSelected: widget.onRadialAction,
          menuRadius: 70,
          buttonRadius: 20,
          centerWidget: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#${widget.player.player.jerseyNumber ?? '-'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: widget.teamColor,
                ),
              ),
              Text(
                widget.player.name.length > 6
                    ? '${widget.player.name.substring(0, 6)}...'
                    : widget.player.name,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isAccepting ? widget.size * 1.2 : widget.size,
              height: isAccepting ? widget.size * 1.2 : widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.teamColor,
                border: Border.all(
                  color: isAccepting ? Colors.white : Colors.white.withValues(alpha: 0.5),
                  width: isAccepting ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.teamColor.withValues(alpha: isAccepting ? 0.6 : 0.4),
                    blurRadius: isAccepting ? 16 : 8,
                    spreadRadius: isAccepting ? 2 : -2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${widget.player.player.jerseyNumber ?? '-'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: widget.size * 0.35,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.player.pointsDisplay,
                    style: TextStyle(
                      fontSize: widget.size * 0.2,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 슛 마커 위젯
class _ShotMarkerWidget extends StatelessWidget {
  const _ShotMarkerWidget({required this.marker});

  final ShotMarker marker;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: marker.isMade
            ? AppTheme.shotMadeColor.withValues(alpha: 0.85)
            : AppTheme.shotMissedColor.withValues(alpha: 0.85),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (marker.isMade ? AppTheme.shotMadeColor : AppTheme.shotMissedColor)
                .withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: marker.isThreePointer
          ? const Center(
              child: Text(
                '3',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}

/// 강화된 코트 페인터
class _EnhancedCourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 배경 그라데이션
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1A1A2E),
          Color(0xFF16213E),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 도트 패턴
    final dotPaint = Paint()..color = const Color(0xFF2A2A4A);
    const dotSpacing = 24.0;
    for (var x = 0.0; x < size.width; x += dotSpacing) {
      for (var y = 0.0; y < size.height; y += dotSpacing) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }

    // 코트 라인
    final linePaint = Paint()
      ..color = const Color(0xFF4A5568)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 외곽선
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
        const Radius.circular(8),
      ),
      linePaint,
    );

    // 중앙선
    canvas.drawLine(
      Offset(size.width / 2, 4),
      Offset(size.width / 2, size.height - 4),
      linePaint,
    );

    // 중앙 원
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final circleRadius = size.height * 0.15;
    canvas.drawCircle(Offset(centerX, centerY), circleRadius, linePaint);

    // 왼쪽 페인트 존
    final keyWidth = size.width * 0.18;
    final keyHeight = size.height * 0.45;
    final keyTop = (size.height - keyHeight) / 2;
    canvas.drawRect(
      Rect.fromLTWH(4, keyTop, keyWidth, keyHeight),
      linePaint,
    );

    // 오른쪽 페인트 존
    canvas.drawRect(
      Rect.fromLTWH(size.width - keyWidth - 4, keyTop, keyWidth, keyHeight),
      linePaint,
    );

    // 3점 라인 (왼쪽)
    final threePointRadius = size.height * 0.42;
    final threePointPath = Path();
    threePointPath.addArc(
      Rect.fromCenter(
        center: Offset(4, size.height / 2),
        width: threePointRadius * 2,
        height: threePointRadius * 2,
      ),
      -1.1,
      2.2,
    );
    canvas.drawPath(threePointPath, linePaint);

    // 3점 라인 (오른쪽)
    final threePointPath2 = Path();
    threePointPath2.addArc(
      Rect.fromCenter(
        center: Offset(size.width - 4, size.height / 2),
        width: threePointRadius * 2,
        height: threePointRadius * 2,
      ),
      3.14 - 1.1,
      2.2,
    );
    canvas.drawPath(threePointPath2, linePaint);

    // 농구 골대 (왼쪽)
    final hoopPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(keyWidth * 0.5, size.height / 2), 8, hoopPaint);

    // 농구 골대 (오른쪽)
    canvas.drawCircle(Offset(size.width - keyWidth * 0.5, size.height / 2), 8, hoopPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

