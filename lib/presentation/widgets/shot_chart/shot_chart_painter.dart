import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';
import '../../screens/shot_chart/shot_chart_screen.dart';

/// 슛차트 페인터
class ShotChartPainter extends CustomPainter {
  ShotChartPainter({
    required this.shots,
    required this.viewMode,
  });

  final List<LocalPlayByPlay> shots;
  final ShotChartViewMode viewMode;

  @override
  void paint(Canvas canvas, Size size) {
    // 코트 그리기
    _drawCourt(canvas, size);

    // 뷰 모드에 따라 슛 그리기
    switch (viewMode) {
      case ShotChartViewMode.scatter:
        _drawScatterPlot(canvas, size);
        break;
      case ShotChartViewMode.heatmap:
        _drawHeatmap(canvas, size);
        break;
      case ShotChartViewMode.zone:
        _drawZoneChart(canvas, size);
        break;
    }
  }

  void _drawCourt(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.courtLineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final width = size.width;
    final height = size.height;

    // 하프코트 기준 (왼쪽이 바스켓)
    // NBA 코트: 94ft x 50ft, 하프코트 47ft x 50ft
    // 3점 라인: 23.75ft (코너는 22ft)
    // 페인트: 16ft x 19ft
    // 자유투 라인: 15ft
    // 제한구역: 4ft 반원

    // 스케일 계산 (하프코트 기준)
    final scaleX = width / 47; // feet to pixels
    final scaleY = height / 50;

    // 외곽선 (이미 Container에서 그려짐)

    // 센터라인
    canvas.drawLine(
      Offset(width, 0),
      Offset(width, height),
      paint,
    );

    // 바스켓 위치 (림 중앙: 4ft from baseline, 코트 중앙)
    final basketX = 4 * scaleX;
    final basketY = height / 2;

    // 백보드
    final backboardPaint = Paint()
      ..color = AppTheme.courtLineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawLine(
      Offset(basketX - 0.5 * scaleX, basketY - 3 * scaleY),
      Offset(basketX - 0.5 * scaleX, basketY + 3 * scaleY),
      backboardPaint,
    );

    // 림
    final rimPaint = Paint()
      ..color = AppTheme.secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      Offset(basketX, basketY),
      0.75 * scaleX, // 림 직경 1.5ft
      rimPaint,
    );

    // 페인트 영역 (키 - 16ft wide, 19ft deep)
    final paintRect = Rect.fromLTWH(
      0,
      basketY - 8 * scaleY,
      19 * scaleX,
      16 * scaleY,
    );
    canvas.drawRect(paintRect, paint);

    // 자유투 원 (6ft 반경)
    final ftCircleCenter = Offset(19 * scaleX, basketY);
    canvas.drawCircle(ftCircleCenter, 6 * scaleY, paint);

    // 3점 라인
    final threePaint = Paint()
      ..color = AppTheme.threePointLineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 3점 아크 (23.75ft from basket center)
    final threePointRadius = 23.75 * scaleX;
    final cornerThreeY = 3 * scaleY; // 3ft from sideline

    // 코너 3점 라인 (수직선)
    canvas.drawLine(
      Offset(0, cornerThreeY),
      Offset(14 * scaleX, cornerThreeY),
      threePaint,
    );
    canvas.drawLine(
      Offset(0, height - cornerThreeY),
      Offset(14 * scaleX, height - cornerThreeY),
      threePaint,
    );

    // 3점 아크
    final threeArcRect = Rect.fromCenter(
      center: Offset(basketX, basketY),
      width: threePointRadius * 2,
      height: threePointRadius * 2,
    );

    // 아크 각도 계산 (코너 3점과 만나는 지점)
    final cornerAngle = math.asin((basketY - cornerThreeY) / threePointRadius);
    canvas.drawArc(
      threeArcRect,
      -cornerAngle,
      cornerAngle * 2,
      false,
      threePaint,
    );

    // 제한구역 (원형, 4ft 반경)
    final restrictedPaint = Paint()
      ..color = AppTheme.courtLineColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(basketX, basketY),
        width: 8 * scaleX,
        height: 8 * scaleX,
      ),
      -math.pi / 2,
      math.pi,
      false,
      restrictedPaint,
    );
  }

  void _drawScatterPlot(Canvas canvas, Size size) {
    for (final shot in shots) {
      if (shot.courtX == null || shot.courtY == null) continue;

      // 좌표 변환 (0-100 → 화면 좌표)
      final x = (shot.courtX! / 100) * size.width;
      final y = (shot.courtY! / 100) * size.height;

      final isMade = shot.isMade == true;
      final paint = Paint()
        ..color = isMade ? AppTheme.shotMadeColor : AppTheme.shotMissedColor
        ..style = isMade ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 2;

      // 성공: 채워진 원, 실패: 빈 원
      canvas.drawCircle(Offset(x, y), 6, paint);

      // 실패 시 X 표시
      if (!isMade) {
        final xPaint = Paint()
          ..color = AppTheme.shotMissedColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        canvas.drawLine(
          Offset(x - 4, y - 4),
          Offset(x + 4, y + 4),
          xPaint,
        );
        canvas.drawLine(
          Offset(x - 4, y + 4),
          Offset(x + 4, y - 4),
          xPaint,
        );
      }
    }
  }

  void _drawHeatmap(Canvas canvas, Size size) {
    // 향상된 히트맵: 15x15 그리드 + 가우시안 스무딩
    const gridSize = 15;
    final cellWidth = size.width / gridSize;
    final cellHeight = size.height / gridSize;

    // 각 셀별 슛 카운트
    final grid = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => _ShotCell()),
    );

    // 슛 데이터 수집
    for (final shot in shots) {
      if (shot.courtX == null || shot.courtY == null) continue;

      final gridX = ((shot.courtX! / 100) * gridSize).floor().clamp(0, gridSize - 1);
      final gridY = ((shot.courtY! / 100) * gridSize).floor().clamp(0, gridSize - 1);

      grid[gridX][gridY].total++;
      if (shot.isMade == true) {
        grid[gridX][gridY].made++;
      }
    }

    // 최대 슛 시도 수 계산 (정규화용)
    int maxAttempts = 0;
    for (var x = 0; x < gridSize; x++) {
      for (var y = 0; y < gridSize; y++) {
        if (grid[x][y].total > maxAttempts) {
          maxAttempts = grid[x][y].total;
        }
      }
    }
    if (maxAttempts == 0) return;

    // 가우시안 스무딩 적용
    final smoothedGrid = _applyGaussianSmoothing(grid, gridSize);

    // 히트맵 그리기 (둥근 모서리로 부드럽게)
    for (var x = 0; x < gridSize; x++) {
      for (var y = 0; y < gridSize; y++) {
        final cell = grid[x][y];
        final smoothedIntensity = smoothedGrid[x][y];

        if (smoothedIntensity < 0.05) continue;

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x * cellWidth + 1,
            y * cellHeight + 1,
            cellWidth - 2,
            cellHeight - 2,
          ),
          const Radius.circular(4),
        );

        // 강도에 따른 알파값
        final alpha = (smoothedIntensity * 0.8).clamp(0.15, 0.85);

        // 성공률에 따른 색상 (3단계 그라데이션)
        Color color;
        if (cell.total > 0) {
          final successRate = cell.percentage / 100;
          if (successRate < 0.33) {
            // 낮은 성공률: 빨강 → 주황
            color = Color.lerp(
              const Color(0xFFE53935), // 빨강
              const Color(0xFFFF9800), // 주황
              successRate / 0.33,
            )!;
          } else if (successRate < 0.5) {
            // 중간 성공률: 주황 → 노랑
            color = Color.lerp(
              const Color(0xFFFF9800), // 주황
              const Color(0xFFFFEB3B), // 노랑
              (successRate - 0.33) / 0.17,
            )!;
          } else {
            // 높은 성공률: 노랑 → 초록
            color = Color.lerp(
              const Color(0xFFFFEB3B), // 노랑
              const Color(0xFF4CAF50), // 초록
              (successRate - 0.5) / 0.5,
            )!;
          }
        } else {
          // 슛이 없는 영역 (주변 영향만)
          color = const Color(0xFFFFEB3B);
        }

        final paint = Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.fill;

        canvas.drawRRect(rect, paint);

        // 숫자 표시 (충분한 시도가 있을 때)
        if (cell.total >= 3) {
          _drawCellStats(canvas, rect.outerRect, cell);
        }
      }
    }

    // 핫존 하이라이트 (가장 많이 슛한 영역)
    _drawHotZoneIndicators(canvas, size, grid, gridSize, maxAttempts);
  }

  /// 가우시안 스무딩 적용
  List<List<double>> _applyGaussianSmoothing(
    List<List<_ShotCell>> grid,
    int gridSize,
  ) {
    // 가우시안 커널 (3x3)
    const kernel = [
      [0.0625, 0.125, 0.0625],
      [0.125, 0.25, 0.125],
      [0.0625, 0.125, 0.0625],
    ];

    final result = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => 0.0),
    );

    // 최대값 계산
    int maxTotal = 0;
    for (var x = 0; x < gridSize; x++) {
      for (var y = 0; y < gridSize; y++) {
        if (grid[x][y].total > maxTotal) {
          maxTotal = grid[x][y].total;
        }
      }
    }
    if (maxTotal == 0) return result;

    // 스무딩 적용
    for (var x = 0; x < gridSize; x++) {
      for (var y = 0; y < gridSize; y++) {
        double sum = 0;
        for (var kx = -1; kx <= 1; kx++) {
          for (var ky = -1; ky <= 1; ky++) {
            final nx = x + kx;
            final ny = y + ky;
            if (nx >= 0 && nx < gridSize && ny >= 0 && ny < gridSize) {
              sum += (grid[nx][ny].total / maxTotal) * kernel[kx + 1][ky + 1];
            }
          }
        }
        result[x][y] = sum;
      }
    }

    return result;
  }

  /// 셀 통계 텍스트 그리기
  void _drawCellStats(Canvas canvas, Rect rect, _ShotCell cell) {
    final percentage = cell.percentage;
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${percentage.toStringAsFixed(0)}%\n',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          TextSpan(
            text: '${cell.made}/${cell.total}',
            style: TextStyle(
              fontSize: 8,
              color: Colors.white.withValues(alpha: 0.9),
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        rect.center.dx - textPainter.width / 2,
        rect.center.dy - textPainter.height / 2,
      ),
    );
  }

  /// 핫존 인디케이터 그리기
  void _drawHotZoneIndicators(
    Canvas canvas,
    Size size,
    List<List<_ShotCell>> grid,
    int gridSize,
    int maxAttempts,
  ) {
    final cellWidth = size.width / gridSize;
    final cellHeight = size.height / gridSize;
    final hotThreshold = maxAttempts * 0.7;

    final hotZonePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var x = 0; x < gridSize; x++) {
      for (var y = 0; y < gridSize; y++) {
        if (grid[x][y].total >= hotThreshold) {
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x * cellWidth,
              y * cellHeight,
              cellWidth,
              cellHeight,
            ),
            const Radius.circular(6),
          );
          canvas.drawRRect(rect, hotZonePaint);
        }
      }
    }
  }

  void _drawZoneChart(Canvas canvas, Size size) {
    // NBA 존 정의 (5개 영역)
    final zones = _getNbaZones(size);

    // 각 존별 통계 계산
    final zoneStats = <int, _ShotCell>{};

    for (final shot in shots) {
      if (shot.courtZone == null) {
        // courtZone이 없으면 좌표로 계산
        if (shot.courtX != null && shot.courtY != null) {
          final zone = _calculateZone(shot.courtX!, shot.courtY!, size);
          zoneStats.putIfAbsent(zone, () => _ShotCell());
          zoneStats[zone]!.total++;
          if (shot.isMade == true) {
            zoneStats[zone]!.made++;
          }
        }
      } else {
        final zone = shot.courtZone!;
        zoneStats.putIfAbsent(zone, () => _ShotCell());
        zoneStats[zone]!.total++;
        if (shot.isMade == true) {
          zoneStats[zone]!.made++;
        }
      }
    }

    // 각 존 그리기
    for (final entry in zones.entries) {
      final zoneId = entry.key;
      final zonePath = entry.value;
      final stats = zoneStats[zoneId] ?? _ShotCell();

      if (stats.total == 0) continue;

      // 성공률에 따른 색상
      final percentage = stats.percentage;
      final color = Color.lerp(
        AppTheme.shotMissedColor,
        AppTheme.shotMadeColor,
        percentage / 100,
      )!
          .withValues(alpha: 0.6);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawPath(zonePath, paint);

      // 존 테두리
      final borderPaint = Paint()
        ..color = AppTheme.courtLineColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawPath(zonePath, borderPaint);

      // 존 통계 텍스트
      final bounds = zonePath.getBounds();
      final textPainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${percentage.toStringAsFixed(0)}%\n',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextSpan(
              text: '${stats.made}/${stats.total}',
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          bounds.center.dx - textPainter.width / 2,
          bounds.center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  Map<int, Path> _getNbaZones(Size size) {
    final width = size.width;
    final height = size.height;

    // 스케일 계산
    final scaleX = width / 47;
    final scaleY = height / 50;

    final basketX = 4 * scaleX;
    final basketY = height / 2;

    return {
      // 1: 제한구역 (림 근처)
      1: Path()
        ..addOval(Rect.fromCenter(
          center: Offset(basketX, basketY),
          width: 8 * scaleX,
          height: 8 * scaleY,
        )),

      // 2: 페인트 영역 (제한구역 제외)
      2: Path()
        ..addRect(Rect.fromLTWH(0, basketY - 8 * scaleY, 19 * scaleX, 16 * scaleY)),

      // 3: 미드레인지 왼쪽
      3: Path()
        ..moveTo(19 * scaleX, 0)
        ..lineTo(23 * scaleX, 0)
        ..lineTo(23 * scaleX, basketY - 8 * scaleY)
        ..lineTo(19 * scaleX, basketY - 8 * scaleY)
        ..close(),

      // 4: 미드레인지 오른쪽
      4: Path()
        ..moveTo(19 * scaleX, basketY + 8 * scaleY)
        ..lineTo(23 * scaleX, basketY + 8 * scaleY)
        ..lineTo(23 * scaleX, height)
        ..lineTo(19 * scaleX, height)
        ..close(),

      // 5: 3점 영역
      5: Path()
        ..moveTo(23 * scaleX, 0)
        ..lineTo(width, 0)
        ..lineTo(width, height)
        ..lineTo(23 * scaleX, height)
        ..close(),
    };
  }

  int _calculateZone(double courtX, double courtY, Size size) {
    // 좌표를 실제 거리로 변환 (0-100 → feet)
    final x = (courtX / 100) * 47; // 하프코트 47ft
    final y = (courtY / 100) * 50; // 코트 폭 50ft

    // 바스켓까지 거리 계산
    final basketX = 4.0;
    final basketY = 25.0;
    final distance = math.sqrt(math.pow(x - basketX, 2) + math.pow(y - basketY, 2));

    // 존 판정
    if (distance <= 4) {
      return 1; // 제한구역
    } else if (x <= 19 && y >= 17 && y <= 33) {
      return 2; // 페인트
    } else if (distance < 23.75) {
      // 미드레인지
      return y < 25 ? 3 : 4;
    } else {
      return 5; // 3점
    }
  }

  @override
  bool shouldRepaint(covariant ShotChartPainter oldDelegate) {
    return oldDelegate.shots != shots || oldDelegate.viewMode != viewMode;
  }
}

/// 슛 셀 (히트맵/존차트용)
class _ShotCell {
  int total = 0;
  int made = 0;

  double get percentage => total > 0 ? (made / total) * 100 : 0;
}
