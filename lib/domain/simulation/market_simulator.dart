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
      expressSpawnCooldown: 18.0,
    );
  }

  static GameState tickMarketStallSales(
    GameState state,
    double dt,
    List<SimEvent> events, {
    required GridPos marketStallPos,
    math.Random? rng,
  }) {
    var current = state;
    var market = current.market;

    // 1. Update Village Rush timer & mid-day rush wave (noon–afternoon)
    var rushRemaining = market.rushSecondsRemaining;
    if (rushRemaining > 0.0) {
      rushRemaining = (rushRemaining - dt).clamp(0.0, 120.0);
    } else if (market.stallCrates.length >= 2 &&
        current.dayProgress >= 0.48 &&
        current.dayProgress <= 0.52 &&
        market.expressOrder == null) {
      rushRemaining = 24.0;
      events.add(
        const SimEvent(
          type: SimEventType.villageRushStarted,
          message: '🌟 Village Market Rush! Customers buy faster!',
          toast: SolvilleToast(SolvilleToastKind.villageRushStarted),
        ),
      );
    }

    // 2. Tick or spawn timed Express Flash Orders from named villagers
    var express = market.expressOrder;
    var spawnCd = market.expressSpawnCooldown;
    if (express != null) {
      final rem = express.remainingSeconds - dt;
      express = rem <= 0.0 ? null : express.copyWith(remainingSeconds: rem);
      if (express == null) {
        spawnCd = 30.0;
      }
    } else if (current.totalCratesHarvested >= 1) {
      spawnCd -= dt;
      if (spawnCd <= 0.0) {
        express = _spawnExpressOrder(current, rng);
        spawnCd = 32.0;
      }
    }

    market = market.copyWith(
      rushSecondsRemaining: rushRemaining,
      expressOrder: express,
      expressSpawnCooldown: spawnCd,
    );

    if (market.stallCrates.isEmpty) {
      return identical(market, current.market)
          ? current
          : current.copyWith(market: market);
    }

    final rushSpeedFactor = market.isRushActive ? 1.65 : 1.0;
    final nextCooldown = market.saleCooldown - dt * rushSpeedFactor;
    if (nextCooldown > 0.0) {
      return current.copyWith(
        market: market.copyWith(saleCooldown: nextCooldown),
      );
    }

    // Prioritize matching crate if express/daily order product is stocked on the stall
    final stallList = List<ProductId>.from(market.stallCrates);
    var soldIdx = 0;
    if (express != null) {
      final idx = stallList.indexOf(express.product);
      if (idx >= 0) soldIdx = idx;
    } else if (market.dailyRequest != null &&
        !market.dailyRequest!.isCompleted) {
      final idx = stallList.indexOf(market.dailyRequest!.product);
      if (idx >= 0) soldIdx = idx;
    }

    final soldProduct = stallList.removeAt(soldIdx);
    final charm = current.charmBonus;
    final salePrice = market.unitPriceFor(soldProduct, charmBonus: charm);
    final isBoom = market.trendFor(soldProduct) == MarketTrend.boom;

    var earnedCoins = salePrice;
    var updatedRequest = market.dailyRequest;
    var completedRequests = current.requestsCompleted;
    var updatedTrials = current.trialSeeds;

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

    // Check timed Express Flash Order progress
    if (express != null &&
        !express.isCompleted &&
        express.product == soldProduct) {
      final nextDelivered = express.deliveredCount + 1;
      express = express.copyWith(deliveredCount: nextDelivered);
      if (express.isCompleted) {
        earnedCoins += express.bonusCoins;
        completedRequests += 1;
        if (express.bonusTrialSeed != null) {
          final trialCopy = Map<ProductId, int>.from(updatedTrials);
          final seed = express.bonusTrialSeed!;
          trialCopy[seed] = (trialCopy[seed] ?? 0) + 1;
          updatedTrials = trialCopy;
        }
        events.add(
          SimEvent(
            type: SimEventType.expressOrderFulfilled,
            tile: marketStallPos,
            amount: express.bonusCoins,
            message:
                '⚡ ${express.villagerName} loved the express order! +${express.bonusCoins}☀️',
            toast: SolvilleToast(
              SolvilleToastKind.expressOrderComplete,
              villagerName: express.villagerName,
              coins: express.bonusCoins,
              product: express.bonusTrialSeed,
            ),
          ),
        );
        express = null;
        spawnCd = 34.0;
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
    return current.copyWith(
      coins: current.coins + earnedCoins,
      lifetimeCoinsEarned: current.lifetimeCoinsEarned + earnedCoins,
      boomCratesSold: current.boomCratesSold + (isBoom ? 1 : 0),
      requestsCompleted: completedRequests,
      trialSeeds: updatedTrials,
      market: market.copyWith(
        stallCrates: stallList,
        saleCooldown: baseInterval,
        dailyRequest: updatedRequest,
        expressOrder: express,
        expressSpawnCooldown: spawnCd,
      ),
    );
  }

  static ExpressOrder? _spawnExpressOrder(GameState state, math.Random? rng) {
    final candidates = state.unlockedSeeds.toList();
    if (candidates.isEmpty) return null;
    final pickSeed = rng != null
        ? rng.nextInt(candidates.length)
        : (state.day + state.totalCratesHarvested) % candidates.length;
    final product = candidates[pickSeed];
    final variant = rng != null
        ? rng.nextInt(_villagerNames.length)
        : (state.day + state.requestsCompleted) % _villagerNames.length;
    final reqCount = state.day >= 2 ? 2 : 1;
    final baseVal = SolvilleCatalog.productBaseValues[product] ?? 20;
    final bonus = (baseVal * reqCount * 0.85).round() + 14;

    ProductId? trialGift;
    const gourmet = <ProductId>[
      ProductId.corn,
      ProductId.lavender,
      ProductId.pumpkin,
    ];
    final lockedGourmet = gourmet
        .where((g) => !state.unlockedSeeds.contains(g))
        .toList();
    if (lockedGourmet.isNotEmpty) {
      final idx = rng != null
          ? rng.nextInt(lockedGourmet.length)
          : state.requestsCompleted % lockedGourmet.length;
      trialGift = lockedGourmet[idx];
    }

    return ExpressOrder(
      villagerName: _villagerNames[variant],
      villagerVariant: variant,
      product: product,
      requiredCount: reqCount,
      deliveredCount: 0,
      remainingSeconds: 65.0,
      totalSeconds: 65.0,
      bonusCoins: bonus,
      bonusTrialSeed: trialGift,
    );
  }
}
