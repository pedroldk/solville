import 'dart:math' as math;
import 'dart:ui';

import '../../domain/models/tile_state.dart';
import 'canvas_draw_helpers.dart';

/// Renders detailed 2.5D Cozy Henhouses, Wildflower Apiaries, and Sunny Cow
/// Paddocks with expressive animated hens, orbiting winged honeybees, and a
/// spotted dairy cow layered inside a true 3D isometric rail fence.
class AnimalsPainter {
  final Paint _fillPaint = Paint();
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final Path _path = Path();

  void drawHenhouse(
    Canvas canvas,
    double cx,
    double cy,
    AnimalUnitState? state,
    double time, {
    bool showDetailedMeters = false,
  }) {
    // Contact shadow & straw yard
    _fillPaint.color = const Color(0x36261412);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 5), width: 60, height: 27),
      _fillPaint,
    );
    _fillPaint.color = const Color(0x55FFE082);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 8, cy + 4), width: 30, height: 14),
      _fillPaint,
    );

    canvas.save();
    canvas.translate(cx - 7, cy);

    // Timber corner stilts
    _strokePaint
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 3.0;
    canvas.drawLine(const Offset(-13, -3), const Offset(-13, 3), _strokePaint);
    canvas.drawLine(const Offset(13, -3), const Offset(13, 3), _strokePaint);

    // Slatted cedar coop body
    final coop = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, -14), width: 32, height: 21),
      const Radius.circular(4.5),
    );
    _fillPaint.color = const Color(0xFFD8A66B);
    canvas.drawRRect(coop, _fillPaint);
    _strokePaint
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 1.3;
    canvas.drawRRect(coop, _strokePaint);
    // Horizontal plank seams
    _strokePaint
      ..color = const Color(0x4D5D4037)
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(-15, -18), const Offset(15, -18), _strokePaint);
    canvas.drawLine(const Offset(-15, -10), const Offset(15, -10), _strokePaint);

    // Dark arched coop door & miniature wooden ramp
    _fillPaint.color = const Color(0xFF3E2723);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(2, -16, 8, 12),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      ),
      _fillPaint,
    );
    _strokePaint
      ..color = const Color(0xFFA16B3B)
      ..strokeWidth = 3.5;
    canvas.drawLine(const Offset(6, -4), const Offset(14, 3), _strokePaint);

    // Pitched terracotta-shingle coop roof
    _path
      ..reset()
      ..moveTo(-20, -23)
      ..lineTo(0, -37)
      ..lineTo(20, -23)
      ..close();
    _fillPaint.color = const Color(0xFFE65100);
    canvas.drawPath(_path, _fillPaint);
    // Scalloped roof shingle courses
    _strokePaint
      ..color = const Color(0x664E342E)
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(-13.5, -27.5), const Offset(13.5, -27.5), _strokePaint);
    canvas.drawLine(const Offset(-7.0, -32.0), const Offset(7.0, -32.0), _strokePaint);
    _strokePaint
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 1.4;
    canvas.drawPath(_path, _strokePaint);
    // Roof crest ridge & coop gable louvre vent
    _strokePaint
      ..color = const Color(0xFFFF8A65)
      ..strokeWidth = 2.0;
    canvas.drawLine(const Offset(-18, -24), const Offset(0, -36.5), _strokePaint);
    _fillPaint.color = const Color(0xFFFF7043);
    canvas.drawCircle(const Offset(0, -37.2), 1.8, _fillPaint);
    _fillPaint.color = const Color(0xFF3E2723);
    canvas.drawCircle(const Offset(-7, -26.5), 2.3, _fillPaint);
    _strokePaint
      ..color = const Color(0xFFFFECB3)
      ..strokeWidth = 0.9;
    canvas.drawCircle(const Offset(-7, -26.5), 2.3, _strokePaint);

    // Cozy straw egg nest filled when eggs are ready
    if ((state?.readyCrates ?? 0) > 0) {
      _fillPaint.color = const Color(0xFFE6A14D);
      canvas.drawOval(Rect.fromCenter(center: const Offset(-5, 3.5), width: 13, height: 6.5), _fillPaint);
      _fillPaint.color = const Color(0xFFFFD54F);
      canvas.drawOval(Rect.fromCenter(center: const Offset(-5, 2.8), width: 10.5, height: 4.5), _fillPaint);
      _fillPaint.color = const Color(0xFFFFFDF5);
      canvas.drawOval(Rect.fromCenter(center: const Offset(-6.8, 2.2), width: 3.4, height: 4.2), _fillPaint);
      _fillPaint.color = const Color(0xFFFFECB3);
      canvas.drawOval(Rect.fromCenter(center: const Offset(-3.2, 2.5), width: 3.3, height: 4.0), _fillPaint);
    }

    canvas.restore();

    // Two expressive pecking hens
    _drawDetailedHen(
      canvas,
      cx + 13,
      cy + 2,
      time: time,
      phase: 0.0,
      bodyColor: const Color(0xFFFFFDF7),
      wingColor: const Color(0xFFECE3D3),
      facingLeft: false,
    );
    _drawDetailedHen(
      canvas,
      cx + 2,
      cy + 9,
      time: time,
      phase: 1.9,
      bodyColor: const Color(0xFFFFCC80),
      wingColor: const Color(0xFFE6A14D),
      facingLeft: true,
    );

    CanvasDrawHelpers.drawAnimalStatusBubble(
      canvas,
      cx,
      cy - 46,
      state,
      '🥚',
      showDetailedMeters: showDetailedMeters,
      animTime: time,
    );
  }

  void _drawDetailedHen(
    Canvas canvas,
    double x,
    double y, {
    required double time,
    required double phase,
    required Color bodyColor,
    required Color wingColor,
    required bool facingLeft,
  }) {
    final dir = facingLeft ? -1.0 : 1.0;
    final peck = math.max(0.0, math.sin(time * 3.4 + phase)) * 3.4;

    canvas.save();
    canvas.translate(x, y);

    // Micro shadow + tiny orange legs
    _fillPaint.color = const Color(0x28000000);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 3), width: 12, height: 5), _fillPaint);
    _strokePaint
      ..color = const Color(0xFFEF6C00)
      ..strokeWidth = 1.3;
    canvas.drawLine(const Offset(-1.5, 0), const Offset(-1.5, 2.8), _strokePaint);
    canvas.drawLine(const Offset(1.5, 0), const Offset(1.5, 2.8), _strokePaint);

    // Tail feathers
    _path
      ..reset()
      ..moveTo(-dir * 4, -2)
      ..lineTo(-dir * 8.5, -7)
      ..lineTo(-dir * 6, -1)
      ..close();
    _fillPaint.color = wingColor;
    canvas.drawPath(_path, _fillPaint);

    // Plump oval body + shaded contoured wing
    _fillPaint.color = bodyColor;
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -3), width: 11.5, height: 8.5), _fillPaint);
    _fillPaint.color = wingColor;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-dir * 1.0, -2.6), width: 6.5, height: 4.5),
      _fillPaint,
    );
    _strokePaint
      ..color = const Color(0x555D4037)
      ..strokeWidth = 0.85;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(-dir * 1.0, -2.5), width: 6.2, height: 4.2),
      0.2,
      math.pi * 0.9,
      false,
      _strokePaint,
    );

    // Bobbing head, red comb, wattle, orange beak & glossy eye
    final hx = dir * 4.5;
    final hy = -6.0 + peck;
    _fillPaint.color = bodyColor;
    canvas.drawCircle(Offset(hx, hy), 3.6, _fillPaint);

    _fillPaint.color = const Color(0xFFE53935);
    canvas.drawCircle(Offset(hx - dir * 0.4, hy - 3.6), 1.6, _fillPaint);
    canvas.drawCircle(Offset(hx + dir * 1.0, hy - 3.2), 1.3, _fillPaint);
    // Miniature red wattle under beak
    canvas.drawCircle(Offset(hx + dir * 2.2, hy + 2.0), 1.15, _fillPaint);

    // Orange beak
    _path
      ..reset()
      ..moveTo(hx + dir * 3.0, hy - 0.8)
      ..lineTo(hx + dir * 5.8, hy + 0.2)
      ..lineTo(hx + dir * 3.0, hy + 1.2)
      ..close();
    _fillPaint.color = const Color(0xFFFF9800);
    canvas.drawPath(_path, _fillPaint);

    _fillPaint.color = const Color(0xFF3E2723);
    canvas.drawCircle(Offset(hx + dir * 1.3, hy - 0.8), 0.9, _fillPaint);

    canvas.restore();
  }

  void drawBeehive(
    Canvas canvas,
    double cx,
    double cy,
    AnimalUnitState? state,
    double time, {
    bool showDetailedMeters = false,
  }) {
    _fillPaint.color = const Color(0x33261412);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 44, height: 21),
      _fillPaint,
    );

    canvas.save();
    canvas.translate(cx, cy);

    // Clover patch & wooden stand
    _fillPaint.color = const Color(0xFF43A047);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 2), width: 36, height: 14), _fillPaint);
    _fillPaint.color = const Color(0xFFF48FB1);
    canvas.drawCircle(const Offset(-13, 2), 2.0, _fillPaint);
    _fillPaint.color = const Color(0xFFFFF59D);
    canvas.drawCircle(const Offset(13, 1), 2.0, _fillPaint);

    _fillPaint.color = const Color(0xFF6D4C41);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -1), width: 28, height: 6),
        const Radius.circular(2.5),
      ),
      _fillPaint,
    );

    // 3-tier woven honey-straw skep with sunlit highlights
    for (var i = 0; i < 3; i++) {
      final w = 28.0 - i * 4.5;
      final tierRect = Rect.fromCenter(center: Offset(0, -6.5 - i * 7.5), width: w, height: 9.5);
      _fillPaint.color = i.isEven ? const Color(0xFFFFCA28) : const Color(0xFFFFB300);
      canvas.drawRRect(RRect.fromRectAndRadius(tierRect, const Radius.circular(5)), _fillPaint);
      _strokePaint
        ..color = const Color(0x998D5A00)
        ..strokeWidth = 1.2;
      canvas.drawRRect(RRect.fromRectAndRadius(tierRect, const Radius.circular(5)), _strokePaint);
      _fillPaint.color = const Color(0x55FFF9C4);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-w * 0.16, -8.5 - i * 7.5), width: w * 0.42, height: 3.0),
        _fillPaint,
      );
    }

    // Protective wooden cap, landing board & golden honey-drip arched entry
    _path
      ..reset()
      ..moveTo(-12, -26)
      ..lineTo(0, -33)
      ..lineTo(12, -26)
      ..close();
    _fillPaint.color = const Color(0xFF795548);
    canvas.drawPath(_path, _fillPaint);

    // Timber landing board ledge
    _fillPaint.color = const Color(0xFF8D6E63);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -3.2), width: 11.5, height: 2.8),
        const Radius.circular(1.2),
      ),
      _fillPaint,
    );

    _fillPaint.color = const Color(0xFF3E2723);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(-3.5, -10, 7, 7),
        topLeft: const Radius.circular(3.5),
        topRight: const Radius.circular(3.5),
      ),
      _fillPaint,
    );
    _fillPaint.color = const Color(0xFFFFA000);
    canvas.drawCircle(const Offset(0, -4), 1.8, _fillPaint);

    // Miniature terracotta honey pot on clover stand when honey crates are ready
    if ((state?.readyCrates ?? 0) > 0) {
      _fillPaint.color = const Color(0xFFD84315);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(11.5, -1.5), width: 6.5, height: 6.0),
          const Radius.circular(2.6),
        ),
        _fillPaint,
      );
      _fillPaint.color = const Color(0xFFFFCA28);
      canvas.drawOval(Rect.fromCenter(center: const Offset(11.5, -4.2), width: 5.8, height: 2.4), _fillPaint);
      _fillPaint.color = const Color(0xFFFFF8E1);
      canvas.drawRect(const Rect.fromLTWH(9.8, -3.2, 3.4, 1.0), _fillPaint);
    }

    // Soft golden pollen orbit shimmer around the skep
    final shimmerAlpha = (0.14 + (math.sin(time * 2.6) + 1.0) * 0.06).clamp(0.0, 1.0);
    _strokePaint
      ..color = Color.fromRGBO(255, 224, 130, shimmerAlpha)
      ..strokeWidth = 1.6;
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -16), width: 38, height: 15), _strokePaint);

    // 4 striped honeybees with fluttering wings orbiting smoothly
    for (var b = 0; b < 4; b++) {
      final a = time * 2.4 + b * 1.57;
      final bx = math.cos(a) * 19.0;
      final by = -16.0 + math.sin(a * 2.0) * 6.5;
      final flap = math.sin(time * 24.0 + b).abs() * 2.5;

      // Translucent wings
      _fillPaint.color = const Color(0xCCFFFFFF);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(bx - 1.5, by - 2.2 - flap * 0.4), width: 3.6, height: 2.8),
        _fillPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(bx + 1.5, by - 2.2 - flap * 0.4), width: 3.6, height: 2.8),
        _fillPaint,
      );

      // Gold & brown striped bee body
      _fillPaint.color = const Color(0xFFFFEE58);
      canvas.drawOval(Rect.fromCenter(center: Offset(bx, by), width: 5.2, height: 3.6), _fillPaint);
      _strokePaint
        ..color = const Color(0xFF3E2723)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(bx, by - 1.5), Offset(bx, by + 1.5), _strokePaint);
    }

    canvas.restore();

    CanvasDrawHelpers.drawAnimalStatusBubble(
      canvas,
      cx,
      cy - 44,
      state,
      '🍯',
      showDetailedMeters: showDetailedMeters,
      animTime: time,
    );
  }

  void drawCowPaddock(
    Canvas canvas,
    double cx,
    double cy,
    AnimalUnitState? state,
    double time, {
    bool showDetailedMeters = false,
  }) {
    canvas.save();
    canvas.translate(cx, cy);

    // Lush sunlit clover pasture patch & wildflowers
    _fillPaint.color = const Color(0xFF689F38);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 0), width: 70, height: 35), _fillPaint);
    _fillPaint.color = const Color(0xFF8BC34A);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-2, -1), width: 56, height: 24), _fillPaint);

    // Clover tufts & miniature pasture daisies
    for (final c in const <(double, double)>[(-22, 2), (18, -5), (16, 7), (-6, 10)]) {
      _fillPaint.color = const Color(0xFF33691E);
      canvas.drawCircle(Offset(c.$1 - 1.3, c.$2), 1.4, _fillPaint);
      canvas.drawCircle(Offset(c.$1 + 1.3, c.$2), 1.4, _fillPaint);
      canvas.drawCircle(Offset(c.$1, c.$2 - 1.2), 1.4, _fillPaint);
    }
    _fillPaint.color = const Color(0xFFFFFDF7);
    canvas.drawCircle(const Offset(-20, 4), 1.6, _fillPaint);
    canvas.drawCircle(const Offset(19, 6), 1.5, _fillPaint);
    _fillPaint.color = const Color(0xFFFFCA28);
    canvas.drawCircle(const Offset(-20, 4), 0.7, _fillPaint);
    canvas.drawCircle(const Offset(19, 6), 0.65, _fillPaint);

    // Isometric diamond fence coordinates
    const top = Offset(0, -19.5);
    const right = Offset(36, -1);
    const bottom = Offset(0, 17.5);
    const left = Offset(-36, -1);

    // Back 2 rails + back posts (behind the cow)
    _drawFenceSegment(canvas, left, top);
    _drawFenceSegment(canvas, top, right);
    _drawFencePost(canvas, top);
    _drawFencePost(canvas, left);
    _drawFencePost(canvas, right);

    // Timber feeding hay trough & wooden water pail in corner
    _fillPaint.color = const Color(0xFF6D4C41);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(-17.5, -4), width: 13.5, height: 6.5),
        const Radius.circular(2.0),
      ),
      _fillPaint,
    );
    _fillPaint.color = const Color(0xFFFFD54F);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-17.5, -6), width: 11.5, height: 5.5), _fillPaint);
    _strokePaint
      ..color = const Color(0xFFE6A14D)
      ..strokeWidth = 0.9;
    canvas.drawLine(const Offset(-21, -6.5), const Offset(-15, -5.5), _strokePaint);
    canvas.drawLine(const Offset(-19, -7.2), const Offset(-14, -6.5), _strokePaint);
    _fillPaint.color = const Color(0xFF795548);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-20.5, 0.5, 7, 6), const Radius.circular(2)),
      _fillPaint,
    );
    _fillPaint.color = const Color(0xFF4FC3F7);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-17.0, 1.0), width: 5.5, height: 2.5), _fillPaint);

    // Expressive spotted dairy cow standing inside the paddock
    _drawDetailedCow(canvas, time);

    // Front 2 rails + front post (in front of the cow for true 2.5D depth)
    _drawFenceSegment(canvas, left, bottom);
    _drawFenceSegment(canvas, bottom, right);
    _drawFencePost(canvas, bottom);

    canvas.restore();

    CanvasDrawHelpers.drawAnimalStatusBubble(
      canvas,
      cx,
      cy - 40,
      state,
      '🥛',
      showDetailedMeters: showDetailedMeters,
      animTime: time,
    );
  }

  void _drawFenceSegment(Canvas canvas, Offset a, Offset b) {
    _strokePaint
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 2.6;
    canvas.drawLine(a.translate(0, -4.5), b.translate(0, -4.5), _strokePaint);
    canvas.drawLine(a.translate(0, -9.5), b.translate(0, -9.5), _strokePaint);
    _strokePaint
      ..color = const Color(0xFFA16B3B)
      ..strokeWidth = 1.6;
    canvas.drawLine(a.translate(0, -10.0), b.translate(0, -10.0), _strokePaint);
  }

  void _drawFencePost(Canvas canvas, Offset p) {
    _strokePaint
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 3.8;
    canvas.drawLine(p, p.translate(0, -13), _strokePaint);
    _strokePaint
      ..color = const Color(0xFF9C724C)
      ..strokeWidth = 2.2;
    canvas.drawLine(p.translate(-0.5, 0), p.translate(-0.5, -13), _strokePaint);
    // Chamfered wooden post cap
    _fillPaint.color = const Color(0xFFD7A86E);
    canvas.drawOval(
      Rect.fromCenter(center: p.translate(0, -13.5), width: 5.2, height: 2.6),
      _fillPaint,
    );
  }

  void _drawDetailedCow(Canvas canvas, double time) {
    final sway = math.sin(time * 1.25) * 1.8;
    final graze = math.max(0.0, math.sin(time * 1.9)) * 2.2;
    final tailWag = math.sin(time * 4.5) * 2.5;

    canvas.save();
    canvas.translate(2 + sway, -3);

    // Soft ground shadow
    _fillPaint.color = const Color(0x36000000);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 4.5), width: 28, height: 11), _fillPaint);

    // Swishing tail
    _strokePaint
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 1.6;
    canvas.drawLine(const Offset(-12, -8), Offset(-16, -2 + tailWag * 0.4), _strokePaint);
    _fillPaint.color = const Color(0xFF3E2723);
    canvas.drawCircle(Offset(-16, -1.5 + tailWag * 0.4), 1.8, _fillPaint);

    // Articulated cream legs with dark hooves
    _strokePaint
      ..color = const Color(0xFFEFEBE9)
      ..strokeWidth = 3.2;
    canvas.drawLine(const Offset(-8, -3), const Offset(-8, 3.5), _strokePaint);
    canvas.drawLine(const Offset(-3, -2), const Offset(-3, 4.0), _strokePaint);
    canvas.drawLine(const Offset(5, -2), const Offset(5, 4.0), _strokePaint);
    canvas.drawLine(const Offset(9, -3), const Offset(9, 3.5), _strokePaint);
    _fillPaint.color = const Color(0xFF4E342E);
    for (final lx in const <double>[-8, -3, 5, 9]) {
      canvas.drawCircle(Offset(lx, lx == -8 || lx == 9 ? 3.8 : 4.2), 1.6, _fillPaint);
    }

    // Creamy-white shaded torso
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(-1, -8), width: 25, height: 15),
      const Radius.circular(7.5),
    );
    _fillPaint.color = const Color(0xFFFFFDF9);
    canvas.drawRRect(bodyRect, _fillPaint);
    _strokePaint
      ..color = const Color(0x666D4C41)
      ..strokeWidth = 1.1;
    canvas.drawRRect(bodyRect, _strokePaint);

    // Chocolate dairy cow patches
    _fillPaint.color = const Color(0xFF4E342E);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-6, -10), width: 7.5, height: 6.0), _fillPaint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(3, -6.5), width: 6.5, height: 5.5), _fillPaint);

    // Head, ears, tiny curved horns, eyes & rosy pink muzzle
    final hx = 12.0;
    final hy = -12.0 + graze;
    _fillPaint.color = const Color(0xFF4E342E);
    canvas.drawOval(Rect.fromCenter(center: Offset(hx - 4.5, hy - 3.5), width: 4.5, height: 3.0), _fillPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(hx + 4.5, hy - 3.5), width: 4.5, height: 3.0), _fillPaint);
    _fillPaint.color = const Color(0xFFF8BBD0);
    canvas.drawOval(Rect.fromCenter(center: Offset(hx - 4.4, hy - 3.4), width: 2.6, height: 1.5), _fillPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(hx + 4.4, hy - 3.4), width: 2.6, height: 1.5), _fillPaint);

    _fillPaint.color = const Color(0xFFFFFDF9);
    canvas.drawCircle(Offset(hx, hy), 6.2, _fillPaint);

    // Cream horns
    _fillPaint.color = const Color(0xFFFFE082);
    canvas.drawCircle(Offset(hx - 3.2, hy - 5.4), 1.8, _fillPaint);
    canvas.drawCircle(Offset(hx + 3.2, hy - 5.4), 1.8, _fillPaint);

    // Expressive eyes with warm catchlights
    _fillPaint.color = const Color(0xFF261412);
    canvas.drawCircle(Offset(hx - 2.0, hy - 1.2), 1.15, _fillPaint);
    canvas.drawCircle(Offset(hx + 2.4, hy - 1.2), 1.15, _fillPaint);
    _fillPaint.color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset(hx - 2.3, hy - 1.5), 0.42, _fillPaint);
    canvas.drawCircle(Offset(hx + 2.1, hy - 1.5), 0.42, _fillPaint);

    // Soft pink muzzle
    _fillPaint.color = const Color(0xFFF48FB1);
    canvas.drawOval(Rect.fromCenter(center: Offset(hx + 0.5, hy + 2.4), width: 8.5, height: 5.0), _fillPaint);
    _fillPaint.color = const Color(0xFFAD1457);
    canvas.drawCircle(Offset(hx - 1.2, hy + 2.2), 0.75, _fillPaint);
    canvas.drawCircle(Offset(hx + 2.2, hy + 2.2), 0.75, _fillPaint);

    canvas.restore();
  }
}
