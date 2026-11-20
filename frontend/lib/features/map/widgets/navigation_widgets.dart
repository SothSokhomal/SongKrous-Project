import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/constants/app_state.dart';
import '../../../core/constants/facilities.dart';
import '../../../core/constants/phnom_penh_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_interactive.dart';
import '../../../shared/widgets/liquid_glass.dart';

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
    final text = Theme.of(context).textTheme;

    // Floating route card: frosted glass refracting the map underneath.
    return LiquidGlassContainer(
      radius: 32,
      sigma: 20,
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: '${ref.tr('details')}: ${f.name(lang)}',
              child: AppPressable(
                onTap: onDetails,
                haptic: AppHaptic.selection,
                builder: (context, hovered, pressed) => AnimatedOpacity(
                  duration: const Duration(milliseconds: 100),
                  opacity: pressed ? 0.55 : 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name underlines on hover: it opens the details screen.
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 130),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: (text.titleMedium ?? const TextStyle()).copyWith(
                          decoration: hovered
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        ),
                        child: Text(f.name(lang)),
                      ),
                      AnimatedSwitcher(
                        duration: AppDurations.fast,
                        child: Text(
                          target.pillSummary(lang),
                          key: ValueKey(target.pillSummary(lang)),
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
          ),
          const SizedBox(width: 8),
          AppInteractiveButton(
            height: 44,
            expand: false,
            fontSize: 13,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            leadingIcon: navigating
                ? Icons.call_rounded
                : Icons.navigation_rounded,
            label: ref.tr(navigating ? 'call_now' : 'start_route'),
            // Red for hospital/fire, deep blue for police.
            colors: f.type == FacilityType.police
                ? AppButtonColors.glassBlue
                : AppButtonColors.glassRed,
            haptic: navigating ? AppHaptic.medium : AppHaptic.light,
            onPressed: onPrimary,
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
      child: LiquidGlassContainer(
        radius: 22,
        tint: LiquidTint.blue,
        useBlur: false,
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
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
                      height: 1.5,
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
            AppInteractiveButton(
              height: 38,
              expand: false,
              fontSize: 13,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              label: ref.tr('exit'),
              colors: AppButtonColors.glassOnBlueSolid,
              haptic: AppHaptic.medium,
              onPressed: onExit,
            ),
          ],
        ),
      ),
    );
  }
}
