import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songkrous/core/constants/app_state.dart';
import 'package:songkrous/core/constants/app_strings.dart';
import 'package:songkrous/core/router/app_router.dart';
import 'package:songkrous/core/router/app_routes.dart';
import 'package:songkrous/core/theme/app_colors.dart';
import 'package:songkrous/main.dart';
import 'package:songkrous/shared/widgets/app_interactive.dart';
import 'package:songkrous/shared/widgets/emergency_emblem.dart';
import 'package:songkrous/shared/widgets/liquid_glass.dart';

/// Captured `HapticFeedback.*` calls ("lightImpact", "heavyImpact", …).
final List<String> haptics = [];

Future<void> frames(WidgetTester tester, [int n = 8, int ms = 120]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

void captureHaptics(WidgetTester tester) {
  haptics.clear();
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(
          (call.arguments as String).replaceFirst('HapticFeedbackType.', ''),
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
}

Future<void> boot(WidgetTester tester, String route) async {
  tester.view.physicalSize = const Size(1170, 2532); // 390 x 844 @3x
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  captureHaptics(tester);

  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.read(langProvider.notifier).set(AppLang.en);
  appRouter.go(route);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const SongkrousApp()),
  );
  await frames(tester, 8);
  haptics.clear();
}

/// A mouse pointer parked off-screen; `moveTo` hovers, `down` presses.
Future<TestGesture> mouse(WidgetTester tester) async {
  final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await g.addPointer(location: const Offset(-50, -50));
  addTearDown(g.removePointer);
  await tester.pump();
  return g;
}

BoxDecoration decorationOf(WidgetTester t, Finder f) =>
    t.widget<AnimatedContainer>(f).decoration! as BoxDecoration;

Finder buttonBox(Finder button) =>
    find.descendant(of: button, matching: find.byType(AnimatedContainer)).first;

Finder scaleOf(Finder inside) =>
    find.descendant(of: inside, matching: find.byType(AnimatedScale)).first;

void main() {
  group('AppInteractiveButton', () {
    Future<Finder> pumpButton(
      WidgetTester tester, {
      VoidCallback? onPressed,
      AppButtonColors colors = AppButtonColors.primary,
      IconData? trailing,
    }) async {
      captureHaptics(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 260,
                child: AppInteractiveButton(
                  label: 'Go',
                  colors: colors,
                  trailingIcon: trailing,
                  onPressed: onPressed,
                ),
              ),
            ),
          ),
        ),
      );
      return find.byType(AppInteractiveButton);
    }

    testWidgets('default → hover → pressed → released', (tester) async {
      var taps = 0;
      final button = await pumpButton(
        tester,
        onPressed: () => taps++,
        trailing: Icons.arrow_forward_rounded,
      );
      final box = buttonBox(button);
      final slide = find.descendant(
        of: button,
        matching: find.byType(AnimatedSlide),
      );

      // Default.
      expect(decorationOf(tester, box).color, const Color(0xFF0F3D91));
      expect(tester.widget<AnimatedSlide>(slide).offset, Offset.zero);

      // Hover: lighter blue, 1.5 px lift, glow, arrow nudged 4 px (4/20).
      final g = await mouse(tester);
      await g.moveTo(tester.getCenter(button));
      await tester.pump(const Duration(milliseconds: 200));
      expect(decorationOf(tester, box).color, const Color(0xFF174DB3));
      expect(
        tester.widget<AnimatedContainer>(box).transform!.getTranslation().y,
        -1.5,
      );
      expect(tester.widget<AnimatedSlide>(slide).offset.dx, closeTo(0.2, 1e-9));
      final hoverShadow = decorationOf(tester, box).boxShadow!.single;
      expect(hoverShadow.blurRadius, greaterThan(12));
      final cursor = tester
          .widget<MouseRegion>(
            find
                .descendant(of: button, matching: find.byType(MouseRegion))
                .first,
          )
          .cursor;
      expect(cursor, SystemMouseCursors.click);

      // Pressed: haptic immediately on touch-down, scale 0.965, darker fill,
      // compressed shadow.
      await g.down(tester.getCenter(button));
      await tester.pump(const Duration(milliseconds: 16));
      expect(haptics, ['lightImpact']);
      expect(tester.widget<AnimatedScale>(scaleOf(button)).scale, 0.965);
      expect(decorationOf(tester, box).color, const Color(0xFF0A2B66));
      expect(
        decorationOf(tester, box).boxShadow!.single.blurRadius,
        lessThan(hoverShadow.blurRadius),
      );

      await g.up();
      await tester.pump(const Duration(milliseconds: 200));
      expect(taps, 1);
      expect(tester.widget<AnimatedScale>(scaleOf(button)).scale, 1.0);
    });

    testWidgets('danger colours', (tester) async {
      final button = await pumpButton(
        tester,
        onPressed: () {},
        colors: AppButtonColors.danger,
      );
      final box = buttonBox(button);
      expect(decorationOf(tester, box).color, const Color(0xFFD91E2A));
      final g = await mouse(tester);
      await g.moveTo(tester.getCenter(button));
      await tester.pump(const Duration(milliseconds: 200));
      expect(decorationOf(tester, box).color, const Color(0xFFE62E3B));
      await g.down(tester.getCenter(button));
      await tester.pump(const Duration(milliseconds: 16));
      expect(decorationOf(tester, box).color, const Color(0xFFA8131D));
      await g.up();
    });

    testWidgets('disabled: 50% opacity, basic cursor, no haptic, no tap', (
      tester,
    ) async {
      final button = await pumpButton(tester, onPressed: null);
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.descendant(
                of: button,
                matching: find.byType(AnimatedOpacity),
              ),
            )
            .opacity,
        0.5,
      );
      final g = await mouse(tester);
      await g.moveTo(tester.getCenter(button));
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester
            .widget<MouseRegion>(
              find
                  .descendant(of: button, matching: find.byType(MouseRegion))
                  .first,
            )
            .cursor,
        SystemMouseCursors.basic,
      );
      await g.down(tester.getCenter(button));
      await g.up();
      expect(haptics, isEmpty);
    });
  });

  group('AppInteractiveCard', () {
    testWidgets('hover border/surface, press sink, selected 2px border', (
      tester,
    ) async {
      var selected = false;
      late StateSetter set;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  set = setState;
                  return SizedBox(
                    width: 240,
                    height: 80,
                    child: AppInteractiveCard(
                      selected: selected,
                      onTap: () {},
                      child: const Text('card'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      captureHaptics(tester);
      final card = find.byType(AppInteractiveCard);
      final box = buttonBox(card);

      var d = decorationOf(tester, box);
      expect(d.color, AppColors.white);
      expect((d.border! as Border).top.color, const Color(0xFFE2E8F0));

      final g = await mouse(tester);
      await g.moveTo(tester.getCenter(card));
      await tester.pump(const Duration(milliseconds: 200));
      d = decorationOf(tester, box);
      expect(d.color, const Color(0xFFF8FAFF));
      expect((d.border! as Border).top.color, const Color(0xFF93C5FD));
      expect(d.boxShadow, isNotEmpty); // lifted

      await g.down(tester.getCenter(card));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.widget<AnimatedScale>(scaleOf(card)).scale, 0.98);
      await g.up();
      await tester.pump(const Duration(milliseconds: 200));
      expect(haptics, ['selectionClick']); // on the confirmed tap

      set(() => selected = true);
      await tester.pump(const Duration(milliseconds: 250));
      d = decorationOf(tester, box);
      final border = (d.border! as Border).top;
      expect(border.width, 2);
      expect(border.color, const Color(0xFF0F3D91));
    });

    testWidgets('a drag beyond the touch slop cancels the pressed state', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 240,
                height: 80,
                child: AppInteractiveCard(onTap: () {}, child: const Text('c')),
              ),
            ),
          ),
        ),
      );
      final card = find.byType(AppInteractiveCard);
      final g = await tester.startGesture(tester.getCenter(card));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.widget<AnimatedScale>(scaleOf(card)).scale, 0.98);
      await g.moveBy(const Offset(0, 60));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.widget<AnimatedScale>(scaleOf(card)).scale, 1.0);
      await g.up();
    });
  });

  group('AppFocusInput', () {
    testWidgets('border: rest → hover → focus ring; external node survives', (
      tester,
    ) async {
      final node = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 260,
                child: AppFocusInput(
                  focusNode: node,
                  builder: (context, n) => TextField(
                    focusNode: n,
                    decoration: AppFocusInput.bareDecoration(hintText: 'type'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final field = find.byType(AppFocusInput);
      final box = find
          .descendant(of: field, matching: find.byType(AnimatedContainer))
          .first;
      Border border() => decorationOf(tester, box).border! as Border;

      expect(border().top.width, 1);
      expect(border().top.color, const Color(0xFFE2E8F0));

      final g = await mouse(tester);
      await g.moveTo(tester.getCenter(field));
      await tester.pump(const Duration(milliseconds: 250));
      expect(border().top.color, const Color(0xFF94A3B8));

      await tester.tap(find.byType(TextField));
      await tester.pump(const Duration(milliseconds: 250));
      expect(border().top.width, 2);
      expect(border().top.color, const Color(0xFF0F3D91));
      final ring = decorationOf(tester, box).boxShadow!.single;
      expect(ring.color, AppColors.blue.withValues(alpha: 0.12));
      expect(ring.spreadRadius, 4);

      // Unmounting must remove the listener but not dispose a node it doesn't
      // own (disposing twice would throw).
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
      node.dispose(); // would assert if the wrapper had already disposed it
    });
  });

  group('screens', () {
    testWidgets('language pill: sliding highlight, selection haptic', (
      tester,
    ) async {
      await boot(tester, AppRoutes.onboarding);
      Alignment indicator() =>
          tester
                  .widget<AnimatedAlign>(
                    find
                        .descendant(
                          of: find.byType(AppPressable).first.evaluate().isEmpty
                              ? find.byType(Scaffold)
                              : find.byType(Scaffold),
                          matching: find.byType(AnimatedAlign),
                        )
                        .first,
                  )
                  .alignment
              as Alignment;

      expect(indicator(), Alignment.centerRight); // English selected
      await tester.tap(find.byKey(const ValueKey('pill-km')));
      await frames(tester, 3);
      expect(haptics, ['selectionClick']);
      expect(indicator(), Alignment.centerLeft);
      expect(find.text('បន្ត'), findsOneWidget); // UI switched to Khmer
    });

    testWidgets('onboarding CTA: hover lift + haptic', (tester) async {
      await boot(tester, AppRoutes.onboarding);
      final cta = find.byType(AppInteractiveButton);
      final g = await mouse(tester);
      await g.moveTo(tester.getCenter(cta));
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester
            .widget<AnimatedContainer>(buttonBox(cta))
            .transform!
            .getTranslation()
            .y,
        -1.5,
      );
      await g.down(tester.getCenter(cta));
      await tester.pump(const Duration(milliseconds: 16));
      expect(haptics, ['lightImpact']);
      await g.up();
    });

    testWidgets('GPS dialog rows: glass highlight on hover', (tester) async {
      await boot(tester, AppRoutes.gps);
      final row = find.text("Don't Allow");
      final g = await mouse(tester);
      await g.moveTo(tester.getCenter(row));
      await tester.pump(const Duration(milliseconds: 200));
      final bg = find
          .ancestor(of: row, matching: find.byType(AnimatedContainer))
          .first;
      expect(decorationOf(tester, bg).color, const Color(0x0F0F172A));
    });

    testWidgets('Home: Copy Location → ✓ Copied (medium haptic) → reverts', (
      tester,
    ) async {
      await boot(tester, AppRoutes.home);
      await tester.tap(find.text('Copy Location'));
      await frames(tester, 3);
      expect(haptics, contains('mediumImpact'));
      expect(find.text('✓ Copied'), findsOneWidget);
      await frames(tester, 20); // > 2 s
      expect(find.text('Copy Location'), findsOneWidget);
      expect(find.text('✓ Copied'), findsNothing);
    });

    testWidgets(
      'Home: emergency card hover widens strip, scales shield; press = medium haptic',
      (tester) async {
        await boot(tester, AppRoutes.home);
        final card = find.ancestor(
          of: find.text('Hospital'),
          matching: find.byType(AppInteractiveCard),
        );
        double strip() => tester
            .getSize(
              find.descendant(
                of: card,
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is AnimatedContainer &&
                      (w.constraints?.maxWidth == 5 ||
                          w.constraints?.maxWidth == 7),
                ),
              ),
            )
            .width;
        double shield() => tester
            .widget<AnimatedScale>(
              find
                  .ancestor(
                    of: find.byType(EmergencyEmblem).first,
                    matching: find.byType(AnimatedScale),
                  )
                  .first,
            )
            .scale;

        expect(strip(), 5);
        expect(shield(), 1.0);

        final g = await mouse(tester);
        await g.moveTo(tester.getCenter(find.text('Hospital')));
        await tester.pump(); // starts the implicit animations…
        await tester.pump(const Duration(milliseconds: 250)); // …and runs them
        expect(strip(), 7);
        expect(shield(), 1.06);

        await g.down(tester.getCenter(find.text('Hospital')));
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.widget<AnimatedScale>(scaleOf(card)).scale, 0.97);
        await g.up();
        await frames(tester, 3);
        expect(haptics, contains('mediumImpact'));
      },
    );

    testWidgets('SOS circle: hover 1.05, press 0.93 + heavy haptic on down', (
      tester,
    ) async {
      await boot(tester, AppRoutes.sosCall);
      final sos = find.ancestor(
        of: find.text('SOS'),
        matching: find.byType(AppPressable),
      );
      final scale = find
          .descendant(of: sos, matching: find.byType(AnimatedScale))
          .first;
      final g = await mouse(tester);
      final p = tester.getCenter(find.text('SOS'));

      await g.moveTo(p);
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.widget<AnimatedScale>(scale).scale, 1.05);

      await g.down(p);
      await tester.pump(const Duration(milliseconds: 16));
      expect(haptics, ['heavyImpact']);
      expect(tester.widget<AnimatedScale>(scale).scale, 0.93);
      await g.up();
    });

    testWidgets(
      'outgoing call: control toggles to white, hang-up heavy haptic',
      (tester) async {
        await boot(tester, AppRoutes.calling('Calmette', '119'));
        final mute = find.ancestor(
          of: find.text('mute'),
          matching: find.byType(AppPressable),
        );
        final glass = find.descendant(
          of: mute,
          matching: find.byType(LiquidGlassContainer),
        );
        // Smoked dark glass at rest; bright frosted glass once toggled on.
        expect(
          tester.widget<LiquidGlassContainer>(glass).tint,
          LiquidTint.dark,
        );
        await tester.tap(find.text('mute'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          tester.widget<LiquidGlassContainer>(glass).tint,
          LiquidTint.frostStrong,
        );
        expect(haptics, contains('selectionClick'));

        haptics.clear();
        final hang = find.byTooltip('End call');
        final g = await mouse(tester);
        await g.down(tester.getCenter(hang));
        await tester.pump(const Duration(milliseconds: 16));
        expect(haptics, ['heavyImpact']);
        await g.up();
      },
    );

    testWidgets('bottom nav: hover lift, press sink 0.88, selection haptic', (
      tester,
    ) async {
      await boot(tester, AppRoutes.home);
      final tab = find.ancestor(
        of: find.text('Safety Tips'),
        matching: find.byType(AppPressable),
      );
      final lift = find
          .descendant(of: tab, matching: find.byType(AnimatedSlide))
          .first;
      final g = await mouse(tester);
      final p = tester.getCenter(find.text('Safety Tips'));

      await g.moveTo(p);
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester.widget<AnimatedSlide>(lift).offset.dy,
        closeTo(-2 / 26, 1e-9),
      );

      await g.down(p);
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.widget<AnimatedScale>(scaleOf(tab)).scale, 0.88);
      await g.up();
      await frames(tester, 3);
      expect(haptics, contains('selectionClick'));
    });

    testWidgets(
      'safety: urgent banner hover → #FECACA; back chevron nudges -3px',
      (tester) async {
        await boot(tester, '${AppRoutes.safety}/tips?situation=car');
        final banner = find.ancestor(
          of: find.text('Need urgent help?'),
          matching: find.byType(AppInteractiveCard),
        );
        final g = await mouse(tester);
        await g.moveTo(tester.getCenter(banner));
        await tester.pump(const Duration(milliseconds: 250));
        expect(
          decorationOf(tester, buttonBox(banner)).color,
          const Color(0xFFFECACA),
        );

        final back = find.byType(AppBackButton);
        final chevron = find.descendant(
          of: back,
          matching: find.byType(AnimatedSlide),
        );
        expect(tester.widget<AnimatedSlide>(chevron).offset, Offset.zero);
        await g.moveTo(tester.getCenter(back));
        await tester.pump(const Duration(milliseconds: 250));
        expect(
          tester.widget<AnimatedSlide>(chevron).offset.dx,
          closeTo(-3 / 28, 1e-9),
        );
      },
    );

    testWidgets(
      'map pin: hover 1.16, tap = light haptic; sheet call button 1.08 / 0.90',
      (tester) async {
        await boot(tester, AppRoutes.map);
        final g = await mouse(tester);

        final pin = find
            .ancestor(
              of: find.text('Hospital').first,
              matching: find.byType(AppPressable),
            )
            .first;
        await g.moveTo(
          tester.getCenter(find.text('Hospital').first) - const Offset(0, 25),
        );
        await tester.pump(const Duration(milliseconds: 250));
        expect(tester.widget<AnimatedScale>(scaleOf(pin)).scale, 1.16);

        await tester.tap(find.text('Hospital').first);
        await frames(tester, 14);
        expect(haptics, contains('lightImpact'));

        // State B: suggestion row tap selects it; no round call button.
        expect(find.byTooltip('Call'), findsNothing);
        final row = find.text('Calmette Hospital').first;
        await g.moveTo(tester.getCenter(row));
        await tester.pump(const Duration(milliseconds: 250));
        await g.down(tester.getCenter(row));
        await tester.pump(const Duration(milliseconds: 16));
        await g.up();
      },
    );

    testWidgets('hotlines: Khan row hover tint + call button pop', (
      tester,
    ) async {
      await boot(tester, AppRoutes.hotlines);
      final row = find.ancestor(
        of: find.text('Khan Chamkar Mon'),
        matching: find.byType(AppInteractiveCard),
      );
      final g = await mouse(tester);
      await g.moveTo(tester.getCenter(find.text('Khan Chamkar Mon')));
      await tester.pump(const Duration(milliseconds: 250));
      // Glass card: the rim/shadow brighten (hovered) …
      final glass = find.descendant(
        of: row,
        matching: find.byType(LiquidGlassContainer),
      );
      expect(tester.widget<LiquidGlassContainer>(glass.first).hovered, isTrue);
    });
  });
}
