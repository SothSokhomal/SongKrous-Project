import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/animations/tactile_scale_button.dart';
import '../../../core/constants/app_state.dart';
import '../../../core/constants/phnom_penh_data.dart';
import '../../../core/theme/app_colors.dart';
import 'map_markers.dart';

/// Floating pill above the category bar: destination, `4 min • 1.2 km` and a
/// primary action (`Start Route`, or `Call Now` once navigating). Tapping the
/// text opens the facility details (SOS screen).
class NavInfoPill extends ConsumerWidget {
  const NavInfoPill({
    super.key,
    required this.target,
    required this.navigating,
    required this.onPrimary,
    required this.onDetails,
  });

  final RankedFacility target;
  final bool navigating;
  final VoidCallback onPrimary;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = target.facility;
    final lang = ref.watch(langProvider);
    final color = facilityColor(f.type);
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: '${ref.tr('details')}: ${f.name(lang)}',
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onDetails,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.name(lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium,
                    ),
                    AnimatedSwitcher(
                      duration: AppDurations.fast,
                      child: Text(
                        target.pillSummary,
                        key: ValueKey(target.pillSummary),
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TactileScaleButton(
            onTap: onPrimary,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    navigating ? Icons.call_rounded : Icons.navigation_rounded,
                    size: 16,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ref.tr(navigating ? 'call_now' : 'start_route'),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      fontFamilyFallback: ['Noto Sans Khmer'],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Apple-Maps-style instruction card shown at the top while "navigating".
class NavBanner extends ConsumerWidget {
  const NavBanner({
    super.key,
    required this.instruction,
    required this.distance,
    required this.onExit,
  });

  final String instruction;
  final String distance;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.blueDeep,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.turn_right_rounded,
                color: AppColors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instruction,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.3,
                      fontFamilyFallback: ['Noto Sans Khmer'],
                    ),
                  ),
                  Text(
                    '• $distance',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TactileScaleButton(
              onTap: onExit,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ref.tr('exit'),
                  style: const TextStyle(
                    color: AppColors.blueDeep,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    fontFamilyFallback: ['Noto Sans Khmer'],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
