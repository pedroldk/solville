import '../models/catalog.dart';
import '../models/game_state.dart';

/// Evaluates milestone trophy conditions and awards bonus Sols when unlocked.
abstract final class TrophyEvaluator {
  static final Map<String, TrophyDef> _trophyById = <String, TrophyDef>{
    for (final def in SolvilleCatalog.trophies) def.id: def,
  };

  static GameState evaluateTrophies(GameState state, List<SimEvent> events) {
    final existing = state.unlockedTrophies;
    if (existing.length >= SolvilleCatalog.trophies.length) {
      return state;
    }

    Set<String>? newlyUnlocked;
    var bonusCoins = 0;

    bool isUnlocked(String id) =>
        existing.contains(id) || (newlyUnlocked?.contains(id) ?? false);

    void check(String id, bool condition) {
      if (!condition || isUnlocked(id)) return;
      (newlyUnlocked ??= Set<String>.from(existing)).add(id);
      final def = _trophyById[id]!;
      bonusCoins += def.rewardCoins;
      events.add(
        SimEvent(
          type: SimEventType.trophyUnlocked,
          trophyId: id,
          amount: def.rewardCoins,
          message: '🏆 Trophy: ${def.title} (+${def.rewardCoins}☀️)!',
        ),
      );
    }

    bool hasProduct(ProductId product) {
      return (state.barnStock[product] ?? 0) > 0 ||
          state.farmer.carriedCrates.contains(product) ||
          state.market.stallCrates.contains(product);
    }

    check('first_sprout', state.totalCratesHarvested >= 1);
    check('market_debut', state.lifetimeCoinsEarned >= 100);
    check('green_thumb', state.totalCratesHarvested >= 25);
    if (!isUnlocked('hydration_hero')) {
      var hasSprinkler = false;
      final tiles = state.tiles;
      for (var i = 0; i < tiles.length; i++) {
        if (tiles[i].structure.sprinklerRadius > 0) {
          hasSprinkler = true;
          break;
        }
      }
      check('hydration_hero', hasSprinkler);
    }
    check('stack_master', state.farmer.carriedCrates.length >= 2);
    if (!isUnlocked('feathered_friends')) {
      check('feathered_friends', hasProduct(ProductId.eggs));
    }
    if (!isUnlocked('sweet_harmony')) {
      check('sweet_harmony', hasProduct(ProductId.honey));
    }
    if (!isUnlocked('dairy_delight')) {
      check('dairy_delight', hasProduct(ProductId.milk));
    }
    check('savvy_trader', state.boomCratesSold >= 5);
    check('master_composter', state.compostedPlotsCount >= 8);
    check('village_darling', state.requestsCompleted >= 3);
    check(
      'golden_oasis',
      state.lifetimeCoinsEarned >= 2000 &&
          state.upgradeTier(UpgradeTrack.farmExpansion) >= 1,
    );

    if (newlyUnlocked == null) {
      return state;
    }

    return state.copyWith(
      unlockedTrophies: newlyUnlocked,
      coins: state.coins + bonusCoins,
      lifetimeCoinsEarned: state.lifetimeCoinsEarned + bonusCoins,
    );
  }
}
