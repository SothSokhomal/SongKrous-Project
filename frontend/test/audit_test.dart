import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:songkrous/core/constants/app_state.dart';
import 'package:songkrous/core/constants/app_strings.dart';
import 'package:songkrous/core/constants/facilities.dart';
import 'package:songkrous/core/constants/phnom_penh_data.dart';
import 'package:songkrous/core/router/app_router.dart';
import 'package:songkrous/core/router/app_routes.dart';
import 'package:songkrous/core/state/auth_state.dart';
import 'package:songkrous/core/state/map_state.dart';
import 'package:songkrous/core/utils/safe_launch.dart';
import 'package:songkrous/features/chat/services/telegram_dispatch_service.dart';
import 'package:songkrous/main.dart';

/// Pre-launch audit: small-screen overflow sweep, safe URL launching, logout,
/// input limits and dispose-safety.
Future<ProviderContainer> boot(
  WidgetTester tester,
  String route, {
  AppLang lang = AppLang.en,
  Size logical = const Size(375, 667),
  double textScale = 1.0,
  Object? extra,
  void Function(ProviderContainer)? setup,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = logical * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final c = ProviderContainer(overrides: overrides);
  addTearDown(c.dispose);
  c.read(langProvider.notifier).set(lang);
  setup?.call(c);
  appRouter.go(AppRoutes.splash);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const SongkrousApp()),
  );
  appRouter.go(route, extra: extra);
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
  return c;
}

Future<void> ms(WidgetTester t, int total) async {
  for (var left = total; left > 0; left -= 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => appRouter.go(AppRoutes.splash));

  group('overflow sweep (no RenderFlex warnings)', () {
    final routes = <String, Object?>{
      AppRoutes.splash: null,
      AppRoutes.onboarding: null,
      AppRoutes.enterNumber: null,
      AppRoutes.otp: null,
      AppRoutes.gps: null,
      AppRoutes.home: null,
      AppRoutes.map: null,
      AppRoutes.safety: null,
      '${AppRoutes.safety}/tips?situation=car': null,
      '${AppRoutes.safety}/tips?situation=fire': null,
      '${AppRoutes.safety}/tips?situation=medical': null,
      AppRoutes.activity: null,
      AppRoutes.activityDetail: null,
      AppRoutes.hotlines: null,
      AppRoutes.settings: null,
      AppRoutes.sosCall: null,
      AppRoutes.calling('Calmette Hospital', '+855 23 426 948'): null,
      AppRoutes.chat: 'facility',
    };
    final sizes = <String, (Size, double)>{
      '320x568': (const Size(320, 568), 1.0),
      '375x667': (const Size(375, 667), 1.0),
      '375x667 @1.3x text': (const Size(375, 667), 1.3),
    };

    for (final lang in AppLang.values) {
      for (final s in sizes.entries) {
        for (final r in routes.entries) {
          testWidgets('${r.key} · ${lang.name} · ${s.key}', (tester) async {
            await boot(
              tester,
              r.key,
              lang: lang,
              logical: s.value.$1,
              textScale: s.value.$2,
              extra: r.value == null ? null : PhnomPenhData.defaultSos,
            );
            expect(tester.takeException(), isNull);
          });
        }
        // The map in State B, with the sheet and route card up.
        for (final type in FacilityType.values) {
          testWidgets('map ${type.name} · ${lang.name} · ${s.key}', (
            tester,
          ) async {
            await boot(
              tester,
              AppRoutes.map,
              lang: lang,
              logical: s.value.$1,
              textScale: s.value.$2,
              setup: (c) =>
                  c.read(selectedMapTargetProvider.notifier).set(type),
            );
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });

  group('safe phone launching', () {
    testWidgets('failed launch shows a friendly fallback (English)', (
      tester,
    ) async {
      final dialed = <String?>[];
      await boot(
        tester,
        AppRoutes.calling('Calmette', '+855 23 426 948'),
        overrides: [
          phoneLauncherProvider.overrideWithValue((n) async {
            dialed.add(n);
            return false;
          }),
        ],
      );
      await ms(tester, 400);
      expect(dialed, ['+855 23 426 948']);
      expect(
        find.text(
          "Couldn't open the phone app. Please dial the number yourself.",
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('fallback is Khmer in Khmer mode', (tester) async {
      await boot(
        tester,
        AppRoutes.calling('x', '119'),
        lang: AppLang.km,
        overrides: [
          phoneLauncherProvider.overrideWithValue((_) async => false),
        ],
      );
      await ms(tester, 400);
      expect(
        find.text('មិនអាចបើកកម្មវិធីទូរសព្ទបានទេ។ សូមហៅលេខនេះដោយខ្លួនឯង។'),
        findsOneWidget,
      );
    });

    testWidgets('a successful launch shows no error', (tester) async {
      await boot(
        tester,
        AppRoutes.calling('x', '119'),
        overrides: [phoneLauncherProvider.overrideWithValue((_) async => true)],
      );
      await ms(tester, 400);
      expect(find.textContaining("Couldn't open"), findsNothing);
    });

    test(
      'placeCall rejects malformed numbers without touching the OS',
      () async {
        expect(await placeCall('tel:abc;--'), isFalse);
        expect(await placeCall(''), isFalse);
        expect(await placeCall(null), isFalse);
        expect(await placeCall('1' * 40), isFalse);
      },
    );
  });

  group('log out', () {
    test('clears phone, channel and logged-in flag', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(authProfileProvider.notifier)
        ..setPhone('012 855 706')
        ..setChannel(OtpChannel.whatsapp)
        ..markLoggedIn();
      expect(c.read(authProfileProvider).isLoggedIn, isTrue);
      expect(c.read(authProfileProvider).phone, '12855706');
      n.logOut();
      final p = c.read(authProfileProvider);
      expect(p.phone, '');
      expect(p.channel, OtpChannel.sms);
      expect(p.isLoggedIn, isFalse);
      expect(p.isGuest, isTrue);
    });

    test('open chats are reset on log out', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final f = PhnomPenhData.defaultSos;
      c.read(authProfileProvider.notifier).markLoggedIn();
      c.read(chatProvider(f).notifier).sendText('private message');
      expect(c.read(chatProvider(f)).messages.length, 3); // seeds + 1
      c.read(authProfileProvider.notifier).logOut();
      expect(c.read(chatProvider(f)).messages.length, 2); // seeds only
      expect(
        c
            .read(chatProvider(f))
            .messages
            .any((m) => m.text == 'private message'),
        isFalse,
      );
    });
  });

  group('input limits', () {
    testWidgets('chat composer caps at 500 characters', (tester) async {
      await boot(tester, AppRoutes.chat, extra: PhnomPenhData.defaultSos);
      await tester.enterText(find.byType(TextField).last, 'a' * 800);
      await tester.pump();
      final t = tester.widget<TextField>(find.byType(TextField).last);
      expect(t.controller!.text.length, 500);
    });

    testWidgets('phone field caps digits; OTP field caps at 6', (tester) async {
      await boot(tester, AppRoutes.enterNumber);
      await tester.enterText(find.byType(TextField), '1' * 40);
      await tester.pump();
      final digits = tester
          .widget<TextField>(find.byType(TextField))
          .controller!
          .text
          .replaceAll(' ', '');
      expect(digits.length, lessThanOrEqualTo(9));

      await boot(tester, AppRoutes.otp);
      await tester.enterText(
        find.byKey(const ValueKey('otp-field')),
        '1234567890',
      );
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('otp-field')))
            .controller!
            .text,
        '123456',
      );
      await ms(tester, 900);
    });
  });

  group('dispose safety', () {
    testWidgets('leaving while "Sending code…" runs does not navigate late', (
      tester,
    ) async {
      await boot(tester, AppRoutes.enterNumber);
      await tester.enterText(find.byType(TextField), '12855706');
      await tester.tap(find.text('Send Verification Code'));
      await tester.pump(const Duration(milliseconds: 100));
      appRouter.go(AppRoutes.home); // leave mid-send
      await ms(tester, 1000);
      expect(
        appRouter.routerDelegate.currentConfiguration.last.matchedLocation,
        AppRoutes.home,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('leaving the OTP screen with timers pending is clean', (
      tester,
    ) async {
      await boot(tester, AppRoutes.otp);
      await tester.enterText(find.byKey(const ValueKey('otp-field')), '123456');
      await tester.pump(const Duration(milliseconds: 200));
      appRouter.go(AppRoutes.home);
      await ms(tester, 1500);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('no sensitive text is ever written to the console', (
    tester,
  ) async {
    final printed = <String>[];
    final old = debugPrint;
    debugPrint = (String? m, {int? wrapWidth}) => printed.add(m ?? '');
    try {
      await boot(tester, AppRoutes.otp);
      await tester.enterText(find.byKey(const ValueKey('otp-field')), '123456');
      await ms(tester, 1500);
    } finally {
      debugPrint = old; // must be restored before the test ends
    }
    final joined = printed.join('\n');
    expect(joined.contains('123456'), isFalse);
    expect(joined.contains('855706'), isFalse);
  });
}
