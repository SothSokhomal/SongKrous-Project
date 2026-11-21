import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songkrous/core/constants/app_state.dart';
import 'package:songkrous/core/constants/app_strings.dart';
import 'package:songkrous/core/constants/facilities.dart';
import 'package:songkrous/core/router/app_router.dart';
import 'package:songkrous/core/router/app_routes.dart';
import 'package:songkrous/core/state/map_state.dart';
import 'package:songkrous/features/map/widgets/facility_sheet.dart';
import 'package:songkrous/features/map/widgets/navigation_widgets.dart';
import 'package:songkrous/main.dart';

const double kH = 844; // logical height of the test screen

Future<void> frames(WidgetTester tester, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<ProviderContainer> bootMap(
  WidgetTester tester, {
  bool openMedical = true,
}) async {
  tester.view.physicalSize = const Size(1170, 2532); // 390 x 844 @3x
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.read(langProvider.notifier).set(AppLang.en);
  appRouter.go(AppRoutes.map);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const SongkrousApp()),
  );
  await frames(tester, 4);
  if (openMedical) {
    c.read(selectedMapTargetProvider.notifier).set(EmergencyCategory.hospital);
    await frames(tester, 14);
  }
  return c;
}

Rect sheetRect(WidgetTester t) => t.getRect(find.byType(NearbySheet));
Rect pillRect(WidgetTester t) => t.getRect(find.byType(NavInfoPill));

void main() {
  testWidgets('State A has no sheet; State B docks one at the very bottom', (
    tester,
  ) async {
    await bootMap(tester, openMedical: false);
    expect(find.byType(NearbySheet), findsNothing);

    final c = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
      listen: false,
    );
    c.read(selectedMapTargetProvider.notifier).set(EmergencyCategory.hospital);
    await frames(tester, 14);

    final r = sheetRect(tester);
    // Docked to the bottom edge (under the floating nav), full width.
    expect(r.bottom, closeTo(kH, 0.5));
    expect(r.left, 0);
    expect(r.width, 390);
    // Opened to the half-open snap (0.45 of the height).
    expect(r.top, closeTo(kH * (1 - 0.45), 2));
    expect(find.text('Nearby Hospitals'), findsOneWidget);
    expect(find.text('Hospitals'), findsOneWidget); // tabs revealed
    expect(tester.takeException(), isNull);
  });

  testWidgets('route pill rides 12px above the sheet top and follows drags', (
    tester,
  ) async {
    await bootMap(tester);
    expect(sheetRect(tester).top - pillRect(tester).bottom, closeTo(12, 1));

    // Drag the sheet up part-way (no release yet): the pill follows frame by
    // frame, staying 12 px above the sheet's top edge.
    final g = await tester.startGesture(const Offset(195, 600));
    await g.moveBy(const Offset(0, -30)); // consumed by touch slop
    await tester.pump(const Duration(milliseconds: 16));
    await g.moveBy(const Offset(0, -80));
    await tester.pump(const Duration(milliseconds: 50));
    expect(sheetRect(tester).top, lessThan(kH * 0.55 - 40));
    expect(sheetRect(tester).top - pillRect(tester).bottom, closeTo(12, 1));
    await g.up();
    await frames(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drag down → peek (title + count + swipe hint), map unobscured', (
    tester,
  ) async {
    await bootMap(tester);
    await tester.drag(find.text('Nearby Hospitals'), const Offset(0, 500));
    await frames(tester, 14);

    expect(find.text('Nearby Hospitals (3)'), findsOneWidget);
    expect(find.text('Swipe up'), findsOneWidget);
    expect(find.text('Closest first').hitTestable(), findsNothing);
    // Rows are faded out *and* inert (the route pill still shows the name).
    expect(
      find
          .descendant(
            of: find.byType(NearbySheet),
            matching: find.text('Calmette Hospital'),
          )
          .hitTestable(),
      findsNothing,
    );
    // Peek is small: > 70% of the screen stays free.
    expect(sheetRect(tester).top, greaterThan(kH * 0.72));
    // Pill still floats just above the (now lower) sheet.
    expect(sheetRect(tester).top - pillRect(tester).bottom, closeTo(12, 1));
    expect(find.text('EMERGENCY SOS').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drag up → fully open; route pill fades out (no search clash)', (
    tester,
  ) async {
    await bootMap(tester);
    await tester.drag(find.text('Nearby Hospitals'), const Offset(0, -600));
    await frames(tester, 14);

    expect(sheetRect(tester).top, lessThan(kH * 0.30));
    expect(find.text('Calmette Hospital'), findsWidgets);
    expect(find.text('EMERGENCY SOS').hitTestable(), findsNothing); // faded out
    expect(tester.takeException(), isNull);
  });

  testWidgets('dragging from the rows (not just the handle) moves the sheet', (
    tester,
  ) async {
    await bootMap(tester);
    final before = sheetRect(tester).top;
    // The row inside the sheet (the first match is the route pill). Moved in
    // steps: a single jump is swallowed by the touch slop.
    final row = find.descendant(
      of: find.byType(NearbySheet),
      matching: find.text('Calmette Hospital'),
    );
    final g = await tester.startGesture(tester.getCenter(row));
    for (var i = 0; i < 6; i++) {
      await g.moveBy(const Offset(0, 40));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await frames(tester, 14);
    expect(sheetRect(tester).top, greaterThan(before + 100));
  });

  testWidgets('handle tap toggles peek ⇄ half-open', (tester) async {
    await bootMap(tester);
    final open = sheetRect(tester).top;

    await tester.tap(find.bySemanticsLabel('Toggle list'));
    await frames(tester, 12);
    expect(sheetRect(tester).top, greaterThan(open + 150)); // collapsed
    expect(find.text('Nearby Hospitals (3)'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Toggle list'));
    await frames(tester, 12);
    expect(sheetRect(tester).top, closeTo(open, 2)); // open again
    expect(find.text('Nearby Hospitals'), findsOneWidget);
  });

  testWidgets('✕ in the peek header returns to State A and removes the sheet', (
    tester,
  ) async {
    final c = await bootMap(tester);
    await tester.tap(find.bySemanticsLabel('Toggle list'));
    await frames(tester, 12);

    await tester.tap(find.byTooltip('Close').hitTestable());
    await frames(tester, 14);
    expect(c.read(selectedMapTargetProvider), isNull);
    expect(find.byType(NearbySheet), findsNothing);
    expect(find.byType(NavInfoPill), findsNothing);
  });

  testWidgets('a pin tap while peeking re-opens the sheet to half-open', (
    tester,
  ) async {
    await bootMap(tester);
    await tester.tap(find.bySemanticsLabel('Toggle list'));
    await frames(tester, 12);
    expect(find.text('Nearby Hospitals (3)'), findsOneWidget);

    await tester.tap(find.text('Hospital').first); // a map pin label
    await frames(tester, 14);
    expect(sheetRect(tester).top, closeTo(kH * (1 - 0.45), 2));
    expect(find.text('Nearby Hospitals'), findsOneWidget);
  });

  testWidgets('selected row is never hidden under the floating nav bar', (
    tester,
  ) async {
    final c = await bootMap(tester);
    // Route to the farthest hospital (3rd row).
    c.read(selectedFacilityProvider.notifier).set('khmer_soviet');
    await frames(tester, 16);
    expect(find.text('3.8 km · 11 min').hitTestable(), findsOneWidget);
    final row = tester.getRect(find.text('3.8 km · 11 min'));
    expect(row.bottom, lessThan(kH - 88)); // above the 88px nav bar
  });
}
