import 'package:flutter/material.dart';

import '../theme/solville_theme.dart';

/// Tactile 3D bordered storybook pill with glossy top sheen, bevel lip, hover
/// lift, and press depression used across the Top Status Bar & Dock trays.
class SolvillePillButton extends StatefulWidget {
  const SolvillePillButton({
    super.key,
    required this.emoji,
    required this.label,
    required this.backgroundColor,
    required this.onTap,
    this.leadingIcon,
    this.tooltip,
    this.badgeEmoji,
    this.highlighted = false,
    this.isMeter = false,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.fontSize = 12.5,
    this.emojiSize = 14,
  });

  final String emoji;
  final Widget? leadingIcon;
  final String label;
  final Color backgroundColor;
  final VoidCallback onTap;
  final String? tooltip;
  final String? badgeEmoji;
  final bool highlighted;
  final bool isMeter;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final double emojiSize;

  @override
  State<SolvillePillButton> createState() => _SolvillePillButtonState();
}

class _SolvillePillButtonState extends State<SolvillePillButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final topSheen = Color.lerp(widget.backgroundColor, Colors.white, 0.56)!;
    final topColor = Color.lerp(widget.backgroundColor, Colors.white, 0.30)!;
    final lipColor = widget.highlighted
        ? const Color(0xFFA84200)
        : (widget.isMeter
              ? const Color(0x556D4C41)
              : Color.lerp(
                  widget.backgroundColor,
                  const Color(0xFF4E342E),
                  0.38,
                )!);

    final maxLip = widget.isMeter ? 1.2 : 2.2;
    final currentLip = _pressed ? 0.8 : maxLip;
    final topPad = _pressed ? (maxLip - 0.8) : 0.0;
    final hoverOffset = (!widget.isMeter && _hovered && !_pressed) ? -0.6 : 0.0;

    final decoration = widget.isMeter
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const <double>[0.0, 0.25, 1.0],
              colors: <Color>[
                Color.lerp(
                  widget.backgroundColor,
                  const Color(0xFFD2B48C),
                  0.22,
                )!,
                widget.backgroundColor,
                Color.lerp(widget.backgroundColor, Colors.white, 0.24)!,
              ],
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.highlighted
                  ? const Color(0xFFE65100)
                  : const Color(0x886D4C41),
              width: widget.highlighted ? 1.8 : 1.3,
            ),
            boxShadow: <BoxShadow>[
              if (widget.highlighted)
                const BoxShadow(
                  color: Color(0x66FFCA28),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
            ],
          )
        : BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const <double>[0.0, 0.16, 0.26, 1.0],
              colors: <Color>[
                topSheen,
                topColor,
                Color.lerp(topColor, widget.backgroundColor, 0.30)!,
                widget.backgroundColor,
              ],
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.highlighted
                  ? const Color(0xFFE65100)
                  : const Color(0x996D442B),
              width: widget.highlighted ? 1.9 : 1.4,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: lipColor,
                offset: Offset(0, currentLip),
                blurRadius: 0,
              ),
              if (widget.highlighted)
                const BoxShadow(
                  color: Color(0x66FFCA28),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              else if (_hovered && !_pressed)
                const BoxShadow(
                  color: Color(0x33FFCA28),
                  offset: Offset(0, 2.5),
                  blurRadius: 6,
                )
              else
                const BoxShadow(
                  color: Color(0x183E2723),
                  offset: Offset(0, 2.5),
                  blurRadius: 3,
                ),
            ],
          );

    final button = Semantics(
      button: true,
      label: widget.tooltip ?? widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: Transform.translate(
            offset: Offset(0, hoverOffset),
            child: Padding(
              padding: EdgeInsets.only(top: topPad, bottom: currentLip),
              child: Container(
                padding: widget.padding,
                decoration: decoration,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (widget.leadingIcon != null || widget.emoji.isNotEmpty)
                      widget.leadingIcon ??
                          Text(
                            widget.emoji,
                            style: TextStyle(fontSize: widget.emojiSize),
                          ),
                    if (widget.label.isNotEmpty) ...<Widget>[
                      if (widget.leadingIcon != null || widget.emoji.isNotEmpty)
                        const SizedBox(width: 4),
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: SolvilleTheme.timberDark,
                          fontWeight: FontWeight.w800,
                          fontSize: widget.fontSize,
                        ),
                      ),
                    ],
                    if (widget.badgeEmoji != null &&
                        widget.badgeEmoji!.isNotEmpty) ...<Widget>[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Color(0xFFFFF176),
                              Color(0xFFFFB300),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0x888C5320),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          widget.badgeEmoji!,
                          style: TextStyle(
                            fontSize: (widget.emojiSize - 1).clamp(10, 14),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}
