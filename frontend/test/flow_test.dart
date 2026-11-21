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
      expect(find.text('Start Route'), findsNothing);
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
    expect(find.text('Start Route'), findsOneWidget);
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
    // Pill + sheet row both show the mock closest-first station.
    expect(find.text('Phnom Penh Police Station (St. 598)'), findsNWidgets(2));
    expect(find.text('2 min • 0.4 km'), findsOneWidget); // nav pill
    expect(find.text('0.4 km · 2 min'), findsOneWidget); // sheet row
    expect(find.text('Start Route'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'row tap re-routes; Start Route shows the banner; Exit hides it',
    (tester) async {
      await boot(tester, AppRoutes.home);
      await tester.tap(find.text('Hospital'));
      await frames(tester, 12);
      expect(find.text('4 min • 1.2 km'), findsOneWidget); // Calmette (nearest)

      // Tapping another row updates the route target + pill.
      await tester.tap(find.text('Sunrise Japan Hospital'));
      await frames(tester);
      expect(find.text('8 min • 2.9 km'), findsOneWidget);

      await tester.tap(find.text('Start Route'));
      await frames(tester);
      expect(find.textContaining('Head '), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);
      expect(find.text('Search hospital, police, fire...'), findsNothing);
      expect(find.text('Call Now'), findsOneWidget);

      await tester.tap(find.text('Exit'));
      await frames(tester);
      expect(find.text('Exit'), findsNothing);
      expect(find.text('Search hospital, police, fire...'), findsOneWidget);
      expect(tester.takeException(), isNull);
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

    await tester.tap(find.text('All'));
    await frames(tester, 12);
    expect(c.read(selectedMapTargetProvider), isNull);
    expect(find.text('Nearby Fire Stations'), findsNothing);
    expect(find.text('Start Route'), findsNothing);

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

  testWidgets('round call button opens the outgoing call screen', (
    tester,
  ) async {
    await boot(tester, AppRoutes.home);
    await tester.tap(find.text('Hospital'));
    await frames(tester, 12);

    await tester.tap(find.byTooltip('Call').first);
    await frames(tester);
    expect(find.text('calling'), findsOneWidget);
    expect(find.text('Calmette Hospital'), findsOneWidget);
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
    expect(find.text('13 min • 4.5 km'), findsOneWidget);
    // The routed (3rd, farthest) row is scrolled into view, not clipped away.
    expect(find.text('4.5 km · 13 min').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
