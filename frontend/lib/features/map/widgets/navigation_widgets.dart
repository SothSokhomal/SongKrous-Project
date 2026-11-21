import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return AppInteractiveButton(
      height: 52,
      expand: true,
      fontSize: 15,
      leadingIcon: navigating
          ? Icons.chat_bubble_rounded
          : Icons.emergency_rounded,
      label: ref.tr(navigating ? 'send_message' : 'trigger_sos'),
      colors: f.type == FacilityType.police
          ? AppButtonColors.glassBlue
          : (navigating ? AppButtonColors.glassBlue : AppButtonColors.danger),
      haptic: AppHaptic.heavy,
      onPressed: onPrimary,
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
