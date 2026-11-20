import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_state.dart';
import '../../core/theme/app_colors.dart';
import 'app_interactive.dart';
import 'liquid_glass.dart';

/// Round frosted-glass `‹` back button (40 pt) for glass-styled screens.
class GlassBackButton extends ConsumerWidget {
  const GlassBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: ref.tr('back'),
      child: AppPressable(
        onTap: onTap,
        haptic: AppHaptic.selection,
        builder: (context, hovered, pressed) => AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: pressed ? 0.92 : 1,
          child: LiquidGlassContainer(
            width: 40,
            height: 40,
            radius: 20,
            useBlur: false,
            hovered: hovered,
            pressed: pressed,
            alignment: Alignment.center,
            child: const Icon(
              Icons.chevron_left_rounded,
              size: 26,
              color: AppColors.blueDeep,
            ),
          ),
        ),
      ),
    );
  }
}
