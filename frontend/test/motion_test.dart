import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songkrous/core/animations/looping_animation.dart';
import 'package:songkrous/core/animations/pulsing_beacon.dart';
import 'package:songkrous/core/animations/staggered_entrance.dart';
import 'package:songkrous/core/animations/tactile_scale_button.dart';
import 'package:songkrous/core/router/app_router.dart';
import 'package:songkrous/core/router/app_routes.dart';
import 'package:songkrous/main.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('StaggeredEntrance: staggered fade + slide, child not rebuilt', (
    tester,
  ) async {
    var builds = 0;
    final probe = Builder(
      builder: (_) {
        builds++;
        return const SizedBox(width: 50, height: 20, key: Key('probe'));
      },
    );

    await tester.pumpWidget(
      _host(
        StaggerScope(
          duration: const Duration(milliseconds: 600),
          builder: (_, a) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StaggeredEntrance(
                animation: a,
                begin: 0.0,
                end: 0.5,
                child: probe,
              ),
              const StaggeredEntrance(
                key: Key('late'),
                animation: kAlwaysDismissedAnimation,
                child: SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );

    double opacityAt() => tester
        .widget<FadeTransition>(
          find
              .descendant(
                of: find.byType(StaggeredEntrance).first,
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;

    expect(opacityAt(), 0.0);
    await tester.pump(const Duration(milliseconds: 150));
    final mid = opacityAt();
    expect(mid, greaterThan(0.0));
    expect(mid, lessThan(1.0));
    await tester.pump(const Duration(milliseconds: 600));
    expect(opacityAt(), 1.0);
    // Ticks animated the wrapper only; the static child was built once.
    expect(builds, 1);
  });

  testWidgets('StaggerScope honours reduce-motion (jumps to the end)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        StaggerScope(
          builder: (_, a) =>
              StaggeredEntrance(animation: a, child: const Text('hello')),
        ),
        reduceMotion: true,
      ),
    );
    final fade = tester.widget<FadeTransition>(
      find
          .descendant(
            of: find.byType(StaggeredEntrance),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, 1.0);
  });

  testWidgets('LoopingAnimation loops, freezes under reduce-motion, disposes', (
    tester,
  ) async {
    final seen = <double>[];
    await tester.pumpWidget(
      _host(
        LoopingAnimation(
          duration: const Duration(milliseconds: 1000),
          reverse: true,
          builder: (_, a) => AnimatedBuilder(
            animation: a,
            builder: (_, _) {
              seen.add(a.value);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(
      const Duration(milliseconds: 700),
    ); // past the turn-around
    expect(seen.toSet().length, greaterThan(2));
    // Removing it must not leave an active ticker (test would fail).
    await tester.pumpWidget(_host(const SizedBox()));

    seen.clear();
    await tester.pumpWidget(
      _host(
        LoopingAnimation(
          duration: const Duration(milliseconds: 1000),
          builder: (_, a) => AnimatedBuilder(
            animation: a,
            builder: (_, _) {
              seen.add(a.value);
              return const SizedBox();
            },
          ),
        ),
        reduceMotion: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(seen.toSet(), {0.0});
  });

  testWidgets('LiveBeacon renders and keeps its static core', (tester) async {
    await tester.pumpWidget(
      _host(
        const LiveBeacon(
          color: Colors.blue,
          size: 8,
          child: SizedBox(key: Key('core'), width: 8, height: 8),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(PulsingBeacon), findsOneWidget);
    expect(find.byKey(const Key('core')), findsOneWidget);
  });

  testWidgets('TactileScaleButton scales to 0.97 while pressed and taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        TactileScaleButton(
          onTap: () => taps++,
          child: const SizedBox(width: 100, height: 100, key: Key('btn')),
        ),
      ),
    );
    double scale() => tester
        .widget<ScaleTransition>(
          find.descendant(
            of: find.byType(TactileScaleButton),
            matching: find.byType(ScaleTransition),
          ),
        )
        .scale
        .value;

    expect(scale(), 1.0);
    final g = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('btn'))),
    );
    await tester.pump(const Duration(milliseconds: 150)); // tap-down delay
    await tester.pump(const Duration(milliseconds: 200)); // animation
    expect(scale(), closeTo(0.97, 0.001));
    await g.up();
    await tester.pumpAndSettle();
    expect(scale(), 1.0);
    expect(taps, 1);

    // Cancelled press also springs back.
    final g2 = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('btn'))),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await g2.moveBy(const Offset(0, 300));
    await g2.up();
    await tester.pumpAndSettle();
    expect(scale(), 1.0);
    expect(taps, 1);
  });

  testWidgets('Home: staggered in, live GPS beacon only when GPS active', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: SongkrousApp()));
    appRouter.go(AppRoutes.home);
    await tester.pump(const Duration(milliseconds: 50));
    // Cards start invisible, then fade in.
    final firstCard = find.byType(StaggeredEntrance).first;
    double opacity() => tester
        .widget<FadeTransition>(
          find
              .descendant(of: firstCard, matching: find.byType(FadeTransition))
              .first,
        )
        .opacity
        .value;
    expect(opacity(), lessThan(1.0));
    await tester.pump(const Duration(milliseconds: 900));
    expect(opacity(), 1.0);
    // GPS is off by default in tests → no beacon.
    expect(find.byType(PulsingBeacon), findsNothing);
  });

  testWidgets('Safety tips: breathing ring runs on "Take a gentle breath"', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: SongkrousApp()));
    appRouter.go('${AppRoutes.safety}/tips?situation=car');
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(LoopingAnimation), findsOneWidget);

    // Fire situation has no breathing tip.
    appRouter.go('${AppRoutes.safety}/tips?situation=fire');
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(LoopingAnimation), findsNothing);
  });
}
