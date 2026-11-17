import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/constants/app_state.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_interactive.dart';

/// Soft-red warning card — an obvious button: it intensifies on hover
/// (`#FEE2E2 → #FECACA`), sinks on press, shows a `Call →` affordance that
/// nudges right on hover, and jumps straight to SOS Direct Call.
class UrgentBanner extends ConsumerWidget {
  const UrgentBanner({super.key, this.bodyKey = 'urgent_body'});

  final String bodyKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return AppInteractiveCard(
      semanticLabel: ref.tr('urgent_title'),
      radius: 16,
      onTap: () => context.push(AppRoutes.sosCall),
      haptic: AppHaptic.medium,
      pressedScale: 0.98,
      surface: AppColors.redSoft,
      hoverSurface: const Color(0xFFFECACA),
      restBorder: null,
      hoverBorder: const Color(0xFFFCA5A5),
      padding: const EdgeInsets.all(16),
      builder: (context, hovered, pressed) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.red,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.tr('urgent_title'),
                  style: text.titleMedium?.copyWith(
                    color: AppColors.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ref.tr(bodyKey),
                  style: text.bodyMedium?.copyWith(color: AppColors.redDark),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // `Call →` affordance.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ref.tr('call'),
                style: const TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  fontFamilyFallback: ['Noto Sans Khmer'],
                ),
              ),
              AnimatedSlide(
                duration: const Duration(milliseconds: 130),
                curve: AppCurves.out,
                offset: Offset(hovered ? 4 / 18 : 0, 0),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.red,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
