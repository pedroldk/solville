import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/entitlement_state.dart';
import '../../l10n/app_localizations.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';
import '../widgets/solville_buttons.dart';
import '../widgets/solville_dialog_shell.dart';
import '../widgets/solville_icons.dart';

/// Cozy "Solville Cozy Version" dialog allowing players to unlock the
/// Full Game forever with a one-time purchase or restore store purchases.
class SunPassModal extends StatelessWidget {
  const SunPassModal({super.key, required this.controller});

  final SolvilleController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final ent = controller.entitlements;
        final isActive = controller.isSunPassActive;
        final busy = controller.isMonetizationBusy;

        return SolvilleDialogShell(
          emoji: '☀️',
          leadingIcon: const SolvilleIcon(
            kind: SolvilleIconKind.sunCoin,
            size: 22,
          ),
          title: l10n.sunPassTitle,
          maxWidth: 680,
          maxHeight: 620,
          trailing: SolvilleBadge(
            label: isActive ? l10n.sunPassBadgeActive : l10n.sunPassBadgeStarter,
            color: isActive ? const Color(0xFFFFF3C4) : const Color(0xFFF3EFE6),
            borderColor: isActive
                ? SolvilleTheme.sunGold
                : SolvilleTheme.timberBorder,
            fontSize: 12.5,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Status Banner
                _StatusBanner(entitlements: ent),

                const SizedBox(height: 12),

                // What's Included visual perk grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: SolvilleTheme.cardDecoration(
                    color: SolvilleTheme.warmCream,
                    radius: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        l10n.sunPassIncludedHeading,
                        style: const TextStyle(
                          color: SolvilleTheme.timberDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final twoCol = constraints.maxWidth >= 320;
                          final tileW = twoCol
                              ? (constraints.maxWidth - 8) / 2
                              : constraints.maxWidth;
                          final perks = <(String, String, Color)>[
                            (
                              '🌽 🪻 🎃',
                              l10n.sunPassPerkCrops,
                              const Color(0xFFFFF8E1),
                            ),
                            (
                              '🍋 🍯 🐝 🐄',
                              l10n.sunPassPerkArtisan,
                              const Color(0xFFE8F5E9),
                            ),
                            (
                              '🏝️ 35×35',
                              l10n.sunPassPerkIsle,
                              const Color(0xFFE1F5FE),
                            ),
                            (
                              '💚 ♾️',
                              l10n.sunPassPerkCozy,
                              const Color(0xFFFCE4EC),
                            ),
                          ];
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              for (final (icons, label, bg) in perks)
                                Container(
                                  width: tileW,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0x33795548),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        icons,
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        label,
                                        style: const TextStyle(
                                          color: SolvilleTheme.timberDark,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // One-Time Full Game Unlock
                _OfferCard(
                  emoji: '👑',
                  title: l10n.sunPassLifetimeTitle,
                  badgeText: l10n.sunPassLifetimeBadge,
                  badgeColor: const Color(0xFFF8BBD0),
                  backgroundColor: const Color(0xFFFFF8F9),
                  description: l10n.sunPassLifetimeDesc,
                  trailing: SolvilleButton(
                    tone: ent.isPermanentSupporter
                        ? SolvilleButtonTone.emerald
                        : SolvilleButtonTone.amber,
                    label: ent.isPermanentSupporter
                        ? l10n.sunPassOwnedCheck
                        : l10n.sunPassBuyOnceBtn,
                    onPressed: (!busy && !ent.isPermanentSupporter)
                        ? () => _runWithParentalGate(
                              context,
                              controller.purchaseLifetimePass,
                            )
                        : null,
                  ),
                ),

                const SizedBox(height: 10),

                // Footer: Restore Purchases
                Align(
                  alignment: Alignment.centerRight,
                  child: SolvilleButton(
                    tone: SolvilleButtonTone.cream,
                    compact: true,
                    icon: Icons.restore_rounded,
                    label: l10n.sunPassRestorePurchases,
                    onPressed: busy
                        ? null
                        : () => _runWithParentalGate(
                              context,
                              controller.restorePurchases,
                            ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _runWithParentalGate(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final passed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ParentalGateDialog(),
    );
    if (passed == true) {
      await action();
    }
  }
}

class _ParentalGateDialog extends StatefulWidget {
  const _ParentalGateDialog();

  @override
  State<_ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<_ParentalGateDialog> {
  late final int _a;
  late final int _b;
  final TextEditingController _answerController = TextEditingController();
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _a = 6 + rng.nextInt(4); // 6..9
    _b = 4 + rng.nextInt(6); // 4..9
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = int.tryParse(_answerController.text.trim());
    if (parsed == _a * _b) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _showError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SolvilleDialogShell(
      emoji: '🔒',
      leadingIcon: const SolvilleIcon(kind: SolvilleIconKind.padlock, size: 22),
      title: l10n.parentalGateTitle,
      maxWidth: 420,
      maxHeight: 360,
      shrinkWrap: true,
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            SolvilleButton(
              tone: SolvilleButtonTone.cream,
              compact: true,
              label: l10n.parentalGateCancel,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(width: 8),
            SolvilleButton(
              tone: SolvilleButtonTone.emerald,
              compact: true,
              label: l10n.parentalGateContinue,
              onPressed: _submit,
            ),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.parentalGateSubtitle,
              style: const TextStyle(color: SolvilleTheme.timberDark),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.parentalGateQuestion(_a, _b),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: SolvilleTheme.timberDark,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _answerController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              autofocus: true,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: l10n.parentalGateHint,
                errorText: _showError ? l10n.parentalGateWrong : null,
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.entitlements});

  final EntitlementState entitlements;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final String headline;
    final String subtext;
    final Color bgColor;

    if (entitlements.isPermanentSupporter) {
      headline = l10n.sunPassStatusLifetimeHeadline;
      subtext = l10n.sunPassStatusLifetimeSubtext;
      bgColor = const Color(0xFFFFF3C4);
    } else {
      headline = l10n.sunPassStatusStarterHeadline;
      subtext = l10n.sunPassStatusStarterSubtext;
      bgColor = const Color(0xFFFFF8E1);
    }

    return SolvilleMenuCard(
      color: bgColor,
      highlighted: entitlements.isPermanentSupporter,
      radius: 15,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            headline,
            style: const TextStyle(
              color: SolvilleTheme.timberDark,
              fontWeight: FontWeight.w900,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtext,
            style: const TextStyle(
              color: SolvilleTheme.timberDark,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.emoji,
    required this.title,
    required this.badgeText,
    required this.badgeColor,
    required this.backgroundColor,
    required this.description,
    required this.trailing,
  });

  final String emoji;
  final String title;
  final String badgeText;
  final Color badgeColor;
  final Color backgroundColor;
  final String description;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return SolvilleMenuCard(
      color: backgroundColor,
      highlighted: true,
      radius: 15,
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackTrailing = constraints.maxWidth < 380;
          final mainRow = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SolvilleIconMedallion(
                size: 46,
                highlighted: true,
                child: Text(emoji, style: const TextStyle(fontSize: 25)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SolvilleBadge(
                      label: badgeText,
                      color: badgeColor,
                      borderColor: const Color(0x66AD1457),
                      fontSize: 10.5,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      borderRadius: 8,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: SolvilleTheme.timberDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12.2,
                        color: SolvilleTheme.timberDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (!stackTrailing) ...<Widget>[
                const SizedBox(width: 10),
                trailing,
              ],
            ],
          );
          if (!stackTrailing) return mainRow;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[mainRow, const SizedBox(height: 10), trailing],
          );
        },
      ),
    );
  }
}
