import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:songkrous/core/constants/app_strings.dart';
import 'package:songkrous/core/constants/facilities.dart';
import 'package:songkrous/core/constants/khans.dart';
import 'package:songkrous/core/constants/phnom_penh_data.dart';
import 'package:songkrous/core/router/app_router.dart';
import 'package:songkrous/core/router/app_routes.dart';
import 'package:songkrous/core/utils/safe_launch.dart';
import 'package:songkrous/main.dart';
import 'package:songkrous/shared/widgets/songkrous_logo.dart';

void main() {
  // appRouter is a global singleton: always start from the splash.
  setUp(() => appRouter.go(AppRoutes.splash));

  test('Phnom Penh has 14 khans', () {
    expect(PhnomPenhKhans.all.length, 14);
  });

  test('strings have EN and KH', () {
    expect(AppStrings.of('sos_shortcut', AppLang.en), 'SOS');
    expect(AppStrings.of('next', AppLang.km), isNot('Next'));
    expect(AppStrings.of('missing_key', AppLang.km), 'missing_key');
  });

  test('facilities rank closest-first and filter by type', () {
    final all = rankFacilities(PhnomPenh.center);
    for (var i = 1; i < all.length; i++) {
      expect(all[i].km, greaterThanOrEqualTo(all[i - 1].km));
    }
    final hospitals = rankFacilities(
      PhnomPenh.center,
      type: FacilityType.hospital,
    );
    expect(
      hospitals.every((r) => r.facility.type == FacilityType.hospital),
      isTrue,
    );
    expect(
      rankFacilities(const LatLng(11.57, 104.92), query: 'calmette'),
      hasLength(1),
    );
  });

  test('sanitizePhone keeps only digits and a leading +', () {
    expect(sanitizePhone('+855 23 426 948'), '+85523426948');
    expect(sanitizePhone('(117)'), '117');
    expect(sanitizePhone('tel:117;rm -rf'), '117');
    expect(sanitizePhone('+85+5 23 426 948'), '+85523426948');
    expect(sanitizePhone('85+523426948'), '85523426948');
    expect(sanitizePhone(''), isNull);
    expect(sanitizePhone(null), isNull);
    expect(sanitizePhone('12'), isNull); // too short
    expect(sanitizePhone('1' * 17), isNull); // too long
    expect(sanitizePhone('abc'), isNull);
    expect(sanitizePhone('1' * 80), isNull);
  });

  testWidgets(
    'splash → onboarding → number → GPS → home (push flow + Heroes)',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ProviderScope(child: SongkrousApp()));
      await tester.pump(const Duration(milliseconds: 900)); // entrance done

      // Splash has the language pill and a 210 px logo.
      expect(find.byKey(const ValueKey('pill-km')), findsOneWidget);
      final splashLogo = tester.getSize(find.byType(SongkrousLogo));
      expect(splashLogo.width, 210);

      Future<void> tapAndSettle(Finder f) async {
        await tester.tap(f);
        // Route transition (300 ms) + Hero flight + stagger.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 800));
      }

      await tapAndSettle(find.text('បន្ទាប់')); // Next (Khmer default)
      expect(find.text('ជំនួយដោយចុចតែម្តង'), findsOneWidget);
      // Logo glided down to the onboarding size.
      expect(tester.getSize(find.byType(SongkrousLogo)).width, 120);
      // Language pill is still there (anchored).
      expect(find.byKey(const ValueKey('pill-km')), findsOneWidget);

      await tapAndSettle(find.text('បន្ត'));
      expect(find.textContaining('+855'), findsNothing); // no Latin digits
      expect(find.textContaining('+៨៥៥'), findsOneWidget);

      await tapAndSettle(find.text('រំលងសិន')); // Skip for now
      expect(find.text('មិនអនុញ្ញាត'), findsOneWidget); // Don't Allow

      await tapAndSettle(find.text('មិនអនុញ្ញាត'));
      expect(find.text('សង្គ្រោះ'), findsOneWidget);
      expect(find.text('ទីតាំងបិទ'), findsOneWidget);
      expect(find.textContaining('GPS'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('language pill on splash switches the whole UI', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: SongkrousApp()));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Next'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('pill-en')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Next'), findsOneWidget);
  });
}
