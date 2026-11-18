import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songkrous/core/constants/app_state.dart';
import 'package:songkrous/core/constants/app_strings.dart';
import 'package:songkrous/core/constants/phnom_penh_data.dart';
import 'package:songkrous/core/router/app_router.dart';
import 'package:songkrous/core/router/app_routes.dart';
import 'package:songkrous/features/chat/models/chat_message.dart';
import 'package:songkrous/features/chat/services/photo_source.dart';
import 'package:songkrous/features/chat/services/telegram_dispatch_service.dart';
import 'package:songkrous/features/chat/widgets/chat_composer.dart';
import 'package:songkrous/features/chat/widgets/photo_bubble.dart';
import 'package:songkrous/features/chat/widgets/typing_indicator.dart';
import 'package:songkrous/features/chat/widgets/voice_bubble.dart';
import 'package:songkrous/main.dart';

final List<String> haptics = [];

Future<void> frames(WidgetTester tester, [int n = 6, int ms = 120]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

class _FakePhotos implements PhotoSource {
  _FakePhotos({this.fail = false});
  final bool fail;
  @override
  Future<String?> pick(PhotoOrigin origin) async {
    if (fail) throw StateError('no camera');
    return '/tmp/does-not-exist.jpg';
  }
}

Future<ProviderContainer> boot(
  WidgetTester tester, {
  AppLang lang = AppLang.en,
  PhotoSource? photos,
  String route = AppRoutes.chat,
  Object? extra,
}) async {
  tester.view.physicalSize = const Size(1170, 2532); // 390 x 844 @3x
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

  final c = ProviderContainer(
    overrides: [
      if (photos != null) photoSourceProvider.overrideWithValue(photos),
    ],
  );
  addTearDown(c.dispose);
  c.read(langProvider.notifier).set(lang);
  appRouter.go(route, extra: extra ?? PhnomPenhData.defaultSos);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const SongkrousApp()),
  );
  await frames(tester, 8);
  haptics.clear();
  return c;
}

Finder tooltip(String m) => find.byTooltip(m).hitTestable();

/// Types into the composer (the only TextField).
Future<void> type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await frames(tester, 3);
}

void main() {
  group('opening the chat', () {
    testWidgets('Send Message on the SOS screen opens the facility chat', (
      tester,
    ) async {
      await boot(tester, route: AppRoutes.sosCall);
      await tester.tap(find.text('Send Message'));
      await frames(tester, 8);

      // Header: name + connection line; welcome + auto-attached location.
      expect(find.text('Calmette Hospital'), findsWidgets);
      expect(find.text('Connected • +855 23 426 948'), findsOneWidget);
      expect(find.text('Calmette Hospital · +855 23 426 948'), findsOneWidget);
      expect(find.text('Live Location'), findsOneWidget);
      expect(find.text('11.5813° N, 104.9158° E'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('quick chips, hint with the facility number, Khmer layout', (
      tester,
    ) async {
      await boot(tester, lang: AppLang.km);
      expect(find.text('📍 ផ្ញើទីតាំង'), findsOneWidget);
      expect(find.text('ផ្ញើសារទៅ +៨៥៥ ២៣ ៤២៦ ៩៤៨...'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('sending text', () {
    testWidgets('Telegram pipeline: sending → ✓ → ✓✓ → read, typing, reply', (
      tester,
    ) async {
      await boot(tester);
      // Send button only appears once there is text.
      expect(tooltip('Send'), findsNothing);
      await type(tester, 'Help, car accident');
      expect(tooltip('Send'), findsOneWidget);

      await tester.tap(tooltip('Send'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(haptics, contains('lightImpact'));
      // Optimistic: visible immediately, with the clock.
      expect(find.text('Help, car accident'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );

      await tester.pump(const Duration(milliseconds: 300)); // +250 → sent
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.done_rounded), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 450)); // +400 → delivered
      expect(find.byIcon(Icons.done_all_rounded), findsWidgets);

      await tester.pump(const Duration(milliseconds: 750)); // +700 → read
      // The last tick on screen is the read (blue) double-check.
      final ticks = tester
          .widgetList<Icon>(find.byIcon(Icons.done_all_rounded))
          .map((i) => i.color)
          .toList();
      expect(ticks, contains(const Color(0xFF93C5FD)));

      await tester.pump(const Duration(milliseconds: 400)); // typing starts
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(TypingIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1300)); // reply
      await frames(tester, 3);
      expect(find.byType(TypingIndicator), findsNothing);
      expect(
        find.text(
          'Received your message at Dispatch (+855 23 426 948). '
          'Please stay at St. 598, Kilometer 6 Village, help is on the way.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty/whitespace never sends', (tester) async {
      await boot(tester);
      await type(tester, '   ');
      // Whitespace still shows no send button.
      expect(tooltip('Send'), findsNothing);
    });

    testWidgets('quick chips send immediately with a light haptic', (
      tester,
    ) async {
      await boot(tester);
      await tester.tap(find.text('🚑 Need Ambulance'));
      await frames(tester, 2);
      expect(haptics, contains('lightImpact'));
      expect(find.text('I need an ambulance at my location.'), findsOneWidget);

      // The row scrolls horizontally: bring the last two chips into view.
      await tester.ensureVisible(find.text('🩸 Severe Bleeding'));
      await tester.tap(find.text('🩸 Severe Bleeding'));
      await tester.ensureVisible(find.text('🚓 Need Police'));
      await tester.tap(find.text('🚓 Need Police'));
      await frames(tester, 2);
      expect(find.text('Severe bleeding — please hurry!'), findsOneWidget);
      expect(find.text('I need the police at my location.'), findsOneWidget);
      await frames(tester, 30); // let the simulated pipelines finish
    });

    testWidgets('consecutive bubbles use Instagram-style corner grouping', (
      tester,
    ) async {
      await boot(tester);
      await type(tester, 'first');
      await tester.tap(tooltip('Send'));
      await frames(tester, 2);
      await type(tester, 'second');
      await tester.tap(tooltip('Send'));
      await frames(tester, 2);
      await type(tester, 'third');
      await tester.tap(tooltip('Send'));
      await frames(tester, 2);

      BorderRadius radiusOf(String text) {
        final box = find
            .ancestor(of: find.text(text), matching: find.byType(Container))
            .evaluate()
            .map((e) => e.widget as Container)
            .firstWhere(
              (c) =>
                  c.decoration is BoxDecoration &&
                  (c.decoration! as BoxDecoration).borderRadius != null,
            );
        return (box.decoration! as BoxDecoration).borderRadius! as BorderRadius;
      }

      final a = radiusOf('first');
      final b = radiusOf('second');
      final c = radiusOf('third');
      // Outer (left) corners always 20…
      for (final r in [a, b, c]) {
        expect(r.topLeft.x, 20);
        expect(r.bottomLeft.x, 20);
      }
      // …the right side tightens to 5 between neighbours.
      expect([a.topRight.x, a.bottomRight.x], [20, 5]); // first of group
      expect([b.topRight.x, b.bottomRight.x], [5, 5]); // middle
      expect([c.topRight.x, c.bottomRight.x], [5, 20]); // last
      await frames(tester, 40);
    });

    testWidgets('mini avatar only on the last bubble of an incoming group', (
      tester,
    ) async {
      await boot(tester);
      Finder miniAvatars() => find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.add_rounded && w.size == 14,
      );
      // Just the welcome message so far.
      expect(miniAvatars(), findsOneWidget);

      // Two quick sends → two consecutive replies = ONE incoming group.
      await type(tester, 'a');
      await tester.tap(tooltip('Send'));
      await frames(tester, 2);
      await type(tester, 'b');
      await tester.tap(tooltip('Send'));
      await frames(tester, 40);

      expect(find.textContaining('Received your message'), findsNWidgets(2));
      // Welcome group + reply group: exactly two avatars (not three).
      expect(miniAvatars(), findsNWidgets(2));
    });
  });

  group('location', () {
    testWidgets('header pin and the GPS chip send a live-location card', (
      tester,
    ) async {
      final c = await boot(tester);
      int locations() => c
          .read(chatProvider(PhnomPenhData.defaultSos))
          .messages
          .where((m) => m.type == MessageType.location)
          .length;
      expect(locations(), 1); // auto-attached pin
      expect(find.text('Live Location'), findsOneWidget);

      await tester.tap(tooltip('Send my location'));
      await frames(tester, 3);
      expect(locations(), 2);
      expect(haptics, contains('lightImpact'));
      expect(find.text('Live Location'), findsWidgets);

      await tester.tap(find.text('📍 Send GPS'));
      await frames(tester, 3);
      expect(locations(), 3);
      await frames(tester, 40);
    });

    testWidgets('header phone jumps to the outgoing call screen', (
      tester,
    ) async {
      await boot(tester);
      await tester.tap(tooltip('Call dispatch'));
      await frames(tester, 8);
      expect(find.text('calling'), findsOneWidget);
    });
  });

  group('photos', () {
    testWidgets(
      'demo photo: stage → remove → stage → caption → send → lightbox',
      (tester) async {
        await boot(tester);
        expect(tooltip('Send'), findsNothing);

        await tester.tap(tooltip('Attach a photo'));
        await frames(tester, 6);
        expect(find.text('Choose from Photo Library'), findsOneWidget);
        expect(find.text('Take Photo'), findsOneWidget);
        expect(find.text('Quick Demo Incident Photo'), findsOneWidget);

        await tester.tap(find.text('Quick Demo Incident Photo'));
        await frames(tester, 6);
        // Thumbnail strip + send button (no text needed).
        expect(find.byTooltip('Remove photo'), findsOneWidget);
        expect(tooltip('Send'), findsOneWidget);
        expect(find.text('Add a caption...'), findsOneWidget);

        await tester.tap(find.byTooltip('Remove photo'));
        await frames(tester, 4);
        expect(find.byTooltip('Remove photo'), findsNothing);
        expect(tooltip('Send'), findsNothing);

        await tester.tap(tooltip('Attach a photo'));
        await frames(tester, 6);
        await tester.tap(find.text('Quick Demo Incident Photo'));
        await frames(tester, 6);
        await type(tester, 'Crash at St. 598');
        await tester.tap(tooltip('Send'));
        await frames(tester, 4);

        expect(find.byType(PhotoBubble), findsOneWidget);
        expect(find.text('Crash at St. 598'), findsOneWidget);
        expect(find.byTooltip('Remove photo'), findsNothing); // strip cleared

        // Tap → full-screen lightbox, then close.
        await tester.tap(find.byType(PhotoBubble));
        await frames(tester, 6);
        expect(find.byType(PhotoLightbox), findsOneWidget);
        await tester.tap(find.byTooltip('Close'));
        await frames(tester, 6);
        expect(find.byType(PhotoLightbox), findsNothing);
        await frames(tester, 40);
      },
    );

    testWidgets('picker success stages the photo', (tester) async {
      await boot(tester, photos: _FakePhotos());
      await tester.tap(tooltip('Photo library'));
      await frames(tester, 4);
      expect(find.byTooltip('Remove photo'), findsOneWidget);
      expect(tooltip('Send'), findsOneWidget);
    });

    testWidgets('picker failure falls back gracefully to the demo photo', (
      tester,
    ) async {
      await boot(tester, photos: _FakePhotos(fail: true));
      await tester.tap(tooltip('Photo library'));
      await frames(tester, 4);
      expect(
        find.text("Photos aren't available here. Try the demo photo."),
        findsOneWidget,
      );
      await tester.tap(find.text('Use demo'));
      await frames(tester, 4);
      expect(find.byTooltip('Remove photo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('voice notes', () {
    testWidgets(
      'record: bar morphs in, timer counts, send creates a voice bubble',
      (tester) async {
        await boot(tester);
        await tester.tap(tooltip('Record voice message'));
        await frames(tester, 4);
        expect(find.text('0:00'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(tooltip('Send voice message'), findsOneWidget);
        expect(find.byType(TextField), findsNothing); // pill replaced

        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('0:03'), findsOneWidget);

        await tester.tap(tooltip('Send voice message'));
        await frames(tester, 4);
        expect(find.byType(VoiceBubble), findsOneWidget);
        expect(find.text('0:03'), findsOneWidget); // bubble duration
        expect(find.byType(TextField), findsOneWidget); // pill is back
        await frames(tester, 40);
      },
    );

    testWidgets('cancel discards the recording', (tester) async {
      await boot(tester);
      await tester.tap(tooltip('Record voice message'));
      await frames(tester, 4);
      await tester.tap(find.text('Cancel'));
      await frames(tester, 4);
      expect(find.byType(VoiceBubble), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('holding the mic also starts recording', (tester) async {
      await boot(tester);
      await tester.longPress(tooltip('Record voice message'));
      await frames(tester, 4);
      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await frames(tester, 3);
    });

    testWidgets('playback: play ⇄ pause, progress runs, duration counts down', (
      tester,
    ) async {
      await boot(tester);
      await tester.tap(tooltip('Record voice message'));
      await frames(tester, 2);
      await tester.pump(const Duration(seconds: 4));
      await tester.tap(tooltip('Send voice message'));
      await frames(tester, 4);

      final play = find.byIcon(Icons.play_arrow_rounded);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      await tester.tap(play);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.text('0:04'), findsNothing); // counting down
      expect(find.text('0:03'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.pause_rounded));
      await frames(tester, 3);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      await frames(tester, 40);
    });
  });

  group('lifecycle', () {
    testWidgets('leaving the chat mid-delivery does not throw', (tester) async {
      await boot(tester);
      await type(tester, 'bye');
      await tester.tap(tooltip('Send'));
      await frames(tester, 2);
      appRouter.go(AppRoutes.home);
      await frames(tester, 40);
      expect(tester.takeException(), isNull);
    });

    testWidgets('composer: external state is disposed cleanly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: ChatComposer(
                  phone: '117',
                  onSendText: (_) {},
                  onSendPhoto: (_, _) {},
                  onSendVoice: (_, _) {},
                ),
              ),
            ),
          ),
        ),
      );
      // Start a recording (a periodic timer) then unmount: no leaked timer.
      await tester.tap(find.byIcon(Icons.mic_rounded));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    });
  });

  test('simulated transport follows the Telegram timeline', () async {
    final events = <String>[];
    final m = ChatMessage(
      id: 'x',
      isMe: true,
      type: MessageType.photo,
      timestamp: DateTime(2026),
    );
    await for (final e in const SimulatedTelegramTransport().deliver(
      m,
      DispatchContext(
        facility: _f,
        userAddress: 'St. 598',
        userAddressKm: 'ផ្លូវ ៥៩៨',
      ),
    )) {
      events.add(switch (e) {
        StatusChanged(:final status) => status.name,
        TypingChanged(:final typing) => 'typing:$typing',
        ReplyReceived(:final message) => 'reply:${message.text}',
      });
    }
    expect(events.sublist(0, 5), [
      'sent',
      'delivered',
      'read',
      'typing:true',
      'typing:false',
    ]);
    expect(events.last, contains('Received your photo at Dispatch'));
  });

  group('language separation', () {
    testWidgets('Khmer chat: welcome, reply, times and address are all Khmer', (
      tester,
    ) async {
      await boot(tester, lang: AppLang.km);
      // Seed welcome + location label: Khmer digits, no English name/address.
      expect(find.textContaining('+៨៥៥'), findsWidgets);
      expect(find.textContaining('Calmette'), findsNothing);
      expect(find.textContaining('Kilometer'), findsNothing);

      await type(tester, 'ជួយខ្ញុំផង');
      await tester.tap(tooltip('ផ្ញើ'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 1300));
      await frames(tester, 3);
      expect(
        find.textContaining('បានទទួលសាររបស់អ្នកដោយមជ្ឈមណ្ឌលបញ្ជា'),
        findsOneWidget,
      );
      expect(find.textContaining('Received'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switching language re-renders history in the new language', (
      tester,
    ) async {
      final c = await boot(tester, lang: AppLang.en);
      expect(find.textContaining('Calmette'), findsWidgets);
      c.read(langProvider.notifier).set(AppLang.km);
      await frames(tester, 4);
      expect(find.textContaining('Calmette'), findsNothing);
      expect(find.textContaining('+៨៥៥'), findsWidgets);
    });
  });
}

final _f = PhnomPenhData.facilities.firstWhere((f) => f.id == 'calmette');
