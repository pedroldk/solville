import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart'
    show FontWeight, TextDirection, TextPainter, TextSpan, TextStyle;

import '../../domain/iso/iso_projection.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/game_state.dart';
import 'structures_and_crops_painter.dart';

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

/// Ambient villager strolling along Solville's northern cobble lane (`y = 0`).
class StrollingVillager {
  StrollingVillager({
    required this.gx,
    required this.speed,
    required this.tunicColor,
    required this.hairColor,
  });

  double gx;
  double speed;
  final Color tunicColor;
  final Color hairColor;
  double pauseTimer = 0.0;
}

/// Renders sky clouds, A* stepping dots, Sol (with stacked crates & work tool
/// popups!), strolling townsfolk with Boom thought bubbles, twilight fireflies,
/// butterflies, sunshowers, and transient VFX particles.
class CharactersAndFxPainter {
  const CharactersAndFxPainter(this.iso, this.structuresPainter);

  final IsoProjection iso;
  final StructuresAndCropsPainter structuresPainter;

  void drawSkyClouds(Canvas canvas, double dayProgress, double animTime) {
    final tint = dayProgress > 0.62
        ? const Color(0x44FFE0B2)
        : const Color(0x48FFFFFF);
    final cloudPaint = Paint()..color = tint;

    for (var c = 0; c < 4; c++) {
      final baseX = -520.0 + ((animTime * (12.0 + c * 3.0) + c * 290.0) % 1160.0);
      final baseY = -110.0 + c * 95.0;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(baseX, baseY), width: 130, height: 34),
        cloudPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(baseX - 24, baseY - 10),
          width: 74,
          height: 28,
        ),
        cloudPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(baseX + 26, baseY - 8),
          width: 68,
          height: 26,
        ),
        cloudPaint,
      );
    }
  }

  void drawActivePathDots(Canvas canvas, FarmerState farmer, double animTime) {
    if (farmer.activePath.isEmpty) return;
    final pulse = 0.65 + 0.35 * math.sin(animTime * 6.0);
    for (var i = 0; i < farmer.activePath.length; i++) {
      final node = farmer.activePath[i];
      final w = iso.tileCenterToWorld(node);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w.x, w.y), width: 10, height: 5),
        Paint()..color = Color.fromRGBO(255, 249, 196, 0.72 * pulse),
      );
    }
  }

  void drawFarmer(Canvas canvas, FarmerState farmer, double animTime) {
    final world = iso.gridToWorld(farmer.x, farmer.y);
    final isMoving = farmer.activePath.isNotEmpty;
    final bob = isMoving ? math.sin(farmer.walkBobPhase).abs() * 4.5 : 0.0;
    final workTilt = farmer.workTimer > 0
        ? math.sin(farmer.workTimer * 28.0) * 3.5
        : 0.0;

    final cx = world.x + workTilt;
    final cy = world.y;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(world.x, world.y + 3),
        width: 28,
        height: 13,
      ),
      Paint()..color = const Color(0x3D000000),
    );

    final step = isMoving ? math.sin(farmer.walkBobPhase) * 3.5 : 0.0;
    canvas.drawCircle(
      Offset(cx - 4 + step * 0.5, cy - 1),
      3.5,
      Paint()..color = const Color(0xFF5D4037),
    );
    canvas.drawCircle(
      Offset(cx + 4 - step * 0.5, cy - 1),
      3.5,
      Paint()..color = const Color(0xFF5D4037),
    );

    final torsoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 13 - bob), width: 16, height: 18),
      const Radius.circular(6),
    );
    canvas.drawRRect(torsoRect, Paint()..color = const Color(0xFFFFCA28));
    final overallsRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 10 - bob), width: 15, height: 12),
      const Radius.circular(5),
    );
    canvas.drawRRect(overallsRect, Paint()..color = const Color(0xFF1E88E5));

    canvas.drawCircle(
      Offset(cx, cy - 26 - bob),
      7.2,
      Paint()..color = const Color(0xFFFFCCBC),
    );

    // Cozy straw sunhat with coral ribbon
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy - 31 - bob),
        width: 26,
        height: 9,
      ),
      Paint()..color = const Color(0xFFFFE082),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy - 34.5 - bob),
          width: 15,
          height: 7,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFFFD54F),
    );
    canvas.drawLine(
      Offset(cx - 7, cy - 31.5 - bob),
      Offset(cx + 7, cy - 31.5 - bob),
      Paint()
        ..color = const Color(0xFFEF5350)
        ..strokeWidth = 2.0,
    );

    // Stacked wooden crates carried in Sol's arms
    if (farmer.carriedCrates.isNotEmpty) {
      final dirSign = (farmer.facingX - farmer.facingY) >= 0 ? 1.0 : -1.0;
      final stackBaseX = cx + dirSign * 12.0;
      for (var i = 0; i < farmer.carriedCrates.length; i++) {
        structuresPainter.drawWoodenCrate(
          canvas,
          Offset(stackBaseX, cy - 11 - bob - i * 11.5),
          farmer.carriedCrates[i],
          scale: 0.78,
        );
      }
    }

    // Active tool action icon pop above sunhat!
    if (farmer.workTimer > 0.01 && farmer.lastActionEmoji != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: farmer.lastActionEmoji,
          style: const TextStyle(fontSize: 15),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width * 0.5, cy - 54 - bob));
    }
  }

  void drawVillager(
    Canvas canvas,
    StrollingVillager villager,
    ProductId? boomHighlight,
    double animTime,
  ) {
    final world = iso.gridToWorld(villager.gx, 0.0);
    final bob = villager.pauseTimer > 0
        ? 0.0
        : math.sin(animTime * 7.5 + villager.gx * 2.0).abs() * 3.0;
    final cx = world.x;
    final cy = world.y;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 2), width: 22, height: 10),
      Paint()..color = const Color(0x30000000),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy - 11 - bob),
          width: 13,
          height: 16,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = villager.tunicColor,
    );
    canvas.drawCircle(
      Offset(cx, cy - 23 - bob),
      6.0,
      Paint()..color = const Color(0xFFFFCCBC),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, cy - 24 - bob),
        width: 13,
        height: 11,
      ),
      math.pi,
      math.pi,
      true,
      Paint()..color = villager.hairColor,
    );

    // Villager craving thought bubble hinting at today's hot Boom good!
    if (boomHighlight != null &&
        (villager.pauseTimer > 0 || (animTime.floor() + villager.gx.round()) % 5 == 0)) {
      final bubble = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 40 - bob), width: 26, height: 18),
        const Radius.circular(9),
      );
      canvas.drawRRect(bubble, Paint()..color = const Color(0xEEFFFFFF));
      final tp = TextPainter(
        text: TextSpan(
          text: SolvilleCatalog.productEmoji(boomHighlight),
          style: const TextStyle(fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(cx - tp.width * 0.5, cy - 40 - bob - tp.height * 0.5),
      );
    }
  }

  void drawFloatingVfx(Canvas canvas, List<FloatingVfx> effects) {
    for (final fx in effects) {
      final t = (fx.life / fx.maxLife).clamp(0.0, 1.0);
      if (fx.text != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: fx.text,
            style: TextStyle(
              color: fx.color.withValues(alpha: t),
              fontSize: 14.0,
              fontWeight: FontWeight.w900,
              shadows: <Shadow>[
                Shadow(
                  color: const Color(0xAA3E2723).withValues(alpha: t),
                  offset: const Offset(0, 1.5),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(fx.x - tp.width * 0.5, fx.y - tp.height * 0.5),
        );
      } else if (fx.isRing) {
        final radius = fx.size * (1.8 - t * 0.8);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(fx.x, fx.y),
            width: radius * 2.0,
            height: radius,
          ),
          Paint()
            ..color = fx.color.withValues(alpha: t * 0.65)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4,
        );
      } else {
        canvas.drawCircle(
          Offset(fx.x, fx.y),
          fx.size * (0.4 + 0.6 * t),
          Paint()..color = fx.color.withValues(alpha: t),
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
      final rainPaint = Paint()
        ..color = const Color(0x66B3E5FC)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 42; i++) {
        final seedX = ((i * 97) % 900) - 450.0;
        final cycle = (animTime * 260.0 + i * 47.0) % 520.0;
        final rx = seedX - cycle * 0.18;
        final ry = cycle;
        canvas.drawLine(Offset(rx, ry), Offset(rx - 4, ry + 13), rainPaint);
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
        canvas.drawCircle(
          Offset(w.x, w.y),
          6.5,
          Paint()
            ..color = Color.fromRGBO(
              255,
              238,
              88,
              0.28 * blink * duskAlpha,
            ),
        );
        canvas.drawCircle(
          Offset(w.x, w.y),
          2.2,
          Paint()
            ..color = Color.fromRGBO(
              255,
              255,
              180,
              0.88 * blink * duskAlpha,
            ),
        );
      }
      return;
    }

    // Daytime meadow butterflies
    for (var b = 0; b < 3; b++) {
      final gx = 4.2 + math.sin(animTime * 0.55 + b * 2.4) * 3.0;
      final gy = 4.2 + math.cos(animTime * 0.45 + b * 1.9) * 2.7;
      final w = iso.gridToWorld(gx, gy, gz: 1.2);
      final flap = (math.sin(animTime * 12.0 + b) + 1.0) * 2.2 + 1.5;
      final wingColor = switch (b) {
        0 => const Color(0xFFFFF176),
        1 => const Color(0xFFF48FB1),
        _ => const Color(0xFF81D4FA),
      };
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w.x - flap * 0.6, w.y),
          width: flap,
          height: 5,
        ),
        Paint()..color = wingColor,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w.x + flap * 0.6, w.y),
          width: flap,
          height: 5,
        ),
        Paint()..color = wingColor,
      );
    }
  }

  void spawnForSimEvent(
    List<FloatingVfx> pool,
    SimEvent event,
    math.Random rng,
  ) {
    final pos = event.tile;
    final world = pos != null
        ? iso.tileCenterToWorld(pos)
        : (x: 0.0, y: 120.0);

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
      case SimEventType.harvest:
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
      case SimEventType.coinsEarned:
        if (event.amount > 0) {
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
