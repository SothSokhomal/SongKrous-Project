import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songkrous/core/constants/app_state.dart';
import 'package:songkrous/core/constants/app_strings.dart';
import 'package:songkrous/core/constants/facilities.dart';
import 'package:songkrous/core/state/map_state.dart';
import 'package:songkrous/core/router/app_router.dart';
import 'package:songkrous/core/router/app_routes.dart';
import 'package:songkrous/main.dart';

/// Renders every route on a small phone (360x640 logical) in both languages.
/// Any RenderFlex overflow or build error fails the test.
void main() {
  final routes = <String>[
    AppRoutes.splash,
    AppRoutes.onboarding,
    AppRoutes.enterNumber,
    AppRoutes.otp,
    AppRoutes.gps,
    AppRoutes.home,
    AppRoutes.map,
    AppRoutes.safety,
    '${AppRoutes.safety}/tips?situation=car',
    '${AppRoutes.safety}/tips?situation=fire',
    '${AppRoutes.safety}/tips?situation=medical',
    AppRoutes.activity,
    AppRoutes.activityDetail,
    AppRoutes.hotlines,
    AppRoutes.sosCall,
    AppRoutes.calling('Calmette Hospital', '+855 23 426 948'),
  ];

  // Map with each category sheet open (long Khmer names stress the rows).
  for (final lang in AppLang.values) {
    for (final type in [null, ...FacilityType.values]) {
      testWidgets('map filter ${type?.name ?? 'all'} [${lang.name}]', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.read(langProvider.notifier).set(lang);
        container.read(selectedMapTargetProvider.notifier).set(type);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const SongkrousApp(),
          ),
        );
        appRouter.go(AppRoutes.map);
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final lang in AppLang.values) {
    for (final route in routes) {
      testWidgets('renders $route [${lang.name}]', (tester) async {
        tester.view.physicalSize = const Size(1080, 1920); // 360x640 @3x
        tester.view.devicePixelRatio = 3;
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
        // Pulsing animations never settle, so pump a fixed duration.
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
