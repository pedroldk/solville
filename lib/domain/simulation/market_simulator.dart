import 'dart:math' as math;

import '../models/catalog.dart';
import '../models/game_state.dart';
import '../models/grid_pos.dart';
import '../models/market_state.dart';
import '../models/solville_toast.dart';

/// Generates morning market trends, daily villager orders, and processes
/// townsfolk purchases at the Market Stall.
abstract final class MarketSimulator {
  static const List<String> _villagerNames = <String>[
    'Baker Mateo',
    'Chef Clara',
    'Florist Mina',
    'Grandpa Leo',
    'Mayor Sunny',
  ];

  static MarketState generateMorningMarket({
    required math.Random rng,
    required Set<ProductId> unlockedSeeds,
    required List<ProductId> existingStallCrates,
    required PricingStance pricing,
    required List<ProductId> extraAccessible,
  }) {
    final trends = <ProductId, MarketTrend>{};
    final allProducts = List<ProductId>.from(ProductId.values)..shuffle(rng);

    for (var i = 0; i < allProducts.length; i++) {
      final p = allProducts[i];
      if (i < 2) {
        trends[p] = MarketTrend.boom;
      } else if (i < 5) {
        trends[p] = MarketTrend.high;
      } else if (i == allProducts.length - 1) {
        trends[p] = MarketTrend.surplus;
      } else {
        trends[p] = MarketTrend.steady;
      }
    }

    final accessible = <ProductId>{
      ...unlockedSeeds,
      ...extraAccessible,
    }.toList();
    if (accessible.isNotEmpty &&
        !accessible.any((p) => trends[p] == MarketTrend.boom)) {
      trends[accessible[rng.nextInt(accessible.length)]] = MarketTrend.boom;
    }

    final reqProduct = accessible[rng.nextInt(accessible.length)];
    final reqCount = 2 + rng.nextInt(2);
    final villager = _villagerNames[rng.nextInt(_villagerNames.length)];
    final baseVal = SolvilleCatalog.productBaseValues[reqProduct] ?? 20;
    final bonus = (baseVal * reqCount * 0.75).round() + 15;

    return MarketState(
      trends: trends,
      stallCrates: existingStallCrates,
      pricing: pricing,
      saleCooldown: 3.0,
      dailyRequest: VillageRequest(
        villagerName: villager,
        product: reqProduct,
        requiredCount: reqCount,
        deliveredCount: 0,
        bonusReward: bonus,
      ),
    );
  }

  static GameState tickMarketStallSales(
    GameState state,
    double dt,
    List<SimEvent> events, {
    required GridPos marketStallPos,
  }) {
    final market = state.market;
    if (market.stallCrates.isEmpty) {
      return state;
    }

    final nextCooldown = market.saleCooldown - dt;
    if (nextCooldown > 0.0) {
      return state.copyWith(
        market: market.copyWith(saleCooldown: nextCooldown),
      );
    }

    final soldProduct = market.stallCrates.first;
    final remainingCrates = market.stallCrates.sublist(1);
    final charm = state.charmBonus;
    final salePrice = market.unitPriceFor(soldProduct, charmBonus: charm);
    final isBoom = market.trendFor(soldProduct) == MarketTrend.boom;

    var earnedCoins = salePrice;
    var updatedRequest = market.dailyRequest;
    var completedRequests = state.requestsCompleted;

    if (updatedRequest != null &&
        !updatedRequest.isCompleted &&
        updatedRequest.product == soldProduct) {
      final nextDelivered = updatedRequest.deliveredCount + 1;
      updatedRequest = updatedRequest.copyWith(deliveredCount: nextDelivered);
      if (updatedRequest.isCompleted) {
        earnedCoins += updatedRequest.bonusReward;
        completedRequests += 1;
        events.add(
          SimEvent(
            type: SimEventType.coinsEarned,
            tile: marketStallPos,
            amount: updatedRequest.bonusReward,
            message:
                '${updatedRequest.villagerName}\'s order complete! +${updatedRequest.bonusReward}☀️',
            toast: SolvilleToast(
              SolvilleToastKind.villagerOrderComplete,
              villagerName: updatedRequest.villagerName,
              coins: updatedRequest.bonusReward,
            ),
          ),
        );
      }
    }

    events.add(
      SimEvent(
        type: SimEventType.coinsEarned,
        tile: marketStallPos,
        amount: salePrice,
        message:
            'Sold ${SolvilleCatalog.productEmoji(soldProduct)} +$salePrice☀️',
        toast: SolvilleToast(
          SolvilleToastKind.soldCrate,
          product: soldProduct,
          coins: salePrice,
        ),
      ),
    );

    final baseInterval = 3.2 * market.pricing.saleIntervalFactor;
    return state.copyWith(
      coins: state.coins + earnedCoins,
      lifetimeCoinsEarned: state.lifetimeCoinsEarned + earnedCoins,
      boomCratesSold: state.boomCratesSold + (isBoom ? 1 : 0),
      requestsCompleted: completedRequests,
      market: market.copyWith(
        stallCrates: remainingCrates,
        saleCooldown: baseInterval,
        dailyRequest: updatedRequest,
      ),
    );
  }
}
