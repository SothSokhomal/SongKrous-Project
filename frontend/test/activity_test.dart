import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songkrous/core/constants/app_state.dart';
import 'package:songkrous/core/constants/app_strings.dart';
import 'package:songkrous/core/router/app_router.dart';
import 'package:songkrous/core/router/app_routes.dart';
import 'package:songkrous/features/activity/activity_detail_screen.dart';
import 'package:songkrous/features/activity/activity_screen.dart';
import 'package:songkrous/features/activity/models/emergency_activity.dart';
import 'package:songkrous/main.dart';
import 'package:songkrous/shared/widgets/app_interactive.dart';

Future<void> frames(WidgetTester tester, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

String path() =>
    appRouter.routerDelegate.currentConfiguration.last.matchedLocation;

Future<ProviderContainer> boot(
  WidgetTester tester, {
  String route = AppRoutes.home,
  AppLang lang = AppLang.en,
}) async {
  tester.view.physicalSize = const Size(1170, 2532); // 390 x 844 @3x
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.read(langProvider.notifier).set(lang);
  appRouter.go(route);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const SongkrousApp()),
  );
  await frames(tester, 8);
  return c;
}

void main() {
  group('Activity Tab & List Screen', () {
    testWidgets('global navigation has Activity tab; tapping it opens ActivityScreen', (
      tester,
    ) async {
      await boot(tester);

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Safety Tips'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Settings'), findsWidgets);

      await tester.tap(find.text('Activity'));
      await frames(tester, 10);

      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.byType(ActivityScreen), findsOneWidget);
    });

    testWidgets('activity screen displays sample emergency records and filter chips', (
      tester,
    ) async {
      await boot(tester, route: AppRoutes.activity);

      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Past emergency calls & SOS dispatches'), findsNothing);

      // Verify all filter chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Hospital'), findsWidgets);
      expect(find.text('Police'), findsWidgets);
      expect(find.text('Fire Station'), findsWidgets);
      expect(find.text('SOS'), findsWidgets);

      // Verify sample records are present
      expect(find.text('Calmette Hospital — Emergency Call'), findsOneWidget);
      expect(find.text('Central Police — Patrol Request'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Fire Station — Rescue Call'), 150);
      expect(find.text('Fire Station — Rescue Call'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Emergency SOS — Direct Alert'), 150);
      expect(find.text('Emergency SOS — Direct Alert'), findsOneWidget);
      expect(find.text('Dispatched'), findsOneWidget);
    });

    testWidgets('filter chips filter the activity list by service', (
      tester,
    ) async {
      await boot(tester, route: AppRoutes.activity);

      // Filter by Hospital
      await tester.tap(find.text('Hospital').first);
      await frames(tester, 4);
      expect(find.text('Calmette Hospital — Emergency Call'), findsOneWidget);
      expect(find.text('Central Police — Patrol Request'), findsNothing);
      expect(find.text('Fire Station — Rescue Call'), findsNothing);

      // Filter by Police
      await tester.tap(find.text('Police').first);
      await frames(tester, 4);
      expect(find.text('Central Police — Patrol Request'), findsOneWidget);
      expect(find.text('Calmette Hospital — Emergency Call'), findsNothing);

      // Filter by Fire Station
      await tester.tap(find.text('Fire Station').first);
      await frames(tester, 4);
      expect(find.text('Fire Station — Rescue Call'), findsOneWidget);
      expect(find.text('Central Police — Patrol Request'), findsNothing);

      // Return to All
      await tester.tap(find.text('All'));
      await frames(tester, 4);
      expect(find.text('Calmette Hospital — Emergency Call'), findsOneWidget);
      expect(find.text('Central Police — Patrol Request'), findsOneWidget);
    });
  });

  group('Activity Detail Screen (Grab-Style Layout)', () {
    testWidgets('tapping a card opens ActivityDetailScreen populated with data', (
      tester,
    ) async {
      await boot(tester, route: AppRoutes.activity);

      await tester.tap(find.text('Calmette Hospital — Emergency Call'));
      await frames(tester, 12);

      expect(find.byType(ActivityDetailScreen), findsOneWidget);
      expect(path(), AppRoutes.activityDetail);

      // Top bar date & time
      expect(find.text('19 Nov 2026, 05:24 PM'), findsOneWidget);

      // Reference ID Row
      expect(find.text('Incident ID'), findsOneWidget);
      expect(find.text('SOS-2026-89124K'), findsOneWidget);

      // Responder / Unit Card
      expect(find.text('Calmette Emergency Unit #03'), findsOneWidget);
      expect(find.text('Dr. Sokha (Lead Paramedic)'), findsOneWidget);
      expect(find.text('ER Paramedic'), findsOneWidget);

      // Map & Route summary card
      expect(find.text('Hospital Dispatch'), findsOneWidget);
      expect(find.text('5.68 km • 12 min'), findsOneWidget);
      expect(find.text('St. 598, Khan Tuol Kouk, Phnom Penh'), findsOneWidget);
      expect(find.text('Calmette Hospital ER, Monivong Blvd'), findsOneWidget);

      // Response rating card
      expect(find.text('Response rating'), findsOneWidget);
      expect(find.text('5 ★ • Fast Response'), findsOneWidget);

      // Call & dispatch info card
      expect(find.text('Call & dispatch info'), findsOneWidget);
      expect(find.text('Voice Call + Live GPS'), findsOneWidget);
      expect(find.text('High — Emergency SOS'), findsOneWidget);
      expect(find.text('Personal'), findsOneWidget);

      // Smooth back-navigation
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await frames(tester, 12);
      expect(find.byType(ActivityScreen), findsOneWidget);
      expect(path(), AppRoutes.activity);
    });

    testWidgets('star rating is interactive and updates rating display', (
      tester,
    ) async {
      await boot(tester, route: AppRoutes.activity);
      // Filter by Fire Station so card is at the top of the list away from floating nav
      await tester.tap(find.text('Fire Station').first);
      await frames(tester, 4);
      await tester.tap(find.text('Fire Station — Rescue Call'));
      await frames(tester, 12);

      expect(find.text('Fire Engine #02 — Team Bravo'), findsOneWidget);
      expect(find.text('FIR-2026-10382F'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('5 ★ • Fire controlled swiftly'), 150);
      expect(find.text('5 ★ • Fire controlled swiftly'), findsOneWidget);

      // Tap 4th star
      final stars = find.byIcon(Icons.star_rounded);
      expect(stars, findsNWidgets(5));
      await tester.tap(stars.at(3));
      await frames(tester, 4);

      expect(find.text('4 ★ • Fire controlled swiftly'), findsOneWidget);
    });

    testWidgets('copy incident ID triggers clipboard and SnackBar', (
      tester,
    ) async {
      await boot(tester, route: AppRoutes.activity);
      await tester.tap(find.text('Calmette Hospital — Emergency Call'));
      await frames(tester, 12);

      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Incident ID copied to clipboard'), findsOneWidget);
    });
  });
}
