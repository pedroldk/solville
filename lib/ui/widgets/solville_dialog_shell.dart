import 'package:flutter/material.dart';

import '../theme/solville_theme.dart';
import 'solville_buttons.dart';

/// Shared carved-cedar & sunlit parchment dialog frame used across all Solville modals.
class SolvilleDialogShell extends StatelessWidget {
  const SolvilleDialogShell({
    super.key,
    required this.emoji,
    required this.title,
    required this.child,
    this.leadingIcon,
    this.trailing,
    this.footer,
    this.maxWidth = 660,
    this.maxHeight = 560,
    this.shrinkWrap = false,
  });

  final String emoji;
  final String title;
  final Widget? leadingIcon;
  final Widget? trailing;
  final Widget child;
  final Widget? footer;
  final double maxWidth;
  final double maxHeight;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isCompact = screenSize.shortestSide < 600;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 16,
        vertical: isCompact ? 8 : 16,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        builder: (context, t, dialogChild) {
          final opacity = t.clamp(0.0, 1.0);
          final scale = 0.93 + 0.07 * t;
          return Opacity(
            opacity: opacity,
            child: Transform.scale(scale: scale, child: dialogChild),
          );
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: Container(
            padding: EdgeInsets.all(isCompact ? 3.5 : 5.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFF9C6846),
                  Color(0xFF7A4E32),
                  Color(0xFF5E3922),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: SolvilleTheme.cedarDark, width: 2.0),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0xFF3B2113),
                  offset: Offset(0, 4.5),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: Color(0x551A0D07),
                  offset: Offset(0, 12),
                  blurRadius: 24,
                ),
              ],
            ),
            child: CustomPaint(
              foregroundPainter: const _StorybookCornerFiligreePainter(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0xFAFFFDF8), Color(0xF5FFF4DE)],
                  ),
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: const Color(0xFFD7B46A),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    mainAxisSize:
                        shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
                    children: <Widget>[
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Color(0xFFFFF5D9),
                              Color(0xFFFFFDF6),
                            ],
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(19),
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          isCompact ? 12 : 18,
                          isCompact ? 9 : 12,
                          isCompact ? 10 : 12,
                          8,
                        ),
                        child: Row(
                          children: <Widget>[
                            SolvilleIconMedallion(
                              size: isCompact ? 36 : 40,
                              highlighted: true,
                              child:
                                  leadingIcon ??
                                  Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 21),
                                  ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: SolvilleTheme.timberDark,
                                  fontSize: isCompact ? 17 : 19,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (trailing != null) ...<Widget>[
                              const SizedBox(width: 6),
                              Flexible(fit: FlexFit.loose, child: trailing!),
                              const SizedBox(width: 6),
                            ],
                            SolvilleIconButton(
                              tone: SolvilleButtonTone.coral,
                              icon: Icons.close_rounded,
                              borderRadius: isCompact ? 16 : 18,
                              size: isCompact ? 32 : 36,
                              iconSize: isCompact ? 17 : 19,
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).closeButtonTooltip,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 1.2, color: const Color(0x78FFD54F)),
                      Container(height: 1.2, color: const Color(0x366D4C41)),
                      if (shrinkWrap)
                        Flexible(child: child)
                      else
                        Expanded(child: child),
                      if (footer != null)
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xAAFFF5DC),
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(19),
                            ),
                            border: Border(
                              top: BorderSide(
                                color: Color(0x2E795548),
                                width: 1.2,
                              ),
                            ),
                          ),
                          child: footer!,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StorybookCornerFiligreePainter extends CustomPainter {
  const _StorybookCornerFiligreePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bracket = Paint()
      ..color = const Color(0x99FFE082)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    const r = 18.0;
    const inset = 5.0;
    // Top-left & bottom-left subtle golden filigree corner arcs
    canvas.drawArc(
      const Rect.fromLTWH(inset, inset, r * 2, r * 2),
      3.14159,
      1.5708,
      false,
      bracket,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width - inset - r * 2, inset, r * 2, r * 2),
      -1.5708,
      1.5708,
      false,
      bracket,
    );
    canvas.drawArc(
      Rect.fromLTWH(inset, size.height - inset - r * 2, r * 2, r * 2),
      1.5708,
      1.5708,
      false,
      bracket,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width - inset - r * 2,
        size.height - inset - r * 2,
        r * 2,
        r * 2,
      ),
      0.0,
      1.5708,
      false,
      bracket,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
