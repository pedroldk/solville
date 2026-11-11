/// Compile-time flag for paid Desktop / Steam builds (`--dart-define=FULL_EDITION=true`).
const bool kFullEdition = bool.fromEnvironment(
  'FULL_EDITION',
  defaultValue: false,
);

/// Immutable snapshot of the player's monetization entitlements in Solville:
/// - Stackable Rewarded Ad Pass (+24h per ad, up to 48h max)
/// - Annual Sun Pass Subscription (2,99€ / year)
/// - Lifetime Cozy Edition (4,99€ one-time)
/// - Daily "Sunny Surge" boost tracker (free daily claim for subscribers/lifetime,
///   or 1 optional rewarded ad for free players)
class EntitlementState {
  const EntitlementState({
    this.adPassExpiresAtUtc,
    this.hasAnnualPass = false,
    this.hasLifetimePass = false,
    this.lastSunnySurgeDay = 0,
    this.isFullEditionBuild = kFullEdition,
  });

  /// Duration granted by watching a single rewarded video ad.
  static const Duration singleAdGrantDuration = Duration(hours: 24);

  /// Maximum total duration that can be stacked by watching ads back-to-back.
  static const Duration maxStackedAdDuration = Duration(hours: 48);

  /// Store product identifier for the 2,99€/year subscription.
  static const String annualPassProductId = 'solville_sun_pass_yearly';

  /// Store product identifier for the 4,99€ one-time Lifetime Cozy Edition.
  static const String lifetimePassProductId = 'solville_lifetime_cozy';

  /// Display price for the annual subscription.
  static const String annualPassPriceLabel = '2,99€ / year';

  /// Display price for the one-time lifetime unlock.
  static const String lifetimePassPriceLabel = '4,99€';

  /// UTC expiration timestamp for the stackable 24h–48h ad pass.
  final DateTime? adPassExpiresAtUtc;

  /// True when the player has an active 2,99€/year Sun Pass subscription.
  final bool hasAnnualPass;

  /// True when the player owns the 4,99€ Lifetime Cozy Edition.
  final bool hasLifetimePass;

  /// In-game day number when the daily "Sunny Surge" boost was last activated.
  final int lastSunnySurgeDay;

  /// True when compiled with `--dart-define=FULL_EDITION=true` (e.g. Steam).
  final bool isFullEditionBuild;

  /// True when the player has a permanent or subscription unlock (no ad timer needed).
  bool get isPermanentSupporter =>
      isFullEditionBuild || hasAnnualPass || hasLifetimePass;

  /// True when all Sun Pass crops, structures, animals, and upgrades are unlocked.
  bool isSunPassActive([DateTime? nowUtc]) {
    if (isPermanentSupporter) return true;
    final exp = adPassExpiresAtUtc;
    if (exp == null) return false;
    final ref = (nowUtc ?? DateTime.now()).toUtc();
    return exp.isAfter(ref);
  }

  /// Remaining time on the Rewarded Ad Pass (`Duration.zero` if expired).
  Duration remainingAdPassDuration([DateTime? nowUtc]) {
    final exp = adPassExpiresAtUtc;
    if (exp == null) return Duration.zero;
    final ref = (nowUtc ?? DateTime.now()).toUtc();
    final diff = exp.difference(ref);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// True when the player can watch another ad to extend their timer (up to 48h cap).
  ///
  /// Allows stacking a 2nd ad back-to-back when remaining time is under 47h 55m.
  bool canStackAnotherAd([DateTime? nowUtc]) {
    if (isPermanentSupporter) return false;
    final remaining = remainingAdPassDuration(nowUtc);
    return remaining < maxStackedAdDuration - const Duration(minutes: 5);
  }

  /// Grants +24 hours of Sun Pass access, stacking on top of any active timer
  /// up to the 48-hour maximum cap.
  EntitlementState grantRewardedAdPass([DateTime? nowUtc]) {
    final ref = (nowUtc ?? DateTime.now()).toUtc();
    final currentExpiry = adPassExpiresAtUtc;
    final baseTime = (currentExpiry != null && currentExpiry.isAfter(ref))
        ? currentExpiry
        : ref;
    final uncapped = baseTime.add(singleAdGrantDuration);
    final maxAllowed = ref.add(maxStackedAdDuration);
    final nextExpiry = uncapped.isAfter(maxAllowed) ? maxAllowed : uncapped;
    return copyWith(adPassExpiresAtUtc: nextExpiry);
  }

  /// Whether the daily "Sunny Surge" (instant Sunshower + +25% Market Boost)
  /// is still available to claim on [currentDay].
  ///
  /// Uses inequality (`lastSunnySurgeDay != currentDay`) so starting a fresh
  /// farm (which resets `day` back to `1`) never locks out Sunny Surge.
  bool canClaimSunnySurgeOnDay(int currentDay) =>
      currentDay > 0 && lastSunnySurgeDay != currentDay;

  /// Formats remaining ad pass duration cleanly (e.g. `47h 59m`, `23h 14m`, `42m`).
  String formatRemainingTime([DateTime? nowUtc]) {
    final rem = remainingAdPassDuration(nowUtc);
    if (rem <= Duration.zero) return 'Expired';
    final totalMinutes = (rem.inSeconds / 60).ceil();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes}m';
  }

  /// Short status text for the Top HUD pill (paired with its emoji).
  String statusPillText([DateTime? nowUtc]) {
    if (hasLifetimePass || isFullEditionBuild) return 'Cozy Edition';
    if (hasAnnualPass) return 'Sun Pass VIP';
    if (isSunPassActive(nowUtc)) {
      return 'Pass ${formatRemainingTime(nowUtc)}';
    }
    return 'Sun Pass';
  }

  /// Short status label with emoji.
  String statusPillLabel([DateTime? nowUtc]) {
    if (hasLifetimePass || isFullEditionBuild) return '👑 Cozy Edition';
    if (hasAnnualPass) return '🌻 Sun Pass VIP';
    if (isSunPassActive(nowUtc)) {
      return '☀️ Pass ${formatRemainingTime(nowUtc)}';
    }
    return '☀️ Sun Pass';
  }

  EntitlementState copyWith({
    DateTime? adPassExpiresAtUtc,
    bool clearAdPassExpiry = false,
    bool? hasAnnualPass,
    bool? hasLifetimePass,
    int? lastSunnySurgeDay,
    bool? isFullEditionBuild,
  }) {
    return EntitlementState(
      adPassExpiresAtUtc: clearAdPassExpiry
          ? null
          : (adPassExpiresAtUtc ?? this.adPassExpiresAtUtc),
      hasAnnualPass: hasAnnualPass ?? this.hasAnnualPass,
      hasLifetimePass: hasLifetimePass ?? this.hasLifetimePass,
      lastSunnySurgeDay: lastSunnySurgeDay ?? this.lastSunnySurgeDay,
      isFullEditionBuild: isFullEditionBuild ?? this.isFullEditionBuild,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (adPassExpiresAtUtc != null)
      'adPassExpiresAtUtc': adPassExpiresAtUtc!.toUtc().toIso8601String(),
    'hasAnnualPass': hasAnnualPass,
    'hasLifetimePass': hasLifetimePass,
    'lastSunnySurgeDay': lastSunnySurgeDay,
  };

  factory EntitlementState.fromJson(Map<String, dynamic> json) {
    final rawExpiry = json['adPassExpiresAtUtc'];
    final rawSurgeDay = json['lastSunnySurgeDay'];
    return EntitlementState(
      adPassExpiresAtUtc: rawExpiry is String
          ? DateTime.tryParse(rawExpiry)?.toUtc()
          : null,
      hasAnnualPass: json['hasAnnualPass'] == true,
      hasLifetimePass: json['hasLifetimePass'] == true,
      lastSunnySurgeDay: rawSurgeDay is num ? rawSurgeDay.toInt() : 0,
    );
  }
}
