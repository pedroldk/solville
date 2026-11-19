import 'dart:math' as math;

import 'package:flutter/material.dart';

enum SolvilleIconKind {
  sunCoin,
  waterCan,
  smartHand,
  trowel,
  seeds,
  hammer,
  shopBasket,
  marketChart,
  trophy,
  musicLullaby,
  musicMeadow,
  musicRain,
  musicOff,
  crown,
  sweepBrush,
  leafUntill,
  sparkleCompost,
  farmhouse,
  marketStall,
  sunrise,
  barnCrate,
  padlock,
  helpBook,
}

/// Crisp custom-drawn storybook vector icon replacing inconsistent OS emojis
/// (especially missing tool glyphs) across Windows, Android, and Web HUDs.
class SolvilleIcon extends StatelessWidget {
  const SolvilleIcon({
    super.key,
    required this.kind,
    this.size = 18.0,
  });

  final SolvilleIconKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _SolvilleIconPainter(kind)),
    );
  }
}

class _SolvilleIconPainter extends CustomPainter {
  const _SolvilleIconPainter(this.kind);

  final SolvilleIconKind kind;

  static const Color _ink = Color(0xFF4E342E);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    final c = Offset(size.width * 0.5, size.height * 0.5);
    final fill = Paint()..isAntiAlias = true;
    final stroke = Paint()
      ..isAntiAlias = true
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = (s * 0.085).clamp(1.1, 2.0);

    switch (kind) {
      case SolvilleIconKind.sunCoin:
        // Radiating sun-coin rim + warm golden medallion
        fill.color = const Color(0xFFFFB300);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi * 0.25;
          canvas.drawCircle(
            Offset(c.dx + math.cos(a) * s * 0.36, c.dy + math.sin(a) * s * 0.36),
            s * 0.09,
            fill,
          );
        }
        fill.color = const Color(0xFFFFD54F);
        canvas.drawCircle(c, s * 0.33, fill);
        canvas.drawCircle(c, s * 0.33, stroke);
        fill.color = const Color(0xFFFFF59D);
        canvas.drawCircle(c.translate(-s * 0.07, -s * 0.07), s * 0.14, fill);

      case SolvilleIconKind.waterCan:
        // Cozy sky-blue watering can with arched handle & spout
        final handleStroke = Paint()
          ..isAntiAlias = true
          ..color = const Color(0xFF0277BD)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = s * 0.10;
        canvas.drawArc(
          Rect.fromCenter(center: c.translate(-s * 0.02, -s * 0.08), width: s * 0.52, height: s * 0.46),
          math.pi,
          math.pi * 0.85,
          false,
          handleStroke,
        );
        // Spout
        final spout = Path()
          ..moveTo(c.dx + s * 0.10, c.dy + s * 0.10)
          ..lineTo(c.dx + s * 0.40, c.dy - s * 0.14)
          ..lineTo(c.dx + s * 0.35, c.dy - s * 0.22)
          ..lineTo(c.dx + s * 0.08, c.dy - s * 0.02)
          ..close();
        fill.color = const Color(0xFF29B6F6);
        canvas.drawPath(spout, fill);
        canvas.drawPath(spout, stroke);
        // Body
        final body = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c.translate(-s * 0.04, s * 0.10), width: s * 0.44, height: s * 0.40),
          Radius.circular(s * 0.09),
        );
        fill.color = const Color(0xFF29B6F6);
        canvas.drawRRect(body, fill);
        canvas.drawRRect(body, stroke);
        fill.color = const Color(0x99E1F5FE);
        canvas.drawCircle(c.translate(-s * 0.10, s * 0.04), s * 0.07, fill);

      case SolvilleIconKind.smartHand:
        // Warm golden magic-tap star wand / cozy mitten hand
        final palm = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c.translate(0, s * 0.08), width: s * 0.46, height: s * 0.44),
          Radius.circular(s * 0.16),
        );
        fill.color = const Color(0xFFFFD54F);
        canvas.drawRRect(palm, fill);
        canvas.drawRRect(palm, stroke);
        // Index finger pointing up
        final finger = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c.translate(-s * 0.05, -s * 0.20), width: s * 0.18, height: s * 0.34),
          Radius.circular(s * 0.09),
        );
        canvas.drawRRect(finger, fill);
        canvas.drawRRect(finger, stroke);
        // Tap glint dot
        fill.color = const Color(0xFFFF6F00);
        canvas.drawCircle(c.translate(s * 0.22, -s * 0.24), s * 0.08, fill);

      case SolvilleIconKind.trowel:
        // Wooden handle + polished steel garden spade blade
        final handlePaint = Paint()
          ..isAntiAlias = true
          ..color = const Color(0xFF8D6E63)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = s * 0.16;
        canvas.drawLine(
          Offset(c.dx - s * 0.28, c.dy + s * 0.28),
          Offset(c.dx - s * 0.02, c.dy + s * 0.02),
          handlePaint,
        );
        canvas.drawLine(
          Offset(c.dx - s * 0.28, c.dy + s * 0.28),
          Offset(c.dx - s * 0.02, c.dy + s * 0.02),
          stroke,
        );
        final blade = Path()
          ..moveTo(c.dx - s * 0.06, c.dy - s * 0.08)
          ..lineTo(c.dx + s * 0.34, c.dy - s * 0.34)
          ..lineTo(c.dx + s * 0.08, c.dy + s * 0.06)
          ..lineTo(c.dx - s * 0.04, c.dy + s * 0.04)
          ..close();
        fill.color = const Color(0xFFB0BEC5);
        canvas.drawPath(blade, fill);
        canvas.drawPath(blade, stroke);

      case SolvilleIconKind.seeds:
        // Twin bright sprout leaves emerging from warm soil dot
        fill.color = const Color(0xFF795548);
        canvas.drawOval(Rect.fromCenter(center: c.translate(0, s * 0.28), width: s * 0.56, height: s * 0.18), fill);
        stroke.color = const Color(0xFF2E7D32);
        canvas.drawLine(c.translate(0, s * 0.24), c.translate(0, -s * 0.04), stroke);
        fill.color = const Color(0xFF66BB6A);
        canvas.save();
        canvas.translate(c.dx - s * 0.16, c.dy - s * 0.08);
        canvas.rotate(-0.45);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 0.34, height: s * 0.20), fill);
        canvas.restore();
        canvas.save();
        canvas.translate(c.dx + s * 0.16, c.dy - s * 0.14);
        canvas.rotate(0.45);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 0.34, height: s * 0.20), fill);
        canvas.restore();

      case SolvilleIconKind.hammer:
        // Carpenter's wooden-handled build hammer
        final handle = Paint()
          ..isAntiAlias = true
          ..color = const Color(0xFFA16B3B)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = s * 0.14;
        canvas.drawLine(
          Offset(c.dx - s * 0.26, c.dy + s * 0.26),
          Offset(c.dx + s * 0.14, c.dy - s * 0.14),
          handle,
        );
        canvas.save();
        canvas.translate(c.dx + s * 0.14, c.dy - s * 0.16);
        canvas.rotate(-0.78);
        final head = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: s * 0.48, height: s * 0.22),
          Radius.circular(s * 0.05),
        );
        fill.color = const Color(0xFF78909C);
        canvas.drawRRect(head, fill);
        canvas.drawRRect(head, stroke);
        canvas.restore();

      case SolvilleIconKind.shopBasket:
        // Cozy woven wooden market basket with red awning handle
        final basket = Path()
          ..moveTo(c.dx - s * 0.34, c.dy - s * 0.02)
          ..lineTo(c.dx + s * 0.34, c.dy - s * 0.02)
          ..lineTo(c.dx + s * 0.25, c.dy + s * 0.32)
          ..lineTo(c.dx - s * 0.25, c.dy + s * 0.32)
          ..close();
        fill.color = const Color(0xFFD7995B);
        canvas.drawPath(basket, fill);
        canvas.drawPath(basket, stroke);
        canvas.drawArc(
          Rect.fromCenter(center: c.translate(0, -s * 0.04), width: s * 0.48, height: s * 0.48),
          math.pi,
          math.pi,
          false,
          stroke,
        );
        fill.color = const Color(0xFFE53935);
        canvas.drawCircle(c.translate(-s * 0.10, -s * 0.05), s * 0.10, fill);
        fill.color = const Color(0xFF66BB6A);
        canvas.drawCircle(c.translate(s * 0.10, -s * 0.05), s * 0.10, fill);

      case SolvilleIconKind.marketChart:
        // Rising emerald price trend arrow over mini stall bars
        fill.color = const Color(0xFFFFB300);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(c.dx - s * 0.32, c.dy + s * 0.08, s * 0.14, s * 0.22), const Radius.circular(1.5)),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(c.dx - s * 0.08, c.dy - s * 0.02, s * 0.14, s * 0.32), const Radius.circular(1.5)),
          fill,
        );
        fill.color = const Color(0xFF43A047);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(c.dx + s * 0.16, c.dy - s * 0.16, s * 0.14, s * 0.46), const Radius.circular(1.5)),
          fill,
        );
        final trend = Path()
          ..moveTo(c.dx - s * 0.32, c.dy - s * 0.04)
          ..lineTo(c.dx - s * 0.04, c.dy - s * 0.18)
          ..lineTo(c.dx + s * 0.28, c.dy - s * 0.32);
        stroke.color = const Color(0xFFE65100);
        canvas.drawPath(trend, stroke);

      case SolvilleIconKind.trophy:
        // Golden winner's cup
        fill.color = const Color(0xFFFFCA28);
        final cup = Path()
          ..moveTo(c.dx - s * 0.28, c.dy - s * 0.30)
          ..lineTo(c.dx + s * 0.28, c.dy - s * 0.30)
          ..quadraticBezierTo(c.dx + s * 0.24, c.dy + s * 0.08, c.dx, c.dy + s * 0.12)
          ..quadraticBezierTo(c.dx - s * 0.24, c.dy + s * 0.08, c.dx - s * 0.28, c.dy - s * 0.30)
          ..close();
        canvas.drawPath(cup, fill);
        canvas.drawPath(cup, stroke);
        canvas.drawLine(c.translate(0, s * 0.12), c.translate(0, s * 0.28), stroke);
        canvas.drawLine(c.translate(-s * 0.18, s * 0.30), c.translate(s * 0.18, s * 0.30), stroke);

      case SolvilleIconKind.musicLullaby:
        // Warm acoustic note
        fill.color = const Color(0xFFE65100);
        canvas.drawCircle(c.translate(-s * 0.14, s * 0.20), s * 0.13, fill);
        canvas.drawCircle(c.translate(s * 0.16, s * 0.12), s * 0.13, fill);
        stroke.color = const Color(0xFFE65100);
        canvas.drawLine(c.translate(-s * 0.04, s * 0.18), c.translate(-s * 0.04, -s * 0.24), stroke);
        canvas.drawLine(c.translate(s * 0.26, s * 0.10), c.translate(s * 0.26, -s * 0.30), stroke);
        canvas.drawLine(c.translate(-s * 0.04, -s * 0.24), c.translate(s * 0.26, -s * 0.30), stroke);

      case SolvilleIconKind.musicMeadow:
        // Cheerful songbird silhouette
        fill.color = const Color(0xFF0288D1);
        canvas.drawOval(Rect.fromCenter(center: c.translate(-s * 0.04, s * 0.04), width: s * 0.52, height: s * 0.38), fill);
        canvas.drawCircle(c.translate(s * 0.16, -s * 0.12), s * 0.16, fill);
        fill.color = const Color(0xFFFFB300);
        canvas.drawCircle(c.translate(s * 0.34, -s * 0.12), s * 0.07, fill);

      case SolvilleIconKind.musicRain:
        // Cozy sky cloud with gentle raindrops
        fill.color = const Color(0xFF90A4AE);
        canvas.drawOval(Rect.fromCenter(center: c.translate(0, -s * 0.08), width: s * 0.68, height: s * 0.34), fill);
        canvas.drawCircle(c.translate(-s * 0.10, -s * 0.18), s * 0.18, fill);
        canvas.drawCircle(c.translate(s * 0.10, -s * 0.16), s * 0.15, fill);
        stroke.color = const Color(0xFF0288D1);
        canvas.drawLine(c.translate(-s * 0.16, s * 0.14), c.translate(-s * 0.22, s * 0.30), stroke);
        canvas.drawLine(c.translate(0, s * 0.14), c.translate(-s * 0.06, s * 0.30), stroke);
        canvas.drawLine(c.translate(s * 0.16, s * 0.14), c.translate(s * 0.10, s * 0.30), stroke);

      case SolvilleIconKind.musicOff:
        fill.color = const Color(0xFF8D6E63);
        canvas.drawCircle(c.translate(-s * 0.08, s * 0.16), s * 0.13, fill);
        stroke.color = const Color(0xFF8D6E63);
        canvas.drawLine(c.translate(s * 0.02, s * 0.14), c.translate(s * 0.02, -s * 0.24), stroke);
        stroke.color = const Color(0xFFD32F2F);
        canvas.drawLine(c.translate(-s * 0.28, -s * 0.28), c.translate(s * 0.28, s * 0.28), stroke);

      case SolvilleIconKind.crown:
        final crown = Path()
          ..moveTo(c.dx - s * 0.34, c.dy + s * 0.22)
          ..lineTo(c.dx - s * 0.36, c.dy - s * 0.16)
          ..lineTo(c.dx - s * 0.14, c.dy + s * 0.02)
          ..lineTo(c.dx, c.dy - s * 0.26)
          ..lineTo(c.dx + s * 0.14, c.dy + s * 0.02)
          ..lineTo(c.dx + s * 0.36, c.dy - s * 0.16)
          ..lineTo(c.dx + s * 0.34, c.dy + s * 0.22)
          ..close();
        fill.color = const Color(0xFFFFCA28);
        canvas.drawPath(crown, fill);
        canvas.drawPath(crown, stroke);

      case SolvilleIconKind.sweepBrush:
        // Curved paint-sweep flourish ribbon + brush tip
        stroke
          ..color = const Color(0xFFE65100)
          ..strokeWidth = s * 0.12;
        final curve = Path()
          ..moveTo(c.dx - s * 0.30, c.dy + s * 0.22)
          ..quadraticBezierTo(c.dx - s * 0.04, c.dy - s * 0.28, c.dx + s * 0.30, c.dy - s * 0.08);
        canvas.drawPath(curve, stroke);
        fill.color = const Color(0xFFFFB300);
        canvas.drawCircle(c.translate(s * 0.28, -s * 0.08), s * 0.11, fill);

      case SolvilleIconKind.leafUntill:
        fill.color = const Color(0xFF43A047);
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(-0.5);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 0.64, height: s * 0.38), fill);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 0.64, height: s * 0.38), stroke);
        canvas.restore();

      case SolvilleIconKind.sparkleCompost:
        fill.color = const Color(0xFFFFB300);
        final star = Path();
        for (var i = 0; i < 8; i++) {
          final r = i.isEven ? s * 0.40 : s * 0.13;
          final a = i * math.pi * 0.25;
          final px = c.dx + math.cos(a) * r;
          final py = c.dy + math.sin(a) * r;
          if (i == 0) {
            star.moveTo(px, py);
          } else {
            star.lineTo(px, py);
          }
        }
        star.close();
        canvas.drawPath(star, fill);
        canvas.drawPath(star, stroke);

      case SolvilleIconKind.farmhouse:
        // Cream cottage walls + pitched terracotta roof + warm glowing window
        final wallRect = Rect.fromCenter(
          center: c.translate(0, s * 0.14),
          width: s * 0.56,
          height: s * 0.36,
        );
        fill.color = const Color(0xFFFFF5DC);
        canvas.drawRRect(
          RRect.fromRectAndRadius(wallRect, Radius.circular(s * 0.06)),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(wallRect, Radius.circular(s * 0.06)),
          stroke,
        );
        // Chimney
        fill.color = const Color(0xFFD84315);
        canvas.drawRect(
          Rect.fromLTWH(c.dx + s * 0.12, c.dy - s * 0.32, s * 0.10, s * 0.18),
          fill,
        );
        // Terracotta roof
        final roof = Path()
          ..moveTo(c.dx - s * 0.38, c.dy - s * 0.02)
          ..lineTo(c.dx, c.dy - s * 0.34)
          ..lineTo(c.dx + s * 0.38, c.dy - s * 0.02)
          ..close();
        fill.color = const Color(0xFFE65100);
        canvas.drawPath(roof, fill);
        canvas.drawPath(roof, stroke);
        // Arched wooden door + sunny window
        fill.color = const Color(0xFF6D4C41);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(c.dx - s * 0.16, c.dy + s * 0.08, s * 0.15, s * 0.24),
            topLeft: Radius.circular(s * 0.07),
            topRight: Radius.circular(s * 0.07),
          ),
          fill,
        );
        fill.color = const Color(0xFFFFE082);
        canvas.drawCircle(c.translate(s * 0.14, s * 0.15), s * 0.085, fill);
        canvas.drawCircle(c.translate(s * 0.14, s * 0.15), s * 0.085, stroke);

      case SolvilleIconKind.marketStall:
        // Striped terracotta-cream canopy + timber stall counter
        fill.color = const Color(0xFF8D6E63);
        final counter = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c.translate(0, s * 0.18), width: s * 0.62, height: s * 0.24),
          Radius.circular(s * 0.06),
        );
        canvas.drawRRect(counter, fill);
        canvas.drawRRect(counter, stroke);
        canvas.drawLine(c.translate(-s * 0.24, s * 0.06), c.translate(-s * 0.24, -s * 0.12), stroke);
        canvas.drawLine(c.translate(s * 0.24, s * 0.06), c.translate(s * 0.24, -s * 0.12), stroke);
        final awning = Path()
          ..moveTo(c.dx - s * 0.38, c.dy - s * 0.06)
          ..lineTo(c.dx - s * 0.28, c.dy - s * 0.30)
          ..lineTo(c.dx + s * 0.28, c.dy - s * 0.30)
          ..lineTo(c.dx + s * 0.38, c.dy - s * 0.06)
          ..close();
        fill.color = const Color(0xFFE53935);
        canvas.drawPath(awning, fill);
        fill.color = const Color(0xFFFFF8E1);
        canvas.drawRect(
          Rect.fromCenter(center: c.translate(0, -s * 0.18), width: s * 0.20, height: s * 0.22),
          fill,
        );
        canvas.drawPath(awning, stroke);

      case SolvilleIconKind.sunrise:
        // Warm golden horizon sun rising above rolling meadow hills
        fill.color = const Color(0xFFFFD54F);
        canvas.drawArc(
          Rect.fromCenter(center: c.translate(0, s * 0.08), width: s * 0.44, height: s * 0.44),
          math.pi,
          math.pi,
          true,
          fill,
        );
        stroke.color = const Color(0xFFFFB300);
        for (var i = 0; i < 5; i++) {
          final a = math.pi + (i + 0.5) * (math.pi / 5.0);
          canvas.drawLine(
            Offset(c.dx + math.cos(a) * s * 0.27, c.dy + s * 0.08 + math.sin(a) * s * 0.27),
            Offset(c.dx + math.cos(a) * s * 0.38, c.dy + s * 0.08 + math.sin(a) * s * 0.38),
            stroke,
          );
        }
        stroke.color = _ink;
        final hill = Path()
          ..moveTo(c.dx - s * 0.40, c.dy + s * 0.26)
          ..quadraticBezierTo(c.dx - s * 0.12, c.dy + s * 0.02, c.dx + s * 0.12, c.dy + s * 0.14)
          ..quadraticBezierTo(c.dx + s * 0.28, c.dy + s * 0.08, c.dx + s * 0.40, c.dy + s * 0.26)
          ..close();
        fill.color = const Color(0xFF43A047);
        canvas.drawPath(hill, fill);
        canvas.drawPath(hill, stroke);

      case SolvilleIconKind.barnCrate:
        // Sturdy timber crate with diagonal crossbar
        final crate = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: s * 0.62, height: s * 0.62),
          Radius.circular(s * 0.09),
        );
        fill.color = const Color(0xFFD7A86E);
        canvas.drawRRect(crate, fill);
        canvas.drawRRect(crate, stroke);
        canvas.drawLine(c.translate(-s * 0.24, -s * 0.24), c.translate(s * 0.24, s * 0.24), stroke);
        canvas.drawLine(c.translate(-s * 0.24, s * 0.12), c.translate(s * 0.24, s * 0.12), stroke);

      case SolvilleIconKind.padlock:
        // Cozy steel-and-brass padlock for locked milestones
        stroke
          ..color = const Color(0xFF78909C)
          ..strokeWidth = s * 0.10;
        canvas.drawArc(
          Rect.fromCenter(center: c.translate(0, -s * 0.12), width: s * 0.34, height: s * 0.34),
          math.pi,
          math.pi,
          false,
          stroke,
        );
        stroke
          ..color = _ink
          ..strokeWidth = (s * 0.085).clamp(1.1, 2.0);
        final lockBody = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c.translate(0, s * 0.13), width: s * 0.52, height: s * 0.42),
          Radius.circular(s * 0.10),
        );
        fill.color = const Color(0xFFB0BEC5);
        canvas.drawRRect(lockBody, fill);
        canvas.drawRRect(lockBody, stroke);
        fill.color = const Color(0xFFFFB300);
        canvas.drawCircle(c.translate(0, s * 0.11), s * 0.075, fill);

      case SolvilleIconKind.helpBook:
        // Open illustrated storybook with terracotta cover & ribbon bookmark
        final cover = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c.translate(0, s * 0.04), width: s * 0.72, height: s * 0.54),
          Radius.circular(s * 0.08),
        );
        fill.color = const Color(0xFFD84315);
        canvas.drawRRect(cover, fill);
        canvas.drawRRect(cover, stroke);
        fill.color = const Color(0xFFFFFDF7);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: c.translate(-s * 0.15, s * 0.02), width: s * 0.30, height: s * 0.44),
            Radius.circular(s * 0.04),
          ),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: c.translate(s * 0.15, s * 0.02), width: s * 0.30, height: s * 0.44),
            Radius.circular(s * 0.04),
          ),
          fill,
        );
        canvas.drawLine(c.translate(0, -s * 0.20), c.translate(0, s * 0.25), stroke);
        fill.color = const Color(0xFF43A047);
        canvas.drawRect(
          Rect.fromLTWH(c.dx + s * 0.08, c.dy - s * 0.22, s * 0.09, s * 0.22),
          fill,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _SolvilleIconPainter oldDelegate) =>
      oldDelegate.kind != kind;
}
