import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Motion tokens. Emergency UX rule: interactions are crisp and calm
/// (220–450 ms, ease-out); only *continuous loops* are slow and breathing.
abstract final class AppDurations {
  /// Small state changes (tab icon, underline, selection).
  static const Duration fast = Duration(milliseconds: 180);

  /// Press feedback.
  static const Duration tap = Duration(milliseconds: 120);

  /// Sheets, cross-fades, route transitions.
  static const Duration medium = Duration(milliseconds: 320);

  /// Total time of a staggered group entrance.
  static const Duration staggerTotal = Duration(milliseconds: 600);

  /// Hero logo entrance on the splash screen.
  static const Duration entrance = Duration(milliseconds: 700);

  /// Live status loops (GPS / SOS beacons).
  static const Duration pulse = Duration(milliseconds: 1600);

  /// Calm breathing guide: 4 s in, 4 s out (reverse).
  static const Duration breathing = Duration(milliseconds: 4000);
}

abstract final class AppCurves {
  /// Default for anything the user triggers.
  static const Curve out = Curves.easeOutCubic;

  /// Smooth symmetric curve for looping/breathing motion.
  static const Curve inOut = Curves.easeInOutSine;
}

CustomTransitionPage<void> buildIosPageTransition({
  required GoRouterState state,
  required Widget child,
  Offset begin = const Offset(0.05, 0),
  bool slide = true,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: AppCurves.out);
      final faded = FadeTransition(opacity: curved, child: child);
      if (!slide) return faded;
      return SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
        child: faded,
      );
    },
  );
}
