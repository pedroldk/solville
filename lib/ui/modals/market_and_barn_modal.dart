import 'package:flutter/material.dart';

import '../../domain/models/catalog.dart';
import '../../domain/models/market_state.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/solville_l10n_extensions.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';
import '../widgets/solville_buttons.dart';
import '../widgets/solville_dialog_shell.dart';
import '../widgets/solville_icons.dart';

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
          leadingIcon: const SolvilleIcon(
            kind: SolvilleIconKind.marketStall,
            size: 22,
          ),
          title: l10n.marketTitle(state.day),
          maxWidth: 700,
          maxHeight: 590,
          trailing: charmPct > 0
              ? SolvilleBadge(
                  label: l10n.marketCharmBadge(charmPct),
                  color: const Color(0xFFFCE4EC),
                  borderColor: const Color(0x99AD1457),
                )
              : null,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: <Widget>[
              if (express != null)
                SolvilleMenuCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(11),
                  color: const Color(0xFFFFF3E0),
                  borderColor: const Color(0xFFE65100),
                  highlighted: true,
                  radius: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const SolvilleIconMedallion(
                            size: 34,
                            highlighted: true,
                            backgroundColor: Color(0xFFFFE0B2),
                            child: Text('⚡', style: TextStyle(fontSize: 18)),
                          ),
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
                          const SizedBox(width: 6),
                          Flexible(
                            fit: FlexFit.loose,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: SolvilleBadge(
                                label:
                                    '⏳ ${l10n.marketExpressTimer(express.remainingSeconds.ceil())}',
                                color: const Color(0xFFFFE082),
                                borderColor: const Color(0xFFE65100),
                                fontSize: 12,
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
                          Flexible(
                            fit: FlexFit.loose,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${SolvilleCatalog.productEmoji(express.product)} ${express.deliveredCount}/${express.requiredCount}  →  +${express.bonusCoins}☀️${express.bonusTrialSeed != null ? ' +🎁🌱' : ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: SolvilleTheme.timberDark,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              if (market.isRushActive)
                SolvilleMenuCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  color: const Color(0xFFFFE082),
                  highlighted: true,
                  radius: 12,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        '${l10n.hudRushBadge} • ⚡ 1.35×',
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
                SolvilleMenuCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(11),
                  color: req.isCompleted
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF8E1),
                  highlighted: req.isCompleted,
                  radius: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          SolvilleIconMedallion(
                            size: 34,
                            backgroundColor: req.isCompleted
                                ? const Color(0xFFC8E6C9)
                                : SolvilleTheme.warmCream,
                            child: Text(
                              req.isCompleted ? '✅' : '💌',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                          const SizedBox(width: 6),
                          Flexible(
                            fit: FlexFit.loose,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: SolvilleBadge(
                                label: req.isCompleted
                                    ? '+${req.bonusReward}☀️ ✓'
                                    : '${SolvilleCatalog.productEmoji(req.product)} ${req.deliveredCount}/${req.requiredCount} → +${req.bonusReward}☀️',
                                color: req.isCompleted
                                    ? const Color(0xFFC8E6C9)
                                    : const Color(0xFFFFECB3),
                                borderColor: const Color(0x66795548),
                                fontSize: 12.5,
                              ),
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
                    SolvilleChip(
                      selected: market.pricing == stance,
                      label: l10n.pricingStanceLabel(stance),
                      onTap: () => controller.setPricingStance(stance),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const SolvilleIcon(
                        kind: SolvilleIconKind.barnCrate,
                        size: 17,
                      ),
                      const SizedBox(width: 6),
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
                    ],
                  ),
                  if (state.totalBarnCrates > 0)
                    SolvilleButton(
                      tone: SolvilleButtonTone.primary,
                      compact: true,
                      icon: Icons.local_fire_department_rounded,
                      label: l10n.marketStockHotGoods,
                      onPressed: controller.stockAllBoomFromBarn,
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: Text(
                  l10n.marketStallFlowHint,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: SolvilleTheme.timberDark.withValues(alpha: 0.78),
                  ),
                ),
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
                        decoration: i < market.stallCrates.length
                            ? SolvilleTheme.cardDecoration(
                                color: SolvilleTheme.warmCream,
                                borderColor: SolvilleTheme.cedarOuter,
                                radius: 10,
                              )
                            : SolvilleTheme.recessedSlotDecoration(radius: 10),
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

    return SolvilleMenuCard(
      radius: 15,
      highlighted: trend == MarketTrend.boom,
      color: trend == MarketTrend.boom
          ? const Color(0xFFFFF8E1)
          : SolvilleTheme.parchment,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: <Widget>[
          SolvilleIconMedallion(
            size: 38,
            radius: 11,
            highlighted: trend == MarketTrend.boom,
            child: Text(
              SolvilleCatalog.productEmoji(id),
              style: const TextStyle(fontSize: 20),
            ),
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
                    SolvilleBadge(
                      label: l10n.marketTrendLabel(trend),
                      color: badgeColor,
                      borderColor: const Color(0x44795548),
                      fontSize: 11,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      borderRadius: 8,
                    ),
                    if (barnCount > 0)
                      SolvilleBadge(
                        label: '📦$barnCount',
                        color: const Color(0xFFE8F5E9),
                        borderColor: const Color(0xFF43A047),
                        textColor: const Color(0xFF2E7D32),
                        fontSize: 11,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        borderRadius: 8,
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
            SolvilleButton(
              tone: SolvilleButtonTone.emerald,
              compact: true,
              fontSize: 12.0,
              borderRadius: 11,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              label: l10n.marketSellOne,
              onPressed: () => controller.stockStallFromBarn(id),
            ),
          ],
        ],
      ),
    );
  }
}
