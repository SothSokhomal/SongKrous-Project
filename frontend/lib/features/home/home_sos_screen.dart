import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/app_animations.dart';
import '../../core/animations/pulsing_beacon.dart';
import '../../core/animations/staggered_entrance.dart';
import '../../core/animations/tactile_scale_button.dart';
import '../../core/constants/app_state.dart';
import '../../core/constants/facilities.dart';
import '../../core/constants/phnom_penh_data.dart';
import '../../core/router/app_routes.dart';
import '../../core/state/location_state.dart';
import '../../core/state/map_state.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/khan_picker.dart';
import '../../shared/widgets/language_toggle.dart';
import '../../shared/widgets/main_shell.dart';
import '../../shared/widgets/shield_badge.dart';

/// 03_Home_SOS — location banner + three emergency category cards, staggered in.
class HomeSosScreen extends ConsumerWidget {
  const HomeSosScreen({super.key});

  // [begin, end] slices of the entrance controller.
  static const _bannerSlice = (0.0, 0.45);
  static const _cardSlices = [(0.15, 0.65), (0.3, 0.8), (0.45, 1.0)];

  Future<void> _copy(BuildContext context, WidgetRef ref) async {
    await Clipboard.setData(
      ClipboardData(text: ref.read(locationProvider).shareText),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(ref.tr('location_copied')),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _openMap(BuildContext context, WidgetRef ref, FacilityType? type) {
    // null → State A (clean map); a category → State B (sheet + route).
    ref.selectMapCategory(type);
    context.go(AppRoutes.map);
  }

  void _sos(BuildContext context, WidgetRef ref, FacilityType type) {
    final loc = ref.read(locationProvider);
    final nearest = rankFacilities(loc.latLng, type: type).firstOrNull;
    context.push(AppRoutes.sosCall, extra: nearest?.facility);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(locationProvider);

    return SafeArea(
      bottom: false,
      child: StaggerScope(
        builder: (context, animation) => ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MainShell.navClearance(context),
          ),
          children: [
            _TopBar(
              gpsActive: loc.gpsActive,
              onGpsTap: () async {
                if (loc.gpsActive) return;
                // GPS off: try again, then fall back to manual Khan selection.
                final ok = await ref
                    .read(locationProvider.notifier)
                    .requestPermission();
                if (!ok && context.mounted) {
                  final khan = await showKhanPicker(
                    context,
                    selected: loc.khan,
                  );
                  if (khan != null) {
                    ref.read(locationProvider.notifier).setKhan(khan);
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            StaggeredEntrance(
              animation: animation,
              begin: _bannerSlice.$1,
              end: _bannerSlice.$2,
              child: _LocationCard(
                loc: loc,
                onCopy: () => _copy(context, ref),
                onViewMap: () => _openMap(context, ref, null),
              ),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < FacilityType.values.length; i++)
              StaggeredEntrance(
                animation: animation,
                begin: _cardSlices[i].$1,
                end: _cardSlices[i].$2,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _CategoryCard(
                    type: FacilityType.values[i],
                    onTap: () => _openMap(context, ref, FacilityType.values[i]),
                    onSos: () => _sos(context, ref, FacilityType.values[i]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.gpsActive, required this.onGpsTap});

  final bool gpsActive;
  final VoidCallback onGpsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = gpsActive ? AppColors.blue : AppColors.red;
    return Row(
      children: [
        const Icon(
          Icons.health_and_safety_rounded,
          color: AppColors.blueDeep,
          size: 28,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'SONGKROUS',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.blueDeep,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onGpsTap,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: gpsActive ? AppColors.blueSoft : AppColors.redSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Live status: pulsing ripple only while GPS is active.
                if (gpsActive)
                  const LiveBeacon(color: AppColors.blue, size: 8)
                else
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  ref.tr(gpsActive ? 'gps_active' : 'gps_off'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        const LanguageCompactToggle(),
      ],
    );
  }
}

class _LocationCard extends ConsumerWidget {
  const _LocationCard({
    required this.loc,
    required this.onCopy,
    required this.onViewMap,
  });

  final UserLocation loc;
  final Future<void> Function() onCopy;
  final VoidCallback onViewMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blueDeep,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📍 ${ref.tr('your_location')}',
            style: text.labelSmall?.copyWith(
              color: AppColors.white.withValues(alpha: 0.85),
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            loc.headline,
            style: text.titleLarge?.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 2),
          Text(
            loc.khanLine,
            style: text.bodyMedium?.copyWith(
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _CopyPill(onCopy: onCopy)),
              const SizedBox(width: 10),
              Expanded(
                child: _Pill(
                  icon: Icons.map_rounded,
                  label: ref.tr('view_map'),
                  background: Colors.white.withValues(alpha: 0.16),
                  foreground: AppColors.white,
                  onTap: onViewMap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `Copy Location` → `Copied ✓` for 2 s, cross-faded with [AnimatedSwitcher].
class _CopyPill extends ConsumerStatefulWidget {
  const _CopyPill({required this.onCopy});

  final Future<void> Function() onCopy;

  @override
  ConsumerState<_CopyPill> createState() => _CopyPillState();
}

class _CopyPillState extends ConsumerState<_CopyPill> {
  bool _copied = false;
  Timer? _reset;

  Future<void> _onTap() async {
    await widget.onCopy();
    if (!mounted) return;
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: _Pill(
        icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
        label: _copied ? '${_copiedLabel()} ✓' : ref.tr('copy_location'),
        background: AppColors.white,
        foreground: _copied ? AppColors.success : AppColors.blueDeep,
        switchKey: _copied,
        onTap: _onTap,
      ),
    );
  }

  String _copiedLabel() => ref.tr('copied');
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.switchKey = false,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  /// Changing this value cross-fades the content.
  final bool switchKey;

  @override
  Widget build(BuildContext context) {
    return TactileScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(28),
        ),
        child: AnimatedSwitcher(
          duration: AppDurations.fast,
          switchInCurve: AppCurves.out,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.9, end: 1.0).animate(animation),
              child: child,
            ),
          ),
          child: Row(
            key: ValueKey(switchKey),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    fontFamilyFallback: const ['Noto Sans Khmer'],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({
    required this.type,
    required this.onTap,
    required this.onSos,
  });

  final FacilityType type;
  final VoidCallback onTap;
  final VoidCallback onSos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = switch (type) {
      FacilityType.hospital => ref.tr('medical'),
      FacilityType.police => ref.tr('police'),
      FacilityType.fire => ref.tr('fire'),
    };
    return Semantics(
      button: true,
      label: label,
      child: TactileScaleButton(
        onTap: onTap,
        child: Container(
          height: 104,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Container(width: 4, color: AppColors.red),
              const SizedBox(width: 56), // balances the SOS button on the right
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShieldBadge(type: type, size: 54),
                    const SizedBox(height: 2),
                    Text(
                      type == FacilityType.police ? label.toUpperCase() : label,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 56,
                child: Tooltip(
                  message: 'SOS',
                  child: IconButton.filled(
                    onPressed: onSos,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: AppColors.white,
                      fixedSize: const Size(40, 40),
                    ),
                    icon: const Icon(Icons.call_rounded, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
