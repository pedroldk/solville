import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';
import '../widgets/solville_buttons.dart';
import '../widgets/solville_dialog_shell.dart';
import '../widgets/solville_icons.dart';

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
    final steps = <(SolvilleIconKind, String)>[
      (SolvilleIconKind.trowel, l10n.helpLoopStep1),
      (SolvilleIconKind.seeds, l10n.helpLoopStep2),
      (SolvilleIconKind.waterCan, l10n.helpLoopStep3),
      (SolvilleIconKind.marketStall, l10n.helpLoopStep4),
    ];

    return SolvilleDialogShell(
      emoji: '🌻',
      leadingIcon: const SolvilleIcon(
        kind: SolvilleIconKind.helpBook,
        size: 22,
      ),
      title: l10n.helpTitle,
      maxWidth: 620,
      maxHeight: 520,
      shrinkWrap: true,
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: <Widget>[
            SolvilleButton(
              tone: SolvilleButtonTone.cream,
              compact: true,
              icon: Icons.school_rounded,
              label: l10n.helpReplayTutorial,
              onPressed: () async {
                await controller.replayTutorial();
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            SolvilleButton(
              tone: SolvilleButtonTone.coral,
              compact: true,
              icon: Icons.restart_alt_rounded,
              label: l10n.helpStartFresh,
              onPressed: () async {
                await controller.resetNewFarm();
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            SolvilleButton(
              tone: SolvilleButtonTone.emerald,
              compact: true,
              icon: Icons.save_rounded,
              label: l10n.helpSaveNow,
              onPressed: () async {
                await controller.saveNow();
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        children: <Widget>[
          // Visual 4-step farm loop diagram
          SolvilleMenuCard(
            color: const Color(0xFFFFF8E1),
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Wrap(
              spacing: 6,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                for (var i = 0; i < steps.length; i++) ...<Widget>[
                  SolvilleMenuCard(
                    color: SolvilleTheme.parchment,
                    radius: 12,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SolvilleIconMedallion(
                          size: 32,
                          child: SolvilleIcon(kind: steps[i].$1, size: 18),
                        ),
                        const SizedBox(height: 4),
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
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF6EAD0)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0x886D4C41),
                      width: 1.3,
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0xFFB8A98E),
                        offset: Offset(0, 2.5),
                        blurRadius: 0,
                      ),
                    ],
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
    return SolvilleMenuCard(
      color: backgroundColor,
      radius: 13,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: <Widget>[
          SolvilleIconMedallion(
            size: 32,
            backgroundColor: Color.lerp(backgroundColor, Colors.white, 0.5)!,
            child: Text(emoji, style: const TextStyle(fontSize: 17)),
          ),
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
