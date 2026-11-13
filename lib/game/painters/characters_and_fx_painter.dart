import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show FontWeight, TextStyle;

import '../../domain/iso/iso_projection.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/grid_pos.dart';
import 'canvas_draw_helpers.dart';

/// Floating particle / text popup in world coordinates.
class FloatingVfx {
  FloatingVfx({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.maxLife,
    this.size = 4.0,
    this.text,
    this.isRing = false,
  }) : life = maxLife;

  double x;
  double y;
  final double vx;
  final double vy;
  final Color color;
  final double maxLife;
  double life;
  final double size;
  final String? text;
  final bool isRing;
}

/// Named villager strolling along Solville's northern cobble lane (`y = 0`).
class StrollingVillager {
  StrollingVillager({
    required this.name,
    required this.variant,
    required this.gx,
    required this.speed,
    required this.tunicColor,
    required this.hairColor,
  });

  final String name;
  final int variant;
  double gx;
  double speed;
  final Color tunicColor;
  final Color hairColor;
  double pauseTimer = 0.0;
  double heartTimer = 0.0;
}

/// Renders sky clouds, A* stepping dots, Sol (with stacked crates & work tool
/// popups!), strolling townsfolk with Boom thought bubbles, twilight fireflies,
/// butterflies, sunshowers, and transient VFX particles.
///
/// Reuses [Paint] objects and quantized opacity styles for cached text rendering.
class CharactersAndFxPainter {
  CharactersAndFxPainter(this.iso);

  final IsoProjection iso;

  final Paint _fillPaint = Paint();
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _rainPaint = Paint()
    ..color = const Color(0x66B3E5FC)
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;

  static const TextStyle _workEmojiStyle = TextStyle(fontSize: 15);
  static const TextStyle _villagerCravingStyle = TextStyle(fontSize: 11);

  final Map<int, List<TextStyle?>> _floatingTextStyleCache =
      <int, List<TextStyle?>>{};

  TextStyle _getFloatingTextStyle(Color baseColor, int alphaStep) {
    final styles = _floatingTextStyleCache.putIfAbsent(
      baseColor.toARGB32(),
      () => List<TextStyle?>.filled(21, null),
    );
    var cached = styles[alphaStep];
    if (cached == null) {
      final qAlpha = alphaStep / 20.0;
      cached = TextStyle(
        color: baseColor.withValues(alpha: qAlpha),
        fontSize: 14.0,
        fontWeight: FontWeight.w900,
        shadows: <Shadow>[
          Shadow(
            color: const Color(0xAA3E2723).withValues(alpha: qAlpha),
            offset: const Offset(0, 1.5),
            blurRadius: 2,
          ),
        ],
      );
      styles[alphaStep] = cached;
    }
    return cached;
  }

  void drawSkyClouds(
    Canvas canvas,
    int gridSize,
    double dayProgress,
    double animTime,
  ) {
    _fillPaint.color = dayProgress > 0.62
        ? const Color(0x44FFE0B2)
        : const Color(0x48FFFFFF);
    final halfSpanX = gridSize * iso.tileWidth * 0.60;
    final spanX = halfSpanX * 2.0;
    final cloudCount = (gridSize ~/ 4).clamp(4, 10);

    for (var c = 0; c < cloudCount; c++) {
      final baseX =
          -halfSpanX + ((animTime * (12.0 + c * 2.5) + c * 310.0) % spanX);
      final baseY = -120.0 + c * (gridSize * iso.tileHeight * 0.13);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(baseX, baseY), width: 130, height: 34),
        _fillPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(baseX - 24, baseY - 10),
          width: 74,
          height: 28,
        ),
        _fillPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(baseX + 26, baseY - 8),
          width: 68,
          height: 26,
        ),
        _fillPaint,
      );
    }
  }

  void drawActivePathDots(Canvas canvas, FarmerState farmer, double animTime) {
    if (farmer.activePath.isEmpty) return;
    final pulse = 0.65 + 0.35 * math.sin(animTime * 6.0);
    _fillPaint.color = Color.fromRGBO(255, 249, 196, 0.72 * pulse);
    for (var i = 0; i < farmer.activePath.length; i++) {
      final node = farmer.activePath[i];
      final w = iso.tileCenterToWorld(node);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w.x, w.y), width: 10, height: 5),
        _fillPaint,
      );
    }
  }

  void drawFarmer(
    Canvas canvas,
    FarmerState farmer,
    double animTime, {
    double dayProgress = 0.35,
  }) {
    final world = iso.gridToWorld(farmer.x, farmer.y);
    final isMoving = farmer.activePath.isNotEmpty;
    final bob = isMoving ? math.sin(farmer.walkBobPhase).abs() * 4.5 : 0.0;
    final workTilt = farmer.workTimer > 0
        ? math.sin(farmer.workTimer * 28.0) * 3.5
        : 0.0;

    final cx = world.x + workTilt;
    final cy = world.y;
    final sunOffsetX = (dayProgress - 0.45) * 7.0;

    _fillPaint.color = const Color(0x3D000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(world.x + sunOffsetX, world.y + 3),
        width: 28,
        height: 13,
      ),
      _fillPaint,
    );

    final step = isMoving ? math.sin(farmer.walkBobPhase) * 3.5 : 0.0;
    final workSquash = farmer.workTimer > 0
        ? math.sin(farmer.workTimer * 26.0) * 0.08
        : 0.0;
    final sx = 1.0 + workSquash;
    final sy = 1.0 - workSquash;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(sx, sy);
    canvas.translate(-cx, -cy);

    _fillPaint.color = const Color(0xFF5D4037);
    canvas.drawCircle(Offset(cx - 4 + step * 0.5, cy - 1), 3.5, _fillPaint);
    canvas.drawCircle(Offset(cx + 4 - step * 0.5, cy - 1), 3.5, _fillPaint);

    final torsoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 13 - bob), width: 16, height: 18),
      const Radius.circular(6),
    );
    _fillPaint.color = const Color(0xFFFFCA28);
    canvas.drawRRect(torsoRect, _fillPaint);
    final overallsRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 10 - bob), width: 15, height: 12),
      const Radius.circular(5),
    );
    _fillPaint.color = const Color(0xFF1E88E5);
    canvas.drawRRect(overallsRect, _fillPaint);

    _fillPaint.color = const Color(0xFFFFCCBC);
    canvas.drawCircle(Offset(cx, cy - 26 - bob), 7.2, _fillPaint);

    // Cozy straw sunhat with coral ribbon
    _fillPaint.color = const Color(0xFFFFE082);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 31 - bob), width: 26, height: 9),
      _fillPaint,
    );
    _fillPaint.color = const Color(0xFFFFD54F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy - 34.5 - bob),
          width: 15,
          height: 7,
        ),
        const Radius.circular(4),
      ),
      _fillPaint,
    );
    _strokePaint
      ..color = const Color(0xFFEF5350)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(
      Offset(cx - 7, cy - 31.5 - bob),
      Offset(cx + 7, cy - 31.5 - bob),
      _strokePaint,
    );

    canvas.restore();

    // Stacked wooden crates carried in Sol's arms
    if (farmer.carriedCrates.isNotEmpty) {
      final dirSign = (farmer.facingX - farmer.facingY) >= 0 ? 1.0 : -1.0;
      final stackBaseX = cx + dirSign * 12.0;
      for (var i = 0; i < farmer.carriedCrates.length; i++) {
        CanvasDrawHelpers.drawWoodenCrate(
          canvas,
          Offset(stackBaseX, cy - 11 - bob - i * 11.5),
          farmer.carriedCrates[i],
          scale: 0.78,
        );
      }
    }

    // Active tool action icon pop above sunhat!
    if (farmer.workTimer > 0.01 && farmer.lastActionEmoji != null) {
      CanvasDrawHelpers.drawCenteredText(
        canvas,
        farmer.lastActionEmoji!,
        Offset(cx, cy - 46 - bob),
        _workEmojiStyle,
      );
    }
  }

  void drawVillager(
    Canvas canvas,
    StrollingVillager villager,
    ProductId? boomHighlight,
    double animTime, {
    double dayProgress = 0.35,
  }) {
    final world = iso.gridToWorld(villager.gx, 0.0);
    final bob = villager.pauseTimer > 0
        ? 0.0
        : math.sin(animTime * 7.5 + villager.gx * 2.0).abs() * 3.0;
    final cx = world.x;
    final cy = world.y;
    final sunOffsetX = (dayProgress - 0.45) * 6.0;

    _fillPaint.color = const Color(0x30000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + sunOffsetX, cy + 2),
        width: 22,
        height: 10,
      ),
      _fillPaint,
    );
    _fillPaint.color = villager.tunicColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy - 11 - bob),
          width: 13,
          height: 16,
        ),
        const Radius.circular(5),
      ),
      _fillPaint,
    );
    _fillPaint.color = const Color(0xFFFFCCBC);
    canvas.drawCircle(Offset(cx, cy - 23 - bob), 6.0, _fillPaint);
    _fillPaint.color = villager.hairColor;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - 24 - bob), width: 13, height: 11),
      math.pi,
      math.pi,
      true,
      _fillPaint,
    );

    // Signature villager hat / accessory per townsfolk identity (0..4)
    if (villager.variant == 0 || villager.variant == 1) {
      // Baker Mateo & Chef Clara crisp white toque
      _fillPaint.color = const Color(0xFFFFFFFF);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, cy - 30 - bob),
            width: 11,
            height: 7,
          ),
          const Radius.circular(3),
        ),
        _fillPaint,
      );
    } else if (villager.variant == 2) {
      // Florist Mina blossom pin
      _fillPaint.color = const Color(0xFFEC407A);
      canvas.drawCircle(Offset(cx + 5, cy - 27 - bob), 3.0, _fillPaint);
    } else if (villager.variant == 3) {
      // Grandpa Leo cozy tweed cap brim
      _fillPaint.color = const Color(0xFF8D6E63);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy - 28 - bob),
          width: 17,
          height: 5,
        ),
        _fillPaint,
      );
    } else if (villager.variant == 4) {
      // Mayor Sunny golden crown-ribbon band
      _fillPaint.color = const Color(0xFFFFCA28);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(cx, cy - 27 - bob),
          width: 12,
          height: 3.2,
        ),
        _fillPaint,
      );
    }

    if (villager.heartTimer > 0.0) {
      CanvasDrawHelpers.drawCenteredText(
        canvas,
        '💛',
        Offset(cx, cy - 39 - bob),
        _villagerCravingStyle,
      );
    } else if (boomHighlight != null &&
        (villager.pauseTimer > 0 ||
            (animTime.floor() + villager.gx.round()) % 5 == 0)) {
      final bubbleCenter = Offset(cx, cy - 41 - bob);
      final bubble = RRect.fromRectAndRadius(
        Rect.fromCenter(center: bubbleCenter, width: 26, height: 18),
        const Radius.circular(9),
      );
      _fillPaint.color = const Color(0xEEFFFFFF);
      canvas.drawRRect(bubble, _fillPaint);
      CanvasDrawHelpers.drawCenteredText(
        canvas,
        SolvilleCatalog.productEmoji(boomHighlight),
        bubbleCenter,
        _villagerCravingStyle,
      );
    }
  }

  void drawFloatingVfx(Canvas canvas, List<FloatingVfx> effects) {
    for (var i = 0; i < effects.length; i++) {
      final fx = effects[i];
      final t = (fx.life / fx.maxLife).clamp(0.0, 1.0);
      if (fx.text != null) {
        // Quantize alpha to 20 steps and reuse cached TextStyle instances so
        // TextPainter cache hits across frames.
        final alphaStep = (t * 20.0).round().clamp(0, 20);
        if (alphaStep <= 0) continue;
        CanvasDrawHelpers.drawCenteredText(
          canvas,
          fx.text!,
          Offset(fx.x, fx.y),
          _getFloatingTextStyle(fx.color, alphaStep),
        );
      } else if (fx.isRing) {
        final radius = fx.size * (1.8 - t * 0.8);
        _strokePaint
          ..color = fx.color.withValues(alpha: t * 0.65)
          ..strokeWidth = 2.4;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(fx.x, fx.y),
            width: radius * 2.0,
            height: radius,
          ),
          _strokePaint,
        );
      } else {
        _fillPaint.color = fx.color.withValues(alpha: t);
        canvas.drawCircle(
          Offset(fx.x, fx.y),
          fx.size * (0.4 + 0.6 * t),
          _fillPaint,
        );
      }
    }
  }

  void drawAmbientButterfliesFirefliesAndRain(
    Canvas canvas, {
    required int gridSize,
    required WeatherType weather,
    required double dayProgress,
    required double animTime,
  }) {
    if (weather == WeatherType.gentleRain) {
      final halfSpanX = gridSize * iso.tileWidth * 0.55;
      final spanX = halfSpanX * 2.0;
      final spanXInt = spanX.round();
      final spanY = gridSize * iso.tileHeight * 1.05;
      for (var i = 0; i < 64; i++) {
        final seedX = ((i * 137) % spanXInt) - halfSpanX;
        final cycle = (animTime * 280.0 + i * 53.0) % spanY;
        final rx = seedX - cycle * 0.18;
        final ry = cycle;
        canvas.drawLine(Offset(rx, ry), Offset(rx - 4, ry + 13), _rainPaint);
      }
      return;
    }

    // Golden twilight fireflies as evening settles over Solville!
    if (dayProgress > 0.60) {
      final duskAlpha = ((dayProgress - 0.60) / 0.35).clamp(0.0, 1.0);
      for (var f = 0; f < 8; f++) {
        final gx =
            2.0 +
            ((f * 3.1) % (gridSize - 3)) +
            math.sin(animTime * 0.9 + f * 1.7) * 1.2;
        final gy =
            2.0 +
            ((f * 2.3) % (gridSize - 3)) +
            math.cos(animTime * 0.8 + f * 2.1) * 1.2;
        final w = iso.gridToWorld(gx, gy, gz: 0.9);
        final blink = (math.sin(animTime * 3.8 + f * 1.9) + 1.0) * 0.5;
        final center = Offset(w.x, w.y);
        _fillPaint.color = Color.fromRGBO(
          255,
          238,
          88,
          0.28 * blink * duskAlpha,
        );
        canvas.drawCircle(center, 6.5, _fillPaint);
        _fillPaint.color = Color.fromRGBO(
          255,
          255,
          180,
          0.88 * blink * duskAlpha,
        );
        canvas.drawCircle(center, 2.2, _fillPaint);
      }
      return;
    }

    // Daytime meadow butterflies
    for (var b = 0; b < 3; b++) {
      final pos = butterflyWorldPos(iso, b, animTime);
      final flap = (math.sin(animTime * 12.0 + b) + 1.0) * 2.2 + 1.5;
      _fillPaint.color = switch (b) {
        0 => const Color(0xFFFFF176),
        1 => const Color(0xFFF48FB1),
        _ => const Color(0xFF81D4FA),
      };
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(pos.dx - flap * 0.6, pos.dy),
          width: flap,
          height: 5,
        ),
        _fillPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(pos.dx + flap * 0.6, pos.dy),
          width: flap,
          height: 5,
        ),
        _fillPaint,
      );
    }
  }

  /// Computes deterministic world coordinates for butterfly [b] at [animTime].
  static Offset butterflyWorldPos(IsoProjection iso, int b, double animTime) {
    final gx = 4.2 + math.sin(animTime * 0.55 + b * 2.4) * 3.0;
    final gy = 4.2 + math.cos(animTime * 0.45 + b * 1.9) * 2.7;
    final w = iso.gridToWorld(gx, gy, gz: 1.2);
    return Offset(w.x, w.y);
  }

  /// Draws zero-text bouncing visual spotlight for the 3-step opening tutorial.
  void drawOnboardingSpotlight(
    Canvas canvas,
    GridPos targetPos,
    String hintEmoji,
    double animTime,
  ) {
    final center = iso.tileCenterToWorld(targetPos);
    final bounce = math.sin(animTime * 5.2).abs() * 7.0;
    final pulse = 0.65 + 0.35 * math.sin(animTime * 4.5);

    _strokePaint
      ..color = Color.fromRGBO(255, 193, 7, 0.85 * pulse)
      ..strokeWidth = 3.0;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.x, center.y + 1),
        width: 58 + pulse * 6,
        height: 29 + pulse * 3,
      ),
      _strokePaint,
    );

    final badgeCenter = Offset(center.x, center.y - 46 - bounce);
    final pill = RRect.fromRectAndRadius(
      Rect.fromCenter(center: badgeCenter, width: 54, height: 26),
      const Radius.circular(13),
    );
    _fillPaint.color = const Color(0xFAFFFDE7);
    canvas.drawRRect(pill, _fillPaint);
    _strokePaint
      ..color = const Color(0xFFFF8F00)
      ..strokeWidth = 2.0;
    canvas.drawRRect(pill, _strokePaint);
    CanvasDrawHelpers.drawCenteredText(
      canvas,
      hintEmoji,
      badgeCenter,
      _villagerCravingStyle,
    );
  }

  void spawnForSimEvent(
    List<FloatingVfx> pool,
    SimEvent event,
    math.Random rng,
  ) {
    final pos = event.tile;
    final world = pos != null ? iso.tileCenterToWorld(pos) : (x: 0.0, y: 120.0);

    switch (event.type) {
      case SimEventType.dig:
        for (var i = 0; i < 6; i++) {
          pool.add(
            FloatingVfx(
              x: world.x + (rng.nextDouble() - 0.5) * 18,
              y: world.y - 4,
              vx: (rng.nextDouble() - 0.5) * 36,
              vy: -24 - rng.nextDouble() * 24,
              color: const Color(0xFF8D6E63),
              maxLife: 0.45,
              size: 3.6,
            ),
          );
        }
      case SimEventType.water:
      case SimEventType.refill:
        for (var i = 0; i < 8; i++) {
          pool.add(
            FloatingVfx(
              x: world.x + (rng.nextDouble() - 0.5) * 20,
              y: world.y - 10,
              vx: (rng.nextDouble() - 0.5) * 40,
              vy: -22 - rng.nextDouble() * 26,
              color: const Color(0xFF4FC3F7),
              maxLife: 0.55,
              size: 3.8,
            ),
          );
        }
      case SimEventType.sprinklerPulse:
        pool.add(
          FloatingVfx(
            x: world.x,
            y: world.y,
            vx: 0,
            vy: 0,
            color: const Color(0xFF29B6F6),
            maxLife: 0.75,
            size: event.radius * 46.0,
            isRing: true,
          ),
        );
      case SimEventType.plant:
      case SimEventType.compost:
        for (var i = 0; i < 7; i++) {
          pool.add(
            FloatingVfx(
              x: world.x + (rng.nextDouble() - 0.5) * 22,
              y: world.y - 12,
              vx: (rng.nextDouble() - 0.5) * 34,
              vy: -30 - rng.nextDouble() * 24,
              color: const Color(0xFFFFEE58),
              maxLife: 0.60,
              size: 3.8,
            ),
          );
        }
      case SimEventType.harvest:
        for (var i = 0; i < 9; i++) {
          pool.add(
            FloatingVfx(
              x: world.x + (rng.nextDouble() - 0.5) * 24,
              y: world.y - 12,
              vx: (rng.nextDouble() - 0.5) * 44,
              vy: -34 - rng.nextDouble() * 28,
              color: const Color(0xFFFFEE58),
              maxLife: 0.65,
              size: 4.0,
            ),
          );
        }
        if (event.amount >= 2) {
          pool.add(
            FloatingVfx(
              x: world.x,
              y: world.y - 38,
              vx: 0,
              vy: -30,
              color: const Color(0xFFFF8F00),
              maxLife: 1.05,
              text: '×${event.amount}!',
            ),
          );
        }
      case SimEventType.goldenHarvest:
        pool.add(
          FloatingVfx(
            x: world.x,
            y: world.y - 6,
            vx: 0,
            vy: 0,
            color: const Color(0xFFFFD54F),
            maxLife: 0.85,
            size: 36.0,
            isRing: true,
          ),
        );
        for (var i = 0; i < 16; i++) {
          pool.add(
            FloatingVfx(
              x: world.x + (rng.nextDouble() - 0.5) * 28,
              y: world.y - 18,
              vx: (rng.nextDouble() - 0.5) * 68,
              vy: -42 - rng.nextDouble() * 34,
              color: i.isEven
                  ? const Color(0xFFFFCA28)
                  : const Color(0xFFFF80AB),
              maxLife: 0.90,
              size: 4.4,
            ),
          );
        }
        pool.add(
          FloatingVfx(
            x: world.x,
            y: world.y - 44,
            vx: 0,
            vy: -30,
            color: const Color(0xFFFFCA28),
            maxLife: 1.45,
            text: event.message ?? '✨ 2×!',
          ),
        );
      case SimEventType.weedTreasure:
      case SimEventType.butterflyBoop:
      case SimEventType.kettleRecipeChanged:
        for (var i = 0; i < 7; i++) {
          pool.add(
            FloatingVfx(
              x: world.x + (rng.nextDouble() - 0.5) * 20,
              y: world.y - 14,
              vx: (rng.nextDouble() - 0.5) * 38,
              vy: -28 - rng.nextDouble() * 24,
              color: event.type == SimEventType.butterflyBoop
                  ? const Color(0xFFF48FB1)
                  : const Color(0xFFA5D6A7),
              maxLife: 0.60,
              size: 3.6,
            ),
          );
        }
        if (event.message != null) {
          pool.add(
            FloatingVfx(
              x: world.x,
              y: world.y - 36,
              vx: 0,
              vy: -26,
              color: const Color(0xFFFFF59D),
              maxLife: 1.25,
              text: event.message,
            ),
          );
        }
      case SimEventType.expressOrderFulfilled:
      case SimEventType.landmarkDiscovered:
      case SimEventType.villageRushStarted:
        pool.add(
          FloatingVfx(
            x: world.x,
            y: world.y - 8,
            vx: 0,
            vy: 0,
            color: const Color(0xFF4DD0E1),
            maxLife: 0.90,
            size: 42.0,
            isRing: true,
          ),
        );
        for (var i = 0; i < 14; i++) {
          pool.add(
            FloatingVfx(
              x: world.x + (rng.nextDouble() - 0.5) * 26,
              y: world.y - 20,
              vx: (rng.nextDouble() - 0.5) * 60,
              vy: -36 - rng.nextDouble() * 32,
              color: i.isEven
                  ? const Color(0xFFFFD54F)
                  : const Color(0xFF4FC3F7),
              maxLife: 0.85,
              size: 4.2,
            ),
          );
        }
        if (event.amount > 0) {
          pool.add(
            FloatingVfx(
              x: world.x,
              y: world.y - 46,
              vx: 0,
              vy: -30,
              color: const Color(0xFFFFCA28),
              maxLife: 1.45,
              text: '+${event.amount}☀️',
            ),
          );
        }
      case SimEventType.coinsEarned:
        if (event.amount > 0) {
          for (var i = 0; i < 6; i++) {
            pool.add(
              FloatingVfx(
                x: world.x + (rng.nextDouble() - 0.5) * 24,
                y: world.y - 24,
                vx: (rng.nextDouble() - 0.5) * 42,
                vy: -26 - rng.nextDouble() * 24,
                color: const Color(0xFFFFE082),
                maxLife: 0.65,
                size: 3.4,
              ),
            );
          }
          pool.add(
            FloatingVfx(
              x: world.x,
              y: world.y - 42,
              vx: 0,
              vy: -28,
              color: const Color(0xFFFFD54F),
              maxLife: 1.35,
              text: '+${event.amount}☀️',
            ),
          );
        }
      case SimEventType.shopPurchase:
      case SimEventType.trophyUnlocked:
      case SimEventType.newDay:
      case SimEventType.statusHint:
        break;
    }
  }
}
