import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show FontWeight, TextStyle;

import '../../domain/iso/iso_projection.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/grid_pos.dart';
import '../../domain/models/market_state.dart';
import '../../domain/models/tile_state.dart';
import 'canvas_draw_helpers.dart';
import 'crops_painter.dart';

/// Renders 2.5D farm landmarks, sprinklers, orchard trees, artisan kettles,
/// animal pens, wooden crates, and Action Queue markers.
///
/// Reuses [Paint] and [Path] instances to keep the 60fps render pass free of
/// transient allocations.
class LandmarksAndStructuresPainter {
  LandmarksAndStructuresPainter(
    this.iso, {
    this.cropsPainter = const CropsPainter(),
  });

  final IsoProjection iso;
  final CropsPainter cropsPainter;

  final Paint _fillPaint = Paint();
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Path _pathA = Path();
  final Path _pathB = Path();

  static const TextStyle _queueBadgeTextStyle = TextStyle(
    color: Color(0xFF3E2723),
    fontSize: 11.5,
    fontWeight: FontWeight.w800,
  );

  void drawTileContents(
    Canvas canvas, {
    required GridPos pos,
    required TileState tile,
    required MarketState market,
    required int totalBarnCrates,
    required double dayProgress,
    required double animTime,
  }) {
    final center = iso.tileCenterToWorld(pos);
    final cx = center.x;
    final cy = center.y;

    // Scenic cypress bushes & fence posts along the northern village lane
    if (pos.y == 0 && tile.structure == StructureType.none) {
      _drawLaneScenery(canvas, cx, cy, pos, animTime);
    }

    switch (tile.structure) {
      case StructureType.farmhouse:
        _drawFarmhouse(canvas, cx, cy, dayProgress, animTime);
      case StructureType.well:
        _drawStoneWell(canvas, cx, cy, animTime);
      case StructureType.barn:
        _drawBarn(canvas, cx, cy, totalBarnCrates);
      case StructureType.marketStall:
        _drawMarketStall(canvas, cx, cy, market.stallCrates, animTime);
      case StructureType.sprinklerRotary:
        _drawRotarySprinkler(canvas, cx, cy, animTime);
      case StructureType.sprinklerSolar:
        _drawSolarSprinkler(canvas, cx, cy, animTime);
      case StructureType.lemonTree:
        _drawLemonTree(canvas, cx, cy, pos, tile, animTime);
      case StructureType.artisanPress:
        _drawArtisanPress(canvas, cx, cy, tile, animTime);
      case StructureType.henhouse:
        _drawHenhouse(canvas, cx, cy, tile.animal, animTime);
      case StructureType.beehive:
        _drawBeehive(canvas, cx, cy, tile.animal, animTime);
      case StructureType.cowPaddock:
        _drawCowPaddock(canvas, cx, cy, tile.animal, animTime);
      case StructureType.lantern:
        _drawSolarLantern(canvas, cx, cy, dayProgress, animTime);
      case StructureType.flowerArch:
        _drawFlowerArch(canvas, cx, cy, animTime);
      case StructureType.none:
        break;
    }

    if (tile.crop != null) {
      cropsPainter.drawPlantedCrop(
        canvas,
        cx,
        cy,
        pos,
        tile.crop!,
        tile.moisture,
        animTime,
      );
    }

    if (tile.droppedCrate != null) {
      CanvasDrawHelpers.drawWoodenCrate(
        canvas,
        Offset(cx + 10, cy + 4),
        tile.droppedCrate!,
        scale: 0.95,
      );
    }
  }

  void drawQueueMarkers(
    Canvas canvas,
    GridPos pos,
    List<int> stepNumbers,
    double animTime,
  ) {
    if (stepNumbers.isEmpty) return;
    final center = iso.tileCenterToWorld(pos);
    final bob = math.sin(animTime * 4.5 + pos.x) * 3.0;
    final label = stepNumbers.length == 1
        ? '${stepNumbers.first}'
        : stepNumbers.join(',');
    final badgeCenter = Offset(center.x, center.y - 34.0 + bob);

    _strokePaint
      ..color = const Color(0xCCFFF8E1)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(
      Offset(center.x, center.y - 8),
      Offset(badgeCenter.dx, badgeCenter.dy + 10),
      _strokePaint,
    );

    final badgeWidth = label.length > 2 ? 32.0 : 24.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: badgeCenter, width: badgeWidth, height: 22),
      const Radius.circular(11),
    );
    _fillPaint.color = const Color(0x44000000);
    canvas.drawRRect(rrect.shift(const Offset(0, 2)), _fillPaint);
    _fillPaint.color = const Color(0xFFFFCA28);
    canvas.drawRRect(rrect, _fillPaint);
    _strokePaint
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 2.0;
    canvas.drawRRect(rrect, _strokePaint);

    CanvasDrawHelpers.drawCenteredText(
      canvas,
      label,
      badgeCenter,
      _queueBadgeTextStyle,
    );
  }

  // ---------------------------------------------------------------------------
  // Village Lane Scenery & Landmarks
  // ---------------------------------------------------------------------------

  void _drawLaneScenery(
    Canvas canvas,
    double cx,
    double cy,
    GridPos pos,
    double animTime,
  ) {
    if (pos.x.isEven && pos.x != 4 && pos.x != 6) {
      final sway = math.sin(animTime * 1.8 + pos.x) * 1.5;
      _fillPaint.color = const Color(0x28000000);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 14, cy - 11), width: 18, height: 9),
        _fillPaint,
      );
      _pathA
        ..reset()
        ..moveTo(cx + 7, cy - 11)
        ..quadraticBezierTo(cx + 14 + sway, cy - 38, cx + 14 + sway, cy - 40)
        ..quadraticBezierTo(cx + 21 + sway, cy - 24, cx + 21, cy - 11)
        ..close();
      _fillPaint.color = const Color(0xFF2E7D32);
      canvas.drawPath(_pathA, _fillPaint);
    }
  }

  void _drawFarmhouse(
    Canvas canvas,
    double cx,
    double cy,
    double dayProgress,
    double animTime,
  ) {
    _fillPaint.color = const Color(0x33000000);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 76, height: 36),
      _fillPaint,
    );

    _pathA
      ..reset()
      ..moveTo(cx - 30, cy - 4)
      ..lineTo(cx, cy + 12)
      ..lineTo(cx, cy - 26)
      ..lineTo(cx - 30, cy - 42)
      ..close();
    _fillPaint.color = const Color(0xFFFFF3E0);
    canvas.drawPath(_pathA, _fillPaint);

    _pathB
      ..reset()
      ..moveTo(cx, cy + 12)
      ..lineTo(cx + 30, cy - 4)
      ..lineTo(cx + 30, cy - 42)
      ..lineTo(cx, cy - 26)
      ..close();
    _fillPaint.color = const Color(0xFFFFE0B2);
    canvas.drawPath(_pathB, _fillPaint);

    final door = RRect.fromRectAndCorners(
      Rect.fromLTWH(cx + 9, cy - 18, 11, 20),
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
    );
    _fillPaint.color = const Color(0xFF795548);
    canvas.drawRRect(door, _fillPaint);

    final isEvening = dayProgress > 0.60;
    if (isEvening) {
      _fillPaint.color = const Color(0x38FFD54F);
      canvas.drawCircle(Offset(cx - 15, cy - 18), 16, _fillPaint);
    }
    _fillPaint.color = isEvening
        ? const Color(0xFFFFD54F)
        : const Color(0xFF81D4FA);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - 15, cy - 18),
          width: 11,
          height: 11,
        ),
        const Radius.circular(3),
      ),
      _fillPaint,
    );

    _fillPaint.color = const Color(0xFFA1887F);
    canvas.drawRect(Rect.fromLTWH(cx - 20, cy - 64, 9, 18), _fillPaint);

    final puffPhase = (animTime * 0.7) % 1.0;
    _fillPaint.color = Color.fromRGBO(255, 255, 255, (1.0 - puffPhase) * 0.65);
    canvas.drawCircle(
      Offset(cx - 15 + puffPhase * 6, cy - 68 - puffPhase * 16),
      4.5 * (1.0 - puffPhase * 0.4),
      _fillPaint,
    );

    _pathA
      ..reset()
      ..moveTo(cx - 35, cy - 39)
      ..lineTo(cx, cy - 22)
      ..lineTo(cx, cy - 56)
      ..close();
    _fillPaint.color = const Color(0xFFD84315);
    canvas.drawPath(_pathA, _fillPaint);

    _pathB
      ..reset()
      ..moveTo(cx, cy - 22)
      ..lineTo(cx + 35, cy - 39)
      ..lineTo(cx, cy - 56)
      ..close();
    _fillPaint.color = const Color(0xFFBF360C);
    canvas.drawPath(_pathB, _fillPaint);
  }

  void _drawStoneWell(Canvas canvas, double cx, double cy, double animTime) {
    _fillPaint.color = const Color(0x33000000);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 52, height: 26),
      _fillPaint,
    );

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 4), width: 42, height: 22),
      const Radius.circular(10),
    );
    _fillPaint.color = const Color(0xFF90A4AE);
    canvas.drawRRect(body, _fillPaint);
    _fillPaint.color = const Color(0xFFB0BEC5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 13), width: 42, height: 18),
      _fillPaint,
    );

    final shimmer = (math.sin(animTime * 3.2) + 1.0) * 0.5;
    _fillPaint.color = Color.lerp(
      const Color(0xFF0288D1),
      const Color(0xFF4FC3F7),
      shimmer,
    )!;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 13), width: 30, height: 12),
      _fillPaint,
    );

    _strokePaint
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(
      Offset(cx - 15, cy - 14),
      Offset(cx - 15, cy - 40),
      _strokePaint,
    );
    canvas.drawLine(
      Offset(cx + 15, cy - 14),
      Offset(cx + 15, cy - 40),
      _strokePaint,
    );

    _pathA
      ..reset()
      ..moveTo(cx - 24, cy - 36)
      ..lineTo(cx, cy - 50)
      ..lineTo(cx + 24, cy - 36)
      ..close();
    _fillPaint.color = const Color(0xFF8D6E63);
    canvas.drawPath(_pathA, _fillPaint);
  }

  void _drawBarn(Canvas canvas, double cx, double cy, int totalBarnCrates) {
    _fillPaint.color = const Color(0x33000000);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 5), width: 74, height: 34),
      _fillPaint,
    );

    _pathA
      ..reset()
      ..moveTo(cx - 28, cy - 3)
      ..lineTo(cx, cy + 12)
      ..lineTo(cx, cy - 26)
      ..lineTo(cx - 28, cy - 40)
      ..close();
    _fillPaint.color = const Color(0xFFC62828);
    canvas.drawPath(_pathA, _fillPaint);

    _pathB
      ..reset()
      ..moveTo(cx, cy + 12)
      ..lineTo(cx + 28, cy - 3)
      ..lineTo(cx + 28, cy - 40)
      ..lineTo(cx, cy - 26)
      ..close();
    _fillPaint.color = const Color(0xFFA31D1D);
    canvas.drawPath(_pathB, _fillPaint);

    _strokePaint
      ..color = const Color(0xFFFFF8E1)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.butt;
    canvas.drawRect(Rect.fromLTWH(cx + 6, cy - 20, 16, 22), _strokePaint);
    _strokePaint.strokeWidth = 2.4;
    canvas.drawLine(
      Offset(cx + 6, cy - 20),
      Offset(cx + 22, cy + 2),
      _strokePaint,
    );
    canvas.drawLine(
      Offset(cx + 22, cy - 20),
      Offset(cx + 6, cy + 2),
      _strokePaint,
    );

    _pathA
      ..reset()
      ..moveTo(cx - 33, cy - 38)
      ..lineTo(cx, cy - 58)
      ..lineTo(cx + 33, cy - 38)
      ..lineTo(cx, cy - 23)
      ..close();
    _fillPaint.color = const Color(0xFF5D4037);
    canvas.drawPath(_pathA, _fillPaint);

    if (totalBarnCrates > 0) {
      CanvasDrawHelpers.drawFloatingStatusPill(
        canvas,
        cx,
        cy - 66,
        '📦 $totalBarnCrates',
      );
    }
  }

  void _drawMarketStall(
    Canvas canvas,
    double cx,
    double cy,
    List<ProductId> stallCrates,
    double animTime,
  ) {
    _fillPaint.color = const Color(0x33000000);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 5), width: 78, height: 34),
      _fillPaint,
    );

    final counter = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 4), width: 58, height: 22),
      const Radius.circular(6),
    );
    _fillPaint.color = const Color(0xFFA1693A);
    canvas.drawRRect(counter, _fillPaint);
    _strokePaint
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.butt;
    canvas.drawRRect(counter, _strokePaint);

    for (var i = 0; i < stallCrates.length && i < 6; i++) {
      final row = i ~/ 3;
      final col = i % 3;
      CanvasDrawHelpers.drawWoodenCrate(
        canvas,
        Offset(cx - 16 + col * 16.0, cy - 14 - row * 9.0),
        stallCrates[i],
        scale: 0.66,
      );
    }

    _strokePaint
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 3.2;
    canvas.drawLine(
      Offset(cx - 25, cy - 12),
      Offset(cx - 25, cy - 44),
      _strokePaint,
    );
    canvas.drawLine(
      Offset(cx + 25, cy - 12),
      Offset(cx + 25, cy - 44),
      _strokePaint,
    );

    const stripeCount = 5;
    const totalW = 60.0;
    const stripeW = totalW / stripeCount;
    for (var i = 0; i < stripeCount; i++) {
      final sx = cx - totalW * 0.5 + i * stripeW;
      _fillPaint.color = i.isEven
          ? const Color(0xFFE53935)
          : const Color(0xFFFFF8E1);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(sx, cy - 52, stripeW + 0.5, 15),
          bottomLeft: const Radius.circular(4),
          bottomRight: const Radius.circular(4),
        ),
        _fillPaint,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Orchard Lemon Tree, Artisan Kettle, Automation & Animals
  // ---------------------------------------------------------------------------

  void _drawLemonTree(
    Canvas canvas,
    double cx,
    double cy,
    GridPos pos,
    TileState tile,
    double time,
  ) {
    final sway = math.sin(time * 2.1 + pos.x) * 2.4;
    _fillPaint.color = const Color(0x33000000);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 46, height: 22),
      _fillPaint,
    );
    _strokePaint
      ..color = const Color(0xFFD84315)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.butt;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 1), width: 32, height: 15),
      _strokePaint,
    );
    _strokePaint
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy + 1),
      Offset(cx + sway * 0.25, cy - 22),
      _strokePaint,
    );

    _fillPaint.color = const Color(0xFF388E3C);
    canvas.drawCircle(Offset(cx - 9 + sway, cy - 28), 13.5, _fillPaint);
    _fillPaint.color = const Color(0xFF2E7D32);
    canvas.drawCircle(Offset(cx + 9 + sway, cy - 27), 13.5, _fillPaint);
    _fillPaint.color = const Color(0xFF43A047);
    canvas.drawCircle(Offset(cx + sway, cy - 35), 15.5, _fillPaint);

    if (tile.producerCrates > 0 || tile.producerProgress > 0.45) {
      final r = tile.producerCrates > 0 ? 3.8 : 2.6;
      _fillPaint.color = const Color(0xFFFFEE58);
      canvas.drawCircle(Offset(cx - 8 + sway, cy - 28), r, _fillPaint);
      canvas.drawCircle(Offset(cx + 7 + sway, cy - 30), r, _fillPaint);
      canvas.drawCircle(Offset(cx + 1 + sway, cy - 39), r, _fillPaint);
      canvas.drawCircle(Offset(cx + 9 + sway, cy - 22), r, _fillPaint);
    }

    if (tile.producerCrates > 0) {
      CanvasDrawHelpers.drawFloatingStatusPill(
        canvas,
        cx,
        cy - 58,
        '🍋 ${tile.producerCrates}',
      );
    }
  }

  void _drawArtisanPress(
    Canvas canvas,
    double cx,
    double cy,
    TileState tile,
    double time,
  ) {
    _fillPaint.color = const Color(0x36000000);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 52, height: 24),
      _fillPaint,
    );

    final hearth = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 4), width: 38, height: 18),
      const Radius.circular(7),
    );
    _fillPaint.color = const Color(0xFF8D6E63);
    canvas.drawRRect(hearth, _fillPaint);

    if (tile.producerActive) {
      final glow = (math.sin(time * 6.0) + 1.0) * 0.5;
      _fillPaint.color = const Color(0xCCFF7043);
      canvas.drawCircle(Offset(cx, cy + 1), 6.0 + glow * 2.0, _fillPaint);
    }

    final kettle = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 17), width: 30, height: 20),
      const Radius.circular(9),
    );
    _fillPaint.color = const Color(0xFFD87A3B);
    canvas.drawRRect(kettle, _fillPaint);
    _fillPaint.color = tile.producerActive
        ? const Color(0xFFC2185B)
        : const Color(0xFF5D4037);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 25), width: 26, height: 10),
      _fillPaint,
    );

    if (tile.producerActive) {
      for (var s = 0; s < 2; s++) {
        final phase = ((time * 0.9 + s * 0.5) % 1.0);
        _fillPaint.color = Color.fromRGBO(255, 248, 225, (1.0 - phase) * 0.75);
        canvas.drawCircle(
          Offset(cx - 4 + s * 8.0, cy - 30 - phase * 18.0),
          3.6 * (1.0 - phase * 0.35),
          _fillPaint,
        );
      }
    }

    if (tile.producerCrates > 0) {
      CanvasDrawHelpers.drawFloatingStatusPill(
        canvas,
        cx,
        cy - 46,
        '🫙 ${tile.producerCrates}',
      );
    }
  }

  void _drawRotarySprinkler(Canvas canvas, double cx, double cy, double time) {
    _fillPaint.color = const Color(0x33000000);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 2), width: 24, height: 12),
      _fillPaint,
    );
    _fillPaint.color = const Color(0xFF546E7A);
    canvas.drawCircle(Offset(cx, cy), 9, _fillPaint);
    _strokePaint
      ..color = const Color(0xFFCFD8DC)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(Offset(cx, cy), Offset(cx, cy - 13), _strokePaint);

    final angle = time * 4.5;
    final dx = math.cos(angle) * 11.0;
    final dy = math.sin(angle) * 5.5;
    _strokePaint
      ..color = const Color(0xFF29B6F6)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - dx, cy - 13 - dy),
      Offset(cx + dx, cy - 13 + dy),
      _strokePaint,
    );
  }

  void _drawSolarSprinkler(Canvas canvas, double cx, double cy, double time) {
    _fillPaint.color = const Color(0x38000000);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 2), width: 30, height: 15),
      _fillPaint,
    );
    _fillPaint.color = const Color(0xFFFFB300);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 11), width: 12, height: 24),
        const Radius.circular(5),
      ),
      _fillPaint,
    );
    _fillPaint.color = const Color(0xFF1565C0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 25), width: 24, height: 11),
      _fillPaint,
    );
    final pulse = (math.sin(time * 3.8) + 1) * 0.5;
    _fillPaint.color = const Color(0x664FC3F7);
    canvas.drawCircle(Offset(cx, cy - 16), 5.0 + pulse * 3.0, _fillPaint);
  }

  void _drawHenhouse(
    Canvas canvas,
    double cx,
    double cy,
    AnimalUnitState? state,
    double time,
  ) {
    _fillPaint.color = const Color(0x30000000);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 56, height: 26),
      _fillPaint,
    );
    final coop = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 6, cy - 12), width: 32, height: 22),
      const Radius.circular(5),
    );
    _fillPaint.color = const Color(0xFFD7A86E);
    canvas.drawRRect(coop, _fillPaint);
    _pathA
      ..reset()
      ..moveTo(cx - 26, cy - 21)
      ..lineTo(cx - 6, cy - 35)
      ..lineTo(cx + 14, cy - 21)
      ..close();
    _fillPaint.color = const Color(0xFFE65100);
    canvas.drawPath(_pathA, _fillPaint);

    final peck = math.sin(time * 5.0).abs() * 3.0;
    void drawHen(double ox, double oy, Color col) {
      _fillPaint.color = col;
      canvas.drawCircle(Offset(cx + ox, cy + oy), 5.5, _fillPaint);
      canvas.drawCircle(
        Offset(cx + ox + 4, cy + oy - 3 + peck),
        3.2,
        _fillPaint,
      );
      _fillPaint.color = const Color(0xFFE53935);
      canvas.drawCircle(
        Offset(cx + ox + 4, cy + oy - 6 + peck),
        1.8,
        _fillPaint,
      );
    }

    drawHen(12.0, 2.0, const Color(0xFFFFFFFF));
    drawHen(2.0, 8.0, const Color(0xFFFFCC80));

    CanvasDrawHelpers.drawAnimalStatusBubble(canvas, cx, cy - 44, state, '🥚');
  }

  void _drawBeehive(
    Canvas canvas,
    double cx,
    double cy,
    AnimalUnitState? state,
    double time,
  ) {
    _fillPaint.color = const Color(0x30000000);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 3), width: 42, height: 20),
      _fillPaint,
    );
    for (var i = 0; i < 3; i++) {
      _fillPaint.color = i.isEven
          ? const Color(0xFFFFCA28)
          : const Color(0xFFFFB300);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, cy - 5 - i * 8.0),
            width: 28 - i * 4.0,
            height: 9,
          ),
          const Radius.circular(5),
        ),
        _fillPaint,
      );
    }
    _fillPaint.color = const Color(0xFF3E2723);
    canvas.drawCircle(Offset(cx, cy - 6), 3.2, _fillPaint);

    _fillPaint.color = const Color(0xFFFFEE58);
    for (var b = 0; b < 3; b++) {
      final a = time * 3.6 + b * 2.1;
      final bx = cx + math.cos(a) * 18.0;
      final by = cy - 16.0 + math.sin(a * 1.5) * 7.0;
      canvas.drawCircle(Offset(bx, by), 2.5, _fillPaint);
    }

    CanvasDrawHelpers.drawAnimalStatusBubble(canvas, cx, cy - 40, state, '🍯');
  }

  void _drawCowPaddock(
    Canvas canvas,
    double cx,
    double cy,
    AnimalUnitState? state,
    double time,
  ) {
    _strokePaint
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.butt;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 2), width: 64, height: 30),
      _strokePaint,
    );

    final sway = math.sin(time * 2.2) * 2.0;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx - 2 + sway, cy - 10),
        width: 26,
        height: 15,
      ),
      const Radius.circular(7),
    );
    _fillPaint.color = const Color(0xFFFAFAFA);
    canvas.drawRRect(bodyRect, _fillPaint);
    canvas.drawCircle(Offset(cx + 12 + sway, cy - 14), 6.0, _fillPaint);

    _fillPaint.color = const Color(0xFF3E2723);
    canvas.drawCircle(Offset(cx - 5 + sway, cy - 11), 4.2, _fillPaint);
    canvas.drawCircle(Offset(cx + 4 + sway, cy - 8), 3.2, _fillPaint);

    _fillPaint.color = const Color(0xFFF48FB1);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 14 + sway, cy - 12),
        width: 7,
        height: 4.5,
      ),
      _fillPaint,
    );

    CanvasDrawHelpers.drawAnimalStatusBubble(canvas, cx, cy - 38, state, '🥛');
  }

  void _drawSolarLantern(
    Canvas canvas,
    double cx,
    double cy,
    double dayProgress,
    double time,
  ) {
    final isDusk = dayProgress > 0.55;
    final glowStrength = isDusk ? 0.52 : 0.16;
    _fillPaint.color = Color.fromRGBO(255, 213, 79, glowStrength);
    canvas.drawCircle(
      Offset(cx, cy - 20),
      (isDusk ? 26.0 : 16.0) + math.sin(time * 3.0) * 2.5,
      _fillPaint,
    );
    _strokePaint
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(Offset(cx, cy + 2), Offset(cx, cy - 18), _strokePaint);

    _fillPaint.color = const Color(0xFFFFEE58);
    canvas.drawCircle(Offset(cx, cy - 21), 6.5, _fillPaint);

    _pathA
      ..reset()
      ..moveTo(cx - 9, cy - 25)
      ..lineTo(cx, cy - 32)
      ..lineTo(cx + 9, cy - 25)
      ..close();
    _fillPaint.color = const Color(0xFF5D4037);
    canvas.drawPath(_pathA, _fillPaint);
  }

  void _drawFlowerArch(Canvas canvas, double cx, double cy, double time) {
    _strokePaint
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - 8), width: 44, height: 56),
      math.pi,
      math.pi,
      false,
      _strokePaint,
    );
    for (var i = 0; i <= 6; i++) {
      final a = math.pi + (math.pi * i / 6.0);
      final fx = cx + math.cos(a) * 22.0;
      final fy = cy - 8 + math.sin(a) * 28.0;
      _fillPaint.color = const Color(0xFF43A047);
      canvas.drawCircle(Offset(fx, fy), 5.2, _fillPaint);
      _fillPaint.color = i.isEven
          ? const Color(0xFFEC407A)
          : const Color(0xFFFF80AB);
      canvas.drawCircle(Offset(fx, fy - 1), 3.4, _fillPaint);
    }
  }
}
