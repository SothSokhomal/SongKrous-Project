import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songkrous/core/constants/app_state.dart';
import 'package:songkrous/core/constants/app_strings.dart';
import 'package:songkrous/core/router/app_router.dart';
import 'package:songkrous/core/router/app_routes.dart';
import 'package:songkrous/features/safety/safety_input_screen.dart';
import 'package:songkrous/features/safety/safety_tips_screen.dart';
import 'package:songkrous/features/safety/widgets/urgent_banner.dart';
import 'package:songkrous/main.dart';
import 'package:songkrous/shared/widgets/app_interactive.dart';

Future<ProviderContainer> _bootApp(
  WidgetTester tester, {
  String route = AppRoutes.safety,
  AppLang lang = AppLang.en,
}) async {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(langProvider.notifier).set(lang);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const SongkrousApp(),
    ),
  );
  appRouter.go(route);
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  return container;
}

void main() {
  group('Safety Category Hub (SafetyInputScreen)', () {
    testWidgets('renders pinned UrgentBanner and all 6 categories without friction', (
      tester,
    ) async {
      await _bootApp(tester, route: AppRoutes.safety);

      // Verify urgent banner is pinned at top
      expect(find.byType(UrgentBanner), findsOneWidget);
      expect(find.text('Need urgent help?'), findsOneWidget);

      // Verify no feelings text input or radio form exists
      expect(find.text('How are you feeling right now?'), findsNothing);
      expect(find.text('Show my safety tips'), findsNothing);

      // Verify all 6 categories exist
      expect(find.text('Bleeding Control'), findsOneWidget);
      expect(find.text('Adult CPR'), findsOneWidget);
      expect(find.text('Drowning'), findsOneWidget);
      expect(find.text('Fainting (Syncope)'), findsOneWidget);
      expect(find.text('Fire / Smoke'), findsOneWidget);
      expect(find.text('Car accident'), findsOneWidget);
    });

    testWidgets('filter pills correctly filter categories', (tester) async {
      await _bootApp(tester, route: AppRoutes.safety);

      // Tap 'Medical' filter pill
      await tester.tap(find.text('Medical'));
      await tester.pumpAndSettle();

      // Should show Adult CPR and Fainting, but not Car accident or Bleeding Control
      expect(find.text('Adult CPR'), findsOneWidget);
      expect(find.text('Fainting (Syncope)'), findsOneWidget);
      expect(find.text('Bleeding Control'), findsNothing);
      expect(find.text('Car accident'), findsNothing);

      // Tap 'Trauma' filter pill
      await tester.tap(find.text('Trauma'));
      await tester.pumpAndSettle();

      expect(find.text('Bleeding Control'), findsOneWidget);
      expect(find.text('Car accident'), findsOneWidget);
      expect(find.text('Adult CPR'), findsNothing);

      // Tap 'Rescue' filter pill
      await tester.tap(find.text('Rescue'));
      await tester.pumpAndSettle();

      expect(find.text('Drowning'), findsOneWidget);
      expect(find.text('Fire / Smoke'), findsOneWidget);
      expect(find.text('Bleeding Control'), findsNothing);

      // Tap 'All' to restore
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.text('Bleeding Control'), findsOneWidget);
      expect(find.text('Adult CPR'), findsOneWidget);
    });

    testWidgets('search bar filters categories in real time', (tester) async {
      await _bootApp(tester, route: AppRoutes.safety);

      await tester.enterText(find.byType(TextField), 'bleeding');
      await tester.pumpAndSettle();

      expect(find.text('Bleeding Control'), findsOneWidget);
      expect(find.text('Adult CPR'), findsNothing);
      expect(find.text('Drowning'), findsNothing);
    });

    testWidgets('tap on category card navigates directly to step-by-step detail', (
      tester,
    ) async {
      await _bootApp(tester, route: AppRoutes.safety);

      await tester.tap(find.text('Bleeding Control'));
      await tester.pumpAndSettle();

      // Should be on Step-by-Step detail
      expect(find.byType(SafetyTipsScreen), findsOneWidget);
      expect(find.text('Bleeding Control'), findsWidgets);
      expect(find.text('STEP 1'), findsOneWidget);
      expect(find.text('Ensure Scene Safety & Use PPE'), findsOneWidget);
      expect(find.text('Apply a Tourniquet (If Necessary)'), findsOneWidget);
    });
  });

  group('Safety Step-by-Step Detail View (SafetyTipsScreen)', () {
    testWidgets('renders overview, steps, checkboxes, attribution and back button', (
      tester,
    ) async {
      await _bootApp(tester, route: '${AppRoutes.safety}/tips?situation=cpr');

      expect(find.byType(AppBackButton), findsOneWidget);
      expect(find.text('Adult CPR'), findsWidgets);
      expect(find.byType(UrgentBanner), findsOneWidget);

      // Verify Red Cross attribution footer
      expect(
        find.text(
          'Reference: Standard Red Cross First Aid & Adult CPR Guidelines',
        ),
        findsOneWidget,
      );

      // Verify CPR steps are present
      expect(find.text('STEP 1'), findsOneWidget);
      expect(find.text('STEP 7'), findsOneWidget);
      expect(find.text('Deliver 30 Chest Compressions'), findsOneWidget);
      expect(find.text('Deliver 2 Rescue Breaths'), findsOneWidget);

      // Check step progress tracker
      expect(find.text('0 of 7 steps completed'), findsOneWidget);

      // Tap step 1 card to mark done
      await tester.tap(find.text('Verify Scene Safety'));
      await tester.pumpAndSettle();

      expect(find.text('1 of 7 steps completed'), findsOneWidget);
    });

    testWidgets('Khmer translation renders without overflow or error', (
      tester,
    ) async {
      await _bootApp(
        tester,
        route: '${AppRoutes.safety}/tips?situation=bleeding',
        lang: AppLang.km,
      );

      expect(find.byType(SafetyTipsScreen), findsOneWidget);
      expect(find.byType(UrgentBanner), findsOneWidget);
      expect(find.text('ការទប់ឈាមហូរ'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
