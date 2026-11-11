import 'catalog.dart';

enum GroundType { grass, weeds, soil, stonePath, cobbleLane }

enum StructureType {
  none,
  farmhouse,
  well,
  barn,
  marketStall,
  sprinklerRotary,
  sprinklerSolar,
  lemonTree,
  artisanPress,
  henhouse,
  beehive,
  cowPaddock,
  lantern,
  flowerArch;

  bool get isWalkable => switch (this) {
    none || flowerArch => true,
    farmhouse ||
    well ||
    barn ||
    marketStall ||
    sprinklerRotary ||
    sprinklerSolar ||
    lemonTree ||
    artisanPress ||
    henhouse ||
    beehive ||
    cowPaddock ||
    lantern => false,
  };

  bool get isRemovable => switch (this) {
    sprinklerRotary ||
    sprinklerSolar ||
    lemonTree ||
    artisanPress ||
    henhouse ||
    beehive ||
    cowPaddock ||
    lantern ||
    flowerArch => true,
    none || farmhouse || well || barn || marketStall => false,
  };

  int get sprinklerRadius => switch (this) {
    sprinklerRotary => 1,
    sprinklerSolar => 2,
    _ => 0,
  };

  double get charmBonus => switch (this) {
    lantern => 0.03,
    flowerArch => 0.06,
    lemonTree => 0.02,
    _ => 0.0,
  };

  /// Whether this placed structure belongs to the Sun Pass tier (pauses new
  /// production cycles gracefully when the Sun Pass is inactive).
  bool get requiresSunPass => switch (this) {
    sprinklerSolar ||
    lemonTree ||
    artisanPress ||
    beehive ||
    cowPaddock ||
    flowerArch => true,
    none ||
    farmhouse ||
    well ||
    barn ||
    marketStall ||
    sprinklerRotary ||
    henhouse ||
    lantern => false,
  };
}

class PlantedCrop {
  const PlantedCrop({
    required this.cropId,
    required this.growth,
    required this.harvestsLeft,
    this.thirstySeconds = 0.0,
  });

  final ProductId cropId;

  /// Normalized growth progress `0.0` (seed) to `1.0` (ripe).
  final double growth;

  final int harvestsLeft;

  /// Seconds spent completely dry (`moisture <= 0.01`). Cozy mode droops visually
  /// without punishingly destroying crops.
  final double thirstySeconds;

  bool get isRipe => growth >= 1.0;
  bool get isDrooping => !isRipe && thirstySeconds > 4.0;

  PlantedCrop copyWith({
    ProductId? cropId,
    double? growth,
    int? harvestsLeft,
    double? thirstySeconds,
  }) {
    return PlantedCrop(
      cropId: cropId ?? this.cropId,
      growth: growth ?? this.growth,
      harvestsLeft: harvestsLeft ?? this.harvestsLeft,
      thirstySeconds: thirstySeconds ?? this.thirstySeconds,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'cropId': cropId.name,
    'growth': growth,
    'harvestsLeft': harvestsLeft,
    'thirstySeconds': thirstySeconds,
  };

  factory PlantedCrop.fromJson(Map<String, dynamic> json) {
    final rawGrowth = (json['growth'] as num?)?.toDouble() ?? 0.0;
    final safeGrowth = (rawGrowth.isNaN || rawGrowth.isInfinite)
        ? 0.0
        : rawGrowth.clamp(0.0, 1.0);
    final rawThirsty = (json['thirstySeconds'] as num?)?.toDouble() ?? 0.0;
    final safeThirsty = (rawThirsty.isNaN || rawThirsty.isInfinite)
        ? 0.0
        : (rawThirsty < 0.0 ? 0.0 : rawThirsty);
    return PlantedCrop(
      cropId: ProductId.values.byName(json['cropId'] as String),
      growth: safeGrowth,
      harvestsLeft: ((json['harvestsLeft'] as num?)?.toInt() ?? 1).clamp(1, 99),
      thirstySeconds: safeThirsty,
    );
  }
}

class AnimalUnitState {
  const AnimalUnitState({
    required this.type,
    this.progress = 0.0,
    this.feedLevel = 1.0,
    this.readyCrates = 0,
  });

  final AnimalType type;
  final double progress;
  final double feedLevel;
  final int readyCrates;

  bool get needsTending =>
      type != AnimalType.bee && feedLevel <= 0.05 && readyCrates == 0;

  AnimalUnitState copyWith({
    AnimalType? type,
    double? progress,
    double? feedLevel,
    int? readyCrates,
  }) {
    return AnimalUnitState(
      type: type ?? this.type,
      progress: progress ?? this.progress,
      feedLevel: feedLevel ?? this.feedLevel,
      readyCrates: readyCrates ?? this.readyCrates,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type.name,
    'progress': progress,
    'feedLevel': feedLevel,
    'readyCrates': readyCrates,
  };

  factory AnimalUnitState.fromJson(Map<String, dynamic> json) {
    double clamp01(Object? raw, double fallback) {
      if (raw is! num) return fallback;
      final v = raw.toDouble();
      return (v.isNaN || v.isInfinite) ? fallback : v.clamp(0.0, 1.0);
    }

    return AnimalUnitState(
      type: AnimalType.values.byName(json['type'] as String),
      progress: clamp01(json['progress'], 0.0),
      feedLevel: clamp01(json['feedLevel'], 1.0),
      readyCrates: ((json['readyCrates'] as num?)?.toInt() ?? 0).clamp(0, 99),
    );
  }
}

const Object _unset = Object();

class TileState {
  const TileState({
    this.ground = GroundType.grass,
    this.structure = StructureType.none,
    this.fertilized = false,
    this.moisture = 0.0,
    this.crop,
    this.animal,
    this.droppedCrate,
    this.sprinklerCooldown = 2.0,
    this.producerProgress = 0.0,
    this.producerCrates = 0,
    this.producerActive = false,
  });

  final GroundType ground;
  final StructureType structure;
  final bool fertilized;
  final double moisture;
  final PlantedCrop? crop;
  final AnimalUnitState? animal;
  final ProductId? droppedCrate;
  final double sprinklerCooldown;

  /// Progress (`0.0..1.0`) & ready crates for Orchard Trees and Artisan Presses.
  final double producerProgress;
  final int producerCrates;
  final bool producerActive;

  bool get isWalkable => structure.isWalkable;

  double get walkCost => switch (ground) {
    GroundType.stonePath || GroundType.cobbleLane => 0.70,
    GroundType.weeds => 1.20,
    GroundType.grass || GroundType.soil => 1.0,
  };

  /// Whether this tile currently has ripe produce or a crate ready for collection.
  bool get isReadyToHarvest =>
      (crop != null && crop!.isRipe) ||
      (animal != null && animal!.readyCrates > 0) ||
      producerCrates > 0 ||
      droppedCrate != null;

  /// Whether this tile is a growing soil plot in need of watering.
  bool get isThirstyPlot =>
      ground == GroundType.soil &&
      crop != null &&
      !crop!.isRipe &&
      moisture < 0.65;

  /// Whether this tile can be restored to grass or have its structure removed.
  bool get canUntillOrRemove =>
      structure.isRemovable ||
      (structure == StructureType.none &&
          (ground == GroundType.soil ||
              ground == GroundType.stonePath ||
              ground == GroundType.weeds ||
              crop != null));

  /// Whether this tile is an open soil or stone-path plot eligible for one-tap untilling.
  bool get canQuickUntill =>
      structure == StructureType.none &&
      (ground == GroundType.soil || ground == GroundType.stonePath);

  TileState copyWith({
    GroundType? ground,
    StructureType? structure,
    bool? fertilized,
    double? moisture,
    Object? crop = _unset,
    Object? animal = _unset,
    Object? droppedCrate = _unset,
    double? sprinklerCooldown,
    double? producerProgress,
    int? producerCrates,
    bool? producerActive,
  }) {
    return TileState(
      ground: ground ?? this.ground,
      structure: structure ?? this.structure,
      fertilized: fertilized ?? this.fertilized,
      moisture: moisture ?? this.moisture,
      crop: identical(crop, _unset) ? this.crop : crop as PlantedCrop?,
      animal: identical(animal, _unset)
          ? this.animal
          : animal as AnimalUnitState?,
      droppedCrate: identical(droppedCrate, _unset)
          ? this.droppedCrate
          : droppedCrate as ProductId?,
      sprinklerCooldown: sprinklerCooldown ?? this.sprinklerCooldown,
      producerProgress: producerProgress ?? this.producerProgress,
      producerCrates: producerCrates ?? this.producerCrates,
      producerActive: producerActive ?? this.producerActive,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'ground': ground.name,
    'structure': structure.name,
    'fertilized': fertilized,
    'moisture': moisture,
    if (crop != null) 'crop': crop!.toJson(),
    if (animal != null) 'animal': animal!.toJson(),
    if (droppedCrate != null) 'droppedCrate': droppedCrate!.name,
    'sprinklerCooldown': sprinklerCooldown,
    if (producerProgress > 0.0) 'producerProgress': producerProgress,
    if (producerCrates > 0) 'producerCrates': producerCrates,
    if (producerActive) 'producerActive': producerActive,
  };

  factory TileState.fromJson(Map<String, dynamic> json) {
    T enumByNameOr<T extends Enum>(List<T> values, Object? raw, T fallback) {
      if (raw is String) {
        for (final v in values) {
          if (v.name == raw) return v;
        }
      }
      return fallback;
    }

    T? enumByNameOrNull<T extends Enum>(List<T> values, Object? raw) {
      if (raw is String) {
        for (final v in values) {
          if (v.name == raw) return v;
        }
      }
      return null;
    }

    double safeDouble(
      Object? raw,
      double fallback, {
      double min = 0.0,
      double max = 1.0,
    }) {
      if (raw is! num) return fallback;
      final v = raw.toDouble();
      return (v.isNaN || v.isInfinite) ? fallback : v.clamp(min, max);
    }

    PlantedCrop? parsedCrop;
    if (json['crop'] is Map<String, dynamic>) {
      try {
        parsedCrop = PlantedCrop.fromJson(json['crop'] as Map<String, dynamic>);
      } catch (_) {}
    }

    AnimalUnitState? parsedAnimal;
    if (json['animal'] is Map<String, dynamic>) {
      try {
        parsedAnimal = AnimalUnitState.fromJson(
          json['animal'] as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    return TileState(
      ground: enumByNameOr(
        GroundType.values,
        json['ground'],
        GroundType.grass,
      ),
      structure: enumByNameOr(
        StructureType.values,
        json['structure'],
        StructureType.none,
      ),
      fertilized: json['fertilized'] == true,
      moisture: safeDouble(json['moisture'], 0.0),
      crop: parsedCrop,
      animal: parsedAnimal,
      droppedCrate: enumByNameOrNull(ProductId.values, json['droppedCrate']),
      sprinklerCooldown: safeDouble(
        json['sprinklerCooldown'],
        2.0,
        min: 0.0,
        max: 60.0,
      ),
      producerProgress: safeDouble(json['producerProgress'], 0.0),
      producerCrates: ((json['producerCrates'] as num?)?.toInt() ?? 0).clamp(
        0,
        99,
      ),
      producerActive: json['producerActive'] == true,
    );
  }
}
