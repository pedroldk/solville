import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show FontWeight, TextStyle;

import '../../domain/iso/iso_projection.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/grid_pos.dart';
import '../../domain/models/market_state.dart';
import '../../domain/models/tile_state.dart';
import 'animals_painter.dart';
import 'buildings_painter.dart';
import 'canvas_draw_helpers.dart';
import 'crops_painter.dart';

/// Depth-aware coordinator rendering 2.5D Mediterranean buildings, landmarks,
/// orchard trees, artisan kettles, animal pens, crops, wooden crates, bee
/// synergy links, and crisp vector Action Queue markers.
class LandmarksAndStructuresPainter {
  LandmarksAndStructuresPainter(
    this.iso, {
    this.cropsPainter = const CropsPainter(),
    BuildingsPainter? buildingsPainter,
    AnimalsPainter? animalsPainter,
  }) : _buildingsPainter = buildingsPainter ?? BuildingsPainter(),
       _animalsPainter = animalsPainter ?? AnimalsPainter();

  final IsoProjection iso;
  final CropsPainter cropsPainter;
  final BuildingsPainter _buildingsPainter;
  final AnimalsPainter _animalsPainter;

  final Paint _fillPaint = Paint();
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final Path _arcPath = Path();

  static const TextStyle _queueNumTextStyle = TextStyle(
    color: Color(0xFF3E2723),
    fontSize: 10.0,
    fontWeight: FontWeight.w900,
  );

  void drawTileContents(
    Canvas canvas, {
    required GridPos pos,
    required TileState tile,
    required MarketState market,
    required int totalBarnCrates,
    required double dayProgress,
    required double animTime,
    WeatherType weather = WeatherType.sunny,
    bool isSunPassActive = true,
    bool showDetailedMeters = false,
    double popScale = 1.0,
    String homesteadLabel = '🏡 Homestead',
    String refillLabel = '🪣 Refill',
    String barnLabel = '🏠 Barn',
  }) {
    final warmRainGlow = weather == WeatherType.gentleRain;
    final center = iso.tileCenterToWorld(pos);
    final cx = center.x;
    final cy = center.y;

    // Scenic cypress trees & terracotta flower planters along northern village lane
    if (pos.y == 0 && tile.structure == StructureType.none) {
      _buildingsPainter.drawLaneScenery(canvas, cx, cy, pos, animTime);
    }

    if (tile.structure != StructureType.none &&
        tile.structure != StructureType.cowPaddock &&
        tile.structure != StructureType.flowerArch) {
      _drawStructureShadow(canvas, cx, cy, tile.structure, dayProgress);
    }

    switch (tile.structure) {
      case StructureType.farmhouse:
        _buildingsPainter.drawFarmhouse(
          canvas,
          cx,
          cy,
          dayProgress,
          animTime,
          warmGlowActive: warmRainGlow,
        );
        if (showDetailedMeters) {
          CanvasDrawHelpers.drawFloatingStatusPill(
            canvas,
            cx,
            cy - 74,
            homesteadLabel,
          );
        }
      case StructureType.well:
        _buildingsPainter.drawStoneWell(canvas, cx, cy, animTime);
        if (showDetailedMeters) {
          CanvasDrawHelpers.drawFloatingStatusPill(
            canvas,
            cx,
            cy - 60,
            refillLabel,
          );
        }
      case StructureType.barn:
        _buildingsPainter.drawBarn(
          canvas,
          cx,
          cy,
          totalBarnCrates,
          showDetailedMeters: showDetailedMeters,
        );
        if (showDetailedMeters && totalBarnCrates == 0) {
          CanvasDrawHelpers.drawFloatingStatusPill(
            canvas,
            cx,
            cy - 70,
            barnLabel,
          );
        }
      case StructureType.marketStall:
        _buildingsPainter.drawMarketStall(
          canvas,
          cx,
          cy,
          market.stallCrates,
          animTime,
        );
        if (showDetailedMeters) {
          CanvasDrawHelpers.drawActionCircleBadge(
            canvas,
            Offset(cx - 26, cy - 52),
            '📈',
            radius: 11.5,
          );
          if (market.expressOrder != null) {
            _buildingsPainter.drawExpressOrderBubble(
              canvas,
              cx + 22,
              cy - 54,
              market.expressOrder!,
            );
          }
        } else if (market.expressOrder != null) {
          final pulse = 0.5 + 0.5 * math.sin(animTime * 4.5);
          _fillPaint.color = const Color(0x4DFFD54F);
          canvas.drawCircle(
            Offset(cx + 22, cy - 48),
            7.8 + pulse * 1.6,
            _fillPaint,
          );
          _fillPaint.color = const Color(0xFFFFCA28);
          CanvasDrawHelpers.drawStar4(
            canvas,
            Offset(cx + 22, cy - 48),
            5.5 + pulse * 0.8,
            _fillPaint,
            rotation: animTime * 0.9,
          );
        }
      case StructureType.sprinklerRotary:
        _buildingsPainter.drawRotarySprinkler(canvas, cx, cy, animTime);
      case StructureType.sprinklerSolar:
        _buildingsPainter.drawSolarSprinkler(canvas, cx, cy, animTime);
      case StructureType.lemonTree:
        _buildingsPainter.drawLemonTree(
          canvas,
          cx,
          cy,
          pos,
          tile,
          animTime,
          showDetailedMeters: showDetailedMeters,
        );
      case StructureType.artisanPress:
        _buildingsPainter.drawArtisanPress(
          canvas,
          cx,
          cy,
          tile,
          animTime,
          isSunPassActive: isSunPassActive,
          showDetailedMeters: showDetailedMeters,
        );
      case StructureType.henhouse:
        _animalsPainter.drawHenhouse(
          canvas,
          cx,
          cy,
          tile.animal,
          animTime,
          showDetailedMeters: showDetailedMeters,
        );
      case StructureType.beehive:
        _animalsPainter.drawBeehive(
          canvas,
          cx,
          cy,
          tile.animal,
          animTime,
          showDetailedMeters: showDetailedMeters,
        );
      case StructureType.cowPaddock:
        _animalsPainter.drawCowPaddock(
          canvas,
          cx,
          cy,
          tile.animal,
          animTime,
          showDetailedMeters: showDetailedMeters,
        );
      case StructureType.lantern:
        _buildingsPainter.drawSolarLantern(
          canvas,
          cx,
          cy,
          dayProgress,
          animTime,
          warmGlowActive: warmRainGlow,
        );
      case StructureType.flowerArch:
        _buildingsPainter.drawFlowerArch(canvas, cx, cy, animTime);
      case StructureType.none:
        break;
    }

    if (tile.structure.requiresSunPass &&
        !isSunPassActive &&
        !tile.isReadyToHarvest) {
      final pulse = 0.8 + 0.2 * math.sin(animTime * 3.5);
      CanvasDrawHelpers.drawActionCircleBadge(
        canvas,
        Offset(cx, cy - 44),
        '🔒',
        background: Color.fromRGBO(255, 248, 225, 0.92 * pulse),
        border: const Color(0xFFFFB300),
        radius: 11.5,
      );
    }

    if (tile.landmark != LandmarkKind.none) {
      _buildingsPainter.drawExpansionLandmark(
        canvas,
        cx,
        cy,
        tile,
        animTime,
        showDetailedMeters: showDetailedMeters,
      );
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
        showDetailedMeters: showDetailedMeters,
        popScale: popScale,
      );
    }

    if (tile.droppedCrate != null) {
      final crateBob = math.sin(animTime * 2.6 + pos.x) * 2.0;
      CanvasDrawHelpers.drawWoodenCrate(
        canvas,
        Offset(cx + 10, cy + 4 + crateBob * 0.3),
        tile.droppedCrate!,
        scale: 0.96,
      );
    }
  }

  void _drawStructureShadow(
    Canvas canvas,
    double cx,
    double cy,
    StructureType structure,
    double dayProgress,
  ) {
    final sunOffsetX = (dayProgress - 0.45) * 10.0;
    final (double w, double h, double dy) = switch (structure) {
      StructureType.farmhouse => (72.0, 32.0, 6.0),
      StructureType.barn => (70.0, 30.0, 6.0),
      StructureType.marketStall => (64.0, 27.0, 5.0),
      StructureType.well || StructureType.henhouse => (46.0, 21.0, 4.0),
      StructureType.lemonTree || StructureType.artisanPress => (42.0, 19.0, 4.0),
      StructureType.beehive => (34.0, 15.0, 3.0),
      StructureType.sprinklerRotary ||
      StructureType.sprinklerSolar ||
      StructureType.lantern => (24.0, 11.0, 3.0),
      StructureType.cowPaddock ||
      StructureType.flowerArch ||
      StructureType.none => (0.0, 0.0, 0.0),
    };
    if (w <= 0) return;
    _fillPaint.color = const Color(0x161A0E0C);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + sunOffsetX * 1.35, cy + dy + 2.0),
        width: w * 1.12,
        height: h * 1.12,
      ),
      _fillPaint,
    );
    _fillPaint.color = const Color(0x221A0E0C);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + sunOffsetX * 0.7, cy + dy),
        width: w,
        height: h,
      ),
      _fillPaint,
    );
  }

  void drawQueueMarkers(
    Canvas canvas,
    GridPos pos,
    List<({int step, ActionKind kind})> entries,
    double animTime,
  ) {
    if (entries.isEmpty) return;
    final center = iso.tileCenterToWorld(pos);
    final bob = math.sin(animTime * 2.8 + pos.x) * 2.8;
    final badgeCenter = Offset(center.x, center.y - 34.0 + bob);

    _strokePaint
      ..color = const Color(0xCCFFF8E1)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(center.x, center.y - 8),
      Offset(badgeCenter.dx, badgeCenter.dy + 10),
      _strokePaint,
    );

    const itemWidth = 24.0;
    final badgeWidth = (entries.length * itemWidth + 10.0).clamp(32.0, 118.0);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: badgeCenter, width: badgeWidth, height: 22),
      const Radius.circular(11),
    );
    _fillPaint.color = const Color(0x40261412);
    canvas.drawRRect(rrect.shift(const Offset(0, 2)), _fillPaint);
    _fillPaint.color = const Color(0xFFFFD54F);
    canvas.drawRRect(rrect, _fillPaint);
    _strokePaint
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 1.8;
    canvas.drawRRect(rrect, _strokePaint);

    final startX =
        badgeCenter.dx - ((entries.length - 1) * itemWidth) * 0.5;
    for (var i = 0; i < entries.length && i < 4; i++) {
      final e = entries[i];
      final ix = startX + i * itemWidth;
      CanvasDrawHelpers.drawCenteredText(
        canvas,
        '${e.step}',
        Offset(ix - 5.5, badgeCenter.dy),
        _queueNumTextStyle,
      );
      CanvasDrawHelpers.drawCanvasActionIcon(
        canvas,
        e.kind,
        Offset(ix + 5.5, badgeCenter.dy),
        11.0,
      );
    }
  }

  /// Draws the floating `[🌿]` quick-untill badge on the inspected tile.
  void drawInspectedActionPill(
    Canvas canvas,
    GridPos pos,
    double animTime,
  ) {
    final center = iso.tileCenterToWorld(pos);
    final bob = math.sin(animTime * 4.0) * 1.5;
    CanvasDrawHelpers.drawActionCircleBadge(
      canvas,
      Offset(center.x + 26, center.y - 34 + bob),
      '🌿',
      background: const Color(0xF6E8F5E9),
      border: const Color(0xFF66BB6A),
      radius: 13.0,
    );
  }

  /// Draws smooth arched golden bee synergy rays with traveling pollen sparkles
  /// from a hovered Beehive to nearby blooms.
  void drawBeeSynergyLinks(
    Canvas canvas,
    GameState state,
    GridPos hivePos,
    double bonus,
    double animTime,
  ) {
    final origin = iso.tileCenterToWorld(hivePos);
    final pulse = 0.55 + 0.25 * math.sin(animTime * 4.5);
    _strokePaint
      ..color = Color.fromRGBO(255, 193, 7, pulse)
      ..strokeWidth = 2.0;

    for (var dy = -2; dy <= 2; dy++) {
      for (var dx = -2; dx <= 2; dx++) {
        if (dx == 0 && dy == 0) continue;
        final np = GridPos(hivePos.x + dx, hivePos.y + dy);
        if (!state.inBounds(np)) continue;
        final nTile = state.tileAt(np);
        final boostsBee =
            (nTile.crop != null && nTile.crop!.growth >= 0.45) ||
            nTile.structure == StructureType.flowerArch ||
            nTile.structure == StructureType.lemonTree;
        if (!boostsBee) continue;
        final target = iso.tileCenterToWorld(np);
        final p0 = Offset(origin.x, origin.y - 16);
        final p2 = Offset(target.x, target.y - 10);
        final mid = Offset(
          (p0.dx + p2.dx) * 0.5,
          math.min(p0.dy, p2.dy) - 16.0,
        );
        _arcPath
          ..reset()
          ..moveTo(p0.dx, p0.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, p2.dx, p2.dy);
        canvas.drawPath(_arcPath, _strokePaint);

        // Animated pollen mote gliding along the synergy arc
        final t = (animTime * 0.8 + (dx + dy) * 0.17) % 1.0;
        final omt = 1.0 - t;
        final px = omt * omt * p0.dx + 2 * omt * t * mid.dx + t * t * p2.dx;
        final py = omt * omt * p0.dy + 2 * omt * t * mid.dy + t * t * p2.dy;
        _fillPaint.color = const Color(0xFFFFEE58);
        canvas.drawCircle(Offset(px, py), 2.4, _fillPaint);
      }
    }
    if (bonus > 0.01) {
      final pct = (bonus * 100).round();
      CanvasDrawHelpers.drawFloatingStatusPill(
        canvas,
        origin.x,
        origin.y - 54,
        '🐝+$pct%',
      );
    }
  }
}
