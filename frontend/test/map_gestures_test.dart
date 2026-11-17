import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songkrous/core/constants/app_state.dart';
import 'package:songkrous/core/constants/app_strings.dart';
import 'package:songkrous/core/constants/facilities.dart';
import 'package:songkrous/core/router/app_router.dart';
import 'package:songkrous/core/router/app_routes.dart';
import 'package:songkrous/core/state/map_state.dart';
import 'package:songkrous/main.dart';

Future<void> frames(WidgetTester tester, [int n = 10, int ms = 120]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

MapCamera cam(WidgetTester t) =>
    t.widget<FlutterMap>(find.byType(FlutterMap)).mapController!.camera;

Future<ProviderContainer> boot(
  WidgetTester tester, {
  bool stateB = false,
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
  await frames(tester, 5);
  if (stateB) {
    c.read(selectedMapTargetProvider.notifier).set(EmergencyCategory.hospital);
    await frames(tester, 16);
  }
  return c;
}

/// Drags in small steps (a single jump is swallowed by touch slop) and lets
/// any fling momentum finish.
Future<void> drag(WidgetTester tester, Offset from, Offset delta) async {
  final g = await tester.startGesture(from);
  const steps = 8;
  for (var i = 0; i < steps; i++) {
    await g.moveBy(delta / steps.toDouble());
    await tester.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await frames(tester, 12);
}

void main() {
  for (final stateB in [false, true]) {
    final label = stateB ? 'State B' : 'State A';

    group(label, () {
      testWidgets('drag pans left/right/up/down', (tester) async {
        await boot(tester, stateB: stateB);
        // Empty map area, away from pins, the sheet and the controls.
        const p = Offset(60, 330);

        var c0 = cam(tester).center;
        await drag(tester, p, const Offset(-120, 0)); // finger left → east
        var c1 = cam(tester).center;
        expect(c1.longitude, greaterThan(c0.longitude + 0.002), reason: 'left');

        c0 = cam(tester).center;
        await drag(tester, p, const Offset(120, 0)); // finger right → west
        c1 = cam(tester).center;
        expect(c1.longitude, lessThan(c0.longitude - 0.002), reason: 'right');

        c0 = cam(tester).center;
        await drag(tester, p, const Offset(0, -100)); // finger up → south
        c1 = cam(tester).center;
        expect(c1.latitude, lessThan(c0.latitude - 0.002), reason: 'up');

        c0 = cam(tester).center;
        await drag(tester, p, const Offset(0, 100)); // finger down → north
        c1 = cam(tester).center;
        expect(c1.latitude, greaterThan(c0.latitude + 0.002), reason: 'down');
        expect(tester.takeException(), isNull);
      });

      testWidgets('the camera does not snap back after panning', (
        tester,
      ) async {
        await boot(tester, stateB: stateB);
        await drag(tester, const Offset(60, 330), const Offset(-150, 60));
        await frames(tester, 6);
        final settled = cam(tester).center;
        await frames(tester, 15, 200); // 3 s of idle frames
        final later = cam(tester).center;
        expect(later.latitude, closeTo(settled.latitude, 1e-9));
        expect(later.longitude, closeTo(settled.longitude, 1e-9));
      });

      testWidgets('pinch zooms in and out', (tester) async {
        await boot(tester, stateB: stateB);
        final z0 = cam(tester).zoom;

        final a = await tester.startGesture(const Offset(140, 330), pointer: 1);
        final b = await tester.startGesture(const Offset(240, 330), pointer: 2);
        for (var i = 0; i < 8; i++) {
          await a.moveBy(const Offset(-8, 0));
          await b.moveBy(const Offset(8, 0));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await a.up();
        await b.up();
        await frames(tester, 6);
        final zIn = cam(tester).zoom;
        expect(zIn, greaterThan(z0 + 0.3), reason: 'pinch out zooms in');

        final c = await tester.startGesture(const Offset(100, 330), pointer: 3);
        final d = await tester.startGesture(const Offset(280, 330), pointer: 4);
        for (var i = 0; i < 8; i++) {
          await c.moveBy(const Offset(10, 0));
          await d.moveBy(const Offset(-10, 0));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await c.up();
        await d.up();
        await frames(tester, 6);
        expect(cam(tester).zoom, lessThan(zIn - 0.3), reason: 'pinch in');
      });

      testWidgets('double tap and mouse wheel zoom', (tester) async {
        await boot(tester, stateB: stateB);
        const p = Offset(60, 330);

        final z0 = cam(tester).zoom;
        await tester.tapAt(p);
        await tester.pump(const Duration(milliseconds: 60));
        await tester.tapAt(p);
        await frames(tester, 10);
        expect(cam(tester).zoom, greaterThan(z0 + 0.5), reason: 'double tap');

        final z1 = cam(tester).zoom;
        final mouse = TestPointer(9, PointerDeviceKind.mouse);
        await tester.sendEventToBinding(mouse.hover(p));
        await tester.sendEventToBinding(mouse.scroll(const Offset(0, -120)));
        await frames(tester, 6);
        expect(cam(tester).zoom, isNot(closeTo(z1, 0.05)), reason: 'wheel');
      });

      testWidgets('zoom is limited to 10.5 – 19', (tester) async {
        await boot(tester, stateB: stateB);
        for (var i = 0; i < 6; i++) {
          final a = await tester.startGesture(
            const Offset(150, 330),
            pointer: 1,
          );
          final b = await tester.startGesture(
            const Offset(240, 330),
            pointer: 2,
          );
          for (var k = 0; k < 10; k++) {
            await a.moveBy(const Offset(-10, 0));
            await b.moveBy(const Offset(10, 0));
            await tester.pump(const Duration(milliseconds: 16));
          }
          await a.up();
          await b.up();
          await frames(tester, 3);
        }
        expect(cam(tester).zoom, lessThanOrEqualTo(19.0));
        for (var i = 0; i < 8; i++) {
          final a = await tester.startGesture(
            const Offset(80, 330),
            pointer: 1,
          );
          final b = await tester.startGesture(
            const Offset(300, 330),
            pointer: 2,
          );
          for (var k = 0; k < 10; k++) {
            await a.moveBy(const Offset(12, 0));
            await b.moveBy(const Offset(-12, 0));
            await tester.pump(const Duration(milliseconds: 16));
          }
          await a.up();
          await b.up();
          await frames(tester, 3);
        }
        expect(cam(tester).zoom, greaterThanOrEqualTo(10.5));
      });
    });
  }

  testWidgets('empty strips beside the controls pass touches to the map', (
    tester,
  ) async {
    await boot(tester);
    // Right of the Khan pill (inside the top-controls box) …
    var c0 = cam(tester).center;
    await drag(tester, const Offset(365, 92), const Offset(-100, 0));
    expect(cam(tester).center.longitude, greaterThan(c0.longitude + 0.001));

    // … and in the margin beside the floating nav bar.
    c0 = cam(tester).center;
    await drag(tester, const Offset(6, 815), const Offset(0, -80));
    expect(cam(tester).center.latitude, lessThan(c0.latitude - 0.001));
  });

  testWidgets('touching the map cancels an in-flight camera animation', (
    tester,
  ) async {
    await boot(tester, stateB: false);
    final c = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
      listen: false,
    );
    // Starts the one-time camera move towards the route…
    c.read(selectedMapTargetProvider.notifier).set(EmergencyCategory.fire);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // …the user puts a finger down mid-animation: the camera must freeze.
    final g = await tester.startGesture(const Offset(60, 330));
    await tester.pump(const Duration(milliseconds: 30));
    final held = cam(tester).center;
    await frames(tester, 8, 100);
    expect(cam(tester).center.latitude, closeTo(held.latitude, 1e-9));
    expect(cam(tester).center.longitude, closeTo(held.longitude, 1e-9));
    await g.up();
  });
}
