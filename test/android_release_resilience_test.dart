import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solville/data/repositories/save_game_repository.dart';
import 'package:solville/data/services/cozy_sound_service.dart';
import 'package:solville/data/services/monetization_service.dart';
import 'package:solville/domain/models/catalog.dart';
import 'package:solville/domain/models/entitlement_state.dart';
import 'package:solville/domain/models/game_state.dart';
import 'package:solville/domain/models/grid_pos.dart';
import 'package:solville/domain/simulation/farm_simulation_engine.dart';
import 'package:solville/main.dart';
import 'package:solville/ui/view_models/solville_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  GameState freshState() => FarmSimulationEngine().createNewGame();

  group('Save corruption recovery (SaveGameRepository)', () {
    test('round-trips a saved game through SharedPreferences', () async {
      final repo = SaveGameRepository();
      final state = freshState().copyWith(coins: 1234, day: 7);
      await repo.saveGame(state);

      final loaded = await SaveGameRepository().loadSave();
      expect(loaded, isNotNull);
      expect(loaded!.coins, equals(1234));
      expect(loaded.day, equals(7));
      expect(loaded.gridSize, equals(state.gridSize));
    });

    test('falls back to backup slot when primary slot is corrupted', () async {
      final good = jsonEncode(freshState().copyWith(coins: 555).toJson());
      SharedPreferences.setMockInitialValues(<String, Object>{
        'solville_save_state_v1': '{"gridSize": 11, "tiles": [truncated',
        'solville_save_state_v1_bak': good,
      });

      final loaded = await SaveGameRepository().loadSave();
      expect(loaded, isNotNull);
      expect(loaded!.coins, equals(555));
    });

    test('rejects tile arrays that do not match gridSize', () async {
      final json = freshState().toJson();
      (json['tiles'] as List<dynamic>).removeLast();
      SharedPreferences.setMockInitialValues(<String, Object>{
        'solville_save_state_v1': jsonEncode(json),
      });

      expect(await SaveGameRepository().loadSave(), isNull);
    });

    test('returns null (new game) when every slot is garbage', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'solville_save_state_v1': 'not json',
        'solville_save_state_v1_bak': '[]',
      });
      expect(await SaveGameRepository().loadSave(), isNull);
    });

    test('GameState.fromJson survives unknown enums and NaN values', () {
      final json = freshState().toJson();
      json['weather'] = 'tornado';
      json['activeTool'] = 'laserBeam';
      json['dayProgress'] = double.nan;
      json['coins'] = -50;

      final restored = GameState.fromJson(json);
      expect(restored.weather, equals(WeatherType.sunny));
      expect(restored.activeTool, equals(ToolMode.smart));
      expect(restored.dayProgress.isNaN, isFalse);
      expect(restored.coins, greaterThanOrEqualTo(0));
    });

    test('clearSave removes both primary and backup slots', () async {
      final repo = SaveGameRepository();
      await repo.saveGame(freshState().copyWith(coins: 1));
      await repo.saveGame(freshState().copyWith(coins: 2));
      await repo.clearSave();
      expect(await SaveGameRepository().loadSave(), isNull);
    });
  });

  group('Entitlement edge cases', () {
    test('Sunny Surge is claimable again after a new farm resets to Day 1', () {
      const claimedOnDay5 = EntitlementState(lastSunnySurgeDay: 5);
      expect(claimedOnDay5.canClaimSunnySurgeOnDay(5), isFalse);
      expect(claimedOnDay5.canClaimSunnySurgeOnDay(1), isTrue);
      expect(claimedOnDay5.canClaimSunnySurgeOnDay(6), isTrue);
      expect(claimedOnDay5.canClaimSunnySurgeOnDay(0), isFalse);
    });

    test('entitlement JSON round-trips ownership flags', () {
      const owned = EntitlementState(
        hasAnnualPass: true,
        hasLifetimePass: true,
        lastSunnySurgeDay: 3,
      );
      final restored = EntitlementState.fromJson(
        jsonDecode(jsonEncode(owned.toJson())) as Map<String, dynamic>,
      );
      expect(restored.hasAnnualPass, isTrue);
      expect(restored.hasLifetimePass, isTrue);
      expect(restored.lastSunnySurgeDay, equals(3));
    });
  });

  group('MonetizationService error handling', () {
    test(
      'ad callback exceptions resolve to unavailable and clear busy',
      () async {
        final service = MonetizationService(
          enablePlatformSdk: false,
          onShowRewardedAd: () async => throw StateError('no fill'),
        );
        expect(
          await service.showRewardedAd(),
          equals(MonetizationResult.unavailable),
        );
        expect(service.isBusy, isFalse);
      },
    );

    test('re-entrant ad/purchase requests are rejected while busy', () async {
      final service = MonetizationService(
        enablePlatformSdk: false,
        simulatedLatency: const Duration(milliseconds: 50),
      );
      final first = service.showRewardedAd();
      expect(service.isBusy, isTrue);
      expect(
        await service.purchaseAnnualPass(),
        equals(MonetizationResult.cancelled),
      );
      expect(await first, equals(MonetizationResult.success));
      expect(service.isBusy, isFalse);
    });

    test('purchase and restore failures never throw', () async {
      final service = MonetizationService(
        enablePlatformSdk: false,
        onPurchaseProduct: (_) async => throw Exception('billing down'),
        onRestorePurchases: () async => throw Exception('offline'),
      );
      expect(
        await service.purchaseLifetimePass(),
        equals(MonetizationResult.unavailable),
      );
      expect(await service.restorePurchases(), isEmpty);
    });
  });

  group('Android lifecycle & back navigation', () {
    test(
      'CozySoundService pauses on background and resumes on foreground',
      () async {
        final sound = CozySoundService(silentPlatformOutput: true);
        sound.initialize();
        await sound.applyBgmSettings();
        expect(sound.isBgmPlaying, isTrue);

        for (final state in const <AppLifecycleState>[
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
          AppLifecycleState.detached,
        ]) {
          await sound.applyBgmSettings();
          sound.didChangeAppLifecycleState(state);
          await Future<void>.delayed(Duration.zero);
          expect(
            sound.isBgmPlaying,
            isFalse,
            reason: '$state should pause BGM',
          );
        }

        sound.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await Future<void>.delayed(Duration.zero);
        expect(sound.isBgmPlaying, isTrue);
        await sound.dispose();
      },
    );

    testWidgets('backgrounding the app auto-saves farm progress', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = SolvilleController(
        soundService: CozySoundService(silentPlatformOutput: true),
      );
      await controller.initialize();
      await tester.pumpWidget(SolvilleApp(controller: controller));
      await tester.pump(const Duration(milliseconds: 50));

      controller.purchaseUpgrade(UpgradeTrack.crateStacker);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );

      final saved = await tester.runAsync(
        () => SaveGameRepository().loadSave(),
      );
      expect(saved, isNotNull);
      expect(saved!.gridSize, equals(controller.state.gridSize));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      controller.dispose();
    });

    testWidgets('back gesture dismisses transient state before exiting', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = SolvilleController(
        soundService: CozySoundService(silentPlatformOutput: true),
      );
      await controller.initialize();
      await tester.pumpWidget(SolvilleApp(controller: controller));
      await tester.pump(const Duration(milliseconds: 50));

      controller.handleTileTap(const GridPos(6, 3));
      expect(controller.inspectedTile, isNotNull);

      expect(controller.handleBackNavigation(), isTrue);
      expect(controller.inspectedTile, isNull);

      controller.clearActionQueue();
      expect(controller.state.actionQueue, isEmpty);
      // With nothing left to dismiss the controller reports "not handled".
      expect(controller.handleBackNavigation(), isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      controller.dispose();
    });
  });
}
