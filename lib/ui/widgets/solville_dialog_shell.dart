import 'package:flutter/material.dart';

import '../theme/solville_theme.dart';

/// Shared parchment dialog container and header bar used across all Solville modals.
class SolvilleDialogShell extends StatelessWidget {
  const SolvilleDialogShell({
    super.key,
    required this.emoji,
    required this.title,
    required this.child,
    this.trailing,
    this.footer,
    this.maxWidth = 660,
    this.maxHeight = 560,
    this.shrinkWrap = false,
  });

  final String emoji;
  final String title;
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
            decoration: SolvilleTheme.panelDecoration(
              color: SolvilleTheme.parchment,
              radius: 24,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 14 : 20,
                      isCompact ? 10 : 14,
                      8,
                      6,
                    ),
                    child: Row(
                      children: <Widget>[
                        Text(emoji, style: const TextStyle(fontSize: 24)),
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
                          const SizedBox(width: 4),
                        ],
                        IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 1.2,
                    thickness: 1.2,
                    color: Color(0x28795548),
                  ),
                  if (shrinkWrap)
                    Flexible(child: child)
                  else
                    Expanded(child: child),
                  ?footer,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
