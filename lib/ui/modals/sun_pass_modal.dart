import 'package:flutter/material.dart';

import '../../domain/models/entitlement_state.dart';
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
        final ent = controller.entitlements;
        final now = controller.nowUtc;
        final isActive = controller.isSunPassActive;
        final canStackAd = ent.canStackAnotherAd(now);
        final remText = ent.formatRemainingTime(now);
        final busy = controller.isMonetizationBusy;

        return SolvilleDialogShell(
          emoji: '☀️',
          title: 'Solville Sun Pass',
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
              isActive ? '☀️ Active' : 'Starter Tier',
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

                // What's Included showcase
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SolvilleTheme.warmCream,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x44795548)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '✨ Everything Included in Sun Pass:',
                        style: TextStyle(
                          color: SolvilleTheme.timberDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '• 🌽🪻🎃 Gourmet Crops: Golden Corn, Fragrant Lavender (+35% Bee speed) & Solville Pumpkin\n'
                        '• 🍋🫙🐝🐄 Artisan & Ranch: Lemon Trees, Artisan Preserves Kettle, Wildflower Apiary, Sunny Cow Paddock, Solar Mist Tower (5×5) & Blossom Arch\n'
                        '• 🏝️🛠️ Grand Expansions & Master Tools: Expand your isle up to 35×35 + Tier 2 Tool Upgrades\n'
                        '• 💚 Cozy Promise: Your farm is never deleted if the ad timer ends—existing builds simply pause until you unlock again!',
                        style: TextStyle(
                          color: SolvilleTheme.timberDark,
                          fontSize: 12.5,
                          height: 1.38,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Option 1: Watch Rewarded Ad (+24h, stackable up to 48h)
                _OfferCard(
                  emoji: '🎬',
                  title: 'Watch 1 Short Ad • +24 Hours Unlock',
                  badgeText: 'FREE • STACK UP TO 48H',
                  badgeColor: const Color(0xFFE1F5FE),
                  backgroundColor: const Color(0xFFFFFFFF),
                  description:
                      'Unlock the entire Solville catalog for 24 hours. Watch 2 ads back-to-back to stack up to 48 hours of uninterrupted play!',
                  trailing: FilledButton.tonal(
                    onPressed: (!busy && canStackAd)
                        ? () => controller.watchAdForSunPass()
                        : null,
                    child: Text(
                      ent.isPermanentSupporter
                          ? 'Unlocked Forever'
                          : (!canStackAd
                                ? 'Maxed (48h)'
                                : (isActive
                                      ? 'Watch Ad (+24h Top-Up)'
                                      : 'Watch Ad (+24h)')),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Option 2: Annual Sun Pass (2,99€ / year)
                _OfferCard(
                  emoji: '🌻',
                  title:
                      'Annual Sun Pass • ${EntitlementState.annualPassPriceLabel}',
                  badgeText: 'MOST POPULAR • ~0,25€/MO',
                  badgeColor: const Color(0xFFFFE082),
                  backgroundColor: const Color(0xFFFFFDE7),
                  description:
                      'Full year of ad-free access to all crops, animals & island expansions + Free 1-tap Daily Sunny Surge (+25% Market Boost & instant Sunshower)!',
                  trailing: FilledButton(
                    onPressed: (!busy && !ent.isPermanentSupporter)
                        ? () => controller.purchaseAnnualPass()
                        : null,
                    child: Text(
                      ent.hasAnnualPass || ent.hasLifetimePass
                          ? 'Active ✓'
                          : 'Subscribe 2,99€/yr',
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Option 3: Lifetime Cozy Edition (4,99€ one-time)
                _OfferCard(
                  emoji: '👑',
                  title:
                      'Lifetime Cozy Edition • ${EntitlementState.lifetimePassPriceLabel}',
                  badgeText: 'ONE-TIME PAYMENT • OWN FOREVER',
                  badgeColor: const Color(0xFFF8BBD0),
                  backgroundColor: const Color(0xFFFFF8F9),
                  description:
                      'No subscriptions, no timers, no ads—ever. Own all of Solville and daily Sunny Surge boosts forever with a single purchase.',
                  trailing: FilledButton(
                    onPressed: (!busy && !ent.hasLifetimePass)
                        ? () => controller.purchaseLifetimePass()
                        : null,
                    child: Text(
                      ent.hasLifetimePass ? 'Owned ✓' : 'Buy Once 4,99€',
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
                  child: Row(
                    children: <Widget>[
                      const Text('🌦️', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Daily Sunny Surge (100% Hydration + +25% Market Prices)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: SolvilleTheme.timberDark,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              ent.isPermanentSupporter
                                  ? 'Included free every day with your supporter pass!'
                                  : 'Watch 1 optional ad once per day to drench your farm & boost Market Stall payouts!',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: (!busy && controller.canClaimSunnySurgeToday)
                            ? () => controller.activateSunnySurge()
                            : null,
                        child: Text(
                          !controller.canClaimSunnySurgeToday
                              ? 'Active Today ✓'
                              : (ent.isPermanentSupporter
                                    ? 'Claim Free Surge'
                                    : 'Watch Ad (Surge)'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Footer: Restore Purchases
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: busy ? null : controller.restorePurchases,
                    icon: const Icon(Icons.restore_rounded, size: 17),
                    label: const Text('Restore Purchases'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    final String headline;
    final String subtext;
    final Color bgColor;

    if (entitlements.hasLifetimePass || entitlements.isFullEditionBuild) {
      headline = '👑 Lifetime Cozy Edition Unlocked';
      subtext =
          'All crops, animals, expansions, and free daily Sunny Surges are yours forever!';
      bgColor = const Color(0xFFFFF3C4);
    } else if (entitlements.hasAnnualPass) {
      headline = '🌻 Annual Sun Pass Active (2,99€ / year)';
      subtext =
          'All Sun Pass content and free daily Sunny Surges are unlocked!';
      bgColor = const Color(0xFFFFF3C4);
    } else if (isActive) {
      headline = '☀️ Ad Pass Active — $remainingLabel remaining';
      subtext =
          'All crops, builds, and upgrades are unlocked! You can stack up to 48 hours max.';
      bgColor = const Color(0xFFE8F5E9);
    } else {
      headline = '🌱 Playing on Free Starter Homestead';
      subtext =
          'Watch 1 short ad for 24h of full access (stackable to 48h), or unlock permanently below!';
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
      child: Row(
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
          const SizedBox(width: 10),
          trailing,
        ],
      ),
    );
  }
}
