import 'package:flutter/widgets.dart';

import '../domain/models/catalog.dart';
import '../domain/models/entitlement_state.dart';
import '../domain/models/game_state.dart';
import '../domain/models/market_state.dart';
import '../domain/models/solville_toast.dart';
import 'app_localizations.dart';

/// Supported user-selectable locales in Solville.
abstract final class SolvilleLocaleHelper {
  static const Locale enUs = Locale('en', 'US');
  static const Locale enGb = Locale('en', 'GB');
  static const Locale ptPt = Locale('pt', 'PT');
  static const Locale fr = Locale('fr');
  static const Locale es = Locale('es');
  static const Locale de = Locale('de');

  static const List<Locale> selectableLocales = <Locale>[
    enUs,
    enGb,
    ptPt,
    fr,
    es,
    de,
  ];

  static String? toStorageCode(Locale? locale) {
    if (locale == null) return null;
    final country = locale.countryCode;
    if (country == null || country.isEmpty) {
      return locale.languageCode;
    }
    return '${locale.languageCode}_$country';
  }

  static Locale? parseLocaleCode(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final parts = code.split(RegExp(r'[_-]'));
    final lang = parts[0].toLowerCase();
    final country = parts.length > 1 ? parts[1].toUpperCase() : null;
    return switch (lang) {
      'en' => country == 'GB' ? enGb : enUs,
      'pt' => ptPt,
      'fr' => fr,
      'es' => es,
      'de' => de,
      _ => null,
    };
  }

  static Locale resolveLocale(
    Locale? deviceLocale,
    Iterable<Locale> supportedLocales,
  ) {
    if (deviceLocale == null) return enUs;
    final lang = deviceLocale.languageCode.toLowerCase();
    final country = deviceLocale.countryCode?.toUpperCase();
    return switch (lang) {
      'en' => country == 'GB' ? enGb : enUs,
      'pt' => ptPt,
      'fr' => fr,
      'es' => es,
      'de' => de,
      _ => enUs,
    };
  }
}

/// Localized helpers for Solville catalog entries, enums, entitlements, and
/// simulation toast notifications.
extension SolvilleL10nX on AppLocalizations {
  String bgmTrackLabel(BgmTrack track) => switch (track) {
    BgmTrack.sunnyLullaby => bgmSunnyLullaby,
    BgmTrack.morningMeadow => bgmMorningMeadow,
    BgmTrack.cozyRain => bgmCozyRain,
    BgmTrack.off => bgmOff,
  };

  String bgmTrackShortTitle(
    BgmTrack track, {
    required bool compact,
    required bool isMobile,
  }) {
    if (isMobile) return '';
    if (compact) return bgmCompactAudio;
    return switch (track) {
      BgmTrack.sunnyLullaby => bgmShortSunnyLullaby,
      BgmTrack.morningMeadow => bgmShortMorningMeadow,
      BgmTrack.cozyRain => bgmShortCozyRain,
      BgmTrack.off => bgmShortOff,
    };
  }

  /// Strips PC-only hotkey suffix `(Hotkey: H)` on mobile viewports.
  String adaptiveHarvestRipeTooltip({required bool isMobile}) {
    if (!isMobile) return dockHarvestRipeTooltip;
    return dockHarvestRipeTooltip.replaceFirst(
      RegExp(r'\s*\([^)]*\)\s*$'),
      '',
    );
  }

  /// Strips PC-only hotkey suffix `(Space / C)` on mobile viewports.
  String adaptiveCenterCameraTooltip({required bool isMobile}) {
    if (!isMobile) return dockCenterCameraTooltip;
    return dockCenterCameraTooltip.replaceFirst(
      RegExp(r'\s*\([^)]*\)\s*$'),
      '',
    );
  }

  /// Strips PC-only `(press M anytime on PC to cycle)` hint on mobile viewports.
  String adaptiveSoundscapeSubtitle({required bool isMobile}) {
    if (!isMobile) return homesteadSoundscapeSubtitle;
    return homesteadSoundscapeSubtitle.replaceFirst(
      RegExp(r'\s*\([^)]*\)(?=:?\s*$)'),
      '',
    );
  }

  /// Omits PC-only keyboard/mouse lines (such as `Shift + Drag (PC)`) on mobile
  /// viewports so touch players see clean, relevant controls.
  String adaptiveHelpControlsBody({required bool isMobile}) {
    if (!isMobile) return helpSec6Body;
    final lines = helpSec6Body.split('\n');
    final filtered = lines.where((line) {
      final lower = line.toLowerCase();
      return !lower.contains('shift +') &&
          !lower.contains('mayús +') &&
          !lower.contains('maj +');
    }).toList();
    return filtered.join('\n');
  }

  String weatherLabel(WeatherType weather) => switch (weather) {
    WeatherType.sunny => weatherSunny,
    WeatherType.goldenBreeze => weatherGoldenBreeze,
    WeatherType.gentleRain => weatherGentleRain,
  };

  String marketTrendLabel(MarketTrend trend) => switch (trend) {
    MarketTrend.boom => trendBoom,
    MarketTrend.high => trendHigh,
    MarketTrend.steady => trendSteady,
    MarketTrend.surplus => trendSurplus,
  };

  String pricingStanceLabel(PricingStance stance) => switch (stance) {
    PricingStance.bargain => pricingBargain,
    PricingStance.fair => pricingFair,
    PricingStance.premium => pricingPremium,
  };

  String productName(ProductId id) => switch (id) {
    ProductId.tomato => productTomato,
    ProductId.carrot => productCarrot,
    ProductId.strawberry => productStrawberry,
    ProductId.corn => productCorn,
    ProductId.lavender => productLavender,
    ProductId.pumpkin => productPumpkin,
    ProductId.lemon => productLemon,
    ProductId.eggs => productEggs,
    ProductId.honey => productHoney,
    ProductId.milk => productMilk,
    ProductId.preserves => productPreserves,
    ProductId.berryJam => productBerryJam,
    ProductId.villageSalsa => productVillageSalsa,
    ProductId.autumnLatte => productAutumnLatte,
  };

  String productShortName(ProductId id) => switch (id) {
    ProductId.tomato => productShortTomato,
    ProductId.carrot => productShortCarrot,
    ProductId.strawberry => productShortStrawberry,
    ProductId.corn => productShortCorn,
    ProductId.lavender => productShortLavender,
    ProductId.pumpkin => productShortPumpkin,
    _ => productName(id),
  };

  String cropDescription(ProductId id) => switch (id) {
    ProductId.tomato => cropDescTomato,
    ProductId.carrot => cropDescCarrot,
    ProductId.strawberry => cropDescStrawberry,
    ProductId.corn => cropDescCorn,
    ProductId.lavender => cropDescLavender,
    ProductId.pumpkin => cropDescPumpkin,
    _ => '',
  };

  String animalName(AnimalType type) => switch (type) {
    AnimalType.chicken => animalChickenName,
    AnimalType.bee => animalBeeName,
    AnimalType.cow => animalCowName,
  };

  String animalDescription(AnimalType type) => switch (type) {
    AnimalType.chicken => animalChickenDesc,
    AnimalType.bee => animalBeeDesc,
    AnimalType.cow => animalCowDesc,
  };

  String buildItemName(BuildItemType type) => switch (type) {
    BuildItemType.sprinklerRotary => buildSprinklerRotaryName,
    BuildItemType.sprinklerSolar => buildSprinklerSolarName,
    BuildItemType.lemonTree => buildLemonTreeName,
    BuildItemType.artisanPress => buildArtisanPressName,
    BuildItemType.henhouse => buildHenhouseName,
    BuildItemType.beehive => buildBeehiveName,
    BuildItemType.cowPaddock => buildCowPaddockName,
    BuildItemType.stonePath => buildStonePathName,
    BuildItemType.lantern => buildLanternName,
    BuildItemType.flowerArch => buildFlowerArchName,
  };

  String buildItemDescription(BuildItemType type) => switch (type) {
    BuildItemType.sprinklerRotary => buildSprinklerRotaryDesc,
    BuildItemType.sprinklerSolar => buildSprinklerSolarDesc,
    BuildItemType.lemonTree => buildLemonTreeDesc,
    BuildItemType.artisanPress => buildArtisanPressDesc,
    BuildItemType.henhouse => buildHenhouseDesc,
    BuildItemType.beehive => buildBeehiveDesc,
    BuildItemType.cowPaddock => buildCowPaddockDesc,
    BuildItemType.stonePath => buildStonePathDesc,
    BuildItemType.lantern => buildLanternDesc,
    BuildItemType.flowerArch => buildFlowerArchDesc,
  };

  String upgradeName(UpgradeTrack track, int tier) => switch ((track, tier)) {
    (UpgradeTrack.wateringCan, 1) => upgradeWater1Name,
    (UpgradeTrack.wateringCan, _) => upgradeWater2Name,
    (UpgradeTrack.crateStacker, 1) => upgradeCrate1Name,
    (UpgradeTrack.crateStacker, _) => upgradeCrate2Name,
    (UpgradeTrack.gardenBoots, 1) => upgradeBoots1Name,
    (UpgradeTrack.gardenBoots, _) => upgradeBoots2Name,
    (UpgradeTrack.farmExpansion, 1) => upgradeExp1Name,
    (UpgradeTrack.farmExpansion, 2) => upgradeExp2Name,
    (UpgradeTrack.farmExpansion, 3) => upgradeExp3Name,
    (UpgradeTrack.farmExpansion, 4) => upgradeExp4Name,
    (UpgradeTrack.farmExpansion, 5) => upgradeExp5Name,
    (UpgradeTrack.farmExpansion, _) => upgradeExpNName(tier),
  };

  String upgradeDescription(UpgradeTrack track, int tier) {
    if (track == UpgradeTrack.farmExpansion) {
      final fromSize = SolvilleCatalog.gridSizeForExpansionTier(tier - 1);
      final toSize = SolvilleCatalog.gridSizeForExpansionTier(tier);
      final addedTiles = toSize * toSize - fromSize * fromSize;
      return upgradeExpDesc(fromSize, toSize, addedTiles);
    }
    return switch ((track, tier)) {
      (UpgradeTrack.wateringCan, 1) => upgradeWater1Desc,
      (UpgradeTrack.wateringCan, _) => upgradeWater2Desc,
      (UpgradeTrack.crateStacker, 1) => upgradeCrate1Desc,
      (UpgradeTrack.crateStacker, _) => upgradeCrate2Desc,
      (UpgradeTrack.gardenBoots, 1) => upgradeBoots1Desc,
      (UpgradeTrack.gardenBoots, _) => upgradeBoots2Desc,
      _ => '',
    };
  }

  String upgradeMaxedTitle(UpgradeTrack track, int maxGrid) => switch (track) {
    UpgradeTrack.wateringCan => upgradeWaterMaxed,
    UpgradeTrack.crateStacker => upgradeCrateMaxed,
    UpgradeTrack.gardenBoots => upgradeBootsMaxed,
    UpgradeTrack.farmExpansion => upgradeExpMaxed(maxGrid),
  };

  String trophyTitle(String id) => switch (id) {
    'first_sprout' => trophyFirstSproutTitle,
    'market_debut' => trophyMarketDebutTitle,
    'green_thumb' => trophyGreenThumbTitle,
    'hydration_hero' => trophyHydrationHeroTitle,
    'stack_master' => trophyStackMasterTitle,
    'feathered_friends' => trophyFeatheredFriendsTitle,
    'sweet_harmony' => trophySweetHarmonyTitle,
    'dairy_delight' => trophyDairyDelightTitle,
    'savvy_trader' => trophySavvyTraderTitle,
    'master_composter' => trophyMasterComposterTitle,
    'village_darling' => trophyVillageDarlingTitle,
    'golden_oasis' => trophyGoldenOasisTitle,
    _ => id,
  };

  String trophyDescription(String id) => switch (id) {
    'first_sprout' => trophyFirstSproutDesc,
    'market_debut' => trophyMarketDebutDesc,
    'green_thumb' => trophyGreenThumbDesc,
    'hydration_hero' => trophyHydrationHeroDesc,
    'stack_master' => trophyStackMasterDesc,
    'feathered_friends' => trophyFeatheredFriendsDesc,
    'sweet_harmony' => trophySweetHarmonyDesc,
    'dairy_delight' => trophyDairyDelightDesc,
    'savvy_trader' => trophySavvyTraderDesc,
    'master_composter' => trophyMasterComposterDesc,
    'village_darling' => trophyVillageDarlingDesc,
    'golden_oasis' => trophyGoldenOasisDesc,
    _ => '',
  };

  String villagerName(String rawName) => switch (rawName) {
    'Baker Mateo' => villagerBakerMateo,
    'Chef Clara' => villagerChefClara,
    'Florist Mina' => villagerFloristMina,
    'Grandpa Leo' => villagerGrandpaLeo,
    'Mayor Sunny' => villagerMayorSunny,
    _ => rawName,
  };

  String formatDuration(Duration rem) {
    if (rem <= Duration.zero) return entitlementExpired;
    final totalMinutes = (rem.inSeconds / 60).ceil();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return entitlementTimeHoursMinutes(
        hours,
        minutes.toString().padLeft(2, '0'),
      );
    }
    return entitlementTimeMinutes(minutes);
  }

  String entitlementStatusPillText(EntitlementState ent, DateTime nowUtc) {
    if (ent.hasLifetimePass || ent.isFullEditionBuild) {
      return entitlementCozyEdition;
    }
    if (ent.hasAnnualPass) return entitlementSunPassVip;
    if (ent.isSunPassActive(nowUtc)) {
      return entitlementPassRemaining(
        formatDuration(ent.remainingAdPassDuration(nowUtc)),
      );
    }
    return entitlementSunPass;
  }

  String resolveToast(SolvilleToast toast) {
    switch (toast.kind) {
      case SolvilleToastKind.sunnySurge:
        return toastSunnySurge;
      case SolvilleToastKind.actionQueueFull:
        return toastActionQueueFull;
      case SolvilleToastKind.noHarvestsReady:
        return toastNoHarvestsReady;
      case SolvilleToastKind.queuedHarvests:
        return toastQueuedHarvests(toast.count ?? 0);
      case SolvilleToastKind.allCropsHydrated:
        return toastAllCropsHydrated;
      case SolvilleToastKind.queuedWatering:
        return toastQueuedWatering(toast.count ?? 0);
      case SolvilleToastKind.stallFull:
        return toastStallFull;
      case SolvilleToastKind.needCoinsSeedLicense:
        return toastNeedCoinsSeedLicense;
      case SolvilleToastKind.unlockedSeeds:
        return toastUnlockedSeeds(productName(toast.product!));
      case SolvilleToastKind.needCoinsForUpgrade:
        return toastNeedCoinsForUpgrade(
          toast.cost ?? 0,
          upgradeName(toast.upgradeTrack!, toast.tier ?? 1),
          toast.coins ?? 0,
        );
      case SolvilleToastKind.expandedIsle:
        return toastExpandedIsle(
          upgradeName(toast.upgradeTrack!, toast.tier ?? 1),
          toast.gridSize ?? 11,
        );
      case SolvilleToastKind.purchasedUpgrade:
        return toastPurchasedUpgrade(
          upgradeName(toast.upgradeTrack!, toast.tier ?? 1),
        );
      case SolvilleToastKind.newDay:
        return toastNewDay(
          toast.day ?? 1,
          weatherLabel(toast.weather ?? WeatherType.sunny),
        );
      case SolvilleToastKind.pathBlocked:
        return toastPathBlocked;
      case SolvilleToastKind.waterRefilled:
        return toastWaterRefilled;
      case SolvilleToastKind.needCoinsForSeed:
        return toastNeedCoinsForSeed(
          toast.cost ?? 0,
          productName(toast.product!),
        );
      case SolvilleToastKind.needCoinsForCompost:
        return toastNeedCoinsForCompost(toast.cost ?? 0);
      case SolvilleToastKind.simmeringPreserves:
        return toastSimmeringPreserves;
      case SolvilleToastKind.handsFull:
        return toastHandsFull;
      case SolvilleToastKind.harvestCratesFirst:
        return toastHarvestCratesFirst;
      case SolvilleToastKind.storedInBarn:
        return toastStoredInBarn;
      case SolvilleToastKind.needCoinsForFeed:
        return toastNeedCoinsForFeed(toast.cost ?? 0);
      case SolvilleToastKind.fedAnimal:
        return toastFedAnimal(animalName(toast.animal!));
      case SolvilleToastKind.needCoinsForBuild:
        return toastNeedCoinsForBuild(
          toast.cost ?? 0,
          buildItemName(toast.buildItem!),
        );
      case SolvilleToastKind.placedBuild:
        return toastPlacedBuild(buildItemName(toast.buildItem!));
      case SolvilleToastKind.villageGrant:
        return toastVillageGrant;
      case SolvilleToastKind.villagerOrderComplete:
        return toastVillagerOrderComplete(
          villagerName(toast.villagerName ?? ''),
          toast.coins ?? 0,
        );
      case SolvilleToastKind.soldCrate:
        return toastSoldCrate(
          SolvilleCatalog.productEmoji(toast.product!),
          toast.coins ?? 0,
        );
      case SolvilleToastKind.trophyUnlocked:
        return toastTrophyUnlocked(
          trophyTitle(toast.trophyId ?? ''),
          toast.coins ?? 0,
        );
      case SolvilleToastKind.welcomeBack:
        return toastWelcomeBack(toast.day ?? 1, toast.gridSize ?? 11);
      case SolvilleToastKind.welcomeNew:
        return toastWelcomeNew;
      case SolvilleToastKind.sunPassEnded:
        return toastSunPassEnded;
      case SolvilleToastKind.queuedUntill:
        return toastQueuedUntill(toast.x ?? 0, toast.y ?? 0);
      case SolvilleToastKind.sunPassRequiredSeed:
        return toastPromptSunPass(
          toastPromptSunPassSeeds(productName(toast.product!)),
        );
      case SolvilleToastKind.sunPassRequiredSeedLicense:
        return toastPromptSunPass(
          toastPromptSunPassLicense(productName(toast.product!)),
        );
      case SolvilleToastKind.sunPassRequiredBuild:
        return toastPromptSunPass(buildItemName(toast.buildItem!));
      case SolvilleToastKind.sunPassRequiredUpgrade:
        return toastPromptSunPass(
          upgradeName(toast.upgradeTrack!, toast.tier ?? 1),
        );
      case SolvilleToastKind.sunPassMaxed:
        return toastSunPassMaxed;
      case SolvilleToastKind.adCancelled:
        return toastAdCancelled;
      case SolvilleToastKind.sunPassUnlocked:
        return toastSunPassUnlocked(
          formatDuration(toast.duration ?? Duration.zero),
        );
      case SolvilleToastKind.sunnySurgeAlreadyActive:
        return toastSunnySurgeAlreadyActive(toast.day ?? 1);
      case SolvilleToastKind.adCancelledSurge:
        return toastAdCancelledSurge;
      case SolvilleToastKind.purchaseCancelled:
        return toastPurchaseCancelled;
      case SolvilleToastKind.annualPassActivated:
        return toastAnnualPassActivated;
      case SolvilleToastKind.lifetimePassActivated:
        return toastLifetimePassActivated;
      case SolvilleToastKind.purchasesRestored:
        return toastPurchasesRestored;
      case SolvilleToastKind.noPreviousPurchases:
        return toastNoPreviousPurchases;
      case SolvilleToastKind.ambienceChanged:
        return toastAmbienceChanged(
          bgmTrackLabel(toast.bgmTrack ?? BgmTrack.sunnyLullaby),
        );
      case SolvilleToastKind.farmSaved:
        return toastFarmSaved;
      case SolvilleToastKind.startedFreshFarm:
        return toastStartedFreshFarm;
      case SolvilleToastKind.expressOrderComplete:
        return toastExpressOrderComplete(
          villagerName(toast.villagerName ?? ''),
          toast.coins ?? 0,
        );
      case SolvilleToastKind.landmarkDiscovered:
        return toastLandmarkDiscovered(toast.coins ?? 0);
      case SolvilleToastKind.goldenHarvest:
        return toastGoldenHarvest;
      case SolvilleToastKind.villageRushStarted:
        return toastVillageRushStarted;
    }
  }
}
