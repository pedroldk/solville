/// Soothing background soundscape modes in Solville.
enum BgmTrack {
  sunnyLullaby,
  morningMeadow,
  cozyRain,
  off;

  String get label => switch (this) {
    sunnyLullaby => '🎸 Sunlit Lullaby',
    morningMeadow => '🐦 Meadow Breeze',
    cozyRain => '🌧️ Cozy Rain',
    off => '🔇 Music Off',
  };

  String get shortEmoji => switch (this) {
    sunnyLullaby => '🎸',
    morningMeadow => '🐦',
    cozyRain => '🌧️',
    off => '🔇',
  };
}

/// All harvestable & tradable goods in Solville.
enum ProductId {
  tomato,
  carrot,
  strawberry,
  corn,
  lavender,
  pumpkin,
  lemon,
  eggs,
  honey,
  milk,
  preserves;

  bool get isCrop => switch (this) {
    tomato || carrot || strawberry || corn || lavender || pumpkin => true,
    lemon || eggs || honey || milk || preserves => false,
  };

  /// Whether this raw farm produce can be simmered into Gourmet Preserves.
  bool get canMakePreserves => switch (this) {
    tomato ||
    carrot ||
    strawberry ||
    corn ||
    lavender ||
    pumpkin ||
    lemon => true,
    eggs || honey || milk || preserves => false,
  };
}

/// Static definition of a crop variety.
class CropDef {
  const CropDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.licenseCost,
    required this.seedCost,
    required this.baseCrateValue,
    required this.growthSeconds,
    required this.waterDrainPerSec,
    required this.maxHarvests,
    required this.primaryColorHex,
    required this.accentColorHex,
  });

  final ProductId id;
  final String name;
  final String emoji;
  final String description;

  /// One-time shop unlock cost (`0` for starter seeds).
  final int licenseCost;

  /// Per-planting seed cost.
  final int seedCost;

  /// Base value of one harvested crate at 1.0x Steady market demand.
  final int baseCrateValue;

  /// Base seconds from seed to ripe harvest (before Compost bonus).
  final double growthSeconds;

  /// Moisture drained per second while growing in the Solville sun.
  final double waterDrainPerSec;

  /// Number of harvests before replanting (`> 1` for multi-harvest bushes/vines).
  final int maxHarvests;

  final int primaryColorHex;
  final int accentColorHex;
}

/// Animal enclosure types inspired by Alice Greenfingers.
enum AnimalType {
  chicken,
  bee,
  cow;
}

class AnimalDef {
  const AnimalDef({
    required this.type,
    required this.name,
    required this.emoji,
    required this.description,
    required this.shopCost,
    required this.tendCost,
    required this.product,
    required this.cycleSeconds,
  });

  final AnimalType type;
  final String name;
  final String emoji;
  final String description;
  final int shopCost;
  final int tendCost;
  final ProductId product;
  final double cycleSeconds;
}

/// Placeable structures, orchard trees, artisan workshops & garden decor.
enum BuildItemType {
  sprinklerRotary,
  sprinklerSolar,
  lemonTree,
  artisanPress,
  henhouse,
  beehive,
  cowPaddock,
  stonePath,
  lantern,
  flowerArch,
}

class BuildItemDef {
  const BuildItemDef({
    required this.type,
    required this.name,
    required this.emoji,
    required this.description,
    required this.cost,
    required this.walkable,
    this.sprinklerRadius = 0,
    this.charmBonus = 0.0,
  });

  final BuildItemType type;
  final String name;
  final String emoji;
  final String description;
  final int cost;
  final bool walkable;
  final int sprinklerRadius;
  final double charmBonus;
}

/// Permanent character & farm upgrades in the Town Shop.
enum UpgradeTrack {
  wateringCan,
  crateStacker,
  gardenBoots,
  farmExpansion,
}

class UpgradeTierDef {
  const UpgradeTierDef({
    required this.track,
    required this.tier,
    required this.name,
    required this.emoji,
    required this.description,
    required this.cost,
  });

  final UpgradeTrack track;
  final int tier;
  final String name;
  final String emoji;
  final String description;
  final int cost;
}

/// Milestone trophy definition (synced to Trophy Cabinet & Steam Achievements).
class TrophyDef {
  const TrophyDef({
    required this.id,
    required this.steamApiName,
    required this.title,
    required this.emoji,
    required this.description,
    required this.rewardCoins,
  });

  final String id;
  final String steamApiName;
  final String title;
  final String emoji;
  final String description;
  final int rewardCoins;
}

/// Central catalog of balanced game definitions for Solville.
abstract final class SolvilleCatalog {
  static const int compostCost = 18;
  static const double lemonTreeCycleSeconds = 24.0;
  static const double artisanPressCycleSeconds = 20.0;

  static const Map<ProductId, CropDef> crops = <ProductId, CropDef>{
    ProductId.tomato: CropDef(
      id: ProductId.tomato,
      name: 'Sunripe Tomato',
      emoji: '🍅',
      description: 'Juicy starter vine! Yields 3 harvests before replanting.',
      licenseCost: 0,
      seedCost: 6,
      baseCrateValue: 20,
      growthSeconds: 18.0,
      waterDrainPerSec: 0.026,
      maxHarvests: 3,
      primaryColorHex: 0xFFE53935,
      accentColorHex: 0xFFFF8A65,
    ),
    ProductId.carrot: CropDef(
      id: ProductId.carrot,
      name: 'Crisp Carrot',
      emoji: '🥕',
      description: 'Fast-growing root crop with light water needs.',
      licenseCost: 0,
      seedCost: 4,
      baseCrateValue: 16,
      growthSeconds: 13.0,
      waterDrainPerSec: 0.018,
      maxHarvests: 1,
      primaryColorHex: 0xFFFB8C00,
      accentColorHex: 0xFFFFCC80,
    ),
    ProductId.strawberry: CropDef(
      id: ProductId.strawberry,
      name: 'Sweet Strawberry',
      emoji: '🍓',
      description: 'Lush berry bush producing 3 sweet harvests.',
      licenseCost: 65,
      seedCost: 10,
      baseCrateValue: 30,
      growthSeconds: 22.0,
      waterDrainPerSec: 0.028,
      maxHarvests: 3,
      primaryColorHex: 0xFFD81B60,
      accentColorHex: 0xFFF48FB1,
    ),
    ProductId.corn: CropDef(
      id: ProductId.corn,
      name: 'Golden Corn',
      emoji: '🌽',
      description: 'Tall sunlit stalks yielding hearty, high-value crates.',
      licenseCost: 110,
      seedCost: 14,
      baseCrateValue: 44,
      growthSeconds: 26.0,
      waterDrainPerSec: 0.024,
      maxHarvests: 1,
      primaryColorHex: 0xFFFDD835,
      accentColorHex: 0xFFFFF59D,
    ),
    ProductId.lavender: CropDef(
      id: ProductId.lavender,
      name: 'Fragrant Lavender',
      emoji: '🪻',
      description:
          'Drought-hardy blooms! Boosts nearby Beehives by +35% speed.',
      licenseCost: 160,
      seedCost: 18,
      baseCrateValue: 48,
      growthSeconds: 24.0,
      waterDrainPerSec: 0.014,
      maxHarvests: 2,
      primaryColorHex: 0xFF8E24AA,
      accentColorHex: 0xFFCE93D8,
    ),
    ProductId.pumpkin: CropDef(
      id: ProductId.pumpkin,
      name: 'Solville Pumpkin',
      emoji: '🎃',
      description: 'Prized gourmet harvest with massive Market Boom payouts.',
      licenseCost: 240,
      seedCost: 26,
      baseCrateValue: 82,
      growthSeconds: 34.0,
      waterDrainPerSec: 0.025,
      maxHarvests: 1,
      primaryColorHex: 0xFFF4511E,
      accentColorHex: 0xFFFFAB91,
    ),
  };

  static const Map<ProductId, int> productBaseValues = <ProductId, int>{
    ProductId.tomato: 20,
    ProductId.carrot: 16,
    ProductId.strawberry: 30,
    ProductId.corn: 44,
    ProductId.lavender: 48,
    ProductId.pumpkin: 82,
    ProductId.lemon: 38,
    ProductId.eggs: 34,
    ProductId.honey: 52,
    ProductId.milk: 76,
    ProductId.preserves: 96,
  };

  static String productName(ProductId id) => switch (id) {
    ProductId.tomato => 'Sunripe Tomato',
    ProductId.carrot => 'Crisp Carrot',
    ProductId.strawberry => 'Sweet Strawberry',
    ProductId.corn => 'Golden Corn',
    ProductId.lavender => 'Fragrant Lavender',
    ProductId.pumpkin => 'Solville Pumpkin',
    ProductId.lemon => 'Sunburst Lemons',
    ProductId.eggs => 'Fresh Eggs',
    ProductId.honey => 'Wildflower Honey',
    ProductId.milk => 'Creamy Milk',
    ProductId.preserves => 'Artisan Preserves',
  };

  static String productEmoji(ProductId id) => switch (id) {
    ProductId.tomato => '🍅',
    ProductId.carrot => '🥕',
    ProductId.strawberry => '🍓',
    ProductId.corn => '🌽',
    ProductId.lavender => '🪻',
    ProductId.pumpkin => '🎃',
    ProductId.lemon => '🍋',
    ProductId.eggs => '🥚',
    ProductId.honey => '🍯',
    ProductId.milk => '🥛',
    ProductId.preserves => '🫙',
  };

  static const Map<AnimalType, AnimalDef> animals = <AnimalType, AnimalDef>{
    AnimalType.chicken: AnimalDef(
      type: AnimalType.chicken,
      name: 'Cozy Henhouse',
      emoji: '🐔',
      description: 'Happy hens lay crates of Fresh Eggs when fed grain.',
      shopCost: 135,
      tendCost: 5,
      product: ProductId.eggs,
      cycleSeconds: 24.0,
    ),
    AnimalType.bee: AnimalDef(
      type: AnimalType.bee,
      name: 'Wildflower Apiary',
      emoji: '🐝',
      description:
          'Gentle honeybees craft Wildflower Honey; faster near blooms!',
      shopCost: 210,
      tendCost: 0,
      product: ProductId.honey,
      cycleSeconds: 28.0,
    ),
    AnimalType.cow: AnimalDef(
      type: AnimalType.cow,
      name: 'Sunny Paddock',
      emoji: '🐄',
      description: 'Contented dairy cow producing rich, top-value Creamy Milk.',
      shopCost: 330,
      tendCost: 8,
      product: ProductId.milk,
      cycleSeconds: 32.0,
    ),
  };

  static const Map<BuildItemType, BuildItemDef> buildItems =
      <BuildItemType, BuildItemDef>{
        BuildItemType.sprinklerRotary: BuildItemDef(
          type: BuildItemType.sprinklerRotary,
          name: 'Rotary Sprinkler',
          emoji: '💦',
          description: 'Automatically waters all 8 surrounding plots (3x3).',
          cost: 105,
          walkable: false,
          sprinklerRadius: 1,
        ),
        BuildItemType.sprinklerSolar: BuildItemDef(
          type: BuildItemType.sprinklerSolar,
          name: 'Solar Mist Tower',
          emoji: '⛲',
          description: 'Waters a lush 5x5 garden zone with golden solar mist.',
          cost: 235,
          walkable: false,
          sprinklerRadius: 2,
        ),
        BuildItemType.lemonTree: BuildItemDef(
          type: BuildItemType.lemonTree,
          name: 'Sunburst Lemon Tree',
          emoji: '🍋',
          description:
              'Permanent orchard tree! Passively grows crates of Lemons.',
          cost: 165,
          walkable: false,
          charmBonus: 0.02,
        ),
        BuildItemType.artisanPress: BuildItemDef(
          type: BuildItemType.artisanPress,
          name: 'Artisan Kettle',
          emoji: '🫙',
          description:
              'Simmers carried or Barn fruit/crops into 96☀️ Preserves!',
          cost: 260,
          walkable: false,
        ),
        BuildItemType.henhouse: BuildItemDef(
          type: BuildItemType.henhouse,
          name: 'Cozy Henhouse',
          emoji: '🐔',
          description: 'Home for happy egg-laying chickens.',
          cost: 135,
          walkable: false,
        ),
        BuildItemType.beehive: BuildItemDef(
          type: BuildItemType.beehive,
          name: 'Wildflower Apiary',
          emoji: '🐝',
          description: 'Produces honey passively; loves nearby Lavender!',
          cost: 210,
          walkable: false,
        ),
        BuildItemType.cowPaddock: BuildItemDef(
          type: BuildItemType.cowPaddock,
          name: 'Sunny Paddock',
          emoji: '🐄',
          description: 'Lush mini-pasture for a prized dairy cow.',
          cost: 330,
          walkable: false,
        ),
        BuildItemType.stonePath: BuildItemDef(
          type: BuildItemType.stonePath,
          name: 'Sunstone Path',
          emoji: '🧱',
          description: 'Warm garden paving: +40% farmer walking speed!',
          cost: 10,
          walkable: true,
        ),
        BuildItemType.lantern: BuildItemDef(
          type: BuildItemType.lantern,
          name: 'Solar Lantern',
          emoji: '🏮',
          description: 'Warm dusk glow + +3% Market Charm price bonus.',
          cost: 45,
          walkable: false,
          charmBonus: 0.03,
        ),
        BuildItemType.flowerArch: BuildItemDef(
          type: BuildItemType.flowerArch,
          name: 'Blossom Arch',
          emoji: '🌸',
          description: 'Walkable floral arch + +6% Market Charm price bonus.',
          cost: 85,
          walkable: true,
          charmBonus: 0.06,
        ),
      };

  static const List<UpgradeTierDef> upgrades = <UpgradeTierDef>[
    UpgradeTierDef(
      track: UpgradeTrack.wateringCan,
      tier: 1,
      name: 'Copper Watering Can',
      emoji: '🪣',
      description: 'Doubles water capacity from 5 to 10 charges per refill.',
      cost: 75,
    ),
    UpgradeTierDef(
      track: UpgradeTrack.wateringCan,
      tier: 2,
      name: 'Solar Mist Jug',
      emoji: '✨',
      description: 'Holds 18 water charges and hydrates adjacent dry sprouts!',
      cost: 175,
    ),
    UpgradeTierDef(
      track: UpgradeTrack.crateStacker,
      tier: 1,
      name: 'Crate Stacker Gloves',
      emoji: '📦',
      description: 'Carry 2 stacked produce crates at once!',
      cost: 90,
    ),
    UpgradeTierDef(
      track: UpgradeTrack.crateStacker,
      tier: 2,
      name: 'Master Stacker Harness',
      emoji: '🏗️',
      description: 'Carry up to 4 stacked crates in a single market trip!',
      cost: 215,
    ),
    UpgradeTierDef(
      track: UpgradeTrack.gardenBoots,
      tier: 1,
      name: 'Breezy Canvas Boots',
      emoji: '👟',
      description: '+28% walking speed across the farm.',
      cost: 80,
    ),
    UpgradeTierDef(
      track: UpgradeTrack.gardenBoots,
      tier: 2,
      name: 'Sunrunner Boots',
      emoji: '🥾',
      description: '+55% walking speed — glide from garden to stall!',
      cost: 190,
    ),
    UpgradeTierDef(
      track: UpgradeTrack.farmExpansion,
      tier: 1,
      name: 'Sunny Meadow Deed',
      emoji: '🗺️',
      description: 'Expands the Solville farm grid from 11x11 to 14x14!',
      cost: 240,
    ),
    UpgradeTierDef(
      track: UpgradeTrack.farmExpansion,
      tier: 2,
      name: 'Grand Oasis Charter',
      emoji: '🏞️',
      description: 'Unlocks the full 17x17 sprawling Solville estate!',
      cost: 460,
    ),
  ];

  static const List<TrophyDef> trophies = <TrophyDef>[
    TrophyDef(
      id: 'first_sprout',
      steamApiName: 'ACH_FIRST_SPROUT',
      title: 'First Harvest',
      emoji: '🌱',
      description: 'Harvest your very first crate of Solville produce.',
      rewardCoins: 20,
    ),
    TrophyDef(
      id: 'market_debut',
      steamApiName: 'ACH_MARKET_DEBUT',
      title: 'Open for Business',
      emoji: '🏪',
      description: 'Earn 100 lifetime Sols selling at the Market Stall.',
      rewardCoins: 25,
    ),
    TrophyDef(
      id: 'green_thumb',
      steamApiName: 'ACH_GREEN_THUMB',
      title: 'Greenfingers Apprentice',
      emoji: '🌿',
      description: 'Harvest 25 crates of crops or artisan goods.',
      rewardCoins: 45,
    ),
    TrophyDef(
      id: 'hydration_hero',
      steamApiName: 'ACH_HYDRATION_HERO',
      title: 'Rainmaker',
      emoji: '💦',
      description: 'Install your first automated Sprinkler on the farm.',
      rewardCoins: 35,
    ),
    TrophyDef(
      id: 'stack_master',
      steamApiName: 'ACH_STACK_MASTER',
      title: 'Crate Juggler',
      emoji: '📦',
      description: 'Carry 2 or more stacked crates at the same time.',
      rewardCoins: 30,
    ),
    TrophyDef(
      id: 'feathered_friends',
      steamApiName: 'ACH_FEATHERED_FRIENDS',
      title: 'Morning Clucks',
      emoji: '🐔',
      description: 'Collect a crate of Fresh Eggs from a Cozy Henhouse.',
      rewardCoins: 40,
    ),
    TrophyDef(
      id: 'sweet_harmony',
      steamApiName: 'ACH_SWEET_HARMONY',
      title: 'Liquid Gold',
      emoji: '🍯',
      description: 'Harvest Wildflower Honey from an Apiary.',
      rewardCoins: 50,
    ),
    TrophyDef(
      id: 'dairy_delight',
      steamApiName: 'ACH_DAIRY_DELIGHT',
      title: 'Cream of the Crop',
      emoji: '🥛',
      description: 'Collect Creamy Milk from a Sunny Paddock.',
      rewardCoins: 65,
    ),
    TrophyDef(
      id: 'savvy_trader',
      steamApiName: 'ACH_SAVVY_TRADER',
      title: 'Market Timing',
      emoji: '📈',
      description: 'Sell 5 crates during a hot Market Boom.',
      rewardCoins: 55,
    ),
    TrophyDef(
      id: 'master_composter',
      steamApiName: 'ACH_MASTER_COMPOSTER',
      title: 'Living Soil',
      emoji: '✨',
      description: 'Enrich 8 garden beds with Rich Compost.',
      rewardCoins: 45,
    ),
    TrophyDef(
      id: 'village_darling',
      steamApiName: 'ACH_VILLAGE_DARLING',
      title: 'Beloved Neighbor',
      emoji: '💌',
      description: 'Fulfill 3 special Daily Village Requests.',
      rewardCoins: 75,
    ),
    TrophyDef(
      id: 'golden_oasis',
      steamApiName: 'ACH_GOLDEN_OASIS',
      title: 'Solville Legend',
      emoji: '🏆',
      description: 'Earn 2,000 lifetime Sols and expand your farm.',
      rewardCoins: 150,
    ),
  ];

  static int maxWaterForTier(int tier) => switch (tier) {
    0 => 5,
    1 => 10,
    _ => 18,
  };

  static int maxCratesForTier(int tier) => switch (tier) {
    0 => 1,
    1 => 2,
    _ => 4,
  };

  static double speedMultiplierForTier(int tier) => switch (tier) {
    0 => 1.0,
    1 => 1.28,
    _ => 1.55,
  };

  static int gridSizeForExpansionTier(int tier) => switch (tier) {
    0 => 11,
    1 => 14,
    _ => 17,
  };
}
