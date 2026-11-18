import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/app_animations.dart';
import '../../core/animations/pulsing_beacon.dart';
import '../../core/animations/staggered_entrance.dart';
import '../../core/constants/app_state.dart';
import '../../core/constants/facilities.dart';
import '../../core/constants/phnom_penh_data.dart';
import '../../core/router/app_routes.dart';
import '../../core/state/location_state.dart';
import '../../core/state/map_state.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_interactive.dart';
import '../../shared/widgets/emergency_emblem.dart';
import '../../shared/widgets/khan_picker.dart';
import '../../shared/widgets/language_toggle.dart';
import '../../shared/widgets/liquid_glass.dart';
import '../../shared/widgets/main_shell.dart';

/// 03_Home_SOS — Liquid Glass: a glossy blue location hero and three detailed
/// emergency cards (live nearest facility, distance/ETA, direct line), staggered
/// in over a soft ambient canvas.
class HomeSosScreen extends ConsumerWidget {
  const HomeSosScreen({super.key});

  // [begin, end] slices of the entrance controller.
  static const _bannerSlice = (0.0, 0.45);
  static const _cardSlices = [(0.15, 0.65), (0.3, 0.8), (0.45, 1.0)];

  Future<void> _copy(BuildContext context, WidgetRef ref) async {
    await Clipboard.setData(
      ClipboardData(
        text: ref.read(locationProvider).shareTextFor(ref.read(langProvider)),
      ),
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

  void _sos(BuildContext context, WidgetRef ref, Facility? facility) {
    context.push(AppRoutes.sosCall, extra: facility);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(locationProvider);

    return LiquidAmbientCanvas(
      child: SafeArea(
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
                child: _LocationHero(
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
                      nearest: rankFacilities(
                        loc.latLng,
                        type: FacilityType.values[i],
                      ).firstOrNull,
                      onTap: () =>
                          _openMap(context, ref, FacilityType.values[i]),
                      onSos: (f) => _sos(context, ref, f),
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

// ── Top bar ────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.gpsActive, required this.onGpsTap});

  final bool gpsActive;
  final VoidCallback onGpsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = gpsActive ? AppColors.blueDeep : AppColors.red;
    return Row(
      children: [
        const Icon(
          Icons.health_and_safety_rounded,
          color: AppColors.blueDeep,
          size: 28,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            ref.tr('app_name'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.blueDeep,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // GPS status: frosted glass pill with a live green beacon.
        Flexible(
          child: Semantics(
            button: true,
            child: AppPressable(
              onTap: onGpsTap,
              haptic: AppHaptic.selection,
              builder: (context, hovered, pressed) => AnimatedScale(
                duration: const Duration(milliseconds: 120),
                curve: AppCurves.out,
                scale: pressed ? 0.95 : 1.0,
                child: LiquidGlassContainer(
                  radius: 16,
                  useBlur: false,
                  hovered: hovered,
                  pressed: pressed,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (gpsActive)
                        const LiveBeacon(color: AppColors.success, size: 8)
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
                      Flexible(
                        child: Text(
                          ref.tr(gpsActive ? 'gps_active' : 'gps_off'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                            fontFamilyFallback: const ['Noto Sans Khmer'],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const LanguageCompactToggle(),
      ],
    );
  }
}

// ── Location hero ──────────────────────────────────────────────────────────

class _LocationHero extends ConsumerWidget {
  const _LocationHero({
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
    final lang = ref.watch(langProvider);
    return LiquidGlassContainer(
      radius: 26,
      tint: LiquidTint.blue,
      useBlur: false,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (loc.gpsActive)
                const LiveBeacon(color: Color(0xFF4ADE80), size: 8)
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 10),
              Text(
                '📍 ${ref.tr('your_location')}',
                style: text.labelSmall?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            loc.headlineFor(lang),
            style: text.titleLarge?.copyWith(
              color: AppColors.white,
              fontSize: 21,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            loc.khanLineFor(lang),
            style: text.bodyMedium?.copyWith(
              color: AppColors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _CopyPill(onCopy: onCopy)),
              const SizedBox(width: 10),
              Expanded(
                child: _GlassPill(
                  icon: Icons.map_rounded,
                  label: ref.tr('view_map'),
                  colors: AppButtonColors.glassOnBlue,
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

/// `Copy Location` → `✓ Copied` for 2 s, cross-faded with [AnimatedSwitcher].
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
      child: _GlassPill(
        icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
        label: _copied ? '✓ ${ref.tr('copied')}' : ref.tr('copy_location'),
        colors: _copied
            ? const AppButtonColors(
                bg: AppColors.white,
                hover: AppColors.white,
                pressed: AppColors.white,
                fg: Color(0xFF15803D), // 4.9:1 on the near-white glass
                glass: LiquidTint.frostStrong,
              )
            : AppButtonColors.glassOnBlueSolid,
        switchKey: _copied,
        haptic: AppHaptic.medium,
        onTap: _onTap,
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
    this.switchKey = false,
    this.haptic = AppHaptic.light,
  });

  final IconData icon;
  final String label;
  final AppButtonColors colors;
  final VoidCallback onTap;
  final AppHaptic haptic;

  /// Changing this value cross-fades the content (200 ms).
  final bool switchKey;

  @override
  Widget build(BuildContext context) {
    return AppInteractiveButton(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      colors: colors,
      haptic: haptic,
      onPressed: onTap,
      semanticLabel: label,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
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
            Icon(icon, size: 18, color: colors.fg),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  fontFamilyFallback: const ['Noto Sans Khmer'],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Emergency category card ────────────────────────────────────────────────

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({
    required this.type,
    required this.nearest,
    required this.onTap,
    required this.onSos,
  });

  final FacilityType type;

  /// Closest facility of this type (live distance/ETA), or null.
  final RankedFacility? nearest;
  final VoidCallback onTap;
  final ValueChanged<Facility?> onSos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final key = switch (type) {
      FacilityType.hospital => 'medical',
      FacilityType.police => 'police',
      FacilityType.fire => 'fire',
    };
    // One language only — never "English / Khmer".
    final title = ref.tr('cat_$key');

    final facility = nearest?.facility;
    final subtitle = nearest == null
        ? ''
        : '${facility!.shortName(lang)} • ${nearest!.summary(lang)}';
    final pill = switch (type) {
      FacilityType.hospital => ref.tr('tag_er'),
      FacilityType.police =>
        ref
            .tr('pill_direct')
            .replaceAll(
              '{phone}',
              ref.num(facility?.phone ?? EmergencyNumbers.police),
            ),
      FacilityType.fire =>
        ref
            .tr('pill_hotline')
            .replaceAll(
              '{phone}',
              ref.num(facility?.phone ?? EmergencyNumbers.fire),
            ),
    };
    final accent = type == FacilityType.police ? AppColors.blue : AppColors.red;

    return AppInteractiveCard(
      semanticLabel: title,
      radius: 22,
      glass: LiquidTint.frost,
      onTap: onTap,
      // Emergency card: stronger haptic, deeper sink.
      haptic: AppHaptic.medium,
      pressedScale: 0.97,
      padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
      builder: (context, hovered, pressed) => Row(
        children: [
          // Left accent glow strip: 4 → 6 px on hover.
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: AppCurves.out,
            width: hovered ? 6 : 4,
            height: 62,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.45),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnimatedScale(
            duration: const Duration(milliseconds: 160),
            curve: AppCurves.out,
            scale: hovered ? 1.06 : 1.0,
            child: EmergencyEmblem(type: type, size: 60),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.4,
                    fontFamilyFallback: ['Noto Sans Khmer'],
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569), // 7.6:1 on the frosted card
                      height: 1.45,
                      fontFamilyFallback: ['Noto Sans Khmer'],
                    ),
                  ),
                const SizedBox(height: 6),
                LiquidGlassContainer(
                  radius: 10,
                  tint: LiquidTint.frostStrong,
                  useBlur: false,
                  shadow: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Text(
                    pill,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: type == FacilityType.police
                          ? AppColors.blueDeep
                          : const Color(0xFFB3121F),
                      fontFamilyFallback: const ['Noto Sans Khmer'],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _GlassChevron(
            tooltip: ref.tr('sos_shortcut'),
            label: '${ref.tr('sos_shortcut')} $title',
            onTap: () => onSos(facility),
          ),
        ],
      ),
    );
  }
}

/// 36 px glass circle with a chevron that nudges right on hover; opens the
/// SOS screen for the nearest facility.
class _GlassChevron extends StatelessWidget {
  const _GlassChevron({
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: label,
        child: AppPressable(
          onTap: onTap,
          haptic: AppHaptic.medium,
          builder: (context, hovered, pressed) => AnimatedScale(
            duration: const Duration(milliseconds: 130),
            curve: AppCurves.out,
            scale: pressed
                ? 0.90
                : hovered
                ? 1.08
                : 1.0,
            child: LiquidGlassContainer(
              radius: 18,
              tint: LiquidTint.frostStrong,
              useBlur: false,
              hovered: hovered,
              pressed: pressed,
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 130),
                curve: AppCurves.out,
                offset: Offset(hovered ? 4 / 22 : 0, 0),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: AppColors.blueDeep,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
