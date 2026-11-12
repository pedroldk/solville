import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('en', 'GB'),
    Locale('en', 'US'),
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
    Locale('pt', 'PT'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Solville'**
  String get appTitle;

  /// No description provided for @bgmSunnyLullaby.
  ///
  /// In en, this message translates to:
  /// **'🎸 Sunlit Lullaby'**
  String get bgmSunnyLullaby;

  /// No description provided for @bgmMorningMeadow.
  ///
  /// In en, this message translates to:
  /// **'🐦 Meadow Breeze'**
  String get bgmMorningMeadow;

  /// No description provided for @bgmCozyRain.
  ///
  /// In en, this message translates to:
  /// **'🌧️ Cozy Rain'**
  String get bgmCozyRain;

  /// No description provided for @bgmOff.
  ///
  /// In en, this message translates to:
  /// **'🔇 Music Off'**
  String get bgmOff;

  /// No description provided for @bgmShortSunnyLullaby.
  ///
  /// In en, this message translates to:
  /// **'Lullaby'**
  String get bgmShortSunnyLullaby;

  /// No description provided for @bgmShortMorningMeadow.
  ///
  /// In en, this message translates to:
  /// **'Meadow'**
  String get bgmShortMorningMeadow;

  /// No description provided for @bgmShortCozyRain.
  ///
  /// In en, this message translates to:
  /// **'Cozy Rain'**
  String get bgmShortCozyRain;

  /// No description provided for @bgmShortOff.
  ///
  /// In en, this message translates to:
  /// **'Music Off'**
  String get bgmShortOff;

  /// No description provided for @bgmCompactAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get bgmCompactAudio;

  /// No description provided for @weatherSunny.
  ///
  /// In en, this message translates to:
  /// **'☀️ Sunny'**
  String get weatherSunny;

  /// No description provided for @weatherGoldenBreeze.
  ///
  /// In en, this message translates to:
  /// **'🌤️ Warm Breeze'**
  String get weatherGoldenBreeze;

  /// No description provided for @weatherGentleRain.
  ///
  /// In en, this message translates to:
  /// **'🌧️ Sunshower (Auto-Water!)'**
  String get weatherGentleRain;

  /// No description provided for @trendBoom.
  ///
  /// In en, this message translates to:
  /// **'🔥 Boom +45%'**
  String get trendBoom;

  /// No description provided for @trendHigh.
  ///
  /// In en, this message translates to:
  /// **'▲ High +20%'**
  String get trendHigh;

  /// No description provided for @trendSteady.
  ///
  /// In en, this message translates to:
  /// **'• Steady'**
  String get trendSteady;

  /// No description provided for @trendSurplus.
  ///
  /// In en, this message translates to:
  /// **'▽ Surplus -15%'**
  String get trendSurplus;

  /// No description provided for @pricingBargain.
  ///
  /// In en, this message translates to:
  /// **'Bargain (-10%, Fast Sales)'**
  String get pricingBargain;

  /// No description provided for @pricingFair.
  ///
  /// In en, this message translates to:
  /// **'Fair Price (Balanced)'**
  String get pricingFair;

  /// No description provided for @pricingPremium.
  ///
  /// In en, this message translates to:
  /// **'Boutique (+15%, Slower)'**
  String get pricingPremium;

  /// No description provided for @toolSmart.
  ///
  /// In en, this message translates to:
  /// **'Smart'**
  String get toolSmart;

  /// No description provided for @toolDig.
  ///
  /// In en, this message translates to:
  /// **'Dig'**
  String get toolDig;

  /// No description provided for @toolSeed.
  ///
  /// In en, this message translates to:
  /// **'Seeds'**
  String get toolSeed;

  /// No description provided for @toolWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get toolWater;

  /// No description provided for @toolCompost.
  ///
  /// In en, this message translates to:
  /// **'Compost'**
  String get toolCompost;

  /// No description provided for @toolBuild.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get toolBuild;

  /// No description provided for @toolRemove.
  ///
  /// In en, this message translates to:
  /// **'Untill'**
  String get toolRemove;

  /// No description provided for @toolRemoveSub.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get toolRemoveSub;

  /// No description provided for @productTomato.
  ///
  /// In en, this message translates to:
  /// **'Sunripe Tomato'**
  String get productTomato;

  /// No description provided for @productCarrot.
  ///
  /// In en, this message translates to:
  /// **'Crisp Carrot'**
  String get productCarrot;

  /// No description provided for @productStrawberry.
  ///
  /// In en, this message translates to:
  /// **'Sweet Strawberry'**
  String get productStrawberry;

  /// No description provided for @productCorn.
  ///
  /// In en, this message translates to:
  /// **'Golden Corn'**
  String get productCorn;

  /// No description provided for @productLavender.
  ///
  /// In en, this message translates to:
  /// **'Fragrant Lavender'**
  String get productLavender;

  /// No description provided for @productPumpkin.
  ///
  /// In en, this message translates to:
  /// **'Solville Pumpkin'**
  String get productPumpkin;

  /// No description provided for @productLemon.
  ///
  /// In en, this message translates to:
  /// **'Sunburst Lemons'**
  String get productLemon;

  /// No description provided for @productEggs.
  ///
  /// In en, this message translates to:
  /// **'Fresh Eggs'**
  String get productEggs;

  /// No description provided for @productHoney.
  ///
  /// In en, this message translates to:
  /// **'Wildflower Honey'**
  String get productHoney;

  /// No description provided for @productMilk.
  ///
  /// In en, this message translates to:
  /// **'Creamy Milk'**
  String get productMilk;

  /// No description provided for @productPreserves.
  ///
  /// In en, this message translates to:
  /// **'Artisan Preserves'**
  String get productPreserves;

  /// No description provided for @productShortTomato.
  ///
  /// In en, this message translates to:
  /// **'Tomato'**
  String get productShortTomato;

  /// No description provided for @productShortCarrot.
  ///
  /// In en, this message translates to:
  /// **'Carrot'**
  String get productShortCarrot;

  /// No description provided for @productShortStrawberry.
  ///
  /// In en, this message translates to:
  /// **'Strawberry'**
  String get productShortStrawberry;

  /// No description provided for @productShortCorn.
  ///
  /// In en, this message translates to:
  /// **'Corn'**
  String get productShortCorn;

  /// No description provided for @productShortLavender.
  ///
  /// In en, this message translates to:
  /// **'Lavender'**
  String get productShortLavender;

  /// No description provided for @productShortPumpkin.
  ///
  /// In en, this message translates to:
  /// **'Pumpkin'**
  String get productShortPumpkin;

  /// No description provided for @cropDescTomato.
  ///
  /// In en, this message translates to:
  /// **'Juicy starter vine! Yields 3 harvests before replanting.'**
  String get cropDescTomato;

  /// No description provided for @cropDescCarrot.
  ///
  /// In en, this message translates to:
  /// **'Fast-growing root crop with light water needs.'**
  String get cropDescCarrot;

  /// No description provided for @cropDescStrawberry.
  ///
  /// In en, this message translates to:
  /// **'Lush berry bush producing 3 sweet harvests.'**
  String get cropDescStrawberry;

  /// No description provided for @cropDescCorn.
  ///
  /// In en, this message translates to:
  /// **'Tall sunlit stalks yielding hearty, high-value crates.'**
  String get cropDescCorn;

  /// No description provided for @cropDescLavender.
  ///
  /// In en, this message translates to:
  /// **'Drought-hardy blooms! Boosts nearby Beehives by +35% speed.'**
  String get cropDescLavender;

  /// No description provided for @cropDescPumpkin.
  ///
  /// In en, this message translates to:
  /// **'Prized gourmet harvest with massive Market Boom payouts.'**
  String get cropDescPumpkin;

  /// No description provided for @animalChickenName.
  ///
  /// In en, this message translates to:
  /// **'Cozy Henhouse'**
  String get animalChickenName;

  /// No description provided for @animalChickenDesc.
  ///
  /// In en, this message translates to:
  /// **'Happy hens lay crates of Fresh Eggs when fed grain.'**
  String get animalChickenDesc;

  /// No description provided for @animalBeeName.
  ///
  /// In en, this message translates to:
  /// **'Wildflower Apiary'**
  String get animalBeeName;

  /// No description provided for @animalBeeDesc.
  ///
  /// In en, this message translates to:
  /// **'Gentle honeybees craft Wildflower Honey; faster near blooms!'**
  String get animalBeeDesc;

  /// No description provided for @animalCowName.
  ///
  /// In en, this message translates to:
  /// **'Sunny Paddock'**
  String get animalCowName;

  /// No description provided for @animalCowDesc.
  ///
  /// In en, this message translates to:
  /// **'Contented dairy cow producing rich, top-value Creamy Milk.'**
  String get animalCowDesc;

  /// No description provided for @buildSprinklerRotaryName.
  ///
  /// In en, this message translates to:
  /// **'Rotary Sprinkler'**
  String get buildSprinklerRotaryName;

  /// No description provided for @buildSprinklerRotaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically waters all 8 surrounding plots (3x3).'**
  String get buildSprinklerRotaryDesc;

  /// No description provided for @buildSprinklerSolarName.
  ///
  /// In en, this message translates to:
  /// **'Solar Mist Tower'**
  String get buildSprinklerSolarName;

  /// No description provided for @buildSprinklerSolarDesc.
  ///
  /// In en, this message translates to:
  /// **'Waters a lush 5x5 garden zone with golden solar mist.'**
  String get buildSprinklerSolarDesc;

  /// No description provided for @buildLemonTreeName.
  ///
  /// In en, this message translates to:
  /// **'Sunburst Lemon Tree'**
  String get buildLemonTreeName;

  /// No description provided for @buildLemonTreeDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanent orchard tree! Passively grows crates of Lemons.'**
  String get buildLemonTreeDesc;

  /// No description provided for @buildArtisanPressName.
  ///
  /// In en, this message translates to:
  /// **'Artisan Kettle'**
  String get buildArtisanPressName;

  /// No description provided for @buildArtisanPressDesc.
  ///
  /// In en, this message translates to:
  /// **'Simmers carried or Barn fruit/crops into 96☀️ Preserves!'**
  String get buildArtisanPressDesc;

  /// No description provided for @buildHenhouseName.
  ///
  /// In en, this message translates to:
  /// **'Cozy Henhouse'**
  String get buildHenhouseName;

  /// No description provided for @buildHenhouseDesc.
  ///
  /// In en, this message translates to:
  /// **'Home for happy egg-laying chickens.'**
  String get buildHenhouseDesc;

  /// No description provided for @buildBeehiveName.
  ///
  /// In en, this message translates to:
  /// **'Wildflower Apiary'**
  String get buildBeehiveName;

  /// No description provided for @buildBeehiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Produces honey passively; loves nearby Lavender!'**
  String get buildBeehiveDesc;

  /// No description provided for @buildCowPaddockName.
  ///
  /// In en, this message translates to:
  /// **'Sunny Paddock'**
  String get buildCowPaddockName;

  /// No description provided for @buildCowPaddockDesc.
  ///
  /// In en, this message translates to:
  /// **'Lush mini-pasture for a prized dairy cow.'**
  String get buildCowPaddockDesc;

  /// No description provided for @buildStonePathName.
  ///
  /// In en, this message translates to:
  /// **'Sunstone Path'**
  String get buildStonePathName;

  /// No description provided for @buildStonePathDesc.
  ///
  /// In en, this message translates to:
  /// **'Warm garden paving: +40% farmer walking speed!'**
  String get buildStonePathDesc;

  /// No description provided for @buildLanternName.
  ///
  /// In en, this message translates to:
  /// **'Solar Lantern'**
  String get buildLanternName;

  /// No description provided for @buildLanternDesc.
  ///
  /// In en, this message translates to:
  /// **'Warm dusk glow + +3% Market Charm price bonus.'**
  String get buildLanternDesc;

  /// No description provided for @buildFlowerArchName.
  ///
  /// In en, this message translates to:
  /// **'Blossom Arch'**
  String get buildFlowerArchName;

  /// No description provided for @buildFlowerArchDesc.
  ///
  /// In en, this message translates to:
  /// **'Walkable floral arch + +6% Market Charm price bonus.'**
  String get buildFlowerArchDesc;

  /// No description provided for @upgradeWater1Name.
  ///
  /// In en, this message translates to:
  /// **'Copper Watering Can'**
  String get upgradeWater1Name;

  /// No description provided for @upgradeWater1Desc.
  ///
  /// In en, this message translates to:
  /// **'Doubles water capacity from 5 to 10 charges per refill.'**
  String get upgradeWater1Desc;

  /// No description provided for @upgradeWater2Name.
  ///
  /// In en, this message translates to:
  /// **'Solar Mist Jug'**
  String get upgradeWater2Name;

  /// No description provided for @upgradeWater2Desc.
  ///
  /// In en, this message translates to:
  /// **'Holds 18 water charges and hydrates adjacent dry sprouts!'**
  String get upgradeWater2Desc;

  /// No description provided for @upgradeCrate1Name.
  ///
  /// In en, this message translates to:
  /// **'Crate Stacker Gloves'**
  String get upgradeCrate1Name;

  /// No description provided for @upgradeCrate1Desc.
  ///
  /// In en, this message translates to:
  /// **'Carry 2 stacked produce crates at once!'**
  String get upgradeCrate1Desc;

  /// No description provided for @upgradeCrate2Name.
  ///
  /// In en, this message translates to:
  /// **'Master Stacker Harness'**
  String get upgradeCrate2Name;

  /// No description provided for @upgradeCrate2Desc.
  ///
  /// In en, this message translates to:
  /// **'Carry up to 4 stacked crates in a single market trip!'**
  String get upgradeCrate2Desc;

  /// No description provided for @upgradeBoots1Name.
  ///
  /// In en, this message translates to:
  /// **'Breezy Canvas Boots'**
  String get upgradeBoots1Name;

  /// No description provided for @upgradeBoots1Desc.
  ///
  /// In en, this message translates to:
  /// **'+28% walking speed across the farm.'**
  String get upgradeBoots1Desc;

  /// No description provided for @upgradeBoots2Name.
  ///
  /// In en, this message translates to:
  /// **'Sunrunner Boots'**
  String get upgradeBoots2Name;

  /// No description provided for @upgradeBoots2Desc.
  ///
  /// In en, this message translates to:
  /// **'+55% walking speed — glide from garden to stall!'**
  String get upgradeBoots2Desc;

  /// No description provided for @upgradeExp1Name.
  ///
  /// In en, this message translates to:
  /// **'Sunny Meadow Deed'**
  String get upgradeExp1Name;

  /// No description provided for @upgradeExp2Name.
  ///
  /// In en, this message translates to:
  /// **'Golden Orchard Charter'**
  String get upgradeExp2Name;

  /// No description provided for @upgradeExp3Name.
  ///
  /// In en, this message translates to:
  /// **'Breezy Hilltop Grant'**
  String get upgradeExp3Name;

  /// No description provided for @upgradeExp4Name.
  ///
  /// In en, this message translates to:
  /// **'Sunlit Peninsula Deed'**
  String get upgradeExp4Name;

  /// No description provided for @upgradeExp5Name.
  ///
  /// In en, this message translates to:
  /// **'Emerald Cove Charter'**
  String get upgradeExp5Name;

  /// No description provided for @upgradeExpNName.
  ///
  /// In en, this message translates to:
  /// **'Grand Archipelago Deed {tier}'**
  String upgradeExpNName(int tier);

  /// No description provided for @upgradeExpDesc.
  ///
  /// In en, this message translates to:
  /// **'Expands the Solville isle from {fromSize}×{fromSize} to {toSize}×{toSize} (+{addedTiles} tiles)!'**
  String upgradeExpDesc(int fromSize, int toSize, int addedTiles);

  /// No description provided for @upgradeWaterMaxed.
  ///
  /// In en, this message translates to:
  /// **'Solar Mist Jug (Maxed)'**
  String get upgradeWaterMaxed;

  /// No description provided for @upgradeCrateMaxed.
  ///
  /// In en, this message translates to:
  /// **'Master Stacker Harness (Maxed)'**
  String get upgradeCrateMaxed;

  /// No description provided for @upgradeBootsMaxed.
  ///
  /// In en, this message translates to:
  /// **'Sunrunner Boots (Maxed)'**
  String get upgradeBootsMaxed;

  /// No description provided for @upgradeExpMaxed.
  ///
  /// In en, this message translates to:
  /// **'Grand Archipelago Estate ({maxGrid}×{maxGrid} Maxed)'**
  String upgradeExpMaxed(int maxGrid);

  /// No description provided for @trophyFirstSproutTitle.
  ///
  /// In en, this message translates to:
  /// **'First Harvest'**
  String get trophyFirstSproutTitle;

  /// No description provided for @trophyFirstSproutDesc.
  ///
  /// In en, this message translates to:
  /// **'Harvest your very first crate of Solville produce.'**
  String get trophyFirstSproutDesc;

  /// No description provided for @trophyMarketDebutTitle.
  ///
  /// In en, this message translates to:
  /// **'Open for Business'**
  String get trophyMarketDebutTitle;

  /// No description provided for @trophyMarketDebutDesc.
  ///
  /// In en, this message translates to:
  /// **'Earn 100 lifetime Sols selling at the Market Stall.'**
  String get trophyMarketDebutDesc;

  /// No description provided for @trophyGreenThumbTitle.
  ///
  /// In en, this message translates to:
  /// **'Greenfingers Apprentice'**
  String get trophyGreenThumbTitle;

  /// No description provided for @trophyGreenThumbDesc.
  ///
  /// In en, this message translates to:
  /// **'Harvest 25 crates of crops or artisan goods.'**
  String get trophyGreenThumbDesc;

  /// No description provided for @trophyHydrationHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Rainmaker'**
  String get trophyHydrationHeroTitle;

  /// No description provided for @trophyHydrationHeroDesc.
  ///
  /// In en, this message translates to:
  /// **'Install your first automated Sprinkler on the farm.'**
  String get trophyHydrationHeroDesc;

  /// No description provided for @trophyStackMasterTitle.
  ///
  /// In en, this message translates to:
  /// **'Crate Juggler'**
  String get trophyStackMasterTitle;

  /// No description provided for @trophyStackMasterDesc.
  ///
  /// In en, this message translates to:
  /// **'Carry 2 or more stacked crates at the same time.'**
  String get trophyStackMasterDesc;

  /// No description provided for @trophyFeatheredFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Morning Clucks'**
  String get trophyFeatheredFriendsTitle;

  /// No description provided for @trophyFeatheredFriendsDesc.
  ///
  /// In en, this message translates to:
  /// **'Collect a crate of Fresh Eggs from a Cozy Henhouse.'**
  String get trophyFeatheredFriendsDesc;

  /// No description provided for @trophySweetHarmonyTitle.
  ///
  /// In en, this message translates to:
  /// **'Liquid Gold'**
  String get trophySweetHarmonyTitle;

  /// No description provided for @trophySweetHarmonyDesc.
  ///
  /// In en, this message translates to:
  /// **'Harvest Wildflower Honey from an Apiary.'**
  String get trophySweetHarmonyDesc;

  /// No description provided for @trophyDairyDelightTitle.
  ///
  /// In en, this message translates to:
  /// **'Cream of the Crop'**
  String get trophyDairyDelightTitle;

  /// No description provided for @trophyDairyDelightDesc.
  ///
  /// In en, this message translates to:
  /// **'Collect Creamy Milk from a Sunny Paddock.'**
  String get trophyDairyDelightDesc;

  /// No description provided for @trophySavvyTraderTitle.
  ///
  /// In en, this message translates to:
  /// **'Market Timing'**
  String get trophySavvyTraderTitle;

  /// No description provided for @trophySavvyTraderDesc.
  ///
  /// In en, this message translates to:
  /// **'Sell 5 crates during a hot Market Boom.'**
  String get trophySavvyTraderDesc;

  /// No description provided for @trophyMasterComposterTitle.
  ///
  /// In en, this message translates to:
  /// **'Living Soil'**
  String get trophyMasterComposterTitle;

  /// No description provided for @trophyMasterComposterDesc.
  ///
  /// In en, this message translates to:
  /// **'Enrich 8 garden beds with Rich Compost.'**
  String get trophyMasterComposterDesc;

  /// No description provided for @trophyVillageDarlingTitle.
  ///
  /// In en, this message translates to:
  /// **'Beloved Neighbor'**
  String get trophyVillageDarlingTitle;

  /// No description provided for @trophyVillageDarlingDesc.
  ///
  /// In en, this message translates to:
  /// **'Fulfill 3 special Daily Village Requests.'**
  String get trophyVillageDarlingDesc;

  /// No description provided for @trophyGoldenOasisTitle.
  ///
  /// In en, this message translates to:
  /// **'Solville Legend'**
  String get trophyGoldenOasisTitle;

  /// No description provided for @trophyGoldenOasisDesc.
  ///
  /// In en, this message translates to:
  /// **'Earn 2,000 lifetime Sols and expand your farm.'**
  String get trophyGoldenOasisDesc;

  /// No description provided for @villagerBakerMateo.
  ///
  /// In en, this message translates to:
  /// **'Baker Mateo'**
  String get villagerBakerMateo;

  /// No description provided for @villagerChefClara.
  ///
  /// In en, this message translates to:
  /// **'Chef Clara'**
  String get villagerChefClara;

  /// No description provided for @villagerFloristMina.
  ///
  /// In en, this message translates to:
  /// **'Florist Mina'**
  String get villagerFloristMina;

  /// No description provided for @villagerGrandpaLeo.
  ///
  /// In en, this message translates to:
  /// **'Grandpa Leo'**
  String get villagerGrandpaLeo;

  /// No description provided for @villagerMayorSunny.
  ///
  /// In en, this message translates to:
  /// **'Mayor Sunny'**
  String get villagerMayorSunny;

  /// No description provided for @hudSolsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sols (Solville Coins)'**
  String get hudSolsTooltip;

  /// No description provided for @hudWaterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Watering Can charges (refill at Stone Well)'**
  String get hudWaterTooltip;

  /// No description provided for @hudCratesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Carried Crates (deliver to Market Stall or Barn)'**
  String get hudCratesTooltip;

  /// No description provided for @hudMarketCompact.
  ///
  /// In en, this message translates to:
  /// **'Market {boomEmojis}'**
  String hudMarketCompact(String boomEmojis);

  /// No description provided for @hudMarketFull.
  ///
  /// In en, this message translates to:
  /// **'Market 🔥 {boomEmojis} ({count}/8)'**
  String hudMarketFull(String boomEmojis, int count);

  /// No description provided for @hudShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get hudShop;

  /// No description provided for @hudPassShort.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get hudPassShort;

  /// No description provided for @hudPassShortActive.
  ///
  /// In en, this message translates to:
  /// **'Pass ✓'**
  String get hudPassShortActive;

  /// No description provided for @hudSunPassTooltip.
  ///
  /// In en, this message translates to:
  /// **'Solville Sun Pass (24h–48h Ad Pass or 2,99€/yr)'**
  String get hudSunPassTooltip;

  /// No description provided for @hudHomesteadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Homestead & Cozy Soundscape'**
  String get hudHomesteadTooltip;

  /// No description provided for @hudMuteSfx.
  ///
  /// In en, this message translates to:
  /// **'Mute Garden SFX'**
  String get hudMuteSfx;

  /// No description provided for @hudEnableSfx.
  ///
  /// In en, this message translates to:
  /// **'Enable Garden SFX'**
  String get hudEnableSfx;

  /// No description provided for @hudHelpTooltip.
  ///
  /// In en, this message translates to:
  /// **'How to Play, Controls & Save'**
  String get hudHelpTooltip;

  /// No description provided for @hudHideExtra.
  ///
  /// In en, this message translates to:
  /// **'Hide Extra Controls'**
  String get hudHideExtra;

  /// No description provided for @hudShowExtra.
  ///
  /// In en, this message translates to:
  /// **'Trophies, Soundscape & Help'**
  String get hudShowExtra;

  /// No description provided for @hudDayWeatherCompact.
  ///
  /// In en, this message translates to:
  /// **'D{day} {weather}'**
  String hudDayWeatherCompact(int day, String weather);

  /// No description provided for @hudDayWeatherFull.
  ///
  /// In en, this message translates to:
  /// **'Day {day} • {weather}'**
  String hudDayWeatherFull(int day, String weather);

  /// No description provided for @hudNextMorningTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rest & start next morning with fresh Market Trends'**
  String get hudNextMorningTooltip;

  /// No description provided for @hudNextCompact.
  ///
  /// In en, this message translates to:
  /// **'🌅 Next'**
  String get hudNextCompact;

  /// No description provided for @hudNextFull.
  ///
  /// In en, this message translates to:
  /// **'🌅 Next Day'**
  String get hudNextFull;

  /// No description provided for @entitlementCozyEdition.
  ///
  /// In en, this message translates to:
  /// **'Cozy Edition'**
  String get entitlementCozyEdition;

  /// No description provided for @entitlementSunPassVip.
  ///
  /// In en, this message translates to:
  /// **'Sun Pass VIP'**
  String get entitlementSunPassVip;

  /// No description provided for @entitlementPassRemaining.
  ///
  /// In en, this message translates to:
  /// **'Pass {time}'**
  String entitlementPassRemaining(String time);

  /// No description provided for @entitlementSunPass.
  ///
  /// In en, this message translates to:
  /// **'Sun Pass'**
  String get entitlementSunPass;

  /// No description provided for @entitlementExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get entitlementExpired;

  /// No description provided for @entitlementTimeHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String entitlementTimeHoursMinutes(int hours, String minutes);

  /// No description provided for @entitlementTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String entitlementTimeMinutes(int minutes);

  /// No description provided for @entitlementAnnualPrice.
  ///
  /// In en, this message translates to:
  /// **'2,99€ / year'**
  String get entitlementAnnualPrice;

  /// No description provided for @entitlementLifetimePrice.
  ///
  /// In en, this message translates to:
  /// **'4,99€'**
  String get entitlementLifetimePrice;

  /// No description provided for @dockQueuedCount.
  ///
  /// In en, this message translates to:
  /// **'⚡ {count} Queued'**
  String dockQueuedCount(int count);

  /// No description provided for @dockClear.
  ///
  /// In en, this message translates to:
  /// **'✕ Clear'**
  String get dockClear;

  /// No description provided for @dockHarvestRipe.
  ///
  /// In en, this message translates to:
  /// **'Harvest Ripe ({count})'**
  String dockHarvestRipe(int count);

  /// No description provided for @dockHarvestRipeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Queue all ripe harvests & crates (Hotkey: H)'**
  String get dockHarvestRipeTooltip;

  /// No description provided for @dockWaterDry.
  ///
  /// In en, this message translates to:
  /// **'Water Dry ({count})'**
  String dockWaterDry(int count);

  /// No description provided for @dockWaterDryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Queue watering on thirsty garden beds'**
  String get dockWaterDryTooltip;

  /// No description provided for @dockCenterCameraTooltip.
  ///
  /// In en, this message translates to:
  /// **'Center on Sol (Space / C)'**
  String get dockCenterCameraTooltip;

  /// No description provided for @dockZoomInTooltip.
  ///
  /// In en, this message translates to:
  /// **'Zoom In'**
  String get dockZoomInTooltip;

  /// No description provided for @dockZoomOutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Zoom Out'**
  String get dockZoomOutTooltip;

  /// No description provided for @dockUnlockSeeds.
  ///
  /// In en, this message translates to:
  /// **'+ Unlock Seeds'**
  String get dockUnlockSeeds;

  /// No description provided for @dockSeedLockedLabel.
  ///
  /// In en, this message translates to:
  /// **'{emoji} {name} (☀️ Pass)'**
  String dockSeedLockedLabel(String emoji, String name);

  /// No description provided for @dockExpandIsleLocked.
  ///
  /// In en, this message translates to:
  /// **'🏝️ Expand Isle {fromSize}×{fromSize}→{toSize}×{toSize} (☀️ Sun Pass)'**
  String dockExpandIsleLocked(int fromSize, int toSize);

  /// No description provided for @dockExpandIsle.
  ///
  /// In en, this message translates to:
  /// **'🏝️ Expand Isle {fromSize}×{fromSize}→{toSize}×{toSize} ({cost}☀️)'**
  String dockExpandIsle(int fromSize, int toSize, int cost);

  /// No description provided for @dockBuildLockedLabel.
  ///
  /// In en, this message translates to:
  /// **'{emoji} {name} (☀️ Pass)'**
  String dockBuildLockedLabel(String emoji, String name);

  /// No description provided for @inspectorSunPassPaused.
  ///
  /// In en, this message translates to:
  /// **'{summary} • ☀️ Sun Pass Paused'**
  String inspectorSunPassPaused(String summary);

  /// No description provided for @inspectorUnlockBtn.
  ///
  /// In en, this message translates to:
  /// **'☀️ Unlock'**
  String get inspectorUnlockBtn;

  /// No description provided for @inspectorUntillBtn.
  ///
  /// In en, this message translates to:
  /// **'🌿 Untill'**
  String get inspectorUntillBtn;

  /// No description provided for @inspectorCrateOnGround.
  ///
  /// In en, this message translates to:
  /// **'{emoji} {name} Crate on ground • Tap to pick up'**
  String inspectorCrateOnGround(String emoji, String name);

  /// No description provided for @inspectorFarmhouse.
  ///
  /// In en, this message translates to:
  /// **'🏡 Sunlit Homestead • Tap for Soothing Soundscape & Farm Journal'**
  String get inspectorFarmhouse;

  /// No description provided for @inspectorWell.
  ///
  /// In en, this message translates to:
  /// **'🪨 Stone Well • Refills Watering Can ({charges}/{maxCharges})'**
  String inspectorWell(int charges, int maxCharges);

  /// No description provided for @inspectorBarn.
  ///
  /// In en, this message translates to:
  /// **'🏚️ Red Barn • {count} crates stored (Tap to store or open Market)'**
  String inspectorBarn(int count);

  /// No description provided for @inspectorMarketStall.
  ///
  /// In en, this message translates to:
  /// **'🏪 Market Stall • {count}/8 crates displayed'**
  String inspectorMarketStall(int count);

  /// No description provided for @inspectorLemonReady.
  ///
  /// In en, this message translates to:
  /// **'🍋 Sunburst Lemon Tree • {count}/2 crates ready! (+2% Charm)'**
  String inspectorLemonReady(int count);

  /// No description provided for @inspectorLemonRipening.
  ///
  /// In en, this message translates to:
  /// **'🍋 Sunburst Lemon Tree • Ripening {pct}% (+2% Charm)'**
  String inspectorLemonRipening(int pct);

  /// No description provided for @inspectorKettleReady.
  ///
  /// In en, this message translates to:
  /// **'🍯 Artisan Preserves Kettle • {count}/2 Gourmet Preserves ready!'**
  String inspectorKettleReady(int count);

  /// No description provided for @inspectorKettleSimmering.
  ///
  /// In en, this message translates to:
  /// **'🍯 Artisan Kettle • Simmering Preserves {pct}% ({count}/2 ready)'**
  String inspectorKettleSimmering(int pct, int count);

  /// No description provided for @inspectorKettleIdle.
  ///
  /// In en, this message translates to:
  /// **'🍯 Artisan Kettle • Idle (auto-pulls raw Barn produce or carry a crate here)'**
  String get inspectorKettleIdle;

  /// No description provided for @inspectorRotarySprinkler.
  ///
  /// In en, this message translates to:
  /// **'💦 Rotary Sprinkler (3×3) • Next mist in {seconds}s'**
  String inspectorRotarySprinkler(String seconds);

  /// No description provided for @inspectorSolarSprinkler.
  ///
  /// In en, this message translates to:
  /// **'⛲ Solar Mist Fountain (5×5) • Next mist in {seconds}s'**
  String inspectorSolarSprinkler(String seconds);

  /// No description provided for @inspectorLantern.
  ///
  /// In en, this message translates to:
  /// **'🏮 Garden Lantern • +3% Townspeople Tip Charm'**
  String get inspectorLantern;

  /// No description provided for @inspectorFlowerArch.
  ///
  /// In en, this message translates to:
  /// **'🌸 Blooming Trellis Arch • +6% Tip Charm & +20% nearby Bee speed'**
  String get inspectorFlowerArch;

  /// No description provided for @inspectorAnimalReady.
  ///
  /// In en, this message translates to:
  /// **'{emoji} {name} • {count} {product} ready!'**
  String inspectorAnimalReady(
    String emoji,
    String name,
    int count,
    String product,
  );

  /// No description provided for @inspectorBeeProducing.
  ///
  /// In en, this message translates to:
  /// **'{emoji} {name} • {pct}% Honey{bonus}'**
  String inspectorBeeProducing(
    String emoji,
    String name,
    int pct,
    String bonus,
  );

  /// No description provided for @inspectorBeeSynergy.
  ///
  /// In en, this message translates to:
  /// **' (+{bonusPct}% Flower Synergy!)'**
  String inspectorBeeSynergy(int bonusPct);

  /// No description provided for @inspectorAnimalHungry.
  ///
  /// In en, this message translates to:
  /// **'{emoji} {name} • Hungry! Tap to feed ({cost}☀️)'**
  String inspectorAnimalHungry(String emoji, String name, int cost);

  /// No description provided for @inspectorAnimalProducing.
  ///
  /// In en, this message translates to:
  /// **'{emoji} {name} • {pct}% • Feed {feedPct}%'**
  String inspectorAnimalProducing(
    String emoji,
    String name,
    int pct,
    int feedPct,
  );

  /// No description provided for @inspectorCompostTag.
  ///
  /// In en, this message translates to:
  /// **' • ✨ +35% Compost'**
  String get inspectorCompostTag;

  /// No description provided for @inspectorCropRipe.
  ///
  /// In en, this message translates to:
  /// **'{emoji} {name} • Ripe! Tap to harvest ({left} left){compost}'**
  String inspectorCropRipe(String emoji, String name, int left, String compost);

  /// No description provided for @inspectorCropThirsty.
  ///
  /// In en, this message translates to:
  /// **' (Thirsty!)'**
  String get inspectorCropThirsty;

  /// No description provided for @inspectorCropGrowing.
  ///
  /// In en, this message translates to:
  /// **'{emoji} {name} • {growthPct}% grown • 💧 {moistPct}%{droop} • {left}x harvest{compost}'**
  String inspectorCropGrowing(
    String emoji,
    String name,
    int growthPct,
    int moistPct,
    String droop,
    int left,
    String compost,
  );

  /// No description provided for @inspectorSoilComposted.
  ///
  /// In en, this message translates to:
  /// **' • ✨ Composted (+35%)'**
  String get inspectorSoilComposted;

  /// No description provided for @inspectorSoil.
  ///
  /// In en, this message translates to:
  /// **'🌱 Tilled Garden Bed ({x}, {y}) • 💧 {moistPct}%{compost} • Tool 7 to untill to grass'**
  String inspectorSoil(int x, int y, int moistPct, String compost);

  /// No description provided for @inspectorWeeds.
  ///
  /// In en, this message translates to:
  /// **'🌿 Wild Weeds ({x}, {y}) • Tap 1–3× to clear, sow & water'**
  String inspectorWeeds(int x, int y);

  /// No description provided for @inspectorStonePath.
  ///
  /// In en, this message translates to:
  /// **'🧱 Sunstone Path ({x}, {y}) • +40% faster walking'**
  String inspectorStonePath(int x, int y);

  /// No description provided for @homesteadTitle.
  ///
  /// In en, this message translates to:
  /// **'Sunlit Homestead & Cozy Soundscape'**
  String get homesteadTitle;

  /// No description provided for @homesteadSoundscapeHeading.
  ///
  /// In en, this message translates to:
  /// **'Soothing Background Soundscape'**
  String get homesteadSoundscapeHeading;

  /// No description provided for @homesteadSoundscapeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a gentle, seamlessly looping garden ambience (press M anytime on PC to cycle):'**
  String get homesteadSoundscapeSubtitle;

  /// No description provided for @homesteadAmbienceVolume.
  ///
  /// In en, this message translates to:
  /// **'Ambience Volume'**
  String get homesteadAmbienceVolume;

  /// No description provided for @homesteadSfxTitle.
  ///
  /// In en, this message translates to:
  /// **'🔊 Tactile Garden Sound Effects (SFX)'**
  String get homesteadSfxTitle;

  /// No description provided for @homesteadSfxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gentle chimes when digging, watering, harvesting & earning Sols'**
  String get homesteadSfxSubtitle;

  /// No description provided for @homesteadLanguageHeading.
  ///
  /// In en, this message translates to:
  /// **'🌐 Language'**
  String get homesteadLanguageHeading;

  /// No description provided for @homesteadLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred display language across Solville:'**
  String get homesteadLanguageSubtitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'🌐 System Default'**
  String get languageSystem;

  /// No description provided for @languageEnUs.
  ///
  /// In en, this message translates to:
  /// **'🇺🇸 English (US)'**
  String get languageEnUs;

  /// No description provided for @languageEnGb.
  ///
  /// In en, this message translates to:
  /// **'🇬🇧 English (UK)'**
  String get languageEnGb;

  /// No description provided for @languagePtPt.
  ///
  /// In en, this message translates to:
  /// **'🇵🇹 Português (PT)'**
  String get languagePtPt;

  /// No description provided for @languageFr.
  ///
  /// In en, this message translates to:
  /// **'🇫🇷 Français'**
  String get languageFr;

  /// No description provided for @languageEs.
  ///
  /// In en, this message translates to:
  /// **'🇪🇸 Español'**
  String get languageEs;

  /// No description provided for @languageDe.
  ///
  /// In en, this message translates to:
  /// **'🇩🇪 Deutsch'**
  String get languageDe;

  /// No description provided for @homesteadJournalHeading.
  ///
  /// In en, this message translates to:
  /// **'📖 Sol\'s Homestead Journal'**
  String get homesteadJournalHeading;

  /// No description provided for @homesteadJournalDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day} • {weather}'**
  String homesteadJournalDay(int day, String weather);

  /// No description provided for @homesteadJournalIsle.
  ///
  /// In en, this message translates to:
  /// **'🏝️ {size}×{size} Isle'**
  String homesteadJournalIsle(int size);

  /// No description provided for @homesteadJournalCoins.
  ///
  /// In en, this message translates to:
  /// **'☀️ {coins} Lifetime Sols'**
  String homesteadJournalCoins(int coins);

  /// No description provided for @homesteadJournalCrates.
  ///
  /// In en, this message translates to:
  /// **'📦 {count} Crates Harvested'**
  String homesteadJournalCrates(int count);

  /// No description provided for @homesteadJournalCharm.
  ///
  /// In en, this message translates to:
  /// **'🌸 +{pct}% Garden Charm'**
  String homesteadJournalCharm(int pct);

  /// No description provided for @homesteadRestNextMorning.
  ///
  /// In en, this message translates to:
  /// **'🌅 Rest Until Next Morning'**
  String get homesteadRestNextMorning;

  /// No description provided for @homesteadSaveFarm.
  ///
  /// In en, this message translates to:
  /// **'Save Farm'**
  String get homesteadSaveFarm;

  /// No description provided for @marketTitle.
  ///
  /// In en, this message translates to:
  /// **'Market Forecast & Barn (Day {day})'**
  String marketTitle(int day);

  /// No description provided for @marketCharmBadge.
  ///
  /// In en, this message translates to:
  /// **'🌸 +{pct}% Charm'**
  String marketCharmBadge(int pct);

  /// No description provided for @marketOrderHeading.
  ///
  /// In en, this message translates to:
  /// **'Daily Village Order — {villager}'**
  String marketOrderHeading(String villager);

  /// No description provided for @marketOrderCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed today! Bonus +{bonus}☀️ earned!'**
  String marketOrderCompleted(int bonus);

  /// No description provided for @marketOrderProgress.
  ///
  /// In en, this message translates to:
  /// **'Sell {required} crates of {emoji} {product} ({delivered}/{required}) for +{bonus}☀️ bonus!'**
  String marketOrderProgress(
    int required,
    String emoji,
    String product,
    int delivered,
    int bonus,
  );

  /// No description provided for @marketSurgeActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Sunny Surge Active Today! (+25% All Market Prices)'**
  String get marketSurgeActiveTitle;

  /// No description provided for @marketSurgeInactiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Sunny Surge (+25% Market Boost & 100% Hydration)'**
  String get marketSurgeInactiveTitle;

  /// No description provided for @marketSurgeActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All garden plots are hydrated and townsfolk pay +25% for every crate today!'**
  String get marketSurgeActiveSubtitle;

  /// No description provided for @marketSurgeSupporterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Included free with your Sun Pass!'**
  String get marketSurgeSupporterSubtitle;

  /// No description provided for @marketSurgeFreeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Watch 1 short ad (or unlock Sun Pass for free daily surges)!'**
  String get marketSurgeFreeSubtitle;

  /// No description provided for @marketSurgeActiveBtn.
  ///
  /// In en, this message translates to:
  /// **'Active ✓'**
  String get marketSurgeActiveBtn;

  /// No description provided for @marketSurgeFreeBtn.
  ///
  /// In en, this message translates to:
  /// **'Activate Free'**
  String get marketSurgeFreeBtn;

  /// No description provided for @marketSurgeWatchAdBtn.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad'**
  String get marketSurgeWatchAdBtn;

  /// No description provided for @marketPricingHeading.
  ///
  /// In en, this message translates to:
  /// **'Market Stall Pricing Strategy'**
  String get marketPricingHeading;

  /// No description provided for @marketCounterAndBarn.
  ///
  /// In en, this message translates to:
  /// **'Stall Counter ({stallCount}/{maxSlots}) • Barn ({barnCount} stored)'**
  String marketCounterAndBarn(int stallCount, int maxSlots, int barnCount);

  /// No description provided for @marketStockHotGoods.
  ///
  /// In en, this message translates to:
  /// **'Stock Hot Goods'**
  String get marketStockHotGoods;

  /// No description provided for @marketTodayPricesHeading.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Produce & Artisan Prices'**
  String get marketTodayPricesHeading;

  /// No description provided for @marketInBarnCount.
  ///
  /// In en, this message translates to:
  /// **'📦 {count} in Barn'**
  String marketInBarnCount(int count);

  /// No description provided for @marketSellOne.
  ///
  /// In en, this message translates to:
  /// **'Sell 1'**
  String get marketSellOne;

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'Solville Town Shop'**
  String get shopTitle;

  /// No description provided for @shopTabUpgrades.
  ///
  /// In en, this message translates to:
  /// **'⬆️ Upgrades'**
  String get shopTabUpgrades;

  /// No description provided for @shopTabSeeds.
  ///
  /// In en, this message translates to:
  /// **'🌱 Seed Licenses'**
  String get shopTabSeeds;

  /// No description provided for @shopTabBuild.
  ///
  /// In en, this message translates to:
  /// **'🏡 Build & Animals'**
  String get shopTabBuild;

  /// No description provided for @shopFullyUpgraded.
  ///
  /// In en, this message translates to:
  /// **'Fully upgraded!'**
  String get shopFullyUpgraded;

  /// No description provided for @shopMaxBadge.
  ///
  /// In en, this message translates to:
  /// **'MAX'**
  String get shopMaxBadge;

  /// No description provided for @shopSunPassBadge.
  ///
  /// In en, this message translates to:
  /// **'☀️ Sun Pass'**
  String get shopSunPassBadge;

  /// No description provided for @shopItemSunPass.
  ///
  /// In en, this message translates to:
  /// **'{name} • ☀️ Sun Pass'**
  String shopItemSunPass(String name);

  /// No description provided for @shopBuyCost.
  ///
  /// In en, this message translates to:
  /// **'Buy {cost}☀️'**
  String shopBuyCost(int cost);

  /// No description provided for @shopSeedBaseCrate.
  ///
  /// In en, this message translates to:
  /// **'{name} • Base Crate {value}☀️'**
  String shopSeedBaseCrate(String name, int value);

  /// No description provided for @shopSeedBaseCrateSunPass.
  ///
  /// In en, this message translates to:
  /// **'{name} • Base Crate {value}☀️ • ☀️ Sun Pass'**
  String shopSeedBaseCrateSunPass(String name, int value);

  /// No description provided for @shopSeedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{description}\nPlanting cost: {seedCost}☀️ • Harvests: {harvests}x'**
  String shopSeedSubtitle(String description, int seedCost, int harvests);

  /// No description provided for @shopEquipSeed.
  ///
  /// In en, this message translates to:
  /// **'Equip Seed'**
  String get shopEquipSeed;

  /// No description provided for @shopUnlockCost.
  ///
  /// In en, this message translates to:
  /// **'Unlock {cost}☀️'**
  String shopUnlockCost(int cost);

  /// No description provided for @shopCurrentIsleTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} (Current Isle: {size}×{size})'**
  String shopCurrentIsleTitle(String name, int size);

  /// No description provided for @shopExpandCost.
  ///
  /// In en, this message translates to:
  /// **'Expand {cost}☀️'**
  String shopExpandCost(int cost);

  /// No description provided for @shopBuildHint.
  ///
  /// In en, this message translates to:
  /// **'Select an item below, then tap any open grass tile on your farm to place it!'**
  String get shopBuildHint;

  /// No description provided for @shopBuildItemTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} ({cost}☀️ each)'**
  String shopBuildItemTitle(String name, int cost);

  /// No description provided for @shopBuildItemTitleSunPass.
  ///
  /// In en, this message translates to:
  /// **'{name} ({cost}☀️ each • ☀️ Sun Pass)'**
  String shopBuildItemTitleSunPass(String name, int cost);

  /// No description provided for @shopPlaceOnFarm.
  ///
  /// In en, this message translates to:
  /// **'Place on Farm'**
  String get shopPlaceOnFarm;

  /// No description provided for @sunPassTitle.
  ///
  /// In en, this message translates to:
  /// **'Solville Sun Pass'**
  String get sunPassTitle;

  /// No description provided for @sunPassBadgeActive.
  ///
  /// In en, this message translates to:
  /// **'☀️ Active'**
  String get sunPassBadgeActive;

  /// No description provided for @sunPassBadgeStarter.
  ///
  /// In en, this message translates to:
  /// **'Starter Tier'**
  String get sunPassBadgeStarter;

  /// No description provided for @sunPassIncludedHeading.
  ///
  /// In en, this message translates to:
  /// **'✨ Everything Included in Sun Pass:'**
  String get sunPassIncludedHeading;

  /// No description provided for @sunPassIncludedBody.
  ///
  /// In en, this message translates to:
  /// **'• 🌽🪻🎃 Gourmet Crops: Golden Corn, Fragrant Lavender (+35% Bee speed) & Solville Pumpkin\n• 🍋🫙🐝🐄 Artisan & Ranch: Lemon Trees, Artisan Preserves Kettle, Wildflower Apiary, Sunny Cow Paddock, Solar Mist Tower (5×5) & Blossom Arch\n• 🏝️🛠️ Grand Expansions & Master Tools: Expand your isle up to 35×35 + Tier 2 Tool Upgrades\n• 💚 Cozy Promise: Your farm is never deleted if the ad timer ends—existing builds simply pause until you unlock again!'**
  String get sunPassIncludedBody;

  /// No description provided for @sunPassAdTitle.
  ///
  /// In en, this message translates to:
  /// **'Watch 1 Short Ad • +24 Hours Unlock'**
  String get sunPassAdTitle;

  /// No description provided for @sunPassAdBadge.
  ///
  /// In en, this message translates to:
  /// **'FREE • STACK UP TO 48H'**
  String get sunPassAdBadge;

  /// No description provided for @sunPassAdDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock the entire Solville catalog for 24 hours. Watch 2 ads back-to-back to stack up to 48 hours of uninterrupted play!'**
  String get sunPassAdDesc;

  /// No description provided for @sunPassUnlockedForever.
  ///
  /// In en, this message translates to:
  /// **'Unlocked Forever'**
  String get sunPassUnlockedForever;

  /// No description provided for @sunPassMaxed48h.
  ///
  /// In en, this message translates to:
  /// **'Maxed (48h)'**
  String get sunPassMaxed48h;

  /// No description provided for @sunPassWatchAdTopUp.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad (+24h Top-Up)'**
  String get sunPassWatchAdTopUp;

  /// No description provided for @sunPassWatchAd24h.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad (+24h)'**
  String get sunPassWatchAd24h;

  /// No description provided for @sunPassAnnualTitle.
  ///
  /// In en, this message translates to:
  /// **'Annual Sun Pass • {price}'**
  String sunPassAnnualTitle(String price);

  /// No description provided for @sunPassAnnualBadge.
  ///
  /// In en, this message translates to:
  /// **'MOST POPULAR • ~0,25€/MO'**
  String get sunPassAnnualBadge;

  /// No description provided for @sunPassAnnualDesc.
  ///
  /// In en, this message translates to:
  /// **'Full year of ad-free access to all crops, animals & island expansions + Free 1-tap Daily Sunny Surge (+25% Market Boost & instant Sunshower)!'**
  String get sunPassAnnualDesc;

  /// No description provided for @sunPassActiveCheck.
  ///
  /// In en, this message translates to:
  /// **'Active ✓'**
  String get sunPassActiveCheck;

  /// No description provided for @sunPassSubscribeBtn.
  ///
  /// In en, this message translates to:
  /// **'Subscribe 2,99€/yr'**
  String get sunPassSubscribeBtn;

  /// No description provided for @sunPassLifetimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Cozy Edition • {price}'**
  String sunPassLifetimeTitle(String price);

  /// No description provided for @sunPassLifetimeBadge.
  ///
  /// In en, this message translates to:
  /// **'ONE-TIME PAYMENT • OWN FOREVER'**
  String get sunPassLifetimeBadge;

  /// No description provided for @sunPassLifetimeDesc.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions, no timers, no ads—ever. Own all of Solville and daily Sunny Surge boosts forever with a single purchase.'**
  String get sunPassLifetimeDesc;

  /// No description provided for @sunPassOwnedCheck.
  ///
  /// In en, this message translates to:
  /// **'Owned ✓'**
  String get sunPassOwnedCheck;

  /// No description provided for @sunPassBuyOnceBtn.
  ///
  /// In en, this message translates to:
  /// **'Buy Once 4,99€'**
  String get sunPassBuyOnceBtn;

  /// No description provided for @sunPassSurgeCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Sunny Surge (100% Hydration + +25% Market Prices)'**
  String get sunPassSurgeCardTitle;

  /// No description provided for @sunPassSurgeSupporterDesc.
  ///
  /// In en, this message translates to:
  /// **'Included free every day with your supporter pass!'**
  String get sunPassSurgeSupporterDesc;

  /// No description provided for @sunPassSurgeFreeDesc.
  ///
  /// In en, this message translates to:
  /// **'Watch 1 optional ad once per day to drench your farm & boost Market Stall payouts!'**
  String get sunPassSurgeFreeDesc;

  /// No description provided for @sunPassActiveTodayCheck.
  ///
  /// In en, this message translates to:
  /// **'Active Today ✓'**
  String get sunPassActiveTodayCheck;

  /// No description provided for @sunPassClaimFreeSurge.
  ///
  /// In en, this message translates to:
  /// **'Claim Free Surge'**
  String get sunPassClaimFreeSurge;

  /// No description provided for @sunPassWatchAdSurge.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad (Surge)'**
  String get sunPassWatchAdSurge;

  /// No description provided for @sunPassRestorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get sunPassRestorePurchases;

  /// No description provided for @sunPassStatusLifetimeHeadline.
  ///
  /// In en, this message translates to:
  /// **'👑 Lifetime Cozy Edition Unlocked'**
  String get sunPassStatusLifetimeHeadline;

  /// No description provided for @sunPassStatusLifetimeSubtext.
  ///
  /// In en, this message translates to:
  /// **'All crops, animals, expansions, and free daily Sunny Surges are yours forever!'**
  String get sunPassStatusLifetimeSubtext;

  /// No description provided for @sunPassStatusAnnualHeadline.
  ///
  /// In en, this message translates to:
  /// **'🌻 Annual Sun Pass Active (2,99€ / year)'**
  String get sunPassStatusAnnualHeadline;

  /// No description provided for @sunPassStatusAnnualSubtext.
  ///
  /// In en, this message translates to:
  /// **'All Sun Pass content and free daily Sunny Surges are unlocked!'**
  String get sunPassStatusAnnualSubtext;

  /// No description provided for @sunPassStatusAdHeadline.
  ///
  /// In en, this message translates to:
  /// **'☀️ Ad Pass Active — {remaining} remaining'**
  String sunPassStatusAdHeadline(String remaining);

  /// No description provided for @sunPassStatusAdSubtext.
  ///
  /// In en, this message translates to:
  /// **'All crops, builds, and upgrades are unlocked! You can stack up to 48 hours max.'**
  String get sunPassStatusAdSubtext;

  /// No description provided for @sunPassStatusStarterHeadline.
  ///
  /// In en, this message translates to:
  /// **'🌱 Playing on Free Starter Homestead'**
  String get sunPassStatusStarterHeadline;

  /// No description provided for @sunPassStatusStarterSubtext.
  ///
  /// In en, this message translates to:
  /// **'Watch 1 short ad for 24h of full access (stackable to 48h), or unlock permanently below!'**
  String get sunPassStatusStarterSubtext;

  /// No description provided for @trophyCabinetTitle.
  ///
  /// In en, this message translates to:
  /// **'Trophy Cabinet ({unlocked}/{total})'**
  String trophyCabinetTitle(int unlocked, int total);

  /// No description provided for @trophySteamSynced.
  ///
  /// In en, this message translates to:
  /// **'🎮 Steam Synced'**
  String get trophySteamSynced;

  /// No description provided for @trophyLocalCabinet.
  ///
  /// In en, this message translates to:
  /// **'💾 Local Cabinet'**
  String get trophyLocalCabinet;

  /// No description provided for @trophyClaimed.
  ///
  /// In en, this message translates to:
  /// **'✓ Claimed +{reward}☀️'**
  String trophyClaimed(int reward);

  /// No description provided for @trophyReward.
  ///
  /// In en, this message translates to:
  /// **'Reward: +{reward}☀️'**
  String trophyReward(int reward);

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'How to Play Solville & Controls'**
  String get helpTitle;

  /// No description provided for @helpStartFresh.
  ///
  /// In en, this message translates to:
  /// **'Start Fresh Farm'**
  String get helpStartFresh;

  /// No description provided for @helpSaveNow.
  ///
  /// In en, this message translates to:
  /// **'Save Game Now'**
  String get helpSaveNow;

  /// No description provided for @helpSec1Title.
  ///
  /// In en, this message translates to:
  /// **'⚡ Multi-Click / Multi-Tap Action Queue'**
  String get helpSec1Title;

  /// No description provided for @helpSec1Body.
  ///
  /// In en, this message translates to:
  /// **'Inspired by Alice Greenfingers! In Smart mode (1), tap any grass plot 3 times in a row to queue Dig → Sow Seed → Water in one seamless combo! Sol detours to the Stone Well automatically when her watering can runs dry.'**
  String get helpSec1Body;

  /// No description provided for @helpSec2Title.
  ///
  /// In en, this message translates to:
  /// **'📦 Crates, Barn & Market Booms'**
  String get helpSec2Title;

  /// No description provided for @helpSec2Body.
  ///
  /// In en, this message translates to:
  /// **'Harvest ripe crops or animal goods into wooden Crates, then tap the striped Market Stall to display them for passing townsfolk! Or store crates in the Red Barn and sell them when a 🔥 Market Boom (+45%) hits.'**
  String get helpSec2Body;

  /// No description provided for @helpSec3Title.
  ///
  /// In en, this message translates to:
  /// **'🍋 Lemon Orchards & Artisan Preserves'**
  String get helpSec3Title;

  /// No description provided for @helpSec3Body.
  ///
  /// In en, this message translates to:
  /// **'Plant Sunburst Lemon Trees in Build mode (6) for carefree passive harvests + Garden Charm. Build an Artisan Preserves Kettle to simmer raw Barn produce (or hand-carried crates) into high-value Gourmet Preserves!'**
  String get helpSec3Body;

  /// No description provided for @helpSec4Title.
  ///
  /// In en, this message translates to:
  /// **'💦 Sprinklers & Bee Synergies'**
  String get helpSec4Title;

  /// No description provided for @helpSec4Body.
  ///
  /// In en, this message translates to:
  /// **'Buy Rotary (3×3) and Solar Mist (5×5) Sprinklers to automate watering. Plant Fragrant Lavender or Blooming Trellis Arches near Wildflower Apiaries to boost Honey speed!'**
  String get helpSec4Body;

  /// No description provided for @helpSec5Title.
  ///
  /// In en, this message translates to:
  /// **'🏝️ Expanding Your Isle & Untilling Soil'**
  String get helpSec5Title;

  /// No description provided for @helpSec5Body.
  ///
  /// In en, this message translates to:
  /// **'Your sunny 11×11 starter isle can be expanded all the way up to 35×35 with Sols via the Shop or the \"🏝️ Expand Isle\" button in Build mode (6)! Select Untill (7) to turn tilled soil, paths, or crops cleanly back into lush green grass.'**
  String get helpSec5Body;

  /// No description provided for @helpSec6Title.
  ///
  /// In en, this message translates to:
  /// **'🖥️ PC / Steam & 📱 Android Controls'**
  String get helpSec6Title;

  /// No description provided for @helpSec6Body.
  ///
  /// In en, this message translates to:
  /// **'• Tap / Left-Click: Queue action (or tap Farmhouse/Stall to open menus)\n• Shift + Drag (PC): Sweep across garden rows to batch-queue chores or untill\n• Right-Click (PC) or \"✕ Clear\": Cancel queued tasks\n• Drag / WASD / Arrow Keys: Pan isometric diorama\n• Pinch (Android) / Scroll Wheel (PC): Zoom camera\n• Keys 1–7: Tools (7 = Untill to Grass) • H: Harvest Ripe • M: Cozy Music • Space/C: Center'**
  String get helpSec6Body;

  /// No description provided for @toastSunnySurge.
  ///
  /// In en, this message translates to:
  /// **'🌦️ Sunny Surge! All plots hydrated & +25% Golden Market Boost active today!'**
  String get toastSunnySurge;

  /// No description provided for @toastActionQueueFull.
  ///
  /// In en, this message translates to:
  /// **'Action queue is full (16 tasks)!'**
  String get toastActionQueueFull;

  /// No description provided for @toastNoHarvestsReady.
  ///
  /// In en, this message translates to:
  /// **'No ripe crops or ready crates to harvest right now!'**
  String get toastNoHarvestsReady;

  /// No description provided for @toastQueuedHarvests.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Queued 1 harvest task!} other{Queued {count} harvest tasks!}}'**
  String toastQueuedHarvests(int count);

  /// No description provided for @toastAllCropsHydrated.
  ///
  /// In en, this message translates to:
  /// **'All growing crops are well hydrated!'**
  String get toastAllCropsHydrated;

  /// No description provided for @toastQueuedWatering.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Queued watering for 1 garden bed!} other{Queued watering for {count} garden beds!}}'**
  String toastQueuedWatering(int count);

  /// No description provided for @toastStallFull.
  ///
  /// In en, this message translates to:
  /// **'Market Stall display is full (8 crates)!'**
  String get toastStallFull;

  /// No description provided for @toastNeedCoinsSeedLicense.
  ///
  /// In en, this message translates to:
  /// **'Need more Sols for this seed license!'**
  String get toastNeedCoinsSeedLicense;

  /// No description provided for @toastUnlockedSeeds.
  ///
  /// In en, this message translates to:
  /// **'Unlocked {name} seeds!'**
  String toastUnlockedSeeds(String name);

  /// No description provided for @toastNeedCoinsForUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Need {cost}☀️ for {name} (you have {coins}☀️)!'**
  String toastNeedCoinsForUpgrade(int cost, String name, int coins);

  /// No description provided for @toastExpandedIsle.
  ///
  /// In en, this message translates to:
  /// **'🏝️ {name}! Isle expanded to {size}×{size}!'**
  String toastExpandedIsle(String name, int size);

  /// No description provided for @toastPurchasedUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Purchased {name}!'**
  String toastPurchasedUpgrade(String name);

  /// No description provided for @toastNewDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day} dawned in Solville! ({weather})'**
  String toastNewDay(int day, String weather);

  /// No description provided for @toastPathBlocked.
  ///
  /// In en, this message translates to:
  /// **'Path blocked! Adjust garden layout.'**
  String get toastPathBlocked;

  /// No description provided for @toastWaterRefilled.
  ///
  /// In en, this message translates to:
  /// **'Watering can refilled!'**
  String get toastWaterRefilled;

  /// No description provided for @toastNeedCoinsForSeed.
  ///
  /// In en, this message translates to:
  /// **'Need {cost}☀️ for {name} seeds!'**
  String toastNeedCoinsForSeed(int cost, String name);

  /// No description provided for @toastNeedCoinsForCompost.
  ///
  /// In en, this message translates to:
  /// **'Need {cost}☀️ for Rich Compost!'**
  String toastNeedCoinsForCompost(int cost);

  /// No description provided for @toastSimmeringPreserves.
  ///
  /// In en, this message translates to:
  /// **'Simmering Gourmet Preserves! 🫙'**
  String get toastSimmeringPreserves;

  /// No description provided for @toastHandsFull.
  ///
  /// In en, this message translates to:
  /// **'Hands full! Deliver crates or upgrade Crate Stacker.'**
  String get toastHandsFull;

  /// No description provided for @toastHarvestCratesFirst.
  ///
  /// In en, this message translates to:
  /// **'Harvest crops into crates first, then bring them here!'**
  String get toastHarvestCratesFirst;

  /// No description provided for @toastStoredInBarn.
  ///
  /// In en, this message translates to:
  /// **'Crates stored safely in the Barn!'**
  String get toastStoredInBarn;

  /// No description provided for @toastNeedCoinsForFeed.
  ///
  /// In en, this message translates to:
  /// **'Need {cost}☀️ for animal feed!'**
  String toastNeedCoinsForFeed(int cost);

  /// No description provided for @toastFedAnimal.
  ///
  /// In en, this message translates to:
  /// **'Fed {name}!'**
  String toastFedAnimal(String name);

  /// No description provided for @toastNeedCoinsForBuild.
  ///
  /// In en, this message translates to:
  /// **'Need {cost}☀️ for {name}!'**
  String toastNeedCoinsForBuild(int cost, String name);

  /// No description provided for @toastPlacedBuild.
  ///
  /// In en, this message translates to:
  /// **'Placed {name}!'**
  String toastPlacedBuild(String name);

  /// No description provided for @toastVillageGrant.
  ///
  /// In en, this message translates to:
  /// **'Mayor Sunny gifted a 25☀️ Village Seed Grant!'**
  String get toastVillageGrant;

  /// No description provided for @toastVillagerOrderComplete.
  ///
  /// In en, this message translates to:
  /// **'{villager}\'s order complete! +{bonus}☀️'**
  String toastVillagerOrderComplete(String villager, int bonus);

  /// No description provided for @toastSoldCrate.
  ///
  /// In en, this message translates to:
  /// **'Sold {emoji} +{price}☀️'**
  String toastSoldCrate(String emoji, int price);

  /// No description provided for @toastTrophyUnlocked.
  ///
  /// In en, this message translates to:
  /// **'🏆 Trophy: {title} (+{reward}☀️)!'**
  String toastTrophyUnlocked(String title, int reward);

  /// No description provided for @toastWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back to Solville! (Day {day} • {size}×{size} Isle)'**
  String toastWelcomeBack(int day, int size);

  /// No description provided for @toastWelcomeNew.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Solville! Tap plots 1–3x to combo-queue Dig → Sow → Water!'**
  String get toastWelcomeNew;

  /// No description provided for @toastSunPassEnded.
  ///
  /// In en, this message translates to:
  /// **'☀️ Your Sun Pass timer ended! Watch 1 ad for +24h anytime.'**
  String get toastSunPassEnded;

  /// No description provided for @toastQueuedUntill.
  ///
  /// In en, this message translates to:
  /// **'🌿 Queued restoring plot ({x}, {y}) back to grass!'**
  String toastQueuedUntill(int x, int y);

  /// No description provided for @toastPromptSunPassSeeds.
  ///
  /// In en, this message translates to:
  /// **'{name} seeds'**
  String toastPromptSunPassSeeds(String name);

  /// No description provided for @toastPromptSunPassLicense.
  ///
  /// In en, this message translates to:
  /// **'{name} license'**
  String toastPromptSunPassLicense(String name);

  /// No description provided for @toastPromptSunPass.
  ///
  /// In en, this message translates to:
  /// **'☀️ {item} is part of Sun Pass! Watch 1 ad for +24h (up to 48h) or unlock forever.'**
  String toastPromptSunPass(String item);

  /// No description provided for @toastSunPassMaxed.
  ///
  /// In en, this message translates to:
  /// **'☀️ Sun Pass is already topped up to the 48-hour maximum!'**
  String get toastSunPassMaxed;

  /// No description provided for @toastAdCancelled.
  ///
  /// In en, this message translates to:
  /// **'Ad cancelled or unavailable right now.'**
  String get toastAdCancelled;

  /// No description provided for @toastSunPassUnlocked.
  ///
  /// In en, this message translates to:
  /// **'☀️ Sun Pass unlocked! ({remaining} active)'**
  String toastSunPassUnlocked(String remaining);

  /// No description provided for @toastSunnySurgeAlreadyActive.
  ///
  /// In en, this message translates to:
  /// **'🌦️ Sunny Surge is already active for Day {day}!'**
  String toastSunnySurgeAlreadyActive(int day);

  /// No description provided for @toastAdCancelledSurge.
  ///
  /// In en, this message translates to:
  /// **'Ad cancelled — Sunny Surge was not activated.'**
  String get toastAdCancelledSurge;

  /// No description provided for @toastPurchaseCancelled.
  ///
  /// In en, this message translates to:
  /// **'Purchase cancelled.'**
  String get toastPurchaseCancelled;

  /// No description provided for @toastAnnualPassActivated.
  ///
  /// In en, this message translates to:
  /// **'🌻 Thank you! Annual Sun Pass (2,99€/yr) is now active!'**
  String get toastAnnualPassActivated;

  /// No description provided for @toastLifetimePassActivated.
  ///
  /// In en, this message translates to:
  /// **'👑 Thank you! Solville Lifetime Cozy Edition is yours forever!'**
  String get toastLifetimePassActivated;

  /// No description provided for @toastPurchasesRestored.
  ///
  /// In en, this message translates to:
  /// **'✅ Restored your Solville Sun Pass purchases!'**
  String get toastPurchasesRestored;

  /// No description provided for @toastNoPreviousPurchases.
  ///
  /// In en, this message translates to:
  /// **'No previous store purchases found for this account.'**
  String get toastNoPreviousPurchases;

  /// No description provided for @toastAmbienceChanged.
  ///
  /// In en, this message translates to:
  /// **'Ambience: {track}'**
  String toastAmbienceChanged(String track);

  /// No description provided for @toastFarmSaved.
  ///
  /// In en, this message translates to:
  /// **'💾 Farm progress saved!'**
  String get toastFarmSaved;

  /// No description provided for @toastStartedFreshFarm.
  ///
  /// In en, this message translates to:
  /// **'🌱 Started a fresh sunny farm in Solville!'**
  String get toastStartedFreshFarm;

  /// No description provided for @parentalGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Grown-Up Check'**
  String get parentalGateTitle;

  /// No description provided for @parentalGateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please solve this quick math problem to continue:'**
  String get parentalGateSubtitle;

  /// No description provided for @parentalGateQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is {a} × {b}?'**
  String parentalGateQuestion(int a, int b);

  /// No description provided for @parentalGateHint.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get parentalGateHint;

  /// No description provided for @parentalGateWrong.
  ///
  /// In en, this message translates to:
  /// **'That wasn\'t quite right. Please ask a grown-up!'**
  String get parentalGateWrong;

  /// No description provided for @parentalGateContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get parentalGateContinue;

  /// No description provided for @parentalGateCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get parentalGateCancel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'GB':
            return AppLocalizationsEnGb();
          case 'US':
            return AppLocalizationsEnUs();
        }
        break;
      }
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'PT':
            return AppLocalizationsPtPt();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
