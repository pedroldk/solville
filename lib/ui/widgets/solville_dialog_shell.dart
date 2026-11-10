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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
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
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                  child: Row(
                    children: <Widget>[
                      Text(emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: SolvilleTheme.timberDark,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (trailing != null) ...<Widget>[
                        trailing!,
                        const SizedBox(width: 6),
                      ],
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
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
    );
  }
}
