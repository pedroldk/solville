import 'catalog.dart';

enum GroundType {
  grass,
  weeds,
  soil,
  stonePath,
  cobbleLane;
}

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
    return PlantedCrop(
      cropId: ProductId.values.byName(json['cropId'] as String),
      growth: (json['growth'] as num).toDouble(),
      harvestsLeft: json['harvestsLeft'] as int,
      thirstySeconds: (json['thirstySeconds'] as num?)?.toDouble() ?? 0.0,
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
    return AnimalUnitState(
      type: AnimalType.values.byName(json['type'] as String),
      progress: (json['progress'] as num).toDouble(),
      feedLevel: (json['feedLevel'] as num).toDouble(),
      readyCrates: json['readyCrates'] as int,
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
    return TileState(
      ground: GroundType.values.byName(json['ground'] as String),
      structure: StructureType.values.byName(json['structure'] as String),
      fertilized: json['fertilized'] as bool? ?? false,
      moisture: (json['moisture'] as num?)?.toDouble() ?? 0.0,
      crop: json['crop'] != null
          ? PlantedCrop.fromJson(json['crop'] as Map<String, dynamic>)
          : null,
      animal: json['animal'] != null
          ? AnimalUnitState.fromJson(json['animal'] as Map<String, dynamic>)
          : null,
      droppedCrate: json['droppedCrate'] != null
          ? ProductId.values.byName(json['droppedCrate'] as String)
          : null,
      sprinklerCooldown:
          (json['sprinklerCooldown'] as num?)?.toDouble() ?? 2.0,
      producerProgress:
          (json['producerProgress'] as num?)?.toDouble() ?? 0.0,
      producerCrates: json['producerCrates'] as int? ?? 0,
      producerActive: json['producerActive'] as bool? ?? false,
    );
  }
}
