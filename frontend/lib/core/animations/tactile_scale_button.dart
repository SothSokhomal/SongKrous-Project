import 'package:flutter/material.dart';

import 'app_animations.dart';

/// Physical press feedback: scales [child] down to 0.97 on tap-down and back to
/// 1.0 on tap-up / cancel (120 ms). Wrap emergency cards, category buttons and
/// CTAs. Give it the `onTap` instead of nesting an `InkWell` inside, so the two
/// don't fight over the gesture.
class TactileScaleButton extends StatefulWidget {
  const TactileScaleButton({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<TactileScaleButton> createState() => _TactileScaleButtonState();
}

class _TactileScaleButtonState extends State<TactileScaleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.tap,
  );
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _controller,
    curve: AppCurves.out,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: widget.pressedScale,
  ).animate(_curved);

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Whole bounds are tappable, even over transparent child areas.
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
