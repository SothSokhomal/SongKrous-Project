import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/staggered_entrance.dart';
import '../../core/constants/app_state.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/onboarding_scaffold.dart';

/// 01_Onboarding — an informational "feature overview" (Apple HIG pattern).
///
/// The three features are flat rows on the white background: no cards, borders,
/// shadows or tap effects, so they read as information. The only clickable
/// element is the `Continue →` pill at the bottom.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  // [begin, end] slices of the 650 ms entrance controller.
  static const _headline = (0.0, 0.4);
  static const _rows = [(0.15, 0.6), (0.3, 0.8), (0.45, 1.0)];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = [
      _Feature(
        icon: Icons.add_rounded,
        color: AppColors.red,
        tint: AppColors.redTint,
        title: ref.tr('feat_help'),
        body: ref.tr('feat_help_sub'),
      ),
      _Feature(
        icon: Icons.location_on_rounded,
        color: AppColors.blue,
        tint: AppColors.blueTint,
        title: ref.tr('feat_gps'),
        body: ref.tr('feat_gps_sub'),
      ),
      _Feature(
        icon: Icons.verified_user_rounded,
        color: AppColors.blue,
        tint: AppColors.blueTint,
        title: ref.tr('feat_aid'),
        body: ref.tr('feat_aid_sub'),
      ),
    ];

    return OnboardingScaffold(
      buttonLabel: ref.tr('continue'),
      buttonIcon: Icons.arrow_forward_rounded,
      onNext: () => context.push(AppRoutes.enterNumber),
      footer: const Padding(
        padding: EdgeInsets.only(bottom: 14),
        child: _StepDots(current: 0, total: 2),
      ),
      body: StaggerScope(
        duration: const Duration(milliseconds: 650),
        // Let the Hero / page cross-fade settle before the content starts.
        delay: const Duration(milliseconds: 120),
        builder: (context, animation) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggeredEntrance(
              animation: animation,
              begin: _headline.$1,
              end: _headline.$2,
              offset: 12,
              child: _Headline(
                title: ref.tr('onb_title'),
                subtitle: ref.tr('onb_sub'),
              ),
            ),
            for (var i = 0; i < features.length; i++) ...[
              const SizedBox(height: 20),
              StaggeredEntrance(
                animation: animation,
                begin: _rows[i].$1,
                end: _rows[i].$2,
                offset: 12,
                child: features[i],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Headline directly on the white background. Line height ≥ 1.45 so Khmer
/// stacked vowels / subscripts are never clipped.
class _Headline extends StatelessWidget {
  const _Headline({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
            height: 1.5,
            fontFamilyFallback: ['Noto Sans Khmer'],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.slate,
            height: 1.5,
            fontFamilyFallback: ['Noto Sans Khmer'],
          ),
        ),
      ],
    );
  }
}

/// One informational row: tinted icon square + title + short explanation.
/// Deliberately has no container, border, shadow or gesture handling.
class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.color,
    required this.tint,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final Color tint;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    // Purely informational: arrow cursor, no hover/press, no gestures.
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1.5,
                      fontFamilyFallback: ['Noto Sans Khmer'],
                    ),
                  ),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.slate,
                      height: 1.5,
                      fontFamilyFallback: ['Noto Sans Khmer'],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill-style progress dots (`●○`), purely decorative orientation.
class _StepDots extends ConsumerWidget {
  const _StepDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = ref
        .tr('step_of')
        .replaceAll('{n}', '${current + 1}')
        .replaceAll('{total}', '$total');
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < total; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == current ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == current
                      ? AppColors.blueDeep
                      : AppColors.slateLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
