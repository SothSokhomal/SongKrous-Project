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
                    // The screen (and its ref) may be gone after the dialog.
                    if (khan != null && context.mounted) {
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
        const SizedBox(width: 6),
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
                      const SizedBox(width: 6),
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
        const SizedBox(width: 6),
        const LanguageCompactToggle(),
        const SizedBox(width: 6),
        // Settings: account, language, privacy, log out.
        Semantics(
          button: true,
          label: ref.tr('settings'),
          child: AppPressable(
            key: const ValueKey('home-settings'),
            onTap: () => context.push(AppRoutes.settings),
            haptic: AppHaptic.selection,
            builder: (context, hovered, pressed) => AnimatedScale(
              duration: const Duration(milliseconds: 120),
              scale: pressed ? 0.92 : 1,
              child: LiquidGlassContainer(
                width: 36,
                height: 36,
                radius: 18,
                useBlur: false,
                hovered: hovered,
                pressed: pressed,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.settings_rounded,
                  size: 20,
                  color: AppColors.blueDeep,
                ),
              ),
            ),
          ),
        ),
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
              height: 1.5,
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

/// Per-category look: tinted glass, accent colour, watermark and arrow chip.
class _CategoryStyle {
  const _CategoryStyle({
    required this.key,
    required this.accent,
    required this.tintTop,
    required this.tintBottom,
    required this.shadow,
    required this.watermark,
    required this.chip,
  });

  final String key;
  final Color accent;
  final Color tintTop;
  final Color tintBottom;
  final Color shadow;
  final IconData watermark;

  /// Background of the circular arrow button.
  final Color chip;

  static const medical = _CategoryStyle(
    key: 'medical',
    accent: Color(0xFFD91E2A),
    tintTop: Color(0xE0FFFFFF), // #FFFFFF @ 0.88
    tintBottom: Color(0xD1FFF1F2), // #FFF1F2 @ 0.82
    shadow: Color(0x1AD91E2A),
    watermark: Icons.medical_services_rounded,
    chip: Color(0xFFFEE2E2),
  );

  static const police = _CategoryStyle(
    key: 'police',
    accent: Color(0xFF0F3D91),
    tintTop: Color(0xE0FFFFFF),
    tintBottom: Color(0xD1EFF6FF),
    shadow: Color(0x1A0F3D91),
    watermark: Icons.local_police_rounded,
    chip: Color(0xFFDBEAFE),
  );

  static const fire = _CategoryStyle(
    key: 'fire',
    accent: Color(0xFFA8131D),
    tintTop: Color(0xE0FFFFFF),
    tintBottom: Color(0xD1FEF2F2),
    shadow: Color(0x1AA8131D),
    watermark: Icons.local_fire_department_rounded,
    // Fire shares Medical's red arrow chip.
    chip: Color(0xFFFEE2E2),
  );

  static _CategoryStyle of(FacilityType t) => switch (t) {
    FacilityType.hospital => medical,
    FacilityType.police => police,
    FacilityType.fire => fire,
  };

  /// Arrow colour: Police blue, otherwise emergency red.
  Color get arrow =>
      this == police ? const Color(0xFF0F3D91) : const Color(0xFFD91E2A);
}

/// One emergency card: a single bold title, nothing else. Tap → that
/// category on the map; the arrow → the SOS call screen.
class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({
    required this.type,
    required this.nearest,
    required this.onTap,
    required this.onSos,
  });

  final FacilityType type;

  /// Closest facility of this type. Not shown — only used to start the SOS
  /// call for the right place.
  final RankedFacility? nearest;
  final VoidCallback onTap;
  final ValueChanged<Facility?> onSos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = _CategoryStyle.of(type);
    // One language only, one line only.
    final title = ref.tr('cat_${style.key}');

    return AppInteractiveCard(
      semanticLabel: title,
      radius: 24,
      onTap: onTap,
      // Emergency card: stronger haptic, deeper sink.
      haptic: AppHaptic.medium,
      pressedScale: 0.97,
      clip: Clip.antiAlias,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [style.tintTop, style.tintBottom],
      ),
      // Crisp white specular rim; the category colour glows on hover.
      restBorder: Colors.white.withValues(alpha: 0.95),
      hoverBorder: style.accent.withValues(alpha: 0.35),
      borderWidth: 1.5,
      restShadow: [
        BoxShadow(
          color: style.shadow,
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
      builder: (context, hovered, pressed) => SizedBox(
        height: 100,
        child: Stack(
          children: [
            // Faint rotated watermark in the right half (Wallet-style depth).
            Positioned(
              right: -14,
              top: -8,
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: -0.28,
                  child: Icon(
                    style.watermark,
                    size: 110,
                    color: style.accent.withValues(alpha: 0.045),
                  ),
                ),
              ),
            ),
            // Glowing accent pill on the left edge: 5 → 7 px on hover.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: AppCurves.out,
                  width: hovered ? 7 : 5,
                  height: 48,
                  decoration: BoxDecoration(
                    color: style.accent,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: style.accent.withValues(alpha: 0.45),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 160),
                    curve: AppCurves.out,
                    scale: hovered ? 1.06 : 1.0,
                    child: EmergencyEmblem(type: type, size: 64),
                  ),
                  const SizedBox(width: 18),
                  // Shrinks (never wraps or clips) if a long Khmer title
                  // meets a narrow phone.
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            height: 1.5, // Khmer stacks need the room
                            fontFamilyFallback: ['Noto Sans Khmer'],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ArrowButton(
                    chip: style.chip,
                    arrow: style.arrow,
                    tooltip: ref.tr('sos_shortcut'),
                    label: '${ref.tr('sos_shortcut')} $title',
                    onTap: () => onSos(nearest?.facility),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 42 px tinted circle with an arrow that nudges 4 px right on hover; opens
/// the SOS screen for the nearest facility of this category.
class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.chip,
    required this.arrow,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final Color chip;
  final Color arrow;
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
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: chip,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 1.2,
                ),
              ),
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 130),
                curve: AppCurves.out,
                offset: Offset(hovered ? 4 / 22 : 0, 0),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 22,
                  color: arrow,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
