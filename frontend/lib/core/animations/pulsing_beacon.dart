import 'package:flutter/material.dart';

import 'app_animations.dart';
import 'looping_animation.dart';

/// Expanding, fading ripple behind a static [child] "core" — used for the live
/// GPS dot and the map user beacon.
///
/// Built as an [AnimatedWidget] (`listenable: animation`); the scale/opacity are
/// evaluated from static [Tween]s. The [child] instance is reused on every
/// tick, so it is never rebuilt.
class PulsingBeacon extends AnimatedWidget {
  const PulsingBeacon({
    super.key,
    required Animation<double> animation,
    required this.color,
    this.size = 10,
    this.child,
  }) : super(listenable: animation);

  /// Ripple colour (the core's colour comes from [child]).
  final Color color;

  /// Diameter of the core; the ripple grows to ~2.8× this.
  final double size;

  /// The static core. Defaults to a solid dot of [color].
  final Widget? child;

  static final Tween<double> _scale = Tween<double>(begin: 1.0, end: 2.8);
  static final Tween<double> _opacity = Tween<double>(begin: 0.45, end: 0.0);

  Animation<double> get _animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: _opacity.evaluate(_animation),
            child: Transform.scale(
              scale: _scale.evaluate(_animation),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
          child ??
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
        ],
      ),
    );
  }
}

/// [PulsingBeacon] driven by a ping-pong loop
/// (`controller.repeat(reverse: true)`, 1.6 s, ease-in-out sine).
class LiveBeacon extends StatelessWidget {
  const LiveBeacon({
    super.key,
    required this.color,
    this.size = 10,
    this.child,
  });

  final Color color;
  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return LoopingAnimation(
      duration: AppDurations.pulse,
      reverse: true,
      curve: AppCurves.inOut,
      builder: (context, animation) => PulsingBeacon(
        animation: animation,
        color: color,
        size: size,
        child: child,
      ),
    );
  }
}
