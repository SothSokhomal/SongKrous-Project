import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songkrous/core/constants/app_state.dart';
import 'package:songkrous/core/constants/app_strings.dart';
import 'package:songkrous/core/router/app_router.dart';
import 'package:songkrous/core/router/app_routes.dart';
import 'package:songkrous/main.dart';

Future<ProviderContainer> boot(
  WidgetTester tester,
  String route, {
  Size logical = const Size(360, 640),
}) async {
  tester.view.physicalSize = logical * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.read(langProvider.notifier).set(AppLang.km);
  appRouter.go(AppRoutes.splash);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const SongkrousApp()),
  );
  appRouter.go(route);
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return c;
}

void main() {
  setUp(() => appRouter.go(AppRoutes.splash));

  for (final route in [
    AppRoutes.splash,
    AppRoutes.onboarding,
    AppRoutes.settings,
  ]) {
    testWidgets('pill on $route shows flags, no language words', (
      tester,
    ) async {
      final c = await boot(tester, route);
      expect(find.text('🇰🇭'), findsOneWidget);
      expect(find.text('🇬🇧'), findsOneWidget);
      expect(find.text('English'), findsNothing);
      expect(find.text('ភាសាខ្មែរ'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('pill-en')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(c.read(langProvider), AppLang.en);
      await tester.tap(find.byKey(const ValueKey('pill-km')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(c.read(langProvider), AppLang.km);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('compact toggle (Home, OTP) uses flags and picks a language', (
    tester,
  ) async {
    for (final route in [AppRoutes.home, AppRoutes.otp]) {
      final c = await boot(tester, route);
      expect(find.text('🇰🇭'), findsOneWidget, reason: route);
      expect(find.text('🇬🇧'), findsOneWidget, reason: route);
      expect(find.textContaining('EN'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('compact-en')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(c.read(langProvider), AppLang.en);
      // Tapping the already-active flag is inert.
      await tester.tap(find.byKey(const ValueKey('compact-en')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(c.read(langProvider), AppLang.en);
      await tester.tap(find.byKey(const ValueKey('compact-km')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(c.read(langProvider), AppLang.km);
    }
  });

  testWidgets('flags fit the smallest phone without overflow', (tester) async {
    for (final route in [AppRoutes.home, AppRoutes.settings, AppRoutes.otp]) {
      await boot(tester, route, logical: const Size(320, 568));
      expect(tester.takeException(), isNull, reason: route);
    }
  });
}
