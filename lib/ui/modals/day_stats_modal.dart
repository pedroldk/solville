import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/solville_l10n_extensions.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';
import '../widgets/solville_buttons.dart';
import '../widgets/solville_dialog_shell.dart';
import '../widgets/solville_icons.dart';

/// Playful, kid-friendly End-of-Day Stats modal showing the new Day number,
/// current piggy-bank Sols, harvest totals, and a funny farm award.
class DayStatsModal extends StatelessWidget {
  const DayStatsModal({super.key, required this.controller});

  final SolvilleController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final state = controller.state;
        final completedDay = math.max(1, state.day - 1);
        final awardIndex = (completedDay - 1) % 4;
        final funnyClucks =
            3 +
            controller.lastDayCratesHarvested * 2 +
            controller.lastDayWeedsCleared +
            completedDay;

        return SolvilleDialogShell(
          emoji: '🌅',
          leadingIcon: const SolvilleIcon(
            kind: SolvilleIconKind.sunrise,
            size: 22,
          ),
          title: l10n.dayStatsTitle(state.day),
          maxWidth: 460,
          maxHeight: 540,
          shrinkWrap: true,
          footer: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
            child: SolvilleButton(
              tone: SolvilleButtonTone.emerald,
              expand: true,
              fontSize: 15.0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              label: l10n.dayStatsContinueBtn(state.day),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
            children: <Widget>[
              Text(
                l10n.dayStatsSubtitle(completedDay),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SolvilleTheme.timberDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: SolvilleTheme.cardDecoration(
                  color: const Color(0xFFFFF3C4),
                  radius: 16,
                  highlighted: true,
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      l10n.dayStatsFunnyAwardTitle(awardIndex),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: SolvilleTheme.timberDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.dayStatsFunnyAwardBody(awardIndex),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: SolvilleTheme.timberDark.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoCol = constraints.maxWidth >= 250;
                  final tileWidth = twoCol
                      ? (constraints.maxWidth - 10) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      SizedBox(
                        width: tileWidth,
                        child: _DayStatTile(
                          emoji: '☀️',
                          leading: const SolvilleIcon(
                            kind: SolvilleIconKind.sunCoin,
                            size: 20,
                          ),
                          label: l10n.dayStatsPiggyBankLabel,
                          value: '☀️ ${state.coins}',
                          badgeText: l10n.dayStatsTodayPlus(
                            controller.lastDayCoinsEarned,
                          ),
                          backgroundColor: const Color(0xFFFFF8E1),
                        ),
                      ),
                      SizedBox(
                        width: tileWidth,
                        child: _DayStatTile(
                          emoji: '🧺',
                          leading: const SolvilleIcon(
                            kind: SolvilleIconKind.barnCrate,
                            size: 20,
                          ),
                          label: l10n.dayStatsHarvestedLabel,
                          value: '${state.totalCratesHarvested}',
                          badgeText: '+${controller.lastDayCratesHarvested}',
                          backgroundColor: const Color(0xFFE8F5E9),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: SolvilleTheme.cardDecoration(
                  color: SolvilleTheme.warmCream,
                  radius: 14,
                ),
                child: Text(
                  l10n.dayStatsFunnyCounterLabel(funnyClucks),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: SolvilleTheme.timberDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayStatTile extends StatelessWidget {
  const _DayStatTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.badgeText,
    required this.backgroundColor,
    this.leading,
  });

  final String emoji;
  final Widget? leading;
  final String label;
  final String value;
  final String badgeText;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SolvilleMenuCard(
      color: backgroundColor,
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SolvilleIconMedallion(
            size: 38,
            highlighted: true,
            backgroundColor: Color.lerp(backgroundColor, Colors.white, 0.5)!,
            child: leading ?? Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: SolvilleTheme.timberDark.withValues(alpha: 0.8),
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SolvilleTheme.timberDark,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 5),
          SolvilleBadge(
            label: badgeText,
            color: SolvilleTheme.parchment,
            borderColor: const Color(0x55795548),
            fontSize: 11,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          ),
        ],
      ),
    );
  }
}
