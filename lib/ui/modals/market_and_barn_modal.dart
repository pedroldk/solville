import 'package:flutter/material.dart';

import '../../domain/models/catalog.dart';
import '../../domain/models/market_state.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/solville_l10n_extensions.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';
import '../widgets/solville_dialog_shell.dart';

/// Town Market Forecast, Pricing Strategy, Daily Village Request & Barn Storage.
class MarketAndBarnModal extends StatelessWidget {
  const MarketAndBarnModal({super.key, required this.controller});

  final SolvilleController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final state = controller.state;
        final market = state.market;
        final charmPct = (state.charmBonus * 100).round();
        final req = market.dailyRequest;

        return SolvilleDialogShell(
          emoji: '🏪',
          title: l10n.marketTitle(state.day),
          maxWidth: 700,
          maxHeight: 590,
          trailing: charmPct > 0
              ? Chip(
                  backgroundColor: const Color(0xFFFCE4EC),
                  label: Text(l10n.marketCharmBadge(charmPct)),
                )
              : null,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: <Widget>[
              // Daily Village Request Card
              if (req != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: req.isCompleted
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SolvilleTheme.timberBorder),
                  ),
                  child: Row(
                    children: <Widget>[
                      Text(
                        req.isCompleted ? '✅' : '💌',
                        style: const TextStyle(fontSize: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              l10n.marketOrderHeading(
                                l10n.villagerName(req.villagerName),
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: SolvilleTheme.timberDark,
                              ),
                            ),
                            Text(
                              req.isCompleted
                                  ? l10n.marketOrderCompleted(req.bonusReward)
                                  : l10n.marketOrderProgress(
                                      req.requiredCount,
                                      SolvilleCatalog.productEmoji(req.product),
                                      l10n.productName(req.product),
                                      req.deliveredCount,
                                      req.bonusReward,
                                    ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Daily Sunny Surge Card (+25% Market Boost & Instant Sunshower)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: market.sunnySurgeActive
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFE1F5FE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SolvilleTheme.timberBorder),
                ),
                child: Row(
                  children: <Widget>[
                    Text(
                      market.sunnySurgeActive ? '✨' : '🌦️',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            market.sunnySurgeActive
                                ? l10n.marketSurgeActiveTitle
                                : l10n.marketSurgeInactiveTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: SolvilleTheme.timberDark,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            market.sunnySurgeActive
                                ? l10n.marketSurgeActiveSubtitle
                                : (controller.entitlements.isPermanentSupporter
                                      ? l10n.marketSurgeSupporterSubtitle
                                      : l10n.marketSurgeFreeSubtitle),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: controller.canClaimSunnySurgeToday
                          ? () => controller.activateSunnySurge()
                          : null,
                      child: Text(
                        market.sunnySurgeActive
                            ? l10n.marketSurgeActiveBtn
                            : (controller.entitlements.isPermanentSupporter
                                  ? l10n.marketSurgeFreeBtn
                                  : l10n.marketSurgeWatchAdBtn),
                      ),
                    ),
                  ],
                ),
              ),

              // Pricing Stance Picker
              Text(
                l10n.marketPricingHeading,
                style: const TextStyle(
                  color: SolvilleTheme.timberDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  for (final stance in PricingStance.values)
                    ChoiceChip(
                      selected: market.pricing == stance,
                      selectedColor: const Color(0xFFFFE082),
                      label: Text(l10n.pricingStanceLabel(stance)),
                      onSelected: (_) => controller.setPricingStance(stance),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // Stall & Barn Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      l10n.marketCounterAndBarn(
                        market.stallCrates.length,
                        MarketState.maxStallSlots,
                        state.totalBarnCrates,
                      ),
                      style: const TextStyle(
                        color: SolvilleTheme.timberDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (state.totalBarnCrates > 0)
                    TextButton.icon(
                      onPressed: controller.stockAllBoomFromBarn,
                      icon: const Icon(Icons.local_fire_department),
                      label: Text(l10n.marketStockHotGoods),
                    ),
                ],
              ),
              if (market.stallCrates.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      for (final p in market.stallCrates)
                        Chip(
                          backgroundColor: SolvilleTheme.warmCream,
                          label: Text(
                            '${SolvilleCatalog.productEmoji(p)} ${market.unitPriceFor(p, charmBonus: state.charmBonus)}☀️',
                          ),
                        ),
                    ],
                  ),
                ),

              const Divider(),
              Text(
                l10n.marketTodayPricesHeading,
                style: const TextStyle(
                  color: SolvilleTheme.timberDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),

              for (final id in ProductId.values)
                _buildPriceRow(
                  l10n: l10n,
                  id: id,
                  trend: market.trendFor(id),
                  price: market.unitPriceFor(id, charmBonus: state.charmBonus),
                  barnCount: state.barnStock[id] ?? 0,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceRow({
    required AppLocalizations l10n,
    required ProductId id,
    required MarketTrend trend,
    required int price,
    required int barnCount,
  }) {
    final badgeColor = switch (trend) {
      MarketTrend.boom => const Color(0xFFFFCDD2),
      MarketTrend.high => const Color(0xFFFFF9C4),
      MarketTrend.steady => const Color(0xFFEEEEEE),
      MarketTrend.surplus => const Color(0xFFE1F5FE),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 7),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: <Widget>[
            Text(
              SolvilleCatalog.productEmoji(id),
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.productName(id),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: SolvilleTheme.timberDark,
                    ),
                  ),
                  if (barnCount > 0)
                    Text(
                      l10n.marketInBarnCount(barnCount),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                l10n.marketTrendLabel(trend),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$price☀️',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: SolvilleTheme.timberDark,
              ),
            ),
            if (barnCount > 0) ...<Widget>[
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () => controller.stockStallFromBarn(id),
                child: Text(l10n.marketSellOne),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
