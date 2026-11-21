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
                      onTap: () =>
                          _openMap(context, ref, FacilityType.values[i]),
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
        // Official SongKrous brand emblem replacing the truncated letters
        Semantics(
          label: ref.tr('app_name'),
          image: true,
          child: LiquidGlassContainer(
            radius: 12,
            tint: LiquidTint.frostStrong,
            useBlur: false,
            width: 38,
            height: 38,
            padding: const EdgeInsets.all(4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.emergency_rounded,
                  color: AppColors.red,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // GPS status: frosted glass pill with a live green beacon.
        Semantics(
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
                    Text(
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
                  ],
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
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
    final lang = ref.watch(langProvider);
    return LiquidGlassContainer(
      radius: 18,
      tint: LiquidTint.blue,
      useBlur: false,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (loc.gpsActive)
                const LiveBeacon(color: Color(0xFF4ADE80), size: 7)
              else
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                '📍 ${ref.tr('your_location')}',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '• ${loc.headlineFor(lang)}, ${loc.khanLineFor(lang)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    fontFamilyFallback: ['Noto Sans Khmer'],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _CopyPill(onCopy: onCopy)),
              const SizedBox(width: 8),
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
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
            Icon(icon, size: 16, color: colors.fg),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: colors.fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    fontFamilyFallback: const ['Noto Sans Khmer'],
                  ),
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
  const _CategoryCard({required this.type, required this.onTap});

  final FacilityType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = _CategoryStyle.of(type);
    // One language only, one line only.
    final title = ref.tr('cat_${style.key}');

    return AppInteractiveCard(
      semanticLabel: title,
      radius: 26,
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
      hoverBorder: style.accent.withValues(alpha: 0.4),
      borderWidth: 1.5,
      restShadow: [
        BoxShadow(
          color: style.shadow,
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
      builder: (context, hovered, pressed) => SizedBox(
        height: 136,
        child: Stack(
          children: [
            // Subtle, large shadow/watermark background icon inside the card
            Positioned(
              right: -12,
              bottom: -16,
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: -0.15,
                  child: Icon(
                    style.watermark,
                    size: 152,
                    color: style.accent.withValues(alpha: 0.08),
                    shadows: [
                      Shadow(
                        color: style.shadow,
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
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
                  height: 60,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 160),
                    curve: AppCurves.out,
                    scale: hovered ? 1.06 : 1.0,
                    child: EmergencyEmblem(type: type, size: 72),
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
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            height: 1.4, // Khmer stacks need the room
                            fontFamilyFallback: ['Noto Sans Khmer'],
                          ),
                        ),
                      ),
                    ),
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
