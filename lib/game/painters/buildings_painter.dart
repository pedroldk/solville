import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show Alignment, FontWeight, LinearGradient, TextStyle;

import '../../domain/models/catalog.dart';
import '../../domain/models/grid_pos.dart';
import '../../domain/models/market_state.dart';
import '../../domain/models/tile_state.dart';
import 'canvas_draw_helpers.dart';

/// Renders ultra-detailed 2.5D Mediterranean buildings, trees, artisan kettles,
/// sprinklers, lanterns, blossom arches, expansion landmarks, and village lane scenery.
///
/// Uses cached origin-relative shaders and reusable [Paint]/[Path] objects to
/// keep the 60fps render loop smooth with zero per-frame shader allocations.
class BuildingsPainter {
  final Paint _fillPaint = Paint();
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final Path _pathA = Path();
  final Path _pathB = Path();

  static const TextStyle _recipeTextStyle = TextStyle(
    color: Color(0xFF3E2723),
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
  );

  // Cached origin-relative gradients
  Shader? _plasterLeftShader;
  Shader? _plasterRightShader;
  Shader? _roofLeftShader;
  Shader? _roofRightShader;
  Shader? _barnLeftShader;
  Shader? _barnRightShader;
  Shader? _copperKettleShader;
  Shader? _wellStoneShader;

  void _ensureShaders() {
    _plasterLeftShader ??= const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFFFFFBF0), Color(0xFFF5E2C3)],
    ).createShader(const Rect.fromLTWH(-32, -45, 34, 60));

    _plasterRightShader ??= const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFFF4D9B4), Color(0xFFDDBB8E)],
    ).createShader(const Rect.fromLTWH(0, -45, 34, 60));

    _roofLeftShader ??= const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[Color(0xFFEA5D28), Color(0xFFD14315)],
    ).createShader(const Rect.fromLTWH(-38, -62, 40, 42));

    _roofRightShader ??= const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[Color(0xFFC84016), Color(0xFF9C290B)],
    ).createShader(const Rect.fromLTWH(0, -62, 40, 42));

    _barnLeftShader ??= const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[Color(0xFFD8342F), Color(0xFFB5201D)],
    ).createShader(const Rect.fromLTWH(-30, -44, 30, 56));

    _barnRightShader ??= const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[Color(0xFFB2221F), Color(0xFF841715)],
    ).createShader(const Rect.fromLTWH(0, -44, 30, 56));

    _copperKettleShader ??= const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFFF39C59), Color(0xFFD16A2E), Color(0xFF914018)],
      stops: <double>[0.0, 0.52, 1.0],
    ).createShader(const Rect.fromLTWH(-18, -30, 36, 26));

    _wellStoneShader ??= const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: <Color>[Color(0xFFB0BEC5), Color(0xFF90A4AE), Color(0xFF6E828C)],
    ).createShader(const Rect.fromLTWH(-22, -18, 44, 26));
  }

  void drawLaneScenery(
    Canvas canvas,
    double cx,
    double cy,
    GridPos pos,
    double animTime,
  ) {
    if (pos.x.isEven && pos.x != 4 && pos.x != 6) {
      final sway = math.sin(animTime * 1.15 + pos.x * 0.9) * 1.8;
      // Soft directional shadow
      _fillPaint.color = const Color(0x2E1B0E0C);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 17, cy - 10), width: 22, height: 10),
        _fillPaint,
      );

      // Textured cypress trunk
      _strokePaint
        ..color = const Color(0xFF5D4037)
        ..strokeWidth = 3.8;
      canvas.drawLine(Offset(cx + 14, cy - 10), Offset(cx + 14, cy - 17), _strokePaint);

      // Layered cypress foliage cone (shadow base -> mid emerald -> sunlit tip)
      _pathA
        ..reset()
        ..moveTo(cx + 6, cy - 14)
        ..quadraticBezierTo(cx + 5 + sway * 0.4, cy - 28, cx + 14 + sway, cy - 45)
        ..quadraticBezierTo(cx + 23 + sway * 0.4, cy - 28, cx + 22, cy - 14)
        ..close();
      _fillPaint.color = const Color(0xFF225C25);
      canvas.drawPath(_pathA, _fillPaint);

      _fillPaint.color = const Color(0xFF2E7D32);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 13 + sway * 0.4, cy - 22), width: 14, height: 15),
        _fillPaint,
      );
      _fillPaint.color = const Color(0xFF388E3C);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 13.5 + sway * 0.7, cy - 32), width: 10.5, height: 14),
        _fillPaint,
      );
      _fillPaint.color = const Color(0xFF558B2F);
      canvas.drawCircle(Offset(cx + 13.5 + sway * 0.9, cy - 40), 4.0, _fillPaint);
    } else if (pos.x == 3 || pos.x == 7) {
      // Charming terracotta planter pot with lane wildflowers
      _fillPaint.color = const Color(0x28000000);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 12, cy - 9), width: 14, height: 7),
        _fillPaint,
      );
      _fillPaint.color = const Color(0xFFD84315);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx - 12, cy - 12), width: 10, height: 8),
          const Radius.circular(2.5),
        ),
        _fillPaint,
      );
      _fillPaint.color = const Color(0xFF43A047);
      canvas.drawCircle(Offset(cx - 12, cy - 17), 5.2, _fillPaint);
      _fillPaint.color = pos.x == 3 ? const Color(0xFFFF8A80) : const Color(0xFFFFEE58);
      canvas.drawCircle(Offset(cx - 14, cy - 18), 2.0, _fillPaint);
      _fillPaint.color = const Color(0xFFEC407A);
      canvas.drawCircle(Offset(cx - 10, cy - 17), 1.9, _fillPaint);
    }
  }

  void drawFarmhouse(
    Canvas canvas,
    double cx,
    double cy,
    double dayProgress,
    double animTime, {
    bool warmGlowActive = false,
  }) {
    _ensureShaders();
    final isEvening = dayProgress > 0.56 || warmGlowActive;

    // Contact AO shadow
    _fillPaint.color = const Color(0x38261412);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 5), width: 78, height: 37),
      _fillPaint,
    );

    canvas.save();
    canvas.translate(cx, cy);

    // Cozy turning wooden garden windmill behind the right eave (inspired by app icon)
    _strokePaint
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 2.6;
    canvas.drawLine(const Offset(24, -4), const Offset(29, -43), _strokePaint);
    canvas.drawLine(const Offset(34, -4), const Offset(29, -43), _strokePaint);
    canvas.drawLine(const Offset(26, -22), const Offset(32, -22), _strokePaint);
    // Rotating 4 wooden lattice windmill sails
    canvas.save();
    canvas.translate(29, -43);
    canvas.rotate(animTime * 0.9);
    for (var s = 0; s < 4; s++) {
      canvas.rotate(math.pi * 0.5);
      _strokePaint
        ..color = const Color(0xFF5D4037)
        ..strokeWidth = 1.6;
      canvas.drawLine(Offset.zero, const Offset(0, -13), _strokePaint);
      _fillPaint
        ..shader = null
        ..color = const Color(0xFFEFE4CE);
      canvas.drawRect(const Rect.fromLTWH(0.8, -12.5, 4.2, 8.5), _fillPaint);
      _strokePaint
        ..color = const Color(0xAA8D6E63)
        ..strokeWidth = 0.8;
      canvas.drawRect(const Rect.fromLTWH(0.8, -12.5, 4.2, 8.5), _strokePaint);
    }
    _fillPaint.color = const Color(0xFF8D6E63);
    canvas.drawCircle(Offset.zero, 2.2, _fillPaint);
    canvas.restore();

    // Stone foundation plinth
    _pathA
      ..reset()
      ..moveTo(-31, -1)
      ..lineTo(0, 14)
      ..lineTo(31, -1)
      ..lineTo(31, -8)
      ..lineTo(0, 7)
      ..lineTo(-31, -8)
      ..close();
    _fillPaint
      ..shader = null
      ..color = const Color(0xFF9E948B);
    canvas.drawPath(_pathA, _fillPaint);

    // Left sunlit whitewashed plaster wall
    _pathA
      ..reset()
      ..moveTo(-30, -6)
      ..lineTo(0, 9)
      ..lineTo(0, -27)
      ..lineTo(-30, -42)
      ..close();
    _fillPaint.shader = _plasterLeftShader;
    canvas.drawPath(_pathA, _fillPaint);

    // Right shaded cream wall
    _pathB
      ..reset()
      ..moveTo(0, 9)
      ..lineTo(30, -6)
      ..lineTo(30, -42)
      ..lineTo(0, -27)
      ..close();
    _fillPaint.shader = _plasterRightShader;
    canvas.drawPath(_pathB, _fillPaint);
    _fillPaint.shader = null;

    // Subtle timber corner trim & carved sandstone quoins
    _fillPaint.color = const Color(0xFFD7BC98);
    for (var q = 0; q < 3; q++) {
      final qy = -13.0 - q * 9.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(0, qy), width: 4.6, height: 5.5),
          const Radius.circular(1.2),
        ),
        _fillPaint,
      );
    }

    // Half-timber warm oak beam accent on left wall
    _strokePaint
      ..color = const Color(0xAA795548)
      ..strokeWidth = 2.0;
    canvas.drawLine(const Offset(-30, -28), const Offset(0, -13), _strokePaint);
    canvas.drawLine(const Offset(-30, -6), const Offset(-30, -42), _strokePaint);
    canvas.drawLine(const Offset(30, -6), const Offset(30, -42), _strokePaint);

    // Climbing emerald ivy & tiny pink bougainvillea blooms on left wall corner
    _fillPaint.color = const Color(0xFF43A047);
    canvas.drawCircle(const Offset(-28, -10), 4.0, _fillPaint);
    canvas.drawCircle(const Offset(-26, -16), 3.4, _fillPaint);
    canvas.drawCircle(const Offset(-28, -22), 3.0, _fillPaint);
    _fillPaint.color = const Color(0xFFEC407A);
    canvas.drawCircle(const Offset(-27, -14), 1.5, _fillPaint);
    canvas.drawCircle(const Offset(-29, -20), 1.4, _fillPaint);

    // Stone porch doorstep + arched plank front door + mini porch awning & sconce
    _fillPaint.color = const Color(0xFFB5ABA1);
    canvas.drawOval(Rect.fromCenter(center: const Offset(15, 5), width: 16, height: 7), _fillPaint);
    final door = RRect.fromRectAndCorners(
      const Rect.fromLTWH(9, -17, 11.5, 20),
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
    );
    _fillPaint.color = const Color(0xFF6D4C41);
    canvas.drawRRect(door, _fillPaint);
    _strokePaint
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 1.2;
    canvas.drawRRect(door, _strokePaint);
    canvas.drawLine(const Offset(13, -15), const Offset(13, 2), _strokePaint);
    canvas.drawLine(const Offset(16.5, -15), const Offset(16.5, 2), _strokePaint);
    _fillPaint.color = const Color(0xFFFFCA28);
    canvas.drawCircle(const Offset(18.5, -6), 1.3, _fillPaint);

    // Mini terracotta porch canopy & warm brass sconce over door
    _pathA
      ..reset()
      ..moveTo(7, -19)
      ..lineTo(15, -24)
      ..lineTo(23, -19)
      ..close();
    _fillPaint.color = const Color(0xFFD84315);
    canvas.drawPath(_pathA, _fillPaint);
    if (isEvening) {
      _fillPaint.color = const Color(0x55FFD54F);
      canvas.drawCircle(const Offset(23.5, -15), 7.5, _fillPaint);
    }
    _fillPaint.color = isEvening ? const Color(0xFFFFEE58) : const Color(0xFFFFCA28);
    canvas.drawCircle(const Offset(23.5, -15), 2.1, _fillPaint);

    // Paned window on left wall with wooden shutters + flowerbox
    if (isEvening) {
      _fillPaint.color = const Color(0x48FFD54F);
      canvas.drawCircle(const Offset(-15, -20), 16, _fillPaint);
    }
    _fillPaint.color = const Color(0xFF558B2F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-23.5, -26, 4.0, 11), const Radius.circular(1.2)),
      _fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-10.5, -24, 4.0, 11), const Radius.circular(1.2)),
      _fillPaint,
    );
    final winRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-19.5, -25, 9, 10),
      const Radius.circular(2.2),
    );
    _fillPaint.color = isEvening ? const Color(0xFFFFE082) : const Color(0xFF81D4FA);
    canvas.drawRRect(winRect, _fillPaint);
    _strokePaint
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 1.2;
    canvas.drawRRect(winRect, _strokePaint);
    canvas.drawLine(const Offset(-15, -25), const Offset(-15, -15), _strokePaint);
    canvas.drawLine(const Offset(-19.5, -20), const Offset(-10.5, -20), _strokePaint);

    // Window flowerbox with blossoms
    _fillPaint.color = const Color(0xFF8D6E63);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-20.5, -15, 11, 3.6), const Radius.circular(1.2)),
      _fillPaint,
    );
    _fillPaint.color = const Color(0xFF43A047);
    canvas.drawCircle(const Offset(-17, -15.5), 2.2, _fillPaint);
    canvas.drawCircle(const Offset(-13, -15.2), 2.2, _fillPaint);
    _fillPaint.color = const Color(0xFFFF80AB);
    canvas.drawCircle(const Offset(-17, -16.5), 1.3, _fillPaint);
    _fillPaint.color = const Color(0xFFFFEE58);
    canvas.drawCircle(const Offset(-13, -16.2), 1.3, _fillPaint);

    // Stone chimney + clay pot + curling smoke puffs
    _fillPaint.color = const Color(0xFF8D827A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-21, -66, 10, 20), const Radius.circular(2.0)),
      _fillPaint,
    );
    _fillPaint.color = const Color(0xFF6D645E);
    canvas.drawRect(const Rect.fromLTWH(-22.5, -67.5, 13, 3.2), _fillPaint);
    for (var s = 0; s < 2; s++) {
      final puffPhase = (animTime * 0.42 + s * 0.5) % 1.0;
      _fillPaint.color = Color.fromRGBO(255, 252, 244, (1.0 - puffPhase) * 0.62);
      canvas.drawCircle(
        Offset(-16 + puffPhase * 9 + s * 2, -70 - puffPhase * 20),
        3.2 + puffPhase * 3.0,
        _fillPaint,
      );
    }

    // Eave shadow beneath roof overhang
    _strokePaint
      ..color = const Color(0x443E2723)
      ..strokeWidth = 3.2;
    canvas.drawLine(const Offset(-31, -39), const Offset(0, -23), _strokePaint);
    canvas.drawLine(const Offset(0, -23), const Offset(31, -39), _strokePaint);

    // Terracotta barrel-tile pitched roof
    _pathA
      ..reset()
      ..moveTo(-36, -39)
      ..lineTo(0, -21)
      ..lineTo(0, -58)
      ..close();
    _fillPaint.shader = _roofLeftShader;
    canvas.drawPath(_pathA, _fillPaint);

    _pathB
      ..reset()
      ..moveTo(0, -21)
      ..lineTo(36, -39)
      ..lineTo(0, -58)
      ..close();
    _fillPaint.shader = _roofRightShader;
    canvas.drawPath(_pathB, _fillPaint);
    _fillPaint.shader = null;

    // 4 staggered courses of scalloped terracotta barrel tiles across both roof slopes
    for (var row = 1; row <= 3; row++) {
      final t = row / 4.0;
      final lx = -36 * (1 - t);
      final ly = -39 - 19 * t;
      final rx = 36 * (1 - t);
      final ry = -39 - 19 * t;
      final midY = -21 - 37 * t;
      _strokePaint
        ..color = const Color(0x403E2723)
        ..strokeWidth = 1.1;
      canvas.drawLine(Offset(lx, ly), Offset(0, midY), _strokePaint);
      canvas.drawLine(Offset(0, midY), Offset(rx, ry), _strokePaint);
      _strokePaint
        ..color = const Color(0x3DFFF3E0)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(lx + 1, ly - 1.2), Offset(0, midY - 1.2), _strokePaint);
    }
    // Vertical barrel tile channels on left slope
    _strokePaint
      ..color = const Color(0x2E3E2723)
      ..strokeWidth = 1.0;
    for (var col = 1; col <= 4; col++) {
      final u = col / 5.0;
      canvas.drawLine(const Offset(0, -58), Offset(-36 * (1 - u), -39 + 18 * u), _strokePaint);
      canvas.drawLine(const Offset(0, -58), Offset(36 * (1 - u), -39 + 18 * u), _strokePaint);
    }

    _strokePaint
      ..color = const Color(0x553E2723)
      ..strokeWidth = 1.4;
    canvas.drawPath(_pathA, _strokePaint);
    canvas.drawPath(_pathB, _strokePaint);

    // Warm ridge tile spine
    _strokePaint
      ..color = const Color(0xFFE65100)
      ..strokeWidth = 3.4;
    canvas.drawLine(const Offset(-2.5, -57), const Offset(2.5, -57), _strokePaint);

    canvas.restore();
  }

  void drawBarn(
    Canvas canvas,
    double cx,
    double cy,
    int totalBarnCrates, {
    bool showDetailedMeters = false,
  }) {
    _ensureShaders();
    _fillPaint.color = const Color(0x38261412);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 5), width: 76, height: 35),
      _fillPaint,
    );

    canvas.save();
    canvas.translate(cx, cy);

    // Stone plinth
    _pathA
      ..reset()
      ..moveTo(-29, 0)
      ..lineTo(0, 14)
      ..lineTo(29, 0)
      ..lineTo(29, -6)
      ..lineTo(0, 8)
      ..lineTo(-29, -6)
      ..close();
    _fillPaint
      ..shader = null
      ..color = const Color(0xFF8D837B);
    canvas.drawPath(_pathA, _fillPaint);

    // Left sunlit red barn wall
    _pathA
      ..reset()
      ..moveTo(-28, -4)
      ..lineTo(0, 10)
      ..lineTo(0, -28)
      ..lineTo(-28, -42)
      ..close();
    _fillPaint.shader = _barnLeftShader;
    canvas.drawPath(_pathA, _fillPaint);

    // Right shaded burgundy barn wall
    _pathB
      ..reset()
      ..moveTo(0, 10)
      ..lineTo(28, -4)
      ..lineTo(28, -42)
      ..lineTo(0, -28)
      ..close();
    _fillPaint.shader = _barnRightShader;
    canvas.drawPath(_pathB, _fillPaint);
    _fillPaint.shader = null;

    // Subtle vertical timber plank grooves
    _strokePaint
      ..color = const Color(0x283E2723)
      ..strokeWidth = 1.0;
    for (final dx in const <double>[-21.0, -14.0, -7.0]) {
      final t = (dx + 28.0) / 28.0;
      canvas.drawLine(Offset(dx, -4 + 14 * t), Offset(dx, -42 + 14 * t), _strokePaint);
    }

    // Crisp cream corner trim posts
    _strokePaint
      ..color = const Color(0xFFFFF8E1)
      ..strokeWidth = 2.2;
    canvas.drawLine(const Offset(-28, -4), const Offset(-28, -41), _strokePaint);
    canvas.drawLine(const Offset(0, 10), const Offset(0, -28), _strokePaint);
    canvas.drawLine(const Offset(28, -4), const Offset(28, -41), _strokePaint);

    // Double X-braced timber barn doors on right face
    _fillPaint.color = const Color(0xFF6D231C);
    canvas.drawRect(const Rect.fromLTWH(5.5, -20, 17, 22), _fillPaint);
    _strokePaint
      ..color = const Color(0xFFFFF8E1)
      ..strokeWidth = 2.0;
    canvas.drawRect(const Rect.fromLTWH(5.5, -20, 17, 22), _strokePaint);
    canvas.drawLine(const Offset(14, -20), const Offset(14, 2), _strokePaint);
    canvas.drawLine(const Offset(5.5, -20), const Offset(22.5, 2), _strokePaint);
    canvas.drawLine(const Offset(22.5, -20), const Offset(5.5, 2), _strokePaint);

    // Hay-loft opening with golden straw peeking out on left wall
    _fillPaint.color = const Color(0xFF4E1A16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-19, -31, 10, 8), const Radius.circular(1.5)),
      _fillPaint,
    );
    _fillPaint.color = const Color(0xFFFFD54F);
    canvas.drawRect(const Rect.fromLTWH(-18, -26, 8, 2.5), _fillPaint);

    // Cedar-shingle gambrel roof + shingle courses
    _pathA
      ..reset()
      ..moveTo(-34, -39)
      ..lineTo(0, -60)
      ..lineTo(34, -39)
      ..lineTo(0, -24)
      ..close();
    _fillPaint.color = const Color(0xFF5D4037);
    canvas.drawPath(_pathA, _fillPaint);
    _strokePaint
      ..color = const Color(0x33D7CCC8)
      ..strokeWidth = 1.0;
    for (final t in const <double>[0.32, 0.64]) {
      canvas.drawLine(
        Offset(-34 * (1 - t), -39 - 21 * t),
        Offset(0, -24 - 36 * t),
        _strokePaint,
      );
      canvas.drawLine(
        Offset(0, -24 - 36 * t),
        Offset(34 * (1 - t), -39 - 21 * t),
        _strokePaint,
      );
    }
    _strokePaint
      ..color = const Color(0xFFFFF8E1)
      ..strokeWidth = 2.0;
    canvas.drawLine(const Offset(-34, -39), const Offset(0, -24), _strokePaint);
    canvas.drawLine(const Offset(0, -24), const Offset(34, -39), _strokePaint);

    // Warm golden hay bale outside left barn wall
    _fillPaint.color = const Color(0xFFFBC02D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-36, -6, 10, 7), const Radius.circular(2.5)),
      _fillPaint,
    );
    _strokePaint
      ..color = const Color(0xFFB77900)
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(-33, -6), const Offset(-33, 1), _strokePaint);
    canvas.drawLine(const Offset(-29, -6), const Offset(-29, 1), _strokePaint);

    // Mini roof cupola + golden weathervane
    _fillPaint.color = const Color(0xFFC62828);
    canvas.drawRect(const Rect.fromLTWH(-4.5, -62, 9, 7), _fillPaint);
    _pathB
      ..reset()
      ..moveTo(-7, -62)
      ..lineTo(0, -68)
      ..lineTo(7, -62)
      ..close();
    _fillPaint.color = const Color(0xFF4E342E);
    canvas.drawPath(_pathB, _fillPaint);
    _strokePaint
      ..color = const Color(0xFFFFCA28)
      ..strokeWidth = 1.3;
    canvas.drawLine(const Offset(0, -68), const Offset(0, -73), _strokePaint);
    canvas.drawLine(const Offset(-3.5, -72), const Offset(3.5, -72), _strokePaint);

    canvas.restore();

    if (totalBarnCrates > 0) {
      final stackCount = math.min(2, totalBarnCrates);
      for (var i = 0; i < stackCount; i++) {
        CanvasDrawHelpers.drawWoodenCrate(
          canvas,
          Offset(cx - 19 + i * 13.0, cy + 9),
          ProductId.tomato,
          scale: 0.62,
        );
      }
      if (showDetailedMeters) {
        CanvasDrawHelpers.drawFloatingStatusPill(
          canvas,
          cx,
          cy - 70,
          '📦 $totalBarnCrates',
        );
      }
    }
  }

  void drawMarketStall(
    Canvas canvas,
    double cx,
    double cy,
    List<ProductId> stallCrates,
    double animTime,
  ) {
    _fillPaint.color = const Color(0x36261412);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 5), width: 78, height: 34),
      _fillPaint,
    );

    canvas.save();
    canvas.translate(cx, cy);

    // True 2.5D isometric oak timber counter base
    // Left sunlit face
    _pathA
      ..reset()
      ..moveTo(-28, -3)
      ..lineTo(0, 11)
      ..lineTo(0, -6)
      ..lineTo(-28, -20)
      ..close();
    _fillPaint
      ..shader = null
      ..color = const Color(0xFFB57845);
    canvas.drawPath(_pathA, _fillPaint);

    // Right shaded face
    _pathB
      ..reset()
      ..moveTo(0, 11)
      ..lineTo(28, -3)
      ..lineTo(28, -20)
      ..lineTo(0, -6)
      ..close();
    _fillPaint.color = const Color(0xFF8C5931);
    canvas.drawPath(_pathB, _fillPaint);

    // Top overhanging timber counter deck
    _pathA
      ..reset()
      ..moveTo(0, -34)
      ..lineTo(31, -19)
      ..lineTo(0, -4)
      ..lineTo(-31, -19)
      ..close();
    _fillPaint.color = const Color(0xFFD99E64);
    canvas.drawPath(_pathA, _fillPaint);

    // Vertical plank lines & crisp chestnut outline
    _strokePaint
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 1.4;
    canvas.drawPath(_pathA, _strokePaint);
    canvas.drawLine(const Offset(-28, -3), const Offset(0, 11), _strokePaint);
    canvas.drawLine(const Offset(0, 11), const Offset(28, -3), _strokePaint);
    canvas.drawLine(const Offset(0, -4), const Offset(0, 11), _strokePaint);
    for (final t in const <double>[0.33, 0.66]) {
      final lx = -28 * (1 - t);
      final ly = -3 + 14 * t;
      canvas.drawLine(Offset(lx, ly), Offset(lx, ly - 15), _strokePaint);
      final rx = 28 * t;
      final ry = 11 - 14 * t;
      canvas.drawLine(Offset(rx, ry), Offset(rx, ry - 15), _strokePaint);
    }

    // Back canopy posts supporting the awning
    _strokePaint
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 3.4;
    canvas.drawLine(const Offset(-26, -18), const Offset(-26, -47), _strokePaint);
    canvas.drawLine(const Offset(26, -18), const Offset(26, -47), _strokePaint);
    canvas.drawLine(const Offset(0, -32), const Offset(0, -54), _strokePaint);

    // Warm hanging brass lantern on front-left corner
    final lampSway = math.sin(animTime * 2.1) * 1.1;
    _fillPaint.color = const Color(0x55FFD54F);
    canvas.drawCircle(Offset(-25 + lampSway, -29), 7.5, _fillPaint);
    _fillPaint.color = const Color(0xFFFFEE58);
    canvas.drawCircle(Offset(-25 + lampSway, -29), 3.0, _fillPaint);

    canvas.restore();

    // Always display at least a sample produce display tray on empty stall, or live crates
    if (stallCrates.isEmpty) {
      CanvasDrawHelpers.drawWoodenCrate(
        canvas,
        Offset(cx - 10, cy - 17),
        ProductId.tomato,
        scale: 0.62,
      );
      CanvasDrawHelpers.drawWoodenCrate(
        canvas,
        Offset(cx + 10, cy - 17),
        ProductId.lemon,
        scale: 0.62,
      );
    } else {
      for (var i = 0; i < stallCrates.length && i < 6; i++) {
        final row = i ~/ 3;
        final col = i % 3;
        CanvasDrawHelpers.drawWoodenCrate(
          canvas,
          Offset(cx - 16 + col * 16.0, cy - 17 - row * 9.5),
          stallCrates[i],
          scale: 0.64,
        );
      }
    }

    // Scalloped sunlit red & cream striped fabric awning
    canvas.save();
    canvas.translate(cx, cy);
    final flutter = math.sin(animTime * 2.4) * 0.7;
    const stripeCount = 5;
    const totalW = 64.0;
    const stripeW = totalW / stripeCount;

    _fillPaint.color = const Color(0x363E2723);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-totalW * 0.5, -42, totalW, 8),
        const Radius.circular(3),
      ),
      _fillPaint,
    );

    for (var i = 0; i < stripeCount; i++) {
      final sx = -totalW * 0.5 + i * stripeW;
      final isRed = i.isEven;
      _fillPaint.color = isRed
          ? const Color(0xFFE53935)
          : const Color(0xFFFFF8E1);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(sx, -55, stripeW + 0.5, 16 + flutter * 0.3),
          topLeft: i == 0 ? const Radius.circular(4) : Radius.zero,
          topRight: i == stripeCount - 1 ? const Radius.circular(4) : Radius.zero,
          bottomLeft: const Radius.circular(6),
          bottomRight: const Radius.circular(6),
        ),
        _fillPaint,
      );
      _fillPaint.color = isRed
          ? const Color(0xFFC62828)
          : const Color(0xFFEDE0C8);
      canvas.drawCircle(
        Offset(sx + stripeW * 0.5, -39 + flutter * 0.35),
        stripeW * 0.48,
        _fillPaint,
      );
    }
    _strokePaint
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 1.4;
    canvas.drawLine(const Offset(-32, -55), const Offset(32, -55), _strokePaint);

    // Carved wooden signboard fascia crest with golden Solville Sun medallion
    final signBoard = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-18, -63, 36, 9.5),
      const Radius.circular(3.0),
    );
    _fillPaint.color = const Color(0xFF8D6E63);
    canvas.drawRRect(signBoard, _fillPaint);
    canvas.drawRRect(signBoard, _strokePaint);
    _fillPaint.color = const Color(0xFFFFCA28);
    canvas.drawCircle(const Offset(0, -58.2), 3.4, _fillPaint);
    _fillPaint.color = const Color(0xFFFFF59D);
    canvas.drawCircle(const Offset(-0.6, -58.8), 1.4, _fillPaint);

    // Woven wicker produce basket tucked beside the counter corner
    _fillPaint.color = const Color(0xFFC68A56);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-28, 3), width: 10, height: 7), _fillPaint);
    _fillPaint.color = const Color(0xFFE53935);
    canvas.drawCircle(const Offset(-29.5, 0.5), 1.8, _fillPaint);
    _fillPaint.color = const Color(0xFF43A047);
    canvas.drawCircle(const Offset(-26.5, 0.8), 1.7, _fillPaint);

    canvas.restore();
  }

  void drawStoneWell(Canvas canvas, double cx, double cy, double animTime) {
    _ensureShaders();
    _fillPaint.color = const Color(0x36261412);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 5), width: 54, height: 27),
      _fillPaint,
    );

    canvas.save();
    canvas.translate(cx, cy);

    // Curved stone masonry cylinder
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-21, -15, 42, 22),
      const Radius.circular(10),
    );
    _fillPaint.shader = _wellStoneShader;
    canvas.drawRRect(body, _fillPaint);
    _fillPaint.shader = null;

    // Mortar & stone block lines
    _strokePaint
      ..color = const Color(0x66455A64)
      ..strokeWidth = 1.1;
    canvas.drawRRect(body, _strokePaint);
    canvas.drawLine(const Offset(-20, -4), const Offset(20, -4), _strokePaint);
    canvas.drawLine(const Offset(-7, -12), const Offset(-7, -4), _strokePaint);
    canvas.drawLine(const Offset(8, -12), const Offset(8, -4), _strokePaint);
    canvas.drawLine(const Offset(0, -4), const Offset(0, 6), _strokePaint);

    // Mossy tufts at base of well
    _fillPaint.color = const Color(0xFF558B2F);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-14, 5), width: 8, height: 4), _fillPaint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(13, 4), width: 7, height: 3.5), _fillPaint);

    // Top stone rim
    _fillPaint.color = const Color(0xFFCFD8DC);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -13), width: 44, height: 19), _fillPaint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -13), width: 44, height: 19), _strokePaint);

    // Shimmering turquoise water, caustic ripple & starlight glints
    final shimmer = (math.sin(animTime * 3.2) + 1.0) * 0.5;
    _fillPaint.color = Color.lerp(
      const Color(0xFF0288D1),
      const Color(0xFF4FC3F7),
      shimmer,
    )!;
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -13), width: 31, height: 12.5), _fillPaint);

    final ripplePhase = (animTime * 0.85) % 1.0;
    _strokePaint
      ..color = Color.fromRGBO(255, 255, 255, (1.0 - ripplePhase) * 0.55)
      ..strokeWidth = 1.3;
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, -13),
        width: 8.0 + ripplePhase * 18.0,
        height: 3.2 + ripplePhase * 7.5,
      ),
      _strokePaint,
    );

    final glintPulseA = (math.sin(animTime * 4.4) + 1.0) * 0.5;
    final glintPulseB = (math.sin(animTime * 4.4 + 2.1) + 1.0) * 0.5;
    _fillPaint.color = Color.fromRGBO(255, 255, 255, 0.45 + glintPulseA * 0.5);
    CanvasDrawHelpers.drawStar4(
      canvas,
      const Offset(-7.5, -14.2),
      2.2 + glintPulseA * 1.1,
      _fillPaint,
    );
    _fillPaint.color = Color.fromRGBO(224, 247, 250, 0.40 + glintPulseB * 0.55);
    CanvasDrawHelpers.drawStar4(
      canvas,
      const Offset(8.0, -12.0),
      1.8 + glintPulseB * 1.0,
      _fillPaint,
    );

    // Timber posts + windlass rope crank
    _strokePaint
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 3.5;
    canvas.drawLine(const Offset(-16, -14), const Offset(-16, -40), _strokePaint);
    canvas.drawLine(const Offset(16, -14), const Offset(16, -40), _strokePaint);
    _strokePaint
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 2.6;
    canvas.drawLine(const Offset(-16, -28), const Offset(16, -28), _strokePaint);
    // Coiled rope drum & crank handle
    _strokePaint
      ..color = const Color(0xFFEFEBE9)
      ..strokeWidth = 1.5;
    for (var rx = -3.0; rx <= 3.0; rx += 2.0) {
      canvas.drawLine(Offset(rx, -29.8), Offset(rx, -26.2), _strokePaint);
    }
    final crankDrop = math.sin(animTime * 1.8) * 1.4;
    _strokePaint
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 1.8;
    canvas.drawLine(const Offset(16, -28), const Offset(20.5, -28), _strokePaint);
    canvas.drawLine(const Offset(20.5, -28), Offset(20.5, -23.5 + crankDrop), _strokePaint);
    _strokePaint
      ..color = const Color(0xFFA16B3B)
      ..strokeWidth = 2.4;
    canvas.drawLine(
      Offset(20.5, -23.5 + crankDrop),
      Offset(23.5, -23.5 + crankDrop),
      _strokePaint,
    );

    // Hanging rope & tiny dangling wooden bucket
    _strokePaint
      ..color = const Color(0xFFD7CCC8)
      ..strokeWidth = 1.6;
    canvas.drawLine(const Offset(0, -28), const Offset(0, -19), _strokePaint);
    _fillPaint.color = const Color(0xFF8D6E63);
    canvas.drawRect(const Rect.fromLTWH(-3, -20, 6, 5), _fillPaint);

    // Pitched terracotta-shingled well roof canopy
    _pathA
      ..reset()
      ..moveTo(-25, -36)
      ..lineTo(0, -53)
      ..lineTo(0, -37)
      ..close();
    _fillPaint.color = const Color(0xFFD84315);
    canvas.drawPath(_pathA, _fillPaint);

    _pathB
      ..reset()
      ..moveTo(0, -37)
      ..lineTo(0, -53)
      ..lineTo(25, -36)
      ..close();
    _fillPaint.color = const Color(0xFFBF360C);
    canvas.drawPath(_pathB, _fillPaint);

    // Terracotta shingle courses & ridge tile cap
    _strokePaint
      ..color = const Color(0x664E342E)
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(-17.5, -41.2), const Offset(17.5, -41.2), _strokePaint);
    canvas.drawLine(const Offset(-9.5, -46.8), const Offset(9.5, -46.8), _strokePaint);
    _strokePaint
      ..color = const Color(0xFFFF8A65)
      ..strokeWidth = 2.0;
    canvas.drawLine(const Offset(0, -53), const Offset(0, -37), _strokePaint);
    _fillPaint.color = const Color(0xFFFF7043);
    canvas.drawCircle(const Offset(0, -53.5), 1.9, _fillPaint);

    _strokePaint
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 1.3;
    canvas.drawPath(_pathA, _strokePaint);
    canvas.drawPath(_pathB, _strokePaint);

    canvas.restore();
  }

  void drawLemonTree(
    Canvas canvas,
    double cx,
    double cy,
    GridPos pos,
    TileState tile,
    double time, {
    bool showDetailedMeters = false,
  }) {
    final sway = math.sin(time * 1.3 + pos.x) * 2.4;
    _fillPaint.color = const Color(0x36261412);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 5), width: 48, height: 22),
      _fillPaint,
    );

    // Terracotta edging planter ring & rich earth mound
    _fillPaint.color = const Color(0xFF6D4C41);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 1), width: 32, height: 15), _fillPaint);
    _strokePaint
      ..color = const Color(0xFFD84315)
      ..strokeWidth = 2.8;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 1), width: 33, height: 15.5), _strokePaint);

    // Forked warm bark trunk
    _strokePaint
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 6.5;
    canvas.drawLine(Offset(cx, cy + 1), Offset(cx + sway * 0.25, cy - 21), _strokePaint);
    _strokePaint
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 2.8;
    canvas.drawLine(Offset(cx - 1, cy), Offset(cx - 1 + sway * 0.2, cy - 19), _strokePaint);
    canvas.drawLine(Offset(cx + sway * 0.2, cy - 15), Offset(cx - 7 + sway * 0.6, cy - 25), _strokePaint);
    canvas.drawLine(Offset(cx + sway * 0.2, cy - 15), Offset(cx + 7 + sway * 0.6, cy - 24), _strokePaint);

    // 6-layer dappled swaying citrus canopy
    _fillPaint.color = const Color(0xFF226827);
    canvas.drawCircle(Offset(cx + sway * 0.8, cy - 25), 16.0, _fillPaint);
    _fillPaint.color = const Color(0xFF2E7D32);
    canvas.drawCircle(Offset(cx + 10 + sway, cy - 28), 13.5, _fillPaint);
    _fillPaint.color = const Color(0xFF388E3C);
    canvas.drawCircle(Offset(cx - 10 + sway, cy - 29), 13.5, _fillPaint);
    _fillPaint.color = const Color(0xFF43A047);
    canvas.drawCircle(Offset(cx + sway, cy - 36), 15.5, _fillPaint);
    _fillPaint.color = const Color(0xFF66BB6A);
    canvas.drawCircle(Offset(cx + 7.5 + sway, cy - 36.5), 10.5, _fillPaint);
    _fillPaint.color = const Color(0xFF8BC34A);
    canvas.drawCircle(Offset(cx - 4 + sway, cy - 41), 9.5, _fillPaint);

    // Delicate fragrant white citrus blossoms tucked into the foliage
    for (final b in const <(double, double)>[(-11, -34), (11, -34), (-3, -43), (4, -27)]) {
      final bc = Offset(cx + b.$1 + sway, cy + b.$2);
      _fillPaint.color = const Color(0xFFFFFDF7);
      for (var p = 0; p < 4; p++) {
        final a = p * math.pi * 0.5;
        canvas.drawCircle(
          bc.translate(math.cos(a) * 1.3, math.sin(a) * 1.3),
          1.2,
          _fillPaint,
        );
      }
      _fillPaint.color = const Color(0xFFFFCA28);
      canvas.drawCircle(bc, 0.95, _fillPaint);
    }

    // Glossy oval Sunburst Lemons with fresh leaf sprigs & specular highlights
    if (tile.producerCrates > 0 || tile.producerProgress > 0.38) {
      final rx = tile.producerCrates > 0 ? 4.2 : 2.8;
      final ry = tile.producerCrates > 0 ? 3.2 : 2.2;
      for (final o in const <(double, double)>[(-9, -29), (8, -31), (1, -40), (-2, -23)]) {
        final lc = Offset(cx + o.$1 + sway, cy + o.$2);
        // Crisp citrus leaf sprig above stem
        _pathA
          ..reset()
          ..moveTo(lc.dx, lc.dy - ry)
          ..quadraticBezierTo(lc.dx + 4.5, lc.dy - ry - 3.5, lc.dx + 5.2, lc.dy - ry - 0.3)
          ..quadraticBezierTo(lc.dx + 2.5, lc.dy - ry + 0.5, lc.dx, lc.dy - ry);
        _fillPaint.color = const Color(0xFF2E7D32);
        canvas.drawPath(_pathA, _fillPaint);
        _fillPaint.color = const Color(0xFFFBC02D);
        canvas.drawOval(Rect.fromCenter(center: lc.translate(0.5, 0.7), width: rx * 2, height: ry * 2), _fillPaint);
        _fillPaint.color = const Color(0xFFFFEE58);
        canvas.drawOval(Rect.fromCenter(center: lc, width: rx * 2, height: ry * 2), _fillPaint);
        _fillPaint.color = const Color(0xAAFFFFFF);
        canvas.drawCircle(lc.translate(-rx * 0.35, -ry * 0.35), 1.0, _fillPaint);
      }
    }

    if (tile.producerCrates > 0) {
      if (showDetailedMeters) {
        CanvasDrawHelpers.drawFloatingStatusPill(
          canvas,
          cx,
          cy - 60,
          '🍋 ${tile.producerCrates}',
        );
      } else {
        final bob = math.sin(time * 4.2 + pos.x).abs() * 2.5;
        _fillPaint.color = const Color(0x4DFFCA28);
        canvas.drawCircle(Offset(cx, cy - 52 - bob), 8.8, _fillPaint);
        _fillPaint.color = const Color(0xF0FFEE58);
        CanvasDrawHelpers.drawStar4(canvas, Offset(cx, cy - 52 - bob), 6.0, _fillPaint);
      }
    }
  }

  void drawArtisanPress(
    Canvas canvas,
    double cx,
    double cy,
    TileState tile,
    double time, {
    bool isSunPassActive = true,
    bool showDetailedMeters = false,
  }) {
    _ensureShaders();
    _fillPaint.color = const Color(0x36261412);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 5), width: 54, height: 24),
      _fillPaint,
    );

    canvas.save();
    canvas.translate(cx, cy);

    // Stone-brick hearth base
    final hearth = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, -4), width: 40, height: 19),
      const Radius.circular(7),
    );
    _fillPaint
      ..shader = null
      ..color = const Color(0xFF8D7B72);
    canvas.drawRRect(hearth, _fillPaint);
    // Stone-brick mortar courses on flanks
    _strokePaint
      ..color = const Color(0x553E2723)
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(-18, -8), const Offset(18, -8), _strokePaint);
    canvas.drawLine(const Offset(-19, -2), const Offset(-8, -2), _strokePaint);
    canvas.drawLine(const Offset(8, -2), const Offset(19, -2), _strokePaint);
    canvas.drawLine(const Offset(-12, -13), const Offset(-12, -8), _strokePaint);
    canvas.drawLine(const Offset(12, -13), const Offset(12, -8), _strokePaint);
    canvas.drawLine(const Offset(-13, -2), const Offset(-13, 4), _strokePaint);
    canvas.drawLine(const Offset(13, -2), const Offset(13, 4), _strokePaint);
    _strokePaint
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 1.3;
    canvas.drawRRect(hearth, _strokePaint);

    // Arched firebox opening
    _fillPaint.color = const Color(0xFF3E2723);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(-7, -6, 14, 10),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      ),
      _fillPaint,
    );

    if (tile.producerActive) {
      final glow = (math.sin(time * 7.5) + 1.0) * 0.5;
      _fillPaint.color = const Color(0xFFFF7043);
      canvas.drawCircle(Offset(0, 0), 5.5 + glow * 1.8, _fillPaint);
      _fillPaint.color = const Color(0xFFFFEE58);
      canvas.drawCircle(Offset(0, 1), 3.0 + glow * 1.0, _fillPaint);
    }

    // Hammered burnished copper cauldron
    final kettle = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, -17), width: 32, height: 21),
      const Radius.circular(10),
    );
    _fillPaint.shader = _copperKettleShader;
    canvas.drawRRect(kettle, _fillPaint);
    _fillPaint.shader = null;
    canvas.drawRRect(kettle, _strokePaint);

    // Glossy copper crescent highlight
    _strokePaint
      ..color = const Color(0x66FFF8E1)
      ..strokeWidth = 2.0;
    canvas.drawArc(
      const Rect.fromLTWH(-12, -23, 10, 11),
      math.pi * 0.9,
      math.pi * 0.55,
      false,
      _strokePaint,
    );

    // Riveted brass handles
    _strokePaint
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 2.2;
    canvas.drawArc(const Rect.fromLTWH(-20, -21, 7, 9), math.pi * 0.5, math.pi, false, _strokePaint);
    canvas.drawArc(const Rect.fromLTWH(13, -21, 7, 9), -math.pi * 0.5, math.pi, false, _strokePaint);

    // Cauldron rim + simmering jam surface
    _fillPaint.color = const Color(0xFFE69148);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -25), width: 30, height: 11), _fillPaint);
    _fillPaint.color = tile.producerActive
        ? const Color(0xFFC2185B)
        : const Color(0xFF4E342E);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -25), width: 24, height: 8.5), _fillPaint);

    if (tile.producerActive) {
      for (var b = 0; b < 3; b++) {
        final bPhase = (time * 1.45 + b * 0.37) % 1.0;
        final bx = -6.0 + b * 6.0;
        final by = -24.5 - bPhase * 3.5;
        final br = 1.2 + math.sin(bPhase * math.pi) * 1.3;
        _fillPaint.color = Color.fromRGBO(252, 228, 236, (1.0 - bPhase * 0.65) * 0.85);
        canvas.drawCircle(Offset(bx, by), br, _fillPaint);
      }
    }

    // Wooden stirring paddle sticking out
    _strokePaint
      ..color = const Color(0xFFD7A86E)
      ..strokeWidth = 2.6;
    canvas.drawLine(const Offset(3, -25), const Offset(11, -36), _strokePaint);

    // Cute miniature glass preserve jars beside hearth
    _fillPaint.color = const Color(0xFFE1F5FE);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-21, -2, 6, 8), const Radius.circular(2)),
      _fillPaint,
    );
    _fillPaint.color = const Color(0xFFD81B60);
    canvas.drawRect(const Rect.fromLTWH(-20, 1, 4, 4), _fillPaint);
    _fillPaint.color = const Color(0xFFFFCA28);
    canvas.drawRect(const Rect.fromLTWH(-20.5, -3.5, 5, 2), _fillPaint);

    canvas.restore();

    if (tile.producerActive) {
      for (var s = 0; s < 3; s++) {
        final phase = ((time * 0.85 + s * 0.33) % 1.0);
        _fillPaint.color = Color.fromRGBO(255, 250, 236, (1.0 - phase) * 0.72);
        canvas.drawCircle(
          Offset(cx - 5 + s * 5.0 + math.sin(time * 3 + s) * 2.0, cy - 31 - phase * 20.0),
          3.4 * (1.0 - phase * 0.3),
          _fillPaint,
        );
      }
      CanvasDrawHelpers.drawProgressArc(
        canvas,
        Offset(cx, cy - 45),
        9.2,
        tile.producerProgress,
        const Color(0xFFFF7043),
        trackColor: const Color(0x88FFF8E1),
        strokeWidth: 3.0,
      );
    } else if (showDetailedMeters &&
        tile.producerCrates == 0 &&
        isSunPassActive) {
      CanvasDrawHelpers.drawFloatingStatusPill(
        canvas,
        cx,
        cy - 45,
        tile.kettleRecipe.formulaEmoji,
      );
    }

    if (tile.producerCrates > 0) {
      CanvasDrawHelpers.drawWoodenCrate(
        canvas,
        Offset(cx + 19, cy + 3),
        tile.kettleRecipe.outputProduct,
        scale: 0.65,
      );
      if (showDetailedMeters) {
        CanvasDrawHelpers.drawFloatingStatusPill(
          canvas,
          cx,
          cy - 48,
          '${SolvilleCatalog.productEmoji(tile.kettleRecipe.outputProduct)} ${tile.producerCrates}',
        );
      } else {
        final bob = math.sin(time * 4.2).abs() * 2.5;
        _fillPaint.color = const Color(0x4DFFCA28);
        canvas.drawCircle(Offset(cx, cy - 41 - bob), 8.2, _fillPaint);
        _fillPaint.color = const Color(0xF0FFEE58);
        CanvasDrawHelpers.drawStar4(canvas, Offset(cx, cy - 41 - bob), 5.8, _fillPaint);
      }
    }
  }

  void drawRotarySprinkler(Canvas canvas, double cx, double cy, double time) {
    _fillPaint.color = const Color(0x33261412);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 2), width: 24, height: 12), _fillPaint);

    // Brass collar & vertical riser
    _fillPaint.color = const Color(0xFF795548);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 16, height: 8), _fillPaint);
    _fillPaint.color = const Color(0xFFD49B35);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - 1), width: 12, height: 6), _fillPaint);
    _strokePaint
      ..color = const Color(0xFFB0BEC5)
      ..strokeWidth = 3.8;
    canvas.drawLine(Offset(cx, cy - 1), Offset(cx, cy - 14), _strokePaint);

    // Rotating spray arms + droplet arcs
    final angle = time * 2.4;
    final dx = math.cos(angle) * 11.5;
    final dy = math.sin(angle) * 5.8;
    _strokePaint
      ..color = const Color(0xFF0288D1)
      ..strokeWidth = 2.8;
    canvas.drawLine(Offset(cx - dx, cy - 14 - dy), Offset(cx + dx, cy - 14 + dy), _strokePaint);

    _fillPaint.color = const Color(0xAA4FC3F7);
    for (var s = 0; s < 2; s++) {
      final phase = (time * 2.2 + s * 0.5) % 1.0;
      final sign = s == 0 ? 1.0 : -1.0;
      canvas.drawCircle(
        Offset(cx + sign * (dx + dx * phase * 0.9), cy - 14 + sign * (dy + dy * phase * 0.9) - math.sin(phase * math.pi) * 6.0),
        2.0 * (1.0 - phase * 0.5),
        _fillPaint,
      );
    }
  }

  void drawSolarSprinkler(Canvas canvas, double cx, double cy, double time) {
    _fillPaint.color = const Color(0x38261412);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 3), width: 32, height: 15), _fillPaint);

    // Bronze-gold tower column
    _fillPaint.color = const Color(0xFFE69A00);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 11), width: 12, height: 24),
        const Radius.circular(5),
      ),
      _fillPaint,
    );
    _fillPaint.color = const Color(0xFFFFD54F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 2, cy - 11), width: 5, height: 22),
        const Radius.circular(3),
      ),
      _fillPaint,
    );

    // Sapphire solar collector disc
    _fillPaint.color = const Color(0xFF1565C0);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - 25), width: 26, height: 12), _fillPaint);
    _strokePaint
      ..color = const Color(0xFFFFCA28)
      ..strokeWidth = 1.6;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - 25), width: 26, height: 12), _strokePaint);
    _strokePaint
      ..color = const Color(0x6681D4FA)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(cx - 8, cy - 25), Offset(cx + 8, cy - 25), _strokePaint);

    // Pulsing solar mist orb
    final pulse = (math.sin(time * 3.8) + 1) * 0.5;
    _fillPaint.color = const Color(0x774FC3F7);
    canvas.drawCircle(Offset(cx, cy - 16), 5.0 + pulse * 3.2, _fillPaint);
  }

  void drawSolarLantern(
    Canvas canvas,
    double cx,
    double cy,
    double dayProgress,
    double time, {
    bool warmGlowActive = false,
  }) {
    final isDusk = dayProgress > 0.54 || warmGlowActive;
    final flicker = 0.85 + 0.15 * math.sin(time * 5.0 + cx);
    _fillPaint.color = Color.fromRGBO(255, 213, 79, isDusk ? 0.45 * flicker : 0.16);
    canvas.drawCircle(
      Offset(cx + 3, cy - 22),
      (isDusk ? 26.0 : 15.0) * flicker,
      _fillPaint,
    );

    // Stone collar base + curved wrought-iron shepherd's hook
    _fillPaint.color = const Color(0xFF8D827A);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 1), width: 12, height: 6), _fillPaint);

    _pathA
      ..reset()
      ..moveTo(cx, cy + 1)
      ..lineTo(cx, cy - 28)
      ..quadraticBezierTo(cx, cy - 35, cx + 6, cy - 32)
      ..lineTo(cx + 7, cy - 28);
    _strokePaint
      ..color = const Color(0xFF3E2723)
      ..strokeWidth = 2.8;
    canvas.drawPath(_pathA, _strokePaint);

    // Hexagonal brass lantern glass & cap
    _fillPaint.color = isDusk ? const Color(0xFFFFEE58) : const Color(0xFFFFF59D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 7, cy - 22), width: 9.5, height: 11),
        const Radius.circular(2.5),
      ),
      _fillPaint,
    );
    _strokePaint
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 1.4;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 7, cy - 22), width: 9.5, height: 11),
        const Radius.circular(2.5),
      ),
      _strokePaint,
    );

    _pathB
      ..reset()
      ..moveTo(cx + 0.5, cy - 27)
      ..lineTo(cx + 7, cy - 32)
      ..lineTo(cx + 13.5, cy - 27)
      ..close();
    _fillPaint.color = const Color(0xFF4E342E);
    canvas.drawPath(_pathB, _fillPaint);
  }

  void drawFlowerArch(Canvas canvas, double cx, double cy, double time) {
    final sway = math.sin(time * 1.4) * 0.8;
    _fillPaint.color = const Color(0x28261412);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 21, cy + 3), width: 12, height: 6), _fillPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 21, cy + 3), width: 12, height: 6), _fillPaint);

    // Timber arch frame with dark outline & sunlit bevel
    _strokePaint
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 5.4;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - 7), width: 44, height: 58),
      math.pi,
      math.pi,
      false,
      _strokePaint,
    );
    _strokePaint
      ..color = const Color(0xFF9C724C)
      ..strokeWidth = 3.2;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - 7), width: 44, height: 58),
      math.pi,
      math.pi,
      false,
      _strokePaint,
    );

    // Climbing foliage clusters & multi-petal roses
    for (var i = 0; i <= 8; i++) {
      final a = math.pi + (math.pi * i / 8.0);
      final fx = cx + math.cos(a) * 22.0 + sway * 0.5;
      final fy = cy - 7 + math.sin(a) * 29.0;
      _fillPaint.color = i.isEven ? const Color(0xFF2E7D32) : const Color(0xFF43A047);
      canvas.drawCircle(Offset(fx, fy), 5.6, _fillPaint);
      _fillPaint.color = switch (i % 3) {
        0 => const Color(0xFFEC407A),
        1 => const Color(0xFFFF80AB),
        _ => const Color(0xFFFFF59D),
      };
      canvas.drawCircle(Offset(fx - 1, fy - 1), 3.3, _fillPaint);
      _fillPaint.color = const Color(0xFFFFEE58);
      canvas.drawCircle(Offset(fx - 1, fy - 1), 1.1, _fillPaint);
    }
  }

  void drawExpansionLandmark(
    Canvas canvas,
    double cx,
    double cy,
    TileState tile,
    double time, {
    bool showDetailedMeters = false,
  }) {
    final bob = math.sin(time * 3.5) * 2.5;
    switch (tile.landmark) {
      case LandmarkKind.treasureCache:
        _fillPaint.color = const Color(0x36261412);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 4), width: 34, height: 15), _fillPaint);

        final chest = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy - 8), width: 28, height: 19),
          const Radius.circular(5),
        );
        _fillPaint.color = const Color(0xFF795548);
        canvas.drawRRect(chest, _fillPaint);
        // Propped lid & golden treasure glow seam
        _fillPaint.color = const Color(0xFFFFE082);
        canvas.drawRect(Rect.fromLTWH(cx - 12, cy - 11.5, 24, 3.0), _fillPaint);
        _fillPaint.color = const Color(0xFFA1887F);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromCenter(center: Offset(cx, cy - 14), width: 29, height: 8.5),
            topLeft: const Radius.circular(5),
            topRight: const Radius.circular(5),
          ),
          _fillPaint,
        );
        _fillPaint.color = const Color(0xFFFFCA28);
        canvas.drawRect(Rect.fromLTWH(cx - 14, cy - 9.5, 28, 2.8), _fillPaint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy - 8), width: 6, height: 7),
            const Radius.circular(2),
          ),
          _fillPaint,
        );
        if (!tile.landmarkClaimed) {
          _fillPaint.color = const Color(0xFFFFEE58);
          CanvasDrawHelpers.drawStar4(canvas, Offset(cx + 8, cy - 22 + bob), 5.2, _fillPaint);
          _fillPaint.color = const Color(0xFFE91E63);
          canvas.drawCircle(Offset(cx - 6, cy - 11), 1.5, _fillPaint);
        }
        if (showDetailedMeters) {
          CanvasDrawHelpers.drawFloatingStatusPill(canvas, cx, cy - 32 + bob, '💎');
        }

      case LandmarkKind.wildflowerShrine:
        _fillPaint.color = const Color(0x36261412);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 4), width: 30, height: 15), _fillPaint);
        _fillPaint.color = const Color(0xFFBDBDBD);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy - 10), width: 16, height: 22),
            const Radius.circular(4),
          ),
          _fillPaint,
        );
        _fillPaint.color = const Color(0xFF9E9E9E);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy - 2), width: 22, height: 6),
            const Radius.circular(2.5),
          ),
          _fillPaint,
        );
        _fillPaint.color = const Color(0xFF689F38);
        canvas.drawCircle(Offset(cx - 5, cy - 4), 3.6, _fillPaint);
        canvas.drawCircle(Offset(cx + 5, cy - 4), 3.2, _fillPaint);
        // Sculpted blooming shrine crown
        _fillPaint.color = const Color(0xFFF48FB1);
        canvas.drawCircle(Offset(cx, cy - 24), 9.5, _fillPaint);
        _fillPaint.color = const Color(0xFFCE93D8);
        canvas.drawCircle(Offset(cx - 5, cy - 22), 4.2, _fillPaint);
        _fillPaint.color = const Color(0xFFFFEE58);
        canvas.drawCircle(Offset(cx, cy - 24), 3.5, _fillPaint);
        if (showDetailedMeters) {
          CanvasDrawHelpers.drawFloatingStatusPill(canvas, cx, cy - 42 + bob, '🌸');
        } else if (!tile.landmarkClaimed) {
          _fillPaint.color = const Color(0xEEFFEE58);
          CanvasDrawHelpers.drawStar4(canvas, Offset(cx, cy - 38 + bob), 5.2, _fillPaint);
        }

      case LandmarkKind.oasisFountain:
        _fillPaint.color = const Color(0x36261412);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 4), width: 48, height: 23), _fillPaint);
        // Tier 1 sculpted marble basin
        _fillPaint.color = const Color(0xFFCFD8DC);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - 3), width: 46, height: 22), _fillPaint);
        _fillPaint.color = const Color(0xFF29B6F6);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - 5), width: 35, height: 15), _fillPaint);
        // Central carved pillar & Tier 2 upper bowl
        _fillPaint.color = const Color(0xFFECEFF1);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy - 16), width: 10, height: 20),
            const Radius.circular(4),
          ),
          _fillPaint,
        );
        _fillPaint.color = const Color(0xFFCFD8DC);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - 21), width: 24, height: 11), _fillPaint);
        _fillPaint.color = const Color(0xFF4FC3F7);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - 22), width: 18, height: 7), _fillPaint);
        // Animated arcing water jets splashing into both tiers
        final phase = (time * 1.85) % 1.0;
        final phase2 = (time * 1.85 + 0.5) % 1.0;
        _fillPaint.color = Color.fromRGBO(225, 245, 254, (1.0 - phase) * 0.88);
        canvas.drawCircle(Offset(cx - 11 * phase, cy - 28 + phase * 20), 2.3, _fillPaint);
        canvas.drawCircle(Offset(cx + 11 * phase, cy - 28 + phase * 20), 2.3, _fillPaint);
        _fillPaint.color = Color.fromRGBO(225, 245, 254, (1.0 - phase2) * 0.82);
        canvas.drawCircle(Offset(cx - 6 * phase2, cy - 29 + phase2 * 9), 1.8, _fillPaint);
        canvas.drawCircle(Offset(cx + 6 * phase2, cy - 29 + phase2 * 9), 1.8, _fillPaint);
        if (showDetailedMeters) {
          CanvasDrawHelpers.drawFloatingStatusPill(
            canvas,
            cx,
            cy - 40 + bob,
            tile.landmarkClaimed ? '💧' : '✨💧',
          );
        } else if (!tile.landmarkClaimed) {
          _fillPaint.color = const Color(0xEEFFEE58);
          CanvasDrawHelpers.drawStar4(canvas, Offset(cx, cy - 36 + bob), 5.2, _fillPaint);
        }

      case LandmarkKind.none:
        break;
    }
  }

  void drawExpressOrderBubble(
    Canvas canvas,
    double x,
    double y,
    ExpressOrder order,
  ) {
    final pill = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, y), width: 50, height: 26),
      const Radius.circular(13),
    );
    _fillPaint.color = const Color(0x333E2723);
    canvas.drawRRect(pill.shift(const Offset(0, 1.5)), _fillPaint);
    _fillPaint.color = const Color(0xFAFFFDF6);
    canvas.drawRRect(pill, _fillPaint);
    _strokePaint
      ..color = const Color(0xFFFF6F00)
      ..strokeWidth = 2.0;
    canvas.drawRRect(pill, _strokePaint);
    CanvasDrawHelpers.drawProgressArc(
      canvas,
      Offset(x - 14, y),
      8.0,
      order.progressFraction,
      const Color(0xFFFF6F00),
      trackColor: const Color(0x33FF6F00),
      strokeWidth: 2.5,
    );
    CanvasDrawHelpers.drawCenteredText(
      canvas,
      '${SolvilleCatalog.productEmoji(order.product)}${order.deliveredCount}/${order.requiredCount}',
      Offset(x + 7, y),
      _recipeTextStyle,
    );
  }
}
