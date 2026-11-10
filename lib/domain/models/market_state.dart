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

class MarketState {
  MarketState({
    required this.trends,
    required this.stallCrates,
    this.pricing = PricingStance.fair,
    this.saleCooldown = 3.5,
    this.dailyRequest,
    this.sunnySurgeActive = false,
  });

  static const int maxStallSlots = 8;

  final Map<ProductId, MarketTrend> trends;
  final List<ProductId> stallCrates;
  final PricingStance pricing;
  final double saleCooldown;
  final VillageRequest? dailyRequest;

  /// True when the daily "Sunny Surge" (+25% Golden Market Boost) is active today.
  final bool sunnySurgeActive;

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
  }) {
    return MarketState(
      trends: trends ?? this.trends,
      stallCrates: stallCrates ?? this.stallCrates,
      pricing: pricing ?? this.pricing,
      saleCooldown: saleCooldown ?? this.saleCooldown,
      dailyRequest: dailyRequest ?? this.dailyRequest,
      sunnySurgeActive: sunnySurgeActive ?? this.sunnySurgeActive,
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
  };

  factory MarketState.fromJson(Map<String, dynamic> json) {
    final rawTrends = json['trends'] as Map<String, dynamic>? ?? const {};
    return MarketState(
      trends: <ProductId, MarketTrend>{
        for (final entry in rawTrends.entries)
          ProductId.values.byName(entry.key): MarketTrend.values.byName(
            entry.value as String,
          ),
      },
      stallCrates: ((json['stallCrates'] as List<dynamic>?) ?? const [])
          .map((e) => ProductId.values.byName(e as String))
          .toList(),
      pricing: json['pricing'] != null
          ? PricingStance.values.byName(json['pricing'] as String)
          : PricingStance.fair,
      saleCooldown: (json['saleCooldown'] as num?)?.toDouble() ?? 3.5,
      dailyRequest: json['dailyRequest'] != null
          ? VillageRequest.fromJson(
              json['dailyRequest'] as Map<String, dynamic>,
            )
          : null,
      sunnySurgeActive: json['sunnySurgeActive'] as bool? ?? false,
    );
  }
}
