import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';
import '../widgets/solville_dialog_shell.dart';

/// Visual quick-start loop diagram, keycap controls, and Save/New Game panel.
class HelpAndControlsModal extends StatelessWidget {
  const HelpAndControlsModal({super.key, required this.controller});

  final SolvilleController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMobile = MediaQuery.sizeOf(context).shortestSide < 600;
    final keycaps =
        (isMobile ? l10n.helpTouchControls : l10n.helpPcControls).split('  •  ');
    final steps = <(String, String)>[
      ('🪏', l10n.helpLoopStep1),
      ('🌱', l10n.helpLoopStep2),
      ('💧', l10n.helpLoopStep3),
      ('🏪', l10n.helpLoopStep4),
    ];

    return SolvilleDialogShell(
      emoji: '🌻',
      title: l10n.helpTitle,
      maxWidth: 620,
      maxHeight: 520,
      shrinkWrap: true,
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: () async {
                await controller.resetNewFarm();
                if (context.mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(l10n.helpStartFresh),
            ),
            FilledButton.icon(
              onPressed: () async {
                await controller.saveNow();
                if (context.mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.save_rounded),
              label: Text(l10n.helpSaveNow),
            ),
          ],
        ),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
        children: <Widget>[
          // Visual 4-step farm loop diagram
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SolvilleTheme.timberBorder),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                for (var i = 0; i < steps.length; i++) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: SolvilleTheme.parchment,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x44795548)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          steps[i].$1,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          steps[i].$2,
                          style: const TextStyle(
                            color: SolvilleTheme.timberDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < steps.length - 1)
                    const Text(
                      '➜',
                      style: TextStyle(
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),
          _TipBanner(
            emoji: '🍯',
            text: l10n.helpTipKettle,
            backgroundColor: const Color(0xFFE8F5E9),
          ),
          const SizedBox(height: 8),
          _TipBanner(
            emoji: '🎪',
            text: l10n.helpTipMarket,
            backgroundColor: const Color(0xFFE1F5FE),
          ),
          const SizedBox(height: 12),

          // Adaptive keycap / gesture controls strip
          Wrap(
            spacing: 7,
            runSpacing: 7,
            alignment: WrapAlignment.center,
            children: <Widget>[
              for (final cap in keycaps)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: SolvilleTheme.warmCream,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x55795548)),
                  ),
                  child: Text(
                    cap,
                    style: const TextStyle(
                      color: SolvilleTheme.timberDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TipBanner extends StatelessWidget {
  const _TipBanner({
    required this.emoji,
    required this.text,
    required this.backgroundColor,
  });

  final String emoji;
  final String text;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33795548)),
      ),
      child: Row(
        children: <Widget>[
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: SolvilleTheme.timberDark,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
