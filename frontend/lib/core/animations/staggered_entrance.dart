import 'dart:async';

import 'package:flutter/material.dart';

import 'app_animations.dart';

/// Owns the one-shot controller that drives a group of [StaggeredEntrance]
/// children. Hands the raw 0→1 animation to [builder]; each child picks its
/// own [Interval] slice of it.
class StaggerScope extends StatefulWidget {
  const StaggerScope({
    super.key,
    required this.builder,
    this.duration = AppDurations.staggerTotal,
    this.delay = Duration.zero,
  });

  final Duration duration;

  /// Wait before starting (e.g. let a page transition finish first).
  final Duration delay;
  final Widget Function(BuildContext context, Animation<double> animation)
  builder;

  @override
  State<StaggerScope> createState() => _StaggerScopeState();
}

class _StaggerScopeState extends State<StaggerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  Timer? _delayTimer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}

/// Fade + slide-up (18 px → 0) for [child] during the `[begin, end]` slice of
/// [animation]. Uses `AnimatedBuilder` with the static [child] passed through
/// `child:` so animation ticks never rebuild it.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.animation,
    required this.child,
    this.begin = 0.0,
    this.end = 1.0,
    this.offset = 18,
  });

  final Animation<double> animation;
  final Widget child;
  final double begin;
  final double end;

  /// Starting vertical offset in logical pixels.
  final double offset;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance> {
  late CurvedAnimation _curved = _create();

  CurvedAnimation _create() => CurvedAnimation(
    parent: widget.animation,
    curve: Interval(widget.begin, widget.end, curve: AppCurves.out),
  );

  @override
  void didUpdateWidget(StaggeredEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation ||
        oldWidget.begin != widget.begin ||
        oldWidget.end != widget.end) {
      _curved.dispose();
      _curved = _create();
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curved,
      child: AnimatedBuilder(
        animation: _curved,
        child: widget.child, // static subtree — built once
        builder: (context, child) => Transform.translate(
          offset: Offset(0, widget.offset * (1 - _curved.value)),
          child: child,
        ),
      ),
    );
  }
}
