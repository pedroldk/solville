import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solville/data/services/cozy_sound_service.dart';
import 'package:solville/domain/models/catalog.dart';
import 'package:solville/main.dart';
import 'package:solville/ui/view_models/solville_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'Solville HUD renders resources and opens Shop, Trophy & Cozy Soundscape modals',
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

      // Verify core HUD elements & default Sunlit Lullaby soundscape chip
      expect(find.text('90'), findsOneWidget);
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Lullaby'), findsOneWidget);
      expect(find.text('Smart'), findsOneWidget);

      // Open Cozy Soundscape & Homestead Modal and switch to Cozy Rain
      await tester.tap(find.text('Lullaby'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.text('Sunlit Homestead & Cozy Soundscape'),
        findsOneWidget,
      );
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
}
