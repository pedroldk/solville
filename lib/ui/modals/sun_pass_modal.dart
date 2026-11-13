import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/entitlement_state.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/solville_l10n_extensions.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';
import '../widgets/solville_dialog_shell.dart';

/// Cozy "Solville Sun Pass" dialog allowing players to:
/// 1. Watch 1 rewarded ad for +24h of full catalog access (stackable up to 48h)
/// 2. Subscribe to the Annual Sun Pass for 2,99€ / year
/// 3. Unlock the Lifetime Cozy Edition for 4,99€ one-time
/// 4. Activate their daily "Sunny Surge" boost or restore store purchases
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
        final now = controller.nowUtc;
        final isActive = controller.isSunPassActive;
        final canStackAd = ent.canStackAnotherAd(now);
        final remText = l10n.formatDuration(ent.remainingAdPassDuration(now));
        final busy = controller.isMonetizationBusy;

        return SolvilleDialogShell(
          emoji: '☀️',
          title: l10n.sunPassTitle,
          maxWidth: 680,
          maxHeight: 620,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFFFF3C4)
                  : const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SolvilleTheme.timberBorder),
            ),
            child: Text(
              isActive ? l10n.sunPassBadgeActive : l10n.sunPassBadgeStarter,
              style: const TextStyle(
                color: SolvilleTheme.timberDark,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Status Banner
                _StatusBanner(
                  entitlements: ent,
                  isActive: isActive,
                  remainingLabel: remText,
                ),

                const SizedBox(height: 12),

                // What's Included visual perk grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SolvilleTheme.warmCream,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x44795548)),
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

                // Option 1: Watch Rewarded Ad (+24h, stackable up to 48h)
                _OfferCard(
                  emoji: '🎬',
                  title: l10n.sunPassAdTitle,
                  badgeText: l10n.sunPassAdBadge,
                  badgeColor: const Color(0xFFE1F5FE),
                  backgroundColor: const Color(0xFFFFFFFF),
                  description: l10n.sunPassAdDesc,
                  trailing: FilledButton.tonal(
                    onPressed: (!busy && canStackAd)
                        ? () => controller.watchAdForSunPass()
                        : null,
                    child: Text(
                      ent.isPermanentSupporter
                          ? l10n.sunPassUnlockedForever
                          : (!canStackAd
                                ? l10n.sunPassMaxed48h
                                : (isActive
                                      ? l10n.sunPassWatchAdTopUp
                                      : l10n.sunPassWatchAd24h)),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Option 2: Annual Sun Pass (2,99€ / year)
                _OfferCard(
                  emoji: '🌻',
                  title: l10n.sunPassAnnualTitle(l10n.entitlementAnnualPrice),
                  badgeText: l10n.sunPassAnnualBadge,
                  badgeColor: const Color(0xFFFFE082),
                  backgroundColor: const Color(0xFFFFFDE7),
                  description: l10n.sunPassAnnualDesc,
                  trailing: FilledButton(
                    onPressed: (!busy && !ent.isPermanentSupporter)
                        ? () => _runWithParentalGate(
                              context,
                              controller.purchaseAnnualPass,
                            )
                        : null,
                    child: Text(
                      ent.hasAnnualPass || ent.hasLifetimePass
                          ? l10n.sunPassActiveCheck
                          : l10n.sunPassSubscribeBtn,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Option 3: Lifetime Cozy Edition (4,99€ one-time)
                _OfferCard(
                  emoji: '👑',
                  title: l10n.sunPassLifetimeTitle(
                    l10n.entitlementLifetimePrice,
                  ),
                  badgeText: l10n.sunPassLifetimeBadge,
                  badgeColor: const Color(0xFFF8BBD0),
                  backgroundColor: const Color(0xFFFFF8F9),
                  description: l10n.sunPassLifetimeDesc,
                  trailing: FilledButton(
                    onPressed: (!busy && !ent.hasLifetimePass)
                        ? () => _runWithParentalGate(
                              context,
                              controller.purchaseLifetimePass,
                            )
                        : null,
                    child: Text(
                      ent.hasLifetimePass
                          ? l10n.sunPassOwnedCheck
                          : l10n.sunPassBuyOnceBtn,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Daily Sunny Surge Quick Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SolvilleTheme.timberBorder),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final stackBtn = constraints.maxWidth < 380;
                      final surgeBtn = OutlinedButton(
                        onPressed: (!busy && controller.canClaimSunnySurgeToday)
                            ? () => controller.activateSunnySurge()
                            : null,
                        child: Text(
                          !controller.canClaimSunnySurgeToday
                              ? l10n.sunPassActiveTodayCheck
                              : (ent.isPermanentSupporter
                                    ? l10n.sunPassClaimFreeSurge
                                    : l10n.sunPassWatchAdSurge),
                        ),
                      );
                      final topRow = Row(
                        children: <Widget>[
                          const Text('🌦️', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  l10n.sunPassSurgeCardTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: SolvilleTheme.timberDark,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  ent.isPermanentSupporter
                                      ? l10n.sunPassSurgeSupporterDesc
                                      : l10n.sunPassSurgeFreeDesc,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (!stackBtn) ...<Widget>[
                            const SizedBox(width: 8),
                            surgeBtn,
                          ],
                        ],
                      );
                      if (!stackBtn) return topRow;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          topRow,
                          const SizedBox(height: 8),
                          surgeBtn,
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Footer: Restore Purchases
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: busy
                        ? null
                        : () => _runWithParentalGate(
                              context,
                              controller.restorePurchases,
                            ),
                    icon: const Icon(Icons.restore_rounded, size: 17),
                    label: Text(l10n.sunPassRestorePurchases),
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
    return AlertDialog(
      backgroundColor: SolvilleTheme.parchment,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: SolvilleTheme.timberBorder, width: 2),
      ),
      title: Text(
        l10n.parentalGateTitle,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: SolvilleTheme.timberDark,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.parentalGateSubtitle),
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
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.parentalGateCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.parentalGateContinue),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.entitlements,
    required this.isActive,
    required this.remainingLabel,
  });

  final EntitlementState entitlements;
  final bool isActive;
  final String remainingLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final String headline;
    final String subtext;
    final Color bgColor;

    if (entitlements.hasLifetimePass || entitlements.isFullEditionBuild) {
      headline = l10n.sunPassStatusLifetimeHeadline;
      subtext = l10n.sunPassStatusLifetimeSubtext;
      bgColor = const Color(0xFFFFF3C4);
    } else if (entitlements.hasAnnualPass) {
      headline = l10n.sunPassStatusAnnualHeadline;
      subtext = l10n.sunPassStatusAnnualSubtext;
      bgColor = const Color(0xFFFFF3C4);
    } else if (isActive) {
      headline = l10n.sunPassStatusAdHeadline(remainingLabel);
      subtext = l10n.sunPassStatusAdSubtext;
      bgColor = const Color(0xFFE8F5E9);
    } else {
      headline = l10n.sunPassStatusStarterHeadline;
      subtext = l10n.sunPassStatusStarterSubtext;
      bgColor = const Color(0xFFFFF8E1);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SolvilleTheme.timberBorder),
      ),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SolvilleTheme.timberBorder, width: 1.4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackTrailing = constraints.maxWidth < 380;
          final mainRow = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: SolvilleTheme.timberDark,
                        ),
                      ),
                    ),
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
