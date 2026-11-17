import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/map_state.dart';

import 'floating_bottom_nav.dart';

/// Hosts the four tab branches with a floating bottom nav over the content.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Bottom space tab content should reserve so it clears the floating nav.
  ///
  /// With `extendBody: true` the body's `MediaQuery.padding.bottom` already
  /// equals the nav bar's full height (bar + gap + system inset), so only a
  /// small breathing margin is added here.
  static double navClearance(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) {
          // Opening "Nearby Map" from the bar always starts on the clean map
          // (State A). Home's category cards pick a target via the router.
          if (i == 1 && navigationShell.currentIndex != 1) {
            ref.selectMapCategory(null);
          }
          navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
