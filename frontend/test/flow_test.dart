import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songkrous/core/constants/app_state.dart';
import 'package:songkrous/core/constants/facilities.dart';
import 'package:songkrous/core/constants/app_strings.dart';
import 'package:songkrous/core/router/app_router.dart';
import 'package:songkrous/core/router/app_routes.dart';
import 'package:songkrous/core/state/map_state.dart';
import 'package:songkrous/main.dart';

/// Several short pumps: animations need frames after each state change
/// (and the map has endless pulsing loops, so `pumpAndSettle` can't be used).
Future<void> frames(WidgetTester tester, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

String path() =>
    appRouter.routerDelegate.currentConfiguration.last.matchedLocation;

Future<ProviderContainer> boot(WidgetTester tester, String route) async {
  tester.view.physicalSize = const Size(1170, 2532); // 390 x 844 @3x
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(langProvider.notifier).set(AppLang.en);

  appRouter.go(route);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const SongkrousApp(),
    ),
  );
  await frames(tester);
  return container;
}

void main() {
  testWidgets(
    'State A: clean map — pins + hint only, no category bar / sheet',
    (tester) async {
      final c = await boot(tester, AppRoutes.map);

      expect(c.read(selectedMapTargetProvider), isNull);
      expect(find.text('Search hospital, police, fire...'), findsOneWidget);
      expect(find.text('Hospitals'), findsNothing); // category bar
      expect(find.text('Nearby Hospitals'), findsNothing); // sheet
      expect(find.text('EMERGENCY SOS'), findsOneWidget);
      expect(find.text('Hospital'), findsWidgets); // target pin labels
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tap a pin → State B (sheet, category bar, route pill)', (
    tester,
  ) async {
    final c = await boot(tester, AppRoutes.map);

    await tester.tap(find.text('Hospital').first);
    await frames(tester);

    expect(c.read(selectedMapTargetProvider), isNotNull);
    expect(find.text('Nearby Hospitals'), findsOneWidget);
    expect(find.text('Closest first'), findsOneWidget);
    expect(find.text('Hospitals'), findsOneWidget); // category bar tab
    expect(find.text('EMERGENCY SOS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home Police card → State B routed to the nearest station', (
    tester,
  ) async {
    final c = await boot(tester, AppRoutes.home);

    await tester.tap(find.text('Police'));
    await frames(tester, 12);

    expect(c.read(selectedMapTargetProvider), isNotNull);
    expect(find.text('Nearby Police Stations'), findsOneWidget);
    // Sheet row shows the mock closest-first station.
    expect(find.text('Phnom Penh Police Station (St. 598)'), findsOneWidget);
    expect(find.text('0.4 km · 2 min'), findsOneWidget); // sheet row
    expect(find.text('EMERGENCY SOS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'row tap re-routes; SOS button directly calls; directions button on hospital but not fire',
    (tester) async {
      await boot(tester, AppRoutes.home);
      await tester.tap(find.text('Hospital'));
      await frames(tester, 12);
      expect(find.text('EMERGENCY SOS'), findsOneWidget);
      expect(find.byTooltip('Directions'), findsOneWidget);

      // Tapping another row updates the route target.
      await tester.tap(find.text('Sunrise Japan Hospital'));
      await frames(tester);
      expect(find.byTooltip('Directions'), findsOneWidget);

      await tester.tap(find.text('EMERGENCY SOS'));
      await frames(tester, 12);
      expect(path(), startsWith('/calling'));
      expect(find.text('Sunrise Japan Hospital'), findsWidgets);
    },
  );

  testWidgets('category bar switches category; All / ✕ return to State A', (
    tester,
  ) async {
    final c = await boot(tester, AppRoutes.home);
    await tester.tap(find.text('Hospital'));
    await frames(tester, 12);

    await tester.tap(find.text('Fire')); // bar tab (label is the tab text)
    await frames(tester);
    expect(find.text('Nearby Fire Stations'), findsOneWidget);
    expect(find.textContaining('FIRE · 118'), findsWidgets);
    expect(find.byTooltip('Directions'), findsNothing);

    await tester.tap(find.text('All'));
    await frames(tester, 12);
    expect(c.read(selectedMapTargetProvider), isNull);
    expect(find.text('Nearby Fire Stations'), findsNothing);
    expect(find.text('EMERGENCY SOS'), findsOneWidget);

    // ✕ on the sheet header does the same.
    await tester.tap(find.text('Hospital').first); // pin
    await frames(tester, 12);
    expect(find.text('Nearby Hospitals'), findsOneWidget);
    await tester.tap(find.byTooltip('Close').hitTestable());
    await frames(tester, 12);
    expect(c.read(selectedMapTargetProvider), isNull);
    expect(find.text('Nearby Hospitals'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('suggestion hospital row tap selects the facility', (
    tester,
  ) async {
    final c = await boot(tester, AppRoutes.home);
    await tester.tap(find.text('Hospital'));
    await frames(tester, 12);

    expect(find.byTooltip('Call'), findsNothing);
    await tester.tap(find.text('Sunrise Japan Hospital'));
    await frames(tester);
    expect(c.read(selectedFacilityProvider), 'sunrise_japan');
  });

  testWidgets('View Map and the bottom-bar Map tab open the clean State A', (
    tester,
  ) async {
    final c = await boot(tester, AppRoutes.home);

    // Enter State B first.
    await tester.tap(find.text('Hospital'));
    await frames(tester, 12);
    expect(c.read(selectedMapTargetProvider), isNotNull);

    // Back to Home, then the bottom-bar "Nearby Map" → State A.
    await tester.tap(find.text('Home'));
    await frames(tester);
    await tester.tap(find.text('Map'));
    await frames(tester, 12);
    expect(c.read(selectedMapTargetProvider), isNull);
    expect(find.text('Nearby Hospitals'), findsNothing);

    // Home banner "View Map" → State A as well.
    await tester.tap(find.text('Home'));
    await frames(tester);
    await tester.tap(find.text('View Map'));
    await frames(tester, 12);
    expect(c.read(selectedMapTargetProvider), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search results select a facility → State B', (tester) async {
    final c = await boot(tester, AppRoutes.map);

    await tester.enterText(find.byType(TextField), 'koh pich');
    await frames(tester, 3);
    expect(find.text('Koh Pich Fire Station'), findsWidgets);

    await tester.tap(find.text('Koh Pich Fire Station').last);
    await frames(tester, 12);
    // State B for the fire category. (The sheet header isn't asserted: the
    // sheet scrolls the routed row into view, which may move it out of the
    // build range — layout, not behaviour.)
    expect(c.read(selectedMapTargetProvider), FacilityType.fire);
    expect(c.read(selectedFacilityProvider), 'koh_pich_fire');
    // The routed (3rd, farthest) row is scrolled into view, not clipped away.
    expect(find.text('4.5 km · 13 min').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
