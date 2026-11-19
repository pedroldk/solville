/// Compile-time flag for paid Desktop / Steam builds (`--dart-define=FULL_EDITION=true`).
const bool kFullEdition = bool.fromEnvironment(
  'FULL_EDITION',
  defaultValue: false,
);

/// Immutable snapshot of the player's monetization entitlements in Solville:
/// - Full Game / Lifetime Cozy Edition (one-time purchase)
/// - Daily "Sunny Surge" boost tracker (free daily claim once Full Game is unlocked)
class EntitlementState {
  const EntitlementState({
    this.hasLifetimePass = false,
    this.lastSunnySurgeDay = 0,
    this.isFullEditionBuild = kFullEdition,
  });

  /// Store product identifier for the one-time Full Game unlock.
  static const String lifetimePassProductId = 'solville_lifetime_cozy';

  /// True when the player owns the one-time Full Game unlock.
  final bool hasLifetimePass;

  /// In-game day number when the daily "Sunny Surge" boost was last activated.
  final int lastSunnySurgeDay;

  /// True when compiled with `--dart-define=FULL_EDITION=true` (e.g. Steam).
  final bool isFullEditionBuild;

  /// True when the player owns the Full Game (via one-time purchase or Steam build).
  bool get isPermanentSupporter => isFullEditionBuild || hasLifetimePass;

  /// True when all Cozy Version crops, structures, animals, and upgrades are unlocked.
  bool isSunPassActive([DateTime? nowUtc]) => isPermanentSupporter;

  /// Whether the daily "Sunny Surge" (instant Sunshower + +25% Market Boost)
  /// is still available to claim on [currentDay].
  ///
  /// Uses inequality (`lastSunnySurgeDay != currentDay`) so starting a fresh
  /// farm (which resets `day` back to `1`) never locks out Sunny Surge.
  bool canClaimSunnySurgeOnDay(int currentDay) =>
      currentDay > 0 && lastSunnySurgeDay != currentDay;

  /// Short status text for the Top HUD pill.
  String statusPillText([DateTime? nowUtc]) =>
      isPermanentSupporter ? 'Cozy Edition' : 'Cozy';

  /// Short status label with emoji.
  String statusPillLabel([DateTime? nowUtc]) =>
      isPermanentSupporter ? '👑 Cozy Edition' : '☀️ Cozy';

  EntitlementState copyWith({
    bool? hasLifetimePass,
    int? lastSunnySurgeDay,
    bool? isFullEditionBuild,
  }) {
    return EntitlementState(
      hasLifetimePass: hasLifetimePass ?? this.hasLifetimePass,
      lastSunnySurgeDay: lastSunnySurgeDay ?? this.lastSunnySurgeDay,
      isFullEditionBuild: isFullEditionBuild ?? this.isFullEditionBuild,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'hasLifetimePass': hasLifetimePass,
    'lastSunnySurgeDay': lastSunnySurgeDay,
  };

  factory EntitlementState.fromJson(Map<String, dynamic> json) {
    final rawSurgeDay = json['lastSunnySurgeDay'];
    return EntitlementState(
      hasLifetimePass:
          json['hasLifetimePass'] == true || json['hasAnnualPass'] == true,
      lastSunnySurgeDay: rawSurgeDay is num ? rawSurgeDay.toInt() : 0,
    );
  }
}
