import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solville/data/services/cozy_sound_service.dart';
import 'package:solville/domain/models/catalog.dart';
import 'package:solville/domain/models/entitlement_state.dart';
import 'package:solville/domain/models/grid_pos.dart';
import 'package:solville/domain/models/tile_state.dart';
import 'package:solville/domain/simulation/farm_simulation_engine.dart';
import 'package:solville/main.dart';
import 'package:solville/ui/view_models/solville_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('EntitlementState & 24h->48h Ad Stacking', () {
    test(
      'Single ad grants 24h, second ad stacks to 48h cap, and expires cleanly',
      () {
        final t0 = DateTime.utc(2026, 11, 10, 10, 0);
        const start = EntitlementState(isFullEditionBuild: false);

        expect(start.isSunPassActive(t0), isFalse);
        expect(start.canStackAnotherAd(t0), isTrue);

        // Watch 1st ad -> +24h
        final after1Ad = start.grantRewardedAdPass(t0);
        expect(after1Ad.isSunPassActive(t0), isTrue);
        expect(
          after1Ad.remainingAdPassDuration(t0),
          equals(const Duration(hours: 24)),
        );
        expect(after1Ad.canStackAnotherAd(t0), isTrue);

        // Watch 2nd ad back-to-back -> stacks to 48h max
        final after2Ads = after1Ad.grantRewardedAdPass(t0);
        expect(
          after2Ads.remainingAdPassDuration(t0),
          equals(const Duration(hours: 48)),
        );
        expect(after2Ads.canStackAnotherAd(t0), isFalse);

        // 30 hours later -> 18h remaining, can top up again
        final t30h = t0.add(const Duration(hours: 30));
        expect(after2Ads.isSunPassActive(t30h), isTrue);
        expect(
          after2Ads.remainingAdPassDuration(t30h),
          equals(const Duration(hours: 18)),
        );
        expect(after2Ads.canStackAnotherAd(t30h), isTrue);

        // 49 hours later -> expired
        final t49h = t0.add(const Duration(hours: 49));
        expect(after2Ads.isSunPassActive(t49h), isFalse);
      },
    );

    test('Catalog split matches Free Starter vs. Sun Pass tiers', () {
      // Free starter crops: Tomato, Carrot, Strawberry
      expect(SolvilleCatalog.isCropSunPassOnly(ProductId.tomato), isFalse);
      expect(SolvilleCatalog.isCropSunPassOnly(ProductId.carrot), isFalse);
      expect(SolvilleCatalog.isCropSunPassOnly(ProductId.strawberry), isFalse);

      // Sun Pass crops: Corn, Lavender, Pumpkin
      expect(SolvilleCatalog.isCropSunPassOnly(ProductId.corn), isTrue);
      expect(SolvilleCatalog.isCropSunPassOnly(ProductId.lavender), isTrue);
      expect(SolvilleCatalog.isCropSunPassOnly(ProductId.pumpkin), isTrue);

      // Free starter builds: Rotary Sprinkler, Henhouse, Stone Path, Lantern
      expect(
        SolvilleCatalog.isBuildSunPassOnly(BuildItemType.sprinklerRotary),
        isFalse,
      );
      expect(
        SolvilleCatalog.isBuildSunPassOnly(BuildItemType.henhouse),
        isFalse,
      );
      expect(
        SolvilleCatalog.isBuildSunPassOnly(BuildItemType.stonePath),
        isFalse,
      );
      expect(
        SolvilleCatalog.isBuildSunPassOnly(BuildItemType.lantern),
        isFalse,
      );

      // Sun Pass builds: Solar Mist Tower, Lemon Tree, Artisan Kettle, Beehive, Cow Paddock, Blossom Arch
      expect(
        SolvilleCatalog.isBuildSunPassOnly(BuildItemType.sprinklerSolar),
        isTrue,
      );
      expect(
        SolvilleCatalog.isBuildSunPassOnly(BuildItemType.lemonTree),
        isTrue,
      );
      expect(
        SolvilleCatalog.isBuildSunPassOnly(BuildItemType.artisanPress),
        isTrue,
      );
      expect(SolvilleCatalog.isBuildSunPassOnly(BuildItemType.beehive), isTrue);
      expect(
        SolvilleCatalog.isBuildSunPassOnly(BuildItemType.cowPaddock),
        isTrue,
      );
      expect(
        SolvilleCatalog.isBuildSunPassOnly(BuildItemType.flowerArch),
        isTrue,
      );

      // Tier 1 upgrades & 1st island expansion (11x11 -> 14x14) are free; Tier 2+ require Sun Pass
      expect(
        SolvilleCatalog.isNextUpgradeSunPassOnly(UpgradeTrack.farmExpansion, 0),
        isFalse,
      );
      expect(
        SolvilleCatalog.isNextUpgradeSunPassOnly(UpgradeTrack.farmExpansion, 1),
        isTrue,
      );
    });
  });

  group('Graceful Lock & Sunny Surge Simulation', () {
    test(
      'Existing crops keep growing and Sun Pass buildings pause gracefully without deletion when pass expires',
      () {
        final engine = FarmSimulationEngine();
        var state = engine.createNewGame();

        // Place a Lemon Tree (Sun Pass structure) and a Henhouse (Free structure),
        // and plant Lavender (Sun Pass crop) on a watered soil plot.
        final tiles = List<TileState>.from(state.tiles);
        final lemonIdx = 4 * state.gridSize + 4;
        final henIdx = 4 * state.gridSize + 5;
        final lavIdx = 5 * state.gridSize + 4;

        tiles[lemonIdx] = tiles[lemonIdx].copyWith(
          structure: StructureType.lemonTree,
          producerProgress: 0.50,
          producerCrates: 1,
        );
        tiles[henIdx] = tiles[henIdx].copyWith(
          structure: StructureType.henhouse,
          animal: const AnimalUnitState(
            type: AnimalType.chicken,
            progress: 0.20,
            feedLevel: 1.0,
          ),
        );
        tiles[lavIdx] = tiles[lavIdx].copyWith(
          ground: GroundType.soil,
          moisture: 0.90,
          crop: const PlantedCrop(
            cropId: ProductId.lavender,
            growth: 0.40,
            harvestsLeft: 2,
          ),
        );
        state = state.copyWith(tiles: tiles);

        // Tick while Sun Pass is INACTIVE:
        final tickedInactive = engine
            .tick(state, 0.25, isSunPassActive: false)
            .state;

        // 1. Lemon tree is still on the map with its ready crate intact, and progress is paused at 0.50
        final lemonAfter = tickedInactive.tileAt(const GridPos(4, 4));
        expect(lemonAfter.structure, equals(StructureType.lemonTree));
        expect(lemonAfter.producerCrates, equals(1));
        expect(lemonAfter.producerProgress, equals(0.50));

        // 2. Henhouse (Free tier) continues advancing egg production
        final henAfter = tickedInactive.tileAt(const GridPos(5, 4));
        expect(henAfter.animal!.progress, greaterThan(0.20));

        // 3. Already-planted Lavender continues growing!
        final lavAfter = tickedInactive.tileAt(const GridPos(4, 5));
        expect(lavAfter.crop!.growth, greaterThan(0.40));

        // Tick while Sun Pass is ACTIVE: Lemon tree resumes immediately!
        final tickedActive = engine
            .tick(tickedInactive, 0.25, isSunPassActive: true)
            .state;
        expect(
          tickedActive.tileAt(const GridPos(4, 4)).producerProgress,
          greaterThan(0.50),
        );
      },
    );

    testWidgets(
      'Sun Pass Modal opens from HUD, stacks 2 ads to 48h, and activates Sunny Surge',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fixedNow = DateTime.utc(2026, 11, 10, 12, 0);
        final controller = SolvilleController(
          soundService: CozySoundService(silentPlatformOutput: true),
          initialEntitlements: const EntitlementState(
            isFullEditionBuild: false,
          ),
          clock: () => fixedNow,
        );
        await controller.initialize();

        await tester.pumpWidget(SolvilleApp(controller: controller));
        await tester.pump(const Duration(milliseconds: 50));

        // Sun Pass pill is visible in TopStatusBar
        expect(find.text('Sun Pass'), findsOneWidget);
        await tester.tap(find.text('Sun Pass'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.text('Solville Sun Pass'), findsOneWidget);
        expect(find.text('Watch Ad (+24h)'), findsOneWidget);
        expect(find.text('Subscribe 2,99€/yr'), findsOneWidget);
        expect(find.text('Buy Once 4,99€'), findsOneWidget);

        // Watch 1st ad -> +24h unlocked
        await tester.tap(find.text('Watch Ad (+24h)'));
        await tester.pump();
        expect(controller.isSunPassActive, isTrue);
        expect(
          controller.entitlements.remainingAdPassDuration(fixedNow),
          equals(const Duration(hours: 24)),
        );
        expect(find.text('Watch Ad (+24h Top-Up)'), findsOneWidget);

        // Watch 2nd ad back-to-back -> stacks to 48h max
        await tester.tap(find.text('Watch Ad (+24h Top-Up)'));
        await tester.pump();
        expect(
          controller.entitlements.remainingAdPassDuration(fixedNow),
          equals(const Duration(hours: 48)),
        );
        expect(find.text('Maxed (48h)'), findsOneWidget);

        // Activate Daily Sunny Surge
        await tester.ensureVisible(find.text('Watch Ad (Surge)'));
        await tester.pump();
        await tester.tap(find.text('Watch Ad (Surge)'));
        await tester.pump();
        expect(controller.state.market.sunnySurgeActive, isTrue);
        expect(find.text('Active Today ✓'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        controller.dispose();
      },
    );

    testWidgets(
      'Parental gate blocks accidental IAP taps until solved',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = SolvilleController(
          soundService: CozySoundService(silentPlatformOutput: true),
          initialEntitlements: const EntitlementState(
            isFullEditionBuild: false,
          ),
        );
        await controller.initialize();

        await tester.pumpWidget(SolvilleApp(controller: controller));
        await tester.pump(const Duration(milliseconds: 50));

        await tester.tap(find.text('Sun Pass'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        // Tap Subscribe -> Parental Gate appears, purchase does not run yet
        await tester.ensureVisible(find.text('Subscribe 2,99€/yr'));
        await tester.pump();
        await tester.tap(find.text('Subscribe 2,99€/yr'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('Grown-Up Check'), findsOneWidget);
        expect(controller.entitlements.hasAnnualPass, isFalse);

        // Wrong answer keeps the dialog open and shows an error
        await tester.enterText(find.byType(TextField), '1');
        await tester.tap(find.text('Continue'));
        await tester.pump();
        expect(
          find.text("That wasn't quite right. Please ask a grown-up!"),
          findsOneWidget,
        );
        expect(controller.entitlements.hasAnnualPass, isFalse);

        // Solve the multiplication question to unlock the purchase
        final questionFinder = find.textContaining('What is ');
        final questionText = tester.widget<Text>(questionFinder).data!;
        final match = RegExp(r'What is (\d+) × (\d+)\?').firstMatch(
          questionText,
        )!;
        final expectedAnswer =
            int.parse(match.group(1)!) * int.parse(match.group(2)!);

        await tester.enterText(
          find.byType(TextField),
          expectedAnswer.toString(),
        );
        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.text('Grown-Up Check'), findsNothing);
        expect(controller.entitlements.hasAnnualPass, isTrue);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        controller.dispose();
      },
    );
  });
}
