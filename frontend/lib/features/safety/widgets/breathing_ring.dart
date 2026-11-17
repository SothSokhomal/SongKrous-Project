import 'package:flutter/material.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/animations/looping_animation.dart';
import '../../../core/theme/app_colors.dart';

/// A soft ring that slowly expands and contracts behind [child] to pace a
/// calm breath: 4 s in, 4 s out (`repeat(reverse: true)`, ease-in-out sine).
///
/// The illustration [child] is static and passed through `AnimatedBuilder`'s
/// `child:` so it is never rebuilt by animation ticks.
class BreathingRing extends StatelessWidget {
  const BreathingRing({
    super.key,
    required this.child,
    this.size = 52,
    this.color = AppColors.blue,
  });

  final Widget child;

  /// Diameter of the illustration; the ring peaks at ~1.22× this.
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final box = size * 1.25;
    return SizedBox(
      width: box,
      height: box,
      child: LoopingAnimation(
        duration: AppDurations.breathing,
        reverse: true,
        curve: AppCurves.inOut,
        builder: (context, animation) => AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final t = animation.value; // 0 = exhaled, 1 = inhaled
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Transform.scale(
                  scale: 1.0 + 0.22 * t,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.06 + 0.1 * t),
                      border: Border.all(
                        color: color.withValues(alpha: 0.18 + 0.2 * t),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                Transform.scale(scale: 1.0 + 0.05 * t, child: child),
              ],
            );
          },
        ),
      ),
    );
  }
}
