import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songkrous/core/constants/app_state.dart';
import 'package:songkrous/core/constants/app_strings.dart';
import 'package:songkrous/core/router/app_router.dart';
import 'package:songkrous/core/router/app_routes.dart';
import 'package:songkrous/core/constants/facilities.dart';
import 'package:songkrous/core/state/map_state.dart';
import 'package:songkrous/core/theme/app_colors.dart';
import 'package:songkrous/main.dart';
import 'package:songkrous/shared/widgets/app_interactive.dart';
import 'package:songkrous/shared/widgets/emergency_emblem.dart';
import 'package:songkrous/shared/widgets/floating_bottom_nav.dart';
import 'package:songkrous/shared/widgets/liquid_glass.dart';

Future<void> frames(WidgetTester tester, [int n = 8, int ms = 120]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

Future<ProviderContainer> boot(WidgetTester tester, String route) async {
  tester.view.physicalSize = const Size(1170, 2532); // 390 x 844 @3x
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.read(langProvider.notifier).set(AppLang.en);
  appRouter.go(route);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const SongkrousApp()),
  );
  await frames(tester, 8);
  return c;
}

// ── WCAG contrast ─────────────────────────────────────────────────────────

double _lin(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
double _lum(Color c) =>
    0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b);
double contrast(Color a, Color b) {
  final l1 = _lum(a), l2 = _lum(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

/// Composite [fg] (with alpha) over an opaque [bg].
Color over(Color fg, Color bg) => Color.alphaBlend(fg, bg);

void main() {
  group('LiquidGlassContainer', () {
    testWidgets('blur only when asked; rim + sheen painters always', (
      tester,
    ) async {
      Widget host(bool blur) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: LiquidGlassContainer(
              useBlur: blur,
              width: 120,
              height: 60,
              child: const Text('x'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(host(true));
      expect(
        find.descendant(
          of: find.byType(LiquidGlassContainer),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(host(false));
      expect(
        find.descendant(
          of: find.byType(LiquidGlassContainer),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
      // Fast mode keeps the look: a foreground (rim) painter is still there.
      final paint = tester.widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(LiquidGlassContainer),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      expect(paint.foregroundPainter, isNotNull);
      expect(paint.painter, isNotNull); // outside-only shadow
    });

    testWidgets('paints without errors for every tint and corner style', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                for (final t in LiquidTint.values)
                  LiquidGlassContainer(
                    tint: t,
                    height: 50,
                    hovered: t.index.isEven,
                    pressed: t.index == 3,
                    child: Text(t.name),
                  ),
                const LiquidGlassContainer(
                  height: 50,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('ambient canvas: #F4F7FB with a blue and a rose orb', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: LiquidAmbientCanvas(child: SizedBox())),
      );
      final base = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(LiquidAmbientCanvas),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(base.color, const Color(0xFFF4F7FB));
      final orbs = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(LiquidAmbientCanvas),
              matching: find.byType(Container),
            ),
          )
          .map((c) => (c.decoration as BoxDecoration?)?.gradient)
          .whereType<RadialGradient>()
          .map((g) => g.colors.first)
          .toList();
      expect(orbs, hasLength(2));
      expect(orbs.map((c) => c.a), everyElement(closeTo(0.40, 0.005)));
    });
  });

  group('Home', () {
    testWidgets('three clean emergency cards: one bold title, nothing else', (
      tester,
    ) async {
      await boot(tester, AppRoutes.home);

      expect(find.text('Hospital'), findsOneWidget);
      expect(find.text('Police'), findsOneWidget);
      expect(find.text('Fire'), findsOneWidget);
      expect(find.byType(EmergencyEmblem), findsNWidgets(3));

      // Every card holds exactly ONE piece of text — its title: no subtitle,
      // distance, facility name or badge.
      final cards = find.byType(AppInteractiveCard);
      expect(cards, findsNWidgets(3));
      for (final title in ['Hospital', 'Police', 'Fire']) {
        final card = find.ancestor(
          of: find.text(title),
          matching: find.byType(AppInteractiveCard),
        );
        final texts = tester
            .widgetList<Text>(
              find.descendant(of: card, matching: find.byType(Text)),
            )
            .map((t) => t.data)
            .toList();
        expect(texts, [title], reason: title);
      }
      for (final gone in [
        'Calmette',
        'km',
        'min',
        '24/7',
        'ER',
        'DIRECT',
        'HOTLINE',
        '118',
        '012',
      ]) {
        expect(find.textContaining(gone), findsNothing, reason: gone);
      }

      // Title style: 23 px, w800, ink.
      final style = tester.widget<Text>(find.text('Hospital')).style!;
      expect(style.fontSize, 23);
      expect(style.fontWeight, FontWeight.w800);

      // Card geometry: ~136 px tall, 72 px emblem, 42 px arrow chip.
      final card = find.ancestor(
        of: find.text('Hospital'),
        matching: find.byType(AppInteractiveCard),
      );
      expect(tester.getSize(card).height, closeTo(136, 4));
      expect(
        tester.getSize(find.byType(EmergencyEmblem).first),
        const Size(72, 72),
      );
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
      expect(find.textContaining('YOUR LOCATION'), findsOneWidget);
    });

    testWidgets('Khmer cards: one Khmer title each, nothing else', (
      tester,
    ) async {
      final c = await boot(tester, AppRoutes.home);
      c.read(langProvider.notifier).set(AppLang.km);
      await frames(tester, 4);
      for (final title in ['មន្ទីរពេទ្យ', 'ប៉ូលិស', 'ពន្លត់អគ្គិភ័យ']) {
        final card = find.ancestor(
          of: find.text(title),
          matching: find.byType(AppInteractiveCard),
        );
        final texts = tester
            .widgetList<Text>(
              find.descendant(of: card, matching: find.byType(Text)),
            )
            .map((t) => t.data)
            .toList();
        expect(texts, [title], reason: title);
      }
      expect(find.textContaining('Medical'), findsNothing);
      expect(find.textContaining('GPS'), findsNothing);
      expect(find.textContaining('SOS'), findsNothing);
      expect(find.textContaining('Calmette'), findsNothing);
      expect(find.text('១១.៥៨១៣° ជើង, ១០៤.៩១៥៨° កើត'), findsNothing);
    });

    testWidgets('category card tap navigates to map for that category', (
      tester,
    ) async {
      final c = await boot(tester, AppRoutes.home);
      await tester.tap(find.text('Hospital'));
      await frames(tester, 12);
      expect(c.read(selectedMapTargetProvider), FacilityType.hospital);
      expect(find.text('Nearby Hospitals'), findsOneWidget);
    });

    testWidgets('no BackdropFilter inside the scrolling list (60 fps rule)', (
      tester,
    ) async {
      await boot(tester, AppRoutes.home);
      // Blur lives on the floating dock only; list items use fast glass.
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
      expect(find.byType(BackdropFilter), findsOneWidget); // the dock
    });
  });

  group('Dock', () {
    testWidgets('blur σ22, and the lens slides to the active tab', (
      tester,
    ) async {
      await boot(tester, AppRoutes.home);
      final dockBlur = find.descendant(
        of: find.byType(FloatingBottomNav),
        matching: find.byType(BackdropFilter),
      );
      expect(dockBlur, findsOneWidget);

      Alignment lens() =>
          tester
                  .widget<AnimatedAlign>(
                    find.descendant(
                      of: find.byType(FloatingBottomNav),
                      matching: find.byType(AnimatedAlign),
                    ),
                  )
                  .alignment
              as Alignment;

      expect(lens(), const Alignment(-1, 0)); // Home
      await tester.tap(find.text('Map'));
      await frames(tester, 6);
      expect(lens().x, closeTo(-0.5, 1e-9));
      await tester.tap(find.text('Safety Tips'));
      await frames(tester, 6);
      expect(lens().x, closeTo(0, 1e-9));
      await tester.tap(find.text('Hotline'));
      await frames(tester, 6);
      expect(lens().x, closeTo(0.5, 1e-9));
      await tester.tap(find.text('Settings').last);
      await frames(tester, 6);
      expect(lens().x, closeTo(1.0, 1e-9));
    });
  });

  group('screens use the glass system', () {
    testWidgets('Frame 1: frosted secondary buttons and address box', (
      tester,
    ) async {
      await boot(tester, AppRoutes.sosCall);
      final tints = tester
          .widgetList<LiquidGlassContainer>(find.byType(LiquidGlassContainer))
          .map((g) => g.tint)
          .toSet();
      expect(tints, contains(LiquidTint.frost));
    });

    testWidgets('Outgoing call: dark smoked glass + glossy red hang-up', (
      tester,
    ) async {
      await boot(tester, AppRoutes.calling('Calmette', '119'));
      final glass = tester
          .widgetList<LiquidGlassContainer>(find.byType(LiquidGlassContainer))
          .toList();
      expect(
        glass.where((g) => g.tint == LiquidTint.dark).length,
        greaterThanOrEqualTo(6),
      );
      expect(glass.where((g) => g.tint == LiquidTint.red), isNotEmpty);
    });

    testWidgets(
      'Onboarding: ambient canvas + glass logo + glass language pill',
      (tester) async {
        await boot(tester, AppRoutes.onboarding);
        expect(find.byType(LiquidAmbientCanvas), findsOneWidget);
        expect(find.byType(LiquidGlassContainer), findsWidgets);
      },
    );

    testWidgets('Map: search, Khan pill and recenter use BACKDROP glass', (
      tester,
    ) async {
      await boot(tester, AppRoutes.map);
      expect(
        find.byType(BackdropFilter),
        findsNWidgets(4),
      ); // 3 overlays + dock
    });

    testWidgets('Chat: glass header blurs the list; composer is glass', (
      tester,
    ) async {
      await boot(tester, AppRoutes.chat);
      expect(find.byType(LiquidAmbientCanvas), findsOneWidget);
      expect(find.byType(BackdropFilter), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('contrast ≥ 4.5:1 on translucent glass', () {
    // Worst realistic backdrops: the ambient canvas and plain white; for map
    // overlays a mid-grey road tile.
    const canvas = Color(0xFFF4F7FB);
    const road = Color(0xFFC8CDD4);
    final frostLightest = Colors.white.withValues(alpha: 0.56); // gradient end

    for (final bg in [canvas, Colors.white, road]) {
      final glass = over(frostLightest, bg);
      final name = bg.toARGB32().toRadixString(16);
      test('ink / body slate text on frost over $name', () {
        expect(contrast(AppColors.ink, glass), greaterThan(4.5));
        expect(contrast(const Color(0xFF475569), glass), greaterThan(4.5));
        expect(contrast(AppColors.blueDeep, glass), greaterThan(4.5));
      });
    }

    test('white on the blue hero glass', () {
      final lightest = over(
        const Color(0xFF1E40AF).withValues(alpha: 0.88),
        Colors.white,
      );
      expect(contrast(Colors.white, lightest), greaterThan(4.5));
    });

    test('white on the red call glass', () {
      final lightest = over(
        const Color(0xFFB3121F).withValues(alpha: 0.90),
        Colors.white,
      );
      final top = over(AppColors.red.withValues(alpha: 0.94), Colors.white);
      expect(contrast(Colors.white, lightest), greaterThan(4.5));
      expect(contrast(Colors.white, top), greaterThan(4.5));
    });

    test('card pills & copied state', () {
      final strong = over(Colors.white.withValues(alpha: 0.88), canvas);
      expect(
        contrast(const Color(0xFFB3121F), strong),
        greaterThan(4.5),
      ); // fire/med pill
      expect(
        contrast(AppColors.blueDeep, strong),
        greaterThan(4.5),
      ); // police pill
      expect(
        contrast(const Color(0xFF15803D), strong),
        greaterThan(4.5),
      ); // ✓ Copied
    });

    test('white text on smoked dark glass over the call background', () {
      final glass = over(
        const Color(0xFF0F172A).withValues(alpha: 0.55),
        AppColors.callBackground,
      );
      expect(contrast(Colors.white, glass), greaterThan(7));
    });
  });
}
