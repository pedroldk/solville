import 'package:flutter/material.dart';

import '../theme/solville_theme.dart';

/// Tactile bordered pill button with leading emoji and bold timber label used
/// across the Top Status Bar and Bottom Tool Dock.
class SolvillePillButton extends StatelessWidget {
  const SolvillePillButton({
    super.key,
    required this.emoji,
    required this.label,
    required this.backgroundColor,
    required this.onTap,
    this.tooltip,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.fontSize = 12.5,
    this.emojiSize = 14,
  });

  final String emoji;
  final String label;
  final Color backgroundColor;
  final VoidCallback onTap;
  final String? tooltip;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final double emojiSize;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: SolvilleTheme.timberBorder, width: 1.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(emoji, style: TextStyle(fontSize: emojiSize)),
              if (label.isNotEmpty) ...<Widget>[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: SolvilleTheme.timberDark,
                    fontWeight: FontWeight.w800,
                    fontSize: fontSize,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
