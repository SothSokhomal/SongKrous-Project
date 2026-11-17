import 'package:flutter/material.dart';

import '../../../core/animations/looping_animation.dart';
import '../../../core/theme/app_colors.dart';

/// Concentric red rings around a static [child] (the solid SOS button).
///
/// * outer ring expands 0.9 → 1.25 while fading 0.35 → 0
/// * middle ring breathes calmly 0.95 → 1.08
///
/// An [AnimatedWidget] driven by a 1.8 s `repeat()` loop; the [child] instance
/// is reused every tick so the button itself is never rebuilt.
class SosPulseRings extends AnimatedWidget {
  const SosPulseRings({
    super.key,
    required Animation<double> animation,
    required this.size,
    required this.child,
  }) : super(listenable: animation);

  /// Diameter of the solid SOS circle.
  final double size;
  final Widget child;

  static final Tween<double> _outerScale = Tween(begin: 0.9, end: 1.25);
  static final Tween<double> _outerOpacity = Tween(begin: 0.35, end: 0.0);
  static final Tween<double> _middleScale = Tween(begin: 0.95, end: 1.08);

  Animation<double> get _animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final t = _animation.value;
    // Triangle wave 0→1→0 so the looping middle ring has no jump at the seam.
    final wave = Curves.easeInOutSine.transform(1 - (2 * t - 1).abs());

    Widget ring(double scale, double opacity) => Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColors.red,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );

    return SizedBox(
      width: size * 1.35,
      height: size * 1.35,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ring(
            _outerScale.evaluate(_animation),
            _outerOpacity.evaluate(_animation),
          ),
          ring(_middleScale.transform(wave), 0.22),
          child,
        ],
      ),
    );
  }
}

/// [SosPulseRings] driven by its own looping controller.
class LiveSosPulseRings extends StatelessWidget {
  const LiveSosPulseRings({super.key, required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LoopingAnimation(
      duration: const Duration(milliseconds: 1800),
      builder: (context, animation) =>
          SosPulseRings(animation: animation, size: size, child: child),
    );
  }
}
