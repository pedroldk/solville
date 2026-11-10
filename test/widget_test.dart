import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solville/data/services/cozy_sound_service.dart';
import 'package:solville/domain/models/catalog.dart';
import 'package:solville/game/solville_game.dart';
import 'package:solville/main.dart';
import 'package:solville/ui/view_models/solville_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'Solville HUD renders 11x11 starter isle tools, Untill, Expand Isle & Cozy Soundscape',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = SolvilleController(
        soundService: CozySoundService(silentPlatformOutput: true),
      );
      await controller.initialize();
      expect(controller.state.gridSize, equals(11));

      await tester.pumpWidget(SolvilleApp(controller: controller));
      await tester.pump(const Duration(milliseconds: 50));

      // Verify core HUD elements, Untill tool, and Sunlit Lullaby chip
      expect(find.text('90'), findsOneWidget);
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Lullaby'), findsOneWidget);
      expect(find.text('Smart'), findsOneWidget);
      expect(find.text('Untill (Clear)'), findsOneWidget);

      // Select Build tool (6) and verify Expand Isle action chip is visible
      await tester.tap(find.text('Build'));
      await tester.pump();
      expect(find.textContaining('Expand Isle 11×11→14×14'), findsOneWidget);

      // Open Cozy Soundscape & Homestead Modal and switch to Cozy Rain
      await tester.tap(find.text('Lullaby'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Sunlit Homestead & Cozy Soundscape'), findsOneWidget);
      expect(find.text('🏝️ 11×11 Isle'), findsOneWidget);
      expect(find.text('🌧️ Cozy Rain'), findsOneWidget);

      await tester.tap(find.text('🌧️ Cozy Rain'));
      await tester.pump();
      expect(controller.bgmTrack, equals(BgmTrack.cozyRain));

      // Close Cozy Soundscape Modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Cozy Rain'), findsOneWidget);

      // Open Town Shop Modal
      await tester.tap(find.text('Shop'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Solville Town Shop'), findsOneWidget);
      expect(find.text('Copper Watering Can'), findsOneWidget);

      // Close Shop Modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Open Trophy Cabinet Modal
      await tester.tap(find.text('0/12'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.textContaining('Trophy Cabinet'), findsOneWidget);

      // Cleanly unmount GameWidget ticker before test teardown
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      controller.dispose();
    },
  );

  testWidgets(
    'Camera pans via drag gesture, keyboard WASD, and re-centers on farmer',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = SolvilleController(
        soundService: CozySoundService(silentPlatformOutput: true),
      );
      await controller.initialize();

      await tester.pumpWidget(SolvilleApp(controller: controller));
      await tester.pump(const Duration(milliseconds: 50));

      final gameWidget = tester.widget<GameWidget<SolvilleGame>>(
        find.byType(GameWidget<SolvilleGame>),
      );
      final game = gameWidget.game!;
      final initialPos = game.camera.viewfinder.position.clone();
      expect(initialPos.y, greaterThan(0));

      // 1. Drag across the viewport center to pan the camera
      await tester.dragFrom(const Offset(640, 360), const Offset(-120, -80));
      await tester.pump(const Duration(milliseconds: 16));

      final afterDragPos = game.camera.viewfinder.position.clone();
      expect(afterDragPos.x, greaterThan(initialPos.x + 50));
      expect(afterDragPos.y, greaterThan(initialPos.y + 30));

      // 2. Pan via keyboard WASD
      game.onKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyD,
          logicalKey: LogicalKeyboardKey.keyD,
          timeStamp: Duration.zero,
        ),
        <LogicalKeyboardKey>{LogicalKeyboardKey.keyD},
      );
      game.update(0.1);
      final afterKeyPos = game.camera.viewfinder.position.clone();
      expect(afterKeyPos.x, greaterThan(afterDragPos.x));

      game.onKeyEvent(
        const KeyUpEvent(
          physicalKey: PhysicalKeyboardKey.keyD,
          logicalKey: LogicalKeyboardKey.keyD,
          timeStamp: Duration.zero,
        ),
        <LogicalKeyboardKey>{},
      );

      // 3. Re-center camera on Sol via HUD button
      await tester.tap(find.byIcon(Icons.my_location_rounded));
      await tester.pump();
      final centeredPos = game.camera.viewfinder.position.clone();
      expect((centeredPos.x - afterKeyPos.x).abs(), greaterThan(10));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      controller.dispose();
    },
  );
}
