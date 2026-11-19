import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show FontWeight, Shadow, TextStyle;

import '../../domain/iso/iso_projection.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/grid_pos.dart';
import 'canvas_draw_helpers.dart';

enum ParticleShape { circle, star4, droplet, leaf, clod, petal, smoke, ring, text }

/// Floating particle, arcing droplet/clod, expanding ripple, or text popup
/// in world coordinates with simple gravity, drag, and rotation physics.
class FloatingVfx {
  FloatingVfx({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.maxLife,
    this.ay = 0.0,
    this.drag = 0.0,
    this.angle = 0.0,
    this.angularVelocity = 0.0,
    this.size = 4.0,
    this.text,
    this.isRing = false,
    ParticleShape? shape,
  }) : life = maxLife,
       shape =
           shape ??
           (isRing
               ? ParticleShape.ring
               : (text != null ? ParticleShape.text : ParticleShape.circle));

  double x;
  double y;
  double vx;
  double vy;
  final double ay;
  final double drag;
  double angle;
  final double angularVelocity;
  final Color color;
  final double maxLife;
  double life;
  final double size;
  final String? text;
  final bool isRing;
  final ParticleShape shape;
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
  String? purchaseBubbleText;
}

/// Renders A* stepping dots, expressive Sol (with animated work props, crates,
/// blinking eyes, braided hair & fluttering sunhat ribbon), distinct townsfolk
/// villagers, 4-wing butterflies with ground shadows, drifting sunlit blossoms,
/// twilight fireflies, splashing rain, and physics-driven VFX particles.
class CharactersAndFxPainter {
  CharactersAndFxPainter(this.iso);

  final IsoProjection iso;

  final Paint _fillPaint = Paint();
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final Path _pointerPath = Path();
  final Path _shapePath = Path();
  final Paint _rainPaint = Paint()
    ..color = const Color(0x70CBEFFF)
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;

  static const TextStyle _villagerCravingStyle = TextStyle(
    color: Color(0xFF3E2723),
    fontSize: 11,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle _spotlightTextStyle = TextStyle(
    color: Color(0xFF3E2723),
    fontSize: 11,
    fontWeight: FontWeight.w900,
  );

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
            color: const Color(0xBA3E2723).withValues(alpha: qAlpha),
            offset: const Offset(0, 1.5),
            blurRadius: 2.5,
          ),
        ],
      );
      styles[alphaStep] = cached;
    }
    return cached;
  }

  void drawActivePathDots(Canvas canvas, FarmerState farmer, double animTime) {
    if (farmer.activePath.isEmpty) return;
    final pulse = 0.65 + 0.35 * math.sin(animTime * 3.4);
    for (var i = 0; i < farmer.activePath.length; i++) {
      final node = farmer.activePath[i];
      final w = iso.tileCenterToWorld(node);
      final isLast = i == farmer.activePath.length - 1;
      if (isLast) {
        _strokePaint
          ..color = Color.fromRGBO(255, 213, 79, 0.80 * pulse)
          ..strokeWidth = 2.0;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w.x, w.y),
            width: 18 + pulse * 4,
            height: 9 + pulse * 2,
          ),
          _strokePaint,
        );
      }
      _fillPaint.color = Color.fromRGBO(255, 249, 196, 0.80 * pulse);
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
    final bob = isMoving
        ? math.sin(farmer.walkBobPhase).abs() * 2.8
        : math.sin(animTime * 2.6) * 0.55;
    final workTilt = farmer.workTimer > 0
        ? math.sin(farmer.workTimer * 15.0) * 2.5
        : 0.0;

    final cx = world.x + workTilt;
    final cy = world.y;
    final sunOffsetX = (dayProgress - 0.45) * 8.0;

    // Soft directional sun shadow + contact AO
    _fillPaint.color = const Color(0x281B0E0C);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(world.x + sunOffsetX, world.y + 3.5),
        width: 30,
        height: 14,
      ),
      _fillPaint,
    );
    _fillPaint.color = const Color(0x361B0E0C);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(world.x, world.y + 2),
        width: 22,
        height: 10,
      ),
      _fillPaint,
    );

    final step = isMoving ? math.sin(farmer.walkBobPhase) * 2.5 : 0.0;
    final dirSign = (farmer.facingX - farmer.facingY) >= 0 ? 1.0 : -1.0;
    final workSquash = farmer.workTimer > 0
        ? math.sin(farmer.workTimer * 15.0) * 0.065
        : 0.0;
    final sx = 1.0 + workSquash;
    final sy = 1.0 - workSquash;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(sx, sy);

    // Articulated gardening boots
    _fillPaint.color = const Color(0xFF5D4037);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-4.2 + step * 0.6, -1.2), width: 6.8, height: 4.5),
      _fillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(4.2 - step * 0.6, -1.2), width: 6.8, height: 4.5),
      _fillPaint,
    );

    // Warm yellow sunlit blouse & sleeves
    final torsoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, -13.5 - bob), width: 17, height: 18),
      const Radius.circular(6.5),
    );
    _fillPaint.color = const Color(0xFFFFD54F);
    canvas.drawRRect(torsoRect, _fillPaint);

    // Animated arms
    final armSwing = isMoving ? math.sin(farmer.walkBobPhase) * 3.0 : 0.0;
    _strokePaint
      ..color = const Color(0xFFFFCA28)
      ..strokeWidth = 3.8;
    canvas.drawLine(
      Offset(-7.5, -18 - bob),
      Offset(-10.0, -10.5 - bob + armSwing * 0.5),
      _strokePaint,
    );
    canvas.drawLine(
      Offset(7.5, -18 - bob),
      Offset(10.0, -10.5 - bob - armSwing * 0.5),
      _strokePaint,
    );

    // Denim overalls + overall straps + brass buttons
    final overallsRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, -10 - bob), width: 15.5, height: 12.5),
      const Radius.circular(5),
    );
    _fillPaint.color = const Color(0xFF1E88E5);
    canvas.drawRRect(overallsRect, _fillPaint);
    _fillPaint.color = const Color(0xFF1565C0);
    canvas.drawRect(Rect.fromLTWH(-5, -18 - bob, 2.8, 6), _fillPaint);
    canvas.drawRect(Rect.fromLTWH(2.2, -18 - bob, 2.8, 6), _fillPaint);
    _fillPaint.color = const Color(0xFFFFE082);
    canvas.drawCircle(Offset(-3.6, -14.2 - bob), 1.1, _fillPaint);
    canvas.drawCircle(Offset(3.6, -14.2 - bob), 1.1, _fillPaint);

    // Chestnut braided pigtails peeking from beneath sunhat
    _fillPaint.color = const Color(0xFF6D4C41);
    canvas.drawCircle(Offset(-6.5, -24.5 - bob), 3.0, _fillPaint);
    canvas.drawCircle(Offset(6.5, -24.5 - bob), 3.0, _fillPaint);
    canvas.drawCircle(Offset(-7.0, -21.5 - bob), 2.3, _fillPaint);
    canvas.drawCircle(Offset(7.0, -21.5 - bob), 2.3, _fillPaint);

    // Warm face + rosy cheeks + blinking eyes + smile
    _fillPaint.color = const Color(0xFFFFCCBC);
    canvas.drawCircle(Offset(0, -26.5 - bob), 7.4, _fillPaint);
    _fillPaint.color = const Color(0x66FF8A80);
    canvas.drawOval(Rect.fromCenter(center: Offset(-3.8, -24.5 - bob), width: 3.0, height: 1.8), _fillPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(3.8, -24.5 - bob), width: 3.0, height: 1.8), _fillPaint);

    final isBlinking = (animTime % 4.2) > 4.05;
    if (isBlinking) {
      _strokePaint
        ..color = const Color(0xFF3E2723)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(-3.5 + dirSign * 0.6, -26.8 - bob), Offset(-1.5 + dirSign * 0.6, -26.8 - bob), _strokePaint);
      canvas.drawLine(Offset(1.5 + dirSign * 0.6, -26.8 - bob), Offset(3.5 + dirSign * 0.6, -26.8 - bob), _strokePaint);
    } else {
      _fillPaint.color = const Color(0xFF3E2723);
      canvas.drawCircle(Offset(-2.4 + dirSign * 0.7, -26.8 - bob), 1.05, _fillPaint);
      canvas.drawCircle(Offset(2.4 + dirSign * 0.7, -26.8 - bob), 1.05, _fillPaint);
    }

    // Cozy woven straw sunhat with coral ribbon & fluttering tails
    _fillPaint.color = const Color(0x444E342E);
    canvas.drawOval(Rect.fromCenter(center: Offset(0, -30.5 - bob), width: 27, height: 9.5), _fillPaint);
    _fillPaint.color = const Color(0xFFFFE082);
    canvas.drawOval(Rect.fromCenter(center: Offset(0, -31.5 - bob), width: 27, height: 9.2), _fillPaint);
    _strokePaint
      ..color = const Color(0x888D6E63)
      ..strokeWidth = 1.1;
    canvas.drawOval(Rect.fromCenter(center: Offset(0, -31.5 - bob), width: 27, height: 9.2), _strokePaint);

    _fillPaint.color = const Color(0xFFFFD54F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -35.2 - bob), width: 15.5, height: 7.5),
        const Radius.circular(4),
      ),
      _fillPaint,
    );
    _strokePaint
      ..color = const Color(0xFFEF5350)
      ..strokeWidth = 2.2;
    canvas.drawLine(Offset(-7.2, -32.2 - bob), Offset(7.2, -32.2 - bob), _strokePaint);
    final ribbonFlutter = math.sin(animTime * 6.0) * 1.4;
    canvas.drawLine(
      Offset(-dirSign * 7.2, -32.2 - bob),
      Offset(-dirSign * 11.5, -30.0 - bob + ribbonFlutter),
      _strokePaint,
    );

    // Live swinging held tool prop during active work animation
    if (farmer.workTimer > 0.01 && farmer.lastActionEmoji != null) {
      final kind = _actionKindForWorkEmoji(farmer.lastActionEmoji!);
      final swing = math.sin(farmer.workTimer * 18.0) * 0.45 * dirSign;
      canvas.save();
      canvas.translate(dirSign * 10.5, -11.0 - bob);
      canvas.rotate(swing);
      switch (kind) {
        case ActionKind.water:
          _fillPaint.color = const Color(0xFFE69148);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(-4, -3, 7.5, 6),
              const Radius.circular(2),
            ),
            _fillPaint,
          );
          _strokePaint
            ..color = const Color(0xFFD87A32)
            ..strokeWidth = 1.6;
          canvas.drawLine(Offset(dirSign * 2, -1), Offset(dirSign * 8, -4.5), _strokePaint);
          _fillPaint.color = const Color(0xFF4FC3F7);
          canvas.drawCircle(Offset(dirSign * 9.5, -2.5), 1.2, _fillPaint);
          canvas.drawCircle(Offset(dirSign * 10.5, 0.2), 1.0, _fillPaint);
        case ActionKind.dig:
        case ActionKind.removeStructure:
          _strokePaint
            ..color = const Color(0xFF8D6E63)
            ..strokeWidth = 2.0;
          canvas.drawLine(const Offset(0, 1), Offset(dirSign * 3.5, -8), _strokePaint);
          _fillPaint.color = const Color(0xFFB0BEC5);
          canvas.drawOval(
            Rect.fromCenter(center: Offset(dirSign * 4.5, -9.5), width: 4.5, height: 5.5),
            _fillPaint,
          );
        case ActionKind.placeBuild:
          _strokePaint
            ..color = const Color(0xFF8D6E63)
            ..strokeWidth = 2.0;
          canvas.drawLine(const Offset(0, 1), Offset(dirSign * 2.5, -7.5), _strokePaint);
          _fillPaint.color = const Color(0xFF5D4037);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(dirSign * 3.0, -8.5), width: 7.5, height: 4.2),
              const Radius.circular(1.2),
            ),
            _fillPaint,
          );
        default:
          _fillPaint.color = const Color(0xFFD7A86E);
          canvas.drawOval(
            Rect.fromCenter(center: Offset(dirSign * 2.5, -3.0), width: 6.5, height: 5.0),
            _fillPaint,
          );
      }
      canvas.restore();
    }

    canvas.restore();

    // Stacked 2.5D wooden crates carried in Sol's arms
    if (farmer.carriedCrates.isNotEmpty) {
      final stackBaseX = cx + dirSign * 13.0;
      for (var i = 0; i < farmer.carriedCrates.length; i++) {
        CanvasDrawHelpers.drawWoodenCrate(
          canvas,
          Offset(stackBaseX, cy - 11 - bob - i * 11.5),
          farmer.carriedCrates[i],
          scale: 0.78,
        );
      }
    }

    // Active animated work prop badge above Sol's sunhat
    if (farmer.workTimer > 0.01 && farmer.lastActionEmoji != null) {
      final propBob = math.sin(farmer.workTimer * 18.0) * 2.0;
      final badgePos = Offset(cx, cy - 45 - bob + propBob);
      _fillPaint.color = const Color(0xECFFFDF6);
      canvas.drawCircle(badgePos, 9.5, _fillPaint);
      _strokePaint
        ..color = const Color(0xFFFFB300)
        ..strokeWidth = 1.5;
      canvas.drawCircle(badgePos, 9.5, _strokePaint);
      CanvasDrawHelpers.drawCanvasActionIcon(
        canvas,
        _actionKindForWorkEmoji(farmer.lastActionEmoji!),
        badgePos,
        11.5,
      );
    }
  }

  ActionKind _actionKindForWorkEmoji(String emoji) => switch (emoji) {
        '⛏️' => ActionKind.dig,
        '🌱' => ActionKind.plant,
        '💧' => ActionKind.water,
        '✨' => ActionKind.compost,
        '📦' => ActionKind.harvest,
        '🪙' => ActionKind.sellAtStall,
        '🏠' => ActionKind.storeInBarn,
        '🌾' => ActionKind.tendAnimal,
        '🫙' => ActionKind.loadArtisan,
        '🔨' => ActionKind.placeBuild,
        '🌿' => ActionKind.removeStructure,
        '💎' => ActionKind.claimLandmark,
        _ => ActionKind.harvest,
      };

  void drawVillager(
    Canvas canvas,
    StrollingVillager villager,
    ProductId? boomHighlight,
    double animTime, {
    double dayProgress = 0.35,
  }) {
    final world = iso.gridToWorld(villager.gx, 0.0);
    final isWalking = villager.pauseTimer <= 0;
    final walkBob = isWalking
        ? math.sin(animTime * 5.0 + villager.gx * 2.0).abs() * 2.2
        : 0.0;
    final happyHop = villager.heartTimer > 0.0
        ? math.sin(villager.heartTimer * 10.0).abs() * 3.8
        : 0.0;
    final bob = walkBob + happyHop;
    final step = isWalking
        ? math.sin(animTime * 5.0 + villager.gx * 2.0) * 1.8
        : 0.0;
    final cx = world.x;
    final cy = world.y;
    final sunOffsetX = (dayProgress - 0.45) * 6.5;

    // Soft cast shadow & boots
    _fillPaint.color = const Color(0x2E1B0E0C);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + sunOffsetX, cy + 2.5), width: 22, height: 10),
      _fillPaint,
    );
    _fillPaint.color = const Color(0xFF4E342E);
    canvas.drawCircle(Offset(cx - 3 + step * 0.5, cy - 0.5 - happyHop * 0.5), 2.5, _fillPaint);
    canvas.drawCircle(Offset(cx + 3 - step * 0.5, cy - 0.5 - happyHop * 0.5), 2.5, _fillPaint);

    // Shaded villager tunic & cozy apron/vest detail
    _fillPaint.color = villager.tunicColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 11.5 - bob), width: 14, height: 16),
        const Radius.circular(5.5),
      ),
      _fillPaint,
    );

    if (villager.variant == 0 || villager.variant == 1) {
      // Crisp cream apron & warm tucked crusty baguette for Baker Mateo & Chef Clara
      _fillPaint.color = const Color(0xFFFFF8E1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy - 9.5 - bob), width: 9.5, height: 11),
          const Radius.circular(3),
        ),
        _fillPaint,
      );
      _fillPaint.color = const Color(0xFFD49B35);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx + 6.5, cy - 12.5 - bob), width: 3.8, height: 9.5),
          const Radius.circular(1.9),
        ),
        _fillPaint,
      );
      _fillPaint.color = const Color(0xFFFFE082);
      canvas.drawRect(Rect.fromLTWH(cx + 5.6, cy - 14.5 - bob, 1.8, 1.0), _fillPaint);
      canvas.drawRect(Rect.fromLTWH(cx + 5.6, cy - 11.5 - bob, 1.8, 1.0), _fillPaint);
    } else if (villager.variant == 2) {
      // Florist Mina fragrant wrapped flower bouquet
      _fillPaint.color = const Color(0xFFFFF8E1);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 6.5, cy - 9.5 - bob), width: 4.8, height: 7.2),
        _fillPaint,
      );
      _fillPaint.color = const Color(0xFFEC407A);
      canvas.drawCircle(Offset(cx + 5.8, cy - 13.5 - bob), 2.1, _fillPaint);
      _fillPaint.color = const Color(0xFFFFEE58);
      canvas.drawCircle(Offset(cx + 7.6, cy - 13.0 - bob), 1.8, _fillPaint);
      _fillPaint.color = const Color(0xFFBA68C8);
      canvas.drawCircle(Offset(cx + 6.5, cy - 15.0 - bob), 1.7, _fillPaint);
    } else if (villager.variant == 3) {
      // Grandpa Leo carved walnut walking cane
      _strokePaint
        ..color = const Color(0xFF5D4037)
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset(cx + 7.0, cy - 12.5 - happyHop * 0.4),
        Offset(cx + 7.5, cy - 0.5 - happyHop * 0.5),
        _strokePaint,
      );
      canvas.drawArc(
        Rect.fromLTWH(cx + 5.0, cy - 14.5 - happyHop * 0.4, 4.0, 4.0),
        math.pi,
        math.pi,
        false,
        _strokePaint,
      );
    } else if (villager.variant == 4) {
      // Mayor Sunny golden sash + shining town medallion
      _strokePaint
        ..color = const Color(0xFFFFEE58)
        ..strokeWidth = 2.6;
      canvas.drawLine(Offset(cx - 5, cy - 17 - bob), Offset(cx + 5, cy - 6 - bob), _strokePaint);
      _fillPaint.color = const Color(0xFFFFCA28);
      canvas.drawCircle(Offset(cx - 0.5, cy - 11.5 - bob), 2.6, _fillPaint);
      _fillPaint.color = const Color(0xFFFFF9C4);
      canvas.drawCircle(Offset(cx - 0.5, cy - 11.5 - bob), 1.2, _fillPaint);
    }

    // Expressive face + dark eyes + rosy cheeks
    _fillPaint.color = const Color(0xFFFFCCBC);
    canvas.drawCircle(Offset(cx, cy - 23.5 - bob), 6.2, _fillPaint);
    _fillPaint.color = const Color(0x55FF8A80);
    canvas.drawCircle(Offset(cx - 3.2, cy - 22.0 - bob), 1.3, _fillPaint);
    canvas.drawCircle(Offset(cx + 3.2, cy - 22.0 - bob), 1.3, _fillPaint);
    _fillPaint.color = const Color(0xFF3E2723);
    canvas.drawCircle(Offset(cx - 1.9, cy - 23.8 - bob), 0.9, _fillPaint);
    canvas.drawCircle(Offset(cx + 1.9, cy - 23.8 - bob), 0.9, _fillPaint);

    // Hair cap
    _fillPaint.color = villager.hairColor;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - 24.5 - bob), width: 13.5, height: 11),
      math.pi,
      math.pi,
      true,
      _fillPaint,
    );

    // Signature villager headwear & details per character (0..4)
    if (villager.variant == 0 || villager.variant == 1) {
      // Pleated tall baker/chef toque
      _fillPaint.color = const Color(0xFFFFFFFF);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy - 31 - bob), width: 12, height: 8.5),
          const Radius.circular(3.5),
        ),
        _fillPaint,
      );
      _fillPaint.color = const Color(0xFFF5F5F5);
      canvas.drawCircle(Offset(cx - 3, cy - 34 - bob), 3.4, _fillPaint);
      canvas.drawCircle(Offset(cx + 3, cy - 34 - bob), 3.4, _fillPaint);
    } else if (villager.variant == 2) {
      // Florist Mina blossom crown
      _fillPaint.color = const Color(0xFF43A047);
      canvas.drawCircle(Offset(cx + 4.5, cy - 27 - bob), 2.8, _fillPaint);
      _fillPaint.color = const Color(0xFFEC407A);
      canvas.drawCircle(Offset(cx + 4.8, cy - 27.5 - bob), 2.5, _fillPaint);
      _fillPaint.color = const Color(0xFFFFEE58);
      canvas.drawCircle(Offset(cx + 4.8, cy - 27.5 - bob), 1.0, _fillPaint);
    } else if (villager.variant == 3) {
      // Grandpa Leo cozy tweed cap & snowy mustache
      _fillPaint.color = const Color(0xFF8D6E63);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy - 28.5 - bob), width: 17, height: 5.5),
        _fillPaint,
      );
      _fillPaint.color = const Color(0xFFECEFF1);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy - 21.0 - bob), width: 6.5, height: 2.6),
        _fillPaint,
      );
    } else if (villager.variant == 4) {
      // Mayor Sunny golden ribbon hatband
      _fillPaint.color = const Color(0xFFFFCA28);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy - 27.5 - bob), width: 13.5, height: 3.8),
          const Radius.circular(1.8),
        ),
        _fillPaint,
      );
    }

    if (villager.heartTimer > 0.0) {
      final label = villager.purchaseBubbleText ?? '💛';
      if (villager.purchaseBubbleText != null) {
        final bubbleCenter = Offset(cx, cy - 42 - bob);
        final w = (label.length * 6.5 + 14.0).clamp(44.0, 98.0);
        final bubble = RRect.fromRectAndRadius(
          Rect.fromCenter(center: bubbleCenter, width: w, height: 19),
          const Radius.circular(9.5),
        );
        _fillPaint.color = const Color(0x30261412);
        canvas.drawRRect(bubble.shift(const Offset(0, 1.5)), _fillPaint);
        _fillPaint.color = const Color(0xF6FFF8E1);
        canvas.drawRRect(bubble, _fillPaint);
        _strokePaint
          ..color = const Color(0xFFFFB300)
          ..strokeWidth = 1.5;
        canvas.drawRRect(bubble, _strokePaint);
        CanvasDrawHelpers.drawCenteredText(
          canvas,
          label,
          bubbleCenter,
          _villagerCravingStyle,
        );
      } else {
        CanvasDrawHelpers.drawCenteredText(
          canvas,
          label,
          Offset(cx, cy - 40 - bob),
          _villagerCravingStyle,
        );
      }
    }
  }

  void drawFloatingVfx(Canvas canvas, List<FloatingVfx> effects) {
    for (var i = 0; i < effects.length; i++) {
      final fx = effects[i];
      final t = (fx.life / fx.maxLife).clamp(0.0, 1.0);
      switch (fx.shape) {
        case ParticleShape.text:
          if (fx.text == null) break;
          final alphaStep = (t * 20.0).round().clamp(0, 20);
          if (alphaStep <= 0) break;
          CanvasDrawHelpers.drawCenteredText(
            canvas,
            fx.text!,
            Offset(fx.x, fx.y),
            _getFloatingTextStyle(fx.color, alphaStep),
          );
        case ParticleShape.ring:
          final radius = fx.size * (1.85 - t * 0.85);
          _strokePaint
            ..color = fx.color.withValues(alpha: t * 0.68)
            ..strokeWidth = 2.4;
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(fx.x, fx.y),
              width: radius * 2.0,
              height: radius,
            ),
            _strokePaint,
          );
        case ParticleShape.star4:
          _fillPaint.color = fx.color.withValues(alpha: t);
          CanvasDrawHelpers.drawStar4(
            canvas,
            Offset(fx.x, fx.y),
            fx.size * (0.55 + 0.65 * t),
            _fillPaint,
            rotation: fx.angle,
          );
        case ParticleShape.droplet:
          _fillPaint.color = fx.color.withValues(alpha: t);
          final r = fx.size * (0.45 + 0.55 * t);
          _shapePath
            ..reset()
            ..moveTo(fx.x, fx.y - r * 1.35)
            ..quadraticBezierTo(fx.x + r * 1.1, fx.y + r * 0.3, fx.x, fx.y + r)
            ..quadraticBezierTo(fx.x - r * 1.1, fx.y + r * 0.3, fx.x, fx.y - r * 1.35)
            ..close();
          canvas.drawPath(_shapePath, _fillPaint);
        case ParticleShape.leaf:
        case ParticleShape.petal:
          _fillPaint.color = fx.color.withValues(alpha: t);
          canvas.save();
          canvas.translate(fx.x, fx.y);
          canvas.rotate(fx.angle);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: fx.size * 1.75,
              height: fx.size * 0.92,
            ),
            _fillPaint,
          );
          canvas.restore();
        case ParticleShape.clod:
          _fillPaint.color = fx.color.withValues(alpha: t);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(fx.x, fx.y),
                width: fx.size * (0.55 + 0.55 * t),
                height: fx.size * (0.45 + 0.45 * t),
              ),
              const Radius.circular(1.4),
            ),
            _fillPaint,
          );
        case ParticleShape.smoke:
        case ParticleShape.circle:
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
      for (var i = 0; i < 68; i++) {
        final seedX = ((i * 137) % spanXInt) - halfSpanX;
        final cycle = (animTime * 290.0 + i * 53.0) % spanY;
        final rx = seedX - cycle * 0.18;
        final ry = cycle;
        canvas.drawLine(Offset(rx, ry), Offset(rx - 4, ry + 14), _rainPaint);

        // Expanding water micro-splashes across meadow surface
        if (i % 5 == 0) {
          final splashPhase = (animTime * 2.1 + i * 0.37) % 1.0;
          final gx = 0.8 + ((i * 1.7) % (gridSize - 1.6));
          final gy = 0.8 + ((i * 2.9) % (gridSize - 1.6));
          final sp = iso.gridToWorld(gx, gy);
          _strokePaint
            ..color = Color.fromRGBO(225, 245, 254, (1.0 - splashPhase) * 0.55)
            ..strokeWidth = 1.2;
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(sp.x, sp.y),
              width: 3.0 + splashPhase * 11.0,
              height: 1.5 + splashPhase * 5.2,
            ),
            _strokePaint,
          );
        }
      }
      return;
    }

    // Golden twilight fireflies as evening settles over Solville
    if (dayProgress > 0.60) {
      final duskAlpha = ((dayProgress - 0.60) / 0.35).clamp(0.0, 1.0);
      for (var f = 0; f < 10; f++) {
        final gx =
            1.5 +
            ((f * 3.1) % (gridSize - 2.5)) +
            math.sin(animTime * 0.52 + f * 1.7) * 1.3;
        final gy =
            1.5 +
            ((f * 2.3) % (gridSize - 2.5)) +
            math.cos(animTime * 0.45 + f * 2.1) * 1.3;
        final w = iso.gridToWorld(gx, gy, gz: 0.9);
        final blink = (math.sin(animTime * 2.3 + f * 1.9) + 1.0) * 0.5;
        final center = Offset(w.x, w.y);
        _fillPaint.color = Color.fromRGBO(
          255,
          224,
          130,
          0.16 * blink * duskAlpha,
        );
        canvas.drawCircle(center, 11.0, _fillPaint);
        _fillPaint.color = Color.fromRGBO(
          255,
          238,
          88,
          0.36 * blink * duskAlpha,
        );
        canvas.drawCircle(center, 6.2, _fillPaint);
        _fillPaint.color = Color.fromRGBO(
          255,
          255,
          210,
          0.92 * blink * duskAlpha,
        );
        canvas.drawCircle(center, 2.2, _fillPaint);
      }
      return;
    }

    // Daytime 4-wing spotted butterflies with ground micro-shadows
    for (var b = 0; b < 3; b++) {
      final gx = 4.2 + math.sin(animTime * 0.30 + b * 2.4) * 3.0;
      final gy = 4.2 + math.cos(animTime * 0.24 + b * 1.9) * 2.7;
      final shadowPos = iso.gridToWorld(gx, gy, gz: 0.0);
      final pos = butterflyWorldPos(iso, b, animTime);
      final flap = (math.sin(animTime * 8.4 + b) + 1.0) * 2.4 + 1.6;

      _fillPaint.color = const Color(0x1E000000);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(shadowPos.x, shadowPos.y), width: 8, height: 4),
        _fillPaint,
      );

      final wingColor = switch (b) {
        0 => const Color(0xFFFFF176),
        1 => const Color(0xFFF48FB1),
        _ => const Color(0xFF81D4FA),
      };
      _fillPaint.color = wingColor;
      // Upper forewings + smaller hindwings
      canvas.drawOval(
        Rect.fromCenter(center: Offset(pos.dx - flap * 0.62, pos.dy - 1.2), width: flap * 1.15, height: 5.5),
        _fillPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(pos.dx + flap * 0.62, pos.dy - 1.2), width: flap * 1.15, height: 5.5),
        _fillPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(pos.dx - flap * 0.45, pos.dy + 2.2), width: flap * 0.85, height: 4.0),
        _fillPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(pos.dx + flap * 0.45, pos.dy + 2.2), width: flap * 0.85, height: 4.0),
        _fillPaint,
      );
      // Slim dark thorax
      _strokePaint
        ..color = const Color(0xFF4E342E)
        ..strokeWidth = 1.4;
      canvas.drawLine(Offset(pos.dx, pos.dy - 2.6), Offset(pos.dx, pos.dy + 3.0), _strokePaint);
    }

    // Gentle sunlit floating blossom petals & warm golden sun motes
    final halfSpanX = gridSize * iso.tileWidth * 0.48;
    final spanX = halfSpanX * 2.0;
    final spanY = gridSize * iso.tileHeight * 0.85;
    for (var m = 0; m < 8; m++) {
      final mx = -halfSpanX + ((animTime * (14.0 + m * 2.1) + m * 170.0) % spanX);
      final my = 20.0 + ((animTime * (7.5 + m * 1.3) + m * 95.0) % spanY) + math.sin(animTime * 1.8 + m) * 6.0;
      if (m.isEven) {
        _fillPaint.color = m % 4 == 0 ? const Color(0x88FFCCBC) : const Color(0x88FFF9C4);
        canvas.save();
        canvas.translate(mx, my);
        canvas.rotate(animTime * 1.2 + m);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 4.6, height: 2.5), _fillPaint);
        canvas.restore();
      } else {
        final twinkle = 0.45 + 0.45 * math.sin(animTime * 2.5 + m * 1.4);
        _fillPaint.color = Color.fromRGBO(255, 245, 180, 0.55 * twinkle);
        canvas.drawCircle(Offset(mx, my), 1.8, _fillPaint);
      }
    }
  }

  /// Computes deterministic world coordinates for butterfly [b] at [animTime].
  static Offset butterflyWorldPos(IsoProjection iso, int b, double animTime) {
    final gx = 4.2 + math.sin(animTime * 0.30 + b * 2.4) * 3.0;
    final gy = 4.2 + math.cos(animTime * 0.24 + b * 1.9) * 2.7;
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
    final bounce = math.sin(animTime * 3.0).abs() * 7.0;
    final pulse = 0.65 + 0.35 * math.sin(animTime * 2.8);

    _strokePaint
      ..color = Color.fromRGBO(255, 193, 7, 0.88 * pulse)
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
    final pillWidth = (hintEmoji.length * 7.2 + 24.0).clamp(68.0, 210.0);
    final pill = RRect.fromRectAndRadius(
      Rect.fromCenter(center: badgeCenter, width: pillWidth, height: 26),
      const Radius.circular(13),
    );
    _fillPaint.color = const Color(0x333E2723);
    canvas.drawRRect(pill.shift(const Offset(0, 2)), _fillPaint);
    _fillPaint.color = const Color(0xFAFFFDE7);
    canvas.drawRRect(pill, _fillPaint);
    _strokePaint
      ..color = const Color(0xFFFF8F00)
      ..strokeWidth = 2.0;
    canvas.drawRRect(pill, _strokePaint);
    _pointerPath
      ..reset()
      ..moveTo(badgeCenter.dx - 6, badgeCenter.dy + 13)
      ..lineTo(badgeCenter.dx + 6, badgeCenter.dy + 13)
      ..lineTo(badgeCenter.dx, badgeCenter.dy + 19)
      ..close();
    _fillPaint.color = const Color(0xFFFF8F00);
    canvas.drawPath(_pointerPath, _fillPaint);
    CanvasDrawHelpers.drawCenteredText(
      canvas,
      hintEmoji,
      badgeCenter,
      _spotlightTextStyle,
    );
  }

  /// Emits subtle warm footstep meadow dust puffs behind Sol while walking.
  void spawnFootstepDust(
    List<FloatingVfx> pool,
    double wx,
    double wy,
    math.Random rng,
  ) {
    if (pool.length > 160) return;
    pool.add(
      FloatingVfx(
        x: wx + (rng.nextDouble() - 0.5) * 8.0,
        y: wy + 1.5,
        vx: (rng.nextDouble() - 0.5) * 14.0,
        vy: -10.0 - rng.nextDouble() * 8.0,
        color: const Color(0x88E6D7BE),
        maxLife: 0.35,
        size: 3.0,
        shape: ParticleShape.smoke,
      ),
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
        for (var i = 0; i < 8; i++) {
          pool.add(
            FloatingVfx(
              x: world.x + (rng.nextDouble() - 0.5) * 18,
              y: world.y - 2,
              vx: (rng.nextDouble() - 0.5) * 48,
              vy: -36 - rng.nextDouble() * 26,
              ay: 150.0,
              color: i.isEven
                  ? const Color(0xFF795548)
                  : const Color(0xFFA16B3B),
              maxLife: 0.48,
              size: 4.0,
              shape: ParticleShape.clod,
            ),
          );
        }
      case SimEventType.water:
      case SimEventType.refill:
        pool.add(
          FloatingVfx(
            x: world.x,
            y: world.y,
            vx: 0,
            vy: 0,
            color: const Color(0xFF4FC3F7),
            maxLife: 0.45,
            size: 16.0,
            isRing: true,
          ),
        );
        for (var i = 0; i < 9; i++) {
          pool.add(
            FloatingVfx(
              x: world.x + (rng.nextDouble() - 0.5) * 20,
              y: world.y - 8,
              vx: (rng.nextDouble() - 0.5) * 46,
              vy: -34 - rng.nextDouble() * 24,
              ay: 130.0,
              color: const Color(0xFF4FC3F7),
              maxLife: 0.54,
              size: 3.6,
              shape: ParticleShape.droplet,
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
            maxLife: 0.78,
            size: event.radius * 46.0,
            isRing: true,
          ),
        );
      case SimEventType.plant:
      case SimEventType.compost:
        for (var i = 0; i < 8; i++) {
          pool.add(
            FloatingVfx(
              x: world.x + (rng.nextDouble() - 0.5) * 22,
              y: world.y - 10,
              vx: (rng.nextDouble() - 0.5) * 38,
              vy: -32 - rng.nextDouble() * 24,
              ay: 35.0,
              angle: rng.nextDouble() * math.pi,
              angularVelocity: (rng.nextDouble() - 0.5) * 6.0,
              color: event.type == SimEventType.plant
                  ? const Color(0xFF66BB6A)
                  : const Color(0xFFFFEE58),
              maxLife: 0.62,
              size: 4.0,
              shape: event.type == SimEventType.plant
                  ? ParticleShape.leaf
                  : ParticleShape.star4,
            ),
          );
        }
      case SimEventType.harvest:
        for (var i = 0; i < 10; i++) {
          pool.add(
            FloatingVfx(
              x: world.x + (rng.nextDouble() - 0.5) * 24,
              y: world.y - 12,
              vx: (rng.nextDouble() - 0.5) * 52,
              vy: -38 - rng.nextDouble() * 30,
              ay: 45.0,
              angle: rng.nextDouble() * math.pi,
              angularVelocity: (rng.nextDouble() - 0.5) * 7.0,
              color: i.isEven
                  ? const Color(0xFFFFEE58)
                  : const Color(0xFF81C784),
              maxLife: 0.68,
              size: 4.2,
              shape: i.isEven ? ParticleShape.star4 : ParticleShape.leaf,
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
            size: 38.0,
            isRing: true,
          ),
        );
        for (var i = 0; i < 16; i++) {
          pool.add(
            FloatingVfx(
              x: world.x + (rng.nextDouble() - 0.5) * 28,
              y: world.y - 18,
              vx: (rng.nextDouble() - 0.5) * 70,
              vy: -44 - rng.nextDouble() * 34,
              ay: 40.0,
              angle: rng.nextDouble() * math.pi,
              angularVelocity: (rng.nextDouble() - 0.5) * 8.0,
              color: i.isEven
                  ? const Color(0xFFFFCA28)
                  : const Color(0xFFFF80AB),
              maxLife: 0.92,
              size: 4.8,
              shape: i.isEven ? ParticleShape.star4 : ParticleShape.petal,
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
        for (var i = 0; i < 8; i++) {
          pool.add(
            FloatingVfx(
              x: world.x + (rng.nextDouble() - 0.5) * 20,
              y: world.y - 14,
              vx: (rng.nextDouble() - 0.5) * 40,
              vy: -28 - rng.nextDouble() * 24,
              angle: rng.nextDouble() * math.pi,
              angularVelocity: (rng.nextDouble() - 0.5) * 6.0,
              color: event.type == SimEventType.butterflyBoop
                  ? const Color(0xFFF48FB1)
                  : const Color(0xFFA5D6A7),
              maxLife: 0.62,
              size: 3.8,
              shape: i.isEven ? ParticleShape.star4 : ParticleShape.petal,
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
      case SimEventType.questCompleted:
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
              vx: (rng.nextDouble() - 0.5) * 62,
              vy: -38 - rng.nextDouble() * 32,
              ay: 35.0,
              angle: rng.nextDouble() * math.pi,
              angularVelocity: (rng.nextDouble() - 0.5) * 7.0,
              color: i.isEven
                  ? const Color(0xFFFFD54F)
                  : const Color(0xFF4FC3F7),
              maxLife: 0.88,
              size: 4.4,
              shape: ParticleShape.star4,
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
          for (var i = 0; i < 7; i++) {
            pool.add(
              FloatingVfx(
                x: world.x + (rng.nextDouble() - 0.5) * 24,
                y: world.y - 24,
                vx: (rng.nextDouble() - 0.5) * 44,
                vy: -28 - rng.nextDouble() * 24,
                angle: rng.nextDouble() * math.pi,
                angularVelocity: (rng.nextDouble() - 0.5) * 7.0,
                color: const Color(0xFFFFE082),
                maxLife: 0.65,
                size: 3.8,
                shape: ParticleShape.star4,
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
