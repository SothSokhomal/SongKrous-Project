import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songkrous/core/constants/app_state.dart';
import 'package:songkrous/core/constants/app_strings.dart';
import 'package:songkrous/core/router/app_router.dart';
import 'package:songkrous/core/router/app_routes.dart';
import 'package:songkrous/core/state/auth_state.dart';
import 'package:songkrous/core/utils/phone_format.dart';
import 'package:songkrous/main.dart';

Future<void> ms(WidgetTester t, int total) async {
  var left = total;
  while (left > 0) {
    final step = left > 100 ? 100 : left;
    await t.pump(Duration(milliseconds: step));
    left -= step;
  }
}

final haptics = <String>[];

Future<ProviderContainer> boot(
  WidgetTester tester, {
  String route = AppRoutes.enterNumber,
  AppLang lang = AppLang.en,
  String phone = '',
  Size size = const Size(1080, 1920), // 360x640
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  haptics.clear();
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        final a = call.arguments;
        haptics.add(
          a is String ? a.replaceFirst('HapticFeedbackType.', '') : 'vibrate',
        );
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.read(langProvider.notifier).set(lang);
  if (phone.isNotEmpty) c.read(authProfileProvider.notifier).setPhone(phone);
  appRouter.go(route);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const SongkrousApp()),
  );
  await ms(tester, 500);
  return c;
}

/// Top-most page, including imperatively pushed ones.
String currentPath() =>
    appRouter.routerDelegate.currentConfiguration.last.matchedLocation;

String phoneText(WidgetTester t) =>
    t.widget<TextField>(find.byType(TextField)).controller!.text;

final otpField = find.byKey(const ValueKey('otp-field'));
final cta = find.byKey(const ValueKey('otp-cta'));

Future<void> enter(WidgetTester t, String code) async {
  await t.enterText(otpField, code);
  await t.pump();
}

void main() {
  khmerEnterNumberScan();
  group('phone formatting', () {
    test('groups, drops the trunk 0, accepts Khmer numerals', () {
      expect(groupPhone('12855706'), '12 855 706');
      expect(groupPhone('128557061'), '12 855 7061');
      expect(cleanPhoneDigits('012 855 706'), '12855706');
      expect(cleanPhoneDigits('១២ ៨៥៥ ៧០៦'), '12855706');
      expect(cleanPhoneDigits('1234567890123'), '123456789');
      expect(isValidPhone('1234567'), isFalse);
      expect(isValidPhone('12855706'), isTrue);
    });
  });

  group('02 enter the number', () {
    testWidgets(
      'the button is never dead: invalid → shake, heavy haptic, prompt',
      (tester) async {
        await boot(tester);
        final btn = find.text('Send Verification Code');
        expect(find.byKey(const ValueKey('phone-error')), findsNothing);

        // Empty field.
        await tester.tap(btn);
        await tester.pump(const Duration(milliseconds: 60));
        expect(haptics, contains('heavyImpact'));
        expect(
          find.text('Please enter a valid phone number, or tap Skip for now'),
          findsOneWidget,
        );
        // Mid-shake the input row is displaced, then settles back.
        final field = find.byType(TextField);
        final x0 = tester.getTopLeft(field).dx;
        await tester.pump(const Duration(milliseconds: 40));
        expect(tester.getTopLeft(field).dx, isNot(closeTo(x0, 0.01)));
        await ms(tester, 500);
        expect(tester.getTopLeft(field).dx, closeTo(x0, 0.5));
        expect(currentPath(), AppRoutes.enterNumber);

        // Too short is still handled, not ignored.
        haptics.clear();
        await tester.enterText(field, '12345');
        await tester.pump();
        await tester.tap(btn);
        await ms(tester, 100);
        expect(haptics, contains('heavyImpact'));
        expect(currentPath(), AppRoutes.enterNumber);

        // Becoming valid clears the prompt.
        await tester.enterText(field, '12855706');
        await ms(tester, 300);
        expect(find.byKey(const ValueKey('phone-error')), findsNothing);
      },
    );

    testWidgets('accepts 012 855 706 / 12 855 706 / 012855706 / 8-10 digits', (
      tester,
    ) async {
      final c = await boot(tester);
      for (final typed in ['012 855 706', '12 855 706', '012855706']) {
        await tester.enterText(find.byType(TextField), typed);
        await tester.pump();
        expect(c.read(userPhoneProvider), '12855706', reason: typed);
      }
      // Display keeps what was typed, spaced automatically.
      await tester.enterText(find.byType(TextField), '012855706');
      await tester.pump();
      expect(phoneText(tester), '012 855 706');
      await tester.enterText(find.byType(TextField), '0128557061');
      await tester.pump();
      expect(c.read(userPhoneProvider), '128557061');
      expect(isValidPhone(c.read(userPhoneProvider)), isTrue);
    });

    testWidgets('valid number: 350 ms "Sending code…", saved, → OTP', (
      tester,
    ) async {
      final c = await boot(tester);
      await tester.enterText(find.byType(TextField), '12 855 706');
      await tester.pump();
      await tester.tap(find.text('Send Verification Code'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Sending code...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(currentPath(), AppRoutes.enterNumber);

      // A second tap while sending is ignored.
      await tester.tap(find.text('Sending code...'));
      await tester.pump(const Duration(milliseconds: 100));

      await ms(tester, 700);
      expect(currentPath(), AppRoutes.otp);
      final p = c.read(authProfileProvider);
      expect(p.phone, '12855706');
      expect(p.channel, OtpChannel.sms);
      expect(p.isLoggedIn, isFalse);
      expect(find.textContaining('+855 12 855 706'), findsOneWidget);
    });

    testWidgets('WhatsApp choice is carried to the OTP screen', (tester) async {
      final c = await boot(tester);
      await tester.enterText(find.byType(TextField), '12855706');
      await tester.ensureVisible(
        find.byKey(const ValueKey('channel-whatsapp')),
      );
      await tester.tap(find.byKey(const ValueKey('channel-whatsapp')));
      await ms(tester, 300);
      await tester.tap(find.text('Send Verification Code'));
      await ms(tester, 1000);
      expect(currentPath(), AppRoutes.otp);
      expect(c.read(authProfileProvider).channel, OtpChannel.whatsapp);
      expect(
        find.text('Enter the 6-digit code we sent via WhatsApp to'),
        findsOneWidget,
      );
      expect(find.text('From WhatsApp'), findsOneWidget);
    });

    testWidgets('demo chip fills 012 855 706 in one tap', (tester) async {
      final c = await boot(tester);
      expect(find.text('Tap to auto-fill: 012 855 706'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('demo-chip')));
      await tester.tap(find.byKey(const ValueKey('demo-chip')));
      await ms(tester, 200);
      expect(phoneText(tester), '012 855 706');
      expect(c.read(userPhoneProvider), '12855706');
    });

    testWidgets('tapping outside the field dismisses the keyboard', (
      tester,
    ) async {
      await boot(tester);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.tapAt(const Offset(180, 300)); // header area
      await tester.pump();
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('CTA stays on-screen and tappable with the keyboard open', (
      tester,
    ) async {
      await boot(tester, size: const Size(960, 1704)); // 320x568 (iPhone SE)
      tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump(const Duration(milliseconds: 300));
      final r = tester.getRect(find.text('Send Verification Code'));
      expect(r.bottom, lessThanOrEqualTo(568 - 300 + 0.5));
      expect(r.top, greaterThanOrEqualTo(0));
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), '12855706');
      await tester.tap(find.text('Send Verification Code'));
      await ms(tester, 1000);
      expect(currentPath(), AppRoutes.otp);
    });

    testWidgets('SMS is the default; WhatsApp can be chosen', (tester) async {
      final c = await boot(tester);
      expect(c.read(authProfileProvider).channel, OtpChannel.sms);
      await tester.ensureVisible(
        find.byKey(const ValueKey('channel-whatsapp')),
      );
      await tester.tap(find.byKey(const ValueKey('channel-whatsapp')));
      await ms(tester, 300);
      expect(c.read(authProfileProvider).channel, OtpChannel.whatsapp);
      await tester.ensureVisible(find.byKey(const ValueKey('channel-sms')));
      await tester.tap(find.byKey(const ValueKey('channel-sms')));
      await ms(tester, 300);
      expect(c.read(authProfileProvider).channel, OtpChannel.sms);
    });

    testWidgets('Skip for now goes straight to GPS in guest mode', (
      tester,
    ) async {
      final c = await boot(tester);
      await tester.tap(find.text('Skip for now'));
      await ms(tester, 600);
      expect(currentPath(), AppRoutes.gps);
      expect(c.read(authProfileProvider).isGuest, isTrue);
    });

    testWidgets('Khmer: Khmer numerals while typing, Khmer labels only', (
      tester,
    ) async {
      await boot(tester, lang: AppLang.km);
      expect(find.text('ផ្ញើលេខកូដផ្ទៀងផ្ទាត់'), findsOneWidget);
      expect(find.text('កូដតាមសារ'), findsOneWidget);
      expect(find.text('វ៉ាត់ស្អាប់'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '12855706');
      await ms(tester, 200);
      expect(phoneText(tester), '១២ ៨៥៥ ៧០៦');
      expect(find.textContaining('+៨៥៥'), findsOneWidget);
    });
  });

  group('02b OTP verification', () {
    testWidgets('header, badge, number, six empty boxes, disabled CTA', (
      tester,
    ) async {
      await boot(tester, route: AppRoutes.otp, phone: '12855706');
      expect(
        find.text('Enter the 6-digit code we sent via SMS to'),
        findsOneWidget,
      );
      expect(find.text('Verify your number'), findsOneWidget);
      expect(find.textContaining('+855 12 855 706'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(ValueKey('otp-box-$i')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('otp-caret')), findsOneWidget);
      expect(find.text('Verify & Continue'), findsOneWidget);
      // Full strength — never a dead button.
      expect(
        tester
            .widget<AnimatedOpacity>(
              find
                  .descendant(of: cta, matching: find.byType(AnimatedOpacity))
                  .first,
            )
            .opacity,
        1.0,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping Verify with an incomplete code: shake + prompt', (
      tester,
    ) async {
      await boot(tester, route: AppRoutes.otp, phone: '12855706');
      await tester.tap(cta);
      await tester.pump(const Duration(milliseconds: 60));
      expect(haptics, contains('heavyImpact'));
      expect(find.text('Enter all 6 digits of the code'), findsOneWidget);
      await ms(tester, 500);
      await enter(tester, '1');
      await tester.pump();
      expect(find.text('Enter all 6 digits of the code'), findsNothing);
      expect(currentPath(), AppRoutes.otp);
    });

    testWidgets('typing fills boxes; a digit pops; backspace works', (
      tester,
    ) async {
      await boot(tester, route: AppRoutes.otp, phone: '12855706');
      await enter(tester, '123');
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      await ms(tester, 200);
      await enter(tester, '12');
      expect(find.text('3'), findsNothing);
      // Pasting spaced text keeps only digits.
      await enter(tester, '1 2 3 4');
      expect(tester.widget<TextField>(otpField).controller!.text, '1234');
    });

    testWidgets('6th digit auto-verifies; 123456 succeeds → GPS', (
      tester,
    ) async {
      final c = await boot(tester, route: AppRoutes.otp, phone: '12855706');
      expect(c.read(authProfileProvider).isLoggedIn, isFalse);
      await enter(tester, '123456');
      expect(haptics, contains('lightImpact'));
      expect(find.text('Verifying...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await ms(tester, 700); // 650 ms verify
      expect(haptics, contains('mediumImpact'));
      expect(find.text('✓ Verified'), findsOneWidget);
      expect(currentPath(), AppRoutes.otp);

      await ms(tester, 900); // 500 ms, then route transition
      expect(currentPath(), AppRoutes.gps);
      expect(c.read(authProfileProvider).isLoggedIn, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('000000 → shake, heavy haptic, red boxes, inline error', (
      tester,
    ) async {
      await boot(tester, route: AppRoutes.otp, phone: '12855706');
      await enter(tester, '000000');
      await ms(tester, 700);
      expect(haptics, contains('heavyImpact'));
      expect(
        find.text('Invalid code. Try 123456 or tap Resend.'),
        findsOneWidget,
      );
      // Mid-shake the row is displaced; once finished it is back at rest.
      final rest = tester
          .getTopLeft(find.byKey(const ValueKey('otp-box-0')))
          .dx;
      await tester.pump(const Duration(milliseconds: 60));
      final moved = tester
          .getTopLeft(find.byKey(const ValueKey('otp-box-0')))
          .dx;
      expect(moved, isNot(closeTo(rest, 0.01)));
      await ms(tester, 500);
      final settled = tester
          .getTopLeft(find.byKey(const ValueKey('otp-box-0')))
          .dx;
      expect(settled, closeTo(rest, 3.0));
      // Red border on every box.
      final box = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byKey(const ValueKey('otp-box-0')),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final border = (box.decoration! as BoxDecoration).border! as Border;
      expect(border.top.color, const Color(0xFFD91E2A));
      expect(border.top.width, 2);

      // Editing clears the error state.
      await enter(tester, '00000');
      await ms(tester, 300);
      expect(find.textContaining('Invalid code'), findsNothing);
      expect(currentPath(), AppRoutes.otp);
    });

    testWidgets('AutoFill banner: appears at 700 ms, fills, verifies', (
      tester,
    ) async {
      await boot(tester, route: AppRoutes.otp, phone: '12855706');
      final banner = find.byKey(const ValueKey('otp-banner'));
      // Parked off-screen / transparent before it shows.
      expect(
        tester
            .widget<AnimatedOpacity>(
              find
                  .ancestor(of: banner, matching: find.byType(AnimatedOpacity))
                  .first,
            )
            .opacity,
        0,
      );
      expect(find.text('From SMS'), findsOneWidget);
      expect(find.text('Your Songkrous code is 123456'), findsOneWidget);
      expect(find.text('Auto-Fill'), findsOneWidget);
      await ms(tester, 900); // 500 + 900 > 700 + 240 slide-in
      expect(
        tester
            .widget<AnimatedOpacity>(
              find
                  .ancestor(of: banner, matching: find.byType(AnimatedOpacity))
                  .first,
            )
            .opacity,
        1,
      );

      await tester.tap(find.text('Auto-Fill'));
      await ms(tester, 400); // sequential fill (6 × 50 ms)
      expect(tester.widget<TextField>(otpField).controller!.text, '123456');
      await ms(tester, 800);
      expect(find.text('✓ Verified'), findsOneWidget);
      await ms(tester, 900);
      expect(currentPath(), AppRoutes.gps);
    });

    testWidgets('banner hides itself after 6 s', (tester) async {
      await boot(tester, route: AppRoutes.otp, phone: '12855706');
      await ms(tester, 1200);
      final banner = find.byKey(const ValueKey('otp-banner'));
      double opacity() => tester
          .widget<AnimatedOpacity>(
            find
                .ancestor(of: banner, matching: find.byType(AnimatedOpacity))
                .first,
          )
          .opacity;
      expect(opacity(), 1);
      await ms(tester, 6500);
      expect(opacity(), 0);
    });

    testWidgets('resend countdown 30 → 0, then both options appear', (
      tester,
    ) async {
      await boot(tester, route: AppRoutes.otp, phone: '12855706');
      expect(find.text("Didn't get the code? Resend in 00:30"), findsOneWidget);
      await ms(tester, 2000);
      expect(find.text("Didn't get the code? Resend in 00:28"), findsOneWidget);
      expect(find.text('Resend via SMS'), findsNothing);

      await ms(tester, 28000);
      await ms(tester, 500);
      expect(find.text('Resend via SMS'), findsOneWidget);
      expect(find.text('Try WhatsApp instead'), findsOneWidget);
      expect(find.textContaining("Didn't get"), findsNothing);
    });

    testWidgets('Try WhatsApp instead: switches channel, clears, restarts', (
      tester,
    ) async {
      final c = await boot(tester, route: AppRoutes.otp, phone: '12855706');
      await enter(tester, '12');
      await ms(tester, 31000);
      await tester.tap(find.text('Try WhatsApp instead'));
      await ms(tester, 700);
      expect(c.read(authProfileProvider).channel, OtpChannel.whatsapp);
      expect(
        find.text('Enter the 6-digit code we sent via WhatsApp to'),
        findsOneWidget,
      );
      expect(find.text('From WhatsApp'), findsOneWidget);
      expect(tester.widget<TextField>(otpField).controller!.text, '');
      expect(find.text("Didn't get the code? Resend in 00:30"), findsOneWidget);
      // And the other way round offers SMS.
      await ms(tester, 31000);
      expect(find.text('Resend via WhatsApp'), findsOneWidget);
      expect(find.text('Try SMS instead'), findsOneWidget);
    });

    testWidgets('Resend via SMS clears the boxes and restarts the timer', (
      tester,
    ) async {
      await boot(tester, route: AppRoutes.otp, phone: '12855706');
      await enter(tester, '000000');
      await ms(tester, 31000);
      await tester.tap(find.text('Resend via SMS'));
      await ms(tester, 600);
      expect(tester.widget<TextField>(otpField).controller!.text, '');
      expect(find.textContaining('Invalid code'), findsNothing);
      expect(find.text("Didn't get the code? Resend in 00:30"), findsOneWidget);
    });

    testWidgets('Edit pops back to the number screen, number preserved', (
      tester,
    ) async {
      final c = await boot(tester, phone: '12855706');
      await tester.tap(find.text('Send Verification Code'));
      await ms(tester, 700);
      expect(currentPath(), AppRoutes.otp);
      await tester.tap(find.text('Edit'));
      await ms(tester, 700);
      expect(currentPath(), AppRoutes.enterNumber);
      expect(phoneText(tester), '12 855 706');
      expect(c.read(userPhoneProvider), '12855706');
    });

    testWidgets('Back and Skip', (tester) async {
      await boot(tester, phone: '12855706');
      await tester.tap(find.text('Send Verification Code'));
      await ms(tester, 700);
      await tester.tap(find.byKey(const ValueKey('otp-back')));
      await ms(tester, 700);
      expect(currentPath(), AppRoutes.enterNumber);

      await tester.tap(find.text('Send Verification Code'));
      await ms(tester, 700);
      await tester.tap(find.byKey(const ValueKey('otp-skip')));
      await ms(tester, 700);
      expect(currentPath(), AppRoutes.gps);
    });

    testWidgets('leaving mid-countdown leaves no timers behind', (
      tester,
    ) async {
      await boot(tester, route: AppRoutes.otp, phone: '12855706');
      await enter(tester, '123456'); // verify timer pending
      await tester.tap(find.byKey(const ValueKey('otp-skip')));
      await ms(tester, 1500);
      expect(currentPath(), AppRoutes.gps);
      expect(tester.takeException(), isNull);
    });
  });

  group('02b OTP — Khmer', () {
    testWidgets('everything Khmer: no Latin letters or digits', (tester) async {
      await boot(
        tester,
        route: AppRoutes.otp,
        phone: '12855706',
        lang: AppLang.km,
      );
      await ms(tester, 1500); // banner up
      expect(find.text('ផ្ទៀងផ្ទាត់លេខទូរសព្ទ'), findsOneWidget);
      expect(find.textContaining('+៨៥៥ ១២ ៨៥៥ ៧០៦'), findsOneWidget);
      expect(find.text('កែប្រែ'), findsOneWidget);
      expect(find.text('ពីសារ'), findsOneWidget);
      expect(find.text('លេខកូដសង្គ្រោះរបស់អ្នកគឺ ១២៣៤៥៦'), findsOneWidget);
      expect(find.text('បំពេញស្វ័យប្រវត្តិ'), findsOneWidget);
      expect(
        find.text('មិនទទួលបានលេខកូដ? ផ្ញើម្តងទៀតក្នុង ០០:២៨'),
        findsOneWidget,
      );

      final latin = RegExp(r'[A-Za-z0-9]');
      final bad = <String>[
        for (final w in tester.widgetList<Text>(find.byType(Text)))
          if (latin.hasMatch(w.data ?? w.textSpan?.toPlainText() ?? ''))
            w.data ?? w.textSpan!.toPlainText(),
      ];
      // Only the language selector's endonym may stay Latin.
      expect(bad.where((t) => !t.contains('EN') && t != 'English'), isEmpty);

      await enter(tester, '123');
      expect(find.text('១'), findsOneWidget);
      expect(find.text('៣'), findsOneWidget);
    });

    testWidgets('Khmer error + verify copy', (tester) async {
      await boot(
        tester,
        route: AppRoutes.otp,
        phone: '12855706',
        lang: AppLang.km,
      );
      await enter(tester, '000000');
      await ms(tester, 700);
      expect(
        find.text('លេខកូដមិនត្រឹមត្រូវ។ សាកល្បង ១២៣៤៥៦ ឬចុចផ្ញើម្តងទៀត។'),
        findsOneWidget,
      );
      await ms(tester, 32000);
      expect(find.text('ផ្ញើម្តងទៀតតាមសារ'), findsOneWidget);
      expect(find.text('សាកល្បងតាមវ៉ាត់ស្អាប់ជំនួសវិញ'), findsOneWidget);
    });

    testWidgets('switching language re-renders the boxes and number', (
      tester,
    ) async {
      final c = await boot(tester, route: AppRoutes.otp, phone: '12855706');
      await enter(tester, '123');
      expect(find.text('1'), findsOneWidget);
      c.read(langProvider.notifier).set(AppLang.km);
      await ms(tester, 300);
      expect(find.text('១'), findsOneWidget);
      expect(find.text('1'), findsNothing);
      expect(find.textContaining('+៨៥៥'), findsOneWidget);
    });
  });
}

void khmerEnterNumberScan() {
  testWidgets('Khmer enter-number: prompt, chip, sending — no Latin', (
    tester,
  ) async {
    await boot(tester, lang: AppLang.km);
    await tester.tap(find.text('ផ្ញើលេខកូដផ្ទៀងផ្ទាត់'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.text('សូមបញ្ចូលលេខទូរសព្ទឲ្យត្រឹមត្រូវ ឬចុច «រំលងសិន»'),
      findsOneWidget,
    );
    expect(
      find.text('ចុចដើម្បីបំពេញស្វ័យប្រវត្តិ៖ ០១២ ៨៥៥ ៧០៦'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('demo-chip')));
    await tester.tap(find.byKey(const ValueKey('demo-chip')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('ផ្ញើលេខកូដផ្ទៀងផ្ទាត់'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('កំពុងផ្ញើលេខកូដ...'), findsOneWidget);
    final latin = RegExp(r'[A-Za-z0-9]');
    final bad = [
      for (final w in tester.widgetList<Text>(find.byType(Text)))
        if (latin.hasMatch(w.data ?? w.textSpan?.toPlainText() ?? ''))
          w.data ?? w.textSpan!.toPlainText(),
    ];
    expect(bad.where((t) => !t.contains('EN') && t != 'English'), isEmpty);
    await ms(tester, 800);
  });
}
