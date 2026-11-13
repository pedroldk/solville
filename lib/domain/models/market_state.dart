import 'catalog.dart';

enum MarketTrend {
  boom,
  high,
  steady,
  surplus;

  double get multiplier => switch (this) {
    boom => 1.45,
    high => 1.20,
    steady => 1.00,
    surplus => 0.85,
  };

  String get label => switch (this) {
    boom => '🔥 Boom +45%',
    high => '▲ High +20%',
    steady => '• Steady',
    surplus => '▽ Surplus -15%',
  };
}

enum PricingStance {
  bargain,
  fair,
  premium;

  double get priceFactor => switch (this) {
    bargain => 0.90,
    fair => 1.00,
    premium => 1.15,
  };

  /// Customer purchase interval multiplier (lower = faster sales!).
  double get saleIntervalFactor => switch (this) {
    bargain => 0.65,
    fair => 1.00,
    premium => 1.45,
  };

  String get label => switch (this) {
    bargain => 'Bargain (-10%, Fast Sales)',
    fair => 'Fair Price (Balanced)',
    premium => 'Boutique (+15%, Slower)',
  };
}

class VillageRequest {
  const VillageRequest({
    required this.villagerName,
    required this.product,
    required this.requiredCount,
    required this.deliveredCount,
    required this.bonusReward,
  });

  final String villagerName;
  final ProductId product;
  final int requiredCount;
  final int deliveredCount;
  final int bonusReward;

  bool get isCompleted => deliveredCount >= requiredCount;

  VillageRequest copyWith({
    String? villagerName,
    ProductId? product,
    int? requiredCount,
    int? deliveredCount,
    int? bonusReward,
  }) {
    return VillageRequest(
      villagerName: villagerName ?? this.villagerName,
      product: product ?? this.product,
      requiredCount: requiredCount ?? this.requiredCount,
      deliveredCount: deliveredCount ?? this.deliveredCount,
      bonusReward: bonusReward ?? this.bonusReward,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'villagerName': villagerName,
    'product': product.name,
    'requiredCount': requiredCount,
    'deliveredCount': deliveredCount,
    'bonusReward': bonusReward,
  };

  factory VillageRequest.fromJson(Map<String, dynamic> json) {
    return VillageRequest(
      villagerName: json['villagerName'] as String,
      product: ProductId.values.byName(json['product'] as String),
      requiredCount: json['requiredCount'] as int,
      deliveredCount: json['deliveredCount'] as int,
      bonusReward: json['bonusReward'] as int,
    );
  }
}

/// Timed flash order requested at the Market Stall by a named villager.
class ExpressOrder {
  const ExpressOrder({
    required this.villagerName,
    required this.villagerVariant,
    required this.product,
    required this.requiredCount,
    required this.deliveredCount,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.bonusCoins,
    this.bonusTrialSeed,
  });

  final String villagerName;
  final int villagerVariant;
  final ProductId product;
  final int requiredCount;
  final int deliveredCount;
  final double remainingSeconds;
  final double totalSeconds;
  final int bonusCoins;
  final ProductId? bonusTrialSeed;

  bool get isCompleted => deliveredCount >= requiredCount;
  bool get isExpired => remainingSeconds <= 0.0;
  double get progressFraction => totalSeconds <= 0.0
      ? 0.0
      : (remainingSeconds / totalSeconds).clamp(0.0, 1.0);

  ExpressOrder copyWith({
    String? villagerName,
    int? villagerVariant,
    ProductId? product,
    int? requiredCount,
    int? deliveredCount,
    double? remainingSeconds,
    double? totalSeconds,
    int? bonusCoins,
    ProductId? bonusTrialSeed,
  }) {
    return ExpressOrder(
      villagerName: villagerName ?? this.villagerName,
      villagerVariant: villagerVariant ?? this.villagerVariant,
      product: product ?? this.product,
      requiredCount: requiredCount ?? this.requiredCount,
      deliveredCount: deliveredCount ?? this.deliveredCount,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      bonusCoins: bonusCoins ?? this.bonusCoins,
      bonusTrialSeed: bonusTrialSeed ?? this.bonusTrialSeed,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'villagerName': villagerName,
    'villagerVariant': villagerVariant,
    'product': product.name,
    'requiredCount': requiredCount,
    'deliveredCount': deliveredCount,
    'remainingSeconds': remainingSeconds,
    'totalSeconds': totalSeconds,
    'bonusCoins': bonusCoins,
    if (bonusTrialSeed != null) 'bonusTrialSeed': bonusTrialSeed!.name,
  };

  factory ExpressOrder.fromJson(Map<String, dynamic> json) {
    final rem = (json['remainingSeconds'] as num?)?.toDouble() ?? 45.0;
    final tot = (json['totalSeconds'] as num?)?.toDouble() ?? 60.0;
    ProductId? parsedBonus;
    final rawBonus = json['bonusTrialSeed'];
    if (rawBonus is String) {
      for (final p in ProductId.values) {
        if (p.name == rawBonus) {
          parsedBonus = p;
          break;
        }
      }
    }
    return ExpressOrder(
      villagerName: json['villagerName'] as String,
      villagerVariant: ((json['villagerVariant'] as num?)?.toInt() ?? 0).clamp(
        0,
        4,
      ),
      product: ProductId.values.byName(json['product'] as String),
      requiredCount: ((json['requiredCount'] as num?)?.toInt() ?? 1).clamp(
        1,
        10,
      ),
      deliveredCount: ((json['deliveredCount'] as num?)?.toInt() ?? 0).clamp(
        0,
        10,
      ),
      remainingSeconds: (rem.isNaN || rem.isInfinite) ? 45.0 : rem.clamp(0, 300),
      totalSeconds: (tot.isNaN || tot.isInfinite) ? 60.0 : tot.clamp(10, 300),
      bonusCoins: ((json['bonusCoins'] as num?)?.toInt() ?? 25).clamp(1, 9999),
      bonusTrialSeed: parsedBonus,
    );
  }
}

const Object _marketUnset = Object();

class MarketState {
  MarketState({
    required this.trends,
    required this.stallCrates,
    this.pricing = PricingStance.fair,
    this.saleCooldown = 3.5,
    this.dailyRequest,
    this.sunnySurgeActive = false,
    this.expressOrder,
    this.rushSecondsRemaining = 0.0,
    this.expressSpawnCooldown = 28.0,
  });

  static const int maxStallSlots = 8;

  final Map<ProductId, MarketTrend> trends;
  final List<ProductId> stallCrates;
  final PricingStance pricing;
  final double saleCooldown;
  final VillageRequest? dailyRequest;

  /// True when the daily "Sunny Surge" (+25% Golden Market Boost) is active today.
  final bool sunnySurgeActive;

  /// Optional timed villager craving order at the Market Stall.
  final ExpressOrder? expressOrder;

  /// Active Village Rush timer (`> 0` speeds up customer purchases and arrivals).
  final double rushSecondsRemaining;

  /// Countdown before the next Express Order can appear.
  final double expressSpawnCooldown;

  bool get isRushActive => rushSecondsRemaining > 0.0;

  MarketTrend trendFor(ProductId id) => trends[id] ?? MarketTrend.steady;

  int unitPriceFor(ProductId id, {double charmBonus = 0.0}) {
    final base = SolvilleCatalog.productBaseValues[id] ?? 20;
    final trendMult = trendFor(id).multiplier;
    final stanceMult = pricing.priceFactor;
    final surgeMult = sunnySurgeActive ? 1.25 : 1.0;
    final total =
        base * trendMult * stanceMult * surgeMult * (1.0 + charmBonus);
    return total.round().clamp(1, 9999);
  }

  /// Cached list of products currently experiencing a Market Boom (`+45%`).
  late final List<ProductId> boomProducts = List<ProductId>.unmodifiable(
    trends.entries.where((e) => e.value == MarketTrend.boom).map((e) => e.key),
  );

  MarketState copyWith({
    Map<ProductId, MarketTrend>? trends,
    List<ProductId>? stallCrates,
    PricingStance? pricing,
    double? saleCooldown,
    VillageRequest? dailyRequest,
    bool? sunnySurgeActive,
    Object? expressOrder = _marketUnset,
    double? rushSecondsRemaining,
    double? expressSpawnCooldown,
  }) {
    return MarketState(
      trends: trends ?? this.trends,
      stallCrates: stallCrates ?? this.stallCrates,
      pricing: pricing ?? this.pricing,
      saleCooldown: saleCooldown ?? this.saleCooldown,
      dailyRequest: dailyRequest ?? this.dailyRequest,
      sunnySurgeActive: sunnySurgeActive ?? this.sunnySurgeActive,
      expressOrder: identical(expressOrder, _marketUnset)
          ? this.expressOrder
          : expressOrder as ExpressOrder?,
      rushSecondsRemaining: rushSecondsRemaining ?? this.rushSecondsRemaining,
      expressSpawnCooldown: expressSpawnCooldown ?? this.expressSpawnCooldown,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'trends': <String, String>{
      for (final entry in trends.entries) entry.key.name: entry.value.name,
    },
    'stallCrates': stallCrates.map((c) => c.name).toList(),
    'pricing': pricing.name,
    'saleCooldown': saleCooldown,
    if (dailyRequest != null) 'dailyRequest': dailyRequest!.toJson(),
    'sunnySurgeActive': sunnySurgeActive,
    if (expressOrder != null) 'expressOrder': expressOrder!.toJson(),
    if (rushSecondsRemaining > 0.0) 'rushSecondsRemaining': rushSecondsRemaining,
    'expressSpawnCooldown': expressSpawnCooldown,
  };

  factory MarketState.fromJson(Map<String, dynamic> json) {
    T? enumByNameOrNull<T extends Enum>(List<T> values, Object? raw) {
      if (raw is String) {
        for (final v in values) {
          if (v.name == raw) return v;
        }
      }
      return null;
    }

    final trends = <ProductId, MarketTrend>{};
    final rawTrends = json['trends'];
    if (rawTrends is Map<String, dynamic>) {
      for (final entry in rawTrends.entries) {
        final pid = enumByNameOrNull(ProductId.values, entry.key);
        final trend = enumByNameOrNull(MarketTrend.values, entry.value);
        if (pid != null && trend != null) {
          trends[pid] = trend;
        }
      }
    }

    final stallCrates = <ProductId>[];
    final rawStall = json['stallCrates'];
    if (rawStall is List<dynamic>) {
      for (final item in rawStall) {
        final pid = enumByNameOrNull(ProductId.values, item);
        if (pid != null && stallCrates.length < maxStallSlots) {
          stallCrates.add(pid);
        }
      }
    }

    final rawCooldown = (json['saleCooldown'] as num?)?.toDouble() ?? 3.5;
    final safeCooldown = (rawCooldown.isNaN || rawCooldown.isInfinite)
        ? 3.5
        : rawCooldown.clamp(0.0, 60.0);

    VillageRequest? parsedRequest;
    if (json['dailyRequest'] is Map<String, dynamic>) {
      try {
        parsedRequest = VillageRequest.fromJson(
          json['dailyRequest'] as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    ExpressOrder? parsedExpress;
    if (json['expressOrder'] is Map<String, dynamic>) {
      try {
        parsedExpress = ExpressOrder.fromJson(
          json['expressOrder'] as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    final rawRush = (json['rushSecondsRemaining'] as num?)?.toDouble() ?? 0.0;
    final rawSpawn = (json['expressSpawnCooldown'] as num?)?.toDouble() ?? 28.0;

    return MarketState(
      trends: trends,
      stallCrates: stallCrates,
      pricing:
          enumByNameOrNull(PricingStance.values, json['pricing']) ??
          PricingStance.fair,
      saleCooldown: safeCooldown,
      dailyRequest: parsedRequest,
      sunnySurgeActive: json['sunnySurgeActive'] == true,
      expressOrder: parsedExpress,
      rushSecondsRemaining: (rawRush.isNaN || rawRush.isInfinite)
          ? 0.0
          : rawRush.clamp(0.0, 120.0),
      expressSpawnCooldown: (rawSpawn.isNaN || rawSpawn.isInfinite)
          ? 28.0
          : rawSpawn.clamp(0.0, 180.0),
    );
  }
}
