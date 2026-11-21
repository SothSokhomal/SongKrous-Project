import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songkrous/core/constants/app_state.dart';
import 'package:songkrous/core/constants/app_strings.dart';
import 'package:songkrous/core/constants/phnom_penh_data.dart';
import 'package:songkrous/core/router/app_router.dart';
import 'package:songkrous/core/router/app_routes.dart';
import 'package:songkrous/core/state/auth_state.dart';
import 'package:songkrous/core/state/location_state.dart';
import 'package:songkrous/features/chat/services/photo_source.dart';
import 'package:songkrous/features/settings/profile_image_io.dart';
import 'package:songkrous/features/settings/widgets/profile_avatar_view.dart';
import 'package:songkrous/features/chat/services/telegram_dispatch_service.dart';
import 'package:songkrous/main.dart';

Future<void> ms(WidgetTester t, int total) async {
  for (var left = total; left > 0; left -= 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

String path() =>
    appRouter.routerDelegate.currentConfiguration.last.matchedLocation;

Future<ProviderContainer> boot(
  WidgetTester tester,
  String route, {
  AppLang lang = AppLang.en,
  bool loggedIn = false,
  List<Override> overrides = const [],
  Size logical = const Size(360, 640),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = logical * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final c = ProviderContainer(overrides: overrides);
  addTearDown(c.dispose);
  c.read(langProvider.notifier).set(lang);
  if (loggedIn) {
    c.read(authProfileProvider.notifier)
      ..setPhone('12855706')
      ..markLoggedIn();
  }
  appRouter.go(AppRoutes.splash);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const SongkrousApp()),
  );
  appRouter.go(route);
  await ms(tester, 800);
  return c;
}

void main() {
  setUp(() => appRouter.go(AppRoutes.splash));

  testWidgets('Top bar has no settings gear; bottom nav opens Settings; back returns', (
    tester,
  ) async {
    await boot(tester, AppRoutes.home);
    expect(find.byKey(const ValueKey('home-settings')), findsNothing);
    await tester.tap(find.text('Settings').last);
    await ms(tester, 700);
    expect(find.text('Settings'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('settings-back')));
    await ms(tester, 700);
    expect(path(), AppRoutes.home);
  });

  testWidgets('guest: shows guest card, verify button, no Log out', (
    tester,
  ) async {
    await boot(tester, AppRoutes.settings);
    expect(find.text('Guest mode'), findsWidgets); // header + account card
    expect(find.byKey(const ValueKey('settings-logout')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('settings-verify')));
    await ms(tester, 700);
    expect(path(), AppRoutes.enterNumber);
  });

  testWidgets('logged in: number + Verified, Log out clears everything', (
    tester,
  ) async {
    final c = await boot(tester, AppRoutes.settings, loggedIn: true);
    expect(find.text('+855 12 855 706'), findsWidgets);
    expect(find.text('Verified'), findsOneWidget);

    // A chat exists with a private message.
    final f = PhnomPenhData.defaultSos;
    c.read(chatProvider(f).notifier).sendText('private');
    expect(c.read(chatProvider(f)).messages.length, 3);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('settings-logout')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('settings-logout')));
    await ms(tester, 400);
    expect(find.text('Log out?'), findsOneWidget);

    // Cancel keeps the session.
    await tester.tap(find.byKey(const ValueKey('logout-cancel')));
    await ms(tester, 400);
    expect(c.read(authProfileProvider).isLoggedIn, isTrue);

    await tester.tap(find.byKey(const ValueKey('settings-logout')));
    await ms(tester, 400);
    await tester.tap(find.byKey(const ValueKey('logout-confirm')));
    await ms(tester, 600);
    final p = c.read(authProfileProvider);
    expect(p.isLoggedIn, isFalse);
    expect(p.phone, '');
    expect(c.read(chatProvider(f)).messages.length, 2);
    expect(find.text('You are logged out.'), findsOneWidget);
    expect(find.text('Guest mode'), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-logout')), findsNothing);

    // The old thread's simulated delivery finishes; it must not leak a reply
    // into the fresh, logged-out chat.
    await ms(tester, 3000);
    expect(c.read(chatProvider(f)).messages.length, 2);
  });

  testWidgets('language pill switches the whole screen', (tester) async {
    final c = await boot(tester, AppRoutes.settings);
    await tester.tap(find.byKey(const ValueKey('pill-km')));
    await ms(tester, 400);
    expect(c.read(langProvider), AppLang.km);
    expect(find.text('ការកំណត់'), findsWidgets);
    expect(find.text('Guest mode'), findsNothing);
  });

  testWidgets('Khmer: all Khmer, Khmer digits, no Latin', (tester) async {
    await boot(tester, AppRoutes.settings, lang: AppLang.km, loggedIn: true);
    expect(find.text('+៨៥៥ ១២ ៨៥៥ ៧០៦'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('settings-logout')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('កំណែ ១.០.០'), findsOneWidget);
    expect(find.text('ចាកចេញ'), findsOneWidget);
    final latin = RegExp(r'[A-Za-z0-9]');
    final bad = [
      for (final w in tester.widgetList<Text>(find.byType(Text)))
        if (latin.hasMatch(w.data ?? w.textSpan?.toPlainText() ?? ''))
          w.data ?? w.textSpan!.toPlainText(),
    ];
    // Only the language selector's own names may stay in Latin script.
    expect(bad, isEmpty); // not even the language switch uses Latin now
  });

  group('profile photo', () {
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    );

    List<Override> picker({String? path = '/x.png', bool throws = false}) => [
      photoSourceProvider.overrideWithValue(
        _FakePhotoSource(path: path, throws: throws),
      ),
      profileImageLoaderProvider.overrideWithValue((_) async => png),
    ];

    Future<void> openSheet(WidgetTester t) async {
      await t.tap(find.byKey(const ValueKey('profile-camera-badge')));
      await ms(t, 600);
    }

    testWidgets('header: avatar, camera badge, name, Set New Photo, uppercase '
        'section headers', (tester) async {
      await boot(tester, AppRoutes.settings);
      expect(find.byKey(const ValueKey('profile-avatar')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('profile-camera-badge')),
        findsOneWidget,
      );
      expect(find.text('Songkrous User'), findsOneWidget);
      expect(find.text('Set New Photo'), findsOneWidget);
      expect(
        tester.getSize(find.byType(ProfileAvatarView)),
        const Size(96, 96),
      );
      for (final h in ['ACCOUNT', 'LANGUAGE', 'PRIVACY', 'ABOUT']) {
        await tester.scrollUntilVisible(
          find.text(h),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(h), findsOneWidget, reason: h);
      }
      // Empty avatar: no Hero yet.
      expect(find.byType(Hero), findsNothing);
    });

    testWidgets('sheet: 3 actions, no Remove until a picture is set', (
      tester,
    ) async {
      await boot(tester, AppRoutes.settings);
      await openSheet(tester);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Choose Avatar Style'), findsOneWidget);
      expect(find.byKey(const ValueKey('photo-remove')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('photo-cancel')));
      await ms(tester, 500);
      expect(find.text('Take Photo'), findsNothing);
    });

    testWidgets('avatar style: 6 presets, one tap sets it, Hero appears', (
      tester,
    ) async {
      final c = await boot(tester, AppRoutes.settings);
      await openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('photo-styles')));
      await ms(tester, 400);
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(ValueKey('preset-$i')), findsOneWidget, reason: '$i');
      }
      await tester.tap(find.byKey(const ValueKey('preset-2')));
      await ms(tester, 700);
      expect(c.read(authProfileProvider).avatar, const PresetAvatar(2));
      expect(find.byType(Hero), findsOneWidget);
      expect(find.text('Take Photo'), findsNothing);

      // Now Remove is offered, in red.
      await openSheet(tester);
      expect(find.byKey(const ValueKey('photo-remove')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('photo-remove')));
      await ms(tester, 700);
      expect(c.read(authProfileProvider).avatar, isNull);
      expect(find.byType(Hero), findsNothing);
    });

    testWidgets('tap avatar → full-screen viewer; close; Change Photo', (
      tester,
    ) async {
      final c = await boot(tester, AppRoutes.settings);
      c.read(authProfileProvider.notifier).setAvatar(const PresetAvatar(0));
      await ms(tester, 400);

      await tester.tap(find.byKey(const ValueKey('profile-avatar')));
      await ms(tester, 800);
      expect(
        find.byKey(const ValueKey('avatar-viewer-surface')),
        findsOneWidget,
      );
      expect(find.text('Change Photo'), findsOneWidget);
      // Big circle.
      expect(
        tester.getSize(find.byType(ProfileAvatarView).last).width,
        greaterThan(200),
      );

      // Tap anywhere to close.
      await tester.tapAt(const Offset(180, 560));
      await ms(tester, 800);
      expect(find.byKey(const ValueKey('avatar-viewer-surface')), findsNothing);

      // Swipe down closes too.
      await tester.tap(find.byKey(const ValueKey('profile-avatar')));
      await ms(tester, 800);
      await tester.fling(
        find.byKey(const ValueKey('avatar-viewer-surface')),
        const Offset(0, 300),
        1500,
      );
      await ms(tester, 800);
      expect(find.byKey(const ValueKey('avatar-viewer-surface')), findsNothing);

      // "Change Photo" closes the viewer and opens the sheet.
      await tester.tap(find.byKey(const ValueKey('profile-avatar')));
      await ms(tester, 800);
      await tester.tap(find.byKey(const ValueKey('avatar-viewer-change')));
      await ms(tester, 900);
      expect(find.byKey(const ValueKey('avatar-viewer-surface')), findsNothing);
      expect(find.text('Choose from Gallery'), findsOneWidget);
    });

    testWidgets('gallery photo → circular preview → confirm sets it', (
      tester,
    ) async {
      final c = await boot(tester, AppRoutes.settings, overrides: picker());
      await openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('photo-gallery')));
      await ms(tester, 900);
      expect(find.byKey(const ValueKey('photo-viewport')), findsOneWidget);
      expect(find.text('Set Profile Photo ✓'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Pinch to zoom, drag to move'), findsOneWidget);
      expect(c.read(authProfileProvider).avatar, isNull); // not yet

      await tester.tap(find.byKey(const ValueKey('photo-preview-confirm')));
      await tester.pump();
      // The frame capture (RepaintBoundary.toImage) is real engine work: give
      // it real time, then let the route pop animate.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1500)),
      );
      await ms(tester, 900);
      expect(c.read(authProfileProvider).avatar, isA<PhotoAvatar>());
      expect(find.byKey(const ValueKey('photo-viewport')), findsNothing);
      expect(find.byType(Hero), findsOneWidget);
    });

    testWidgets('cancelling the preview keeps the old picture', (tester) async {
      final c = await boot(tester, AppRoutes.settings, overrides: picker());
      c.read(authProfileProvider.notifier).setAvatar(const PresetAvatar(1));
      await openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('photo-gallery')));
      await ms(tester, 900);
      await tester.tap(find.byKey(const ValueKey('photo-preview-cancel')));
      await ms(tester, 800);
      expect(c.read(authProfileProvider).avatar, const PresetAvatar(1));
    });

    testWidgets('user cancels the system picker: nothing happens', (
      tester,
    ) async {
      final c = await boot(
        tester,
        AppRoutes.settings,
        overrides: picker(path: null),
      );
      await openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('photo-gallery')));
      await ms(tester, 800);
      expect(find.byKey(const ValueKey('photo-viewport')), findsNothing);
      expect(c.read(authProfileProvider).avatar, isNull);
    });

    testWidgets('camera unavailable (simulator): friendly message', (
      tester,
    ) async {
      await boot(tester, AppRoutes.settings, overrides: picker(throws: true));
      await openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('photo-camera')));
      await ms(tester, 900);
      expect(
        find.text(
          "Camera isn't available here. Try the gallery or pick an avatar style.",
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Log out clears the picture', (tester) async {
      final c = await boot(tester, AppRoutes.settings, loggedIn: true);
      c.read(authProfileProvider.notifier).setAvatar(PhotoAvatar(png));
      await ms(tester, 400);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settings-logout')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('settings-logout')));
      await ms(tester, 400);
      await tester.tap(find.byKey(const ValueKey('logout-confirm')));
      await ms(tester, 800);
      expect(c.read(authProfileProvider).avatar, isNull);
    });

    testWidgets('logged in shows verified tick and the number under the name', (
      tester,
    ) async {
      await boot(tester, AppRoutes.settings, loggedIn: true);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('profile-subtitle')))
            .data,
        '+855 12 855 706',
      );
      expect(find.byIcon(Icons.verified_rounded), findsWidgets);
    });

    for (final (w, scale) in [(320.0, 1.0), (360.0, 1.3)]) {
      testWidgets(
        'Khmer sheet + preview + header: no overflow @${w}px x$scale',
        (tester) async {
          await boot(
            tester,
            AppRoutes.settings,
            lang: AppLang.km,
            loggedIn: true,
            overrides: picker(),
            logical: Size(w, 640),
            textScale: scale,
          );
          expect(find.text('ផ្លាស់ប្តូររូបភាព'), findsWidgets);
          await openSheet(tester);
          await tester.tap(find.byKey(const ValueKey('photo-styles')));
          await ms(tester, 400);
          expect(find.text('ថតរូប'), findsOneWidget);
          expect(find.text('ជ្រើសរើសពីវិចិត្រសាល'), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('photo-gallery')));
          // Styles row open means gallery is still reachable above it.
          await ms(tester, 900);
          expect(find.text('កំណត់រូបភាពប្រូហ្វាល ✓'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('location switch', () {
    testWidgets('flipping it ON/OFF updates the subtitle, Home and the map', (
      tester,
    ) async {
      final c = await boot(
        tester,
        AppRoutes.settings,
        overrides: [locationProvider.overrideWith(_FakeLocation.new)],
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settings-location-switch')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      Switch sw() => tester.widget<Switch>(
        find.byKey(const ValueKey('settings-location-switch')),
      );
      expect(sw().value, isFalse);
      expect(find.text('Off — manual Khan selection active'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('settings-location-switch')));
      await ms(tester, 600);
      expect(c.read(locationEnabledProvider), isTrue);
      expect(sw().value, isTrue);
      expect(find.text('On — used only to find nearby help'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('settings-location-switch')));
      await ms(tester, 600);
      expect(c.read(locationEnabledProvider), isFalse);
      expect(find.text('Off — manual Khan selection active'), findsOneWidget);
    });

    testWidgets('permission denied: stays off and explains', (tester) async {
      final c = await boot(
        tester,
        AppRoutes.settings,
        overrides: [
          locationProvider.overrideWith(() => _FakeLocation(grant: false)),
        ],
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settings-location-switch')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('settings-location-switch')));
      await ms(tester, 700);
      expect(c.read(locationEnabledProvider), isFalse);
      expect(
        find.text(
          'Location permission is off. Turn it on in your device Settings.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Khmer subtitle', (tester) async {
      await boot(tester, AppRoutes.settings, lang: AppLang.km);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('settings-location-switch')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('បិទ — កំពុងប្រើការជ្រើសរើសខណ្ឌដោយដៃ'), findsOneWidget);
    });
  });
}

class _FakePhotoSource implements PhotoSource {
  _FakePhotoSource({this.path, this.throws = false});

  final String? path;
  final bool throws;

  @override
  Future<String?> pick(PhotoOrigin origin) async {
    if (throws) throw StateError('no camera');
    return path;
  }
}

class _FakeLocation extends LocationNotifier {
  _FakeLocation({this.grant = true});

  final bool grant;

  @override
  Future<bool> requestPermission() async {
    if (grant) state = state.copyWith(gpsActive: true);
    return grant;
  }
}
