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
        final express = market.expressOrder;
        final visibleProducts = ProductId.values.where((id) {
          if (!id.isSpecialtyCraft) return true;
          return (state.barnStock[id] ?? 0) > 0 ||
              market.trendFor(id) == MarketTrend.boom ||
              express?.product == id ||
              req?.product == id;
        }).toList();

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
              if (express != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE65100),
                      width: 1.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Text('⚡', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.marketExpressHeading(
                                l10n.villagerName(express.villagerName),
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: SolvilleTheme.timberDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE082),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '⏳ ${l10n.marketExpressTimer(express.remainingSeconds.ceil())}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: SolvilleTheme.timberDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                minHeight: 8,
                                value: express.requiredCount > 0
                                    ? (express.deliveredCount /
                                              express.requiredCount)
                                          .clamp(0.0, 1.0)
                                    : 1.0,
                                backgroundColor: const Color(0x33795548),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFE65100),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${SolvilleCatalog.productEmoji(express.product)} ${express.deliveredCount}/${express.requiredCount}  →  +${express.bonusCoins}☀️${express.bonusTrialSeed != null ? ' +🎁🌱' : ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: SolvilleTheme.timberDark,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              if (market.isRushActive)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE082),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SolvilleTheme.timberBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        '${l10n.hudRushBadge} • ⚡ 1.65×',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: SolvilleTheme.timberDark,
                        ),
                      ),
                      Text(
                        '⏳ ${l10n.marketExpressTimer(market.rushSecondsRemaining.ceil())}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: SolvilleTheme.timberDark,
                        ),
                      ),
                    ],
                  ),
                ),

              // Daily Village Request Card
              if (req != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: req.isCompleted
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SolvilleTheme.timberBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            req.isCompleted ? '✅' : '💌',
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.marketOrderHeading(
                                l10n.villagerName(req.villagerName),
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: SolvilleTheme.timberDark,
                              ),
                            ),
                          ),
                          Text(
                            req.isCompleted
                                ? '+${req.bonusReward}☀️ ✓'
                                : '${SolvilleCatalog.productEmoji(req.product)} ${req.deliveredCount}/${req.requiredCount}  →  +${req.bonusReward}☀️',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: SolvilleTheme.timberDark,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          minHeight: 7,
                          value: req.requiredCount > 0
                              ? (req.deliveredCount / req.requiredCount).clamp(
                                  0.0,
                                  1.0,
                                )
                              : 1.0,
                          backgroundColor: const Color(0x22795548),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            req.isCompleted
                                ? const Color(0xFF43A047)
                                : SolvilleTheme.sunGold,
                          ),
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stackButton = constraints.maxWidth < 380;
                    final surgeBtn = FilledButton.tonal(
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
                    );
                    final infoRow = Row(
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
                                    : (controller
                                              .entitlements
                                              .isPermanentSupporter
                                          ? l10n.marketSurgeSupporterSubtitle
                                          : l10n.marketSurgeFreeSubtitle),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (!stackButton) ...<Widget>[
                          const SizedBox(width: 8),
                          surgeBtn,
                        ],
                      ],
                    );
                    if (!stackButton) return infoRow;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        infoRow,
                        const SizedBox(height: 8),
                        surgeBtn,
                      ],
                    );
                  },
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
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
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
                  if (state.totalBarnCrates > 0)
                    TextButton.icon(
                      onPressed: controller.stockAllBoomFromBarn,
                      icon: const Icon(Icons.local_fire_department),
                      label: Text(l10n.marketStockHotGoods),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 10),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    for (var i = 0; i < MarketState.maxStallSlots; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: i < market.stallCrates.length
                              ? SolvilleTheme.warmCream
                              : const Color(0x16795548),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: i < market.stallCrates.length
                                ? SolvilleTheme.timberBorder
                                : const Color(0x33795548),
                          ),
                        ),
                        child: Text(
                          i < market.stallCrates.length
                              ? '${SolvilleCatalog.productEmoji(market.stallCrates[i])} ${market.unitPriceFor(market.stallCrates[i], charmBonus: state.charmBonus)}☀️'
                              : '📦',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: i < market.stallCrates.length
                                ? SolvilleTheme.timberDark
                                : Colors.black26,
                          ),
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

              LayoutBuilder(
                builder: (context, constraints) {
                  final twoCol = constraints.maxWidth >= 440;
                  final tileWidth = twoCol
                      ? (constraints.maxWidth - 8) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final id in visibleProducts)
                        SizedBox(
                          width: tileWidth,
                          child: _buildPriceRow(
                            l10n: l10n,
                            id: id,
                            trend: market.trendFor(id),
                            price: market.unitPriceFor(
                              id,
                              charmBonus: state.charmBonus,
                            ),
                            barnCount: state.barnStock[id] ?? 0,
                          ),
                        ),
                    ],
                  );
                },
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
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: <Widget>[
            Text(
              SolvilleCatalog.productEmoji(id),
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.productName(id),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: SolvilleTheme.timberDark,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 5,
                    runSpacing: 3,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.marketTrendLabel(trend),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (barnCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '📦$barnCount',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$price☀️',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: SolvilleTheme.timberDark,
              ),
            ),
            if (barnCount > 0) ...<Widget>[
              const SizedBox(width: 6),
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
