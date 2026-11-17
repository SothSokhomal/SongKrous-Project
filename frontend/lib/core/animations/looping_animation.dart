import 'package:flutter/material.dart';

/// Owns a repeating [AnimationController] (+ [CurvedAnimation]) and hands the
/// curved animation to [builder]. Centralises ticker creation and disposal for
/// every continuous loop in the app (beacons, SOS rings, breathing guide).
///
/// Honours the OS "reduce motion" setting: loops are frozen at their start
/// value instead of running.
class LoopingAnimation extends StatefulWidget {
  const LoopingAnimation({
    super.key,
    required this.duration,
    required this.builder,
    this.reverse = false,
    this.curve = Curves.linear,
  });

  final Duration duration;

  /// `true` → `controller.repeat(reverse: true)` (ping-pong).
  final bool reverse;
  final Curve curve;
  final Widget Function(BuildContext context, Animation<double> animation)
  builder;

  @override
  State<LoopingAnimation> createState() => _LoopingAnimationState();
}

class _LoopingAnimationState extends State<LoopingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(LoopingAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.reverse != widget.reverse) {
      _controller.stop();
    }
    _sync();
  }

  void _sync() {
    if (_reduceMotion) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: widget.reverse);
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _curved);
}
