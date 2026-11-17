import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songkrous/core/animations/tactile_scale_button.dart';
import 'package:songkrous/core/constants/app_state.dart';
import 'package:songkrous/core/constants/app_strings.dart';
import 'package:songkrous/core/router/app_router.dart';
import 'package:songkrous/core/router/app_routes.dart';
import 'package:songkrous/main.dart';

Future<void> frames(WidgetTester tester, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<ProviderContainer> boot(
  WidgetTester tester, {
  AppLang lang = AppLang.en,
  Size size = const Size(1170, 2532),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.read(langProvider.notifier).set(lang);
  appRouter.go(AppRoutes.onboarding);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const SongkrousApp()),
  );
  await frames(tester);
  return c;
}

void main() {
  testWidgets('English: headline + 3 informational rows + Continue', (
    tester,
  ) async {
    await boot(tester);
    expect(find.text('Emergency help, simplified'), findsOneWidget);
    expect(
      find.text('Know what Songkrous does before you need it.'),
      findsOneWidget,
    );
    for (final t in [
      'One-Tap Help',
      'Auto-GPS Location',
      'First-Aid Guidance',
    ]) {
      expect(find.text(t), findsOneWidget);
    }
    expect(find.textContaining('without memorizing numbers'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
  });

  testWidgets('Khmer: exact headline, rows and Continue', (tester) async {
    await boot(tester, lang: AppLang.km);
    expect(find.text('ជំនួយសង្គ្រោះបន្ទាន់ កាន់តែងាយស្រួល'), findsOneWidget);
    expect(find.text('ស្វែងយល់ពីមុខងារសំខាន់ៗរបស់សង្គ្រោះ'), findsOneWidget);
    expect(find.text('ជំនួយដោយចុចតែម្តង'), findsOneWidget);
    expect(find.text('កំណត់ទីតាំង GPS ស្វ័យប្រវត្តិ'), findsOneWidget);
    expect(find.text('ការណែនាំសង្គ្រោះបឋម'), findsOneWidget);
    expect(find.text('បន្ត'), findsOneWidget);
  });

  testWidgets('language pill switches every onboarding text', (tester) async {
    await boot(tester, lang: AppLang.km);
    expect(find.text('Continue'), findsNothing);

    await tester.tap(find.text('English'));
    await frames(tester, 4);
    expect(find.text('Emergency help, simplified'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('បន្ត'), findsNothing);

    await tester.tap(find.text('ភាសាខ្មែរ'));
    await frames(tester, 4);
    expect(find.text('ជំនួយដោយចុចតែម្តង'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('feature rows are flat: no cards, ink, shadows or tap effects', (
    tester,
  ) async {
    await boot(tester);

    // The only InkWell is the one inside the CTA's FilledButton — the feature
    // rows have no ink/tap effects, and the CTA is the only tactile element.
    expect(find.byType(InkWell), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(InkWell),
      ),
      findsOneWidget,
    );
    expect(find.byType(Card), findsNothing);
    expect(find.byType(TactileScaleButton), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);

    // No decorated box in the row area carries a shadow or a border.
    final rows = find.ancestor(
      of: find.text('One-Tap Help'),
      matching: find.byType(DecoratedBox),
    );
    for (final e in rows.evaluate()) {
      final d = (e.widget as DecoratedBox).decoration as BoxDecoration;
      expect(d.boxShadow, isNull);
      expect(d.border, isNull);
    }

    // Tapping a row does nothing: still on onboarding, no exception.
    await tester.tap(find.text('One-Tap Help'));
    await frames(tester, 4);
    expect(find.text('Emergency help, simplified'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('feature text uses line height >= 1.45 (Khmer glyph safety)', (
    tester,
  ) async {
    await boot(tester, lang: AppLang.km);
    for (final t in [
      'ជំនួយសង្គ្រោះបន្ទាន់ កាន់តែងាយស្រួល',
      'ជំនួយដោយចុចតែម្តង',
      'ស្វែងយល់ពីមុខងារសំខាន់ៗរបស់សង្គ្រោះ',
    ]) {
      final style = tester.widget<Text>(find.text(t)).style!;
      expect(style.height, greaterThanOrEqualTo(1.45), reason: t);
    }
    final body = tester.widget<Text>(
      find.textContaining('ទាក់ទងទៅមន្ទីរពេទ្យ'),
    );
    expect(body.style!.height, greaterThanOrEqualTo(1.45));
  });

  testWidgets('Continue → phone-number screen', (tester) async {
    await boot(tester);
    await tester.tap(find.text('Continue'));
    await frames(tester, 6);
    expect(find.text('Enter your phone number'), findsOneWidget);
  });

  for (final lang in AppLang.values) {
    testWidgets('no overflow on a small phone [${lang.name}]', (tester) async {
      await boot(tester, lang: lang, size: const Size(960, 1704)); // 320x568
      expect(tester.takeException(), isNull);
    });
  }
}
